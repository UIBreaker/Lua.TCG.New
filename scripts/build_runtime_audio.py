"""Build cached Vorbis release assets without touching the source WAVs.

Requires FFmpeg with libvorbis and NumPy. Set FFMPEG if it is not on PATH.
"""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / "dist/runtime-audio"
RECIPE = "vorbis-q7-stereo-v1"


def ffmpeg_path():
    configured = os.environ.get("FFMPEG") or shutil.which("ffmpeg")
    if configured:
        return configured
    for folder in (ROOT / "dist", ROOT / ".tmp"):
        found = next(folder.rglob("ffmpeg*.exe"), None)
        if found:
            return str(found)
    raise RuntimeError("Install FFmpeg with libvorbis or set FFMPEG to its executable")


def encode(source, ffmpeg):
    relative = source.relative_to(ROOT)
    output = (CACHE / relative).with_suffix(".ogg")
    metadata = output.with_suffix(".json")
    signature = hashlib.sha256(source.read_bytes() + RECIPE.encode()).hexdigest()
    if metadata.exists() and output.exists():
        cached = json.loads(metadata.read_text())
        if cached["source"] == signature and cached["output"] == hashlib.sha256(output.read_bytes()).hexdigest():
            return relative, output if cached["use_ogg"] else source, cached
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([ffmpeg, "-v", "error", "-nostdin", "-y", "-i", str(source),
                    "-map_metadata", "-1", "-c:a", "libvorbis", "-q:a", "7", str(output)], check=True)
    with wave.open(str(source)) as wav:
        assert wav.getsampwidth() == 2, source
        channels, rate, frames = wav.getnchannels(), wav.getframerate(), wav.getnframes()
        original = np.frombuffer(wav.readframes(frames), dtype="<i2").astype(np.float32) / 32768
    decoded = subprocess.run([ffmpeg, "-v", "error", "-nostdin", "-i", str(output),
                              "-f", "f32le", "-c:a", "pcm_f32le", "-"], check=True, capture_output=True).stdout
    actual = np.frombuffer(decoded, dtype="<f4")
    peak = float(np.max(np.abs(actual)))
    source_peak = float(np.max(np.abs(original)))
    energy_ratio = float(np.mean(actual ** 2) / max(1e-12, np.mean(original ** 2)))
    # Keep tiny/codec-sensitive sounds as PCM instead of padding, clipping or cutting them.
    valid = (abs(len(actual) - len(original)) <= channels * rate * .005
             and peak <= min(1, source_peak * 1.2 + .0001) and .94 <= energy_ratio <= 1.06)
    use_ogg = valid and output.stat().st_size < source.stat().st_size * .9
    report = dict(source=signature, output=hashlib.sha256(output.read_bytes()).hexdigest(),
                  use_ogg=bool(use_ogg), channels=channels, rate=rate,
                  duration=frames / rate, decoded_duration=len(actual) / channels / rate,
                  source_peak=source_peak, decoded_peak=peak, energy_ratio=energy_ratio)
    metadata.write_text(json.dumps(report, indent=2), encoding="utf-8")
    return relative, output if use_ogg else source, report


def build():
    ffmpeg = ffmpeg_path()
    sources = sorted((ROOT / "assets/audio").rglob("*.wav"))
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(lambda p: encode(p, ffmpeg), sources))
    mapping = {relative: packed for relative, packed, _ in results}
    raw = sum((ROOT / path).stat().st_size for path in mapping)
    packed = sum(path.stat().st_size for path in mapping.values())
    converted = sum(report["use_ogg"] for _, _, report in results)
    print(f"Runtime audio: {converted}/{len(sources)} Vorbis, {raw / 1048576:.1f} -> {packed / 1048576:.1f} MiB", flush=True)
    return mapping


if __name__ == "__main__":
    build()

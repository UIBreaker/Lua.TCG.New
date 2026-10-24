"""Check the shipped SFX mix, including variants, Nen, loot and timing feedback."""
import json
import re
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]


def check():
    manifest = json.loads((ROOT / "assets/audio/continental/manifest.json").read_text())
    entries = []
    for section in ("sfx", "variants"):
        for name, cue in manifest[section].items():
            base = re.sub(r"_[23]$", "", name) if section == "variants" else name
            entries.append((name, cue["path"], manifest["sfx"][base]["gain"]))
    for catalog in ("attack_outcome_audio", "reward_audio_baked", "timing_audio_baked"):
        for line in (ROOT / "config" / (catalog + ".lua")).read_text().splitlines():
            path = re.search(r'path="([^"]+)"', line)
            gain = re.search(r"gain=([\d.e+-]+)", line)
            if path and gain:
                entries.append((Path(path[1]).stem, path[1], float(gain[1])))
    assert len(entries) == 958, "all SFX banks and variations must be checked"
    max_high, max_rms = 0, 0
    for name, path, gain in entries:
        with wave.open(str(ROOT / path)) as source:
            assert (source.getnchannels(), source.getframerate(), source.getsampwidth()) == (2, 32000, 2)
            pcm = np.frombuffer(source.readframes(source.getnframes()), "<i2").reshape(-1, 2) / 32768
        assert np.isfinite(pcm).all() and np.max(np.abs(pcm[[0, -1]])) == 0, name
        assert 0 < gain <= .60, name + " excessive gain"
        power = np.abs(np.fft.rfft(pcm, axis=0)) ** 2
        frequencies = np.fft.rfftfreq(len(pcm), 1 / 32000)
        high = float(power[frequencies >= 5000].sum() / max(1e-15, power.sum()))
        rms = float(np.sqrt(np.mean(pcm ** 2)) * gain * .8)
        assert high < .015, name + " brittle high-frequency energy"
        assert .0001 < rms < .11, name + " inaudible or excessive sustained energy"
        max_high, max_rms = max(max_high, high), max(max_rms, rms)
    print(f"Quiet SFX PASS: {len(entries)} files; maximum >5kHz energy {max_high:.2%}, default played RMS {max_rms:.3f}")


if __name__ == "__main__":
    check()

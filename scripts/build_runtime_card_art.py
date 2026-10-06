"""Build small runtime card textures; keep the original Continental PNGs intact.

Run after adding or changing card art. Requires Pillow, already used by the
asset/release scripts. Missing runtime copies fall back to the original in game.
"""
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART_ROOT = ROOT / "assets/cards/continental"


def build():
    paths = sorted(set(re.findall(r'"(assets/cards/continental/[^"\n]+\.png)"',
                                 (ROOT / "config/continental_asset_paths.lua").read_text(encoding="utf-8"))))
    source_bytes = runtime_bytes = written = 0
    for path in paths:
        source = ROOT / path
        with Image.open(source) as image:
            has_alpha = ("A" in image.getbands() and image.getchannel("A").getextrema()[0] < 255) or "transparency" in image.info
            destination = (ART_ROOT / "runtime" / source.relative_to(ART_ROOT)).with_suffix(
                ".png" if has_alpha else ".jpg")
            if not destination.exists() or destination.stat().st_mtime_ns < source.stat().st_mtime_ns:
                image.thumbnail((512, 768), Image.Resampling.LANCZOS)
                destination.parent.mkdir(parents=True, exist_ok=True)
                if has_alpha:
                    image.save(destination, optimize=True)
                else:
                    image.convert("RGB").save(destination, quality=94, subsampling=0, optimize=True)
                alternate = destination.with_suffix(".jpg" if has_alpha else ".png")
                if alternate.exists():
                    alternate.unlink()
                written += 1
        source_bytes += source.stat().st_size
        runtime_bytes += destination.stat().st_size
    print(f"Runtime card art: {len(paths)} textures, {written} updated; "
          f"{source_bytes / 1048576:.1f} MiB -> {runtime_bytes / 1048576:.1f} MiB")


if __name__ == "__main__":
    build()

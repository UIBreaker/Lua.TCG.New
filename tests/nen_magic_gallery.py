"""Contact sheets from native rendered frames; never writes game assets."""
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parents[1]
output = root / "docs/nen_magic"
rows = re.findall(r'^add\("([^"]+)","([^"]+)"', (root / "config/nen_magic_config.lua").read_text(encoding="utf-8"), re.M)
assert len(rows) == 27
font = ImageFont.truetype(str(root / "fonts/arial.ttf"), 17)
for phase in ("travel", "impact"):
    sheet = Image.new("RGB", (1260, 2160), "#0b101b")
    draw = ImageDraw.Draw(sheet)
    for i, (hand, name) in enumerate(rows):
        with Image.open(output / f"{hand}_{phase}.png") as source:
            frame = source.convert("RGB").crop((300, 140, 1020, 540))
            frame.thumbnail((414, 210))
        x, y = i % 3 * 420, i // 3 * 240
        sheet.paste(frame, (x, y + 28))
        draw.text((x + 8, y + 4), f"{i + 1:02}  {name}", font=font, fill="#d5e4fa")
    sheet.save(output / f"review_{phase}.jpg", quality=91)

heroes = ("high_card", "pair", "full_house", "tesla_369", "sealed_gate", "endless_cycle")
sheet = Image.new("RGB", (1260, 1260), "#0b101b")
draw = ImageDraw.Draw(sheet)
for i, hand in enumerate(heroes):
    name = dict(rows)[hand]
    y = i * 210
    for j, phase in enumerate(("travel", "impact")):
        with Image.open(output / f"{hand}_{phase}.png") as source:
            frame = source.convert("RGB").crop((360, 140, 960, 490))
            frame.thumbnail((570, 185))
        sheet.paste(frame, (j * 630 + 45, y + 24))
    draw.text((18, y + 2), name, font=font, fill="#e8d5a5")
    draw.text((650, y + 2), "VA CHẠM", font=font, fill="#7d9cb5")
sheet.save(output / "highlights.jpg", quality=92)

# Compact combat evidence; the exact damage-layer comparisons remain lossless PNGs.
for path in (output / "combat_final").glob("*.png"):
    with Image.open(path) as source:
        source.convert("RGB").save(path.with_suffix(".jpg"), quality=85)
print("27 travel + 27 impact review sheets, six highlights, compact combat evidence created.")

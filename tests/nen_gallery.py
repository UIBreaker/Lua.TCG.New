"""Build review sheets from native LÖVE frames; does not alter game assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import sys
sys.stdout.reconfigure(encoding="utf-8")

root = Path(sys.argv[1])
if "--compact" in sys.argv:
    count = 0
    for file in root.glob("*.png"):
        with Image.open(file) as frame:
            frame = frame.convert("RGB")
            frame.thumbnail((960, 540))
            frame.save(file.with_suffix(".jpg"), quality=84)
        count += 1
    print(f"Compacted {count} review frames in {root.name}; source PNGs retained for explicit cleanup.")
    sys.exit(0)
phase = sys.argv[2] if len(sys.argv) > 2 else "anticipation"
files = sorted(root.glob(f"*_tier*_{phase}.png"))
if not files:
    files = sorted(root.glob(f"*_tier*_{phase}.jpg"))
for start in range(0, len(files), 18):
    group = files[start:start + 18]
    sheet = Image.new("RGB", (1200, ((len(group) + 2) // 3) * 195), "#11151c")
    pen = ImageDraw.Draw(sheet)
    for index, file in enumerate(group):
        frame = Image.open(file)
        sx, sy = frame.width / 1280, frame.height / 720
        frame = frame.crop((int(242*sx), int(150*sy), int(1022*sx), int(565*sy)))
        frame.thumbnail((394, 170))
        x, y = index % 3 * 400, index // 3 * 195
        sheet.paste(frame, (x, y + 20))
        pen.text((x + 4, y + 3), file.stem, fill="#d0d7e5")
    output = root / f"review_{phase}_{start // 18 + 1}.jpg"
    sheet.save(output, quality=88)
    print(output.resolve())

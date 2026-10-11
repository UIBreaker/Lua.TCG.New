"""Install and verify the new regional landscapes and neutral human portraits."""
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
catalog_path = ROOT / "docs/journey_assets.json"
catalog = json.loads(catalog_path.read_text(encoding="utf-8-sig"))
manifest_path = ROOT / "docs/asset_manifest.json"
manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
existing = {a["id"] for a in manifest["assets"]}
hashes = set()
for asset in catalog["assets"]:
    source = Path(asset["generator_source"])
    destination = ROOT / asset["file"]
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    with Image.open(destination) as image:
        w, h = image.size
        ratio = 16 / 9 if asset["group"] == "background" else 2 / 3
        assert image.format == "PNG" and abs(w / h - ratio) < .01, (asset["id"], image.size)
        assert w >= 512 and h >= 768
        asset["dimensions"] = [w, h]
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    assert digest not in hashes, "Duplicate new artwork: " + asset["id"]
    hashes.add(digest)
    asset["sha256"] = digest
    asset["status"] = "generated"
    if asset["group"] == "enemy" and asset["id"] not in existing:
        entry = dict(asset, rarity="", ability="Tấn công thông thường; vô chất. Thủ lĩnh giữ kỹ năng boss hiện có.",
                     source="src/expedition.lua", previous_paths=[], redesigned_from_existing=False,
                     generation={"id": asset["id"], "generator_source": str(source), "prompt": asset["prompt"]})
        manifest["assets"].append(entry)
        receipt = ROOT / "docs/continental_generated" / (asset["id"] + ".json")
        receipt.write_text(json.dumps(entry["generation"], ensure_ascii=False, indent=2), encoding="utf-8")
manifest["completion"] = {"generated": sum(a.get("status") == "generated" for a in manifest["assets"]),
                          "total": len(manifest["assets"]), "missing": [a["id"] for a in manifest["assets"] if a.get("status") != "generated"]}
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
prompt_path = ROOT / "docs/CONTINENTAL_ASSET_PROMPTS.md"
prompts = prompt_path.read_text(encoding="utf-8")
for asset in catalog["assets"]:
    heading = f"## {asset['group']} / {asset['id']} — {asset['name']}"
    if heading not in prompts:
        prompts += f"\n\n{heading}\n\nConcept: {asset['concept']}\n\nPrompt: {asset['prompt']}\n\nOutput: `{asset['file']}`\n\nSource: `src/expedition.lua`; mode: built-in image_gen\n"
prompt_path.write_text(prompts, encoding="utf-8")
font = ImageFont.truetype(str(ROOT / "fonts/arial.ttf"), 16)
for group, columns, tw, th in [("enemy", 6, 160, 240), ("background", 4, 320, 180)]:
    assets = [a for a in catalog["assets"] if a["group"] == group]
    cw, ch = tw + 16, th + 42
    sheet = Image.new("RGB", (cw * columns, ch * ((len(assets) + columns - 1) // columns)), (9, 15, 24))
    draw = ImageDraw.Draw(sheet)
    for i, asset in enumerate(assets):
        with Image.open(ROOT / asset["file"]) as image:
            image = image.convert("RGB")
            image.thumbnail((tw, th), Image.Resampling.LANCZOS)
            x, y = (i % columns) * cw + 8, (i // columns) * ch + 8
            sheet.paste(image, (x, y))
            draw.text((x, y + th + 5), asset["name"], font=font, fill=(229, 211, 174))
    sheet.save(ROOT / "docs/expedition" / ("journey_" + group + "_catalog.png"))
print(f"Journey assets: {len(hashes)} distinct PNGs, 20 backgrounds, 12 neutral portraits; manifests, prompts and QA sheets updated")

"""Integrate the 52 individually generated portraits and make QA contact sheets."""
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
assets = [json.loads(p.read_text(encoding="utf-8")) for p in (ROOT / "docs/continental_generated/v2").glob("*.json")]
assets.sort(key=lambda a: ({"heart": 0, "diamond": 1, "club": 2, "spade": 3}[a["suit"]], a["rank"]))
assert len(assets) == 52
hashes = set()
for a in assets:
    file = ROOT / a["file"]
    with Image.open(file) as im:
        assert im.width * 3 == im.height * 2, (file, im.size)
        a["dimensions"] = list(im.size)
    digest = hashlib.sha256(file.read_bytes()).hexdigest()
    assert digest not in hashes, "Duplicate portrait: " + a["key"]
    hashes.add(digest)
    a["sha256"] = digest
    a["status"] = "generated"
(ROOT / "docs/continental_52_v2.json").write_text(json.dumps({"version": 2, "generator": "built-in image_gen", "assets": assets}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

path_file = ROOT / "config/continental_asset_paths.lua"
paths = path_file.read_text(encoding="utf-8")
for a in assets:
    old = "assets/cards/continental/playing/" + a["key"] + ".png"
    assert old in paths or a["file"] in paths, old
    paths = paths.replace('"' + old + '"', '"' + a["file"] + '"')
path_file.write_text(paths, encoding="utf-8")

manifest_file = ROOT / "docs/asset_manifest.json"
manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
entries = manifest["assets"]
for a in assets:
    entry = next(e for e in entries if e["id"] == a["id"])
    old = entry["file"]
    entry.setdefault("previous_paths", [])
    if old != a["file"] and old not in entry["previous_paths"]:
        entry["previous_paths"].append(old)
    entry.update({k: a[k] for k in ("name", "ability", "ambition", "concept", "file", "prompt", "status", "dimensions", "sha256")})
    entry["abilityName"] = a["abilityName"]
    entry["generation"] = {"mode": "built-in image_gen", "generator_source": a["generator_source"], "prompt": a["prompt"]}
manifest_file.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

sections = ["# Continental 52 — thiết kế khả năng và nhân vật", "", "Ngày 2026-10-07. Bộ 52 dùng bốn trục tài nguyên: Máu, Giáp, Tốc đánh, Vàng. Tranh được tạo riêng từng lá bằng built-in image_gen; PNG gốc 2:3, không chứa UI.", "", "## Quy tắc chiến thuật", "", "Khả năng chạy trước so tốc đánh; mỗi instance một lần/tay, chỉ lá tính điểm. Tái kích hoạt điểm không tái tạo tài nguyên. Điều kiện Máu/Giáp/Vàng dùng ảnh chụp đầu tay, chi phí dùng số dư thực tế theo thứ tự tính điểm. Thiếu chi phí thì dùng nhánh an toàn ghi trên lá.", "", "Cơ chuyển hồi dư thành Giáp; Bích tích và đổi Giáp; Chuồn giành nhịp trước quái; Rô kiếm tiền hoặc chi cho hồi phục, Giáp, Tốc. Khả năng bị khóa và lá kiệt sức không kích hoạt. Các khả năng phe cũ và Át đổi chất được thay thế để không cộng chồng ngoài ngân sách.", "", "Giới hạn chung từ bộ 52: 12 hồi Máu, 24 Giáp, +3 Tốc mỗi tay; 3 Vàng mỗi tay và 12 Vàng mỗi trận. Tiền không bị nhân theo số lượt lặp. Đây là giới hạn chống farm, không phải tuyên bố mọi deck có tỉ lệ thắng bằng nhau.", "", "Tốc nền: 2–10 = 14 − rank; J/Q/K = 3; A = 7. Lá thấp nhanh, lá lớn/hoàng gia sát thương cao. Tốc tay là trung bình mọi lá chơi + thưởng khả năng, bao gồm lá chơi không tính điểm trong mẫu trung bình. UI dự báo dùng cùng phép tính với thực thi.", "", "## Các hướng phối hợp", "", "- Đôi cơ động: 2 Cơ + 2 Chuồn; hồi phục đi cùng quyền đánh trước.", "- Băng và tiếp tế: 8 Bích + 8 Rô; Giáp đầu tay mở bảo lãnh kinh tế, chuyển Giáp sang tốc để giành nhịp.", "- Viễn chinh đa chất: các lá 4 tăng giá trị khi đủ 3 chất tính điểm; cần thế poker cho phép ít nhất 3 lá cùng tính điểm.", "- Hậu tuyến: giữ Q để tích; các lá 9 thưởng khi còn quân dự phòng. Giữ Q đồng nghĩa chưa dùng sát thương của Q.", "- Huyết tốc: 7 Cơ đánh đổi Máu khi đủ quỹ và còn khỏe; 7 Chuồn/7 Bích cứu thế trận khi bị thương.", "- Tài chính chủ động: 9 Rô cứu thương, 10 Rô mua tốc, K Rô mua thành lũy; tiền dùng chiến đấu sẽ giảm ngân sách mua đồ.", "- K đơn hành: K Chuồn/K Bích mạnh với một lá tính điểm; ít quân cộng dồn sát thương, đổi lại tự chủ phòng thủ/tốc.", "", "## Kiểm chứng", "", "`lovec . --test-continental52`: 11.232 tình huống với 52 danh tính, Máu/Vàng/Giáp, cấp 0/8, nhóm 1/2/5 lá. Kiểm tra preview thuần, chi phí, giới hạn, không farm khi lặp, tích/xả và thay đổi thứ tự đòn. Cần playtest các run đầy đủ để tiếp tục cân theo tỉ lệ thắng và nhịp kinh tế; bài test cơ chế không chứng minh cân bằng tuyệt đối.", "", "## Danh mục 52 nhân vật", "", "| Lá | Nhân vật | Khả năng cấp 0 | Khát vọng |", "|---|---|---|---|"]
sections.insert(sections.index("## Các hướng phối hợp"), "Vàng hoặc Tốc vượt giới hạn tạo 2 Giáp mỗi đơn vị; vẫn chịu trần 24 Giáp/tay. Lá kinh tế và tốc không mất hết giá trị khi đạt trần. Chi phí Máu được trừ trước hồi phục; không hồi sinh người chơi đã chết.")
sections.insert(sections.index("## Các hướng phối hợp"), "")
for a in assets:
    ability = a["ability"].replace("{" + a["resource"] + "}", str(a["base"])).replace("{bonus}", str(a["bonus"]))
    sections.append(f'| {a["key"]} | {a["name"]} | {ability} | {a["ambition"]} |')
(ROOT / "docs/CONTINENTAL_52_DESIGN.md").write_text("\n".join(sections) + "\n", encoding="utf-8")
prompt_sections = ["# Bộ prompt 52 chân dung mới", "", "Mỗi ảnh có một lần gọi built-in image_gen riêng. Bộ cũ được giữ để so sánh.", ""]
for a in assets:
    prompt_sections.extend([f'## {a["key"]} — {a["name"]}', "", f'Khát vọng: {a["ambition"]}', "", a["prompt"], "", f'Output: `{a["file"]}`', ""])
(ROOT / "docs/CONTINENTAL_52_PROMPTS.md").write_text("\n".join(prompt_sections), encoding="utf-8")
main_prompts = ROOT / "docs/CONTINENTAL_ASSET_PROMPTS.md"
prompts = main_prompts.read_text(encoding="utf-8")
link = "[Bộ 52 chân dung v2 và prompt riêng](CONTINENTAL_52_PROMPTS.md)"
if link not in prompts:
    main_prompts.write_text(prompts + "\n\n## Playing cards — v2\n\n" + link + "\n", encoding="utf-8")

font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 16)
for suit in ("heart", "diamond", "club", "spade"):
    group = [a for a in assets if a["suit"] == suit]
    sheet = Image.new("RGB", (816, 1280), "#101820")
    draw = ImageDraw.Draw(sheet)
    for i,a in enumerate(group):
        x,y = i % 4 * 204 + 6, i // 4 * 320 + 6
        with Image.open(ROOT / a["file"]) as im:
            sheet.paste(im.resize((192, 288), Image.Resampling.LANCZOS), (x,y))
        draw.text((x, y+290), a["key"] + " · " + a["name"].split(" · ")[0], font=font, fill="white")
    sheet.save(ROOT / f"docs/continental52_{suit}_sheet.jpg", quality=95)
print("52 unique PNG portraits verified, manifest/loader/prompts/design integrated; 4 contact sheets saved.")

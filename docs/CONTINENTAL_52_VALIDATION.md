# Kiểm chứng bộ 52 v2 — 2026-10-07

Đã lưu 52 PNG riêng biệt, mỗi ảnh 1024×1536. SHA-256 khác nhau cho mọi ảnh; không dùng đổi màu một chân dung. Đã xem bốn contact sheet và bảng render thực tế của cả 52 lá. Nguồn và prompt: `continental_52_v2.json`, `CONTINENTAL_52_PROMPTS.md`.

Đã tích hợp các alias hiện có vào loader và tạo 52 bản runtime 512×768 bằng pipeline hiện hữu. Ảnh cũ được giữ, đường dẫn lịch sử có trong manifest.

Các lệnh đã qua:

- `lovec . --test-continental52`: 11.232 tình huống; tên duy nhất, dự báo không thay đổi state, dự báo và tốc thực tế khớp, chi phí đúng, trần tài nguyên, không farm bằng retrigger, tích/xả, hồi dư thành Giáp, không hồi sinh ngoài ý muốn.
- `lovec . --test-continental52-regressions`: 52 trigger, tiến hóa và save roundtrip, 10 combo, 22 Boss, bed/speed, 200 nâng cấp inventory, soul shop, 8 spectral, 9 editions, 10 SPN tactics và 10 SPN anomalies.
- `lovec . --test-poker`: 11 kiểm tra thế bài và tích hợp tính điểm.
- `lovec . --test-features`: 6 nhóm tính năng nâng cao; potion tốc giữ đúng bonus với tốc nền mới.
- `lovec . --test-card-motion`: khung chung, 8 bậc và overflow, chuyển động/hover/hit area tại 30/60/120/144 FPS; khung đi cùng mặt lá.
- `lovec . --capture-continental52`: 52 texture riêng, các bậc khung, rank 10, tốc 999, tên và bảng mô tả. Chỉ số được vẽ lại sau mọi lần vẽ khung, kể cả khung thêm ở reward/shop.
- `git diff --check`: không có lỗi whitespace.

Ảnh kiểm chứng: `continental52_runtime.png`, `continental52_inspector.png`, `playing_card_rarity_frames.png`; bốn `continental52_*_sheet.jpg` dùng xem từng nhân vật rõ hơn.

Giới hạn kiểm chứng: suite tổng `lovec . --test` đã đi qua phần bài/Boss/collection/benchmark nhưng dừng ở kỳ vọng sát thương quái Ante 6 tối đa 50, trong khi cơ chế tăng sức mạnh quái hiện tại trả 59. `src/monster.lua` không đổi trong đợt này. Đây không phải phép chứng minh các run có tỉ lệ thắng bằng nhau. Cần chơi nhiều run để tiếp tục cân nhịp kinh tế và độ khó theo từng chiến thuật.

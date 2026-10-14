# Phúc Linh Khải Hoàn

SPN `spirit_victory_bounty`, bán trong shop như bình thường, có thể tiến hóa. Trang bị trước khi nhận lễ trao thưởng để hiệu ứng được chốt cùng kết quả chiến thắng.

| Bậc C ban đầu, cấp tiến hóa | Lượt rút thưởng thêm | Trọng số quà Hiếm trở lên |
| --- | --- | --- |
| 0 | +1 | ×2 (+100%) |
| 1 | +2 | ×2,5 (+150%) |
| 2 | +3 | ×3 (+200%) |

Lượt rút thêm dùng bảng thưởng của trận: trận thường 2–3 lượt thành 3–4; boss 3–4 thành 4–5 ở cấp 0. Mỗi lượt thêm có thể là quân bài, vàng, gói, tiêu hao hoặc rương theo bảng đó và được nhận thật vào bộ bài, dự trữ hoặc hàng đợi gói. Rương có thể chứa nhiều món nên số món cuối cùng còn cao hơn số lượt rút. Tiếp tế và vé Void dùng luồng trao riêng hiện có.

Quà **Hiếm / Sử Thi / Huyền Thoại** trong bảng của lễ, nội dung rương thưởng và tiếp tế được tăng trọng số. Rương ITM, rương bạc/hoàng kim, tiêu hao tiến hóa và Thu Hoạch Linh Hồn hưởng ưu tiên theo bậc quà đã định nghĩa. Bậc quà được xét ở bảng lễ; hiệu ứng không tự nâng cấp từng quân bên trong gói.

Trọng số ×2 không đồng nghĩa xác suất cuối cùng luôn ×2. Với bảng trận thường hiện tại, tổng trọng số quà Hiếm trở lên là 5, các quà khác là 90: tỷ lệ mỗi lượt chuyển từ 5/95 ≈ **5,26%** sang 10/(90+10) = **10%**. Bảng boss chuyển từ 30/85 ≈ **35,29%** sang 60/(55+60) ≈ **52,17%**. Đây là tỷ lệ của lượt rút chính, chưa tính quà trong rương và tiếp tế.

Hiệu ứng tiến hóa, bậc hiếm cao, nhiều bản và Vọng Linh cộng các lượt thêm và phần trọng số tăng. Huyết Luyện/Void dùng hệ thống nhân hiệu quả hiện có. Tổng giới hạn mỗi lễ: +32 lượt và +2000% trọng số. Rương kế thừa ưu tiên độ hiếm nhưng không nhận thêm lượt rút để tránh nhân số lượng qua rương lồng nhau.

SPN trong dự trữ không kích hoạt; bỏ qua ải không nhận bonus. Khóa ô của boss được giải phóng theo hệ thống khi boss chết. Kết quả chốt một lần trong `pendingVictoryReward`, gồm `spnLootBonus`; tải lại, mở nhanh hoặc vẽ giao diện không quay lại RNG hay nhận quà lặp.

## Mã và kiểm tra

- Catalog / tiến hóa / trọng số: `src/spn_bounty.lua`, `src/deities.lua`.
- Tạo và trao loot: `src/reward_system.lua`; dòng vàng ở đầu lễ hiển thị lượt rút và hệ số hiếm đã chốt.
- `tests/spn_bounty_smoke.lua`: thưởng thực, ranh giới chọn trọng số chính xác, tiến hóa, rương, mọi bảng boss, giới hạn, sao chép, Huyết Luyện, skip/khóa/dự trữ, mua shop, lưu/tải và không trao lặp.
- Đã qua reward ceremony, bulk exchange, snapshot 78 SPN, scoring runtime 184 kiểm tra và hồi quy Continental 52 với 11.232 tình huống.
- Native LÖVE: `--test-spn-bounty-art`, kiểm tra loader/khung và lễ thưởng tiến hóa. Ảnh `docs/spn_bounty_runtime.png`, `docs/spn_bounty_ceremony.png`.

## Tranh

Tạo bằng **built-in ImageGen**, giữ phong cách Continental, PNG 1024×1536 tràn viền không chữ/khung. Bản runtime JPG 512×768 qua loader hiện có.

- PNG: `assets/cards/continental/spn/spirit_victory_bounty.png`.
- JPG: `assets/cards/continental/runtime/spn/spirit_victory_bounty.jpg`.
- Prompt/nguồn ảnh: mục “SPN victory abundance - 2026-10-14” trong `docs/CONTINENTAL_ASSET_PROMPTS.md`, metadata trong `docs/asset_manifest.json`.

Chưa playtest dài để đánh giá tốc độ tích lũy tài nguyên trong toàn bộ hành trình.

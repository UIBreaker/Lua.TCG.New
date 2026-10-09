# 6 SPN tốc đánh và hệ số nhân — 2026-10-09

Thêm 6 lá vào 42 SPN trước đó: tổng **48 SPN**. Hai lá chuyển tốc đánh sang chỉ số, bốn lá nhân Sát thương/Cường hóa/AURA. Tất cả khởi đầu Thường, giá 4, xuất hiện qua catalog chung của shop, phần thưởng, gói Hộ Linh và bộ sưu tập.

| SPN | Bậc Thường | Chiến thuật |
|---|---|---|
| **Phong Nha** | +4 Sát thương mỗi điểm tốc đánh trung bình của tay đã chơi. Tốc 10 thêm 40 ST. | Nuôi tốc bằng quân bài nhỏ, trang bị, tăng tốc và kỹ năng. Các lá không tính điểm vẫn ảnh hưởng tốc trung bình. |
| **Mạch Lôi** | +1 Cường hóa mỗi điểm tốc đánh trung bình. Tốc 10 thêm 10 CH. | Đưa trang bị tốc vào bộ bài để bổ sung Cường hóa; phối với Phong Nha tăng cả hai trục. |
| **Cự Linh Trễ Nhịp** | Tốc trung bình thấp hơn mục tiêu: ×2 Sát thương tại ô này; bằng tốc không kích hoạt. | Dùng tay chậm, chịu đòn trước rồi đánh nặng. Đặt các SPN cộng ST trước nó để phần cộng cũng được nhân. |
| **Song Nhịp** | Chơi đúng hai lá có tốc cá nhân bằng nhau: ×2 Cường hóa tại ô này. | Cân tốc hai lá qua trang bị/tăng tốc; không bắt buộc cùng hạng. J và K đều có tốc gốc 3 nên có thể đồng nhịp. |
| **Dư Chấn Tàn Quang** | Có ít nhất ba lá đã chơi không tính điểm: ×2 AURA tổng. | Chơi tay nhỏ có nhiều lá thừa; tận dụng AURA cố định của Vết Nứt, Lò Hồn, Mộ Chữ Số. |
| **Mặt Trời Cuối** | Không còn lượt đánh sau khi chơi, còn ít nhất 10 Giáp tại ô này: đốt toàn bộ Giáp để ×3 AURA tổng. | Dồn Giáp cho đòn kết trận. Quái nhanh đánh trước có thể làm mất Giáp và phá điều kiện. SPN hồi thêm lượt ở ô trước cũng khiến tay không còn là lượt cuối. |

## Công thức và tiến hóa

Tốc tay dùng cùng nguồn với thứ tự đánh trong chiến đấu: trung bình tốc cá nhân của mọi lá đã chơi, cộng thưởng tốc chiến thuật, trần 999. Tốc cá nhân gồm tốc theo hạng, thưởng vĩnh viễn, thưởng tạm thời và trang bị. Hàm đọc tốc mới không thay đổi cache, bonus hoặc RNG khi xem trước. Game truyền tốc đã chốt lúc xác định thứ tự đánh vào chấm điểm thật; xem trước dùng bộ tính tốc hiện có ở chế độ thuần.

`xChips` nhân trục Sát thương tại vị trí SPN; `xMult` nhân Cường hóa tại vị trí SPN. `xAura` nhân tổng sau công thức và sát thương cố định, trước khi trả nợ Quỹ Đạo Khuyết. Ví dụ AURA gốc 100, cố định +25 và ×2 AURA cho 250. Nếu có nợ 20 thì còn 230, khoản nợ không bị nhân thành 40. Nhiều SPN nhân AURA tạo tích hệ số: ×2 cùng ×3 thành ×6. Giới hạn ×5 hiện có của hệ số quân bài/trang bị giữ nguyên.

Tiến hóa tăng phần hệ số vượt 1 theo quy tắc SPN chung: ×2 → ×2.5 sau một lần; ×3 → ×4. Hệ số tốc cũng tăng: Phong Nha từ +4 lên +6 ST/tốc, Mạch Lôi từ +1 lên +1.5 CH/tốc. Chi phí đốt Giáp và mốc 10 Giáp không tăng theo hệ số; hai bản Mặt Trời Cuối chia một ngân sách Giáp, không cùng tiêu số Giáp đã mất.

Xem trước không đốt Giáp; khóa ô vô hiệu hóa cả chỉ số và chi phí. Thứ tự ô quyết định các khoản cộng/nhân và lượng Giáp/lượt còn để dùng. Bộ tích số của 4 SPN trước được giữ nguyên. Save/load khôi phục callback, hệ số và tiến hóa của 6 lá mới; không mang bộ nhớ trận sang chuyến đi mới.

## Ảnh và kiểm tra

Tranh tạo bằng built-in imagegen, PNG 1024×1536 ở `assets/cards/continental/spn/`, texture runtime JPG 512×768 tương ứng. Cả sáu có concept riêng, dùng loader và khung chung Continental. Prompt chính xác và nguồn tạo ảnh nằm trong `docs/CONTINENTAL_ASSET_PROMPTS.md` và `docs/asset_manifest.json`. Bản chụp sáu lá qua game: `docs/spn_velocity_runtime.png`.

`tests/spn_velocity_smoke.lua` kiểm tra tốc thật và các loại bonus, tốc phân số/trần, điều kiện bằng tốc, thứ tự ô, hệ số tích nhau, sát thương cố định và nợ AURA, Giáp dùng chung, lượt đã trừ của caller thật, hồi lượt trước ô, xem trước thuần, tiến hóa, khóa ô và save/load. Các smoke test SPN cũ, snapshot 48 lá, trình diễn công thức và hồi quy LÖVE cũng được chạy.

Chưa đánh giá cân bằng qua nhiều chuyến đi dài.

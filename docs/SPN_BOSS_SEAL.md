# Kẻ Xóa Vương Quyền — 2026-10-22

SPN `spirit_crown_eraser`, Common, giá 4 Vàng; bán trong shop và có thể tiến hóa.

| Cấp tiến hóa | Sát thương mỗi tay | Cường hóa mỗi tay |
|---|---|---|
| 0 | +0 | +0 |
| 1 | +5 | +5 |
| 2 | +10 | +10 |
| 3 | +15 | +15 |

Mỗi cấp cộng đúng 5 vào cả hai trục. Không áp dụng thêm hệ số tiến hóa mặc định lần thứ hai; bậc gốc không tự cấp thưởng tiến hóa. Bản sao khả năng và khóa ô dùng quy tắc tính điểm hiện có; phần thưởng chỉ có hiệu lực khi trang bị.

Trong trận Boss, mở **Balo → SPN**, chọn bản đang trang bị hoặc trong kho, rồi nhấn **TIÊU HỦY · VÔ HIỆU BOSS**. Được chủ động hủy ngay cả khi Boss khóa ô/bậc SPN. Không mất Vàng hoặc lượt đánh. Thao tác chỉ thực hiện trong lượt người chơi, không chen vào hoạt ảnh hay đòn địch. Không tiêu khi ngoài trận Boss, Boss đã chết hoặc đã bị phong ấn.

Xóa vĩnh viễn bản SPN được chọn, phát sự kiện tiêu hủy thật cho các SPN tích lũy. Sau đó vô hiệu hóa nội tại và chiêu thức của mọi Boss đang sống trong trận đến hết trận; không giới hạn số tay. Boss vẫn đánh thường và vẫn giữ trang bị/tiêu hao vốn có. Gỡ khóa ô, khóa quân/chất, câm lặng, úp mặt, giới hạn chọn bài và các phong tỏa tài nguyên đang duy trì; bỏ sát thương chiêu thức còn chờ. Không hồi lại Vàng/HP hay vật phẩm đã bị tiêu hủy trước đó.

Bao gồm Boss thường, mười Boss người, thực thể Vương Quốc và bốn Boss người tự do: ngừng chống oneshot/hồi sinh, hạ bậc, cấm thế, gạch tên, tăng tốc/sát thương theo chất và những chiêu riêng. Gỡ biến hình tạm, giải cứu quân còn sống bị khống chế và bỏ các chỉ số tăng trực tiếp từ năng lực Boss người. Lượt bỏ bị Boss Đoạn Mệnh khóa được trả lại. Mỗi Boss mới bắt đầu với năng lực hoạt động bình thường.

Bán, hiến tế cho SPN khác, bị Boss hủy hoặc tự hủy không kích hoạt phong ấn. Chỉ thao tác chủ động tại nút balo kích hoạt hiệu ứng này.

Mã chính: `src/spn_boss_seal.lua`; các đường năng lực dùng cờ `spnAbilitiesSealed` trên instance Boss. UI trong `ui/backpack.lua` và callback tại `main.lua`.

Kiểm tra: `tests/spn_boss_seal_smoke.lua`, các bộ Boss người/tự do/Vương Quốc, scoring audit, `--test-spn-boss-seal-ui` và `--test-spn-boss-seal-art`. Tranh runtime: `docs/spn_boss_seal_runtime.png`.

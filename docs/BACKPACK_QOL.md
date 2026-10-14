# Balo: thao tác và tra cứu

Kho tiêu hao gộp các lá giống nhau thành chồng tối đa 99 lá, hiển thị ×số lượng ngay trên lá. Từ lá thứ 100 tạo chồng mới. Hiệu lực khác nhau được giữ riêng. Lấy ra trang bị hoặc bán chỉ trừ một lá; cất lại tự gộp. Ô mang vào trận vẫn chứa từng lá. Số lượng của save cũ và dấu nhận thưởng của từng lá được giữ nguyên. Số ở ngăn Tiêu hao là tổng số lá trong kho.

Kiểm tra chồng: `tests/consumable_stacks_smoke.lua` (mốc 99/100/199/1.000, phiên bản khác hiệu lực, lấy/cất/bán từng lá, save cũ); `--capture-shop --capture-consumable-stacks` (hiển thị, thay đồ, dùng/bán thật, save và 960×540).

- Tìm theo tên, nhân vật, khả năng và chỉ số; không cần gõ dấu, có thể nhập nhiều từ.
- Sắp xếp theo thứ tự kho, tên A–Z hoặc tầng/bậc giảm dần. Bàn ghép có ưu tiên công thức ghép được.
- Lọc trang bị cơ bản/đồ lớn, quân bài có/chưa có trang bị, hoặc công thức đủ nguyên liệu và vàng.
- Nhớ trang, từ tìm và bộ lọc riêng cho mỗi ngăn trong phiên chơi; đóng/mở lại không quay về trang đầu.
- Nhấp đúp trang bị để chọn lá gắn. Mặc định chỉ hiện lá gắn được; đổi sang Mọi lá nếu muốn kiểm tra lá bị thiếu hốc hoặc trùng đồ.
- Esc khi đang gắn quay về trang trang bị trước đó; các bước xem cây trang bị cũng có thể quay lại bằng Esc.
- Chọn SPN/tiêu hao trong kho rồi nhấp một ô phía trên để gắn hoặc thay thế. Món bị thay trở về kho; vẫn có thể kéo thả.
- Tiêu hao đang mang có nút Dùng vật phẩm rõ ràng. Nút bán nằm riêng ở hồ sơ bên phải, không chồng lên nút dùng.
- Công thức báo cụ thể nguyên liệu đầu tiên hoặc số vàng còn thiếu. Tìm kiếm không có kết quả có hướng dẫn khôi phục.
- Nền balo được dựng lại khi đổi kích thước cửa sổ, tránh lộ giao diện shop phía sau.

| Phím | Thao tác |
|---|---|
| I | Mở/đóng balo |
| Ctrl+F | Tìm trong ngăn hiện tại |
| Ctrl+A / Ctrl+V | Chọn toàn bộ / dán từ tìm |
| Ctrl+Backspace | Xóa từ tìm |
| 1–5 | Đổi ngăn khi không nhập từ tìm |
| PgUp / PgDn | Chuyển trang; cuộn khi đang xem toàn bộ cây |
| Enter | Rời ô tìm; gắn/ghép/sắp xếp món đang chọn khi không nhập từ tìm |
| Esc | Rời ô tìm → hủy gắn / trở về cây trước → đóng balo |

Trong combat, đổi SPN/tiêu hao vẫn dùng đúng một lượt đánh, địch vẫn hành động và các ô bị boss khóa vẫn được kiểm tra. Gắn trang bị quân bài, bán trang bị và ghép đồ vẫn chỉ thực hiện ở shop. Khi mở balo trong trận từ ngăn Bàn ghép, giao diện chuyển sang Trang bị.

Kiểm tra: `--test-backpack`; `--capture-shop --capture-backpack-qol`; `--capture-shop --capture-backpack-fullscreen`; `--test-battle-backpack`. Capture chạy riêng, không ghi đè save của người chơi.

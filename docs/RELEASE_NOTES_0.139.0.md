# Terra Suit — beta 0.139.0 cho Android

- Thêm **Song Quang Hội Tụ**: nhân tổng AURA ×2 / ×2,5 / ×3 theo tiến hóa; **Kẻ Dệt Số**: ghép rank các quân đã chơi theo đúng thứ tự thành AURA, giữ các quy tắc giáp/phòng thủ/né. Giao diện trình bày đúng công thức và xem trước.
- Thêm **Sứ Giả Khảo Luyện**: khi đã mở ít nhất ba thế, mỗi trận nhận hai thế khác nhau; hoàn thành cả hai sẽ tiến hóa ngẫu nhiên một SPN đang trang bị lên một cấp. Mỗi bản có nhiệm vụ riêng, tối đa một thưởng/trận, tiến hóa giữ qua lưu/tải.
- Thêm nguyên liệu **Mũi Thép** (3 Vàng, +5 Sát thương) và **Mảnh Hổ Phách** (4 Vàng, +1 Cường hóa). Cập nhật công thức chế tạo và nguồn hàng ở shop.
- Đánh hụt có quỹ đạo né, hiệu ứng và âm thanh riêng cho đủ 27 thế/ba cấp lực; không dùng nháy va chạm hoặc rung camera như đánh trúng.
- Nâng cấp khung và thông tin quân bài: số/chất rõ hơn, bảng tên/chỉ số, hiệu ứng hốc khảm; kho đồ địch trình bày đồ dùng/trang bị và chi tiết dễ đọc hơn.
- Thêm năm tranh Continental tương ứng; giữ các tối ưu tài nguyên, khởi động và cache RAM của beta 0.138.2. Âm thanh mới được bake sẵn; mobile không tổng hợp lúc vào game.

Android 6+, ARM64/ARMv7; khóa màn hình ngang, tràn màn hình. APK **117,6 MiB**. VersionCode **13900**, cùng khóa ký và định dạng save. Tải `LUA-TCG-0.139.0-Android.apk`, mở và chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Kiểm tra: 40 bộ scoring; trận thật với ba SPN mới; 756 cue Niệm khớp PCM/metadata bake, decoder phát đủ 108 SFX + 756 Niệm + 40 thưởng; mua/khảm/tháo/lưu tải hai nguyên liệu; 3.402 ca hiệu ứng hụt; cache âm thanh mobile, cảm ứng và bốn tỉ lệ màn hình. Luồng âm thanh được kiểm tra bằng LÖVE launcher trực tiếp (Python embedding từng lỗi ghi một file preview). APK được kiểm tra chữ ký, checksum, ZIP CRC và đối chiếu toàn bộ Lua/shader nhúng với mã nguồn phát hành.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Không xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

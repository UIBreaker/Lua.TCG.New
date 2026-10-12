# Terra Suit — beta 0.125.1 cho Android

- Sửa đường vẽ lửa sát thương cho Android: dùng mesh với tọa độ cục bộ, tránh phụ thuộc tọa độ framebuffer/DPI; tính noise với độ chính xác cao trên OpenGL ES.
- Thêm lớp lửa hình học chuyển động quanh số trên mobile, luôn hiện kể cả khi shader biên dịch thành công nhưng vẽ sai; dự phòng không shader rõ hơn.
- Giữ đúng bậc: dưới 100 là số bình thường, 100–999 cháy nhẹ, 1.000–9.999 cháy mạnh; từ 10.000 có sét và từ 100.000 có holographic. Mỗi hàng số cao hơn giữ bản sắc riêng.
- Giữ gameplay, phần thưởng và save của beta 0.125.0.

Tải `LUA-TCG-0.125.1-Android.apk`, mở rồi chọn **Cập nhật**. Không gỡ bản cũ để giữ save. Android 6.0+, ARM64/ARMv7; cùng khóa ký, versionCode 12501.

Kiểm tra shader OpenGL ES và số pixel lửa thực sự hiện ở 100, 250, 1.000, 7.700 và 9.999 với shader PC, mobile và không shader; kiểm tra mesh dùng lại và trạng thái đồ họa. APK được đối chiếu mã/shader và kiểm tra chữ ký/checksum. Chưa kiểm tra trực tiếp trên điện thoại người dùng.

# Terra Suit — beta 0.124.1 cho Android

- Hiệu ứng sát thương riêng theo từng hàng số: chục, trăm, nghìn, triệu, tỉ và cao hơn. Hào quang, lửa, dáng sét và holographic đổi theo bậc, giữ chữ số dễ đọc.
- Mobile giữ đủ kiểu hiệu ứng, giới hạn tối đa 12 đường sét, 2 nhánh/đường và 18 tàn lửa; có dự phòng khi thiết bị không hỗ trợ shader.
- Tinh chỉnh shader lửa và kiểm tra tương thích OpenGL ES; kiểm tra mã shader cùng Lua khi đóng gói để tránh APK chứa mã cũ.
- Giữ nội dung gameplay beta 0.124.0: chính xác theo tốc đánh, hỗ trợ của địch và hai SPN tiêu hao; giữ save, màn hình ngang tràn viền và cảm ứng.

Tải `LUA-TCG-0.124.1-Android.apk`, mở rồi chọn **Cập nhật**. Không gỡ bản cũ để giữ save. Android 6.0 trở lên, ARM64/ARMv7; cùng khóa ký, versionCode 12401.

Đã kiểm tra ranh giới hàng số tới 1e308, hiệu ứng/giới hạn hình học, nhiều FPS, khung hình mobile, shader OpenGL ES, chế độ dự phòng và trạng thái đồ họa. APK được đối chiếu source/shader, kiểm tra chữ ký và checksum. Chưa thử trên điện thoại Android thật.

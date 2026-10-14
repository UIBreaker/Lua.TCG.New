# Terra Suit — beta 0.133.0 cho Android

- Thêm bộ trình diễn 27 đòn Niệm với vũ khí, đường bay, palette và kiểu nổ riêng; bốn mức hình ảnh Normal/Enhanced/Overdrive/Maximum theo AURA.
- Tích hợp renderer/shader mới vào chiến đấu, giữ thời điểm tiếp xúc, số lần gây sát thương, công thức tính điểm và renderer số hiện có.
- Có giới hạn hạt/chất lượng, xử lý hủy/địch chết và phương án không shader; dùng bloom/world pass hiện có, phục hồi trạng thái graphics.
- Thêm công cụ preview và tài liệu/ảnh kiểm chứng; giữ nội dung trước, save, màn hình ngang tràn viền và cảm ứng.

Tải `LUA-TCG-0.133.0-Android.apk`, mở rồi chọn **Cập nhật**. Không gỡ bản cũ để giữ save. Android 6.0 trở lên, ARM64/ARMv7; cùng khóa ký, versionCode 13300.

Đã kiểm tra 27 profile, đường bay/giới hạn AURA, nhiều FPS, hủy/địch chết, hồi quy tính điểm và renderer native. Baseline scoring/UI/audio đã được đối chiếu; main chỉ đổi nhãn phiên bản khi đóng gói. APK được đối chiếu source/shader, kiểm tra chữ ký và checksum. Chưa thử trên điện thoại Android thật.

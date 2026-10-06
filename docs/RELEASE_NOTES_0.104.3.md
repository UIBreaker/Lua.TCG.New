# Terra Suit — beta 0.104.3 cho Android

Đóng gói đầy đủ nội dung từ commit `b655156aeabc364516c84831e43007f7323ac784`, chỉ đổi nhãn menu thành **beta 0.104.3**.

- Shader riêng cho 9 ấn bản lá bài.
- Ảnh runtime cho các lá bài và giao diện bộ sưu tập dạng sách.
- Bao gồm toàn bộ nội dung của bản trước; giữ màn hình ngang, tràn viền và điều khiển cảm ứng.

Tải `LUA-TCG-0.104.3-Android.apk`, mở file và chọn **Cập nhật**. Dùng cùng khóa ký với APK trước, versionCode 10403. Không gỡ bản cũ để giữ save.

Yêu cầu Android 6.0 trở lên, hỗ trợ ARM64 và ARMv7. Đã kiểm tra chữ ký, biên dịch cả 9 shader và chạy kiểm tra ấn bản, Giường/Tốc Đánh, cảm ứng và bố cục mobile. Chưa thử trên điện thoại Android thật.

Kiểm tra `--test-card-effects` còn thất bại ở giả định cũ rằng ô tiện ích shop luôn là lá hủy; mã hiện tại chọn ngẫu nhiên thuốc hoặc lá hủy. APK giữ nguyên hành vi của commit được yêu cầu.

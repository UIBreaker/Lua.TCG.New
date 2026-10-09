# Terra Suit — beta 0.120.0 cho Android

APK chứa đầy đủ nội dung từ commit `3353ff3f089af4fbcf2f1e25d911977ce6f12c20`, chỉ đổi nhãn menu thành **beta 0.120.0**. Tăng phiên bản tính năng từ 0.119.0 và giữ trạng thái beta.

- Thiết kế lại bố cục giao diện chiến đấu và lớp trang trí các bảng.
- Cập nhật HUD, bảng thông tin tay bài, SPN, tiêu hao và đội hình quái.
- Cải thiện trình bày điểm và xem trước đội hình.
- Bao gồm nội dung và âm thanh của bản trước; giữ khóa màn hình ngang, tràn viền và điều khiển cảm ứng.

Tải `LUA-TCG-0.120.0-Android.apk`, mở file và chọn **Cập nhật**. Dùng cùng khóa ký với APK trước, versionCode 12000. Không gỡ bản cũ để giữ save.

Yêu cầu Android 6.0 trở lên; hỗ trợ ARM64 và ARMv7. Đã kiểm tra giao diện chạy thực tế: đội hình 8 lá, chọn mục tiêu, kho, đánh bài/tính điểm, boss, menu phụ, ánh xạ thao tác ở 960/1920; vật liệu khôi phục trạng thái đồ họa và không tạo ảnh/canvas mới trong 30 frame. Kiểm tra phản hồi chiến đấu, trình bày điểm, cảm ứng và bố cục mobile đều qua. Chưa thử trên điện thoại Android thật.

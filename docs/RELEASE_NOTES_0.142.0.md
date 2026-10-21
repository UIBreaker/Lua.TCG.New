# Terra Suit — beta 0.142.0 cho Android

- **Đường HP dùng chung**: ba trận ải đầu có nền 50/100/150 HP (thường/tinh anh/boss, trước nội tại/trang bị riêng). Các ải sau tăng theo đường cong hiện có; tinh anh ×2, boss ×3 nền. Chiến dịch và xem trước cùng dùng một hàm tính, tránh hiển thị lệch.
- **Shop Nhỏ**: hai ô SPN/trang bị đổi chỗ sau mỗi reroll thành công, gồm lượt miễn phí/đặc quyền; không đổi khi thiếu tiền. Ưu đãi Đá Tam Kích theo đúng ô trang bị; lưu/tải giữ bố cục, lượt ghé mới đặt lại.
- **Loot**: bỏ rương quân bài khỏi các bảng thưởng trận/rương liên quan, vẫn giữ quân bài lẻ, trang bị, tiêu hao và các nhóm thưởng khác. Không xóa đồ đã sở hữu.
- **Kiểm tra bộ nhớ**: thêm regression 1.000 lần preview và bài soak nhiều vòng menu/trận/shop/inspector. Bản sửa weak-key/weak-value của preview đã có từ beta 0.141.0; bản này bổ sung kiểm chứng và CI, không nhận là sửa mới. Xem `docs/MEMORY_AUDIT.md`.
- Sửa launcher Windows chạy từ đúng thư mục game; giữ bộ khởi đầu năm lá, lưu/tải và các tính năng từ bản trước.

Đã đọc được 546 ID tranh và 958 file âm thanh trong gói mobile; xác minh mã nguồn nhúng, chữ ký, CRC và checksum. Soak Windows 6.000 frame hoàn tất, bộ nhớ ổn định sau warm-up trong chuỗi thao tác lặp cố định.

Đã qua 41 nhóm scoring và 12 nhóm bổ sung về cân bằng, shop, loot, lưu tải, preview memory và mobile. Báo cáo mô phỏng cân bằng ngày 20/10 là dữ liệu lịch sử, chưa chạy lại cho HP mới; không dùng để bảo đảm tỷ lệ thắng cấu hình hiện tại.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. APK **119,1 MiB**. VersionCode **14200**, cùng khóa ký. Mở `LUA-TCG-0.142.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Chưa xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0. Kiểm tra bộ nhớ có giới hạn không chứng minh mọi phiên chơi dài đều không rò rỉ.

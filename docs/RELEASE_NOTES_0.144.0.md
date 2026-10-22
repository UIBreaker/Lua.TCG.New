# Terra Suit — beta 0.144.0 cho Android

- **Bốn boss người tự do**, có thể gặp ở mọi vùng chính; mỗi boss chiếm 1/16 lượt chọn, bốn thực thể vương quốc vẫn giữ tổng 25%, Vương Huyết giữ nhánh riêng:
  - **Quan Chấp Cấm Thế**: mỗi thế đã mở chỉ dùng một lần/trận; hết thế hợp lệ khi boss còn sống sẽ thua. Hạ boss bằng thế cuối vẫn thắng.
  - **Kẻ Gạch Tên**: ghi ID quân đã đánh trong ải để vô hiệu khi gặp boss; mỗi lượt hạ một cấp tiến hóa của một lá đã ghi nhận. Lưu/tải giữ lịch sử ải, sang ải/vùng mới đặt lại.
  - **Kẻ Thách Tử**: sát thương nền ×5; đòn kết liễu từ đầy HP khiến boss tái lập HP theo sát thương thực và nhân ba sát thương. Mỗi lượt cho người chơi +20% tổng sát thương cộng dồn trong trận.
  - **Giám Quan Tước Phẩm**: phong ấn ngẫu nhiên một bậc SPN C–TT trong trận; cuối lượt hạ vĩnh viễn tối đa hai bậc một SPN trên C, gồm cả balo. HUD/tooltip hiển thị bậc đang khóa.
- **Kẻ Xóa Vương Quyền**: SPN Common, tăng +5 Sát thương và +5 Cường hóa mỗi cấp tiến hóa. Trong lượt chuẩn bị ở trận boss, mở Balo → SPN và chủ động tiêu hủy bản đang trang bị hoặc trong kho để phong ấn nội tại/kỹ năng mọi boss đang sống đến hết trận. Không tốn lượt/vàng; boss vẫn đánh thường và giữ trang bị/tiêu hao. Thao tác xóa vĩnh viễn SPN, không khôi phục những tài nguyên boss đã lấy trước đó. Bán/hiến tế/bị hủy tự động không kích hoạt phong ấn.
- Đồng bộ vô hiệu điểm/kỹ năng/trang bị/ấn, khóa bậc và nguồn SPN sao chép với dự báo, tính điểm thật, giao diện và lưu/tải. Thêm năm tranh Continental tương ứng.

Chi tiết: `docs/FREE_HUMAN_BOSSES.md`, `docs/DEATH_CHALLENGER.md`, `docs/RARITY_INQUISITOR.md`, `docs/SPN_BOSS_SEAL.md`.

Đã qua 42 nhóm scoring và 12 nhóm bổ sung; bốn boss và nút phong ấn được thử trong trận thật trên cấu hình mobile. Gói mobile đọc đủ 555 ID tranh, 958 file âm thanh; Lua/shader nhúng khớp nguồn, chữ ký/CRC/checksum hợp lệ.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. APK **120,3 MiB**. VersionCode **14400**, cùng khóa ký. Mở `LUA-TCG-0.144.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Chưa chạy lại mô phỏng toàn chiến dịch cho các boss/SPN mới. Chưa xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

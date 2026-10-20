# Terra Suit — beta 0.141.0 cho Android

- **Khởi đầu và độ khó**: Bộ Bài Đỏ bắt đầu với năm lá khác nhau, đủ bốn chất, rút ba lá vào tay. Quái mở đầu 100 HP; điều chỉnh đường tăng HP theo ải. Thắng trận hồi 20% HP tối đa ở ải 1–5, sau đó 15%; thắng boss tương ứng 40% / 30%, không nhận lặp.
- **Kinh tế và nguồn nâng cấp**: shop đầu luôn là Shop Nhỏ, Đá Tam Kích T1 giá 12 vàng mua tối đa một lần/run. Phần lớn hàng trả vàng dùng giá gốc ×4; trang bị chế sẵn tính theo cây nguyên liệu/phí ghép, SPN cao mở dần theo ải. Giá reroll tăng từ 5 vàng; bán giấy phép được 250 vàng. Shop Máu/Chợ Linh Hồn được cân lại giá, tránh vòng hồi máu miễn phí.
- **Cặp shop**: giữ lựa chọn hai lượt ghé, reroll và trạng thái mua/nhận thưởng qua lưu tải; sự kiện hành trình chờ xử lý đúng thời điểm.
- **AI và kho đồ địch**: phối hợp buff đồng đội, tránh hỗ trợ trùng, chọn vật phẩm theo tốc/độ chính xác và lượng sát thương đã quan sát. Sau hỗ trợ phải thử đánh; hành động thực thi tại nhịp tiếp xúc, không dùng vật phẩm vô hạn. Kho đồ tăng theo độ khó, không tự tăng ngân sách theo sức mạnh người chơi.
- **Boss nhân loại**: giảm áp lực sát thương bổ sung ở ải đầu; Chủ Hội Kim Quyền tối đa sáu lần tăng chỉ số từ tiền. Giữ các cơ chế và cảnh báo riêng.
- **Giao diện**: màn xem bộ bài mới, xem trước đối thủ rõ trang bị/đội hình/cơ chế, nâng inspector và mô tả để đọc trên màn hình nhỏ.

Chi tiết: `docs/BALANCE_APPLIED_REPORT.md`, `docs/ENEMY_TACTICS.md`, `docs/SHOP_MARKETS.md`. Kết quả mô phỏng dùng build/bot giả định; không đại diện tỷ lệ thắng người chơi hay bảo đảm toàn bộ chiến dịch đã cân bằng.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. APK **119,1 MiB**. VersionCode **14100**, cùng khóa ký. Mở `LUA-TCG-0.141.0-Android.apk` và chọn **Cập nhật**; không gỡ bản cũ để giữ save. Bộ khởi đầu mới áp dụng cho run mới, không thay bộ bài đang lưu.

Đã kiểm tra: 40 nhóm scoring, 15 nhóm cân bằng/shop/AI/lưu tải/mobile; ba màn giao diện mới chạy trong game thật ở 960; đủ 546 ID tranh và 958 file âm thanh decode được. APK khớp mã nguồn Lua/shader, CRC, chữ ký và checksum.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Không xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

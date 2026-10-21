# Terra Suit — beta 0.143.0 cho Android

- **Bốn thực thể vương quốc**: Chủ Tể Tro Tim, Kẻ Nuốt Hoàng Kim, Cội Rễ Lãng Quên, Bóng Vương Băng Tịch có tranh và cơ chế riêng. Chiếm 25% lượt chọn boss của vùng chính, không thay boss Vương Huyết. Phong ấn chất tương ứng; mỗi lá chất đó trên tay tăng 10% tốc và sát thương cho boss.
- **Tốc độ ×1/×2/×4**: nhịp ×1 bằng 65% nhịp cũ để dễ theo dõi; cài đặt được lưu, Siêu Tốc cũ chuyển sang ×2. Điều khiển, tooltip và âm thanh theo thời gian thực; không đổi tốc đánh hay sát thương gameplay.
- **SPN**: shop chỉ bán C/UC/R/E/L, vẫn mở E từ ải 3 và L từ ải 6. Mỗi SPN đang trang bị khi hạ boss nhận một lượt dùng lá Tiến Hóa; mỗi bậc tăng tốn một lượt. Balo giữ lượt đã tích, bản sao không nhận lượt chưa dùng của nguồn. Save cũ giữ bậc, bắt đầu với 0 lượt nếu chưa có dữ liệu. Kỹ năng tự tiến hóa giữ nguyên. Cân lại Độc Kích Thiên Thạch (+100 gốc) và Đồng Hồ Vô Tận (+0,5 Cường hóa/lần bỏ).
- **Kinh tế**: bán SPN/tiêu hao/quân bài theo 60% cơ sở định giá; trang bị theo 60% vàng đầu tư. Lưu giá thực trả, xử lý hàng miễn phí/HP/linh hồn và giảm giá để tránh vòng mua–bán kiếm lời; định giá đổi đồ dùng chung cơ sở. Save cũ không có hóa đơn dùng giá thị trường hiện tại.
- **Giao diện**: luồng khảm trang bị và nghi thức Tượng Cổ rõ lựa chọn/kết quả hơn; phản hồi kích hoạt, khóa và mất SPN ngay trên lá, bỏ bảng thông báo lớn che chiến trường. Giữ Reduced Motion.
- **Âm thanh**: nâng 142 SFX/biến thể, 756 cue Niệm và 40 cue thưởng bằng tiếng tiếp xúc nhiều lớp, transient và cộng hưởng; giữ motif/timing, gain, giới hạn peak và cache mobile. Nhạc/ambience giữ bản phối.

Chi tiết: `docs/KINGDOM_ENTITIES.md`, `docs/GAME_SPEED.md`, `docs/SPN_BALANCE_2026_10_21.md`, `docs/SHOP_MARKETS.md`, `docs/COMBAT_NOTICES.md`.

Gói mobile đọc được đủ 550 ID tranh và 958 file âm thanh; toàn bộ Lua/shader nhúng khớp nguồn, CRC/chữ ký/checksum hợp lệ. Kiểm tra âm thanh thật và luồng game ×1/×2/×4, bốn boss, phản hồi lá ở 960/1920, khảm trang bị và nghi thức Tượng Cổ đều qua.

Đã qua 41 nhóm scoring và 16 nhóm bổ sung về boss, tốc độ, SPN, kinh tế, đổi đồ, lưu tải và mobile. Chưa chạy lại mô phỏng toàn chiến dịch cho cấu hình mới; báo cáo cân bằng trước là dữ liệu lịch sử.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. APK **120,0 MiB**. VersionCode **14300**, cùng khóa ký. Mở `LUA-TCG-0.143.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật; chất âm cần nghe thêm trên loa/tai nghe thực tế. Chưa xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

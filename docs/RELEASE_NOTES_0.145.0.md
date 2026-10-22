# Terra Suit — beta 0.145.0 cho Android

- **Canh nhịp combat**: mỗi tay bài có thanh tấn công trước tính điểm; mỗi đòn địch có parry riêng, không áp dụng cho hành động hỗ trợ. Thanh nằm dưới hàng điều khiển, phân biệt đồng đỏ/xanh thép. Bấm Space, Enter, chuột trái hoặc chạm khi đặt ngón tay xuống; mỗi thanh nhận đúng một lần. Có thời gian đọc bố cục và hiển thị kết quả; không bấm vẫn tự tiếp tục.
- **Tấn công**: xanh ×1,35 sát thương; vàng ×2 và chắc trúng; ◆ ×2,6 và chắc trúng; ★ ×4 và chắc trúng. Vẫn tuân thủ luật chặn thế của boss. Đỏ ép đánh hụt, kể cả có buff chính xác; hết thời gian ×0,75 sát thương.
- **Parry**: xanh giảm 50% sát thương trước giáp; vàng/◆/★ chặn toàn bộ sát thương và hiệu ứng trúng đòn. ◆ tạo giáp bằng 25% đòn địch; ★ tạo 50% giáp và phản ×100 sát thương trước giáp về đúng kẻ tấn công, theo phòng thủ/hồi sinh hiện có. Đỏ nhận thêm 25% sát thương nếu trúng. Tuân thủ giới hạn giáp hiện có.
- Vị trí vùng, độ lệch và hướng chạy thay đổi mỗi lần, nhưng giữ nguyên sau khi thanh hiện. Tốc thanh theo chênh tốc thực tế, độc lập tốc độ game ×1/×2/×4 và Reduced Motion; pause/settings dừng thanh. Vùng thưởng lớn được đánh dấu rõ và có bẫy đỏ hai bên.
- **Âm thanh**: 16 cue riêng cho attack/parry và từng kết quả, dùng âm lượng SFX/mute/mixer/cache hiện có; bake sẵn, không tổng hợp lúc vào game.
- **Cân bằng địch**: nền HP ba trận đầu 80/160/240 trước nội tại/trang bị; sát thương nền 8/12/16 và tăng theo lần gặp. Tốc ban đầu 8–22, cận tăng theo tiến trình. Các buff, trang bị và quy tắc khu vực tiếp tục áp dụng.

Chi tiết và điều khiển: `docs/combat_timing.md`. Chưa chạy lại mô phỏng toàn chiến dịch cho cấu hình timing mới; báo cáo cân bằng trước là dữ liệu lịch sử.

Đã qua 42 nhóm scoring và 10 nhóm timing/cân bằng/lưu tải/mobile. Runtime kiểm tra attack/parry bằng phím/chạm, pause, ×4, các vùng thưởng/bẫy và phản đòn kết liễu. Audio decoder/mixer phát đủ 16 cue mới; gói mobile đọc 555 ID tranh, 974 file âm thanh. Chữ ký, CRC, checksum và toàn bộ Lua/shader nhúng khớp nguồn phát hành.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. APK **120,5 MiB**. VersionCode **14500**, cùng khóa ký. Mở `LUA-TCG-0.145.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Chưa xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

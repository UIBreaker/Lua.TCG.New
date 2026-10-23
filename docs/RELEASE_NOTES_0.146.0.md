# Terra Suit — beta 0.146.0 cho Android

- **Luật 52 quân bài mới**: bốn chất dùng chung chỉ số rank. A–K có sát thương 1–13 và tốc 13–1; A vẫn là rank 14 khi xét poker. Bỏ khả năng riêng cũ và thưởng vai trò J/Q/K/A; giữ tranh Continental và thế poker. ITM, SPN, thuốc, ấn bản tiếp tục áp dụng bổ trợ riêng.
- **Bỏ bài chủ động**: mỗi lá cho các lá cùng chất còn trên tay +1 Cường hóa đến khi rời tay. Cơ hồi % HP tối đa, Rô nhận vàng, Chuồn tăng tốc trong lượt đánh kế tiếp, Bích nhận giáp theo % HP tối đa. Giá trị tăng theo cấp, dừng ở cấp 10. Bỏ do boss ép, tiêu hủy và chơi bài không tạo hiệu ứng chủ động này.
- **Tiến hóa TT+**: sau TT vẫn tăng không giới hạn; mỗi bậc dư cộng vĩnh viễn +1 sát thương, +1 tốc, +1 Cường hóa gốc. Save cũ chuyển chỉ số nền theo luật mới, giữ phần nâng cấp/trang bị/tiến hóa; TT+ giữ qua sao chép và lưu/tải.
- **Phản hồi buff bỏ bài**: bảng kết quả cố định dưới THẾ TRẬN và nhãn theo từng lá, chuyển động nảy/rung ngắn; lượng hồi máu là lượng thực nhận, tốc ghi rõ một lượt. Lá rút mới không nhận nhãn cũ; Reduced Motion giữ phản hồi tĩnh.
- **Cực Hạn ✦**: vùng trắng rộng 1,5% giữa bẫy đỏ; tấn công ×8 và chắc trúng, parry phản ×250 sát thương trước giáp người chơi, giữ thưởng giáp của ★. Các luật phòng thủ/hồi sinh hiện có vẫn áp dụng.
- **Timing VFX/âm thanh**: dải sáng theo mốc dừng, lưỡi chém/mặt khiên/mảnh vỡ và luồng phản lực ngắn. HP hiển thị, số sát thương, giật lùi và tử vong địch chờ tiếp xúc phản lực; nhịp hồi tối thiểu theo thời gian thực để ×4 vẫn nhìn rõ. Có giới hạn số hiệu ứng và tự dọn, giảm trên mobile/Reduced Motion. Thêm hai cue Cực Hạn.
- Dùng chung mẫu khiên thép cho parry, giáp, thuốc, HUD và các biểu tượng liên quan; thêm điểm sáng trên menu.

Chi tiết: `docs/PLAYING_CARD_RULES.md`, `docs/combat_timing.md`. Chưa chạy lại mô phỏng toàn chiến dịch cho luật quân bài mới; báo cáo cân bằng trước là dữ liệu lịch sử.

Đã qua 42 nhóm scoring, 11 nhóm bổ sung, 11 ca poker và 6 nhóm advanced features (hai fixture CI này đã được đồng bộ với chỉ số/giá và kho balo hiện hành). Runtime timing/phản lực, buff bỏ bài nhiều độ phân giải, khiên và audio thật đều qua. Gói mobile đọc 555 ID tranh và 976 file âm thanh; chữ ký, CRC, checksum và mã Lua/shader nhúng đã xác minh.

Giới hạn CI cũ: suite tổng `--test` trong `test_system.lua` vẫn dùng nền 50 HP thay vì 80, reroll 2 thay vì 5 và các kỳ vọng cũ khác; không coi toàn bộ CI đã xanh. Các lỗi fixture này có trước bản phát hành và được tách khỏi các suite trực tiếp ở trên.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. APK **120,5 MiB**. VersionCode **14600**, cùng khóa ký. Mở `LUA-TCG-0.146.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Chưa xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

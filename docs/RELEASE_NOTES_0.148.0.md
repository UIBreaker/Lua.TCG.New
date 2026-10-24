# Terra Suit — beta 0.148.0 cho Android

- **Chuỗi canh nhịp**: mỗi mốc có chuỗi riêng, dùng chung giữa tấn công/parry và giữ qua trận/save trong cùng run. Trượt/nền tối/đỏ/cam/hết giờ xóa chuỗi. Chuỗi nhân sát thương, phản đòn và giáp thưởng; tím/trắng/Thần Tích thưởng 5 linh hồn + 5 vàng nhân chuỗi khi xử lý thành công, chống trả lặp.
- **Thưởng trắng/Thần Tích**: khóa hệ số lễ cao nhất trong trận ở ×2/×4/×6… cho vàng lễ, lượt chiến lợi phẩm, vé Void và linh hồn hạ địch, giữ đồ độc nhất. Thần Tích chuỗi N tiến hóa N cấp cho từng SPN vật lý đang sở hữu và lá còn trên tay; đồng bộ lá gốc và bản sao cùng ID.
- **Sáu mốc chiến thuật**: Hấp huyết hồi HP, Xuyên phá bỏ qua giáp thường, Tiếp nhịp tăng tốc các lá hợp lệ còn trên tay; parry Hồi sức, Tiếp tế và Đỡ phản giảm 75% sát thương rồi thưởng nếu sống sót. Mỗi thanh chọn hai mốc phù hợp, có chú giải, màu/hình và chuỗi riêng.
- **Nhịp timing mới**: thanh dài hơn, ba kiểu nhịp báo trước, tốc độ chịu áp lực chuỗi; vùng thưởng hẹp hơn và vị trí cố định trong lần canh nhịp. Vùng cam khi đánh bị địch chặn/phản 100% sát thương tay bài; khi parry nhận đòn chắc trúng ×5 trước giáp. Có phản hồi riêng, hỗ trợ giảm chuyển động.
- **Bài bị vô hiệu**: không thể đánh, tạo thế poker, kích hoạt SPN/trang bị hoặc điều kiện cầm bài. Vẫn chọn bỏ được; chọn lẫn thì chỉ đánh lá hợp lệ. Preview, tính điểm và hàng đợi kỹ năng dùng cùng luật; hết khóa thì hoạt động lại.
- **Giao diện**: tinh chỉnh khung kim loại vẽ bằng mã, mặt cắt đá và chi tiết các bậc; renderer hiện tại không dùng asset khung kim hoàn thử nghiệm. Hiệu ứng tiến hóa/tăng tốc dùng chung, không ghi vào save; giữ Reduced Motion. Cải thiện gom bài và thứ tự lớp/hover/dùng SPN, tiêu hao theo ô trang bị.
- **Âm thanh**: phối lại SFX bàn bài gần, trầm, khô và nhỏ hơn; làm mềm dải cao, giảm vang và chồng tiếng tính điểm/tiền. Giữ nhạc/file nền, slider và thiết lập đã lưu; giảm gain mặc định và ducking, giữ giới hạn voice/source pool/cache mobile 16 MiB. Lọc/phối âm khi dựng tài nguyên, không xử lý lọc mỗi frame.

Chi tiết: [timing](combat_timing.md), [hiệu ứng nâng cấp](progression_effects.md), [khung/chuyển động](card_motion.md), [âm thanh](audio/README.md).

Đã qua 42 nhóm scoring và 14 nhóm bổ sung. Runtime chuỗi, vùng nguy hiểm, bài bị vô hiệu, gom bài thắng trận, khung bài, hiệu ứng nâng cấp và sáu mẫu chiến thuật đều đạt. Hai fixture runtime được sửa để chờ hoàn tất chuyển cảnh/chia bài trước khi thao tác. Audio thật và đo phổ 958 SFX đạt; kiểm tra gói đọc 555 ID tranh, 978 file âm thanh. CRC, ghép ba phần APK, checksum, chữ ký cũ và toàn bộ Lua/shader nhúng đã xác minh.

APK **136,4 MiB**, SHA-256: `006a6969d42183c3a4e4bb39ac7bcd9915792a09e23885a2d1794b322e1ac384`.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. VersionCode **14800**, cùng khóa ký. Tải `LUA-TCG-0.148.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. CI tổng cũ trong `test_system.lua` còn các kỳ vọng HP/giá từ luật cũ; không coi toàn bộ CI đã xanh. Chưa xác nhận sửa lỗi cài APK từng báo trên thiết bị ở bản 0.136.0.

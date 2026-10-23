# Terra Suit — beta 0.147.0 cho Android

- **Bàn Ký Ức**: sự kiện có 25% cơ hội sau boss ải lẻ, ngoài Huyết Vực, sau chuỗi shop. Phí 50 vàng, 18 lá úp / 9 cặp, 24 lượt lật. Tìm cặp để nhận bài; chuỗi ghép đúng cuối nhân toàn bộ phần thưởng tối đa ×4. Có thể nhận sớm sau khi so cặp. Lưu/tải không thu phí hoặc phát thưởng lặp.
- **Trạm Nghỉ Huấn Luyện**: cơ hội 25% sau boss ải lẻ, ngoài Huyết Vực; chọn một nhánh miễn phí. Nghỉ tăng vĩnh viễn 10 HP tối đa rồi hồi 65% HP tối đa mới. Huấn luyện 1–3 lá khác nhau: mỗi lá nhận ngẫu nhiên +5 sát thương, tốc hoặc Cường hóa vĩnh viễn. Có chọn bài nhiều trang và kết quả riêng từng lá, giữ qua save.
- **Xào lại và suy yếu**: hết lượt đánh, xử lý phản ứng địch rồi gom tay/bộ rút/chồng bỏ để chia lại; hồi lượt đánh/bỏ theo giới hạn thực tế. Mỗi lần xào cộng −1 sát thương, −1 tốc, −1 Cường hóa trên toàn bộ bài chiến đấu, từng chỉ số tối thiểu 0. Thuốc tính trước suy yếu. Chỉ số gốc giữ nguyên; trận mới xóa suy yếu. Bài tiêu hủy không hồi sinh. Có nhãn SUY YẾU và hiệu ứng gom/chia bài, hỗ trợ giảm chuyển động.
- **Thần Tích ♦**: vùng hồng ngọc rộng 0,8% giữa bẫy đỏ; đánh ×12 và chắc trúng, parry chặn toàn bộ và phản ×500 sát thương trước giáp, tạo giáp như mốc tím. Có VFX và hai cue âm thanh riêng.
- **Linh hồn timing**: đánh trúng/parry thành công ở mốc tím thưởng ngẫu nhiên 1–5 LH, trắng +2 LH, Thần Tích +3 LH. Trả khi xử lý đòn thực tế, chống nhận lặp; hụt/né hoặc bỏ qua đòn không thưởng.
- Giản lược chuyển động hover của lá địch; giữ hoạt cảnh đứng và phản hồi đòn đánh.

Quy tắc: [Bàn Ký Ức](MEMORY_MATCH.md), [Trạm Nghỉ Huấn Luyện](TRAINING_CAMP.md), [xào bài](combat_reshuffle.md), [timing](combat_timing.md).

Đã qua 42 nhóm scoring và 11 nhóm bổ sung. Runtime giao diện Bàn Ký Ức/Trạm Nghỉ, tự xào suy yếu và Thần Tích đều đạt; audio, tách/ghép gói, CRC, checksum và chữ ký đã xác minh. Gói mobile đọc đủ 555 ID tranh và 978 file âm thanh; toàn bộ Lua/shader nhúng khớp mã nguồn. APK **120,9 MiB**, SHA-256: `41b340a3b5bc582e1f214afa892ae14320473c51942040131bdcc2f5fdb721f9`.

Android 6+, ARM64/ARMv7, khóa ngang/tràn màn hình. VersionCode **14700**, dùng cùng khóa ký. Tải `LUA-TCG-0.147.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Suite CI tổng cũ trong `test_system.lua` còn kỳ vọng HP/giá từ luật cũ; không coi toàn bộ CI đã xanh. Chưa xác nhận sửa lỗi cài APK trên thiết bị từng báo lỗi ở bản 0.136.0.

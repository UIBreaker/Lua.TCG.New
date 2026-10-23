# Xào lại và suy yếu trong trận

Khi dùng hết lượt đánh, game xử lý xong phản ứng của địch rồi tự gom toàn bộ bài trên tay, bộ rút và chồng bỏ để xào và chia đủ tay mới. Lượt đánh và lượt bỏ được hồi về giới hạn thực tế của trận, bao gồm thay đổi từ SPN, phe và boss.

Mỗi lần xào cộng một mức suy yếu cho mọi lá của bộ bài chiến đấu: **−1 tốc đánh, −1 sát thương và −1 cường hóa**, cộng dồn, từng chỉ số tối thiểu 0. Thưởng chỉ số từ thuốc được tính trước khi trừ suy yếu và chặn về 0. Hiệu ứng/khả năng ghi điểm riêng vẫn hoạt động theo luật của chúng.

Lựa chọn trên tay cũ được xóa để không tự đánh nhầm sau khi xào. Một lượt đã hồi không thể bị xử lý xào lần hai. Bài đã tiêu hủy không hồi sinh và cùng một lá không xuất hiện hai lần trong bộ rút. Trận đã thắng hoặc người chơi đã chết không tự xào tiếp.

Mức suy yếu chỉ ghi trên bản sao chiến đấu; chỉ số gốc, nâng cấp, tốc cộng vĩnh viễn và cường hóa huấn luyện của bộ bài chính được giữ nguyên. Bắt đầu trận mới xóa mức suy yếu. Dữ liệu xào không được đưa vào save dài hạn. Boss Kim Nhọn vẫn giới hạn một tay đánh mỗi lượt, nhưng hết tay sẽ xào và suy yếu thay vì tự thua chỉ vì hết lượt.

Hiệu ứng dùng chuyển động gom bài/chia bài hiện có. Sau khi chia xong, các con số giảm xuất hiện trên từng lá, kèm mảnh sáng đỏ đồng rơi xuống và một nhịp hạ nhẹ của lá bài. Nhãn **SUY YẾU −N** giữ trên lá để chỉ rõ mức cộng dồn. Không có vòng sáng hoặc các bản sao chồng trên lá. Chế độ giảm chuyển động bỏ nhịp hạ và các mảnh bay.

Kiểm tra:

- `lovec.exe . --test-combat-fatigue`: gom các chồng bài, giới hạn lượt, giảm ba chỉ số về 0, scoring/preview, nâng cấp gốc, save và reset trận mới; VFX độc lập RNG ở 30/60/144 FPS.
- `lovec.exe . --capture-combat-timing --fatigue`: lượt đánh cuối tự xào, lượt bỏ hồi đầy, xào lần hai thành −2, xóa lựa chọn cũ và hồi chỉ số ở trận kế.
- `lovec.exe . --test-play-turn-continuation`: chuột/phím/nút cũ khi hết lượt và luật ra đòn trước/sau.

Ảnh trong game: [lần xào thứ nhất](combat_reshuffle_fatigue_1.png), [lần xào thứ hai](combat_reshuffle_fatigue_2.png).

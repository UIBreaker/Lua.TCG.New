# Combat: chính xác và hành động hỗ trợ

- Tốc bạn là tốc đánh trung bình của toàn bộ lá đã chơi, gồm trang bị và thưởng tốc. Tốc địch gồm buff đang có.
- Chính xác: `clamp(tốc người đánh / tốc mục tiêu, 5%, 100%)`. Nhanh bằng hoặc hơn mục tiêu: trúng 100%. Tốc 5 đánh tốc 10: 50%; tốc 9 đánh tốc 10: 90%. Bạn tốc 27, địch tốc 1: bạn trúng 100%, địch trúng 5%. Áp dụng đối xứng cho cả hai phía, gồm buff tốc đang có.
- Đòn hụt gây 0 sát thương, không tiêu hao giáp/giường, không kích hoạt hiệu ứng khi đánh trúng, độc, hút máu hoặc sát thương lan của đòn đó. Các thưởng từ thế bài như giáp, vàng, hồi máu vẫn nhận được; sét của Ba Cột không gây sát thương khi hụt. Sát thương hiệu ứng độc và sát thương chuẩn độc lập không phải đòn đánh thường.
- Địch luân phiên tấn công và hỗ trợ. Khi hỗ trợ, ưu tiên hồi máu cho thành viên còn sống có tỉ lệ HP thấp nhất nếu còn tối đa 65% HP, gồm cả bản thân. Nếu không cần hồi máu thì luân phiên giáp, tốc, sát thương; luân phiên tự buff và hỗ trợ đồng đội. Địch một mình tự buff. Khi giáp/tốc đã đạt giới hạn, chuyển sang buff sát thương.
- Buff tính trực tiếp từ **chỉ số của địch nhận buff**, gồm tự buff và buff đồng đội. Không có lượng cộng cố định theo ải; chỉ số tăng thì buff tăng theo:
  - Giáp: 25% HP tối đa. Tổng giáp tối đa 50% HP tối đa, bị tiêu hao khi chịu sát thương.
  - Hồi máu: 20% HP tối đa, giới hạn theo HP còn thiếu, không hồi sinh đồng đội đã chết.
  - Tốc: 25% tốc đánh hiện tại lúc nhận buff mới; tổng tốc không vượt 999.
  - Sát thương: 25% chỉ số tấn công hiện tại lúc nhận buff mới.
- Làm tròn xuống, lượng buff tối thiểu 1 (trừ tăng tốc khi đã đạt 999). Ví dụ địch có 1.000.000 HP tối đa: thêm 250.000 Giáp, đủ hấp thụ một đòn 200.000 AURA, hoặc hồi 200.000 HP. Địch tốc 100 nhận +25 Tốc; tấn công 2.000 nhận +500 ST.
- Tăng tốc / sát thương khi đang có buff cùng loại chỉ gia hạn lượng buff đã nhận, không lấy buff đó tự nhân tiếp. Khi buff hết hạn, lần thi triển mới tính lại theo chỉ số hiện tại, bao gồm thay đổi tấn công do cuồng nộ hoặc tăng trưởng sau đòn đánh.
- Buff tốc / sát thương kéo dài 2 hành động tiếp theo của người nhận. Buff cùng loại làm mới thời hạn, không cộng dồn. Hành động bị khóa/ngủ cũng tiêu thụ thời hạn buff.
- Hỗ trợ thay thế lượt đánh, không gây sát thương lên người chơi và không thể đánh hụt. Hiệu ứng hỗ trợ chỉ áp dụng khi đến nhịp tiếp xúc, sau thời gian chuẩn bị.
- Chốt thứ tự nhanh/chậm ở đầu mỗi tay: mỗi địch sống chỉ hành động một lần, kể cả buff tốc tăng/hết hạn giữa tay. Buff vẫn tác động ngay lên chính xác và sát thương.
- HUD mỗi địch hiện chỉ số sau buff, loại chiêu và người nhận; bảng mục tiêu hiện ý định chi tiết và tỉ lệ trúng của hai phía khi chọn bài. Hụt hiện thông báo riêng, không rung/kick/hit flash của đòn trúng.
- Địch có kho đồ riêng theo ải/vai trò, gồm trang bị phần trăm, ấn bản, dấu và SPN. Đồ dự trữ phải tốn một hành động đã báo trước để dùng/đổi. Xem [quy tắc kho đồ địch](ENEMY_LOADOUTS.md); buff cơ bản bên trên được tăng hiệu lực khi người thi triển có Tàn Hỏa.

Kiểm tra logic: `lovec.exe . --test-combat-tactics`.
Kiểm tra game/UI, xuất ảnh `docs/combat_tactics_*.png`: `lovec.exe . --capture-combat-tactics` (chế độ capture cách ly save người chơi).

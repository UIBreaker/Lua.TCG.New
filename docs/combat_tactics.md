# Combat: chính xác và hành động hỗ trợ

- Tốc bạn là tốc đánh trung bình của toàn bộ lá đã chơi, gồm trang bị và thưởng tốc. Tốc địch gồm buff đang có.
- Chính xác: `clamp(tốc người đánh / tốc mục tiêu, 5%, 100%)`. Nhanh bằng hoặc hơn mục tiêu: trúng 100%. Tốc 5 đánh tốc 10: 50%; tốc 9 đánh tốc 10: 90%. Bạn tốc 27, địch tốc 1: bạn trúng 100%, địch trúng 5%. Áp dụng đối xứng cho cả hai phía, gồm buff tốc đang có.
- Đòn hụt gây 0 sát thương, không tiêu hao giáp/giường, không kích hoạt hiệu ứng khi đánh trúng, độc, hút máu hoặc sát thương lan của đòn đó. Các thưởng từ thế bài như giáp, vàng, hồi máu vẫn nhận được; sét của Ba Cột không gây sát thương khi hụt. Sát thương hiệu ứng độc và sát thương chuẩn độc lập không phải đòn đánh thường.
- Địch xen kẽ tấn công và hỗ trợ. AI có kho đồ chọn hỗ trợ theo HP, giáp, tốc/chính xác và sát thương thực tế thay vì xoay vòng cứng; ưu tiên cứu người ≤65% HP, buff sát thương cho chủ lực và buff tốc khi cải thiện chính xác/thứ tự ra đòn. Đồng đội ≤35% HP được ưu tiên cứu trước khi chuẩn bị tiêu hao tấn công. Không làm mới buff còn hiệu lực, không hỗ trợ vào giáp/tốc đã chạm trần. Khi đủ sát thương và chính xác ≥80%, ưu tiên đòn kết liễu người chơi thay vì chuẩn bị đồ.
- Buff tính trực tiếp từ **chỉ số của địch nhận buff**, gồm tự buff và buff đồng đội. Không có lượng cộng cố định theo ải; chỉ số tăng thì buff tăng theo:
  - Giáp: 25% HP tối đa. Tổng giáp tối đa 50% HP tối đa, bị tiêu hao khi chịu sát thương.
  - Hồi máu: 20% HP tối đa, giới hạn theo HP còn thiếu, không hồi sinh đồng đội đã chết.
  - Tốc: 25% tốc đánh hiện tại lúc nhận buff mới; tổng tốc không vượt 999.
  - Sát thương: 25% chỉ số tấn công hiện tại lúc nhận buff mới.
- Làm tròn xuống, lượng buff tối thiểu 1 (trừ tăng tốc khi đã đạt 999). Ví dụ địch có 1.000.000 HP tối đa: thêm 250.000 Giáp, đủ hấp thụ một đòn 200.000 AURA, hoặc hồi 200.000 HP. Địch tốc 100 nhận +25 Tốc; tấn công 2.000 nhận +500 ST.
- Tăng tốc / sát thương khi đang có buff cùng loại chỉ gia hạn lượng buff đã nhận, không lấy buff đó tự nhân tiếp. Khi buff hết hạn, lần thi triển mới tính lại theo chỉ số hiện tại, bao gồm thay đổi tấn công do cuồng nộ hoặc tăng trưởng sau đòn đánh.
- Buff tốc / sát thương kéo dài 2 hành động tiếp theo của người nhận. Buff cùng loại làm mới thời hạn, không cộng dồn. Hành động bị khóa/ngủ cũng tiêu thụ thời hạn buff.
- Mỗi trận, địch thường dùng tối đa **1 lần mỗi loại** hồi máu / giáp / tốc / sát thương. Tinh anh: **2 / 2 / 1 / 1**; Boss: **2 / 2 / 2 / 2**. Hết lượt hỗ trợ thì tiếp tục tấn công. Hai lần hồi máu cần cách nhau ít nhất hai hành động thực sự; ngủ/khóa hành động không làm giảm thời gian chờ này.
- Sau hỗ trợ, uống thuốc hoặc đổi trang bị, hành động thực sự tiếp theo bắt buộc là tấn công (kể cả đánh hụt). Không nối hồi máu, thuốc và đổi đồ thành chuỗi đứng yên.
- Mỗi mục tiêu có dự trữ chung cho mọi nguồn hồi lặp lại: thường **35%**, tinh anh **50%**, Boss **60%** HP tối đa đầu trận sau trang bị. Kỹ năng, thuốc, hút máu, trang bị, SPN và hồi máu của Boss đều trừ vào cùng dự trữ; đồng đội chữa trị cũng không vượt nó. Chỉ trừ lượng thực hồi, không trừ phần dư khi đầy máu.
- Giáp được tạo thêm trong toàn trận cũng hữu hạn: thường **50%**, tinh anh **75%**, Boss **100%** HP tối đa đầu trận. Mọi kỹ năng, dấu/SPN, đổi đồ và tái tạo giáp dùng chung dự trữ này; lượng giáp đang có vẫn tối đa 50% HP tối đa. Giáp ban đầu không tiêu dự trữ. Phá giáp không nạp lại dự trữ.
- Các giới hạn chỉ làm mới khi bắt đầu trận mới, không làm mới khi đổi tay, xem ý định, đổi mục tiêu, hết thời hạn buff hoặc thay trang bị. Giường và Tái Kết Xương giữ cơ chế cứu mạng một lần vốn có, độc lập với hồi máu lặp lại.
- Hỗ trợ thay thế lượt đánh, không gây sát thương lên người chơi và không thể đánh hụt. Hiệu ứng hỗ trợ chỉ áp dụng khi đến nhịp tiếp xúc, sau thời gian chuẩn bị.
- Chốt thứ tự nhanh/chậm ở đầu mỗi tay: mỗi địch sống chỉ hành động một lần, kể cả buff tốc tăng/hết hạn giữa tay. Buff vẫn tác động ngay lên chính xác và sát thương.
- HUD mỗi địch hiện chỉ số sau buff, loại chiêu và người nhận; bảng mục tiêu hiện ý định chi tiết và tỉ lệ trúng của hai phía khi chọn bài. Hụt hiện thông báo riêng, không rung/kick/hit flash của đòn trúng.
- Địch có kho đồ riêng theo ải/vai trò, gồm trang bị phần trăm, ấn bản, dấu và SPN. Đồ dự trữ phải tốn một hành động đã báo trước để dùng/đổi. Xem [quy tắc kho đồ địch](ENEMY_LOADOUTS.md); buff cơ bản bên trên được tăng hiệu lực khi người thi triển có Tàn Hỏa.

Kiểm tra logic: `lovec.exe . --test-combat-tactics`.

Khi hết lượt đánh nhưng còn bài trên tay, chọn bài làm nút chính hiện **ĐÁNH LƯỢT KẾ**. Nhấn nút hoặc Space sẽ kết thúc lượt hiện tại, giữ đúng các lá đã chọn rồi tự đánh ở lượt mới; địch và bạn vẫn phân xử theo tốc đánh. Bảng tốc hiển thị **CHUYỂN LƯỢT · ĐỊCH ĐI** trong bước kết thúc lượt, tránh báo sai bạn đánh trước chỉ vì tốc cao hơn. Nếu chưa chọn lá nào, **KẾT THÚC LƯỢT** chỉ chuyển lượt. Không tiếp tục lệnh đánh nếu nhân vật đã chết; giới hạn lượt cuối của Xuyên Tâm vẫn giữ nguyên. Trước bản sửa, nút kết thúc lượt luôn xóa lựa chọn và chỉ cho địch hành động, khiến thao tác chọn rồi Đánh trông như mất đòn.

Kiểm tra thao tác thật (cách ly save): `lovec.exe . --test-play-turn-continuation`. Đã tái hiện lỗi trước sửa: chọn khi hết lượt rồi click nút khiến số lần phân xử đòn người chơi bằng 0. Kiểm thử hồi quy gồm chuột/Space, chọn rồi bấm nhanh trước khi nút vẽ lại, nhiều lá, nhanh/chậm/bằng tốc, bấm lặp trong hoạt ảnh, kết thúc lượt không chọn bài và hủy lệnh khi chết.
Kiểm tra game/UI, xuất ảnh `docs/combat_tactics_*.png`: `lovec.exe . --capture-combat-tactics` (chế độ capture cách ly save người chơi).

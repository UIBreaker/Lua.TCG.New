# Rà soát tính điểm, trang bị và SPN — 09/10/2026

Đã sửa các lỗi xác nhận bằng ca tái hiện. Phạm vi bao gồm 87 định nghĩa trang bị, 48 SPN, kỹ năng 52 quân bài, con dấu, cường hóa, ấn bản và các điểm nối với chiến đấu/lưu game.

| Lỗi đã xác nhận | Khắc phục |
| --- | --- |
| ST nâng vĩnh viễn bị cộng hai lần: lá có 4 ST +20 nâng cấp nhận 44 thay vì 24. | Dùng `baseChips` đã chứa nâng cấp; chỉ dựng lại từ rank khi trường này vắng mặt. |
| Nội tại Quân Lực phe Bích cũ áp dụng cả cho bộ Continental đã tắt nội tại phe. Ví dụ 4/5/6 nhận 45 ST thay vì 25 gồm ST thế bài. | Chỉ chạy nội tại khi có lá Bích còn sử dụng nội tại cũ. |
| Xem trước bỏ sót lá còn giữ trên tay, làm sai Ống Tên Dự Trữ, Bát Dưỡng Sinh và các hiệu ứng tương tự. | Cung cấp tay còn giữ sau khi loại toàn bộ lá đã chơi. |
| Xem trước không chạy kỹ năng quân bài/di vật: Gương Song Vọng từng báo 44 trong khi đánh thật ra 76 ở ca kiểm tra. | Dùng luồng kỹ năng và hàng đợi tái kích hoạt thật trên bản sao trận đấu. Không tự chấp thuận các lựa chọn trả chi phí. |
| Chỉ chọn bài có thể thiêu hủy lá, trừ HP quái, tiết lộ ý định, gắn cờ Ấn Neo/Ấn Huyết, xả tích điện, tăng Cuồng Nộ hoặc tiêu RNG. | Cô lập toàn bộ dữ liệu xem trước và phục hồi trạng thái RNG, kể cả khi tính toán lỗi. |
| Xem trước SPN dùng Giáp/Vàng trước khi trang bị chuyển đổi đã tiêu chúng. | Trang bị và SPN đọc cùng ngân sách tài nguyên của bản tính hiện tại. |
| SPN kích hoạt theo lá và phù phép vẫn chạy ở ô bị boss khóa nếu không có `abilityHand` đang hoạt động. | Kiểm tra khóa ô từ trạng thái game, độc lập với hàng đợi kỹ năng. |
| Hệ số nhân của SPN đã nằm trong `totalMult` nhưng lại xuất hiện trong hệ số nhân cuối, khiến HUD/công thức bị hiểu thành nhân hai lần. | Hệ số cuối chỉ chứa hệ số lá/trang bị; SPN giữ đúng thứ tự nhân tại từng ô. |
| Trường `bonusMult` bỏ sót phần Cường hóa từ SPN. | Trả phần chênh lệch giữa Cường hóa cuối và Cường hóa gốc. |
| Gương Dị Chất/Mắt Đồng Chất phát thưởng từ lá kiệt sức/bị khóa; gương còn cộng ST cho mục tiêu kiệt sức. | Loại cả nguồn và mục tiêu không thể tính điểm khỏi thưởng trang bị trước tay. |
| Ấn Huyết không ghi vào cờ trận được tạo bởi `Combat.start`, nên có thể dùng lại ở tay sau; lần phụ còn lặp SPN và ấn bản. | Ghi giới hạn vào trận; lần phụ chỉ cộng ST cơ bản và trả đúng 3 HP. |
| Di vật có tác dụng nhưng thiếu chỉ số hốc để sáng hốc; Bút Ký im lặng khi không đủ điều kiện và có thể chọn đồng đội kiệt sức. | Gắn phản hồi đúng hốc; Bút Ký bỏ qua mục tiêu kiệt sức/đạt trần và báo rõ thiếu mục tiêu hoặc đã dùng. |

## Bút Ký Khởi Nguyên trong ảnh

Bút Ký cần một **đồng đội khác cùng nằm trong vùng tính điểm**, chưa đạt trần tiến hóa. Đánh Đơn Thủ thường chỉ có một lá tính điểm, nên các lá đã chơi nhưng không tính điểm không phải mục tiêu hợp lệ. Không có mục tiêu thì không tiêu lượt dùng. Đã kiểm tra chọn đúng đồng đội ít tiến hóa nhất, +1 cấp vĩnh viễn, đồng bộ bản gốc, lưu/tải lại và chỉ dùng thành công một lần mỗi trận. Nay có phản hồi rõ lý do chưa kích hoạt.

Trang bị có mô tả “khi tính điểm” cần chủ trang bị nằm trong vùng tính điểm. Trang bị tốc đánh cộng khi gắn; Đèn Tro Bất Diệt cần được giữ trên tay. Không quy mọi trường hợp không kích hoạt thành lỗi.

## Kiểm tra

- `../love-11.5-win64/lovec.exe tests/scoring_audit`: 17 bộ liên quan đều qua.
- Bộ mới `tests/scoring_runtime_smoke.lua`: 154 kiểm tra, gồm 19 ca ghép hệ thống và toàn bộ 87 trang bị/48 SPN ở 4 số lượng lá chơi (540 cấu hình). Đối chiếu ST, Cường hóa, Aura, Giáp, HP, chi phí và Vàng giữa xem trước/đánh thật; kiểm tra dữ liệu game và RNG không đổi khi xem trước.
- Bộ trang bị theo tầng: 10.800 tình huống điều kiện/tài nguyên; bộ Continental: 11.232 tình huống kỹ năng/tốc đánh/giới hạn.
- `--test-continental52-regressions`: qua các bộ mở rộng gameplay, toàn bộ 22 boss, SPN, tốc đánh, di vật, ấn bản và lưu nâng cấp.
- `--test-poker`: 11 kiểm tra qua. `--test-features`: 6 kiểm tra qua; đã cập nhật kỳ vọng cũ về 3 hốc và chỉ số trang bị sang cân bằng hiện tại.
- Benchmark LÖVE: khoảng 0,40 ms/lần xem trước trên máy này, 200 lần, bộ 52 lá mỗi lá 4 trang bị và 5 SPN. Đây là ca đo tổng hợp, không phải cam kết FPS của mọi trận.

## Giới hạn còn lại

Bộ tổng `--test` cũ dừng tại `test_system.lua:1347`: kỳ vọng Đá Thủ Thế cho 12 Giáp, trong khi định nghĩa hiện tại cho 7. Các phần sau điểm dừng của bộ này chưa được xác nhận bằng lần chạy đó; các bộ chuyên biệt bên trên đã chạy độc lập. Không đổi cân bằng gameplay để khớp kỳ vọng cũ.

Chưa chơi thủ công một chuyến đi dài. Số xem trước tính từ trạng thái hiện tại và các quyết định đã có; đòn quái đi trước hoặc quyết định trả chi phí sau đó có thể thay đổi trạng thái trước khi đánh thật. Rà soát và các ca tự động không chứng minh mọi tổ hợp có thể xảy ra đều không còn lỗi.

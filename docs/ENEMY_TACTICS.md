# AI và kho đồ địch

## Quyết định trong trận

- Ưu tiên đòn kết liễu có độ chính xác cao và nhịp Vọng Âm đã sẵn sàng.
- Bỏ lịch đánh/buff theo lượt chẵn lẻ đối với địch có kho đồ. So sánh hỗ trợ với vật phẩm dự trữ; không phí đòn đánh cho buff sát thương bản thân có lợi quá thấp.
- Tính hiệu quả buff theo tốc, xác suất trúng và sát thương của từng đồng đội. Ưu tiên tăng tốc nếu vượt được tốc người chơi. Trước đòn đầu, dùng tốc lá nhanh nhất đang cầm để ước lượng; sau đó dùng tốc tay vừa đánh.
- Các thành viên đứng sau tránh lặp cùng loại hỗ trợ vào mục tiêu đã được thành viên trước báo buff. Không cộng dồn buff đang có.
- Thuốc máu và thuốc giáp dùng được cho đồng đội; hiệu lực dựa trên HP tối đa của người nhận. Thuốc chính xác được ưu tiên khi chênh tốc lớn, chỉ bảo đảm một lần đánh và vẫn bị thuốc né chặn.
- Ghi nhớ Aura của đòn người chơi đã tung trong trận. Không chọn hồi máu/giáp nếu lượng đó vẫn không đủ sống qua đòn đã thấy. Không dự đoán kết quả chấm điểm của tay tiếp theo; trí nhớ xóa khi bắt đầu trận khác.
- Chọn thuốc, trang bị dự trữ hoặc SPN dự trữ theo độ hữu ích; chỉ đổi trang bị phòng ngự nếu còn dự trữ giáp. Đổi trang bị giữ hệ số HP riêng của boss và không hồi HP miễn phí.

Ý định được báo trước. Vật phẩm/kỹ năng chỉ thực thi ở nhịp tiếp xúc, không đổi ngầm thành đòn đánh nếu vật phẩm không còn. Sau một hành động hỗ trợ, địch phải thử tấn công trước khi hỗ trợ tiếp; ngủ không làm mất vật phẩm.

## Tăng trưởng kho đồ

Ngân sách dựa trên độ khó ải hiện có, không đọc Aura hoặc trang bị người chơi để tự tăng chỉ số.

| Loại | Ngân sách ải 1 → 20 | Ô trang bị | Tiêu hao tối đa |
| --- | --- | --- | --- |
| Thường | 1 → 13 | 1; lên 2 ở ải 8, 3 ở ải 15 | 1; lên 2 từ ải 12 |
| Tinh anh | 4 → 16 | 2; lên 3 từ ải 12 | 3 |
| Boss | 6 → 24 | 3 | 4 |

Đồ vẫn phải mua trong ngân sách, nên không phải đối thủ nào cũng lấp mọi ô. Ưu tiên bộ trang bị theo vai trò trước khi thêm dấu, SPN và đồ dự trữ. Ấn bản bắt đầu ở ải 5, Holographic từ 12, Polychrome từ 20; chỉ khuếch đại món mang ấn bản.

SPN đang dùng xuất hiện ở boss từ ải 4, tinh anh từ 8, một phần quân thường từ 16. SPN dự trữ có thể xuất hiện ở tinh anh/boss từ 12, một phần quân thường từ 15. Tất cả phụ thuộc ngân sách; tạo kho đồ giữ ổn định và không tiêu RNG chiến đấu.

Trần cộng từ trang bị: HP +40%, sát thương +80%, tốc +60%, giáp đầu trận bằng 30% HP tối đa, hồi sau hỗ trợ 8% HP tối đa. Đây là trần tổng, không phải mức mặc định cho mọi địch. Các nội tại riêng của boss tính riêng.

Dự trữ hồi/tạo giáp, số lần dùng kỹ năng, thời hạn buff và trần tốc chung giữ nguyên. Không thêm bất tử, giới hạn sát thương nhận hay chống oneshot. Màn kho đồ tự co hàng dự trữ khi có sáu món.

## Kiểm chứng

- `--test-enemy-loadouts`: 240 cuộc chạm trán và 240 kho đồ AI; ngân sách/trần chỉ số, đủ loại vật phẩm, ưu tiên kết liễu/cứu đồng đội/tốc, phối hợp buff, trí nhớ sát thương, đổi đồ, lưu/tải và hạ địch một đòn khi sát thương vượt HP cộng giáp ở ải 20.
- `--test-combat-tactics`: chính xác hai phía, dự trữ hữu hạn, đội hình, thứ tự và nhịp tiếp xúc; tình huống 7 sát thương đầu game kết thúc trong 6 lượt.
- `--test-human-bosses`: đầy đủ mười boss và thay đổi vĩnh viễn.

Đã chạy 720 lượt chiến dịch có kiểm soát và 63.484 trận: xem `docs/CAMPAIGN_BALANCE_REPORT.md` để đọc số liệu, thay đổi HP/boss và giới hạn của mô hình. Trí nhớ sát thương chỉ là ước lượng từ đòn trước, có thể sai khi người chơi thay build, thế bài hoặc mục tiêu.

# Năm SPN thừa diệt và dự trữ

Tất cả là SPN Common trong shop, hỗ trợ tiến hóa, sao chép và tái kích hoạt như các lá hiện có.

| SPN | Cấp gốc | Tiến hóa 1 lần | Tiến hóa 2 lần |
|---|---|---|---|
| Tàn Linh Thừa Diệt | Mỗi SPN bị tiêu hủy: tích +0,5 hệ số Sát thương | Tích +0,75 | Tích +1 |
| Dư Lực Chưa Xả | +50 Sát thương mỗi lượt bỏ còn lại | +75 mỗi lượt | +100 mỗi lượt |
| Kim Trọng Hư Linh | Hệ số ST = 0,25 × Vàng | 0,375 × Vàng | 0,5 × Vàng |
| Linh Vực Khai Thủ | +1 kích thước tay | +2 kích thước tay | +3 kích thước tay |
| Độc Âm Vạn Ảnh | Chơi đúng 1 quân: thêm số lần kích hoạt bằng số quân cầm trước khi đánh | Gấp 2 số quân | Gấp 3 số quân |

Tàn Linh Thừa Diệt bắt đầu với ×1 Sát thương. Hai lần tiêu hủy ở cấp gốc đưa hệ số lên ×2. Tiến hóa chỉ tăng lượng tích cho sự kiện sau, không nhân lại phần đã tích. Lưu lượng tích trên chính SPN, giữ trong chuyến đi qua trận và lưu/tải. Hiến tế, Kén Kế Thừa nở và Máu ảo cạn đều là tiêu hủy thật; bán/cất/trao đổi không tính. Chỉ SPN trang bị và không bị khóa tại sự kiện được nhận; SPN đã bị tiêu hủy không tự nhận thưởng. Nếu hiến tế xảy ra trước ô Thừa Diệt trong cùng tay, hệ số mới có hiệu lực ngay tại ô đó; nếu xảy ra sau, phần tích mới chờ lần kích hoạt sau.

Dư Lực đọc lượt bỏ còn lại tại ô của nó: chi phí của SPN phía trước có thể giảm thưởng. Lá này không tiêu lượt bỏ.

Kim Trọng dùng đúng hệ số trực tiếp đã được người dùng chốt: 2 Vàng là ×0,5; 4 Vàng là ×1; 8 Vàng là ×2. Không có nền +1. 0 Vàng là ×0 trên trục Sát thương tại ô này; các phần Sát thương được cộng sau nó vẫn tuân theo thứ tự bình thường. Hệ số đọc số Vàng hiện có, không tiêu Vàng. Tiến hóa tăng hệ số mỗi Vàng; mô tả giữ đủ 3 chữ số thập phân cho các hệ số như 0,375.

Khai Thủ cộng sức chứa động, áp dụng cho rút đầu trận, rút bù, rút trong tay và bộ đếm giao diện. Không sửa kích thước gốc, nên tháo, bán hoặc khóa không để lại bonus. Khi sức chứa giảm, những quân đang cầm được giữ; không tự bỏ bài.

Độc Âm chỉ hoạt động khi toàn bộ tay đánh có đúng 1 quân, không phải chỉ có 1 quân ghi điểm. Chốt số quân cầm trước khi đánh, tính cả quân đã chọn; những lá rút thêm sau đó không làm tăng số lần. Cầm 4 quân và đánh 1 quân ở cấp gốc: 1 lần gốc +4 lần tái kích hoạt. Dùng hàng đợi tính điểm đầy đủ, gồm trang bị và SPN ghi điểm theo quân; không tạo thêm hàng đợi từ chính những lần lặp. Chung trần 128 lượt/tay với các nguồn khác và vẫn theo giới hạn, điều kiện của từng kỹ năng.

Kiểm tra: `tests/spn_reserves_smoke.lua`, `--test-spn-reserves-ui`, `--test-spn-reserves-art`, scoring audit và snapshot cho catalog 91 SPN.

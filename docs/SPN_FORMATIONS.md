# Năm SPN đội hình và sinh lực

Cả năm là SPN Common bán trong shop bình thường và đều tiến hóa được.

| SPN | Cấp gốc | Tiến hóa 1 lần | Tiến hóa 2 lần |
|---|---|---|---|
| Quân Lộ Sinh Linh | Đường Hành Quân: +50 ST, hồi 5% HP tối đa | +75 ST, hồi 7,5% | +100 ST, hồi 10% |
| Tiên Quân Hồi Trận | Đánh 5 quân: tổng lượt kích hoạt mỗi quân ghi điểm = giá trị quân đầu ×1 | Giá trị quân đầu ×2 | Giá trị quân đầu ×3 |
| Từ Tức Sinh Linh | Mỗi tay hồi 5% HP tối đa | Hồi 7,5% | Hồi 10% |
| Tứ Ảnh Chiến Phong | Đánh 4 quân: ×2 ST đóng góp riêng của từng quân ghi điểm | ×2,5 | ×3 |
| Tứ Trụ Đồng Tâm | Bốn quân cùng số: cùng chất ×4 ST, khác chất ×4 Cường hóa | ×5,5 cho nhánh tương ứng | ×7 cho nhánh tương ứng |

Quân Lộ xét đúng thế Đường Hành Quân đang tính điểm (`straight`), kể cả Sảnh 3 quân hợp lệ. Thùng phá sảnh hoặc thế nâng cao chứa Sảnh không tự tính là Đường Hành Quân.

Tiên Quân dùng đúng quân đầu theo thứ tự đánh, không lấy quân nhỏ nhất hay quân ghi điểm đầu tiên. A=1, J=11, Q=12, K=13. Ví dụ 2–3–4–5–6: mỗi quân ghi điểm tổng cộng 2 lần; 5–5–6–6–6: tổng cộng 5 lần. Đúng 5 quân đã chơi mới kích hoạt, gồm cả quân không ghi điểm trong điều kiện; chỉ các quân thuộc phần ghi điểm được tái kích hoạt. Không lặp điểm nền của thế, SPN theo tay, chi phí một tay hoặc hành động của địch. Tái kích hoạt là tính điểm đầy đủ cho quân, trang bị và SPN theo quân; không tạo vòng lặp từ những lượt lặp. Chung trần 128 lượt tính điểm/tay với những nguồn khác; nhiều nguồn cộng số lần thêm ngoài lượt gốc.

Từ Tức hồi một lần mỗi tay đánh, độc lập số quân hoặc số lần quân tái kích hoạt. Quân Lộ và Từ Tức tính theo máu tối đa của người chơi; không hồi Máu ảo và không vượt HP tối đa. Tiến hóa tăng tỷ lệ; sao chép/tái kích hoạt chính SPN có thể cộng thêm lượt hồi.

Tứ Ảnh xét đúng 4 quân đã chơi, gồm cả quân không ghi điểm trong điều kiện. Chỉ nhân phần đóng góp trên trục Sát thương của quân đang ghi điểm, sau thuốc, trang bị, SPN theo quân và ấn bản. Giữ nguyên Cường hóa, giáp, vàng, sát thương cố định AURA, điểm nền thế và SPN theo tay. Không nâng chỉ số quân vĩnh viễn. Các lần tính điểm lặp lại của quân cũng nhận hệ số; sao chép và Hồi Âm có thể nhân tiếp.

Tứ Trụ vẫn yêu cầu đúng 4 quân cùng số. Nếu cả bốn cùng chất thì chỉ nhân Sát thương; nếu không cùng chất thì chỉ nhân Cường hóa. Không cộng hai nhánh. Nhận các bí danh chất và hiệu ứng chất hoang theo quy tắc hiện có. Không yêu cầu game đang tính thế Tứ Quý nếu chưa mở khóa, vì điều kiện dựa trên bốn quân thực đã chơi.

Kiểm tra: `tests/spn_formations_smoke.lua`, `--test-spn-formations-ui`, `--test-spn-formations-art`, scoring audit, snapshot và kiểm tra trình bày tính điểm.

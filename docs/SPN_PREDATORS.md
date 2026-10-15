# SPN tiếng vọng, đoạt tốc và hiến tế

Ba SPN Common mua trong shop, có thể trang bị, cất và tiến hóa như các SPN khác.

| SPN | Cấp gốc | Tiến hóa lần 1 | Tiến hóa lần 2 |
|---|---|---|---|
| Hồi Âm Tả Cực | SPN ở ô có bài ngoài cùng bên trái kích hoạt thêm 2 lần | Thêm 3 lần | Thêm 4 lần |
| Đoạt Phong U Linh | Mỗi tay cướp tối đa 2 Tốc từ mục tiêu | Cướp 3 Tốc | Cướp 4 Tốc |
| Hữu Tế Tham Linh | Mỗi hiến tế tích +0,5 vào hệ số Cường hóa | Tích +0,75 | Tích +1 |

Hồi Âm dùng cấp và trạng thái của chính nguồn. Ví dụ nguồn có khả năng tích tầng sẽ tự tích ba lần ở cấp gốc. Nguồn vẫn trả chi phí và tuân thủ điều kiện riêng ở mỗi lần kích hoạt; các giới hạn một lần của nguồn được giữ. Nếu Hồi Âm nằm ngoài cùng bên trái thì không tự kích hoạt. Ô bị khóa không hoạt động; ô trống đầu hàng được bỏ qua khi xác định nguồn. Nhiều Hồi Âm cộng số lượt thêm, tổng tối đa 128 lần mỗi sự kiện; sao chép Hồi Âm không tạo vòng lặp.

Đoạt Phong cướp một lần mỗi tay trước khi xét thứ tự tấn công, từ mục tiêu đang chọn, giữ tốc địch tối thiểu 1. Mỗi quân đã chơi nhận đúng lượng thực cướp, gồm cả quân không ghi điểm. Tái kích hoạt quân không cướp thêm; tái kích hoạt chính SPN có thể cướp thêm. Tốc cộng dồn tạm trong trận.

**Cơ chế ẩn:** khi Đoạt Phong thực sự bị tiêu hủy trong trận, phần tốc nó từng cấp cho từng quân chuyển thành tốc vĩnh viễn của quân đó. Không cộng lại tổng tốc khi chuyển: phần tạm tương ứng bị gỡ. Nhiều lá và bản sao có sổ tốc riêng; bán, cất hoặc tiêu hủy ngoài trận không chuyển. Quân đã bị hủy không được phục hồi. Sổ tốc chưa chuyển không được lưu qua trận.

Hữu Tế tiêu hủy đúng SPN ngay bên phải mỗi tay ghi điểm; không nhảy qua ô trống, không ăn ô bị khóa. Mỗi nạn nhân tăng hệ số vĩnh viễn, dùng ngay tay hiện tại. Hệ số bắt đầu ×1, sau hai lần hiến tế cấp gốc là ×2. Khi không có nạn nhân, hệ số đã tích vẫn có hiệu lực. Tiến hóa chỉ tăng lượng nhận từ những lần hiến tế tiếp theo; tích lũy cũ được giữ nguyên và lưu trong chuyến đi. Nạn nhân bị xóa trước giai đoạn tính điểm SPN ở ô đó.

Vọng Linh Hữu Ảnh sở hữu phần tốc và tích lũy của bản sao riêng. Một bản sao Hữu Tế có thể hiến tế chính nguồn ngay bên phải nó. Hiến tế Đoạt Phong ngay trong tay nó vừa cướp tốc sẽ kích hoạt cơ chế ẩn.

Kiểm tra: `tests/spn_predators_smoke.lua`, `--test-spn-predators-ui`, `--test-spn-predators-art`, bộ snapshot và scoring audit.

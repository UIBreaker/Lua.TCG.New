# Mười ấn viễn chinh

Thông số được cập nhật theo yêu cầu người dùng ngày 13/10/2026. Giữ bộ 10 dấu đã tinh gọn từ 26 dấu; một lá có một ô dấu. Đóng dấu mới thay dấu cũ trên mọi bản sao trong trận và bộ bài vĩnh viễn.

| Dấu | Hiệu ứng cơ bản | Biểu tượng |
| --- | --- | --- |
| Huyết | Trang bị trên lá đã chơi tái kích hoạt thêm 2 lần, gồm cả lá không tính điểm. Tổng chi phí cả tay chỉ 3 HP dù có nhiều lá Huyết; dùng lại được ở tay sau | Giọt máu và vòng lặp |
| Neo | Mọi lá mang dấu luôn được chia vào tay mở đầu, kể cả khi số lá Neo vượt kích thước tay | Mỏ neo |
| Truy Nã | Tay kết liễu địch cuối cùng để thắng trận: +3 Vàng mỗi lá mang dấu đã đánh ra, kể cả lá không tính điểm; lá còn giữ không được thưởng | Đồng tiền có vương miện |
| Giáp | Mỗi lá mang dấu thật sự giữ lại trong tay cho Giáp bằng 10% HP tối đa của người chơi trong mỗi tay đánh | Khiên khắc nổi |
| Phá Giáp | Khi tính điểm: xóa toàn bộ Giáp của mục tiêu và thêm sát thương bằng 10% HP tối đa của mục tiêu | Khiên nứt |
| Hải Đăng | Khi tính điểm: +16 Cường hóa mỗi lá cùng chất còn giữ trên tay, không dùng điều kiện cùng rank và không còn trần ba lá | Hải đăng |
| Tứ Phương | Mỗi lá mang dấu còn giữ trên tay nhân đôi Cường hóa của tay đánh; nhiều lá nhân liên tiếp | La bàn bốn hướng |
| Thu Hồi | Bỏ mỗi lá mang dấu: +4 Vàng; không cần bỏ riêng, không trả Vàng và không giới hạn một lần mỗi trận | Mũi tên quay lại và đồng tiền |
| Đổi Lượt | Lần bỏ chỉ gồm các lá mang dấu không mất lượt bỏ, kể cả khi đang còn 0 lượt. Bỏ kèm lá khác vẫn tiêu một lượt | Bánh xe năm nan |
| Tam Nhịp | Mỗi lá mang dấu tính điểm tổng cộng 3 lần, gồm lần gốc và 2 lần thêm; hồi 3 HP mỗi lá. Không tích nhịp qua ba tay | Ba vạch nhịp |

## Phân biệt trạng thái của bài

Nhóm giữ tay loại bỏ **cả lá đã đánh ra tính điểm lẫn lá đã đánh ra không tính điểm**. Vì vậy, Giáp và Tứ Phương không kích hoạt trên các lá này; Hải Đăng chỉ đếm các lá cùng chất thật sự giữ lại. Chất dùng các alias Cơ/Rô/Chuồn/Bích và các phe tương ứng như cùng một chất.

Huyết tái kích hoạt trang bị, không lặp ST cơ bản/khả năng quân bài. Trang bị có thể kích hoạt tổng cộng ba lần; nếu không có trang bị thì không trả chi phí tái kích hoạt. Chi phí 3 HP được thu một lần cho cả tay. Tam Nhịp đưa hai lần tính điểm thêm vào cùng hàng đợi tính điểm thật như các nguồn tái kích hoạt khác; chỉ hồi 3 HP một lần cho mỗi lá gốc. Các giới hạn chung của trang bị, hàng đợi kích hoạt và Giáp toàn game vẫn áp dụng. Biến thể x5 của Chợ Máu giữ cơ chế tăng hiệu lực riêng, không tăng chi phí Huyết.

Truy Nã không thưởng ngay khi hạ một thành viên đội địch. Nó dùng tay đòn kết thúc toàn trận, cộng từng lá khác nhau và chống nhận thưởng lặp; cờ nhận thưởng được xóa ở trận kế tiếp.

## Save và hình ảnh

Tên hiển thị **Ấn Thanh Tẩy** đổi thành **Ấn Giáp**. Mã nội bộ `seal_purifying` được giữ để tương thích save và tranh Continental; hiệu ứng tẩy Boss cũ đã bỏ. `Deck.RETIRED_SEALS` vẫn chuyển 16 dấu đã loại sang nhóm hiện hành. Tiến hóa, ITM, tốc đánh và ST từ Nảy Mầm cũ vẫn giữ nguyên.

Biểu tượng nằm trong `ui/components/seal_emblems.lua`: kim loại vàng cổ, men tối theo vùng, nét lớn và hình riêng. Biểu tượng Ấn Giáp được đổi thành khiên; giữ chung biến đổi/vật liệu với metadata và khung lá bài. Không thêm khung hay chữ vào tranh Continental.

## Kiểm tra

- `love . --test-seals`: cả 10 quy tắc mới; phân biệt tính điểm/không tính điểm/giữ tay; nhiều dấu Huyết chỉ thu 3 HP; trang bị tái kích hoạt; Neo vượt kích thước tay; cộng thưởng Truy Nã và đường quyết toán thắng trận thật; đường bỏ bài thật miễn phí ở 0 lượt; preview thuần; chuyển save; hình riêng và độ trong suốt.
- `love . --test-chest-expansion`: dùng trực tiếp/cất tiêu hao, loader, rương và save.
- `love tests/scoring_audit`: 29 bộ kiểm tra tính điểm, ITM, SPN và trình bày hiệu ứng.

Ảnh từ renderer thật: `docs/seal_emblems_runtime.png`, bài ở kích thước 64 và 144 px. Chưa playtest trọn một lượt chơi dài để đo độ khó với thông số mới.

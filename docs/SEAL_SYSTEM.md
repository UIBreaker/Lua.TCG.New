# Mười ấn viễn chinh

Bộ con dấu được tinh gọn từ 26 xuống 10 ngày 12/10/2026. Mỗi lá có một ô dấu; đóng dấu mới thay dấu cũ trên mọi bản sao của lá trong trận và bộ bài vĩnh viễn.

| Dấu | Vai trò và hiệu ứng | Biểu tượng |
| --- | --- | --- |
| Huyết | Mỗi lá tái kích hoạt điểm cơ bản một lần mỗi trận, trả 3 HP nếu vẫn sống; không lặp ITM, hồi máu, Giáp hay Vàng | Giọt máu và vòng lặp |
| Neo | Ưu tiên lá chủ lực vào tay mở đầu; nhiều lá Neo vẫn chịu giới hạn kích thước tay | Mỏ neo |
| Truy Nã | Tay tính điểm có dấu kết liễu quái: +2 Vàng; nhiều dấu không nhân thưởng | Đồng tiền có vương miện |
| Thanh Tẩy | Giữ qua lượt quái: +4 Giáp mỗi lá, tối đa 12 mỗi lượt; tẩy nội tại Boss một lần mỗi trận | Khiên và sao thanh tẩy |
| Phá Giáp | Phá 8 Giáp trước Aura; mục tiêu đã hết Giáp thì nhận +12 ST thay thế | Khiên nứt |
| Hải Đăng | Mỗi lá cùng rank giữ lại: +16 ST, tối đa +48; phải chọn giữa đánh và giữ bộ cùng rank | Hải đăng |
| Tứ Phương | Các lá mang dấu ghi chung chất khi bị bỏ; đủ bốn chất, lần tính điểm kế tiếp +0.75 hệ số Aura rồi xóa ghi | La bàn bốn hướng |
| Thu Hồi | Bỏ riêng lá mang dấu: trả 2 Vàng để hoàn một lượt bỏ; toàn bộ dấu chung một lần mỗi trận | Mũi tên quay lại và đồng tiền |
| Đổi Lượt | Đúng năm lá tính điểm: trả 6 HP để nhận một lượt đánh; chỉ trả khi vẫn sống; toàn bộ dấu chung một lần mỗi trận | Bánh xe năm nan |
| Tam Nhịp | Mỗi lần tính điểm thật tích một nhịp; lần thứ ba hồi 8 HP rồi xóa nhịp; tái kích hoạt không tích thêm | Ba vạch nhịp |

Huyết ưu tiên lá có ST cơ bản cao; Neo giúp đưa lá chủ lực vào trận. Hải Đăng cần chia cùng rank giữa bài đánh và bài giữ. Tứ Phương cần phân bổ dấu qua nhiều chất và chuẩn bị bằng lượt bỏ. Thu Hồi đổi tài nguyên kinh tế lấy khả năng sửa tay bài; Đổi Lượt cần xây thế năm lá và giữ đủ HP. Thanh Tẩy và Tam Nhịp tạo hai cách phòng thủ khác nhau: giữ bài hoặc tái sử dụng lá trong trận.

Các hiệu ứng cộng ST/Vàng với điều kiện nhỏ, mạng lưới chỉ cộng ST, tạm nâng tiến hóa và cơ chế đổi lượt trùng vai trò đã được bỏ khỏi cửa hàng, rương và bộ sưu tập. Tiên Tri trùng phần lập kế hoạch; Tro Tàn trùng công cụ tiêu hủy bộ bài. Tranh cũ vẫn giữ làm tư liệu, không xuất hiện trong nhóm thưởng hiện hành.

## Save cũ

`Deck.RETIRED_SEALS` đổi 16 mã cũ sang dấu còn lại gần vai trò nhất. Bài giữ nguyên tiến hóa, trang bị, tốc đánh và ST đã tích vĩnh viễn từ Nảy Mầm. Tiêu hao con dấu đang cất cũng chuyển đổi; rương đang mở loại bỏ lựa chọn bị trùng sau chuyển đổi. Các tên màu cũ được chuẩn hóa.

## Hình ảnh và kiểm tra

Biểu tượng là hình vector trong `ui/components/seal_emblems.lua`: kim loại vàng cổ, men tối theo vùng, nét lớn và hình riêng cho từng hiệu ứng. Chúng nằm dưới cờ tốc đánh, được vẽ cùng metadata/khung trong biến đổi và vật liệu của lá bài. Không thêm khung bài hay chữ vào tranh Continental.

Chạy `love . --test-seals` để kiểm tra hiệu ứng, chi phí, giới hạn chung, preview, chuyển save, mười hình khác nhau khi dùng cùng màu và độ trong suốt. Lệnh tạo `docs/seal_emblems_runtime.png` từ renderer thật ở kích thước bài 64 và 144 px. `love . --test-chest-expansion` kiểm tra thêm đường dùng trực tiếp/cất tiêu hao, loader và rương.

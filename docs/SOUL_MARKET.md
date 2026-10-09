# Chợ linh hồn — nghi lễ trang bị

Chợ dùng đủ chiều ngang với 5 ô di vật và 9 ô tiêu hao/nghi lễ. Mỗi ô giữ nguyên vị trí sau khi mua. Nhấp vào ô để xem và xác nhận giao dịch; thẻ mua vào balo, chuột phải để dùng.

| Thẻ | Giá | Hiệu ứng |
|---|---:|---|
| Khảm Hốc Linh Hồn | 32 LH | Chọn một quân bài, tăng vĩnh viễn 1 hốc; từ 4 hốc ban đầu lên tối đa 8. |
| Phá Luật | 48 LH | Chọn một quân bài, cho phép vĩnh viễn gắn nhiều món cùng loại. |

Cả hai thẻ có màn hình chọn lá và xem trước. Hủy bằng ESC giữ thẻ. Lá đã có Phá Luật hoặc đủ 8 hốc không được chọn lại cho cùng hiệu ứng. Nâng cấp áp dụng vào đúng ID trong bộ bài và các bản trên tay/cọc rút/cọc bỏ; giữ qua đổi rank, sao chép và lưu/tải.

Khung quân bài có bốn hốc ở góc. Mỗi lần mở rộng thêm một hốc giữa cạnh theo thứ tự trên, phải, dưới, trái. Hốc trống tối; hốc đã khảm mang màu tầng trang bị và sáng khi kích hoạt. Món chiếm hai hốc hiển thị một hốc liên kết, vẫn chỉ kích hoạt một lần. Chi tiết lá bài hiển thị ảnh, tầng và hiệu ứng từng món. Các lá cùng mang trang bị kích hoạt riêng: 10♣ và 10♠ cùng mang Tấm Sắt nhận tổng +4 Giáp khi cả hai tính điểm.

Mỗi món trang bị trùng có lượt kích hoạt riêng. Bình Tích Sét, Lọ Huyết Tế, Kim Đồng Hồ và Chuông Tĩnh Lặng có tích trữ riêng từng món. Di vật linh hồn có số lần dùng riêng; Neo nối thời hạn, Chén đặt độc riêng và Khế Ước cộng thưởng từ từng món. Xích trả lại đúng một lá vốn có. Các món vẫn cần đủ hốc, điều kiện và chi phí; trần Giáp toàn tay 30 và Vàng từ trang bị thường 6/tay giữ nguyên. Tái kích hoạt lá không trả lại tài nguyên/trang bị đã dùng trong tay.

## Lá Tiêu Hủy

Thưởng tại chợ linh hồn: **2 × giá trị linh hồn của lá + hồi 10 HP + 5 Vàng**. Không vượt HP tối đa; hiệu ứng Dược Sĩ của đặc quyền cộng thêm như trước. Cửa hàng thường vẫn trả giá trị linh hồn gốc. Phần thưởng dự kiến hiện trước khi xác nhận. Mỗi ID chỉ nhận thưởng một lần; bộ bài phải giữ ít nhất 1 lá.

## Tranh và kiểm tra

Hai tranh riêng được tạo bằng built-in image_gen, đúng phong cách Continental, PNG 1024×1536 và JPG runtime 512×768. Prompt và nguồn ở `soul_market_assets.json`; đăng ký trong manifest và loader chung.

- `lovec.exe . --test-soul-market`: giao dịch, chọn/hủy, giới hạn hốc, từng món trùng, tích trữ/preview, di vật linh hồn, thưởng và lưu/tải; chạy kèm bộ kiểm tra di vật/chiều sâu cũ.
- `lovec.exe . --capture --capture-soul-market`: thao tác giao diện thật từ mua đến dùng/tháo/tiêu hủy; ảnh `soul_market_*.png`. Capture không ghi vào file lưu ván của người chơi.
- `lovec.exe . --test-equipment-sockets`: kiểm tra 4–8 hốc, lưu/tải, cộng dồn từng món/từng chủ sở hữu và hiệu ứng +2 Giáp riêng trên hai lá; ảnh `equipment_socket_frames.png` và `equipment_scoring_stack.png`.

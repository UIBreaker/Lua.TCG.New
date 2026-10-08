# Chợ linh hồn — nghi lễ trang bị

Chợ dùng đủ chiều ngang với 5 ô di vật và 9 ô tiêu hao/nghi lễ. Mỗi ô giữ nguyên vị trí sau khi mua. Nhấp vào ô để xem và xác nhận giao dịch; thẻ mua vào balo, chuột phải để dùng.

| Thẻ | Giá | Hiệu ứng |
|---|---:|---|
| Khảm Hốc Linh Hồn | 32 LH | Chọn một quân bài, tăng vĩnh viễn 1 hốc; từ 3 hốc ban đầu lên tối đa 6. |
| Phá Luật | 48 LH | Chọn một quân bài, cho phép vĩnh viễn gắn nhiều món cùng loại. |

Cả hai thẻ có màn hình chọn lá và xem trước. Hủy bằng ESC giữ thẻ. Lá đã có Phá Luật hoặc đủ 6 hốc không được chọn lại cho cùng hiệu ứng. Nâng cấp áp dụng vào đúng ID trong bộ bài và các bản trên tay/cọc rút/cọc bỏ; giữ qua đổi rank, sao chép và lưu/tải.

Mỗi món trang bị trùng có lượt kích hoạt riêng. Bình Tích Sét, Lọ Huyết Tế, Kim Đồng Hồ và Chuông Tĩnh Lặng có tích trữ riêng từng món. Di vật linh hồn có số lần dùng riêng; Neo nối thời hạn, Chén đặt độc riêng và Khế Ước cộng thưởng từ từng món. Xích trả lại đúng một lá vốn có. Các món vẫn cần đủ hốc, điều kiện và chi phí; trần Giáp toàn tay 30 và Vàng từ trang bị thường 6/tay giữ nguyên. Tái kích hoạt lá không trả lại tài nguyên/trang bị đã dùng trong tay.

## Lá Tiêu Hủy

Thưởng tại chợ linh hồn: **2 × giá trị linh hồn của lá + hồi 10 HP + 5 Vàng**. Không vượt HP tối đa; hiệu ứng Dược Sĩ của đặc quyền cộng thêm như trước. Cửa hàng thường vẫn trả giá trị linh hồn gốc. Phần thưởng dự kiến hiện trước khi xác nhận. Mỗi ID chỉ nhận thưởng một lần; bộ bài phải giữ ít nhất 1 lá.

## Tranh và kiểm tra

Hai tranh riêng được tạo bằng built-in image_gen, đúng phong cách Continental, PNG 1024×1536 và JPG runtime 512×768. Prompt và nguồn ở `soul_market_assets.json`; đăng ký trong manifest và loader chung.

- `lovec.exe . --test-soul-market`: giao dịch, chọn/hủy, giới hạn hốc, từng món trùng, tích trữ/preview, di vật linh hồn, thưởng và lưu/tải; chạy kèm bộ kiểm tra di vật/chiều sâu cũ.
- `lovec.exe . --capture-shop --capture-soul-market`: thao tác giao diện thật từ mua đến dùng/tháo/tiêu hủy; ảnh `soul_market_*.png`. Capture không ghi vào file lưu ván của người chơi.

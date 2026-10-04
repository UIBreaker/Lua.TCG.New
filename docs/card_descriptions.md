# Mô tả lá bài

Mọi tooltip quân bài, SPN, ITM, tiêu hao, rương và đặc quyền dùng chung
`src/card_description.lua` và `ui/components/card_description.lua`, kể cả màn xem bộ bài.
Thông số vẫn lấy từ resolver và khả năng hiện tại của game.

Chữ nội dung Arial thường 14px; tiêu đề và nhãn dùng font UI có sẵn.
Các phần hiệu ứng, tiến hóa, cấp kế tiếp, chỉ số, vai trò, trang bị và cảnh báo
được tách riêng. Con số dùng màu của mục tương ứng. Tooltip có nền kín,
viền kim loại và màu nhận diện theo loại lá.

Khung mặc định rộng 360px. Với nhiều hiệu ứng, khung mở rộng tới 430px và
giảm khoảng cách giữa các mục. Mô tả vượt chiều cao 680px được thu vừa màn hình,
giữ đầy đủ nội dung. Đây là kích thước trên hệ tọa độ game 1280×720.

Kiểm tra dữ liệu: `lua tests/gameplay_expansion_smoke.lua`.
Kiểm tra hover thật: `../love-11.5-win64/love.exe . --test-ux-polish`.
Render các mẫu và kiểm tra toàn bộ danh mục:
`../love-11.5-win64/love.exe tests/card_description_preview`.
Chạy từ thư mục gốc dự án; trên Windows có đường dẫn Unicode, đặt biến môi trường
`POKER_DESCRIPTION_ROOT` thành đường dẫn ngắn ASCII của dự án.
Ảnh kết quả: `docs/card_description_preview.png`.

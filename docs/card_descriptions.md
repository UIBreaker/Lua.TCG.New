# Mô tả lá bài

Tooltip dùng chung `src/card_description.lua` và `ui/components/card_description.lua`.
Mặc định chỉ hiện tên, hiệu ứng thực tế, trạng thái đang có và hiệu ứng bổ sung.
Không hiện tiểu sử, luật chung, chỉ số nền, vai trò hay cấp kế tiếp trong bản gọn.
Giữ Shift để đọc các thông tin tham khảo này; thả Shift để thu gọn.
Cảnh báo khóa/vô hiệu luôn đứng đầu. Trang bị, dấu ấn, cường hóa và ấn bản
được gom vào một mục; tên ấn bản đi cùng hiệu ứng thực tế của nó.

Chữ nội dung Arial thường 14px, khung rộng 340px. Chiều cao tối đa
440px ở bản gọn và 600px ở bản chi tiết trên hệ tọa độ game 1280×720.
Nội dung dài cuộn bằng con lăn khi rê trên lá bài, có thanh cuộn chỉ vị trí.
Không thu nhỏ chữ hay cắt mất nội dung. Tiêu đề và chân khung luôn cố định.
Cấp 0 được ẩn; chỉ hiện cấp đã nâng hoặc cấp tạm thời.

Kiểm tra mô tả và render mẫu:
`../love-11.5-win64/love.exe tests/card_description_preview`.
Chạy từ gốc dự án. Với đường dẫn Unicode trên Windows, đặt
`POKER_DESCRIPTION_ROOT` thành đường dẫn ngắn ASCII của dự án.
Ảnh: `docs/card_description_preview.png`.
Harness kiểm tra danh mục, khung nội dung, ưu tiên cảnh báo, thông tin phụ,
nhóm bổ sung, cuộn quá dài, giữ Shift và việc trả con lăn lại cho game.

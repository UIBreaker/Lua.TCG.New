# Mô tả lá bài

Tooltip dùng chung `src/card_description.lua` và `ui/components/card_description.lua`.
Mặc định hiện danh tính, cấp (kể cả cấp 0), cấp tạm, khả năng ở cấp hiện tại,
trạng thái, thưởng quân bài và toàn bộ trang bị. Thanh chỉ số cố định ghi rõ
sát thương gốc và tốc đánh hiện tại của lá (gồm buff và trang bị).
Thưởng có điều kiện được ghi riêng, không gộp thành một tổng sát thương giả định.
Thưởng Q hiển thị số cụ thể theo số món đang khảm, không theo số hốc chiếm.
Luật kích hoạt và giới hạn tài nguyên hiện trong mục Quy tắc khả năng.
Tiểu sử và cấp kế tiếp nằm trong phần tham khảo khi giữ Shift.
Giữ Shift để đọc các thông tin tham khảo này; thả Shift để thu gọn.
Cảnh báo khóa/vô hiệu luôn đứng đầu. Trang bị, dấu ấn, cường hóa và ấn bản
giữ đầy đủ hiệu ứng. Trang bị có tên, tầng, vị trí hốc và tranh thu nhỏ;
hốc đã dùng / tổng hốc luôn hiển thị. Trang bị được ưu tiên trước
dấu ấn/cường hóa/ấn bản khi có nhiều thông tin. Tên ấn bản đi cùng hiệu ứng thực tế.

Chữ nội dung Arial thường 14px, quy tắc tham khảo Arial thường 12px,
tiêu đề 22px. Khung quân bài rộng 400px,
loại khác 360px, chiều cao tối đa 600px trên hệ tọa độ game 1280×720.
Nội dung dài cuộn bằng con lăn khi rê trên lá bài, có thanh cuộn chỉ vị trí.
Không thu nhỏ chữ hay cắt mất nội dung. Tiêu đề và chân khung luôn cố định.
Trang bị đơn lẻ dùng cùng kiểu trình bày với trang bị đã khảm: tầng, số hốc,
tranh nhỏ và danh sách ít khung; chỉ tách dòng ở nhánh thay thế để tiết kiệm
chiều cao, không bỏ điều kiện hay chi phí.

Kiểm tra mô tả và render mẫu:
`../love-11.5-win64/love.exe tests/card_description_preview`.
Chạy từ gốc dự án. Với đường dẫn Unicode trên Windows, đặt
`POKER_DESCRIPTION_ROOT` thành đường dẫn ngắn ASCII của dự án.
Ảnh: `docs/card_description_preview.png`.
Kiểm tra trong trận thật: `../love-11.5-win64/love.exe . --capture-card-description`.
Ảnh: `docs/card_description_combat.png`; chế độ capture không ghi save người chơi.
Harness kiểm tra danh mục, khung nội dung, ưu tiên cảnh báo, thông tin phụ,
nhóm bổ sung, cuộn quá dài, giữ Shift và việc trả con lăn lại cho game.

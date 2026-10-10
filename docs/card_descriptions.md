# Mô tả lá bài

Tooltip dùng chung `src/card_description.lua` và `ui/components/card_description.lua`.
Mặc định hiện danh tính, cấp (kể cả cấp 0), cấp tạm, khả năng ở cấp hiện tại,
trạng thái, thưởng quân bài và toàn bộ trang bị. Thanh chỉ số cố định ghi rõ
sát thương gốc và tốc đánh hiện tại của lá (gồm buff và trang bị).
Thưởng có điều kiện được ghi riêng, không gộp thành một tổng sát thương giả định.
Thưởng Q hiển thị số cụ thể theo số món đang khảm, không theo số hốc chiếm.
Khung mô tả không hiện mục Quy tắc khả năng, kể cả khi giữ Shift.
Tiểu sử và cấp kế tiếp nằm trong phần tham khảo khi giữ Shift.
Giữ Shift để đọc các thông tin tham khảo này; thả Shift để thu gọn.
Cảnh báo khóa/vô hiệu luôn đứng đầu. Trang bị có tên, tầng, vị trí hốc và tranh thu nhỏ;
hốc đã dùng / tổng hốc luôn hiển thị. Trang bị được ưu tiên trước
dấu ấn/cường hóa/ấn bản khi có nhiều thông tin. Tên ấn bản đi cùng hiệu ứng thực tế.

Chữ nội dung Arial thường 14px, hiệu ứng trang bị đã khảm ở chế độ thường 12px,
tiêu đề 22px. Khung quân bài rộng 400px, loại khác 360px, luôn một cột.
Chế độ thường cao tối đa 520px, ưu tiên hiện đủ thông tin và không có thanh cuộn.
Tầng và hốc nằm cùng dòng với tên trang bị; tranh nhỏ 24×36px. Danh tính nhân vật
phụ chỉ hiện khi giữ Shift. Mẫu ba trang bị kèm cường hóa, ấn bản hiện đầy đủ
hiệu ứng mà không mở rộng ngang hay co chữ.
Nếu nội dung quá dài, khung thường giữ danh sách tên/tầng/hốc của tất cả trang bị;
Shift mở toàn bộ hiệu ứng. Nếu vẫn quá dài, phần bổ sung hiện số hiệu ứng và hướng
dẫn Shift. Khung không tự mở thêm cột để che sân đấu. Nội dung cực dài vượt các
bước này mới co toàn khung để giữ kích thước giới hạn.
Giữ Shift mở chi tiết đầy đủ trong khung một cột, cao tối đa 560px trên hệ tọa độ
game 1280×720. Thanh cuộn chỉ xuất hiện trong chế độ này nếu nội dung dài.
Con lăn được ưu tiên cho khung Shift; khung giữ nguyên lá và vị trí khi đưa
chuột vào mô tả. Thả Shift trả lại hành vi rê và cuộn của game.
Tiêu đề và chân khung luôn cố định khi cuộn.
Trang bị đơn lẻ dùng cùng kiểu trình bày với trang bị đã khảm: tầng, số hốc,
tranh nhỏ và danh sách ít khung; chỉ tách dòng ở nhánh thay thế để tiết kiệm
chiều cao, không bỏ điều kiện hay chi phí.

Kiểm tra mô tả và render mẫu:
`../love-11.5-win64/love.exe tests/card_description_preview`.
Chạy từ gốc dự án. Với đường dẫn Unicode trên Windows, đặt
`POKER_DESCRIPTION_ROOT` thành đường dẫn ngắn ASCII của dự án.
Ảnh: `docs/card_description_preview.png`.
Kiểm tra trong trận thật: `../love-11.5-win64/love.exe . --capture-card-description`.
Ảnh: `docs/card_description_combat.png`, `docs/card_description_shift.png`;
chế độ capture không ghi save người chơi.
Harness kiểm tra danh mục, khung nội dung, ưu tiên cảnh báo, thông tin phụ,
nhóm bổ sung, cuộn quá dài, giữ Shift và việc trả con lăn lại cho game.

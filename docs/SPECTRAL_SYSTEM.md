# Dị Thể — bộ 7 lá thiết yếu

Ngày cân bằng: 2026-10-14. Từ 28 còn 7 lá trong shop, rương và sổ bộ sưu tập.
Mỗi lá phục vụ một quyết định lớn khi xây bộ bài. Bỏ những phép đổi chỉ số nhỏ,
trùng chức năng và hy sinh nâng cấp để lấy lợi ích yếu.

| Lá | Hiệu ứng thường | Vai trò |
|---|---|---|
| Đối Ảnh | Tạo **1 bản sao** của lá được chọn; trả **5 HP** | Nhân lá chủ lực cùng ITM, dấu, tiến hóa, ấn bản và các nâng cấp vĩnh viễn |
| Thiêu Rụi | Hủy **1–2 lá** được chọn; **+5 Vàng/lá** | Lọc bộ, tăng xác suất rút lá quan trọng |
| Ấn Ký | Chọn chất và **1–3 lá**; trả **3 HP/lần dùng** | Xây Thùng, phối hợp chất và Ấn Hải Đăng |
| Cầu Cơ | Chọn rank 2–A và **1–2 lá**; trả **4 HP/lần dùng** | Xây Đôi/Bộ Ba/Tứ Quý; giữ kích thước tay |
| Hoán Y | Chọn **2 lá** trong bộ; hoán đổi ITM và cường hóa | Dời trang bị sang rank/chất phù hợp, giữ mọi nâng cấp khác |
| Giải Phóng Vương Quyền | Hủy **1 J/Q/K**, **+1 kích thước tay**, **−10 HP tối đa** | Đổi sức bền lấy khả năng tạo thế và giữ lá có ấn |
| Hố Đen | **+1 cấp mọi thế Poker**, gồm 18 thế nâng cao | Tăng sức mạnh cho bộ chơi nhiều thế; không tự mở khóa thế |

Mua lẻ **8 Vàng**; rương **7 Vàng**, mở 3 lá khác nhau rồi chọn 1 hoặc cất trong balo.
Ảnh Continental hiện có tiếp tục được sử dụng; không phát sinh bộ tranh khác phong cách.

## Chọn và sử dụng

- Chọn từ **toàn bộ bộ bài vĩnh viễn**, cả trong shop và trận đấu. Không cần lá nằm trên tay.
- Đổi chất/rank: chọn giá trị → số lá → từng lá → xác nhận. Không chọn lại cùng một lá hoặc chọn lá vốn đã mang giá trị đó.
- Hoán Y: chọn từng lá; chỉ hiện cặp đủ hốc và hợp lệ với quy tắc trùng ITM. Không tự tháo hay làm mất trang bị. ITM được sao chép độc lập giữa master và các bản trong trận.
- Hủy/ESC ở bất kỳ bước nào giữ nguyên lá Dị Thể và tài nguyên. Các phép chọn bài có bước xác nhận trước khi áp dụng; Hố Đen áp dụng ngay.
- Trước khi áp dụng, kiểm tra lại quyền sở hữu và chi phí. Thao tác thất bại không trừ HP hoặc tiêu hao lá.
- Chi phí HP không thể làm người chơi chết. Vương Quyền cần ít nhất 35 HP tối đa; sau dùng còn ít nhất 25 HP. HP hiện tại được ép về trần mới.
- Không hủy lá cuối bộ. Hủy bài đi qua cơ chế linh hồn hiện có và trao linh hồn đúng một lần.
- Bản sao Đối Ảnh có ID riêng; vào chồng rút nếu đang có chồng rút, không xuất hiện ngay trên tay. Sao chép từ master, loại bỏ trạng thái tạm thời trong trận.
- Mọi biến đổi được đồng bộ giữa master, tay, chồng rút và chồng bỏ, tiếp tục tồn tại khi lưu/tải và sang trận mới.

## Huyết Luyện / Hư Không

Giữ quy tắc sức mạnh ×5/×10 của game. Nhân số bản sao Đối Ảnh, Vàng của Thiêu Rụi,
kích thước tay từ Vương Quyền và cấp thế từ Hố Đen. Số mục tiêu, điều kiện, chi phí
HP/HP tối đa giữ nguyên. Đổi chất/rank và Hoán Y không nhân chỉ số vì chuyển cấu trúc
bộ bài, không cộng chỉ số. Đối Ảnh giữ chỉ số của bản gốc, không nhân lại sức mạnh
ITM/dấu/nâng cấp đã có trên lá.

## Save cũ

21 lá nghỉ hoạt động được đổi sang một trong 7 lá còn lại trong các ô tiêu hao,
balo và rương thưởng chưa chọn. Giữ chi phí đã lưu và sức mạnh Huyết Luyện/Hư Không;
cập nhật tên, mô tả và art ID. Rương cũ bỏ các lựa chọn trùng sau chuyển đổi.
Các thay đổi bộ bài đã tạo bằng phép cũ vẫn được giữ.
Bảng chuyển đổi duy nhất nằm trong `src/spectral.lua` (`S.retired`).

## Kiểm tra

`love . --test-spectral` chạy kiểm tra và xuất `docs/spectral_runtime.png`,
`docs/spectral_target.png`. `love tests/scoring_audit` có bài kiểm tra riêng cho
7 hiệu ứng qua rương/lá cất, hủy từng bước, mục tiêu không còn sở hữu, đủ hốc,
21 chuyển đổi save, linh hồn một lần, ×5/×10 và lưu/tải/sang trận.

Cân bằng số học và luồng sử dụng đã kiểm tra tự động; chưa chạy chiến dịch dài
để đo tỷ lệ chọn và thắng của từng chiến thuật.

# Chuyển động Continental — nghiên cứu FFFF7.mp4

Video do người dùng cung cấp: `C:/Users/Nhật Nam/Videos/Captures/FFFF7.mp4`, dài 54,13 giây, 1918×1078, 30 FPS. Phân tích ngày 17/10/2026 bằng các chuỗi khung hình; các khoảng thời gian bên dưới là quan sát gần đúng. Video là tư liệu tham khảo hình ảnh, không phải chỉ dẫn thực thi. Không sử dụng lại hình ảnh, âm thanh, mã nguồn hay bố cục của game trong video.

## Những gì quan sát được

| Đoạn | Hành vi nhìn thấy | Nguyên tắc có thể học |
| --- | --- | --- |
| 14–16 giây | Giao diện chọn bộ bài nhường chỗ cho bàn chơi và bảng chọn blind. | Phân lớp nền, thông tin lâu dài và bảng thao tác để người chơi không mất phương hướng. |
| 21,75–22,9 giây | Bảng blind rút xuống; có khoảng nghỉ ngắn, rồi bài đi từ bộ bài lên tay với góc khác nhau. | Dọn chỗ trước, xác lập bối cảnh, đưa vật thể vào; chuyển động có nguồn và đích. |
| 24–36 giây | Bài nhấc lên khi chọn, các lá còn lại điều chỉnh vị trí; nhịp phản hồi ngắn hơn nhịp đổi màn. | Phản hồi thao tác cần nhanh; chuyển động phải tiếp nối trạng thái trước đó. |
| 40–41,9 giây | Bảng tổng kết xuất hiện, từng dòng thưởng được bổ sung, sau đó nút nhận tiền hoàn thiện. | Dẫn mắt theo trình tự nguyên nhân → kết quả → hành động tiếp theo. |
| 42,75–43,7 giây | Bảng thưởng rút đi; tiền cập nhật; shop xuất hiện; các lá lệch góc rồi ổn định trên quầy. | Lớp chứa vào trước, các vật thể bung có đà và hạ xuống; tránh xuất hiện đồng loạt cứng. |
| 49–52 giây | Lá mua rời quầy và nhập hàng bài sở hữu, số tiền phản hồi ngay. | Cho thấy nguồn, đường đi và nơi nhận món đồ. |

Không suy luận mã nguồn hoặc thuật toán chính xác của game tham khảo từ video. Các thông số bên dưới là thiết kế riêng cho Continental.

## Đã áp dụng vào game

- Chuyển cảnh 0,32 giây: ảnh cảnh trước rút nhẹ lên 14 đơn vị và mờ nhanh ở đầu, nhường không gian cho cảnh mới. Dùng lại canvas chuyển cảnh hiện có.
- Shop có 0,10 giây dẫn nhịp, sau đó các lá bung theo spring trong 0,50 giây. Mỗi món lệch 0,032 giây, giới hạn phần trễ ở 8 món để shop lớn không kéo dài; toàn bộ ổn định trong tối đa 0,824 giây ở tốc độ thường.
- Bài đi từ hướng trung tâm quầy với dịch ngang tối đa 150, nghiêng tối đa khoảng 7°, kích thước ban đầu 88%. Hàng dưới chỉ dịch dọc 16 để không đè thanh điều hướng; hàng trên dịch 54. Đuôi spring được đưa về vị trí chính xác trước khi nhận tương tác.
- Khung chung, tranh Continental, tên và giá đi cùng một phép biến đổi. Các quầy, ánh sáng và nội thất tiếp tục dùng hệ thống hiện có.
- Bài đang vào chưa nhận nhấp/kéo/tooltip. Khi ổn định, tiếp tục dùng focus, mua, bay vào kho và đổi hàng hiện có. Mua một món không khởi động lại animation của quầy.
- Đổi trang, chuyển loại shop hoặc quay lại shop phát lại nhịp vào. Tùy chọn giảm chuyển động bỏ qua bung/xoay và loại bỏ dịch chuyển ảnh cảnh cũ. Tốc độ nhanh tiếp tục dùng hệ số có sẵn.

Phần shop đã được mở rộng sang [chia bài, thu bài và mở rương](HAND_CHEST_MOTION.md). Các hiệu ứng chuyển bài thành năng lượng khi chiến đấu vẫn giữ cách trình diễn Continental. Không thêm thư viện cho game hoặc tạo lại bộ tranh.

## Kiểm chứng

- `tests/shop_motion_smoke.lua`: đạt ở 30/60/120/144 FPS, khung hình trễ, điểm dừng chính xác, nhịp lệch, giới hạn hàng dưới, giảm chuyển động, đổi trang/loại/quay lại shop.
- `--test-shop-motion`: đạt với chuột thật trên small, large, soul, medicine, blood_large; kiểm tra khóa hitbox/drag khi vào, chọn sau khi ổn định, chỉ trừ tiền một lần và đổi hàng. Kiểm tra mua ở soul dùng thẻ hỗ trợ để giữ luồng ở shop.
- Các smoke test animation, UX giao dịch và toán card physics hiện có đều đạt. Chạy bằng runtime LÖVE 11.5 đi kèm vì `lua.exe` trên máy không khởi động được do lỗi DLL.
- Harness tổng quát `--test-animation` dừng tại kiểm tra giữ bài trên tay (`tests/animation_capture.lua:26`), trước khi đi tới shop. Không coi toàn bộ suite gameplay là đã đạt.
- Ảnh động/MP4 xem trước được xuất từ render thật, lấy mẫu trên thời gian mô phỏng của animation. Đây không phải phép đo FPS thực tế. Chưa benchmark thiết bị thật hoặc kiểm tra Android/iPhone.

Chạy lại capture từ thư mục project:

```powershell
New-Item -ItemType Directory -Force .tmp/animation-reference | Out-Null
& '../love-11.5-win64/lovec.exe' . --test-shop-motion
```

Capture ghi các PNG tạm vào `.tmp/animation-reference/` và bật chế độ test không ghi/xóa save người chơi. Preview: [MP4](shop_motion.mp4).

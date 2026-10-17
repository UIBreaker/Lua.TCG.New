# Chia bài, thu bài và mở rương Continental

Tiếp nối nghiên cứu `FFFF7.mp4` và animation shop ngày 17/10/2026. Dùng lại tranh, mặt sau, khung bài chung, nội thất và hiệu ứng tro Continental; không nhập tài nguyên từ game tham khảo.

## Nhịp chuyển động

- **Chia bài:** áp dụng cả đầu trận lẫn rút bổ sung. Lá đi từ chồng bài bên phải lên tay theo đường cong, nghiêng nhẹ rồi hạ xuống. Mỗi lá đi trong 0,46 giây, lệch 0,045 giây; giới hạn phần trễ ở 8 lá. Spring và đuôi hạ cánh dùng chung với shop qua `Motion.settle`.
- **Thu bài:** lá bỏ giữ hình dáng tại vị trí cũ, thu về chồng bài và lật úp trong 0,36 giây; lệch 0,035 giây giữa các lá. Hình đang bay là bản chụp dữ liệu riêng, không sửa lá thật. Chồng bài bên phải là điểm thu trực quan chung; luật đưa lá vào mộ bài hay đáy bộ bài vẫn do gameplay quyết định.
- **Bài mới chờ bài cũ:** luật bỏ/rút giải quyết một lần như cũ, phần hình ảnh chia bổ sung chờ lượt thu kết thúc. Nhờ vậy lá được rút lại ngay cũng không bị nhân hình hoặc nhảy giữa hai vị trí.
- **Kết thúc trận:** các lá còn trên tay thu về trước khi chuyển màn tổng kết. Thông báo thắng lặp lại dùng chung một callback; chỉ chạy quy trình thưởng sau khi thu xong. Các lá đã chuyển thành năng lượng trong lúc đánh vẫn giữ cách trình diễn chiến đấu riêng của game.
- **Mở rương:** giữ nhịp tan tro → tụ vật chất, rồi bung ba mặt sau lệch nhịp → lật và tái tạo tranh → mở hành động. Bay 0,50 giây, lệch 0,08 giây; toàn bộ mặt thưởng ổn định sau 1,76 giây. Đường bay có đà và đuôi hạ cánh cùng họ chuyển động với shop. Rương shop, kho báu và boss dùng chung renderer.
- **Ánh sáng:** giảm lớp chớp vàng đầu rương để còn đọc được tranh; màn che và tiêu đề xuất hiện mềm. Khung đi cùng phép biến đổi của mặt bài.

Chọn, sắp xếp, kéo, đánh và bỏ bài trên tay chờ lượt chia/thu ổn định. Nút và phím tắt dùng cùng điều kiện. Tốc độ nhanh dùng hệ số hiện có cho các nhịp mới. Giảm chuyển động đưa bài về vị trí ổn định, giữ cách tái tạo mặt thưởng nhưng bỏ bung/xoay và rung rương, giảm flash/particle. Trạng thái chuyển động và callback được giữ ngoài dữ liệu save; mở trận mới hoặc đổi cảnh qua Debug hủy trạng thái cũ. Debug vẫn mở trực tiếp được màn tính điểm.

## Kiểm chứng

- `tests/hand_chest_motion_smoke.lua`: quỹ đạo ở 30/60/120/144 FPS, frame trễ, điểm đầu/cuối, nhịp lệch, một âm thanh cho mỗi lá, chờ thu trước khi chia, ghost không sửa lá thật, callback chạy đúng một lần, nhanh/giảm chuyển động. Kiểm tra reveal không thay đổi RNG phần thưởng.
- `--test-hand-chest-motion`: chuột và phím thật; chia 5 lá từ bộ 12 lá, chặn chọn/sắp xếp sớm, chọn hai lá và bỏ, kiểm tra lượt bỏ và số lá từng chồng. Mở rương shop và giữ thưởng vào balo, mở rương kho báu/boss và nhận đúng một lá. Kiểm tra nhanh/giảm chuyển động, sau đó thắng trận qua luồng thật: chờ thu bài, giữ bài sở hữu, nhận loot một lần và chuyển sang tổng kết.
- Các smoke test hand motion, chest reveal, animation, UX giao dịch, card physics và shop motion hiện có vẫn đạt.
- Chưa benchmark FPS trên thiết bị thật hoặc kiểm tra cảm ứng Android/iPhone. Video lấy mẫu theo thời gian mô phỏng của render LÖVE, không phải bằng chứng FPS thời gian thực. Không tuyên bố toàn bộ suite gameplay đã đạt.

Chạy từ thư mục project với runtime LÖVE 11.5 đi kèm:

```powershell
New-Item -ItemType Directory -Force .tmp/hand-chest-motion | Out-Null
& '../love-11.5-win64/lovec.exe' . --test-hand-chest-motion
# Chỉ kiểm tra luồng, không xuất các frame preview:
& '../love-11.5-win64/lovec.exe' . --test-hand-chest-motion --no-motion-preview
```

Capture bật chế độ test không ghi/xóa save người chơi, xuất PNG tạm vào `.tmp/hand-chest-motion/`. [Video chia / thu / mở rương](hand_chest_motion.mp4).

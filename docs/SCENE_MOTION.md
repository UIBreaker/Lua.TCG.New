# Chuyển cảnh Continental

Tiếp nối [nhịp kết thúc combat và nhận thưởng](OUTCOME_MOTION.md), dùng lại khung hình đã vẽ và đường cong `Motion.settle`. Không thêm tranh, shader, thư viện hoặc canvas riêng cho từng lần chuyển.

- **Bắt đúng màn cũ:** quan sát trạng thái ngay trước khi vẽ màn mới, rồi chụp canvas của khung hình vừa hiển thị. Trước đây việc phát hiện nằm đầu `love.update`; thay đổi trạng thái muộn hơn có thể làm lọt một khung màn mới rồi chụp nhầm nó làm màn cũ. Nền cảnh cũng được cập nhật tại ranh giới vẽ nếu trạng thái vừa đổi.
- **Nhịp chung:** màn cũ nhấc nhẹ 12 px rồi tan trong 0,44 giây. Opacity đi đơn điệu, bắt đầu ở 1 và kết thúc chính xác ở 0; premultiplied alpha giữ độ sáng đúng khi chồng hai cảnh. Bản đồ hành trình hạ vào 16 px bằng cùng đường cong hạ bài/shop. Combat, bảng thưởng và stock shop giữ animation vào riêng, không cộng thêm một chuyển động toàn màn khác.
- **Chuyển liên tiếp:** nếu cảnh đổi lần nữa khi fade chưa xong, chụp đúng composite đang nhìn thấy để tiếp tục; không quay lại một ảnh cũ hơn. Cảnh chỉ đổi nội dung tạm thời trong một lần update và chưa từng được vẽ không bị đưa vào hàng đợi.
- **Cùng arena:** chơi, tính điểm, địch tấn công và màn thất bại đã ổn định dùng cùng khóa arena, giữ các nhịp combat/thất bại hiện có. Đổi mục tiêu trong đội hình không khởi động lại chuyển cảnh. Thay vùng/ải bản đồ hoặc loại cửa hàng có khóa cảnh tương ứng.
- **Input:** khóa chuột, phím thao tác và cảm ứng từ khi trạng thái đổi, kể cả trước lần vẽ đầu tiên, đến khi fade hoàn tất. Hủy ngón tay/kéo bài và trạng thái nút nhấn khi bàn giao màn; chặn tooltip của màn đang chuyển. Escape, debug và các hộp tùy chọn đang mở vẫn có đường điều khiển riêng.
- **Tốc độ và fallback:** nhanh dùng cùng hệ số 2× với combat/shop. Giảm chuyển động dùng fade ngắn 0,18 giây, không nhấc màn cũ hay hạ bản đồ; tùy chọn được đọc ngay ở khung hình chuyển đầu tiên. Khi tắt hiệu ứng hoặc không có canvas, hiển thị màn mới trực tiếp và không giữ khóa input thừa.

Toàn bộ trạng thái này nằm ngoài dữ liệu game/save. Chuyển cảnh không gọi nhận thưởng, mua hàng, sinh đối thủ, đổi lượt, RNG hoặc các giao dịch tiền/vật phẩm. Luồng bản đồ → combat → thưởng → shop → bản đồ giữ nguyên luật hiện có.

## Kiểm chứng

- `tests/scene_motion_smoke.lua`: 30/60/120/144 FPS, thường/2×/giảm chuyển động; điểm đầu/cuối, opacity đơn điệu, thời lượng, frame chậm, đổi liên tiếp, vùng/shop, khóa input trước vẽ và fallback; RNG không đổi.
- `--test-scene-motion`: sáu vòng đi thật qua toàn bộ chuỗi trên — thường, nhanh, giảm chuyển động, LOW, thiếu canvas và tắt hiệu ứng. Chuột/phím/cảm ứng thật; nhận nhanh và tiếp tục, rời shop, số tiền/vật phẩm và một receipt chiến thắng. Fixture cố định sát thương trúng, loot và loại shop để tập trung kiểm tra chuyển cảnh; bộ giải quyết combat và giao dịch phần thưởng vẫn chạy thật. Save/settings được chặn ghi và xóa trong harness.
- Kiểm tra GPU so các pixel của snapshot với canvas khung hình trước, kể cả khi ngắt giữa một fade; kiểm tra phục hồi canvas/shader. Thêm trường hợp bản đồ node cũ cho tooling. Chạy lại smoke GPU HD2D, animation, combat/đòn địch, reward ceremony/outcome, chia bài/rương và shop.

```powershell
& '..\love-11.5-win64\lovec.exe' .tmp/motion-check tests/scene_motion_smoke.lua
& '..\love-11.5-win64\lovec.exe' . --test-scene-motion --no-motion-preview
```

`docs/scene_motion.mp4`: trích các đoạn chuyển trong vòng thường, 1280×720 / 20 FPS. Đoạn tính điểm/chờ thưởng giữa các lần chuyển được lược bớt. Chưa đo FPS trên điện thoại thật.

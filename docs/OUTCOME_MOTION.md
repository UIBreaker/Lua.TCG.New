# Chiến thắng, thất bại và nhận thưởng Continental

Phần tiếp theo: [chuyển cảnh giữa combat, thưởng, shop và bản đồ](SCENE_MOTION.md).

Tiếp nối [combat](COMBAT_MOTION.md) và [đòn địch](ENEMY_MOTION.md). Giữ toàn bộ tranh, khung bài, màu vàng cổ của chiến thắng và sắc linh hồn lạnh của thất bại. Không thêm asset hoặc thư viện.

- **Chiến thắng:** giữ thứ tự địch tan thành tro → thu các lá còn trên tay → mở lễ trao thưởng. Chặn thông báo chiến thắng lặp sau khi đã rời combat, tránh hoàn tất thêm một ải. Bảng hạ vào trong 0,46 giây bằng `Motion.settle`; các ô chiến lợi phẩm bung từ giữa hàng, lệch 0,032 giây và dừng chính xác. Ô, tranh, khung, tên và nhãn cùng dịch chuyển.
- **Nhận thưởng:** vật phẩm lật trong 0,36 giây, nhấc nhẹ theo `Motion.impact`; bỏ cú nhảy vị trí lúc lật và cú rơi rương đột ngột. Chờ mặt bài ổn định trước món tiếp theo; tooltip chỉ hoạt động khi ô đã dừng. Hover lên/xuống mềm; physics kéo thả không cộng thêm một chuyển động khác vào lễ trao thưởng. Đổi trang có cùng nhịp bung ô. Xu, linh hồn và âm thanh hiện có tiếp tục chạy theo clock lễ trao thưởng.
- **Thất bại:** bài hạ và nghiêng theo cùng đường cong với shop/chia bài, tranh và khung đi cùng nhau. Chữ thất bại hạ vào rồi ổn định; thông tin hiện trước nút chơi lại. Nhịp camera kết thúc tăng từ 0 rồi về 0 bằng `Motion.impact`, thay cho cú giật tức thời. Giữ hiệu ứng tan tro/linh hồn và fallback shader hiện tại.
- **Tốc độ và giảm chuyển động:** death, bảng thưởng và combat cùng 2× khi bật nhanh. Giảm chuyển động bỏ cú lao của địch chết, rơi/xoay bài, bay xu/linh hồn, lật mặt, hover phóng lớn và burst chiến lợi phẩm; vẫn giữ chữ, số chính xác, ánh sáng nhẹ và tín hiệu nhận thưởng.

Tiền và vật phẩm vẫn được giao dịch một lần trước animation. Không đổi luật tính thưởng, tỉ lệ rơi, giá đổi, receipt, RNG hay nội dung gói. Enter/click nhận nhanh vẫn chốt đúng số cuối; Continue đi qua luồng shop/gói hiện có. Nút chơi lại vẫn đợi thất bại ổn định.

## Kiểm chứng

- `tests/outcome_motion_smoke.lua`: 30/60/120/144 FPS, thường/2×/giảm chuyển động; điểm đầu/cuối của bảng, ô và bài thua; stagger, trang, thời điểm nhận input, nhận nhanh nhiều lần; tổng tiền/linh hồn và RNG không đổi.
- `--test-outcome-motion`: tám luồng trong game thật — thắng thường, nhanh, giảm chuyển động, nhận nhanh; thua do địch đánh trước, phản công nhanh, kết thúc lượt với giảm chuyển động; thưởng nhiều trang và đổi toàn bộ hai lần. Kiểm tra chờ tro/thu bài, một transaction, Continue sang shop, và nút chơi lại thật. Harness chặn ghi/xóa save và settings.
- Chạy lại kiểm tra hiện có của reward ceremony/effects, đổi gói, đổi toàn bộ, death VFX, enemy/combat motion và chia bài/rương.

```powershell
& '..\love-11.5-win64\lovec.exe' .tmp/motion-check tests/outcome_motion_smoke.lua
& '..\love-11.5-win64\lovec.exe' . --test-outcome-motion --no-motion-preview
```

`docs/outcome_motion.mp4` trích một chiến thắng có thu bài, lễ trao thưởng và một thất bại. Fixture dùng HP/tốc độ cố định để quan sát; video 20 FPS không phải phép đo hiệu năng trên điện thoại thật.

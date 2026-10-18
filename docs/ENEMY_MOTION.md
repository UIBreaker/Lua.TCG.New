# Nhịp địch tấn công và nhận sát thương Continental

Phần tiếp theo: [chiến thắng, thất bại và nhận thưởng](OUTCOME_MOTION.md).

Tiếp nối [nhịp đánh bài](COMBAT_MOTION.md), dùng lại `Motion.settle` và `Motion.impact`. Giữ tranh, khung bài, âm thanh Continental và toàn bộ luật combat hiện tại; không thêm thư viện hoặc asset bên ngoài.

- Một đòn thường: nghỉ 0,14 giây → lấy đà 0,40 → lao/chém 0,18 → hồi vị 0,56. Các pha nối liên tục về vị trí và vận tốc; hồi vị có dư chấn nhỏ rồi dừng chính xác. Hành động hỗ trợ có chuyển động nhẹ riêng.
- Vệt chém vàng cổ đi về phía người chơi; điểm nhận đòn dùng đỏ ấm khi mất HP, xanh lạnh khi giáp đỡ toàn bộ. Rung máy, nhịp HUD, vòng chạm và HP/giáp cùng dùng clock của đòn đánh. Bỏ chớp trắng toàn màn hình của đòn địch.
- Chế độ nhanh chạy cùng hệ số 2× với tính điểm/shop. Giảm chuyển động bỏ lao/rung/phóng lớn, giữ vòng chạm nhỏ, chữ và thanh tài nguyên để đọc được kết quả.
- HP và giáp chỉ thay đổi khi hết pha lao, qua đúng một lần gọi bộ giải quyết combat. Thanh chính chạy 0,28 giây, đuôi bắt đầu sau 0,12 và kết thúc trong 0,38 giây. Hồi vị kết thúc sau khi cả hai đã ổn định. Không đổi sát thương, công thức giáp, tỉ lệ trúng, thứ tự hay số lượt.
- Phản công sau khi đánh bài chờ timeline người chơi kết thúc. Trong lúc địch ra đòn, snapshot hiệu ứng người chơi nhường quyền hiển thị. SPN phản/chuyển sát thương lấy chênh lệch HP/giáp thực tế từ bộ giải quyết, cho địch giật nhẹ và hiển thị đúng mục tiêu; HUD không bật lại snapshot cũ ở khung hình trả quyền điều khiển.
- Hụt, đóng băng/chặn và hỗ trợ không phát hiệu ứng người chơi bị thương. Nhiều địch tiếp tục ra đòn lần lượt; đòn kết liễu hồi vị xong mới sang animation thất bại. Nhập đánh bài vẫn khóa trong lượt địch.

## Kiểm tra

`tests/enemy_motion_smoke.lua`: 30/60/120/144 FPS, thường/2×; nối pha tấn công và hỗ trợ; thời lượng không phụ thuộc FPS; contact một lần; HP/giáp và đuôi về đúng đích; hụt/chặn/hỗ trợ/kết liễu/nhóm địch. Cũng chạy lại smoke hiện có của enemy attack, combat tactics, enemy AI, giới hạn hỗ trợ, tính điểm, combat feedback, Nen và chia bài/rương.

`--test-enemy-motion`: chạy game thật, chọn/đánh bằng input, kiểm tra HUD thực sự nhận đúng meter và không bật ngược khi mở khóa. Chín luồng: địch đánh trước, phản công nhanh, giáp đỡ với giảm chuyển động, hụt, chặn, hỗ trợ, ba địch nối lượt, kết liễu, Gương Oán phản sát thương. Fixture cố định tốc độ/evasion để kết quả rõ ràng; không thay bộ giải quyết sát thương. Capture mode không ghi vào lượt chơi đã lưu.

```powershell
& '..\love-11.5-win64\lovec.exe' .tmp/motion-check tests/enemy_motion_smoke.lua
& '..\love-11.5-win64\lovec.exe' . --test-enemy-motion --no-motion-preview
```

`docs/enemy_motion.mp4`: trích hai lượt đầu, 1280×720, 20 FPS; fixture HP/giáp dùng để quan sát animation. Không phải phép đo FPS trên điện thoại thật.

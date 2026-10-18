# Nhịp đánh bài và gây sát thương Continental

Phần tiếp theo: [địch tấn công, phản công và nhận sát thương](ENEMY_MOTION.md).

Tiếp nối animation shop và chia/thu bài ngày 17/10/2026. Không thêm tranh, âm thanh hoặc thư viện; giữ các kỹ năng Niệm, màu chất, chùm năng lượng và hiệu ứng chuyển hóa đang có trong game.

## Thay đổi

- **Đưa bài lên đánh:** lấy tâm, góc và kích thước từ lá thực sự đang hiển thị, kể cả hover/tilt. Nhấc 0,06 giây, bay/hạ xuống trong 0,36 giây, lệch 0,045 giây giữa các lá. Dùng `Motion.settle` cùng họ chuyển động với chia bài và shop. Trong lượt đánh, timeline sở hữu chuyển động của lá; physics kéo thả không cộng thêm một quỹ đạo khác.
- **Lá kích hoạt:** thay cú nhấc tức thời bằng nhịp tăng lực rồi hạ xuống trong 0,30 giây. Vị trí, xoay và co giãn dùng cùng một xung; timer theo tốc độ timeline. Mote năng lượng và số đếm có khoảng dẫn nhịp ngắn để đọc được nguồn đóng góp. Mỗi bước vẫn kết thúc tại giá trị do bộ tính điểm cung cấp.
- **Chuyển thành năng lượng:** giữ góc, kích thước và khung đang hiển thị khi bắt đầu dissolve. Highlight của lá dừng khi lá bắt đầu chuyển hóa, tránh để lại viền cố định trên bàn. Kỹ năng, đường phóng và điểm chạm riêng của 27 thế bài tiếp tục dùng hệ thống hiện có.
- **Va chạm:** camera và phản ứng địch dùng xung có điểm đầu/cuối ở trạng thái nghỉ; lực tăng rồi hạ thay vì nhảy ngay tới độ giật lớn nhất. Nghiêng và đổi màu thân địch theo cùng nhịp. Giảm chuyển động bỏ phần bay/xoay bài, giật và co giãn mới; vẫn giữ thông tin tính điểm và phản hồi sát thương.
- **Đánh hụt:** giữ thông báo hụt và đường phóng, bỏ chớp sáng tại điểm chạm thành công; không giật địch hoặc thay đổi HP/giáp.
- **HP và giáp:** giữ số trước đòn đến khi timeline phát sự kiện chạm. Sau đó thanh chính và phần đuôi cùng chạy theo clock tính điểm, có điểm dừng chính xác. Khi mở lại thao tác, HUD không lấy lại một frame từ meter nền còn đang đếm chậm. Snapshot giữ tham chiếu mục tiêu đã nhận đòn để HUD/giật không chạy sang mục tiêu khác.

Không đổi công thức tính điểm, giá trị giáp/HP gameplay, lượt đánh, tỉ lệ trúng hay phần thưởng. Đòn đánh vẫn được giải quyết tại sự kiện contact duy nhất. Số sát thương hiển thị giữ giá trị sau xử lý gameplay, gồm cả overkill; không thay nó bằng lượng HP còn lại của mục tiêu.

## Kiểm chứng

- `tests/combat_motion_smoke.lua`: vị trí đầu/hạ cánh, xung kích hoạt và va chạm liên tục; 30/60/120/144 FPS; HP/giáp không giảm trước contact, không bật ngược và về đúng đích; callback sát thương một lần; không tiêu thụ RNG; giảm chuyển động và đánh hụt.
- `--test-combat-motion`: chuột/phím thật, luồng tính điểm và giải quyết sát thương thật. Fixture kiểm soát kết quả trúng/hụt để kiểm tra rõ từng đường đi. Kiểm tra lặp thao tác không trừ thêm lượt; renderer của HP/giáp và đuôi đọc cùng snapshot; sau hồi phục, HP không nhảy về meter cũ.

| Luồng runtime | Aura | Sát thương được giải quyết | Giáp còn |
| --- | ---: | ---: | ---: |
| Đôi, 5 lá, thường | 52 | 32 | 0 |
| Nhanh, thêm ITM/SPN | 92 | 67 | 0 |
| Giảm chuyển động, giáp chặn hết | 13 | 0 | 99987 |
| Tua nhanh, đánh hụt | 52 | 0 | 30 |
| Kết liễu mục tiêu 1 HP | 13 | 13, có overkill | 0 |
| Địch đánh trước | 13 | 3 | 0 |

Các smoke test scoring presentation, scoring runtime (202 checks), Nen foundation, Nen all-ready, hand VFX/continuity, shop motion và hand/chest motion đều đạt. Chúng bao gồm Normal/Fast/skip/reduced, 27 profile / 81 biến thể và kiểm tra không phát sát thương lặp. Đây là kiểm chứng cho phạm vi thay đổi; không tuyên bố toàn bộ suite gameplay đã đạt.

Chạy với LÖVE 11.5 từ thư mục project:

```powershell
New-Item -ItemType Directory -Force .tmp/combat-motion | Out-Null
& '../love-11.5-win64/lovec.exe' . --test-combat-motion
# Kiểm tra đầy đủ sáu luồng, bỏ xuất PNG preview:
& '../love-11.5-win64/lovec.exe' . --test-combat-motion --no-motion-preview
```

Capture không ghi/xóa save người chơi; PNG tạm nằm trong `.tmp/combat-motion/`. [Video đánh bài → tính điểm → năng lượng → sát thương](combat_motion.mp4) lấy từ render thật với dữ liệu kiểm thử, lấy mẫu theo thời gian mô phỏng. Chưa benchmark FPS hoặc kiểm tra cảm ứng trên điện thoại thật.

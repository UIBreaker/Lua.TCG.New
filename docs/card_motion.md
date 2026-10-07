# Chuyển động và viền lá bài

Tham khảo FFF3.mp4 về nhịp nghiêng nhẹ và hover theo con trỏ; giữ tranh Continental và chất kim loại cổ của game.

- Các renderer dùng chung `src/card_physics.lua`: nhịp đứng yên riêng từng lá, hover nâng 3 px, phóng 2.5%, nghiêng theo vị trí chuột, chuyển trạng thái bằng spring và exponential smoothing. Không ghi trạng thái hình ảnh vào save.
- Bài nhân vật trong trận có cùng thông số nghiêng/hover trong `render/entity.lua`, kết hợp chuyển động tấn công và recoil. Viền nằm cùng transform với tranh.
- `UI.drawCardBorder` dùng ma trận cuối của mặt bài cho viền chọn/tiến hóa vẽ sau. Vùng chọn bài trên tay vẫn neo vào ô để không mất hover ở mép dưới.
- Rương giữ quyền điều khiển lá trong lúc materialize; khi lá sẵn sàng thì chuyển sang hover chung.
- `ui/components/card_frame.lua` giải bậc theo cùng quy tắc của huy hiệu SPN: bậc gốc + tiến hóa, chặn ở UQ và có dấu khắc vượt bậc.

| Bậc | Viền |
| --- | --- |
| C | Đồng cơ bản, nét mảnh |
| UC | Kim loại xanh cổ, khắc góc |
| R | Bạc xanh, nẹp góc và sapphire |
| E | Kim loại tím, góc kép và amethyst |
| L | Vàng cổ, huy hiệu hai đầu và ánh viền nhẹ |
| M | Đồng hồng, góc tỏa nhánh và ruby hai bên |
| T | Bạc lam, điểm sáng và đường khắc bên |
| UQ | Bạch kim tím, vương miện và chòm sao |

Họa tiết ôm vào tranh, cờ đuôi én ở góc trên phải; thu nhỏ vẫn giữ rõ hình chính. Hover làm sáng kim loại nhưng giữ màu bậc.

Kiểm tra đã qua:

- `lovec.exe . --test-card-motion`: 8 bậc ở hai kích thước, hover trên 6 loại bài bằng renderer thật, 30/60/120/144 FPS, rời hover, vùng bấm và viền vẽ sau bám mặt bài; kiểm tra viền tấn công/recoil và không còn viền enemy đã chết.
- `lua tests/card_physics_smoke.lua`: spring, phép đổi tọa độ và giữ quán tính.
- `lovec.exe . --test-hand-drag-select`: 12 chu kỳ kéo chọn ở ba độ rộng cửa sổ; mép lá, cảm ứng, Shift reorder và mất focus.
- `lovec.exe . --test-chest-vfx`: chọn/dùng/giữ bài và trang bị, hủy thao tác, túi đầy, quyền tương tác sau materialize.

Hai kiểm thử cửa hàng cũ chưa tương thích luồng hiện tại: `--test-card-physics` đòi kéo bài stock nhưng cửa hàng hiện dùng chọn rồi xác nhận; `--test-ux-polish` đòi click bài trong deck viewer để bán nhưng luồng đó hiện mở inspector, chỉ chọn hiến tế khi Soul Destroy đang bật. Hai điều kiện này đã có trong HEAD trước thay đổi hover.

Xem `docs/card_rarity_frames.png` và `docs/card_frame_evolution.png`.

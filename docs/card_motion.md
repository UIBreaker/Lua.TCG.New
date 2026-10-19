# Chuyển động và viền lá bài

Tham khảo FFF3.mp4 về nhịp nghiêng nhẹ và hover theo con trỏ; giữ tranh Continental và chất kim loại cổ của game.

Tinh chỉnh tay bài theo nhịp tương tác của FFF4.mp4 (2026-10-11):

- `src/hand_motion.lua` giữ quán tính bằng spring chính xác theo thời gian; hover nâng 14 px, chọn nâng 28 px, hover trên lá đã chọn thêm 6 px. Phóng nhẹ 3.5%/4.5% và nhịp xác nhận nhỏ thay cho nhịp phóng mạnh trước đây.
- Lá hover vẽ trên lá chọn và các lá còn lại. Vùng bấm tiếp tục neo vào ô tay bài để không rung hover ở mép và vẫn kéo chọn nhanh được.
- Ánh xanh khi hover chuyển mềm sang vàng khi chọn; glow và bóng nằm trong cùng transform với tranh/viền kim loại Continental. Trạng thái quán tính/ánh sáng nằm trong bảng weak, không lưu vào card/save.
- Kiểm thử toán và input: `lovec.exe . --test-hand-motion`, `tests/hand_drag_select_smoke.lua`; kiểm thử renderer/input thật: `lovec.exe . --test-hand-drag-select` và `lovec.exe . --test-card-motion`.
- Đã qua: spring ở 30/60/120/144 FPS; 12 lượt kéo chọn ở độ rộng 960/1280/1920, 3 trường hợp mép lá, cảm ứng và Shift reorder; viền của 6 loại bài bám transform. Ảnh kiểm tra: `shot_drag_select.png`.

- Các renderer dùng chung `src/card_physics.lua`: nhịp đứng yên riêng từng lá, hover nâng 3 px, phóng 2.5%, nghiêng theo vị trí chuột, chuyển trạng thái bằng spring và exponential smoothing. Không ghi trạng thái hình ảnh vào save.
- Bài nhân vật trong trận có cùng thông số nghiêng/hover trong `render/entity.lua`, kết hợp chuyển động tấn công và recoil. Viền nằm cùng transform với tranh.
- `UI.drawCardBorder` dùng ma trận cuối của mặt bài cho viền chọn/tiến hóa vẽ sau. Vùng chọn bài trên tay vẫn neo vào ô để không mất hover ở mép dưới.
- Rương giữ quyền điều khiển lá trong lúc materialize; khi lá sẵn sàng thì chuyển sang hover chung.
- `ui/components/card_frame.lua` giải bậc theo cùng quy tắc của huy hiệu SPN: bậc gốc + tiến hóa, chặn ở TT và có dấu khắc vượt bậc. Save cũ UQ+1/UQ+2 hiển thị thành VH/TT mà không đổi sức mạnh.

| Bậc | Viền |
| --- | --- |
| C | Đồng cơ bản, nét mảnh |
| UC | Kim loại xanh cổ, khắc góc và một ánh quét chậm |
| R | Bạc vát cạnh, nẹp góc, sapphire và dòng sáng xanh chạy viền |
| E | Men amethyst, viền khắc kép và đường năng lượng thở nhẹ |
| L | Vàng cổ nổi khối, bệ đá quý hai đầu và hai luồng ánh kim |
| M | Đồng hồng, ruby hai bên và tinh thạch phát sáng theo nhịp |
| T | Bạc lam, hai quỹ đạo ngược chiều và sóng năng lượng vào mép tranh |
| UQ | Bạch kim tím, ba đuôi sao, tinh tú ở góc và bùng sáng bảo thạch |
| VH | Bạc xanh ngọc, nút thắt vĩnh hằng, hai đường dẫn và luồng sáng đan ngược chiều |
| TT | Vàng trắng, bốn luồng sao, hai lớp sóng sáng và vầng mặt trời ở bốn góc |

Họa tiết ôm vào tranh, cờ đuôi én ở góc trên phải; thu nhỏ vẫn giữ rõ hình chính. Hover làm sáng kim loại nhưng giữ màu bậc.

Huy hiệu SPN dùng `Frame.drawRarityPennant` trong cùng khung cơ bản. Bậc càng cao, phù hiệu càng lớn: C/UC là kim loại khắc trên men tối; R/E thêm bảo thạch và viền kép; L/M có vương miện và cánh kim loại; T/UQ thêm quỹ đạo, tinh tú và ánh kim; VH có nút thắt vĩnh hằng màu ngọc; TT có vương miện vàng trắng, tinh thạch và vầng mặt trời bùng sáng. Chữ nổi có bóng, luôn nằm trong bảng men tối để đọc trên cả tranh sáng lẫn tối.

Ánh quét, quỹ đạo và đợt bùng sáng tính theo đồng hồ trình diễn, không dùng RNG gameplay. LOW bỏ các đốm sáng bay; Reduced Motion giữ phù hiệu tĩnh. Mọi chi tiết nằm trong giới hạn lá, theo transform và alpha của lá. Ảnh tổng hợp: `docs/spn_rarity_badges.png`; bản chuyển động: `docs/spn_rarity_badges.mp4`.

Viền động SPN và quân bài dùng `Frame.drawEnergy` ngay trong khung chung, nhận cùng đồng hồ và Reduced Motion với huy hiệu. Quân bài tiến hóa 0–8 dùng lần lượt kiểu viền C–VH; cấp tăng tạm thời có thể nâng tiếp đến TT, rồi trở về viền theo cấp thực khi hết hiệu lực. Số, chất, tốc đánh và hốc trang bị giữ nguyên. Đường dẫn mép được dùng lại; sóng đang lan không được ghi vào cache. Kim loại có cạnh sáng/tối, mặt men và bệ bảo thạch; ánh chạy và tia sáng nằm trong vùng mép để không che chủ thể. LOW giảm số luồng/đoạn và bỏ sóng phụ nhưng vẫn giữ chuyển động của bậc cao; Reduced Motion hoặc tắt hiệu ứng sẽ giữ viền tĩnh. Không áp chuyển động này cho quái, trang bị hay mặt sau lá bài. Ảnh tổng hợp: `docs/spn_rarity_frames.png`, `docs/playing_card_frames.png`; bản chuyển động: `docs/spn_rarity_frames.mp4`, `docs/playing_card_frames.mp4`.

Chỉ số và thẻ tên quân bài dùng `ui/components/card_inscriptions.lua` trong cùng lượt metadata sau khung. Tốc đánh lấy giá trị từ `Deck.getCardAttackSpeed`, sát thương dùng `baseChips` như trước; hiệu ứng không tăng sức mạnh. Mỗi bảng có nền men tối, viền kim loại, ánh chạy, đá quý và tia bùng sáng tăng dần theo giá trị. Chữ giữ nguyên giá trị, tự thu nhỏ theo bề rộng; từ mốc thứ tư có ánh phát quanh chữ số. Tốc đánh dùng lam bạc, sát thương dùng đỏ vàng. Các mốc hiệu ứng:

| Chỉ số | Mốc tăng hiệu ứng |
| --- | --- |
| Tốc đánh | 0, 15, 25, 40, 65, 100, 175, 300, 600, 900 (giới hạn gameplay hiện tại 999) |
| Sát thương | 0, 10, 25, 50, 100, 250, 500, 1000, 2500, 10000 |

Thẻ tên lấy đúng cấp/màu của viền, gồm cả tiến hóa tạm thời; thêm bảo thạch, đường sáng và đỉnh miện theo cấp. Cả ba bảng theo alpha/transform của lá, không hiện khi úp; LOW giảm đốm sáng, Reduced Motion/tắt hiệu ứng giữ tĩnh. `tests/card_inscriptions_capture.lua` kiểm tra 10 mức ở 46/82/200 px, giá trị chính xác gồm số lẻ/số lớn, chuyển động, LOW/Reduced/tắt, alpha/mặt úp, trạng thái graphics và RNG. Xem `docs/playing_card_inscriptions.png` và `docs/playing_card_inscriptions.mp4`.

Ô số/chất cũng nằm trong `card_inscriptions`: khung kim loại theo cấp viền, lõi men ngà cố định để số đỏ/đen luôn tương phản. Số dùng font 22 thay vì 17, tự thu gọn số 10; bốn chất cơ/rô/chuồn/bích vẽ bằng hình học, không phụ thuộc glyph font. Ánh chạy, đá quý và tia sáng nằm quanh khung, không chạy qua số/chất. Kiểm tra 52 tổ hợp số/chất đều có hình ảnh riêng ở cả 46/82/200 px, cùng các kiểm tra alpha/mặt úp/Reduced Motion hiện có. Xem `docs/playing_card_identity.png` và `docs/playing_card_identity.mp4`.

Hốc trang bị dùng chung `Frame.socketGem` trên lá và trong bảng trang bị. Ổ kim loại theo cấp viền của quân bài; màu ngọc và hiệu ứng theo `Equipment.getTier` (8 bậc hiện có, C–UQ). Hốc trống có lòng ổ tối và dấu khắc; hốc đã gắn có ngọc nhiều mặt, bốn chấu, ánh thở. Từ UC có vòng năng lượng, R thêm tinh tú, L có hai quỹ đạo ngược chiều, M/T thêm tia bùng sáng, UQ có vòng xung. Hốc liên kết có dấu mắt xích và ánh dịu hơn. Nhịp kích hoạt vẫn lấy riêng theo từng trang bị từ `CardEffects.getEquipmentPulse`. Vị trí cách mép 6% chiều ngắn, bán kính ngọc 2.5%; ánh sáng nằm trong lá ở cả kích thước nhỏ. Quân bài vẽ hốc đúng một lần sau metadata, cùng transform/alpha của mặt bài. LOW giảm đốm/tia, Reduced Motion/tắt hiệu ứng giữ tĩnh. Không đổi số hốc, bậc hay sức mạnh trang bị. `--test-equipment-sockets` kiểm tra 8 bậc ở 46/82/200 px, giới hạn ánh sáng, liên kết/kích hoạt riêng, alpha/mặt úp, hốc trống, LOW/Reduced/tắt, trạng thái graphics, transform và RNG. Bảng mô tả trong test dùng chế độ mở rộng để kiểm tra cuộn đủ 8 món. Xem `docs/equipment_socket_jewels.png` và `docs/equipment_socket_jewels.mp4`.

Kiểm tra đã qua:

- `lovec.exe . --test-card-motion`: 10 bậc ở hai kích thước và 11 mức tiến hóa gồm TT+1, hover trên 6 loại bài bằng renderer thật, 30/60/120/144 FPS, rời hover, vùng bấm và viền vẽ sau bám mặt bài; kiểm tra viền tấn công/recoil và không còn viền enemy đã chết.
- Kiểm tra huy hiệu trong cùng lệnh: đủ 10 bậc ở 46/82/200 px, tương phản kim loại/men, không tràn ra khỏi lá, Reduced Motion, phục hồi trạng thái graphics, tan biến theo alpha, bám lá khi chuyển động và không thay đổi RNG.
- Kiểm tra viền động trong cùng lệnh: cả SPN và quân bài đủ 10 kiểu ở 46/82/200 px, chuyển động từ UC đến TT, giữ thoáng chủ thể, giới hạn ánh sáng, Reduced Motion, alpha/mặt úp, phục hồi graphics và bám transform. Kiểm tra thêm LOW/tắt hiệu ứng và không tạo Image/Canvas theo frame; có phép đo riêng 15 SPN TT, không coi đó là cam kết FPS trên thiết bị khác.
- `lua tests/card_physics_smoke.lua`: spring, phép đổi tọa độ và giữ quán tính.
- `lovec.exe . --test-hand-drag-select`: 12 chu kỳ kéo chọn ở ba độ rộng cửa sổ; mép lá, cảm ứng, Shift reorder và mất focus.
- `lovec.exe . --test-chest-vfx`: chọn/dùng/giữ bài và trang bị, hủy thao tác, túi đầy, quyền tương tác sau materialize.

Hai kiểm thử cửa hàng cũ chưa tương thích luồng hiện tại: `--test-card-physics` đòi kéo bài stock nhưng cửa hàng hiện dùng chọn rồi xác nhận; `--test-ux-polish` đòi click bài trong deck viewer để bán nhưng luồng đó hiện mở inspector, chỉ chọn hiến tế khi Soul Destroy đang bật. Hai điều kiện này đã có trong HEAD trước thay đổi hover.

Xem `docs/card_rarity_frames.png` và `docs/card_frame_evolution.png`.

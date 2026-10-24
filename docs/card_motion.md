# Chuyển động và viền lá bài

Trạng thái hiện tại: theo yêu cầu bỏ asset viền kim hoàn, renderer đã trở về bộ viền kim loại vẽ bằng mã trước đó. Không tải `assets/ui/jewel_frames/`, không dùng `card_jewelwork.lua` hay shader phản chiếu ảnh khung. Số/chất, tên, chỉ số, hốc trang bị và giới hạn tiến hóa 10 vẫn giữ nguyên. Các mô tả kim hoàn PNG bên dưới là lịch sử phương án đã gỡ khỏi hiển thị.

Tinh chỉnh trên bộ viền bằng mã hiện có: giữ đường bao, vị trí nẹp góc, miện và đặc trưng màu từng bậc. Nẹp được chia thành vai kim loại bắt sáng, mặt satin và mép trong tối; nét biên cơ bản chung được giữ nguyên. Các miếng góc có đường khắc chìm kèm cạnh sáng mảnh, miện có mặt bên tối và rãnh chạm, bảo thạch có bốn mặt cắt cùng mặt bàn sáng và ổ kim loại ôm sát. Không thêm asset ảnh hay thay thiết kế khung. `--test-card-motion` xác minh nét chung trên sáu loại bài, alpha/transform, 10 bậc/3 kích thước, phân biệt cấp 8–10, Reduced Motion/LOW và không tải module ảnh viền đã bỏ. Xem `docs/frame_polish_current.mp4`.

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

| Bậc | Thiết kế kim hoàn hiện có | Chuyển động nhận diện |
| --- | --- | --- |
| C | Đồng cổ và thép tối, khóa góc đúc, đinh tán nhỏ, rãnh da tối | Tĩnh, nổi chiều sâu kim loại cổ |
| UC | Bạc cổ chạm lá acanthus, patina xanh và spinel xanh lá | Một ánh phản xạ chậm đi lên theo nẹp lá |
| R | Khiên bạc khảm sapphire, men xanh đêm và sống kim loại vát | Hai khiên sapphire lóe lạnh luân phiên |
| E | Bạc niello tối, cung nguyệt chạm nổi, amethyst cắt giọt nước | Ánh tím thở theo chu kỳ cung nguyệt |
| L | Vàng cổ chạm nguyệt quế, miện hoa đúc và citrine hổ phách | Ánh vàng tỏa từ miện ra các lá |
| M | Đồng hồng/thiên thạch, lông phượng uốn, ruby đỏ sâu | Vệt lửa đi lên theo lông phượng |
| T | Bạch kim băng, nẹp thủy tinh khắc và aquamarine dài | Khúc xạ băng mảnh trượt hai chiều |
| UQ | Rhodium tối, vòng thiên văn, sao khảm và sapphire tím | Ánh sao chạy trên vòng kim loại thiên văn |
| VH | Vàng/bạc đan nút vô cực, lá nguyệt quế và emerald | Hai phản xạ đan ngược chiều theo nút vô cực |
| TT | Vàng trắng/bạch kim, cánh chạm nhiều lớp và kim cương | Ánh vàng trắng rộng, chậm theo các lớp cánh |
| Quân bài cấp 10 | Cánh kép, hào quang miện và kim cương opal có sẵn | Ba sóng sáng từ miện xuống viền, miện bùng sáng, phản sắc opal |

Đại tu ngày 2026-10-24 thay toàn bộ nẹp đa giác cũ bằng 11 PNG UI được tạo qua 11 lần gọi built-in image_gen riêng, giữ nguyên tranh Continental. Ảnh nằm ở `assets/ui/jewel_frames/`, tâm và nền có alpha trong suốt. Prompt nguyên văn, nguồn và ánh xạ từng ảnh: `docs/FRAME_JEWEL_ASSETS.json`; đăng ký trong `docs/asset_manifest.json`. Đây là lớp trang trí do renderer chung ghép lên, không có chữ, rank/chất hay huy hiệu vẽ cứng trong ảnh.

Tinh chỉnh tiếp theo yêu cầu giữ thiết kế hiện có: không thay hay tạo thêm PNG. Shader tăng tương phản phần chạm nổi, độ trong màu đá và ánh phản chiếu; giữ nguyên alpha và dáng khung. Mỗi bậc dùng nhịp sáng trong bảng trên. Cấp 10 có ba sóng sáng, quầng sáng ngay trên chi tiết miện và phản sắc opal, phân biệt với cánh vàng trắng cấp 9. Ánh mạnh được nén mềm theo phần sáng còn lại của chất liệu để tránh mất nét chạm khi bùng sáng. Kiểm tra `frame_tier_identity` so 55 cặp chất liệu/relief ở 46/82/200 px, đo mức phát sáng qua 12 thời điểm của cấp 9/10 và kiểm tra uniform của khung cao không ảnh hưởng khung thấp. Các kiểm tra LOW, Reduced Motion, alpha, giới hạn ánh sáng và GPU cache nằm trong `--test-card-motion`.

Video tinh chỉnh trên ảnh hiện có: `docs/frame_refinement_all.mp4` (C–TT, cấp 0–9) và `docs/frame_refinement_10.mp4` (so sánh cấp 8/9/10). Kết quả kiểm tra: 55 cặp khác nhau tối thiểu 75% theo tiêu chí alpha/luminance của test; phát sáng cấp 10 trung bình 3.35× cấp 9 trong 12 thời điểm lấy mẫu. Đây là phép đo renderer phục vụ phân biệt hiệu ứng, không phải hệ số sức mạnh gameplay.

`ui/components/card_frame.lua` vẫn sở hữu silhouette vát góc và nét biên chung cho các loại bài. Nó dùng `card_jewelwork.lua` để tải/ghép ảnh, rồi vẽ huy hiệu, metadata và hốc bằng các thành phần hiện có. Mỗi PNG được lấy mẫu một lần vào Canvas 384×576 có alpha premultiplied; ảnh nguồn giải phóng khỏi GPU sau đó. 11 texture cache chiếm khoảng 9.3 MiB RGBA8, không tính các asset khác. Không tạo Image/Canvas theo frame.

`shaders/card_jewel_glints.glsl` chỉ chiếu sáng lên phần ảnh khung có alpha: ánh phản xạ quét chéo theo mặt kim loại, vệt phản xạ ngược chiều từ bậc cao, điểm ngọc lóe thành tia nhỏ. Luminance của chất liệu quyết định nơi nhận phản sáng, nên không vẽ vòng sao rời hoặc ánh sáng qua cửa sổ giữa. C đứng yên; UC–TT tăng cường độ/độ dày điểm lóe; cấp 10 tăng thêm và dùng ảnh riêng. LOW giảm mật độ điểm lóe. Reduced Motion/tắt hiệu ứng giữ khung ảnh tĩnh. Hiệu ứng theo cùng transform/alpha, không dùng RNG gameplay.

Quân bài vẫn có cấp 0 ban đầu và tối đa 10 lần tiến hóa: 0–8 tương ứng C–VH, 9 dùng TT, 10 dùng biến thể opal riêng. Tiến hóa tạm thời tiếp tục cộng vào bậc hiển thị. Không đổi giới hạn, chỉ số, giá hoặc xác suất. Huy hiệu SPN dùng `Frame.drawRarityPennant` như trước, cùng đồng hồ trình diễn.

Ảnh xem trước: `docs/spn_rarity_frames.png`, `docs/playing_card_frames.png`, `docs/playing_card_evolution_10.png`; video cùng tên đuôi mp4. `tests/frame_tier_identity.lua` kiểm tra 45 cặp bằng thang xám của chất liệu và silhouette ở 46/82/200 px, không có tranh/chữ/chuyển động. Đây là phép kiểm tra nhận diện, không phải điểm thẩm mỹ. Ảnh kiểm tra: `docs/frame_tier_silhouettes.png`.


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

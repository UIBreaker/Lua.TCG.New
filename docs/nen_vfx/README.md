# TERRA SUIT — Niệm combat VFX

27 thế, 6 hệ trình diễn, 81 biến thể có renderer và contact thực thi. Dùng hình thể procedural gốc, shader/material preload và audio synthesis riêng; không dùng asset hoặc animation từ tác phẩm khác. Hệ Niệm chỉ trình diễn kết quả do resolver/scoring hiện có chốt.

## Chạy và xem

**F6** mở Lab, ←/→ chọn thế, **1/2/3** chọn cấp, **N** lọc hệ, **R** replay, **+/-** điều chỉnh AURA, **Tab** Fast, **Q** LOW/MEDIUM/HIGH, **B** cỡ boss, **L** slow motion, **T** timeline, **V** target anchor, **M** Reduced Motion, **Space** skip. Lab có đủ 81 biến thể, particle/draw counters và không mượn run hiện tại. Reduced Motion cũng có trong Tùy chọn → Thế giới điện ảnh và được lưu vào settings.

Ảnh trận thật nằm trong `final/`: `<hand_id>_tier<1..3>_<anticipation|attack|impact|after_contact>.jpg`. Bộ ảnh gồm lượt checkpoint 4 cho cả 81 và ảnh cập nhật checkpoint 5 cho 30 tổ hợp; các frame shader fallback được giữ để QA. Vì số sát thương đã dời sang bên ở lượt polish cuối, các ảnh checkpoint 4 còn thể hiện vị trí/nhãn cũ. Các tấm `review_*` gom 18 biến thể/tấm để so silhouette, formation, flight và contact. Ảnh chụp được giữ dưới dạng JPEG để tránh đưa hàng trăm MB PNG vào project.

## Điểm tích hợp đã audit

| Thành phần | Cách tích hợp |
|---|---|
| `main.lua`, `src/poker.lua`, `src/advanced_hands.lua` | Truyền đúng `evalResult.type.id` từ resolver; không phát hiện lại hand bằng VFX. Giữ điều kiện, priority, unlock và Sảnh 3 lá. |
| `src/scoring.lua` | Đọc `finalScore` đã chứa ST, Cường hóa, local AURA, extra damage, Edition, ITM/SPN, flat/debt/caps. Không tính lại score. |
| `src/scoring_presentation.lua` | Giữ log card scoring/retrigger. Một RELEASE chính, một ENEMY_IMPACT yield đến combat handler cũ. |
| `src/hand_attacks.lua` | Điểm nối chung của game và Lab; giữ API geometry/tier cũ cho callers và regression fixtures. |
| `render/renderer.lua`, `render/nen_effects.lua` | Vẽ Niệm trong world pass sau quái; bloom/lighting/camera ở world, HUD sắc nét ngoài pass. |
| Card motion / frame / dissolve | Đúng scoringCards, card ID và nguồn y365. Dùng canvas/shader dissolve preload hiện có. Khung chung tan/thu/chuyển động cùng artwork; không xóa card gameplay. |
| Combat / HP / armor | `Combat.resolvePlayerAttack` giữ quyền damage/reward. HP chờ contact, trail settle trước mở khóa. Tesla giữ bonus 18 vốn có, không nhân damage theo số tia. |
| Boss reaction / camera | Enemy formation nhận recoil/squash; impulse có damping, zoom nhỏ theo cấp. Reduced Motion bỏ camera/zoom/distortion, giảm hit-stop/reaction/number pulse. |
| Audio | Dùng mixer/voice pool/cooldown/headroom/duck có sẵn. 108 cue Niệm PCM gốc preload; không load file hoặc clone trong attack. Missing optional audio không chặn combat. |
| Scene / saves | Encounter mới cancel presentation. Snapshot/particles không vào run save; chỉ thêm boolean Reduced Motion vào settings, không đổi save version. |

Graphify graph 232 node dùng để định hướng; các điểm tích hợp đã đối chiếu lại source thật vì graph cũ. Không nâng dependency hoặc thay engine.

## Power và timeline

`config/nen_vfx_config.lua` là nguồn chung cho taxonomy, 27 profile, 3 choreography/profile, thresholds, quality, timing, hit-stop và repeat acceleration.

Reference mặc định = tổng **maxHP + giáp** của encounter / 2 tay dự kiến. Reference không phụ thuộc HP còn lại nên không tự tăng tier khi quái gần chết. Thiếu reference dùng 1000; giá trị invalid/infinite được chặn. `targetAura` override chỉ có trong fixtures/Lab. Không thêm công thức round progression; reference tự theo độ bền quái đã cân bằng.

Ratio AURA/reference: **I <0.70**, **II 0.70–<1.80**, **III ≥1.80**. Niệm giữ riêng `attack.nen.tier` (1–3); legacy tier API vẫn tồn tại cho callers cũ. AURA snapshot bất biến, ratio hiển thị có trần 64.

PREPARE → ANTICIPATION → NEN_AWAKENING → CARD_TRANSFORMATION → CHARGE → RELEASE → TRAVEL → ENEMY_IMPACT → AFTERSHOCK → SETTLE. Gia tốc flight, launch pose đóng băng, card fragments đi đúng emitter; các beat không tự gây damage. Settle có sàn cho HP trail. Đánh liên tục cùng mục tiêu trong 9s tăng tốc ultimate tối đa 24%; không tăng tốc scoring trigger. Fast ×2, forward ×3 vẫn đi qua contact một lần.

## 81 biến thể

| ID | I | II | III |
|---|---|---|---|
| high_card | Lá bọc Niệm + thương đơn | Kỵ sĩ lấy đà chéo | Kỵ sĩ cưỡi thú, gait + rạn ánh sáng |
| pair | Hai bóng hộ vệ | Khiên khóa trước, thương sau | Hai vệ binh lớn trên cung giao nhau |
| two_pair | Hai cặp đòn ở hai cánh | Cánh trái/phải đánh lệch nhịp | Hộ vệ + cờ, gọng kìm rộng |
| three_of_a_kind | Ba thương theo nhịp | Tam giác ba thương đồng thời | Ba thương hợp thành đại thương |
| straight | Rank trails theo thứ tự | Bộ binh + tuyến hành quân | Kỵ binh tăng tốc trên tuyến |
| flush | Năm dải cùng Chất | Một lá cờ Niệm | Đại kỳ cuốn thành xoáy |
| full_house | Pháo đài nhỏ, một phát | Hai tháp, hai phát | Năm tháp bắn loạt |
| four_of_a_kind | Bốn trụ ép đồng thời | Bốn trụ ép theo nhịp | Bốn đòn nặng có nhấc/giáng, vòng nén |
| straight_flush | Thương hoàng gia đơn | Năm đoạn thương hợp nhất | Nén không gian rồi phóng đại thương |
| tesla_369 | Ba arc từ đúng 3/6/9 | Arc liên kết + nhánh | Ba cột/cuộn điện + sét trung tâm |
| jackpot_777 | Ba ấn vàng | Ba ấn khóa kho báu | Máy tiền cổ, vòng quay + loạt tiền |
| fibonacci | Xoắn ốc sinh trưởng | Năm ấn/pulse tăng dần | Vòng vàng co và cuộn các mũi nhọn |
| prime | Năm sao độc lập | Đường cong/quỹ đạo riêng | Năm khóa mục tiêu hội tụ |
| odd_star | Bình minh tỏa tia | Mặt trời chín tia | Đại nhật + chín vệ tinh/tia tăng tốc |
| even_frost | Năm thương băng | Mũi khoan ghép ba tầng | Thành băng + khoan năm tầng |
| crimson_tide | Sóng đỏ đơn | Hai dòng từ hai phía | Ba dòng triều + huyết nguyệt |
| obsidian_tide | Mảnh đá đen bất đối xứng | Hai sóng đá răng cưa | Đại thương địa chất, fracture |
| eclipse_duality | Hai quầng đối cực | Nguyệt thực qua mặt trời | Corona nén, mặt tối, rạn không gian |
| four_kingdom_prism | Lăng kính + tia bốn màu | Bốn tuyến khúc xạ | Hợp tia thành thương quang phổ |
| four_kingdom_expedition | Bốn luồng liên minh | Bốn cờ đánh theo tuyến | Cờ + hộ vệ + đường chiến trường |
| destiny_crown | Vương miện + kiếm đơn | Năm kiếm phán quyết | Đại kiếm + nghi thức năm ấn |
| continental_gate | Bốn ấn + khóa | Cổng cổ mở hai cánh | Đại cổng, silhouette thế giới bên kia, chùm lực |
| answer_42 | Năm tọa độ liên kết | Dẫn đường qua waypoint | Bản đồ sao + tuyến định hướng |
| sealed_gate | Cổng triệu hồi kiếm | Ba ấn + ba kiếm | Hai trụ, nghi thức + đại kiếm |
| seven_stars | Bảy sao theo cung | Chòm sao liên kết | Bảy đợt sao băng lớn |
| five_ley_lines | Năm mạch nền | Trụ/mạch kích theo lớp | Hội tụ thành phun trào trung tâm |
| endless_cycle | Vòng khép kín | Hai quỹ đạo ngược | Ba vòng tăng tốc, co lõi và xé không gian |

Khác biệt nằm ở dựng hình, đường bay, nhịp, hợp nhất/phân nhánh, contact và vật liệu; không chỉ thay màu/scale. Bóng người/thú là hình học Niệm có chuyển động, không phải sprite nhân vật vẽ tay nhiều frame.

## Checkpoint và bằng chứng

| Checkpoint | Kiểm chứng |
|---|---|
| 1 — Foundation | 27 ID / 6 hệ; relative-tier boundaries, snapshot, multiple targets/dead target, 3-card Straight, cancellation 10 pha, single release/contact, Fast/Skip/Reduced. |
| 2 — Sáu mẫu | 18 biến thể: 180 trận thật, 36 Lab Normal/Fast; xem 72 frame bốn pha, sửa framing kỵ sĩ. |
| 3 — Chín thế cơ bản | 27 tổ hợp trong trận thật + 360 chuỗi logic lúc gate; xem formation/flight, dời pháo đài khỏi HUD, xác nhận lại trong lượt toàn bộ. |
| 4 — Mười tám nâng cao | 243 trận thật cho toàn bộ 81 biến thể; HIGH, MEDIUM thiếu material shader, LOW Reduced, Normal/Fast; đúng resolver, HP/damage/thưởng/input, một release. |
| 5 — Polish | Chạy lại 30 tổ hợp bị ảnh hưởng: gait, hammer path, ice drill framing, sword angle, obsidian slabs/material, contact beam, number pulse và vị trí nhãn thưởng. 108 PCM cue khác nhau, peak/energy kiểm chứng. |
| 6 — Performance | Shader và geometry của 81 biến thể prewarm khi load. Scratch buffer dùng lại, particle stateless/capped 8/16/24, Source pool 3/cue, mixer trần 24 voices. 1200 create/release/cancel (<64KB GC growth); 810 warm-up + 810 chuỗi đo mixed profiles (<250KB GC growth). Native HIGH Lab 81×Normal/Fast không export trong lượt đo. |
| 7 — Final QA | Cả 81 có renderer/contact; tối thiểu 10 lần liên tục mỗi biến thể trong test logic, 243 trận thật trước polish + 30 sau polish + 162 native Lab. Canvas/shader/scissor/blend/linewidth/transform restore; optional audio/reload/fallback; regression bên dưới. |

Đo frame interval thực tế ở `benchmark.txt`, có log outliers ở `benchmark_spikes.txt`: HIGH, 81×Normal/Fast, 22776 khung hình, trung bình **6,06ms**, P95 **6,79ms**, P99 **7,06ms**, peak **9,39ms**; không có frame đo vượt 16,67ms. Lượt đo không export ảnh, bỏ 1s khởi động Lab và 120ms đầu mỗi case; shader/geometry/GPU prewarm khi load. Không tính chi phí khởi tạo game vào số đo đòn đánh. `combat_benchmark.txt` là lượt trận thật có screenshot/encoding, không dùng peak của lượt này làm GPU benchmark. Draw count được đọc sau draw; counter trận thật ở cuối attack draw, counter Lab gần cuối frame. Đây là số đo trên host này, không bảo đảm 60 FPS trên mọi máy.

Regression PASS: 270 scoring cơ bản; 135 basic + 270 advanced continuity; 18 advanced condition/priority/reward/planet/chest/save; 24 hands có equipment/Edition/SPN; **11232 Continental52 scenarios**; 9 Edition (Echo/Evolution/Wild…); 154 runtime checks / 87 ITM / 48 SPN; SPN snapshots/convergence và spectral persistence; bed/initiative/speed; mixer và missing assets.

## Lệnh lặp lại

Chạy từ project root với LÖVE 11.5 (`love` hoặc `lovec`):

```text
lovec tests/nen_runner
lovec . --test-hand-vfx-combat --nen-samples
lovec . --test-hand-vfx-combat --nen-basics
lovec . --test-hand-vfx-combat --nen-all
lovec . --test-hand-vfx-combat --nen-polish
lovec . --test-hand-vfx --nen-lab --nen-benchmark
lovec . --test-hand-vfx --nen-lab --nen-all-lab
```

Native capture giữ timing ultimate, chỉ tăng tốc phần bookkeeping trước ultimate. Headless runner dùng assertions, không cần UI/window. `tests/nen_gallery.py` chỉ là tiện ích review ảnh với Pillow; game không phụ thuộc Python.

Giới hạn art/audio: silhouette Niệm procedural và âm thanh tổng hợp gốc đã hoạt động và qua kiểm tra; chưa có animation nhân vật vẽ tay hoặc Foley thu âm. Đánh giá cảm giác trên loa/tai nghe và cấu hình GPU khác vẫn cần kiểm tra trực tiếp. Không coi một bài test hoặc một frame đẹp là bảo đảm chất lượng cảm nhận trên mọi máy.

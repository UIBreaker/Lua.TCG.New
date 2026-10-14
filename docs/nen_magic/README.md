# 27 Niệm Attack VFX — hoàn tất ngày 15/10/2026

27 chiêu chạy trong chiến đấu thật qua `HandAttacks.draw → NenEffects.draw → NenMagic.draw`. Không thay cách nhận diện tay bài, công thức, số lần gây sát thương, điểm tiếp xúc hay thời điểm hiện số. Tên tay bài đang hiển thị trong game được giữ nguyên; các tên dưới đây là tên tạo hình VFX.

## Bảo vệ hệ thống số

- Baseline: `a96534232f9fb69d9f6dad3b5a5d52d03052e52c`; working tree sạch lúc bắt đầu.
- [protected.json](protected.json): đầy đủ 37 đường dẫn và SHA-256 của scoring, damage, UI, camera, postprocess, audio, shader số và font. Các phụ thuộc bổ sung được xác nhận Git diff rỗng so với cùng baseline trước khi ghi nhận checksum.
- [protection_results.txt](protection_results.txt): 36 tệp nguyên byte; main.lua chỉ khác nhãn phiên bản menu khi đóng gói. Kiểm tra bảo vệ cho phép riêng thay đổi nhãn đó, giữ kiểm tra toàn bộ code còn lại.
- [damage_preservation.txt](damage_preservation.txt): 76 so sánh từng pixel của lớp số hiện tại trước/sau khi vẽ attack; 19 giá trị từ 0 đến `1e308`, bốn tuổi hoạt ảnh `.04/.14/.4/.9` giây. Không sao chép hay thay renderer số.
- [damage_baseline.png](damage_baseline.png) và [damage_after_attack.png](damage_after_attack.png) là cặp ảnh lossless tiêu biểu, giống hệt nhau.
- Attack shader chỉ dùng trong lệnh vẽ chiến trường, khôi phục shader/Canvas/blend/scissor/transform sau khi vẽ. Bloom dùng pipeline world đã có; HUD và số vẽ sau đó. Không thêm shake, popup, công thức hay callback damage.

Ảnh tham chiếu của hệ số không đi kèm prompt này. Phép so sánh pixel dùng chính renderer hiện hành trong project làm chuẩn, không tuyên bố so sánh với một ảnh tham chiếu chưa nhận được.

## Tệp

Tạo mới:

- `config/nen_magic_config.lua`: registry 27 chiêu, palette, vũ khí, số lượng, chuyển động, kiểu nổ, chất lượng và chuẩn hóa AURA.
- `src/nen_magic.lua`: trạng thái hình ảnh độc lập, đường bay, bốn cấp AURA, API preview `play/update/clear`.
- `render/nen_magic.lua`: vật liệu, vệt sáng thuôn, hạt theo hướng, nổ, fallback CPU và khôi phục trạng thái graphics.
- `shaders/nen_magic.glsl`: bề mặt vũ khí, lõi/rìa/halo, vật liệu đá có thân tối, 27 silhouette va chạm.
- `tools/nen_preview/main.lua`, `conf.lua`: trình xem thử độc lập, không gây damage hay ghi save game.
- `tests/nen_magic_smoke.lua`, `nen_magic_damage_capture.lua`, `nen_magic_edges.lua`, `nen_magic_protection.py`, `nen_magic_gallery.py`: kiểm tra và tạo bằng chứng.
- Thư mục tài liệu này: baseline, log, ảnh native và bảng xem.

Chỉnh hai tệp có sẵn:

- `render/nen_effects.lua`: đúng ba dòng thêm để preload và gọi renderer mới. Giữ bộ biến đổi lá bài và code cũ.
- `tests/hand_vfx_combat_capture.lua`: thêm chế độ kiểm tra bốn mức AURA, đối chiếu pixel, đường xuất riêng và đo khi không chụp ảnh. Chỉ là harness kiểm tra.

## 27 chiêu đã có hình ảnh và chạy được

Tất cả dòng dưới đã được render native, thử bốn mức AURA × 10 lần liên tục, và chạy qua luồng chiến đấu thật. “Hoàn tất” là trạng thái triển khai/kiểm tra; cảm nhận mỹ thuật vẫn cần người chơi đánh giá trong game.

| # | ID / tạo hình | Chuyển động | Vụ nổ đặc trưng | Trạng thái |
|---|---|---|---|---|
| 01 | `high_card` — KIẾM NIỆM | Một kiếm cyan chĩa mũi rồi lao tăng tốc | Vết chém dài + vòng dạng lưỡi | Hoàn tất |
| 02 | `pair` — SONG KIẾM NIỆM | Kiếm xanh/vàng vòng đối xứng | Chém X, tia theo bốn hướng | Hoàn tất |
| 03 | `two_pair` — SONG NHẬN | Hai lưỡi cong cam/xanh ép hai bên | Hai cánh phong nhận | Hoàn tất |
| 04 | `three_of_a_kind` — TAM THƯƠNG | Ba thương lệch nhịp | Sóng tam giác | Hoàn tất |
| 05 | `straight` — VẠN TIỄN | Hàng bảy tên lao dồn | Quạt sáng vàng | Hoàn tất |
| 06 | `flush` — PHONG NHẬN | Trăng khuyết xanh lượn gió | Xoáy gió ba nhánh | Hoàn tất |
| 07 | `full_house` — NGŨ THẠCH | Năm khối đá nóng có vân lửa | Khối lửa, đá văng và sóng mặt đất | Hoàn tất |
| 08 | `four_of_a_kind` — TỨ TRỤ | Bốn tinh thể băng ép vào tâm | Vỡ chéo và mảnh băng | Hoàn tất |
| 09 | `straight_flush` — THÁNH THƯƠNG | Thương vàng từ trên, vòng sáng | Cột quang và halo ngang | Hoàn tất |
| 10 | `tesla_369` — TAM LÔI | Ba tia sét lệch nhịp | Plasma, ba nhịp sét ngắn, electric sparks | Hoàn tất |
| 11 | `jackpot_777` — KIM TIỀN | Ba đồng xu quay | Sao vàng, xu và hạt lấp lánh | Hoàn tất |
| 12 | `fibonacci` — SINH MỆNH XOÁY | Hai dải sống quấn xoắn | Hoa năng lượng năm cánh | Hoàn tất |
| 13 | `prime` — NGŨ TINH | Năm ngôi sao hội tụ | Sao năm cánh sắc và bụi sao | Hoàn tất |
| 14 | `odd_star` — CỬU QUANG | Chín tia nắng từ trên | Nhật quang có vành lửa | Hoàn tất |
| 15 | `even_frost` — BĂNG TIỄN | Bảy mũi băng tăng tốc | Khối tinh thể sáu nhánh vỡ | Hoàn tất |
| 16 | `crimson_tide` — HỒNG TRIỀU | Sóng ruby lướt ngang | Vòng chất lỏng, giọt văng rồi rơi | Hoàn tất |
| 17 | `obsidian_tide` — HẮC THẠCH | Đá đen góc cạnh, khe tím | Mảnh sắc tím, thân đá tối | Hoàn tất |
| 18 | `eclipse_duality` — NHẬT NGUYỆT | Hai khối đỏ/tím hội tụ | Tâm tối và vành nhật thực | Hoàn tất |
| 19 | `four_kingdom_prism` — TỨ SẮC QUANG | Bốn tia màu gom vào tâm | Lăng kính bốn hướng + mảnh màu | Hoàn tất |
| 20 | `four_kingdom_expedition` — TỨ KIẾM | Bốn kiếm quay quanh rồi đâm | Xoáy bốn màu | Hoàn tất |
| 21 | `destiny_crown` — HOÀNG QUANG | Vương miện vàng/tím bay cong | Năm tia và halo hoàng kim | Hoàn tất |
| 22 | `continental_gate` — CỔNG HƯ KHÔNG | Cổng rune phóng cầu xanh | Vòng không gian giao nhau | Hoàn tất |
| 23 | `answer_42` — THIÊN LA BÀN | Kim la bàn khóa hướng, phóng tên | Tám hướng tọa độ vỡ | Hoàn tất |
| 24 | `sealed_gate` — THỨC TỈNH QUANG | Cửa sáng phát tia | Hai cánh sáng có lớp lông quang | Hoàn tất |
| 25 | `seven_stars` — THẤT TINH | Bảy sao rơi có vệt dài | Sao bảy cánh và bụi sao | Hoàn tất |
| 26 | `five_ley_lines` — NGŨ MẠCH | Năm dòng mặt đất gom cầu | Năm nhánh nguyên tố | Hoàn tất |
| 27 | `endless_cycle` — VÔ TẬN LUÂN | Vòng vô cực tím/vàng/xanh | Xoáy và nhiều lớp sóng | Hoàn tất |

Xem [27 đường bay](review_travel.jpg), [27 vụ nổ](review_impact.jpg), [sáu ví dụ phóng/va chạm](highlights.jpg). PNG nguồn được render trực tiếp bằng LÖVE, không phải ảnh concept.

## AURA, vật liệu và hiệu năng

- Chỉ đọc AURA và reference của snapshot đã có. Tỷ lệ AURA/reference chia tại `.7 / 1.8 / 4`: NORMAL, ENHANCED, OVERDRIVE, MAXIMUM. Preview mặc định reference = 1000; chiến đấu dùng reference của encounter hiện tại. Không thay ba tier cũ đang điều khiển timeline/audio/số.
- Chuẩn hóa logarithm và chặn ratio ở 32; size tối đa 1.45; particle tối đa 8/16/24 theo LOW/MEDIUM/HIGH. 0, âm, NaN, vô cực và `1e308` không tạo hình học vô hạn.
- Đường bay được tính theo tiến độ, trail lấy mẫu lại đường cong, không phụ thuộc số frame đã chạy. Projectile/hạt không tạo image, shader hoặc Canvas mỗi frame.
- Shader mới dùng analytic distance fields cho blade, guard, grip, crescent, crystal, crown, star, plasma và infinity; đá có pass thân tối trước phát sáng. Nổ có lõi cục bộ, khối chính, sóng, hạt văng và falloff ngắn. MAXIMUM có lớp sóng bổ sung; reduced motion bỏ ảnh lưu và lớp sóng phụ.
- Bloom chiến đấu tái sử dụng shader/pipeline world hiện tại. Preview có Canvas half-resolution với bright pass + Gaussian ngang/dọc từ shader hiện có, điều chỉnh thông số trong config mới. Không sửa shader/pipeline số hoặc UI.

## Mở preview

Từ thư mục gốc project, PowerShell:

```powershell
& '..\love-11.5-win64\lovec.exe' tools/nen_preview
```

Nếu dùng LÖVE đã cài trong PATH: `love tools/nen_preview`.

| Phím | Chức năng |
|---|---|
| ← / → | Chọn một trong 27 chiêu |
| R / Space | Phát lại / pause |
| 1 / 2 / 3 / 4 | AURA 200 / 1000 / 2500 / 8000 |
| + / − | Điều chỉnh AURA liên tục |
| Tab | 0.5× / 1× / 2× |
| Q | LOW / MEDIUM / HIGH |
| B | Bật/tắt Bloom |
| E | Chỉ xem vụ nổ |
| F | 1280×720 / 1920×1080 / 960×540 |
| Esc | Thoát |

FPS, số particle, số lượt vẽ vật liệu, cấp AURA hiển thị trong preview. Đây là tool riêng; màn hình preview số và phím trong game không đổi.

## Kiểm tra tái lập

```powershell
& '..\love-11.5-win64\lovec.exe' tools/nen_preview --verify
& '..\love-11.5-win64\lovec.exe' tests/nen_runner
& '..\love-11.5-win64\lovec.exe' . --test-hand-vfx-combat --nen-magic
& '..\love-11.5-win64\lovec.exe' . --test-hand-vfx-combat --nen-magic-timing
& '..\love-11.5-win64\lovec.exe' . --test-hand-vfx-combat --nen-magic-edges
python tests/nen_magic_protection.py
python tests/nen_magic_gallery.py
```

- [native_results.txt](native_results.txt): 1.080 lượt native, 27.000 frame kiểm tra; 27 fallback không shader; state restoration, snapshot, particle budget, cancel đạt. Thêm 270 vòng tạo/vẽ/xóa sau warm-up, JIT tắt: retained heap 34,9 KB, dưới ngưỡng 128 KB. Image GPU không tăng.
- [native.log](native.log): resize 960/1280/1920, pause, replay, AURA 0/cực lớn, xóa giữa hoạt ảnh đạt. Mục tiêu mất/di chuyển dùng tọa độ snapshot, mục tiêu đã chết và cancel không vẽ thêm.
- [edges.txt](edges.txt): ca native hạ quái ngay khi chạm chỉ gây damage một lần rồi kết thúc; gọi `UI.Debug.clearScene()` giữa TRAVEL hủy chiêu, không vẽ hoặc gây sát thương lên mục tiêu của trận mới, và trận mới nhận được lượt đánh tiếp theo.
- [regression.log](regression.log): bộ kiểm tra sẵn có đạt, gồm 810 sequence × hai pass, Normal/Fast/skip/reduced motion, single contact, 30/60/144 FPS, score/HP, advanced hands, equipment/SPN và audio.
- [combat_final.log](combat_final.log): 27 × 4 = 108 lần chạy qua combat thật, trải đều ba chất lượng và Normal/Fast. Kiểm tra HP, input lock, once-only advanced effects, kết thúc lượt, không GPU allocation trong draw đạt. Đợt này có chụp/encode ảnh nên không dùng spike thời gian làm số đo riêng của VFX.
- [combat_timing.log](combat_timing.log) và [combat_final/performance.txt](combat_final/performance.txt): thêm 108 ca combat không chụp ảnh, bao gồm game/UI/audio trên máy kiểm tra; 41.428 frame, trung bình 6,15 ms, P95 7,01 ms, P99 7,67 ms, đỉnh 1.499,22 ms. Harness khởi tạo lại encounter và đổi chất lượng giữa các ca; chưa tách nguyên nhân đỉnh này, không gán nó cho riêng VFX và không khẳng định game luôn giữ 60 FPS. Sau đó chỉnh độ xòe hình cánh sáng, chạy lại toàn bộ 1.080 lượt native để xác nhận hình học cuối.

Máy kiểm tra: NVIDIA GTX 1650, OpenGL 3.3, LÖVE 11.5. Batch VFX riêng có GPU readback: trung bình 0,217 ms/frame, P95 0,283 ms, tối đa 15,439 ms; đây không phải FPS toàn game hay bảo đảm trên phần cứng khác.

## Giới hạn

- Chưa chạy trên điện thoại/Android hoặc GPU khác. Fallback CPU giữ nhận diện chính, ánh sáng/vật liệu đơn giản hơn shader.
- Lượt đo toàn game còn có spike nêu trên; đây chưa phải chứng nhận không giật trên mọi cảnh hoặc thiết bị.
- Audio và chuyển đổi lá bài giữ nguyên cue/timeline đã có; không thu hoặc thiết kế lại 27 sound mới. Việc giữ nguyên là chủ đích để tránh thay đồng bộ số sát thương.
- Một snapshot đích vẫn hoàn tất hình ảnh tại vị trí cuối nếu đối tượng biến mất; việc gây damage/cancel do combat hiện tại quyết định. Renderer không nắm quyền gọi damage hay đổi mục tiêu.
- Ca đổi cảnh dùng hàm reset cảnh sẵn có `UI.Debug.clearScene()`. Trong quá trình thử, gọi thẳng hai helper `startNewGame/startMonsterEncounter` khi đang scoring mà bỏ qua reset để lại cờ `anim.active`; không coi đường gọi helper đó là một ca chuyển cảnh đã đạt, và không sửa `main.lua` thuộc vùng được bảo vệ.
- Preview dùng dummy và nhịp trình diễn riêng; thời lượng trong game luôn theo timeline hiện hành để bảo toàn gameplay và số.
- Bộ so sánh pixel chứng minh lớp số không bị sửa hoặc nhiễm graphics state. Toàn khung hình khi bật Attack VFX đương nhiên khác ở chiến trường; không tuyên bố toàn ảnh game giống trước.

# Giường phát nổ — implementation và polish

Hook thật: `Inventory.useBed` đặt giường lên quái. `Combat.bedExplosions` dùng chung điều kiện SPN Ngủ Dưới Địa Ngục và slot lock với resolver hiện có. Khi scoring tới final_score, main giữ bước này trong pendingBedScore, chạy anticipation, rồi gọi resolver đúng tick detonation. Damage AoE lấy từ callback SPN hiện có (catalog hiện tại: 500%), giáp, quái chết bởi đòn đầu, hồi máu của giường thường, thứ tự splash và RNG gameplay được giữ nguyên. Không thêm mechanic.

`src/bed_explosion.lua` là presentation: bed gỗ/chăn/kim loại nguyên bản, 64 record pool tạo một lần, tối đa 54 record mặc định HIGH (36 debris, 7 smoke, 11 ember). Mỗi mảnh có velocity, drag theo vật liệu, gravity, spin và tối đa một bounce. Không tạo Image/Canvas/Shader lúc kích hoạt. `shaders/bed_explosion_fire.glsl` được compile/cache một lần ở startup: khối lửa cuộn, pocket nhiệt và viền than thay các miếng lửa polygon phẳng. Lõi contact có tia sáng sắc; debris lớn hơn và vận tốc 280–750px/s ngang, 260–700px/s dọc, trail ngắn. Glow/smoke/dust dùng radial sprite đã cache của lighting. Shockwave dùng world_composite hiện có; waveAspect làm distortion khớp ellipse perspective. UI được vẽ sau world nên không bị distortion/flash.

Polish: anticipation 50ms; core flash 35ms; fire delay 8ms, fireball 300ms/radius 190px; shockwave delay 12ms, đạt 320px trong 135ms; dust delay 60ms; smoke delay 90ms; hit-stop 80ms; camera shake 220ms với cubic falloff; light decay 240ms; scorch 1.25s; settle toàn bộ 1.35s sau nổ. Contact được giữ ở frame đầu khi máy có frame chậm. Mảnh vỡ nóng ngắn rồi về màu gỗ/chăn/kim loại. Khói/bụi mép mềm; môi trường mưa giảm bụi và đổi khói sang hơi xám. Recoil chỉ thay visual offset của quái/card world.

Audio hooks charge / boom / debris / rumble được giữ nguyên, dùng cue đã preload của hệ thống Sound hiện tại, gain có giới hạn và pitch variation nhẹ. Không sử dụng asset/code/sound bên thứ ba.

Các thế bài dùng cùng nhịp contact trong `src/hand_attacks.lua`: vòng chấn động nứt nhẹ theo ellipse phối cảnh, một vòng lõi theo sau, tia sáng bắn thành quạt không lặp hướng, lõi sáng nóng hơn và decay nhanh. Kiểu damage riêng của chín hand (pierce/cross/collapse/seal/wave/detonation/convergence) được giữ làm silhouette chính. Sóng tầm 118px, tan trong 290ms. Recoil theo độ xa tâm nổ để quái ngoài shockwave không bật mạnh như mục tiêu.

## Tuning và replay

`config/bed_explosion_config.lua` giữ timing, palette, physics, light, camera và LOW/MEDIUM/HIGH. Gameplay tự lấy quality của renderer.

F8 bật panel debug. B replay; 1/2/3 chọn quality; C bật/tắt camera; V bật/tắt distortion; [ / ] chỉnh debris; - / + chỉnh radius; H đổi hit-stop 40–80ms; K chỉnh camera kick. Replay chỉ là presentation, không gây damage.

## Kiểm tra

- `lua tests/bed_explosion_smoke.lua`: 90 lần liên tục qua 3 quality và 30/60/144 FPS; kiểm tra single contact, audio ordering, giới hạn/reuse pool, one bounce, RNG không đổi, debug và frame stall không bỏ core.
- `lovec . --test-bed-explosion`: 10 lần thực sự qua scoring → giường → detonation → damage trên nhóm 3 quái; Normal/Fast, 3 quality, khóa đánh lần hai, HP giữ nguyên trong anticipation và HP đúng ở draw contact, AoE đúng theo callback SPN hiện tại, audio resources và shaders không fallback; không tạo GPU resource trong explosion draw. Sau đó chụp 6 lớp hiệu ứng.
- `lovec . --test-bed-explosion --bed-preview-only`: capture riêng HIGH với physics/light được tiến bằng bước 1/120s.
- Regression qua: bed_speed_smoke (heal, lethal trap, locked SPN, single-use, AoE), hand_vfx_smoke (270 scoring sequence và 135 continuity case), scoring_presentation_smoke (24 hand, nhiều FPS/speed), enemy_group_smoke (240 encounter).
- `spn_combat_smoke.lua:65` có assertion cũ đòi 21 SPN; catalog hiện có 22. Đã xác nhận cũng lỗi khi nạp Combat nguyên bản từ HEAD; không phải regression của VFX này.

Ảnh review: `bed_explosion/anticipation.png`, `contact.png`, `shockwave.png`, `fireball.png`, `debris.png`, `smoke.png`. Kiểm tra FPS ở trên là simulation dt và tính ổn định motion; không phải cam kết FPS GPU trên mọi máy. Không thay toàn bộ renderer hoặc thêm thư viện.

## Lượt nâng cấp hình ảnh cuối

Lửa có flow warp, chi tiết nhiệt nhỏ, normal từ độ dốc billow, vùng soot tối và lõi nóng có ngưỡng riêng; viền rõ hơn để giữ khối trên nền sáng. Mảnh gỗ có cạnh tước/grain, vải có nếp biến dạng, kim loại có cạnh bắt sáng; vẫn cùng pool và số hạt. Các thế đánh dùng thân có màu dưới alpha blend và cạnh emissive, tránh trắng bệt trên nền vàng. Thêm hình kết riêng cho chín hand và sửa scratch buffer shockwave dùng chung với slash gây điểm thừa.

Kết quả bản cuối: native hand combat 9 thế × 10 lượt liên tiếp, LOW/MEDIUM/HIGH, Normal/Fast; HP đổi đúng một lần, khóa input và không cấp phát Image/Canvas/Shader trong attack draw. Headless LÖVE: 270 scoring sequences, 135 continuity cases, 24 scoring presentation cases và 90 explosion repeats ở 30/60/144 FPS; bed/speed regression qua. Native fire shader đã compile khi chạy trận; 6 frame explosion được chụp ở lượt đầu. Khởi chạy LÖVE mới bị kẹt trước entry của mã game ở lượt thử cuối, nên chưa xác nhận lại 10 trận nổ và chưa chụp lại phần tinh chỉnh viền/grain cuối. Không ghi lượt bị kẹt là pass.

`lovec . --test-hand-vfx-combat --vfx-review` chạy lại 90 trận và lưu 27 ảnh anticipation/attack/impact trong `docs/vfx_review/`. Test explosion tính expected splash từ callback SPN để giữ thông số gameplay hiện tại, không ép về hệ số cũ.

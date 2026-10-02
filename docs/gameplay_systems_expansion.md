# Gameplay Systems Expansion — báo cáo triển khai

## Kết quả và cách dùng

Đã mở rộng Card/Combat/Shop hiện có; không tạo Card system, renderer hoặc combat loop thứ hai. Áp dụng đủ 52 khả năng, 3 Boss mới, kỹ năng chủ động cho 19 định nghĩa Boss cũ, tiến hóa theo instance và mô tả tập trung.

- Chuột phải vào **Lá Tiến Hóa**: chọn quân bài hoặc SPN, xem thông số TRƯỚC → SAU, rồi xác nhận. Hủy không mất thẻ.
- Quân bài thường có `evolutionLevel` 0–5; cấu hình được. SPN vẫn dùng hệ độ hiếm/tiến hóa riêng hiện có, không bị cap 5 của quân bài thường.
- Mọi “+1/+2 bậc” tăng **thông số khả năng**, không đổi rank/chất. Cấp “đến hết trận” nằm ở `temporaryAbilityLevels`; cấp lâu dài cập nhật đúng ID trong bộ bài.
- Khi khả năng yêu cầu trả Vàng/hiến tế/chọn mục tiêu, modal xuất hiện trước khi commit Chơi Tay Bài. Chọn bỏ qua từng khả năng hoặc Esc để hủy cả lần chơi, không tự chi tài nguyên.
- F4 mở glossary; Esc đóng. Hover hiển thị khả năng, thông số đã giải quyết, tiến hóa hiện tại/kế tiếp, Tâm/Vàng tích và khóa Boss.
- Các lá cùng rank/chất là các instance riêng. Tiến hóa một lá không nâng cả template.

## Kiến trúc và thứ tự thực thi

### Card abilities

`config/card_ability_data.lua` chứa ID, rank/chất, trigger, op, baseParams, evolutionRules và template mô tả.
`src/card_abilities.lua` giải quyết thông số, dispatch trigger và quản lý state trận/tay/instance; các op không được rải thành 52 if/elseif trong scoring.

Thứ tự thực tế:

1. Poker.evaluate chọn thế đánh và các lá được tính điểm, giữ thứ tự hiển thị ổn định.
2. Thu thập lựa chọn tự nguyện; chưa commit và chưa chi tài nguyên.
3. beginHand: snapshot tay ban đầu, lựa chọn trước chấm điểm, before_score, not_scored, rồi mồi retrigger.
4. Theo luật tốc đánh hiện có, quái nhanh hơn có thể đánh trước. Khóa nội tại từ 4♠/A♠ được xử lý trước bước này.
5. Queue chấm các lá gốc theo thứ tự hiển thị; từng job đi qua ability, điểm/role/modifier/ITM/SPN hiện có. Retrigger được nối FIFO sau các job đã xếp.
6. Khi queue hết: lựa chọn sau chấm điểm (2♠/5♠); nếu tiêu hủy K♣ tạo thêm job, tiếp tục drain queue. Điểm nền của thế đánh chỉ tính một lần.
7. SPN toàn tay và tổng kết Aura sử dụng công thức hiện có; shader/presentation chỉ đọc kết quả, không chấm lại.
8. Presentation scoring → chuyển năng lượng → impact → HP settle. Sau đó trả đúng instance còn sống từ discard về tay, xử lý held/hand_end và Boss active.
9. Kết thúc vòng tài nguyên: round_end trước đòn quái cuối lượt; redeal/reset tài nguyên rồi round_start/hand_start. Kỹ năng sát thương Boss được drain đúng một lần ở cả Play Hand và Kết thúc lượt.

J♥ dùng vị trí bên trái trên tay hiển thị; J♣ dùng lá scoring trước theo cùng thứ tự; J♦ dùng lá Rô vừa kích hoạt; J♠ dùng instance tiêu hủy gần nhất. Khi đồng cấp, “thấp nhất” chọn lá đầu tiên theo thứ tự ổn định; bậc ở đây là cấp khả năng theo xác nhận của người dùng.

Các hooks ITM onHandEvaluate vẫn là đánh giá toàn tay một lần. Retrigger lặp điểm và hiệu ứng per-card, không nhân lại điểm nền/tất cả hook toàn tay một cách mù quáng. Tái kích hoạt SPN tính lại phần thưởng số của callback đầu tiên qua hệ hiện có.

### Boss

`src/boss_abilities.lua` dùng ngay monster.bossState: countdown, telegraph, cooldown, passive/active lock, cancel/delay/skip, slot lock và đánh dấu Forgotten.
Nội tại cũ vẫn được gọi từ Combat/Scoring/Monster hiện có, nhưng có gate vô hiệu chung. Slot lock không xóa vật phẩm. Khóa lượt không hạ tài nguyên xuống dưới 1. Boss đã chết không dùng kỹ năng hay giữ khóa sang shop.

3 Boss mới đi vào pool/progression hiện có: Thu Thuế Đen, Nuốt Ký Ức, Giữ Cổng. Thu Thuế Đen là định nghĩa mới riêng, không thay Boss Taxman cũ.

### Evolution và save

`A.params(card)` = base + scaling theo cấp; hỗ trợ cộng mỗi cấp hoặc bước theo số cấp. `A.evolve(game,card)` nâng đúng instance, đồng bộ persistentDeck, giữ rank/chất. Preview dùng chính resolver này.
Save tiếp tục schema đang có, bổ sung default cấp 0 và normalize ID trùng/thiếu trong save cũ. Không yêu cầu xóa save. State tạm trong trận được reset; save/continue hiện có vẫn vào shop/chọn ải, không mở thêm cơ chế resume giữa scoring.

5♥ được bổ sung Giáp trên mỗi lá còn sống trả về khi tiến hóa: ở cấp cuối, dù đã trả đủ năm lá, nâng tiếp vẫn thực sự có lợi. Cấp 0 vẫn giữ hành vi gốc.

### Tooltip và feedback

`src/card_description.lua` resolve quân bài, SPN, ITM, ấn/rèn, ấn bản, tiêu hao, tiến hóa, bình máu, phiếu và rương từ catalog/runtime hiện có.
SPN lấy giá trị đã scale theo độ hiếm; ITM, modifier, consumable và voucher dùng cùng params với logic. Aura/Hex đọc bonus ấn bản trực tiếp từ CardEffects.
Tooltip artwork PNG không được viết chữ lên ảnh: mô tả là overlay hover riêng.

Dùng lại score pulse, âm thanh và floating text hiện có; copy có echo/đường nguồn→J. Không thêm screen shake cho từng trigger. Evolution dùng pulse/toast/âm thanh nâng cấp hiện có.

## Protection chống loop

- maxRetriggerDepth = 4; maxCopyDepth = 3.
- maxTriggersPerHand = 128; maxRetriggersPerCard = 8.
- Queue hữu hạn và visited chain theo ability ID.
- J không copy J; copy held/choice được xử lý đúng ngữ cảnh, không mở prompt giữa scoring.
- Những ability sinh retrigger chỉ tạo lịch một lần mỗi nguồn/original job; copy có iteration key riêng nhưng vẫn chịu budget.
- Tiêu hủy có destructionNotified theo instance; K♣ chỉ truy cập tay đang mở, không lặp destruction.
- Card đã bị tiêu hủy không được trả lại tay. Card trả về rời discard, không tạo clone.
- Preview không mutate ability state và không chi Vàng.
- Thông báo trigger không làm thay đổi số damage; không re-evaluate để vẽ.

## File đã tạo/sửa

Tạo:

- `config/card_ability_data.lua`
- `src/card_abilities.lua`
- `src/boss_abilities.lua`
- `src/card_description.lua`
- `ui/ability_choices.lua`
- `tests/gameplay_expansion_smoke.lua`
- `tests/gameplay_expansion_capture.lua`
- `scripts/describe_gameplay_expansion.lua`
- `docs/gameplay_systems_expansion.md`

Sửa:

- `main.lua`, `capture_screens.lua`
- `src/deck.lua`, `src/poker.lua`, `src/scoring.lua`, `src/combat.lua`
- `src/monster.lua`, `src/run_manager.lua`, `src/persistence.lua`
- `src/deities.lua`, `src/equipment.lua`, `src/shop.lua`, `src/ui.lua`
- `src/scoring_presentation.lua`, `ui/card_surfaces.lua`, `ui/components/hand_info_panel.lua`

Test LÖVE tạo log `expansion_*stdout/stderr.log`, screenshot `shot_expansion_*.png` và cập nhật một số screenshot hồi quy. Không commit, không đổi asset gốc hoặc shader GLSL trong task này.

## Test đã chạy

Pure Lua — đều PASS:

- gameplay_expansion_smoke: 52 registration + handler thực + tooltip + evolution + instance identity + save mới/cũ; 10 combo; 22 lifecycle active/counter và 22 nội tại qua gameplay hooks.
- Trường hợp biên: Q chơi nhưng không scoring vẫn xả tích; 2♥ không hồi sinh bạn bài; 5♥ cấp 4→5 mạnh hơn dù trả đủ 5 lá; ID save cũ trùng; Boss chết không ra đòn; pendingDamage và feedback được consume một lần.
- test_poker: 10 loại thế bài + integration scoring, tổng 11 test.
- card_effects_smoke: bonus ấn bản/roll/state.
- scoring_presentation_smoke: 24 tay, 30/60/120/144 FPS, Normal/Fast, Aura tới 1e15, một hit tổng, HP settle.
- card_physics_smoke: inverse transform, momentum, 60/120/144 FPS.
- shop_vouchers_smoke: 9 phiếu, giá, hồi máu, reroll, hiến tế, save/reset.

LÖVE 11.5 thật — đều PASS:

- --test-gameplay-expansion: chuột phải Tiến Hóa, 53 instance, before/after, confirm giữ identity, cancel choices, tiêu hủy/upgrade lưu đúng ID, scoring→energy attack→return integrity.
- --test-card-effects: compile thành công cả 3 shader thật.
- --test-pack-skip: bỏ qua cả 9 pack, không nhận thưởng/hoàn tiền ngoài luật.
- --test-card-physics: 46 trường hợp hold/drag qua các bề mặt card hiện có.
- --test-shop-deck-drop: 22 trường hợp mua kéo-thả, 9 pack/card backs.
- --test-scoring-feel: 4 case Aura/đòn đánh chính xác, including Boss chuyển Aura nửa damage; Lab isolated khoảng 4.49 ms/frame trong lần đo này (không phải bảo đảm hiệu năng trên mọi máy).

Kiểm tra loadfile mọi Lua source và git diff --check: PASS.
Test test_system.lua cũ cần khởi tạo graphics/fonts LÖVE, không được tính là suite pure Lua đã PASS. Các capture LÖVE phía trên kiểm tra các đường UI/runtime liên quan.

Lưu ý test combo năm lá: Poker hiện có vẫn phân loại bốn lá 5 giống rank là Tứ Quý, không tự biến thành “5 lá scoring”. Test phần điều kiện đúng 5 scoring dùng contract scoring rõ ràng; không thêm Five of a Kind hay sửa luật poker.

## Lỗi phát hiện và sửa

- Instance thiếu/trùng ID trong save cũ; clone Cryptid thiếu identity riêng.
- Khả năng chạy lặp khi preview hoặc đọc lại context đã finish.
- Thiếu nguồn Rng cho nhánh brittle.
- Q bị chơi nhưng không scoring không xả tích; lá đã chơi quay lại tay bị tính nhầm là held.
- 2♥ trả nhầm/chạm lá đã bị hiến tế; evolution số lần trả không có tác dụng trong Pair.
- 5♥ cấp cuối không có lợi nếu chỉ tăng số lá trả vượt quá 5.
- Giáp chống đòn đầu vòng bị reset quá sớm trước đòn cuối lượt.
- K♣ destruction ngoài tay mới lặp lại context cũ.
- Copy Q dùng state sau xả thay vì snapshot trước xả.
- Boss The Arm báo “lâu dài” nhưng chưa đồng bộ persistentDeck; giờ chỉ giảm những lá thật sự scoring. Đây là nội tại cũ có chủ đích đổi rank, KHÔNG phải hành vi Evolution.
- Bonus Cổng Hẹp/Hành Quyết tích lũy nhầm vào base attack.
- Khóa resource được trả lại nhiều lần gây refill miễn phí; nay release/restore theo delta một lần.
- Boss chết vẫn chạy end-hand và giữ slot lock sang shop.
- Boss fixture không có name làm panel LÖVE crash; thêm fallback.
- Kỹ năng damage Boss chưa drain khi chỉ Kết thúc lượt; nay dùng chung resolveBossDamage, không áp dụng hai lần.
- Feedback cuối tay ghi vào combat queue nhưng đọc nhầm finished hand; nay drain đúng queue.
- Mô tả modifier/tiêu hao/ITM/SPN lệch số thực; chuyển resolver về dữ liệu chung.
- Tránh thêm nhiều local module vào closure main để không tái phát giới hạn 60 upvalues của LuaJIT; module UI được truy cập qua namespace UI hiện có.

## Chỉnh balance ở đâu

- `config/card_ability_data.lua`: toàn bộ baseParams/evolutionRules, cap Evolution và các budget loop.
- `src/boss_abilities.lua`: Boss.config và Boss.actives (amount/cooldown); progression trong run_manager/monster.
- `src/deities.lua`: params SPN và độ hiếm/scaling hiện có.
- `src/equipment.lua`: params ITM.
- `src/deck.lua`: params enhancement/seal hiện có.
- `src/shop.lua`: CONSUMABLE_RULES, voucher params/giá.
- `config/card_effect_config.lua`: bonus Foil/Holographic/Polychrome (task này chỉ đọc, không tuning shader).
- `src/poker.lua`: cấp/thông số thế đánh hiện có; không được tự động chỉnh bởi Evolution quân bài.

Các thông số không có scaling trong bảng dưới giữ nguyên. “+n” là cộng mỗi cấp; “/ 2 levels” là tăng theo bước hai cấp. Cấp tạm cộng vào resolver nhưng không được save lâu dài. Balance đã tách để chỉnh, chưa khẳng định cân bằng hoàn hảo.

Có thể tái sinh hai bảng cuối từ dữ liệu thật: `lua scripts/describe_gameplay_expansion.lua`.

## 52 lá và bảng tiến hóa

| Lá | Ability ID — Tên | Trigger | Cấp 0 | Tăng mỗi cấp |
|---|---|---|---|---|
| A♥ | `heart_ace` — Khoang Dự Trữ | held | capacity=1 | capacity +1 |
| 2♥ | `heart_2` — Không Rời Nhau | score | count=2, returnArmor=0, returns=1 | returnArmor +2 |
| 3♥ | `heart_3` — Nhịp Thở Thứ Ba | score | armor=3, draw=1, play=3 | armor +1, draw +1 |
| 4♥ | `heart_4` — Bốn Mạch | score | armor=8, suits=4 | armor +2 |
| 5♥ | `heart_5` — Giữ Người Ở Lại | score | count=5, returnArmor=0, returns=1 | returnArmor +1, returns +1 |
| 6♥ | `heart_6` — Tiết Chế | round_end | armor=6, discards=1 | armor +2 |
| 7♥ | `heart_7` — Ví Cứu Mệnh | damage | block=7, cost=1, threshold=7 | block +2 |
| 8♥ | `heart_8` — Hộ Linh | hand_start | armor=1 | armor +1 |
| 9♥ | `heart_9` — Hành Trang Đầy | held | capacity=1 | capacity +1 |
| 10♥ | `heart_10` — Trưởng Thành | upgraded | capacity=1 | capacity +1 |
| J♥ | `heart_jack` — Phản Chiếu | held | range=1 | range +1 |
| Q♥ | `heart_queen` — Tích Tâm | hand_end | gain=1, healPercent=2, maxStacks=3 | healPercent +0.5, maxStacks +1 / 2 levels |
| K♥ | `heart_king` — Di Nguyện | destroyed | armor=10, healPercent=25 | armor +2, healPercent +5 |
| A♦ | `diamond_ace` — Tay Đầy Túi Đầy | hand_start | gold=1 | gold +1 |
| 2♦ | `diamond_2` — Giao Dịch Đôi | score | count=2, gold=1 | gold +1 |
| 3♦ | `diamond_3` — Lần Ba Có Lãi | score | gold=3, play=3 | gold +1 |
| 4♦ | `diamond_4` — Đa Dạng Hóa | score | gold=2, suits=4 | gold +1 |
| 5♦ | `diamond_5` — Đầu Tư Năm Lá | score | count=5, levels=1 | levels +1 |
| 6♦ | `diamond_6` — Tiền Dư | round_end | gold=1, maxGold=2 | maxGold +1 |
| 7♦ | `diamond_7` — Lãi Suất | combat_win | divisor=7, gold=1, maxGold=3 | maxGold +1 |
| 8♦ | `diamond_8` — Hoa Hồng SPN | spn | gold=1, required=3 | gold +1 |
| 9♦ | `diamond_9` — Hoàn Tiền | consumable | gold=1 | gold +1 |
| 10♦ | `diamond_10` — Đầu Tư Nâng Cấp | choice | cost=2, levels=1 | levels +1 |
| J♦ | `diamond_jack` — Sao Kê | score | copies=1 | copies +1 |
| Q♦ | `diamond_queen` — Gửi Tiết Kiệm | hand_end | gain=1, maxStacks=3 | maxStacks +1 |
| K♦ | `diamond_king` — Di Sản | destroyed | gold=8, levels=1 | gold +2, levels +1 |
| A♣ | `club_ace` — Tràn Nhịp | score | repeats=1 | repeats +1 |
| 2♣ | `club_2` — Song Kích | score | repeats=1 | repeats +1 |
| 3♣ | `club_3` — Nhịp Ba | score | play=3, repeats=1 | repeats +1 |
| 4♣ | `club_4` — Tứ Hợp | score | repeats=1, suits=4 | repeats +1 |
| 5♣ | `club_5` — Đầu Cuối Tương Ứng | score | count=5, repeats=1 | repeats +1 |
| 6♣ | `club_6` — Mồi Nhịp | discard | repeats=1 | repeats +1 |
| 7♣ | `club_7` — Mua Nhịp | choice | cost=2, repeats=1, threshold=7 | repeats +1 |
| 8♣ | `club_8` — Dội SPN | spn | repeats=1 | repeats +1 |
| 9♣ | `club_9` — Dư Âm Tiêu Hao | consumable | repeats=1 | repeats +1 |
| 10♣ | `club_10` — Theo Kịp | score | repeats=1 | repeats +1 |
| J♣ | `club_jack` — Bắt Chước | score | copies=1 | copies +1 |
| Q♣ | `club_queen` — Đánh Trượt Có Chủ Ý | not_scored | repeats=2 | repeats +1 |
| K♣ | `club_king` — Tiếng Vọng Cuối | destroyed | repeats=1 | repeats +1 |
| A♠ | `spade_ace` — Đốt Đường Lui | choice | duration=1 | duration +1 |
| 2♠ | `spade_2` — Một Mất Một Còn | choice | levels=1 | levels +1 |
| 3♠ | `spade_3` — Tam Phong Ấn | score | cancels=1, play=3 | cancels +1 |
| 4♠ | `spade_4` — Bốn Dấu Ấn | before_score | duration=1, suits=4 | duration +1 |
| 5♠ | `spade_5` — Hiến Tế Thứ Năm | choice | count=5, hands=1 | hands +1 |
| 6♠ | `spade_6` — Trì Hoãn | discard | duration=1 | duration +1 |
| 7♠ | `spade_7` — Hối Lộ Bóng Tối | choice | cost=7, duration=2 | duration +1 |
| 8♠ | `spade_8` — Phong Ấn SPN | choice | duration=1, required=3 | duration +1 |
| 9♠ | `spade_9` — Vật Tế | choice | cancels=1 | cancels +1 |
| 10♠ | `spade_10` — Trao Đổi Bậc | choice | costLevels=1, levels=2 | levels +1 |
| J♠ | `spade_jack` — Hồn Kẻ Đã Mất | score | copies=1 | copies +1 |
| Q♠ | `spade_queen` — Đánh Sai Có Chủ Đích | not_scored | cancels=1 | cancels +1 |
| K♠ | `spade_king` — Đoạn Tuyệt | destroyed | duration=1, skip=1 | duration +1 |

## Boss: nội tại, chủ động, hồi chiêu, counter

Telegraph lần đầu: 1 tay; sau mỗi lần dùng/hủy: cooldown + 1 tay. Counter chung: 3♠/Q♠/9♠ hủy, 6♠ trì hoãn, K♠ bỏ hành động, A♠/4♠/7♠ tắt nội tại, 8♠ khóa cả hai.

| Boss ID — Tên | Nội tại | Chủ động | Cooldown | Counter theo build |
|---|---|---|---|---|
| `black_tax_collector` — KẺ THU THUẾ ĐEN | Cuối tay: lấy tối đa 1 Vàng nếu có ít nhất 1. Hết Vàng: +1 Nợ (tối đa 10); mỗi Nợ thêm 1 sát thương Tịch Thu. | Tịch Thu: Khóa ô Tiêu Hao số 1 tay kế tiếp; sát thương Nợ 0. | 2 | Chi tiền trước thuế; giữ lá Bích để hủy Tịch Thu |
| `damage_resist` — BÁ VƯƠNG GIÁP SẮT | Kháng 20.0% mọi sát thương nhận vào. | Nghiền Giáp: Bào 6 Giáp người chơi. | 2 | Tắt nội tại trước đòn mạnh |
| `echo_knight` — HIỆP SĨ VỌNG ÂM | Vọng Âm Nghịch Đảo: Nếu đánh cùng kiểu bài với lượt trước, Mult của thế bài đó = 0! | Dội Âm: Tay kế tiếp: lặp thế đánh vừa dùng sẽ mất 2 Cường hóa. | 2 | Đổi thế đánh giữa hai tay |
| `executioner` — ĐAO PHỦ HẮC ÁM | Khi người chơi dưới 40.0% HP tối đa: đòn đánh ×2, bỏ qua Giáp; không xóa Giáp. | Lưỡi Đao: Gây 3 sát thương (được Giáp chặn). | 2 | Giữ HP trên ngưỡng; hủy Lưỡi Đao |
| `faceless` — NGƯỜI KHÔNG MẶT | Vô Diện Bí Mật: Toàn bộ bài trên tay đều bị Úp Mặt (Face-down) suốt trận chiến! | Mặt Nạ Câm: Khóa khả năng lá đã báo trước trong tay kế tiếp. | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |
| `gatekeeper` — NGƯỜI GIỮ CỔNG | Đầu tay có hơn 5 lá: mỗi lá dư tăng 1 tấn công trong tay đó; không giảm kích thước tay. | Phong Tỏa: Khóa 1 lượt bỏ bài tay kế tiếp; không hạ dưới 1. | 2 | Cân nhắc tay lớn / tấn công tăng; giữ tài nguyên dự phòng |
| `gem_devourer` — KẺ ĂN NGỌC | Cuối tay: nuốt một ITM ngẫu nhiên từ lá đang giữ, hồi 40 HP nếu nuốt được. | Nuốt Linh Lực: Hồi 12 HP; không xóa thêm trang bị. | 2 | Chơi lá có ITM để không giữ trên tay |
| `less_discard` — CHÚA QUỶ GAI GÓC | Lời nguyền Gai Độc: Giảm 1 lượt Đổi bài (Discard) của bạn! | Gai Trói: Khóa 1 lượt bỏ bài tay kế tiếp (không hạ dưới 1). | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |
| `lock_aurelia` — KHÓA QUANG HUY | Quang Huy Tắt Lịm: Toàn bộ bài phe Aurelia (Ánh Sáng) bị vô hiệu hóa (0 Chips / 0 Mult)! | Dấu Ấn Câm: Khóa khả năng lá thuộc chất áp chế đã báo trước trong tay kế tiếp. | 2 | Dùng chất/rank khác hoặc tắt Nội Tại |
| `lock_elaris` — KHÓA SINH LINH | Rừng Già Khô Cạn: Toàn bộ bài phe Elaris (Thiên Nhiên) bị vô hiệu hóa (0 Chips / 0 Mult)! | Dấu Ấn Câm: Khóa khả năng lá thuộc chất áp chế đã báo trước trong tay kế tiếp. | 2 | Dùng chất/rank khác hoặc tắt Nội Tại |
| `lock_royals` — TRẢM VƯƠNG QUAN | Trảm Vương: Khóa toàn bộ bài Hoàng Gia (J, Q, K - 0 Chips / 0 Mult)! | Câm Vương: Khóa khả năng một lá J/Q/K đã báo trước trong tay kế tiếp. | 2 | Dùng chất/rank khác hoặc tắt Nội Tại |
| `lock_valoria` — KHÓA THIẾT HUYẾT | Khí Giới Rỉ Sét: Toàn bộ bài phe Valoria (Nhân Loại) bị vô hiệu hóa (0 Chips / 0 Mult)! | Dấu Ấn Câm: Khóa khả năng lá thuộc chất áp chế đã báo trước trong tay kế tiếp. | 2 | Dùng chất/rank khác hoặc tắt Nội Tại |
| `lock_vharos` — KHÓA HẮC ÁM | Lửa Quỷ Đóng Băng: Toàn bộ bài phe Vharos (Hắc Ám) bị vô hiệu hóa (0 Chips / 0 Mult)! | Dấu Ấn Câm: Khóa khả năng lá thuộc chất áp chế đã báo trước trong tay kế tiếp. | 2 | Dùng chất/rank khác hoặc tắt Nội Tại |
| `max_3_cards` — HẠN CHẾ BINH LỰC | Hạn Chế Binh Lực: Mỗi tay bài xuất trận chỉ được chọn tối đa 3 lá bài! | Ép Quân: Khóa 1 lượt đánh tay kế tiếp (không hạ dưới 1). | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |
| `max_4_cards` — TỐI THƯỢNG MA THẦN | Hư Vô Tận Diệt: Giảm 1 lượt Đổi bài và giới hạn tối đa 4 lá bài mỗi lượt đánh! | Ép Quân: Khóa 1 lượt đánh tay kế tiếp (không hạ dưới 1). | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |
| `memory_eater` — KẺ NUỐT KÝ ỨC | Lá đầu tiên tái kích hoạt mỗi tay bị Quên Lãng: từ lần tái kích hoạt tiếp theo, khả năng không chạy; điểm cơ bản vẫn chạy. | Xóa Dấu: Khóa khả năng lá đã báo trước trong tay kế tiếp; vẫn tính điểm bình thường. | 2 | Chia retrigger ra nhiều lá; bảo vệ khả năng lá mục tiêu |
| `taxman` — KẺ THU THUẾ | Mỗi lá tạo Aura trả 1 Vàng; không đủ trả sẽ mất 3 HP. | Truy Thu: Lấy tối đa 2 Vàng, không tạo nợ HP. | 2 | Giữ Vàng để không mất HP |
| `the_arm` — CỰ MA BÀN TAY | Bàn Tay Suy Đồi: Mỗi lượt đánh, các lá bài tạo Aura bị suy đồi giảm vĩnh viễn 1 Rank! | Bàn Tay Câm: Khóa khả năng lá đã báo trước trong tay kế tiếp; không đổi rank/chất. | 2 | Bích vô hiệu nội tại trước khi scoring |
| `the_fish` — VUA BIỂN ĐÊM ĐEN | Màn Đêm Vô Tận: Mọi lá bài rút lên đều bị Úp Mặt (Face-down)! | Mù Sương: Úp mặt lá đã báo trước trong tay kế tiếp. | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |
| `the_hook` — MA THẦN LƯỠI CÂU | Mỗi khi chơi: bỏ ngẫu nhiên tối đa 2 lá còn giữ trên tay; kích hoạt hiệu ứng Khi Bỏ. | Móc Câu Ký Ức: Khóa khả năng lá đã báo trước trong tay kế tiếp. | 2 | Giữ 6♣/6♠ để tận dụng Khi Bỏ |
| `the_needle` — CHÚA TỂ KIM NHỌN | Kim Nhọn Tuyệt Mạng: Chỉ có duy nhất 1 Lượt Đánh (1 Hand) cả trận! | Xuyên Tâm: Gây 3 sát thương (được Giáp và Ví Cứu Mệnh chặn). | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |
| `the_water` — THỦY THẦN NƯỚC LŨ | Nước Lũ Tối Tăm: Bắt đầu trận đấu với 0 Lượt Đổi bài (0 Discards)! | Triều Dâng: Khóa 1 lượt bỏ bài tay kế tiếp (không hạ dưới 1). | 2 | Đọc telegraph; giữ Bích hủy/trì hoãn; dự trữ lượt |

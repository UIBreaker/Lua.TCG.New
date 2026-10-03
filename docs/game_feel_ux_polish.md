# Game Feel + UX Polish

## Phạm vi

Mở rộng renderer và luồng input hiện có, không tạo Card system thứ hai. Không sửa công thức điểm, poker, khả năng, giá, luật bộ bài, Boss hay định dạng save. `UI.Polish` chỉ giữ trạng thái trình bày trong module; không gắn timeline/Canvas vào dữ liệu lưu.

Backend `Shop.buyItem`, `sellCard`, `sellConsumable`, `sellDeity` vẫn kiểm tra điều kiện và cập nhật tài nguyên đúng một lần. `Shop.reroll` chỉ thêm callback refresh tùy chọn: cách tính/trừ giá, lượt miễn phí và voucher giữ nguyên; dữ liệu hàng được refresh muộn khi mặt trước đã bị che. Người gọi cũ không truyền callback vẫn hoạt động như trước.

## File của pass này

Tạo:

- `config/ux_polish_config.lua`: thời lượng, hover/focus, stagger, tốc độ, số shard và điểm HUD.
- `src/ux_polish.lua`: focus/giao dịch, reroll timeline, dissolve dùng chung và phản hồi thay đổi thông số.
- `shaders/card_dissolve.glsl`: noise đa tần, mép sáng, alpha/premultiplied alpha đúng.
- `tests/ux_polish_smoke.lua`: kiểm tra backend/UI timeline không cần cửa sổ.
- `tests/ux_polish_capture.lua`: kiểm tra input, shader/pixel và luồng thực trong LÖVE.
- Tài liệu này.

Sửa:

- `main.lua`: nối input/animation/activation/scoring, khóa thao tác, bỏ mua bằng drop, xóa tooltip tiêu hao trùng.
- `src/ui.lua`: expose module và nối focus vào interaction của shader ấn bản (không đổi `card.selected`).
- `src/shop.lua`: callback refresh cho reroll.
- `ui/shop_display.lua`: hover/focus/arrival/flip/dim và kiểm tra identity của hitbox.
- `src/card_description.lua`: trễ hover, định vị tránh lá/nút mua và mép màn hình.
- `ui/ability_choices.lua`: phản hồi tiến hóa bằng giá trị thay đổi, giữ source slot của lá tiêu hao.
- `ui/components/hand_info_panel.lua`: Boss telegraph ngắn; mô tả đầy đủ chuyển sang tooltip.
- `capture_screens.lua`: test flag mới; fixture shop dùng focus/confirm.
- `tests/shop_deck_drop_capture.lua`: giữ lệnh cũ như alias kiểm thử UX mới và kiểm tra mặt úp chung.

## State machine và ưu tiên

`IDLE → HOVERED → FOCUSED → BUYING / SELLING → IDLE`

`IDLE / FOCUSED → FLIPPING → IDLE`

`ACTIVATION → PULSE → DISSOLVING → SHARDS → FINISHED`

`DISABLED` được suy ra từ tài nguyên hoặc điều kiện bán (ví dụ phải giữ ít nhất một quân bài). Scoring khóa tương tác; transaction/flip chặn focus, mua, bán, reroll, click nền và Escape. Hover chỉ điều khiển vật phẩm rảnh. Không thêm state vào save.

Nhấp ngoài, Escape hoặc chọn lá khác hủy/thay focus. Đóng/chuyển modal không để nút cũ hoạt động xuyên lớp. Hitbox giữ identity hàng đã vẽ: không dùng index cũ để mua nhầm hàng vừa dịch vị trí.

## Luồng mua / bán / reroll

- Mua: nhấp hàng → nhấc/scale 1.08, hàng khác dim → nút **MUA — $X** cạnh lá → backend xác nhận → button squash/rebound → delta Vàng và coin Vàng→lá → card pulse → bay về bộ bài/ô SPN → settle. Mất khoảng 0.55s Normal. Trang bị mở màn khảm và rương mở picker sau khi animation mua hoàn tất.
- Thiếu tiền: vẫn được chọn để xem, nhưng nút ghi **KHÔNG ĐỦ VÀNG** và không giao dịch. Đầy SPN hoặc HP đầy dùng nguyên thông báo/validation backend.
- Bán: nhấp SPN/tiêu hao trong shop hoặc quân bài trong viewer → **BÁN — $X** → backend bán một lần → nén/rung nhẹ, viền vàng → dissolve → coin lá→HUD → settle (~0.45s). Viewer có số Vàng riêng để coin bay đến nơi nhìn thấy được. Không cần kéo vào Hiến Tế. Không vẽ bản sao tại ô cũ khi lá đang focus/giao dịch.
- Reroll: trừ giá đúng một lần → các nhóm hàng lật theo stagger → đợi mọi mặt trước đều bị che → `Shop.refresh` một lần → lật hàng mới → settle/unlock (~0.78s). Nhóm tối đa 5 lá chạy song song để shop đầy hàng không bị cắt animation. Dùng lại cùng asset mặt úp của trò chơi, không shake mạnh.
- Vào shop: slide/lift, reveal tối→sáng, thu/phục hồi chiều ngang theo stagger ngắn.

Âm thanh dùng lại `ui_hover`, `card_select`, `shop_buy`, `coin`, `card_deal`, `shop_reroll`, `card_slide`, `sell`, `mult_pop`, `card_activate`; không thêm file âm thanh giả.

## Dissolve và application

`Renderer hiện có → Canvas 256×384 dùng lại → dissolve shader → shard nhỏ → luồng energy/beam hiện có`

Canvas vẽ card với kích thước logic gốc rồi scale vào buffer, giữ font/layer/bo góc giống renderer thường. Shader và Canvas nạp một lần trong `love.load`, không biên dịch khi hover/score. Canvas trong suốt, noise vùng + mép sáng, không có hình chữ nhật đen. Nếu shader không hoạt động, Canvas fade bình thường; nếu Canvas cũng không khả dụng, game vẫn vẽ lá thường. GPU resources không nằm trong save.

Tiêu hao: pulse/buildup → dissolve bắt đầu khoảng 0.12s → 8 shard bay lên → kết thúc khoảng 0.35s. Card scoring dùng cùng shader trong giai đoạn chuyển đổi đã có; giữ nguyên converge/beam/impact/damage/HP settle của combat.

Application: snapshot chỉ khi thao tác hiệu ứng → backend áp dụng như cũ → so giá trị trước/sau → source→target energy → rim/flash + score pulse → popup những giá trị vừa đổi (~0.85s). Có hook cho tiêu hao, ấn bản, tăng tốc, tiến hóa, chọn hiệu ứng trong rương, gắn/chuyển ITM. Dedupe hand/persistent copies bằng ID. Nếu target chỉ nằm trong bộ bài và picker đã đóng, hiện preview ngắn để xác định lá được thay đổi.

Các điểm gọi có thể dùng lại:

```lua
local before = UI.Polish.snapshot(game)
-- Giữ nguyên thao tác gameplay hiện có.
UI.Polish.changed(UI, game, before, sourceCard, sourceRect)

-- Hoặc thông báo một thay đổi đã biết, không áp dụng lại gameplay:
UI.Polish.application(UI, sourceCard, targetCard, "GIÁP 8 → 10")
```

## Audit clarity

| Phân loại | Nội dung |
| --- | --- |
| Always | HP/giáp/Vàng, lượt đánh/bỏ, ST/Cường hóa/Aura, intent và tốc đánh quái, sức chứa inventory |
| Contextual | MUA/BÁN trên focus, lựa chọn target, preview trước→sau khi tiến hóa, picker rương |
| Hover only | Khả năng quân bài/SPN/ITM, chi tiết tiến hóa/ấn bản/voucher, nội tại và mô tả đầy đủ của Boss |
| Temporary | Thay đổi giá trị, coin transfer, pulse/flash/shard, thông báo giao dịch thất bại |
| Hidden | Tooltip khi kéo/scoring/giao dịch/flip, tooltip của lá khác trong focus; debug chỉ qua toggle dev |

Tooltip dùng chung một nơi, trễ 0.20s, rộng 320 logical px, đổi bên khi gần mép và tránh lá/nút xác nhận. Bỏ mô tả voucher dài luôn nằm trong shop và các tooltip tiêu hao tức thời/đúp. Boss giữ tên kỹ năng, đếm ngược và telegraph ngắn; chi tiết chỉ xuất hiện khi hover.

## Tuning

Trong `config/ux_polish_config.lua`: `hoverDelay`, `hoverResponse`, `hoverScale`, `focusScale`, `focusLift`, `dim`, `buy`, `sell`, `dissolve`, `application`, `popup`, `reroll`, `stagger`, `flip`, `flipGroup`, `arrival`, `fastFactor`, `shards`, `gold`, `viewerGold`, `deck`. `buyFlightStart/End` và `coinStart/Travel` là tỷ lệ của duration. Normal/Fast dùng setting `fastScoring` hiện có; Fast tăng tốc timeline, không bỏ feedback.

## Chạy kiểm thử

```powershell
& 'E:/Lua/Lua/lua.exe' tests/ux_polish_smoke.lua
& '../love-11.5-win64/lovec.exe' . --test-ux-polish
& '../love-11.5-win64/lovec.exe' . --test-gameplay-expansion
& '../love-11.5-win64/lovec.exe' . --test-pack-skip
& '../love-11.5-win64/lovec.exe' . --capture-shop
```

Test UX đi qua **SHOP OPEN → FOCUS → PURCHASE → SELL → REROLL → PURCHASE SAU REROLL**, thiếu Vàng, cancel, spam, Fast, hover delay và đúng một tooltip. Pixel test kiểm tra organic coverage/transparent border; kiểm tra 5/10/20 lần dùng không tạo resource mỗi lá, và ép shader lỗi để xác nhận fallback. Kiểm thử gameplay/scoring, voucher/giá, save/load/8 lá dị thể và bỏ qua 9 rương được chạy riêng để bảo vệ gameplay.

Ảnh UX: `shot_ux_shop.png`, `shot_ux_focus.png`, `shot_ux_purchase.png`, `shot_ux_sell.png`, `shot_ux_backs.png`, `shot_ux_reveal.png`.

# Kẻ Thách Tử

Boss tự do hình người, có thể được chọn ở mọi vùng chính; tỷ lệ 1/16 như các boss tự do hình người khác. Tranh riêng dùng phong cách Continental và khung K vô chất của game.

## Nội tại

- Sát thương cơ bản gấp 5 boss thường cùng độ khó, trước các buff khác.
- Oneshot là **một đòn từ đầy HP xuống 0**. Nếu HP đã giảm trước đòn kết liễu thì nội tại không kích hoạt.
- Khi bị oneshot: dùng **sát thương thực sau giảm trừ và giáp**, bao gồm sát thương vượt HP, làm HP tối đa mới; HP hiện tại được nạp đầy bằng số đó. Nhân 3 sát thương boss mỗi lần kích hoạt, không giới hạn một lần mỗi trận.
- Ví dụ 100/100 HP nhận 150 sát thương: boss trở thành 150/150 HP và sát thương ×3. Đánh tiếp một đòn 300 từ đầy máu: 300/300 HP, sát thương lại ×3. Đánh bào 1 HP trước rồi kết liễu thì boss chết bình thường.
- Đánh hụt hoặc sát thương bị giáp hấp thụ đến mức không đủ kết liễu không kích hoạt. Vô hiệu nội tại cho phép oneshot. Áp dụng tại hàm nhận sát thương chung, kể cả sát thương chuẩn và sát thương phụ.

## Khiêu Chiến Tử Thần

Cuối mỗi lượt cho người chơi +20% tổng sát thương tay bài: lượt đầu ×1,2, lượt sau ×1,4, ×1,6... Đây là phần thưởng tạm trong trận, không tăng vĩnh viễn từng lá. Dự báo sát thương và đòn thực dùng cùng hệ số. Kỹ năng bị phong ấn thì không cấp thêm buff. Boss chết hoặc bắt đầu trận khác sẽ mất buff. Theo cơ chế lưu hiện tại, tải lại khởi động lại trận và các buff trong trận.

HUD hiển thị số lần tái lập, hệ số sát thương boss và phần trăm tăng cho người chơi. Tái lập dùng VFX vàng; ban sát thương dùng VFX cường hóa đỏ trên tay bài.

PNG và prompt đầy đủ (built-in image_gen): [DEATH_CHALLENGER_ASSET.json](DEATH_CHALLENGER_ASSET.json).

Kiểm tra: `lua tests/oneshot_boss_smoke.lua`; giao diện: `lovec.exe . --test-oneshot-boss`. Ảnh trong game: `docs/oneshot_boss_before.png`, `docs/oneshot_boss_rebirth.png`.

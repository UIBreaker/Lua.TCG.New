# Cửa hàng trên hành trình

Sau mỗi trận thường, chọn ngẫu nhiên một trong sáu cửa hàng, mỗi loại có xác suất 1/6 (khoảng 16,67%). Sau boss, giữ chợ linh hồn hiện có. Rời chợ linh hồn sẽ vào shop lớn; chỉ rời shop lớn mới tăng ải. Việc chuyển giữa hai shop không cấp lại thưởng, không thu phí và không làm đổi HP, vàng hay linh hồn.

| Loại | Hàng trên kệ |
| --- | --- |
| Shop nhỏ | Tối đa 8 món: SPN, trang bị, quân bài, mở rộng tay, thuốc/tiêu hủy, đặc quyền, một rương ngẫu nhiên và một thẻ tiêu hao lẻ. Hết đặc quyền chưa sở hữu thì còn 7 món. |
| Shop tiêu hao | 8 thẻ lẻ, không trùng: Phép SPN, Ấn Chiến, Phổ, Hành Tinh, Ấn Bản. Toàn bộ thẻ trong các rương này đều có thể xuất hiện. Giá mỗi thẻ bằng giá rương gốc × 1,2, làm tròn lên. Mua vào ô tiêu hao, giữ nguyên khả năng của thẻ trong rương. |
| Shop trang bị | 4 nguyên liệu cơ bản, mỗi nhóm HP/giáp/tốc/vàng một món; 4 trang bị lớn ngẫu nhiên, không trùng. Kho gồm toàn bộ trang bị thường, kể cả đồ ghép; di vật chỉ đổi bằng linh hồn vẫn ở chợ linh hồn. Mua vào balo. |
| Shop SPN | Tối đa 6 SPN chưa sở hữu, không trùng. Mỗi lá chọn ngẫu nhiên đều giữa 8 bậc Thường–Độc Nhất; giá theo hệ số bậc hiện có. |
| Shop thuốc | Đủ 8 món: bình máu thường/nhỏ/lớn, bình giáp nhỏ/lớn, tốc đánh nhỏ/lớn và giường. Mua vào ô tiêu hao. |
| Shop quân bài | 8 lá không trùng bậc/chất trên cùng kệ, lấy đều từ đủ 52 lá (2–A của Cơ/Rô/Chuồn/Bích). Có thể là bản thường hoặc kèm tiến hóa cấp 1–2, một trang bị **cơ bản** đã gắn, một trong 9 ấn bản. Các nâng cấp có thể đi cùng nhau; không có đồ lớn, đồ ghép hay di vật linh hồn. Mua thẳng vào bộ bài, giữ nguyên thuộc tính. |
| Shop lớn | Giữ các quầy cũ: hàng tuyển chọn, nguyên liệu cơ bản, đặc quyền, rương, giảm giá. Chỉ mở sau chợ linh hồn trong luồng chơi. |

Đổi hàng giữ nguyên loại cửa hàng, dùng chi phí/voucher hiện có. Lưu game giữ loại shop đang mở; save cũ có shop `normal` được tiếp tục ở shop nhỏ. Nút thoát chợ linh hồn ghi rõ **SHOP LỚN →**.

Shop quân bài: mỗi lá có 50% không tiến hóa, 35% cấp 1, 15% cấp 2. Trang bị cơ bản có xác suất 35%, chọn đều giữa 12 nguyên liệu; ấn bản có xác suất 30%, chọn đều giữa 9 loại. Ba lần chọn độc lập. Giá = 4 vàng + 6 mỗi cấp tiến hóa + giá trang bị cơ bản + 8 nếu có ấn bản. Nhãn quầy ghi loại nâng cấp, rê chuột xem khả năng và trang bị thực tế. Lá bài mua được giữ tiến hóa, trang bị, ấn bản khi nhân bản bộ bài và lưu/khôi phục game.

## Nội thất và trưng bày

Mỗi shop nhỏ có một phòng riêng, tạo bằng built-in imagegen, giữ phong cách Continental. Sáu PNG 16:9 nằm trong `assets/scene/shops/`; prompt, concept, nguồn ảnh, kích thước và SHA-256 nằm trong `docs/shop_interior_assets.json`. Shop lớn dùng lại nội thất tiệm tiếp tế. Nền shop được chọn độc lập với vùng chiến đấu, tải một lần khi cần, dùng renderer hiện có.

- Tiệm tiếp tế: gỗ ấm, túi viễn chinh, quầy tuyển chọn và quầy tiếp tế/khám phá.
- Hiệu thẻ phép: tủ sách, giấy cuộn, nhung tím và quầy thẻ lẻ.
- Lò rèn: lò nung, đe, giá nguyên liệu nhỏ và bàn trang bị lớn.
- Điện SPN: đá xanh, thiên cầu, hai hàng bệ khế ước, mỗi hàng ba lá.
- Tiệm thuốc: lọ dược, thảo mộc, gỗ xanh; hàng trên là máu/giường, hàng dưới là giáp/tốc đánh.
- Hiệu quân bài: gỗ anh đào, nhung đỏ rượu, máy ép mạ đồng và cờ bốn vương quốc; hai hàng, mỗi hàng bốn lá, sổ quầy ghi số quân bài trong bộ.

Biển tiệm treo và sổ quầy nằm bên trái, chừa phần giữa để thấy đạo cụ nội thất. Nhãn tên, bậc và giá nằm trên quầy, giữ yên khi lá bài nghiêng hoặc được nhấc lên. Kệ giữ nguyên vị trí sau giao dịch; chỗ hết hàng được để trống. Khung lá bài vẫn dùng chung `ui/components/card_frame.lua`.

## Kiểm tra

- `lua tests/card_shop_smoke.lua`: đủ 52 lá, tiến hóa 0/1/2, toàn bộ 12 đồ cơ bản và 9 ấn bản, biến thể kết hợp, giá, giao dịch thất bại/thành công và giữ nâng cấp khi nhân bản/lưu/khôi phục.
- `lua tests/shop_markets_smoke.lua`: phân phối 6 loại shop; đủ toàn bộ kho trang bị/thẻ tiêu hao và 8 bậc SPN; giao dịch; giới hạn ô; dùng máu/giường; đổi hàng; lưu/khôi phục loại shop; soul → large → tăng ải.
- `lovec.exe . --test-shop-markets`: kiểm tra đúng sáu nền nội thất đã tải, hitbox từng món, phân nhóm thuốc và kệ không dịch sau mua; mua thực tế ở cả 6 loại, bao gồm lá tiến hóa cấp 2 đã gắn Lông Gió và ấn bản Ancient; cash-out bằng chuột và bàn phím; rời chợ linh hồn vẫn giữ nguyên ải/tiền; rời shop lớn mới tăng ải; đổi hàng bằng nút giữ nguyên loại shop. Chế độ này không ghi save/settings của người chơi.
- Hồi quy: `tests/soul_shop_smoke.lua`, `tests/soul_market_smoke.lua`, `tests/shop_vouchers_smoke.lua`.

Ảnh chụp trong game: `shop_small.png`, `shop_consumable.png`, `shop_equipment.png`, `shop_spn.png`, `shop_medicine.png`, `shop_cards.png`, `shop_soul_before_large.png`, `shop_large_after_soul.png`.

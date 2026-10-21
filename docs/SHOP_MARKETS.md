# Cửa hàng trên hành trình

Ván mới bắt đầu với bộ 5 lá ngẫu nhiên, không trùng rank/chất, luôn đủ Cơ–Rô–Chuồn–Bích; rút 3 lá lên tay và giữ 2 lá trong bộ. Địch đầu tiên ở ải 1 có 50 HP; Ba trận ải 1 là 50/100/150 HP; ải 2 là 75/150/225 HP. Mỗi ải tăng nền HP theo đường cong hiện có, trận lớn ×2 và boss ×3 nền HP. Lễ trao thưởng không sinh rương quân bài, kể cả trong rương lồng; quân bài lẻ vẫn có thể nhận.

Mỗi lượt chơi mới được cấp sẵn vào 3 ô tiêu hao: 1 Bình Máu hồi 25 HP, 1 Bình Giáp Nhỏ tăng 8 Giáp và 1 Tốc Đánh Nhỏ tăng 3 tốc cho một lá trong trận. Có sẵn từ trận đầu tiên, chỉ cấp khi bắt đầu lượt chơi mới; chuyển trận hoặc tải save không cấp lại. Kiểm tra bằng `lovec.exe . --test-starter-supplies` (không ghi save/settings của người chơi).

Sau mỗi trận thường, kể cả trận đầu, luôn đi theo thứ tự **Shop Nhỏ → một shop đi kèm → trận tiếp theo**. Shop đi kèm chọn đều giữa thẻ phép, trang bị, SPN, thuốc và quân bài (20% mỗi loại khi không có shop máu đặc biệt); không chọn lặp Shop Nhỏ. Shop máu nếu xuất hiện theo luật hiện có sẽ là shop đi kèm. Nút **SHOP KÈM →** rời shop nhỏ; chỉ rời shop đi kèm mới tiếp tục hành trình. Lưu/tải và đổi hàng giữ nguyên shop đi kèm đã chọn. Shop nhỏ sau trận đầu vẫn có Đá Tam Kích T1 giá 12 vàng, mua một lần/run.

Luồng sau boss giữ nguyên: chợ linh hồn → shop lớn → shop máu nếu đã có lịch, rồi tiếp tục hành trình. Chuyển giữa các shop không cấp lại thưởng, không thu phí và không làm đổi HP, vàng hay linh hồn; các sự kiện sau shop vẫn xuất hiện sau khi đã rời đủ các shop trong lượt ghé.

Giá hiện tại theo nhóm: vàng ×4 cho vật liệu, SPN thấp, quân bài và phần lớn hàng; SPN E+ giữ ×6; thuốc hồi 25/60 HP giá 12/21 vàng; trang bị chế sẵn bằng 1,35 lần chi phí ghép thật; linh hồn ×2; Shop Máu có bảng giá riêng. Thanh lý chỉ miễn phí vật liệu/T1. Xem [bảng cân bằng đã áp dụng](BALANCE_APPLIED_REPORT.md).

Balo mở được khi đang đến lượt người chơi trong trận bằng nút **BALO** hoặc phím **I**. Ngăn Tiêu hao/SPN có hàng **Trang bị · Mang vào trận** ở trên và kho balo riêng bên dưới. Kéo đồ từ kho lên ô để trang bị; kéo xuống kho để cất lại, hoặc kéo lên ô đã có đồ để thay thế. Chỉ đồ đã trang bị mới xuất hiện/có hiệu lực trong chiến đấu. Chuột phải tiêu hao đã trang bị để dùng; chuột phải đồ trong kho chỉ xem thông tin.

Mua SPN/tiêu hao, giữ thẻ rương và nhận tiếp tế đều vào kho balo, kể cả khi các ô chiến đấu đã đầy. Kho không giới hạn theo số ô trang bị. Xem hoặc đóng balo không mất lượt; mỗi lần trang bị/cất/đổi vị trí hợp lệ trong trận trừ **1 lượt đánh** và cho các địch còn sống hành động. Sau đó balo đóng để hiện phản ứng của địch. Kéo sai chỗ/ô bị khóa/hết lượt không mất đồ hay lượt. Sắp xếp trong shop miễn phí. Ba bình khởi đầu vẫn được trang bị sẵn. Save cũ giữ nguyên đồ đang trang bị; save mới giữ cả kho và vị trí, tiến hóa, ấn bản, kỹ năng SPN. Ghép/gắn trang bị vào quân bài và bán hàng thực hiện tại shop.

| Loại | Hàng trên kệ |
| --- | --- |
| Shop nhỏ | Tối đa 8 món: SPN, trang bị, quân bài, mở rộng tay, thuốc/tiêu hủy, đặc quyền, một rương ngẫu nhiên và một thẻ tiêu hao lẻ. Hết đặc quyền chưa sở hữu thì còn 7 món. |
| Shop tiêu hao | 8 thẻ lẻ, không trùng: Phép SPN, Ấn Chiến, Phổ, Hành Tinh, Ấn Bản. Toàn bộ thẻ trong các rương này đều có thể xuất hiện. Giá gốc thông thường bằng giá rương × 1,2, làm tròn lên; một số phép có giá gốc riêng. Giá bán bằng giá gốc của thẻ × 4. Mua vào kho balo, giữ nguyên khả năng của thẻ trong rương. |
| Shop trang bị | 4 nguyên liệu cơ bản, mỗi nhóm HP/giáp/tốc/vàng một món; 4 trang bị lớn ngẫu nhiên, không trùng. Kho gồm toàn bộ trang bị thường, kể cả đồ ghép; di vật chỉ đổi bằng linh hồn vẫn ở chợ linh hồn. Mua vào balo. |
| Shop SPN | Tối đa 6 SPN chưa sở hữu, không trùng. Mỗi lá chọn bậc theo tỷ lệ: Thường 61,34%, Không Thường 20%, Hiếm 10%, Sử Thi 5%, Huyền Thoại 2%, Thần Thoại 1%, Siêu Việt 0,5%, Độc Nhất 0,1%, Vĩnh Hằng 0,05%, Tối Thượng 0,01%; giá theo hệ số bậc hiện có. |
| Shop thuốc | Đủ 15 món trong hai ngăn: 7 đồ hồi phục/giáp/tốc/giường và 8 thuốc chiến thuật. Chỉ còn bình hồi 25 và 60 HP; bình nhỏ không còn xuất hiện trong shop hoặc thưởng tiếp tế. Mua vào kho balo. |
| Shop quân bài | 8 lá không trùng bậc/chất trên cùng kệ, lấy đều từ đủ 52 lá (2–A của Cơ/Rô/Chuồn/Bích). Có thể là bản thường hoặc kèm tiến hóa cấp 1–2, một trang bị **cơ bản** đã gắn, một trong 9 ấn bản. Các nâng cấp có thể đi cùng nhau; không có đồ lớn, đồ ghép hay di vật linh hồn. Mua thẳng vào bộ bài, giữ nguyên thuộc tính. |
| Shop lớn | Giữ các quầy cũ: hàng tuyển chọn, nguyên liệu cơ bản, đặc quyền, rương, giảm giá. Chỉ mở sau chợ linh hồn trong luồng chơi. |

Đổi hàng giữ nguyên loại cửa hàng. Riêng Shop Nhỏ, ô SPN và ô trang bị đổi loại hàng cho nhau sau mỗi lần đổi hàng thành công, kể cả miễn phí; mua hàng hoặc tải lại không tự đổi loại. Ưu đãi Đá Tam Kích nằm ở ô trang bị theo vị trí hiện tại. Phí cơ bản tại các shop dùng vàng bắt đầu từ 5 Vàng và tăng sau mỗi lượt trả phí: 5 → 7 → 10 → 14 → 19…; vào shop mới trở về 5. Đặc quyền giảm giá và lượt miễn phí vẫn áp dụng; lượt miễn phí không tăng phí. Shop Máu/Linh Hồn dùng chi phí theo tiền tệ riêng. Lưu game giữ loại shop đang mở; save cũ có shop `normal` được tiếp tục ở shop nhỏ. Nút thoát chợ linh hồn ghi rõ **SHOP LỚN →**.

Shop mở E từ ải 3, L từ 6, M từ 10, T/UQ từ 15, VH/TT từ 21; chuẩn hóa trọng số trong nhóm đã mở. SPN có mười bậc: **C → UC → R → E → L → M → T → UQ → VH → TT**. Hai bậc mới là **Vĩnh Hằng (VH)** và **Tối Thượng (TT)**; hệ số giá gốc lần lượt ×27 và ×40, trước hệ số giá chung của shop. Tiến hóa tiếp sau TT hiển thị TT+1, TT+2… Save cũ giữ nguyên cấp và sức mạnh: UQ+1 đổi nhãn thành VH, UQ+2 thành TT, UQ+3 thành TT+1. Huyết Khế Đổi Vận vẫn chỉ nâng SPN dưới UQ lên đúng UQ.

Shop quân bài: mỗi lá có 50% không tiến hóa, 35% cấp 1, 15% cấp 2. Trang bị cơ bản có xác suất 35%, chọn đều giữa 12 nguyên liệu; ấn bản có xác suất 30%, chọn đều giữa 9 loại. Ba lần chọn độc lập. Giá gốc = 4 vàng + 6 mỗi cấp tiến hóa + giá trang bị cơ bản + 8 nếu có ấn bản; giá bán bằng giá gốc × 4. Nhãn quầy ghi loại nâng cấp, rê chuột xem khả năng và trang bị thực tế. Lá bài mua được giữ tiến hóa, trang bị, ấn bản khi nhân bản bộ bài và lưu/khôi phục game.

Shop quân bài có cơ chế thu mua ẩn: mở Balo → Bộ bài (hoặc màn xem bộ bài), nhấp lá đang sở hữu để hiện nút **BÁN** rồi xác nhận. Giá thu mua = 50% giá trị lá, làm tròn xuống: 4 vàng gốc + 6 mỗi cấp tiến hóa + giá trang bị đang gắn + 8 nếu có ấn bản. Trang bị bán cùng lá; tháo vào balo trước nếu muốn giữ lại. Bán chỉ nhận vàng, không nhận linh hồn/hồi máu hay dùng Lá Tiêu Hủy. Giữ ít nhất một lá; mọi shop khác đều khóa chức năng này. Kiểm tra giao dịch, hủy chọn, hiệu ứng vàng và khóa theo shop bằng `lovec.exe . --test-card-shop-sale`.

## Thuốc chiến thuật

Cả tám loại đều bán ngẫu nhiên trong quầy thuốc của shop nhỏ và shop lớn, đồng thời có đầy đủ trong ngăn Chiến thuật của shop thuốc. Dùng khi đang chuẩn bị tay bài trong trận; không dùng giữa lúc địch tấn công, kết toán hoặc trong shop. Hủy chọn mục tiêu không mất thuốc.

| Thuốc | Giá | Tác dụng |
| --- | --- | --- |
| Chính Xác | 36 | Tay bài tiếp theo đánh trúng 100%, không phụ thuộc tốc. |
| Né Tránh | 42 | Né mọi đòn đánh trong lượt tiếp theo, xuyên suốt cả pha địch đánh trước và sau, kể cả nhóm 3 địch; độc và tự mất máu vẫn có tác dụng. |
| Phá Giáp | 48 | Chọn địch còn giáp; xóa cả giáp thường và giáp sinh vật, gây sát thương chuẩn bằng đúng 25% lượng giáp bị phá, không giới hạn lượng giáp, không làm tròn mất sát thương nhỏ. Có thể kết liễu và nhận thưởng thắng trận bình thường. |
| Sát Thương | 36 | +20 ST mỗi lá hiện đang trên tay, hết lượt tiếp theo là hết hiệu lực. |
| Cường Hóa | 42 | +5 Cường hóa mỗi lá hiện đang trên tay, hết lượt tiếp theo là hết hiệu lực. |
| Máu Vàng | 54 | Trong trận này: 1 HP thực mất do địch (kể cả độc/nội tại boss) = 1 Vàng. Không trả vàng từ giáp hấp thụ, tự trả HP hoặc sát thương vượt HP còn lại; không cộng dồn. |
| Rút Bài | 48 | Rút ngay 5 lá, kể cả tay đã đầy. Kho hết thì xáo cọc bỏ bài; tổng bài còn ít hơn 5 thì lấy số còn lại. Hết bài hoàn toàn thì giữ thuốc. Không tăng kích thước tay vĩnh viễn và không đổi các lá đang chọn. |
| Giảm Tốc | 42 | Ném vào một địch còn sống, giảm 50% tổng tốc hiện tại (kể cả buff), tối thiểu 1, trong 2 hành động của địch. Không cộng dồn; địch đang chậm hoặc tốc 1 thì không mất thuốc. Thứ tự hành động và xác suất trúng dùng tốc đã giảm. Hết thời hạn thì tự trở về tốc gốc/buff còn lại. |

Thuốc chính xác và né tránh không cộng dồn, giữ thuốc nếu hiệu lực đang có. Bỏ bài không làm mất buff; kết thúc lượt mới hết các buff một lượt. Thuốc ST/CH theo ID của các lá đã có trên tay lúc uống; không đổi chỉ số gốc, không lan sang lá mới rút hay bộ bài vĩnh viễn. Buff và hàng đợi hiệu ứng không được lưu vào save hoặc mang sang trận khác; thuốc chưa dùng vẫn được lưu như các tiêu hao khác. Save cũ có bình nhỏ vẫn dùng được.

Toàn bộ VFX dùng quầng sáng mềm từ texture ánh sáng chung, lõi sáng, đường sáng nhiều lớp theo chế độ blend cộng và hạt sáng có quỹ đạo riêng. Có 12 motif: xoắn sinh lực/lá xanh, khiên xanh lam, luồng tốc cyan, vòng ngắm vàng, bóng né tím, mảnh giáp vỡ cam, lửa đỏ quanh từng lá, xoắn năng lượng xanh kết nối các lá, máu/đồng vàng, đường sáng từ kho tới 5 lá vừa rút, vòng băng giảm tốc và hồi sức giường. VFX bám chuyển động lá bài; vòng giảm tốc còn hiển thị nhẹ trong thời gian debuff. Hiệu ứng liên tiếp giảm chồng lấn, số lượng được giới hạn; không đổi shader/blend/line width của renderer ngoài phạm vi vẽ và không dùng RNG gameplay. Chế độ giảm chuyển động giảm số hạt từ 54 còn 12 mỗi hiệu ứng, giữ thông tin tác dụng.

Chín tranh bình thuốc (8 thuốc chiến thuật, 1 thay cánh quạt tốc lớn) dùng built-in ImageGen; PNG và bản runtime nằm trong `assets/cards/continental/utility/`, `speed/` và `runtime/`, có đường dẫn, prompt và SHA-256 trong `docs/potion_assets.json` và manifest chung. Chỉ bổ sung hai tranh Rút Bài/Giảm Tốc trong lần mở rộng này, giữ nguyên các tranh thuốc đã chốt.

## Nội thất và trưng bày

Mỗi shop nhỏ có một phòng riêng, tạo bằng built-in imagegen, giữ phong cách Continental. Sáu PNG 16:9 nằm trong `assets/scene/shops/`; prompt, concept, nguồn ảnh, kích thước và SHA-256 nằm trong `docs/shop_interior_assets.json`. Shop lớn dùng lại nội thất tiệm tiếp tế. Nền shop được chọn độc lập với vùng chiến đấu, tải một lần khi cần, dùng renderer hiện có.

- Tiệm tiếp tế: gỗ ấm, túi viễn chinh, quầy tuyển chọn và quầy tiếp tế/khám phá.
- Hiệu thẻ phép: tủ sách, giấy cuộn, nhung tím và quầy thẻ lẻ.
- Lò rèn: lò nung, đe, giá nguyên liệu nhỏ và bàn trang bị lớn.
- Điện SPN: đá xanh, thiên cầu, hai hàng bệ khế ước, mỗi hàng ba lá.
- Tiệm thuốc: lọ dược, thảo mộc, gỗ xanh; ngăn Hồi phục có máu/giường phía trên, giáp/tốc phía dưới; ngăn Chiến thuật có 8 thuốc, giữ vị trí sau mua và chuyển ngăn.
- Hiệu quân bài: gỗ anh đào, nhung đỏ rượu, máy ép mạ đồng và cờ bốn vương quốc; hai hàng, mỗi hàng bốn lá, sổ quầy ghi số quân bài trong bộ.

Biển tiệm treo và sổ quầy nằm bên trái, chừa phần giữa để thấy đạo cụ nội thất. Nhãn tên, bậc và giá nằm trên quầy, giữ yên khi lá bài nghiêng hoặc được nhấc lên. Kệ giữ nguyên vị trí sau giao dịch; chỗ hết hàng được để trống. Khung lá bài vẫn dùng chung `ui/components/card_frame.lua`.

## Kiểm tra

- `lua tests/starting_balance_smoke.lua`: 200 bộ bài khởi đầu đủ 4 chất, 5 lá không trùng, tay bài 3 lá, địch đầu 50 HP và giữ nguyên sở hữu khi lưu/tải.
- `lua tests/shop_price_balance_smoke.lua`: giá theo nhóm trên cả 10 chế độ shop, trừ tiền đúng giá hiển thị, nhãn giảm giá và đặc quyền rương.

- `lua tests/loadout_smoke.lua`: mua khi ô chiến đấu đầy, trang bị/hoán đổi/cất, vị trí tiêu hao, SPN trong kho không kích hoạt, ô bị khóa/hết lượt, tiến hóa/ấn bản/callback SPN và save cũ/mới.
- `lovec.exe . --test-battle-backpack`: mở/đóng bằng nút và phím I; kéo thả thật để thay tiêu hao, trang bị SPN và cất lại; trừ đúng 1 lượt, phản ứng địch, chặn thao tác khi địch hành động/hết lượt, kéo sai không mất lượt, sắp xếp trong shop miễn phí. Không ghi save/settings; ảnh `backpack_battle_consumables.png`, `backpack_battle_spn.png`.

- `lua tests/potions_smoke.lua`: tám cơ chế, rút đủ 5 vượt tay đầy, xáo cọc bỏ, hết kho, chuẩn bị animation, giữ chọn bài; giảm tốc đúng mục tiêu/thời hạn/thứ tự; các hiệu ứng cũ; kho 15 món; thuốc có trong shop nhỏ/lớn; lưu/khôi phục và reset.
- `lovec.exe . --test-potions`: hai ngăn thuốc, mua thật, không dùng thuốc trong shop, VFX 8 thuốc, chọn/hủy mục tiêu, rút 5 ngay từ tay đầy, giảm tốc đúng địch; hồi quy né cả nhóm/hết buff, máu vàng, cash-out và thắng bằng tay bài. Kiểm tra giảm chuyển động và RNG không bị VFX làm thay đổi. Không ghi save/settings của người chơi. Ảnh `docs/potion_*.png`.
- `lovec.exe . --capture-potion-vfx`: vẽ và chụp đủ 12 motif VFX trong game, kiểm tra hạt/texture, trạng thái graphics và RNG được giữ nguyên. Gallery `docs/potion_vfx_gallery.png`.
- `lua tests/card_shop_smoke.lua`: đủ 52 lá, tiến hóa 0/1/2, toàn bộ 12 đồ cơ bản và 9 ấn bản, biến thể kết hợp, giá, giao dịch thất bại/thành công và giữ nâng cấp khi nhân bản/lưu/khôi phục.
- `lua tests/shop_markets_smoke.lua`: phân phối 6 loại shop; đủ toàn bộ kho trang bị/thẻ tiêu hao và phân phối bậc SPN; giao dịch; giới hạn ô; dùng máu/giường; đổi hàng; lưu/khôi phục loại shop; soul → large → tăng ải.
- `lovec.exe . --test-shop-markets`: kiểm tra đúng sáu nền nội thất đã tải, hitbox từng món, phân nhóm thuốc và kệ không dịch sau mua; mua thực tế ở cả 6 loại, bao gồm lá tiến hóa cấp 2 đã gắn Lông Gió và ấn bản Ancient; cash-out bằng chuột và bàn phím; rời chợ linh hồn vẫn giữ nguyên ải/tiền; rời shop lớn mới tăng ải; đổi hàng bằng nút giữ nguyên loại shop. Chế độ này không ghi save/settings của người chơi.
- Hồi quy: `tests/soul_shop_smoke.lua`, `tests/soul_market_smoke.lua`, `tests/shop_vouchers_smoke.lua`.

Ảnh chụp trong game: `shop_small.png`, `shop_consumable.png`, `shop_equipment.png`, `shop_spn.png`, `shop_medicine.png`, `shop_cards.png`, `shop_soul_before_large.png`, `shop_large_after_soul.png`.

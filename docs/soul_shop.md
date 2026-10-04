# Chợ Linh Hồn

Quân bài không bán lấy vàng. Ô tiêu hao cuối của shop thường ngẫu nhiên 50/50 giữa **Bình Máu** và **Lá Tiêu Hủy**, đều giá 4 vàng. Mua cất vào ô tiêu hao (tối đa 3), chuột phải để dùng. Bình Máu hồi 25 HP; khi đầy HP thì giữ thẻ. Lá Tiêu Hủy dùng một lần trong shop: chọn quân bài, xem giá trị và xác nhận **HỦY** để nhận linh hồn. Đóng màn chọn không mất thẻ; luôn giữ ít nhất một quân bài. Shop linh hồn bán Lá Tiêu Hủy giá 4 LH, cũng phải mua rồi dùng.

Mọi lần tiêu hủy quân bài (chiến đấu, tự hủy, phép biến đổi, nuốt bài, nghi lễ) đều thưởng linh hồn một lần, kể cả khi cùng lá tồn tại ở nhiều cọc. Hộ Linh bị Ankh/Hex tiêu hủy cũng trả linh hồn. Dùng tiêu hao bình thường và bán SPN/tiêu hao không phải tiêu hủy.

Linh hồn nhận được = **1 + tổng giá trị trang bị đang khảm + 4 × bậc tiến hóa + thưởng ấn bản**. Thưởng ấn bản: Foil 3, Holographic 6, Polychrome 10, Negative 12. Trang bị mất cùng lá; có thể hoán đổi trang bị trước khi thực hiện nghi lễ. Dược Sư hồi 8 HP khi tiêu hủy thành công. Tro Vàng chỉ tăng tiền bán SPN và tiêu hao.

Sau thưởng mỗi boss, game vào Chợ Linh Hồn với giao diện tím riêng. Linh hồn tích lũy suốt run và được lưu cùng trạng thái shop. Mỗi di vật có một bản mỗi lần bày hàng. Đổi hàng bằng linh hồn: lần đầu 5 LH, tăng 2 LH mỗi lần trong lượt ghé; chọn 5 trang bị ngẫu nhiên khác lượt trước, đồng thời bổ sung lại thẻ hỗ trợ đã mua. Giá đổi hàng được lưu và reset về 5 LH sau boss tiếp theo. Mua xong chọn lá để khảm, rồi quay lại shop. Rời chợ tiếp tục chiến dịch.

| Di vật | Giá LH | Hốc | Hiệu ứng khi tính điểm |
|---|---:|---:|---|
| Kiếm Diệt Thế | 32 | 2 | +120 Sát thương, +35% sát thương |
| Vương Miện Hư Không | 28 | 2 | +30 Cường hóa |
| Khiên Thành Trì | 22 | 1 | +30 Giáp, +60 Sát thương |
| Tim Cổ Thụ | 24 | 1 | Hồi 18 HP |
| Đồng Hồ Tận Thế | 30 | 2 | +80 Sát thương, +20 Cường hóa |

Giáp vẫn chịu trần 30 của game; các hệ số theo chất hiện có vẫn áp dụng. Tất cả 15 di vật chỉ xuất hiện trong Chợ Linh Hồn, không vào pool shop vàng/rương ngẫu nhiên.

Thẻ hỗ trợ: **Tiến Hóa 12 LH**, **Tăng Tốc Đơn 6 LH**, **Tăng Tốc Đội 10 LH**, **Sinh Lực Vĩnh Cửu 10 LH (+20 máu tối đa và hồi 20 HP)**. Mua cất vào ô tiêu hao (tối đa 3); Tiến Hóa có thể dùng trong shop, các lá tăng tốc dùng trong trận. Mỗi thẻ bán một lần mỗi lần bày hàng; có thể mua lại sau đổi hàng.

Nền riêng `assets/scene/soul_bazaar.png` tạo bằng built-in image_gen; có chuyển động nhẹ và đốm linh hồn. Prompt trong `soul_background_prompt.md`.

Tranh được tạo bằng built-in image_gen: `assets/cards/continental/itm/soul_*.png` và `assets/cards/continental/utility/soul_reaper.png`. Prompt đầy đủ nằm trong `CONTINENTAL_ASSET_PROMPTS.md`, danh mục trong `asset_manifest.json`. Tất cả ảnh PNG 1024 × 1536, sử dụng khung chung của game.

Kiểm tra:

```powershell
lua tests/soul_shop_smoke.lua
lua tests/shop_vouchers_smoke.lua
lua tests/reward_ceremony_smoke.lua
& '../love-11.5-win64/lovec.exe' . --test-soul-shop
& '../love-11.5-win64/lovec.exe' . --test-card-effects
```

Capture không đọc/ghi/xóa save người chơi. Ảnh kiểm tra nằm trong `docs/soul_normal_shop.png`, `docs/soul_destruction_preview.png`, `docs/soul_shop.png`, `docs/soul_shop_purchased.png`.

## Mười di vật có cơ chế riêng

Shop bày 5 trang bị ngẫu nhiên từ bộ 15 di vật. Không có nút chuyển trang: chỉ đổi hàng bằng linh hồn mới thay đổi 5 món đang bày. Lượt mới không trùng 5 món ở lượt ngay trước. Kho hàng được lưu cùng run; mở lại shop hoặc tải save không tự đổi hàng.

| Trang bị | Giá LH | Hốc | Cơ chế |
|---|---:|---:|---|
| Đèn Tro Bất Diệt | 38 | 2 | Khi còn trên tay: chặn sát thương chí tử và hồi 50% máu tối đa. Một lần mỗi trận. |
| Chuông Đông Cứng | 34 | 2 | Khi tính điểm: đóng băng 2 đòn đánh địch kế tiếp. Một lần mỗi trận. |
| La Bàn Khe Nứt | 26 | 1 | Mỗi tay tính điểm: kéo lá rank cao nhất còn trong bộ vào tay, vượt giới hạn cầm bài. |
| Xích Vòng Luân Hồi | 30 | 1 | Sau khi tính điểm: lá mang xích trở lại tay thay vì nằm trong cọc bỏ. |
| Gương Song Vọng | 36 | 2 | Mỗi tay tính điểm: tái kích hoạt 2 lần cho mỗi lá kề trái/phải trong vùng tính điểm. |
| Bút Ký Khởi Nguyên | 40 | 2 | Khi tính điểm: tiến hóa vĩnh viễn +1 cấp cho đồng đội ít tiến hóa nhất đang tính điểm. Một lần mỗi trận. |
| Neo Câm Lặng | 32 | 2 | Khi tính điểm: tắt cả kỹ năng chủ động và nội tại boss đến hết 2 tay bài kế tiếp. Một lần mỗi trận. |
| Chén Độc Vĩnh Dạ | 28 | 1 | Khi tính điểm: đầu 3 đòn đánh của mục tiêu, độc gây sát thương bằng 8% máu tối đa địch. Không cộng dồn; làm mới thời hạn. |
| Khế Ước Người Gặt | 30 | 1 | Sau lần tính điểm đầu: mỗi kẻ địch chết cho +3 linh hồn đến hết trận. Không cộng dồn nhiều khế ước. |
| Lăng Kính Hoàng Hôn | 42 | 2 | Tính điểm cùng ít nhất 3 chất: nâng ấn bản chính lá này vĩnh viễn, Thường → Foil → Holo → Poly. Một lần mỗi trận. |

Tiến hóa và ấn bản được đồng bộ về lá gốc, lưu cùng run. Hồi sinh cần giữ lá trên tay. Tái kích hoạt tuân theo giới hạn chống vòng lặp của game. Độc đi qua hệ thống sát thương/giáp của quái; kẻ địch tái sinh chỉ trả linh hồn khi chết hẳn. Mỗi món có tranh riêng tại `assets/cards/continental/itm/`; prompt chính xác trong `soul_relic_art_prompts.json` và `CONTINENTAL_ASSET_PROMPTS.md`.

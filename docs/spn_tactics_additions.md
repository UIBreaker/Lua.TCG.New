# 10 SPN chiến thuật mới

Bổ sung ngày 2026-10-05, nâng bộ SPN từ 11 lên 21 lá. Tất cả khởi đầu ở bậc Thường, giá 4; có trong shop, gói Hộ Linh, lựa chọn boss và bộ sưu tập qua catalog hiện có.

| SPN | Hiệu ứng ở bậc Thường | Lối chơi |
|---|---|---|
| Độc Hành | Chơi đúng một lá: ×1.8 Cường hóa | Dồn đầu tư vào một chủ lực; chơi thêm lá không tính điểm cũng mất hiệu ứng. |
| Hội Lưu | Ít nhất 3 phe trong các lá tính điểm: +3 Cường hóa mỗi phe | Xây bộ đa phe thay vì đơn chất; tên phe cũ và mới cùng chất chỉ tính một. |
| Hậu Vệ | +4 Giáp mỗi lá đã chơi không tính điểm | Dùng lá phụ làm hộ vệ cho Đơn Thủ, Đôi hoặc Bộ Ba; không tính lá giữ lại trên tay. |
| Huyết Khuyết | +1 Sát thương mỗi HP thiếu, tính tối đa 60 HP | Phản công sau khi chịu thương, phối hợp chiến thuật mất máu. |
| Pháo Linh | Mỗi Giáp hiện có cộng 0.02 vào hệ số Cường hóa, tính tối đa 30 Giáp | Giữ giáp để tăng sức đánh: 20 Giáp → ×1.4; không tiêu giáp. |
| Tĩnh Triều | Khi chưa bỏ bài trong trận: +8 Sát thương mỗi lượt bỏ còn lại | Đánh từ bài được chia, giữ tài nguyên; sau lần bỏ đầu tiên hiệu ứng ngừng đến trận mới. |
| Lột Xác | +2 Cường hóa mỗi lượt bỏ đã dùng, tính tối đa 3 lượt | Chủ động bỏ bài để tìm tổ hợp và tăng sức mạnh trong trận. |
| Chuyển Ảnh | Từ tay thứ hai: ×1.4 Cường hóa nếu đổi kiểu tay so với tay trước | Luân phiên thế đánh; tay đầu và lặp kiểu vừa chơi không nhận thưởng. |
| Khâu Hồn | Hồi 4 HP nếu ít nhất 2 lá tính điểm có trang bị | Phân bổ trang bị cho nhiều lá để duy trì sức bền; hai ngọc trên một lá vẫn chỉ tính một lá. |
| Mót Sao | +1 Vàng nếu chỉ chơi bậc 2–10 và tổng bậc ≤12 | Kiếm tiền bằng chiến binh bậc thấp; mọi lá đã chơi đều tham gia kiểm tra. |

Tiến hóa tăng các lượng thưởng theo công thức SPN hiện có: mỗi bậc +50% lượng thưởng cơ bản. Với hệ số nhân chỉ tăng phần vượt 1: Độc Hành tiến hóa lần đầu thành ×2.2, Chuyển Ảnh thành ×1.6. Điều kiện kích hoạt và trần tài nguyên đầu vào không đổi. Giáp nhận thêm vẫn theo trần 30 của chiến đấu; hồi HP được chặn ở HP tối đa trong luồng đánh hiện có.

Các callback chỉ đọc trạng thái. Kết quả tính điểm trả giáp, hồi HP và vàng về luồng áp dụng hiệu ứng hiện có; preview không trao thưởng và không chi vàng Mua Chuộc. SPN bị boss khóa không kích hoạt. Trạng thái lượt bỏ và kiểu tay trước được reset bằng hệ thống chiến đấu hiện có.

Art: 10 PNG riêng trong `assets/cards/continental/spn/`, sử dụng built-in image_gen và chuẩn `docs/CONTINENTAL_ART_BIBLE.md`; prompt đầy đủ nằm trong `docs/CONTINENTAL_ASSET_PROMPTS.md` và `docs/asset_manifest.json`.

Kiểm tra: `lua tests/spn_tactics_smoke.lua`, `lua tests/spn_combat_smoke.lua`, `lua tests/scoring_presentation_smoke.lua`.

Kiểm tra render thật: `../love-11.5-win64/lovec.exe . --test-spn-art`, ảnh kết quả `docs/spn_tactics_runtime.png`. Bộ `--test-features` cũng qua; bộ `--test` đầy đủ hiện dừng ở test giá bán Hộ Linh (`test_system.lua:138`), nằm ngoài phần SPN mới.

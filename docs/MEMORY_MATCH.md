# Bàn Ký Ức

Một người chủ bàn viễn chinh mời người chơi lật tìm cặp. Sự kiện có 25% cơ hội xuất hiện sau khi thắng boss ở ải lẻ (1, 3, 5...), chỉ xét một lần mỗi ải/vùng. Chơi sau chuỗi cửa hàng, trước khi sang ải tiếp theo. Không thay thế shop máu, trao đổi hoặc tượng cổ; không sinh trong Lãnh Địa Máu.

## Bộ thẻ và lượt chơi

- Tham gia tốn 50 vàng, thu đúng một lần khi bấm bắt đầu. Thiếu tiền không thể chơi. Bỏ qua miễn phí; tải lại ván đã bắt đầu không thu thêm và không hoàn phí.
- 18 thẻ úp, chia thành 9 cặp. Mỗi thẻ lật tiêu 1 trong 24 lượt; mỗi lần so sánh dùng 2 lượt.
- Sáu cặp luôn dùng đúng lá và asset có sẵn: Tiến Hóa, Tăng Tốc Đơn, Tăng Tốc Đội, Sinh Lực Vĩnh Cửu, Khế Ước Dung Linh, Túi Không Gian.
- Ba cặp còn lại là ba SPN có ID khác nhau, được chọn ngẫu nhiên và gán bậc trước khi xáo bàn. Được nhận bản sao kể cả đã sở hữu SPN đó.
- Ghép đúng nhận quyền giữ một lá trong cặp. Lật sai cho xem hai lá trong 1,1 giây rồi úp lại. Không được lật thẻ thứ ba khi đang đối chiếu, lật lại cùng thẻ hoặc chọn thẻ đã ghép.

## Chuỗi và chốt thưởng

Chuỗi hiện tại là số cặp đúng liên tiếp: 0–1 tương ứng ×1, 2 tương ứng ×2, 3 tương ứng ×3, 4 trở lên tương ứng ×4. Khi kết thúc, **mọi cặp đã tìm** nhận số lá bằng hệ số chuỗi cuối. Không lưu chuỗi cao nhất cũ.

Ví dụ đã tìm 5 cặp, chuỗi cuối 3: nhận 15 lá. Lật sai trước khi chốt thì chuỗi về 0, còn 5 lá cơ bản. Có thể xây lại chuỗi. Người chơi được dừng sớm sau một lần đối chiếu để bảo toàn hệ số; không được dừng khi mới mở một lá hoặc hai lá còn đang đối chiếu.

Hết lượt hoặc ghép đủ bàn sẽ chuyển sang bảng thưởng. Trần tuyệt đối là 9 × 4 = 36 lá. Phần thưởng nhân **số bản sao**, không nhân chỉ số. SPN và tiêu hao được cất vào balo, không tự trang bị. Nhận thưởng có biên nhận chống bấm/lưu/tải phát lặp.

## Bậc SPN

| C | UC | R | E | L | M | T | UQ | VH | TT |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 45% | 25% | 15% | 8% | 4% | 1,5% | 0,8% | 0,4% | 0,2% | 0,1% |

Tỷ lệ áp dụng riêng cho từng SPN trong ba cặp; không gán chỉ số Void/Huyết Luyện. Không có bảo hiểm. Bảng tỷ lệ và toàn bộ quy tắc được hiển thị trong sự kiện.

## Kiểm tra cân bằng

`tests/memory_match_balance.lua` mô phỏng 1.000 ván cho mỗi cách chơi, dùng đúng module trò chơi. Chiến thuật ghi nhớ chỉ lưu thông tin đã lật, tìm cặp đã biết trước, và chốt khi có ít nhất 5 cặp với chuỗi 4. Cách lật ngẫu nhiên dùng cùng điều kiện chốt.

| Lượt lật | Cách chơi | Cặp trung bình | Lá thưởng trung bình | Ghép đủ bàn theo chiến thuật trên |
| --- | --- | --- | --- | --- |
| 28 (thử nghiệm) | Ghi nhớ hoàn hảo | 6,989 | 26,422 | 12,7% |
| 24 (đã áp dụng) | Ghi nhớ hoàn hảo | 6,336 | 20,246 | 0,4% |
| 24 (đã áp dụng) | Lật ngẫu nhiên | 0,742 | 0,760 | 0% |

Đây là mô phỏng hai chiến thuật, không phải lời hứa phần thưởng hoặc tỷ lệ thắng của người chơi. Giới hạn 24 lượt giảm việc phát quá nhiều thẻ nâng cấp trong khi vẫn cho trí nhớ và may mắn tạo chênh lệch lớn. Chưa đánh giá ảnh hưởng kinh tế qua một hành trình hoàn chỉnh do người chơi thật điều khiển.

## Lưu và hình ảnh

Lưu từng lần lật, thứ tự bàn, SPN/bậc đã chọn, chuỗi, lượt còn lại và trạng thái đang đối chiếu. Tải lại không xáo bàn hoặc khôi phục lượt lật. Các hàm SPN được nối lại từ catalog khi phục hồi.

Người chủ bàn dùng PNG có alpha, tạo bằng built-in image_gen. Prompt và nguồn ảnh: [MEMORY_MATCH_HOST_ASSET.json](MEMORY_MATCH_HOST_ASSET.json). Nền lấy khu vực chiến đấu hiện tại, bàn và mặt sau dùng thành phần game; sáu lá hỗ trợ tái sử dụng asset hiện có.

Kiểm tra: `lua tests/memory_match_smoke.lua`, `lua tests/memory_match_balance.lua`, `lovec.exe . --test-memory-match`.

Ảnh QA: `docs/memory_match_welcome.png`, `docs/memory_match_rules.png`, `docs/memory_match_table.png`, `docs/memory_match_reveal.png`, `docs/memory_match_combo.png`, `docs/memory_match_mismatch.png`, `docs/memory_match_max_combo.png`, `docs/memory_match_rewards.png`.

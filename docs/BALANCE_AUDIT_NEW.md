# Báo cáo cân bằng: 150 HP mở đầu, bộ 5 lá, giá shop ×6

**Đã có bản áp dụng và kiểm chứng mới:** [BALANCE_APPLIED_REPORT.md](BALANCE_APPLIED_REPORT.md). Các số liệu bên dưới là lịch sử.

Ngày chạy: 20/10/2026. Chạy bằng LÖVE 11.5 với RNG và các hàm tính điểm/chiến đấu của game. **Chưa áp dụng các đề xuất bên dưới vào game.**

**Kết luận:** trận đầu 150 HP chưa gây tỷ lệ thua cao cho các bot được thử, nhưng kéo dài phần mở đầu. Sức ép tăng rõ khi phải thắng cả ba trận ải 1 rồi tiếp tục tích lũy tổn thất. Giá trả tiền hiện đã khắt khe; vấn đề đồ mạnh dễ nhận vẫn còn ở quầy tặng miễn phí và các khoản thưởng tiền lớn. Tăng đồng loạt giá thêm nữa sẽ làm yếu nhịp hình thành build mà không xử lý hai nguồn này.

**Phạm vi và cách hiểu số liệu**

- 200 seed bộ bài được ghép cặp qua 4 mức HP và 2 cách đánh: 1.600 lượt mở đầu, giải quyết 4.046 trận. Mỗi ván dùng 5 lá đủ 4 chất, tay 3 lá, 100 HP người chơi và đúng ba bình khởi đầu. Bot có tính toán dùng xem trước điểm, giáp, hồi máu và thuốc tốc theo API thật. Bot đơn giản chỉ chọn sát thương ước tính, không dùng thuốc.
- Trong phép đo mở đầu, HP và đồ còn lại được mang qua ba trận; **không cấp thưởng chiến thắng, không mở rương hay mua đồ giữa trận**. Đây là phép đo sức chịu đựng của bộ khởi đầu, không phải tỷ lệ thắng ải 1 của người chơi sử dụng đầy đủ mọi nguồn thưởng.
- Chiến dịch vùng đầu: mỗi cấu hình chính có 40 seed × 3 profile build × 2 chính sách = 240 lượt thử vượt 20 ải/60 trận. Thua thì dừng. Ngoài ra có probe riêng từng trận để vẫn đo được cuối vùng khi các run chết sớm.
- Phủ hành trình rộng: thêm 30 lượt thử tuyến Con Người → Cơ → Rô → Chuồn → Bích → Bí Ẩn, cùng 10.800 probe tại đủ **100 ải hữu hạn/300 vị trí trận**, cộng **20 ải đầu vùng vô tận/60 vị trí trận**. Mỗi vùng có 1.800 probe. Không thể kiểm tra “hết” phần vô tận.
- Kinh tế: 600 lộ trình **giả định thắng đủ 60 trận**, dùng hàm thưởng và stock shop thật, tổng 36.000 lần trao thưởng và 593.583 lượt chào bán. Hai nhóm chỉ tiết kiệm với 0 hoặc 2 lượt đánh còn dư; nhóm thứ ba mua tối đa một món hữu ích trả phí mỗi lần ghé và lấy đồ miễn phí. Đây là mô hình khả năng chi trả, không phải 600 chiến dịch đã thắng bằng cách mua đồ đó.

**1. Trận đầu có quá khó không?**

| Máu địch đầu | Cách đánh | Thắng trận đầu | Qua cả ải 1, không nâng cấp giữa trận | Trung vị số tay đánh trận đầu |
| --- | --- | ---: | ---: | ---: |
| 150 | Đơn giản | 195/200 = 97,5% | 31/200 = 15,5% | 16 |
| 150 | Có tính toán, dùng thuốc | 200/200 = 100% | 70/200 = 35% | 6,5 |
| 125 | Có tính toán, dùng thuốc | 200/200 = 100% | 81/200 = 40,5% | 6,5 |
| 100 | Đơn giản | 200/200 = 100% | 37/200 = 18,5% | 12 |
| 100 | Có tính toán, dùng thuốc | 200/200 = 100% | 91/200 = 45,5% | 4,5 |
| 75 | Có tính toán, dùng thuốc | 200/200 = 100% | 105/200 = 52,5% | 4 |

Với 150 HP, các trận tiếp theo của ải 1 có ngân sách 225 và 300 HP trước các cơ chế riêng của đối thủ. Bot đơn giản có ván cần tới 38 tay đánh riêng trận đầu. Vì vậy vấn đề rõ nhất là nhịp chơi dài và sức ép liên tiếp, không phải chết ngay khi gặp con địch đầu tiên. Mẫu 200 seed chưa đủ để khẳng định người chơi thật luôn thắng.

**2. Kết quả đi chiến dịch và thử các phương án**

Bot chiến dịch dùng build theo kịch bản: tăng Chips/tốc/HP theo profile, cấp một số bài/trang bị/SPN ở mốc cố định, mở thế bài theo mốc. Bot chưa tự tìm mọi combo hoặc mua/ghép đồ tối ưu. Mô hình này còn giữ khoản thuốc hồi 60 HP giá 7 và ngân sách thuốc của bộ stress-test cũ; **không dùng mô hình này để kết luận giá shop hiện hành**. Các phương án bên dưới dùng cùng giả định để so sánh tác động HP và cầu nối đầu game.

| Cấu hình thử | Build trung bình, có tính toán | Build mạnh, có tính toán | Số ải hoàn tất trung bình của build mạnh |
| --- | ---: | ---: | ---: |
| Hiện tại: 150 HP, đường cong hiện tại | 0/40 | 0/40 | 1,05 |
| Chỉ mềm đoạn đầu 100/200/400/750/1284 HP, trở về đường cong cũ từ ải 5, thêm món T1 đầu game | 0/40 | 0/40 | 1,40 |
| 100 HP; tăng ×1,60 đến ải 5, rồi ×1,50 đến ải 20 | 0/40 | 6/40 = 15% | 3,73 |
| Đường cong 100 HP trên + món T1 giá 12 sau trận đầu, mẫu chính | 1/40 = 2,5% | 11/40 = 27,5% | 6,35 |
| Cùng phương án có T1, 20 seed mới để kiểm chứng | 0/20 | 4/20 = 20% | 5,10 |

Gộp mẫu chính và kiểm chứng của phương án có T1: build mạnh **15/60 = 25%**, khoảng tin cậy Wilson 95% khoảng **15,8–37,2%**; build trung bình **1/60 ≈ 1,7%**. Build mạnh đánh đơn giản chỉ đạt 3/60 = 5%. Phương án cải thiện rõ nhưng vẫn là roguelike khó, nhất là với build trung bình; không nên gọi đây là cân bằng đã hoàn tất.

Món T1 trong thí nghiệm là **Đá Tam Kích**, được đảm bảo chào bán giá 12 cho lá có Chips nền cao nhất sau trận đầu; bot trả tiền, không được tặng miễn phí. Đây là giả định về một ưu đãi mở màn, không phải giá hay xác suất hiện có của shop. Không thể suy rộng kết quả này cho mọi món T1 khác.

Ở cân bằng hiện tại, cả sáu nhóm chính đều 0/40 vượt vùng đầu; do đó không run nào đi trọn 100 ải hữu hạn. Tuy nhiên, probe build mạnh có tính toán vẫn thắng 90,8% các trận độc lập ải 20. Điều này cho thấy build đủ mạnh có thể xử lý trận về sau; vấn đề lớn là đến được đó và thắng liên tiếp với tổn thất mang theo.

Đợt phủ 120 ải giải quyết 10.953 trận, đủ 360 vị trí trận. Có 65 probe chạm ngưỡng 60 tay đánh: Cơ 9, Rô 8, Chuồn 6, Bích 26, Bí Ẩn 16; các trường hợp đó không được tính thắng. Build sau ải 20 là ngoại suy của profile, nên dữ liệu này chỉ kiểm tra độ phủ và sức ép, **không phải ước tính đáng tin cậy về tỷ lệ thắng của người chơi ở các vùng sau**.

**3. Đồ mạnh trong shop còn dễ mua không?**

| Hàng hóa | Giá hiện tại |
| --- | ---: |
| Bình Máu 25 HP | 24 vàng |
| Bình Máu Lớn 60 HP | 42 vàng |
| Quân bài thường | 24 vàng |
| SPN Thường / Sử Thi / Huyền Thoại | 24 / 72 / 120 vàng |
| SPN Độc Nhất / Tối Thượng, theo catalog | 432 / 960 vàng |
| Trang bị T4–T5 trả vàng, trung vị các lượt chào bán | 966 vàng |
| Di vật chợ linh hồn | 132–252 linh hồn |

Với chỉ thưởng chiến thắng, không tiêu tiền, không cộng tiền từ kỹ năng bài/SPN, tiền trung vị là **12 sau trận 1**, **20 sau trận 2**, **41,5 sau boss ải 1**, **85 sau ải 2**, **129 sau ải 3**, **872 sau 20 ải**. Nếu mỗi trận còn dư hai lượt đánh, các mốc tương ứng là 14, 25, 49, 99, 148 và 993.

Trong 200 lộ trình tiết kiệm không có thưởng lượt đánh dư:

- 21,5% từng gặp SPN Sử Thi trở lên mà đủ tiền mua trong 9 trận đầu. Trung vị lần đầu vừa có hàng vừa đủ tiền là trận 15. Đây chưa phải đã mua, và chỉ xét nhóm tiết kiệm từ thưởng chiến thắng.
- Di vật linh hồn có trung vị lần đầu đủ tiền và có hàng ở **trận 51**, gần cuối vùng đầu. Với nhu cầu dùng linh hồn cho tiêu hao/nâng cấp, việc mua còn chậm hơn.
- Bot mua hàng đạt trung bình **2,27 món thuộc nhóm bậc cao** trên toàn bộ lộ trình 60 trận; chỉ 8% có ít nhất một món trong 9 trận đầu. “Bậc cao” ở đây là SPN E+, trang bị T4/T5, di vật linh hồn hoặc quân tiến hóa cấp 2; không bao quát mọi combo mạnh của bài/trang bị bậc thấp.

Vì vậy, xét tiền thưởng thông thường, **đồ trả tiền hiện không còn quá dễ mua ở đầu game**. Ngược lại, trước boss đầu tiên người tiết kiệm trung vị chỉ có 20 vàng, còn một bình hồi nhỏ đã giá 24. Người chơi dễ thiếu công cụ để vượt đoạn mở màn.

**Hai đường cần xử lý riêng:**

- Quầy thanh lý vẫn có 8% cơ hội miễn phí mỗi ô và có thể chọn cả T4/T5. Với hai ô, cơ hội có ít nhất một món miễn phí bất kỳ trong một lượt stock là 15,36%. Trong nhóm mua hàng, **44% lộ trình 60 trận nhận được ít nhất một món T4/T5 miễn phí**; trung bình 0,56 món bậc cao miễn phí mỗi lộ trình. Tăng giá ×6 không ảnh hưởng giá 0 này.
- Bán giấy phép di chuyển cho **1.000 vàng**, đã kiểm tra trực tiếp bằng giao dịch thật. Một khoản này tương đương giá tám SPN Huyền Thoại, hai SPN Độc Nhất hoặc một SPN Tối Thượng nếu có hàng. Sự kiện tượng cổ còn có nhánh thưởng 100–300 vàng. Các khoản này, tiền do kỹ năng, đổi chác, bán đồ, crafting và The Void **chưa được đưa vào mô hình ngân sách phía trên**, nên không thể kết luận mọi nguồn đồ mạnh đã khó tiếp cận.

Shop SPN cũng cần phân biệt “thấy hàng mạnh” và “đủ tiền”: với trọng số hiện tại, xác suất có ít nhất một SPN E+ trong sáu lá xấp xỉ 41,9%; qua ba stock độc lập là khoảng 80,4%, đổi hai lần tốn 5 + 7 = 12 vàng trước đặc quyền. Người đã tích đủ tiền có thể tìm món mạnh khá nhanh.

**4. Phương án nên thử tiếp**

1. **Mở đầu 100 HP**, giữ bộ 5 lá đủ 4 chất và tay 3 lá. Cấu hình đã thử: Small HP 100 → 160 → 256 → 410 → 656, sau đó ×1,50 mỗi ải đến ải 20, đạt **287.315 HP**; Big ×1,5 và Boss ×2. Đây là phương án có dữ liệu so sánh, chưa được kiểm chứng cân bằng khi đi sang vương quốc khác.
2. **Một ưu đãi mở màn có kiểm soát:** sau trận đầu đảm bảo một món T1 hữu ích giá 12, chỉ mua một lần trong run. Mô phỏng đã thử Đá Tam Kích; cần thử thêm các lựa chọn tương đương trước khi mở rộng danh sách. Cách này tạo quyết định mua đồ hay hồi phục, thay vì bắt người chơi chờ roll được hàng phù hợp.
3. **Tách giá theo vai trò và tiền tệ.** Thử vàng ×4 cho vật liệu, SPN thấp và quân thường; riêng bình hồi 25 HP khoảng 12 vàng, bình lớn khoảng 21. Giữ SPN E/L ở 72/120 thay vì hạ theo cùng hệ số. Với T4/T5, tính niêm yết theo khoảng 1,25–1,5 lần **tổng chi phí ghép thật ở giá vật liệu hiện tại**, tránh nhân thêm cả hệ số ×6 lên giá catalog đã gồm phí hàng chế sẵn. Các giá đề xuất này mới được đối chiếu khả năng chi trả, chưa chạy chiến dịch với bot mua/ghép đồ tối ưu.
4. **Đóng đường đồ mạnh miễn phí:** hàng miễn phí chỉ gồm vật liệu hoặc T1; T2+ vẫn có thể giảm giá nhưng tối thiểu phải trả tiền. Nếu muốn giữ quà T4/T5, cho vào thưởng chinh phục có mốc và số lượng rõ ràng.
5. **Giới hạn bậc xuất hiện thay vì chỉ tăng giá:** thử mở E từ ải 3, L từ ải 6, M từ ải 10, T/UQ từ ải 15; VH/TT dành cho sau vùng đầu. Đây là đề xuất chưa đo lại, cần kiểm tra cùng tiến hóa và các nguồn thưởng khác để không chặn build hợp lệ.
6. **Chợ linh hồn thử hệ số ×2**, tức di vật khoảng 44–84 LH, để có thể chọn món đầu trong khoảng giữa vùng thay vì chờ tới trận 51. Shop máu cần bảng giá riêng theo sức mạnh ×5: có thể thử vật liệu khoảng 32 HP, SPN Thường khoảng 64 HP; thuốc hồi/giường phải định giá hoặc giới hạn riêng để không tạo vòng mua rồi hồi lại chính lượng HP đã trả.
7. **Cân lại thưởng tiền lớn:** thử tiền bán giấy phép khoảng 200–250 thay vì 1.000, hoặc giữ thưởng lớn nhưng giới hạn hàng bậc cao theo mốc. Đây là lựa chọn thiết kế cần chốt trước khi tiếp tục tăng giá shop đại trà.

Ưu tiên của mình là thử **100 HP + đường cong chậm hơn + ưu đãi T1 mở màn**, đồng thời loại T4/T5 khỏi hàng miễn phí. Sau đó mới chỉnh bảng giá theo nhóm. Nhánh chỉ hạ vài ải đầu rồi quay lại đường cong hiện tại vẫn 0/40 cả build mạnh, nên chỉ đổi con số mở màn là chưa đủ trong mô hình này.

**Giới hạn và kiểm chứng**

Đây là bot, không phải kết quả chơi của người thật hoặc bộ tìm chiến thuật tối ưu. Mô hình chiến đấu và mô hình kinh tế tách nhau; chưa mô phỏng tự động toàn bộ vòng mua → ghép → thay đồ → đánh với mọi lựa chọn, chưa lượng hóa các nguồn tiền sự kiện. Vùng vô tận chỉ lấy mẫu 20 ải đầu. Vì nhóm trung bình của phương án tốt nhất vẫn chỉ 1/60, cần thêm một lượt thử có kinh tế và nâng cấp thật trước khi chốt độ khó phát hành.

Các tự kiểm tra cấu hình, bộ bài, trả đúng tiền mua và phân tích CSV đã qua. Phép kiểm tra giao dịch bán giấy phép riêng đã qua. `tests/journey_routing_smoke.lua` đang dừng ở khẳng định dòng 46 trong trạng thái repo hiện có; không tính bộ kiểm tra đó là đã qua và không sửa gameplay để làm báo cáo này.

**Dữ liệu và tái chạy**

- [Tổng hợp mở đầu/kinh tế/shop](balance_audit_new_summary.json), [trận mở đầu](balance_audit_new_opening.csv), [dòng tiền](balance_audit_new_economy.csv), [stock shop nén](balance_audit_new_offers.csv.gz).
- [Cân bằng hiện tại](balance_new_150.json), [100 HP và đường cong mềm](balance_proposal_100.json), [thêm ưu đãi T1](balance_proposal_kit.json), [20 seed kiểm chứng mới](balance_proposal_holdout.json), [chỉ mềm đoạn đầu](balance_proposal_bridge.json).
- [Dữ liệu phủ 120 ải](balance_world_120.csv), [tổng hợp phạm vi](balance_world_120_summary.json).
- Bộ chạy: [campaign_balance_sim.lua](../tests/campaign_balance_sim.lua), [balance_new_audit.lua](../tests/balance_new_audit.lua), [report_balance_audit.py](../tools/report_balance_audit.py).

```powershell
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-seeds=40 --sim-out=docs/balance_new_150
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-audit --sim-seeds=200 --sim-out=docs/balance_audit_new
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-proposal-kit --sim-seeds=40 --sim-out=docs/balance_proposal_kit
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-proposal-kit --sim-seeds=20 --sim-offset=50000 --sim-out=docs/balance_proposal_holdout
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-world --sim-seeds=5 --sim-out=docs/balance_world_120
python tools/report_balance_audit.py docs/balance_audit_new
```

Các tùy chọn đề xuất thay hàm HP và ưu đãi trong tiến trình mô phỏng riêng; không ghi vào mã cân bằng hoặc save của người chơi.

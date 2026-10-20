# Mô phỏng và cân bằng ải 1–20

**Đã có bản áp dụng và kiểm chứng mới:** [BALANCE_APPLIED_REPORT.md](BALANCE_APPLIED_REPORT.md). Các số liệu bên dưới là lịch sử.

Lưu ý: số liệu bên dưới là ảnh chụp cân bằng trước đợt đổi sang 150 HP mở đầu, bộ bài khởi đầu 5 lá đủ 4 chất/tay bài 3 lá và hệ số giá shop ×6. Đợt thử mới nằm trong [BALANCE_AUDIT_NEW.md](BALANCE_AUDIT_NEW.md); không dùng tỷ lệ thắng cũ để kết luận độ khó hiện tại.

Ngày kiểm tra: 20/10/2026. **720 lượt chạy chiến dịch, 63.484 trận** dùng combat và chấm điểm thật. Một run phải thắng đủ 60 trận để hoàn thành; chết thì dừng, không hồi sinh để đi tiếp. Ngoài ra có các trận kiểm tra độc lập ở đủ 20 ải, tránh chỉ đo được đoạn đầu của những run chết sớm.

## Kết quả vượt đủ 20 ải

Mỗi ô là 40 run. Cột trước/sau dùng cùng seed 10001–10040. Cột kiểm chứng dùng seed mới 60001–60040, chỉ chạy sau khi chốt thông số; không dùng để tiếp tục chỉnh.

| Build / cách đánh | Trước chỉnh | Sau chỉnh | Kiểm chứng seed mới |
| --- | ---: | ---: | ---: |
| Yếu / tối đa sát thương | 0/40 | 0/40 | 0/40 |
| Yếu / có tính toán | 0/40 | 0/40 | 0/40 |
| Trung bình / tối đa sát thương | 0/40 | 0/40 | 0/40 |
| Trung bình / có tính toán | 0/40 | **7/40 (17,5%)** | **5/40 (12,5%)** |
| Mạnh / tối đa sát thương | 1/40 (2,5%) | 17/40 (42,5%) | 11/40 (27,5%) |
| Mạnh / có tính toán | 19/40 (47,5%) | **36/40 (90%)** | **37/40 (92,5%)** |

Gộp hai bộ seed sau chỉnh: build trung bình có tính toán đạt **12/80 = 15%**, khoảng tin cậy Wilson 95% **8,8–24,4%**; build mạnh có tính toán **73/80 = 91,25%**, khoảng **83,0–95,7%**. Đây là tỷ lệ của các bot và lộ trình build bên dưới, không phải tỷ lệ thắng của người chơi thật.

Build trung bình đi trung bình khoảng **12,85 ải trọn vẹn** trước khi thất bại/hoàn thành, so với khoảng **6,29 ải** khi chỉ ưu tiên sát thương. Vì phải vượt 60 trận với tổn thất tích lũy, tỷ lệ vượt cả vùng thấp hơn nhiều so với tỷ lệ thắng một trận riêng lẻ.

## Oneshot và độ khó cuối vùng

- Trong các trận kiểm tra độc lập ải 20 sau chỉnh, build mạnh có **456 lần hạ mục tiêu bằng đòn gây thương tổn đầu tiên / 507 đòn trúng**, xấp xỉ **89,94%**. Chỉ tính một lần hạ nếu mục tiêu chưa nhận đòn gây thương tổn trước đó; đánh hụt không được tính là đòn gây thương tổn. Đây không phải tỷ lệ thắng trận ngay lượt một: đội hình có nhiều địch, boss có điều kiện phá giáp hoặc yêu cầu đúng thế bài.
- Build trung bình có tính toán thắng **90,8% / 92,5%** các trận kiểm tra riêng ải 20 trên hai bộ seed. Tuy nhiên hao máu, cướp tốc, mất SPN/lá bài khiến nó khó vượt trọn vùng.
- Trong kiểm tra độc lập ải 20, Aura trung bình mỗi trận của ba build sau chỉnh lần lượt khoảng **75–86 nghìn**, **496–500 nghìn**, **1,02–1,15 triệu**; phụ thuộc tay bài, SPN còn lại và thời điểm hạ địch. Các con số này được đo từ `Scoring.calculate`, không gán trực tiếp vào sát thương.
- Cả 63.484 trận đều không chạm giới hạn an toàn 60 lượt đánh. Kiểm tra hồi quy riêng vẫn xác nhận tình huống 7 sát thương đầu game kết thúc trong 6 lượt.

## Đã thay đổi trong game

1. **Dốc HP:** giữ nguyên ải 1–5; độ khó 6–20 tăng 64% mỗi ải thay vì 71%, vẫn làm tròn từng bước. HP nền ải 20: địch thường **302.370**, tinh anh **453.555**, boss **604.740**, trước trang bị/nội tại/đội hình. Sau mốc 20 tăng lại 71% từ nền mới; độ cân bằng các vùng sau 20 chưa được mô phỏng ở đây.
2. **Boss xuất hiện theo mức chuẩn bị:** boss 1/5 từ ải 1; boss 3 từ 4; boss 4/9 từ 5; boss 2/6 từ 6; boss 7/8 từ 8; boss 10 từ 10. Chọn ngẫu nhiên trong nhóm đã mở, không thay đổi theo Aura người chơi. Boss đã lưu giữ nguyên danh tính dù chưa tới mốc mở mới.
3. **Thẩm Phán:** chỉ định thế đã mở khóa và ghép được từ tay đang cầm. Vẫn bắt buộc chọn đúng thế; thuốc chính xác không vượt qua luật này. Với tay quá lớn do thuốc/SPN, tìm tập con trong tối đa 10 lá đầu, tối đa 5 lá mỗi thế để tránh làm khựng game; mọi thế được đưa ra đều ghép được.
4. **Bù chỉ số cho cơ chế mạnh:** boss 2 có 80% HP / 80% ST nền; boss 5 có 90% HP / 65% ST trước phép nhân số lá; boss 6 có 90% HP / 90% ST trước lớp giáp bằng HP. Boss ải 1–3 có 85% ST nền. Không đổi cướp 2 tốc vĩnh viễn, giảm 1 ô tay, xóa bài/SPN, hồi 5%, hệ số vàng hoặc các nội tại đã chốt.

Trang bị, finite healing, số lần buff, xác suất trúng hai phía và AI phối hợp từ lần nâng cấp trước vẫn giữ. Không thêm giới hạn sát thương nhận hoặc miễn chết để cản oneshot. Lớp giáp đặc biệt boss 6 vẫn yêu cầu người chơi có giáp.

## Mô hình và giới hạn

Đây là **mô phỏng chiến đấu với build tăng trưởng có kiểm soát**, không phải bot tự mua mọi shop/phần thưởng theo RNG. Không đổi profile hay bot giữa các cột trước/sau/kiểm chứng.

- Ba profile bơm bonus Chips trên mỗi lá ở mốc 20 là **2.488 / 13.988 / 69.988**, tăng theo đường cong trong script, chưa tính phần tăng thêm từ khả năng; khả năng riêng của lá, trang bị, SPN và chấm điểm vẫn chạy thật. Bonus tốc đích tương ứng **4 / 16 / 28**, cộng vào tốc theo rank. Các hao hụt tốc/lá bài/SPN vĩnh viễn giữ xuyên run.
- Khởi đầu dùng đúng một lá Red Deck ngẫu nhiên. Sau trận đầu có thêm một lá và gắn Đá Tam Kích cho lá đầu, trừ 4 vàng. Tiếp tục tăng kho bài theo mốc, tối đa 12 lá đã nhận; lá bị phá không tự sinh lại. Từ ải 2 mỗi lá được gắn Đá Tam Kích theo kịch bản build. Mở Đôi/Sám/Sảnh từ 3, Hai Đôi/Thùng từ 12; không nâng cấp thế bài tự do để ép thắng.
- HP nền đi từ 100 đến 500. Tăng trần chỉ hồi phần HP tăng thêm; không hồi đầy giữa trận. Mỗi ải có ngân sách tối đa hai bình hồi 60 HP, mỗi bình giá 7 vàng; bot chỉ dùng giữa các trận khi thực thiếu ít nhất 60 HP và đủ vàng. Không có hồi đầy miễn phí sau boss.
- Mỗi ải cấp lại một thuốc chính xác, một thuốc né, một bình giáp nhỏ 8 giáp. SPN Blade/Drum/Pebble được cấp một lần tại mốc 4/9/14; mất do boss thì không tự được cấp lại ở cùng mốc. Đây là giả định tiếp tế theo kịch bản, không mô phỏng tỷ lệ xuất hiện của shop.
- Bot tối đa sát thương xét các tập con tay bài, chọn lượng Chips × Mult ước tính lớn nhất, đánh mục tiêu hiện tại, không dùng thuốc chiến thuật. Bot có tính toán còn xét tốc/chính xác, chọn mục tiêu, tránh giết con tin, theo luật Thẩm Phán, bỏ bài khi cần, dùng thuốc giáp/chính xác/né đúng điều kiện. Bot dùng ước lượng để chọn bài, không tìm chiến lược tối ưu toàn cục.
- Các trận kiểm tra độc lập khởi tạo đầy máu ở từng ải và không mang tổn thất từ ải trước. Chúng phục vụ đo độ khó cục bộ; chỉ bảng chiến dịch mang HP và tổn thất thật xuyên 60 trận.
- Ba profile chủ yếu khác về tăng trưởng Chips/tốc, dùng bộ trang bị/SPN giản lược giống nhau. Script không tự cấp cấp tiến hóa cao và không quản lý một balo dự trữ đầy đồ. Vì vậy tác động kinh tế lâu dài của boss 10 bán đồ và tác động hạ cấp lên build tiến hóa cao chưa được đo đầy đủ; các cơ chế này vẫn có unit test thực thi riêng.

**Nhận định:** đã tạo được khoảng cách rõ giữa cách đánh đơn giản và cách đánh có tính toán; build mạnh vẫn được thưởng bằng oneshot. Mức hiện tại vẫn nghiêng về roguelike khó với build trung bình. Cần dữ liệu chơi thật và mô phỏng kinh tế/shop trước khi khẳng định tỷ lệ thắng phù hợp cho mọi người chơi.

## Tái chạy và dữ liệu

Chạy tại thư mục project với LÖVE 11.5:

```powershell
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-before --sim-seeds=40 --sim-out=docs/balance_before
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-seeds=40 --sim-out=docs/balance_after
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-seeds=40 --sim-offset=50000 --sim-out=docs/balance_holdout
python tools/summarize_campaign_balance.py docs/balance_before.csv docs/balance_after.csv docs/balance_holdout.csv
& '..\love-11.5-win64\lovec.exe' . --test-campaign-balance
```

`--sim-before` tái dựng quy tắc trước hiệu chỉnh trong bộ nhớ riêng của trình mô phỏng. Không ghi đè code game hoặc save người chơi. Mô phỏng dùng identity LÖVE riêng và tắt ghi tự động từ boss.

- `tests/campaign_balance_sim.lua`: bot, tăng trưởng build, vòng đời thật của trận/tay/lượt, probe và xuất CSV.
- `tools/summarize_campaign_balance.py`: tổng hợp từng ải, từng boss, kiểu build, kiểu chơi, tỷ lệ và khoảng tin cậy.
- `docs/balance_before.csv`, `docs/balance_after.csv`, `docs/balance_holdout.csv`: từng trận, seed, HP, Aura, sát thương địch, hụt và oneshot.
- Các file `_summary.csv` chứa từng nhóm chiến dịch; `.json` chứa tổng hợp từng ải và từng boss.

Kiểm tra hồi quy đã qua: 10 boss, bộ trang bị/AI, chính xác, hồi/buff hữu hạn, đội hình/nhịp tiếp xúc, oneshot 500K, HP gấp đôi của Lãnh Địa Máu, và lưu/tải qua các mốc hành trình.

# Cân bằng đã áp dụng và kiểm chứng lại

**Cập nhật 21/10/2026:** ba trận ải 1 là 50/100/150 HP, nền HP bắt đầu 50 và các ải sau tăng theo đường cong hiện có (trận lớn ×2, boss ×3); hai ô SPN/trang bị của Shop Nhỏ đổi chỗ theo mỗi reroll thành công; lễ trao thưởng bỏ rương quân bài, giữ quân bài lẻ. Số liệu mô phỏng bên dưới thuộc cấu hình ngày 20/10, chưa chạy lại cho thay đổi này.

Ngày: 20/10/2026. Chạy bằng LÖVE 11.5, dùng RNG, chấm điểm, AI và chiến đấu thật của game. Báo cáo này thay thế kết luận của [đợt 150 HP / giá ×6](BALANCE_AUDIT_NEW.md).

## Cấu hình đã đưa vào game

- Quái mở đầu **100 HP**; bộ khởi đầu giữ **5 lá đủ 4 chất, rút 3 lá**.
- HP trận nhỏ: ×1,50 mỗi ải từ ải 2–5; ×1,45 từ ải 6–20; ×1,50 từ ải 21 trở đi. Mỗi bước làm tròn; trận lớn ×1,5, boss ×2 trước cơ chế riêng/trang bị của quái. HP trận nhỏ ở ải 5/10/20 là **507 / 3.251 / 133.565**.
- Sau trận thắng: ải 1–5 hồi **20% HP tối đa**, boss **40%**; từ ải 6 hồi **15%**, boss **30%**. Không vượt HP tối đa, không cộng lặp khi mở lại phần thưởng. Lễ trao thưởng hiện lượng HP thực được hồi.
- Boss Nhân Loại: hệ số sát thương bổ sung **0,40** ở ải 1–5, **0,55** ở ải 6–20; sau đó trở lại 1. Các hệ số riêng của từng boss vẫn áp dụng. Đây không phải giảm sát thương của toàn bộ quái.
- Chủ Hội Kim Quyền vẫn nhận ×1,5 theo từng 10 vàng nhưng tối đa **6 lần tăng**, thay vì tăng không giới hạn theo tiền tích trữ.
- Shop đầu sau trận đầu luôn là Shop Nhỏ, có **Đá Tam Kích T1 giá 12 vàng**, mua tối đa một lần/run. Reroll không làm mất ưu đãi chưa mua; mua xong và tải save không tạo lại ưu đãi.

### Giá và nguồn đồ mạnh

| Nhóm | Giá cuối |
| --- | --- |
| Vật liệu, SPN thấp, quân bài và phần lớn hàng trả vàng | Giá gốc ×4 |
| Bình Máu 25 / 60 HP | 12 / 21 vàng |
| SPN Sử Thi / Huyền Thoại | 72 / 120 vàng |
| Trang bị chế sẵn trả vàng | 1,35 × tổng giá mua nguyên liệu hiện tại và phí ghép theo cây công thức |
| Di vật linh hồn | 44–84 linh hồn |
| Shop Máu: Tấm Sắt / SPN Thường | 32 / 64 HP; sức mạnh ×5 |
| Thuốc hồi trong Shop Máu | Giá HP lớn hơn lượng HP thuốc hồi; không sinh Giường trong stock |
| Bán giấy phép di chuyển | 250 vàng |
| Reroll trả vàng | 5 → 7 → 10 → 14 → 19… trước đặc quyền |

SPN mở theo ải toàn run: **E từ 3, L từ 6, M từ 10, T/UQ từ 15, VH/TT từ 21**. Trọng số được chuẩn hóa lại trong các bậc đã mở. Các nguồn tiến hóa khác vẫn có tác dụng. Hàng thanh lý chỉ được miễn phí nếu là vật liệu hoặc T1; T2–T5 vẫn có thể giảm giá nhưng phải trả tiền.

## Cách kiểm chứng

Mô phỏng dùng ba tiến trình build yếu / trung bình / mạnh, với bot tham sát thương và bot chiến thuật. Bot chiến thuật dự đoán sát thương thật, xét mục tiêu, tốc đánh, thế bài bắt buộc và thuốc đang mang. Ở tay lớn, bot lọc 16 ứng viên tốt nhất theo ước lượng rồi mới tính dự đoán thật; không phải bộ tìm chiến thuật tối ưu. Bot mua thuốc và một nâng cấp hữu ích mỗi lượt ghé shop, trả tiền thật, gắn đồ vào lá sở hữu và giữ HP/vàng qua các trận. Không hồi sinh để đi tiếp khi thua.

**Tiến trình build vẫn là giả định kiểm soát:** sát thương nền, tốc, HP tối đa, số lá, một số thế bài và SPN được tăng theo mốc định sẵn. Đây chưa phải bot tự xây build hoàn toàn từ mọi phần thưởng. Bot chưa tối ưu ghép đồ, mở mọi rương, đổi chác, tượng cổ, The Void hoặc bán đồ; các trận kiểm tra độc lập dùng build mẫu được hồi đầy trước trận, không tính là chiến dịch đã vượt.

Mốc ải 20 của ba mẫu có ngân sách sát thương nền lần lượt 2.500 / 14.000 / 70.000, tốc 12 / 24 / 36; HP mẫu tăng từ 100 lên 500 trước nâng cấp mua thêm. Mẫu còn được gắn Đá Tam Kích từ ải 2 và nhận SPN cơ bản theo mốc 4/9/14. Các phần cấp sẵn này không trừ vàng; chỉ thuốc và nâng cấp do bot mua mới dùng giá shop thật. Vì vậy tỷ lệ bên dưới đo độ khó đối với các đường phát triển giả định, chưa chứng minh người chơi có thể kiếm đúng build đó từ nền kinh tế hiện tại. Sau ải 20, mô hình tiếp tục ngoại suy tiến trình; kết luận các vùng sau có độ chắc chắn thấp hơn.

Tuyến chạy cố định: Nhân Loại → Cơ → Rô → Chuồn → Bích, 20 ải/vùng, sau đó lấy mẫu 20 ải Bí Ẩn. Đây là tuyến giả định để kiểm tra mọi vùng; chưa mô phỏng đầy đủ thao tác chọn giấy phép/công nhận khi chuyển vùng. Không thể kiểm tra toàn bộ vùng vô tận.

## Kết quả chiến dịch

Chỉ thống kê các lượt đã hoàn tất, chết thì dừng. Mẫu chính tập trung vào build trung bình; build mạnh dùng làm đối chiếu và kiểm tra khả năng đi hết tuyến. Các batch nhiều profile bị dừng trước khi kết thúc nhóm build mạnh không được cộng vào mẫu báo cáo.

| Build trung bình / chiến thuật | Vượt ải 1 | Vượt ải 10 | Vượt đủ 20 ải đầu | Số ải vượt trung bình, chặn tại 20 |
| --- | ---: | ---: | ---: | ---: |
| Đối chứng: gói đề xuất HP 100, ×1,60/×1,50; chưa thêm nghỉ/ngưỡng ST boss mới | 27/40 | 1/40 | 0/40 | 1,98 |
| Cấu hình cuối, 40 seed chính | 30/40 | 14/40 | **7/40 = 17,5%** | **8,38** |
| Cấu hình cuối, 20 seed mới | 17/20 | 8/20 | **3/20 = 15%** | **8,60** |
| Cấu hình cuối, gộp 60 seed | 47/60 | 22/60 | **10/60 = 16,7%** | **8,45** |

Đối chứng dùng cùng thuật toán mua/chọn bài và bảng giá mới, nhưng đường HP/áp lực boss trước tinh chỉnh bổ sung, không có nghỉ sau thắng. Không so trực tiếp tỷ lệ này với mô hình kinh tế tách rời trong báo cáo cũ. Khoảng Wilson 95% cho tỷ lệ vượt 20 ải của cấu hình cuối là **9,3–28,0%**; đây vẫn là ước lượng từ bot.

**Giới hạn còn rõ:** build trung bình đi xa nhất **ải 38**, trung bình **9,68 ải** trên tuyến dài; **0/60 vượt đủ 100 ải**, và 0/60 hoàn tất 120 ải thử. Cả 10 lượt đã vượt vùng đầu đều dừng trong vùng Cơ. Không có lượt chiến dịch trung bình nào chạm giới hạn 60 tay/trận. Các chỉnh sửa đã giúp đi qua nhiều ải hơn, nhưng chưa đủ căn cứ nói build trung bình có thể hoàn thành toàn chiến dịch ổn định.

Build mạnh có **3/6 lượt** thắng liên tục đủ 100 ải và cả 20 ải Bí Ẩn lấy mẫu: 1/3 seed chính và 2/3 seed mới. Cả ba lượt vượt vùng đầu đều đi hết tuyến thử. Mẫu đối chiếu nhỏ hơn nhiều so với mẫu trung bình; không dùng tỷ lệ này làm tỷ lệ thắng dự đoán cho người chơi.


### Probe độc lập mọi vùng

Mỗi ô sau là kết quả **180 trận/vùng/build**: 3 seed × 20 ải × 3 trận. Hồi đầy trước mỗi trận; đây là kiểm tra khả năng xử lý từng trận, không có hao mòn liên trận hoặc quá trình kiếm nâng cấp.

| Vùng | Trung bình / chiến thuật | Mạnh / chiến thuật |
| --- | ---: | ---: |
| Nhân Loại | 97,8% | 98,9% |
| Cơ | 96,1% | 100% |
| Rô | 94,4% | 100% |
| Chuồn | 73,3% | 100% |
| Bích | 50,6% | 100% |
| Bí Ẩn, 20 ải lấy mẫu | 14,4% | 100% |

Không có trận nào trong 2.160 probe chạm giới hạn 60 tay. Mẫu 3 seed chủ yếu xác nhận phủ đủ vị trí; chưa đủ để ước lượng chính xác tỷ lệ thắng của người chơi từng vùng.

**Hướng cân bằng sau đợt này:** ưu tiên kiểm tra nhịp kiếm nâng cấp thật ở vùng Cơ (các run trung bình thực tế đều dừng tại đây), rồi Chuồn/Bích trong probe. Giữ đồ bậc cao bị chặn ở đầu game, không giảm tiếp HP toàn chiến dịch: build mạnh đã thắng gần như mọi probe cuối game. Điểm cần playtest tiếp là nhịp kiếm nâng cấp và hồi phục khi bước sang Chuồn/Bích, đặc biệt các build thiếu giáp/tốc hoặc chịu mất bài/SPN. Chưa nên coi build trung bình là đã ổn định ở toàn bộ 100 ải.

## Mở đầu và kinh tế: 200 seed

- Trận đầu 100 HP: **200/200** thắng với cả hai bot. Bot chiến thuật dùng trung vị **4,5 tay đánh**; bot tham sát thương **12 tay**. Một số trận vẫn kéo dài; không thể dùng tỷ lệ thắng để kết luận trải nghiệm đã ngắn gọn.
- Thắng cả ba trận ải 1, **chưa mua đồ giữa trận**: bot chiến thuật **107/200 = 53,5%**, bot tham sát thương **50/200 = 25%**. Có thuốc khởi đầu và hồi phục sau thắng. Đây là phép đo tách biệt với chiến dịch có mua đồ.
- Trong 200 lộ trình kinh tế giả định thắng đủ 60 trận, bot mua hàng chỉ **0,5%** có món thuộc nhóm bậc cao trong 9 trận đầu; cuối vùng mua trung bình **3,55 món**. Nhóm này gồm SPN E+, trang bị T4/T5, di vật linh hồn và quân tiến hóa cấp 2; không bao quát mọi combo mạnh của đồ thấp.
- **Không ghi nhận T4/T5 miễn phí** trong 592.387 lượt chào bán đã đo. Kiểm tra định giá riêng cũng ép roll miễn phí cho toàn catalog và xác nhận T2+ luôn có giá dương.
- Với bot chỉ tích tiền thưởng: 14,5% lộ trình từng gặp SPN E+ và đủ tiền trong 9 trận đầu; trung vị lần đầu là trận **18**. T4/T5 tương ứng **3%**, trung vị trận **18**. Đây là khả năng mua khi có hàng, chưa phải đã mua.
- Di vật linh hồn: trung vị bắt đầu đủ tiền và có hàng ở trận **18**, so với trận 51 trong báo cáo cũ. Trang bị T4/T5 trả vàng có giá niêm yết trung vị **362 vàng**, so với 966 trước đây; đã loại đường nhận miễn phí, nhưng hàng cao cấp trở nên có thể mua ở giữa vùng.

**Đánh giá shop:** vật tư và hồi phục dễ tiếp cận hơn; đồ bậc cao vẫn hiếm ở đầu game. Ở cuối vùng, người tích tiền có thể mua đồ mạnh — đây là nhịp tiến triển chủ ý. Kinh tế trên chỉ có thưởng chiến thắng, không gồm vàng do mọi kỹ năng/sự kiện; chưa kết luận mọi nguồn kiếm đồ mạnh đã cân bằng.

## Kiểm tra hồi quy

Đã qua: `--test-campaign-balance`, `--test-shop-vouchers`, `--test-backpack`, `--test-soul-market` và kiểm tra khởi đầu 200 bộ bài. Bao gồm boss/AI, đội hình, HP, tiền thực trả, công thức ghép, voucher, lưu/tải, hồi phục không cộng lặp, ưu đãi T1 một lần và thuốc Shop Máu không tự hoàn lại HP đã trả.

Đã sửa thêm vòng giữ context dự đoán sát thương: bảng liên kết lá → game dùng cả khóa và giá trị yếu. LuaJIT trước đó giữ cả game bản sao qua vòng tham chiếu, khiến mô phỏng hết bộ nhớ. Có kiểm tra thu gom context; lượt thử cùng mẫu giảm từ hàng trăm MB tăng dần xuống khoảng 3–6 MB Lua heap.

Hai bộ kiểm tra cũ vẫn dừng ở lỗi đã có trước đợt này: `tests/journey_routing_smoke.lua:46` và phần phù phép đã bỏ ở `tests/soul_shop_smoke.lua:133`. Fixture giá liên quan đã cập nhật; không tính hai bộ này là đã qua.

## Dữ liệu và chạy lại

- [Đối chứng cùng bot, 40 seed](balance_proposal_control.csv).
- [Build trung bình, 40 seed chính](balance_final_normal.csv), [20 seed mới](balance_final_normal_holdout.csv), [build mạnh, seed mới](balance_final_strong_holdout.csv).
- [Probe mọi vị trí với build trung bình](balance_final_world_probes.csv), [build mạnh](balance_final_strong_probes.csv).
- [Tổng hợp cuối](balance_final_summary.json), [tổng hợp 60 lượt trung bình](balance_final_normal_summary.json), [phủ mọi vùng](balance_final_probes_summary.json), [mở đầu/kinh tế/shop](balance_final_audit_summary.json).

```powershell
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-supplies --sim-no-probes --sim-seeds=40 --sim-proposal --sim-no-rest --sim-original-pressure --sim-out=docs/balance_proposal_control
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-supplies --sim-no-probes --sim-world --sim-seeds=40 --sim-profile=normal --sim-policy=tactical --sim-out=docs/balance_final_normal
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-supplies --sim-no-probes --sim-world --sim-seeds=20 --sim-offset=50000 --sim-profile=normal --sim-policy=tactical --sim-out=docs/balance_final_normal_holdout
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-supplies --sim-world --sim-seeds=3 --sim-profile=normal --sim-policy=tactical --sim-out=docs/balance_final_world_probes
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-supplies --sim-world --sim-seeds=3 --sim-profile=strong --sim-policy=tactical --sim-out=docs/balance_final_strong_probes
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-supplies --sim-no-probes --sim-world --sim-seeds=3 --sim-offset=50000 --sim-profile=strong --sim-policy=tactical --sim-out=docs/balance_final_strong_holdout
& '..\love-11.5-win64\lovec.exe' . --simulate-campaign-balance --sim-audit --sim-seeds=200 --sim-out=docs/balance_final_audit
python tools/report_applied_balance.py docs/balance_final_summary.json docs/balance_final_normal.csv docs/balance_final_normal_holdout.csv docs/balance_final_strong_probes.csv docs/balance_final_strong_holdout.csv
python tools/report_balance_audit.py docs/balance_final_audit
```

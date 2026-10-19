# Tượng Cổ & Lãnh Địa Máu

Ở cuối ải chẵn, sau boss và shop: Tượng Cổ có 30% cơ hội xuất hiện, xét độc lập với Người Viễn Chinh Bí Ẩn. Nếu gặp cả hai, trao đổi trước, tượng sau. Mỗi mốc chỉ kiểm tra một lần. Lưu/tải giữ kết quả xuất hiện, lá được chọn, số lần chạm và kết quả đã trao; không bốc lại kết quả cũ.

Chọn một quân bài thật trong bộ rồi chạm tượng. Mỗi lần trừ chính xác 10% HP hiện tại, bỏ qua giáp và giảm sát thương, không hồi lại phí. Có thể đổi lá giữa các lần hoặc rời tượng trước ngưỡng dịch chuyển. Kết quả được áp dụng vĩnh viễn và đồng bộ bản gốc/các cọc. Mỗi kết quả dưới đây có tỷ lệ 10%, công khai trong nút Kết Quả:

| Kết quả | Hiệu lực |
| --- | --- |
| Sát thương | +5 ST cơ bản |
| Tốc đánh | +3 Tốc |
| Tiến hóa | +1 cấp, theo trần tiến hóa hiện có |
| Nhân đôi | ×2 ST cơ bản, tốc/khả năng/vai trò; giữ rank/chất và giới hạn hệ thống |
| Nhân bản | Thêm 3 bản sao có ID mới, giữ tiến hóa, ấn bản và trang bị |
| Trừ sát thương | −5 ST cơ bản, tối thiểu 1 |
| Trừ tốc | −3 Tốc vĩnh viễn, tốc cuối cùng tối thiểu 1 |
| Trừ cấp | −1 tiến hóa, tối thiểu 0 |
| Vàng | 100–300 vàng, chọn đều |
| Trống rỗng | Không nhận gì, vẫn mất phí máu |

Ngay sau lần chạm đưa HP xuống ≤10% HP tối đa, dịch chuyển vào Lãnh Địa Máu. Từ 100/100 HP, lần chạm thứ 22 vượt ngưỡng này. Không tự làm tròn phí thành một HP tối thiểu và không gây chết do làm tròn.

## Tám trận trong lãnh địa

Khu vực bí mật có đúng tám trận, một trận mỗi ải. Mỗi ải có loài địch và tranh riêng; ải 8 duy nhất là boss Vương Huyết. Nhóm địch dùng hệ thống tối đa ba đối thủ hiện có. Nền Hồ Huyết Thạch dùng cho ải 1–4, Thánh Điện Vương Huyết cho ải 5–8. Có màn chọn trận riêng với tiến độ tám mốc.

| Ải | Cấp | Địch | Đặc điểm chiến đấu |
| --- | --- | --- | --- |
| 1 | 2 | Huyết Khuyển | +20% sát thương mỗi đồng đội còn sống |
| 2 | 4 | Vệ Binh Huyết Thạch | Giáp đầu trận 12% HP, tái tạo giáp hữu hạn |
| 3 | 6 | Tiên Tri Huyết Vụ | Mỗi 2 đòn lấy 1 Vàng; khi bạn hết vàng, +15% sát thương |
| 4 | 8 | Đỉa Chúa Huyết Hồ | Hút sinh mệnh qua sát thương, dự trữ hồi máu hữu hạn |
| 5 | 10 | Đao Phủ Huyết Ngục | +35% sát thương khi bạn còn dưới 40% HP tối đa |
| 6 | J | Nhện Dệt Huyết Chú | Đòn gây HP thực thêm 2 Độc, tối đa 6; giảm 1 mỗi tay |
| 7 | Q | Thạch Quỷ Huyết Dực | Hồi sinh một lần với 25% HP |
| 8 | K | Vương Huyết | Bạn hồi máu thì nhân đôi Máu/Tốc/ST; trừ 2% HP mỗi lượt |

Danh mục và mô tả trong game cùng lấy từ `src/ancient_statue.lua`; các đặc điểm dùng cơ chế địch sẵn có, giữ chung giới hạn hồi máu và giáp. Bốn tranh mới thay các loài bị lặp ở ải 4–7. Ảnh kiểm tra đủ tám lá với khung/rank thực tế: `docs/blood_enemies_roster.png`.

Giữa các trận có shop nhỏ; không sinh thêm Tượng Cổ, Void, Người Viễn Chinh hoặc Shop Máu trong lãnh địa. Không thể dùng giấy phép thoát khỏi lãnh địa. Hành trình gốc được giữ riêng; chặng phụ không tiêu hao tiến độ vùng hoặc phát thêm giấy công nhận. Thắng boss, chọn phần thưởng rồi trở lại sau ải gốc vừa hoàn thành.

### Độ khó gấp đôi nhánh chính

Cả tám trận lấy mốc độ khó thực tế của nhánh chính lúc bước vào làm chuẩn cố định. Nếu nhánh chính đang giữ độ khó ở một ải đã chinh phục thì dùng mốc đã khóa, không lấy số ải hiển thị đang tăng. Máu, sát thương và tốc đánh cơ bản của địch bằng ×2 đối thủ cùng loại tại mốc đó: ải 1–6 đối chiếu địch thường, ải 7 tinh anh, ải 8 boss. Cả các thành viên trong nhóm cũng nhận tốc đánh ×2. Nội tại riêng và trang bị tiếp tục hoạt động trên bộ chỉ số này; phản ứng nhân đôi của Vương Huyết khi bạn hồi máu vẫn cộng dồn.

Không nhân đôi số ải trong công thức tăng trưởng và không tăng thêm tám mốc độ khó khi ở nhánh phụ. `run.difficultyCap` của nhánh phụ giữ mốc gốc, `bloodDomainMultiplier=2` chỉ thuộc địch lãnh địa. Save cũ đang trong lãnh địa được dựng lại theo quy tắc mới, giữ trạng thái các trận và lựa chọn thưởng đã chốt.

Sau khi hạ boss, chọn một trong ba SPN ×4 rồi lập tức trở lại nhánh chính, tiếp tục ở ải kế tiếp của hành trình gốc. Vùng đất, tiến độ vùng, giấy phép và mốc độ khó đã khóa được giữ; hệ số ×2 không theo ra ngoài. Ví dụ rẽ vào tượng sau ải 40 thì trở về tiếp tục ải 41, dù trong lãnh địa đã vượt tám trận.

## Vương Huyết

Mỗi lần người chơi thực sự nhận HP từ một nguồn hồi máu, boss còn sống lập tức nhân đôi HP hiện tại, HP tối đa, tốc đánh và sát thương. Các lần hồi riêng biệt cộng dồn theo lũy thừa hai, gồm thuốc, Giường, khả năng quân bài, thế trận, SPN, tăng sinh lực có hồi HP và hồi sinh. Hồi khi đầy máu không tăng boss. Boss chết không phản ứng với hồi máu sau chiến thắng. Tăng cường lượng hồi của cùng một nguồn không tính là một lần hồi riêng. Boss dùng bộ chỉ số riêng, không có trang bị hỗ trợ ngẫu nhiên; tốc có thể vượt trần 999 của địch thường.

Cuối mỗi lượt hành động đã hoàn tất, nếu boss còn sống: mất 2% HP hiện tại trực tiếp, bỏ qua giáp. Cùng điểm kết thúc lượt được dùng cho đánh bài, kết thúc lượt và đổi trang bị trong chiến đấu. Phong ấn nội tại bằng cơ chế boss hiện có tạm dừng cả hai hiệu ứng. Hiệu ứng máu và lời cảnh báo dùng hệ VFX thuốc hiện có. Đánh hạ boss trước khi kết thúc lượt sẽ dừng nội tại.

Phần thưởng đặc biệt: chọn đúng một trong ba SPN khác nhau, mỗi lá có `bloodDomainPower=4`. Hệ số ×4 áp dụng vào cơ chế SPN thật qua bộ nhân dùng chung và xuất hiện trong mô tả. Lựa chọn được chốt một lần khi thắng boss; tải lại không đổi ba lá. SPN được cất vào balo, giữ hệ số khi trang bị và lưu/tải. Chọn xong đóng giao dịch thưởng, không nhận lặp.

## Tranh và kiểm tra

Tổng cộng mười một ảnh tạo bằng built-in image_gen: chín PNG dọc (tượng, bảy loài địch, boss), hai nền PNG ngang. Prompt đầy đủ và nguồn ảnh nằm trong [BLOOD_DOMAIN_ASSETS.json](BLOOD_DOMAIN_ASSETS.json), đồng bộ vào `asset_manifest.json`; riêng bốn địch bổ sung nằm trong [BLOOD_ENEMY_EXPANSION_ASSETS.json](BLOOD_ENEMY_EXPANSION_ASSETS.json). Card loader dùng `config/continental_asset_paths.lua`, khung và rank do runtime vẽ theo Continental Art Bible.

Kiểm tra logic: `lua tests/ancient_statue_smoke.lua`, `lua tests/blood_enemies_smoke.lua` (tám PNG khác nhau, cấp và từng đặc điểm thực tế), `lua tests/blood_difficulty_smoke.lua` (×2 trên cả tám trận, nhóm địch, mốc khóa, lưu/tải/save cũ và quay về đúng nhánh chính). Kiểm tra game thật: `lovec.exe . --test-ancient-statue` (không ghi save/settings người chơi), render thư viện tám địch và đi qua shop → tượng → hiến máu → dịch chuyển → combat → boss phản ứng hồi máu → lễ thưởng → chọn SPN ×4 → trở lại hành trình. Các ảnh QA lưu tại `docs/ancient_statue_*.png` và `docs/blood_enemies_roster.png`.

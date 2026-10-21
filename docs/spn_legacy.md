# Kén Kế Thừa và Độc Kích Thiên Thạch — 2026-10-12

| SPN | Hiệu ứng | Tiến hóa từ bậc Thường |
| --- | --- | --- |
| Kén Kế Thừa (`spirit_legacy_cocoon`) | Không cộng chỉ số khi chiến đấu. Khi hạ Boss, tự tiêu hủy và nhân bản một SPN khác đang sở hữu ngẫu nhiên. | 1 → 2 → 3… bản sao của cùng SPN được chọn; mỗi cấp thêm 1. |
| Độc Kích Thiên Thạch (`spirit_meteor_solitude`) | Khi hoạt động, chỉ được đánh 1 lá mỗi tay; tay đúng 1 lá cộng 100 Sát thương. | Sát thương cộng thêm nhân đôi mỗi cấp: 100 → 200 → 400 → 800 → 1.600… |

Kén giữ toàn bộ tiến hóa, bậc, ấn bản, phù phép và tiến trình tích số của SPN gốc; bản sao bắt đầu với 0 lượt tiến hóa từ boss. Bản sao có dữ liệu độc lập. Nhận được cả khi đầy ô; bản sao đầu thay Kén, các bản tiếp theo dùng ô trống hoặc thêm vị trí vượt giới hạn. Những vị trí đang có SPN luôn được hiển thị, tính điểm và lưu/tải. Khi dọn hết vị trí vượt giới hạn, dung lượng quay về số ô đã mở cùng hiệu ứng Negative. Mua SPN thường vẫn kiểm tra dung lượng.

Mỗi Boss đã chết chỉ kích hoạt Kén một lần; quái thường và Boss còn sống không kích hoạt. Kén mới được nhân bản không nở tiếp trong cùng lần hạ Boss. Nếu chỉ giữ một Kén và không có SPN khác để sao chép, giữ Kén chờ Boss sau. Nếu có nhiều Kén ban đầu, từng Kén được xử lý một lần.

Độc Kích giới hạn thao tác **đánh**, không giới hạn thao tác bỏ bài hay sức chứa tay. Chọn nhiều lá vẫn bỏ bình thường; nút đánh bị khóa và phím Space cũng bị chặn trước khi tiêu lượt hoặc mở lựa chọn khả năng. Khi Boss khóa ô Độc Kích, cả thưởng và giới hạn đánh của lá đó tạm ngừng.

Xem trước, tính điểm thật, mô tả và phản hồi tiến hóa đều dùng chung hệ số. Bậc ban đầu cao hơn áp dụng số bước tương ứng: Độc Nhất chưa tiến hóa có 12.800 Sát thương cộng thêm.

Nguồn cơ chế: `src/spn_legacy.lua`; sự kiện Boss chết dùng biên nhận ở `src/souls.lua`. Kiểm thử: `tests/spn_legacy_smoke.lua`, snapshot 55 SPN, hồi quy Continental/LÖVE và `--test-spn-legacy-art`.

Tranh Continental tạo bằng ImageGen, PNG 1024×1536 ở `assets/cards/continental/spn/`, JPG runtime 512×768 ở thư mục runtime tương ứng. Prompt và nguồn trong `CONTINENTAL_ASSET_PROMPTS.md`, manifest trong `asset_manifest.json`. Ảnh kiểm tra khung thật: `spn_legacy_runtime.png`.

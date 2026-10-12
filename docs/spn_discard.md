# Dư Ảnh Cuối — 2026-10-12

`spirit_last_remnant` là SPN bậc Thường. Khi chủ động dùng lượt bỏ cuối cùng (còn 1 lượt trước khi bỏ), nếu bỏ đúng 1 lá còn tồn tại và thao tác có tiêu lượt bỏ, tạo 1 bản sao vĩnh viễn của lá đó.

Mỗi cấp tiến hóa thêm 1 bản sao: cấp 0/1/2/3 tạo 1/2/3/4 bản sao. SPN có bậc ban đầu cao hơn cũng nhận số bản sao tương ứng; bậc Độc Nhất chưa tiến hóa tạo 8 bản sao. Mô tả và phản hồi nâng cấp hiển thị số lượng hiện tại.

Bản sao vào cọc bỏ bài. Khi bộ rút cạn và game thu hồi cọc bỏ vào cuối lượt, chúng tham gia bộ rút. Chúng cũng được thêm vào bộ bài vĩnh viễn và tồn tại qua trận tiếp theo/lưu tải. Giữ bậc, chất, tiến hóa, tốc đánh vĩnh viễn, trang bị, số hốc, ấn, rèn và ấn bản. Mỗi bản sao có ID mới, dữ liệu trang bị độc lập; trạng thái tạm thời của trận không trở thành nâng cấp vĩnh viễn.

Bỏ nhiều lá, còn từ 2 lượt bỏ trở lên, bỏ miễn phí, Boss ép bỏ, xem trước, lá bị tiêu hủy hoặc SPN bị khóa đều không kích hoạt. Nhiều Dư Ảnh Cuối đang hoạt động có thể cùng tạo bản sao; nếu hồi lượt bỏ rồi lại dùng lượt cuối đúng điều kiện, lá có thể kích hoạt tiếp.

Nguồn: `src/spn_discard.lua`, gọi qua `src/card_abilities.lua` với ngữ cảnh từ thao tác bỏ bài trong `main.lua`. Kiểm thử: `tests/spn_discard_smoke.lua`, snapshot 51 SPN và hồi quy Continental/LÖVE.

Tranh ImageGen Continental: `assets/cards/continental/spn/spirit_last_remnant.png` (1024×1536), JPG runtime tương ứng (512×768). Prompt và nguồn ở `CONTINENTAL_ASSET_PROMPTS.md`, manifest ở `asset_manifest.json`. Kiểm tra khung thật: `--test-spn-discard-art`, xuất `spn_discard_runtime.png`.

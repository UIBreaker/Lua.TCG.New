# Hai SPN linh hồn — 2026-10-12

| SPN | Cơ chế cơ bản | Tiến hóa |
| --- | --- | --- |
| Gặt Hồn Bình Minh (`spirit_dawn_reaper`) | Trước lần đánh đầu tiên của trận, chủ động bỏ đúng 1 lá: tiêu hủy vĩnh viễn lá đó và nhận ×3 giá trị linh hồn. | Mỗi cấp thêm 1 vào hệ số: ×3 → ×4 → ×5… |
| Dàn Đồng Ca Linh Hồn (`spirit_soul_choir`) | Khi tính điểm, cộng 1 Cường hóa cho mỗi linh hồn đang giữ tại ô SPN này. Không tiêu hồn. | Mỗi cấp thêm 0,5 Cường hóa mỗi hồn: 1 → 1,5 → 2… |

Gặt Hồn dùng giá trị từ `src/souls.lua`: gồm giá trị cơ bản, trang bị, tiến hóa và ấn bản. Mỗi lá bị mất chỉ có một biên nhận thưởng; bản thể trong bộ bài vĩnh viễn và mọi cọc của trận đều bị xóa, không quay lại cọc bỏ. Giữ tối thiểu 1 lá trong bộ bài vĩnh viễn.

Điều kiện mở đầu là chưa chơi tay nào trong trận. Có thể hiến tế bằng nhiều lần bỏ riêng từng lá trước lần đánh đầu tiên; lượt bỏ miễn phí cũng hợp lệ. Bỏ nhiều lá cùng lúc, bỏ sau lần đánh đầu, Boss ép bỏ, xem trước và SPN bị khóa không kích hoạt.

SPN xử lý từ trái sang phải. Dư Ảnh Cuối đặt trước Gặt Hồn có thể sao chép trước khi lá gốc bị tiêu hủy; đặt sau thì không sao chép được lá đã mất. Nhiều Gặt Hồn không nhận thưởng lặp cho cùng một lá.

Dàn Đồng Ca lấy số hồn còn lại tại vị trí của nó, không dùng tổng hồn từng kiếm. Với 10 hồn, đặt sau Lò Hồn đốt 3 hồn sẽ cộng 7 Cường hóa ở cấp 0; đặt trước sẽ cộng 10. Mô tả, phản hồi tiến hóa, thưởng thật và xem trước dùng cùng hệ số. Khi bắt đầu ở bậc cao hơn, áp dụng tiến trình bậc tương ứng của hệ SPN.

Kiểm tra: `tests/spn_souls_smoke.lua`, snapshot 53 SPN và hồi quy Continental/LÖVE. Tranh PNG 1024×1536 + JPG runtime 512×768 tại `assets/cards/continental/spn/` và `assets/cards/continental/runtime/spn/`. Prompt ImageGen và nguồn trong `CONTINENTAL_ASSET_PROMPTS.md`, manifest trong `asset_manifest.json`. `--test-spn-souls-art` xuất `spn_souls_runtime.png` qua khung thật của game.

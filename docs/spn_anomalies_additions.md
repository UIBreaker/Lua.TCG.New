# 10 SPN dị tượng

Bổ sung ngày 2026-10-05. Catalog hiện có 32 SPN: giữ nguyên 22 lá cũ, thêm đúng 10 lá. Các lá mới khởi đầu Thường, giá 4; xuất hiện trong shop, gói Hộ Linh, draft boss và bộ sưu tập qua catalog chung.

| SPN | Cơ chế ở bậc Thường | Chiến thuật |
|---|---|---|
| Dư Ảnh Ngày Mai | Từ đòn thứ hai, thêm một hit bằng 35% AURA đòn trước vào mục tiêu hiện tại | Dồn một đòn lớn rồi nối tay nhỏ; dư ảnh đi theo mục tiêu mới. Hit thêm chịu giáp và khả năng quái. |
| Gương Oán | Phản 60% HP thực mất về kẻ vừa đánh, không kết liễu | Đổi máu lấy áp lực; phản thương không tính lượng Giáp đã hấp thụ, không tạo vòng phản hồi. |
| Giao Kèo Cuối | Một lần mỗi trận: tiêu mọi lượt bỏ còn lại để thoát đòn chí tử và giữ 5 HP | Để dành ít nhất một lượt bỏ làm bảo hiểm. Hoạt động trong đường xử lý sát thương chung, kể cả kỹ năng boss. |
| Lò Hồn | Mỗi tay đốt tối đa 3 Linh Hồn; +25 sát thương cố định mỗi hồn | Đổi tài nguyên Linh Hồn sang AURA; phần này được cộng sau tích Sát thương × Cường hóa. |
| Nghịch Luyện | Ngay tại ô SPN này, chuyển 10% Sát thương hiện có sang Cường hóa | Chủ động sắp xếp các SPN cộng Sát thương/Cường hóa trước và sau lò luyện. Ví dụ 100 × 2 → 90 × 12. |
| Thư Viện Mù | Chơi 3 kiểu tay khác nhau: hồi 1 lượt bỏ, xóa bộ nhớ để bắt đầu chu kỳ mới | Xây bộ đa thế đánh; chơi lại một kiểu trong cùng chu kỳ không tính thêm. Không vượt lượt bỏ được cấp đầu trận. |
| Vay Khoảnh Khắc | Một lần mỗi trận: chơi đúng 3 lá đều tính điểm, đổi 1 lượt bỏ lấy 1 lượt đánh | Đổi tài nguyên tìm bài thành nhịp tấn công. Lá phụ không tính điểm khiến giao kèo không kích hoạt. |
| Cai Ngục Mộng | Lần đầu đánh mỗi quái, nếu nó sống: buộc bỏ một đòn đánh kế tiếp, đồng thời +4 Giáp | Chuyển mục tiêu để gây gián đoạn cả đội địch; cùng một quái không bị gây ngủ lại bởi lá này trong trận. |
| Nuốt Tàn Dư | Kết liễu bằng đòn chính: 40% sát thương dư thành Giáp, tối đa 30 | Giết mục tiêu yếu để chuẩn bị chống đòn quái còn lại. Tính sau giáp địch; quái hồi sinh không tính là kết liễu. |
| Không Thời | Chặn hết sát thương HP của một đòn quái: tích ×2 Cường hóa cho tay tiếp theo | Canh Giáp hoặc kỹ năng chặn đòn để nạp sức mạnh. Không cộng dồn; tay thực sự được tính điểm sẽ tiêu tích trữ. |

Tiến hóa dùng công thức chung: mỗi bậc tăng 50% lượng thưởng gốc; với ×2 chỉ tăng phần vượt 1 (lần đầu thành ×2.5). Lượt đánh/lượt bỏ được làm tròn xuống để giữ tài nguyên nguyên; lần tiến hóa thứ hai đưa +1 lên +2. Nghịch Luyện chặn tỷ lệ ở 90%. Chi phí 3 hồn tối đa, 1 lượt bỏ, toàn bộ lượt bỏ, chu kỳ 3 kiểu tay và số lần mỗi trận không tăng theo tiến hóa.

Các callback tính tay chỉ đọc dữ liệu. Preview không tiêu Linh Hồn, lượt bỏ hoặc tích trữ; không ghi bộ nhớ và không trao thưởng. Khi tính thật mới ghi trạng thái và tiêu tài nguyên. Bộ nhớ nằm trong `game.spnCombat`, được reset khi vào trận và loại khỏi snapshot lưu run. Catalog và tiến hóa được phục hồi theo cơ chế lưu/tải hiện có. SPN bị khóa không kích hoạt; hiệu ứng ngủ đã gây lên quái vẫn được giải quyết như một hiệu ứng đã thi triển.

`src/spn_anomalies.lua` chứa catalog và các hook dị tượng; dùng luồng tính điểm, nhận sát thương, tấn công và phản hồi hiện có. Metadata `stat` đầy đủ cho cả 32 SPN; snapshot sử dụng tiêu hao và phản hồi tiến hóa được kiểm tra lại.

Tranh: 10 PNG dọc 2:3 trong `assets/cards/continental/spn/`, tạo từng ảnh bằng built-in image_gen. Loader: `config/continental_asset_paths.lua`. Prompt và provenance: `docs/CONTINENTAL_ASSET_PROMPTS.md`, `docs/asset_manifest.json`. Bảng tranh: `docs/spn_anomalies_catalog.png`; render khung thật: `docs/spn_anomalies_runtime.png`.

Kiểm tra: `lua tests/spn_anomalies_smoke.lua`, `lua tests/spn_snapshot_smoke.lua`, `lua tests/spn_tactics_smoke.lua`, `lua tests/spn_combat_smoke.lua`, `lua tests/scoring_presentation_smoke.lua`, `lua tests/enemy_group_smoke.lua`, `lua tests/enemy_attack_presentation_smoke.lua`.

Trạng thái tích trữ đi theo từng bản SPN sở hữu, nên đổi vị trí không làm mất tích trữ hoặc reset giao kèo đã dùng; bản sao có trạng thái riêng.

Render LÖVE: `../love-11.5-win64/lovec.exe . --test-spn-anomalies-art`. Các kiểm tra trên và bộ `--test-features` đã qua.

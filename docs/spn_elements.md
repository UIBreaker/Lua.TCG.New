# Máu ảo, đóng băng mở trận và AURA phân quang

Ba SPN bán trong shop và tiến hóa theo hệ thống hiện có. Bậc C ban đầu:

| SPN | Cấp 0 | Cấp 1 | Cấp 2 |
| --- | --- | --- | --- |
| Huyễn Tâm Hộ Mệnh | 1.000 máu ảo | 1.500 | 2.000 |
| Tĩnh Đông Khai Trận | Đóng băng mất 1 lượt | 2 lượt | 3 lượt |
| Liệt Hồn Phân Quang | Chia 100% AURA, đốt 5% phần nhận | 150% AURA, đốt 7,5% | 200% AURA, đốt 10% |

## Huyễn Tâm Hộ Mệnh

Mỗi lá đang trang bị có một lượng máu ảo riêng. Sát thương địch trúng người chơi được trừ vào máu ảo trước Giáp; lượng tràn mới đến giáp và HP thật. Giáp không làm giảm lượng máu ảo bị mất. Né/hụt không mất máu ảo. Thuốc hồi, hồi từ kỹ năng và tăng HP tối đa không hồi lớp này.

Lượng đã tiêu `phantomSpent` nằm trên **lá SPN vật lý**, giữ qua đổi ô, cất/trang bị lại, trận tiếp theo và lưu/tải. Tiến hóa chỉ tăng dung lượng, không xóa khoản đã tiêu: dùng 400/1.000 còn 600; tiến hóa thành dung lượng 1.500 thì còn 1.100. Tự hủy lá khi cạn, không trao thêm linh hồn từ việc tự hủy này. Sát thương dư vẫn được xử lý trong cùng đòn.

Có hỗ trợ đòn đánh thường, sát thương chờ của boss, độc từ địch và thuế HP của boss. Chi phí tự trả HP từ kỹ năng không tự lấy máu ảo. Thuốc Máu Vàng không sinh vàng cho lượng chỉ trừ vào máu ảo.

Máu ảo có thanh tím riêng trên HUD. Các bản/sao chép có ngân sách theo lá vật lý; bản Vọng Linh cạn sẽ tự hủy Vọng Linh đó. Nguồn bị khóa hoặc nằm dự trữ không cấp ngân sách; giữ khoản đã tiêu để không hồi khi mở khóa. Giới hạn dung lượng mỗi nguồn 1 tỷ.

**Cơ chế ẩn — ghi cho phát triển:** Shop Máu dùng máu ảo trước, gồm mua món và đổi hàng. Phải giữ ít nhất 1 HP thật; cho phép trả sạch máu ảo và tự hủy SPN trong giao dịch. Không thêm gợi ý về cơ chế này vào mô tả lá hoặc hướng dẫn trong game.

## Tĩnh Đông Khai Trận

Theo lựa chọn của người dùng, chỉ đóng băng **mục tiêu đang chọn**. Lượt đánh đầu mỗi trận hủy toàn bộ đòn sát thương chính, lan, đốt mới, Giường và hiệu ứng tấn công phụ của lượt đó; thay bằng đóng băng, không cần quay trúng đòn. Điểm AURA vẫn được tính, nhưng đòn tấn công gây 0 sát thương. Hiệu ứng riêng của quân/kỹ năng phát sinh trong giai đoạn ghi điểm vẫn theo cơ chế của chúng.

Địch mất các lượt hành động kế tiếp, gồm tấn công và hỗ trợ. Nếu nó đã đánh trước người chơi ở lượt mở trận, lần mất lượt bắt đầu từ hành động kế tiếp của nó. Chỉ dùng một lần đầu trận; trang bị muộn không khởi động lại. Nhiều nguồn cộng số lượt, trần 128; mỗi cấp tiến hóa tăng 1 lượt.

Trạng thái đòn đầu nằm ở `spnOpeningAttackUsed`, loại khỏi save và reset khi bắt đầu trận/chạy mới. Trạng thái đóng băng ở địch vẫn còn sau khi nguồn SPN rời ô, như hiệu ứng đã áp dụng.

## Liệt Hồn Phân Quang

Thay phân phối đòn chính bằng chia đều tổng AURA cho tất cả địch còn sống **tại thời điểm đòn trúng**. Không đánh thêm một đòn AURA đầy đủ vào mục tiêu chính. Giữ số lẻ để tổng không bị mất do làm tròn. Trượt đòn không gây sát thương hay đặt đốt. Các hiệu ứng tấn công bổ sung từ SPN khác vẫn có thể phối hợp sau đòn chia đều.

Theo lựa chọn của người dùng, mỗi địch bị đốt bằng **5% phần AURA nó nhận**, không phải 5% toàn bộ AURA của tay. Ví dụ 300 AURA / 3 địch: mỗi địch nhận 100 AURA trực tiếp, rồi 5 sát thương đốt mỗi vòng trong 2 vòng. Tiến hóa tăng cả hệ số chia và tỷ lệ đốt. Đòn trực tiếp chịu giảm sát thương bình thường; đốt là sát thương chuẩn và giữ giá trị từ lúc áp dụng.

Đốt tick cuối vòng hành động hiện tại và vòng tiếp theo. Mỗi lần áp dụng có bộ đếm riêng, cộng dồn khi đánh tiếp. Chỉ địch còn sống nhận tick; hồi sinh địch dùng cơ chế hiện có. Rời ô SPN không hủy nguồn đốt đã đặt. Tick chỉ đi từ vòng đời chiến đấu, không chạy khi vẽ/preview. Thắng do đốt đi qua `spnCombat.victoryPending` và lễ trao thưởng hiện có, tránh trao lại quà.

## Kiểm tra

- `tests/spn_elements_smoke.lua`: ngân sách không hồi/không ăn giáp, tràn chí tử, tự hủy, shop máu/đổi hàng, lưu/trận sau/tiến hóa, bản sao, độc/boss, đòn đầu 0 ST/chọn mục tiêu/thứ tự tốc, chia AURA và số lẻ, 2 tick đốt/tiến hóa/hạ địch, dự trữ/khóa/preview/RNG/shop.
- Snapshot 83 SPN, scoring runtime 189 kiểm tra, Blood Shop và Potions: PASS.
- Hồi quy LÖVE: các test SPN và Continental 52 (11.232 tình huống) PASS. Bộ chung vẫn còn lỗi cũ `tests/soul_shop_smoke.lua:133` về kỳ vọng Ankh/Hex tiêu hủy SPN sau khi hai lá đã đổi sang hệ phù phép mới.
- Native `--test-spn-elements-ui`: tay đầu đóng băng, thanh máu ảo/đỡ đòn, tay thứ hai chia AURA và đốt, thắng do đốt mở đúng một lễ thưởng.
- Native `--test-spn-elements-art`: loader 512×768 và khung chung cho cả 3 lá PASS.

Chưa playtest hành trình dài để cân bằng máu ảo và kinh tế shop máu.

## Tranh

Tạo riêng bằng **built-in ImageGen**, đúng Continental Art Bible; PNG 1024×1536, runtime JPG 512×768:

- `assets/cards/continental/spn/spirit_phantom_heart.png`
- `assets/cards/continental/spn/spirit_first_frost.png`
- `assets/cards/continental/spn/spirit_cinder_confluence.png`
- Gallery: `docs/spn_elements_runtime.png`.
- Capture: `docs/spn_elements_phantom_frost.png`, `docs/spn_elements_shared_cinders.png`, `docs/spn_elements_burn_victory.png`.
- Prompt/nguồn: mục “SPN phantom heart, opening frost and shared cinders - 2026-10-15” trong `docs/CONTINENTAL_ASSET_PROMPTS.md`, metadata trong `docs/asset_manifest.json`.

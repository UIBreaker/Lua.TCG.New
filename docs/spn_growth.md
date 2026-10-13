# Hai SPN: chiến tích vĩnh viễn và sức mạnh từ vàng

Hai lá xuất hiện trong shop và bộ sưu tập như SPN thông thường. Có thể tiến hóa, bán, trang bị và lưu/tải theo hệ thống hiện có.

| SPN | Cơ chế | Bậc C, cấp 0 / 1 / 2 |
| --- | --- | --- |
| Dư Hồn Chiến Tích | Mỗi quân **ghi điểm** nhận sát thương cơ bản vĩnh viễn, đúng một lần mỗi quân trong mỗi tay. Quân chơi nhưng không ghi điểm không nhận. | +4 / +6 / +8 cho quân đó |
| Kim Hồn Tụ Lực | Mỗi tay cộng sát thương theo số nhóm **đủ 5 vàng** đang giữ, không tiêu vàng. | +10 / +15 / +20 mỗi nhóm |

Chiến Tích tăng ngay trong lần ghi điểm đầu tiên. Một quân rank 2 được kích hoạt tám lần vẫn chỉ nhận +4 vĩnh viễn, nhưng cả tám lần đều dùng sát thương cơ bản đã tăng. Tay đánh sau có thể nhận thêm. Các quân cùng rank có ID riêng, chỉ quân thực sự ghi điểm được tăng; chỉ số đồng bộ vào bộ bài gốc và giữ qua trận, đổi hạng, lưu/tải. Chân Rết giữ phần tăng này bên cạnh sát thương cơ bản đặc biệt của nó. Vọng Linh sao chép theo số lần kích hoạt SPN của nó; từng lần sao chép chỉ cấp thưởng một lần cho mỗi quân trong tay.

Kim Hồn: 4 vàng → +0; 5–9 vàng → +10; 10–14 vàng → +20; 19 vàng → +30; 20 vàng → +40 ở bậc C cấp 0. Lượng vàng là ngân sách hiện tại lúc SPN được tính theo thứ tự các ô, sau các chi phí của SPN đứng trước. Vàng thưởng chỉ được nhận sau khi giải quyết tay đánh không được tính sớm.

SPN trong dự trữ hoặc ô bị boss khóa không kích hoạt. Xem trước chỉ tính trên bản sao riêng, không tăng sát thương thật hoặc đổi RNG.

## Triển khai và xác minh

- Logic: `src/spn_growth.lua`, hook ghi điểm `src/scoring.lua`.
- Sát thương lưu bằng `bonusBaseChips`; `spnPermanentDamage` giữ riêng phần tăng SPN cho dạng Chân Rết để không cộng lại +50 vốn có của phép biến đổi. `Deck.cloneCard` giữ trường này.
- Kiểm thử `tests/spn_growth_smoke.lua`: nhận một lần mỗi tay, đồng bộ/de-dupe ID, tái kích hoạt đầy đủ, sao chép, tiến hóa, đổi hạng, Chân Rết, trận sau/lưu game, preview thuần, nhóm vàng/không tiêu vàng, boss khóa, dự trữ và mua shop.
- Đã qua hồi quy LÖVE Continental 52 (11.232 tình huống), snapshot của 77 SPN và 183 kiểm tra scoring runtime; native art kiểm tra hai ảnh 512×768 qua loader và khung dùng chung.

## Tranh

Tạo bằng **built-in ImageGen**, hai lời gọi riêng theo Continental Art Bible. Canonical PNG 1024×1536, ảnh runtime JPG 512×768:

- `assets/cards/continental/spn/spirit_battle_memory.png`
- `assets/cards/continental/spn/spirit_golden_tithe.png`
- Xem trong khung game: `docs/spn_growth_runtime.png`.
- Prompt và nguồn ảnh: mục “SPN permanent damage and stored gold - 2026-10-13” trong `docs/CONTINENTAL_ASSET_PROMPTS.md`; metadata trong `docs/asset_manifest.json`.

Chưa playtest một lượt chạy dài để đánh giá cân bằng kinh tế và tăng sát thương tích lũy.

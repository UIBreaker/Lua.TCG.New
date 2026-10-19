# Hai SPN AURA — 2026-10-19

Hai SPN Common giá 4 Vàng, bán bình thường trong shop, vào kho rồi trang bị; hỗ trợ tiến hóa, sao chép và lưu/tải.

| Lá | Cấp gốc | Tiến hóa 1 | Tiến hóa 2 |
|---|---|---|---|
| Song Quang Hội Tụ | ×2 tổng AURA | ×2,5 | ×3 |
| Kẻ Dệt Số | Ghép số ×1 AURA | Ghép số ×1,5 | Ghép số ×2 |

## Ba trục riêng biệt

- ×Sát thương: nhân trục Chips tại vị trí SPN, các khoản cộng phía sau không được nhân ngược.
- ×Cường hóa: nhân trục Mult tại vị trí SPN.
- ×AURA: nhân kết quả cuối, bao gồm sát thương cố định. Nợ AURA được trừ sau phép nhân.

Song Quang dùng `xAura`, không thay Chips hay Mult. Nhiều bản sao/tái kích hoạt nhân liên tiếp theo cơ chế hiện có.

Kẻ Dệt Số nối rank của mọi quân đã chơi theo đúng thứ tự, kể cả quân không ghi điểm. Không sắp xếp, không lấy bài còn cầm hoặc số lần tái kích hoạt. A=1, J=11, Q=12, K=13. Ví dụ: 2–2 →22; 9–9–9–9 →9999; 2–3–4–5–6 →23456; 6–5–4–3–2 →65432.

Số ghép thay toàn bộ công thức điểm nền, thưởng Sát thương, Cường hóa, phần trăm sát thương, AURA Đa Sắc cục bộ và sát thương cố định. Chỉ nhân các hệ số AURA tổng sau đó, rồi trừ nợ AURA. Không chi Vàng mua chuộc K♦ để cứu điểm khi công thức đã bị thay. Đòn đánh vẫn chịu giáp/phòng thủ/né và các quy tắc chiến đấu; SPN đóng băng hoặc thay cách phân phối đòn vẫn hoạt động. Đây không phải sát thương chuẩn.

Các hiệu ứng phụ như nhận Vàng, hồi máu, Giáp, trả tài nguyên và tăng vĩnh viễn quân bài vẫn chạy theo điều kiện gốc; thưởng điểm của chúng không chen vào số ghép. Nhiều Kẻ Dệt Số chỉ dùng giá trị cao nhất: không cộng, không nối lại số hoặc nhân số lần kích hoạt. Sao chép theo cấp nguồn như các SPN khác. Boss khóa ô hoặc cất trong kho thì không có hiệu lực.

Ví dụ hai SPN cấp gốc: 2–2 →22 ×2 =44 AURA; 2–3–4–5–6 →23456 ×2 =46912 AURA. Giao diện ghi rõ GHÉP → AURA và ×AURA tổng; bỏ hoạt ảnh điểm nền và không hiện số Chips/Mult khi đang dùng cách tính này.

## Kiểm tra

`tests/spn_aura_smoke.lua`, `tests/scoring_presentation_smoke.lua`, `--test-spn-aura-ui` và `--test-spn-aura-art`. Ảnh runtime: `docs/spn_aura_runtime.png`; ảnh trận thật: `docs/spn_aura_battle.png`.

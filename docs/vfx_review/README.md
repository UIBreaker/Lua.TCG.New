# VFX review trong trận — 2026-10-10

Đã nâng 9 thế cơ bản và 18 thế nâng cao đang có: đội hình phóng đúng số luồng, gia tốc và timing riêng, phản ứng lá bài khớp điểm phóng, hình kết chuyển động theo từng thế. Vụ nổ giường bung nhanh hơn, fireball rộng hơn, mảnh lớn có bóng xuống nền và recoil rõ hơn; giảm chớp sáng world để giữ contact dễ chịu. Giữ nguyên damage, thưởng và luật chơi.

270 đòn đánh thật đã pass: mỗi thế 10 lần liên tục, luân phiên Normal/Fast và HIGH/LOW/MEDIUM. Kiểm tra damage một lần, input lock, thưởng nâng cao một lần, 18 damage bổ sung vốn có của Tesla, shader/audio và không cấp phát Image/Canvas/Shader trong draw. Test chỉ rút ngắn các pha đọc số tính điểm; conversion, anticipation, release, contact, settle và hit-stop giữ timing bình thường.

Thêm 27 trận HIGH để chụp đủ 108 frame dưới đây: anticipation/attack qua 45%, impact 25–70ms, after-contact 110–180ms. Đây là ảnh thật trong trận, gồm UI, phản ứng quái/lá bài, số damage và world lighting. Các ảnh contact sớm có thể bị số damage che; cột sau contact giúp xem hình kết khi đang tan.

- F6 mở lab cả 27 thế; ← / → đổi thế, 1–5 đổi cấp lực, R replay, Tab đổi tốc độ.
- F8 → B replay vụ nổ; 1/2/3 đổi quality. Replay không gây damage.
- `lovec . --test-hand-vfx-combat --all-hand-vfx --vfx-review`: chạy 270 đòn liên tục.
- `lovec . --test-hand-vfx-combat --all-hand-vfx --vfx-frame-review`: chụp 108 frame HIGH.
- `lovec . --test-bed-explosion`: 10 trận nổ thật trên nhóm ba quái, Normal/Fast, ba quality; HP/contact/AoE đúng theo catalog hiện tại.

Headless LÖVE cũng qua 270 scoring sequence cơ bản, 135 continuity case cơ bản, 270 continuity case nâng cao, 27 lab entry ở năm cấp lực, 90 repeat explosion tại 30/60/144 FPS và regression advanced/scoring/bed-speed. Kiểm tra FPS này là simulation dt, không phải benchmark GPU trên mọi máy.

| Thế đánh | Chuẩn bị | Phóng | Va chạm | Sau va chạm |
|---|---|---|---|---|
| Đơn Thủ | [Xem](frames/high_card_anticipation.png) | [Xem](frames/high_card_attack.png) | [Xem](frames/high_card_impact.png) | [Xem](frames/high_card_after_contact.png) |
| Song Đao | [Xem](frames/pair_anticipation.png) | [Xem](frames/pair_attack.png) | [Xem](frames/pair_impact.png) | [Xem](frames/pair_after_contact.png) |
| Song Đôi | [Xem](frames/two_pair_anticipation.png) | [Xem](frames/two_pair_attack.png) | [Xem](frames/two_pair_impact.png) | [Xem](frames/two_pair_after_contact.png) |
| Tam Hoa | [Xem](frames/three_of_a_kind_anticipation.png) | [Xem](frames/three_of_a_kind_attack.png) | [Xem](frames/three_of_a_kind_impact.png) | [Xem](frames/three_of_a_kind_after_contact.png) |
| Trường Long | [Xem](frames/straight_anticipation.png) | [Xem](frames/straight_attack.png) | [Xem](frames/straight_impact.png) | [Xem](frames/straight_after_contact.png) |
| Đồng Khí | [Xem](frames/flush_anticipation.png) | [Xem](frames/flush_attack.png) | [Xem](frames/flush_impact.png) | [Xem](frames/flush_after_contact.png) |
| Hỗn Nguyên | [Xem](frames/full_house_anticipation.png) | [Xem](frames/full_house_attack.png) | [Xem](frames/full_house_impact.png) | [Xem](frames/full_house_after_contact.png) |
| Tứ Tượng | [Xem](frames/four_of_a_kind_anticipation.png) | [Xem](frames/four_of_a_kind_attack.png) | [Xem](frames/four_of_a_kind_impact.png) | [Xem](frames/four_of_a_kind_after_contact.png) |
| Vạn Kiếm Quy Tông | [Xem](frames/straight_flush_anticipation.png) | [Xem](frames/straight_flush_attack.png) | [Xem](frames/straight_flush_impact.png) | [Xem](frames/straight_flush_after_contact.png) |
| THIÊN CƠ 369 | [Xem](frames/tesla_369_anticipation.png) | [Xem](frames/tesla_369_attack.png) | [Xem](frames/tesla_369_impact.png) | [Xem](frames/tesla_369_after_contact.png) |
| JACKPOT 777 | [Xem](frames/jackpot_777_anticipation.png) | [Xem](frames/jackpot_777_attack.png) | [Xem](frames/jackpot_777_impact.png) | [Xem](frames/jackpot_777_after_contact.png) |
| DÃY FIBONACCI | [Xem](frames/fibonacci_anticipation.png) | [Xem](frames/fibonacci_attack.png) | [Xem](frames/fibonacci_impact.png) | [Xem](frames/fibonacci_after_contact.png) |
| NGŨ SỐ NGUYÊN TỐ | [Xem](frames/prime_anticipation.png) | [Xem](frames/prime_attack.png) | [Xem](frames/prime_impact.png) | [Xem](frames/prime_after_contact.png) |
| CỬU DƯƠNG | [Xem](frames/odd_star_anticipation.png) | [Xem](frames/odd_star_attack.png) | [Xem](frames/odd_star_impact.png) | [Xem](frames/odd_star_after_contact.png) |
| THẬP HUYỀN ÂM | [Xem](frames/even_frost_anticipation.png) | [Xem](frames/even_frost_attack.png) | [Xem](frames/even_frost_impact.png) | [Xem](frames/even_frost_after_contact.png) |
| HỒNG TRIỀU | [Xem](frames/crimson_tide_anticipation.png) | [Xem](frames/crimson_tide_attack.png) | [Xem](frames/crimson_tide_impact.png) | [Xem](frames/crimson_tide_after_contact.png) |
| HẮC TRIỀU | [Xem](frames/obsidian_tide_anticipation.png) | [Xem](frames/obsidian_tide_attack.png) | [Xem](frames/obsidian_tide_impact.png) | [Xem](frames/obsidian_tide_after_contact.png) |
| NHẬT THỰC SONG SẮC | [Xem](frames/eclipse_duality_anticipation.png) | [Xem](frames/eclipse_duality_attack.png) | [Xem](frames/eclipse_duality_impact.png) | [Xem](frames/eclipse_duality_after_contact.png) |
| CẦU VỒNG TỨ CHẤT | [Xem](frames/four_kingdom_prism_anticipation.png) | [Xem](frames/four_kingdom_prism_attack.png) | [Xem](frames/four_kingdom_prism_impact.png) | [Xem](frames/four_kingdom_prism_after_contact.png) |
| TỨ QUỐC VIỄN CHINH | [Xem](frames/four_kingdom_expedition_anticipation.png) | [Xem](frames/four_kingdom_expedition_attack.png) | [Xem](frames/four_kingdom_expedition_impact.png) | [Xem](frames/four_kingdom_expedition_after_contact.png) |
| VƯƠNG MIỆN THIÊN MỆNH | [Xem](frames/destiny_crown_anticipation.png) | [Xem](frames/destiny_crown_attack.png) | [Xem](frames/destiny_crown_impact.png) | [Xem](frames/destiny_crown_after_contact.png) |
| CHÌA KHÓA ĐẠI LỤC | [Xem](frames/continental_gate_anticipation.png) | [Xem](frames/continental_gate_attack.png) | [Xem](frames/continental_gate_impact.png) | [Xem](frames/continental_gate_after_contact.png) |
| BẢN ĐỒ TẬN CÙNG | [Xem](frames/answer_42_anticipation.png) | [Xem](frames/answer_42_attack.png) | [Xem](frames/answer_42_impact.png) | [Xem](frames/answer_42_after_contact.png) |
| THIÊN MÔN KHAI ẤN | [Xem](frames/sealed_gate_anticipation.png) | [Xem](frames/sealed_gate_attack.png) | [Xem](frames/sealed_gate_impact.png) | [Xem](frames/sealed_gate_after_contact.png) |
| THẤT TINH ĐỔI MỆNH | [Xem](frames/seven_stars_anticipation.png) | [Xem](frames/seven_stars_attack.png) | [Xem](frames/seven_stars_impact.png) | [Xem](frames/seven_stars_after_contact.png) |
| NGŨ ĐẠI ĐỊA MẠCH | [Xem](frames/five_ley_lines_anticipation.png) | [Xem](frames/five_ley_lines_attack.png) | [Xem](frames/five_ley_lines_impact.png) | [Xem](frames/five_ley_lines_after_contact.png) |
| VÔ TẬN LUÂN HỒI | [Xem](frames/endless_cycle_anticipation.png) | [Xem](frames/endless_cycle_attack.png) | [Xem](frames/endless_cycle_impact.png) | [Xem](frames/endless_cycle_after_contact.png) |

Ảnh vụ nổ: [Chuẩn bị](../bed_explosion/anticipation.png), [Contact](../bed_explosion/contact.png), [Shockwave](../bed_explosion/shockwave.png), [Fireball](../bed_explosion/fireball.png), [Debris](../bed_explosion/debris.png), [Smoke](../bed_explosion/smoke.png).

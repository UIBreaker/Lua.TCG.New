# VFX review trong trận

Ảnh từ bản cuối, quality HIGH, chụp khi anticipation/attack qua 45% và impact ở 25–70ms. Đây là frame thật trong trận, gồm card reaction, damage number và world lighting.

90 trận đã pass: mỗi thế 10 lần liên tiếp, luân phiên Normal/Fast và HIGH/LOW/MEDIUM. Kiểm tra HP chỉ đổi một lần tại contact, input lock, shader không fallback, không cấp phát GPU resource trong draw; buffer shockwave không giữ điểm thừa từ slash.

| Thế đánh | Chuẩn bị | Phóng | Va chạm |
|---|---|---|---|
| Đơn Thủ — mũi kiếm xuyên | [Xem](high_card_anticipation.png) | [Xem](high_card_attack.png) | [Xem](high_card_impact.png) |
| Song Đao — hai cung chém giao nhau | [Xem](pair_anticipation.png) | [Xem](pair_attack.png) | [Xem](pair_impact.png) |
| Song Đôi — bốn lưỡi xoáy khép | [Xem](two_pair_anticipation.png) | [Xem](two_pair_attack.png) | [Xem](two_pair_impact.png) |
| Tam Hoa — phong ấn ba đỉnh | [Xem](three_of_a_kind_anticipation.png) | [Xem](three_of_a_kind_attack.png) | [Xem](three_of_a_kind_impact.png) |
| Trường Long — chuỗi chém nối | [Xem](straight_anticipation.png) | [Xem](straight_attack.png) | [Xem](straight_impact.png) |
| Đồng Khí — hai lớp sóng cuộn | [Xem](flush_anticipation.png) | [Xem](flush_attack.png) | [Xem](flush_impact.png) |
| Hỗn Nguyên — lõi nóng và ba cung lửa | [Xem](full_house_anticipation.png) | [Xem](full_house_attack.png) | [Xem](full_house_impact.png) |
| Tứ Tượng — bốn góc phong ấn khóa | [Xem](four_of_a_kind_anticipation.png) | [Xem](four_of_a_kind_attack.png) | [Xem](four_of_a_kind_impact.png) |
| Vạn Kiếm Quy Tông — đại kiếm và sóng kết | [Xem](straight_flush_anticipation.png) | [Xem](straight_flush_attack.png) | [Xem](straight_flush_impact.png) |

Phạm vi thay đổi: silhouette, vật liệu, glow falloff, shockwave perspective và contact. Không thay damage hoặc luật chơi. F6 mở lab các thế đánh; F8 → B replay vụ nổ.

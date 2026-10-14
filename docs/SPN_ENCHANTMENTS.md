# Tám phù phép SPN

Tinh gọn từ 24 xuống 8 lá ngày 14/10/2026. Mỗi SPN có một phù phép; tiến hóa, ấn bản, nâng cấp SPN và các SPN còn lại được giữ nguyên. Một lá phép dùng một lần để gắn hiệu ứng lâu dài. Giá mua riêng: **4 Vàng**; rương **6 Vàng** đưa ba lựa chọn khác nhau.

| Phù phép | Chiến thuật | Hiệu ứng |
| --- | --- | --- |
| Thành Lũy | Đánh nhóm bài để phòng thủ | Có ít nhất hai lá tính điểm: +Giáp bằng 15% HP tối đa, ít nhất 10 Giáp |
| Giao Hòa | Hồi phục; tay nhỏ có lợi hơn | Mỗi tay hồi 4% HP tối đa, ít nhất 3 HP; tối đa hai lá tính điểm thì hồi 8% |
| Khởi Nghiệp | Thu hồi vốn và chuẩn bị mua đồ | +3 Vàng mỗi tay; ngân sách chung 9 Vàng mỗi trận |
| Hội Tụ | Xây bộ Thùng | Thùng/Thùng Phá Sảnh: +75% Cường hóa sau SPN |
| Dẫn Lối | Xây bộ Sảnh | Sảnh/Thùng Phá Sảnh: +75% ST sau SPN |
| Trăng Non | Đầu tư một lá chủ lực | Đúng một lá tính điểm, bất kỳ rank: +100% Cường hóa sau SPN |
| Bách Khí | Phối hợp nhiều loại ITM | Mỗi loại ITM khác nhau trên bài tính điểm: +10% ST sau SPN, tối đa +50% từ mỗi phù phép |
| Biến Thế | Luân phiên thế Poker | Thế tay này khác tay trước trong trận: +50% Cường hóa sau SPN; tay đầu chưa kích hoạt |

## Thay đổi quan trọng

ST/Cường hóa được tính trên chỉ số **sau toàn bộ SPN**, nên phù phép vẫn có giá trị khi SPN và lá bài đã mạnh lên. Phần trăm của nhiều phù phép cộng chung trên mỗi trục, không nhân lồng nhau. Trần cộng từ phù phép: +200% ST và +200% Cường hóa, tương đương tối đa ×3 trên mỗi trục. Ví dụ hai Hội Tụ cho +150% Cường hóa (×2.5), không phải ×1.75². Những nguồn tăng sức mạnh ngoài phù phép vẫn dùng công thức riêng của game.

Hồi từ phù phép có tổng trần 25% HP tối đa mỗi tay. Giáp tuân theo giới hạn Giáp toàn game; không chịu trần 30 Giáp riêng của ITM khi tính điểm. Khởi Nghiệp chung ngân sách 9 Vàng giữa mọi bản sao: nhiều SPN nhận Vàng nhanh hơn, không tạo ngân sách mới. Đổi SPN, thay phép, sao chép hoặc giữ trong balo không làm mới ngân sách. Chỉ bắt đầu trận mới làm mới ngân sách.

Mỗi SPN trang bị kích hoạt phù phép một lần mỗi tay. Tái kích hoạt quân bài, ITM hoặc SPN không lặp phù phép. SPN bị Boss khóa ô không kích hoạt; SPN trong balo chỉ giữ phép, cần trang bị mới có hiệu lực. Bản Huyết Luyện tăng hiệu lực nhưng vẫn chịu các trần chung; dùng bản yếu hơn không ghi đè bản đã nâng cấp.

## Chọn mục tiêu và hủy

Dùng trong ô tiêu hao hoặc chọn trực tiếp từ rương đều mở màn chọn SPN. Có thể chọn SPN đang trang bị hoặc trong balo, kể cả các ô thưa và ô trên số 10. Màn chọn cho biết SPN chưa có phép hay sẽ thay phép nào. Hủy hoặc chọn giữ lại không tiêu hao lá và không đóng rương. Xác nhận chỉ thay phù phép trên SPN đã chọn. Nếu SPN không còn được sở hữu, thao tác thất bại và giữ lá phép.

Không tự gắn lên SPN đầu tiên, không chọn SPN ngẫu nhiên và không xóa các SPN khác. Hiệu ứng ấn bản Foil/Holographic/Polychrome/Negative đã có trên SPN được giữ nguyên. Các thẻ ấn bản trong nhóm riêng vẫn được game hỗ trợ.

## Nội dung bỏ và save cũ

Bỏ bốn phép biến đổi SPN ngẫu nhiên cũ (Aura, Ectoplasm, Ankh, Hex) khỏi nhóm phù phép, cùng 12 phép có điều kiện vụn, thưởng nhỏ, trùng vai trò hoặc khó dùng: Độc Tôn, Tinh Giản, Hợp Xướng, Tàn Hỏa, Bốn Mùa, Bảo Hiểm, Tái Chế, Nhịp Tiến, Trú Quân, Hút Gió, Phản Thành, Luân Vai.

`src/spn_enchantments.lua` lưu ánh xạ 16 mã cũ sang tám phép hiện hành. Chuyển đổi áp dụng cho phù phép đã gắn, SPN trong balo, lá tiêu hao đang trang bị/cất và rương chưa chọn. Giữ hiệu lực nâng cấp, giá đã có, tiến hóa và ấn bản; lựa chọn bị trùng trong rương sau chuyển đổi được gộp. Tranh cũ giữ làm tư liệu, nhóm thưởng chỉ có tám lá hiện hành.

## Kiểm tra

- `love . --test-enchantments`: tám phép; tăng chỉ số sau SPN; điều kiện và trần; Boss khóa; bắt đầu trận làm mới ngân sách; giá; mục tiêu/cancel/replace; SPN balo và ô thưa; handler dùng lá thật; nâng cấp đúng mục tiêu; preview thuần và 16 chuyển đổi save.
- `love . --test-chest-expansion`: đường dùng trực tiếp/cất, rương, loader, tooltip, save và tranh.
- `love tests/scoring_audit`: 32 bộ kiểm tra tính điểm, ITM, SPN, kinh tế và trình bày.

Ảnh renderer thật: `docs/spn_enchantments_runtime.png` và `docs/spn_enchantments_target.png`. Chưa playtest trọn nhiều lượt chơi dài để đo tỷ lệ thắng và giá trị kinh tế thực tế.

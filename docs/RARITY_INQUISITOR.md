# Giám Quan Tước Phẩm

Boss tự do hình người, tham gia nhóm dùng chung cho mọi vùng chính; xác suất 1/16 lượt chọn như từng boss tự do hình người khác. Nhánh Vương Huyết vẫn giữ boss sự kiện riêng.

## Phong ấn bậc

Đầu trận chọn đều một trong mười bậc **C, UC, R, E, L, M, T, UQ, VH, TT**. Tất cả SPN trang bị đang thuộc bậc đó bị vô hiệu, gồm khả năng tính điểm, nội tại, phù phép và sao chép. TT bao gồm TT+; không bỏ bớt phần tiến hóa dư khi xác định sức mạnh.

Bậc bị chọn giữ nguyên trong trận, hiện trên HUD và tooltip; lưu/tải giữ lựa chọn đó. Thay thứ tự ô không né được phong ấn. Đổi bậc sẽ kiểm tra lại ngay: rời bậc bị khóa thì được hoạt động, bước vào bậc đó thì bị khóa. Vô hiệu nội tại boss hoặc hạ boss sẽ gỡ phong ấn. SPN trong balo chưa hoạt động; khi trang bị sẽ chịu cùng điều kiện.

## Giáng Hai Phẩm

Cuối mỗi lượt chọn ngẫu nhiên một SPN trên C trong toàn bộ SPN người chơi sở hữu, gồm trang bị và balo, hạ vĩnh viễn tối đa 2 bậc. R → C; UC → C; C không bị chọn. Tính phần tiến hóa trước rồi mới giảm bậc gốc, hỗ trợ TT+ và không giảm dưới C. Không xóa ấn bản, phù phép, hệ số Void/Huyết Luyện hoặc lượt tiến hóa chưa dùng. Không có SPN đủ điều kiện thì kỹ năng không gây thay đổi.

Kỹ năng chịu các cơ chế vô hiệu kỹ năng hiện có, độc lập với phong ấn nội tại. VFX tím thể hiện hai mảnh phẩm cấp bị tước, thông báo chỉ rõ tên SPN và bậc trước → sau. Hiệu ứng khóa bậc dùng dấu vô hiệu của SPN trong giao diện chiến đấu.

Tranh tạo bằng built-in image_gen, PNG và prompt đầy đủ: [RARITY_INQUISITOR_ASSET.json](RARITY_INQUISITOR_ASSET.json).

Kiểm tra: `lua tests/rarity_boss_smoke.lua`; giao diện: `lovec.exe . --test-rarity-boss`. Ảnh QA: `docs/rarity_boss_sealed.png`, `docs/rarity_boss_downgrade.png`.

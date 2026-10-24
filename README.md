# 🃏 LUA.TCG — Poker Roguelike

**beta 0.148.0** · Lua / LuaJIT · LÖVE 11.5 · [MIT](LICENSE)

Game thẻ bài roguelike kết hợp thế bài Poker, xây dựng bộ bài và chiến đấu theo lượt. Từ bốn vương quốc trên lục địa, bạn giành giấy phép viễn chinh, lên tàu và khám phá vùng đất bí ẩn trong thế giới fantasy phương Tây.


## 📸 Hình ảnh trực quan

Ảnh chụp mới từ game chạy bằng LÖVE, ngày **05/10/2026**. Một số màn dùng bộ bài và tài nguyên dựng sẵn trong chế độ capture để minh họa các tính năng về sau.

![Chiến đấu theo lượt với đội hình đối thủ, HP, Giáp và tốc đánh](docs/screenshots/0.75.3/combat.png)

| Chọn ải viễn chinh | Khám phá vùng đất bí ẩn |
| :---: | :---: |
| ![Chọn ải và xem đối thủ trước trận](docs/screenshots/0.75.3/expedition.png) | ![Đội hình quái vật tại vùng đất bí ẩn](docs/screenshots/0.75.3/unknown-land.png) |

| Hải trình viễn chinh | Chợ linh hồn |
| :---: | :---: |
| ![Đối đầu các đoàn thám hiểm trên tàu ở ải 21](docs/screenshots/0.75.3/voyage.png) | ![Đổi linh hồn lấy di vật và thẻ hỗ trợ](docs/screenshots/0.75.3/soul-shop.png) |

| Soi chi tiết lá bài | Bộ sưu tập |
| :---: | :---: |
| ![Thông tin khả năng, tiến hóa và trang bị của quân bài](docs/screenshots/0.75.3/card-inspector.png) | ![Tra cứu các nhóm nội dung trong bộ sưu tập](docs/screenshots/0.75.3/collection.png) |

## Mới trong beta 0.148.0

- Chuỗi timing riêng theo mốc, giữ qua trận/save; tăng thưởng vàng, linh hồn, giáp và lễ trao thưởng. Thần Tích tiến hóa bài/SPN đang sở hữu theo chuỗi.
- Sáu mốc chiến thuật: Hấp huyết, Xuyên phá, Tiếp nhịp, Hồi sức, Tiếp tế, Đỡ phản; thêm vùng phản đòn/vỡ thế và nhịp thanh thay đổi có báo trước.
- Lá bị vô hiệu không thể đánh, tạo bộ hoặc kích hoạt SPN; vẫn có thể bỏ. Đồng bộ dự báo và kết quả thật.
- Tinh chỉnh khung kim loại, chuyển động gom bài, hiệu ứng tiến hóa/tăng tốc và thứ tự SPN/tiêu hao theo ô trang bị.
- Phối lại SFX trầm, gọn và nhỏ hơn; giảm chồng tiếng và giữ cache mobile.
- Chi tiết: [ghi chú phát hành](docs/RELEASE_NOTES_0.148.0.md).

## Mới trong beta 0.147.0

- **Bàn Ký Ức**: lật tìm 9 cặp bài, 24 lượt lật; phí 50 vàng, combo cuối nhân phần thưởng tối đa ×4.
- **Trạm Nghỉ Huấn Luyện**: chọn nghỉ để tăng HP tối đa và hồi máu, hoặc nâng vĩnh viễn 1–3 lá bài. Hai sự kiện có cơ hội xuất hiện sau boss ải lẻ ngoài Huyết Vực.
- **Xào lại / suy yếu**: hết lượt đánh sẽ xào bộ bài và hồi lượt; mỗi lần xào giảm 1 sát thương, tốc và Cường hóa trên bài chiến đấu, xóa khi sang trận mới.
- Timing **Thần Tích ♦**: tấn công ×12, parry phản ×500; thêm linh hồn thưởng ở mốc tím/trắng/Thần Tích, VFX và hai âm thanh mới.
- Chi tiết và hướng dẫn cài: [ghi chú phát hành](docs/RELEASE_NOTES_0.147.0.md).

## Mới trong beta 0.146.0

- Luật quân bài mới: sát thương A–K là 1–13, tốc 13–1; bỏ bài chủ động tạo hiệu ứng theo chất và Cường hóa cho lá cùng chất còn giữ. Khả năng riêng/vai trò J/Q/K/A cũ đã bỏ.
- Tiến hóa TT+ không giới hạn, giữ qua save; thêm bảng/nhãn và chuyển động phản hồi buff bỏ bài.
- Timing **Cực Hạn ✦**: tấn công ×8, parry phản ×250; nâng VFX tiếp xúc/phản lực và âm thanh.
- Dùng chung mẫu khiên thép cho giáp, parry, thuốc và HUD; thêm điểm sáng menu.
- Chi tiết: [luật quân bài](docs/PLAYING_CARD_RULES.md), [timing combat](docs/combat_timing.md).

## Mới trong beta 0.145.0

- Canh nhịp **tấn công / parry** bằng Space, Enter, chuột hoặc chạm, dùng thời gian thực độc lập tốc độ game.
- Vùng xanh/vàng/◆/★ có thưởng tăng dần; vùng đỏ là rủi ro công khai. Parry ★ có phản đòn về đúng kẻ tấn công.
- Thêm 16 cue âm thanh; nâng chỉ số địch, nền HP ba trận đầu **80/160/240**.
- Xem [quy tắc canh nhịp](docs/combat_timing.md).

## Mới trong beta 0.144.0

- Bốn boss người tự do: **Quan Chấp Cấm Thế**, **Kẻ Gạch Tên**, **Kẻ Thách Tử**, **Giám Quan Tước Phẩm**; tranh và cơ chế riêng.
- SPN **Kẻ Xóa Vương Quyền**: tiến hóa cộng +5 Sát thương/+5 Cường hóa mỗi cấp; chủ động tiêu hủy trong balo để phong ấn năng lực boss đến hết trận.
- Đồng bộ khóa thế/quân/bậc SPN với dự báo điểm, sao chép, giao diện và lưu/tải.
- Chi tiết: [boss tự do](docs/FREE_HUMAN_BOSSES.md), [SPN phong ấn boss](docs/SPN_BOSS_SEAL.md).

## Mới trong beta 0.143.0

- Bốn thực thể vương quốc: phong ấn chất bài và tăng sức mạnh theo tay đang cầm.
- Tốc độ game ×1/×2/×4; nhịp ×1 chậm hơn, giữ input/âm thanh theo thời gian thực.
- Giới hạn SPN bán trong shop ở C–L; lá Tiến Hóa cho SPN dùng lượt tích khi cùng hạ boss.
- Đồng bộ giá trị bán lại/đổi đồ, nâng UI khảm trang bị và nghi thức Tượng Cổ.
- Phản hồi trạng thái ngay trên lá, nâng chất âm SFX/Niệm/phần thưởng.

## Mới trong beta 0.142.0

- HP ba trận ải đầu **50/100/150**; dùng chung công thức HP cho chiến dịch và preview.
- Hai ô SPN/trang bị Shop Nhỏ đổi chỗ sau mỗi reroll thành công, giữ qua lưu/tải.
- Loot bỏ rương quân bài, vẫn giữ quân bài lẻ và các nhóm thưởng khác.
- Thêm kiểm tra bộ nhớ preview/soak; sửa launcher Windows chạy từ đúng thư mục game. Xem [ghi nhận bộ nhớ](docs/MEMORY_AUDIT.md).

## Mới trong beta 0.141.0

- Bộ Bài Đỏ khởi đầu **5 lá đủ bốn chất**, rút 3 lá; điều chỉnh HP địch, hồi HP sau thắng, giá shop và mốc mở SPN hiếm.
- Shop đầu có Đá Tam Kích T1 giá 12 vàng, mua một lần/run; hỗ trợ cặp shop và giữ trạng thái qua lưu/tải.
- AI địch phối hợp hỗ trợ, dùng vật phẩm theo tình huống, ghi nhớ đòn đã nhận; ý định vẫn được báo trước.
- Màn xem bộ bài mới, xem trước đối thủ chi tiết hơn và inspector dễ đọc trên màn hình nhỏ.
- Chi tiết cân bằng và giới hạn mô phỏng: [báo cáo đã áp dụng](docs/BALANCE_APPLIED_REPORT.md).

## Mới trong beta 0.140.0

- **Tượng Cổ**: sự kiện hiến máu đổi nâng cấp/ngẫu nhiên; lưu lựa chọn và tiến độ.
- **Lãnh Địa Máu**: nhánh bí mật tám trận, tám loại địch và boss Vương Huyết; thắng chọn một SPN có sức mạnh ×4 rồi quay lại hành trình chính. Xem [quy tắc](docs/ANCIENT_STATUE.md).
- **10 boss nhân loại** với nội tại, kỹ năng và tranh riêng; chọn boss và kết quả ảnh hưởng bộ bài được giữ qua lưu/tải. Xem [danh mục boss](docs/HUMAN_BOSSES.md).
- Nâng trần tiến hóa quân bài lên **10**; thêm 21 tranh/nền Continental và khung cấp cao.

## Mới trong beta 0.139.0

- Ba SPN: **Song Quang Hội Tụ**, **Kẻ Dệt Số**, **Sứ Giả Khảo Luyện**; công thức AURA và nhiệm vụ tiến hóa riêng, hỗ trợ lưu/tải.
- **Mũi Thép** (+5 Sát thương), **Mảnh Hổ Phách** (+1 Cường hóa), công thức chế tạo và nguồn hàng cập nhật.
- Âm thanh/hiệu ứng đánh hụt riêng; nâng cấp khung, chữ số, hốc khảm và kho đồ địch.
- Giữ các tối ưu khởi động, RAM và tài nguyên từ beta 0.138.2.

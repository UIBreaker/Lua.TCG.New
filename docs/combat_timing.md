# Canh nhịp combat

Mỗi tay bài có một lần canh nhịp trước khi tính điểm. Mỗi đòn đánh của địch có một lần canh parry riêng, kể cả khi địch ra đòn trước hoặc người chơi kết thúc lượt. Hành động hồi máu, tăng giáp, đổi trang bị không có parry.

Thanh mảnh nằm ở hàng điều khiển dưới cùng, thay thế nút đánh/bỏ bài trong lúc canh nhịp. Không che quân địch hoặc lá bài. Tấn công có nền đồng đỏ, biểu tượng kiếm và nhãn RA ĐÒN / TẤN CÔNG; parry có nền xanh thép, biểu tượng khiên và nhãn PARRY / PHÒNG THỦ. Nhãn chế độ luôn hiện, kể cả lúc đọc nhịp. Có chú giải màu ngay dưới thanh và kết quả ngắn tại chỗ.

Nhấn Space, Enter, chuột trái hoặc chạm màn hình để dừng con trỏ. Chạm được nhận ngay khi đặt ngón tay xuống. Mỗi thanh chỉ nhận một lần bấm; giữ phím không tự bấm lại. Có 0,45 giây đọc bố cục và 0,4 giây hiển thị kết quả. Không bấm thì combat tự tiếp tục.

Mỗi lần thanh xuất hiện, các vùng được xáo vị trí và thêm độ lệch ngẫu nhiên; hướng chạy trái/phải cũng ngẫu nhiên. Bố cục không đổi sau khi xuất hiện để người chơi có thể đọc và chọn mức rủi ro. Vàng an toàn nằm trong vùng xanh rộng hơn. Điểm vàng nhạt có dấu ◆ cho phần thưởng lớn hơn nhưng hai bên là bẫy đỏ có vạch chéo; có thêm một bẫy đỏ độc lập. Không có vùng nguy hiểm ẩn.

| Vùng | Tấn công | Parry |
|---|---|---|
| Xanh | Sát thương ×1,35, giữ xác suất đánh trúng hiện có | Giảm 50% sát thương trước giáp |
| Vàng (rộng 7%) | Sát thương ×2, chắc chắn trúng; vẫn tuân thủ luật chặn tay bài của boss | Chặn toàn bộ sát thương và hiệu ứng trúng đòn; giữ giáp |
| Vàng nhạt ◆ (rộng 4,5%, kẹp giữa đỏ) | Đòn quyết định ×2,6 và chắc chắn trúng | Phản thế: chặn toàn bộ, tạo giáp bằng 25% sát thương đòn địch, theo giới hạn giáp hiện có |
| Tím sáng ★ (rộng 2,5%, kẹp giữa đỏ) | Tuyệt Kỹ ×4 và chắc chắn trúng | Chặn toàn bộ, phản lại 10.000% (×100) sát thương đòn địch trước giáp người chơi; tạo giáp bằng 50% sát thương đòn địch theo giới hạn giáp hiện có |
| Đỏ sọc | Chắc chắn đánh hụt, kể cả khi có thuốc/buff chính xác | Lộ sườn: đòn địch gây thêm 25% sát thương trước giáp nếu trúng |
| Nền tối | Sát thương gốc, giữ xác suất đánh trúng | Không đỡ được |
| Hết thời gian | Sát thương ×0,75, giữ xác suất đánh trúng | Không đỡ được |

Hệ số tốc thanh = `clamp(sqrt(tốc địch / tốc người chơi), 0.55, 2.4)`. Tốc dùng chỉ số thực tế sau buff và trang bị. Hai bên bằng tốc có hệ số 1, thanh đi hết trong 1,6 giây; địch nhanh hơn thì thanh nhanh hơn, người chơi nhanh hơn thì thanh chậm hơn. Cửa sổ canh nhịp dùng thời gian thực, độc lập tốc độ game ×1/×2/×4 và tùy chọn giảm chuyển động. Mở menu tạm dừng hoặc cài đặt sẽ dừng thanh.

Địch thường / tinh anh / boss có nền HP ải đầu 80 / 160 / 240 (trước đây 50 / 100 / 150), tiếp tục theo đường cong tăng HP hiện có. Sát thương nền 8 / 12 / 16, tăng theo lần gặp với hệ số 2,4 / 3,2 / 4,8. Tốc đánh khởi điểm ngẫu nhiên 8–22, cận dưới tăng 0,4 và cận trên tăng 0,6 mỗi lần gặp; trang bị và hiệu ứng khu vực tiếp tục áp dụng như trước.

Kiểm tra bằng LÖVE 11.5:

```
lovec.exe . --test-combat-tactics
lovec.exe . --test-combat-timing
lovec.exe . --capture-combat-timing
```

Kiểm tra logic gồm tốc tương đối, 30/60/144 FPS, một lần bấm, hết thời gian, 150 bố cục ngẫu nhiên, vùng đỏ ép đánh hụt kể cả có buff chính xác, phản thế tạo giáp và lộ sườn nhận thêm sát thương. Kiểm tra game thật đi qua thứ tự địch trước/sau, tấn công bằng bàn phím, parry bằng chạm, menu tạm dừng, chế độ ×4, cố ý bấm đỏ và bấm vàng nhạt. Ảnh: `combat_timing_attack.png`, `combat_timing_parry.png` và biến thể `_3`, `_4`.

Hồi quy phát hành 0.145.0: đã đồng bộ fixture giới hạn trang bị với hệ số boss riêng, cho phép boss tự do ở vùng cuối và migration HP mới; 42 nhóm scoring và 10 nhóm bổ sung đều qua.

## Âm thanh canh nhịp

16 cue riêng cho hai chế độ: mở thanh, đòn thường, xanh, vàng, vàng ◆, đỏ và hết thời gian. Tấn công dùng tiếng chém với thân âm trầm; parry dùng cộng hưởng kim loại. Vàng có hợp âm ngân, vàng ◆ có chuỗi nốt và lực trầm rõ hơn; đỏ trượt âm xuống với tiếng ma sát. Âm kết quả phát ngay khi bấm, tuân theo âm lượng SFX, mute và mixer hiện có. Các cue có headroom và giảm âm nền ngắn để không bị tiếng combat che.

Tạo lại riêng bộ này: `python scripts/build_timing_audio.py`; kiểm tra WAV: `python scripts/build_timing_audio.py --check`. Game nạp qua `config/timing_audio_baked.lua` và `src/timing_audio.lua`.

Nghe thử `audio/timing_feedback_preview.wav`: năm âm tấn công rồi năm âm parry, mỗi nhóm theo thứ tự xanh → vàng → vàng ◆ → tím ★ → đỏ. Kiểm tra phát và giải mã cả 16 cue qua `lovec.exe . --test-audio`.

Kiểm tra mở đầu 200 seed đã qua với 80 HP. Ngoài lỗi nhóm địch nêu trên, `enemy_loadouts_smoke.lua:29` cũng lỗi với cả công thức địch cũ và mới; chưa thay đổi quy tắc đó trong đợt này.

Mốc Tuyệt Kỹ ★ nằm ở vị trí ngẫu nhiên riêng, có âm thanh riêng cho đánh và parry. Rộng 2,5% so với 4,5% của vàng ◆; khi ngang tốc, cửa sổ trúng khoảng 40 ms. Hai bên đều là đỏ nên bấm lệch sẽ đánh hụt / lộ sườn. Bộ kiểm tra bao gồm sát thương ×4 thực tế, phần thưởng giáp, biên hai bên, 150 bố cục và thao tác thật trong game.

Parry Tuyệt Kỹ ★ phản đòn về đúng kẻ đang tấn công, theo luật giáp, giảm sát thương và hồi sinh hiện có của địch. Ví dụ đòn 20 sát thương phản 2.000 sát thương trước phòng thủ địch. Nếu địch cuối bị phản chết trước lượt đánh người chơi, game chuyển thẳng sang thắng trận sau hiệu ứng tử vong và chỉ trao thưởng một lần.

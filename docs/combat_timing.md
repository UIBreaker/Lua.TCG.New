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
| Trắng sáng ✦ Cực Hạn (rộng 1,5%, giữa bẫy đỏ) | ×8 và chắc chắn trúng | Chặn toàn bộ, phản 25.000% (×250) sát thương trước giáp người chơi; giữ phần thưởng giáp của tím ★ |
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

18 cue riêng cho hai chế độ: mở thanh, đòn thường, xanh, vàng, vàng ◆, đỏ và hết thời gian. Tấn công dùng tiếng chém với thân âm trầm; parry dùng cộng hưởng kim loại. Vàng có hợp âm ngân, vàng ◆ có chuỗi nốt và lực trầm rõ hơn; đỏ trượt âm xuống với tiếng ma sát. Âm kết quả phát ngay khi bấm, tuân theo âm lượng SFX, mute và mixer hiện có. Các cue có headroom và giảm âm nền ngắn để không bị tiếng combat che.

Tạo lại riêng bộ này: `python scripts/build_timing_audio.py`; kiểm tra WAV: `python scripts/build_timing_audio.py --check`. Game nạp qua `config/timing_audio_baked.lua` và `src/timing_audio.lua`.

Nghe thử `audio/timing_feedback_preview.wav`: sáu âm tấn công rồi sáu âm parry, mỗi nhóm theo thứ tự xanh → vàng → vàng ◆ → tím ★ → trắng ✦ → đỏ. Kiểm tra phát và giải mã cả 18 cue qua `lovec.exe . --test-audio`.

Kiểm tra mở đầu 200 seed đã qua với 80 HP. Ngoài lỗi nhóm địch nêu trên, `enemy_loadouts_smoke.lua:29` cũng lỗi với cả công thức địch cũ và mới; chưa thay đổi quy tắc đó trong đợt này.

Mốc Tuyệt Kỹ ★ nằm ở vị trí ngẫu nhiên riêng, có âm thanh riêng cho đánh và parry. Rộng 2,5% so với 4,5% của vàng ◆; khi ngang tốc, cửa sổ trúng khoảng 40 ms. Hai bên đều là đỏ nên bấm lệch sẽ đánh hụt / lộ sườn. Bộ kiểm tra bao gồm sát thương ×4 thực tế, phần thưởng giáp, biên hai bên, 150 bố cục và thao tác thật trong game.

Parry Tuyệt Kỹ ★ phản đòn về đúng kẻ đang tấn công, theo luật giáp, giảm sát thương và hồi sinh hiện có của địch. Ví dụ đòn 20 sát thương phản 2.000 sát thương trước phòng thủ địch. Nếu địch cuối bị phản chết trước lượt đánh người chơi, game chuyển thẳng sang thắng trận sau hiệu ứng tử vong và chỉ trao thưởng một lần.

Mốc Cực Hạn ✦ nằm riêng trong vùng đỏ còn lại, độc lập vị trí mốc tím. Rộng 1,5% thay vì 2,5% của tím; cửa sổ 24 ms khi ngang tốc, ngắn hơn khi địch nhanh. Có ký hiệu tia trắng và hai âm thanh riêng. Kiểm tra game thật riêng mốc này: `lovec.exe . --capture-combat-timing --apex-only` (đánh, parry, phản 5.000 sát thương từ đòn 20 và thắng trận nhờ phản đòn).

## Hiệu ứng trúng mốc và phản đòn

`src/timing_vfx.lua` bổ sung hai lớp: xác nhận ngắn ngay trên thanh khi bấm; hiệu ứng combat theo kết quả thật ở thời điểm va chạm. Không thay đổi sát thương, RNG hoặc cửa sổ timing.

- Xanh: vệt chém gọn và vài tia nhỏ; đỡ một phần chỉ hiện nửa khiên.
- Vàng → vàng ◆: một lưỡi chém sắc nét, tan trong 0,28 giây.
- Tím ★: nhát cắt xiên mảnh, mép tím nhạt, đầu nhọn hơi móc và tia năng lượng nhỏ.
- Trắng ✦: cú bổ gần thẳng đứng, bản chém rộng, mặt trắng và cạnh xanh thép; điểm va chạm lóe ngắn, mảnh sáng đặc và lực giật rõ hơn tím. Vệt chính tan trong 0,32 giây, tối đa bảy mảnh nhỏ.
- Chặn hoàn toàn: khiên thép đặc, mép vát sáng, hai mặt kim loại và sống nổi. Khiên nhún nhẹ khi trúng đòn, tia va chạm ở mặt trên; bỏ dấu tick, không có sóng tròn hoặc viền phụ.
- Đánh hụt: một vệt chém đi bên cạnh mục tiêu và dấu hụt nhỏ, không có tia va chạm hoặc rung camera.
- Parry trượt: hai nửa của chính khiên thép nứt đỏ, tách và xoay ngược nhau; không để hình khiên nguyên phía sau.
- Phản đòn: khiên hấp thụ, lao năng lượng đi ngược từ người chơi về đúng địch tấn công, chạm sau 0,22 giây rồi bung hiệu ứng theo cấp. Âm chạm phản lực chỉ phát một lần khi lao đến đích. HP hiển thị, giật lùi, số sát thương và hiệu ứng tử vong của địch cũng chờ mốc 0,22 giây; nhịp hồi giữ tối thiểu 0,48 giây thực để chế độ ×4 không cắt mất cú phản lực.

Các hiệu ứng chạy theo thời gian thực để chế độ ×4 vẫn nhìn rõ. Chỉ rung camera và dừng hình ngắn khi đòn trúng, theo độ hiếm; giảm chuyển động dùng dấu hiệu tĩnh, không rung hoặc bắn hạt. Tối đa tám hiệu ứng, bảy tia mỗi hiệu ứng (giảm trên cấu hình mobile), tự dọn hết sau tối đa 1,02 giây. Đổi combat xóa toàn bộ hiệu ứng cũ.

Kiểm tra: `--test-combat-timing` bao gồm 144 tổ hợp loại/cấp/FPS, thời gian sống, RNG, giảm chuyển động và âm phản lực một lần. Kiểm tra thao tác thật dùng `--capture-combat-timing --apex-only`; thư viện 15 ảnh qua `--capture-combat-timing --vfx-gallery`.

Video xem thử: `timing_vfx_preview.mp4`, gồm 10 cảnh chạy ở 30 FPS. Tạo bằng `--capture-combat-timing --vfx-reel` với biến môi trường `TIMING_VFX_FFMPEG` trỏ tới FFmpeg cục bộ (đường dẫn tương đối không chứa khoảng trắng). Chỉ xuất video, không dùng encoder trong game thông thường.

Bản xem thử có âm thanh đồng bộ: `timing_vfx_preview_sound.mp4` (10,87 giây, H.264 960×540 / 30 FPS + AAC). Các ảnh `combat_timing_reflect_before_contact.png` và `combat_timing_reflect_after_contact.png` kiểm tra cảnh phản đòn kết liễu trong game: địch còn hiển thị nguyên trạng trước khi luồng phản lực tới, sau đó mới đổi HP, số sát thương và tan vỡ.

Quy chuẩn hiệu ứng hiện tại: bỏ hoàn toàn vòng tròn, cung xoáy, ấn hình học trang trí, quầng sáng và nét vẽ chồng tạo dư ảnh. Chỉ giữ một lưỡi chém, vài tia ngắn, một mặt khiên hoặc hai mảnh khiên vỡ. Phản đòn dùng một luồng ngắn đi tới địch rồi tan ngay khi chạm; không để dây sáng nối hai bên kéo dài.

Màu va chạm sáng và bão hòa hơn, lõi chém trắng sắc. Phản đòn trắng dùng một mũi lao dày, tím dùng luồng mảnh; độ sáng va chạm tính từ lúc chạm địch để không bị mờ vì thời gian bay. Phụ đề kết quả trong game và video dùng chung `ui/components/timing_caption.lua`: màu theo mốc, bóng chữ tối mảnh; từ vàng ◆ trở lên có một lượt ánh sáng lướt qua chữ và tối đa ba điểm lấp lánh nhỏ. Chế độ giảm chuyển động giữ chữ tĩnh. Font và fallback của game hỗ trợ đầy đủ tiếng Việt.

Mẫu khiên thép đã chốt được dùng chung qua `ui/components/shield.lua`: parry, thanh giáp người chơi/địch, biểu tượng phòng thủ trên thanh timing, tăng/mất giáp, thuốc giáp/phá giáp, hộ vệ NEN và biểu tượng khiên trong chữ/cửa hàng/sổ tay. Các nơi chỉ chọn kích thước, màu nhấn, nửa khiên hoặc trạng thái vỡ; không sao chép hình dáng hay thêm vòng bao. Phần bóng và ánh sáng phụ của chữ không vẽ lặp biểu tượng khiên. Tranh minh họa lá bài vẫn do hệ thống ảnh Continental quản lý.

Kiểm tra và ảnh tổng hợp mẫu khiên: `lovec.exe . --test-shields`, xuất `shield_style_gallery.png`. Bao gồm sáu kích thước 12–110 px, biến thể nửa/vỡ, hai dạng emoji khiên trong chữ tiếng Việt, xuống dòng/căn lề, khôi phục trạng thái đồ họa và tích hợp renderer giáp/thuốc.

Parry có ba pha theo thời gian thực: nén khiên vào đòn trong 55 ms, giữ tới 75 ms, bật trả trong 70 ms rồi ổn định. Ánh lóe làm sáng chính mặt thép, không chồng thêm hình khiên. Phản lực rời khiên ở 90 ms, tăng tốc theo đường cong bậc ba và vẫn chạm địch đúng 220 ms. Va chạm phản đòn có một nhịp khựng riêng, nén địch nhanh, giữ lực 40 ms rồi bật lùi; trắng mạnh hơn tím. Nhịp dừng ngắn do VFX quản lý bằng đồng hồ thực, nên tốc độ ×4 không cắt mất cảm giác va chạm. Giảm chuyển động bỏ nén, rung, tia bay và nhịp dừng.

Khi bấm đúng mốc, thanh timing phát một dải sáng tại vị trí dừng, lan theo chiều thanh và bắn tia ngắn. Xanh/vàng gọn; vàng ◆ có điểm lấp lánh; tím có dải tím rộng và tia sắc; trắng lóe khắp thanh với lõi trắng và mảnh sáng lớn hơn. Ánh sáng được giới hạn ở khu vực thanh, không có vòng bao hoặc dư ảnh. Thư viện `--vfx-gallery` hiện có 20 cảnh, gồm năm mốc sáng của thanh; video xem thử cũng dùng renderer timing thật.

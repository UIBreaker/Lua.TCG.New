# Canh nhịp combat

## Mốc chiến thuật và bài vô hiệu

Mỗi thanh lấy ngẫu nhiên hai mốc chiến thuật khác nhau, nằm hai bên mốc vàng. Mỗi mốc rộng 2,6%, giữ nguyên vị trí trong lần canh nhịp và có tên ngắn trên thanh. Mỗi loại có chuỗi riêng như các mốc cũ; trúng loại khác giữ chuỗi, nền tối/đỏ/cam/hết giờ xóa chuỗi.

Chú thích tác dụng cơ bản của hai mốc hiện sẵn ở hàng dưới thanh. Số trong `[N]` bên cạnh chú giải là chuỗi hiện đang giữ, có nhãn `CHUỖI [N]` ở ô chế độ. Khi trúng, thanh đổi màu và hiện tác dụng đã nhân chuỗi.

Sáu màu/hình dùng chung trên thanh, khiên và điểm va chạm: Hấp huyết đỏ huyết với giọt máu hút vào; Xuyên phá ngà trắng với mũi xuyên và mảnh giáp bật hai bên; Tiếp nhịp lam điện với hai dấu tăng tốc bật lên; Hồi sức lục ngọc với dấu cộng và nét sáng gom vào khiên; Tiếp tế hổ phách với một thẻ gấp góc và ba mảnh tiếp tế rơi gọn; Đỡ phản tím chàm với mũi gấp hướng lên và tia bật trả. Mỗi hiệu ứng chỉ có một hình chính, vài nét va chạm, không vòng/cung tròn hay dư ảnh. Âm sắc xác nhận cũng khác nhau giữa sáu loại. Giảm chuyển động giữ màu và hình để vẫn phân biệt được.

Preview sáu mẫu: `docs/timing_utility_styles.png`. Kiểm tra hình, font, trạng thái đồ họa, chế độ giảm chuyển động và không dùng primitive tròn: `--test-timing-utility-visuals`. Capture trong trận: `--capture-combat-timing --vfx-gallery --utility-visuals`.

| Chế độ | Mốc | Hiệu quả cơ bản khi chuỗi 1 |
|---|---|---|
| Đánh | Hấp huyết | ×1,2 sát thương; hồi 4% HP tối đa sau khi đánh trúng |
| Đánh | Xuyên phá | ×1,6 sát thương; bỏ qua giáp thường, vẫn giữ các luật bảo vệ đặc biệt của boss |
| Đánh | Tiếp nhịp | ×1,4 sát thương; các lá hợp lệ còn trên tay +1 tốc đánh trong trận |
| Parry | Hồi sức | Giảm 75% sát thương; sống sót qua đòn thì hồi 4% HP tối đa |
| Parry | Tiếp tế | Giảm 75% sát thương; sống sót qua đòn thì +1 lượt bỏ, không vượt giới hạn hiện có |
| Parry | Đỡ phản | Giảm 75% sát thương; sống sót qua đòn thì trả lại ×3 sát thương đòn địch trước giáp |

Chuỗi N nhân sát thương đánh/phản và lượng hồi HP/tốc/lượt bỏ với N. Mức giảm sát thương giữ 75%. Thưởng chỉ trả một lần khi đòn thật sự thành công; hồi phục không cứu sống một đòn đã gây chết người. Các mốc chiến thuật không cho vàng, linh hồn hay hệ số lễ trao thưởng.

Hai lỗi nặng có hiệu ứng riêng: địch chặn rồi phóng lưỡi phản lực về vị trí người chơi; mốc nhận ×5 làm khiên vỡ ngay tại vị trí người chơi. Va chạm có nhịp khựng thực 45 ms, cú nén camera nhỏ, âm trầm và nhãn rõ. Không có vòng sáng, dư ảnh hoặc flash toàn màn hình; giảm chuyển động tắt rung, tia bay và nhịp khựng.

Lá bị vô hiệu bởi khóa kỹ năng, khóa chất/bậc hoặc luật chặn ghi điểm không được đánh, không góp vào bộ, không kích hoạt SPN, trang bị hoặc điều kiện cầm bài. Có thể chọn để bỏ. Khi chọn cả lá hợp lệ lẫn lá khóa, chỉ các lá hợp lệ được đánh; lá khóa ở lại tay. Đôi có một lá khóa trở thành bài lẻ. Preview, tính điểm thật và hàng đợi kỹ năng cùng dùng luật lọc; hết thời hạn khóa thì lá hoạt động lại.

Kiểm tra: `--test-combat-timing`, `--test-continental52`, `--test-human-bosses`, `--test-kingdom-bosses`; capture `--capture-combat-timing --hazard-runtime` và `--capture-combat-timing --vfx-gallery --hazards`.

Mỗi tay bài có một lần canh nhịp trước khi tính điểm. Mỗi đòn đánh của địch có một lần canh parry riêng, kể cả khi địch ra đòn trước hoặc người chơi kết thúc lượt. Hành động hồi máu, tăng giáp, đổi trang bị không có parry.

Thanh mảnh nằm ở hàng điều khiển dưới cùng, thay thế nút đánh/bỏ bài trong lúc canh nhịp. Không che quân địch hoặc lá bài. Tấn công có nền đồng đỏ, biểu tượng kiếm và nhãn RA ĐÒN / TẤN CÔNG; parry có nền xanh thép, biểu tượng khiên và nhãn PARRY / PHÒNG THỦ. Nhãn chế độ luôn hiện, kể cả lúc đọc nhịp. Có chú giải màu ngay dưới thanh và kết quả ngắn tại chỗ.

Nhấn Space, Enter, chuột trái hoặc chạm màn hình để dừng con trỏ. Chạm được nhận ngay khi đặt ngón tay xuống. Mỗi thanh chỉ nhận một lần bấm; giữ phím không tự bấm lại. Có 0,45 giây đọc bố cục và 0,4 giây hiển thị kết quả. Không bấm thì combat tự tiếp tục.

Mỗi lần thanh xuất hiện, các vùng được xáo vị trí và thêm độ lệch ngẫu nhiên; hướng chạy trái/phải cũng ngẫu nhiên. Vàng an toàn nằm trong vùng xanh rộng hơn. Mọi mốc đứng yên sau khi xáo vị trí, kể cả các mốc hiếm. Vùng thưởng thu nhỏ, vùng đánh hụt và phản đòn rộng hơn. Không có vùng nguy hiểm ẩn hoặc đổi hướng bất ngờ.

| Vùng | Tấn công | Parry |
|---|---|---|
| Xanh | Sát thương ×1,35, giữ xác suất đánh trúng hiện có | Giảm 50% sát thương trước giáp |
| Vàng (rộng 6,2%) | Sát thương ×2, chắc chắn trúng; vẫn tuân thủ luật chặn tay bài của boss | Chặn toàn bộ sát thương và hiệu ứng trúng đòn; giữ giáp |
| Xanh lam ◆ (rộng 4%, kẹp giữa đỏ) | Đòn quyết định ×2,6 và chắc chắn trúng | Phản thế: chặn toàn bộ, tạo giáp bằng 25% sát thương đòn địch, theo giới hạn giáp hiện có |
| Tím sáng ★ (rộng 2,2%, kẹp giữa đỏ) | Tuyệt Kỹ ×4 và chắc chắn trúng | Chặn toàn bộ, phản lại 10.000% (×100) sát thương đòn địch trước giáp người chơi; tạo giáp bằng 50% sát thương đòn địch theo giới hạn giáp hiện có |
| Trắng sáng ✦ Cực Hạn (rộng 1,3%, giữa bẫy đỏ) | ×8 và chắc chắn trúng | Chặn toàn bộ, phản 25.000% (×250) sát thương trước giáp người chơi; giữ phần thưởng giáp của tím ★ |
| Hồng ngọc ♦ Thần Tích (rộng 0,7%, giữa bẫy đỏ) | ×12 và chắc chắn trúng | Chặn toàn bộ, phản 50.000% (×500) sát thương trước giáp; tạo giáp như tím |
| Đỏ sọc | Chắc chắn đánh hụt, kể cả khi có thuốc/buff chính xác | Lộ sườn: đòn địch gây thêm 25% sát thương trước giáp nếu trúng |
| Cam đen, dấu ×× | Địch chặn đòn, nhận 0 sát thương và dội lại 100% sát thương tay bài trước giáp; không nhận thưởng trúng mốc | Vỡ thế: đòn địch chắc chắn trúng, gây ×5 sát thương trước giáp, kể cả khi tốc bạn cao hơn hoặc có thuốc né |
| Nền tối | Sát thương gốc, giữ xác suất đánh trúng | Không đỡ được |
| Hết thời gian | Sát thương ×0,75, giữ xác suất đánh trúng | Không đỡ được |

Hệ số tốc thanh = `min(2.4, max(0.95, sqrt(tốc địch / tốc người chơi)) × (1 + áp lực))`. Áp lực bằng 1,25% mỗi bậc của chuỗi cao nhất đang giữ, tối đa 25%; mất chuỗi thì áp lực giảm ở thanh kế tiếp. Không có chuỗi, hai bên bằng tốc có hệ số 1 và thời gian 1,45 giây (nhanh hơn khoảng 10% so với 1,6 giây trước đây); vượt tốc địch chỉ giảm xuống 0,95, không còn 0,55. Tốc dùng chỉ số thực tế sau buff và trang bị.

Ba nhịp được báo ngay lúc đọc thanh: đều; nhanh → chậm → nhanh; chậm → nhanh → chậm. Con trỏ luôn đi cùng hướng, biến tốc trơn theo tiến độ và kết thúc đúng thời gian đã định. Tất cả vùng giữ nguyên vị trí trong suốt lần canh nhịp; chỉ con trỏ di chuyển và đổi tốc theo nhịp đã báo. Chuyển động xác định theo thời gian, không tung RNG mỗi khung hình. Cửa sổ canh nhịp dùng thời gian thực, độc lập tốc độ game ×1/×2/×4 và tùy chọn giảm chuyển động. Mở menu tạm dừng hoặc cài đặt sẽ dừng thanh.

Hai ô cam đều xóa toàn bộ chuỗi. Phản sát thương và đòn ×5 vẫn qua các lớp giảm sát thương/giáp hiện có; các hiệu ứng bảo vệ khi nhận sát thương vẫn hoạt động. Phản đòn của địch không kích hoạt thưởng đánh trúng, sát thương lan hoặc chuỗi phản vô hạn.

Thần Tích có cửa sổ 12,8 ms khi ngang tốc (trắng 24 ms), nằm ngẫu nhiên ở một trong hai bên vùng đỏ bao quanh lam ◆, không chồng lên mốc khác. Bấm lệch hai bên đều vào đỏ. Có nhát chém hồng ngọc lõi vàng, ánh lóe toàn thanh và hai cue âm thanh riêng; vẫn không vòng sáng hoặc dư ảnh. Bộ âm timing hiện có 20 cue.

Đánh trúng hoặc parry thành công ở tím, trắng và Thần Tích thưởng **5 linh hồn + 5 vàng × chuỗi của mốc**. Thưởng ghi nhận khi xử lý đòn thực tế, không cộng lặp cho phản đòn. Hụt, né, đóng băng bỏ qua lượt và hỗ trợ không thưởng.

Mỗi mốc có chuỗi riêng, dùng chung giữa tấn công/parry: lần đầu ×1, lần tiếp ×2, ×3… Vào mốc màu khác tăng chuỗi của mốc đó và giữ các chuỗi còn lại; nền tối, đỏ hoặc hết thời gian xóa toàn bộ chuỗi. Chuỗi được lưu qua các trận và save của cùng lượt chơi, tạo lượt chơi mới thì xóa. Chuỗi nhân sát thương, phản đòn và giáp thưởng; phần trăm giảm sát thương không tăng quá chặn toàn bộ. Giáp thưởng làm tròn số gốc rồi nhân chuỗi, theo giới hạn giáp hiện có.

Trắng/Thần Tích khóa thưởng lễ ở mức cao nhất trong trận: ×2, ×4, ×6… Không nhân dồn nhiều lần. Hệ số áp dụng vàng lễ, số lượt chiến lợi phẩm, vé Void và linh hồn hạ địch; đồ vùng/giấy thông hành độc nhất vẫn giữ bản gốc. Đã trúng rồi trượt không xóa phần lễ đã kiếm. Lễ được thanh toán một lần, hệ số lễ đặt lại khi sang trận mới; chuỗi vẫn giữ.

Thần Tích chuỗi N tiến hóa **N cấp** cho mọi SPN vật lý đang sở hữu (trang bị và balo) và từng lá còn trên tay. Đồng bộ tiến hóa về lá gốc và các bản sao cùng ID; không tiến hóa lặp một vật thể bị tham chiếu nhiều lần. Các nâng cấp là vĩnh viễn theo luật tiến hóa hiện có.

Kiểm tra `--test-combat-timing` gồm 200 bố cục mới, hệ số ×12/×500, ba cấp linh hồn, chống trả lặp và không trả khi hụt/né. `--capture-combat-timing --divine-only` kiểm tra đòn và ví linh hồn thật, gồm phản đòn kết liễu; fixture đặt thời điểm bấm chính xác vì cửa sổ 5 ms ở tốc cao hẹp hơn một khung hình chụp. `--vfx-gallery` hiện có 24 cảnh gồm mốc mới.

Địch thường / tinh anh / boss có nền HP ải đầu 80 / 160 / 240 (trước đây 50 / 100 / 150), tiếp tục theo đường cong tăng HP hiện có. Sát thương nền 8 / 12 / 16, tăng theo lần gặp với hệ số 2,4 / 3,2 / 4,8. Tốc đánh khởi điểm ngẫu nhiên 8–22, cận dưới tăng 0,4 và cận trên tăng 0,6 mỗi lần gặp; trang bị và hiệu ứng khu vực tiếp tục áp dụng như trước.

Kiểm tra bằng LÖVE 11.5:

```
lovec.exe . --test-combat-tactics
lovec.exe . --test-combat-timing
lovec.exe . --capture-combat-timing
```

Kiểm tra logic gồm tốc tương đối, 30/60/144 FPS, một lần bấm, hết thời gian, 150 bố cục ngẫu nhiên, vùng đỏ ép đánh hụt kể cả có buff chính xác, phản thế tạo giáp và lộ sườn nhận thêm sát thương. Kiểm tra game thật đi qua thứ tự địch trước/sau, tấn công bằng bàn phím, parry bằng chạm, menu tạm dừng, chế độ ×4, cố ý bấm đỏ và bấm xanh lam. Ảnh: `combat_timing_attack.png`, `combat_timing_parry.png` và biến thể `_3`, `_4`.

Hồi quy phát hành 0.145.0: đã đồng bộ fixture giới hạn trang bị với hệ số boss riêng, cho phép boss tự do ở vùng cuối và migration HP mới; 42 nhóm scoring và 10 nhóm bổ sung đều qua.

## Âm thanh canh nhịp

18 cue riêng cho hai chế độ: mở thanh, đòn thường, xanh, vàng, lam ◆, đỏ và hết thời gian. Tấn công dùng tiếng chém với thân âm trầm; parry dùng cộng hưởng kim loại. Vàng có hợp âm ngân, lam ◆ có chuỗi nốt và lực trầm rõ hơn; đỏ trượt âm xuống với tiếng ma sát. Âm kết quả phát ngay khi bấm, tuân theo âm lượng SFX, mute và mixer hiện có. Các cue có headroom và giảm âm nền ngắn để không bị tiếng combat che.

Tạo lại riêng bộ này: `python scripts/build_timing_audio.py`; kiểm tra WAV: `python scripts/build_timing_audio.py --check`. Game nạp qua `config/timing_audio_baked.lua` và `src/timing_audio.lua`.

Nghe thử `audio/timing_feedback_preview.wav`: sáu âm tấn công rồi sáu âm parry, mỗi nhóm theo thứ tự xanh → vàng → lam ◆ → tím ★ → trắng ✦ → đỏ. Kiểm tra phát và giải mã cả 18 cue qua `lovec.exe . --test-audio`.

Kiểm tra mở đầu 200 seed đã qua với 80 HP. Ngoài lỗi nhóm địch nêu trên, `enemy_loadouts_smoke.lua:29` cũng lỗi với cả công thức địch cũ và mới; chưa thay đổi quy tắc đó trong đợt này.

Mốc Tuyệt Kỹ ★ nằm ở vị trí ngẫu nhiên riêng, có âm thanh riêng cho đánh và parry. Rộng 2,2% so với 4% của lam ◆; khi ngang tốc, cửa sổ trúng danh nghĩa khoảng 31,9 ms ở nhịp đều. Hai bên đều là đỏ nên bấm lệch sẽ đánh hụt / lộ sườn. Bộ kiểm tra bao gồm sát thương ×4 thực tế, phần thưởng giáp, biên hai bên, 150 bố cục và thao tác thật trong game.

Parry Tuyệt Kỹ ★ phản đòn về đúng kẻ đang tấn công, theo luật giáp, giảm sát thương và hồi sinh hiện có của địch. Ví dụ đòn 20 sát thương phản 2.000 sát thương trước phòng thủ địch. Nếu địch cuối bị phản chết trước lượt đánh người chơi, game chuyển thẳng sang thắng trận sau hiệu ứng tử vong và chỉ trao thưởng một lần.

Mốc Cực Hạn ✦ nằm riêng trong vùng đỏ còn lại, độc lập vị trí mốc tím. Rộng 1,5% thay vì 2,5% của tím; cửa sổ 24 ms khi ngang tốc, ngắn hơn khi địch nhanh. Có ký hiệu tia trắng và hai âm thanh riêng. Kiểm tra game thật riêng mốc này: `lovec.exe . --capture-combat-timing --apex-only` (đánh, parry, phản 5.000 sát thương từ đòn 20 và thắng trận nhờ phản đòn).

## Hiệu ứng trúng mốc và phản đòn

`src/timing_vfx.lua` bổ sung hai lớp: xác nhận ngắn ngay trên thanh khi bấm; hiệu ứng combat theo kết quả thật ở thời điểm va chạm. Không thay đổi sát thương, RNG hoặc cửa sổ timing.

- Xanh: vệt chém gọn và vài tia nhỏ; đỡ một phần chỉ hiện nửa khiên.
- Vàng → lam ◆: một lưỡi chém sắc nét, tan trong 0,28 giây.
- Tím ★: nhát cắt xiên mảnh, mép tím nhạt, đầu nhọn hơi móc và tia năng lượng nhỏ.
- Trắng ✦: cú bổ gần thẳng đứng, bản chém rộng, mặt trắng và cạnh xanh thép; điểm va chạm lóe ngắn, mảnh sáng đặc và lực giật rõ hơn tím. Vệt chính tan trong 0,32 giây, tối đa bảy mảnh nhỏ.
- Chặn hoàn toàn: khiên thép đặc, mép vát sáng, hai mặt kim loại và sống nổi. Khiên nhún nhẹ khi trúng đòn, tia va chạm ở mặt trên; bỏ dấu tick, không có sóng tròn hoặc viền phụ.
- Đánh hụt: một vệt chém đi bên cạnh mục tiêu và dấu hụt nhỏ, không có tia va chạm hoặc rung camera.
- Parry trượt: hai nửa của chính khiên thép nứt đỏ, tách và xoay ngược nhau; không để hình khiên nguyên phía sau.
- Phản đòn: khiên hấp thụ, lao năng lượng đi ngược từ người chơi về đúng địch tấn công, chạm sau 0,22 giây rồi bung hiệu ứng theo cấp. Âm chạm phản lực chỉ phát một lần khi lao đến đích. HP hiển thị, giật lùi, số sát thương và hiệu ứng tử vong của địch cũng chờ mốc 0,22 giây; nhịp hồi giữ tối thiểu 0,48 giây thực để chế độ ×4 không cắt mất cú phản lực.

Các hiệu ứng chạy theo thời gian thực để chế độ ×4 vẫn nhìn rõ. Chỉ rung camera và dừng hình ngắn khi đòn trúng, theo độ hiếm; giảm chuyển động dùng dấu hiệu tĩnh, không rung hoặc bắn hạt. Tối đa tám hiệu ứng, bảy tia mỗi hiệu ứng (giảm trên cấu hình mobile), tự dọn hết sau tối đa 1,02 giây. Đổi combat xóa toàn bộ hiệu ứng cũ.

Kiểm tra: `--test-combat-timing` bao gồm 162 tổ hợp loại/cấp/FPS, thời gian sống, RNG, giảm chuyển động và âm phản lực một lần. Kiểm tra thao tác thật dùng `--capture-combat-timing --apex-only`; thư viện 26 ảnh qua `--capture-combat-timing --vfx-gallery`.

Video xem thử: `timing_vfx_preview.mp4`, gồm 12 cảnh chạy ở 30 FPS. Tạo bằng `--capture-combat-timing --vfx-reel` với biến môi trường `TIMING_VFX_FFMPEG` trỏ tới FFmpeg cục bộ (đường dẫn tương đối không chứa khoảng trắng). Chỉ xuất video, không dùng encoder trong game thông thường.

Bản xem thử có âm thanh đồng bộ: `timing_vfx_preview_sound.mp4` (13,77 giây, H.264 960×540 / 30 FPS + AAC). Các ảnh `combat_timing_reflect_before_contact.png` và `combat_timing_reflect_after_contact.png` kiểm tra cảnh phản đòn kết liễu trong game: địch còn hiển thị nguyên trạng trước khi luồng phản lực tới, sau đó mới đổi HP, số sát thương và tan vỡ.

Quy chuẩn hiệu ứng hiện tại: bỏ hoàn toàn vòng tròn, cung xoáy, ấn hình học trang trí, quầng sáng và nét vẽ chồng tạo dư ảnh. Chỉ giữ một lưỡi chém, vài tia ngắn, một mặt khiên hoặc hai mảnh khiên vỡ. Phản đòn dùng một luồng ngắn đi tới địch rồi tan ngay khi chạm; không để dây sáng nối hai bên kéo dài.

Màu va chạm sáng và bão hòa hơn, lõi chém trắng sắc. Phản đòn trắng dùng một mũi lao dày, tím dùng luồng mảnh; độ sáng va chạm tính từ lúc chạm địch để không bị mờ vì thời gian bay. Phụ đề kết quả trong game và video dùng chung `ui/components/timing_caption.lua`: màu theo mốc, bóng chữ tối mảnh; từ lam ◆ trở lên có một lượt ánh sáng lướt qua chữ và tối đa ba điểm lấp lánh nhỏ. Chế độ giảm chuyển động giữ chữ tĩnh. Font và fallback của game hỗ trợ đầy đủ tiếng Việt.

Mẫu khiên thép đã chốt được dùng chung qua `ui/components/shield.lua`: parry, thanh giáp người chơi/địch, biểu tượng phòng thủ trên thanh timing, tăng/mất giáp, thuốc giáp/phá giáp, hộ vệ NEN và biểu tượng khiên trong chữ/cửa hàng/sổ tay. Các nơi chỉ chọn kích thước, màu nhấn, nửa khiên hoặc trạng thái vỡ; không sao chép hình dáng hay thêm vòng bao. Phần bóng và ánh sáng phụ của chữ không vẽ lặp biểu tượng khiên. Tranh minh họa lá bài vẫn do hệ thống ảnh Continental quản lý.

Kiểm tra và ảnh tổng hợp mẫu khiên: `lovec.exe . --test-shields`, xuất `shield_style_gallery.png`. Bao gồm sáu kích thước 12–110 px, biến thể nửa/vỡ, hai dạng emoji khiên trong chữ tiếng Việt, xuống dòng/căn lề, khôi phục trạng thái đồ họa và tích hợp renderer giáp/thuốc.

Parry có ba pha theo thời gian thực: nén khiên vào đòn trong 55 ms, giữ tới 75 ms, bật trả trong 70 ms rồi ổn định. Ánh lóe làm sáng chính mặt thép, không chồng thêm hình khiên. Phản lực rời khiên ở 90 ms, tăng tốc theo đường cong bậc ba và vẫn chạm địch đúng 220 ms. Va chạm phản đòn có một nhịp khựng riêng, nén địch nhanh, giữ lực 40 ms rồi bật lùi; trắng mạnh hơn tím. Nhịp dừng ngắn do VFX quản lý bằng đồng hồ thực, nên tốc độ ×4 không cắt mất cảm giác va chạm. Giảm chuyển động bỏ nén, rung, tia bay và nhịp dừng.

Khi bấm đúng mốc, thanh timing phát một dải sáng tại vị trí dừng, lan theo chiều thanh và bắn tia ngắn. Xanh/vàng gọn; lam ◆ có điểm lấp lánh; tím có dải tím rộng và tia sắc; trắng lóe khắp thanh với lõi trắng và mảnh sáng lớn hơn. Ánh sáng được giới hạn ở khu vực thanh, không có vòng bao hoặc dư ảnh. Thư viện `--vfx-gallery` hiện có 20 cảnh, gồm năm mốc sáng của thanh; video xem thử cũng dùng renderer timing thật.


## Thanh dài và chuỗi kỹ năng

Khung timing rộng 720 px, phần trượt 588 px (trước đó 510/370 px). Mốc giáp chuyển sang xanh lam để phân biệt vàng chặn đòn. Hồng ngọc có dấu đá quý lớn, lõi trắng và viền vàng; ô trúng vẫn đúng 0,8%. Sau khi trúng, toàn khung đổi màu theo mốc; giáp có khiên nhỏ, tím có tia chém xiên, trắng có lóe và mảnh sáng trắng, hồng ngọc có lõi vàng. Ánh sáng tăng vừa phải theo chuỗi, không vòng sáng hay dư ảnh. Nhãn dưới thanh hiển thị chuỗi từng mốc.

Kiểm tra: `--test-combat-timing`, `--test-timing-rewards`, `--capture-combat-timing --chains`, và `--vfx-gallery` (26 cảnh). Video mới có 12 cảnh, gồm cả Thần Tích và chuỗi ×3.

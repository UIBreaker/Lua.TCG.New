# Continental audio

Phiên bản đòn đánh có bản sắc riêng: 108 hiệu ứng file + 756 hiệu ứng stereo cho 27 thế Niệm + 40 cue thưởng cho 10 bậc hiếm, thêm 34 bản thu biến thể cho 17 âm thường lặp; 9 vòng nhạc soạn bằng DSP và 10 lớp âm môi trường. Giữ bản menu có sẵn. Các file mới là tác phẩm procedural của project, không lấy sample bên thứ ba. Game chỉ cần LÖVE; NumPy chỉ dùng khi xây dựng lại tài nguyên.

## Trong game

- UI, giấy bài, tiền và trang bị có chất liệu riêng. Hồi máu, vỡ giáp, SPN và nhịp chuẩn bị/tung đòn của quái có cue riêng.
- Chín thế poker cơ bản giữ bản sắc quân sự của hiệu ứng hiện tại: kỵ sĩ xuyên giáp, hộ vệ giao binh, đội kẹp sườn, giáo ba người, hành quân, ngọn cờ, pháo đài, trụ thành và giáo hoàng gia.
- 27 thế Niệm có score riêng trong `config/attack_audio.lua`: chất liệu, thân trầm, nhịp va chạm, khoảng cao độ và đuôi vang được viết cho từng thế. Charge, release, impact, armor_break, finisher, armored_finisher, boss_finisher, boss_armored_finisher và miss đều có ba bản phối thường/mạnh/cực mạnh; beat giữ motif riêng. Tổng 28 cue mỗi thế. Cấp cao thêm thân đòn, lớp cộng hưởng và dư chấn, thay vì chỉ hạ pitch. Peak charge 0,46/0,54/0,62; release 0,60/0,68/0,76; các contact 0,70/0,74/0,78; beat 0,62. Limiter tổng giữ mức 0,92, PCM về 0 ở hai đầu.
- Tích lực tăng áp bằng đúng chất liệu và chuỗi nốt của thế: nhịp motif nổi rõ trên lớp thân năng lượng dâng lên. Cấp thường ngắn và sáng; cấp mạnh dày, dài hơn; cấp cực mạnh có thêm một vòng motif dồn nhanh cuối câu, gain tăng dần và stereo bị thu hẹp tới lúc tung. Khi release, tiếng bật xuất hiện ngay mẫu đầu có âm, nở stereo trong 26 ms; cấp cao thêm thân xé khí, bồi âm vật liệu và nhịp đáp hai cánh. Không phát nổ va chạm sớm trong lúc chuẩn bị.
- Charge dài đúng tổng thời gian `NEN_AWAKENING + CARD_TRANSFORMATION + CHARGE`: 225 / 330 / 455 ms ở tốc thường. Âm được phát theo tốc animation × repeat acceleration, hỗ trợ pitch tối đa 4 riêng cho charge/release. Release đến thì dừng đúng cue charge của đòn đó; hủy đòn cũng dừng cue, không dừng âm của hành động khác. Đã bỏ khoảng silence ở đầu CHARGE vốn cắt mất crescendo cực mạnh. Nhịp gameplay và mốc gây sát thương giữ nguyên.
- Cấp thường: contact gọn, stereo hẹp và phòng vang ngắn. Cấp mạnh: thân trầm dày hơn, lớp vật liệu ngân, stereo mở vừa; dài hơn thường 200 ms. Cấp cực mạnh: chùm bồi âm từ chính các nốt của thế, toàn bộ motif đáp ở hai cánh, đuôi vật liệu hạ một quãng và phản xạ xa; dài hơn mạnh 520 ms. Độ rộng pan chính tăng 0,23 → 0,52 → 0,80. Cổng đá/vòng xoáy được cân mật độ riêng để không mất lực khi mở không gian.
- Phá giáp thêm tiếng nứt sắc, mảnh vỡ cao độ rơi và đối đáp stereo theo đúng nhịp/nốt/vật liệu của thế. Cực mạnh có nhịp giáp sụp trầm sau contact. Kết liễu thêm thân sụp đổ, motif hạ quãng và nhịp khép vang xa ở cấp cực mạnh. Vừa phá giáp vừa giết dùng một cue phối chung, không cộng ba tiếng contact rồi ép limiter. Cực mạnh hạ nhạc còn 25% trong 420 ms khi phá giáp, 22% trong 550 ms khi kết liễu; nền tự hồi sau đó.
- Outcome được chốt từ HP/giáp thực sau resolver của cả nhóm địch: phá giáp kể cả damage HP bằng 0, kết liễu cả mục tiêu phụ. Đòn hụt không phát contact; quái hồi sinh/hồi máu chưa chết không có âm kết liễu. Mỗi lượt sát thương chỉ phát một contact theo thế/cấp; duplicate callback không phát lại. Khi đã có finisher, bỏ death-hit/ash-break và jackpot trùng lúc; cái chết do nguồn khác vẫn có âm fallback. Số giáp mất và VFX vẫn hiện, chỉ tắt tiếng armor-loss chung khi cue phá giáp đã đảm nhiệm.
- Boss có hai bản kết liễu riêng (có/không phá giáp), đủ ba cấp lực. Giữ contact ngay lúc HP chạm 0; nhịp phán quyết theo motif của thế đến sau 180 / 255 / 330 ms trước pitch. Cực mạnh dồn năng lượng ở giữa câu, motif giáng rộng hai cánh, khép bằng hai tiếng vật liệu ngân xa. Từ dư âm đó mở thành khải hoàn: chất liệu riêng tiếp tục ngân, kèn hòa theo chính nốt/nhịp của thế, đáp hai cánh rồi hợp âm khép. Phần chuyển bắt đầu ở 650 / 1.100 / 1.550 ms trước pitch, lớp nối vào sớm hơn 220 ms để không có khoảng trống. Cả chuỗi nằm trong cùng PCM/voice, dài 3,85 / 4,35 / 4,85 giây trước pitch (khoảng 3,67 / 4,63 / 5,84 giây khi phát). Nhạc/môi trường hạ còn 46% / 30% / 14% trong 1,8 / 2,7 / 3,9 giây rồi hồi lên sau khải hoàn. Chỉ chọn khi một boss sống trước đòn thực sự chết sau resolver; boss hồi sinh, chuyển phase hoặc còn sống trong lúc lính chết vẫn dùng outcome tương ứng bình thường.
- Hai bước tính thưởng và chuyển màn gọi `Sound.playCombatVictory()`: nếu voice kết liễu boss có khải hoàn còn đang phát, không chồng thêm `round_win`, không cắt hoặc phát lại câu âm. Các màn thưởng CASH_OUT/boss draft/chest/map đều dùng cùng đường này. Thắng thường, kết liễu không có thế Niệm và voice đã dừng vẫn phát cue thắng chung. Không đổi công thức hay thời điểm trao thưởng.
- `src/reward_audio.lua` có bốn câu âm lấy đà / bật nắp / hé lộ vật phẩm / nhận lựa chọn cho mỗi bậc Thường, Không Thường, Hiếm, Sử Thi, Huyền Thoại, Thần Thoại, Siêu Việt, Độc Nhất, Vĩnh Hằng, Tối Thượng. Nhịp/nốt và bồi âm thay theo bậc: từ tiếng chốt gọn, kim loại đôi, chuỗi nốt sáng đến cộng hưởng nhiều lớp, đáp stereo rộng. Peak lấy đà 0,32; các contact tăng 0,475 → 0,70. 40 cue được bake sẵn. Mobile đăng ký đường dẫn lúc init, nạp trước các phase thưởng vào cache; cache miss vẫn nạp đồng bộ để không mất tiếng. Desktop tạo pool trước khi chơi.
- Hoạt cảnh thưởng chụp tông của voice boss đang ngân, tính cả pitch thực và octave; giữ tông đó xuyên chuỗi loot. Rương chờ qua nhịp nâng của khải hoàn nếu gold/giảm chuyển động đưa loot tới quá sớm; rương mở ở đúng mốc hé lộ, dừng đúng cue lấy đà. Bỏ qua hoạt cảnh cũng dừng lấy đà, không phát bù một loạt âm. Chốt vàng và thu linh hồn dùng tiếng nhận hòa cùng tông. Phiên thưởng không có loot không chờ thêm. Phần thưởng được trao đúng logic cũ, timing nghe không tiêu thụ RNG.
- Gói thưởng giữ rarity của rương; khi mở phát bản mở theo bậc đó, khi chọn/cất một vật phẩm phát bản nhận theo rarity thực của vật phẩm (hỗ trợ cả 10 bậc SPN). Chọn lỗi hoặc chọn lại gói đã đóng không phát âm nhận. Gói mua trong shop giữ phản hồi mua cũ. Vàng rơi/va chạm và phần thưởng vé theo số lượng vẫn có âm đặc trưng hiện tại.
- 17 cue giấy bài/coin/UI/combat đổi bản thu theo vòng ba lượt, kể cả khi không có tiếng nào đang chồng. Tất cả biến thể được tải trước, không tạo source mới trong lúc thao tác.
- Nổ giường có ngòi, blast, debris và rumble độc lập. Cái chết, tan tro, loot thường/hiếm và chuỗi tiền thưởng có âm riêng.
- Nhạc chuyển theo menu, khám phá, combat, boss, shop, nghỉ, sự kiện, chiến thắng và thất bại. Combat/boss/percussion cùng nhịp 120 BPM; lớp percussion tăng ở scoring, boss và dưới 30% HP.
- Nhạc dài 16 ô nhịp, 32–60 giây. Nửa sau phát triển chủ đề với horn, đối đáp dây/harp và percussion; nhịp cuối chừa khoảng thở. Độ lệch thời điểm/cường độ nhỏ được bake có seed cố định. Combat/boss/tension đồng bộ cả phần phát triển trong vòng 32 giây.
- Âm môi trường theo cảnh đang render; hải trình dùng biển, mưa/bão theo thời tiết. Thư viện hỗ trợ đủ bảy preset cùng biển/mưa/bão.
- Crossfade nhạc 1,25 giây; môi trường 1,8 giây. Đòn quan trọng hạ nhạc ngắn; khoảng lặng trước đòn cực mạnh hạ toàn bộ nền trong tối đa 80 ms.
- Cài đặt lưu riêng âm lượng tổng, SFX, nhạc và môi trường. Pause/settings hạ nền; mất focus dừng SFX và tạm ngưng các vòng nền.

## Tài nguyên và hiệu năng

`assets/audio/continental/manifest.json` lưu công thức, peak/RMS và SHA-256. `config/audio_catalog.lua` được sinh từ `scripts/build_audio.py`; chỉnh công thức trong script rồi build lại.

161 WAV stereo PCM 16-bit / 32 kHz, tổng khoảng 71 MiB, chưa tính PCM Niệm được tạo lúc khởi động. Peak SFX ≤ 0,64; nhạc ≤ 0,48; ambience ≤ 0,32. Lọc rumble dưới 28 Hz, hạ dải cao gắt, giữ bass ở giữa stereo và saturation mềm trước khi cân peak. Attack fade 1 ms giữ rõ transient; tail fade chống click. Stereo reflections và reverb được bake sẵn. Vòng nhạc giữ tail qua biên bằng wrap; kiểm tra bước nhảy sample ở biên loop.

Toàn bộ 756 phase Niệm (27 thế × 28 phase) có WAV ở `assets/audio/nen_outcomes/` (148,6 MiB); 40 cue thưởng ở `assets/audio/reward_cues/` (5,4 MiB). Metadata nằm trong `config/attack_outcome_audio.lua` và `config/reward_audio_baked.lua`, xuất bằng `python scripts/verify_audio_runtime.py --bake-outcomes`. Rebuild khi thay công thức âm thanh. Test so PCM và metadata với synthesizer để phát hiện bake cũ. Gói phát hành dùng OGG/WAV tối ưu như beta 0.138.1. Mobile không tổng hợp lúc khởi động: cache PCM ước tính 16 MiB cho các cue trì hoãn, không tính SFX chung và có thể vượt tạm thời khi voice đang phát. Cache chỉ đẩy pool không hoạt động; prewarm tối đa hai cue mỗi update, deadline mềm giữa các lần decode. Cache miss khi phát vẫn nạp đồng bộ; không cam kết mọi cold-play đều không cấp phát.

Mixer dùng tối đa 24 SFX và 6 stream nền. Mỗi cue có ba source dùng lại, không clone/tổng hợp lúc đánh. Cue yếu không ngắt cue mạnh; khi đòn chính phát, UI/giấy bài hạ bớt để giữ rõ đòn. Đánh liên tiếp hết ba slot của cùng đòn nặng thì contact mới thay đuôi cũ nhất, không bỏ mất đòn mới. Headroom tính theo mật độ đã cân ưu tiên. Limiter bảo thủ dựa trên peak thực của từng cue, kể cả PCM đăng ký bằng `registerProcedural`, giữ tổng tín hiệu dưới 0,92; bản menu có peak giả định tối đa 1. Va chạm ba cấp hạ nền về 62% / 46% / 30% trong 120 / 210 / 340 ms; release về 75% / 55% / 38% trong 100 ms; charge mạnh/cực mạnh về 84% / 72% cho tới lúc tung. Nền phục hồi sau transient, không bị giữ thấp suốt đuôi ngân. Cue khác giữ mặc định 100–180 ms. Variation pitch và sample dùng bộ đếm riêng, không tiêu thụ RNG gameplay. Stream hết crossfade được giải phóng; tài nguyên lỗi được cô lập và không tải lại mỗi frame.

## Kiểm tra

```powershell
python scripts/build_audio.py --check
& '../love-11.5-win64/lovec.exe' . --test-audio
```

Nếu launcher Windows không chạy trong môi trường kiểm tra:

```powershell
python scripts/verify_audio_runtime.py
python scripts/verify_audio_runtime.py --render
```

Fallback dùng chính DLL Lua 5.1/LÖVE 11.5, decoder, OpenAL và renderer, không giả lập giải mã bằng Python. Render chạy capture mode, không lưu setting/run; ảnh `settings.png` dùng màn cài đặt thật và kiểm tra input nút thật.

Đã kiểm tra: 161 WAV Continental không trùng, hash/peak/RMS/envelope/loop seam; 108 cue Continental + 756 cue Niệm và 34 biến thể decode/play thật; đường chọn tier → charge/release/impact và 2.106 ca outcome. Trên cả 27 thế: charge đúng thời lượng, crescendo cuối câu và stereo cực mạnh hội tụ; RMS charge/release tăng theo cấp; RMS contact thường mạnh tăng tối thiểu 8%, cực mạnh tăng tối thiểu 10%; năng lượng toàn đòn tăng tối thiểu 30% / 40%; năng lượng sau 360 ms của cực mạnh hơn gấp đôi cấp mạnh; stereo cực mạnh rộng hơn thường. Năm kiểu outcome có RMS contact tăng tối thiểu 6% và năng lượng tăng tối thiểu 20% mỗi cấp; dư chấn cực mạnh hơn 1,7 lần mạnh, khác contact thường. Kết liễu boss có năng lượng hơn bản thường ít nhất 15%, giữ RMS cú chạm đầu tối thiểu 90%, có thời lượng và đường bao riêng. Cả 351 cặp thế được so envelope/dải tần ở từng cấp cho tám loại gesture (8.424 phép so) để giữ bản sắc. Kiểm tra thêm pitch 3,72 khi fast-forward + repeat acceleration; dừng charge riêng khi tung/hủy; không silence đầu CHARGE; duck theo cấp, refire cực mạnh không mất contact, toàn bộ stream theo state; luân phiên bản thu, foreground/headroom, đồng bộ phần nhạc thứ hai, source pool/cooldown/priority/limiter/crossfade/focus/mute; button input; và các smoke test menu, quái, action VFX, scoring, 27 thế Niệm, nổ giường, phần thưởng, death fallback. Đây là kiểm tra tín hiệu; không thay cho đánh giá nghe của người chơi.

Phần khải hoàn được kiểm tra thêm ở cửa sổ nối 80 ms (không khoảng lặng), RMS phần ngân, và 1.053 phép so envelope/dải tần giữa 351 cặp thế ở ba cấp lực sau nhịp phán quyết. Mixer xác nhận hai lần gọi thắng liên tiếp không thêm voice/jingle chung, duck còn giữ qua CASH_OUT và tiếng nhận thưởng, tự hồi sau cao trào, có fallback khi voice kết liễu đã dừng.

Thưởng: 40 PCM stereo/32 kHz có peak/energy/đầu đuôi sạch, không trùng; 180 cặp so envelope/dải tần giữa các bậc ở bốn phase. Routing chạy đủ 10 bậc trong ceremony và chọn gói, 30/60/144 FPS, cả thường/nhanh/giảm chuyển động; đúng tông/thời điểm thực sau khải hoàn (không dùng đồng hồ animation chạy nhanh làm thời gian nhạc), dừng charge khi reveal/skip, không lặp khi chọn lại, không làm đổi RNG/thưởng. Kiểm tra thêm tông theo pitch thực của boss và hết voice trở về tông mặc định. Decoder/OpenAL phát cả 40 cue thật bằng pool, không tạo source lúc phát.

`continental_cinematic_preview.wav` là tuyển đoạn file SFX trên nhạc boss mới. `nen_cinematic_preview.wav` được kiểm tra runtime xuất từ đúng PCM Niệm trong game trên cùng nhạc nền, dài 24 giây. Chất lượng cảm nhận và cân âm cuối cùng vẫn cần nghe trên loa/tai nghe thực tế.

## Nghe từng bản sắc đòn đánh

`miss_showcase.wav`: 24 giây, Tứ Quý → Tesla → Băng → Nhật Thực; mỗi thế có tiếng hụt thường → mạnh → cực mạnh, cách nhau 2 giây. Dùng PCM, gain SFX 80% và pitch thực trong game, không normalize từng đoạn.

Đánh hụt có 81 cue riêng: gió lướt stereo và nhịp chất liệu của từng thế, không thêm tiếng nổ/thân trầm của va chạm. Đuôi dài 0,34 / 0,54 / 0,78 giây trước pitch; thường một nhịp lướt hẹp, mạnh có nhịp đáp vật liệu, cực mạnh thêm lớp ngân motif ở cuối và mở stereo rộng hơn. Peak 0,44 / 0,58 / 0,70, gain 0,48 / 0,64 / 0,80; không chỉ đổi pitch. Hình ảnh tăng từ 2 → 3 → 5 lớp vệt, dài và cong hơn theo lực; điện có nét gãy, băng/lăng kính có mảnh sắc, nhật thực có sóng lệch pha; tàn vụn theo nhịp/nốt riêng rồi tan trong 0,38 / 0,52 / 0,70 giây; quái né nhẹ, không lóe sáng hay rung camera. Giảm chuyển động giữ hai nét báo hụt tĩnh. Kiểm tra 3.402 tổ hợp thế/cấp/chất lượng/tuổi/giảm chuyển động; 1.053 cặp so tín hiệu miss giữa các thế; render đủ ba cấp ở thường/giảm chuyển động từ game thật và giữ nguyên HP/giáp. Thanh phụ “Mục tiêu / Đang giải quyết” đã bỏ khỏi combat; khung nhắm và tên trên mỗi địch vẫn dùng để chọn mục tiêu.

`boss_reward_flow.wav`: 16 giây minh họa **phán quyết → khải hoàn → rương Huyền Thoại → vật phẩm theo độ hiếm → nhận lựa chọn**, dùng cùng tông của Tứ Quý cực mạnh. Rương lấy đà ở 4,10 giây, bật nắp ở 4,625; vật phẩm Thường / Hiếm / Sử Thi / Huyền Thoại / Tối Thượng hé lộ ở 6 / 7,2 / 8,6 / 10,2 / 12,3 giây, nhận Tối Thượng ở 13,8. Đây là bản phối PCM minh họa, không đổi thời điểm hay xác suất loot trong game.

`reward_rarity_showcase.wav`: 40 giây so đủ 10 bậc theo thứ tự danh sách ở trên, mỗi bậc cách 4 giây; lấy đà → mở rương → hé lộ → nhận. Gain SFX mặc định 80%, không normalize riêng từng đoạn. Cue lấy đà được cắt khi bật nắp như trong game.

`boss_victory_showcase.wav`: 32 giây, bốn chuỗi **phá giáp → phán quyết → khải hoàn** cực mạnh của Tứ Quý / Tesla / Băng / Nhật Thực, lần lượt ở 0 / 8 / 16 / 24 giây. Không cắt đuôi; đúng gain SFX 80% và pitch tier trong game.

`boss_finisher_showcase.wav`: 64 giây, đã gồm phần khải hoàn nối tiếp. Tứ Quý kết liễu boss thường → mạnh → cực mạnh ở 0 / 8 / 16 giây; vừa phá giáp vừa kết liễu boss cực mạnh ở 24 giây. Cùng outcome cực mạnh của Tesla / Băng / Nhật Thực / Cổng Lục Địa ở 32 / 40 / 48 / 56 giây. `boss_verdict_signatures.wav`: đủ 27 thế vừa phá giáp vừa kết liễu boss cực mạnh và khải hoàn theo thứ tự bảng dưới, mỗi thế cách 8 giây, tổng 216 giây. Không normalize từng đoạn, để giữ tương quan lực trong game.

`armor_finisher_showcase.wav`: 43,2 giây, gain/pitch đúng contact trong game ở SFX 80%, không normalize từng đoạn. Tứ Quý phá giáp ở 0 / 3,6 / 7,2 giây; kết liễu ở 10,8 / 14,4 / 18 giây; vừa phá giáp vừa kết liễu ở 21,6 / 25,2 / 28,8 giây. Mỗi nhóm đi từ thường → mạnh → cực mạnh. Ba đoạn cuối là cùng outcome cực mạnh của Tesla (32,4), Băng (36), Nhật Thực (39,6), để so bản sắc. `armored_finisher_signatures.wav`: đủ 27 thế vừa phá giáp vừa kết liễu cực mạnh theo thứ tự bảng dưới, mỗi thế cách 4 giây, tổng 108 giây.

`poker_attack_preview.wav`: 9 thế cơ bản trong 18 giây. `hand_attack_signatures.wav`: đủ 27 thế, mỗi thế một khoảng 2 giây, gồm release → impact thực. Không nhạc nền, không normalize từng đoạn sau khi mix nên giữ được tương quan gain trong game. `attack_weights_preview.wav`: Đơn → Mạnh → Cực mạnh của Kỵ Sĩ Tiên Phong, mỗi cấp cách 2 giây. Các file đều được xuất bằng PCM thật trong test runtime.

`attack_tiers_showcase.wav`: 30 giây, thứ tự Tứ Quý → Tesla → Băng → Nhật Thực; mỗi thế có Thường → Mạnh → Cực mạnh, cách 2,5 giây. `extreme_attack_signatures.wav`: đủ 27 đòn cực mạnh theo cùng thứ tự bảng dưới, mỗi đòn cách 2,5 giây (67,5 giây). Hai file này và `attack_weights_preview.wav` dùng gain SFX mặc định 80% và resample theo đúng pitch của tier trong combat, không normalize từng đoạn. Nghe cả lực, độ rộng và phần ngân; tránh đánh giá chỉ bằng peak.

`windup_launch_showcase.wav`: chuỗi **tích lực → tung → va chạm** dài 38,4 giây. Thứ tự Tứ Quý → Tesla → Băng → Nhật Thực; mỗi thế đủ ba cấp thường/mạnh/cực mạnh, mỗi cấp cách 3,2 giây. `extreme_full_attacks.wav`: cả 27 chuỗi cực mạnh, 86,4 giây. Hai file đặt charge/release/impact theo đúng các mốc timing ở tốc thường và pitch từng phase, gain SFX mặc định 80%, không normalize từng đoạn; không thêm các beat phụ trong pha bay.

| Giây | Thế | Bản sắc |
|---|---|---|
| 0 | High Card | Một mũi giáo xuyên giáp, vó ngựa trầm |
| 2 | Pair | Hai tiếng thép đối đáp |
| 4 | Two Pair | Bốn nhát kẹp sườn, trái/phải |
| 6 | Three of a Kind | Ba mũi giáo khí nén |
| 8 | Straight | Năm nhịp hành quân tăng dần |
| 10 | Flush | Cờ quật gió, sóng khí rộng |
| 12 | Full House | Pháo khai hỏa, gạch đá vỡ |
| 14 | Four of a Kind | Bốn trụ đá, nhịp trầm dần |
| 16 | Straight Flush | Giáo hoàng gia và hợp âm kèn |
| 18 | Tesla 369 | Ba hồ quang, sấm theo sau |
| 20 | Jackpot 777 | Ba khóa vàng, tiếng tiền ngân |
| 22 | Fibonacci | Năm vòng cộng hưởng giãn dần |
| 24 | Prime | Năm sao bắn độc lập |
| 26 | Odd Star | Chín tia sáng xòe |
| 28 | Even Frost | Nghiền băng, vỡ giòn |
| 30 | Crimson Tide | Sóng đặc, bọt trầm, hút ngược |
| 32 | Obsidian Tide | Đá đen cào sắc, mảnh vỡ |
| 34 | Eclipse Duality | Hai đĩa lệch pha hội tụ |
| 36 | Four Kingdom Prism | Bốn tiếng thủy tinh khúc xạ |
| 38 | Four Kingdom Expedition | Bốn hồi quân hiệu trên trống trận |
| 40 | Destiny Crown | Kiếm phán quyết, chuông uy nghi |
| 42 | Continental Gate | Cổng đá nghiến, đóng sập |
| 44 | Answer 42 | Bốn tín hiệu cộng hai |
| 46 | Sealed Gate | Đại kiếm, thép rèn và chốt khóa |
| 48 | Seven Stars | Bảy sao rít xuống |
| 50 | Five Ley Lines | Năm mạch đất trồi |
| 52 | Endless Cycle | Xoáy hút, nén và khép vòng |

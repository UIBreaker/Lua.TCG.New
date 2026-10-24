# Continental — âm thanh bàn bài trầm ấm

Bản phối ngày 24/10/2026 thay hướng điện ảnh ồn, sáng và vang dài bằng âm thanh gần, khô và nhỏ: giấy bài, mặt bàn nỉ/gỗ, đồng xu cổ, di vật và phép thuật tiết chế, hợp một cuộc viễn chinh fantasy phương Tây trên bàn bài. Đây là bản đang dùng trong game, thay các thông số phối âm trước đó.

## Thiết kế hiện tại

- Thao tác: bài sột soạt ngắn, ít cao độ; đánh bài là tiếng chạm bàn nhẹ. Hover rất nhỏ; không thêm chuông ở mọi lần di chuột.
- Tính điểm/tiền: đồng xu thấp hơn, tiếng chip và multiplier nhẹ hơn; cooldown tối thiểu 60 ms. Các tiếng cùng cue và nhóm tiền thưởng chia ngân sách âm lượng theo căn bậc hai số voice đang phát, tránh cộng dồn tuyến tính khi tính điểm nhanh.
- Chiến đấu: giữ nhịp riêng của 27 thế Niệm, ba cấp lực và các outcome; hạ cao độ vật liệu 20%, gain còn 58% bản trước, giảm phản xạ xa và làm mềm dải cao. Không cần tăng độ ồn lớn ở mỗi cấp để báo một đòn mạnh hơn.
- Phần thưởng: chuỗi dây gảy/đồng cổ trầm hơn, đuôi nốt ngắn, vang ít; 10 bậc hiếm phân biệt bằng nhịp và khoảng nốt. Tông nhận thưởng khớp tông thực đã hạ của boss.
- Căn nhịp: 20 cue đánh/đỡ từ ready đến divine/trap/timeout được dựng lại thấp và ngắn tiếng hơn, gain 0,12–0,36; không chồng một fanfare lớn lên đòn chính.
- Phổ âm: loại bớt trầm dưới 60 Hz, làm mềm cao bằng hai tầng low-pass quanh 2.300 Hz và thu hẹp stereo. Áp dụng lúc build hoặc fallback tổng hợp; không lọc từng frame khi chơi.
- Phối nền: SFX nhấn nhẹ nền trong 60–380 ms, thay việc kéo nền xuống sâu nhiều giây. Giảm gain nhạc catalog 20% (menu 0,38 → 0,25), môi trường 0,25 → 0,15; giữ nguyên file nhạc, các slider và thiết lập đã lưu của người chơi.
- Mixer vẫn có 24 SFX / 6 stream, source pool, ưu tiên, crossfade, focus/mute và cache mobile 16 MiB. Giới hạn tổng peak bảo thủ giảm từ 0,92 xuống 0,72. Không thay RNG, HP, sát thương, mốc animation hay xác suất thưởng.

## Tài nguyên và dựng lại

958 WAV hiệu ứng: 108 cue chung + 34 biến thể + 756 cue Niệm + 40 cue thưởng + 20 cue căn nhịp. Stereo PCM 16-bit / 32 kHz. Tổng hợp gốc của project, không dùng sample bên thứ ba. Nhạc và ambience giữ bản thu hiện có.

```powershell
python scripts/build_audio.py
python scripts/build_timing_audio.py
python scripts/verify_audio_runtime.py --bake-outcomes
python scripts/build_audio.py --check
python scripts/build_timing_audio.py --check
python scripts/verify_quiet_audio.py
python scripts/verify_audio_runtime.py
python scripts/verify_audio_runtime.py --render
```

`src/audio_finish.lua` xử lý bản tổng hợp Niệm/thưởng; `scripts/build_audio.py` xử lý SFX file chung/căn nhịp. Mobile dùng file bake và nạp trước/cache hiện có, không tổng hợp khi khởi động. Gói phát hành vẫn dùng `scripts/build_runtime_audio.py` để tạo cache OGG theo hash mới.

Kiểm tra mới ràng buộc gain không quá 0,60, năng lượng trên 5 kHz dưới 1,5%, RMS toàn cue ở SFX 80% dưới 0,11, cạnh PCM sạch; kiểm tra mixer chặn cộng dồn lặp và giữ peak tổng 0,72. Các kiểm tra bản sắc, thời điểm, routing, PCM khớp synthesizer và không cấp phát source lúc phát vẫn được giữ. Kiểm tra cấp lực đánh giá nhịp/thời lượng và khả năng nghe rõ, thay yêu cầu bản cũ phải tăng lớn năng lượng/đuôi nổ qua từng cấp. Những giới hạn này là kiểm tra tín hiệu, không phải cam kết cảm nhận trên mọi loa/tai nghe.

## Nghe thử

- `continental_preview.wav`: 20 giây — bài, mua hàng, hồi máu, đòn cơ bản, phần thưởng.
- `continental_cinematic_preview.wav`, `nen_cinematic_preview.wav`: chiến đấu trên nền nhạc đã hạ.
- `timing_feedback_preview.wav`: phản hồi căn nhịp đánh/đỡ.
- `boss_reward_flow.wav`: kết liễu → câu kết → mở rương → nhận vật phẩm.
- `reward_rarity_showcase.wav`: đủ 10 bậc hiếm.
- Các file `attack_tiers_showcase`, `windup_launch_showcase`, `miss_showcase`, `armor_finisher_showcase` và `boss_victory_showcase` vẫn dùng để so nhịp riêng của từng đòn.

Preview ghi mức phối SFX 80%, không normalize riêng từng đoạn để biến tiếng nhỏ thành tiếng lớn. Bảng dưới là thứ tự trong `hand_attack_signatures.wav` (2 giây/thế), vẫn giữ chủ đề vật liệu nhưng với chất âm trầm và tiết chế mới.

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

# Continental audio

108 hiệu ứng stereo riêng, 9 vòng nhạc được soạn bằng DSP và 10 lớp âm môi trường. Giữ bản menu có sẵn. Các file mới là tác phẩm procedural của project, không lấy sample bên thứ ba. Game chỉ cần LÖVE; NumPy chỉ dùng khi xây dựng lại tài nguyên.

## Trong game

- UI, giấy bài, tiền và trang bị có chất liệu riêng. Hồi máu, vỡ giáp, SPN và nhịp chuẩn bị/tung đòn của quái có cue riêng.
- Chín thế bài có charge/release/impact và từng nhịp riêng: xuyên, song đao, quỹ đạo, tam giác rune, chuỗi kim loại, sóng, hợp nhất, phong ấn và bão kiếm.
- Nổ giường có ngòi, blast, debris và rumble độc lập. Cái chết, tan tro, loot thường/hiếm và chuỗi tiền thưởng có âm riêng.
- Nhạc chuyển theo menu, khám phá, combat, boss, shop, nghỉ, sự kiện, chiến thắng và thất bại. Combat/boss/percussion cùng nhịp 120 BPM; lớp percussion tăng ở scoring, boss và dưới 30% HP.
- Âm môi trường theo cảnh đang render; hải trình dùng biển, mưa/bão theo thời tiết. Thư viện hỗ trợ đủ bảy preset cùng biển/mưa/bão.
- Crossfade nhạc 1,25 giây; môi trường 1,8 giây. Đòn quan trọng hạ nhạc ngắn; khoảng lặng trước đòn cực mạnh hạ toàn bộ nền trong tối đa 80 ms.
- Cài đặt lưu riêng âm lượng tổng, SFX, nhạc và môi trường. Pause/settings hạ nền; mất focus dừng SFX và tạm ngưng các vòng nền.

## Tài nguyên và hiệu năng

`assets/audio/continental/manifest.json` lưu công thức, peak/RMS và SHA-256. `config/audio_catalog.lua` được sinh từ `scripts/build_audio.py`; chỉnh công thức trong script rồi build lại.

WAV stereo PCM 16-bit / 32 kHz, tổng khoảng 46 MiB. Peak SFX ≤ 0,64; nhạc ≤ 0,48; ambience ≤ 0,32. Envelope chống click, stereo reflections và reverb được bake sẵn. Vòng nhạc giữ tail qua biên bằng wrap; kiểm tra bước nhảy sample ở biên loop.

Mixer dùng tối đa 24 SFX và 6 stream nền. Mỗi cue có ba source dùng lại, không clone/tổng hợp lúc đánh. Cue yếu không ngắt cue mạnh; cooldown và giới hạn mỗi cue chặn spam. Limiter bảo thủ dựa trên tổng peak đã kiểm chứng giữ tổng tín hiệu dưới 0,92, gồm cả bản menu có peak giả định tối đa 1. Variation pitch có bộ đếm riêng và không tiêu thụ RNG gameplay. Stream hết crossfade được giải phóng; tài nguyên lỗi được cô lập và không tải lại mỗi frame.

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

Đã kiểm tra: 127 WAV không trùng, hash/peak/RMS/envelope/loop seam; 108 cue decode/play thật; toàn bộ stream theo state; source pool/cooldown/priority/limiter/crossfade/focus/mute; button input; và các smoke test menu, quái, action VFX, scoring, chín thế bài, nổ giường, phần thưởng. File preview 20 giây là tuyển đoạn SFX. Chất lượng cảm nhận và cân âm cuối cùng vẫn cần nghe trên loa/tai nghe thực tế.

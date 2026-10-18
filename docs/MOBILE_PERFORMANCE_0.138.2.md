# Mobile performance — beta 0.138.2

Giữ nguyên gameplay, hình ảnh, số lượng hiệu ứng và mức chất lượng; tối ưu việc khởi tạo, tuổi thọ cache và công việc GPU lặp lại. Tài nguyên gốc không bị thay đổi.

## Phép đo có thể chạy lại

`tests/mobile_profile` chạy LÖVE 11.5 Windows, mount chính gói Mobile.love trước/sau. Seed cố định 1792330200, 720 frame menu/trận/shop, bỏ 80 frame đầu mỗi cảnh, vsync tắt, dt 1/60. Chạy ba lần mỗi mức LOW/HIGH, không chạy build/test nặng cùng lúc. CSV ở `docs/performance/mobile_0.138.2/`. `menu_ready` tính phần khởi tạo game sau mount/instrumentation, không phải toàn bộ thời gian bấm icon Android. RSS gồm archive FileData và driver trên PC; không quy đổi trực tiếp thành RAM/FPS điện thoại.

| Trung vị | 0.138.1 LOW | 0.138.2 LOW | 0.138.1 HIGH | 0.138.2 HIGH |
|---|---:|---:|---:|---:|
| Sound.init (ms) | 4925.721 | 194.697 | 4929.246 | 196.111 |
| Menu ready (ms) | 5380.241 | 535.536 | 5385.034 | 534.700 |
| RSS menu ready (MiB) | 513.2 | 318.8 | 515.8 | 318.8 |
| Menu frame trung bình (ms) | 3.054 | 3.027 | 3.106 | 3.021 |
| Trận frame trung bình (ms) | 5.014 | 4.861 | 5.015 | 4.830 |
| Shop frame trung bình (ms) | 4.975 | 4.696 | 5.065 | 4.752 |
| RSS trong trận (MiB) | 599.9 | 436.6 | 600.0 | 437.9 |
| RSS shop (MiB) | 610.2 | 439.5 | 610.2 | 439.7 |

## Thay đổi và giới hạn

- Bake 675 phase Niệm + 40 cue thưởng bằng cùng synthesizer, kiểm tra PCM/metadata. Mobile chỉ đăng ký chúng lúc init, prewarm theo đòn/thưởng, PCM cache ước tính 16 MiB; voice đang phát không bị ngắt. SFX chung nằm ngoài budget. Cache miss vẫn decode đồng bộ; deadline prewarm là mềm, không thể ngắt một lần decode.
- Nạp tranh phụ/quái khi dùng; indexed Canvas cache 16 trên mobile, mesh 64 và rim 128. Không release Canvas còn được animation giữ. Full GC một lần sau init, thu hồi cache khi `love.lowmemory`.
- Cache duy nhất một lớp nền Image/radius bằng đúng shader 9 tap; video/Canvas động giữ đường vẽ trực tiếp. Camera, fog, weather và particle vẫn cập nhật. Pixel RMSE 0.00309 trên thang 0–1 do thứ tự lọc/làm tròn; không tuyên bố bit-identical. Tranh clipping RMSE 0; khung tier 10 sai số tối đa 1/255.
- Mobile giữ warm-up shader trên Canvas nhỏ, bỏ vòng warm geometry toàn bộ profile lúc startup. Kiểm tra combat thật đủ 9 profile ở LOW/MEDIUM/HIGH.
- `assets/game.love` được ZIP_STORED trong APK thay vì nén ZIP lần hai. AssetManager.openFd yêu cầu asset không nén ([Android docs](https://developer.android.com/reference/android/content/res/AssetManager)); điều này sửa cấu trúc gói, chưa chứng minh là nguyên nhân duy nhất gây chậm trên máy người dùng.

Chưa có điện thoại Android thật để đo tổng thời gian mở game, FPS, RAM hoặc xác minh cài đè. Chạy benchmark: `lovec tests/mobile_profile <short-path-Mobile.love> <output.csv> LOW` (hoặc HIGH). Kiểm tra render: `lovec tests/mobile_render <after.love> <before.love>`.

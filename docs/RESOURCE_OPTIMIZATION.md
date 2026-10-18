# Tối ưu tài nguyên phát hành — beta 0.138.1

Đo bằng file thật từ beta 0.138.0 và APK mới, đơn vị MiB (1024² byte):

| Thành phần đã nén trong game.love | Trước | Sau |
| --- | ---: | ---: |
| Âm thanh, gồm nhạc và menu | 173,9 | 35,3 |
| Tranh bài, gồm fallback hiện có | 65,3 | 25,5 |
| APK đã ký | 288,0 | 109,5 |

APK giảm **61,98%**, từ 301.982.124 xuống 114.811.308 byte. Không xóa thế bài, SPN, âm thanh, biến thể hoặc tính năng; không đổi dữ liệu save.

## Âm thanh

`scripts/build_runtime_audio.py` chuyển WAV sang Ogg Vorbis quality 7, giữ số kênh/tần số lấy mẫu. Cache dưới `dist/runtime-audio`, ký bằng hash nguồn/công thức và kiểm tra hash đầu ra. Mỗi file được decode lại để kiểm tra độ dài (lệch tối đa 5 ms), peak và tỷ lệ năng lượng (0,94–1,06). Chỉ dùng OGG khi giảm ít nhất 10% dung lượng và qua kiểm tra; còn lại đóng gói PCM.

539/566 WAV được chuyển sang OGG; 27 âm rất ngắn hoặc nhạy với codec giữ WAV. Tổng file WAV nguồn 197,9 MiB thành 32,1 MiB tài nguyên phát hành, chưa tính MP3 menu. Nguồn WAV và công thức tổng hợp vẫn nguyên trong project. Đây là nén có mất dữ liệu, không phải âm thanh giống từng byte; không giảm số cue. Mixer tính thêm khoảng dự phòng peak 20% cho file Vorbis, phù hợp giới hạn được kiểm tra khi build. Nhạc vẫn stream; cue vẫn tạo pool lúc khởi động, không thêm decode trong lúc đánh.

`src/runtime_assets.lua` chọn OGG nếu có, fallback WAV khi chạy project gốc. Đường dẫn được cache. Áp dụng chung desktop/mobile/web qua `scripts/build_release.py`.

## Tranh và đóng gói

Chỉ đóng gói 466 texture Continental đang được cấu hình sử dụng (522 ID có thể dùng chung tranh), bỏ bản PNG nguồn và runtime cũ không còn tham chiếu. Loader lấy runtime trước khi kiểm tra fallback PNG, nên hoạt động khi nguồn không nằm trong gói. Bản gốc vẫn giữ trong project để sửa art và build lại.

Giữ giới hạn texture mobile 256×384 như bản cũ, desktop 512×768. JPEG chất lượng 88; ảnh có alpha giữ PNG. 466 JPEG mobile so với bản cũ cùng kích thước có RMSE trung bình 5,66/255, tối đa 7,66/255. UI atlas giữ kích thước/dữ liệu gốc vì dùng tọa độ pixel; không làm nhỏ atlas tùy tiện. Bản phát hành không mang docs, video minh họa, cache chuyển mã hay file thiết kế.

Mỗi lần build xuất báo cáo `.size.json` cạnh `.love` để theo dõi dung lượng. Lua/GLSL trong APK vẫn đối chiếu byte với source; không sửa mã khi đóng gói. `scripts/build_android.py` tiếp tục kiểm tra chữ ký, CRC, ABI, fullscreen và checksum.

## Kiểm chứng và build

Yêu cầu FFmpeg có libvorbis, NumPy và Pillow khi build; đặt `FFMPEG` hoặc cài FFmpeg vào PATH. Không thêm thư viện cho người chơi.

```powershell
python scripts/build_android.py
python scripts/build_release.py --target windows
# Dùng đường dẫn ngắn ASCII trên Windows nếu tên thư mục chứa Unicode:
lovec.exe tests/optimized_package <absolute-path-to-game.love>
```

`tests/runtime_assets_smoke.lua` kiểm tra OGG/PCM, khoảng peak và art không có nguồn. `tests/optimized_package` mount gói thật, decode mọi tranh/âm thanh, xác nhận 405 outcome được đọc từ file thay vì tổng hợp lại, khởi tạo mixer đủ 823 cue và phát thử. Scoring audit 38 bộ, kiểm tra save/vé/bậc SPN/mobile và audio runtime gốc đều qua.

Chưa đo FPS/RAM hoặc đánh giá nghe trên điện thoại thật. Giảm dung lượng tải không đồng nghĩa giảm tương ứng bộ nhớ PCM sau decode. Lỗi cài APK từng báo ở 0.136.0 vẫn chưa có mã lỗi Android để kết luận nguyên nhân.

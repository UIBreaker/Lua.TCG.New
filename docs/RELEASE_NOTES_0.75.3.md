# LUA.TCG 0.75.3

- **Windows 64-bit:** tải `LUA-TCG-0.75.3-Windows-x64.zip`, giải nén toàn bộ, mở `LUA-TCG.exe`. Không cần cài Lua hoặc LÖVE.
- **Android — APK cài trực tiếp:** tải `LUA-TCG-0.75.3-Android.apk`, mở file, chọn **Cài đặt**, rồi mở **Terra Suit**. Không cần LÖVE riêng; chơi offline. Android 6+, ARM 32/64-bit; khoảng 58 MiB. Khi Android yêu cầu, cho phép ứng dụng đang mở file cài từ nguồn này rồi tắt lại sau khi cài. APK có tên gói riêng, màn hình ngang, icon game và không yêu cầu Internet, micro hay quyền đọc bộ nhớ ngoài.
- **Android và iPhone — trình duyệt:** mở [trang chơi web](https://uibreaker.github.io/Lua.TCG.New/), xoay ngang máy, bấm **BẮT ĐẦU CHƠI**.
- **Android / máy đã cài LÖVE 11.5:** có thể mở `LUA-TCG-0.75.3-Mobile.love` bằng LÖVE. Đây là gói game, không phải APK cài độc lập.
- `LUA-TCG-0.75.3.love` là gói cho các máy đã cài LÖVE. `SHA256SUMS.txt` dùng kiểm tra tính toàn vẹn tải về.

Điện thoại: chạm chọn bài, rê chọn nhiều lá, giữ 0,5 giây để xem bài hoặc dùng tiêu hao. Bật **ĐỔI CHỖ** rồi kéo để sắp xếp; có thanh nút lớn Đánh / Bỏ / Bộ bài / Quay lại trên trình duyệt cảm ứng. Các giao dịch tiếp tục dùng bước xác nhận của game.

Ảnh trong bản phát hành được thu gọn riêng; tài nguyên gốc vẫn nằm trong repository. Bản điện thoại dùng canvas 1280×720, đồ họa LOW mặc định và ảnh nhỏ hơn, bỏ video nền menu. Save trong trình duyệt lưu theo thiết bị và trình duyệt; xóa dữ liệu trang web sẽ xóa save.

Đã kiểm tra khởi động, vào trận và các cử chỉ bằng kiểm thử trên máy tính. Chưa kiểm chứng trực tiếp trên thiết bị Android hoặc iPhone thật; tốc độ, âm thanh và độ tương thích còn phụ thuộc trình duyệt/máy.

APK đã kiểm tra chữ ký v1/v2/v3, zip alignment, launcher, application ID và dữ liệu game nhúng. Khóa ký riêng không nằm trong repository.

**Cập nhật Android tràn viền (versionCode 754):** ẩn thanh trạng thái/điều hướng từ lúc mở game, phủ đầy màn hình ngang dài, giữ ánh xạ chạm đúng theo tỷ lệ hiển thị. Tự khôi phục fullscreen khi quay lại ứng dụng. Dùng cùng khóa ký với APK đầu tiên, cài đè bằng **Cập nhật** để giữ save. Đã kiểm tra bốn tỷ lệ màn hình, cử chỉ và ảnh xem trước từ game; cần xác nhận lại trên điện thoại thật.

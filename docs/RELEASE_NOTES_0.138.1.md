# Terra Suit — beta 0.138.1 cho Android

- Tối ưu APK từ **288,0 xuống 109,5 MiB**, giảm **61,98%**; giữ toàn bộ tính năng, 96 SPN và các biến thể âm thanh.
- Chuyển 539 WAV sang Ogg Vorbis chất lượng 7; giữ 27 WAV ngắn/nhạy với codec. Kiểm tra decode, độ dài, peak và năng lượng từng file; thêm khoảng dự phòng peak cho mixer. Tài nguyên gốc vẫn nguyên trong project.
- Loại tranh nguồn đóng gói trùng và runtime cũ không được dùng; chỉ giữ texture Continental hiện tại. Giữ giới hạn texture mobile, không thu nhỏ atlas UI; loader có fallback WAV/PNG khi chạy source.
- Pipeline tài nguyên tối ưu dùng chung PC/mobile/web; có cache theo hash và báo cáo dung lượng sau build. Không đổi dữ liệu save hoặc cơ chế chơi.

Tải `LUA-TCG-0.138.1-Android.apk`, mở rồi chọn **Cập nhật**. Không gỡ bản cũ để giữ save. Android 6.0 trở lên, ARM64/ARMv7; cùng khóa ký, versionCode 13801.

Đã kiểm tra gói tối ưu thật bằng LÖVE: 522 ID tranh, 567 file âm thanh, 675 cue Niệm, 405 outcome đọc từ file; mixer đủ 823 cue. Scoring audit 38 bộ không lỗi; kiểm tra audio, save/vé/SPN, cảm ứng và bốn tỉ lệ màn hình. Chữ ký/source/shader/checksum được xác minh.

Chưa thử cài/cập nhật hoặc đo FPS/RAM trên điện thoại thật. Chưa xác nhận sửa lỗi cài 0.136.0 trên máy đã báo lỗi. OGG/JPEG là nén có mất dữ liệu; giữ nguyên nội dung và số lượng tài nguyên, không tuyên bố giống từng byte bản gốc.

# Terra Suit — beta 0.138.2 cho Android

- Giảm chờ vào menu: bake sẵn toàn bộ âm thanh Niệm và phần thưởng; điện thoại không phải tổng hợp chúng lúc mở game.
- Giảm RAM: nạp âm thanh theo đòn sắp dùng, cache có giới hạn và giữ nguyên tiếng đang phát; tranh phụ/quái được nạp khi cần. Thu hồi cache khi hệ thống báo thiếu bộ nhớ.
- Giảm việc vẽ lặp: cache phần làm mờ nền tĩnh, tái dùng hình học khung bài và giới hạn cache tranh có chỉ số. Giữ nguyên tính năng, tranh, hiệu ứng và mức chất lượng hiện tại.
- Giữ `game.love` không nén lần hai trong APK, cho phép truy cập tài nguyên dạng seekable.

Đo trên PC bằng LÖVE với cấu hình mobile, cùng seed, trung vị ba lần: khởi tạo menu **5,38 → 0,54 giây**, RAM tiến trình lúc menu sẵn sàng **513 → 319 MiB**. Thời gian khung hình trận/shop giảm khoảng **3–6%**. Đây không phải số đo trên điện thoại hoặc thời gian từ bấm biểu tượng Android; xem `docs/MOBILE_PERFORMANCE_0.138.2.md` và CSV gốc.

APK khoảng **115,3 MiB**, lớn hơn 0.138.1 khoảng 6 MiB vì lưu sẵn âm thanh để đổi lấy khởi động nhanh và ít RAM. Không hạ độ phân giải tranh. Android 6+, ARM64/ARMv7, landscape; versionCode 13802, cùng khóa ký. Mở APK và chọn **Cập nhật**, không gỡ bản cũ để giữ save.

Đã kiểm tra: 38 bộ scoring; cache âm thanh/cảm ứng/lưu tải; 675 cue bake khớp PCM gốc; 2.106 ca outcome; chiến đấu và targeting thật bằng LÖVE; so ảnh trước/sau, cache và gói APK/chữ ký/checksum/source. Chưa thử cài/cập nhật và đo FPS/RAM trên điện thoại thật. Chưa xác nhận sửa lỗi cài APK 0.136.0 đã được báo trước đó.

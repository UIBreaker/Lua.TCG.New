# Terra Suit — beta 0.140.0 cho Android

- **Tượng Cổ**: cuối ải chẵn sau boss/shop có 30% cơ hội xuất hiện. Chọn quân bài, mỗi lần hiến 10% HP hiện tại để nhận một trong mười kết quả được công khai. Lưu/tải giữ kết quả, lá chọn và số lần chạm.
- **Lãnh Địa Máu**: hiến máu tới ngưỡng ≤10% HP tối đa sẽ vào nhánh tám trận, mỗi ải có địch riêng. Độ khó bằng ×2 mốc nhánh chính tại lúc vào; có shop nhỏ và hai cảnh nền mới. Boss Vương Huyết nhân đôi chỉ số khi bạn thực sự hồi HP, cuối lượt trừ 2% HP hiện tại. Thắng chọn một trong ba SPN sức mạnh ×4, rồi trở lại đúng hành trình gốc.
- **10 boss nhân loại mới**: mỗi boss có tranh, nội tại và kỹ năng riêng; gặp trong các ải địa phương 1–20 của vùng Con Người. Có khóa thế bài, vô hiệu J/Q/K, giáp đặc biệt, cướp tốc, bắt giữ quân bài và tác động vĩnh viễn lên bài/SPN. Nội dung và cảnh báo xem trong game hoặc `docs/HUMAN_BOSSES.md`.
- Nâng trần tiến hóa quân bài từ 8 lên **10**, cập nhật sức mạnh khả năng, khung TT/TT+1 và lưu/tải.
- Bổ sung 19 tranh dọc và hai nền Continental; cập nhật UI sự kiện, tiến độ lãnh địa, thông tin boss và khung/tiến hóa bài. Giữ các tính năng và tối ưu mobile từ bản trước.

Android 6+, ARM64/ARMv7, khóa ngang và tràn màn hình. APK **119,1 MiB**. VersionCode **14000**, cùng khóa ký và định dạng save. Mở `LUA-TCG-0.140.0-Android.apk`, chọn **Cập nhật**; không gỡ bản cũ để giữ save.

Đã kiểm tra: 40 nhóm scoring; 8 nhóm tính năng mới/combat/lưu tải; luồng Tượng Cổ đến phần thưởng/quay về và đủ mười boss trong game thật; 6 nhóm mobile/cache/cảm ứng/SPN; 546 ID tranh và 958 file âm thanh decode được trong gói mobile; cấu trúc gói, chữ ký, checksum và toàn bộ Lua/shader nhúng khớp mã nguồn phát hành. Không thay dữ liệu lưu của người chơi trong quá trình kiểm tra.

Chưa thử cài đè hoặc đo FPS/RAM trên điện thoại thật. Không xác nhận sửa lỗi cài APK của thiết bị từng báo lỗi ở bản 0.136.0.

# Thời tiết chiến trường

Thời tiết luân phiên theo ải qua 14 trạng thái; giữ nguyên khi chuyển từ chọn bài sang tính sát thương. Đây là hiệu ứng hình ảnh, không sửa chỉ số chiến đấu hoặc RNG gameplay.

| Thứ tự trong chu kỳ | Thời tiết | Hiệu ứng |
|---|---|---|
| 1 | Nắng | Tia sáng mềm, bụi lơ lửng |
| 2 | Gió | Vệt gió cong, bụi cuốn theo cơn |
| 3 | Mưa | Mưa xiên nhiều lớp, vòng nước trên mặt đất |
| 4 | Sương mù | Dải sương mềm trôi gần mặt đất |
| 5 | Bão sét | Mưa mạnh, sét phân nhánh xa và quầng sáng dịu |
| 6 | Cực quang | Ba dải ánh sáng xanh tím chuyển động |
| 7 | Mưa sao băng | Sao băng có đuôi sáng tan dần |
| 8 | Bão cát | Cát vàng bay nhanh, màn bụi sát đất |
| 9 | Tro lửa | Tro và tàn lửa bay ngược lên, ánh cam âm ỉ |
| 10 | Mưa tinh thể | Tinh thể xanh xoay khi rơi, điểm sáng lạnh |
| 11 | Bào tử linh quang | Bào tử xanh lơ lửng theo đường cong |
| 12 | Nhật thực | Đĩa tối với vành nhật hoa tím, bụi sao |
| 13 | Mưa tinh tú | Sao tím bay ngược lên với đuôi sáng |
| 14 | Đom đóm | Đốm vàng theo quỹ đạo mềm, quầng sáng nhịp nhàng |

Ánh sáng bầu trời nằm sau đối thủ; sương và hạt nằm trước đối thủ. Bài trên tay, HUD và tooltip được vẽ sau cùng. Sét chỉ xuất hiện xa mỗi 8 giây, không chớp trắng toàn màn hình. Mức LOW/MEDIUM/HIGH giới hạn số hạt và độ chi tiết cực quang; bật/tắt hiệu ứng điện ảnh vẫn có hiệu lực. Không tạo thêm texture, shader hoặc canvas trong mỗi frame; quầng sáng dùng lại texture của hệ ánh sáng.

Kiểm tra logic: `lua tests/weather_smoke.lua`.

Kiểm tra GPU và chụp tất cả thời tiết: `../love-11.5-win64/lovec.exe . --test-weather`. Chế độ này không tải hoặc ghi save người chơi. PNG được lưu trong thư mục này.

# Hiệu ứng tiến hóa và tăng tốc

`ui/progression_effects.lua` dùng chung cho quân bài và SPN qua renderer `src/ui.lua`, trên tay, cửa hàng, bộ bài và màn chọn tiến hóa.

- Tiến hóa: dải sáng vàng trắng quét lên, mảnh tím nhỏ và điểm sáng vàng ở tâm. Nhãn ghi đúng số cấp vừa tăng; nhiều cấp cùng lúc gộp thành một hiệu ứng.
- Tăng tốc: ánh lam trắng, hai nét tăng tốc hướng lên và nhãn số tốc thực nhận. Tăng tốc đội lan lần lượt qua các lá, tối đa 0,27 giây chờ. Không báo tăng khi chỉ số đã chạm trần.
- Không dùng vòng, cung tròn, dư ảnh hoặc khung sao chép. Chế độ giảm chuyển động giữ dấu hiệu màu và chữ, bỏ chuyển động quét.

Các hàm nâng cấp quân bài, tiến hóa SPN, tăng tốc vĩnh viễn/tạm thời và thưởng bỏ bài đều phát hiệu ứng. Thưởng timing gọi cùng các hàm này. Renderer theo dõi thay đổi tốc thực tế để nhận cả thưởng hào quang/trang bị. Màn tiến hóa giữ nhịp lật bài và đồng bộ điểm sáng vào thời điểm hợp nhất.

Trạng thái hiệu ứng nằm ngoài game/card, dùng khóa yếu, tự hết hạn và không đi vào save hoặc bản sao bài; không dùng RNG của gameplay.

Kiểm tra: `lovec.exe . --test-progression-effects`. Ảnh xem trước: `docs/progression_effects.png`.

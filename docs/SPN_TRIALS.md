# Sứ Giả Khảo Luyện — 2026-10-19

`spirit_trial_emissary`: SPN Common, giá 4 Vàng, mua vào kho rồi trang bị như bình thường.

- Chỉ hoạt động khi đã mở khóa ít nhất 3 thế bài hợp lệ, tính cả thế cơ bản và thế nâng cao.
- Mỗi trận chọn ngẫu nhiên 2 thế **khác nhau** từ các thế đã mở. Tooltip hiển thị tên và trạng thái CHƯA/XONG của từng thế.
- Đánh đủ hai thế theo bất kỳ thứ tự: tiến hóa ngẫu nhiên đúng một SPN đang trang bị lên đúng một cấp. Có thể trúng chính Sứ Giả, hoặc SPN đang bị khóa ô; không chọn SPN trong kho.
- Mỗi bản nhận một phần thưởng mỗi trận. Đánh lặp một thế không thay thế yêu cầu còn lại; tái kích hoạt quân/SPN không tạo thêm nhiệm vụ hoặc phần thưởng.
- Ghi nhận đúng thế thực sự được game tính, không tính một thế bị chứa trong thế mạnh hơn. Đòn đánh hụt vẫn là tay đã chơi. Thưởng trao khi kết thúc giải quyết tay; không tăng điểm ngược lại trong tay đó.
- Nhiệm vụ và tiến độ gắn với bản SPN vật lý trong trận: đổi ô/cất rồi trang bị lại không đổi yêu cầu. Trang bị giữa trận hoặc vừa đủ 3 thế được mở thì nhận nhiệm vụ trước tay tiếp theo. Những tay trước khi nhận nhiệm vụ không tính ngược.
- SPN bị khóa không nhận nhiệm vụ hoặc tiến độ cho tới khi được mở khóa. Mỗi bản sao vật lý và Vọng Linh Hữu Ảnh có nhiệm vụ riêng; số lần sao chép/tái kích hoạt không tăng số thưởng của một nhiệm vụ.
- Tiến hóa được giữ qua trận và lưu/tải. Nhiệm vụ đặt lại khi bắt đầu trận mới. Sứ Giả có thể được tiến hóa, nhưng giữ nguyên điều kiện hai thế và phần thưởng đúng +1 cấp theo yêu cầu.
- Xem trước, tooltip, vẽ lại giao diện không đổi RNG thật, ghi nhận tiến độ hoặc trao tiến hóa.

Mã: `src/spn_trials.lua`; hook trận trong `src/combat.lua`, trang bị trong `src/loadout.lua`, bắt đầu/kết thúc tay trong `src/card_abilities.lua`. Tooltip trong `src/card_description.lua`.

Kiểm tra: `tests/spn_trials_smoke.lua`, `--test-spn-trials-ui`, `--test-spn-trials-art` và scoring audit. Tranh: `docs/spn_trials_runtime.png`.

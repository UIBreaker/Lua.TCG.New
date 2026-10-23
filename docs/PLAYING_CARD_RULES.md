# Luật 52 quân bài — 2026-10-23

Bốn chất Cơ, Rô, Chuồn, Bích có cùng 13 rank. Khả năng riêng cũ của từng lá và thưởng vai trò J/Q/K/A đã bỏ. Tranh Continental và cách xếp thế poker giữ nguyên.

| Rank | A | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | J | Q | K |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Sát thương | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
| Tốc đánh | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 |

Tốc đánh giảm đều từ A = 13 tới K = 1. Trong dữ liệu poker, A vẫn dùng rank 14, nhưng chỉ số sát thương/tốc tính như rank 1.

Cường hóa gốc là 0. Mỗi lá bị người chơi chủ động bỏ cho các lá cùng chất còn trên tay +1 Cường hóa. Bỏ nhiều lá cộng dồn theo số lá, không theo cấp tiến hóa. Các lá đang bỏ không nhận thưởng của nhau. Phần cộng này giữ đến khi lá rời tay; lá rút mới không kế thừa. Cường hóa được cộng vào Mult của thế đánh khi lá ghi điểm, kể cả các lần tái kích hoạt.

| Chất bị bỏ | Hiệu ứng mỗi lá, cấp 1 | Cấp 10 |
|---|---|---|
| Cơ | Hồi 1% máu tối đa | Hồi 10% |
| Rô | +1 vàng | +10 vàng |
| Chuồn | Các lá còn trên tay +0,5 tốc trong lượt đánh kế tiếp | +5 tốc |
| Bích | +giáp bằng 1% máu tối đa | +giáp bằng 10% máu tối đa |

Mỗi cấp tăng một lần giá trị cấp 1. Chuồn cộng dồn từ nhiều lần bỏ và hết sau lượt đánh kế tiếp, trên cả lá được đánh lẫn lá vẫn giữ. Hồi máu dừng ở máu tối đa; không chuyển hồi dư thành giáp. Bỏ do Boss ép, tiêu hủy và chơi bài không tạo hiệu ứng chủ động bỏ bài.

Mười bậc hiện hữu từ C tới TT tương ứng cấp hiển thị 1–10 (`evolutionLevel` nội bộ 0–9). Sau TT vẫn tiến hóa không giới hạn: TT+1, TT+2… Mỗi bậc vượt TT cộng vĩnh viễn +1 sát thương, +1 tốc và +1 Cường hóa gốc. Hiệu ứng bỏ bài vẫn dừng ở cấp 10. ITM, SPN, thuốc và ấn bản tiếp tục áp dụng các bổ trợ riêng của chúng.

Save cũ chuyển chỉ số nền A/J/Q/K sang luật mới, giữ `bonusBaseChips`, trang bị và tiến hóa. TT+ giữ qua bản sao chiến đấu, khôi phục bộ bài và lưu/tải.

Kiểm tra chính: `lovec.exe . --test-continental52`. Kiểm tra tích hợp: `lovec.exe . --test-continental52-regressions`.

## Hiển thị hiệu ứng bỏ bài

Mỗi lần chủ động bỏ bài hiện một bảng kết quả trong khoảng 3 giây: hồi máu xanh lá, vàng vàng kim, giáp xanh lam, tốc xanh ngọc và Cường hóa tím. Máu báo lượng thực hồi hoặc “Máu đã đầy”. Cường hóa trong bảng là tổng của các lá nhận được; trên từng lá hiện chính xác lượng tăng riêng. Tốc ghi rõ “1 lượt”. Nhãn bám theo lá đang di chuyển và ngừng hiện khi lá rời tay. Lá rút mới không được gắn nhãn của lần bỏ trước.

Lá nhận buff nảy lên khoảng 11 px, rung nhẹ dưới 1 độ rồi dừng hẳn sau 0,82 giây; từng lá lệch nhau 0,035 giây. Tranh và khung chuyển động cùng nhau, nhãn bám theo lá; vùng chọn bài giữ ổn định. Hiệu ứng dùng ánh sáng nhẹ quanh ô chỉ số, vòng sáng dưới chân lá và nhãn vát cạnh; chế độ giảm chuyển động giữ bảng và nhãn tĩnh. Bảng luôn nằm trong một ô cố định dưới tiêu đề THẾ TRẬN ở cột trái, cùng hệ tọa độ và lớp hiển thị với giao diện chiến đấu. Từ 1 đến 5 dòng hiệu ứng giữ nguyên điểm neo và co theo vùng chứa; thứ tự hành động, mục tiêu và chiêu tiếp theo nằm phía dưới. Chọn bài sẽ trả lại phần xem trước ngay. Bảng và nhãn buff không nổi lên trên bảng xem bộ bài hoặc hộp thoại khác.

Kiểm tra: `lovec.exe . --test-discard-feedback` và `lovec.exe . --capture-discard-feedback`. Ảnh kiểm chứng: [hiệu ứng đầy đủ](discard_feedback.png), [đầy máu và giảm chuyển động](discard_feedback_reduced.png), [nhiều địch](discard_feedback_squad.png). Dữ liệu hiển thị dùng kênh phản hồi tạm thời, không lưu vào save hoặc thay đổi RNG. Bộ hồi quy vẫn còn lỗi có sẵn `soul_shop_smoke.lua:133`.

Ảnh động kiểm chứng rung buff: [discard_buff_motion.gif](discard_buff_motion.gif). Đã kiểm tra chuyển động ở 30/60/120/144 FPS, lá không nhận buff, hết chuyển động, chế độ giảm chuyển động và renderer thật.

Kiểm chứng sửa vị trí: `--test-discard-feedback` kiểm tra điểm neo cho 1–5 dòng và giới hạn viewport; `--capture-discard-feedback` kiểm tra một/nhiều địch, chọn bài, bảng xem bộ bài và resize thực tế ở 960×600, 1280×720, 1920×1080. Ảnh: [màn hình nhỏ](discard_feedback_960x600.png), [màn hình lớn](discard_feedback_1920x1080.png), [đang chọn bài](discard_feedback_selected.png).

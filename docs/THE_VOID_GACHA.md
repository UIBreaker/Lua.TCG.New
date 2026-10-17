# The Void

Hiệu ứng nhận vé dùng chung với lễ trao thưởng qua `ui/reward_effects.lua`: 1–9 / 10–24 / 25–49 / 50–74 / 75–99 vé tăng dần ánh sáng, quỹ đạo, tia sét và vé bay. Đúng 100 vé có màn jackpot riêng 2,35 giây với nhật thực tím–vàng, pháo giấy, bộ đếm lớn và âm thanh jackpot. Đồ thường, đồ hiếm, vàng và rương/gói có nhóm hiệu ứng riêng. LOW giảm số hạt; tắt hiệu ứng hoặc bỏ qua sẽ bỏ màn jackpot. Hiệu ứng không thay đổi tỷ lệ, số thưởng hay RNG trò chơi.

Thắng boss ở ải toàn hành trình 10, 20, 30, 40… có 10% cơ hội mở The Void sau lễ thưởng (`config/void_gacha.lua.entryChance`). Mỗi mốc chỉ bốc một lần; cả kết quả xuất hiện và không xuất hiện đều được lưu, tải lại không bốc lại. Nếu không xuất hiện thì tiếp tục luồng shop bình thường. Nếu xuất hiện: The Void → Chợ Linh Hồn → Shop Lớn → sự kiện trao đổi (nếu có) → ải tiếp / giấy phép tại mốc khu vực 20. Nền riêng `assets/scene/events/the_void_space.png`, PNG 1672×941: không gian vũ trụ mở, hành tinh tối có vành đai sáng, đường cong hành tinh lớn ở rìa trái, tinh vân tím/lam và sao xa; không có kiến trúc hoặc mặt đất. Không bỏ qua lễ thưởng hay luồng shop cũ. Có thể rời Void miễn phí, không cần quay. Lối vào trực tiếp trong Debug bỏ qua phép thử xác suất để kiểm tra giao diện.

Mỗi lần viếng thăm chốt một banner: SPN bất kỳ từ toàn catalog ở bậc UQ với ×5 chỉ số; trang bị tầng 3–5 hoặc di vật linh hồn với ×10; một trong 52 quân bài với ×10. Ảnh, tên, rank/chất, bậc, hệ số và tỷ lệ hiển thị; rê chuột xem năng lực đầy đủ. Banner giữ nguyên suốt lần ghé, kể cả tải lại. Dùng `voidPower` độc lập với Huyết Luyện; lưu, tháo/gắn, ghép đồ và trao đổi giữ hệ số. Chỉ số số học/điểm nền/tốc/khả năng/vai trò/ấn bản nhận hệ số; điều kiện, chi phí phụ, logic định tính và trần hệ thống vẫn giữ nguyên. SPN ×5 so với phiên bản UQ thường; trang bị/quân bài ×10 so với bản cùng loại thường.

Một lượt dùng **10 vé** hoặc 100 vàng. Mười lượt dùng **100 vé** hoặc 1.000 vàng, chọn phương thức rõ ràng; không tự trộn hai tiền. Vé là lá tiêu hao trong balo, mỗi vé đổi được **1 vàng** bằng nút đổi vé hoặc bán. The Void trừ trực tiếp vé thật từ balo trước, rồi mới đến các ô tiêu hao. Mười lượt là mười mẫu độc lập, không được tặng món hiếm. Không có bảo hiểm, không tăng tỷ lệ vì trượt nhiều, không giới hạn số trượt. Tổng banner 0,004% = trung bình 1/25.000 lượt, không phải hạn bảo đảm; không ưu đãi thì chi phí kỳ vọng khoảng 2.500.000 vàng cho một lần trúng bất kỳ banner.

Các cơ chế đặc biệt cũng nhận hệ số: Vay Khoảnh Khắc ×5 tạo bình tăng vĩnh viễn +15 Tốc; Thư Viện Mù ×5 cho 5 lá Tiến Hóa. Mười di vật linh hồn nhân lượng hồi/giới hạn hồi sinh, số đòn đóng băng, số lá kéo/trở lại tay, số tái kích hoạt, cấp tiến hóa, thời hạn khóa boss, độc và linh hồn theo hệ số. Lăng Kính ×10 còn gắn `editionPower=10` lên ấn bản của lá, đồng bộ bản gốc và các cọc; Poly cũng được tăng cường độ. Gương ×5/×10 cho 10/20 lần tái kích hoạt mỗi lá kề, vẫn dùng chung trần 128 lượt của tay. Điều kiện kích hoạt và số hốc không tăng. Tooltip phản ánh số thực tế và chỉ hiện chú thích hệ số một lần.

Tỷ lệ tuyệt đối mỗi lượt, trọng số nguyên trên 100.000:

| Nhóm | Tỷ lệ |
|---|---:|
| Banner SPN UQ ×5 | 0,002% (1/50.000) |
| Banner trang bị ×10 | 0,001% (1/100.000) |
| Banner quân bài ×10 | 0,001% (1/100.000) |
| Vàng lẻ 1–10 | 37% |
| Linh hồn 1–5 | 20% |
| Tiêu hao, thuốc, thẻ phép | 18% |
| Trang bị toàn catalog | 10% |
| 52 quân bài | 8% |
| SPN thường C–UQ | 3% |
| Rương toàn catalog | 2% |
| Đặc quyền | 0,496% |
| Mở rộng tay bài +1 | 0,5% |
| Vé The Void · 1–100 | 1% |

Khi trúng nhóm vé trong gacha, số lượng chọn đều từ 1 đến 100 (1% cho mỗi số lượng trong nhóm, tức 0,01% tuyệt đối mỗi lượt). Số lượng chốt và cộng ngay khi quay; mở hoặc bỏ qua hoạt cảnh không cộng lại. Lễ thưởng trận thường cho một vé khi trúng; boss luôn cho 1–100 vé.

Nhóm SPN thường có tỷ lệ bậc điều kiện: C 61,4%, UC 20%, R 10%, E 5%, L 2%, M 1%, T 0,5%, UQ 0,1%. Trong các nhóm đồ/lá/rương/tiêu hao/đặc quyền: chọn đều danh mục. Tiêu hao gồm toàn thẻ bán lẻ các rương, tất cả thuốc, tiêu hủy và tám hỗ trợ viễn chinh. Trang bị gồm cả cơ bản, trang bị lớn, di vật linh hồn. Đặc quyền trùng chuyển 3 vàng; rương không còn nội dung hợp lệ chuyển 1 vàng, không nâng lên quà hiếm. Rương hợp lệ được mở tại shop ngay sau Void; SPN, tiêu hao và trang bị vào balo, quân bài vào bộ, đặc quyền/tài nguyên áp dụng ngay.

Vé lễ thưởng: trận thường có 1% nhận một vé; mỗi trận thắng boss chắc chắn nhận ngẫu nhiên đều 1–100 vé (mỗi số lượng có xác suất 1%). Khoảng thưởng boss nằm ở `config/void_gacha.lua.bossTicketAmount`. Mỗi vé là một vật phẩm `void_ticket`, xếp chồng 99 trong ngăn tiêu hao; nút đổi trong balo đổi chồng đang chọn theo 1:1. Không bị bán tự động bởi nút đổi toàn bộ quà lễ thưởng và không rơi khi bỏ qua. `src/void_tickets.lua` quản lý cộng/trừ/đổi và chuyển ví cũ sang vật phẩm đúng một lần, không nhân đôi; `voidTickets` chỉ là số đếm tương thích. Số vé được chốt và cộng một lần trong giao dịch thưởng, nên mở lại hoặc tải save không nhận vé lặp và không bốc lại số lượng. Artwork riêng `assets/cards/continental/utility/void_ticket.png` dùng chung trong balo, gacha và lễ thưởng, với khung lá bài runtime. Quà mở rộng tay bài tái sử dụng artwork `hand_expansion.png` của shop thông qua `UI.getVoucherImage("v_hand_size")`.

Ưu đãi độc lập mỗi lần vào: 2% có đúng một lượt miễn phí, 5% giảm 50% giá vàng, 10% giảm 25% giá vàng, 83% giá thường. Vé không giảm giá. Lượt miễn phí có thể bù một lượt trong gói 10 (còn trả 9 lượt); dùng xong không sinh thêm lượt miễn phí. Giảm giá giữ suốt lần ghé; tải lại không gieo lại ưu đãi.

Giao dịch chốt chi phí, tạo và trao đủ quà trước khi chạy VFX. Khi đang mở kết quả, không nhận lượt quay tiếp; thoát/lưu giữa hoạt cảnh giữ kết quả và tài nguyên, đọc lại chỉ mở tiếp kết quả đã có. Có nút mở toàn bộ kết quả, không ảnh hưởng tỷ lệ hay nhận quà lần nữa.

VFX chín mức, dùng đồng hồ hoạt cảnh và hạt giải tích, không dùng RNG gameplay: hút năng lượng → tín hiệu màu → nứt lõi → sóng xung kích → lộ quà. 1,05 giây đầu mọi quà dùng cùng lõi tím/lam, số hạt và vòng, chưa lộ ảnh hay bậc; sau đó mới phát tín hiệu theo bậc. Dải tinh vân xoáy có bloom, lõi sáng nhịp thở, đốm sao, mảnh vỡ, hai sóng xung kích và sao lóe. Thường/UC/Hiếm tăng từ ánh bạc tới lục và lam; Sử Thi có vòng lục giác tím; Huyền Thoại có cánh hào quang vàng; Thần Thoại có tia lửa đỏ; Siêu Việt có hai cổng lam; UQ có sao chổi đa sắc; banner có trụ sáng, xung kích lớn, phá lõi và flash vàng trắng. Độ dài, số hạt, vòng, kích thước quà và rung tăng theo mức. LOW giảm hạt; tắt hiệu ứng điện ảnh giảm flash/rung. Nút mở toàn bộ bỏ qua hoạt cảnh mà không trao thưởng lặp.

Giao diện: ba banner có ô artwork, tên, sức mạnh và tỷ lệ riêng. Kết quả 10 lượt xếp hai hàng năm ô, tên và bậc ở cạnh tranh; rê chuột đọc mô tả đầy đủ. Túi tài nguyên và chọn thanh toán hiển thị riêng. Vàng/linh hồn dùng hai artwork Continental mới `void_gold`/`void_souls`, khung chung và số lượng do runtime hiển thị, không vẽ số vào ảnh.

Kiểm tra: `lua tests/void_gacha_smoke.lua` duyệt đủ 100.000 giá trị để chứng minh tỷ lệ, kiểm tra mốc 10–50, không bảo hiểm, mọi nhóm quà, tiền/vé/ưu đãi, ×5/×10 thực tế, lưu giữa hoạt cảnh, socket và lễ thưởng vé. `lovec.exe . --test-void-gacha` thao tác lễ boss → Void → shop → ải 11, quay 1/10 thật, bảng tỷ lệ, banner, quà x10 và chụp đủ VFX 1–9; chế độ kiểm tra không ghi save/settings người chơi.

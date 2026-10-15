# Gặp người viễn chinh bí ẩn

Sau trận thứ ba của mỗi ải chẵn (2, 4, 6…), kiểm tra một lần với tỷ lệ 30%. Cuộc gặp diễn ra sau shop, trước khi sang ải mới; sau boss vẫn đi qua Chợ Linh Hồn → Shop Lớn trước sự kiện. Nền và ánh sáng lấy đúng combat của vùng hiện tại, thêm người viễn chinh che kín mặt từ `assets/scene/events/mysterious_expeditioner.png`.

## Hai hành trang, một bàn thương lượng

Hai bên đều có kho đồ thật và số vàng hữu hạn. Kho của bạn bên trái, kho người viễn chinh bên phải; chính giữa là chân dung, lời đối thoại và phần trả giá. Khung kim loại cổ đồng bộ giao diện chiến đấu. Duyệt theo loại qua bộ lọc xổ xuống, phân trang sáu món hoặc lọc riêng các món đã chọn; có tìm kiếm tiếng Việt không dấu và lăn chuột đổi trang trong từng kho.

Chọn nhiều món từ cả hai kho, kèm vàng mỗi bên. Khay dưới mỗi kho hiển thị hình từng món đã chọn: bấm để bỏ khỏi bàn, “Xem đủ” để xem toàn bộ điều khoản. Nhấp ô vàng để nhập số, Enter áp dụng, Esc hủy; có nút tăng/giảm nhanh và tổng vàng trả/nhận ròng ngay bên dưới. SPN đang trang bị, trang bị trong balo hoặc đang khảm, quân bài có đầy đủ nâng cấp/ấn bản/trang bị, thuốc và mọi thẻ tiêu hao (kể cả giấy phép di chuyển), linh hồn, vé The Void đều có thể tham gia. Linh hồn và vé trong ví cho phép chỉnh lượng đem đổi; phần của người viễn chinh là từng gói có số lượng rõ ràng. Công nhận vùng đất và các nâng cấp đã học thuộc tiến trình vĩnh viễn, không phải vật phẩm hàng hóa trong kho.

Có thể mua hoàn toàn bằng vàng, bán nhiều món lấy vàng, đổi nhiều món lấy nhiều món hoặc dùng vật phẩm bớt phần vàng cần trả. Trang bị đi kèm quân bài nằm trong giá của quân đó; chọn quân tự bỏ lựa chọn riêng trang bị của nó và ngược lại. Luôn giữ ít nhất một quân trong bộ bài.

## Người viễn chinh suy nghĩ và trả giá

Mỗi cuộc gặp có nhu cầu riêng: phòng hộ/tiếp tế, tốc đánh, nguồn lực hoặc sức mạnh. Đồ đáp ứng nhu cầu được trả tốt hơn; đồ đã có nhiều trong kho được định giá thấp hơn. Giá còn tính bậc thực tế, tiến hóa, ấn bản, phù phép, cường hóa vĩnh viễn, hốc khảm, Huyết Luyện và sức mạnh The Void. Giá tham khảo trên ô hàng không phải giá chốt.

Người viễn chinh chủ động đề nghị mua, bán hoặc đổi tùy hành trang. Sau khi nhận đề nghị của người chơi, họ cân nhắc khoảng một giây rồi đồng ý, trả giá khác hoặc từ chối. Đề nghị khác có thể thay phần vàng hoặc xin thêm tối đa ba món hữu ích khi người chơi thiếu tiền; có lúc họ không thích đồ được đưa và chỉ muốn bán bằng vàng. Giá mở đầu còn biên thương lượng, giảm dần qua các vòng trả giá nhưng luôn giữ ngưỡng định giá của họ. Cơ chế dựa trên nhu cầu, hành trang và ngân sách đã lưu, không gọi dịch vụ AI hay gieo lại kết quả khi vẽ giao diện.

“Xem đề nghị của họ” hoặc nhấp lời đối thoại mở cửa sổ điều khoản hai cột, có hình, tên, loại, vị trí món và tổng vàng, phân trang bốn món khi có nhiều món. Nếu một bên chỉ trả vàng, cột đó hiển thị rõ thanh toán bằng vàng. Đưa đề nghị lên bàn chưa lấy tiền hay đồ; có thể sửa tiếp để trả giá. Chỉ “Chốt giao dịch” khi hai bên đồng ý mới chuyển vật phẩm. Có thể chốt nhiều giao dịch trong một cuộc gặp, đến khi hết đồ/vàng hoặc tự lên đường.

## Bảo toàn dữ liệu

Chốt kiểm tra lại đúng vật phẩm, lượng tài nguyên, giá và quyền sở hữu của đề nghị đã đồng ý. Thay đổi đồ hoặc tiền làm đề nghị mất hiệu lực. Xóa nhiều món theo chỉ số giảm dần, bảo toàn từng bản tiến hóa/ấn bản/phù phép và vốn đầu tư trang bị. Món người chơi đưa trở thành đồ thật trong kho người viễn chinh; món nhận đi vào balo, bộ bài hoặc ví tương ứng. Không thể chốt lại cùng giao dịch.

Lưu/tải giữ nguyên kho, số vàng, nhu cầu, lượt thương lượng, trạng thái đang suy nghĩ và đề nghị chưa chốt. Khi khôi phục, các callback trang bị/SPN được nối lại từ catalog; quân bài trong kho NPC cũng giữ ID riêng. Save dùng sự kiện 1-đổi-1 cũ được chuyển sang cuộc gặp mới mà không trao hay thu thêm vật phẩm.

Kiểm tra: `lua tests/barter_smoke.lua`, `lua tests/shop_markets_smoke.lua`, `lua tests/run_resume_smoke.lua` và `lovec.exe . --test-barter`. Kịch bản LÖVE không ghi save/settings, kiểm tra lựa chọn hai kho, vàng, suy nghĩ, trả giá thấp hơn, điều khoản, chốt, đổi hỗn hợp, tài nguyên, nền các vùng và thoát sang ải kế. Ảnh mang tên `docs/barter_<timestamp>_*.png`.

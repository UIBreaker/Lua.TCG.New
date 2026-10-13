# Bảng Debug

Vào **Tùy chọn → Cài đặt → Chế độ Debug: Bật → Mở bảng Debug**. Sau khi bật, dùng **F7** để mở nhanh từ bất kỳ màn nào, kể cả lúc tính Aura, địch tấn công hoặc đang kết liễu. Game tạm dừng khi bảng mở. **Esc**, **F7** hoặc **Đóng** quay lại cài đặt.

## Tiền và tài nguyên

Bấm ô vàng, nhập số mới rồi bấm **Đặt số vàng**, **Cộng số vàng** hoặc **Enter** (đặt). Ô giữ nguyên số khi nhận focus; lần gõ đầu thay số cũ. **Ctrl+A**, **Ctrl+V**, **Backspace** hỗ trợ sửa nhanh. Vàng nhận số nguyên từ 0 đến 9007199254740991; lỗi được hiển thị và không thay tài nguyên. Có nút **+100 linh hồn**, **Hồi đầy HP**, **+10 vé Void**.

## Dịch chuyển

Nhập **ải 1–999**, bấm nút **Vùng** để đổi giữa Nhân loại, bốn vương quốc và lục địa Bí ẩn, rồi chọn màn. **Áp dụng ải / Enter** chuyển tới màn chọn trận. Chọn vùng có chủ đích: số ải không tự thay vùng đang chọn; ở các vùng hữu hạn, khu vực dùng chu kỳ 20 ải.

Ô nhập nhận cả hàng số phía trên và numpad, kể cả khi Num Lock tắt. Phím số được xử lý trực tiếp; sự kiện nhập chữ đi kèm không làm lặp số. Sau khi cập nhật mã nguồn, khởi động lại game để dùng bản sửa.

29 đích đến chia thành hai trang. Đổi trang bằng mũi tên, **Page Up/Down**, **←/→** hoặc con lăn. Có đủ màn gameplay cũ, sáu shop thường, shop lớn, chợ linh hồn, hai shop máu, Đổi hàng và The Void.

Mỗi lần chuyển màn hủy lựa chọn, thao tác chờ và hiệu ứng của màn trước; giữ bộ bài, đồ sở hữu và tài nguyên. Trận đấu được khởi tạo với đúng ải, vùng và loại địch. Các shop đánh dấu trận hiện tại đã hoàn thành để nút rời shop tiến tới trận sau. Chiến thắng có giấy phép dùng/bán được; màn cũ cần bản đồ sẽ tạo bản đồ để đi tiếp. Nếu chuyển từ Thua cuộc sang màn khác, HP được hồi đầy khi đang bằng 0.

**The Void** yêu cầu ải chia hết cho 10 (10, 20, 30…). Nhập ải khác sẽ báo lỗi và giữ nguyên màn. Các màn map/rest/event/chest/boss-deity thuộc luồng bản đồ cũ, dùng để kiểm thử luồng đó.

## Bộ sưu tập

12 nhóm gồm Quân bài, Trang bị, SPN, tiêu hao, phiếu, cường hóa, con dấu, ấn bản, rương, thế đánh, quái và bộ bài. Chọn lá đích bằng hai mũi tên trước khi áp dụng hiệu ứng. Hiệu ứng đồng bộ ngay với bản sao của lá trên tay, chồng rút và chồng bỏ.

SPN/tiêu hao vào **balo**; kéo lên ô trang bị để dùng. Trang bị mở màn khảm có thể gắn hoặc bỏ qua; rương mở bằng luồng chọn thưởng thật. Quái trong bộ sưu tập khởi tạo đúng boss đã chọn. **Ván mới** trong nhóm Bộ bài thay thế ván hiện tại; tên nút và dòng hướng dẫn ghi rõ thao tác này.

Thay đổi Debug có thể được tự lưu vào ván hiện tại, như hướng dẫn ngay trong bảng. Các lệnh kiểm thử dưới đây chạy ở chế độ capture, không ghi/xóa save hoặc cài đặt người chơi.

## Kiểm thử

```powershell
love . --test-debug-tools
love . --test-debug-ui
love . --test-debug-input # Cửa sổ riêng: bấm ô ải, gõ 13, rồi Enter hoặc Áp dụng ải
love . --test-run-resume
```

Test logic kiểm tra 325 mục catalog, 108 tổ hợp vùng/ải/trận, biên số vàng, đồng bộ bài và dọn dữ liệu màn. Test giao diện bấm nút thật, kiểm tra 29 đích đến, nhận đồ, phân trang, giấy phép, thoát cửa hàng/rương/Đổi hàng/Void, chọn boss, ấn bản trên bài đang chơi và tạo ván mới. Ảnh chụp được ghi vào `docs/debug_resources.png`, `docs/debug_collection.png`, `docs/debug_teleport.png`.

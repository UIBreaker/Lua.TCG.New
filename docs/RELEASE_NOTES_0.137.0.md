# Terra Suit — beta 0.137.0 cho Android

- Làm mới kéo/thả bài: nhấc bài, nghiêng theo quán tính, bóng mềm, chuyển động trả về ô; dùng chung cho tay bài, SPN, tiêu hao, shop, balo, bộ sưu tập và rương.
- Thêm nhịp chia/thu bài theo đường cong và thứ tự, chờ bài cũ thu xong trước khi chia bổ sung. Kết thúc trận thu bài trước tổng kết; callback thưởng chỉ chạy một lần.
- Cải thiện chuyển cảnh, bài vào shop và mở rương với bung bài lệch nhịp, lật/tái tạo tranh và hạ cánh. Chặn thao tác khi bài chưa ổn định; hỗ trợ nhanh/giảm chuyển động.
- Vé The Void trở thành lá tiêu hao trong balo, xếp chồng 99; đổi/bán mỗi vé lấy 1 vàng. Chuyển ví vé cũ sang vật phẩm đúng một lần; lưu/tải và giao dịch giữ số lượng.
- The Void có 10% cơ hội xuất hiện sau boss ở mốc 10/20/30…; lưu cả kết quả không xuất hiện để không bốc lại khi tải save. Quay một lần giá 10 vé hoặc 100 vàng; mười lần giá 100 vé hoặc 1.000 vàng. Trừ vé thật từ balo trước rồi ô mang theo.
- Hoàn thiện áp dụng sức mạnh ×5/×10 cho các cơ chế di vật linh hồn, ấn bản, SPN tạo thuốc và mô tả hiệu lực. Giữ tổng 96 SPN và nội dung các bản trước.
- Giữ cảm ứng và màn hình ngang tràn viền.

Tải `LUA-TCG-0.137.0-Android.apk`, mở rồi chọn **Cập nhật**. Không gỡ bản cũ để giữ save. Android 6.0 trở lên, ARM64/ARMv7; cùng khóa ký, versionCode 13700.

Kiểm chứng: vé/Void, chuyển ví cũ, sức mạnh vật phẩm, giao dịch, chuyển động nhiều FPS/nhanh/giảm chuyển động, scoring audit 38 bộ không lỗi, 202 kiểm tra scoring và 96 SPN; hồi quy gameplay/Niệm, cảm ứng và bốn tỉ lệ màn hình. APK được đối chiếu source/shader, manifest, chữ ký và checksum.

Chưa thử cài/cập nhật trên điện thoại thật. Lỗi cài 0.136.0 đã được báo trên một máy nhưng chưa có mã lỗi Android để xác định nguyên nhân; bản này không tuyên bố đã sửa lỗi đó. Giữ game cũ nếu bản cập nhật không cài được.

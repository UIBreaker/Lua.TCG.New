# Shop Máu

Hai background riêng, PNG 1672×941 (~16:9): `assets/scene/shops/blood_small.png` là quầy Huyết Ước trong hầm đá ven biển, cân đồng đổi sinh lực, pha lê đỏ và quầy gỗ; `assets/scene/shops/blood_large.png` là đại điện Gothic vòm cao, bệ ruby Huyết Ước, quầy đá đen và cửa sổ xanh lạnh. Loader chọn ảnh riêng theo kích thước shop, cùng dùng màu giao diện đỏ trầm; quầy lớn giữ nền khi chuyển trang. Prompt và nguồn ảnh được ghi trong manifest và tài liệu Continental.

Sau khi hoàn tất một ải lẻ (1, 3, 5…), kiểm tra một lần với tỷ lệ 30%. Nếu gặp: 75% là Shop Máu nhỏ (8 món), 25% là Shop Máu lớn (16 món, hai trang). Nếu không gặp: +3 HP tối đa, không tự hồi HP. Kết quả đã kiểm tra được lưu để tải lại hoặc gọi lại luồng shop không cộng thưởng lần nữa. Ải chẵn không kiểm tra và không nhận +3 HP này.

Nếu sau boss đang có Chợ Linh Hồn, thứ tự giữ là Chợ Linh Hồn → Shop Lớn → Shop Máu đã chọn → ải tiếp. Có thể rời Shop Máu mà không mua. Shop Máu không xuất hiện từ pool sáu shop thường.

Mỗi quầy có SPN, mọi loại trang bị (kể cả di vật linh hồn), quân bài trong bộ 52, thuốc, đặc quyền, rương, thẻ tiêu hao lẻ/các thẻ hỗ trợ linh hồn và mở rộng tay bài. Tất cả hàng được tạo thành bản riêng Huyết Luyện ×5, giữ artwork và catalog thường nguyên vẹn. Giá bằng 8 lần giá vàng gốc, tối thiểu 16 HP. Bậc SPN dùng hệ số giá hiện có. Đổi hàng mất 20 HP (nhỏ) / 30 HP (lớn), tăng 10 HP mỗi lần; không dùng lượt đổi miễn phí hay vàng. Mọi giao dịch phải còn ít nhất 1 HP, không dùng giáp và không kích hoạt Thuốc Máu Vàng.

Chỉ số hiệu quả được nhân 5: điểm nền/tốc/khả năng/vai trò quân bài; hiệu ứng SPN theo bậc hiện tại; trang bị, thuốc, con dấu, phù phép, ấn bản, đặc quyền và thưởng trong rương. Ví dụ Tấm Sắt +2 → +10 Giáp, SPN Cổ Thạch +20 → +100 ST, Bình Máu 25 → 125 HP, Thuốc Rút Bài 5 → 25 lá. Thuốc chính xác/né tránh giữ xác suất 100% nhưng kéo dài 5 lượt; giảm tốc giữ 50% trong 10 hành động. Phá giáp gây 125% số giáp phá; Máu Vàng trả 5 Vàng/HP do địch gây ra.

Các điều kiện, rank/chất, chi phí phụ, số hốc chiếm dụng và hiệu ứng định tính giữ nguyên. Trần HP/giáp/tốc, tối đa 8 hốc, trần tiến hóa và xác suất vẫn áp dụng. Trang bị Huyết Luyện giữ thuộc tính khi mua, gắn/tháo, lưu/đọc lại và ghép; biên nhận HP không tính thành vốn vàng để bán lại. Mở rộng hốc/tiến hóa xem trước đúng mức +5 hoặc phần còn lại tới trần. Danh mục nền không bị sửa chỉ số.

Kiểm tra: `lua tests/blood_shop_smoke.lua`; `lovec.exe . --test-blood-shop` kiểm tra UI mua/reroll với 0 vàng, giá và xác nhận HP, hai trang, thiếu HP giữ nguyên hàng, cảnh shop và thông báo +3 HP tối đa. Chế độ chụp không ghi save/settings. Ảnh `shop_blood_small.png`, `shop_blood_large.png`, `shop_blood_large_page2.png`, `shop_blood_miss_bonus.png`.

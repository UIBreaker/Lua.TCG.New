# Cửa hàng và balo viễn chinh

Đã thay hai bảng SPN/tiêu hao sở hữu bên phải cửa hàng bằng bốn ô trang bị cơ bản và hai ô giảm giá. SPN, tiêu hao, vàng, linh hồn, bài và trang bị được quản lý trong Balo Viễn Chinh. Các ô SPN/tiêu hao trong chiến đấu tiếp tục phục vụ thao tác nhanh.

## Nguyên liệu

Tất cả chiếm một hốc; mỗi nguyên liệu chỉ có một chỉ số. HP/giáp/vàng kích hoạt khi lá được tính điểm. Tốc đánh tăng trực tiếp trên lá được gắn và mất ngay khi tháo.

| Món | Hiệu ứng | Giá gốc |
|---|---|---:|
| Băng Vải | Hồi 1 HP | 2 |
| Rễ Sinh Lực | Hồi 2 HP | 3 |
| Hộp Cao Lành | Hồi 3 HP | 4 |
| Tấm Sắt | +2 Giáp | 2 |
| Da Thuộc | +4 Giáp | 3 |
| Khoanh Xích | +6 Giáp | 4 |
| Dây Giày | +1 Tốc đánh | 3 |
| Đinh Thúc | +2 Tốc đánh | 5 |
| Lông Gió | +3 Tốc đánh | 7 |
| Túi Đồng | +1 Vàng | 5 |
| Quả Cân | +2 Vàng | 10 |
| Con Dấu Buôn | +3 Vàng | 15 |

## Công thức

Ghép cần hai nguyên liệu rời trong balo và tiền công. Có thể tháo đồ đang gắn về balo miễn phí trước khi ghép. Đồ ghép chiếm một hốc và kết hợp hai hướng; không thay thế di vật chiến thuật cũ.

| Thành phẩm | Nguyên liệu | Công | Hiệu ứng |
|---|---|---:|---|
| Áo Hộ Mệnh | Băng Vải + Tấm Sắt | 2 | Hồi 2 HP, +4 Giáp |
| Ủng Hồi Sức | Rễ Sinh Lực + Dây Giày | 2 | Hồi 3 HP, +2 Tốc |
| Giáp Hành Quân | Da Thuộc + Đinh Thúc | 3 | +6 Giáp, +3 Tốc |
| Túi Quân Y | Hộp Cao Lành + Túi Đồng | 3 | Hồi 4 HP, +1 Vàng |
| Khiên Thương Đội | Khoanh Xích + Quả Cân | 3 | +8 Giáp, +2 Vàng |
| La Bàn Giao Thương | Lông Gió + Con Dấu Buôn | 4 | +4 Tốc, +3 Vàng |

## Các quyết định chiến thuật

- Mua nguyên liệu rẻ để dùng ngay hay để dành cho một thành phẩm tiết kiệm hốc.
- Đặt hồi phục/giáp trên lá thường xuyên tính điểm; đặt tốc trên lá quan trọng để vượt tốc đối thủ.
- Mua đồ kinh tế sớm để có thời gian hoàn vốn, hoặc giữ vàng để nhận lãi và mua món khác. Không món kinh tế nào tăng thêm giới hạn lãi.
- Sáu công thức bao phủ cả sáu cặp của bốn tài nguyên: máu–giáp, máu–tốc, máu–vàng, giáp–tốc, giáp–vàng, tốc–vàng.
- Giảm giá còn khoảng 65% giá gốc, làm tròn xuống, tối thiểu 1 vàng. Mỗi lần đổi hàng có bốn nguyên liệu và hai món giảm giá khác nhau. Mua hết một ô sẽ để trống ô đó đến lần đổi hàng tiếp theo.
- Giá bán lại đồ rời là một phần ba giá gốc, làm tròn xuống; luôn không vượt giá mua giảm. Không có vòng mua–bán sinh lời.
- Trang bị mới tạo tối đa 6 vàng mỗi tay tính điểm; dùng chung hạn mức giữa nguyên liệu và thành phẩm. Không tăng vàng qua lá phụ không tính điểm. Cơ chế lặp điểm hiện có không lặp trang bị.
- Một lá không gắn hai món cùng ID và vẫn chịu giới hạn ba hốc. Gắn/tháo không cộng dồn vĩnh viễn tốc đánh.

Các mức giá và hiệu ứng là mốc cân bằng ban đầu. Kiểm tra tự động xác nhận cơ chế và giới hạn; mức sức mạnh giữa các chiến thuật vẫn cần theo dõi qua chơi thử.

## Giao diện

Balo có ngăn SPN, tiêu hao, trang bị, bộ bài và bàn ghép; trang bị/bài phân trang mười món. Nhấp SPN/tiêu hao để bán; chuột phải tiêu hao để dùng. Chọn trang bị rồi chọn “Gắn vào lá bài”, sau đó chọn lá. Trong ngăn bộ bài, chọn lá có đồ để tháo. Chuột phải lên bài, SPN hoặc trang bị mở mô tả. Có nút đổi thứ tự SPN trong balo. Escape đóng balo.

18 tranh PNG độc lập theo Continental; chữ, chỉ số và khung đều do game vẽ. Loader dùng bản runtime 512×768; ảnh nguồn 1024×1536 được giữ nguyên. Manifest và prompt nằm trong `continental_basic_equipment.json`, `asset_manifest.json` và `CONTINENTAL_ASSET_PROMPTS.md`.

## Kiểm chứng

- `lovec . --test-backpack`: 12 nguyên liệu, 6 công thức, kiểm tra ghép nguyên tử, quyền sở hữu, tốc khi gắn/tháo, hạn mức vàng, mua một lần, giảm giá, 25 lượt hàng, lưu/khôi phục và reset run.
- `lovec . --capture-shop --capture-backpack`: thao tác giao diện thực tế cho mua thường/giảm, điều hướng balo, gắn/tháo, ghép, dùng thuốc, bán SPN, phân trang, áp dụng Ấn Bản lên bài/SPN và hủy mà giữ thẻ. Bảy ảnh `backpack_*.png` trong docs.
- `lovec . --test-continental52-regressions`: toàn bộ chín bộ hồi quy, gồm 11.232 tình huống 52 lá bài, 22 boss, SPN, tiêu hao, soul shop và persistence.

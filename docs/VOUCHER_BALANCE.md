# Phiếu đặc quyền: cấp cộng dồn trong một run

Mỗi lần mua tăng một cấp, cộng thêm hiệu ứng và giữ đến hết run. Cửa hàng nhỏ/lớn và Shop Máu tiếp tục bán cả phiếu đã sở hữu; mua đủ 9 loại không làm mất ô phiếu. The Void nhận phiếu trùng cũng nâng cấp thay vì đổi thành 3 vàng.

| Phiếu | Lợi ích thêm ở mỗi cấp thường | Giá cấp 1 (Vàng) |
|---|---|---:|
| Thẻ Thành Viên | Giảm 2 vàng mỗi lần đổi hàng trả vàng | 18 |
| Sổ Tiết Kiệm | Trần lãi +5; thêm 1 lãi mỗi 20 vàng tích trữ | 24 |
| Bùa Hảo Thủ | +1 lượt đánh mỗi trận, nhận ngay khi mua | 36 |
| Lời Chào Thương Hội | +1 lần đổi hàng miễn phí ở mỗi shop vàng | 18 |
| Bản Đồ Kho Báu | Rương shop vàng giảm thêm 3 vàng | 24 |
| Lời Thề Dược Sư | Hồi 8 HP đầu mỗi trận và ngay khi mua | 24 |
| Giao Kèo Tro Vàng | +2 vàng mỗi trận thắng | 24 |
| Trái Tim Bất Diệt | +25 HP tối đa, hồi ngay 25 HP | 24 |
| Quân Cờ Dự Phòng | +1 lượt bỏ bài mỗi trận, nhận ngay khi mua | 24 |

## Giá và giới hạn

Giá gốc ở cấp `n`: `ceil(giá cơ sở × (1 + 0.6(n−1) + 0.15(n−1)²))`. Sau đó áp dụng hệ số giá shop hiện có (×3). Hiệu ứng tăng tuyến tính, giá nâng cấp tăng nhanh dần; không giới hạn cấp. Ví dụ phiếu giá cơ sở 8 có giá cấp 1/2/3/4 lần lượt 24/42/69/102 vàng. Bùa Hảo Thủ đắt hơn vì tăng cả số lượt xử lý trận và tiền thưởng lượt đánh còn dư.

- Đổi hàng và rương vẫn có giá tối thiểu 1 vàng. Giảm giá không chuyển thành vàng thừa. Các cấp giảm giá cao chỉ hữu ích với món/lần đổi còn đủ đắt.
- Giữ riêng giá đổi hàng trước giảm giá để cấp sau tiếp tục có tác dụng; không trừ lặp khi làm mới hàng. Giá đổi hàng chưa giảm vẫn tăng 2 → 4 → 7 → 11… sau các lượt trả tiền.
- Lượt đổi miễn phí không tăng giá, không bị cấp lại khi chỉ làm mới stock. Sang shop mới mới nhận lại; nâng cấp giữa shop chỉ thêm phần lượt mới. Lượt miễn phí từ nguồn khác được dùng trước.
- Shop Máu/Chợ Linh Hồn giữ loại tiền và phí đổi riêng; hai phiếu đổi hàng chỉ áp dụng shop vàng. Giảm giá rương chỉ áp dụng giá vàng.
- Lãi thêm vẫn chịu trần lãi của phe thường; phe miễn trần nhận lãi thêm mà không bị áp trần. Cấp 1 ở 20/40 vàng nhận 5/10 lãi; cấp 2 ở 40 vàng nhận 12 lãi, trần 15. Không có tiền tích trữ thì không có lãi.
- Tro Vàng trả khi thắng, không trả khi bỏ trận; bỏ thưởng bán đồ để tránh vòng mua/bán sinh lời ở cấp cao. 24 vàng hoàn vốn sau 12 trận, nhanh hơn nếu có nội tại thưởng vàng của phe.
- Dược Sư chuyển từ điều kiện tiêu hủy bài hiếm gặp sang hồi đầu trận. Không vượt HP tối đa và không cộng thêm lần nữa vào tiêu hủy bài.

## Save, Huyết Luyện và hiển thị

Lưu `{level, power}` theo từng ID phiếu: cấp là số lần mua, power là tổng đơn vị hiệu ứng. Phiếu thường thêm 1 đơn vị; Huyết Luyện thêm 5 đơn vị và vẫn chỉ tăng 1 cấp. Không ghi đè mất hiệu ứng mạnh đã có khi mua thêm phiếu thường. Save cũ dạng `true` hoặc `{bloodPower=5}` được đọc như cấp 1; các chỉ số đã mua trong save không bị cộng lại khi tải. Run mới xóa toàn bộ cấp và hiệu ứng như trước.

Tên trong shop ghi cấp sắp mua, mô tả ghi tổng hiệu lực sau nâng cấp; bộ sưu tập trong run ghi cấp và hiệu lực đang sở hữu. Giá bộ sưu tập là giá cấp 1. Tiền từ Tro Vàng có dòng riêng trong bảng thưởng; lãi ở shop, kết thúc trận và bảng thưởng dùng cùng một công thức.

Kiểm tra: `love . --test-shop-vouchers`; ảnh giao diện và mua qua nút thật: `love . --capture-vouchers`. Kiểm thử bảo đảm cơ chế và quan hệ giá/hiệu ứng; cân bằng cảm nhận cuối cùng vẫn cần theo dõi các run thực tế.

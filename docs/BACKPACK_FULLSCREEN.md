# Balo toàn màn hình

Balo sử dụng trọn vùng game 1280 × 720; hệ thống scale hiện có đưa toàn bộ bố cục lên cửa sổ. Thanh trên hiển thị vàng, linh hồn và dung lượng đang dùng. Ngăn bên trái giữ SPN, tiêu hao, trang bị, bộ bài và bàn ghép. Ngăn bên phải hiển thị khả năng, giá trị đầu tư, bán lại hoặc từng trang bị đang khảm. Hỗ trợ đủ 8 hốc hiện tại, kể cả nhiều bản sao cùng loại.

Chất liệu da có đường chỉ và đinh đồng, nền bản đồ la bàn, ô trưng bày có bóng đổ và ánh sáng theo món đang chọn. Mỗi ngăn có biểu tượng riêng và số lượng thực tế. Tên ngắn của nhân vật giữ riêng với tên khả năng; hồ sơ hiển thị từng hốc bằng dấu kim cương. Nền chất liệu được vẽ vào canvas một lần để tránh dựng lại chi tiết mỗi khung hình; bụi sáng và ánh sáng nhẹ chuyển động theo thời gian thực.

## Bàn ghép

- Lọc 5 tầng; 6 bản thiết kế mỗi trang. Nhấp chọn mở cây công thức.
- Cây gần: nguyên liệu trực tiếp → thành phẩm → các trang bị dùng thành phẩm làm nguyên liệu. Nhấn bất kỳ nút nào để đi đến công thức của nó; Trở lại giữ lịch sử chọn.
- Nguyên liệu trùng được cộng số lượng, không hiển thị thành hai ô dễ nhầm. Màu xanh chỉ đủ nguyên liệu trong balo; màu cam báo thiếu.
- Toàn bộ cây gom các phần trùng thành một nút, cộng nhu cầu qua tất cả các nhánh, vẫn giữ các đường nối. Tổng nguyên liệu gốc là lượng để làm toàn bộ từ đầu, chưa trừ thành phẩm trung gian đang có.
- Nút +/- phóng to/thu nhỏ, Vừa cây xem tổng thể. Lăn chuột cuộn dọc, Shift + lăn cuộn ngang; có nút mũi tên ngang.
- Nhấn nút trong cây để đọc ở kích thước đầy đủ và ghép đúng bước đó. Chuột phải xem chi tiết. Nút ghép sử dụng `B.canCraft`/`B.craft` hiện có: chỉ dùng món chưa gắn trong balo, đủ số lượng, đủ công ghép. Di vật linh hồn không xuất hiện trong cây.
- Giá “Từ gốc” gồm toàn bộ nguyên liệu và công ghép theo công thức; giá “Mua” là giá trang bị tiêu chuẩn, chưa áp dụng giảm giá cửa hàng.
- Thành phẩm có bệ trưng bày và la bàn xoay chậm, tranh chuyển động nhẹ cùng khung chuẩn. Đường nối có điểm sáng chạy khi nguyên liệu đủ; đường thiếu giữ mờ. Tổng nguyên liệu gốc hiển thị thành các thẻ nhỏ riêng, giữ đủ số lượng.

## Gắn và tháo

Gắn: di vật bay từ ngăn chuẩn bị lên lá bài, ánh vàng hội tụ, các góc khóa vào khung, xác nhận trên lá. Tháo: vòng xanh mở ra, di vật tách khỏi lá và bay theo cung cao về ngăn thu hồi, xác nhận tại balo. Tranh và khung chung đi cùng nhau; không tạo khung hay chữ cố định trong asset.

Thông báo ghi rõ tên món, hốc sau thay đổi và tốc đánh trước/sau nếu thay đổi. Trong ngăn Bộ bài, thanh xác nhận xuất hiện ở khu thao tác phía dưới, không che tiêu đề hoặc chỉ số trên lá. Các luồng ánh sáng cuốn quanh di vật lúc bay; ấn hình la bàn đóng lại khi gắn và mở ra khi tháo. Hiệu ứng chỉ phát khi thao tác thành công; xem bằng chuột phải không gắn đồ. Tất cả thời gian dựa trên giây, tự hết ở 30/60/144 FPS.

## Kiểm tra

`lovec.exe . --test-backpack` kiểm tra đủ 60 cây công thức, nhu cầu cộng dồn, đồ trùng, đường nâng cấp, điều hướng, giá, số lượng, ghép và lưu/khôi phục.

`lovec.exe . --test-equipment-feedback` kiểm tra gắn/tháo, từ chối gắn trùng, xem bằng chuột phải, kho/tốc đánh và kết thúc hiệu ứng ở 30/60/144 FPS.

`lovec.exe . --capture-shop --capture-backpack-fullscreen` kiểm tra nút thật, ghép thật, cây nhiều tầng, phóng to/cuộn, hiệu ứng gắn/tháo và đủ 8 nút tháo. Chế độ capture không ghi lên lượt chơi hiện có. Ảnh kiểm tra trong `docs/backpack_fullscreen_*.png`.

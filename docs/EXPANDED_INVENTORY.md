# SPN và Tiêu hao mở rộng

Trong trận, giữ nguyên hai khung và kiểu xếp chồng cũ: Cả SPN và tiêu hao đều xếp theo số ô trang bị tăng dần, ô đầu tiên nằm trên cùng và các lá tiếp theo lộ cạnh phải. Thứ tự lớp, hover và chuột phải dùng tiêu hao cùng lấy theo ô trang bị, không phụ thuộc thứ tự lưu trong balo. Toàn bộ lá đang trang bị được vẽ cùng lúc, không còn giới hạn cửa sổ 6 SPN/3 tiêu hao hoặc phân trang ở khung thu gọn. Số ở tiêu đề là số lá đang trang bị / sức chứa; dòng “Hiện … lá” là số lá thực tế đang được vẽ. Ô trống không vẽ thêm lá; khoảng trống giữa các vị trí và vị trí tiêu hao được giữ sau khi dùng một lá. Với 15 SPN và 4 tiêu hao trong 7 ô, cả 15 SPN và 4 tiêu hao đều xuất hiện trong kiểu xếp chồng cũ.

Kiểm tra xếp chồng: `lovec.exe . --test-inventory-rail` (15/16 SPN, 4 tiêu hao trong 7 ô, vẽ đủ từng lá, kích thước và vị trí khung cũ, hover từng cạnh SPN đang lộ, tiêu hao ở ô rời rạc, dùng đúng lá, bảng mở rộng và chặn hover khi tạm dừng). Ảnh: `inventory_rail_15_spn_7_consumables.png`.

Nút **MỞ RỘNG** ở đáy hai khung trong trận mở bảng các ô đang trang bị. Mỗi trang tối đa 10 ô, tách tranh và tên, đánh số vị trí, hiển thị ô trống/ô boss khóa. Chọn lá để đọc toàn bộ tác dụng và ấn bản ở cột bên phải; lăn chuột trong cột để đọc tiếp. Nút XEM CHI TIẾT hoặc chuột phải mở hồ sơ toàn màn hình. Nút SPN/TIÊU HAO đổi ngăn; mũi tên, phím trái/phải và lăn chuột trên lưới chuyển trang.

Kéo lá tới ô đích để đổi chỗ, hoặc chọn SPN → ĐỔI VỊ TRÍ → chọn ô đích (có thể sang trang khác). Dùng chung `UI.Backpack.transfer`: đổi đồ trong trận tốn một lượt đánh và địch hành động, không cho đổi ô khóa hoặc khi hết lượt. Xem bảng, chọn lá và thả ra ngoài không tốn lượt.

Chọn tiêu hao → DÙNG THẺ. Thẻ ấn bản tự chuyển sang bảng SPN để chọn chính xác mục tiêu, kể cả SPN ngoài dãy thu gọn. Áp dụng giữ nguyên luật `activateConsumable`/`Shop.applyEdition`, không tự sử dụng đồ trong kho balo. THU GỌN cho phép tiếp tục chọn quân bài trên tay. Esc hủy đổi ô, hủy chọn ấn bản hoặc đóng bảng; không mất thẻ khi hủy.

Kiểm tra: `lovec.exe . --test-expanded-inventory`. Chín SPN không chồng nhau, mô tả/inspector, dùng thuốc, áp đúng ấn bản cho SPN thứ 9, phân trang 14 ô, đổi bằng kéo/chọn, thả sai chỗ, ô khóa, hết lượt, trừ đúng một lượt và địch hành động. Chế độ này không ghi save/settings. Ảnh: `expanded_inventory_spn.png`, `expanded_inventory_consumables.png`, `expanded_inventory_edition_target.png`.

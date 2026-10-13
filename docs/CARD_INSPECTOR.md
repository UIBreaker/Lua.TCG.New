# Chi tiết lá bài toàn màn hình

Chuột phải lá trong balo, bộ bài hoặc trận đấu để mở hồ sơ phủ toàn màn hình. Ba cột: tranh/chỉ số, toàn bộ khả năng/hiệu ứng, trang bị khảm hoặc hồ sơ vật phẩm. Thông tin lấy từ `src/card_description.lua` và catalog trang bị hiện có, gồm khả năng theo cấp thực tế, cấp tiếp theo, cấp tạm, vai trò, quy tắc kích hoạt, ấn bản, con dấu, cường hóa, Phá Luật và trạng thái động. SPN giữ mô tả bậc/tiến hóa/phù phép và trạng thái trang bị.

Hai cột văn bản cuộn độc lập bằng lăn chuột, Page Up/Down, Home/End theo cột dưới con trỏ; giữ nguyên cỡ chữ, không rút gọn mô tả bằng dấu ba chấm. Tám hốc đều hiện, trang bị nhiều hốc có ghi liên kết; hốc trống được thu gọn. Đóng bằng nút, Esc hoặc chuột phải. Không hiển thị tooltip chồng lên hồ sơ và không cho thao tác vào bộ bài/cửa hàng bên dưới.

Tranh dùng renderer và khung chung hiện có. Khi renderer tạm dừng physics để xem trước, khung bám đúng tranh xem trước thay vì dùng vị trí lá phía sau.

Kiểm tra `lovec.exe . --test-card-inspector`: mở bằng chuột thật từ balo; đủ 52 khả năng; khung đúng kích thước; mô tả tám trang bị; cuộn tới cuối; SPN/phù phép, trang bị và thuốc; đóng và giữ nguyên đồ/vàng. Không ghi save/settings. Ảnh: `inspector_playing_card.png`, `inspector_all_effects.png`, `inspector_spn.png`, `inspector_equipment.png`, `inspector_potion.png`.

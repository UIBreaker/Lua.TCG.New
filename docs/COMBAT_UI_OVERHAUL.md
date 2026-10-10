# Giao diện chiến đấu

Combat sử dụng lớp vật liệu nổi khối: đồng cổ, thép tối, nền da có vân, cạnh vát bắt sáng và bóng đổ. Viền chất liệu lấy từ `assets/ui/generated/panels/spm_row_frame_v1.png`, được chia chín vùng lúc render để giữ nguyên góc và bề rộng viền ở mọi tỉ lệ. Tranh nhân vật, khung bài chung và luật chiến đấu giữ nguyên.

Các bảng chính có bề mặt nổi; các ô số và ngăn trống lõm xuống với mép trên tối, mép dưới sáng. Nút đánh/bỏ có mặt kim loại màu riêng, cạnh trên bắt sáng, bóng dưới và chuyển động lún xuống khi nhấn. Huy hiệu Aura và bệ mục tiêu tạo điểm nhấn, các tiêu đề lớn có bóng chữ và số liệu được giữ trong vùng đệm riêng.

Bề mặt được dựng một lần trên Canvas có độ phân giải gấp đôi và tái sử dụng. Khi đổi độ phân giải, `love.resize` bỏ các bề mặt cũ để dựng lại, tránh lỗi mất chất liệu sau khi LÖVE tạo lại context đồ họa. Không tạo ảnh hoặc Canvas mới mỗi frame.

- Thanh đầu: ải/trận, máu/giáp có chuyển động và dấu vết mất chỉ số, vàng/linh hồn, lượt đánh/bỏ, sổ tay, bộ bài, tùy chọn. Không còn nút tùy chọn chồng lên nhau khi tính điểm; có thể tạm dừng chuỗi đánh.
- Bảng chiến thuật: khi chọn bài, chỉ hiển thị thế đánh, tốc đánh hai bên, thứ tự hành động và chiêu tiếp theo của mục tiêu. Không tính trước tổng điểm: số sát thương/cường hóa để dấu “—”, không hiện phép nhân hay khung Aura. Khi đánh, các chỉ số và Aura xuất hiện theo chuỗi tính điểm thật. Máu chỉ hiển thị trên đầu nhân vật, theo đúng nhịp va chạm và dấu vết tụt máu của chuỗi tính điểm. Nội tại dài có thể xem đầy đủ khi rê chuột vào phần đặc điểm; đối thủ không có nội tại không hiện dòng thông báo trống.
- Đấu trường: tên và thanh máu trên nền riêng; mục tiêu có bệ sáng, dấu chọn vàng và bảng chỉ số. Độc nằm cạnh nhãn đấu trường.
- Bàn bài: nền tối xuyên cảnh, số lá/số chọn, nút đánh/bỏ có phím tắt, nút sắp xếp phụ. Bỏ tiêu đề nằm sau lá đã chọn và khung lồng quanh các nút. Hướng dẫn rê chọn/đổi chỗ chỉ hiện khi chuột ở vùng bài; trên cảm ứng vẫn giữ hướng dẫn. Giữ nguyên vị trí và kích thước tay bài để thao tác rê chọn và kéo đổi chỗ hoạt động như trước.
- Ngăn SPN/tiêu hao: tiêu đề và số lượng riêng với đường phân cách mảnh; ngăn trống chỉ có biểu tượng và một dòng trạng thái. Chồng bài có số còn/tổng và số đã bỏ, bỏ các ô số trùng lặp. Hướng dẫn mở bộ bài chỉ hiện khi rê chuột vào chồng bài.
- Tính điểm: luồng đóng góp bay vào tâm chỉ số; giữ Aura tăng dần và nhịp tiến trình, bỏ thanh nhật ký dài phía trên khay bài. Nút thao tác bị khóa được thể hiện rõ trong chuỗi đánh.

Kiểm tra bằng LÖVE:

```
lovec.exe . --capture-shop --capture-combat-ui
lovec.exe . --test-hand-drag-select
lovec.exe . --test-scoring-feel
lovec.exe . --test-enemy-attacks
```

Kiểm tra chất liệu chạy cùng capture: đo cạnh sáng/bóng đổ và ánh sáng của hốc, kiểm tra khôi phục trạng thái graphics, 30 frame không tạo thêm ảnh/Canvas; lặp lại sau khi đổi cửa sổ ở cả hai độ phân giải.

Capture combat chạy trong chế độ cô lập, không đọc/ghi save người chơi. Bao gồm trận mở đầu, đội hình ba đối thủ, tám lá trên tay, dự báo, tính điểm thật, tạm dừng/tiếp tục, boss, sổ tay/bộ bài/tùy chọn và thao tác ở 960×540 / 1920×1080. Ảnh tham khảo: `combat_ui_starter.png`, `combat_ui_squad_preview.png`, `combat_ui_scoring.png`, `combat_ui_boss.png`.

Đợt tinh gọn bỏ huy hiệu trang trí lặp trên HUD, tên mục tiêu lặp ở thanh đầu, vạch lượt đánh trùng số đếm và nhãn “nhà thám hiểm” dưới mọi đối thủ. Khay bài co theo số lá để tránh một mảng nền trống lớn ở đầu trận; vị trí lá bài và vùng thao tác không thay đổi. Sổ tay/bộ bài/tùy chọn căn về cạnh phải, mục tiêu vẫn nhận diện bằng khung bài, bệ sáng và dấu vàng. Capture kiểm tra trực tiếp thanh máu mục tiêu trong chuỗi va chạm, gồm giá trị hiện tại và vệt tụt máu.

Huy hiệu la bàn được vẽ từ cùng một tâm với vành đồng; không sử dụng sprite 38×38 bị cắt lệch. Khung bảng trái luôn giữ chiều cao 615 ở mọi trạng thái; Aura chỉ xuất hiện khi tính điểm, giữ nguyên tọa độ nhận hiệu ứng. Capture xác nhận không truyền/hiện điểm dự kiến, và Aura chỉ xuất hiện trong trạng thái tính điểm.

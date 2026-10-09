# Giao diện chiến đấu

Combat sử dụng lớp vật liệu nổi khối: đồng cổ, thép tối, nền da có vân, cạnh vát bắt sáng và bóng đổ. Viền chất liệu lấy từ `assets/ui/generated/panels/spm_row_frame_v1.png`, được chia chín vùng lúc render để giữ nguyên góc và bề rộng viền ở mọi tỉ lệ. Tranh nhân vật, khung bài chung và luật chiến đấu giữ nguyên.

Các bảng chính có bề mặt nổi; các ô số và ngăn trống lõm xuống với mép trên tối, mép dưới sáng. Nút đánh/bỏ có mặt kim loại màu riêng, cạnh trên bắt sáng, bóng dưới và chuyển động lún xuống khi nhấn. Huy hiệu Aura và bệ mục tiêu tạo điểm nhấn, các tiêu đề lớn có bóng chữ và số liệu được giữ trong vùng đệm riêng.

Bề mặt được dựng một lần trên Canvas có độ phân giải gấp đôi và tái sử dụng. Khi đổi độ phân giải, `love.resize` bỏ các bề mặt cũ để dựng lại, tránh lỗi mất chất liệu sau khi LÖVE tạo lại context đồ họa. Không tạo ảnh hoặc Canvas mới mỗi frame.

- Thanh đầu: ải/trận, máu/giáp có chuyển động và dấu vết mất chỉ số, vàng/linh hồn, lượt đánh/bỏ, sổ tay, bộ bài, tùy chọn. Không còn nút tùy chọn chồng lên nhau khi tính điểm; có thể tạm dừng chuỗi đánh.
- Bảng chiến thuật: tay bài, sát thương, cường hóa, Aura dự kiến **trước giảm trừ của mục tiêu**, tốc đánh hai bên, thứ tự hành động, máu và chiêu tiếp theo của mục tiêu. Nội tại dài có thể xem đầy đủ khi rê chuột vào phần đặc điểm.
- Đấu trường: tên và thanh máu trên nền riêng; mục tiêu có bệ sáng, dấu chọn vàng và bảng chỉ số. Độc nằm cạnh nhãn đấu trường, không che nhật ký tính điểm.
- Bàn bài: nền tối xuyên cảnh, nhãn khu vực, số lá/số chọn, nút đánh/bỏ có phím tắt, nút sắp xếp. Giữ nguyên vị trí và kích thước tay bài để thao tác rê chọn và kéo đổi chỗ hoạt động như trước.
- Ngăn SPN/tiêu hao: tiêu đề và số lượng riêng, minh họa chỉ dẫn khi trống, tranh bài nằm dưới tiêu đề. Chồng bài có bảng số lá còn lại và đã bỏ.
- Tính điểm: luồng đóng góp bay vào tâm chỉ số mới; Aura, nhịp tiến trình và nhật ký đòn đánh được đọc riêng. Nút thao tác bị khóa được thể hiện rõ trong chuỗi đánh.

Kiểm tra bằng LÖVE:

```
lovec.exe . --capture-shop --capture-combat-ui
lovec.exe . --test-hand-drag-select
lovec.exe . --test-scoring-feel
lovec.exe . --test-enemy-attacks
```

Kiểm tra chất liệu chạy cùng capture: đo cạnh sáng/bóng đổ và ánh sáng của hốc, kiểm tra khôi phục trạng thái graphics, 30 frame không tạo thêm ảnh/Canvas; lặp lại sau khi đổi cửa sổ ở cả hai độ phân giải.

Capture combat chạy trong chế độ cô lập, không đọc/ghi save người chơi. Bao gồm trận mở đầu, đội hình ba đối thủ, tám lá trên tay, dự báo, tính điểm thật, tạm dừng/tiếp tục, boss, sổ tay/bộ bài/tùy chọn và thao tác ở 960×540 / 1920×1080. Ảnh tham khảo: `combat_ui_starter.png`, `combat_ui_squad_preview.png`, `combat_ui_scoring.png`, `combat_ui_boss.png`.

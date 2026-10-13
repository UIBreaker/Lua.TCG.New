# Bốn SPN khế ước

| SPN | Khả năng gốc | Tiến hóa lần đầu |
| --- | --- | --- |
| Ấn Mệnh | Chơi đúng một quân được chỉ định: ×10 Cường hóa | ×14.5 |
| Tam Vật Hộ Mệnh | Bỏ đúng bộ ba quân chỉ định trong cùng lần: +40 Giáp | +60 Giáp |
| Vọng Âm Tiến Hóa | Tổng số kích hoạt của quân ghi điểm bằng cấp tiến hóa; cấp 8 gồm lần gốc + 7 lần lặp | Tổng bằng cấp ×2 |
| Huyết Khế Đổi Vận | Hết lượt bỏ: trả 20 HP để bỏ bài; 0.5% nâng một SPN trang bị ngẫu nhiên lên đúng UQ | 0.75%; giá vẫn 20 HP |

Hai SPN chỉ định chọn ngẫu nhiên quân bài vật lý theo ID từ bộ bài khi vào mỗi trận. Mục tiêu không đổi khi đổi ô; thiếu ba quân khác nhau thì Tam Vật không có bộ mục tiêu hợp lệ. Các quân bị tiêu hủy không được tự thay mục tiêu trong trận. SPN trang bị mới trong trận chọn mục tiêu khi trang bị; SPN trong balo không hoạt động. Mục tiêu hiện trong tooltip SPN và trên tooltip các quân liên quan, giúp phân biệt hai quân cùng rank/chất.

Ấn Mệnh yêu cầu đánh đúng một quân, không tính tay nhiều quân chứa mục tiêu. Tam Vật yêu cầu bỏ đúng ba quân trong cùng lần; bỏ do Boss cưỡng chế hoặc preview không nhận Giáp. Vọng Âm áp dụng toàn bộ lần ghi điểm, gồm trang bị và callback SPN; chỉ thêm hàng đợi một lần/tay, không tự lặp đệ quy. Cấp 0/1 vẫn có lần gốc; nhiều nguồn được cộng vào hàng đợi dùng giới hạn chung 128 lần/tay. Cấp tiến hóa quân bài là cấp vĩnh viễn, không tính cấp khả năng tạm.

Huyết Khế chỉ trả máu khi không còn lượt bỏ bình thường, yêu cầu HP >20, không dùng Giáp để trả. Nút bỏ bài ghi giá 20 HP; trả đúng một lần mỗi thao tác, không làm lượt bỏ âm, kể cả có nhiều SPN/copy. Mỗi Huyết Khế đang hoạt động gieo xác suất riêng sau lần bỏ bằng máu; SPN sao chép dùng cấp và số lần của nguồn. Chỉ chọn SPN vật lý đang trang bị dưới UQ, không chọn balo và không hạ bậc UQ+. Giữ cấp tiến hóa, điều chỉnh bậc gốc để bậc tổng đúng UQ. Nếu tất cả đã UQ trở lên thì không gieo thưởng. Tiến hóa tăng xác suất 0.5 →0.75 →1…%, tối đa 100%.

Cả bốn bán trong shop bình thường, mua vào balo rồi trang bị. PNG 1024×1536 trong `assets/cards/continental/spn/`, JPG 512×768 trong `assets/cards/continental/runtime/spn/`. Tranh tạo bằng ImageGen tích hợp; prompt và nguồn ảnh trong `docs/CONTINENTAL_ASSET_PROMPTS.md`. Chụp render: `docs/spn_pacts_runtime.png`; nút bỏ bằng máu: `docs/spn_pacts_blood.png`.

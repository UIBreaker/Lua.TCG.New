# Năm SPN bổ sung cơ bản

| SPN | Cấp gốc | Tiến hóa lần đầu |
| --- | --- | --- |
| Hồn Vũ | +5 Cường hóa mỗi tay tính điểm | +7.5 |
| Thạch Quyền | +20 Sát thương mỗi tay tính điểm | +30 |
| Lôi Chỉ | Đầu trận +20 Tốc đánh cho một quân ngẫu nhiên trên tay, tạm trong trận | +30 |
| Song Hồn Đồng Ước | Tay Đôi +10 Cường hóa, đôi cùng chất thay bằng +20 | +15 / +30 |
| Dư Ảnh Nhị Khúc | Quân rank 2 ghi điểm kích hoạt tổng 2 lần gồm lần gốc | Tổng 3 lần |

Song Hồn chỉ kích hoạt khi tay được tính là Đôi; xét đúng hai quân tạo đôi, không xét các quân không ghi điểm. Đôi cùng chất nhận mức cao hơn, không cộng thành +30 ở cấp gốc. Tính chất theo alias và lá Astral/wild như luật của game. Các tay Hai Đôi, Cù Lũ hoặc chỉ cùng chất không có Đôi không nhận thưởng này.

Lôi Chỉ kích hoạt sau khi tay mở đầu đã được chia. Không chọn lại theo lượt, không tăng vĩnh viễn, không kích hoạt khi mới trang bị giữa trận. Quân được chọn giữ tăng tốc nếu quay lại tay trong cùng trận; các bản sao quân bài và bộ bài lưu không giữ thưởng tạm. Một bản sao khả năng có thể kích hoạt theo số lần của SPN sao chép, nhưng mỗi bản chỉ nhận sự kiện đầu trận một lần. Giới hạn tốc đánh chung 999.

Dư Ảnh áp dụng các lần ghi điểm đầy đủ gồm trang bị/callback; không áp dụng quân 2 không ghi điểm. Nhiều nguồn tái kích hoạt cộng các lần bổ sung và dùng chung giới hạn 128 lượt/tay, không tự gọi lại SPN để lặp đệ quy. Lần đầu tiến hóa cho tổng 3, tiếp theo tổng 4… lần.

Cả năm bán trong shop bình thường, mua vào balo rồi trang bị; mọi lá đều tiến hóa và giữ cấp khi lưu/tải. Tranh tạo bằng ImageGen tích hợp, PNG 1024×1536 trong `assets/cards/continental/spn/`, JPG 512×768 trong `assets/cards/continental/runtime/spn/`; prompt trong `docs/CONTINENTAL_ASSET_PROMPTS.md`; ảnh render `docs/spn_foundations_runtime.png`.

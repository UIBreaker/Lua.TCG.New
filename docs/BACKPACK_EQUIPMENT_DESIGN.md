# Cửa hàng, balo và toàn bộ công thức trang bị

35/35 trang bị thường hoàn chỉnh đều ghép được từ 12 nguyên liệu cơ bản. Không có công thức hoặc nguyên liệu trang bị linh hồn. Công thức nằm trong `config/equipment_recipes.lua`; game kiểm tra thiếu công thức, chu trình, thành phẩm trùng và nguyên liệu sai ngay khi nạp.

## Nguyên liệu

Mỗi nguyên liệu chiếm một hốc, chỉ tăng một tài nguyên. Máu/giáp/vàng kích hoạt khi lá tính điểm; tốc đánh áp dụng khi gắn và mất khi tháo. Bốn ô nguyên liệu của shop luôn đại diện lần lượt máu, giáp, tốc và kinh tế.

| Nguyên liệu | Hiệu ứng | Giá vàng |
|---|---|---:|
| Băng Vải | +1 HP khi lá tính điểm. | 2 |
| Rễ Sinh Lực | +2 HP khi lá tính điểm. | 3 |
| Hộp Cao Lành | +3 HP khi lá tính điểm. | 4 |
| Tấm Sắt | +2 Giáp khi lá tính điểm. | 2 |
| Da Thuộc | +4 Giáp khi lá tính điểm. | 3 |
| Khoanh Xích | +6 Giáp khi lá tính điểm. | 4 |
| Dây Giày | +1 Tốc đánh cho lá được gắn. | 3 |
| Đinh Thúc | +2 Tốc đánh cho lá được gắn. | 5 |
| Lông Gió | +3 Tốc đánh cho lá được gắn. | 7 |
| Túi Đồng | +1 Vàng khi lá tính điểm. Các trang bị cơ bản/ghép: tối đa 6 Vàng mỗi tay. | 5 |
| Quả Cân | +2 Vàng khi lá tính điểm. Các trang bị cơ bản/ghép: tối đa 6 Vàng mỗi tay. | 10 |
| Con Dấu Buôn | +3 Vàng khi lá tính điểm. Các trang bị cơ bản/ghép: tối đa 6 Vàng mỗi tay. | 15 |

## Công thức và định giá

Tầng 1 ghép nguyên liệu trực tiếp; tầng 2 cần nhiều thành phần hơn hoặc món trung gian; tầng 3 phát triển chuỗi chuyên dụng; tầng 4 phối hợp nhiều hệ; tầng 5 cần nhiều di vật tinh luyện. Có nguyên liệu lặp: cần đủ số lượng thực tế. Chỉ đồ rời trong balo được dùng; tháo đồ đang gắn trước khi ghép.

“Tự làm” cộng giá các nguyên liệu gốc và tất cả tiền công trên cây ghép. Giá mua thành phẩm = làm tròn lên 150% chi phí tự làm. Mua ngay tiết kiệm thời gian tìm nguyên liệu nhưng đắt hơn; ghép từng tầng tiết kiệm vàng và có thể tận dụng nguyên liệu giảm giá. Món thấp bắt đầu từ 12 vàng, món cao nhất 263 vàng. Đây là mốc thiết kế ban đầu; mức cân bằng sức mạnh vẫn cần kiểm chứng bằng chơi thử.

| Thành phẩm | Tầng | Nguyên liệu | Công ghép | Tự làm | Mua ngay |
|---|---:|---|---:|---:|---:|
| Áo Hộ Mệnh | 1 | Băng Vải + Tấm Sắt | 4 | 8 | 12 |
| Ủng Hồi Sức | 1 | Rễ Sinh Lực + Dây Giày | 4 | 10 | 15 |
| Giáp Hành Quân | 2 | Áo Hộ Mệnh + Da Thuộc + Đinh Thúc | 7 | 23 | 35 |
| Túi Quân Y | 2 | Áo Hộ Mệnh + Hộp Cao Lành + Túi Đồng | 7 | 24 | 36 |
| Khiên Thương Đội | 3 | Giáp Hành Quân + Khoanh Xích + Quả Cân | 10 | 47 | 71 |
| La Bàn Giao Thương | 3 | Ủng Hồi Sức + Lông Gió + Con Dấu Buôn | 10 | 42 | 63 |
| Đá Tiên Phong | 1 | Tấm Sắt + Đinh Thúc | 4 | 11 | 17 |
| Đá Tam Kích | 1 | Tấm Sắt + Đinh Thúc + Đinh Thúc | 5 | 17 | 26 |
| Đá Thủ Thế | 1 | Tấm Sắt + Da Thuộc | 4 | 9 | 14 |
| Gương Dị Chất | 2 | Tấm Sắt + Quả Cân + Dây Giày | 6 | 21 | 32 |
| Mắt Đồng Chất | 2 | Dây Giày + Đinh Thúc + Lông Gió | 6 | 21 | 32 |
| Đồng Tiền Át | 2 | Túi Đồng + Quả Cân + Con Dấu Buôn | 6 | 36 | 54 |
| Ngọc Cấp Cứu | 2 | Rễ Sinh Lực + Hộp Cao Lành + Băng Vải | 6 | 15 | 23 |
| Nhẫn Liều Mạng | 3 | Ngọc Cấp Cứu + Khoanh Xích + Đinh Thúc | 9 | 33 | 50 |
| Bàn Tính Tân Binh | 2 | Quả Cân + Tấm Sắt + Túi Đồng | 5 | 22 | 33 |
| Nanh Song Sinh | 3 | Đá Tam Kích + Đinh Thúc + Khoanh Xích | 9 | 35 | 53 |
| La Bàn Lữ Hành | 2 | Dây Giày + Lông Gió + Túi Đồng | 6 | 21 | 32 |
| Lăng Kính Viễn Chinh | 3 | Gương Dị Chất + Lông Gió + Quả Cân | 9 | 47 | 71 |
| Cát Chậm | 2 | Đá Thủ Thế + Tấm Sắt + Dây Giày | 6 | 20 | 30 |
| Chìa Khóa Ngân Khố | 3 | Đồng Tiền Át + Quả Cân + Con Dấu Buôn | 9 | 70 | 105 |
| Ống Tên Dự Trữ | 2 | Da Thuộc + Lông Gió + Tấm Sắt | 6 | 18 | 27 |
| Đe Ba Khảm | 3 | Đá Tiên Phong + Đá Thủ Thế + Khoanh Xích | 10 | 34 | 51 |
| Vương Miện Độc Hành | 2 | Khoanh Xích + Quả Cân + Rễ Sinh Lực | 6 | 23 | 35 |
| Rễ Hóa Thạch | 3 | Áo Hộ Mệnh + Rễ Sinh Lực + Rễ Sinh Lực + Quả Cân | 9 | 33 | 50 |
| Bình Tích Sét | 3 | Mắt Đồng Chất + Khoanh Xích + Quả Cân | 10 | 45 | 68 |
| Rìu Phản Lực | 4 | Nhẫn Liều Mạng + Giáp Hành Quân + Khoanh Xích | 14 | 74 | 111 |
| Sổ Giao Kèo | 3 | Chìa Khóa Ngân Khố + Quả Cân + Túi Đồng | 10 | 95 | 143 |
| Mái Chèo Chuyển Dòng | 2 | Da Thuộc + Tấm Sắt + Dây Giày | 6 | 14 | 21 |
| Kim Đồng Hồ Canh Gác | 3 | Cát Chậm + Đinh Thúc + Đinh Thúc | 10 | 40 | 60 |
| Lọ Huyết Tế | 4 | Nhẫn Liều Mạng + Hộp Cao Lành + Hộp Cao Lành + Quả Cân | 14 | 65 | 98 |
| Dây Xích Tiếp Sức | 3 | Ống Tên Dự Trữ + Khoanh Xích + Khoanh Xích + Dây Giày | 10 | 39 | 59 |
| Khóa Giáp Ngân | 3 | Đá Thủ Thế + Quả Cân + Khoanh Xích | 10 | 33 | 50 |
| Chuông Tĩnh Lặng | 4 | Ngọc Cấp Cứu + Tấm Sắt + Quả Cân + Lông Gió | 12 | 46 | 69 |
| Quả Lắc Viễn Chinh | 2 | Đá Tiên Phong + Tấm Sắt + Dây Giày | 7 | 23 | 35 |
| Xúc Tác Hư Không | 5 | Bình Tích Sét + Chuông Tĩnh Lặng + Lăng Kính Viễn Chinh + Con Dấu Buôn | 22 | 175 | 263 |

## Cơ sở từng công thức

- **Áo Hộ Mệnh:** Lót vải hồi phục bên trong tấm giáp.
- **Ủng Hồi Sức:** Ủng buộc chắc và túi dược rễ cho người chạy đường dài.
- **Giáp Hành Quân:** Gia cố áo hộ mệnh để hành quân nhanh trong giáp.
- **Túi Quân Y:** Nâng bộ bảo hộ thành túi quân y có ngăn tiền tiếp tế.
- **Khiên Thương Đội:** Giáp hành quân kết hợp khóa xích và đối trọng thương đội.
- **La Bàn Giao Thương:** Đồ người chạy tin được chuẩn hóa cho đường giao thương.
- **Đá Tiên Phong:** Mũi thép thúc lực cho đòn tiên phong.
- **Đá Tam Kích:** Ba bộ phận chịu lực tạo nhịp tam kích.
- **Đá Thủ Thế:** Thép và lớp da giảm chấn cho thế thủ ít quân.
- **Gương Dị Chất:** Bề mặt thép cân chỉnh để nối hiệu ứng giữa hai lá kề.
- **Mắt Đồng Chất:** Ba linh kiện tốc phối hợp một luồng đồng chất.
- **Đồng Tiền Át:** Đồng tiền được cân, đóng dấu và cất giữ.
- **Ngọc Cấp Cứu:** Cô đặc bộ dược cứu thương cho lúc máu thấp.
- **Nhẫn Liều Mạng:** Khóa sức sống trong vòng kim loại để đổi máu lấy sát thương.
- **Bàn Tính Tân Binh:** Cân và hạt tiền tạo dụng cụ tính sức mạnh quân thấp.
- **Nanh Song Sinh:** Từ nhịp tam kích rèn thành cặp nanh liên kết cùng rank.
- **La Bàn Lữ Hành:** Dụng cụ lữ hành nối bước quân theo rank liền nhau.
- **Lăng Kính Viễn Chinh:** Gương đã cân chỉnh được mài thành lăng kính đa chất.
- **Cát Chậm:** Bộ thủ thế được căn theo nhịp tốc của đối thủ.
- **Chìa Khóa Ngân Khố:** Đồng tiền Át trở thành chìa khóa kho vàng tích trữ.
- **Ống Tên Dự Trữ:** Ống da và tên thép dự trữ cho quân còn giữ trên tay.
- **Đe Ba Khảm:** Đe kết hợp rèn công, thủ và khóa hốc trang bị.
- **Vương Miện Độc Hành:** Vương miện cân sức người chỉ huy độc hành.
- **Rễ Hóa Thạch:** Bảo hộ sống được nuôi bằng hai rễ, lớn theo tiến hóa.
- **Bình Tích Sét:** Luồng sét được nhốt trong ba khoang tích điện.
- **Rìu Phản Lực:** Phản đòn từ máu mất đòi hỏi cả huyết khí lẫn giáp chịu lực.
- **Sổ Giao Kèo:** Ngân khố và sổ đầu tư lưu các nấc phát triển vĩnh viễn.
- **Mái Chèo Chuyển Dòng:** Mái chèo chuyển thế kết hợp sức công và giáp.
- **Kim Đồng Hồ Canh Gác:** Cơ cấu hai nhịp canh gác chịu được hai đòn quái.
- **Lọ Huyết Tế:** Bình huyết tế cần vòng khóa, hai phần cao và khoang đo giọt.
- **Dây Xích Tiếp Sức:** Hai mắt xích chuyển lực từ vũ khí dự trữ sang quân tiếp theo.
- **Khóa Giáp Ngân:** Giáp được cân và khóa để đổi thành lực công.
- **Chuông Tĩnh Lặng:** Chuông dưỡng nhịp tĩnh lặng cần sức sống và cơ cấu cân nhịp.
- **Quả Lắc Viễn Chinh:** Quả lắc đổi công hoặc thủ theo số quân giữa hai tay.
- **Xúc Tác Hư Không:** Xúc tác hư không hội tụ năng lượng tích, nhịp ổn định và lăng kính đa chất.

## Quầy giảm giá và giá trị bán lại

Hai ô giảm giá chọn từ mọi trang bị không thuộc hệ linh hồn, gồm nguyên liệu và thành phẩm; không lặp các trang bị đang bán trong cùng lượt. Giá còn 65%, làm tròn xuống và tối thiểu 1 vàng. Mỗi ô có 8% khả năng giá bằng 0, được nhận kể cả không có vàng. Ô đã mua biến mất đến lượt đổi hàng tiếp theo; không nhận lặp bằng nhấp hai lần.

Giá gốc có đường gạch chéo, giá hôm nay hiển thị bên cạnh; món miễn phí có nhãn xanh “MIỄN PHÍ”. Kích thước nguyên liệu/giảm giá là 118×176, đúng bằng SPN tuyển chọn.

Đồ mới lưu giá thực trả. Thành phẩm ghép lưu tổng đầu tư thực của nguyên liệu bị dùng và công ghép. Bán lại = làm tròn xuống một phần ba tổng đầu tư; đồ miễn phí không tự sinh giá trị bán lại khi gắn/tháo hoặc lưu/khôi phục. Đồ trong save cũ vẫn đọc được; giá trị cũ dùng làm nền đầu tư, không hưởng mức tăng giá mới. Quy đổi trang bị cũ sang linh hồn giữ mốc trước đợt tăng giá vàng này.

## Balo và bố cục shop

Shop trải ngang toàn màn hình: hàng tuyển chọn/nguyên liệu ở trên; đặc quyền/kho rương/giảm giá ở dưới. Nút Balo nằm giữa thanh thao tác đáy màn hình.

Balo có viền da khâu chỉ, khóa đồng, túi vàng và năm ngăn: SPN, tiêu hao, trang bị, bộ bài, bàn ghép. Ngăn đồ có 8 món/trang và bảng xem tranh/tên/khả năng/đầu tư. Bàn ghép có 5 công thức/trang, lọc tầng 1–5, số sở hữu/số cần cho từng nguyên liệu, phí công, tổng chi phí tự làm và giá mua. Công thức thiếu đồ hoặc tiền bị khóa. Chuột phải công thức mở mô tả đầy đủ thành phẩm.

- Nhấp SPN/tiêu hao để bán; chuột phải tiêu hao để dùng.
- Chọn trang bị → Gắn vào lá bài → chọn lá. Chọn lá có đồ trong Bộ bài để tháo.
- Chuột phải bài, SPN hoặc trang bị để xem đầy đủ. Đổi thứ tự SPN bằng nút điều hướng.
- Escape đóng balo; hủy chọn mục tiêu Ấn Bản giữ lại thẻ tiêu hao.

Trang bị cơ bản/ghép vẫn dùng chung giới hạn 6 vàng/tay tính điểm; không lặp hiệu ứng qua tái kích hoạt, không trả vàng trên lá không tính điểm. Ba hốc mỗi lá và quy tắc không gắn hai món cùng ID vẫn áp dụng.

18 tranh thiết bị đã có được giữ theo Continental, dùng khung/chữ/chỉ số vẽ bằng game. Thay đổi lần này tập trung công thức, giá và bố cục giao diện.

## Kiểm chứng

- `lovec . --test-backpack`: 12 nguyên liệu, toàn bộ 35 cây ghép, định giá, đủ số lượng/công phí, ghép nguyên tử, mua miễn phí, giá bán qua lưu/gắn/tháo, giới hạn vàng và kích thước quầy.
- `lovec . --capture-shop --capture-backpack`: thao tác mua thường/miễn phí, gắn/tháo, ghép, lọc tầng/phân trang công thức, dùng thuốc, bán SPN, phân trang đồ, Ấn Bản bài/SPN, hủy an toàn và tám ảnh `backpack_*.png`.
- `lovec . --test-continental52-regressions`: toàn bộ bộ hồi quy bài/boss/SPN/tiêu hao/shop linh hồn/persistence đều qua, gồm 11.232 tình huống 52 lá.

Danh mục máy đọc được: `equipment_recipe_catalog.tsv` (35 thành phẩm), `basic_equipment_catalog.tsv` (18 nguyên liệu/trang bị kết hợp).

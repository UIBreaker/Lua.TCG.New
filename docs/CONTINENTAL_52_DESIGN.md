# Continental 52 — thiết kế khả năng và nhân vật

Ngày 2026-10-07. Bộ 52 dùng bốn trục tài nguyên: Máu, Giáp, Tốc đánh, Vàng. Tranh được tạo riêng từng lá bằng built-in image_gen; PNG gốc 2:3, không chứa UI.

## Quy tắc chiến thuật

Khả năng chạy trước so tốc đánh; mỗi instance một lần/tay, chỉ lá tính điểm. Tái kích hoạt điểm không tái tạo tài nguyên. Điều kiện Máu/Giáp/Vàng dùng ảnh chụp đầu tay, chi phí dùng số dư thực tế theo thứ tự tính điểm. Thiếu chi phí thì dùng nhánh an toàn ghi trên lá.

Cơ chuyển hồi dư thành Giáp; Bích tích và đổi Giáp; Chuồn giành nhịp trước quái; Rô kiếm tiền hoặc chi cho hồi phục, Giáp, Tốc. Khả năng bị khóa và lá kiệt sức không kích hoạt. Các khả năng phe cũ và Át đổi chất được thay thế để không cộng chồng ngoài ngân sách.

Giới hạn chung từ bộ 52: 12 hồi Máu, 24 Giáp, +3 Tốc mỗi tay; 3 Vàng mỗi tay và 12 Vàng mỗi trận. Tiền không bị nhân theo số lượt lặp. Đây là giới hạn chống farm, không phải tuyên bố mọi deck có tỉ lệ thắng bằng nhau.

Tốc nền: 2–10 = 14 − rank; J/Q/K = 3; A = 7. Lá thấp nhanh, lá lớn/hoàng gia sát thương cao. Tốc tay là trung bình mọi lá chơi + thưởng khả năng, bao gồm lá chơi không tính điểm trong mẫu trung bình. UI dự báo dùng cùng phép tính với thực thi.

Vàng hoặc Tốc vượt giới hạn tạo 2 Giáp mỗi đơn vị; vẫn chịu trần 24 Giáp/tay. Lá kinh tế và tốc không mất hết giá trị khi đạt trần. Chi phí Máu được trừ trước hồi phục; không hồi sinh người chơi đã chết.

## Các hướng phối hợp

- Đôi cơ động: 2 Cơ + 2 Chuồn; hồi phục đi cùng quyền đánh trước.
- Băng và tiếp tế: 8 Bích + 8 Rô; Giáp đầu tay mở bảo lãnh kinh tế, chuyển Giáp sang tốc để giành nhịp.
- Viễn chinh đa chất: các lá 4 tăng giá trị khi đủ 3 chất tính điểm; cần thế poker cho phép ít nhất 3 lá cùng tính điểm.
- Hậu tuyến: giữ Q để tích; các lá 9 thưởng khi còn quân dự phòng. Giữ Q đồng nghĩa chưa dùng sát thương của Q.
- Huyết tốc: 7 Cơ đánh đổi Máu khi đủ quỹ và còn khỏe; 7 Chuồn/7 Bích cứu thế trận khi bị thương.
- Tài chính chủ động: 9 Rô cứu thương, 10 Rô mua tốc, K Rô mua thành lũy; tiền dùng chiến đấu sẽ giảm ngân sách mua đồ.
- K đơn hành: K Chuồn/K Bích mạnh với một lá tính điểm; ít quân cộng dồn sát thương, đổi lại tự chủ phòng thủ/tốc.

## Kiểm chứng

`lovec . --test-continental52`: 11.232 tình huống với 52 danh tính, Máu/Vàng/Giáp, cấp 0/8, nhóm 1/2/5 lá. Kiểm tra preview thuần, chi phí, giới hạn, không farm khi lặp, tích/xả và thay đổi thứ tự đòn. Cần playtest các run đầy đủ để tiếp tục cân theo tỉ lệ thắng và nhịp kinh tế; bài test cơ chế không chứng minh cân bằng tuyệt đối.

## Danh mục 52 nhân vật

| Lá | Nhân vật | Khả năng cấp 0 | Khát vọng |
|---|---|---|---|
| hearts_2 | Maera · Y Sĩ Tro Hồng | Hồi 2 Máu; đúng 2 lá tính điểm: hồi thêm 4 Máu. Hồi dư chuyển thành Giáp. | Cứu mọi người bị bỏ lại ở biên giới dung nham. |
| hearts_3 | Corvin · Người Giữ Nhịp Tim | Hồi 2 Máu; mỗi lượt đánh thứ 3: hồi thêm 6 Máu. | Tìm cách chữa trái tim hóa đá của em trai. |
| hearts_4 | Yselle · Sứ Giả Bốn Bờ | Hồi 2 Máu; có ít nhất 3 chất tính điểm: hồi thêm 5 Máu. | Hợp nhất những đoàn viễn chinh từng là kẻ thù. |
| hearts_5 | Bram · Người Cõng Bình Minh | Hồi 2 Máu; đứng cuối thứ tự tính điểm: hồi thêm 3 Máu và 4 Giáp. | Đưa đoàn tị nạn vượt vùng tro trước bình minh. |
| hearts_6 | Edda · Bếp Lửa Viễn Chinh | Hồi 2 Máu; mỗi lá Cơ còn giữ: hồi thêm 2 Máu, tối đa 4. | Nấu bữa tối cuối cùng ở mọi trại bị chiến tranh bỏ quên. |
| hearts_7 | Lucan · Kẻ Trả Nợ Máu | Hồi 2 Máu; đầu tay từ 50% Máu và 7 Vàng: trả 3 Máu để +1.5 Tốc đánh tay và 4 Giáp. | Chuộc lại đoàn lính từng bị mình bán đứng. |
| hearts_8 | Vesta · Người Vá Khiên | Hồi 2 Máu; đã có Giáp trước tay: thêm 3 Máu; chưa có: +6 Giáp. | Tái tạo bộ giáp bảo vệ quê nhà khỏi núi lửa. |
| hearts_9 | Neris · Người Canh Lều | Hồi 2 Máu; còn ít nhất 1 lá không chơi: hồi thêm 3 Máu. | Dựng nơi trú ẩn mà không người lữ hành nào bị từ chối. |
| hearts_10 | Aveline · Người Không Gục | Đầu tay dưới 75% Máu: hồi 6 Máu; từ 75%: trả 4 Máu, nhận 8 Giáp và +0.5 Tốc đánh tay. | Giữ lời hứa sống sót để bảo vệ con gái. |
| hearts_J | Ronan · Cận Vệ Đỏ | Hồi 2 Máu; ngay trước là lá 2–10: hồi thêm 4 Máu. | Trở thành người bảo hộ mà người thầy đã không kịp trở thành. |
| hearts_Q | Seraphine · Người Gom Tàn Lửa | Hồi 2 Máu; mỗi tay giữ không chơi tích 1 Tàn Lửa (tối đa 3), khi chơi mỗi tầng hồi thêm 2 Máu. | Khôi phục khu vườn đầu tiên trên đất cháy. |
| hearts_K | Garrick · Vua Không Ngai | Hồi 2 Máu, +2 Giáp; bắt đầu tay dưới 35% Máu: hồi thêm 6 Máu và +4 Giáp. | Giành lại vương quốc bằng cách cứu dân trước khi lấy ngai. |
| hearts_A | Althea · Người Mở Bình Minh | Hồi 2 Máu; tay đầu trận: hồi thêm 3 Máu và +1 Tốc đánh tay. | Chứng minh ánh sáng vẫn tồn tại phía sau nhật thực. |
| diamonds_2 | Orrin · Người Đổi Muối | Nhận 1 Vàng; đúng 2 lá tính điểm: thêm 1 Vàng. | Mở tuyến trao đổi công bằng giữa sa mạc và biển. |
| diamonds_3 | Tamsin · Người Đòi Công | Nhận 1 Vàng; mỗi lượt đánh thứ 3: thêm 2 Vàng. | Thu hồi tiền công bị cướp của thợ khai quật. |
| diamonds_4 | Nasira · Người Nối Bốn Chợ | Nhận 1 Vàng; ít nhất 3 chất tính điểm: thêm 1 Vàng và 4 Giáp. | Kết nối bốn thương cảng mà không phục tùng đế chế. |
| diamonds_5 | Perrin · Chủ Đoàn Lữ Hành | Nhận 1 Vàng; 5 lá tính điểm: thêm 1 Vàng và +1 Tốc đánh tay. | Dẫn đoàn hàng đầu tiên đến tận rìa lục địa. |
| diamonds_6 | Mirel · Người Nhặt Cơ Hội | Nhận 1 Vàng; đã bỏ bài từ tay trước: thêm 1 Vàng. | Biến những thứ bị bỏ đi thành cơ nghiệp của riêng mình. |
| diamonds_7 | Hadrien · Người Đếm Hoàng Hôn | Nhận 1 Vàng; mỗi 10 Vàng đầu tay thêm 1 Vàng, tối đa 2 thêm. | Tích đủ tiền mua tự do cho thị trấn mắc nợ. |
| diamonds_8 | Sabria · Người Bảo Chứng | Nhận 1 Vàng; bắt đầu tay có ít nhất 8 Giáp: thêm 1 Vàng; chưa đủ: +2 Giáp. | Xây ngân khố không thể cướp để bảo vệ lương của đoàn. |
| diamonds_9 | Elio · Người Bán Thuốc | Dưới 50% Máu và đủ 2 Vàng: trả 2 Vàng để hồi 8 Máu; trường hợp khác nhận 1 Vàng. | Đem thuốc tới những người mà thương hội không chịu cứu. |
| diamonds_10 | Rhea · Người Thuê Gió | Đủ 2 Vàng: trả 2 Vàng để +2 Tốc đánh tay; thiếu tiền: nhận 1 Vàng. | Thuê được đoàn trinh sát đưa mình tới thành phố thất lạc. |
| diamonds_J | Dorian · Người Giữ Hợp Đồng | Nhận 1 Vàng; ngay trước khác chất: +6 Giáp. | Viết bản hiệp ước mà cả người giàu lẫn nghèo đều giữ lời. |
| diamonds_Q | Isolde · Người Gom Hạt Vàng | Nhận 1 Vàng; mỗi tay giữ không chơi tích 1 Hạt Vàng (tối đa 2), khi chơi nhận thêm mỗi tầng 1 Vàng. | Mua lại ốc đảo bị chính gia đình bán cho bạo chúa. |
| diamonds_K | Balthazar · Vua Của Đường Xa | Có ít nhất 15 Vàng đầu tay và đủ 3 Vàng: trả 3 Vàng nhận 12 Giáp; trường hợp khác nhận 2 Vàng. | Dùng tài sản xây con đường an toàn thay vì cung điện. |
| diamonds_A | Zara · Người Bắt Đầu Từ Không | Nhận 1 Vàng; đầu tay dưới 5 Vàng: thêm 1 Vàng và 3 Giáp; từ 5 Vàng: +0.5 Tốc đánh tay. | Chứng minh một đứa trẻ đường phố cũng có thể dựng thương hội. |
| clubs_2 | Finn · Người Chạy Song Song | +0.5 Tốc đánh tay; đúng 2 lá tính điểm: thêm 1.5. | Chạy nhanh đủ để không mất người bạn đồng hành lần nữa. |
| clubs_3 | Sylva · Người Đếm Sấm | +0.5 Tốc đánh tay; mỗi lượt đánh thứ 3: thêm 2. | Tìm nơi tiếng sấm đã đánh thức khu rừng. |
| clubs_4 | Kellan · Người Dẫn Bốn Lối | +0.5 Tốc đánh tay; ít nhất 3 chất tính điểm: thêm 1.5. | Vẽ đường thoát hiểm từ mọi ngả rừng. |
| clubs_5 | Ivara · Đội Trưởng Lá Rơi | +0.5 Tốc đánh tay; 5 lá tính điểm: thêm 1.5 và 3 Giáp. | Đưa cả đội tới đích mà không bỏ người chậm nhất. |
| clubs_6 | Tobin · Người Cắt Lối | +0.5 Tốc đánh tay; đã bỏ bài từ tay trước: thêm 1.5. | Phá vòng lặp của cánh rừng nuốt người. |
| clubs_7 | Liora · Người Chạy Qua Đau | +0.5 Tốc đánh tay; đầu tay dưới 50% Máu: thêm 1.5 và hồi 2 Máu. | Mang lời cầu cứu về trước khi vết thương khuất phục mình. |
| clubs_8 | Aeric · Người Lướt Khiên | +0.5 Tốc đánh tay; đầu tay có ít nhất 8 Giáp: thêm 1.5. | Tạo cách di chuyển giúp lính giáp nặng vượt rừng. |
| clubs_9 | Moss · Người Canh Nhịp | +0.5 Tốc đánh tay; còn lá không chơi: thêm 1. | Nghe được nhịp sống của cây cổ nhất lục địa. |
| clubs_10 | Kael · Người Vượt Dốc | +0.5 Tốc đánh tay; ngay trước có rank nhỏ hơn: thêm 1.5. | Đặt chân lên đỉnh cây che cả bầu trời. |
| clubs_J | Thalia · Người Mở Lối | +0.5 Tốc đánh tay; đứng đầu thứ tự tính điểm: thêm 1.5. | Mở đường để đoàn không phải trả giá bằng mạng người. |
| clubs_Q | Elowen · Người Ủ Gió | +0.5 Tốc đánh tay; mỗi tay giữ không chơi tích 1 Gió (tối đa 3), khi chơi mỗi tầng thêm 0.5. | Tìm lại giọng hát của khu rừng đã im lặng. |
| clubs_K | Rowan · Vua Những Bước Chân | +0.5 Tốc đánh tay; chỉ 1 lá tính điểm: thêm 1.5 và 4 Giáp. | Kết thúc chiến tranh bằng một bước đi quyết định. |
| clubs_A | Zephyr · Người Đuổi Chân Trời | +0.5 Tốc đánh tay; tay đầu trận: thêm 1.5 và nhận 1 Vàng. | Nhìn thấy nơi tận cùng của tất cả những dòng sông. |
| spades_2 | Torren · Người Giữ Cửa | +4 Giáp; đúng 2 lá tính điểm: thêm 4 Giáp. | Giữ cánh cổng băng đến khi người cuối cùng vượt qua. |
| spades_3 | Freya · Người Đếm Tuyết | +4 Giáp; mỗi lượt đánh thứ 3: thêm 6 Giáp. | Ghi lại tên mọi người mất tích trong bão tuyết. |
| spades_4 | Soren · Người Xây Bốn Trụ | +4 Giáp; ít nhất 3 chất tính điểm: thêm 5 Giáp. | Xây pháo đài nơi bốn dân tộc cùng được bảo vệ. |
| spades_5 | Hilda · Người Gánh Tường Thành | +4 Giáp; 5 lá tính điểm: thêm 6 Giáp. | Mang một phần thành lũy tới những nơi không có thành. |
| spades_6 | Borek · Thợ Rèn Băng | +4 Giáp; đã bỏ bài từ tay trước: thêm 4 Giáp. | Rèn từ phế tích một tấm khiên không bao giờ bỏ chủ. |
| spades_7 | Astrid · Người Che Vết Thương | +4 Giáp; đầu tay dưới 50% Máu: thêm 6 Giáp. | Bảo vệ người em từng mất một tay vì mình. |
| spades_8 | Osric · Người Rút Đinh | Đầu tay từ 8 Giáp và đủ 4 Giáp: đổi 4 Giáp lấy +1.5 Tốc đánh tay, rồi +4 Giáp; chưa đủ: +8 Giáp. | Chứng minh phòng thủ cũng có thể chủ động ra đòn. |
| spades_9 | Eira · Người Giữ Hậu Phương | +4 Giáp; còn lá không chơi: thêm 4 Giáp. | Giữ ánh đèn của trại luôn cháy trong đêm cực dài. |
| spades_10 | Magnus · Người Vá Xương Sống | Đầu tay từ 12 Giáp và đủ 6 Giáp: đổi 6 Giáp hồi 6 Máu, rồi +4 Giáp; chưa đủ: +6 Giáp. | Chữa lời nguyền khiến cơ thể đồng đội hóa thành sắt. |
| spades_J | Cedric · Người Chốt Đoàn | +4 Giáp; đứng cuối thứ tự tính điểm: thêm 5 Giáp. | Không bao giờ để kẻ truy đuổi chạm vào đoàn mình. |
| spades_Q | Morrigan · Người Ủ Pha Lê | +4 Giáp; mỗi tay giữ không chơi tích 1 Băng (tối đa 3), khi chơi mỗi tầng thêm 2 Giáp. | Tái tạo hồ băng giữ ký ức của mẹ. |
| spades_K | Ulric · Vua Của Người Ở Lại | +4 Giáp; chỉ 1 lá tính điểm: thêm 6 Giáp và hồi 2 Máu. | Bảo vệ một vương quốc nhỏ còn đúng một ngôi làng. |
| spades_A | Vaela · Người Dựng Trại Đầu | +4 Giáp; tay đầu trận: thêm 4 Giáp và +0.5 Tốc đánh tay. | Dựng trại đầu tiên ở bên kia dãy núi không ai vượt qua. |

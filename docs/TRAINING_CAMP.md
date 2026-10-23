# Trạm Nghỉ Huấn Luyện

Giao diện: hai lựa chọn có ảnh khu trại, xem trước sinh lực sau nghỉ, danh sách 3 thành viên đã chọn luôn hiện khi đổi trang. Nhấn cả ô quân bài để chọn/bỏ chọn; giữ Shift khi rê trên lá để xem chi tiết. Kết quả trình bày riêng từng lá và chỉ số tăng, hoặc lượng hồi phục cùng giới hạn máu mới.

- Thử xuất hiện một lần với xác suất 25% sau khi thắng boss của mỗi ải lẻ, ngoài Lãnh Địa Máu. Rời shop thì đến trạm nếu đã xuất hiện; các sự kiện khác đang chờ vẫn tiếp tục sau trạm, rồi mới tăng ải.
- Chọn đúng một nhánh, không mất vàng. Lựa chọn và kết quả được lưu ngay, không thể đổi nhánh hay quay lại lấy thêm thưởng.
- **Nghỉ ngơi:** tăng vĩnh viễn 10 máu tối đa trước; sau đó hồi 65% máu tối đa mới, làm tròn lên và giới hạn ở máu tối đa. Ví dụ 20/100 → 92/110.
- **Huấn luyện:** chọn 1–3 quân bài khác nhau trong bộ bài, có phân trang và bỏ chọn trước xác nhận. Mỗi lá nhận vĩnh viễn +5 sát thương, +5 tốc đánh hoặc +5 cường hóa, cơ hội bằng nhau. Từng lá tung riêng khi xác nhận nhóm; lá đã sát trần tốc đánh 999 chỉ nhận một trong hai chỉ số còn lại. Các bản thể cùng ID trong tay/nọc/bài bỏ được đồng bộ; bản sao ID khác là lá riêng.
- Không tự động chơi bài, tiêu thụ lượt hoặc thay đổi ô trang bị. Sau kết quả, rời trạm để tiếp tục hành trình.

Nền riêng: `assets/scene/events/training_camp.png`. Prompt và nguồn built-in image_gen: `docs/TRAINING_CAMP_ASSET.json`.

Kiểm tra: `lua tests/training_camp_smoke.lua`; `lovec.exe . --test-training-camp` (chụp lựa chọn, chọn bài, kết quả huấn luyện và nghỉ ngơi).

# Boss tự do hình người

Các boss tham gia nhóm boss tự do dùng chung cho mọi vùng chính. Mỗi boss có trọng số 1/16 lượt chọn (6,25%); bốn thực thể cũ vẫn giữ tổng 25%. Boss Vương Huyết của nhánh sự kiện giữ nguyên.

## Quan Chấp Cấm Thế

Thế bài đã mở khóa chỉ được dùng một lần trong trận. Khóa áp dụng sau khi hoàn tất tay đánh, không hủy đòn đánh đầu tiên. Chọn lại một thế đã khóa sẽ bị từ chối trước khi dùng lượt hoặc mở lựa chọn kỹ năng; dự báo sát thương bằng 0. Những thế chưa mở khóa không được tính vào điều kiện thua.

Kỹ năng **Phán Quyết Cuối** kiểm tra cuối lượt: nếu Boss còn sống và không còn thế đã mở khóa nào chưa bị khóa, người chơi thua ngay. Hạ Boss bằng thế cuối cùng vẫn thắng. Có thể phong ấn nội tại hoặc kỹ năng bằng cơ chế phản chế hiện có. Khóa thế được làm mới khi bắt đầu trận khác.

## Kẻ Gạch Tên

Lưu ID tất cả lá đã đánh trong ải, kể cả trận thường/tinh anh trước khi gặp Boss; bỏ bài không tính. Các lá đã ghi nhận bị vô hiệu điểm riêng, khả năng, trang bị và ấn khi gặp Boss này. Một lá được đánh lần đầu vẫn hoàn tất hiệu ứng trước khi được ghi nhận. Bản sao ID khác vẫn được đánh bình thường. Chuyển ải hoặc vùng sẽ làm mới lịch sử; lưu/tải giữ lại lịch sử của ải.

Kỹ năng **Tước Tiến Hóa** mỗi lượt chọn ngẫu nhiên một lá bị khóa còn tồn tại trong các chồng bài, kể cả bộ bài gốc, giảm vĩnh viễn 1 cấp tiến hóa và đồng bộ các bản cùng ID. Không giảm rank; cấp tiến hóa thấp nhất là 0. Nếu lá được chọn đã ở cấp 0 thì không giảm thêm.

Tranh mới tạo bằng built-in image_gen: đường dẫn PNG và toàn bộ prompt nằm trong [FREE_HUMAN_BOSS_ASSETS.json](FREE_HUMAN_BOSS_ASSETS.json). Game dùng khung chung và ký hiệu K vô chất.

Kiểm tra: `lua tests/free_human_bosses_smoke.lua`; giao diện: `lovec.exe . --test-free-human-bosses`.

## Kẻ Thách Tử

Boss tự do thứ ba: sát thương cơ bản ×5, hấp thụ đòn oneshot từ đầy máu để tái lập HP và nhân 3 sát thương mỗi lần; mỗi lượt cho người chơi +20% sát thương cộng dồn trong trận. Chi tiết và kiểm tra: [DEATH_CHALLENGER.md](DEATH_CHALLENGER.md).

## Giám Quan Tước Phẩm

Chọn một bậc C–TT để vô hiệu hóa SPN thuộc bậc đó trong trận; mỗi lượt hạ 2 bậc một SPN ngẫu nhiên đang trên C trong trang bị hoặc balo. Chi tiết và kiểm tra: [RARITY_INQUISITOR.md](RARITY_INQUISITOR.md).

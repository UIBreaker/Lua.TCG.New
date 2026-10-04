# Phong cách card art đã được người dùng chốt

Khi người dùng yêu cầu tạo thêm hoặc thiết kế lại lá bài trong project này, mặc định tiếp tục phong cách của bộ `assets/cards/continental/`. Không cần hỏi lại phong cách, trừ khi người dùng yêu cầu thay đổi.

Trước khi tạo ảnh, đọc `docs/CONTINENTAL_ART_BIBLE.md`, xem `docs/continental_reference.png` và một vài PNG hiện có cùng loại. Dùng `docs/CONTINENTAL_ASSET_PROMPTS.md` và `docs/asset_manifest.json` làm tham khảo cho prompt và concept đã chốt.

- Fantasy phương Tây, điện ảnh, cuộc viễn chinh trên lục địa bí ẩn; tranh có cảm giác cùng một thế giới với bộ hiện tại.
- Một chủ thể chính, hình dáng rõ, chi tiết vừa phải, ánh sáng và glow có kiểm soát; dễ đọc khi thu nhỏ.
- Concept phải thể hiện đúng tên và khả năng thực tế của lá bài. SPN là hiện tượng/thực thể dị giới; ITM là di vật hữu hình. Không chỉ đổi màu một ảnh để tạo lá khác.
- PNG dọc 2:3, tranh tràn viền. Không vẽ chữ, bậc, chất, huy hiệu hay khung cố định vào tranh; game tự hiển thị các phần đó.
- Dùng duy nhất khung cơ bản chung của `ui/components/card_frame.lua`, ôm sát tranh và cùng chuyển động/tan biến với lá bài. Khung được trang trí đẹp dần theo cấp tiến hóa; cờ đuôi én ở góc trên bên phải.
- Giữ màu theo vùng: biển xanh sâu, băng xanh lạnh, rừng xanh, sa mạc vàng xương, dung nham cam, hư không tím, kim loại vàng cổ. Tránh họa tiết/cung điện/thư pháp fantasy Đông Á và trang trí li ti dày đặc.
- Đặt ảnh mới trong thư mục loại tương ứng dưới `assets/cards/continental/`, nối vào loader hiện có và bổ sung manifest/prompt. Không tạo lại toàn bộ bộ ảnh khi chỉ được yêu cầu thêm một vài lá.

Quy chuẩn này là sở thích lâu dài do người dùng yêu cầu lưu ngày 2026-10-04. Yêu cầu mới của người dùng luôn được ưu tiên nếu họ muốn thay đổi.

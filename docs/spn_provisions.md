# Hai SPN tiêu hao — 2026-10-11

| SPN | Hiệu ứng mỗi tay tính điểm |
| --- | --- |
| Sứ Giả Tiếp Tế (`spirit_wayfarer`) | 25% nhận một tiêu hao ngẫu nhiên vào ô tiêu hao. |
| Ảnh Kép Đầu Tiên (`spirit_first_echo`) | 25% sao chép tiêu hao đang ở ô đầu tiên, giữ nguyên nâng cấp và thuộc tính. |

Xác suất cơ bản 25%, tăng theo hệ số tiến hóa SPN hiện có: mỗi cấp thêm 12,5 điểm phần trăm, tối đa 100%. Từ bậc Thường: 25% → 37,5% → 50% → 62,5% → 75% → 87,5% → 100%. Bậc ban đầu cao hơn cũng áp dụng hệ số tương ứng. Mỗi SPN đang hoạt động quay một lần mỗi tay tính điểm; tái kích hoạt thông số điểm không tăng số lần quay. Xem trước điểm không quay thưởng hoặc thay đổi túi.

Cần ô trống. Khi túi đầy, hoặc túi rỗng với lá sao chép, hiệu ứng bỏ qua. Phần thưởng được thêm ở cuối túi, không thay thế lá đang giữ. Số ô tuân theo các nâng cấp túi hiện tại. SPN bị Boss khóa không kích hoạt.

Các SPN xử lý từ trái sang phải: Sứ Giả đặt trước Ảnh Kép có thể tạo tiêu hao rồi được Ảnh Kép sao chép trong cùng tay. Bản sao có dữ liệu độc lập, kể cả bảng thông số, màu và nâng cấp; sử dụng hoặc sửa một lá không sửa lá kia.

Danh sách ngẫu nhiên lấy từ các danh mục game: phù phép SPN, ấn, phép hồn, hành tinh, ấn bản, thuốc, giường, tốc đánh, tiến hóa, sinh lực, mở ô, thêm hốc, phá luật và Lá Tiêu Hủy. Mỗi ID xuất hiện một lần trong danh sách; chọn đều giữa các ID.

Tranh tạo bằng ImageGen, PNG 1024×1536 và JPG runtime 512×768; prompt và nguồn lưu ở `CONTINENTAL_ASSET_PROMPTS.md` và `asset_manifest.json`. Bản xem trong game: `spn_provisions_runtime.png`.

Kiểm tra: `tests/spn_provisions_smoke.lua`, snapshot 50 SPN, bộ Continental/LÖVE và `--test-spn-provisions-art`.

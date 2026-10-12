# Vọng Linh Hữu Ảnh — 2026-10-12

`spirit_right_echo` sao chép khả năng của SPN ở ô **ngay bên phải**, kích hoạt một lần tại ô của mình mỗi khi tới sự kiện tương ứng. SPN nguồn vẫn hoạt động bình thường. Tiến hóa tăng số lần: 1 → 2 → 3…; bậc ban đầu cao hơn áp dụng số bước tương ứng của hệ SPN.

Sức mạnh và điều kiện của khả năng sao chép theo **cấp của SPN nguồn**. Tiến hóa Vọng Linh tăng số lần, không thay cấp nguồn. Các lần chạy nối tiếp nhau: hai lần ×2 cho ×4; mỗi lần tiêu linh hồn, lấy Giáp, quay thưởng hoặc tạo tiêu hao đều dùng lượng tài nguyên/ô trống còn lại. Giới hạn một lần mỗi trận hoặc việc tự tiêu hủy của nguồn vẫn được giữ.

Hỗ trợ tính điểm từng lá/từng tay, vào trận, thắng trận, tấn công, phản ứng đòn quái, bỏ bài và hạ Boss. Sao chép Độc Kích cũng sao chép giới hạn đánh một lá. Sao chép Kén Kế Thừa có thể tự tiêu hủy Vọng Linh khi hạ Boss. Không sao chép ấn bản hoặc phù phép của nguồn; ấn bản/phù phép riêng của Vọng Linh vẫn xử lý như SPN thường.

Ô phải trống không bỏ qua sang ô xa hơn. Đổi vị trí đổi nguồn ngay. Khóa ô của Vọng Linh hoặc nguồn đều chặn sao chép. Chuỗi nhiều Vọng Linh hướng sang phải được giải quyết tới SPN cuối; số lần kết hợp theo tích, tối đa 128 lần cho một sự kiện theo giới hạn kích hoạt của game. Không tự gọi lại một vòng tham chiếu lỗi.

Trạng thái trận của bản sao tách khỏi SPN gốc. Tiến trình tích số được giữ riêng trên Vọng Linh theo loại khả năng, lưu/tải cùng lá; không làm tăng tiến trình của nguồn. Đổi đi rồi trở lại cùng loại khả năng không làm mới giới hạn đã dùng trong trận. Xem trước chỉ mô phỏng trạng thái trong game tách biệt, không sửa dữ liệu thật hoặc quay thưởng tiêu hao.

Tooltip giữ tên, cấp và tranh của Vọng Linh; thêm tên nguồn, số lần hiện tại, mô tả sức mạnh và tích lũy đang sao chép. Khi không có nguồn hoạt động, tooltip báo rõ.

Nguồn: `src/spn_mimic.lua`, nối vào các luồng SPN hiện có qua một lần kích hoạt với trạng thái riêng. Kiểm thử: `tests/spn_mimic_smoke.lua`, snapshot 57 SPN, scoring runtime và hồi quy Continental/LÖVE. Tranh ImageGen Continental PNG 1024×1536 + JPG runtime 512×768; prompt/nguồn ở `CONTINENTAL_ASSET_PROMPTS.md`, manifest ở `asset_manifest.json`. Khung thật: `--test-spn-mimic-art`, xuất `spn_mimic_runtime.png`.

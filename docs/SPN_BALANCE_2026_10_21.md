# Cân bằng SPN — 21/10/2026

## Giảm sức mạnh

- **Độc Kích Thiên Thạch:** sát thương gốc +100 thay cho +1.000. Vẫn yêu cầu đánh đúng một lá; mỗi cấp tiến hóa vẫn nhân đôi: 100 → 200 → 400…
- **Đồng Hồ Vô Tận:** mỗi lần bỏ bài tích lũy vĩnh viễn +0,5 Cường hóa thay cho +2. Giữ số lần bỏ bài đã tích; sức mạnh mỗi tầng tính lại theo mức mới. Tiến hóa/bậc vẫn nhân hiệu lực theo quy tắc SPN.

## Bậc SPN được bán

Mọi quầy shop có bán SPN chỉ sinh **C, UC, R, E, L**. Không bán M/T/UQ/VH/TT. Các nguồn thưởng ngoài shop và tiến hóa vẫn dùng hệ thống bậc đầy đủ.

| Bậc | Tỷ lệ khi mở đủ C–L | Giá vàng với SPN giá gốc 4 |
| --- | ---: | ---: |
| C | 68% | 16 |
| UC | 22% | 24 |
| R | 7,5% | 32 |
| E | 2% | 72 |
| L | 0,5% | 120 |

Giữ mốc E từ ải 3, L từ ải 6. Trước khi mở đủ bậc, chuẩn hóa trọng số trong các bậc đã mở. Giá riêng của Shop Máu và hiệu lực Huyết Luyện vẫn áp dụng.

## Lượt dùng lá Tiến Hóa cho SPN

- Mỗi SPN đang trang bị khi hạ một boss nhận **1 lượt tiến hóa riêng**; thắng hai boss tích hai lượt. SPN trong balo không nhận lượt.
- Dùng lá Tiến Hóa cho SPN đang trang bị tốn một lượt cho mỗi bậc tăng. Không có lượt thì không tăng bậc, không mất lá Tiến Hóa.
- Thẻ được khuếch đại chỉ tăng tối đa số bậc mà SPN còn lượt. Ví dụ thẻ ×5 nhưng SPN chỉ có một lượt thì tăng một bậc; màn xem trước hiện đúng mức này.
- Cất SPN vào balo không xóa lượt đã tích; trang bị lại có thể dùng tiếp. Lượt không chuyển sang SPN khác. SPN mới được sao chép không thừa hưởng lượt chưa dùng của bản gốc.
- Mỗi boss có biên nhận đã cấp lượt, lưu theo trận/khu vực và giữ qua save/load. Mở lại phần thưởng hoặc xử lý chiến thắng nhiều lần không cấp thêm.
- Save cũ giữ bậc tiến hóa đang có, bắt đầu với 0 lượt chưa dùng nếu chưa lưu trường này; không cộng bù từ số boss thắng trước đây.
- **Kỹ năng tự tiến hóa SPN giữ nguyên**, theo lựa chọn của người dùng. Quân bài thường tiếp tục dùng lá Tiến Hóa theo cơ chế cũ.

Mô tả SPN hiện số lượt còn lại. Màn Tiến Hóa khóa xác nhận khi SPN chưa có lượt và giải thích cần cùng SPN thắng boss.

## Kiểm chứng

- `tests/spn_balance_limits_smoke.lua`: 6.000 SPN chào bán, chỉ C–L, phân bố gần trọng số và giá tăng theo bậc; quầy nhỏ/lớn/máu; 1/2 boss, balo, thẻ ×5, lưu/tải, chống cấp lặp, bản sao, xác nhận modal và giữ thẻ khi thất bại.
- `tests/spn_convergence_smoke.lua`: số lẻ +0,5 trong chấm điểm thật, tích lũy và tiến hóa.
- `tests/spn_legacy_smoke.lua`: +100 gốc, nhân đôi đúng qua các cấp và lưu/tải.
- Đã qua hồi quy chiến dịch, shop/voucher và các cơ chế SPN liên quan, gồm kỹ năng tự tiến hóa.

Chưa chạy lại mô phỏng toàn chiến dịch cho cấu hình này; số liệu cân bằng trong các báo cáo trước là lịch sử.

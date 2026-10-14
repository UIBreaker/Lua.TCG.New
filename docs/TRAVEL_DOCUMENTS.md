# Giấy phép và công nhận vương quốc

Số ải tổng dùng `run.ante` và luôn tiếp tục qua mọi khu vực: hết ải 20 đi khu vực mới bắt đầu ải 21. `run.areaStage` là tiến độ nội bộ để chọn bốn background và mốc chinh phục, không dùng làm số ải chính trên HUD. Tiến độ boss đã thắng theo khu vực lưu ở `run.regionStagesWon`; quay lại khu vực tiếp tục mốc nội bộ đang khám phá.

Mỗi chặng 20 ải của khu vực hữu hạn cấp một `cons_travel_permit` vào ngăn tiêu hao dự trữ. Cơ, Rô, Chuồn, Bích đồng thời cấp lá công nhận vĩnh viễn riêng khi chinh phục lần đầu; lưu tại `game.regionRecognitions`, xem trong ngăn Công nhận của balo và trong màn hình di chuyển. Chinh phục lại giữ công nhận đã có, không tăng số loại vượt bốn. Lục địa con người cấp giấy phép; lục địa bí ẩn vô tận không cấp công nhận hoặc giấy phép ở mốc 20.

Lục địa bí ẩn chỉ mở khi đủ công nhận của cả bốn vương quốc. Điều kiện nằm trên cấu hình khu vực `requiresRecognitions` và được kiểm tra bằng `Expedition.canEnter`, cả UI và giao dịch. Thêm khu vực vào `Expedition.regions` sẽ xuất hiện trong màn chọn điểm đến; khu vực không có điều kiện được đi bằng giấy phép.

Shop tiêu hao có một giấy phép giá 2.000 vàng, nằm cùng bảy món tiêu hao khác. Mua vào balo, dùng nút Chọn điểm đến hoặc chuột phải khi ở giữa các trận; cũng có thể dùng từ ô tiêu hao đã trang bị. Giấy phép chỉ mất khi xác nhận điểm đến hợp lệ. Hủy giữ nguyên giấy phép, vàng và tiến độ. Bán nhận 1.000 vàng; giấy phép mua giữa hành trình khi bán chỉ trở lại màn trước, không tự đổi khu vực hay tăng ải.

Giấy phép và công nhận mới được hiện trong lễ trao thưởng, nhưng giao dịch đã chốt khi thắng boss. Hoạt cảnh hoặc mở lại không cấp lặp; quy đổi nhanh chiến lợi phẩm không bán các hồ sơ hành trình. Save giữ công nhận, tiến độ từng khu vực và lựa chọn giấy phép đang mở; save cũ đang có giấy phép ở mốc thắng 20 được chuyển thành lá tiêu hao tương ứng.

Artwork: `assets/cards/continental/utility/recognition_hearts.png`, `recognition_diamonds.png`, `recognition_clubs.png`, `recognition_spades.png`, `travel_permit.png`. Năm PNG 2:3 do built-in ImageGen tạo theo Continental, dùng khung chung runtime; prompt và nguồn lưu tại `CONTINENTAL_ASSET_PROMPTS.md` / `asset_manifest.json`.

Kiểm tra: `lua tests/journey_routing_smoke.lua`, `lua tests/shop_markets_smoke.lua`, `lua tests/run_resume_smoke.lua`, `lua tests/loadout_smoke.lua`; `lovec.exe . --test-travel-documents` kiểm tra lễ thưởng, HUD 21, khóa/mở bí ẩn, mua thật 2.000 vàng, dùng/hủy giấy phép từ balo và đủ bốn công nhận. Chế độ capture không ghi save người chơi; PNG có tiền tố thời gian để tránh ghi đè file đang mở trên Windows.

# Bốn thực thể bí ẩn của vương quốc

Đây là bốn boss tự do: có thể xuất hiện ở lượt boss của bất kỳ vùng chính nào, không phụ thuộc chất của vùng hoặc mốc ải 20. Nhóm thực thể chiếm 25% lượt chọn boss (mỗi thực thể 6,25%); những lượt còn lại dùng nhóm boss sẵn có. Boss sự kiện Vương Huyết ở Lãnh Địa Máu giữ nguyên để hoàn tất nhánh riêng.

| Nguồn gốc | Thực thể | Chất bị phong ấn |
| --- | --- | --- |
| Valoria | Chủ Tể Tro Tim | Cơ |
| Aurelia | Kẻ Nuốt Hoàng Kim | Rô |
| Elaris | Cội Rễ Lãng Quên | Chuồn |
| Vharos | Bóng Vương Băng Tịch | Bích |

Quân bài bị phong ấn không đóng góp điểm riêng và không kích hoạt khả năng hoặc trang bị khi tính điểm. Phong ấn áp dụng cả với chất Bích, không bị bỏ qua bởi miễn nhiễm chất Bích cũ.

Mỗi lá cùng chất đang trên tay người chơi tăng **10% tốc đánh và 10% sát thương** cho boss, cộng theo số lá: hai lá tăng 20%, ba lá tăng 30%. Thay đổi tay bài cập nhật chỉ số ngay; không tích lũy qua lượt và không tính bài trong kho. Boss chết hoặc bị vô hiệu nội tại sẽ gỡ phong ấn và phần tăng chỉ số.

Tranh mới dùng khung và ký hiệu chất chung của game, không vẽ chữ hoặc khung vào ảnh. Prompt đầy đủ và đường dẫn từng ảnh: [KINGDOM_ENTITY_ASSETS.json](KINGDOM_ENTITY_ASSETS.json). Bản xem trước: [kingdom_entity_roster.png](kingdom_entity_roster.png).

Kiểm tra cơ chế: `lua tests/kingdom_bosses_smoke.lua`. Kiểm tra hiển thị bằng LÖVE: `lovec.exe . --test-kingdom-bosses`, xuất ảnh bốn trận và bộ chân dung vào `docs/kingdom_entity_*.png`.

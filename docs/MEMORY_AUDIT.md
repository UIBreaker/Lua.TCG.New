# Kiểm tra bộ nhớ ngày 21/10/2026

## Nguyên nhân tìm được

Nhật ký System của Windows lúc 23:11:20 ngày 20/10/2026 (giờ Việt Nam),
event 2004 của Resource-Exhaustion-Detector, ghi nhận hai `lovec.exe` dùng
16.653.266.944 và 11.918.020.608 byte bộ nhớ cam kết, tổng khoảng 26,6 GiB.
Đây là tổng hai tiến trình; nhật ký không lưu đối số để xác định chúng đang
chạy game hay kiểm thử nào. Không còn tiến trình đó để lấy heap dump.

Phiên bản trước commit `c90efc5` có lỗi giữ bản sao trận đấu trong
`src/spn_basics.lua`: `cardGames` dùng bảng weak-key (`__mode="k"`), nhưng
giá trị trỏ về game, game lại giữ các lá bài làm khóa. Trong LuaJIT của LÖVE,
vòng này giữ lại bản sao dùng để xem trước điểm sau khi thu gom rác.
Mỗi lần xem trước lại tạo và đăng ký một bản sao trận đấu mới.

Commit `c90efc5` lúc 00:38:01 ngày 21/10 đã đổi bảng sang weak-key và weak-value
(`__mode="kv"`). Bản sửa đã tồn tại trước lần rà soát này.

Đã tái hiện riêng cơ chế cũ bằng cách đổi metatable trong một tiến trình kiểm
thử, không sửa ngược mã game: sau 100 lần xem trước giữ 500 liên kết; sau
100 lần tiếp theo giữ 1.000 liên kết dù đã chạy GC hai lần.
Đây là một nguyên nhân có khả năng giải thích mức tăng tối qua; không thể
quy toàn bộ 26,6 GiB cho nó khi thiếu heap dump của hai tiến trình cũ.

## Kiểm chứng mã hiện tại

`tests/preview_memory_smoke.lua` chạy 100 lần khởi động JIT rồi 1.000 lần
xem trước trên bộ 52 lá, mỗi lá có hai trang bị, trong chính LuaJIT của game.
Chạy riêng: số liên kết ổn định 10 → 10; heap Lua tăng khoảng 7 KiB.
Chạy cùng các regression khác: 0 → 0, heap không tăng đáng kể.

`tests/memory_soak/main.lua` chạy 6.000 khung hình với timestep 1/60 giây:
5 chu kỳ bắt đầu ván, chọn bài/xem trước, đánh bài, mở shop, mở inspector,
trở về menu. Seed lặp lại để đo cùng nội dung và phân biệt cache ảnh mới.
Persistence được thay bằng hàm kiểm thử; không đọc/ghi/xóa save thật.

| Sau khung hình | Private/commit (MiB) | RAM working set (MiB) | Texture (MiB) | Heap Lua (MiB) | Canvas / Image |
| --- | ---: | ---: | ---: | ---: | --- |
| 1.200 | 1.133,1 | 728,0 | 267,6 | 8,2 | 37 / 113 |
| 3.600 | 1.143,3 | 744,2 | 279,6 | 7,7 | 37 / 121 |
| 6.000 | 1.140,6 | 741,3 | 279,6 | 7,8 | 37 / 121 |

Không thấy tăng liên tục sau khi nạp đủ tài nguyên trong chuỗi này.
Lượt 12.000 khung hình với nội dung ngẫu nhiên khác nhau giữ heap Lua
khoảng 7–8 MiB; texture tăng từ việc cache thêm các ảnh trong catalog.
Lượt đó chạm ngưỡng kiểm tra tăng texture, nên bài soak dùng seed cố định
để không nhầm nội dung mới với rò rỉ khi lặp cùng thao tác.

7 nhóm regression đã qua: scoring runtime (207 checks), preview memory,
SPN snapshot, SPN basics, SPN mimic, applied balance và enemy AI.

## Chạy lại trên Windows

Từ thư mục dự án, với runtime LÖVE ở thư mục cha:

```powershell
& '..\love-11.5-win64\lovec.exe' tests/scoring_audit tests.preview_memory_smoke
& '..\love-11.5-win64\lovec.exe' . --test-memory-soak 6000
```

Bài soak đo bộ nhớ Windows qua PSAPI, texture/canvas qua LÖVE và heap qua
Lua GC; có ngưỡng dừng 1,5 GiB private để tránh làm máy cạn bộ nhớ.
Kết quả phụ thuộc driver và thiết bị. Đây là kiểm thử ngắn có giới hạn,
không chứng minh mọi tổ hợp bài hoặc một phiên chơi kéo dài nhiều giờ.
Chưa build lại gói phát hành; các bài đo dùng mã nguồn hiện tại.

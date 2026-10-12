# Song Nanh Hư Không — 2026-10-12

`spirit_twin_fang`: mỗi tay tính điểm nhân ×2 Sát thương tại ô SPN này, không cần điều kiện. Tiến hóa theo hệ SPN: ×2 → ×2,5 → ×3 → ×3,5… Bậc ban đầu cao hơn áp dụng hệ số tương ứng.

Nhân trục Sát thương (`xChips`), giữ Cường hóa. Các thưởng Sát thương đặt trước lá này được nhân; thưởng đặt sau được cộng sau phép nhân. Nhiều bản sao nhân hệ số với nhau. Không giới hạn số lá chơi, không tăng tốc hoặc tiêu tài nguyên. Boss khóa ô thì tạm ngừng hiệu ứng.

Kiểm thử `tests/spn_twin_fang_smoke.lua`, snapshot 56 SPN và hồi quy Continental/LÖVE đã xác nhận tiến hóa, thứ tự ô, tích hệ số, xem trước/RNG và lưu tải. `--test-spn-twin-fang-art` xuất `spn_twin_fang_runtime.png`. Tranh ImageGen và prompt trong `CONTINENTAL_ASSET_PROMPTS.md`, manifest trong `asset_manifest.json`.

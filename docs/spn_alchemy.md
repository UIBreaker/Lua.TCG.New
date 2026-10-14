# Hai SPN dược

Hai lá bán trong shop như SPN thường, có thể tiến hóa và lưu/tải. Bậc C ban đầu:

| SPN | Cấp 0 | Cấp 1 | Cấp 2 |
| --- | --- | --- | --- |
| Dược Linh Cộng Hưởng | Hiệu quả thuốc ×2 | ×2,5 | ×3 |
| Dược Hồn Bất Diệt | 10% hóa vĩnh viễn | 15% | 20% |

## Cộng Hưởng

Áp dụng các bình thuốc máu, giáp, Tốc Đánh Nhỏ/Lớn và tám thuốc chiến thuật trong shop thuốc. Không nhân giá mua, chi phí, Cái Giường, thẻ tăng tốc vốn vĩnh viễn hoặc các tiêu hao không phải thuốc.

- Máu/giáp: tăng lượng nhận, giữ giới hạn HP/giáp.
- Sát Thương/Cường Hóa: tăng lượng thưởng cho mỗi quân hiện trên tay.
- Tốc Đánh: tăng lượng tốc cho quân chọn, giữ giới hạn 999.
- Phá Giáp: vẫn phá toàn bộ giáp, tăng sát thương chuẩn từ lượng giáp phá (25% thành 50% ở ×2).
- Máu Vàng: 1 HP thực mất từ địch thành 2 vàng ở ×2, không trả tiền cho chi phí tự mất HP hay phần giáp hấp thụ.
- Rút Bài: 5 thành 10, lượng rút nguyên làm tròn xuống và không vượt số quân còn lại.
- Chính Xác/Né Tránh: đã đạt 100% nên tăng thời gian từ 1 thành 2 lượt; số lượt nguyên làm tròn xuống. Chính Xác được giữ qua đủ các lượt, không xóa ngay sau lần đánh đầu.
- Giảm Tốc: độ giảm 50% thành 100%, tốc địch tối thiểu 1; thời gian gốc 2 hành động. Phiên bản Huyết Luyện vẫn dùng thời gian dài hơn theo cơ chế cũ.

Nhiều bản/sao chép nhân hệ số với nhau, trần tổng ×128. Huyết Luyện/Void dùng cơ chế nhân hiệu quả hiện có.

## Bất Diệt

Theo lựa chọn của người dùng, chỉ áp dụng **thuốc Sát Thương, Cường Hóa, Tốc Đánh Nhỏ/Lớn** cho quân bài. Không hóa vĩnh viễn Chính Xác, Né Tránh, Máu Vàng, Giảm Tốc, Phá Giáp, Rút Bài, thuốc máu hoặc giáp.

Một lần quay khi dùng thành công một bình. Sát Thương/Cường Hóa quay một lần cho toàn bộ các quân chịu bình đó; Tốc Đánh chỉ quay sau khi xác nhận một quân hợp lệ. Thuốc không hợp lệ hoặc hủy chọn không mất bình và không dùng RNG.

Nếu thành công, lượng chỉ số **đã nhân bởi Cộng Hưởng** được thêm vào quân bài và bộ bài gốc. Không tạo thêm bản thưởng tạm của cùng lượng đó. Nếu thất bại, giữ cách hoạt động tạm thời cũ. Ví dụ thuốc +20 ST với hai SPN cấp 0: +40 ST tạm; trúng 10% thì +40 ST vĩnh viễn.

Tiến hóa tăng tỷ lệ, tối đa 100%. Nhiều bản/sao chép kết hợp như các cơ hội độc lập: hai nguồn 10% cho xác suất tổng 19%, không tự cộng thành 20%. Khi tỷ lệ đạt 100% không cần quay RNG.

Phần tăng giữ qua trận, lưu/tải, nhân bản quân và thay đổi rank. Sát thương nằm trong `baseChips`/`bonusBaseChips`, thêm `potionPermanentDamage` để dạng Chân Rết giữ được phần tăng riêng; cường hóa nằm trong `potionPermanentMult` và được tính trong mỗi lần quân ghi điểm; tốc dùng `speedBonus`. Không phụ thuộc việc tiếp tục trang bị SPN sau khi đã nhận thưởng.

SPN trong dự trữ hoặc ô bị boss khóa không tác dụng. Tooltip thuốc hiển thị giá trị theo SPN hiện có và tỷ lệ hóa vĩnh viễn. Tooltip quân phân biệt thưởng tạm và Dược Hồn vĩnh viễn. Xem trước điểm không quay tỷ lệ hoặc thay đổi chỉ số thật.

## Kiểm tra

- `tests/spn_alchemy_smoke.lua`: tất cả thuốc, tiến hóa, ranh giới 10/15%, một lần quay, nhiều nguồn, xác nhận/hủy mục tiêu, giới hạn, thưởng vĩnh viễn không cộng đôi, bộ bài gốc/Chân Rết/lưu/trận sau, preview/RNG, shop và khóa/dự trữ.
- Potions, inventory expansion, snapshot 80 SPN và scoring runtime 186 kiểm tra: PASS.
- Native `--test-potions`: PASS luồng dùng thuốc và hai đường thắng trận.
- Native `--test-spn-alchemy-ui`: PASS click/hủy chọn thực, +6 tốc vĩnh viễn, +40 ST/+10 CH vĩnh viễn; ảnh `docs/spn_alchemy_battle.png`. Capture dùng SPN Bất Diệt tiến hóa đến 100% để kiểm tra chắc chắn; tỷ lệ cơ bản được kiểm tra riêng ở smoke test.
- Continental 52: 11.232 tình huống PASS; mọi test SPN PASS. Bộ hồi quy tổng còn thất bại ở `tests/soul_shop_smoke.lua:133`: fixture cũ của Ankh/Hex vẫn đòi xóa SPN/trao linh hồn, trong khi hai ID này đã được chuyển sang phù phép mới trong `src/spn_enchantments.lua`. Không thay cơ chế ngoài phạm vi thuốc để thỏa fixture cũ.

Chưa playtest dài để cân bằng kinh tế và mức tăng vĩnh viễn.

## Tranh

Hai ảnh được tạo riêng bằng **built-in ImageGen** theo Continental Art Bible:

- `assets/cards/continental/spn/spirit_potion_resonance.png`
- `assets/cards/continental/spn/spirit_potion_eternity.png`
- PNG 1024×1536, runtime JPG 512×768; loader hiện có và khung dùng chung đã kiểm tra qua LÖVE.
- Ảnh xem trước: `docs/spn_alchemy_runtime.png`.
- Prompt/nguồn: mục “SPN potion resonance and permanence - 2026-10-14” trong `docs/CONTINENTAL_ASSET_PROMPTS.md`, metadata trong `docs/asset_manifest.json`.

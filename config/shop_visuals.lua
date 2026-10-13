local V = {}
V.profiles = {
    small = {brand="TRẠM TIẾP TẾ", motto="Một điểm dừng nhỏ cho chuyến đi dài.",
        rows={"QUẦY TUYỂN CHỌN", "TIẾP TẾ & KHÁM PHÁ"},
        notes={"SPN · Trang bị · Quân bài", "Thuốc · Đặc quyền · Rương · Thẻ lẻ"},
        material={.22,.14,.075}, accent={.80,.68,.43,1}, preset="DESERT", columns=4,
        help="Mua từng món cần thiết trước khi lên đường."},
    consumable = {brand="HIỆU THẺ PHÉP", motto="Một thẻ đúng lúc có thể đổi cả trận chiến.",
        rows={"TỦ THẺ PHÉP", "QUẦY DI VẬT & ẤN CHÚ"},
        notes={"Thẻ lẻ từ các rương", "Chọn từng lá · Cất vào balo"},
        material={.12,.10,.19}, accent={.72,.57,.92,1}, preset="VOID", columns=4,
        help="Giá thẻ lẻ cao hơn giá rương 20%."},
    equipment = {brand="LÒ RÈN VIỄN CHINH", motto="Từ nguyên liệu thô đến trang bị đồng hành.",
        rows={"GIÁ NGUYÊN LIỆU", "BÀN TRANG BỊ LỚN"},
        notes={"Sinh lực · Giáp · Tốc đánh · Vàng", "Mua vào balo · Ghép và khảm tại balo"},
        material={.16,.15,.13}, accent={.91,.68,.37,1}, preset="RUINS", columns=4,
        help="Mở balo để ghép đồ hoặc gắn trang bị lên quân bài."},
    spn = {brand="ĐIỆN HỘ LINH", motto="Những khế ước từ bên kia lục địa.",
        rows={"BỆ KHẾ ƯỚC I", "BỆ KHẾ ƯỚC II"},
        notes={"SPN ngẫu nhiên từ Thường đến Độc Nhất", "Xem bậc và năng lực trước khi chiêu mộ"},
        material={.075,.10,.18}, accent={.57,.74,.96,1}, preset="MYSTIC", columns=3,
        help="SPN mua vào balo. Kéo vào ô trang bị để kích hoạt."},
    medicine = {brand="TIỆM THẢO DƯỢC", motto="Nghỉ chân, hồi sức rồi tiếp tục hành trình.",
        rows={"HỒI PHỤC & NGHỈ NGƠI", "GIÁP & TỐC ĐÁNH"},
        notes={"Bình máu · Giường nghỉ", "Bình giáp · Thuốc tăng tốc"},
        tacticalRows={"THUỐC CHIẾN THUẬT", "CƯỜNG HÓA & MÁU VÀNG"},
        tacticalNotes={"Chính xác · Né tránh · Phá giáp · Rút bài", "Sát thương · Cường hóa · Máu vàng · Giảm tốc"},
        material={.13,.18,.11}, accent={.53,.82,.56,1}, preset="FOREST", columns=4,
        help="Mua thuốc vào balo. Trang bị vào ô tiêu hao trước khi dùng trong trận."},
    cards = {brand="HIỆU QUÂN BÀI", motto="Chiêu mộ đồng hành từ bốn vương quốc.",
        rows={"TỦ QUÂN BÀI I", "TỦ QUÂN BÀI II"},
        notes={"Đủ 52 lá · 2–A · Cơ / Rô / Chuồn / Bích", "Tiến hóa 1–2 · Đồ cơ bản · Ấn bản"},
        material={.23,.09,.09}, accent={.92,.65,.45,1}, preset="DESERT", columns=4,
        help="Nâng cấp được giữ khi mua. Trang bị đi kèm chỉ là đồ cơ bản."},
}
V.scenes = {}
for _,size in ipairs({"small","large"}) do
    V.profiles["blood_"..size]={brand=size=="large" and "ĐẠI ĐIỆN HUYẾT ƯỚC" or "QUẦY HUYẾT ƯỚC",motto="Sức mạnh có giá bằng sinh lực.",
        rows={"DI VẬT HUYẾT LUYỆN", "KHẾ ƯỚC & TIẾP TẾ"},notes={"SPN · Trang bị · Quân bài · Thuốc", "Đặc quyền · Rương · Thẻ lẻ · Tay bài"},
        material={.25,.065,.09},accent={.95,.34,.43,1},preset="VOLCANIC",columns=4,
        help="Mọi món Huyết Luyện ×5. Trả bằng HP, giữ ít nhất 1 HP. Đổi hàng cũng mất máu."}
end
for mode,profile in pairs(V.profiles) do
    profile.background="assets/scene/shops/"..mode..".png"
    V.scenes[mode]={base="shop_"..mode,backgroundPath=profile.background,
        preset=profile.preset,brightness=.95}
end
V.scenes.large={base="shop_small",backgroundPath=V.profiles.small.background,
    preset="DESERT",brightness=.90}
return V

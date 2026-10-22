local D={list={},byId={}}
for _,row in ipairs({
    {"human_last_strategist","Quan Chấp Cấm Thế","formation","CẤM THẾ",{.70,.46,.49,1},
        "Mỗi thế bài đã mở khóa chỉ được đánh một lần trong trận. Sau khi tay đó hoàn tất, thế bài bị khóa đến hết trận.",
        "Phán Quyết Cuối","Khi toàn bộ thế bài đã mở khóa đều bị khóa và Boss còn sống: bạn thua ngay lập tức."},
    {"human_ashen_archivist","Kẻ Gạch Tên","cards","GẠCH TÊN",{.62,.73,.80,1},
        "Vô hiệu hóa các lá từng được đánh trong cùng ải, kể cả ở trận trước: 0 điểm riêng, không kích hoạt khả năng hoặc trang bị. Không khóa các bản sao có ID khác.",
        "Tước Tiến Hóa","Mỗi lượt giảm vĩnh viễn 1 cấp tiến hóa của một lá ngẫu nhiên đang bị khóa; tối thiểu 0."},
    {"human_death_challenger","Kẻ Thách Tử","oneshot","THÁCH TỬ",{.92,.65,.31,1},
        "Sát thương cơ bản ×5. Không thể bị oneshot từ đầy máu: sát thương đòn kết liễu sau giảm trừ trở thành Máu tối đa và Máu hiện tại mới; sát thương Boss ×3 mỗi lần kích hoạt. Bào máu rồi kết liễu vẫn hạ được Boss.",
        "Khiêu Chiến Tử Thần","Mỗi lượt cho người chơi +20% tổng sát thương, cộng dồn theo lượt (20%, 40%, 60%...). Chỉ trong trận này."},
    {"human_rank_inquisitor","Giám Quan Tước Phẩm","rarity","TƯỚC PHẨM",{.73,.56,.91,1},
        "Đầu trận chọn ngẫu nhiên một bậc SPN từ C đến TT và vô hiệu hóa SPN thuộc bậc đó. Bậc được chọn giữ nguyên trong trận; SPN đổi bậc được kiểm tra lại ngay. TT bao gồm TT+.",
        "Giáng Hai Phẩm","Mỗi lượt hạ vĩnh viễn 2 bậc một SPN ngẫu nhiên của bạn, kể cả trong balo. Bỏ qua SPN đang ở C; không hạ dưới C."},
}) do
    local d={id=row[1],debuffId=row[1],artKey=row[1],name=row[2],freeHumanBoss=row[3],title=row[4],color=row[5],desc=row[6],expeditionActive=true}
    d.active={name=row[7],description=row[8],amount=1,op=row[3]=="cards" and "devolve_sealed" or "formation_doom",cooldown=0}
    d.activeCooldown=0;D.list[#D.list+1]=d;D.byId[d.id]=d
    if d.freeHumanBoss=="oneshot" then d.baseAttackMultiplier=5;d.active.op="challenge_damage" end
    if d.freeHumanBoss=="rarity" then d.active.op="devolve_spn_two" end
end
return D

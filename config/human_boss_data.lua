local rows={
    {"human_vital_marshal","Thống Soái Huyết Mạch","Máu tối đa +50% so với Boss của ải hiện tại.","Huyết Mạch","Mỗi đòn tấn công hồi 5% HP tối đa; dùng dự trữ hồi hữu hạn."},
    {"human_wind_reaver","Kẻ Cướp Gió","Tốc đánh tối thiểu gấp đôi lá nhanh nhất đang trên tay bạn, kể cả vượt 999.","Đoạt Phong","Đánh trúng: cướp vĩnh viễn 2 tốc từ lá nhanh nhất bạn đã chọn chơi."},
    {"human_oath_judge","Thẩm Phán Thệ Ước","Chỉ tay bài được chỉ định mới đánh trúng; chọn thế đã mở khóa và ghép được từ tay hiện tại.","Tước Lệnh","Đánh trúng: lập tức bỏ ngẫu nhiên 2 lá còn trên tay bạn."},
    {"human_court_puppeteer","Nhiếp Chính Mặt Nạ","Vô hiệu hóa J, Q, K: không gây sát thương và không kích hoạt khả năng/trang bị.","Mặt Nạ Triều Đình","Đánh trúng: biến một lá trên tay thành J/Q/K và khóa nó. Chỉ tồn tại trong trận này."},
    {"human_hand_gaoler","Giám Ngục Thiết Luật","Giảm 1 ô sức chứa tay bài, tối thiểu còn 1 ô.","Áp Lực Đám Đông","Sát thương đòn đánh nhân số lá đang trên tay bạn; cầm 5 lá nhận ×5 ST."},
    {"human_bastion","Pháo Đài Nhân Thế","Đầu trận có giáp đặc biệt bằng 100% HP hiện tại. Bạn phải có giáp để phá lớp này, kể cả sát thương chuẩn.","Mũi Giáo Xuyên Tâm","Đòn đánh bỏ qua giáp của bạn, gây sát thương thẳng vào HP."},
    {"human_spirit_breaker","Kẻ Bẻ Hồn","Đầu trận tiêu hủy vĩnh viễn một SPN ngẫu nhiên của bạn, gồm cả SPN trong balo.","Bào Mòn Linh Hồn","Mỗi lần Boss thực mất HP: giảm vĩnh viễn một bậc của một SPN ngẫu nhiên; tối thiểu Thường."},
    {"human_chain_binder","Chủ Nhân Xiềng Bạc","Đầu trận bắt tối đa 2 lá trên tay thành đồng minh. Hạ Boss trước để cứu chúng; đồng minh chết thì mất vĩnh viễn lá gốc.","Xiềng Suy Tàn","Đánh trúng: giảm vĩnh viễn 1 cấp tiến hóa một lá còn trên tay, không giảm dưới 0."},
    {"human_last_executioner","Đao Phủ Đoạn Mệnh","Lượt bỏ bài khi vào trận bằng 0.","Đoạn Mệnh","Dùng một lần mỗi trận, thay lượt đánh: tiêu hủy vĩnh viễn một lá ngẫu nhiên trên tay."},
    {"human_gilded_broker","Chủ Hội Kim Quyền","Mỗi 10 vàng của bạn lúc đầu trận tạo một lần ×1.5 vào ngẫu nhiên HP, ST hoặc tốc của Boss; tối đa 6 lần.","Cưỡng Chế Giao Dịch","Mỗi lần gây mất HP cho bạn: bán một món ngẫu nhiên trong balo, trả giá bán thường vào vàng của bạn."},
}
local D={list={},byId={}}
local firstStages={1,6,4,5,1,6,8,8,5,10}
local hpScales={[2]=.8,[5]=.9,[6]=.9}
local damageScales={[2]=.8,[5]=.65,[6]=.9}
for number,row in ipairs(rows) do
    local d={id=row[1],debuffId=row[1],artKey=row[1],name=row[2],title="THỦ LĨNH NHÂN LOẠI",humanBoss=number,
        desc=row[3],color={.89,.73,.43,1},expeditionActive=true,
        firstStage=firstStages[number],hpScale=hpScales[number] or 1,damageScale=damageScales[number] or 1,
        active={name=row[4],op="human_contact",amount=0,cooldown=0,description=row[5]}}
    D.list[number]=d;D.byId[d.id]=d
end
return D

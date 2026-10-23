-- The 52 cards share rank stats and suit-based discard effects.
local Data = {
    maxEvolutionLevel=10, maxRetriggerDepth=4, maxCopyDepth=3,
    maxTriggersPerHand=128, maxRetriggersPerCard=8, armorCap=999,
    tacticsVersion=3, definitions={}, order={},
}
local effects={
    heart={name="Hồi sinh lực",text="Bỏ lá này: hồi {healPercent}% máu tối đa.",params={healPercent=1}},
    diamond={name="Thu vàng",text="Bỏ lá này: nhận {gold} Vàng.",params={gold=1}},
    club={name="Tiếp sức",text="Bỏ lá này: các lá còn trên tay +{speed} Tốc đánh trong 1 lượt.",params={speed=0.5}},
    spade={name="Dựng giáp",text="Bỏ lá này: nhận Giáp bằng {armorPercent}% máu tối đa.",params={armorPercent=1}},
}
local function add(suit,rank,character,ambition)
    local id=suit.."_"..(({[11]="jack",[12]="queen",[13]="king",[14]="ace"})[rank] or rank)
    local effect=effects[suit]
    local d={id=id,suit=suit,rank=rank,characterName=character,name=effect.name,
        description=effect.text.." Các lá cùng chất còn trên tay +1 Cường hóa.",
        trigger="discard",op="suit_discard",baseParams=effect.params,evolutionRules={},ambition=ambition}
    Data.definitions[id]=d;Data.order[#Data.order+1]=id
end
add("heart",2,"Maera · Y Sĩ Tro Hồng","Cứu mọi người bị bỏ lại ở biên giới dung nham.")
add("heart",3,"Corvin · Người Giữ Nhịp Tim","Tìm cách chữa trái tim hóa đá của em trai.")
add("heart",4,"Yselle · Sứ Giả Bốn Bờ","Hợp nhất những đoàn viễn chinh từng là kẻ thù.")
add("heart",5,"Bram · Người Cõng Bình Minh","Đưa đoàn tị nạn vượt vùng tro trước bình minh.")
add("heart",6,"Edda · Bếp Lửa Viễn Chinh","Nấu bữa tối cuối cùng ở mọi trại bị chiến tranh bỏ quên.")
add("heart",7,"Lucan · Kẻ Trả Nợ Máu","Chuộc lại đoàn lính từng bị mình bán đứng.")
add("heart",8,"Vesta · Người Vá Khiên","Tái tạo bộ giáp bảo vệ quê nhà khỏi núi lửa.")
add("heart",9,"Neris · Người Canh Lều","Dựng nơi trú ẩn mà không người lữ hành nào bị từ chối.")
add("heart",10,"Aveline · Người Không Gục","Giữ lời hứa sống sót để bảo vệ con gái.")
add("heart",11,"Ronan · Cận Vệ Đỏ","Trở thành người bảo hộ mà người thầy đã không kịp trở thành.")
add("heart",12,"Seraphine · Người Gom Tàn Lửa","Khôi phục khu vườn đầu tiên trên đất cháy.")
add("heart",13,"Garrick · Vua Không Ngai","Giành lại vương quốc bằng cách cứu dân trước khi lấy ngai.")
add("heart",14,"Althea · Người Mở Bình Minh","Chứng minh ánh sáng vẫn tồn tại phía sau nhật thực.")
add("diamond",2,"Orrin · Người Đổi Muối","Mở tuyến trao đổi công bằng giữa sa mạc và biển.")
add("diamond",3,"Tamsin · Người Đòi Công","Thu hồi tiền công bị cướp của thợ khai quật.")
add("diamond",4,"Nasira · Người Nối Bốn Chợ","Kết nối bốn thương cảng mà không phục tùng đế chế.")
add("diamond",5,"Perrin · Chủ Đoàn Lữ Hành","Dẫn đoàn hàng đầu tiên đến tận rìa lục địa.")
add("diamond",6,"Mirel · Người Nhặt Cơ Hội","Biến những thứ bị bỏ đi thành cơ nghiệp của riêng mình.")
add("diamond",7,"Hadrien · Người Đếm Hoàng Hôn","Tích đủ tiền mua tự do cho thị trấn mắc nợ.")
add("diamond",8,"Sabria · Người Bảo Chứng","Xây ngân khố không thể cướp để bảo vệ lương của đoàn.")
add("diamond",9,"Elio · Người Bán Thuốc","Đem thuốc tới những người mà thương hội không chịu cứu.")
add("diamond",10,"Rhea · Người Thuê Gió","Thuê được đoàn trinh sát đưa mình tới thành phố thất lạc.")
add("diamond",11,"Dorian · Người Giữ Hợp Đồng","Viết bản hiệp ước mà cả người giàu lẫn nghèo đều giữ lời.")
add("diamond",12,"Isolde · Người Gom Hạt Vàng","Mua lại ốc đảo bị chính gia đình bán cho bạo chúa.")
add("diamond",13,"Balthazar · Vua Của Đường Xa","Dùng tài sản xây con đường an toàn thay vì cung điện.")
add("diamond",14,"Zara · Người Bắt Đầu Từ Không","Chứng minh một đứa trẻ đường phố cũng có thể dựng thương hội.")
add("club",2,"Finn · Người Chạy Song Song","Chạy nhanh đủ để không mất người bạn đồng hành lần nữa.")
add("club",3,"Sylva · Người Đếm Sấm","Tìm nơi tiếng sấm đã đánh thức khu rừng.")
add("club",4,"Kellan · Người Dẫn Bốn Lối","Vẽ đường thoát hiểm từ mọi ngả rừng.")
add("club",5,"Ivara · Đội Trưởng Lá Rơi","Đưa cả đội tới đích mà không bỏ người chậm nhất.")
add("club",6,"Tobin · Người Cắt Lối","Phá vòng lặp của cánh rừng nuốt người.")
add("club",7,"Liora · Người Chạy Qua Đau","Mang lời cầu cứu về trước khi vết thương khuất phục mình.")
add("club",8,"Aeric · Người Lướt Khiên","Tạo cách di chuyển giúp lính giáp nặng vượt rừng.")
add("club",9,"Moss · Người Canh Nhịp","Nghe được nhịp sống của cây cổ nhất lục địa.")
add("club",10,"Kael · Người Vượt Dốc","Đặt chân lên đỉnh cây che cả bầu trời.")
add("club",11,"Thalia · Người Mở Lối","Mở đường để đoàn không phải trả giá bằng mạng người.")
add("club",12,"Elowen · Người Ủ Gió","Tìm lại giọng hát của khu rừng đã im lặng.")
add("club",13,"Rowan · Vua Những Bước Chân","Kết thúc chiến tranh bằng một bước đi quyết định.")
add("club",14,"Zephyr · Người Đuổi Chân Trời","Nhìn thấy nơi tận cùng của tất cả những dòng sông.")
add("spade",2,"Torren · Người Giữ Cửa","Giữ cánh cổng băng đến khi người cuối cùng vượt qua.")
add("spade",3,"Freya · Người Đếm Tuyết","Ghi lại tên mọi người mất tích trong bão tuyết.")
add("spade",4,"Soren · Người Xây Bốn Trụ","Xây pháo đài nơi bốn dân tộc cùng được bảo vệ.")
add("spade",5,"Hilda · Người Gánh Tường Thành","Mang một phần thành lũy tới những nơi không có thành.")
add("spade",6,"Borek · Thợ Rèn Băng","Rèn từ phế tích một tấm khiên không bao giờ bỏ chủ.")
add("spade",7,"Astrid · Người Che Vết Thương","Bảo vệ người em từng mất một tay vì mình.")
add("spade",8,"Osric · Người Rút Đinh","Chứng minh phòng thủ cũng có thể chủ động ra đòn.")
add("spade",9,"Eira · Người Giữ Hậu Phương","Giữ ánh đèn của trại luôn cháy trong đêm cực dài.")
add("spade",10,"Magnus · Người Vá Xương Sống","Chữa lời nguyền khiến cơ thể đồng đội hóa thành sắt.")
add("spade",11,"Cedric · Người Chốt Đoàn","Không bao giờ để kẻ truy đuổi chạm vào đoàn mình.")
add("spade",12,"Morrigan · Người Ủ Pha Lê","Tái tạo hồ băng giữ ký ức của mẹ.")
add("spade",13,"Ulric · Vua Của Người Ở Lại","Bảo vệ một vương quốc nhỏ còn đúng một ngôi làng.")
add("spade",14,"Vaela · Người Dựng Trại Đầu","Dựng trại đầu tiên ở bên kia dãy núi không ai vượt qua.")
return Data

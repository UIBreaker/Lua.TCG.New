-- Ability levels never modify a card's poker rank or suit.
local Data = {
    maxEvolutionLevel = 8, maxRetriggerDepth = 4, maxCopyDepth = 3,
    maxTriggersPerHand = 128, maxRetriggersPerCard = 8, armorCap = 999,
    definitions = {}, order = {},
}
local ranks = { [14] = "ace", [11] = "jack", [12] = "queen", [13] = "king" }
local function add(suit, rank, name, event, op, params, scaling, description)
    local id = suit .. "_" .. (ranks[rank] or rank)
    local d = { id = id, suit = suit, rank = rank, name = name, trigger = event,
        op = op, baseParams = params, evolutionRules = scaling, description = description }
    Data.definitions[id] = d
    Data.order[#Data.order + 1] = id
end
-- Scaling numbers mean additive per level; tables mean a stepped increment.
add("heart",14,"Khoang Dự Trữ","held","capacity",{capacity=1},{capacity=1},"Khi giữ trên tay: kích thước tay +{capacity}.")
add("heart",2,"Không Rời Nhau","score","return_other",{count=2,returns=1,returnArmor=0},{returnArmor=2},"Đúng {count} lá tính điểm: lá còn lại trở về tay sau chấm điểm; nhận thêm {returnArmor} Giáp nếu lá đó còn sống.")
add("heart",3,"Nhịp Thở Thứ Ba","score","third_draw",{play=3,draw=1,armor=3},{draw=1,armor=1},"Lượt đánh thứ {play} trong trận: rút {draw} lá, nhận {armor} Giáp.")
add("heart",4,"Bốn Mạch","score","suits_armor",{suits=4,armor=8},{armor=2},"Đủ {suits} chất tính điểm: nhận {armor} Giáp.")
add("heart",5,"Giữ Người Ở Lại","score","return_lowest",{count=5,returns=1,returnArmor=0},{returns=1,returnArmor=1},"Đúng {count} lá tính điểm: tối đa {returns} lá cấp khả năng thấp nhất trở về tay; nhận {returnArmor} Giáp mỗi lá còn sống trở về.")
add("heart",6,"Tiết Chế","round_end","discard_armor",{discards=1,armor=6},{armor=2},"Cuối vòng: đổi tối đa {discards} lượt bỏ bài còn dư thành {armor} Giáp mỗi lượt.")
add("heart",7,"Ví Cứu Mệnh","damage","guard",{threshold=7,cost=1,block=7},{block=2},"Có ít nhất {threshold} Vàng: lần đầu nhận sát thương mỗi vòng trả {cost} Vàng, chặn {block} sát thương.")
add("heart",8,"Hộ Linh","hand_start","spn_armor",{armor=1},{armor=1},"Đầu mỗi tay, khi lá này trên tay: nhận {armor} Giáp mỗi SPN đang trang bị.")
add("heart",9,"Hành Trang Đầy","held","full_consumables",{capacity=1},{capacity=1},"Khi giữ và ô Tiêu Hao đầy: kích thước tay +{capacity}.")
add("heart",10,"Trưởng Thành","upgraded","growth",{capacity=1},{capacity=1},"Lần đầu được nâng cấp khả năng trong trận: kích thước tay +{capacity} đến hết trận.")
add("heart",11,"Phản Chiếu","held","copy_held",{range=1},{range=1},"Khi giữ: sao chép hiệu ứng GIỮ của tối đa {range} lá ngay bên trái theo thứ tự hiển thị; không sao chép J.")
add("heart",12,"Tích Tâm","hand_end","heart_store",{gain=1,healPercent=2,maxStacks=3},{healPercent=0.5,maxStacks={every=2,amount=1}},"Mỗi tay giữ không đánh: +{gain} Tâm (tối đa {maxStacks}). Khi chơi: hồi {healPercent}% HP tối đa mỗi Tâm.")
add("heart",13,"Di Nguyện","destroyed","death_heal",{healPercent=25,armor=10},{healPercent=5,armor=2},"Khi tiêu hủy: hồi {healPercent}% HP tối đa, nhận {armor} Giáp.")
add("diamond",14,"Tay Đầy Túi Đầy","hand_start","full_gold",{gold=1},{gold=1},"Lần đầu mỗi vòng bắt đầu tay đầy và có lá này trên tay: +{gold} Vàng.")
add("diamond",2,"Giao Dịch Đôi","score","pair_gold",{count=2,gold=1},{gold=1},"Đúng {count} lá tính điểm: +{gold} Vàng.")
add("diamond",3,"Lần Ba Có Lãi","score","third_gold",{play=3,gold=3},{gold=1},"Lượt đánh thứ {play} trong trận: +{gold} Vàng.")
add("diamond",4,"Đa Dạng Hóa","score","suits_gold",{suits=4,gold=2},{gold=1},"Đủ {suits} chất tính điểm: +{gold} Vàng.")
add("diamond",5,"Đầu Tư Năm Lá","score","invest_lowest",{count=5,levels=1},{levels=1},"Đúng {count} lá tính điểm: lá cấp khả năng thấp nhất +{levels} cấp đến hết trận.")
add("diamond",6,"Tiền Dư","round_end","discard_gold",{gold=1,maxGold=2},{maxGold=1},"Cuối vòng: +{gold} Vàng mỗi lượt bỏ bài dư, tối đa {maxGold} Vàng (tính trước khi Tiết Chế đổi lượt).")
add("diamond",7,"Lãi Suất","combat_win","interest",{divisor=7,gold=1,maxGold=3},{maxGold=1},"Sau trận: mỗi {divisor} Vàng nhận thêm {gold} Vàng, tối đa {maxGold}.")
add("diamond",8,"Hoa Hồng SPN","spn","commission",{required=3,gold=1},{gold=1},"{required} SPN khác nhau kích hoạt cùng tay: +{gold} Vàng, một lần mỗi tay.")
add("diamond",9,"Hoàn Tiền","consumable","refund",{gold=1},{gold=1},"Khi lá này trên tay: tiêu hao đầu tiên dùng mỗi tay hoàn {gold} Vàng.")
add("diamond",10,"Đầu Tư Nâng Cấp","choice","paid_invest",{cost=2,levels=1},{levels=1},"Khi tính điểm, có thể trả {cost} Vàng: lá tính điểm cấp thấp nhất +{levels} cấp đến hết trận.")
add("diamond",11,"Sao Kê","score","copy_diamond",{copies=1},{copies=1},"Sao chép {copies} lần khả năng lá Rô vừa kích hoạt trước đó theo thứ tự tính điểm; không sao chép J.")
add("diamond",12,"Gửi Tiết Kiệm","hand_end","gold_store",{gain=1,maxStacks=3},{maxStacks=1},"Mỗi tay giữ không đánh: tích {gain} Vàng, tối đa {maxStacks}. Khi chơi: nhận Vàng tích.")
add("diamond",13,"Di Sản","destroyed","death_gold",{gold=8,levels=1},{gold=2,levels=1},"Khi tiêu hủy: +{gold} Vàng; lá Rô còn lại cấp thấp nhất +{levels} cấp đến hết trận.")
add("club",14,"Tràn Nhịp","score","full_repeat",{repeats=1},{repeats=1},"Đánh khi tay đầy: lá tính điểm đầu tiên tái kích hoạt {repeats} lần.")
add("club",2,"Song Kích","score","pair_repeat",{repeats=1},{repeats=1},"Đôi chứa lá này: lá còn lại trong Đôi tái kích hoạt {repeats} lần.")
add("club",3,"Nhịp Ba","score","third_repeat",{play=3,repeats=1},{repeats=1},"Lượt đánh thứ {play}: lá tính điểm cuối cùng tái kích hoạt {repeats} lần.")
add("club",4,"Tứ Hợp","score","suits_repeat",{suits=4,repeats=1},{repeats=1},"Đủ {suits} chất tính điểm: lá đầu tiên mỗi chất tái kích hoạt {repeats} lần.")
add("club",5,"Đầu Cuối Tương Ứng","score","ends_repeat",{count=5,repeats=1},{repeats=1},"Đúng {count} lá tính điểm: lá đầu và cuối tái kích hoạt {repeats} lần.")
add("club",6,"Mồi Nhịp","discard","prime_repeat",{repeats=1},{repeats=1},"Khi bỏ: lá tính điểm đầu tiên tay kế tiếp tái kích hoạt {repeats} lần.")
add("club",7,"Mua Nhịp","choice","paid_repeat",{threshold=7,cost=2,repeats=1},{repeats=1},"Có ít nhất {threshold} Vàng: khi tính điểm, có thể trả {cost} Vàng để tự tái kích hoạt {repeats} lần.")
add("club",8,"Dội SPN","spn","spn_repeat",{repeats=1},{repeats=1},"Khi lá này tham gia tay (giữ hoặc chơi): SPN đầu tiên kích hoạt tái kích hoạt {repeats} lần, một lần mỗi tay.")
add("club",9,"Dư Âm Tiêu Hao","consumable","cons_repeat",{repeats=1},{repeats=1},"Khi giữ, dùng tiêu hao: lá tính điểm kế tiếp tái kích hoạt {repeats} lần.")
add("club",10,"Theo Kịp","score","higher_repeat",{repeats=1},{repeats=1},"Có lá cấp khả năng cao hơn trong tay tính điểm: tự tái kích hoạt {repeats} lần.")
add("club",11,"Bắt Chước","score","copy_previous",{copies=1},{copies=1},"Lặp {copies} lần khả năng lá tính điểm ngay trước (thứ tự hiển thị); không sao chép J.")
add("club",12,"Đánh Trượt Có Chủ Ý","not_scored","miss_repeat",{repeats=2},{repeats=1},"Chơi nhưng không tính điểm: lá tính điểm kế tiếp tái kích hoạt {repeats} lần.")
add("club",13,"Tiếng Vọng Cuối","destroyed","death_repeat",{repeats=1},{repeats=1},"Khi tiêu hủy: mọi lá đã tính điểm trong tay đó tái kích hoạt {repeats} lần (không lặp tiêu hủy).")
add("spade",14,"Đốt Đường Lui","choice","burn_refill",{duration=1},{duration=1},"Khi chơi, có thể tiêu hủy lá này: rút đầy tay và vô hiệu Nội Tại Boss {duration} tay, bắt đầu ngay tay hiện tại.")
add("spade",2,"Một Mất Một Còn","choice","pair_sacrifice",{levels=1},{levels=1},"Đôi chứa lá này: có thể chọn một lá trong Đôi để tiêu hủy, lá còn lại +{levels} cấp khả năng lâu dài.")
add("spade",3,"Tam Phong Ấn","score","third_cancel",{play=3,cancels=1},{cancels=1},"Lượt đánh thứ {play}: hủy {cancels} kỹ năng chủ động kế tiếp của Boss.")
add("spade",4,"Bốn Dấu Ấn","before_score","suits_disable",{suits=4,duration=1},{duration=1},"Đủ {suits} chất tính điểm: vô hiệu Nội Tại Boss {duration} tay từ tay hiện tại.")
add("spade",5,"Hiến Tế Thứ Năm","choice","five_sacrifice",{count=5,hands=1},{hands=1},"Đúng {count} lá tính điểm: có thể chọn một lá để tiêu hủy sau chấm điểm, nhận {hands} lượt đánh.")
add("spade",6,"Trì Hoãn","discard","delay",{duration=1},{duration=1},"Khi bỏ: hành động kế tiếp của Boss lùi {duration} tay.")
add("spade",7,"Hối Lộ Bóng Tối","choice","bribe",{cost=7,duration=2},{duration=1},"Một lần mỗi trận, khi chơi: có thể trả {cost} Vàng, vô hiệu Nội Tại Boss {duration} tay.")
add("spade",8,"Phong Ấn SPN","choice","burn_lock",{required=3,duration=1},{duration=1},"Có ít nhất {required} SPN, khi chơi: có thể tiêu hủy lá này để khóa Nội Tại và Chủ Động Boss {duration} tay.")
add("spade",9,"Vật Tế","choice","consume_cancel",{cancels=1},{cancels=1},"Khi giữ, trước đánh: có thể chọn một tiêu hao để tiêu hủy, hủy {cancels} kỹ năng chủ động kế tiếp của Boss.")
add("spade",10,"Trao Đổi Bậc","choice","transfer",{costLevels=1,levels=2},{levels=1},"Khi tính điểm, có thể hạ {costLevels} cấp khả năng lâu dài của lá này: một lá tính điểm khác +{levels} cấp đến hết trận. Cần đủ cấp để trả.")
add("spade",11,"Hồn Kẻ Đã Mất","score","copy_destroyed",{copies=1},{copies=1},"Sao chép {copies} lần khả năng lá gần nhất bị tiêu hủy trong trận; không sao chép J hay chuỗi tự lặp.")
add("spade",12,"Đánh Sai Có Chủ Đích","not_scored","miss_cancel",{cancels=1},{cancels=1},"Chơi nhưng không tính điểm: hủy {cancels} kỹ năng chủ động kế tiếp của Boss.")
add("spade",13,"Đoạn Tuyệt","destroyed","death_lock",{skip=1,duration=1},{duration=1},"Khi tiêu hủy: Boss bỏ qua {skip} hành động kế tiếp và mất Nội Tại {duration} tay tiếp theo.")
return Data

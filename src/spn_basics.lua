local B={entries={
    {"spirit_life_bloom","Mạch Sinh","addHealHp",2,"Mỗi tay tính điểm: hồi {value} HP cho mỗi quân bài còn cầm trên tay, không vượt máu tối đa."},
    {"spirit_coin_wisp","Linh Kim","addGold",2,"Mỗi tay tính điểm: +{value} Vàng cho mỗi lá đã chơi, kể cả lá không ghi điểm."},
    {"spirit_fleet_wind","Linh Phong","addAttackSpeed",2,"Mọi lá đang cầm nhận +{value} Tốc đánh khi SPN hoạt động. Lá vừa chơi giữ thưởng cho đòn đó; không tăng vĩnh viễn."},
    {"spirit_guardian_shell","Linh Giáp","addArmor",5,"Mỗi lượt giao chiến: +{value} Giáp trước đòn của bạn; nếu địch đánh trước, thay bằng +{double} Giáp trước đòn địch. Chỉ nhận một lần/lượt."},
}}
local D
-- Keep battle context outside cards so clones/saves cannot capture the entire game.
B.cardGames=setmetatable({},{__mode="k"})
function B.register(deities)
    D=deities
    for _,row in ipairs(B.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            trigger=row[3]=="addAttackSpeed" and "held" or row[3]=="addArmor" and "initiative" or "hand",
            lore="Một hộ linh giản dị đồng hành cùng người viễn chinh trên lục địa."}
        if entry.id=="spirit_life_bloom" then
            entry.onHandScored=function(hand,context)
                local played={}
                for _,group in ipairs({hand.scoringCards or {},hand.unscoredCards or {}}) do
                    for _,card in ipairs(group) do played[card.id or card]=true end
                end
                local count=0
                for _,card in ipairs(context.unplayedCards or context.hand or context.gameState and context.gameState.hand or {}) do
                    if not card.destroyed and not played[card.id or card] then count=count+1 end
                end
                return {addHealHp=entry.values.value*count,fixedMessage=true,message="MẠCH SINH · HỒI MÁU THEO LÁ CÒN CẦM"}
            end
        elseif entry.id=="spirit_coin_wisp" then
            entry.onHandScored=function(hand)
                return {addGold=entry.values.value*(#(hand.scoringCards or {})+#(hand.unscoredCards or {})),fixedMessage=true,message="LINH KIM · VÀNG THEO LÁ ĐÃ CHƠI"}
            end
        end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{double}",tostring(row[4]*2));entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
function B.bind(game,cards)
    for _,card in ipairs(cards or game.hand or {}) do B.cardGames[card]=game end
end
function B.speed(game)
    if not game then return 0 end
    D=D or require("src.deities")
    local speed=0
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            local source,count=D.resolveDeity(game.deities,slot,game)
            if source and source.id=="spirit_fleet_wind" then
                speed=speed+D.scaleEffect(source,{addAttackSpeed=2}).addAttackSpeed*count
            end
        end
    end
    return speed
end
function B.armor(game,enemyFirst)
    if game.spnBasicArmorGranted then return end
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source)
                if source.id=="spirit_guardian_shell" then
                    local gain=D.scaleEffect(source,{addArmor=enemyFirst and 10 or 5}).addArmor
                    game.playerArmor=math.min(require("config.card_ability_data").armorCap,(game.playerArmor or game.playerShield or 0)+gain)
                    game.playerShield=game.playerArmor
                    game.spnFeedback=game.spnFeedback or {}
                    game.spnFeedback[#game.spnFeedback+1]={deity=game.deities[slot],slot=slot,text="LINH GIÁP · +"..gain.." GIÁP"}
                end
            end)
        end
    end
    game.spnBasicArmorGranted=true
end
return B

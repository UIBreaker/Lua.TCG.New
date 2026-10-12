local V={entries={
    {"spirit_galefang","Phong Nha","addChips",4,"+{value} Sát thương mỗi điểm tốc đánh trung bình của toàn bộ lá đã chơi, gồm trang bị và thưởng tốc kỹ năng."},
    {"spirit_thunderpulse","Mạch Lôi","addMult",1,"+{value} Cường hóa mỗi điểm tốc đánh trung bình của toàn bộ lá đã chơi, gồm trang bị và thưởng tốc kỹ năng."},
    {"spirit_slow_colossus","Cự Linh Trễ Nhịp","xChips",1,"Tốc đánh trung bình thấp hơn mục tiêu: ×{factor} Sát thương và đòn đánh không thể hụt."},
    {"spirit_twinbeat","Song Nhịp","xMult",1,"Chơi đúng 2 lá có tốc đánh cá nhân bằng nhau: ×{factor} Cường hóa tại ô này. Tính cả trang bị và tăng tốc cá nhân."},
    {"spirit_afterstorm","Dư Chấn Tàn Quang","xChips",4,"Chậm hơn mục tiêu: ×{factor} Sát thương và gây sát thương lên toàn bộ quái. Nếu đánh hụt: các lá vừa ghi điểm nhận +2 Tốc đánh vĩnh viễn."},
    {"spirit_last_sun","Mặt Trời Cuối","xMult",4,"Lượt đánh cuối cùng: ×{factor} Cường hóa."},
}}
local Deck=require("src.deck")
local function played(hand)
    local cards={};for _,c in ipairs(hand.scoringCards or {}) do cards[#cards+1]=c end
    for _,c in ipairs(hand.unscoredCards or {}) do cards[#cards+1]=c end
    return cards
end
function V.speed(hand,context)
    context=context or {}
    if context.playerAttackSpeed~=nil then return math.max(0,math.min(999,context.playerAttackSpeed)) end
    local game=context.gameState;local info=hand
    if game and game.abilityHand and not game.abilityHand.finished and not context.preview then info=nil end
    return require("src.combat").getAverageAttackSpeed(played(hand),game,info)
end
local effects={
    spirit_galefang=function(hand,context,value) return {addChips=value*V.speed(hand,context),message="PHONG NHA · TỐC THÀNH SÁT THƯƠNG"} end,
    spirit_thunderpulse=function(hand,context,value) return {addMult=value*V.speed(hand,context),message="MẠCH LÔI · TỐC THÀNH CƯỜNG HÓA"} end,
    spirit_slow_colossus=function(hand,context,value)
        local target=context.monster or context.gameState and context.gameState.monster
        if target and V.speed(hand,context)<require("src.enemy_abilities").speed(target) then return {xChips=1+value,guaranteeHit=true,message="TRỄ NHỊP · NHÂN SÁT THƯƠNG · CHẮC TRÚNG"} end
    end,
    spirit_twinbeat=function(hand,context,value)
        local cards=played(hand)
        if #cards==2 and math.abs(Deck.peekCardAttackSpeed(cards[1])-Deck.peekCardAttackSpeed(cards[2]))<0.000001 then
            return {xMult=1+value,message="ĐỒNG TỐC · NHÂN CƯỜNG HÓA"}
        end
    end,
    spirit_afterstorm=function(hand,context,value)
        local target=context.monster or context.gameState and context.gameState.monster
        if target and V.speed(hand,context)<require("src.enemy_abilities").speed(target) then
            return {xChips=1+value,afterstorm=true,afterstormCards=hand.scoringCards,message="TÀN QUANG · LAN SÁT THƯƠNG"}
        end
    end,
    spirit_last_sun=function(hand,context,value)
        local game=context.gameState or context
        local remaining=context.handsAfterPlay
        if remaining==nil then remaining=math.max(0,(game.handsRemaining or 1)-1) end
        if remaining==0 then return {xMult=1+value,message="MẶT TRỜI CUỐI · NHÂN CƯỜNG HÓA"} end
    end,
}
function V.register(deities)
    for _,row in ipairs(V.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],
            trigger="hand",rarity="common",cost=4,lore="Nhịp chiến đấu trên lục địa có thể hóa thành sức mạnh, hoặc một lần bùng nổ cuối cùng."}
        entry.onHandScored=function(hand,context) return effects[entry.id](hand or {},context or {},entry.values.value) end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4]));entry.baseDesc=entry.desc
        deities.CATALOG[entry.id]=entry
    end
end
return V

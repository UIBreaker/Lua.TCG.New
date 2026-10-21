local T={entries={
    {"spirit_left_refrain","Hồi Âm Tả Cực","copyActivations",2,"SPN đang chiếm ô ngoài cùng bên trái tái kích hoạt thêm {value} lần, ngoài lần gốc; dùng cấp và trạng thái của chính lá nguồn. Nguồn/tái kích hoạt bị khóa thì không tác dụng. Không tự kích hoạt; tổng tối đa 128 lần/sự kiện."},
    {"spirit_wind_thief","Đoạt Phong U Linh","addStolenSpeed",2,"Mỗi tay đánh: cướp tối đa {value} Tốc đánh từ địch đang chọn (địch còn ít nhất 1 Tốc); mỗi quân đã chơi nhận lượng cướp đó trong trận. Bao gồm quân không tính điểm; một lần mỗi tay, không lặp theo tái kích hoạt quân."},
    {"spirit_right_offering","Hữu Tế Tham Linh","addOfferingMult",0.5,"Mỗi tay ghi điểm: tiêu hủy SPN ngay bên phải nếu ô đó không bị khóa; tích vĩnh viễn +{value} vào hệ số Cường hóa của lá này. Hệ số = 1 + tổng đã tích, có hiệu lực ngay. Tiến hóa tăng lượng tích cho lần hiến tế sau."},
}}
local D
local function notice(game,source,slot,text)
    game.spnFeedback=game.spnFeedback or {};game.spnFeedback[#game.spnFeedback+1]={deity=source,slot=slot,text=text}
end
function T.register(deities)
    D=deities
    for _,row in ipairs(T.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            trigger=row[1]=="spirit_left_refrain" and "repeat_spn" or "hand",lore="Dị linh điều khiển tiếng vọng, đoạt nhịp sống hoặc đổi đồng loại lấy sức mạnh."}
        if entry.id=="spirit_left_refrain" then entry.integerEffect=true end
        if entry.id=="spirit_right_offering" then entry.onHandScored=function() return {offering=true,fixedMessage=true,message="HỮU TẾ · HỆ SỐ TÍCH LŨY"} end end
        entry.desc=row[5]:gsub("{value}",tostring(row[4]));entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
    end
end
function T.beginHand(game,played)
    D=D or require("src.deities")
    local enemy=game.monster
    if not enemy or enemy.hp<=0 then return end
    local cards,seen={},{}
    for _,card in ipairs(played or {}) do local id=card.id or card
        if not card.destroyed and not seen[id] then seen[id]=true;cards[#cards+1]=card end
    end
    if #cards==0 then return end
    game.spnCombat=game.spnCombat or {}
    for slot=1,D.getMaxSlots(game) do
        local physical=game.deities and game.deities[slot]
        if physical and not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source)
                if source.id~="spirit_wind_thief" then return end
                local amount=math.min(D.scaleEffect(source,{addStolenSpeed=2}).addStolenSpeed,math.max(0,require("src.enemy_abilities").speed(enemy)-1))
                if amount<=0 then return end
                enemy.spnStolenSpeed=(enemy.spnStolenSpeed or 0)+amount
                local memory=game.spnCombat[physical] or {};game.spnCombat[physical]=memory;memory.stolenSpeed=memory.stolenSpeed or {}
                for _,card in ipairs(cards) do
                    require("src.deck").applyTemporaryAttackSpeedBonus(card,amount)
                    memory.stolenSpeed[card.id or card]=(memory.stolenSpeed[card.id or card] or 0)+amount
                end
                notice(game,physical,slot,"CƯỚP "..amount.." TỐC · "..#cards.." QUÂN")
            end)
        end
    end
end
function T.destroyed(game,physical)
    local memory=game.spnCombat and game.spnCombat[physical]
    if not memory or not memory.stolenSpeed or memory.stolenClaimed then return end
    memory.stolenClaimed=true
    for id,amount in pairs(memory.stolenSpeed) do
        local card
        for _,pile in ipairs({game.persistentDeck or {},game.hand or {},game.deck or {},game.discardPile or {}}) do
            for _,c in ipairs(pile) do if (c.id or c)==id and not c.destroyed then card=c;break end end
            if card then break end
        end
        if card then require("src.chest_expansion").sync(game,card,function(c)
            c.temporarySpeedBonus=math.max(0,(c.temporarySpeedBonus or 0)-amount)
            require("src.deck").applyAttackSpeedBonus(c,amount)
        end) end
    end
    notice(game,physical,0,"TỐC ĐOẠT · ĐÃ KẾT TINH VĨNH VIỄN")
end
function T.scored(game,slot,source,result)
    D=D or require("src.deities")
    local growth=source.spnGrowth or {};local victim=game.deities and game.deities[slot+1]
    if victim and victim~=game.deities[slot] and not require("src.boss_abilities").isSlotLocked(game,"spn",slot+1) then
        local gain=D.scaleEffect(source,{addOfferingMult=.5}).addOfferingMult
        if D.destroyDeity(game,slot+1,true,nil,"HIẾN TẾ bởi "..source.name.." · đổi lấy hệ số Cường hóa") then
            growth.offeringMult=(growth.offeringMult or 0)+gain;source.spnGrowth=growth
            notice(game,source,slot,"HIẾN TẾ "..victim.name.." · +"..gain.." HỆ SỐ")
        end
    end
    result.xMult=1+(growth.offeringMult or 0)
    return result
end
return T

local S={entries={
    {"spirit_primeval_product","Cổ Linh Bồi Tụ","addChips",2,"Mỗi lá đã chơi thêm 1 tầng vĩnh viễn trong chuyến đi; mỗi tầng +{value} Sát thương. Tính cả lá không ghi điểm."},
    {"spirit_parity","Lưỡng Cực","xMult",0.04,"Mỗi tay tích 1 điện; đổi ưu thế chẵn/lẻ so với tay trước thêm 1 điện. Mỗi điện tăng hệ số Cường hóa thêm {value}. Điện giữ suốt chuyến đi; hòa chẵn/lẻ không đổi cực."},
    {"spirit_extremes","Vết Nứt Vô Cực","addChips",1,"Mỗi tay thêm 5 vết nứt; mỗi HP thực mất do đòn quái thêm 1 vết. Mỗi vết thêm {value} Sát thương tính điểm; mỗi 100 vết thêm 1 Cường hóa. Giữ suốt chuyến đi."},
    {"spirit_hour_product","Đồng Hồ Vô Tận","addMult",2,"Mỗi tay tích 1 hạt cát suốt chuyến đi. Mỗi 4 hạt: thêm 1 nhịp lực và hồi đúng 1 lượt đánh. Mỗi nhịp +{value} Cường hóa; nhịp không tiêu hao."},
    {"spirit_number_grave","Mộ Chữ Số","addFlatDamage",6,"Chôn tối đa 15 Giáp hiện tại của mục tiêu mỗi tay; mỗi Giáp bị chôn thêm {value} sát thương cố định vào AURA. Giáp thực sự bị lấy đi."},
    {"spirit_reverse_stair","Bậc Thang Ngược","xMult",0.25,"Tại ô này, hoán đổi toàn bộ Sát thương và Cường hóa đang có, rồi ×{factor} Cường hóa. Các SPN phía sau tính trên hai trục đã đảo."},
    {"spirit_three_moons","Nhịp Sao Rơi","addHealHp",1,"Chơi 1 lá: đốt Giáp đang có, hồi {value} HP mỗi Giáp. Chơi 3 lá: +{value} sát thương cố định mỗi HP thiếu. Chơi 5 lá: đổi 1 lượt bỏ để cả bầy quái ngủ 1 đòn. Tính cả lá không ghi điểm."},
    {"spirit_name_eater","Kẻ Ăn Tên","addRedirectPct",50,"Chơi đúng 2 lá, trả 2 Vàng: {value}% sát thương sau Giáp của đòn mục tiêu kế tiếp chuyển sang một quái khác còn sống. Có thể kết liễu; cần ít nhất 2 quái. Tối đa 100%; không ghi đè mặt nạ chưa dùng."},
    {"spirit_four_seasons","Cửa Bốn Mùa","addPortalPct",25,"Chơi đủ 4 chất, kể cả lá không ghi điểm: AURA đòn chính tăng {value}%, rồi chia đều cho mọi quái còn sống. Mỗi phần chịu phòng thủ riêng; nhiều cổng dùng cổng mạnh nhất."},
    {"spirit_missing_orbit","Quỹ Đạo Khuyết","addDebtGuard",20,"Còn ít nhất 2 lượt đánh và không mắc nợ: né tối đa {value} sát thương của đòn quái kế tiếp. Số né trở thành nợ, trừ nguyên số vào AURA tay sau; tay trả nợ không mở né mới."},
}}
local Deck=require("src.deck")
local Boss=require("src.boss_abilities")
local Group=require("src.enemy_group")
local D
S.byId={}
local function played(hand)
    local all={};for _,c in ipairs(hand.scoringCards or {}) do all[#all+1]=c end
    for _,c in ipairs(hand.unscoredCards or {}) do all[#all+1]=c end
    return all
end
local function state(game,owned) return game.spnCombat and game.spnCombat[owned] or {} end
local function visit(game,fn,locked)
    for slot=1,D.getMaxSlots(game) do
        local owned=game.deities and game.deities[slot]
        if owned and S.byId[owned.id] and not (locked and locked[slot]) and not Boss.isSlotLocked(game,"spn",slot) then
            fn(owned,slot,state(game,owned))
        end
    end
end
local effects={
    spirit_primeval_product=function(hand,game,memory,value,context,growth)
        local layers=(growth.layers or 0)+#played(hand)
        return {addChips=layers*value,nextSpnGrowth={layers=layers},fixedMessage=true,message="BỒI TỤ · "..layers.." TẦNG"}
    end,
    spirit_parity=function(hand,game,memory,value,context,growth)
        local balance=0
        for _,c in ipairs(played(hand)) do balance=balance+(c.rank%2==0 and 1 or -1) end
        local pole=balance>0 and "even" or balance<0 and "odd" or growth.pole
        local charge=(growth.charge or 0)+1+(balance~=0 and growth.pole and pole~=growth.pole and 1 or 0)
        return {xMult=1+value*charge,nextSpnGrowth={charge=charge,pole=pole},fixedMessage=true,message="LƯỠNG CỰC · "..charge.." ĐIỆN"}
    end,
    spirit_extremes=function(hand,game,memory,value,context,growth)
        local cracks=(growth.cracks or 0)+5
        return {addChips=cracks*value,addMult=math.floor(cracks/100),nextSpnGrowth={cracks=cracks},fixedMessage=true,message="VẾT NỨT · "..cracks}
    end,
    spirit_hour_product=function(hand,game,memory,value,context,growth)
        local sand=(growth.sand or 0)+1;local beats=math.floor(sand/4)
        return {addMult=beats*value,handRefund=sand%4==0 and 1 or 0,nextSpnGrowth={sand=sand},fixedMessage=true,message="CÁT · "..sand.." / NHỊP · "..beats}
    end,
    spirit_number_grave=function(hand,game,memory,value,context)
        local target=game.monster or {}
        local buried=math.min(15,math.max(0,context.enemyArmorAvailable or (target.creatureArmor or 0)+(target.armor or 0)))
        if buried>0 then return {armorDrain=buried,addFlatDamage=buried*value,nextSpnState={},message="CHÔN "..buried.." GIÁP"} end
    end,
    spirit_reverse_stair=function(hand,game,memory,value)
        return {swapAxes=true,xMult=1+value,message="ĐẢO SÁT THƯƠNG ↔ CƯỜNG HÓA"}
    end,
    spirit_three_moons=function(hand,game,memory,value,context)
        local count=#played(hand)
        if count==1 then
            local armor=context.playerArmorAvailable or game.playerArmor or 0
            if armor>0 then return {armorBurn=armor,addHealHp=armor*value,nextSpnState={},message="TRĂNG LAM · ĐỐT GIÁP HỒI HP"} end
        elseif count==3 then
            local missing=math.max(0,(game.maxPlayerHp or 100)-(game.playerHp or 100))
            return {addFlatDamage=missing*value,message="TRĂNG VÀNG · VẾT THƯƠNG THÀNH AURA"}
        elseif count==5 and (context.discardsAvailable or game.discardsRemaining or 0)>=1 then
            return {discardCost=1,sleepAll=true,nextSpnState={},message="TRĂNG LỤC · CẢ BẦY NGỦ 1 ĐÒN"}
        end
    end,
    spirit_name_eater=function(hand,game,memory,value,context)
        if #played(hand)==2 and (context.goldAvailable or game.gold or 0)>=2 and not context.enemyMaskPending
            and not (game.monster and game.monster.spnMask) and Group.alive(Group.members(game))>=2 then
            return {goldCost=2,addRedirectPct=value,nextSpnState={},message="MẶT NẠ · QUÁI ĐÁNH ĐỒNG ĐỘI"}
        end
    end,
    spirit_four_seasons=function(hand,game,memory,value)
        local seen,count={},0
        for _,c in ipairs(played(hand)) do
            local info=Deck.SUITS[c.suit];local suit=info and info.id
            if suit and not seen[suit] then seen[suit]=true;count=count+1 end
        end
        if count==4 then return {addPortalPct=value,nextSpnState={},message="MỞ CỔNG · CHIA AURA CHO CẢ BẦY"} end
    end,
    spirit_missing_orbit=function(hand,game,memory,value,context)
        if (memory.debt or 0)>0 then
            return {auraTax=memory.debt,nextSpnState={},message="TRẢ NỢ · -"..memory.debt.." AURA"}
        elseif (memory.ward or 0)==0 and (context.handsAvailable or game.handsRemaining or 0)>=2 then
            return {addDebtGuard=value,nextSpnState={},message="RỜI QUỸ ĐẠO · NÉ BẰNG AURA TƯƠNG LAI"}
        end
    end,
}
function S.register(deities)
    D=deities
    for i,row in ipairs(S.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],
            trigger="hand",rarity="common",cost=4,accumulationMechanic=i<=4,mechanicRevision=2,
            lore="Dị tượng không ban sức mạnh miễn phí: nó đổi quy luật cuộc chiến, và đòi bạn chơi theo quy luật ấy."}
        entry.onHandScored=function(hand,context,owned,slot)
            context=context or {};local game=context.gameState or context
            local instance=game.deities and game.deities[slot or 1] or owned or entry
            return effects[entry.id](hand or {},game,state(game,instance),entry.values.value,context,instance.spnGrowth or {})
        end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4]))
        entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry;S.byId[entry.id]=entry
    end
end
function S.describe(owned)
    local g=owned.spnGrowth or {}
    if owned.id=="spirit_primeval_product" then return "BỒI TỤ HIỆN TẠI · "..(g.layers or 0).." TẦNG"
    elseif owned.id=="spirit_parity" then return "ĐIỆN HIỆN TẠI · "..(g.charge or 0)
    elseif owned.id=="spirit_extremes" then return "VẾT NỨT HIỆN TẠI · "..(g.cracks or 0)
    elseif owned.id=="spirit_hour_product" then return "CÁT HIỆN TẠI · "..(g.sand or 0).." / NHỊP · "..math.floor((g.sand or 0)/4) end
end
function S.migrate(owned)
    local def=S.byId[owned.id];if not def then return end
    for _,key in ipairs({"name","stat","values","descriptionTemplate","baseDesc","trigger","accumulationMechanic","mechanicRevision"}) do owned[key]=def[key] end
    owned.productMechanic=nil;owned.desc=D.getDescription(owned)
end
function S.commit(game,slot,result)
    local owned=game.deities[slot]
    if result.nextSpnGrowth then owned.spnGrowth=result.nextSpnGrowth;owned.desc=D.getDescription(owned) end
    if (result.handRefund or 0)>0 then game.handsRemaining=(game.handsRemaining or 0)+result.handRefund end
    if result.armorDrain then
        local removed=math.min(result.armorDrain,game.monster.creatureArmor or 0)
        game.monster.creatureArmor=math.max(0,(game.monster.creatureArmor or 0)-removed)
        game.monster.armor=math.max(0,(game.monster.armor or 0)-(result.armorDrain-removed))
    end
    if result.armorBurn then game.playerArmor=math.max(0,(game.playerArmor or 0)-result.armorBurn);game.playerShield=game.playerArmor end
    if result.sleepAll then for _,m in ipairs(Group.members(game)) do if m.hp>0 then m.spnSleep=(m.spnSleep or 0)+1 end end end
    if result.goldCost then game.gold=math.max(0,(game.gold or 0)-result.goldCost) end
    if result.addRedirectPct then game.monster.spnMask={pct=math.min(100,result.addRedirectPct),deity=owned,slotIndex=slot} end
    local memory=state(game,owned)
    if result.addPortalPct then memory.portal=result.addPortalPct end
    if result.addDebtGuard then memory.ward=result.addDebtGuard end
end
function S.enemyDamage(game,damage)
    if damage<=0 then return end
    visit(game,function(owned)
        if owned.id=="spirit_extremes" then
            owned.spnGrowth={cracks=(owned.spnGrowth and owned.spnGrowth.cracks or 0)+damage}
            owned.desc=D.getDescription(owned)
        end
    end)
end
function S.guard(game,damage)
    visit(game,function(owned,slot,memory)
        if owned.id=="spirit_missing_orbit" and (memory.ward or 0)>0 then
            local avoided=math.min(damage,memory.ward);damage=damage-avoided
            memory.ward=nil;memory.debt=avoided
        end
    end)
    return damage
end
function S.redirect(game,monster,damage)
    local mask=monster.spnMask;if not mask then return damage end
    monster.spnMask=nil
    for _,other in ipairs(Group.members(game)) do
        if other~=monster and other.hp>0 then
            local redirected=math.floor(math.max(0,damage)*mask.pct/100)
            require("src.monster").takeDamage(other,redirected)
            game.spnFeedback=game.spnFeedback or {}
            game.spnFeedback[#game.spnFeedback+1]={deity=mask.deity,slot=mask.slotIndex,text="CHUYỂN "..redirected.." ST SANG QUÁI KHÁC"}
            return damage-redirected
        end
    end
    return damage
end
function S.route(game,aura,locked)
    local strongest,source,sourceSlot=0
    visit(game,function(owned,slot,memory)
        if (memory.portal or 0)>strongest then strongest=memory.portal;source=owned;sourceSlot=slot end
        memory.portal=nil
    end,locked)
    if strongest<=0 then return aura,{} end
    local members={};for _,m in ipairs(Group.members(game)) do if m.hp>0 then members[#members+1]=m end end
    if #members==0 then return aura,{} end
    local total=math.floor(math.max(0,aura)*(1+strongest/100));local share=math.floor(total/#members)
    local hits={}
    for _,m in ipairs(members) do if m~=game.monster then hits[#hits+1]={enemy=m,raw=share,deity=source,slotIndex=sourceSlot,portal=true} end end
    return total-share*(#members-1),hits
end
return S

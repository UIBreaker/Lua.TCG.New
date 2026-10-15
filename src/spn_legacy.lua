local Rng=require("src.rng")
local Boss=require("src.boss_abilities")
local L={}
local D
L.entries={
    {"spirit_legacy_cocoon","Kén Kế Thừa","bossCopies",1,
        "Khi hạ Boss: tự tiêu hủy, tạo {value} bản sao của 1 SPN khác đang giữ ngẫu nhiên, giữ nâng cấp và vượt giới hạn ô. Mỗi cấp thêm 1 bản sao."},
    {"spirit_meteor_solitude","Độc Kích Thiên Thạch","addChips",1000,
        "Khi hoạt động, chỉ được đánh 1 lá mỗi tay. Tay đúng 1 lá: +{value} Sát thương. Mỗi cấp tiến hóa nhân đôi Sát thương này."},
}
local function clone(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local copy={};seen[value]=copy
    for k,v in pairs(value) do copy[k]=clone(v,seen) end
    return copy
end
function L.register(deities)
    D=deities
    for _,row in ipairs(L.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            lore="Một dị tượng của lục địa đặt toàn bộ số phận vào một khoảnh khắc."}
        entry.desc=row[5]:gsub("{value}",tostring(row[4]));entry.baseDesc=entry.desc
        if entry.id=="spirit_legacy_cocoon" then entry.trigger="boss_kill";entry.integerEffect=true
        else
            entry.trigger="hand";entry.doubleEvolution=true
            entry.onHandScored=function(hand)
                if #(hand.scoringCards or {})+#(hand.unscoredCards or {})==1 then
                    return {addChips=entry.values.value,fixedMessage=true,message="ĐỘC KÍCH · 1 LÁ DUY NHẤT"}
                end
            end
        end
        D.CATALOG[entry.id]=entry
    end
end
function L.canPlay(game,count)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        local owned=D.resolveDeity(game.deities,slot,game)
        if owned and owned.id=="spirit_meteor_solitude" and not Boss.isSlotLocked(game,"spn",slot) then return count==1 end
    end
    return true
end
function L.bossDefeated(game,enemy)
    if not enemy.isBoss or (enemy.hp or 1)>0 or enemy.spnLegacyClaimed then return 0 end
    enemy.spnLegacyClaimed=true
    D=D or require("src.deities")
    -- Only cocoons owned at this kill can hatch; newborn copies await another boss.
    local cocoons={}
    for slot=1,D.getMaxSlots(game) do
        local physical=game.deities and game.deities[slot]
        local owned=D.resolveDeity(game.deities,slot,game)
        if owned and owned.id=="spirit_legacy_cocoon" and not Boss.isSlotLocked(game,"spn",slot) then
            cocoons[#cocoons+1]={physical=physical,slot=slot}
        end
    end
    local created=0
    for _,cocoon in ipairs(cocoons) do
        if game.deities[cocoon.slot]==cocoon.physical then
        require("src.spn_mimic").each(game,game.deities,cocoon.slot,function(owned)
        cocoon.owned=owned
        local pool={}
        for slot=1,D.getMaxSlots(game) do
            local owned=game.deities and game.deities[slot]
            if owned and owned~=cocoon.owned then pool[#pool+1]=owned end
        end
        if #pool>0 and game.deities[cocoon.slot]==cocoon.owned then
            local source=pool[Rng.random(#pool)]
            local count=D.scaleEffect(cocoon.owned,{bossCopies=1}).bossCopies
            D.destroyDeity(game,cocoon.slot,true,cocoon.physical)
            if game.spnCombat then game.spnCombat[cocoon.owned]=nil end
            for i=1,count do
                local copy=clone(source);copy.desc=D.getDescription(copy)
                local slot=cocoon.slot
                if i>1 then slot=1;while game.deities[slot] do slot=slot+1 end end
                -- This reward bypasses the ordinary shop capacity check.
                game.deities[slot]=copy;created=created+1
            end
            game.spnFeedback=game.spnFeedback or {}
            game.spnFeedback[#game.spnFeedback+1]={deity=cocoon.owned,slot=cocoon.slot,text="KẾ THỪA · "..count.." × "..source.name}
        end
        end)
        end
    end
    return created
end
return L

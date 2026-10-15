local E={entries={
    {"spirit_phantom_heart","Huyễn Tâm Hộ Mệnh","addPhantomHp",1000,"Cấp {value} Máu ảo riêng cho lá này, đỡ sát thương địch trước Giáp. Không thể hồi; Giáp không bảo vệ Máu ảo. Giữ lượng đã tiêu qua trận và lưu game; cạn thì lá tự hủy. Tiến hóa tăng dung lượng, không xóa lượng đã tiêu."},
    {"spirit_first_frost","Tĩnh Đông Khai Trận","addFreezeTurns",1,"Lượt đánh đầu tiên mỗi trận: thay toàn bộ sát thương đòn đánh bằng đóng băng mục tiêu đang chọn, khiến nó mất {value} lượt hành động kế tiếp. Không cần trúng đòn. Mỗi cấp SPN thêm 1 lượt; tối đa 128."},
    {"spirit_cinder_confluence","Liệt Hồn Phân Quang","addAuraSplitPct",100,"Thay đòn chính: chia đều {value}% tổng AURA cho mọi địch còn sống. Mỗi địch bị đốt thêm {burn}% phần AURA nó nhận mỗi vòng, trong 2 vòng. Tiến hóa tăng cả phần AURA và tỷ lệ đốt."},
}}
local D
local function each(game,fn,locked)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        if not (locked and locked[slot]) and not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source) fn(source,slot) end,locked)
        end
    end
end
local function notice(game,deity,slot,text)
    game.spnFeedback=game.spnFeedback or {};game.spnFeedback[#game.spnFeedback+1]={deity=deity,slot=slot,text=text}
end
function E.register(deities)
    D=deities
    for _,row in ipairs(E.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,trigger="combat",
            lore="Dị tượng lục địa đổi sinh lực, băng giá hoặc ánh lửa thành một quy luật chiến đấu mới."}
        if entry.id=="spirit_first_frost" then entry.turnGrowth=true;entry.integerEffect=true end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{burn}","5");entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
    end
end
-- The spent ledger lives on the physical SPN, so moving, copying or saving cannot refill it.
function E.pools(game)
    D=D or require("src.deities")
    local pools={};local seen={}
    for slot=1,D.getMaxSlots(game) do
        local owner=game.deities and game.deities[slot]
        if owner and not seen[owner] and not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            seen[owner]=true
            local source,count=require("src.spn_mimic").resolve(game.deities,slot,game)
            if source and source.id=="spirit_phantom_heart" then
                local cap=math.min(1000000000,D.scaleEffect(source,{addPhantomHp=1000}).addPhantomHp*count)
                pools[#pools+1]={owner=owner,slot=slot,capacity=cap,remaining=math.max(0,cap-(owner.phantomSpent or 0))}
            end
        end
    end
    return pools
end
function E.remaining(game)
    local total,capacity=0,0;for _,p in ipairs(E.pools(game)) do total=total+p.remaining;capacity=capacity+p.capacity end;return total,capacity
end
function E.absorb(game,amount,inCombat)
    local remaining=math.max(0,amount or 0)
    for _,p in ipairs(E.pools(game)) do
        if remaining<=0 then break end
        local taken=math.min(remaining,p.remaining)
        p.owner.phantomSpent=(p.owner.phantomSpent or 0)+taken;remaining=remaining-taken
        if taken>0 then notice(game,p.owner,p.slot,"MÁU ẢO -"..string.format("%g",taken)) end
        if p.owner.phantomSpent>=p.capacity then
            D.destroyDeity(game,p.slot,inCombat~=false,p.owner)
            notice(game,p.owner,p.slot,"MÁU ẢO CẠN · TỰ HỦY")
        end
    end
    return remaining,math.max(0,(amount or 0)-remaining)
end
function E.openingPower(game)
    if game.spnOpeningAttackUsed then return 0 end
    local turns=0
    each(game,function(source)
        if source.id=="spirit_first_frost" then turns=math.min(128,turns+D.scaleEffect(source,{addFreezeTurns=1}).addFreezeTurns) end
    end)
    return turns
end
function E.opening(game)
    local turns=E.openingPower(game)
    game.spnOpeningAttackUsed=true
    if turns<=0 or not game.monster or game.monster.hp<=0 then return false end
    game.monster.spnFrozen=math.min(128,(game.monster.spnFrozen or 0)+turns)
    notice(game,{name="Tĩnh Đông Khai Trận"},0,"ĐÓNG BĂNG · MẤT "..turns.." LƯỢT · 0 ST")
    return true
end
function E.frozen(game,enemy)
    if (enemy.spnFrozen or 0)<=0 then return false end
    enemy.spnFrozen=enemy.spnFrozen-1;enemy.enemyFeedback="ĐÓNG BĂNG · MẤT LƯỢT"
    return true
end
function E.spread(game,aura,locked)
    local enemies={}
    for _,enemy in ipairs(require("src.enemy_group").members(game)) do if enemy.hp>0 then enemies[#enemies+1]=enemy end end
    if #enemies==0 then return end
    local hits,byEnemy={},{}
    each(game,function(source,slot)
        if source.id~="spirit_cinder_confluence" then return end
        local effect=D.scaleEffect(source,{addAuraSplitPct=100,addBurnPct=5})
        local share=math.max(0,aura)*effect.addAuraSplitPct/100/#enemies
        for _,enemy in ipairs(enemies) do
            local hit=byEnemy[enemy]
            if not hit then hit={enemy=enemy,raw=0,deity=source,slotIndex=slot,confluence=true};byEnemy[enemy]=hit;hits[#hits+1]=hit end
            hit.raw=hit.raw+share
            if share>0 then
                enemy.spnAuraBurns=enemy.spnAuraBurns or {}
                enemy.spnAuraBurns[#enemy.spnAuraBurns+1]={damage=share*effect.addBurnPct/100,turns=2}
            end
        end
    end,locked)
    return #hits>0 and hits or nil
end
function E.roundEnd(game)
    local dealt=0
    for _,enemy in ipairs(require("src.enemy_group").members(game)) do
        local burns=enemy.spnAuraBurns or {};local total=0
        for i=#burns,1,-1 do
            if enemy.hp>0 then total=total+require("src.monster").takeDamage(enemy,burns[i].damage,true) end
            burns[i].turns=burns[i].turns-1;if burns[i].turns<=0 then table.remove(burns,i) end
        end
        if total>0 then dealt=dealt+total;enemy.enemyFeedback="THIÊU ĐỐT -"..string.format("%g",total);notice(game,{name="Liệt Hồn Phân Quang"},0,enemy.enemyFeedback) end
    end
    if dealt>0 then
        require("src.soul_relics").reap(game)
        if require("src.combat").getOutcome(game)=="victory" then game.spnCombat=game.spnCombat or {};game.spnCombat.victoryPending=true end
    end
end
return E

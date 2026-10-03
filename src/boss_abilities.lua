-- Telegraphs and counters belong to the existing monster instance, not a second combat system.
local Boss = { config = { cooldown=2, taxThreshold=1, tax=1, debtDamage=1, debtCap=10,
    gateThreshold=5, gateAttackPerCard=1, activeDamage=3, armorDrain=6, heal=12,
    hookCount=2,gemPassiveHeal=40,executionThreshold=0.4,executionMultiplier=2,taxCardCost=1,taxCardHp=3,resist=0.2 } }
local function active(name, op, desc, amount)
    return { name=name, op=op, description=desc, amount=amount, cooldown=Boss.config.cooldown }
end
Boss.actives = {
    less_discard=active("Gai Trói", "discard", "Khóa 1 lượt bỏ bài tay kế tiếp (không hạ dưới 1).",1),
    the_water=active("Triều Dâng", "discard", "Khóa 1 lượt bỏ bài tay kế tiếp (không hạ dưới 1).",1),
    damage_resist=active("Nghiền Giáp", "armor", "Bào {amount} Giáp người chơi.",6),
    max_4_cards=active("Ép Quân", "hands", "Khóa 1 lượt đánh tay kế tiếp (không hạ dưới 1).",1),
    max_3_cards=active("Ép Quân", "hands", "Khóa 1 lượt đánh tay kế tiếp (không hạ dưới 1).",1),
    the_needle=active("Xuyên Tâm", "damage", "Gây {amount} sát thương (được Giáp và Ví Cứu Mệnh chặn).",3),
    the_hook=active("Móc Câu Ký Ức", "silence", "Khóa khả năng lá đã báo trước trong tay kế tiếp.",1),
    the_fish=active("Mù Sương", "face", "Úp mặt lá đã báo trước trong tay kế tiếp.",1),
    faceless=active("Mặt Nạ Câm", "silence", "Khóa khả năng lá đã báo trước trong tay kế tiếp.",1),
    the_arm=active("Bàn Tay Câm", "silence", "Khóa khả năng lá đã báo trước trong tay kế tiếp; không đổi rank/chất.",1),
    echo_knight=active("Dội Âm", "repeat_penalty", "Tay kế tiếp: lặp thế đánh vừa dùng sẽ mất {amount} Cường hóa.",2),
    taxman=active("Truy Thu", "gold", "Lấy tối đa {amount} Vàng, không tạo nợ HP.",2),
    gem_devourer=active("Nuốt Linh Lực", "heal", "Hồi {amount} HP; không xóa thêm trang bị.",12),
    executioner=active("Lưỡi Đao", "damage", "Gây {amount} sát thương (được Giáp chặn).",3),
    lock_royals=active("Câm Vương", "silence_royal", "Khóa khả năng một lá J/Q/K đã báo trước trong tay kế tiếp.",1),
    black_tax_collector=active("Tịch Thu", "tax_lock", "Luân phiên khóa ô Tiêu Hao / SPN số 1 trong tay kế tiếp; không xóa vật phẩm.",1),
    memory_eater=active("Xóa Dấu", "silence", "Khóa khả năng lá đã báo trước trong tay kế tiếp; vẫn tính điểm bình thường.",1),
    gatekeeper=active("Phong Tỏa", "gate_lock", "Luân phiên khóa 1 lượt bỏ / lượt đánh tay kế tiếp, không hạ dưới 1.",1),
}
for _, suit in ipairs({"aurelia","elaris","vharos","valoria"}) do
    Boss.actives["lock_"..suit]=active("Dấu Ấn Câm", "silence_suit", "Khóa khả năng lá thuộc chất áp chế đã báo trước trong tay kế tiếp.",1)
end
Boss.newDefinitions = {
    black_tax_collector={id="black_tax_collector",debuffId="black_tax_collector",name="KẺ THU THUẾ ĐEN",title="THUẾ ĐEN",
        color={0.95,0.75,0.25,1},desc="Cuối tay: lấy 1 Vàng nếu còn Vàng. Khi hết Vàng: +1 Nợ (tối đa 10); mỗi Nợ tăng 1 sát thương Tịch Thu."},
    memory_eater={id="memory_eater",debuffId="memory_eater",name="KẺ NUỐT KÝ ỨC",title="QUÊN LÃNG",
        color={0.65,0.4,0.95,1},desc="Lá đầu tiên tái kích hoạt mỗi tay bị Quên Lãng: từ lần tái kích hoạt tiếp theo, khả năng không chạy; điểm cơ bản vẫn chạy."},
    gatekeeper={id="gatekeeper",debuffId="gatekeeper",name="NGƯỜI GIỮ CỔNG",title="CỔNG HẸP",
        color={0.3,0.8,0.7,1},desc="Đầu tay có hơn 5 lá: mỗi lá dư tăng 1 tấn công trong tay đó. Không giảm kích thước tay."},
}
function Boss.attach(def)
    if def and not def.expeditionActive then def.active=Boss.actives[def.debuffId or def.id]; def.activeCooldown=def.active and def.active.cooldown end
    return def
end
function Boss.key(monster) return monster and monster.bossData and (monster.bossData.debuffId or monster.bossData.id) end
function Boss.state(monster)
    return monster and monster.isBoss and monster.bossState
end
function Boss.passiveEnabled(monster)
    local s=Boss.state(monster)
    return not monster or not monster.bossDebuffCleansed and (not s or s.passiveUntil < s.handIndex)
end
function Boss.start(game)
    local m=game.monster
    if not m or not m.isBoss then return end
    Boss.attach(m.bossData)
    m.bossState={handIndex=1,activeCountdown=1,activeState="telegraph",disabledPassiveTurns=0,
        passiveUntil=0,activeUntil=0,cancelNextActive=0,delayNextAction=0,skipNextAction=0,
        cycle=0,debt=0,forgotten={},baseLimits={hands=game.maxHands,discards=game.maxDiscards}}
end
function Boss.disable(game, turns, activeToo, nextHand)
    local s=Boss.state(game.monster); if not s then return end
    local offset=nextHand and 1 or 0
    s.passiveUntil=math.max(s.passiveUntil,s.handIndex+turns-1+offset)
    s.disabledPassiveTurns=math.max(0,s.passiveUntil-s.handIndex+1)
    if activeToo then s.activeUntil=math.max(s.activeUntil,s.handIndex+turns-1+offset) end
    -- Temporarily release opening resource/selection restrictions as well.
    local key=Boss.key(game.monster)
    if key=="the_needle" and not s.releasedHands then
        local delta=math.max(0,(game.maxHands or 1)-(game.turnHandLimit or 1))
        game.handsRemaining=(game.handsRemaining or 0)+delta;game.turnHandLimit=(game.turnHandLimit or 1)+delta;s.releasedHands=delta
    end
    if (key=="the_water" or key=="less_discard" or key=="max_4_cards") and not s.releasedDiscards then
        local delta=key=="the_water" and (game.maxDiscards or 0) or 1
        game.discardsRemaining=(game.discardsRemaining or 0)+delta;s.releasedDiscards=delta
    end
    if key=="max_3_cards" or key=="max_4_cards" then game.maxSelectableCards=nil end
    if key=="faceless" or key=="the_fish" then
        for _,c in ipairs(game.hand or {}) do c.faceDown=false end
    end
end
function Boss.counter(game, kind, amount)
    local s=Boss.state(game.monster); if not s then return end
    s[kind]=(s[kind] or 0)+(amount or 1)
end
local function targetCard(game, op)
    for _, c in ipairs(game.hand or {}) do
        local key=Boss.key(game.monster)
        if op~="silence_royal" or c.rank>=11 and c.rank<=13 then
            if op~="silence_suit" or c.suit==key:sub(6) then return c end
        end
    end
end
function Boss.handStart(game)
    local m=game.monster; local s=Boss.state(m); if not s then return end
    local a=m.bossData.active
    if Boss.passiveEnabled(m) then
        if s.releasedHands then
            game.handsRemaining=math.max(0,(game.handsRemaining or 0)-s.releasedHands)
            game.turnHandLimit=math.max(1,(game.turnHandLimit or 1)-s.releasedHands);s.releasedHands=nil
        end
        if s.releasedDiscards then game.discardsRemaining=math.max(0,(game.discardsRemaining or 0)-s.releasedDiscards);s.releasedDiscards=nil end
        if m.bossData.maxSelectedCards then game.maxSelectableCards=m.bossData.maxSelectedCards end
    end
    s.disabledPassiveTurns=math.max(0,s.passiveUntil-s.handIndex+1)
    s.forgotten={}; s.forgottenCard=nil; s.excess=0
    if Boss.key(m)=="gatekeeper" and Boss.passiveEnabled(m) then
        s.excess=math.max(0,#(game.hand or {})-Boss.config.gateThreshold)
    end
    if s.activeCountdown==1 and a then
        local c=targetCard(game,a.op)
        s.targetId=c and c.id; s.targetName=c and ((c.rankName or "")..(c.suitSymbol or "")) or "không có mục tiêu"
        s.telegraph=Boss.activeDescription(m)..((a.op:find("silence") or a.op=="face") and (" · Mục tiêu: "..s.targetName) or "")
    end
    if Boss.passiveEnabled(m) and (Boss.key(m)=="faceless" or Boss.key(m)=="the_fish") then
        for _,c in ipairs(game.hand or {}) do c.faceDown=true end
    end
end
function Boss.activeDescription(m)
    local s=Boss.state(m); local a=m and m.bossData and m.bossData.active
    if not a then return "" end
    local desc=a.description:gsub("{amount}",tostring(a.amount))
    if a.op=="tax_lock" then return "Khóa ô "..((s and s.cycle or 0)%2==0 and "Tiêu Hao" or "SPN").." số 1 tay kế tiếp; sát thương Nợ "..((s and s.debt or 0)*Boss.config.debtDamage).."." end
    if a.op=="gate_lock" then return "Khóa 1 lượt "..((s and s.cycle or 0)%2==0 and "bỏ bài" or "đánh").." tay kế tiếp; không hạ dưới 1." end
    return desc
end
function Boss.isSlotLocked(game, kind, slot)
    if not game.monster or (game.monster.hp or 0)<=0 then return false end
    local s=Boss.state(game.monster)
    return s and s.slotLock and s.slotLock.kind==kind and s.slotLock.slot==slot and s.slotLock.untilHand>=s.handIndex or false
end
function Boss.isAbilityDisabled(game, card)
    if not game or not game.monster or (game.monster.hp or 0)<=0 then return false end
    local s=Boss.state(game and game.monster)
    return s and card.abilityDisabledUntil and card.abilityDisabledUntil>=s.handIndex or false
end
function Boss.allowRetriggerAbility(game, card)
    local m=game.monster; local s=Boss.state(m)
    if not s or Boss.key(m)~="memory_eater" or not Boss.passiveEnabled(m) then return true end
    if not s.forgottenCard then s.forgottenCard=card.id; s.forgotten[card.id]=1; return true end
    if s.forgottenCard==card.id then s.forgotten[card.id]=(s.forgotten[card.id] or 1)+1; return false end
    return true
end
function Boss.beforeAttack(game)
    local s=Boss.state(game.monster)
    if not s then return true end
    if s.skipNextAction>0 then s.skipNextAction=s.skipNextAction-1; s.actionBlocked=true; s.feedback="HÀNH ĐỘNG BỊ BỎ QUA"; return false end
    if s.delayNextAction>0 then s.delayNextAction=s.delayNextAction-1; s.actionBlocked=true; s.feedback="TRÌ HOÃN +1 TAY"; return false end
    if s.activeUntil>=s.handIndex then s.actionBlocked=true; s.feedback="BOSS BỊ KHÓA"; return false end
    return true
end
local function applyActive(game,a,s)
    local m=game.monster; local op=a.op
    if op=="tax_lock" then
        s.slotLock={kind=s.cycle%2==0 and "consumable" or "spn",slot=1,untilHand=s.handIndex+1}
        s.pendingDamage=(s.pendingDamage or 0)+s.debt*Boss.config.debtDamage
    elseif op=="gate_lock" then
        s.resourceLock={kind=s.cycle%2==0 and "discards" or "hands",amount=a.amount,untilHand=s.handIndex+1}
    elseif op=="hands" or op=="discard" then
        s.resourceLock={kind=op=="hands" and "hands" or "discards",amount=a.amount,untilHand=s.handIndex+1}
    elseif op:find("silence") or op=="face" then
        for _,pile in ipairs({game.hand or {},game.deck or {},game.discardPile or {}}) do
            for _,c in ipairs(pile) do if c.id==s.targetId then
                if op=="face" then c.faceDown=true else c.abilityDisabledUntil=s.handIndex+1 end
            end end
        end
    elseif op=="armor" then game.playerArmor=math.max(0,(game.playerArmor or 0)-a.amount); game.playerShield=game.playerArmor
    elseif op=="gold" then game.gold=math.max(0,(game.gold or 0)-a.amount)
    elseif op=="heal" then m.hp=math.min(m.maxHp,m.hp+a.amount)
    elseif op=="damage" then s.pendingDamage=(s.pendingDamage or 0)+a.amount
    elseif op=="repeat_penalty" then s.repeatHand=game.lastPlayedHandId; s.repeatUntil=s.handIndex+1 end
    s.cycle=s.cycle+1
end
function Boss.handEnd(game)
    local m=game.monster; local s=Boss.state(m); if not s or (m.hp or 0)<=0 then return end
    if Boss.key(m)=="black_tax_collector" and Boss.passiveEnabled(m) then
        if (game.gold or 0)>=Boss.config.taxThreshold then game.gold=math.max(0,game.gold-Boss.config.tax)
        elseif (game.gold or 0)==0 then s.debt=math.min(Boss.config.debtCap,s.debt+1) end
    end
    if Boss.key(m)=="gem_devourer" and Boss.passiveEnabled(m) then
        local targets={}
        for _,c in ipairs(game.hand or {}) do if #(c.equipments or {})>0 then targets[#targets+1]=c end end
        if #targets>0 then
            local target=targets[require("src.rng").random(#targets)]
            local index=require("src.rng").random(#target.equipments)
            table.remove(target.equipments,index)
            for _,pc in ipairs(game.persistentDeck or {}) do if pc.id==target.id then table.remove(pc.equipments,index) end end
            m.hp=math.min(m.maxHp,m.hp+Boss.config.gemPassiveHeal)
        end
    end
    local a=m.bossData.active
    if a and not s.actionBlocked then
        if s.activeUntil>=s.handIndex then s.feedback="KỸ NĂNG BỊ KHÓA"
        else
            s.activeCountdown=s.activeCountdown-1
            if s.activeCountdown<=0 then
                if s.cancelNextActive>0 then s.cancelNextActive=s.cancelNextActive-1; s.feedback="KỸ NĂNG VÔ HIỆU"
                else applyActive(game,a,s); s.feedback=a.name end
                s.activeCountdown=a.cooldown+1
            end
        end
    end
    s.actionBlocked=nil; s.handIndex=s.handIndex+1
    s.activeState=s.activeCountdown==1 and "telegraph" or "cooldown"
    if s.resourceLock and s.resourceLock.untilHand>=s.handIndex then
        local key=s.resourceLock.kind=="hands" and "handsRemaining" or "discardsRemaining"
        game[key]=math.max(1,(game[key] or 1)-s.resourceLock.amount)
    end
end
function Boss.passiveDescription(m)
    local key=Boss.key(m);local c=Boss.config
    if key=="black_tax_collector" then return "Cuối tay: lấy tối đa "..c.tax.." Vàng nếu có ít nhất "..c.taxThreshold..". Hết Vàng: +1 Nợ (tối đa "..c.debtCap.."); mỗi Nợ thêm "..c.debtDamage.." sát thương Tịch Thu." end
    if key=="gatekeeper" then return "Đầu tay có hơn "..c.gateThreshold.." lá: mỗi lá dư tăng "..c.gateAttackPerCard.." tấn công trong tay đó; không giảm kích thước tay." end
    if key=="damage_resist" then return "Kháng "..(c.resist*100).."% mọi sát thương nhận vào." end
    if key=="taxman" then return "Mỗi lá tạo Aura trả "..c.taxCardCost.." Vàng; không đủ trả sẽ mất "..c.taxCardHp.." HP." end
    if key=="the_hook" then return "Mỗi khi chơi: bỏ ngẫu nhiên tối đa "..c.hookCount.." lá còn giữ trên tay; kích hoạt hiệu ứng Khi Bỏ." end
    if key=="gem_devourer" then return "Cuối tay: nuốt một ITM ngẫu nhiên từ lá đang giữ, hồi "..c.gemPassiveHeal.." HP nếu nuốt được." end
    if key=="executioner" then return "Khi người chơi dưới "..(c.executionThreshold*100).."% HP tối đa: đòn đánh ×"..c.executionMultiplier..", bỏ qua Giáp; không xóa Giáp." end
    return m and m.bossData and m.bossData.desc or ""
end
function Boss.onPlay(game)
    if Boss.key(game.monster)~="the_hook" or not Boss.passiveEnabled(game.monster) then return 0 end
    local count=math.min(Boss.config.hookCount,#(game.hand or {}));local cards={}
    for _=1,count do local c=table.remove(game.hand,require("src.rng").random(#game.hand));c.selected=false;game.discardPile[#game.discardPile+1]=c;cards[#cards+1]=c end
    require("src.card_abilities").discard(game,cards)
    return count
end
function Boss.afterScore(game,cards)
    if Boss.key(game.monster)~="the_arm" or not Boss.passiveEnabled(game.monster) then return false end
    local Deck=require("src.deck")
    for _,c in ipairs(cards or {}) do
        if not c.destroyed then
            if Deck.degradeCard(c)=="destroyed" then require("src.card_abilities").destroy(game,c)
            else
                c.baseRank=c.rank
                for _,pc in ipairs(game.persistentDeck or {}) do if pc.id==c.id then pc.baseRank=c.rank;pc.rank=c.rank;pc.rankName=c.rankName;pc.baseChips=c.baseChips;Deck.getCardAttackSpeed(pc) end end
            end
        end
    end
    return true
end
function Boss.describe(m)
    local s=Boss.state(m); if not s then return m and m.desc or "" end
    local active=m.bossData.active
    return "NỘI TẠI · "..(m.bossData.title or m.bossData.name).."\n"..Boss.passiveDescription(m)
        ..(not Boss.passiveEnabled(m) and ("\nVÔ HIỆU · "..math.max(0,s.passiveUntil-s.handIndex+1).." tay") or "")
        .."\nKỸ NĂNG · "..(active and active.name or "Không có").."\n"..Boss.activeDescription(m)
        .."\nSẼ DÙNG SAU: "..s.activeCountdown.." tay · "..(s.telegraph or "")
        ..(s.cancelNextActive>0 and "\nĐÃ PHONG ẤN KỸ NĂNG KẾ TIẾP" or "")
        ..(s.delayNextAction>0 and ("\nTRÌ HOÃN +"..s.delayNextAction.." tay") or "")
        ..(s.feedback and ("\n"..s.feedback) or "")
end
return Boss

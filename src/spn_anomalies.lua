local Boss=require("src.boss_abilities")
local A={}
local D
A.entries={
    {"spirit_afterimage","Dư Ảnh Ngày Mai","addAfterimagePct",35,"Từ đòn thứ hai: đánh thêm {value}% AURA đòn trước vào mục tiêu hiện tại.","attack"},
    {"spirit_reprisal","Gương Oán","addReflectPct",60,"Sau đòn quái: phản {value}% HP thực mất về kẻ đánh; không kết liễu.","damage"},
    {"spirit_last_pact","Giao Kèo Cuối","addReviveHp",5,"Một lần mỗi trận: chặn đòn chí tử, còn {value} HP.","damage"},
    {"spirit_soul_furnace","Lò Hồn","addFlatDamage",25,"Mỗi tay: đốt tối đa 3 Linh Hồn; mỗi hồn thêm {value} sát thương cố định vào AURA.","hand"},
    {"spirit_transmuter","Nghịch Luyện","addTransmutePct",10,"Tại ô này: chuyển {value}% Sát thương đang có sang Cường hóa (tối đa 90%).","hand"},
    {"spirit_archive","Thư Viện Mù","addDiscards",1,"Mỗi 3 kiểu tay khác nhau đánh trong trận: nhận 1 lá Tiến Hóa, rồi bắt đầu đếm lại.","hand"},
    {"spirit_borrowed_turn","Vay Khoảnh Khắc","addHands",0,"Một lần mỗi trận: chơi đúng 3 lá đều tính điểm, nhận Tốc Đánh Nhỏ áp dụng tốc đánh vĩnh viễn cho một lá.","hand"},
    {"spirit_dream_jailer","Cai Ngục Mộng","addArmor",4,"Lần đầu đánh mỗi quái: nếu quái sống, nó bỏ 1 đòn kế tiếp và bạn nhận +{value} Giáp.","attack"},
    {"spirit_abyss_feast","Nuốt Tàn Dư","addOverkillArmorPct",40,"Hạ quái bằng đòn chính: chuyển {value}% sát thương dư thành Giáp (tối đa 30).","attack"},
    {"spirit_zero_hour","Không Thời","xMult",1,"Chặn hoàn toàn một đòn quái: tích ×{factor} Cường hóa cho tay kế tiếp; không cộng dồn.","hand"},
}
local function peek(game,slot)
    local deity=game.deities and game.deities[slot]
    return game.spnCombat and game.spnCombat[deity] or {}
end
local function store(game,slot,state)
    -- State follows the owned instance when SPNs are reordered or duplicated.
    local deity=assert(game.deities and game.deities[slot])
    game.spnCombat=game.spnCombat or {};game.spnCombat[deity]=state
end
local function notice(game,deity,slot,text)
    game.spnFeedback=game.spnFeedback or {}
    game.spnFeedback[#game.spnFeedback+1]={deity=deity,slot=slot,text=text}
end
local function giveConsumable(game,reward)
    require("src.loadout").storeConsumable(game,reward)
end
function A.takeFeedback(game)
    local result=game.spnFeedback or {};game.spnFeedback={};return result
end
function A.showFeedback(game,anim)
    for _,event in ipairs(A.takeFeedback(game)) do
        table.insert(anim.floatingTexts,{text=event.deity.name.." · "..event.text,
            color={0.65,0.8,1},x=640,y=400-event.slot*20,alpha=2})
    end
end
local function active(game,visit,locked)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game) do
        local deity=game.deities and game.deities[slot]
        if deity and (not locked or not locked[slot]) and not Boss.isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(effective) visit(effective,slot,peek(game,slot)) end,locked)
        end
    end
end
local function value(deity)
    local def=D.CATALOG[deity.id]
    return D.scaleEffect(deity,{[def.stat]=def.values.value})[def.stat]
end
local handEffects={
    spirit_soul_furnace=function(hand,game,state,amount,context)
        local used=math.min(3,math.max(0,math.floor(context.soulsAvailable or game.souls or 0)))
        if used>0 then return {addFlatDamage=used*amount,soulCost=used} end
    end,
    spirit_transmuter=function(hand,game,state,amount)
        return {addTransmutePct=amount}
    end,
    spirit_archive=function(hand,game,state,amount)
        if not hand.type then return end
        local seen,count={},0
        for id in pairs(state.seen or {}) do seen[id]=true;count=count+1 end
        if seen[hand.type.id] then return end
        seen[hand.type.id]=true;count=count+1
        return {nextSpnState={seen=count>=3 and {} or seen},grantEvolution=count>=3,
            message=count>=3 and "THƯ VIỆN · NHẬN TIẾN HÓA" or nil}
    end,
    spirit_borrowed_turn=function(hand,game,state,amount,context)
        if not state.used and #(hand.scoringCards or {})==3 and #(hand.unscoredCards or {})==0 then
            return {grantPermanentSpeedSmall=true,nextSpnState={used=true}}
        end
    end,
    spirit_zero_hour=function(hand,game,state,amount)
        if state.charged then return {xMult=1+amount,nextSpnState={charged=false}} end
    end,
}
function A.register(deities)
    D=deities
    for _,row in ipairs(A.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],trigger=row[6],
            rarity="common",cost=4,lore="Dị tượng của lục địa: bẻ cong một quy luật, đòi lại một cái giá."}
        entry.integerEffect=entry.stat=="addHands" or entry.stat=="addDiscards"
        if handEffects[entry.id] then
            entry.onHandScored=function(hand,context,owned,slot)
                context=context or {};local game=context.gameState or context
                return handEffects[entry.id](hand or {},game,peek(game,slot or 1),entry.values.value,context)
            end
        end
        entry.desc=entry.descriptionTemplate:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4]))
        entry.baseDesc=entry.desc;D.CATALOG[entry.id]=entry
    end
end
-- Called only when scoring commits; callbacks and HUD previews stay read-only.
function A.commitHand(game,slot,result,preview)
    if result.nextSpnState then store(game,slot,result.nextSpnState) end
    if result.destroyEight and #(game.persistentDeck or {})>1 and require("src.card_abilities").destroy(game,result.destroyEight) then
        game.maxDiscards=(game.maxDiscards or 3)+1
        game.discardsRemaining=(game.discardsRemaining or 0)+1
        game.spnDiscardCap=(game.spnDiscardCap or game.maxDiscards-1)+1
    end
    if result.grantPermanentSpeedSmall then
        local reward=require("src.shop").healingItem("upper","cons_speed_small").consumable
        local power=result.grantPermanentSpeedSmallPower or 1
        if power>1 then reward.voidPower=power end
        reward.permanentSpeed=true
        reward.desc="Chọn một lá đang trên tay: +"..(3*power).." tốc đánh vĩnh viễn (tối đa 999)."
        giveConsumable(game,reward)
    end
    if result.grantEvolution then
        for _=1,result.grantEvolutionCount or 1 do giveConsumable(game,require("src.run_manager").createEvolutionCard()) end
    end
    if result.guaranteeHit or result.afterstorm then
        game.spnAttack=game.spnAttack or {afterstorms={}}
        if result.guaranteeHit then game.spnAttack.guaranteeHit=true end
        if result.afterstorm then
            game.spnAttack.afterstorms[#game.spnAttack.afterstorms+1]={deity=game.deities[slot],slot=slot,cards=result.afterstormCards or {}}
        end
    end
    game.souls=math.max(0,(game.souls or 0)-(result.soulCost or 0))
    game.discardsRemaining=math.max(0,(game.discardsRemaining or 0)-(result.discardCost or 0))
    if (result.addDiscards or 0)>0 then
        game.discardsRemaining=math.min(game.spnDiscardCap or game.maxDiscards or 3,game.discardsRemaining+result.addDiscards)
    end
    if (result.addHands or 0)>0 then game.handsRemaining=(game.handsRemaining or 0)+result.addHands end
    require("src.spn_convergence").commit(game,slot,result)
    if not preview then require("src.spn_provisions").commit(game,slot,result) end
end
function A.playerAttack(game,aura,hpBefore,damage,locked)
    local hits={};local target=game.monster
    active(game,function(deity,slot,state)
        if deity.id=="spirit_afterimage" then
            local amount=math.floor((state.aura or 0)*value(deity)/100)
            store(game,slot,{aura=math.max(0,aura)})
            if amount>0 and target.hp>0 then
                hits[#hits+1]={enemy=target,damage=require("src.monster").takeDamage(target,amount),deity=deity,slotIndex=slot}
            end
        elseif deity.id=="spirit_dream_jailer" and target.hp>0 then
            local key=target.groupIndex or 1;state.seen=state.seen or {}
            if not state.seen[key] then
                state.seen[key]=true;store(game,slot,state);target.spnSleep=(target.spnSleep or 0)+1
                game.playerArmor=math.min(30,(game.playerArmor or 0)+value(deity));game.playerShield=game.playerArmor
                notice(game,deity,slot,"BỎ 1 ĐÒN · +GIÁP")
            end
        elseif deity.id=="spirit_abyss_feast" and target.hp<=0 and hpBefore>0 then
            local armor=math.min(30,math.floor(math.max(0,damage-hpBefore)*value(deity)/100))
            if armor>0 then
                game.playerArmor=math.min(30,(game.playerArmor or 0)+armor);game.playerShield=game.playerArmor
                notice(game,deity,slot,"TÀN DƯ · +"..armor.." GIÁP")
            end
        end
    end,locked)
    return hits
end
function A.sleep(game,monster)
    if (monster.spnSleep or 0)<=0 then return false end
    monster.spnSleep=monster.spnSleep-1
    return true
end
function A.guard(game,damage)
    active(game,function(deity,slot,state)
        local hp=game.playerHp or 100
        if deity.id=="spirit_last_pact" and hp>0 and damage>=hp then
            if not state.used then
                local keep=math.min(game.maxPlayerHp or 100,5*require("src.blood_shop").powerOf(deity))
                game.playerHp=math.max(hp,keep);damage=game.playerHp-keep
                state.used=true;store(game,slot,state)
                notice(game,deity,slot,"GIAO KÈO · CÒN "..keep.." HP")
            elseif not state.legendaryUsed and D.getRarityTier(deity)>=5 then
                local pool={}
                for _,card in ipairs(game.persistentDeck or {}) do
                    if not card.destroyed then pool[#pool+1]=card end
                end
                if #pool>=6 then
                    local Rng=require("src.rng")
                    local Abilities=require("src.card_abilities")
                    local sync=require("src.chest_expansion").sync
                    for i=#pool,2,-1 do local j=Rng.random(i);pool[i],pool[j]=pool[j],pool[i] end
                    for i=1,5 do
                        local card=pool[i]
                        Abilities.destroy(game,card,nil,6)
                        sync(game,card,function(copy) copy.destroyed=true;copy.destructionNotified=true end)
                    end
                    require("src.combat").cleanupDestroyedCards(game)
                    state.legendaryUsed=true;store(game,slot,state)
                    game.playerHp=game.maxPlayerHp or 100;damage=0
                    notice(game,deity,slot,"GIAO KÈO BẬC L · HỒI ĐẦY HP · HIẾN TẾ 5 LÁ")
                end
            end
        end
    end)
    return damage
end
function A.enemyAttack(game,monster,damage)
    require("src.spn_convergence").enemyDamage(game,damage)
    active(game,function(deity,slot,state)
        if deity.id=="spirit_reprisal" and damage>0 and monster.hp>1 then
            local amount=math.min(monster.hp-1,math.floor(damage*value(deity)/100))
            if amount>0 then
                local reflected=require("src.monster").takeDamage(monster,amount)
                notice(game,deity,slot,"PHẢN "..reflected.." ST")
            end
        elseif deity.id=="spirit_zero_hour" and damage==0 and (game.playerHp or 0)>0 then
            store(game,slot,{charged=true});notice(game,deity,slot,"TÍCH KHÔNG THỜI")
        end
    end)
end
return A

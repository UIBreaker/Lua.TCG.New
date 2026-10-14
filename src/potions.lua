local P={}
P.definitions={
    {id="cons_accuracy",name="Thuốc Chính Xác",cost=6,kind="accuracy",color={.96,.80,.36,1},
        desc="Tay bài kế tiếp đánh trúng 100%, bất kể tốc đánh. Hết hiệu lực sau lượt kế tiếp; bỏ bài không làm mất hiệu lực."},
    {id="cons_evasion",name="Thuốc Né Tránh",cost=7,kind="evasion",color={.73,.62,.98,1},
        desc="Né mọi đòn tấn công của địch trong lượt kế tiếp, kể cả nhiều địch đánh trước và sau tay bài. Không chặn độc hoặc chi phí tự mất máu."},
    {id="cons_armor_break",name="Thuốc Phá Giáp",cost=8,kind="armor_break",color={.96,.63,.28,1},
        desc="Chọn một địch: phá toàn bộ giáp, không giới hạn lượng giáp; gây sát thương chuẩn bằng 25% tổng giáp vừa phá. Không có giáp thì không mất thuốc."},
    {id="cons_damage",name="Thuốc Sát Thương",cost=6,kind="damage",amount=20,color={.98,.38,.28,1},
        desc="Mỗi lá hiện đang trên tay nhận +20 Sát thương khi tính điểm trong lượt kế tiếp. Không tăng vĩnh viễn; hết lượt là hết hiệu lực."},
    {id="cons_empower",name="Thuốc Cường Hóa",cost=7,kind="empower",amount=5,color={.47,.74,.98,1},
        desc="Mỗi lá hiện đang trên tay nhận +5 Cường hóa khi tính điểm trong lượt kế tiếp. Không tăng vĩnh viễn; hết lượt là hết hiệu lực."},
    {id="cons_gold_blood",name="Thuốc Máu Vàng",cost=9,kind="gold_blood",color={.99,.76,.29,1},
        desc="Trong trận này: mỗi 1 HP thực mất do địch gây ra nhận 1 Vàng. Giáp hấp thụ, tự mất máu và sát thương vượt HP còn lại không tạo vàng. Không cộng dồn."},
    {id="cons_draw",name="Thuốc Rút Bài",cost=8,kind="draw",amount=5,color={.35,.95,.86,1},
        desc="Rút ngay 5 lá lên tay, kể cả khi tay đầy. Kho hết thì xáo cọc bỏ bài để rút tiếp; nếu tổng bài còn ít hơn 5 thì rút hết số còn lại. Hết cả kho/cọc bỏ thì không mất thuốc."},
    {id="cons_slow",name="Thuốc Giảm Tốc",cost=7,kind="slow",amount=.5,color={.48,.57,.99,1},
        desc="Ném vào một địch: giảm 50% tốc đánh hiện tại trong 2 hành động của địch, tối thiểu tốc 1. Tác động ngay đến thứ tự ra đòn và xác suất trúng; không cộng dồn."},
}
P.byId={}
for _,def in ipairs(P.definitions) do def.category="combat_potion";P.byId[def.id]=def end
function P.describe(item,game)
    local def=P.byId[item.id];if not def then return nil end
    if game then
        local effective,power=P.effective(game,item)
        local count=math.max(1,math.floor(power))
        local descriptions={
            accuracy="Đánh trúng 100% trong "..count.." lượt kế tiếp; bỏ bài không mất hiệu lực.",
            evasion="Né đòn địch trong "..count.." lượt kế tiếp; không chặn độc hoặc tự mất máu.",
            armor_break="Phá toàn bộ giáp một địch, gây sát thương chuẩn bằng "..(25*power).."% số giáp vừa phá.",
            damage="Mỗi lá hiện trên tay nhận +"..(effective.amount or 0).." Sát thương trong lượt kế tiếp.",
            empower="Mỗi lá hiện trên tay nhận +"..(effective.amount or 0).." Cường hóa trong lượt kế tiếp.",
            gold_blood="Trong trận: mỗi 1 HP thực mất do địch gây ra nhận "..power.." Vàng.",
            draw="Rút ngay "..(effective.amount or 0).." lá; kho hết thì xáo cọc bỏ, không vượt số bài còn lại.",
            slow="Giảm "..((effective.amount or 0)*100).."% tốc đánh một địch trong "..effective.slowTurns.." hành động, tối thiểu tốc 1.",
        }
        local text=descriptions[def.kind]
        if def.kind=="damage" or def.kind=="empower" then
            local _,chance=require("src.spn_alchemy").effects(game)
            if chance>0 then text=text.."\nDƯỢC HỒN · "..string.format("%g",chance).."% giữ toàn bộ lượng tăng vĩnh viễn." end
        end
        return text
    end
    if require("src.blood_shop").powerOf(item)==1 then return def.desc end
    local text={accuracy="Tay bài đánh trúng 100% trong 5 lượt kế tiếp.",evasion="Né đòn địch trong 5 lượt kế tiếp; không chặn độc hoặc tự mất máu.",
        armor_break="Phá toàn bộ giáp một địch, gây sát thương chuẩn bằng 125% số giáp vừa phá.",damage="Mỗi lá hiện trên tay nhận +100 Sát thương trong lượt kế tiếp.",
        empower="Mỗi lá hiện trên tay nhận +25 Cường hóa trong lượt kế tiếp.",gold_blood="Trong trận: mỗi 1 HP thực mất do địch gây ra nhận 5 Vàng. Chi phí mua hàng không tạo vàng.",
        draw="Rút ngay 25 lá; kho hết thì xáo cọc bỏ. Không vượt số bài còn lại.",slow="Giảm 50% tốc đánh một địch trong 10 hành động, tối thiểu tốc 1."}
    return text[def.kind].."\nHUYẾT LUYỆN ×5"
end

function P.emit(game,kind,label,value,target,cards)
    game.potionFeedback=game.potionFeedback or {}
    game.potionFeedback[#game.potionFeedback+1]={kind=kind,label=label,value=value,target=target,cards=cards}
end

function P.effective(game,card)
    local def=P.byId[card.id];if not def then return end
    local blood=require("src.blood_shop").powerOf(card)
    local boost=require("src.spn_alchemy").multiplier(game,card)
    local power=blood*boost
    local copy={};for k,v in pairs(def) do copy[k]=v end
    if def.amount then copy.amount=def.kind=="slow" and math.min(1,def.amount*boost) or def.amount*power end
    if def.kind=="draw" then copy.amount=math.floor(copy.amount) end
    copy.slowTurns=2*blood
    return copy,power
end

function P.makePermanent(game,card,kind,amount)
    require("src.chest_expansion").sync(game,card,function(c)
        if kind=="damage" then
            c.baseChips=(c.baseChips or require("src.deck").getChipValue(c.rank))+amount
            c.bonusBaseChips=(c.bonusBaseChips or 0)+amount
            c.potionPermanentDamage=(c.potionPermanentDamage or 0)+amount
        else c.potionPermanentMult=(c.potionPermanentMult or 0)+amount end
    end)
end

-- Called only after a speed target is confirmed; cancelling never rolls or consumes a potion.
function P.applySpeed(game,item,target)
    local present=false
    for _,held in ipairs(game.hand or {}) do if held==target and not held.destroyed then present=true end end
    if not present then return false end
    local potion=item.id=="cons_speed_small" or item.id=="cons_speed_large"
    local amount=require("src.shop").getConsumableParams(item).speed
    if not amount then return false end
    amount=amount*require("src.spn_alchemy").multiplier(game,item)
    local permanent=not potion or item.permanentSpeed or require("src.spn_alchemy").rollPermanent(game)
    if permanent then
        require("src.chest_expansion").sync(game,target,function(c) require("src.deck").applyAttackSpeedBonus(c,amount) end)
    else require("src.deck").applyTemporaryAttackSpeedBonus(target,amount) end
    P.emit(game,"speed","TỐC ĐÁNH +"..amount..(permanent and " · VĨNH VIỄN" or " · TRONG TRẬN"),amount,nil,{target})
    return true,amount,permanent
end

function P.use(game,index,target,prepareDraw)
    local card=game.consumables and game.consumables[index]
    local def=card and P.byId[card.id]
    if not def then return false,"Không phải thuốc chiến thuật." end
    if not game.monster or (game.playerHp or 0)<=0 or require("src.enemy_group").alive(require("src.enemy_group").members(game))==0 then
        return false,"Chỉ dùng thuốc chiến thuật trong trận."
    end
    local power
    def,power=P.effective(game,card)
    local state=game.potionCombat or {}
    local cards
    if def.kind=="draw" then
        game.hand=game.hand or {};game.deck=game.deck or {};game.discardPile=game.discardPile or {};cards={}
        while #cards<def.amount do
            if #game.deck==0 and #game.discardPile>0 then
                while #game.discardPile>0 do game.deck[#game.deck+1]=table.remove(game.discardPile) end
                require("src.deck").shuffle(game.deck)
            end
            if #game.deck==0 then break end
            local drawn=table.remove(game.deck)
            if not drawn.destroyed then
                drawn.selected=false;game.hand[#game.hand+1]=drawn;cards[#cards+1]=drawn
                if prepareDraw then prepareDraw(drawn,#cards) end
                if game.monster.isBoss and game.monster.bossData and game.monster.bossData.debuffId=="the_fish"
                    and require("src.boss_abilities").passiveEnabled(game.monster) then drawn.faceDown=true end
            end
        end
        if #cards==0 then return false,"Kho bài và cọc bỏ đã hết bài." end
        P.emit(game,"draw","RÚT NGAY "..#cards.." LÁ",#cards,nil,cards)
    elseif def.kind=="slow" then
        target=target or game.monster
        local present=false
        for _,enemy in ipairs(require("src.enemy_group").members(game)) do if enemy==target then present=true end end
        if not present or target.hp<=0 then return false,"Chọn một địch còn sống." end
        target.combatBuffs=target.combatBuffs or {}
        if target.combatBuffs.slow then return false,"Địch đang bị giảm tốc." end
        local before=require("src.enemy_abilities").speed(target)
        if before<=1 then return false,"Tốc đánh địch đã ở mức thấp nhất." end
        target.combatBuffs.slow={value=def.amount,turns=def.slowTurns}
        local after=require("src.enemy_abilities").speed(target)
        P.emit(game,"slow","GIẢM TỐC "..before.." → "..after.." · "..def.slowTurns.." HÀNH ĐỘNG",before-after,target)
    elseif def.kind=="armor_break" then
        target=target or game.monster
        local present=false
        for _,enemy in ipairs(require("src.enemy_group").members(game)) do if enemy==target then present=true end end
        local armor=math.max(0,target.armor or 0)+math.max(0,target.creatureArmor or 0)
        if not present or target.hp<=0 or armor<=0 then return false,"Chọn địch còn sống và có giáp." end
        target.armor=0;target.creatureArmor=0
        local damage=require("src.monster").takeDamage(target,armor*.25*power,true)
        P.emit(game,"armor_break","PHÁ "..armor.." GIÁP · "..damage.." ST",damage,target)
        game.potionVictoryPending=require("src.combat").getOutcome(game)=="victory"
    elseif def.kind=="damage" or def.kind=="empower" then
        if #(game.hand or {})==0 then return false,"Cần có quân bài trên tay." end
        local key=def.kind=="damage" and "damageCards" or "multCards"
        cards={};local seen={}
        for _,held in ipairs(game.hand) do if not held.destroyed then
            local id=held.id or held
            if not seen[id] then seen[id]=true;cards[#cards+1]=held end
        end end
        if #cards==0 then return false,"Cần có quân bài còn sống trên tay." end
        local permanent=require("src.spn_alchemy").rollPermanent(game)
        for _,held in ipairs(cards) do
            if permanent then P.makePermanent(game,held,def.kind,def.amount)
            else state[key]=state[key] or {};state[key][held.id or held]=(state[key][held.id or held] or 0)+def.amount end
        end
        P.emit(game,def.kind,"TOÀN TAY +"..def.amount..(def.kind=="damage" and " ST" or " CƯỜNG HÓA")..(permanent and " · VĨNH VIỄN" or " · 1 LƯỢT"),def.amount,nil,cards)
    else
        if state[def.kind] then return false,"Thuốc này đang có hiệu lực." end
        state[def.kind]=true
        if def.kind=="accuracy" or def.kind=="evasion" then power=math.max(1,math.floor(power));state[def.kind.."Turns"]=power
        elseif def.kind=="gold_blood" then state.goldBloodPower=power end
        P.emit(game,def.kind,def.kind=="accuracy" and ("CHÍNH XÁC 100% · "..power.." LƯỢT")
            or def.kind=="evasion" and ("NÉ TRÁNH · "..power.." LƯỢT") or ("MÁU VÀNG · 1 HP = "..power.." VÀNG"))
    end
    game.potionCombat=state
    table.remove(game.consumables,index)
    require("src.card_abilities").consumableUsed(game)
    return true
end

function P.cardBonus(game,card)
    local s=game and game.potionCombat or {}
    return (s.damageCards or {})[card.id or card] or 0,((s.multCards or {})[card.id or card] or 0)+(card.potionPermanentMult or 0)
end

function P.payBlood(game,hpBefore)
    if not (game.potionCombat or {}).gold_blood then return 0 end
    local lost=math.max(0,hpBefore-(game.playerHp or 0))
    if lost>0 then
        local gain=lost*(game.potionCombat.goldBloodPower or 1)
        game.gold=(game.gold or 0)+gain
        P.emit(game,"gold_blood","MÁU VÀNG · +"..gain.." VÀNG",gain)
    end
    return lost
end

function P.endTurn(game)
    local s=game.potionCombat
    if not s then return end
    for _,kind in ipairs({"accuracy","evasion"}) do
        if s[kind] then s[kind.."Turns"]=(s[kind.."Turns"] or 1)-1;if s[kind.."Turns"]<=0 then s[kind]=nil;s[kind.."Turns"]=nil end end
    end
    s.damageCards=nil;s.multCards=nil
end
return P

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

function P.emit(game,kind,label,value,target,cards)
    game.potionFeedback=game.potionFeedback or {}
    game.potionFeedback[#game.potionFeedback+1]={kind=kind,label=label,value=value,target=target,cards=cards}
end

function P.use(game,index,target,prepareDraw)
    local card=game.consumables and game.consumables[index]
    local def=card and P.byId[card.id]
    if not def then return false,"Không phải thuốc chiến thuật." end
    if not game.monster or (game.playerHp or 0)<=0 or require("src.enemy_group").alive(require("src.enemy_group").members(game))==0 then
        return false,"Chỉ dùng thuốc chiến thuật trong trận."
    end
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
        target.combatBuffs.slow={value=def.amount,turns=2}
        local after=require("src.enemy_abilities").speed(target)
        P.emit(game,"slow","GIẢM TỐC "..before.." → "..after.." · 2 HÀNH ĐỘNG",before-after,target)
    elseif def.kind=="armor_break" then
        target=target or game.monster
        local present=false
        for _,enemy in ipairs(require("src.enemy_group").members(game)) do if enemy==target then present=true end end
        local armor=math.max(0,target.armor or 0)+math.max(0,target.creatureArmor or 0)
        if not present or target.hp<=0 or armor<=0 then return false,"Chọn địch còn sống và có giáp." end
        target.armor=0;target.creatureArmor=0
        local damage=require("src.monster").takeDamage(target,armor*.25,true)
        P.emit(game,"armor_break","PHÁ "..armor.." GIÁP · "..damage.." ST",damage,target)
        game.potionVictoryPending=require("src.combat").getOutcome(game)=="victory"
    elseif def.kind=="damage" or def.kind=="empower" then
        if #(game.hand or {})==0 then return false,"Cần có quân bài trên tay." end
        local key=def.kind=="damage" and "damageCards" or "multCards"
        state[key]=state[key] or {};cards={}
        for _,held in ipairs(game.hand) do if not held.destroyed then
            state[key][held.id]=(state[key][held.id] or 0)+def.amount;cards[#cards+1]=held
        end end
        if #cards==0 then return false,"Cần có quân bài còn sống trên tay." end
        P.emit(game,def.kind,"TOÀN TAY +"..def.amount..(def.kind=="damage" and " ST" or " CƯỜNG HÓA"),def.amount,nil,cards)
    else
        if state[def.kind] then return false,"Thuốc này đang có hiệu lực." end
        state[def.kind]=true
        P.emit(game,def.kind,def.kind=="accuracy" and "CHÍNH XÁC 100% · 1 LƯỢT"
            or def.kind=="evasion" and "NÉ TRÁNH · 1 LƯỢT" or "MÁU VÀNG · 1 HP = 1 VÀNG")
    end
    game.potionCombat=state
    table.remove(game.consumables,index)
    require("src.card_abilities").consumableUsed(game)
    return true
end

function P.cardBonus(game,card)
    local s=game and game.potionCombat or {}
    return (s.damageCards or {})[card.id] or 0,(s.multCards or {})[card.id] or 0
end

function P.payBlood(game,hpBefore)
    if not (game.potionCombat or {}).gold_blood then return 0 end
    local lost=math.max(0,hpBefore-(game.playerHp or 0))
    if lost>0 then
        game.gold=(game.gold or 0)+lost
        P.emit(game,"gold_blood","MÁU VÀNG · +"..lost.." VÀNG",lost)
    end
    return lost
end

function P.endTurn(game)
    local s=game.potionCombat
    if not s then return end
    s.accuracy=nil;s.evasion=nil;s.damageCards=nil;s.multCards=nil
end
return P

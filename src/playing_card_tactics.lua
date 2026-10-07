-- Shared bounded resource ledger, resolved before initiative. No resource retriggers.
local T={}
local Data=require("config.card_ability_data")
local Boss=require("src.boss_abilities")
local function contains(list,c) for _,v in ipairs(list or {}) do if v==c then return true end end end
local function snapshot(g,x)
    if x.tacticStart then return x.tacticStart end
    local A=require("src.card_abilities")
    local s={hp=g.playerHp or 100,maxHp=g.maxPlayerHp or 100,armor=g.playerArmor or g.playerShield or 0,gold=g.gold or 0,
        held=0,heldHearts=0,suits=0,previous={},discarded=g.abilityCombat and g.abilityCombat.tacticDiscarded}
    local seen={}
    for i,c in ipairs(x.scoring or {}) do
        local d=A.definition(c);local suit=d and d.suit or c.suit
        if not seen[suit] then seen[suit]=true;s.suits=s.suits+1 end
        s.previous[c]=x.scoring[i-1]
    end
    for _,c in ipairs(g.hand or {}) do
        if not c.destroyed and not contains(x.played,c) then
            s.held=s.held+1;local d=A.definition(c);if d and d.suit=="heart" then s.heldHearts=s.heldHearts+1 end
        end
    end
    x.tacticStart=s;x.tacticLedger={heal=0,armor=0,gold=0,speed=0,seen={}}
    return s
end
function T.apply(g,c,p,x)
    local A=require("src.card_abilities");local d=A.definition(c)
    local s=snapshot(g,x);local ledger=x.tacticLedger
    local key=c.id or c
    if ledger.seen[key] or c.exhausted or (g.playerHp or 100)<=0 then return false end
    ledger.seen[key]=true
    local r=d.rule;local b=p.bonus or 0
    local out={heal=p.heal or 0,armor=p.armor or 0,gold=p.gold or 0,speed=p.speed or 0}
    local resource=d.suit=="heart" and "heal" or d.suit=="spade" and "armor" or d.suit=="club" and "speed" or "gold"
    local previous=s.previous[c];local pd=A.definition(previous)
    local hit=r=="pair" and #x.scoring==2 or r=="third" and (x.play or 1)%3==0
        or r=="diverse" and s.suits>=3 or r=="five" and #x.scoring==5
        or r=="discarded" and s.discarded or r=="wounded" and s.hp<s.maxHp*.5
        or r=="armor8" and s.armor>=8 or r=="reserve" and s.held>0
        or r=="ascending" and previous and previous.rank<c.rank
        or r=="first" and x.scoring[1]==c or r=="last" and x.scoring[#x.scoring]==c
        or r=="solo" and #x.scoring==1 or r=="opening" and (x.play or 1)==1
        or r=="soldier_before" and previous and previous.rank>=2 and previous.rank<=10
    if hit then out[resource]=out[resource]+b end
    if r=="charge" then
        local cap=d.suit=="diamond" and 2 or 3
        out[resource]=out[resource]+math.min(cap,(c.abilityState or {}).tacticCharge or 0)*(p.charge or b/cap)
        if not x.preview then A.runtime(c).tacticCharge=0 end
    elseif r=="held_hearts" then out.heal=out.heal+math.min(b,s.heldHearts*2)
    elseif r=="blood_pledge" and s.gold>=7 and s.hp>=s.maxHp*.5 and (g.playerHp or 0)>3 then out.hpCost=3;out.speed=1.5;out.armor=b
    elseif r=="armored" then if s.armor>0 then out.heal=out.heal+b else out.armor=6 end
    elseif r=="blood_plate" then
        if s.hp>=s.maxHp*.75 and (g.playerHp or 0)>4 then out.heal=0;out.hpCost=4;out.armor=8;out.speed=.5 else out.heal=b end
    elseif r=="critical" then out.armor=2;if s.hp<s.maxHp*.35 then out.heal=out.heal+b;out.armor=6 end
    elseif r=="interest" then out.gold=out.gold+math.min(b,math.floor(s.gold/10))
    elseif r=="different_before" and pd and pd.suit~=d.suit then out.armor=b
    elseif r=="buy_heal" and s.hp<s.maxHp*.5 and (g.gold or 0)>=2 and ledger.heal<12 then out.gold=0;out.heal=b;out.goldCost=2
    elseif r=="buy_speed" and (g.gold or 0)>=2 and ledger.speed<Data.speedPerHand then out.gold=0;out.speed=b;out.goldCost=2
    elseif r=="buy_armor" and s.gold>=15 and (g.gold or 0)>=3 and ledger.armor<24 then out.gold=0;out.armor=b;out.goldCost=3
    elseif r=="poor" then if s.gold<5 then out.gold=out.gold+b;out.armor=3 else out.speed=.5 end
    elseif r=="armor_speed" then
        if s.armor>=8 and (g.playerArmor or 0)>=4 then out.armorCost=4;out.speed=b else out.armor=8 end
    elseif r=="armor_heal" then
        if s.armor>=12 and (g.playerArmor or 0)>=6 then out.armorCost=6;out.heal=b else out.armor=6 end
    end
    if hit and r=="last" and d.suit=="heart" then out.armor=4 end
    if hit and r=="five" then if d.suit=="club" then out.armor=3 elseif d.suit=="diamond" then out.speed=1 end end
    if hit and r=="wounded" and d.suit=="club" or hit and r=="solo" and d.suit=="spade" then out.heal=2 end
    if hit and r=="solo" and d.suit=="club" then out.armor=4 end
    if hit and r=="opening" then
        if d.suit=="heart" then out.speed=1 elseif d.suit=="club" then out.gold=1 elseif d.suit=="spade" then out.speed=.5 end
    end
    if r=="armor8" and d.suit=="diamond" and not hit then out.armor=2 end
    g.gold=(g.gold or 0)-(out.goldCost or 0)
    g.playerHp=math.max(1,(g.playerHp or s.hp)-(out.hpCost or 0))
    g.playerArmor=math.max(0,(g.playerArmor or g.playerShield or 0)-(out.armorCost or 0))
    local allowedHeal=math.min(out.heal,math.max(0,12-ledger.heal))
    local actualHeal=math.min(allowedHeal,math.max(0,s.maxHp-(g.playerHp or s.hp)))
    g.playerHp=math.min(s.maxHp,(g.playerHp or s.hp)+actualHeal);ledger.heal=ledger.heal+allowedHeal
    if d.suit=="heart" then out.armor=out.armor+allowedHeal-actualHeal end
    local armor=math.min(out.armor,math.max(0,24-ledger.armor))
    g.playerArmor=math.min(Data.armorCap,g.playerArmor+armor);g.playerShield=g.playerArmor;ledger.armor=ledger.armor+armor
    local bc=g.abilityCombat or {};g.abilityCombat=bc
    local gold=math.min(math.floor(out.gold),math.max(0,Data.goldPerHand-ledger.gold),math.max(0,Data.goldPerCombat-(bc.tacticGold or 0)))
    g.gold=g.gold+gold;bc.tacticGold=(bc.tacticGold or 0)+gold;ledger.gold=ledger.gold+gold
    local speed=math.min(out.speed,math.max(0,Data.speedPerHand-ledger.speed));ledger.speed=ledger.speed+speed;x.tacticSpeed=ledger.speed
    -- A saturated economy/initiative build still contributes, within the armor cap.
    local overflow=math.max(0,math.floor(out.gold)-gold)*2+math.max(0,out.speed-speed)*2
    local overflowArmor=math.min(overflow,math.max(0,24-ledger.armor))
    armor=armor+overflowArmor;ledger.armor=ledger.armor+overflowArmor
    g.playerArmor=math.min(Data.armorCap,g.playerArmor+overflowArmor);g.playerShield=g.playerArmor
    if not x.preview then
        x.feedback=x.feedback or {}
        x.feedback[#x.feedback+1]={type="card_ability",card=c,abilityId=d.id,kind="ability",addedChips=0,addedMult=0,
            message=d.characterName.." · "..string.format("%+g",actualHeal-(out.hpCost or 0)).." HP / "..string.format("%+g",armor-(out.armorCost or 0)).." Giáp / "..string.format("%+g",gold-(out.goldCost or 0)).." Vàng / +"..string.format("%g",speed).." Tốc"}
    end
    return false -- Exact resource feedback already emitted.
end
function T.hold(g,cards)
    local A=require("src.card_abilities")
    for _,c in ipairs(cards or {}) do
        local d=A.definition(c)
        if d and d.rule=="charge" and not c.destroyed and not c.exhausted and not Boss.isAbilityDisabled(g,c) then
            local state=A.runtime(c);state.tacticCharge=math.min(d.suit=="diamond" and 2 or 3,(state.tacticCharge or 0)+1)
        end
    end
end
function T.preview(g,cards,info)
    if not g then return 0 end
    local A=require("src.card_abilities");local shadow={}
    for k,v in pairs(g) do shadow[k]=v end
    shadow.abilityCombat={};for k,v in pairs(g.abilityCombat or {}) do shadow.abilityCombat[k]=v end
    local x={scoring=info.scoringCards,played=cards,play=(shadow.abilityCombat.playIndex or 0)+1,preview=true}
    for _,c in ipairs(x.scoring) do
        if not c.destroyed and not Boss.isAbilityDisabled(g,c) then T.apply(shadow,c,A.effectiveParams(g,c,nil,{resonanceHand=g.hand,played=cards}),x) end
    end
    return x.tacticSpeed or 0
end
return T

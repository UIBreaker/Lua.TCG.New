local Deck=require("src.deck")
local E=require("src.equipment")
local A=require("src.card_abilities")
local S=require("src.scoring")
local D=require("src.deities")
local Rng=require("src.rng")
local Game=require("src.game_state")
local Poker=require("src.poker")
local failures,checks={},0
local function check(name,fn)
    checks=checks+1
    local ok,err=pcall(fn)
    if not ok then failures[#failures+1]=name..": "..tostring(err) end
end
local function fixture(cards)
    local g=Game.new();g.hand={};g.deck={};g.discardPile={};g.persistentDeck={}
    for _,c in ipairs(cards) do g.persistentDeck[#g.persistentDeck+1]=c;g.hand[#g.hand+1]=c end
    g.deities={};g.monster={hp=10000,maxHp=10000,attackSpeed=1,armor=0}
    g.enemies={g.monster};A.start(g)
    return g
end
local function info(cards)
    return {type=Poker.HAND_TYPES.PAIR,chips=10,mult=2,scoringCards=cards,unscoredCards={}}
end
local function live(g,h)
    local played={}
    for _,group in ipairs({h.scoringCards,h.unscoredCards or {}}) do for _,c in ipairs(group) do played[#played+1]=c end end
    A.beginHand(g,h,played)
    g.handsRemaining=g.handsRemaining-1
    for _,c in ipairs(played) do
        for i=#g.hand,1,-1 do if g.hand[i]==c then table.remove(g.hand,i) end end
        g.discardPile[#g.discardPile+1]=c
    end
    return S.calculate(h,g.deities,{gameState=g,monster=g.monster,hand=g.hand,handsAfterPlay=g.handsRemaining})
end
check("permanent base damage counted once",function()
    local c=Deck.newCard(4,"clubs");c.disableFactionPassives=true;c.bonusBaseChips=20;c.baseChips=24
    local r=S.calculate(info({c}),{},{});assert(r.bonusChips==24,"received "..r.bonusChips.." instead of 24")
end)
for _,seal in ipairs({"seal_ashen","seal_prophecy","seal_anchor","seal_blood"}) do
    check(seal.." preview is read only",function()
        local c=Deck.newCard(4,"clubs");c.disableFactionPassives=true;c.seal=seal
        local monster={hp=100,maxHp=100};local flags={}
        S.calculate(info({c}),{}, {preview=true,monster=monster,combatFlags=flags})
        assert(monster.hp==100 and not monster.showNextIntent and not c.destroyed and not c.isAnchor and not flags.bloodSealUsedThisCombat)
    end)
end
check("random enhancement preview does not consume RNG",function()
    local c=Deck.newCard(4,"clubs");c.disableFactionPassives=true;c.enhancement="enh_brittle"
    local state=Rng.getState();S.calculate(info({c}),{}, {preview=true});assert(Rng.getState()==state)
end)
check("held equipment preview matches play",function()
    local c=Deck.newCard(4,"clubs");c.equipments={E.ITEMS.itm_quiver,E.ITEMS.itm_lifebasin}
    local held={Deck.newCard(7,"hearts"),Deck.newCard(8,"hearts")}
    local g=fixture({c,held[1],held[2]});g.playerHp=50
    local h=info({c});local pre=S.calculate(h,{}, {preview=true,gameState=g,monster=g.monster})
    local actual=live(g,h);assert(pre.finalScore==actual.finalScore and pre.healHp==actual.healHp)
end)
check("relic echo preview matches play and does not spend freeze",function()
    local left,owner,right=Deck.newCard(4,"clubs"),Deck.newCard(4,"hearts"),Deck.newCard(4,"spades")
    owner.equipments={E.ITEMS.soul_echo_mirror,E.ITEMS.soul_frost_bell}
    local g=fixture({left,owner,right});local h=info({left,owner,right})
    local pre=S.calculate(h,{}, {preview=true,gameState=g,monster=g.monster})
    assert(g.soulRelicCombat.freeze==0 and not g.abilityHand)
    local actual=live(g,h);assert(pre.finalScore==actual.finalScore,"preview "..pre.finalScore.." / actual "..actual.finalScore)
    assert(g.soulRelicCombat.freeze==2)
end)
check("SPN sees tactical armor in preview",function()
    local c=Deck.newCard(4,"spades");local g=fixture({c});g.playerArmor=0
    D.addDeity(g,D.CATALOG.spirit_bastion,1);local h=info({c})
    local pre=S.calculate(h,g.deities,{preview=true,gameState=g,monster=g.monster})
    local actual=live(g,h);assert(pre.finalScore==actual.finalScore)
end)
check("SPN display multiplier does not multiply the same gain twice",function()
    local h=info({});h.chips=100;h.mult=2
    local r=S.calculate(h,{D.CATALOG.spirit_lone},{})
    -- Use an unconditional multiplier to isolate the final contract.
    r=S.calculate(h,{{name="Multiplier",onHandScored=function() return {xMult=2} end}},{})
    assert(r.finalScore==400 and r.xMultTotal==r.cardXMultTotal,"SPN multiplier already belongs to totalMult")
end)
check("boss locks card SPN and enchantment without active abilityHand",function()
    local c=Deck.newCard(4,"clubs");c.disableFactionPassives=true
    local g=fixture({c});D.addDeity(g,D.CATALOG.spirit_blade,1);g.deities[1].enchantment="spell_requiem"
    g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
    local h=info({c});local locked=S.calculate(h,g.deities,{preview=true,gameState=g,monster=g.monster})
    local base=S.calculate(h,{}, {preview=true,gameState=g,monster=g.monster})
    assert(locked.finalScore==base.finalScore)
end)
check("exhausted and locked cards cannot grant pre-hand equipment buffs",function()
    for _,mode in ipairs({"exhausted","locked"}) do
        local c,other=Deck.newCard(4,"hearts"),Deck.newCard(4,"clubs")
        c.disableFactionPassives=true;other.disableFactionPassives=true;c.equipments={E.ITEMS.mirror_adjacent,E.ITEMS.storm_eye}
        local monster={hp=100}
        if mode=="exhausted" then c.exhausted=true else
            monster.isBoss=true;monster.bossState={handIndex=1,passiveUntil=0};monster.lockedFaction=c.suit
        end
        local h=info({c,other});local r=S.calculate(h,{}, {monster=monster})
        c.equipments={};local base=S.calculate(h,{}, {monster=monster})
        assert(r.finalScore==base.finalScore,mode.." "..r.finalScore.." / "..base.finalScore)
    end
end)
check("equipment armor conversion and SPN share a preview budget",function()
    local c=Deck.newCard(4,"clubs");c.disableFactionPassives=true;c.equipments={E.ITEMS.itm_lockbox}
    local g={playerArmor=8,hand={},deities={D.CATALOG.spirit_bastion},monster={hp=100},handsRemaining=2}
    local h=info({c});local pre=S.calculate(h,g.deities,{preview=true,gameState=g,monster=g.monster})
    local actual=S.calculate(h,g.deities,{gameState=g,monster=g.monster})
    assert(pre.finalScore==actual.finalScore and g.playerArmor==0)
end)
check("mirror cannot grant damage to an exhausted neighbor",function()
    local owner,other=Deck.newCard(4,"hearts"),Deck.newCard(4,"clubs")
    other.exhausted=true;owner.equipments={E.ITEMS.mirror_adjacent}
    local h=info({owner,other});local r=S.calculate(h,{}, {})
    owner.equipments={};assert(r.finalScore==S.calculate(h,{}, {}).finalScore)
end)
check("Tàn Hỏa doubles Mult",function()
    local plain=S.calculate(info({}),{}, {})
    local r=S.calculate(info({}),{D.CATALOG.spirit_ember},{})
    assert(r.totalMult==plain.totalMult*2 and r.finalScore==plain.finalScore*2)
end)
check("retired faction progression cannot inflate Continental hands",function()
    local cards={Deck.newCard(4,"clubs"),Deck.newCard(5,"hearts"),Deck.newCard(6,"spades")}
    local r=S.calculate(info(cards),{}, {})
    assert(r.totalChips==25,"expected 10+4+5+6, got "..r.totalChips)
end)
check("quill selects an eligible teammate, preserves save and reports its socket",function()
    local owner,a,b=Deck.newCard(10,"clubs"),Deck.newCard(10,"hearts"),Deck.newCard(10,"spades")
    owner.equipments={E.ITEMS.soul_evolution_quill}
    local g=fixture({owner,a,b});a.evolutionLevel=2;b.evolutionLevel=0
    local h=info({owner,a,b});local pre=S.calculate(h,{}, {preview=true,gameState=g,monster=g.monster})
    assert(b.evolutionLevel==0 and not next(g.soulRelicCombat.used))
    local result=live(g,h);assert(a.evolutionLevel+b.evolutionLevel==3 and owner.evolutionLevel==0)
    assert(result.finalScore==pre.finalScore)
    local trigger
    for _,st in ipairs(result.steps) do for _,child in ipairs(st.presentationTriggers or {}) do
        if child.equipment and child.equipment.id=="soul_evolution_quill" then trigger=child end
    end end
    assert(trigger and trigger.equipmentIndex==1)
    local P=require("src.persistence");local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
    assert(restored.persistentDeck[2].evolutionLevel+restored.persistentDeck[3].evolutionLevel==3)
    A.finishHand(g);g.hand={owner,a,b};live(g,h);assert(a.evolutionLevel+b.evolutionLevel==4)
end)
check("quill does not consume its battle charge without a teammate",function()
    local owner,other=Deck.newCard(10,"clubs"),Deck.newCard(10,"spades")
    owner.equipments={E.ITEMS.soul_evolution_quill}
    local g=fixture({owner,other});local result=live(g,info({owner}))
    assert(not next(g.soulRelicCombat.used))
    A.finishHand(g);g.hand={owner,other};live(g,info({owner,other}));assert(other.evolutionLevel==1)
end)
check("blood seal is limited across hands and repeats only base damage",function()
    local c=Deck.newCard(4,"clubs");c.seal="seal_blood";c.edition="foil";c.equipments={E.ITEMS.gem_fire}
    local g=fixture({c});g.combatFlags={bloodSealUsedThisCombat=false};D.addDeity(g,D.CATALOG.spirit_blade,1)
    local h=info({c});local first=live(g,h)
    assert(g.combatFlags.bloodSealUsedThisCombat and first.hpCost==3)
    assert(first.flatDamageBonus==20 and first.totalChips==10+4+4+22+10)
    A.finishHand(g);g.hand={c};local second=live(g,h)
    assert(second.hpCost==0 and first.totalChips-second.totalChips==4)
end)
local equipmentCount,spnCount=0,0
local function parityCase(item,deity,n)
    local cards={};local suits={"hearts","clubs","spades","diamonds","hearts"}
    for i=1,n do cards[i]=Deck.newCard(i+2,suits[i]) end
    if item then cards[math.min(2,n)].equipments={item} end
    local held=Deck.newCard(8,"hearts");local g=fixture(cards);g.hand[#g.hand+1]=held
    g.persistentDeck[#g.persistentDeck+1]=held;g.playerHp=25;g.playerArmor=20;g.gold=20;g.souls=5
    if deity then D.addDeity(g,deity,1) end
    local h=assert(Poker.evaluate(cards))
    local P=require("src.persistence")
    local before=P.encode(g);local rng=Rng.getState()
    local pre=S.calculate(h,g.deities,{preview=true,gameState=g,monster=g.monster})
    assert(P.encode(g)==before and Rng.getState()==rng,"preview changed saved run or RNG")
    local actual=live(g,h)
    for _,field in ipairs({"finalScore","totalChips","totalMult","healHp","addArmor","hpCost","bonusGoldAwarded"}) do
        assert(math.abs(pre[field]-actual[field])<0.000001,field.." preview="..pre[field].." play="..actual[field])
    end
end
for id,item in pairs(E.ITEMS) do
    equipmentCount=equipmentCount+1
    check("catalog equipment "..id,function() for _,n in ipairs({1,2,3,5}) do parityCase(item,nil,n) end end)
end
for id,deity in pairs(D.CATALOG) do
    spnCount=spnCount+1
    check("catalog SPN "..id,function() for _,n in ipairs({1,2,3,5}) do parityCase(nil,deity,n) end end)
end
for _,err in ipairs(failures) do print("REGRESSION "..err) end
assert(#failures==0,#failures.." runtime regressions failed")
print("Scoring runtime PASS: "..checks.." checks; "..equipmentCount.." equipment and "..spnCount.." SPNs, 4 hand sizes each")

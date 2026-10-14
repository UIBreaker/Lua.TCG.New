local D=require("src.chest_depth")
local X=require("src.chest_expansion")
local Deck=require("src.deck")
local Shop=require("src.shop")
local G=require("src.game_state")
local A=require("src.card_abilities")
local E=require("src.equipment")
local S=require("src.scoring")
local P=require("src.persistence")
local Poker=require("src.poker")
local Deities=require("src.deities")
local Combat=require("src.combat")
local function fixture()
    local g=G.new();g.gold=30;g.playerHp=80;g.maxPlayerHp=100;g.playerArmor=20;g.playerShield=20
    g.handsRemaining=3;g.discardsRemaining=3;g.depthCombat={values={}}
    local c,a,b=Deck.newCard(12,"valoria"),Deck.newCard(6,"vharos"),Deck.newCard(9,"elaris")
    for _,v in ipairs({c,a,b}) do v.disableFactionPassives=true end
    c.evolutionLevel=2;c.edition="foil";c.enhancement="enh_armor";c.equipments={E.ITEMS.gem_fire}
    a.evolutionLevel=3;a.speedBonus=4;b.speedBonus=3
    g.persistentDeck={c,a,b};g.masterDeck=g.persistentDeck
    g.hand={Deck.cloneCard(c),Deck.cloneCard(a),Deck.cloneCard(b)};g.deck={};g.discardPile={}
    g.monster={hp=100,maxHp=100,armor=12,attackSpeed=8}
    g.deities={};assert(Deities.addDeity(g,Deities.CATALOG.spirit_ward,1))
    g.selectedIndices={1};return g,g.hand[1]
end
local function hand(cs,kind) return {type=Poker.HAND_TYPES[kind or "HIGH_CARD"],scoringCards=cs,unscoredCards={},chips=10,mult=2} end
local function score(g,cs,kind,preview,held)
    return S.calculate(hand(cs,kind),g.deities,{gameState=g,monster=g.monster,hand=held or {},preview=preview})
end
local ids={}
for _,list in ipairs({D.equipment,D.seals,D.spectral,D.spells}) do
    assert(#list==(list==D.seals and 4 or list==D.spells and 2 or list==D.spectral and 2 or 10))
    for _,d in ipairs(list) do assert(not ids[d.id] and not X.equipment[d.id]);ids[d.id]=true;assert(X.byId[d.id]==d) end
end
for _,d in ipairs(D.spectral) do
    local g,c=fixture();local shop=Shop.new();shop.currentPackOpening={pack={packType="spectral"},cards={d}}
    assert(Shop.choosePackCard(shop,1,g,{cards=d.id=="spec_rethread" and {c,g.hand[2]} or {c}}),d.id);assert(not shop.currentPackOpening)
    if d.id=="spec_rethread" then assert(#c.equipments==0 and #g.hand[2].equipments==1 and g.hand[2].enhancement=="enh_armor" and g.gold==30)
    elseif d.id=="spec_shrink" then assert(c.destroyed and #g.persistentDeck==2 and g.maxPlayerHp==90 and g.maxHandSize==4) end
    local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(#restored.persistentDeck==#g.persistentDeck)
    for i,v in ipairs(g.persistentDeck) do local r=restored.persistentDeck[i];assert(r.rank==v.rank and r.suit==v.suit and r.evolutionLevel==v.evolutionLevel and r.speedBonus==v.speedBonus) end
end
for _,d in ipairs(D.spectral) do
    local g,c=fixture();g.gold=0;g.playerHp=1;g.maxPlayerHp=30;g.persistentDeck={g.persistentDeck[1]};g.hand={c}
    Deck.transformCard(g,c,2);c.enhancement=nil;c.edition=nil
    local before=P.encode({gold=g.gold,hp=g.playerHp,c=c,deck=g.persistentDeck})
    if d.id~="spec_rebirth" then assert(not X.apply(g,d,c),d.id);assert(before==P.encode({gold=g.gold,hp=g.playerHp,c=c,deck=g.persistentDeck}),d.id.." mutated failed action") end
end
-- Discard preparation, actual enemy damage, once per hand and preview resource safety.
local g,c=fixture();c.equipments={E.ITEMS.itm_capacitor,E.ITEMS.itm_bloodvial}
A.discard(g,{c});A.discard(g,{c});assert(g.playerHp==76)
local memory=P.encode(g.depthCombat);local gold=g.gold;local hp=g.playerHp
local preview=score(g,{c},nil,true);assert(preview.bonusMult>=10 and preview.bonusChips>=36)
assert(P.encode(g.depthCombat)==memory and g.gold==gold and g.playerHp==hp)
local live=score(g,{c});assert(live.bonusChips==preview.bonusChips and live.bonusMult==preview.bonusMult)
assert(score(g,{c}).bonusMult<live.bonusMult)
g,c=fixture();c.equipments={E.ITEMS.itm_ledger};score(g,{c});assert(c.depthInvestment==1 and g.gold==29)
assert(g.persistentDeck[1].depthInvestment==1 and Deck.cloneCard(g.persistentDeck[1]).depthInvestment==1)
local saved=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(saved.persistentDeck[1].depthInvestment==1 and not saved.depthCombat)
g,c=fixture();c.equipments={E.ITEMS.itm_lockbox};local other=g.hand[2];other.equipments={E.ITEMS.itm_lockbox};g.playerArmor=8
local pre=score(g,{c,other},"PAIR",true);assert(g.playerArmor==8)
local actual=score(g,{c,other},"PAIR");assert(actual.totalExtraDamagePct==pre.totalExtraDamagePct and g.playerArmor==0)
g,c=fixture();c.equipments={E.ITEMS.itm_hourhand};D.enemyAttack(g,5,0);D.enemyAttack(g,7,0)
assert(score(g,{c}).bonusMult>=12);assert(score(g,{c}).bonusMult<12)
g,c=fixture();c.equipments={E.ITEMS.itm_counterweight};D.enemyAttack(g,12,0)
assert(score(g,{c}).totalExtraDamagePct>=0.12);assert(score(g,{c}).totalExtraDamagePct==0)
g,c=fixture();c.equipments={E.ITEMS.itm_bell};assert(score(g,{c}).bonusMult>=3);assert(score(g,{c}).bonusMult>=6)
A.discard(g,{g.hand[2]});assert(score(g,{c}).bonusMult<5)
g,c=fixture();c.equipments={E.ITEMS.itm_oar};score(g,{c},"PAIR");assert(score(g,{c},"STRAIGHT").addArmor>=4)
g,c=fixture();c.equipments={E.ITEMS.itm_pendulum};score(g,{c,g.hand[2]},"PAIR");assert(score(g,{c}).addArmor>=6)
g,c=fixture();c.equipments={E.ITEMS.itm_relay};g.hand[2].equipments={E.ITEMS.gem_fire}
local relay=E.ITEMS.itm_relay.onCardScore(c,{g.hand[2],c},2,{gameState=g,depthHandType="pair"});assert(relay.addChips==math.floor(g.hand[2].baseChips/2))
-- New depth seals separate held effects, discard rewards and triple scoring.
g,c=fixture();c.seal="seal_echoes"
assert(score(g,{g.hand[2]},nil,false,{c}).totalMult>=4)
assert(score(g,{c},nil,false,{}).xMultTotal<2)
g,c=fixture();c.seal="seal_reclaimer";A.discard(g,{c});assert(g.discardsRemaining==3 and g.gold==34)
A.discard(g,{c});assert(g.discardsRemaining==3 and g.gold==38)
g,c=fixture();c.seal="seal_gambit"
assert(Deck.freeSealDiscard(g,{c}) and not Deck.freeSealDiscard(g,{c,g.hand[2]}))
g,c=fixture();c.seal="seal_threshold";assert(score(g,{c}).healHp==3)
assert(score(g,{c}).healHp==3)
-- Spells span multiple turns; none should consume game resources in preview.
for _,d in ipairs(D.spells) do
    local g,c=fixture();assert(X.apply(g,d,g.deities[1]));local before=P.encode({g.depthCombat,g.gold,g.playerHp,g.handsRemaining,g.discardsRemaining,g.handLevels})
    score(g,{c},nil,true)
    assert(before==P.encode({g.depthCombat,g.gold,g.playerHp,g.handsRemaining,g.discardsRemaining,g.handLevels}),d.id)
    local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(restored.deities[1].enchantment==d.id)
end
local monster=require("src.monster").create(1,false,false,1);Combat.start(g,monster,1);assert(not next(g.depthCombat.values))
-- Verify stored cards use the same activation path and failures keep the card.
local f=assert(io.open("main.lua","r"));local source=f:read("*a");f:close()
local start=assert(source:find("local function useConsumable(idx)",1,true));local stop=assert(source:find("local function activateConsumable",start,true))
local chunk=source:sub(start,stop-1).."\nreturn useConsumable"
local function stored(g,d)
    local env=setmetatable({game=g,Shop=Shop,Sound=require("src.sound"),UI={BossAbilities=require("src.boss_abilities"),Inventory=require("src.inventory"),COLORS={goldYellow={}},
        Abilities=A,Polish={snapshot=function() return {} end,changed=function() end},
        AbilityUI={openChoices=function(_,choices,callback) callback({{target=choices[1].options[1].target}}) end}},anim={floatingTexts={}},saveRunAtSafePoint=function() end},{__index=_G})
    local loader;if setfenv then loader=assert(loadstring(chunk));setfenv(loader,env) else loader=assert(load(chunk,"stored depth card","t",env)) end
    g.consumables={d};return loader()(1)
end
for _,list in ipairs({D.spectral,D.spells}) do for _,d in ipairs(list) do local g=fixture();assert(stored(g,d),d.id);assert(#g.consumables==0) end end
g,c=fixture();g.maxPlayerHp=30;assert(not stored(g,D.byId.spec_shrink) and #g.consumables==1)
g,c=fixture();c.equipments={E.ITEMS.itm_hourhand};local beforeHp=g.playerHp
Combat.resolveMonsterAttack(g,"before",0);assert((g.depthCombat.attacks or 0)==1 and g.playerHp<=beforeHp)
for _,kind in ipairs({"arcana","seal","spectral","joker_edition"}) do
    local reached={};for _=1,700 do local p=Shop.openPack({packType=kind},G.new());local same={};for _,d in ipairs(p.cards) do assert(not same[d.id]);same[d.id]=true;reached[d.id]=true end end
    for _,d in ipairs(Shop.getPackContents(kind)) do assert(reached[d.id],d.id) end
end
print("PASS: retained depth cards, multi-turn combinations, discard/attack hooks, costs, preview isolation, persistence, reset and chest availability")

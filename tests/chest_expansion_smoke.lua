-- Run: lua tests/chest_expansion_smoke.lua
local X=require("src.chest_expansion")
local Shop=require("src.shop")
local Deck=require("src.deck")
local E=require("src.equipment")
local G=require("src.game_state")
local Scoring=require("src.scoring")
local Poker=require("src.poker")
local Deities=require("src.deities")
local Persistence=require("src.persistence")
local seen={}
for _,list in ipairs({X.equipment,X.seals,X.spectral,X.spells}) do
    assert(#list==10)
    for _,d in ipairs(list) do assert(not seen[d.id]);seen[d.id]=true;assert(d.desc~="" and d.artConcept~="") end
end
assert(#Shop.getPackContents("arcana")==#E.POOL)
assert(#Shop.getPackContents("seal")==26)
assert(#Shop.getPackContents("spectral")==28)
assert(#Shop.getPackContents("joker_edition")==24)
local function fixture()
    local g=G.new();g.gold=24;g.playerHp=80;g.maxPlayerHp=100;g.handsRemaining=1
    local a,b,c=Deck.newCard(6,"valoria"),Deck.newCard(6,"vharos"),Deck.newCard(9,"elaris")
    a.evolutionLevel=2;a.equipments={E.ITEMS.gem_fire};a.seal="seal_anchor"
    g.persistentDeck={a,b,c};g.masterDeck=g.persistentDeck
    g.hand={Deck.cloneCard(a),Deck.cloneCard(b),Deck.cloneCard(c)}
    g.deck={Deck.cloneCard(a)};g.discardPile={Deck.cloneCard(b)};g.selectedIndices={1}
    g.monster={hp=20,maxHp=100,armor=12,attackSpeed=999}
    g.deities={};assert(Deities.addDeity(g,Deities.CATALOG.spirit_ward,2))
    return g,g.hand[1]
end
-- Every transformation passes through the actual chest activation path.
for _,d in ipairs(X.spectral) do
    local g,t=fixture();local shop=Shop.new()
    shop.currentPackOpening={pack={packType="spectral"},cards={d}}
    local ok,message=Shop.choosePackCard(shop,1,g)
    assert(ok,d.id..": "..tostring(message));assert(not shop.currentPackOpening)
    local master=g.persistentDeck[1]
    assert(master.rank==t.rank and master.suit==t.suit and master.speedBonus==t.speedBonus)
    assert(master.evolutionLevel==t.evolutionLevel)
    if d.id=="spec_stairway" then assert(g.hand[2].rank==7 and g.hand[3].rank==8 and g.playerHp==76)
    elseif d.id=="spec_twin" then assert(g.hand[2].rank==6 and g.hand[2].suit=="vharos" and g.gold==21)
    elseif d.id=="spec_molt" then assert(t.evolutionLevel==1 and t.speedBonus==8)
    elseif d.id=="spec_prune" then assert(#g.persistentDeck==2 and t.bonusBaseChips==10 and #g.hand==2)
    elseif d.id=="spec_migration" then assert(t.suit=="aurelia" and g.persistentDeck[2].suit=="aurelia" and g.gold==20)
    elseif d.id=="spec_inversion" then assert(t.rank==10 and g.playerHp==78)
    elseif d.id=="spec_temper" then assert(#t.equipments==0 and t.evolutionLevel==4)
    elseif d.id=="spec_fission" then assert(t.rank==4 and #g.persistentDeck==4 and g.persistentDeck[4].rank==2)
    elseif d.id=="spec_redistribute" then assert(t.suit=="vharos" and g.hand[2].suit=="valoria")
    elseif d.id=="spec_distill" then assert(not t.seal and not t.isAnchor and t.evolutionLevel==3 and t.speedBonus==4) end
end
for _,id in ipairs({"spec_twin","spec_stairway","spec_redistribute","spec_temper","spec_molt","spec_prune","spec_distill","spec_fission"}) do
    local g,t=fixture();g.gold=0;g.playerHp=2;g.hand={t};g.persistentDeck={g.persistentDeck[1]}
    t.equipments={};t.evolutionLevel=0;t.seal=nil;t.rank=2
    local shop=Shop.new();shop.currentPackOpening={pack={packType="spectral"},cards={X.byId[id]}}
    assert(not Shop.choosePackCard(shop,1,g),id.." should fail")
    assert(shop.currentPackOpening and g.gold==0 and g.playerHp==2 and t.rank==2)
end
-- Check each equipment's unique condition, including unscored suppression.
local g,t=fixture();local u=g.hand[2];t.rank=3;u.rank=3
local ctx={gameState=g,monster=g.monster,hand={u,g.hand[3]}}
assert(E.ITEMS.itm_abacus.onCardScore(t,{t},1,ctx).addChips==24)
assert(E.ITEMS.itm_twinfang.onCardScore(t,{t,u},1,ctx).xMultBonus==0.30)
u.rank=2;assert(E.ITEMS.itm_wayfarer.onCardScore(t,{u,t},2,ctx).addMult==7)
assert(E.ITEMS.itm_prism.onCardScore(t,g.hand,1,ctx).addChips==48)
assert(E.ITEMS.itm_hourglass.onCardScore(t,{t},1,ctx).addArmor==11)
assert(E.ITEMS.itm_miser.onCardScore(t,{t},1,ctx).addMult==4)
assert(E.ITEMS.itm_quiver.onCardScore(t,{t},1,ctx).addChips==14)
t.equipments={E.ITEMS.itm_anvil,E.ITEMS.gem_fire,E.ITEMS.gem_blast}
assert(E.ITEMS.itm_anvil.onCardScore(t,{t},1,ctx).extraDamagePct==0.18)
t.rank=12;assert(E.ITEMS.itm_crown.onCardScore(t,{t,u},1,ctx).addGold==1)
assert(E.ITEMS.itm_root.onCardScore(t,{t},1,ctx).addChips==20)
for _,d in ipairs(X.equipment) do assert(not d.onCardScore(t,{t},0,ctx)) end
-- All seals run in scoring. Seed is permanent, capped, and preview-safe.
local function info(cards,id) return {type=Poker.HAND_TYPES[id or "HIGH_CARD"],scoringCards=cards,unscoredCards={},chips=10,mult=2} end
g,t=fixture();t.disableFactionPassives=true;t.seal="seal_seed"
local old=t.baseChips
Scoring.calculate(info({t}),{}, {gameState=g,monster=g.monster,hand={},preview=true})
assert(t.baseChips==old)
for _=1,15 do Scoring.calculate(info({t}),{}, {gameState=g,monster=g.monster,hand={}}) end
assert(t.seedChips==20 and t.baseChips==old+20 and g.persistentDeck[1].seedChips==20)
assert(Deck.cloneCard(t).seedChips==20)
local restoredSeed=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop"))
assert(restoredSeed.persistentDeck[1].seedChips==20 and restoredSeed.persistentDeck[1].baseChips==old+20)
for _,item in ipairs(X.equipment) do
    g,t=fixture();g.persistentDeck[1].equipments={item}
    local restored=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop"))
    assert(restored.persistentDeck[1].equipments[1].onCardScore==item.onCardScore)
end
for _,d in ipairs(X.seals) do
    g,t=fixture();t.disableFactionPassives=true;t.seal=d.id
    g.consumables={{},{}};g.hand[2].evolutionLevel=1;g.hand[3].rank=3
    local cards={t,g.hand[3]};if d.id=="seal_harvest" then cards={t,Deck.newCard(2,"valoria"),Deck.newCard(3,"valoria"),Deck.newCard(4,"valoria"),Deck.newCard(5,"valoria")} end
    local r=Scoring.calculate(info(cards),{}, {gameState=g,monster=g.monster,hand={g.hand[2]}})
    assert(r.finalScore>=0)
    if d.id=="seal_sunder" then assert(g.monster.armor==4)
    elseif d.id=="seal_mercy" then assert(r.healHp==6)
    elseif d.id=="seal_reserve" then assert(r.bonusGoldAwarded==1)
    elseif d.id=="seal_oath" then assert(r.hpCost==2 and r.addArmor==10)
    elseif d.id=="seal_equilibrium" then assert(r.bonusChips>=30)
    elseif d.id=="seal_harvest" then assert(r.bonusGoldAwarded==2)
    elseif d.id=="seal_dusk" then assert(r.totalExtraDamagePct>=0.2)
    elseif d.id=="seal_lantern" then assert(r.bonusChips>=20) end
end
-- Enchantments are saved data, trigger once per hand and preserve editions.
for _,d in ipairs(X.spells) do
    g,t=fixture();local deity=g.deities[2];deity.edition="foil"
    local shop=Shop.new();shop.currentPackOpening={pack={packType="joker_edition"},cards={d}}
    assert(Shop.choosePackCard(shop,1,g));assert(deity.enchantment==d.id and deity.edition=="foil")
    g.gold=0;g.playerHp=20
    local cards={t};local hand=info(cards)
    if d.id=="spell_bastion" then hand=info(g.hand);hand.scoringCards[4]=Deck.newCard(4,"valoria")
    elseif d.id=="spell_mend" then hand=info({t,g.hand[2]})
    elseif d.id=="spell_confluence" then hand=info({t},"FLUSH")
    elseif d.id=="spell_ladder" then hand=info({t},"STRAIGHT")
    elseif d.id=="spell_chorus" then assert(Deities.addDeity(g,Deities.CATALOG.spirit_echo,3)) end
    local r=Scoring.calculate(hand,g.deities,{gameState=g,monster=g.monster,hand={}})
    local count=0;for _,s in ipairs(r.steps) do if s.type=="deity_enchantment" then count=count+1 end end
    assert(count==1,d.id.." must trigger once")
    local saved=Persistence.makeSnapshot(g,"shop");local restored=Persistence.restoreSnapshot(saved)
    assert(restored.deities[2].enchantment==d.id and restored.deities[2].edition=="foil")
    assert(Deities.getDescription(restored.deities[2]):find(d.name,1,true))
end
-- Stored consumables exercise the real main.lua handler too.
local file=assert(io.open("main.lua","r"));local source=file:read("*a");file:close()
local first=assert(source:find("local function useConsumable(idx)",1,true))
local last=assert(source:find("local function activateConsumable",first,true))
local chunk=source:sub(first,last-1).."\nreturn useConsumable"
local function useStored(g,d)
    local env=setmetatable({game=g,Shop=Shop,Sound=require("src.sound"),
        UI={BossAbilities=require("src.boss_abilities"),Inventory=require("src.inventory"),COLORS={goldYellow={}}},
        anim={floatingTexts={}},saveRunAtSafePoint=function() end},{__index=_G})
    local loader
    if setfenv then loader=assert(loadstring(chunk));setfenv(loader,env)
    else loader=assert(load(chunk,"stored consumable","t",env)) end
    g.consumables={d};return loader()(1)
end
for _,list in ipairs({X.spectral,X.spells}) do
    for _,d in ipairs(list) do local g=fixture();assert(useStored(g,d),d.id);assert(#g.consumables==0) end
end
g,t=fixture();g.gold=0
assert(not useStored(g,X.byId.spec_twin) and #g.consumables==1)
g,t=fixture();g.deities={}
assert(not useStored(g,X.byId.spell_bastion) and #g.consumables==1)
-- Repeated chest rolls can reach every new reward; no duplicate candidates.
for _,kind in ipairs({"arcana","seal","spectral","joker_edition"}) do
    local found={}
    for _=1,600 do
        local pack=Shop.openPack({packType=kind},G.new())
        local ids={};for _,c in ipairs(pack.cards) do assert(not ids[c.id]);ids[c.id]=true;found[c.id]=true end
    end
    for _,d in ipairs(Shop.getPackContents(kind)) do assert(found[d.id],"unobtainable "..d.id) end
end
print("PASS: 40 chest discoveries, activation, scoring, persistence and random reward coverage")

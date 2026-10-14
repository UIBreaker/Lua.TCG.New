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
    assert(#list==(list==X.seals and 2 or list==X.spells and 6 or list==X.spectral and 0 or 10))
    for _,d in ipairs(list) do assert(not seen[d.id]);seen[d.id]=true;assert(d.desc~="" and d.artConcept~="") end
end
assert(#Shop.getPackContents("arcana")==#E.POOL)
assert(#Shop.getPackContents("seal")==10)
assert(#Shop.getPackContents("spectral")==7)
assert(#Shop.getPackContents("joker_edition")==8)
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
-- Curated transformations and retired save migration: spectral_persistence_smoke.lua.
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
-- Retired Seed upgrades remain permanent, while its stamp migrates.
local function info(cards,id) return {type=Poker.HAND_TYPES[id or "HIGH_CARD"],scoringCards=cards,unscoredCards={},chips=10,mult=2} end
g,t=fixture();X.sync(g,t,function(c) c.seal="seal_seed";c.seedChips=20;c.bonusBaseChips=20;c.baseChips=c.baseChips+20 end)
local restoredSeed=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop"))
assert(restoredSeed.persistentDeck[1].seal=="seal_lantern" and restoredSeed.persistentDeck[1].seedChips==20)
assert(restoredSeed.persistentDeck[1].baseChips==t.baseChips)
for _,item in ipairs(X.equipment) do
    g,t=fixture();g.persistentDeck[1].equipments={item}
    local restored=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop"))
    assert(restored.persistentDeck[1].equipments[1].onCardScore==item.onCardScore)
end
for _,d in ipairs(X.seals) do
    g,t=fixture();t.disableFactionPassives=true;t.seal=d.id
    g.consumables={{},{}};g.hand[2].evolutionLevel=1;g.hand[3].rank=3
    if d.id=="seal_lantern" then g.hand[2].suit=t.suit end
    local r=Scoring.calculate(info({t,g.hand[3]}),{}, {gameState=g,monster=g.monster,hand={g.hand[2]}})
    assert(r.finalScore>=0)
    if d.id=="seal_sunder" then assert(g.monster.armor==0 and r.flatDamageBonus==10)
    elseif d.id=="seal_lantern" then assert(r.bonusMult>=16) end
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
        UI={BossAbilities=require("src.boss_abilities"),Inventory=require("src.inventory"),COLORS={goldYellow={}},
            Abilities=require("src.card_abilities"),Polish={snapshot=function() return {} end,changed=function() end},
            AbilityUI={openChoices=function(_,choices,callback) callback({{target=choices[1].options[1].target}}) end}},
        anim={floatingTexts={}},saveRunAtSafePoint=function() end},{__index=_G})
    local loader
    if setfenv then loader=assert(loadstring(chunk));setfenv(loader,env)
    else loader=assert(load(chunk,"stored consumable","t",env)) end
    g.consumables={d};return loader()(1)
end
for _,list in ipairs({X.spectral,X.spells}) do
    for _,d in ipairs(list) do local g=fixture();assert(useStored(g,d),d.id);assert(#g.consumables==0) end
end
g,t=fixture();g.playerHp=5
assert(not useStored(g,require("src.spectral").get("spec_cryptid")) and #g.consumables==1)
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
print("PASS: retained chest discoveries, activation, scoring, persistence and random reward coverage")

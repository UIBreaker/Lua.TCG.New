local D=require("src.deities")
local P=require("src.spn_provisions")
local Rng=require("src.rng")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Scoring=require("src.scoring")
local Poker=require("src.poker")
local Persistence=require("src.persistence")
local Abilities=require("src.card_abilities")
local function game(ids)
    local g=Game.new();g.deities={};g.consumables={};g.hand={};g.handsRemaining=2
    g.monster={hp=10000,maxHp=10000,attackSpeed=10,attack=10}
    for slot,id in ipairs(ids) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    return g
end
local card=Deck.newCard(3,"hearts");card.disableFactionPassives=true
local hand=assert(Poker.evaluate({card}))
local function score(g,preview)
    return Scoring.calculate(hand,g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function handMessage(result)
    for _,step in ipairs(result.steps) do if step.type=="deity_hand" then return step.message end end
    error("Missing SPN hand step")
end
local originalRandom=Rng.random
local rolls={};local count=0
Rng.random=function(max)
    count=count+1;local roll=assert(rolls[count],"Unexpected RNG roll "..count)
    if max then assert(roll>=1 and roll<=max) end
    return roll
end
local function expectRolls(values) rolls=values;count=0 end
local g=game({"spirit_wayfarer"})
expectRolls({});local pool=P.randomPool();assert(count==0 and #pool>0)
local ids={}
for _,item in ipairs(pool) do
    assert(item.id and item.name and item.category and item.desc and not ids[item.id]);ids[item.id]=true
end
assert(ids.cons_bed and ids.cons_evolution and ids.soul_reaper and ids.cons_speed_small,"all consumable families are eligible")
expectRolls({});local preview=score(g,true)
assert(count==0 and #g.consumables==0 and #(g.spnFeedback or {})==0,"preview neither rolls nor grants")
expectRolls({.249999,1});local actual=score(g)
assert(count==2 and #g.consumables==1 and g.consumables[1].id==pool[1].id and #g.spnFeedback==1)
assert(actual.finalScore==preview.finalScore)
expectRolls({.25});score(g);assert(count==1 and #g.consumables==1,"25% boundary fails")
expectRolls({.999});score(g);assert(#g.consumables==1)

g=game({"spirit_first_echo"})
expectRolls({});score(g);assert(count==0 and #g.consumables==0,"empty inventory cannot copy")
local source=require("src.run_manager").createSpeedSingleCard()
source.evolutionLevel=3;source.permanentSpeed=true;source.params={speed=17};source.color={.2,.4,.6,1}
g.consumables={source,require("src.run_manager").createEvolutionCard()}
expectRolls({});score(g,true);assert(count==0 and #g.consumables==2)
expectRolls({0});score(g)
local copy=g.consumables[3]
assert(count==1 and copy.id==source.id and copy~=source and copy.params~=source.params and copy.color~=source.color)
assert(copy.evolutionLevel==3 and copy.permanentSpeed and copy.params.speed==17)
copy.params.speed=2;copy.color[1]=1;assert(source.params.speed==17 and source.color[1]==.2,"nested copy remains independent")
expectRolls({});score(g);assert(count==0 and #g.consumables==3,"full inventory skips the roll")
g.maxConsumables=4;expectRolls({0});score(g);assert(#g.consumables==4,"honors expanded capacity")
D.evolve(g.deities[1]);assert(D.getDescription(g.deities[1]):find("37.5%",1,true))
assert(D.scaleEffect(g.deities[1],{consumableChancePct=25}).consumableChancePct==37.5)
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(saved.deities[1].onHandScored and saved.consumables[1].params.speed==17 and saved.consumables[3].params.speed==2)
saved.consumables[3].params.speed=99;assert(saved.consumables[1].params.speed==17)

-- Evolution raises the real roll threshold, description and saved callback together.
for _,row in ipairs(P.entries) do
    g=game({row[1]});local owned=g.deities[1]
    for level=0,8 do
        local chance=math.min(100,25*(1+level*.5))
        local percent=string.format("%g",chance).."%"
        assert(D.scaleEffect(owned,{consumableChancePct=25}).consumableChancePct==chance)
        assert(D.getDescription(owned):find(percent,1,true))
        g.consumables={source};expectRolls({});local r=score(g,true)
        assert(count==0 and #g.consumables==1 and handMessage(r):find(percent,1,true))
        g.consumables={source};expectRolls(row[3]=="random" and {chance/100-.000001,1} or {chance/100-.000001})
        score(g);assert(#g.consumables==2 and count==(row[3]=="random" and 2 or 1))
        if chance<100 then
            g.consumables={source};expectRolls({chance/100});r=score(g)
            assert(#g.consumables==1 and count==1 and handMessage(r):find(percent,1,true))
        end
        D.evolve(owned)
    end
    D.setRarity(owned,"unique");assert(D.getDescription(owned):find("100%",1,true))
    owned.fixedEffect=true -- Metadata from saves made before the evolution fix.
    local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    g=restored;g.consumables={source}
    expectRolls(row[3]=="random" and {.999999,1} or {.999999});score(g)
    assert(#g.consumables==2 and D.getDescription(g.deities[1]):find("100%",1,true))
end

-- Processing order allows a supply to be copied by the next SPN, once per owned slot.
g=game({"spirit_wayfarer","spirit_first_echo"})
expectRolls({0,1,0});score(g)
assert(count==3 and #g.consumables==2 and g.consumables[1].id==g.consumables[2].id)
g=game({"spirit_first_echo","spirit_wayfarer"})
expectRolls({0,1});score(g);assert(count==2 and #g.consumables==1)
g=game({"spirit_wayfarer","spirit_first_echo"});g.consumables={source,source}
expectRolls({0,1});score(g);assert(count==2 and #g.consumables==3,"last free slot prevents second grant")

for _,row in ipairs(P.entries) do
    g=game({row[1]});g.consumables={source}
    g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
    expectRolls({});score(g);assert(count==0 and #g.consumables==1,"boss-locked SPN cannot roll")
end
g=game({"spirit_first_echo"});g.consumables={source}
local originalTriggered=Abilities.spnTriggered
Abilities.spnTriggered=function() return 10 end
expectRolls({0});score(g);assert(count==1 and #g.consumables==2,"numeric score retriggers do not multiply the lottery")
Abilities.spnTriggered=originalTriggered
Rng.random=originalRandom
g=game({"spirit_wayfarer","spirit_first_echo"});g.consumables={source}
local state=Rng.getState();for i=1,5 do score(g,true) end
assert(Rng.getState()==state and #g.consumables==1,"repeated previews preserve the real RNG stream")
assert(#D.getRandomShopPool({},99)==61)
print("SPN provisions PASS: evolving chance thresholds/cap, all consumable families, pure previews, independent upgraded copies, slot order/capacity, retriggers, boss locks and old/new saves")

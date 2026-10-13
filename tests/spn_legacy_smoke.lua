local D=require("src.deities")
local L=require("src.spn_legacy")
local Deck=require("src.deck")
local Game=require("src.game_state")
local Souls=require("src.souls")
local Scoring=require("src.scoring")
local Poker=require("src.poker")
local Persistence=require("src.persistence")
local function game(ids)
    local g=Game.new();g.deities={};g.hand={};g.handsRemaining=3
    g.monster={hp=10000,maxHp=10000,isBoss=true,attack=1,attackSpeed=1}
    for slot,id in ipairs(ids) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    return g
end
local function hand(ranks)
    local cards={};for _,rank in ipairs(ranks) do local card=Deck.newCard(rank,"hearts");card.disableFactionPassives=true;cards[#cards+1]=card end
    return assert(Poker.evaluate(cards))
end
local function score(g,h,preview) return Scoring.calculate(h,g.deities,{gameState=g,monster=g.monster,preview=preview}) end
local function bonus(result,id)
    local value=0;for _,s in ipairs(result.steps) do if s.type=="deity_hand" and s.deity.id==id then value=value+s.addedChips end end
    return value
end
local g=game({"spirit_meteor_solitude"});local h=hand({3})
assert(L.canPlay(g,1) and not L.canPlay(g,2) and not L.canPlay(g,5))
assert(bonus(score(g,h),"spirit_meteor_solitude")==1000)
assert(bonus(score(g,hand({3,3})),"spirit_meteor_solitude")==0)
assert(bonus(score(g,hand({2,5})),"spirit_meteor_solitude")==0,"unscored played cards count too")
for level=1,8 do
    D.evolve(g.deities[1]);local expected=1000*2^level
    assert(bonus(score(g,h,true),"spirit_meteor_solitude")==expected and bonus(score(g,h),"spirit_meteor_solitude")==expected)
    assert(D.getDescription(g.deities[1]):find(tostring(math.floor(expected)),1,true))
end
g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(L.canPlay(g,2) and bonus(score(g,h),"spirit_meteor_solitude")==0,"disabled SPN has neither bonus nor restriction")
g.deities={};assert(L.canPlay(g,5))

g=game({"spirit_pebble","spirit_legacy_cocoon"})
local initial=score(g,h).finalScore;g.deities[2]=nil;assert(score(g,h).finalScore==initial,"cocoon has no score effect")
g=game({"spirit_pebble","spirit_legacy_cocoon"})
local source=g.deities[1];source.spnGrowth={layers=4};source.values={value=20};source.color={.2,.4,.6,1};source.enchantment="spell_veil"
D.evolve(source)
local egg=g.deities[2]
assert(L.bossDefeated(g,g.monster)==0 and g.deities[2]==egg,"live boss cannot hatch")
g.monster.isBoss=false;g.monster.hp=0;Souls.awardKills(g);assert(g.deities[2]==egg,"ordinary kill cannot hatch")
g.monster={hp=0,maxHp=10000,isBoss=true}
Souls.awardKills(g)
local copy=g.deities[2]
assert(copy.id==source.id and copy~=source and copy.evolutionLevel==source.evolutionLevel and copy.enchantment==source.enchantment)
assert(copy.spnGrowth~=source.spnGrowth and copy.values~=source.values and copy.color~=source.color)
copy.spnGrowth.layers=99;copy.values.value=3;copy.color[1]=1
assert(source.spnGrowth.layers==4 and source.values.value==20 and source.color[1]==.2)
assert(g.monster.spnLegacyClaimed and D.getCount(g.deities)==2)
Souls.awardKills(g);assert(D.getCount(g.deities)==2 and L.bossDefeated(g,g.monster)==0,"same boss cannot hatch twice")

-- Full slots: evolve the egg to produce three copies, then verify overflow slots score and survive saves.
g=game({"spirit_pebble","spirit_blade","spirit_coin","spirit_ward","spirit_legacy_cocoon"})
D.evolve(g.deities[5]);D.evolve(g.deities[5]);g.monster.hp=0
local Rng=require("src.rng");local oldRandom=Rng.random;local rolls=0
Rng.random=function(max) rolls=rolls+1;assert(max==4);return 1 end
Souls.awardKills(g);Rng.random=oldRandom
assert(rolls==1 and D.getCount(g.deities)==7 and D.getMaxSlots(g)==7 and g.deities[7].id=="spirit_pebble")
g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
assert(bonus(score(g,h),"spirit_pebble")==80,"all original/copied slots contribute including overflow")
assert(not D.addDeity(g,D.CATALOG.spirit_coin),"regular buying still respects occupied capacity")
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(D.getCount(saved.deities)==7 and D.getMaxSlots(saved)==7 and saved.deities[7].onHandScored)
saved.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
assert(bonus(score(saved,h),"spirit_pebble")==80)
saved.deities[1],saved.deities[2]=saved.deities[2],saved.deities[1]
saved.deities[5]=nil;assert(D.getMaxSlots(saved)==7,"holes never hide an occupied overflow slot")
saved.deities[6]=nil;saved.deities[7]=nil;assert(D.getMaxSlots(saved)==5,"capacity returns after overflow empties")

g=game({"spirit_legacy_cocoon"});g.monster.hp=0;Souls.awardKills(g)
assert(g.deities[1].id=="spirit_legacy_cocoon","keep lone cocoon until another boss when there is a source")
g=game({"spirit_legacy_cocoon","spirit_legacy_cocoon"});g.monster.hp=0
Souls.awardKills(g);assert(D.getCount(g.deities)==2,"newborn cocoons cannot recursively hatch on this kill")
g=game({"spirit_pebble","spirit_legacy_cocoon"});g.deities[1].edition="negative";D.evolve(g.deities[2]);g.monster.hp=0
Souls.awardKills(g);assert(D.getCount(g.deities)==3 and D.getMaxSlots(g)==8,"copy keeps negative edition capacity")

g=game({"spirit_meteor_solitude"});D.evolve(g.deities[1]);D.evolve(g.deities[1])
saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")));saved.monster=g.monster
assert(not L.canPlay(saved,2) and bonus(score(saved,h),"spirit_meteor_solitude")==4000)
local state=Rng.getState();score(saved,h,true);assert(Rng.getState()==state and D.getCount(saved.deities)==1)
assert(#D.getRandomShopPool({},99)==77)
print("SPN legacy PASS: boss-only sacrifice/copies, one kill receipt, deep owned upgrades, full/negative/overflow slots, save/load, no hatch recursion, single-card restriction and doubling evolution")

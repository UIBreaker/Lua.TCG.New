local D=require("src.deities")
local G=require("src.game_state")
local Deck=require("src.deck")
local Poker=require("src.poker")
local S=require("src.scoring")
local A=require("src.card_abilities")
local P=require("src.persistence")
local Rng=require("src.rng")
local double,writer="spirit_aura_bifurcation","spirit_numeral_weaver"
local function game(ids,ranks)
    local g=G.new();g.deities={};g.hand={};g.persistentDeck={};g.deck={};g.discardPile={}
    g.monster={hp=100000000000,maxHp=100000000000,attack=0,attackSpeed=1};g.enemies={g.monster};g.gold=100
    for i,rank in ipairs(ranks or {2,2}) do
        local c=Deck.newCard(rank,({"spades","hearts","clubs","diamonds","spades"})[i]);c.disableFactionPassives=true
        g.hand[i]=c;g.persistentDeck[i]=Deck.cloneCard(c)
    end
    for slot,id in ipairs(ids or {}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    A.start(g);return g
end
local function score(g,preview)
    return S.calculate(assert(Poker.evaluate(g.hand)),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local baseline=score(game({})).finalScore
local g=game({double});local r=score(g)
near(r.finalScore,baseline*2);near(r.spnAuraMultiplier,2)
local plain=score(game({}));near(r.totalChips,plain.totalChips);near(r.totalMult,plain.totalMult)
D.evolve(g.deities[1]);near(score(g).finalScore,baseline*2.5)
assert(D.getDescription(g.deities[1]):find("2.5",1,true))
g=game({double,double});near(score(g).finalScore,baseline*4)
g=game({"spirit_right_echo",double});near(score(g).finalScore,baseline*4)
g=game({double,"spirit_left_refrain"});near(score(g).finalScore,baseline*8)
g=game({double});g.deities[2]={name="Flat AURA",onHandScored=function() return {addFlatDamage=17} end}
near(score(g).finalScore,(baseline+17)*2)
for _,case in ipairs({{{2,2},22},{{9,9,9,9},9999},{{2,3,4,5,6},23456},{{6,5,4,3,2},65432},{{14,11,12,13,10},111121310},{{2,9,9,4,7},29947}}) do
    g=game({writer},case[1]);r=score(g)
    near(r.finalScore,case[2]);near(r.writtenAura,case[2]);assert(r.writtenDigits==tostring(case[2]))
end
-- Only real played cards enter the number, never held cards or retriggered copies.
g=game({writer,"spirit_second_wave"});r=score(g);near(r.finalScore,22)
g=game({writer,double});near(score(g).finalScore,44)
g=game({double,writer});near(score(g).finalScore,44)
g=game({writer,"spirit_pebble","spirit_ember","spirit_twin_fang"});g.hand[1].baseChips=99999
g.deities[5]={name="Ignored score",onHandScored=function() return {addFlatDamage=999999,xChips=100,xMult=100} end}
near(score(g).finalScore,22)
g=game({writer,writer});near(score(g).finalScore,22)
D.evolve(g.deities[2]);near(score(g).finalScore,33)
D.evolve(g.deities[2]);near(score(g).finalScore,44)
g=game({"spirit_right_echo",writer});D.evolve(g.deities[1]);near(score(g).finalScore,22)
D.evolve(g.deities[2]);near(score(g).finalScore,33)
g=game({writer,"spirit_coin_wisp"});r=score(g);assert(r.bonusGoldAwarded==4 and r.finalScore==22,"resource triggers survive writing")
g=game({writer});g.deities[2]={name="Aura debt",onHandScored=function() return {auraTax=5} end}
near(score(g).finalScore,17)
g=game({writer,double});g.deities[3]={name="Aura debt",onHandScored=function() return {auraTax=5} end}
near(score(g).finalScore,39)
g=game({writer,double},{2,2,8});local before=P.encode(g);local rng=Rng.getState();local pre=score(g,true)
assert(P.encode(g)==before and Rng.getState()==rng,"preview remains isolated")
near(pre.finalScore,456);near(score(g).finalScore,pre.finalScore)
local locked=game({writer});locked.monster.isBoss=true
locked.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(not score(locked).writtenAura)
local reserve=game({});reserve.backpackDeities={D.CATALOG[writer]};assert(not score(reserve).writtenAura)
g=game({writer,double});D.evolve(g.deities[1]);D.evolve(g.deities[2]);local saved=assert(P.restoreSnapshot(P.makeSnapshot(g,"playing")))
g.deities=saved.deities;near(score(g).finalScore,82);assert(D.getDescription(saved.deities[1]):find("1.5",1,true))
assert(#D.getRandomShopPool({},999)==100)
assert(require("src.spn_aura").digits({playedCards={}})==nil)
assert(require("src.spn_aura").digits({playedCards={{rank=0}}})==nil)
print("SPN Aura PASS: final Aura multiplication, ordered direct writing, all user examples, face ranks, evolution, copy/retrigger, isolated preview, locks, reserve and save/load")
return true

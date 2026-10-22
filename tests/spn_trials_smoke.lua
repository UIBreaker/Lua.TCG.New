local T=require("src.spn_trials")
local D=require("src.deities")
local G=require("src.game_state")
local A=require("src.card_abilities")
local Deck=require("src.deck")
local Poker=require("src.poker")
local S=require("src.scoring")
local Rng=require("src.rng")
local P=require("src.persistence")
local function game(ids,unlocked)
    local g=G.new();g.deities={};g.hand={};g.persistentDeck={};g.deck={};g.discardPile={}
    g.unlockedHands=unlocked or {high_card=true,pair=true,straight=true};g.monster={hp=100000,maxHp=100000,attack=0,attackSpeed=1};g.enemies={g.monster}
    for i,rank in ipairs({2,3,4,7,9}) do local c=Deck.newCard(rank,"spades");c.disableFactionPassives=true;g.persistentDeck[i]=c;g.hand[i]=Deck.cloneCard(c) end
    for slot,id in ipairs(ids or {T.id}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    A.start(g);return g
end
local function trial(g,slot) return g.spnCombat and g.spnCombat[g.deities[slot or 1]] and g.spnCombat[g.deities[slot or 1]].trial end
local function hand(id) for _,h in ipairs(Poker.ALL_HANDS_ORDERED) do if h.id==id then return {type=h} end end;error(id) end
local function levels(g) local n=0;for _,d in pairs(g.deities) do n=n+(d.evolutionLevel or 0) end;return n end
for _,unlocked in ipairs({{}, {high_card=true},{high_card=true,pair=true},{high_card=true,pair=true,fake_hand=true}}) do
    local g=game(nil,unlocked);local rng=Rng.getState();T.prepare(g)
    assert(not trial(g) and rng==Rng.getState(),"at least three valid unlocked hands, no inactive RNG")
    T.handEnd(g,hand("high_card"));assert(levels(g)==0)
    assert(T.describe(g,g.deities[1]):find("CHƯA HOẠT ĐỘNG",1,true))
end
for seed=1,20 do
    Rng.seed(seed);local g=game();T.prepare(g);local t=assert(trial(g))
    assert(t.ids[1]~=t.ids[2] and g.unlockedHands[t.ids[1]] and g.unlockedHands[t.ids[2]])
    local state=Rng.getState();T.prepare(g);assert(trial(g)==t and Rng.getState()==state,"no reroll")
    T.handEnd(g,hand("flush"));assert(not next(t.seen) and levels(g)==0,"only requested hands count")
    T.handEnd(g,hand(t.ids[2]));T.handEnd(g,hand(t.ids[2]));assert(levels(g)==0,"repeated same hand is one objective")
    T.handEnd(g,hand(t.ids[1]));assert(t.done and levels(g)==1 and g.deities[1].evolutionLevel==1,"self is an eligible target, any order")
    T.handEnd(g,hand(t.ids[1]));T.handEnd(g,hand(t.ids[2]));assert(levels(g)==1,"one reward per combat")
    assert(T.describe(g,g.deities[1]):find("ĐÃ THƯỞNG",1,true))
    local restored=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
    assert(restored.deities[1].evolutionLevel==1 and not restored.spnCombat,"reward persists, tasks are combat-scoped")
    g.spnCombat={};T.prepare(g);assert(trial(g)~=t and not trial(g).done,"fresh next battle")
end
local g=game({T.id,"spirit_pebble","spirit_ember"});T.prepare(g);local t=trial(g)
T.handEnd(g,hand(t.ids[1]));T.handEnd(g,hand(t.ids[2]));assert(levels(g)==1)
g=game({T.id,T.id,"spirit_left_refrain"});T.prepare(g)
assert(trial(g,1)~=trial(g,2),"independent physical tasks")
for _,h in ipairs(Poker.ALL_HANDS_ORDERED) do if g.unlockedHands[h.id] then T.handEnd(g,{type=h}) end end
assert(levels(g)==2,"one exact level per task source, not multiplied by retriggers or own evolution")
g=game({"spirit_right_echo",T.id});T.prepare(g);assert(trial(g,1) and trial(g,2))
for _,h in ipairs(Poker.ALL_HANDS_ORDERED) do if g.unlockedHands[h.id] then T.handEnd(g,{type=h}) end end
assert(levels(g)==2,"copier has its own single contract")
g=game();g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
T.prepare(g);assert(not trial(g),"locked source cannot start")
g.monster.bossState.slotLock=nil;T.prepare(g);t=trial(g)
T.handEnd(g,hand(t.ids[1]));g.monster.bossState.slotLock={kind="spn",slot=1,untilHand=1}
T.handEnd(g,hand(t.ids[2]));assert(not t.done and levels(g)==0,"locked source cannot progress")
g.monster.bossState.slotLock=nil;T.handEnd(g,hand(t.ids[2]));assert(t.done)
g=game({});g.backpackDeities={D.CATALOG[T.id]};T.prepare(g);assert(not g.spnCombat or not next(g.spnCombat))
g=game();local before=P.encode(g);local rng=Rng.getState()
local h=assert(Poker.evaluate(g.hand,g.unlockedHands,g.handLevels))
S.calculate(h,g.deities,{gameState=g,monster=g.monster,preview=true})
assert(before==P.encode(g) and rng==Rng.getState(),"preview never assigns real tasks or evolves targets")
-- Real begin/end lifecycle claims exactly once, not on numeric scoring or redraw.
T.prepare(g);t=trial(g);t.ids={"high_card","straight"};t.names={"Đơn thủ","Sảnh"}
for _,cards in ipairs({{g.hand[5]},{g.hand[1],g.hand[2],g.hand[3]}}) do
    h=assert(Poker.evaluate(cards,g.unlockedHands,g.handLevels));A.beginHand(g,h,cards)
    S.calculate(h,g.deities,{gameState=g,monster=g.monster});assert(not t.done)
    A.finishHand(g);A.finishHand(g)
end
assert(t.done and levels(g)==1)
assert(#D.getRandomShopPool({},999)==100)
print("SPN trials PASS: three-unlock gate, two distinct unlocked requests, any order, no duplicate progress, random equipped/self reward, one level once, copies/locks/reserve, preview/RNG, saved evolution and real hand lifecycle")
return true

local R=require("src.spn_reserves")
local D=require("src.deities")
local G=require("src.game_state")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local S=require("src.scoring")
local P=require("src.persistence")
local Combat=require("src.combat")
local Rng=require("src.rng")
local death,fury,gold,size,echo="spirit_ashen_legacy","spirit_unspent_fury","spirit_gilded_weight","spirit_open_horizon","spirit_lone_procession"
local function game(ids,n)
    local g=G.new();g.deities={};g.hand={};g.persistentDeck={};g.deck={};g.discardPile={};g.spnCombat={}
    g.monster={hp=100000,maxHp=100000,attack=1,attackSpeed=1};g.enemies={g.monster}
    for i=1,n or 4 do local c=Deck.newCard(i+2,"spades");c.disableFactionPassives=true;g.hand[i]=c;g.persistentDeck[i]=Deck.cloneCard(c) end
    for slot,id in ipairs(ids or {}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    A.start(g);return g
end
local function hand(g,n)
    local cards={};for i=1,n or 1 do cards[i]=g.hand[i] end
    return {type=require("src.poker").HAND_TYPES.HIGH_CARD,chips=10,mult=1,scoringCards=cards,unscoredCards={}}
end
local function preview(g,h) return S.calculate(h or hand(g),g.deities,{gameState=g,monster=g.monster,preview=true}) end
local function score(g,h)
    h=h or hand(g);local played={};for _,pile in ipairs({h.scoringCards,h.unscoredCards}) do for _,c in ipairs(pile) do played[#played+1]=c end end
    A.beginHand(g,h,played);g.handsRemaining=g.handsRemaining-1
    for _,c in ipairs(played) do for i=#g.hand,1,-1 do if g.hand[i]==c then g.discardPile[#g.discardPile+1]=table.remove(g.hand,i) end end end
    return S.calculate(h,g.deities,{gameState=g,monster=g.monster})
end
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local function step(r,slot)
    for _,s in ipairs(r.steps) do if s.type=="deity_hand" and s.slotIndex==slot then return s end end
end
local function events(r) local n=0;for _,s in ipairs(r.steps) do if s.type=="card_scored" then n=n+1 end end;return n end
local function lock(g,slot)
    g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=slot,untilHand=1}}
end
local g=game({death,"spirit_pebble"});local owned=g.deities[1]
assert(D.destroyDeity(g,2,true) and owned.spnGrowth.deathChips==.5)
assert(not D.destroyDeity(g,2,true) and owned.spnGrowth.deathChips==.5,"one physical destruction, one gain")
near(step(score(g),1).xChips,1.5)
D.evolve(owned);assert(D.addDeity(g,D.CATALOG.spirit_pebble,2));D.destroyDeity(g,2,true)
near(owned.spnGrowth.deathChips,1.25);near(step(preview(g),1).xChips,2.25)
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));near(loaded.deities[1].spnGrowth.deathChips,1.25)
assert(D.getDescription(loaded.deities[1]):find("2.25",1,true))
Combat.start(loaded,{hp=100000,maxHp=100000,attack=1,attackSpeed=1},2);near(loaded.deities[1].spnGrowth.deathChips,1.25)
g=game({death,"spirit_pebble"});require("src.shop").sellDeity(g,2);assert(not g.deities[1].spnGrowth)
assert(require("src.loadout").move(g,"spn","equipped",1,nil,false));assert(D.addDeity(g,D.CATALOG.spirit_pebble,2));D.destroyDeity(g,2,true)
assert(not g.backpackDeities[1].spnGrowth,"reserve cannot observe destruction")
g=game({death,"spirit_pebble"});lock(g,1);D.destroyDeity(g,2,true);assert(not g.deities[1].spnGrowth)
g=game({death,"spirit_phantom_heart"});g.playerHp=1;require("src.shop").payItem({currency="blood",cost=1000},g)
assert(g.deities[1].spnGrowth.deathChips==.5,"real self-destruction also counts outside combat")
g=game({death,"spirit_legacy_cocoon"});g.monster.isBoss=true;g.monster.hp=0
require("src.souls").awardKills(g);assert(g.deities[1].spnGrowth.deathChips==.5,"boss cocoon self-sacrifice notifies once")
g=game({"spirit_right_offering","spirit_pebble",death});local before=P.encode(g);local pre=preview(g)
assert(before==P.encode(g));local r=score(g);near(r.finalScore,pre.finalScore)
assert(g.deities[3].spnGrowth.deathChips==.5 and step(r,3).xChips==1.5,"later slot uses gain in the same hand")
g=game({death,"spirit_right_offering","spirit_pebble"});r=score(g)
assert(step(r,1).xChips==1 and g.deities[1].spnGrowth.deathChips==.5,"earlier slot gains for its next activation")
g=game({death});owned=g.deities[1];D.destroyDeity(g,1,true);assert(not owned.spnGrowth,"destroyed observer cannot feed itself")
g=game({"spirit_right_echo",death,"spirit_pebble"});D.evolve(g.deities[1]);D.destroyDeity(g,3,true)
assert(g.deities[1].mimicGrowth[death].deathChips==1 and g.deities[2].spnGrowth.deathChips==.5,"copier owns two gains independently")
g=game({death,"spirit_left_refrain","spirit_pebble"});D.destroyDeity(g,3,true);assert(g.deities[1].spnGrowth.deathChips==1.5)

for _,count in ipairs({0,1,3,8}) do
    g=game({fury});g.discardsRemaining=count;r=score(g)
    assert(step(r,1).addedChips==50*count and g.discardsRemaining==count)
end
g=game({fury});D.evolve(g.deities[1]);g.discardsRemaining=3;assert(step(score(g),1).addedChips==225)
g=game({"spirit_three_moons",fury},5);g.discardsRemaining=3
r=score(g,hand(g,5));assert(step(r,2).addedChips==100 and g.discardsRemaining==2,"an earlier SPN's discard payment reduces the bonus")
for _,count in ipairs({0,1,2,4,8,100}) do
    g=game({gold});g.gold=count;pre=preview(g);r=score(g)
    near(step(r,1).xChips,.25*count);near(pre.finalScore,r.finalScore);assert(g.gold==count)
    if count==0 then assert(r.totalChips==0 and r.finalScore==0) end
end
g=game({gold});g.gold=2;D.evolve(g.deities[1]);near(step(score(g),1).xChips,.75);assert(D.getDescription(g.deities[1]):find("0.375",1,true))
g=game({gold});g.gold=2;local baseline=game();baseline.gold=2
near(preview(g).totalChips,preview(baseline).totalChips*.5)

g=game({size});local base=g.maxHandSize
assert(A.handSize(g)==base+1);for _=1,5 do assert(A.handSize(g)==base+1 and g.maxHandSize==base) end
D.evolve(g.deities[1]);assert(A.handSize(g)==base+2)
g.hand={};for i=1,10 do g.deck[i]=Deck.newCard(3,"spades") end
Combat.drawCards(g,base);assert(#g.hand==base+2)
assert(require("src.loadout").move(g,"spn","equipped",1,nil,false));assert(A.handSize(g)==base)
assert(require("src.loadout").move(g,"spn","reserve",1,1,false));assert(A.handSize(g)==base+2)
lock(g,1);assert(A.handSize(g)==base)
g=game({"spirit_right_echo",size});D.evolve(g.deities[1]);assert(A.handSize(g)==g.maxHandSize+3)
g=game({size,"spirit_left_refrain"});assert(A.handSize(g)==g.maxHandSize+3)
g=game({"spirit_right_echo",death});before=P.encode(g);A.handSize(g);assert(before==P.encode(g),"capacity reads cannot initialize unrelated copied growth")
g=game({size});Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},1);assert(#g.hand==g.maxHandSize+1)
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},2);assert(#g.hand==g.maxHandSize+1)

g=game({echo},4);pre=preview(g);r=score(g);assert(events(r)==5 and #g.hand==3 and r.finalScore==pre.finalScore,"four held gives four EXTRA full card activations")
g=game({echo},4);D.evolve(g.deities[1]);assert(events(score(g))==9)
g=game({echo},4);assert(events(score(g,hand(g,2)))==2,"must play only one, not merely score one")
g=game({echo},4);local h=hand(g);h.unscoredCards={g.hand[2]};assert(events(score(g,h))==1,"one scored plus one unscored is still a two-card play")
g=game({echo},1);assert(events(score(g))==2,"selected card counts in the original held total")
g=game({"spirit_right_echo",echo},4);assert(events(score(g))==9)
g=game({echo,"spirit_left_refrain"},4);assert(events(score(g))==13)
g=game({echo},4);lock(g,1);assert(events(score(g))==1)
g=game({echo},4);g.hand[2].destroyed=true;assert(events(score(g))==4)
g=game({echo},4);h=hand(g);A.beginHand(g,h,h.scoringCards);local count=#g.abilityHand.queue
g.hand[#g.hand+1]=Deck.newCard(3,"spades");assert(count==5 and #g.abilityHand.queue==5,"later draws cannot enlarge the saved repeat count")
g=game({echo},4);g.deities[1].evolutionLevel=1000;assert(events(score(g))==128)
g=game({echo,"spirit_awakened_echo"},4);g.hand[1].evolutionLevel=8;assert(events(score(g))==12,"shares the existing finite queue with other repeat sources")
g=game({echo},4);local rng=Rng.getState();before=P.encode(g);preview(g);assert(before==P.encode(g) and rng==Rng.getState())
for _,row in ipairs(R.entries) do
    g=game();g.gold=100
    assert(require("src.shop").buyItem({items={{category="deity",deity=D.CATALOG[row[1]],cost=4}}},1,g))
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));assert(D.evolve(g.deities[1]))
    loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(loaded.deities[1].evolutionLevel==1)
end
assert(#D.getRandomShopPool({},99)==96)
print("SPN reserves PASS: destruction growth/offerings/cocoons/phantom/shop/locks/copies/save; remaining discards; exact direct gold coefficient including zero/fractions; dynamic evolved held capacity/draws; original-held single repeats/shared cap/preview/shop/evolution")
return true

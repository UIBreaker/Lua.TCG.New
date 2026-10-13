local P=require("src.spn_pacts")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Poker=require("src.poker")
local S=require("src.scoring")
local Rng=require("src.rng")
local Persistence=require("src.persistence")
local function card(rank) local c=Deck.newCard(rank or 3,"spades");c.disableFactionPassives=true;return c end
local function game(id)
    local g=Game.new();g.deities={};g.backpackDeities={};g.playerHp=100;g.playerArmor=0;g.playerShield=0
    g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
    g.persistentDeck={card(3),card(5),card(7),card(9),card(11)}
    g.hand={};g.discardPile={};g.spnCombat={}
    if id then assert(D.addDeity(g,D.CATALOG[id],1)) end
    return g
end
local function find(g,id) for _,c in ipairs(g.persistentDeck) do if c.id==id then return Deck.cloneCard(c) end end end
local function score(g,cards,preview)
    return S.calculate(assert(Poker.evaluate(cards)),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function factor(r)
    local f=1;for _,s in ipairs(r.steps) do if s.type=="deity_hand" then f=f*(s.xMult or 1) end end;return f
end
local function fixed(unit,fn)
    local original=Rng.random
    Rng.random=function(a,b) return a and (b and a or 1) or unit end
    local ok,err=pcall(fn);Rng.random=original;if not ok then error(err,0) end
end
local g=game("spirit_fated_mark");P.prepare(g);local owned=g.deities[1]
local ids=P.targets(g,owned);assert(#ids==1)
local selected=find(g,ids[1]);local rng=Rng.getState()
assert(factor(score(g,{selected},true))==10 and Rng.getState()==rng)
assert(factor(score(g,{selected}))==10 and factor(score(g,{card(selected.rank)}))==1,"physical identity, not rank/suit")
assert(factor(score(g,{selected,card(2)}))==1,"must play exactly one card")
D.evolve(owned);assert(factor(score(g,{selected}))==14.5)
assert(P.describe(g,owned):find(tostring(selected.id),1,true) and P.cardMark(g,selected))
local snapshot=Persistence.encode(g);P.cardMark(g,selected);assert(Persistence.encode(g)==snapshot,"read-only marks")
g.deities[4]=owned;g.deities[1]=nil;assert(P.targets(g,owned)==ids,"reordering keeps targets")
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},2)
assert(#P.targets(g,owned)==1 and P.targets(g,owned)~=ids,"new battle selects again")
g=game("spirit_threefold_ward");P.prepare(g);owned=g.deities[1];ids=P.targets(g,owned)
assert(#ids==3 and ids[1]~=ids[2] and ids[2]~=ids[3] and ids[1]~=ids[3])
local trio={find(g,ids[3]),find(g,ids[1]),find(g,ids[2])}
A.discard(g,trio,{playerDiscard=true,remainingBefore=2});assert(g.playerArmor==40 and g.playerShield==40)
D.evolve(owned);g.playerArmor=0;A.discard(g,trio,{playerDiscard=true,remainingBefore=0,bloodPaid=false});assert(g.playerArmor==60)
g.playerArmor=0;A.discard(g,{trio[1],trio[2],card(trio[3].rank)},{playerDiscard=true,remainingBefore=1});assert(g.playerArmor==0)
A.discard(g,trio);assert(g.playerArmor==0,"forced discard excluded")
A.discard(g,trio,{playerDiscard=true,preview=true});assert(g.playerArmor==0,"preview excluded")
g.playerArmor=980;A.discard(g,trio,{playerDiscard=true});assert(g.playerArmor==999)
g=game("spirit_threefold_ward");g.persistentDeck={card(3),card(4)};P.prepare(g)
assert(#P.targets(g,g.deities[1])==0)
g=game("spirit_fated_mark");assert(D.addDeity(g,D.CATALOG.spirit_right_echo,2))
g.deities[1],g.deities[2]=g.deities[2],g.deities[1];P.prepare(g)
local copy=g.deities[1];local proxy=D.resolveDeity(g.deities,1,g)
assert(#P.targets(g,proxy)==1 and #P.targets(g,g.deities[2])==1 and copy.id=="spirit_right_echo")

-- Level 8 means one original plus seven full scoring jobs, and cannot recursively grow.
local function events(r) local n=0;for _,s in ipairs(r.steps) do if s.type=="card_scored" then n=n+1 end end;return n end
g=game("spirit_awakened_echo");local c=card(3);c.evolutionLevel=8;g.hand={c};g.persistentDeck={Deck.cloneCard(c)}
local h=assert(Poker.evaluate({c}));rng=Rng.getState();local preview=score(g,{c},true)
assert(events(preview)==8 and Rng.getState()==rng)
A.start(g);A.beginHand(g,h,{c});local actual=score(g,{c})
assert(events(actual)==8 and actual.finalScore==preview.finalScore)
A.finishHand(g);D.evolve(g.deities[1]);g.hand={c};A.beginHand(g,h,{c});actual=score(g,{c});assert(events(actual)==16)
local queue={};for i=1,5 do queue[#queue+1]={card=c,index=i} end
g.deities[2]=g.deities[1];g.deities[3]=g.deities[1];g.deities[4]=g.deities[1]
P.queueRepeats(g,{c,c,c,c,c},queue);assert(#queue==128,"shared global trigger cap")
g.abilityHand=nil;c.edition="echo"
assert(events(score(g,{c},true))<=128,"echo edition also respects the full preview queue cap")
g=game("spirit_awakened_echo");c=card(3);c.evolutionLevel=0;assert(events(score(g,{c},true))==1)
c.evolutionLevel=1;assert(events(score(g,{c},true))==1)
c.evolutionLevel=8;g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(events(score(g,{c},true))==1,"locked repeat source is excluded")
g=game();g.backpackDeities={D.CATALOG.spirit_awakened_echo};assert(events(score(g,{c},true))==1)
g=game("spirit_awakened_echo");g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));c=card(3);c.evolutionLevel=8
assert(events(score(g,{c},true))==15,"copied repeat source adds seven more jobs without recursive loops")

-- Pay once even with multiple blood SPNs/copies; never spend a normal discard or lethal HP.
g=game("spirit_blood_bargain");g.discardsRemaining=0
assert(P.canDiscard(g) and P.payDiscard(g)==true and g.playerHp==80 and g.discardsRemaining==0)
require("src.spn_anomalies").showFeedback(g,{floatingTexts={}})
g.playerHp=20;assert(not P.canDiscard(g) and P.payDiscard(g)==nil and g.playerHp==20)
g.playerHp=21;assert(P.payDiscard(g)==true and g.playerHp==1)
g.playerHp=80;g.discardsRemaining=1;assert(P.payDiscard(g)==false and g.playerHp==80)
g.discardsRemaining=0;g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(not P.canDiscard(g))
g=game();g.discardsRemaining=0;g.backpackDeities={D.CATALOG.spirit_blood_bargain};assert(not P.canDiscard(g))
g=game("spirit_blood_bargain");g.discardsRemaining=0
local target={};for k,v in pairs(D.CATALOG.spirit_pebble) do target[k]=v end
g.deities[2]=target;D.evolve(target);D.evolve(target)
fixed(.005,function() P.bloodReward(g) end);assert(D.getRarityBadge(g.deities[1])=="C" and D.getRarityBadge(target)=="R","0.5% boundary excluded")
D.setRarity(g.deities[1],"unique")
fixed(0,function() P.bloodReward(g) end)
assert(D.getRarityBadge(target)=="UQ" and target.evolutionLevel==2,"exact UQ keeps evolution")
local calls=0;local original=Rng.random;Rng.random=function() calls=calls+1;return 0 end
P.bloodReward(g);Rng.random=original;assert(calls==0,"no rolls if every equipped SPN is already UQ or higher")
g=game("spirit_blood_bargain");D.evolve(g.deities[1])
assert(D.scaleEffect(g.deities[1],{uqChancePct=.5}).uqChancePct==.75)
fixed(.00749,function() P.bloodReward(g) end);assert(D.getRarityBadge(g.deities[1])=="UQ")
g=game("spirit_blood_bargain");g.discardsRemaining=0
fixed(0,function()
    assert(P.payDiscard(g)==true)
    A.discard(g,{card(3)},{playerDiscard=true,remainingBefore=0,bloodPaid=true})
end)
assert(D.getRarityBadge(g.deities[1])=="UQ" and g.playerHp==80)
g=game("spirit_blood_bargain");fixed(0,function() A.discard(g,{card(3)},{playerDiscard=true,preview=true,bloodPaid=true}) end)
assert(D.getRarityBadge(g.deities[1])=="C","discard preview cannot promote anything")
g=game("spirit_blood_bargain");g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));g.discardsRemaining=0
fixed(0,function()
    assert(P.payDiscard(g)==true)
    A.discard(g,{card(3)},{playerDiscard=true,remainingBefore=0,bloodPaid=true})
end)
assert(g.playerHp==80 and g.deities[1].id=="spirit_right_echo" and D.getRarityBadge(g.deities[1])=="UQ"
    and D.getRarityBadge(g.deities[2])=="UQ","one HP payment, promotion uses physical copier/source")
local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(restored.deities[1].id=="spirit_right_echo" and D.getRarityBadge(restored.deities[1])=="UQ")
local catalogCount=0;for _ in pairs(D.CATALOG) do catalogCount=catalogCount+1 end
assert(#D.getRandomShopPool({},catalogCount)==catalogCount)
print("SPN pacts PASS: unique physical battle targets/marks/reset, exact single/triple conditions, full level repeats/evolution/caps, nonlethal blood payment, exact evolving odds/UQ, locks/reserves/mimic/preview/save")

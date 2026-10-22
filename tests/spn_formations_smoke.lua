local D=require("src.deities")
local G=require("src.game_state")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local S=require("src.scoring")
local Poker=require("src.poker")
local P=require("src.persistence")
local Rng=require("src.rng")
local march,reprise,mercy,edge,oath="spirit_march_covenant","spirit_vanguard_reprise","spirit_breath_of_mercy","spirit_fourfold_edge","spirit_quartet_oath"
local suits={"hearts","spades","clubs","diamonds","hearts"}
local function game(ids,ranks,suit)
    local g=G.new();g.deities={};g.hand={};g.deck={};g.discardPile={};g.persistentDeck={};g.maxHandSize=5
    g.monster={hp=100000,maxHp=100000,attack=1,attackSpeed=1};g.enemies={g.monster};g.playerHp=50;g.maxPlayerHp=200
    for i,rank in ipairs(ranks or {2,3,4,5,6}) do local c=Deck.newCard(rank,suit or suits[i] or "spades")
        c.disableFactionPassives=true;g.hand[i]=c;g.persistentDeck[i]=Deck.cloneCard(c) end
    for slot,id in ipairs(ids or {}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    A.start(g);return g
end
local function hand(g) return assert(Poker.evaluate(g.hand)) end
local function score(g,h,preview)
    h=h or hand(g)
    return S.calculate(h,g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function live(g,h)
    h=h or hand(g);local played=require("src.spn_formations").played(h)
    A.beginHand(g,h,played);g.handsRemaining=g.handsRemaining-1
    for _,c in ipairs(played) do for i=#g.hand,1,-1 do if g.hand[i]==c then g.discardPile[#g.discardPile+1]=table.remove(g.hand,i) end end end
    return score(g,h)
end
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local function steps(r,slot,key)
    local value,count=0,0;for _,s in ipairs(r.steps) do
        if s.type=="deity_hand" and s.slotIndex==slot then value=value+(s[key] or 0);count=count+1 end
    end;return value,count
end
local function events(r)
    local count,byCard=0,{};for _,s in ipairs(r.steps) do if s.type=="card_scored" then count=count+1;byCard[s.card.id]=(byCard[s.card.id] or 0)+1 end end
    return count,byCard
end
local function lock(g,slot) g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=slot,untilHand=1}} end
local g=game({march});local h=hand(g);assert(h.type.id=="straight")
local r=score(g);assert(steps(r,1,"addedChips")==50 and r.healHp==10 and g.playerHp==50)
D.evolve(g.deities[1]);r=score(g);assert(steps(r,1,"addedChips")==75 and r.healHp==15)
assert(D.getDescription(g.deities[1]):find("7.5",1,true))
g=game({march},{2,3,4});assert(hand(g).type.id=="straight" and steps(score(g),1,"addedChips")==50)
g=game({march},nil,"spades");assert(hand(g).type.id=="straight_flush" and select(2,steps(score(g),1,"addedChips"))==0)
g=game({march},{2,2,7,8,9});assert(select(2,steps(score(g),1,"addedChips"))==0)
for _,ranks in ipairs({{3},{3,3},{2,3,4},{2,3,4,5},{2,3,4,5,6}}) do
    g=game({mercy},ranks);assert(score(g).healHp==10,"heal once per hand, independent of card count")
end
g=game({mercy});D.evolve(g.deities[1]);assert(score(g).healHp==15)
g=game({"spirit_right_echo",mercy});D.evolve(g.deities[1]);assert(score(g).healHp==30)
g=game({mercy,"spirit_left_refrain"});assert(score(g).healHp==30)

g=game({reprise});h=hand(g);assert(events(score(g,h))==10,"first 2 gives total two activations per scored card")
g=game({reprise},{5,5,6,6,6});h=hand(g);local total,counts=events(score(g,h));assert(total==25)
for _,c in ipairs(h.scoringCards) do assert(counts[c.id]==5) end
g=game({reprise},{6,5,6,5,6});assert(events(score(g))==30,"uses visual first, not minimum rank")
g=game({reprise},{14,2,3,4,5});assert(events(score(g))==5,"Ace is one")
g=game({reprise},{11,11,11,12,12});assert(events(score(g))==55)
g=game({reprise},{13,13,13,12,12});assert(events(score(g))==65)
g=game({reprise},{2,9,9,4,7});h=hand(g)
assert(h.playedCards[1]==g.hand[1] and h.scoringCards[1].rank==9)
local before=P.encode(g);local rng=Rng.getState();local pre=score(g,h,true)
assert(events(pre)==4 and before==P.encode(g) and rng==Rng.getState(),"unscored first card and pure preview")
r=live(g,h);assert(events(r)==4 and r.finalScore==pre.finalScore)
g=game({reprise,march,mercy,"spirit_pebble"});h=hand(g);r=score(g,h)
assert(events(r)==10 and r.baseChips==h.chips and r.baseMult==h.mult)
assert(select(2,steps(r,2,"addedChips"))==1 and steps(r,4,"addedChips")==20 and r.healHp==20,"no repeated hand SPN or base hand")
g=game({reprise},{2,3,4,5});assert(events(score(g))==1,"exactly five played cards required")
g=game({reprise});D.evolve(g.deities[1]);assert(events(score(g))==20)
g=game({reprise});g.deities[1].evolutionLevel=1000;assert(events(score(g))==128)
g=game({"spirit_right_echo",reprise});assert(events(score(g))==15)
g=game({reprise,"spirit_left_refrain"});assert(events(score(g))==20)

g=game({edge},{3,3,7,9});h=hand(g);local base=game({}, {3,3,7,9})
local plain=score(base);r=score(g,h)
near(r.totalChips-r.baseChips,2*(plain.totalChips-plain.baseChips));assert(r.baseChips==plain.baseChips)
assert(events(r)==2,"unscored cards never become scored")
local c=g.hand[1];c.bonusBaseChips=11;c.baseChips=14;c.equipments={require("src.equipment").ITEMS.gem_fire}
assert(D.addDeity(g,D.CATALOG.spirit_blade,2));assert(D.addDeity(g,D.CATALOG.spirit_pebble,3))
local owned=g.deities[1];g.deities[1]=nil;plain=score(g,h);g.deities[1]=owned;r=score(g,h)
near(r.totalChips,plain.baseChips+(plain.totalChips-plain.baseChips-20)*2+20)
assert(c.baseChips==14 and c.bonusBaseChips==11,"local contribution scaling never changes owned stats")
D.evolve(owned);r=score(g,h);near(r.totalChips,plain.baseChips+(plain.totalChips-plain.baseChips-20)*2.5+20)
g=game({edge},{3,3,3});base=game({}, {3,3,3});near(score(g).totalChips,score(base).totalChips)
g=game({edge},{3,3,3,3});r=score(g)
for _,s in ipairs(r.steps) do if s.type=="card_scored" then assert(s.addedChips==6 and #s.presentationTriggers>=1) end end
g=game({"spirit_right_echo",edge},{3,3,3,3});r=score(g);assert(r.totalChips==r.baseChips+4*3*4)

g=game({oath},{7,7,7,7});r=score(g);assert(steps(r,1,"xMult")==4 and steps(r,1,"xChips")==1)
g=game({oath},{7,7,7,7},"spades");r=score(g);assert(steps(r,1,"xChips")==4 and steps(r,1,"xMult")==1)
D.evolve(g.deities[1]);assert(steps(score(g),1,"xChips")==5.5)
g=game({oath},{7,7,7,7});D.evolve(g.deities[1]);assert(steps(score(g),1,"xMult")==5.5)
g=game({oath},{7,7,7,8},"spades");assert(select(2,steps(score(g),1,"xChips"))==0,"same rank remains required")
g=game({oath},{7,7,7});assert(select(2,steps(score(g),1,"xChips"))==0)
g=game({oath},{7,7,7,7},"spades");g.hand[4].suit="vharos";assert(steps(score(g),1,"xChips")==4,"canonical suit aliases")
g=game({oath},{7,7,7,7},"spades");g.hand[4].suit="hearts";require("src.card_effects").setEffect(g.hand[4],"astral")
assert(steps(score(g),1,"xChips")==4,"wild suit can join the matching suit branch")

for _,row in ipairs(require("src.spn_formations").entries) do
    local ranks=(row[1]==edge or row[1]==oath) and {7,7,7,7} or nil
    g=game({row[1]},ranks);before=P.encode(g);rng=Rng.getState();h=hand(g);pre=score(g,h,true)
    assert(before==P.encode(g) and rng==Rng.getState(),row[1].." preview purity")
    r=live(g,h);near(r.finalScore,pre.finalScore);near(r.healHp,pre.healHp)
    g=game({row[1]},ranks);lock(g,1);r=score(g)
    assert(select(2,steps(r,1,"addedChips"))==0 and r.healHp==0)
    g=game({},ranks);g.backpackDeities={D.CATALOG[row[1]]};plain=score(g);assert(plain.healHp==0)
    g.gold=100;g.backpackDeities={}
    assert(require("src.shop").buyItem({items={{category="deity",deity=D.CATALOG[row[1]],cost=4}}},1,g))
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));assert(D.evolve(g.deities[1]))
    local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(loaded.deities[1].evolutionLevel==1)
end
assert(#D.getRandomShopPool({},999)==100)
print("SPN formations PASS: exact marching hand/heal/evolution; five-card first-in-play-order full card repeats/no base or hand-SPN repeats/cap/A/J/Q/K/preview; percent heal; per-card local damage/equipment/SPN/evolution; exclusive four-kind suit branches/wild/aliases; locks/reserves/shop/save")
return true

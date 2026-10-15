local G=require("src.spn_growth")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Poker=require("src.poker")
local S=require("src.scoring")
local P=require("src.persistence")
local Rng=require("src.rng")
local function card(rank)
    local c=Deck.newCard(rank or 2,"spades");c.disableFactionPassives=true;return c
end
local function game(id)
    local g=Game.new();g.deities={};g.persistentDeck={card(),card(),card(9)};g.masterDeck=g.persistentDeck
    g.hand={Deck.cloneCard(g.persistentDeck[1]),Deck.cloneCard(g.persistentDeck[2]),Deck.cloneCard(g.persistentDeck[3])}
    g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1};g.spnCombat={}
    if id then assert(D.addDeity(g,D.CATALOG[id],1)) end;return g
end
local function score(g,cards,preview)
    return S.calculate(assert(Poker.evaluate(cards)),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function handBonus(r)
    local n=0;for _,s in ipairs(r.steps) do if s.type=="deity_hand" and s.effectiveDeity.id=="spirit_golden_tithe" then n=n+(s.addedChips or 0) end end;return n
end
local g=game("spirit_battle_memory");local two=g.hand[1]
g.deck={Deck.cloneCard(two)};g.discardPile={two} -- Same reference in two piles must be updated only once.
local rng=Rng.getState();local before=P.encode(P.makeSnapshot(g,"combat"))
local preview=score(g,{two},true);local again=score(g,{two},true)
assert(preview.finalScore==again.finalScore and Rng.getState()==rng and before==P.encode(P.makeSnapshot(g,"combat")),"preview stays pure")
local actual=score(g,{two});assert(actual.finalScore==preview.finalScore)
assert(two.baseChips==6 and two.bonusBaseChips==4 and g.persistentDeck[1].baseChips==6 and g.deck[1].baseChips==6,"sync physical identity without double updates")
assert(not g.persistentDeck[2].bonusBaseChips,"other cards do not gain")
score(g,{two});assert(two.baseChips==10 and g.persistentDeck[1].bonusBaseChips==8,"each new hand grants again")
local restored=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
assert(restored.persistentDeck[1].baseChips==10 and restored.persistentDeck[1].bonusBaseChips==8)
Combat.start(restored,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},1)
for _,c in ipairs(restored.hand) do if c.id==two.id then assert(c.baseChips==10) end end
D.evolve(g.deities[1]);score(g,{two});assert(two.baseChips==16 and D.getDescription(g.deities[1]):find("+6",1,true))

-- Full card repeats reuse the upgraded base but grant no additional permanent stack.
g=game("spirit_battle_memory");assert(D.addDeity(g,D.CATALOG.spirit_second_wave,2));two=g.hand[1]
preview=score(g,{two},true);actual=score(g,{two})
assert(actual.finalScore==preview.finalScore and two.bonusBaseChips==4 and g.persistentDeck[1].bonusBaseChips==4)
assert(actual.totalChips==actual.baseChips+12,"two activations each score the new six-point base")
g=game("spirit_battle_memory");assert(D.addDeity(g,D.CATALOG.spirit_awakened_echo,2));two=g.hand[1];two.evolutionLevel=8
preview=score(g,{two},true);actual=score(g,{two})
assert(actual.finalScore==preview.finalScore and actual.totalChips==actual.baseChips+48 and two.bonusBaseChips==4)
g=game("spirit_battle_memory");g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1]);two=g.hand[1]
assert(D.addDeity(g,D.CATALOG.spirit_second_wave,3));score(g,{two})
assert(two.bonusBaseChips==12,"two copied SPN activations plus source, each once per card")
g=game("spirit_battle_memory");g.hand[3].suit="hearts";local cards={g.hand[1],g.hand[2],g.hand[3]};score(g,cards)
assert(cards[1].bonusBaseChips==4 and cards[2].bonusBaseChips==4 and (cards[3].bonusBaseChips or 0)==0,"only scoring cards, not a pair kicker")
g=game("spirit_battle_memory");two=g.hand[1];two.isPrimalDrone=true;two.baseChips=50;two.bonusBaseChips=50;g.persistentDeck[1]=Deck.cloneCard(two)
score(g,{two});Deck.restoreDeck(g.persistentDeck);assert(g.persistentDeck[1].baseChips==54)
local drone=Deck.cloneCard(g.persistentDeck[1]);Deck.addCardToDeck(g,drone);assert(drone.baseChips==54,"drone's permanent bonus survives restore and insertion")
restored=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(restored.persistentDeck[1].baseChips==54)
g=game("spirit_battle_memory");two=g.hand[1];score(g,{two});Deck.upgradeCard(two)
assert(two.baseChips==7);Deck.degradeCard(two);assert(two.baseChips==6,"rank changes preserve permanent growth")

-- Live ability queue and the isolated preview agree, including card reactivations.
g=game("spirit_battle_memory");assert(D.addDeity(g,D.CATALOG.spirit_second_wave,2));two=g.hand[1]
A.start(g);preview=score(g,{two},true);A.beginHand(g,assert(Poker.evaluate({two})),{two});actual=score(g,{two})
assert(preview.finalScore==actual.finalScore and two.bonusBaseChips==4)
A.finishHand(g)

for _,id in ipairs({"spirit_battle_memory","spirit_golden_tithe"}) do
    g=game(id);g.gold=19;g.monster.isBoss=true
    g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
    score(g,{g.hand[1]});assert((g.hand[1].bonusBaseChips or 0)==0 and handBonus(score(g,{g.hand[1]},true))==0)
    g=game();g.gold=19;g.backpackDeities={D.CATALOG[id]};score(g,{g.hand[1]})
    assert((g.hand[1].bonusBaseChips or 0)==0 and handBonus(score(g,{g.hand[1]}))==0,"reserve is inactive")
end
g=game("spirit_golden_tithe")
for _,gold in ipairs({0,4,5,9,10,14,15,19,20,103}) do
    g.gold=gold;preview=score(g,{g.hand[1]},true);actual=score(g,{g.hand[1]})
    assert(handBonus(actual)==math.floor(gold/5)*10 and actual.finalScore==preview.finalScore and g.gold==gold,"complete five-gold groups, no spending")
end
D.evolve(g.deities[1]);g.gold=19;assert(handBonus(score(g,{g.hand[1]}))==45)
assert(D.getDescription(g.deities[1]):find("+15",1,true))
local res=D.CATALOG.spirit_golden_tithe.onHandScored({}, {goldAvailable=9,gameState={gold=100}})
assert(res.addChips==10,"use the current sequential gold budget")
g=game("spirit_golden_tithe");g.gold=19;g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));assert(handBonus(score(g,{g.hand[1]}))==60)
for _,row in ipairs(G.entries) do
    g=game();g.gold=100
    assert(require("src.shop").buyItem({items={{category="deity",deity=D.CATALOG[row[1]],cost=4}}},1,g))
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));assert(D.evolve(g.deities[1]))
    restored=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
    assert(restored.deities[1].id==row[1] and restored.deities[1].evolutionLevel==1)
end
assert(#D.getRandomShopPool({},99)==83)
print("SPN growth PASS: permanent per-card/hand claims, full repeats, mirror activations, sync/drones/next battle/save, pure live previews, complete gold groups/evolution/no spending, locks/reserve/shop")

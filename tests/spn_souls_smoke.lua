local D=require("src.deities")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local Game=require("src.game_state")
local Souls=require("src.souls")
local Scoring=require("src.scoring")
local Poker=require("src.poker")
local Persistence=require("src.persistence")
local Rng=require("src.rng")
local function game(ids,level)
    local g=Game.new();g.deities={};g.hand={};g.deck={};g.discardPile={};g.persistentDeck={};g.souls=0
    g.discardsRemaining=3;g.handsRemaining=4;g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
    local card=Deck.newCard(9,"spades");card.evolutionLevel=2;card.edition="foil";card.equipments={require("src.equipment").ITEMS.basic_lace}
    Deck.addCardToDeck(g,card);Deck.addCardToDeck(g,Deck.newCard(4,"clubs"))
    for slot,id in ipairs(ids) do
        assert(D.addDeity(g,D.CATALOG[id],slot))
        for i=1,level or 0 do D.evolve(g.deities[slot]) end
    end
    return g,Deck.cloneCard(card),card
end
local function discard(g,cards,options)
    local context={playerDiscard=true,remainingBefore=g.discardsRemaining}
    for k,v in pairs(options or {}) do context[k]=v end
    A.discard(g,cards,context)
end
local g,card,canonical=game({"spirit_dawn_reaper"})
local value=Souls.value(card);local id=card.id;local rng=Rng.getState()
g.deck={Deck.cloneCard(card)};g.discardPile={Deck.cloneCard(card)}
discard(g,{card})
assert(card.destroyed and canonical.destroyed and #g.persistentDeck==1 and #g.deck==0 and #g.discardPile==0)
assert(g.souls==value*3 and Rng.getState()==rng,"triple full value incl. gear/evolution/edition, with no RNG")
assert(g.soulDestroyedIds[tostring(id)] and Souls.award(g,canonical)==0 and not A.destroy(g,card,nil,3))
local destroyed=0;for _,e in ipairs(A.takeFeedback(g)) do if e.kind=="destroy" then destroyed=destroyed+1 end end
assert(destroyed==1,"one destruction event despite live/persistent copies")
discard(g,{card});assert(g.souls==value*3,"cannot harvest an already destroyed card")

for _,options in ipairs({{playerDiscard=false},{preview=true},{handsPlayedBefore=1}}) do
    g,card=game({"spirit_dawn_reaper"});discard(g,{card},options);assert(not card.destroyed and g.souls==0)
end
g,card=game({"spirit_dawn_reaper"});A.discard(g,{card});assert(not card.destroyed,"forced discards cannot harvest")
g,card=game({"spirit_dawn_reaper"});g.handsPlayedThisCombat=1;discard(g,{card});assert(not card.destroyed)
g,card=game({"spirit_dawn_reaper"});g.abilityCombat={playIndex=1};discard(g,{card});assert(not card.destroyed)
g,card=game({"spirit_dawn_reaper"});discard(g,{});assert(g.souls==0)
g,card=game({"spirit_dawn_reaper"});discard(g,{card,Deck.newCard(3,"hearts")});assert(not card.destroyed)
g,card=game({"spirit_dawn_reaper"});discard(g,{card},{freeDiscard=true});assert(card.destroyed,"free player discard still meets the sacrifice condition")
g,card=game({"spirit_dawn_reaper"});table.remove(g.persistentDeck,2);discard(g,{card});assert(not card.destroyed,"never destroy the last persistent card")
g,card=game({"spirit_dawn_reaper"});g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
discard(g,{card});assert(not card.destroyed,"locked SPN cannot harvest")
g,card=game({"spirit_dawn_reaper","spirit_dawn_reaper"});value=Souls.value(card);discard(g,{card});assert(g.souls==3*value,"two reapers cannot pay for the same lost card twice")
for level=0,7 do
    g,card=game({"spirit_dawn_reaper"},level);value=Souls.value(card);discard(g,{card})
    assert(g.souls==value*(3+level) and D.getDescription(g.deities[1]):find("×"..(3+level),1,true))
end

-- SPNs resolve left to right; a remnant can copy a card before the reaper destroys its original.
g,card=game({"spirit_last_remnant","spirit_dawn_reaper"});g.discardsRemaining=1;discard(g,{card})
assert(#g.persistentDeck==2 and #g.discardPile==1 and g.discardPile[1].id~=card.id)
g,card=game({"spirit_dawn_reaper","spirit_last_remnant"});g.discardsRemaining=1;discard(g,{card})
assert(#g.persistentDeck==1 and #g.discardPile==0,"a destroyed card cannot become a later remnant")

local played=Deck.newCard(3,"hearts");played.disableFactionPassives=true
local hand=assert(Poker.evaluate({played}))
local function score(g,preview) return Scoring.calculate(hand,g.deities,{gameState=g,monster=g.monster,preview=preview}) end
local function bonus(result)
    for _,step in ipairs(result.steps) do if step.type=="deity_hand" and step.deity.id=="spirit_soul_choir" then return step.addedMult end end
    return 0
end
g=game({"spirit_soul_choir"})
assert(bonus(score(g))==0)
for _,souls in ipairs({1,17,10000}) do
    g.souls=souls;rng=Rng.getState();local preview=score(g,true)
    assert(bonus(preview)==souls and bonus(score(g))==souls and g.souls==souls and Rng.getState()==rng)
end
g.souls=10;D.evolve(g.deities[1]);assert(bonus(score(g))==15)
D.evolve(g.deities[1]);assert(bonus(score(g))==20)
g.souls=2;assert(bonus(score(g))==4,"bonus follows current balance, not cumulative souls earned")
g=game({"spirit_soul_furnace","spirit_soul_choir"});g.souls=10
local preview=score(g,true);assert(bonus(preview)==7 and g.souls==10)
assert(bonus(score(g))==7 and g.souls==7,"previous SPN spending reduces souls available at the choir slot")
g=game({"spirit_soul_choir","spirit_soul_furnace"});g.souls=10;assert(bonus(score(g))==10 and g.souls==7)
g=game({"spirit_soul_choir"});g.souls=10;g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(bonus(score(g))==0)

g,card=game({"spirit_dawn_reaper","spirit_soul_choir"},2);value=Souls.value(card);discard(g,{card})
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(saved.souls==5*value and #saved.persistentDeck==1 and saved.deities[1].onDiscard and saved.deities[2].onHandScored)
assert(saved.deities[1].evolutionLevel==2 and bonus(score(saved))==saved.souls*2)
assert(#D.getRandomShopPool({},99)==57)
print("SPN souls PASS: opening single discard, triple/full soul value, evolving yield, permanent destruction, one receipt, discard order, held-soul Mult, preview/spending order, locks and save/load")

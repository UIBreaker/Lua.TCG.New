local D=require("src.deck")
local C=require("src.combat")
local G=require("src.game_state")
local M=require("src.monster")
local P=require("src.persistence")
local g=G.new("red_deck");g.deities={};g.persistentDeck={}
for i=1,8 do
    local card=D.newCard(i+1,"clubs");card.baseMult=3;card.trainingEmpowerment=2;card.speedBonus=4
    g.persistentDeck[i]=card
end
C.start(g,M.create(1,false,false,1),1)
g.spnDiscardCap=5;g.turnHandLimit=4;g.playerHp=1000
local old={};for _,pile in ipairs({g.hand,g.deck,g.discardPile}) do
    for _,c in ipairs(pile) do old[c]={D.getCardDamage(c),D.getCardEmpowerment(c),D.peekCardAttackSpeed(c)} end
end
for round=1,4 do
    g.handsRemaining=0;g.discardsRemaining=0
    g.discardPile[#g.discardPile+1]=table.remove(g.hand)
    local drawn=C.reshuffleExhaustedHand(g,3)
    assert(drawn==3 and #g.hand==3 and #g.deck==5 and #g.discardPile==0)
    assert(g.combatReshuffles==round and g.handsRemaining==4 and g.discardsRemaining==5)
    local seen={};local count=0
    for _,pile in ipairs({g.hand,g.deck}) do for _,card in ipairs(pile) do
        assert(not seen[card.id]);seen[card.id]=true;count=count+1
        assert(card.combatFatigue==round and not card.selected)
        assert(D.getCardDamage(card)==math.max(0,old[card][1]-round))
        assert(D.getCardEmpowerment(card)==math.max(0,old[card][2]-round))
        assert(D.peekCardAttackSpeed(card)==math.max(0,old[card][3]-round))
    end end
    assert(count==8 and #g.selectedIndices==0)
    assert(C.reshuffleExhaustedHand(g,3)==0 and g.combatReshuffles==round,"repeated calls cannot charge fatigue twice")
end
for _,c in ipairs(g.persistentDeck) do assert(not c.combatFatigue and c.trainingEmpowerment==2 and c.speedBonus==4) end
local c=g.hand[1];c.combatFatigue=1000
assert(D.getCardDamage(c)==0 and D.getCardEmpowerment(c)==0 and D.peekCardAttackSpeed(c)==0)
assert(D.getCardDamage(c,nil,20)==0 and D.getCardEmpowerment(c,nil,20)==0,"temporary bonuses must be included before the zero floor")
local Scoring=require("src.scoring");local Poker=require("src.poker")
c.disableFactionPassives=true
g.potionCombat={damageCards={[c.id]=20},multCards={[c.id]=10}}
local score=Scoring.calculate(Poker.evaluate({c},{high_card=true}),{}, {gameState=g,preview=true})
local scored=0
for _,event in ipairs(score.steps or {}) do
    if event.type=="card_scored" then scored=scored+1;assert(event.addedChips==0 and event.addedMult==0) end
end
assert(scored==1,"verify the real scoring event, not only stat getters")
local fx=require("ui.reshuffle_effects");local rng=require("src.rng")
local state=rng.getState()
for _,fps in ipairs({30,60,144}) do
    fx.clear();fx.emit(c,{damage=1,speed=1,empowerment=1})
    for i=1,math.ceil(fps*1.3) do
        fx.update(1/fps)
        assert(fx.pose(c,true)==0 and fx.pose(c,false)>=0 and fx.pose(c,false)<=4)
    end
    assert(fx.pose(c,false)==0)
end
assert(rng.getState()==state,"fatigue effects cannot consume gameplay RNG")
g.handsRemaining=0;g.playerHp=0
assert(C.reshuffleExhaustedHand(g,3)==0,"defeated players cannot reshuffle")
local snapshot=P.makeSnapshot(g,"shop")
assert(not snapshot.game.combatReshuffles)
local loaded=assert(P.restoreSnapshot(snapshot))
for _,card in ipairs(loaded.persistentDeck) do assert(not card.combatFatigue) end
g.playerHp=1000;C.start(g,M.create(1,false,false,2),2)
assert(g.combatReshuffles==0)
for _,pile in ipairs({g.hand,g.deck}) do for _,card in ipairs(pile) do
    assert((card.combatFatigue or 0)==0 and card.trainingEmpowerment==2 and card.speedBonus==4)
end end
local needle=M.create(1,true,false,1)
needle.bossData={debuffId="the_needle"};g.monster=needle;g.handsRemaining=0
assert(C.getOutcome(g)=="continue","one-hand bosses use fatigue rollover instead of an exhausted-hand defeat")
local one=D.newCard(2,"clubs");local lost=D.newCard(3,"clubs");lost.destroyed=true
local two=D.newCard(4,"clubs")
local tiny={playerHp=10,handsRemaining=0,maxHands=3,maxDiscards=3,hand={one},deck={one,lost},discardPile={two},deities={}}
assert(C.reshuffleExhaustedHand(tiny,3)==2 and #tiny.hand==2 and #tiny.deck==0)
assert(tiny.hand[1]~=tiny.hand[2] and tiny.hand[1]~=lost and tiny.hand[2]~=lost,"never duplicate or revive destroyed cards")
print("Combat fatigue PASS: full-pile shuffle, refill caps, cumulative three-stat reduction to zero, no duplicate cards/charges, scoring, persistent upgrades, save isolation and new-combat reset")

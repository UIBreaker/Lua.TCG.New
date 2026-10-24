local D=require("src.deck")
local B=require("src.boss_abilities")
local P=require("src.poker")
local S=require("src.scoring")
local A=require("src.card_abilities")
local function fixture()
    local g=require("src.game_state").new()
    g.hand={D.newCard(7,"hearts"),D.newCard(7,"clubs")};g.deck={};g.discardPile={};g.deities={}
    g.monster={isBoss=true,hp=1000,maxHp=1000,bossData={debuffId="the_hook"},
        bossState={handIndex=1,passiveUntil=0,activeUntil=0,slotLock=nil}}
    A.start(g);g.hand[2].abilityDisabledUntil=1
    return g,g.hand[1],g.hand[2]
end
local g,a,b=fixture()
assert(B.isAbilityDisabled(g,b) and #B.playableCards(g,g.hand)==1)
assert(P.evaluate(g.hand).type.id=="pair")
local h=P.evaluate(g.hand,nil,nil,g)
assert(h.type.id=="high_card" and #h.playedCards==1 and h.playedCards[1]==a)
local callbacks=0
g.deities={{id="test_disabled_probe",name="Probe",rarity="common",onCardScored=function(c)
    assert(c~=b,"disabled card cannot trigger SPN");callbacks=callbacks+1;return {addChips=1}
end,onHandScored=function(hand)
    assert(hand.type.id~="pair" and #hand.playedCards==1,"disabled card cannot satisfy a SPN formation")
end}}
local legacy=P.evaluate(g.hand)
local ctx=A.beginHand(g,legacy,g.hand)
assert(#ctx.played==1 and #ctx.active==1 and #ctx.scoring==1)
local originalQueue=ctx.queue;local originalScoring=ctx.scoring
S.calculate(legacy,g.deities,{gameState=g,monster=g.monster,hand=g.hand,preview=true})
assert(ctx.queue==originalQueue and ctx.scoring==originalScoring,"preview must not rewrite live ability state")
callbacks=0
local scored=S.calculate(legacy,g.deities,{gameState=g,monster=g.monster,hand=g.hand})
assert(scored.finalScore>0 and callbacks==1)
assert(#D.heldCards(h,{gameState=g,hand=g.hand})==0,"disabled held cards cannot feed held effects")
assert(require("src.spn_reserves").heldCount(g,{a})==1)
g.hand={b};g.abilityHand=nil
assert(not P.evaluate(g.hand,nil,nil,g) and not A.beginHand(g,P.evaluate(g.hand),g.hand))
local empty=S.calculate(P.evaluate(g.hand),g.deities,{gameState=g,monster=g.monster})
assert(empty.finalScore==0 and #empty.steps==1 and callbacks==1)
g.monster.bossState.handIndex=2
assert(not B.isAbilityDisabled(g,b) and P.evaluate({a,b},nil,nil,g).type.id=="pair","expiry restores the card")
g,a,b=fixture();b.abilityDisabledUntil=nil;g.monster.lockedFaction=b.suit
assert(B.isAbilityDisabled(g,b) and P.evaluate(g.hand,nil,nil,g).type.id=="high_card","score-blocked cards obey the same rule")
print("Disabled cards PASS: no attack/combination/SPN/held contribution, stale scoring sanitization, empty hand and expiry")

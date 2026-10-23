local A=require("src.card_abilities")
local T=require("src.playing_card_tactics")
local Deck=require("src.deck")
local Combat=require("src.combat")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Deities=require("src.deities")
local Persistence=require("src.persistence")
local Game=require("src.game_state")
local function card(rank,suit,level)
    local c=Deck.newCard(rank,({heart="hearts",diamond="diamonds",club="clubs",spade="spades"})[suit] or suit)
    c.evolutionLevel=level or 0;return c
end
local function game(cards)
    local g=Game.new();g.hand=cards or {};g.deck={};g.discardPile={};g.deities={};g.consumables={}
    g.playerHp=50;g.maxPlayerHp=200;g.playerArmor=0;g.playerShield=0;g.gold=0
    A.start(g);return g
end
local function info(cards) return {type=Poker.HAND_TYPES.HIGH_CARD,scoringCards=cards,unscoredCards={},chips=0,mult=1} end
local names,identities={},{}
assert(#A.config.order==52)
for _,id in ipairs(A.config.order) do
    local d=A.definitions[id]
    assert(not names[d.characterName] and not identities[d.suit..":"..d.rank])
    names[d.characterName]=true;identities[d.suit..":"..d.rank]=true
    for _,level in ipairs({0,1,8,9,10,25}) do
        local c=card(d.rank,d.suit,level)
        local rank=d.rank==14 and 1 or d.rank
        local overflow=math.max(0,level-9)
        assert(Deck.getCardDamage(c)==rank+overflow)
        assert(Deck.getCardAttackSpeed(c)==math.max(1,14-rank)+overflow)
        assert(Deck.getCardEmpowerment(c)==overflow)
        local p=A.params(c);local tier=math.min(10,level+1)
        assert((p.healPercent or p.gold or p.armorPercent or p.speed*2)==tier)
        assert(not A.description(c):find("{",1,true))
        local held=card(3,d.suit);local g=game({c,held})
        local h=info({c});A.beginHand(g,h,{c})
        assert(g.playerHp==50 and g.gold==0 and g.playerArmor==0,"no legacy play effects")
        g.abilityHand.finished=true
        A.discard(g,{c},{playerDiscard=true})
        assert(Deck.getCardEmpowerment(held)==1 and not c.heldEmpowerment)
        assert(g.playerHp==50+(d.suit=="heart" and tier*2 or 0))
        assert(g.gold==(d.suit=="diamond" and tier or 0))
        assert(g.playerArmor==(d.suit=="spade" and tier*2 or 0))
        assert(Deck.getCardAttackSpeed(held)==11+(d.suit=="club" and tier*.5 or 0))
    end
end
assert(Deck.getChipValue(1)==1 and Deck.getAttackSpeed(1)==13)
local h1,h2,held,other=card(2,"heart"),card(5,"heart"),card(8,"heart"),card(8,"spade")
local g=game({h1,h2,held,other})
A.discard(g,{h1,h2},{playerDiscard=true})
assert(g.playerHp==54 and held.heldEmpowerment==2 and other.heldEmpowerment==0)
assert(not h1.heldEmpowerment and not h2.heldEmpowerment,"batch excludes discarded cards")
g.playerHp=200;A.discard(g,{h1},{playerDiscard=true});assert(g.playerArmor==0,"no overheal conversion")
local before=held.heldEmpowerment
A.discard(g,{h1},{playerDiscard=true,preview=true});A.discard(g,{h1},{})
assert(held.heldEmpowerment==before and g.playerHp==200,"no effects for preview or passive moves")
held.heldEmpowerment=4;held.discardSpeedBonus=2
A.discard(g,{held})
assert(not held.heldEmpowerment and not held.discardSpeedBonus,"forced discard clears held buffs")
local club=card(6,"club",9);g=game({held,other})
A.discard(g,{club},{playerDiscard=true});A.discard(g,{club},{playerDiscard=true})
assert(Combat.getAverageAttackSpeed({held,other},g)==16,"club bonuses stack")
local drawn=card(8,"heart");g.hand[#g.hand+1]=drawn
assert(Deck.getCardAttackSpeed(drawn)==6 and Deck.getCardEmpowerment(drawn)==0,"new draws do not inherit buffs")
held.heldEmpowerment=3
local h=info({held});local preview=Scoring.calculate(h,{}, {preview=true,gameState=g})
assert(held.discardSpeedBonus==10 and held.heldEmpowerment==3,"pure preview")
A.beginHand(g,h,{held});g.hand={other,drawn};g.discardPile={held}
local live=Scoring.calculate(h,{}, {gameState=g})
assert(preview.finalScore==live.finalScore,"preview equals actual empowered score")
assert(live.totalMult==4,"held empowerment contributes to scoring Mult")
A.finishHand(g)
assert(not held.discardSpeedBonus and not other.discardSpeedBonus and not held.heldEmpowerment)
for _,rank in ipairs({11,12,13,14}) do
    local c=card(rank,"diamond");local result=Scoring.calculate(info({c}),{}, {})
    assert(result.bonusChips==Deck.getChipValue(rank) and result.bonusMult==0,"no legacy role bonuses")
end
local permanent=card(13,"diamond",9);g=game({})
g.persistentDeck={permanent};local liveCard=Deck.cloneCard(permanent);g.hand={liveCard}
assert(Deities.getRarityBadge(permanent)=="TT")
assert(A.evolve(g,liveCard) and permanent.evolutionLevel==10)
assert(Deities.getRarityBadge(permanent)=="TT+1")
assert(Deck.getCardDamage(liveCard)==14 and Deck.getCardAttackSpeed(liveCard)==2 and Deck.getCardEmpowerment(liveCard)==1)
assert(A.params(liveCard).gold==10,"discard cap after TT")
assert(A.upgrade(g,liveCard,15,false) and permanent.evolutionLevel==25)
local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"MAP")))
local c=restored.persistentDeck[1];Deck.restoreDeck({c});c=Deck.cloneCard(c)
assert(c.evolutionLevel==25 and Deck.getCardDamage(c)==29 and Deck.getCardAttackSpeed(c)==17 and Deck.getCardEmpowerment(c)==16)
local legacy=Persistence.makeSnapshot(g,"MAP");local old=legacy.game.persistentDeck[1]
old.playingStatsVersion=nil;old.rank=14;old.baseRank=14;old.baseChips=18;old.bonusBaseChips=7
restored=assert(Persistence.restoreSnapshot(legacy));assert(restored.persistentDeck[1].baseChips==8,"legacy damage migration preserves upgrades")
local _,description=require("src.card_description").resolve(c,g)
assert(description:find("Cường hóa",1,true) and not description:find("MAX EVOLUTION",1,true))
local view=require("ui.components.card_description").model(c,"",description)
assert(view.stats.damage==29 and view.stats.speed==17 and view.stats.empowerment==16)
local picker=require("ui.ability_choices")
assert(picker.openEvolution(g,{id="cons_evolution"},function() end))
assert(picker.current.cards[1]==permanent,"TT+ cards remain selectable for evolution")
old.bloodPower=5;old.baseChips=62;old.bonusBaseChips=51
restored=assert(Persistence.restoreSnapshot(legacy))
assert(restored.persistentDeck[1].baseChips==12 and restored.persistentDeck[1].bonusBaseChips==11,"legacy blood Ace keeps its bonus above the scaled new base")
print("Continental 52 PASS: 312 rank/suit/evolution cases; discard, held buffs, expiry, scoring/preview, TT+, clones and saves")

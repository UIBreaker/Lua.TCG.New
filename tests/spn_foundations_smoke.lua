local F=require("src.spn_foundations")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Poker=require("src.poker")
local S=require("src.scoring")
local Persistence=require("src.persistence")
local Rng=require("src.rng")
local function card(rank,suit)
    local c=Deck.newCard(rank or 3,suit or "spades");c.disableFactionPassives=true;return c
end
local function game(id)
    local g=Game.new();g.deities={};g.hand={};g.persistentDeck={card(3),card(5),card(7)}
    g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1};g.spnCombat={}
    if id then assert(D.addDeity(g,D.CATALOG[id],1)) end;return g
end
local function score(g,cards,preview)
    return S.calculate(assert(Poker.evaluate(cards)),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function bonus(r,id,key)
    local total=0
    for _,s in ipairs(r.steps) do if s.type=="deity_hand" and s.effectiveDeity.id==id then total=total+(s[key] or 0) end end
    return total
end
for _,row in ipairs({F.entries[1],F.entries[2]}) do
    local g=game(row[1]);local list={card(3),card(3)};local key=row[3]=="addMult" and "addedMult" or "addedChips"
    local rng=Rng.getState();local preview=score(g,list,true);local actual=score(g,list)
    assert(bonus(actual,row[1],key)==row[4] and actual.finalScore==preview.finalScore and Rng.getState()==rng)
    D.evolve(g.deities[1]);assert(bonus(score(g,list),row[1],key)==row[4]*1.5)
end
local g=game("spirit_twin_oath")
assert(bonus(score(g,{card(6,"hearts"),card(6,"spades")}),"spirit_twin_oath","addedMult")==10)
assert(bonus(score(g,{card(6,"hearts"),card(6,"hearts")}),"spirit_twin_oath","addedMult")==20,"same-suit pair replaces the ten, no sum to thirty")
assert(bonus(score(g,{card(6,"hearts"),card(6,"hearts"),card(9,"spades")}),"spirit_twin_oath","addedMult")==20,"only the pair determines matching suits")
assert(bonus(score(g,{card(6,"hearts"),card(9,"hearts")}),"spirit_twin_oath","addedMult")==0,"matching suits without a pair do not trigger")
assert(bonus(score(g,{card(6),card(6),card(9),card(9)}),"spirit_twin_oath","addedMult")==0,"two-pair is a different hand")
local astral=card(6,"spades");astral.edition="astral"
assert(bonus(score(g,{card(6,"hearts"),astral}),"spirit_twin_oath","addedMult")==20)
assert(bonus(score(g,{card(6,"hearts"),card(6,"valoria")}),"spirit_twin_oath","addedMult")==20,"suit aliases")
D.evolve(g.deities[1]);assert(bonus(score(g,{card(6,"hearts"),card(6,"hearts")}),"spirit_twin_oath","addedMult")==30)
assert(D.getDescription(g.deities[1]):find("+30",1,true))

-- Opening speed chooses one live card; subsequent hands and saved permanent cards retain no bonus.
g=game("spirit_lightning_choice");g.hand={Deck.cloneCard(g.persistentDeck[1]),Deck.cloneCard(g.persistentDeck[2]),Deck.cloneCard(g.persistentDeck[3])}
local original=Rng.random;local rolls=0
Rng.random=function(a) rolls=rolls+1;assert(a==3);return 2 end
F.openingSpeed(g);F.openingSpeed(g);Rng.random=original
assert(rolls==1 and not g.hand[1].temporarySpeedBonus and g.hand[2].temporarySpeedBonus==20 and not g.hand[3].temporarySpeedBonus)
assert(g.persistentDeck[2].temporarySpeedBonus==nil and Deck.cloneCard(g.hand[2]).temporarySpeedBonus==nil)
local speed=Deck.peekCardAttackSpeed(g.hand[2]);A.handStart(g);F.openingSpeed(g);assert(Deck.peekCardAttackSpeed(g.hand[2])==speed)
local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
for _,c in ipairs(restored.persistentDeck) do assert(c.temporarySpeedBonus==nil) end
g=game("spirit_lightning_choice");D.evolve(g.deities[1]);g.hand={card(2)}
F.openingSpeed(g);assert(g.hand[1].temporarySpeedBonus==30 and Deck.peekCardAttackSpeed(g.hand[1])==42)
g=game("spirit_lightning_choice");g.hand={card(2)};g.hand[1].speedBonus=980;F.openingSpeed(g)
assert(Deck.peekCardAttackSpeed(g.hand[1])==999 and g.hand[1].speedBonus==980)
g=game("spirit_lightning_choice");g.hand={};local rng=Rng.getState();F.openingSpeed(g)
assert(Rng.getState()==rng)
g=game("spirit_lightning_choice");g.hand={card(2)};g.monster.isBoss=true
g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
F.openingSpeed(g);assert(not g.hand[1].temporarySpeedBonus)
g=game();g.backpackDeities={D.CATALOG.spirit_lightning_choice};g.hand={card(2)};F.openingSpeed(g);assert(not g.hand[1].temporarySpeedBonus)
g=game("spirit_lightning_choice");g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1]);D.evolve(g.deities[2]);g.hand={card(2)}
F.openingSpeed(g);assert(g.hand[1].temporarySpeedBonus==90,"two copied activations plus the evolved source")
g=game("spirit_lightning_choice");Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},1)
local count=0;for _,c in ipairs(g.hand) do if c.temporarySpeedBonus then assert(c.temporarySpeedBonus==20);count=count+1 end end
assert(count==1,"speed grant is wired after the opening hand is dealt")
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},2)
count=0;for _,c in ipairs(g.hand) do if c.temporarySpeedBonus then assert(c.temporarySpeedBonus==20);count=count+1 end end;assert(count==1)

local function events(r,id)
    local n=0;for _,s in ipairs(r.steps) do if s.type=="card_scored" and (not id or s.card.id==id) then n=n+1 end end;return n
end
g=game("spirit_second_wave");local two=card(2);local other=card(8)
local cards={two,other};assert(events(score(g,cards,true),two.id)==0,"an unscored two is not a scoring trigger")
cards={two,card(2)}
local preview=score(g,cards,true);assert(events(preview)==4)
g.hand=cards;A.start(g);A.beginHand(g,assert(Poker.evaluate(cards)),cards)
local actual=score(g,cards);assert(events(actual)==4 and actual.finalScore==preview.finalScore)
A.finishHand(g);D.evolve(g.deities[1]);g.hand=cards;A.beginHand(g,assert(Poker.evaluate(cards)),cards)
assert(events(score(g,cards))==6 and D.getDescription(g.deities[1]):find("3 lần",1,true))
g=game("spirit_second_wave");two=card(2);two.equipments={{id="repeat_test",name="Test",onCardScore=function() return {addChips=7} end}}
local with=score(g,{two});g.deities={};local base=score(g,{two})
assert(with.totalChips-base.totalChips==9,"repeat the card's base damage and equipment, not only one scalar")
g=game("spirit_second_wave");g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));assert(events(score(g,{card(2)},true))==3,"copied repeat adds one extra activation")
g=game("spirit_second_wave");assert(D.addDeity(g,D.CATALOG.spirit_awakened_echo,2));two=card(2);two.evolutionLevel=8
assert(events(score(g,{two},true))==9,"rank-two and evolution sources stack their extra jobs")
g=game("spirit_second_wave");g.deities[1].evolutionLevel=1000;assert(events(score(g,{card(2)},true))==128)
g=game("spirit_second_wave");g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(events(score(g,{card(2)},true))==1)
for _,row in ipairs(F.entries) do
    g=game();g.gold=100;local shop={items={{category="deity",deity=D.CATALOG[row[1]],cost=4}}}
    assert(require("src.shop").buyItem(shop,1,g) and #g.backpackDeities==1)
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));D.evolve(g.deities[1])
    restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    assert(restored.deities[1].id==row[1] and restored.deities[1].evolutionLevel==1)
end
assert(#D.getRandomShopPool({},99)==78)
print("SPN foundations PASS: flat/evolved hand bonuses, replacement same-suit pair/wild aliases, one random temporary opening speed/reset/caps, full rank-two repeats/mimic/resource bounds, preview/shop/save")

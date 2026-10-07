local A=require("src.card_abilities")
local T=require("src.playing_card_tactics")
local Deck=require("src.deck")
local Combat=require("src.combat")
local Poker=require("src.poker")
local function card(rank,suit,level)
    local c=Deck.newCard(rank,({heart="hearts",diamond="diamonds",club="clubs",spade="spades"})[suit] or suit)
    c.evolutionLevel=level or 0;return c
end
local function game(cards,hp,gold,armor)
    local g={hand=cards,deck={},discardPile={},deities={},consumables={},playerHp=hp or 50,maxPlayerHp=100,
        gold=gold or 10,playerArmor=armor or 8,maxHandSize=5,handsRemaining=4,discardsRemaining=3}
    A.start(g);return g
end
local function info(cards) return {type={id="high_card"},scoringCards=cards,unscoredCards={}} end
local names,identities={},{}
for _,id in ipairs(A.config.order) do
    local d=A.definitions[id]
    assert(not names[d.characterName] and not identities[d.suit..":"..d.rank],id.." unique protagonist")
    names[d.characterName]=true;identities[d.suit..":"..d.rank]=true
    assert(#d.ambition>10 and not A.description(card(d.rank,d.suit)):find("{",1,true),id.." complete description")
end
assert(#A.config.order==52)
local scenarios=0
for _,id in ipairs(A.config.order) do
    local d=A.definitions[id]
    for _,hp in ipairs({20,49,75,100}) do for _,gold in ipairs({0,7,20}) do for _,armor in ipairs({0,8,16}) do
        for _,level in ipairs({0,8}) do
            local c=card(d.rank,d.suit,level)
            local others={card(2,"heart"),card(3,"club"),card(4,"diamond"),card(5,"spade")}
            for _,count in ipairs({1,2,5}) do
                local cards={c};for i=2,count do cards[i]=others[i-1] end
                local g=game(cards,hp,gold,armor);g.abilityCombat.playIndex=2;g.abilityCombat.tacticDiscarded=true
                A.runtime(c).tacticCharge=3
                local beforeHp,beforeGold=g.playerHp,g.gold
                local preview=Combat.getAverageAttackSpeed(cards,g,info(cards))
                assert(g.playerHp==beforeHp and g.gold==beforeGold and A.runtime(c).tacticCharge==3,"preview pure")
                local x=A.beginHand(g,info(cards),cards)
                local speed=Combat.getAverageAttackSpeed(cards,g)
                assert(math.abs(preview-speed)<1e-8,"preview equals actual initiative: "..id)
                assert(g.playerHp>0 and g.playerHp<=100 and g.gold>=0 and g.playerArmor>=0,"resource bounds: "..id)
                assert(x.tacticLedger.heal<=12 and x.tacticLedger.armor<=24 and x.tacticLedger.gold<=3 and x.tacticSpeed<=3,"bounded combos")
                local hp1,gold1,armor1=g.playerHp,g.gold,g.playerArmor
                A.dispatch(g,"before_score",cards,x)
                assert(g.playerHp==hp1 and g.gold==gold1 and g.playerArmor==armor1,"no duplicate resources")
                A.repeatCard(g,c,8,x)
                while A.nextScore(g) do A.score(g,x.current) end
                assert(g.playerHp==hp1 and g.gold==gold1 and g.playerArmor==armor1,"retriggers only score")
                scenarios=scenarios+1
            end
        end
    end end end
end
-- Initiative must alter actual before/after enemy timing, not just the badge.
local c=card(2,"club");local other=card(2,"heart");local g=game({c,other},100,0,0)
local base=Combat.getAverageAttackSpeed(g.hand)
A.beginHand(g,info(g.hand),g.hand)
local speed=Combat.getAverageAttackSpeed(g.hand,g);assert(speed>base)
g.monster={hp=500,maxHp=500,attack=10,attackSpeed=base+.25,armor=0}
assert(Combat.resolveMonsterAttack(g,"before",speed)==nil,"speed beats enemy")
assert(Combat.resolveMonsterAttack(g,"after",speed),"enemy acts once after")
-- Conservation of resource costs and encounter money limit.
c=card(10,"diamond");g=game({c},100,2,0);A.beginHand(g,info({c}),{c})
assert(g.gold==0 and g.abilityHand.tacticSpeed==2,"paid speed spends exact cost")
c=card(14,"diamond");g=game({c},100,0,0)
for _=1,20 do A.beginHand(g,info({c}),{c});g.abilityHand.finished=true end
assert(g.abilityCombat.tacticGold==12,"encounter cap stops farming")
c=card(12,"heart");local other=card(2,"club");g=game({c,other},50,0,0)
T.hold(g,{c});T.hold(g,{c});T.hold(g,{c});T.hold(g,{c});assert(A.runtime(c).tacticCharge==3)
A.beginHand(g,info({c}),{c});assert(g.playerHp==58 and A.runtime(c).tacticCharge==0,"hold and release charge")
local ch=card(2,"heart");g=game({ch},100,0,0);A.beginHand(g,info({ch}),{ch})
assert(g.playerHp==100 and g.playerArmor==2,"overheal becomes armor")
assert(Deck.getAttackSpeed(2)>Deck.getAttackSpeed(10) and Deck.getAttackSpeed(10)>Deck.getAttackSpeed(13),"low rank initiative trade")
c=card(14,"diamond");g=game({c},100,0,0);g.abilityCombat.tacticGold=12
A.beginHand(g,info({c}),{c});assert(g.gold==0 and g.playerArmor>0,"saturated economy still grants armor")
g=game({ch},0,0,0);g.playerHp=0;A.beginHand(g,info({ch}),{ch});assert(g.playerHp==0,"no unrequested resurrection")
print("Continental 52 PASS: "..scenarios.." scenarios; unique names; pure preview; bounded resources; no retrigger farming; initiative and charges")

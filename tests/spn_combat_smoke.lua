local Combat = require("src.combat")
local Deities = require("src.deities")
local Monster = require("src.monster")
local Rng = require("src.rng")
local Scoring = require("src.scoring")
local Poker = require("src.poker")
local Deck = require("src.deck")
local Collection = require("src.collection")

local game = {deities={},maxHands=4,maxDiscards=3,maxHandSize=3}
Deities.addDeity(game,Deities.CATALOG.spirit_ward)
Combat.start(game, Monster.create(1,false,false,1), 1)
assert(game.playerArmor==10 and game.playerShield==10)
game.playerArmor=25
Combat.start(game, Monster.create(1,false,false,1), 1)
assert(game.playerArmor==10, "Opening armor resets and triggers once per battle")
Deities.evolve(game.deities[1])
Combat.start(game, Monster.create(1,false,false,1), 1)
assert(game.playerArmor==15 and Deities.getDescription(game.deities[1]):find("+15",1,true))

local function squad(hp, targetIndex, deity)
    local enemies={}
    for i=1,#hp do enemies[i]={hp=hp[i],maxHp=hp[i],groupIndex=i} end
    for _,enemy in ipairs(enemies) do enemy.group=enemies end
    return {enemies=enemies,monster=enemies[targetIndex],deities={[5]=deity or Deities.CATALOG.spirit_echo}}
end
local seen={}
Rng.seed(17)
for i=1,30 do
    local g=squad({500,500,500},2)
    local damage,defeated,hits=Combat.resolvePlayerAttack(g,100)
    assert(damage==100 and not defeated and #hits==1 and hits[1].damage==20)
    assert(g.monster.hp==400 and g.monster==g.enemies[2])
    assert(hits[1].enemy~=g.monster)
    seen[hits[1].enemy.groupIndex]=true
end
assert(seen[1] and seen[3], "Both living neighbors can be chosen")
local locked=squad({50,500},1)
locked.monster.isBoss=true
locked.monster.bossState={handIndex=1,slotLock={kind="spn",slot=5,untilHand=1}}
assert(#select(3,Combat.resolvePlayerAttack(locked,100))==0, "A locked SPN stays locked even when the primary target dies")
local g=squad({500,0,500,500},1)
assert(#select(3,Combat.resolvePlayerAttack(g,100))==0, "Do not jump over a dead adjacent enemy")
g=squad({50,20},1)
local _,defeated,hits=Combat.resolvePlayerAttack(g,100)
assert(defeated and #hits==1 and g.enemies[2].hp==0, "Splash can finish the encounter")
g=squad({500,500},1)
g.enemies[2].creatureArmor=8
Combat.resolvePlayerAttack(g,103)
assert(g.enemies[2].hp==488 and g.enemies[2].creatureArmor==0, "Floor 20% of total aura, then apply enemy armor")
g=squad({500},1)
local rng=Rng.getState()
assert(#select(3,Combat.resolvePlayerAttack(g,100))==0 and rng==Rng.getState())
local evolved={}
Deities.addDeity({deities=evolved},Deities.CATALOG.spirit_echo)
Deities.evolve(evolved[1])
g=squad({500,500},1,evolved[1])
Combat.resolvePlayerAttack(g,100)
assert(g.enemies[2].hp==470 and Deities.getDescription(evolved[1]):find("30%",1,true))
local hand=Poker.evaluate({Deck.newCard(3,"hearts")},{high_card=true})
g=squad({500,500},1)
rng=Rng.getState()
local preview=Scoring.calculate(hand,g.deities,{preview=true,gameState=g,monster=g.monster})
assert(preview.finalScore>0 and g.enemies[1].hp==500 and g.enemies[2].hp==500 and rng==Rng.getState())
assert(#Collection.getItems("jokers")==48 and #Deities.getRandomShopPool({},50)==48)
print("SPN combat: opening armor/reset/evolution, random live adjacency, group victory, armor, rounding, solo and preview safety passed")

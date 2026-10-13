local V=require("src.spn_vitality")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Rng=require("src.rng")
local Persistence=require("src.persistence")
local function game()
    local g=Game.new();g.deities={};g.hand={};g.persistentDeck={Deck.newCard(3,"spades")}
    g.playerHp=40;g.maxPlayerHp=100;g.playerArmor=20;g.playerShield=20
    g.monster={hp=0,maxHp=100,attack=1,attackSpeed=1}
    assert(D.addDeity(g,D.CATALOG.spirit_armor_vitality,3));return g
end
local g=game();local rng=Rng.getState()
A.combatWin(g)
assert(g.maxPlayerHp==120 and g.playerHp==60 and g.playerArmor==0 and g.playerShield==0)
assert(Rng.getState()==rng and #g.spnFeedback==1)
A.combatWin(g);assert(V.finish(g)==0 and g.maxPlayerHp==120,"one receipt even if win is handled twice")
require("src.reward_system").calculate({baseReward=4},g,false)
assert(g.maxPlayerHp==120,"reward calculation does not convert again")
local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(restored.maxPlayerHp==120 and restored.playerHp==60 and restored.deities[3].id=="spirit_armor_vitality")
Combat.start(restored,{hp=100,maxHp=100,attack=1,attackSpeed=1},2)
assert(restored.maxPlayerHp==120 and restored.playerArmor==0)
restored.playerArmor=12;restored.monster.hp=0;A.combatWin(restored)
assert(restored.maxPlayerHp==132 and restored.playerHp==72,"next battle has a fresh receipt, permanent life stays")
g=game();D.evolve(g.deities[3]);assert(V.finish(g)==30 and g.maxPlayerHp==130 and g.playerHp==70)
assert(D.getDescription(g.deities[3]):find("150%",1,true))
g=game();D.evolve(g.deities[3]);D.evolve(g.deities[3]);assert(V.finish(g)==40 and g.maxPlayerHp==140)
g=game();g.playerArmor=7.5;D.evolve(g.deities[3]);assert(V.finish(g)==11 and g.playerArmor==0)
g=game();g.playerHp=100;assert(V.finish(g)==20 and g.playerHp==120,"healing fills the newly added capacity")
g=game();g.playerArmor=0;g.playerShield=0;assert(V.finish(g)==0 and g.maxPlayerHp==100)
g=game();g.monster.hp=1;assert(V.finish(g)==0 and g.playerArmor==20 and g.maxPlayerHp==100)
g=game();g.playerHp=0;assert(V.finish(g)==0 and g.maxPlayerHp==100,"defeat cannot revive or grant capacity")
g=game();local other={hp=10,maxHp=10};g.enemies={g.monster,other};for _,m in ipairs(g.enemies) do m.group=g.enemies end
assert(V.finish(g)==0,"one dead target is not a squad victory")
other.hp=0;assert(V.finish(g)==20)
g=game();g.backpackDeities={g.deities[3]};g.deities={};assert(V.finish(g)==0 and g.playerArmor==20)
g=game();g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=3,untilHand=1}}
assert(V.finish(g)==20 and g.playerArmor==0,"defeated Boss releases its SPN slot locks")
g=game();assert(D.addDeity(g,D.CATALOG.spirit_armor_vitality,1));D.evolve(g.deities[1])
assert(V.finish(g)==30 and g.maxPlayerHp==130,"leftmost conversion spends the shared armor once")
g=game();g.deities[2]=g.deities[3];g.deities[3]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1]);D.evolve(g.deities[2])
assert(V.finish(g)==30 and g.deities[1].id=="spirit_right_echo" and g.maxPlayerHp==130,"copied conversion uses source power and shares armor budget")
g=game();g.gold=100;g.deities={}
local shop={items={{category="deity",deity=D.CATALOG.spirit_armor_vitality,cost=4}}}
assert(require("src.shop").buyItem(shop,1,g) and g.gold==96 and #g.backpackDeities==1)
assert(require("src.loadout").move(g,"spn","reserve",1,1,false));D.evolve(g.deities[1])
restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(restored.deities[1].evolutionLevel==1)
local catalogCount=0;for _ in pairs(D.CATALOG) do catalogCount=catalogCount+1 end
assert(#D.getRandomShopPool({},catalogCount)==catalogCount)
print("SPN vitality PASS: remaining armor to permanent capacity/heal, consumption, integer evolution, one receipt, real squad victory/no defeat, shared copied budget, locks/reserves/shop and next battle/save")

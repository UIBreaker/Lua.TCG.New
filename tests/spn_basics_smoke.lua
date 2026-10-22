local B=require("src.spn_basics")
local D=require("src.deities")
local Deck=require("src.deck")
local Game=require("src.game_state")
local Combat=require("src.combat")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Persistence=require("src.persistence")
local Rng=require("src.rng")
local function game(id)
    local g=Game.new();g.deities={};g.hand={};g.gold=0;g.playerHp=40;g.playerArmor=0;g.playerShield=0
    g.monster={hp=10000,maxHp=10000,attack=12,attackSpeed=20}
    if id then assert(D.addDeity(g,D.CATALOG[id])) end
    return g
end
local function card(rank)
    local c=Deck.newCard(rank,"hearts");c.disableFactionPassives=true;return c
end
local played={card(3),card(3),card(5)}
local h=assert(Poker.evaluate(played))
local function score(g,preview)
    return Scoring.calculate(h,g.deities,{gameState=g,monster=g.monster,preview=preview,unplayedCards=g.hand})
end
local g=game("spirit_life_bloom");g.hand={card(2),card(7),played[1]}
local rng=Rng.getState();local preview=score(g,true);local actual=score(g)
assert(preview.healHp==4 and actual.healHp==4 and g.playerHp==40 and Rng.getState()==rng)
D.evolve(g.deities[1]);assert(score(g).healHp==6)
g.hand={};assert(score(g).healHp==0)
g=game("spirit_coin_wisp");assert(#h.unscoredCards==1 and score(g).bonusGoldAwarded==6)
D.evolve(g.deities[1]);assert(score(g).bonusGoldAwarded==9 and score(g,true).bonusGoldAwarded==9 and g.gold==0)
g=game("spirit_fleet_wind");g.hand={card(3),card(8)};B.bind(g)
assert(Deck.peekCardAttackSpeed(g.hand[1])==13 and Deck.peekCardAttackSpeed(g.hand[2])==8)
assert(Combat.getAverageAttackSpeed(g.hand,g)==10.5)
D.evolve(g.deities[1]);assert(Deck.peekCardAttackSpeed(g.hand[1])==14)
assert(g.hand[1].speedBonus==0 and Deck.peekCardAttackSpeed(Deck.cloneCard(g.hand[1]))==11)
local source=g.deities[1];g.deities={};assert(Deck.peekCardAttackSpeed(g.hand[1])==11)
g.deities[2]=source;assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1])
assert(B.speed(g)==9 and Deck.peekCardAttackSpeed(g.hand[1])==20,"copy repeats and source evolution affect held speed")
g.monster.isBoss=true;g.monster.bossState={handIndex=1,slotLock={kind="spn",slot=2,untilHand=1}}
assert(B.speed(g)==0,"locked source also disables copies")
g.monster.isBoss=false
g.deck={card(6)};g.hand={};Combat.drawCards(g,1);assert(Deck.peekCardAttackSpeed(g.hand[1])==17)
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(saved.deities[2].evolutionLevel==1 and #(saved.hand or {})==0,"battle card references do not enter save")

-- Faster enemy receives armor before absorption, once across the whole exchange.
g=game("spirit_guardian_shell");Combat.beginEnemyTurn(g,10)
local hit=assert(Combat.resolveMonsterAttack(g,"before",10,g.monster))
assert(hit.absorbed==10 and hit.damage==2 and g.playerHp==38,"first enemy hit consumes the new armor")
Combat.resolvePlayerAttack(g,1,{missed=false});assert(g.playerArmor==0,"no second armor grant after enemy-first")
assert(not Combat.resolveMonsterAttack(g,"before",10,g.monster))
g=game("spirit_guardian_shell")
g.enemies={g.monster,{hp=10000,maxHp=10000,attack=12,attackSpeed=20}}
for i,m in ipairs(g.enemies) do m.group=g.enemies;m.groupIndex=i end
Combat.beginEnemyTurn(g,10)
local squadHit=assert(Combat.resolveMonsterAttack(g,"before",10,g.enemies[1]))
local secondHit=assert(Combat.resolveMonsterAttack(g,"before",10,g.enemies[2]))
assert(squadHit.absorbed==10 and secondHit.absorbed==0 and g.playerHp==26,"one grant across sequential enemies")
g=game("spirit_guardian_shell");g.monster.attackSpeed=1;Combat.beginEnemyTurn(g,10)
Combat.resolvePlayerAttack(g,1,{missed=true});assert(g.playerArmor==5,"attacking grants armor even on a miss")
B.armor(g,false);assert(g.playerArmor==5)
D.evolve(g.deities[1]);Combat.beginEnemyTurn(g,10);B.armor(g,false);assert(g.playerArmor==12.5)
assert(D.getDescription(g.deities[1]):find("+15",1,true),"enemy-first description evolves too")
g=game("spirit_guardian_shell");g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1]);B.armor(g,true)
assert(g.playerArmor==30,"copied armor activates twice, then source once")
g.playerArmor=998;g.spnBasicArmorGranted=nil;B.armor(g,true);assert(g.playerArmor==999 and g.playerShield==999)
g=game("spirit_guardian_shell");g.monster.isBoss=true
g.monster.bossState={handIndex=1,slotLock={kind="spn",slot=1,untilHand=1}};B.armor(g,true);assert(g.playerArmor==0)

-- Ordinary shop ownership: buy/sell, persistent evolution, and no automatic grants.
local Shop=require("src.shop")
local pool={};for _,entry in ipairs(D.getRandomShopPool({},999)) do pool[entry.id]=true end
for _,row in ipairs(B.entries) do
    assert(pool[row[1]],"basic SPN belongs to the ordinary shop pool")
    g=game();g.gold=100
    local item={category="deity",deity=D.CATALOG[row[1]],cost=4}
    local shop={items={item}}
    assert(Shop.buyItem(shop,1,g) and g.gold==96 and #shop.items==0)
    assert(not g.deities[1] and #g.backpackDeities==1)
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false))
    local owned=g.deities[1];assert(owned.id==row[1] and not owned.battleSupport)
    assert(D.evolve(owned));g.persistentDeck={card(3),card(6),card(8)}
    for round=1,2 do
        Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},round)
        assert(D.getCount(g.deities)==1 and g.deities[1]==owned and owned.evolutionLevel==1)
    end
    local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    assert(restored.deities[1].id==row[1] and restored.deities[1].evolutionLevel==1)
    local before=restored.gold
    assert(Shop.sellDeity(restored,1) and not restored.deities[1] and restored.gold>before)
end
g=game();g.persistentDeck={card(3),card(6),card(8)}
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},1)
assert(D.getCount(g.deities)==0 and #g.hand>0,"starting battle does not grant any SPN")
for _,c in ipairs(g.hand) do assert(B.cardGames[c]==g and c.spnSpeedGame==nil) end
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},2);assert(D.getCount(g.deities)==0)
for i=1,5 do assert(D.addDeity(g,D.CATALOG.spirit_pebble,i)) end
g.gold=100
local fullShop={items={{category="deity",deity=D.CATALOG.spirit_coin_wisp,cost=4}}}
assert(Shop.buyItem(fullShop,1,g) and g.gold==96 and #fullShop.items==0 and g.backpackDeities[1].id=="spirit_coin_wisp")
Combat.start(g,{hp=10000,maxHp=10000,attack=1,attackSpeed=1},3)
assert(D.getCount(g.deities)==5 and D.getMaxSlots(g)==5,"battle adds no overflow slot")
assert(#D.getRandomShopPool({},999)==100)
print("SPN basics PASS: held heal, all-played gold, dynamic/evolved/copied speed, pre-hit armor, locks/caps, normal shop buy/sell, persistent evolution, no automatic grants and save safety")

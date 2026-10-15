local E=require("src.spn_elements")
local D=require("src.deities")
local G=require("src.game_state")
local Deck=require("src.deck")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Shop=require("src.shop")
local P=require("src.persistence")
local Rng=require("src.rng")
local shield="spirit_phantom_heart";local frost="spirit_first_frost";local fire="spirit_cinder_confluence"
local function game(ids)
    local g=G.new();g.deities={};g.playerHp=100;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0;g.lastPlayerAttackSpeed=1
    g.hand={Deck.newCard(3,"spades")};g.persistentDeck={Deck.cloneCard(g.hand[1])};g.masterDeck=g.persistentDeck
    g.enemies={};for i=1,3 do g.enemies[i]={name="Enemy "..i,hp=1000,maxHp=1000,attack=50,attackSpeed=1,armor=0,groupIndex=i} end
    for _,m in ipairs(g.enemies) do m.group=g.enemies end;g.monster=g.enemies[1]
    for slot,id in ipairs(ids or {}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    return g
end
local function hit(g,amount,roll) return Combat.resolvePlayerAttack(g,amount,roll or {hitChance=1,missed=false}) end
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local g=game({shield});g.playerArmor=30;g.playerShield=30
assert(E.remaining(g)==1000)
local r=Combat.resolveMonsterAttack(g,nil,1,g.monster)
assert(g.playerHp==100 and E.remaining(g)==950 and g.playerArmor==30 and r.absorbed==50 and r.damage==0,"raw damage reaches phantom pool before armor")
g.monster.attack=980;r=Combat.resolveMonsterAttack(g,nil,1,g.monster)
assert(g.playerHp==100 and not g.deities[1] and g.playerArmor==0 and r.damage==0,"remaining thirty hits real armor, exhausted SPN destroys")
g=game({shield});g.monster.attack=1100;r=Combat.resolveMonsterAttack(g,nil,1,g.monster)
assert(not g.deities[1] and g.playerHp==0 and r.killedPlayer,"lethal overflow is never lost")
g=game({shield});E.absorb(g,500);g.playerHp=50
g.consumables={Shop.healingItem("upper","healing_potion").consumable};assert(require("src.inventory").useUtility(g,1))
assert(g.playerHp==75 and E.remaining(g)==500)
D.evolve(g.deities[1]);assert(E.remaining(g)==1000 and g.deities[1].phantomSpent==500,"evolution adds capacity, never clears expenditure")
local loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
assert(E.remaining(loaded)==1000 and loaded.deities[1].phantomSpent==500)
Combat.start(loaded,{hp=1000,maxHp=1000,attack=1,attackSpeed=1},1);assert(E.remaining(loaded)==1000)
assert(require("src.loadout").move(g,"spn","equipped",1,nil,false) and E.remaining(g)==0)
assert(require("src.loadout").move(g,"spn","reserve",1,1,false) and E.remaining(g)==1000)
g=game({shield});g.playerHp=1;assert(Shop.canAfford({cost=1000,currency="blood"},g))
local before=P.encode(P.makeSnapshot(g,"shop"));assert(not Shop.canAfford({cost=1001,currency="blood"},g));assert(before==P.encode(P.makeSnapshot(g,"shop")))
Shop.payItem({cost=1000,currency="blood"},g);assert(g.playerHp==1 and not g.deities[1])
g=game({shield});g.playerHp=5;Shop.payItem({cost=1002,currency="blood"},g);assert(g.playerHp==3 and not g.deities[1])
g=game({shield});g.playerHp=0;assert(not Shop.canAfford({cost=1,currency="blood"},g))
g=game({shield});g.playerHp=1
local item={category="deity",deity=D.CATALOG.spirit_blade,cost=1000,currency="blood"}
assert(Shop.buyItem({mode="blood_small",items={item}},1,g) and g.playerHp==1 and not g.deities[1] and #g.backpackDeities==1)
g=game({shield});g.playerHp=1
local shop={mode="blood_small",bloodMode=true,rerollCount=0}
assert(Shop.reroll(shop,g,function() end) and g.playerHp==1 and E.remaining(g)<1000)
g=game({shield});g.enemyPoison=3;require("src.enemy_abilities").handEnd(g);assert(E.remaining(g)==997 and g.playerHp==100)
g.monster.isBoss=true;g.monster.bossState={handIndex=1,pendingDamage=9,passiveUntil=0}
A.resolveBossDamage(g);assert(E.remaining(g)==988 and g.playerHp==100)
g=game({shield});g.potionCombat={gold_blood=true};g.gold=0;Combat.resolveMonsterAttack(g,nil,1,g.monster);assert(g.gold==0)
g=game({"spirit_right_echo",shield});D.evolve(g.deities[1]);assert(E.remaining(g)==3000)
E.absorb(g,2000);assert(not g.deities[1] and g.deities[2] and E.remaining(g)==1000,"copier owns its pool and its own sacrifice")

g=game({frost});local rng=Rng.getState();assert(Combat.rollPlayerAttack(g).frozen and rng==Rng.getState())
local damage,dead,hits,roll=hit(g,900,{hitChance=.05,missed=true})
assert(damage==0 and not dead and #hits==0 and roll.frozen and g.monster.spnFrozen==1)
for _,m in ipairs(g.enemies) do assert(m.hp==1000) end
assert(not g.enemies[2].spnFrozen)
r=Combat.resolveMonsterAttack(g,nil,1,g.monster);assert(r.blocked and r.damage==0 and g.monster.spnFrozen==0)
assert(hit(g,90)==90 and g.monster.hp==910,"second strike deals damage")
g=game({frost});D.evolve(g.deities[1]);hit(g,10)
for _=1,2 do assert(Combat.resolveMonsterAttack(g,nil,1,g.monster).blocked) end
assert(not Combat.resolveMonsterAttack(g,nil,1,g.monster).blocked)
g=game({frost});g.enemies[2].attackSpeed=99
Combat.beginEnemyTurn(g,10);Combat.resolveMonsterAttack(g,"before",10,g.enemies[2]);hit(g,100)
assert(Combat.resolveMonsterAttack(g,"after",10,g.monster).blocked and g.enemies[2].spnFrozen==nil)
g=game();hit(g,10);assert(D.addDeity(g,D.CATALOG[frost],1));assert(hit(g,10)==10,"equipping late cannot rearm the opening strike")
g=game({"spirit_right_echo",frost});hit(g,5);assert(g.monster.spnFrozen==2)

g=game({fire});damage,dead,hits=hit(g,300);assert(damage==100 and #hits==2)
for _,m in ipairs(g.enemies) do assert(m.hp==900 and #m.spnAuraBurns==1 and m.spnAuraBurns[1].damage==5) end
Combat.onMonsterTurnEnd(g);for _,m in ipairs(g.enemies) do assert(m.hp==895 and m.spnAuraBurns[1].turns==1) end
Combat.onMonsterTurnEnd(g);for _,m in ipairs(g.enemies) do assert(m.hp==890 and #m.spnAuraBurns==0) end
Combat.onMonsterTurnEnd(g);assert(g.monster.hp==890)
g=game({fire});D.evolve(g.deities[1]);hit(g,300)
for _,m in ipairs(g.enemies) do assert(m.hp==850);near(m.spnAuraBurns[1].damage,11.25) end
assert(D.getDescription(g.deities[1]):find("7.5",1,true))
g=game({fire});g.enemies[3].hp=0;hit(g,100);assert(g.monster.hp==950 and g.enemies[2].hp==950 and not g.enemies[3].spnAuraBurns)
g=game({fire});hit(g,1);for _,m in ipairs(g.enemies) do near(m.hp,1000-1/3);near(m.spnAuraBurns[1].damage,1/60) end
g=game({fire});hit(g,0);for _,m in ipairs(g.enemies) do assert(not m.spnAuraBurns) end
g=game({fire});hit(g,100,{hitChance=.05,missed=true});assert(not g.monster.spnAuraBurns and g.monster.hp==1000)
g=game({frost,fire});hit(g,300);for _,m in ipairs(g.enemies) do assert(m.hp==1000 and not m.spnAuraBurns) end
hit(g,300);assert(g.monster.hp==900)
g=game({fire});g.enemies[2].hp=0;g.enemies[3].hp=0;g.monster.hp=105
hit(g,100);assert(g.monster.hp==5);Combat.onMonsterTurnEnd(g)
assert(Combat.getOutcome(g)=="victory" and g.spnCombat.victoryPending,"burn kills use the normal victory path")
g=game({"spirit_right_echo",fire});hit(g,300);assert(g.monster.hp==800 and #g.monster.spnAuraBurns==2)

for _,id in ipairs({shield,frost,fire}) do
    g=game({id});g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
    assert(E.remaining(g)==0 and E.openingPower(g)==0 and E.spread(g,100)==nil)
    g=game();g.backpackDeities={D.CATALOG[id]};assert(E.remaining(g)==0 and E.openingPower(g)==0 and E.spread(g,100)==nil)
    g=game({id});local cards={g.hand[1]};local info=assert(require("src.poker").evaluate(cards))
    local snap=P.encode(P.makeSnapshot(g,"shop"));local rng=Rng.getState()
    require("src.scoring").calculate(info,g.deities,{gameState=g,monster=g.monster,preview=true})
    assert(snap==P.encode(P.makeSnapshot(g,"shop")) and rng==Rng.getState() and not g.monster.spnFrozen and not g.monster.spnAuraBurns)
    g=game();g.gold=100;assert(Shop.buyItem({items={{category="deity",deity=D.CATALOG[id],cost=4}}},1,g))
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));D.evolve(g.deities[1])
    loaded=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(loaded.deities[1].id==id and loaded.deities[1].evolutionLevel==1)
end
assert(#D.getRandomShopPool({},99)==83)
print("SPN elements PASS: persistent phantom ledger/no heal/armor/depletion/overflow/locks, hidden blood purchases/reroll, targeted zero-damage opening freeze/evolution/initiative, exact AURA split/burn two rounds/evolution/victory, copies/reserve/preview/RNG/shop/save")

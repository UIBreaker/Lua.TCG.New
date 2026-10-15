local L=require("src.enemy_loadout")
local A=require("src.enemy_abilities")
local C=require("src.combat")
local M=require("src.monster")
local Run=require("src.run_manager")
local Game=require("src.game_state")
local R=require("src.rng")
local Equipment=require("src.equipment")
local Deck=require("src.deck")
local Deities=require("src.deities")
for _,def in ipairs(L.config.equipment) do assert(Equipment.ITEMS[def.id],def.id) end
for _,def in ipairs(L.config.seals) do assert(Deck.SEALS[def.id],def.id) end
for _,def in ipairs(L.config.spns) do assert(Deities.CATALOG[def.id],def.id) end
local counts={edition=0,seal=0,spn=0,reserve=0,potion=0}
for stage=1,80 do for _,kind in ipairs({"small","big","boss"}) do
    local g=Game.new("red_deck")
    local blind=Run.generateAnteBlinds(stage)[kind=="small" and 1 or kind=="big" and 2 or 3]
    C.start(g,Run.createBlindMonster(blind,g),stage)
    for _,m in ipairs(g.enemies) do
        local bag=assert(m.enemyInventory)
        assert(bag.spent<=bag.budget and #bag.equipment<=L.profile(m).slots)
        local state=R.getState();local nextBag=L.generate(m)
        assert(R.getState()==state and nextBag.equipment[1].id==bag.equipment[1].id,"loadouts are stable and RNG-neutral")
        local stats=L.stats(m)
        for key,value in pairs(stats) do assert(value>=0 and value<=L.config.caps[key]) end
        assert(m.maxHp>=bag.base.maxHp and m.maxHp<=bag.base.maxHp*1.2)
        assert(A.attack(m)>=m.attack and A.attack(m)<=m.attack*1.4)
        assert(A.speed(m)<=999 and m.creatureArmor<=m.maxHp*.5)
        if bag.equipment[1].edition then counts.edition=counts.edition+1 end
        if bag.seal then counts.seal=counts.seal+1 end
        if bag.spn then counts.spn=counts.spn+1 end
        if bag.backpack.equipment[1] then counts.reserve=counts.reserve+1 end
        if bag.backpack.consumables[1] then counts.potion=counts.potion+1 end
        for _,item in ipairs(bag.equipment) do assert(#L.describeItem(item).desc>0) end
        if bag.seal then assert(#L.describeItem(bag.seal).desc>0) end
        if bag.spn then assert(#L.describeItem(bag.spn).desc>0) end
    end
end end
for key,n in pairs(counts) do assert(n>0,"missing generated "..key) end
local idempotent={stage=20,hp=1000,maxHp=1000,attack=100,attackSpeed=10,groupIndex=1,creatureKind="lava_golem"}
A.start(idempotent);L.start(idempotent);local startingArmor=idempotent.creatureArmor
L.start(idempotent);assert(idempotent.creatureArmor==startingArmor,"reinitializing equipment cannot accumulate shield")
local function fixture()
    local m={name="Test",stage=20,groupIndex=1,hp=1000,maxHp=1000,attack=100,attackSpeed=10}
    A.start(m);L.start(m);m.maxHp=1000;m.hp=1000;m.creatureArmor=0
    local bag=m.enemyInventory;bag.base.maxHp=1000;bag.equipment={};bag.spn=nil;bag.seal=nil;bag.backpack={equipment={},consumables={}}
    local g={monster=m,enemies={m},playerHp=500,maxPlayerHp=500,playerArmor=0,playerShield=0,hand={},deities={},gold=10,lastPlayerAttackSpeed=10}
    m.group=g.enemies;return g,m,bag
end
local g,m,bag=fixture()
bag.equipment={{id="blood_ring",kind="equipment",edition="polychrome",power=1}}
assert(A.attack(m)==125,"edition amplifies the 20% affix to 25%, not the whole monster")
bag.equipment[2]={id="blood_ring",kind="equipment",power=10}
assert(A.attack(m)==140,"duplicate/oversized stat entries cannot bypass the total cap")
bag.equipment={{id="basic_feather",kind="equipment",power=1}}
m.attackSpeed=990;assert(A.speed(m)==999)
m.intent={type="speed",targetIndex=1};assert(A.support(g,m).value==0 and A.speed(m)==999)
g,m,bag=fixture();bag.spn={id="spirit_echo",kind="spn",power=1};bag.attacks=2
assert(A.plan(g,m,1).value==120 and m.intent.label:find("Vọng Âm",1,true))
assert(C.resolveMonsterAttack(g,nil,nil,m).attack==120 and bag.attacks==3)
g,m,bag=fixture();bag.seal={id="seal_sunder",kind="seal",power=1};g.playerArmor=100;g.playerShield=100
assert(C.resolveMonsterAttack(g,nil,nil,m).damage==15 and g.playerHp==485,"seal pierce is part of the telegraphed attack, not an extra hit")
g,m,bag=fixture();bag.seal={id="seal_blood",kind="seal",power=1};m.hp=500
assert(C.resolveMonsterAttack(g,nil,nil,m).damage==100 and m.hp==540)
g,m,bag=fixture();bag.seal={id="seal_blood",kind="seal",power=1};m.hp=500;g.playerArmor=75;g.playerShield=75
assert(C.resolveMonsterAttack(g,nil,nil,m).damage==25 and m.hp==510,"leech scales with enemy HP and falls with absorbed damage")
g,m,bag=fixture();bag.seal={id="seal_blood",kind="seal",power=1};m.hp=500;g.lastPlayerAttackSpeed=27
local random=R.random;R.random=function() return .99 end
local missed=C.resolveMonsterAttack(g,nil,nil,m);R.random=random
assert(missed.missed and m.hp==500 and bag.attacks==1,"misses advance the attempted attack rhythm without leech")
g,m,bag=fixture();bag.spn={id="spirit_ember",kind="spn",power=1}
m.hp=500;m.intent={type="heal",targetIndex=1}
assert(C.resolveMonsterAttack(g,nil,nil,m).value==240 and m.hp==740)
g,m,bag=fixture();bag.seal={id="seal_purifying",kind="seal",power=1};bag.spn={id="spirit_ward",kind="spn",power=1}
m.intent={type="armor",targetIndex=1}
assert(C.resolveMonsterAttack(g,nil,nil,m).value==250 and m.creatureArmor==350)
for i=1,5 do m.intent={type="armor",targetIndex=1};C.resolveMonsterAttack(g,nil,nil,m) end
assert(m.creatureArmor==350,"exhausted/blocked support cannot trigger seal or SPN armor")
assert(A.addArmor(m,1000)==150 and m.creatureArmor==500,"all generated armor shares the finite reserve")
g,m,bag=fixture();bag.backpack.consumables[1]={id="healing_potion",kind="consumable",pct=.12};m.hp=300
assert(A.plan(g,m).type=="consume" and m.hp==300)
m.spnSleep=1;assert(C.resolveMonsterAttack(g,nil,nil,m).blocked and #bag.backpack.consumables==1)
local result=C.resolveMonsterAttack(g,nil,nil,m)
assert(result.action=="heal" and result.value==120 and m.hp==420 and #bag.backpack.consumables==0)
g,m,bag=fixture();bag.backpack.equipment[1]={id="ward_stone",kind="equipment",power=1};m.hp=400
assert(A.plan(g,m).type=="equip" and m.creatureArmor==0)
result=C.resolveMonsterAttack(g,nil,nil,m)
assert(result.action=="equip" and result.damage==0 and m.creatureArmor==100 and #bag.backpack.equipment==0)
assert(A.plan(g,m).type~="equip","reserve cannot be swapped back indefinitely")
g,m,bag=fixture();m.isBoss=true;require("src.boss_abilities").start(g)
bag.spn={id="spirit_ember",kind="spn",power=1};bag.seal={id="seal_purifying",kind="seal",power=1}
require("src.boss_abilities").disable(g,2,true)
assert(L.supportMultiplier(m)==1);L.afterAction(m,"armor",false);assert(m.creatureArmor==0)
-- Real 20th-stage opponents retain killability; no barrier, revival or damage cap is introduced by gear.
for _,kind in ipairs({"small","big","boss"}) do
    g=Game.new("red_deck");g.playerHp=500;g.maxPlayerHp=500
    C.start(g,Run.createBlindMonster(Run.generateAnteBlinds(20)[kind=="small" and 1 or kind=="big" and 2 or 3],g),20)
    for _,enemy in ipairs(g.enemies) do
        local hp=enemy.hp;local armor=enemy.creatureArmor
        if kind=="small" then M.takeDamage(enemy,500000);assert(enemy.hp==0,"500K can one-shot stage-20 normal opponents")
        else M.takeDamage(enemy,hp+armor+1);assert(enemy.hp==0,"a strong build can always exceed gear durability") end
    end
end
g=Game.new("red_deck");C.start(g,Run.createBlindMonster(Run.generateAnteBlinds(20)[1],g),20)
local hp=g.enemies[1].maxHp;local id=g.enemies[1].enemyInventory.equipment[1].id
C.start(g,g.enemies[1],20);assert(g.enemies[1].maxHp==hp and g.enemies[1].enemyInventory.equipment[1].id==id,"starting again cannot compound HP or share inventories")
assert(g.enemies[1].enemyInventory~=g.enemies[2].enemyInventory and g.enemies[1].enemyInventory.backpack~=g.enemies[2].enemyInventory.backpack)
local saved=require("src.persistence").makeSnapshot(g,"BLIND_SELECT")
assert(not saved.game.monster and not saved.game.enemies,"enemy inventories do not leak into the player backpack/save")
require("tests.enemy_ai_smoke")
print("Enemy loadouts passed: 240 encounters, budgets/caps, editions, seals, SPN, contact actions, counters, 500K one-shots, independent inventories and restart/save safety")
return true

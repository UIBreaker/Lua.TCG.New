local W=require("src.free_human_bosses")
local Data=require("config.free_human_boss_data")
local C=require("src.combat")
local M=require("src.monster")
local EA=require("src.enemy_abilities")
local B=require("src.boss_abilities")
local D=require("src.deck")
local P=require("src.persistence")
local Run=require("src.run_manager")
local def=assert(Data.byId.human_death_challenger)
local function fixture()
    local g=require("src.game_state").new("red_deck");g.run=Run.newRun("red_deck")
    g.run.ante=7;g.run.areaStage=7;g.run.regionId="human";g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(7,nil,"human",7);g.run.blinds[3].debuff=def
    local m=Run.createBlindMonster(g.run.blinds[3],g,true);C.start(g,m,7)
    m.enemyInventory=nil;m.creatureArmor=0;m.maxHp=100;m.hp=100;m.attack=10;m.phase=nil
    m.intent={type="attack",value=50,label="Tấn công 50 ST"}
    g.playerHp=10000;g.maxPlayerHp=10000;g.playerArmor=0;g.playerShield=0
    return g,m
end
local g,m=fixture();assert(m.human and EA.attack(m)==50)
local damage,dead=M.takeDamage(m,150,true)
assert(damage==150 and not dead and m.hp==150 and m.maxHp==150 and m.oneshotRages==1 and EA.attack(m)==150)
assert(m.intent.value==150 and m.intent.label:find("150",1,true),"Telegraph must reflect the new attack immediately")
damage,dead=M.takeDamage(m,300,true)
assert(damage==300 and not dead and m.hp==300 and m.maxHp==300 and EA.attack(m)==450,"Repeated one-shots triple damage again")
assert(C.getOutcome(g)=="continue")
M.takeDamage(m,1,true);damage,dead=M.takeDamage(m,10000,true)
assert(dead and m.hp==0 and m.oneshotRages==2,"Chipping first permits a normal lethal finish")

g,m=fixture();m.creatureArmor=50
damage,dead=M.takeDamage(m,200)
assert(damage==150 and m.hp==150 and m.maxHp==150,"Use actual damage after armor, without capping overkill at old HP")
g,m=fixture();m.creatureArmor=50
damage,dead=M.takeDamage(m,120)
assert(damage==70 and m.hp==30 and m.oneshotRages==0,"Armor-absorbed damage that is not lethal cannot trigger rebirth")
g,m=fixture();B.disable(g,1)
damage,dead=M.takeDamage(m,100,true);assert(dead and m.hp==0,"Passive suppression allows one-shot kills")
g,m=fixture();C.resolvePlayerAttack(g,1000,{missed=true,hitChance=0})
assert(m.hp==100 and m.oneshotRages==0,"A miss cannot empower the boss")
C.resolvePlayerAttack(g,250,{missed=false,hitChance=1})
assert(m.hp==250 and m.maxHp==250 and C.getOutcome(g)=="continue","Real player attacks must not award an early victory")

g,m=fixture();local c=D.newCard(8,"hearts");c.bonusBaseChips=100
g.hand={c};g.deck={};g.discardPile={};g.deities={}
local info=require("src.poker").evaluate({c},g.unlockedHands,g.handLevels)
local function score() return require("src.scoring").calculate(info,{}, {gameState=g,monster=m,hand={},preview=true}).finalScore end
local base=score();assert(W.playerDamageFactor(g)==1)
B.handEnd(g);assert(W.playerDamageFactor(g)==1.2 and score()==math.floor(base*1.2))
B.handEnd(g);assert(W.playerDamageFactor(g)==1.4 and score()==math.floor(base*1.4))
B.disable(g,1,true);B.handEnd(g);assert(W.playerDamageFactor(g)==1.4,"Active suppression prevents the next gift")
B.handEnd(g);assert(W.playerDamageFactor(g)==1.6 and score()==math.floor(base*1.6))
local encoded=P.encode(g.monster.freeHumanState.playerDamageStacks);score();assert(P.encode(g.monster.freeHumanState.playerDamageStacks)==encoded,"Preview must not advance turns")
EA.resources(m).mustAttack=true;m.intent={type="attack"}
local attack=EA.attack(m);local hit=C.resolveMonsterAttack(g,nil,1,m)
assert(hit.attack==attack and hit.damage>0,"Huge attack must reach real combat damage")
local loaded=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"playing")))))
assert(loaded.run.blinds[3].debuff.id==def.id)
C.start(loaded,Run.createBlindMonster(loaded.run.blinds[3],loaded,true),7)
assert(W.playerDamageFactor(loaded)==1 and loaded.monster.oneshotRages==0,"Restarted battles reset temporary challenge buffs")
m.hp=0;assert(W.playerDamageFactor(g)==1)
assert(W.attackFactor({isBoss=false,attack=10})==1)
print("Death Challenger PASS: x5 base damage, exact/repeated oneshot rebirth, post-armor overkill HP, chip-then-kill, passive counters/misses, real combat, additive player buffs/previews and save/load")

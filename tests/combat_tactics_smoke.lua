local C=require("src.combat")
local A=require("src.enemy_abilities")
local M=require("src.monster")
local R=require("src.rng")
local P=require("src.enemy_attack_presentation")
local function fixture()
    local a={name="A",hp=100,maxHp=100,attack=20,attackSpeed=8,groupIndex=1}
    local b={name="B",hp=100,maxHp=100,attack=12,attackSpeed=8,groupIndex=2}
    local g={monster=a,enemies={a,b},playerHp=100,maxPlayerHp=100,playerArmor=10,playerShield=10,
        hand={},deities={},gold=10}
    a.group=g.enemies;b.group=g.enemies
    return g,a,b
end
local random=R.random
local function roll(value,fn)
    R.random=function() return value end
    local ok,err=pcall(fn)
    R.random=random
    assert(ok,err)
end
assert(C.getHitChance(10,10)==1 and C.getHitChance(20,10)==1)
assert(C.getHitChance(5,10)==.5 and C.getHitChance(0,999)==.05)
assert(C.getHitChance(1,27)==.05 and C.getHitChance(27,1)==1,"27 vs 1 must bottom out enemy accuracy")
assert(C.getHitChance(1,999)==.05 and C.getHitChance(9,10)==.9)
for n=1,999 do assert(C.getHitChance(n,999)>=.05 and C.getHitChance(n,999)<=1) end
local g,a,b=fixture()
g.lastPlayerAttackSpeed=4;a.creatureArmor=15;a.hasBed=true
roll(.99,function()
    local dmg,dead,hits,result=C.resolvePlayerAttack(g,50)
    assert(result.missed and result.hitChance==.5 and dmg==0 and not dead and #hits==0)
    assert(a.hp==100 and b.hp==100 and a.creatureArmor==15 and a.hasBed,"a miss cannot consume shields, beds or splash procs")
end)
g.advancedHand={id="tesla_369"}
roll(.99,function()
    C.resolvePlayerAttack(g,50)
    assert(g.advancedHand.resolved and a.hp==100 and b.hp==100,"missed advanced hands resolve rewards without lightning damage")
end)
g.advancedHand=nil
a.hasBed=nil
roll(0,function() assert(C.resolvePlayerAttack(g,50)==35 and a.hp==65 and a.creatureArmor==0) end)
g.lastPlayerAttackSpeed=8
R.random=function() error("equal speed must not roll RNG") end
local ok,err=pcall(function() assert(C.resolvePlayerAttack(g,5)==5) end);R.random=random;assert(ok,err)
g,a,b=fixture();g.lastPlayerAttackSpeed=16
a.enemyAbility=A.types.desert_scorpion;a.creatureKind="desert_scorpion"
roll(.99,function()
    local hit=C.resolveMonsterAttack(g,nil,nil,a)
    assert(hit.missed and hit.damage==0 and hit.absorbed==0)
    assert(g.playerHp==100 and g.playerArmor==10 and g.playerShield==10 and not g.enemyPoison)
    assert(a.attack==20 and not a.enemyActions,"misses cannot trigger hit effects")
end)
roll(0,function() assert(C.resolveMonsterAttack(g,nil,nil,a).damage==10 and g.enemyPoison==1) end)

-- Each support action can reach self and allies, consumes the action, and never hurts the player.
for _,kind in ipairs({"armor","speed","damage","heal"}) do
    for _,index in ipairs({1,2}) do
        g,a,b=fixture();local target=g.enemies[index]
        if kind=="heal" then target.hp=40 end
        a.intent={type=kind,targetIndex=index}
        local hit=C.resolveMonsterAttack(g,nil,nil,a)
        assert(hit.action==kind and hit.target==target and hit.damage==0 and g.playerHp==100 and g.playerArmor==10)
        if kind=="armor" then
            assert(target.creatureArmor==25 and M.takeDamage(target,30)==5 and target.hp==95)
        elseif kind=="heal" then assert(target.hp==60)
        else
            assert(kind=="speed" and A.speed(target)==10 or kind=="damage" and A.attack(target)==target.attack+hit.value)
            assert(target.combatBuffs[kind].turns==2)
            A.finishAction(g,target);assert(target.combatBuffs[kind].turns==1)
            A.finishAction(g,target);assert(not target.combatBuffs[kind])
        end
    end
end
g,a,b=fixture();a.intent={type="damage",targetIndex=1}
C.resolveMonsterAttack(g,nil,nil,a)
a.intent={type="attack"};g.playerArmor=0;g.playerShield=0
assert(C.resolveMonsterAttack(g,nil,nil,a).attack==25,"damage buff changes resolved damage")
assert(a.attack==22,"temporary damage is excluded from permanent attack growth")
g,a,b=fixture();a.intent={type="speed",targetIndex=2}
A.support(g,a);b.intent={type="speed",targetIndex=2}
A.support(g,b);assert(A.speed(b)==10,"an ally's second cast refreshes instead of stacking")
b.attackSpeed=999;A.support(g,a);assert(A.speed(b)==999)
g,a,b=fixture();g.lastPlayerAttackSpeed=9;b.combatBuffs={speed={value=2,turns=2}}
roll(.99,function() assert(not C.resolveMonsterAttack(g,nil,nil,b).missed,"speed buffs affect accuracy immediately") end)
g,a,b=fixture();g.lastPlayerAttackSpeed=4;a.combatBuffs={speed={value=2,turns=2}}
assert(C.rollPlayerAttack(g).hitChance==.4,"target speed buffs reduce player accuracy")
g,a,b=fixture();a.intent={type="armor",targetIndex=1}
for i=1,10 do A.support(g,a) end
assert(a.creatureArmor==25,"normal enemies cannot recast exhausted armor buffs")
assert(A.addArmor(a,100)==25 and a.creatureArmor==50,"armor is capped at 50% max HP")
g,a,b=fixture();b.hp=99;a.intent={type="heal",targetIndex=2}
A.support(g,a);assert(b.hp==100,"healing is capped at max HP")
g,a,b=fixture();a.intent={type="heal",targetIndex=2}
b.hp=0;a.hp=50;A.support(g,a);assert(b.hp==0 and a.hp==70,"dead recipients are retargeted, never revived")

g,a,b=fixture();A.start(a);A.start(b)
local seen={}
for turn=1,12 do
    local intent=A.plan(g,a,turn)
    if turn%2==1 then assert(intent.type=="attack")
    else seen[intent.type..intent.targetIndex]=true end
end
for _,kind in ipairs({"armor","speed","damage"}) do assert(seen[kind..1] and seen[kind..2],kind.." self/ally cycle") end
a.actionTurns=1;b.hp=40;C.onMonsterTurnEnd(g)
assert(a.intent.type=="heal" and a.intent.targetIndex==2,"AI prioritizes wounded allies after player damage")
a.hp=20;A.plan(g,a);assert(a.intent.targetIndex==1,"AI also heals itself")
assert(M.nextIntent(a,2,g).type=="heal")
g,a,b=fixture();a.attackSpeed=999
assert(A.plan(g,a,10).type=="damage","AI does not waste a speed buff at the cap")
a.creatureArmor=50;assert(A.plan(g,a,2).type=="damage","AI does not waste an armor buff at the cap")
g,a,b=fixture();A.start(a);a.intent={type="armor",targetIndex=2};a.spnSleep=1
assert(C.resolveMonsterAttack(g,nil,nil,a).blocked and not b.creatureArmor,"sleep blocks support actions too")

-- A speed buff crossing the initiative boundary must not skip or repeat an enemy's action.
g,a,b=fixture();a.attackSpeed=20;a.intent={type="speed",targetIndex=2};b.intent={type="attack"}
local before=C.resolveMonsterAttack(g,"before",9)
assert(before.attackerCount==1 and A.speed(b)==10)
local after=C.resolveMonsterAttack(g,"after",9)
assert(after.attackerCount==1 and not C.resolveMonsterAttack(g,"after",9))
g,a,b=fixture();a.attackSpeed=8;a.combatBuffs={speed={value=4,turns=1}};b.hp=0
assert(C.resolveMonsterAttack(g,"before",10).attackerCount==1 and A.speed(a)==8)
assert(not C.resolveMonsterAttack(g,"after",10),"expired speed buff cannot grant a second action")

-- Buff magnitude follows the recipient's actual stats, regardless of either enemy's stage.
for _,maxHp in ipairs({100,200000,1000000,10000000}) do
    g,a,b=fixture();a.stage=80;b.stage=1;b.maxHp=maxHp;b.hp=1
    b.attack=2000;b.attackSpeed=100
    for _,kind in ipairs({"armor","heal","speed","damage"}) do
        local expected=({armor=math.floor(maxHp*.25),heal=math.floor(maxHp*.20),speed=25,damage=500})[kind]
        assert(A.buffAmount(b,kind)==expected,kind.." must scale with actual recipient stats")
        a.intent={type=kind,targetIndex=2}
        local hit=A.support(g,a)
        assert(hit.value==expected,"resolved support must match the stat-based magnitude")
        if kind=="speed" or kind=="damage" then
            for i=1,10 do assert(A.support(g,a).blocked and A.buffAmount(b,kind)==expected,"exhausted buffs cannot be amplified or refreshed") end
        end
    end
    assert(A.speed(b)==125 and A.attack(b)==2500)
end
g,a,b=fixture();a.stage=20;b.maxHp=1000000;b.hp=1000000
A.plan(g,a,8)
assert(a.intent.type=="armor" and a.intent.value==250000,"intent scales to recipient max HP")
local hit=A.support(g,a);assert(hit.value==250000 and b.creatureArmor==250000)
assert(M.takeDamage(b,200000)==0 and b.hp==1000000 and b.creatureArmor==50000,"250k armor absorbs a real 200k AURA hit")
for i=1,3 do A.support(g,a) end
assert(b.creatureArmor==50000,"spent casts cannot refill broken armor")
assert(A.addArmor(b,1000000)==250000 and b.creatureArmor==300000,"generated armor has a finite lifetime reserve")
assert(A.addArmor(b,1000000)==0,"absorbing damage cannot refill the armor reserve")
b.combatBuffs={};b.attack=4000;b.attackSpeed=200
assert(A.buffAmount(b,"damage")==1000 and A.buffAmount(b,"speed")==50,"new buffs use current attack and speed")
g,a,b=fixture();a.stage=80;b.stage=1
assert(A.buffAmount(b,"armor")==25 and A.buffAmount(b,"damage")==3,"stage cannot override recipient stats")
g,a,b=fixture();g.lastPlayerAttackSpeed=27;a.attackSpeed=1;b.hp=0
roll(.1,function() assert(C.resolveMonsterAttack(g).missed,"27 vs 1 applies the 5% floor in actual enemy combat") end)
roll(.01,function() assert(not C.resolveMonsterAttack(g).missed,"the 5% floor still allows rare hits") end)

-- Casting has the same visible contact timing as attacks at every supported frame rate.
for _,fps in ipairs({30,60,144}) do
    g,a,b=fixture();b.hp=0;a.intent={type="armor",targetIndex=1}
    local calls,time=0,0
    local s=P.start(g,nil,nil,function(hit)
        calls=calls+1;assert(hit.action=="armor" and g.playerHp==100 and a.creatureArmor==25)
        assert(time>=P.timing.pause+P.timing.prepare+P.timing.strike)
    end,function() end)
    repeat
        if s.phase~="recover" then assert(not a.creatureArmor) end
        time=time+1/fps
    until P.update(s,g,1/fps)
    assert(calls==1 and time>=P.timing.pause+P.timing.prepare+P.timing.strike+P.timing.recover)
end
local snapshot=require("src.persistence").makeSnapshot(g,"BLIND_SELECT")
assert(not snapshot.game.enemyActed and not snapshot.game.enemyActionPhases)
print("Combat tactics passed: both-side accuracy, real self/ally buffs, healing AI, caps/expiry, blocked/missed effects, initiative, contact timing, save safety")

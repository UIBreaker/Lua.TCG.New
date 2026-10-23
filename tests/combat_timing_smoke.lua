local T=require("src.combat_timing")
require("tests.timing_vfx_smoke")
local C=require("src.combat")
local P=require("src.enemy_attack_presentation")
local M=require("src.monster")
local function fixture()
    local m={hp=1000,maxHp=1000,attack=20,attackSpeed=10,intent={type="attack"}}
    return {monster=m,playerHp=100,maxPlayerHp=100,playerArmor=10,playerShield=10,
        hand={},deities={},lastPlayerAttackSpeed=10},m
end
assert(T.start("attack",10,10).speed==1)
assert(T.start("attack",10,20).speed>1 and T.start("parry",20,10).speed<1)
assert(T.start("attack",0,99999).speed==2.4 and T.start("parry",99999,0).speed==.55)
for _,fps in ipairs({30,60,144}) do
    local s=T.start("attack",10,10)
    assert(not T.press(s),"ignore the click that opened the bar")
    local center=(s.zones[1].from+s.zones[1].to)/2
    while s.reverse and s.position>center or not s.reverse and s.position<center do T.update(s,1/fps) end
    assert(T.press(s) and s.result.grade=="perfect")
    assert(not T.press(s),"one attempt only")
    local g,m=fixture()
    assert(not C.rollPlayerAttack(g,s.result).missed)
    local damage=C.resolvePlayerAttack(g,40,C.rollPlayerAttack(g,s.result),s.result)
    assert(damage==80 and m.hp==920,"perfect doubles actual damage once")
    local timeout=T.start("parry",10,10)
    while not T.update(timeout,1/fps) do end
    assert(timeout.result.grade=="timeout")
end
local g,m=fixture()
local perfect={grade="perfect",multiplier=2,reduction=1}
local good={grade="good",multiplier=1.35,reduction=.5}
local hit=C.resolveMonsterAttack(g,nil,10,m,perfect)
assert(hit.parried and hit.damage==0 and g.playerHp==100 and g.playerArmor==10 and not g.enemyPoison)
assert(require("src.enemy_abilities").resources(m).actions==1,"parry still counts as an attempted attack")
assert(not C.resolveMonsterAttack(g,"after",10,m,perfect),"parried enemy already consumed its turn")
g,m=fixture();hit=C.resolveMonsterAttack(g,nil,10,m,good)
assert(hit.damage==0 and hit.absorbed==10 and g.playerHp==100,"partial parry precedes armor")
g,m=fixture();g.playerArmor=0;g.playerShield=0
hit=C.resolveMonsterAttack(g,nil,10,m,good);assert(hit.damage==10)
g,m=fixture();assert(C.resolvePlayerAttack(g,40,{missed=false},good)==54)
g,m=fixture();g.lastPlayerAttackSpeed=1
assert(C.resolvePlayerAttack(g,40,nil,perfect)==80,"perfect timing bypasses accuracy when no roll was supplied")
g,m=fixture();m.intent={type="heal"};m.hp=500
hit=C.resolveMonsterAttack(g,nil,10,m,perfect)
assert(not hit.parried and hit.action=="heal","support actions cannot be parried")
for _,fast in ipairs({false,true}) do
    g,m=fixture()
    local hits=0
    local s=P.start(g,nil,10,function(result) hits=hits+1;assert(result.parried) end,function() end,{interactive=true})
    local time=0
    while not s.finished do
        P.update(s,g,1/60,fast);time=time+1/60
        if s.timing and not s.timing.result then
            local center=(s.timing.zones[1].from+s.timing.zones[1].to)/2
            if s.timing.age>=s.timing.ready and math.abs(s.timing.position-center)<.03 then T.press(s.timing) end
        end
        assert(time<10,"interactive turn must finish")
    end
    assert(hits==1 and g.playerHp==100)
end
assert(M.getAttackByEncounter(1)==8 and M.getAttackByEncounter(1,true)==16 and M.getAttackByEncounter(1,false,true)==12)
for i=1,100 do local speed=M.rollAttackSpeed(1);assert(speed>=8 and speed<=22) end
print("Combat timing passed: FPS, speed ratios, one attempt, timeout, damage, parry, armor, supports and interactive enemy turns")

local layouts,directions={},{}
for i=1,150 do
    local s=T.start("attack",10,10)
    layouts[string.format("%.4f",s.zones[1].from)]=true;directions[s.reverse]=true
    for _,zone in ipairs(s.zones) do assert(zone.from>0 and zone.to<1 and zone.from<zone.to) end
    assert(T.grade(s,(s.zones[1].from+s.zones[1].to)/2)=="perfect")
    assert(T.grade(s,(s.zones[4].from+s.zones[4].to)/2)=="critical")
    assert(T.grade(s,s.zones[5].from+.01)=="trap","red surrounds the risky gold point")
    assert(T.grade(s,s.zones[6].from+.005)=="trap")
    assert(T.grade(s,0)=="normal" and T.grade(s,1)=="normal")
end
local count=0;for _ in pairs(layouts) do count=count+1 end
assert(count>10 and directions[true] and directions[false],"shuffle and offset targets and travel direction")
local function stopAt(index,offset)
    local s=T.start("attack",10,10)
    s.age=s.ready;s.position=offset and s.zones[index].from+offset or (index==6 and s.zones[index].from+.005 or (s.zones[index].from+s.zones[index].to)/2)
    assert(T.press(s));return s.result
end
local trap=stopAt(6)
g,m=fixture();g.potionCombat={accuracy=true};g.spnAttack={guaranteeHit=true}
local damage,_,_,attack=C.resolvePlayerAttack(g,40,{missed=false},trap)
assert(attack.missed and attack.timingMiss and damage==0 and m.hp==1000,"red forces a miss even with accuracy effects")
g,m=fixture();g.playerArmor=0;g.playerShield=0
assert(C.resolveMonsterAttack(g,nil,10,m,trap).damage==25,"exposed parry takes 25% extra damage")
local critical=stopAt(4)
g,m=fixture();assert(C.resolvePlayerAttack(g,40,nil,critical)==104,"risky gold grants x2.6 actual damage")
g,m=fixture();hit=C.resolveMonsterAttack(g,nil,10,m,critical)
assert(hit.parried and hit.parryArmor==5 and g.playerArmor==15 and g.playerHp==100)
g,m=fixture();local excess=require("src.card_abilities").config.armorCap+100;g.playerArmor=excess;g.playerShield=excess
hit=C.resolveMonsterAttack(g,nil,10,m,critical);assert(g.playerArmor==excess and hit.parryArmor==0,"reward cannot reduce existing armor")
print("Timing depth passed: 150 shuffled layouts, both directions, risk borders, forced misses, exposed parries and armor rewards")

local audio=require("src.timing_audio")
local cues=require("config.timing_audio_baked")
local sound=require("src.sound");local play=sound.play;local heard={}
sound.play=function(name) assert(cues[name],name);heard[#heard+1]=name;return true end
for _,kind in ipairs({"attack","parry"}) do
    for _,grade in ipairs({"good","perfect","critical","ultimate","apex","divine","trap","normal","timeout"}) do
        local s=T.start(kind,10,10)
        if grade=="timeout" then T.update(s,s.ready+s.duration+.01)
        else
            local index=({good=3,perfect=1,critical=4,ultimate=7,trap=6})[grade]
            s.age=s.ready;s.position=grade=="divine" and (s.divine.from+s.divine.to)/2 or grade=="apex" and (s.apex.from+s.apex.to)/2 or grade=="trap" and s.zones[6].from+.005 or index and (s.zones[index].from+s.zones[index].to)/2 or 0
            T.press(s)
        end
        assert(heard[#heard]==audio.cue(kind,grade),"each mode/grade routes its own recording")
    end
end
sound.play=play
assert(M.getBlindHp(1,"small")==80 and M.getBlindHp(1,"big")==160 and M.getBlindHp(1,"boss")==240)
assert(M.getBlindHp(2,"small")==120)
print("Timing modes passed: 20 distinct audio routes and stronger enemy HP/damage/speed")

local ultimate=stopAt(7)
g,m=fixture();g.lastPlayerAttackSpeed=1
assert(C.resolvePlayerAttack(g,40,nil,ultimate)==160,"ultimate gives x4 and guarantees accuracy")
g,m=fixture();hit=C.resolveMonsterAttack(g,nil,10,m,ultimate)
assert(hit.parried and hit.parryArmor==10 and g.playerArmor==20 and g.playerHp==100,"ultimate doubles critical parry armor")
for i=1,150 do
    local s=T.start("attack",10,10);local zone=s.zones[7]
    local center=(zone.from+zone.to)/2
    assert(math.abs(zone.to-zone.from-.025)<1e-9 and zone.to-zone.from<s.zones[4].to-s.zones[4].from)
    assert(T.grade(s,center)=="ultimate")
    assert(T.grade(s,zone.from-.001)=="trap" and T.grade(s,zone.to+.001)=="trap","a near miss lands in red")
    assert(math.abs((zone.to-zone.from)*s.duration-.04)<1e-9,"equal speeds give a 40ms ultimate window")
end
print("Ultimate timing passed: x4 damage, double parry armor, 150 randomized narrow targets with dangerous near misses")

g,m=fixture();m.hp=5000;m.maxHp=5000;g.playerArmor=100;g.playerShield=100
hit=C.resolveMonsterAttack(g,nil,10,m,ultimate)
assert(hit.reflectedAttack==2000 and hit.reflectedDamage==2000 and m.hp==3000,"10000% means x100 incoming damage before player armor")
assert(g.playerHp==100 and g.playerArmor==110,"reflection keeps full parry and armor reward")
g,m=fixture();m.creatureArmor=300
hit=C.resolveMonsterAttack(g,nil,10,m,ultimate)
assert(hit.reflectedAttack==2000 and hit.reflectedDamage==1700 and m.hp==0 and m.creatureArmor==0,"reflection uses normal enemy armor rules and can kill")
assert(C.getOutcome(g)=="victory")
g,m=fixture();m.creatureKind="ancient_skeleton";m.enemyAbility=require("src.enemy_abilities").types.ancient_skeleton
C.resolveMonsterAttack(g,nil,10,m,ultimate)
assert(m.hp==250 and m.reassembled and C.getOutcome(g)=="continue","reflection respects enemy revival")
g,m=fixture();hit=C.resolveMonsterAttack(g,nil,10,m,critical)
assert(hit.reflectedAttack==0 and m.hp==1000,"ordinary parry grades do not gain ultimate reflection")
print("Ultimate reflection passed: x100 pre-armor damage, armor mitigation, kill victory, revival and unchanged lower grades")

g,m=fixture()
local ally={hp=5000,maxHp=5000,attack=20,attackSpeed=10,intent={type="attack"}}
g.enemies={m,ally};m.group=g.enemies;ally.group=g.enemies
C.resolveMonsterAttack(g,nil,10,m,ultimate)
assert(m.hp==0 and ally.hp==5000 and C.getOutcome(g)=="continue","reflection hits only its attacker, not the whole formation")
assert(require("src.enemy_group").ensureTarget(g)==ally,"a reflected kill retargets a surviving enemy")
print("Reflection formation passed: exact attacker, surviving allies and target transfer")

local apexBar=T.start("attack",10,10)
apexBar.age=apexBar.ready;apexBar.position=(apexBar.apex.from+apexBar.apex.to)/2
assert(T.press(apexBar) and apexBar.result.grade=="apex")
local apex=apexBar.result
g,m=fixture();g.lastPlayerAttackSpeed=1
assert(C.resolvePlayerAttack(g,40,nil,apex)==320,"apex x8 damage and guaranteed accuracy")
g,m=fixture();m.maxHp=10000;m.hp=10000
hit=C.resolveMonsterAttack(g,nil,10,m,apex)
assert(hit.parried and hit.reflectedAttack==5000 and m.hp==5000 and g.playerHp==100 and hit.parryArmor==10)
for i=1,150 do
    local s=T.start("parry",10,10);local z=s.apex
    assert(z.to-z.from<s.zones[7].to-s.zones[7].from and math.abs(z.to-z.from-.015)<1e-9)
    assert(T.grade(s,(z.from+z.to)/2)=="apex")
    assert(T.grade(s,z.from-.001)=="trap" and T.grade(s,z.to+.001)=="trap")
end
print("Apex passed: x8 damage, x250 reflection, 1.5% target, 150 randomized red-bordered layouts")

for _,fps in ipairs({30,60,144}) do for _,speed in ipairs({1,2.6}) do
    g,m=fixture();m.hp=10000;m.maxHp=10000
    local turn;local hits,impacts,time=0,0,0
    turn=P.start(g,nil,10,function(result)
        hits=hits+1;assert(result.reflectedAttack==5000)
        turn.onReflectionImpact=function()
            impacts=impacts+1;assert(turn.reflectionAge>=.22)
        end
    end,function() end)
    turn.parryResult=apex
    while not turn.finished do
        P.update(turn,g,speed/fps,false,1/fps);time=time+1/fps
        if turn.phase=="recover" and turn.result and (turn.reflectionAge or 0)<.22 then
            assert(turn.reactions[m].hp.shown==10000,"enemy meter must wait for the return beam")
            local _,_,flash=P.reaction(turn,m);assert(flash==0,"no recoil before return contact")
        end
        assert(time<5)
    end
    assert(hits==1 and impacts==1 and turn.reflectionAge>=.48 and g.playerHp==100)
end end
print("Reflection presentation passed: delayed enemy meters/recoil, one impact callback, readable recovery at 30/60/144 FPS and fast speed")

local function stop(grade,kind)
    local s=T.start(kind or "attack",10,10)
    local z=grade=="divine" and s.divine or grade=="apex" and s.apex or s.zones[7]
    s.age=s.ready;s.position=(z.from+z.to)/2
    assert(T.press(s) and s.result.grade==grade)
    assert(not s.result.soulClaimed,"pressing a band cannot award currency before a real hit")
    return s.result
end
for i=1,200 do
    local s=T.start("attack",10,10);local z=s.divine
    assert(math.abs(z.to-z.from-.008)<1e-9 and z.to-z.from<s.apex.to-s.apex.from)
    assert(math.abs((z.to-z.from)*s.duration-.0128)<1e-9)
    assert(T.grade(s,z.from-.0001)=="trap" and T.grade(s,z.to+.0001)=="trap")
    assert(T.grade(s,(z.from+z.to)/2)=="divine")
end
for _,entry in ipairs({{"ultimate",1,4,100},{"apex",2,8,250},{"divine",3,12,500}}) do
    local grade,reward,multiplier,reflection=unpack(entry)
    local timing=stop(grade)
    g,m=fixture();m.hp=50000;m.maxHp=50000;g.lastPlayerAttackSpeed=1
    local damage,_,_,roll=C.resolvePlayerAttack(g,40,nil,timing)
    if grade=="ultimate" then reward=roll.timingSouls;assert(reward>=1 and reward<=5 and reward%1==0) end
    assert(damage==40*multiplier and roll.timingSouls==reward and g.souls==reward)
    assert(T.awardSouls(g,timing)==0 and g.souls==reward,"one receipt per timing attempt")
    timing=stop(grade,"parry")
    g,m=fixture();m.hp=50000;m.maxHp=50000
    local hit=C.resolveMonsterAttack(g,nil,10,m,timing)
    if grade=="ultimate" then reward=hit.timingSouls;assert(reward>=1 and reward<=5 and reward%1==0) end
    assert(hit.parried and hit.reflectedAttack==20*reflection and hit.timingSouls==reward and g.souls==reward)
    assert(T.awardSouls(g,timing)==0,"reflection cannot pay a second soul reward")
    timing=stop(grade);timing.forceMiss=true
    g,m=fixture();C.resolvePlayerAttack(g,40,nil,timing)
    assert((g.souls or 0)==0 and not timing.soulClaimed,"a miss cannot award souls")
    timing=stop(grade,"parry")
    g,m=fixture();g.potionCombat={evasion=true}
    C.resolveMonsterAttack(g,nil,10,m,timing)
    assert((g.souls or 0)==0 and not timing.soulClaimed,"enemy evasion is not a successful parry")
end
local timing=stop("divine");g,m=fixture();g.souls=9007199254740990
assert(T.awardSouls(g,timing)==1 and g.souls==9007199254740991)
print("Divine and souls passed: 200 risky 0.8% targets, x12 attack/x500 reflection, purple/white/ruby soul rewards, single receipts, misses/evasion and currency cap")

local rng=require("src.rng");local saved=rng.getState();local seen={};local rewards={}
for i=1,100 do
    local game={};local attempt={grade="ultimate"}
    local amount=T.awardSouls(game,attempt)
    assert(amount>=1 and amount<=5 and amount%1==0 and game.souls==amount)
    seen[amount]=true;rewards[i]=amount
    local after=rng.getState()
    assert(T.awardSouls(game,attempt)==0 and game.souls==amount and rng.getState()==after,"duplicate claims cannot reroll the reward")
end
for amount=1,5 do assert(seen[amount],"purple soul rewards should vary across the full 1-5 range") end
rng.setState(saved)
for i=1,100 do assert(T.awardSouls({},{grade="ultimate"})==rewards[i],"soul rewards must follow the saved gameplay RNG") end
rng.setState(saved)
print("Purple souls passed: random integers 1-5, full range, saved RNG replay and no duplicate payout/reroll")

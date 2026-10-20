local L=require("src.enemy_loadout")
local A=require("src.enemy_abilities")
local C=require("src.combat")
local R=require("src.rng")
local function fixture()
    local a={name="Medic",hp=1000,maxHp=1000,attack=20,attackSpeed=8,groupIndex=1,stage=20}
    local b={name="Striker",hp=1000,maxHp=1000,attack=100,attackSpeed=10,groupIndex=2,stage=20}
    for _,m in ipairs({a,b}) do
        A.start(m);L.start(m);m.maxHp=1000;m.hp=1000;m.creatureArmor=0;m.enemyResources=nil
        local bag=m.enemyInventory;bag.base.maxHp=1000;bag.equipment={};bag.spn=nil;bag.seal=nil
        bag.backpack={equipment={},consumables={},spns={}}
    end
    local g={monster=a,enemies={a,b},playerHp=10000,maxPlayerHp=10000,playerArmor=0,playerShield=0,
        hand={},deities={},gold=10,lastPlayerAttackSpeed=10}
    a.group=g.enemies;b.group=g.enemies
    return g,a,b,a.enemyInventory
end
local g,a,b,bag=fixture()
local generated,spares,normalSpn={},0,0
for stage=1,80 do for encounter,kind in ipairs({"normal","elite","boss"}) do
    local m={stage=stage,isBoss=kind=="boss",isElite=kind=="elite",groupIndex=1,encounterCount=stage*3+encounter}
    local state=R.getState();local inv=L.generate(m)
    assert(R.getState()==state and inv.spent<=inv.budget)
    assert(#inv.backpack.consumables<=L.profile(m).supplies)
    if stage<4 then assert(#inv.backpack.consumables==0) end
    for _,item in ipairs(inv.backpack.consumables) do
        generated[item.id]=true;assert(#L.describeItem(item).desc>0)
    end
    if inv.backpack.spns[1] then spares=spares+1;if kind=="normal" then normalSpn=normalSpn+1 end end
end end
for _,def in ipairs(L.config.consumables) do assert(generated[def.id],"not generated: "..def.id) end
assert(spares>0 and normalSpn>0,"rare SPN reserves must reach regular late-stage enemies too")

-- Select a useful later slot, not the first item; previews are pure.
bag.backpack.consumables={{id="healing_potion",kind="consumable",pct=.12},{id="cons_damage",kind="consumable",pct=.25}}
for i=1,10 do assert(L.plan(a,g).itemIndex==2 and #bag.backpack.consumables==2 and A.attack(b)==100) end
a.intent=L.plan(a,g)
local hit=C.resolveMonsterAttack(g,nil,nil,a)
assert(hit.action=="damage" and hit.target==b and hit.value==25 and A.attack(b)==125 and #bag.backpack.consumables==1)
assert(A.plan(g,a).type=="attack","consumables cannot form a support chain")

-- Rescue an endangered ally before preparing an offensive potion, even on an odd turn.
g,a,b,bag=fixture();bag.role="Quân y";b.hp=100
bag.backpack.consumables={{id="cons_damage",kind="consumable",pct=.25}}
assert(A.plan(g,a).type=="heal" and a.intent.targetIndex==2)
hit=C.resolveMonsterAttack(g,nil,nil,a);assert(hit.value==200 and b.hp==300 and #bag.backpack.consumables==1)

-- Buff the actual damage dealer; speed is chosen when it crosses initiative/accuracy.
g,a,b,bag=fixture();bag.role="Đấu sĩ";a.actionTurns=1;g.lastPlayerAttackSpeed=1
assert(A.plan(g,a).type=="damage" and a.intent.targetIndex==2)
bag.role="Quân y";g.lastPlayerAttackSpeed=11
assert(A.plan(g,a).type=="speed" and a.intent.targetIndex==2)
b.combatBuffs={speed={value=3,turns=2},damage={value=25,turns=2}}
local intent=A.plan(g,a)
assert(not((intent.type=="speed" or intent.type=="damage") and intent.targetIndex==2),"do not waste charges refreshing active buffs")

-- Do not use defensive supplies when there is a reliable lethal attack.
g,a,b,bag=fixture();g.playerHp=10;g.lastPlayerAttackSpeed=1;a.hp=100
bag.backpack.consumables={{id="healing_potion",kind="consumable",pct=.12}}
assert(A.plan(g,a,2).type=="attack")

-- Team card affects living eligible allies once, scales by their own speed, and expires.
g,a,b,bag=fixture();g.lastPlayerAttackSpeed=27
bag.backpack.consumables={{id="cons_speed_team",kind="consumable",pct=.25}}
assert(A.plan(g,a).type=="consume")
hit=C.resolveMonsterAttack(g,nil,nil,a)
assert(hit.action=="speed" and A.speed(a)==10 and A.speed(b)==12 and #bag.backpack.consumables==0)
A.finishAction(g,a);A.finishAction(g,a);A.finishAction(g,b);A.finishAction(g,b)
assert(A.speed(a)==8 and A.speed(b)==10)

-- Healing/armor items obey existing shared defensive reserves, including stale intentions.
for _,case in ipairs({{id="healing_potion",effect="heal",left="healingLeft"},{id="armor_potion_small",effect="armor",left="armorLeft"}}) do
    g,a,b,bag=fixture();a.hp=100;A.resources(a)[case.left]=7
    A.resources(a).charges={}
    bag.backpack.consumables={{id=case.id,kind="consumable",pct=.25}}
    assert(A.plan(g,a).type=="consume")
    hit=C.resolveMonsterAttack(g,nil,nil,a)
    assert(hit.action==case.effect and hit.value==7 and A.resources(a)[case.left]==0)
    g,a,b,bag=fixture();a.hp=100
    A.resources(a).charges={}
    bag.backpack.consumables={{id=case.id,kind="consumable",pct=.25}}
    A.plan(g,a);A.resources(a)[case.left]=0
    hit=C.resolveMonsterAttack(g,nil,nil,a)
    assert(hit.blocked and #bag.backpack.consumables==1,"unusable announced supplies cannot become surprise attacks or be wasted")
end

-- Accuracy potion survives sleep, guarantees exactly one attack, then normal 5% accuracy returns.
g,a,b,bag=fixture();a.attackSpeed=1;g.lastPlayerAttackSpeed=27
bag.backpack.consumables={{id="cons_accuracy",kind="consumable"}}
assert(A.plan(g,a).type=="consume")
a.spnSleep=1;assert(C.resolveMonsterAttack(g,nil,nil,a).blocked and #bag.backpack.consumables==1)
assert(C.resolveMonsterAttack(g,nil,nil,a).action=="accuracy" and bag.guaranteedAttacks==1)
local random=R.random;R.random=function() return .99 end
local ok,err=xpcall(function()
    hit=C.resolveMonsterAttack(g,nil,nil,a)
    assert(not hit.missed and hit.hitChance==1 and bag.guaranteedAttacks==0)
    a.intent={type="attack"};hit=C.resolveMonsterAttack(g,nil,nil,a)
    assert(hit.missed and hit.hitChance==.05)
end,debug.traceback)
R.random=random;assert(ok,err)
g,a,b,bag=fixture();a.attackSpeed=1;g.lastPlayerAttackSpeed=27;bag.guaranteedAttacks=1
A.resources(a).mustAttack=true
a.intent={type="attack"};a.spnSleep=1
assert(C.resolveMonsterAttack(g,nil,nil,a).blocked and bag.guaranteedAttacks==1)
g.potionCombat={evasion=true}
hit=C.resolveMonsterAttack(g,nil,nil,a)
assert(hit.missed and hit.hitChance==0 and bag.guaranteedAttacks==0,"one-attack accuracy cannot bypass evasion or be saved after an attempt")

-- SPN equipment uses an announced action and one slot, without refilling resources.
g,a,b,bag=fixture();bag.spn={id="spirit_ember",kind="spn",power=1}
bag.backpack.spns={{id="spirit_echo",kind="spn",power=1}};A.resources(a).healingLeft=17
A.resources(a).charges={} -- This scenario isolates reserve summoning, not squad buff priority.
assert(A.plan(g,a).type=="equip_spn" and bag.spn.id=="spirit_ember")
a.spnSleep=1;assert(C.resolveMonsterAttack(g,nil,nil,a).blocked and #bag.backpack.spns==1)
hit=C.resolveMonsterAttack(g,nil,nil,a)
assert(hit.action=="equip" and bag.spn.id=="spirit_echo" and bag.stowedSpn.id=="spirit_ember" and #bag.backpack.spns==0)
assert(A.resources(a).healingLeft==17 and A.plan(g,a).type=="attack")
assert(L.plan(a,g)==nil,"cannot swap a stowed SPN back forever")
g,a,b,bag=fixture();a.isBoss=true
local Boss=require("src.boss_abilities");Boss.start(g);Boss.disable(g,2,false)
bag.backpack.spns={{id="spirit_echo",kind="spn",power=1}}
assert(L.plan(a,g)==nil,"sealed magic cannot summon a reserve SPN")
a.intent={type="equip_spn"}
hit=L.action(a,g);assert(hit.blocked and #bag.backpack.spns==1 and not bag.spn)

-- Late squads have real equipment builds, rather than just one weak item.
local early=L.generate({stage=1,groupIndex=1})
for _,kind in ipairs({"normal","elite","boss"}) do
    local late=L.generate({stage=20,groupIndex=1,isBoss=kind=="boss",isElite=kind=="elite"})
    assert(late.budget>early.budget and #late.equipment==3 and late.equipment[1].edition=="polychrome")
    assert(late.seal and #late.backpack.consumables>0 and late.spent<=late.budget)
end

-- Useful squad support can open a fight; a lone fighter does not lose an attack to a weak buff.
g,a,b,bag=fixture();g.lastPlayerAttackSpeed=1;bag.role="Đấu sĩ"
assert(A.plan(g,a,1).type=="damage" and a.intent.targetIndex==2)
g.enemies={a};a.group=g.enemies
assert(A.plan(g,a,1).type=="attack")
bag.backpack.consumables={{id="cons_damage",kind="consumable",pct=.25}}
assert(A.plan(g,a,1).type=="attack","a weak self buff should not replace a stronger immediate attack")

-- Two supporters reserve different buffs even while planning the next round.
g,a,b,bag=fixture();g.lastPlayerAttackSpeed=1;bag.role="Đấu sĩ"
local striker={name="Carry",hp=1000,maxHp=1000,attack=200,attackSpeed=10,groupIndex=3}
A.start(striker);striker.group=g.enemies;g.enemies[3]=striker
assert(A.plan(g,a).type=="damage" and a.intent.targetIndex==3)
g.enemyActed={[a]=true,[b]=true}
local coordinated=A.plan(g,b)
assert(not(coordinated.type=="damage" and coordinated.targetIndex==3),"announced buffs must not be duplicated by squadmates")

-- Stock can rescue allies, not only the owner, and executes only at contact.
g,a,b,bag=fixture();A.resources(a).charges={};b.hp=100
bag.backpack.consumables={{id="healing_potion",kind="consumable",pct=.12}}
assert(A.plan(g,a).targetIndex==2 and b.hp==100 and #bag.backpack.consumables==1)
hit=C.resolveMonsterAttack(g,nil,nil,a)
assert(hit.action=="heal" and hit.target==b and b.hp==220 and #bag.backpack.consumables==0)

-- Threat memory uses an observed attack only; it resets and never reads the next scoring result.
g,a,b,bag=fixture();a.hp=100;b.hp=100
C.resolvePlayerAttack(g,2000,{missed=true,hitChance=.05})
assert(a.enemyObservedDamage==2000 and b.enemyObservedDamage==2000)
local desperate=A.plan(g,a)
assert(desperate.type~="heal" and desperate.type~="armor","do not waste a turn on recovery too small to survive the known attack")
A.start(a);assert(not a.enemyObservedDamage)

-- Changing gear preserves boss vitality and cannot replenish defense or chain support.
g,a,b,bag=fixture();a.maxHp=1500;a.hp=400
bag.backpack.equipment={{id="ward_stone",kind="equipment",power=1}}
a.intent={type="equip"};A.resources(a).mustAttack=true
assert(L.action(a,g).blocked and #bag.backpack.equipment==1)
A.resources(a).mustAttack=false;local defense=A.resources(a).armorLeft
hit=L.action(a,g)
assert(hit.action=="equip" and a.maxHp==1500 and a.hp==400 and A.resources(a).armorLeft==defense-150)
a.intent={type="equip"}
assert(L.action(a,g).blocked,"an empty announced swap cannot turn into a surprise attack")
print("Enemy AI passed: six useful consumables, 240 budgeted loadouts, rare reserve SPNs, pure planning, rescue/kill/initiative priorities, finite contact effects and one-attack accuracy")
return true

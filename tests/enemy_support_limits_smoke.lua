local A=require("src.enemy_abilities")
local C=require("src.combat")
local L=require("src.enemy_loadout")
local M=require("src.monster")
local R=require("src.rng")
local function fixture(kind,hp)
    local m={name="Support test",stage=1,groupIndex=1,hp=hp or 100,maxHp=hp or 100,attack=1,attackSpeed=1,
        isElite=kind=="elite",isBoss=kind=="boss"}
    A.start(m)
    local g={monster=m,enemies={m},playerHp=1000000,maxPlayerHp=1000000,playerArmor=0,playerShield=0,
        hand={},deities={},gold=10,lastPlayerAttackSpeed=999}
    m.group=g.enemies
    return g,m
end
local function step(g,m)
    A.plan(g,m)
    return assert(C.resolveMonsterAttack(g,nil,nil,m))
end
local random=R.random
local ok,err=xpcall(function()
    R.random=function(a) return a and 1 or .99 end
    -- Reproduce 7 damage versus a 7 HP heal. Healing cannot cancel every hit forever.
    local g,m=fixture("normal",35)
    local turns,healed,casts,previousSupport=0,0,0,false
    while m.hp>0 and turns<40 do
        turns=turns+1
        C.resolvePlayerAttack(g,7)
        if m.hp>0 then
            C.onMonsterTurnEnd(g)
            local before=m.hp
            local result=step(g,m)
            local support=result.action~="attack"
            assert(not (previousSupport and support),"support must be separated by an attack, even a miss")
            previousSupport=support
            healed=healed+m.hp-before
            if result.action=="heal" then casts=casts+1;assert(result.value==7) end
            C.onPlayerTurnEnd(g)
        end
    end
    assert(m.hp==0 and turns<=12 and healed==7 and casts==1,"7-damage early-game fight must finish")

    -- Every tier exhausts each ability; repeated planning and hand ends cannot replenish it.
    for _,kind in ipairs({"normal","elite","boss"}) do
        g,m=fixture(kind,10000)
        local used={heal=0,armor=0,speed=0,damage=0};local lastSupport=false
        for turn=1,80 do
            m.hp=1000;m.creatureArmor=0
            for i=1,5 do A.plan(g,m) end
            local result=step(g,m);local support=result.action~="attack"
            assert(not(lastSupport and support));lastSupport=support
            if support then used[result.action]=used[result.action]+1 end
            C.onMonsterTurnEnd(g);C.onPlayerTurnEnd(g)
        end
        for ability,count in pairs(used) do
            assert(count==A.limits[kind][ability],kind.." exhausts "..ability)
            assert(A.resources(m).charges[ability]==0)
        end
        assert(A.plan(g,m).type=="attack","spent enemies keep attacking")
    end

    -- Two healers share the patient's reserve rather than multiplying recovery indefinitely.
    g,m=fixture("normal")
    local ally={hp=1,maxHp=100,attack=1,attackSpeed=1,groupIndex=2}
    local other={hp=100,maxHp=100,attack=1,attackSpeed=1,groupIndex=3}
    A.start(ally);A.start(other);g.enemies={m,ally,other}
    for _,member in ipairs(g.enemies) do member.group=g.enemies end
    m.intent={type="heal",targetIndex=2};other.intent={type="heal",targetIndex=2}
    assert(A.support(g,m).value==20 and A.support(g,other).value==15)
    assert(ally.hp==36 and A.resources(ally).healingLeft==0)
    assert(A.heal(ally,100)==0,"allies cannot bypass the recipient's recovery reserve")

    -- Cooldown: two actual actions are required between elite heal casts; sleep does not advance it.
    g,m=fixture("elite");m.hp=1;m.intent={type="heal",targetIndex=1}
    local result=C.resolveMonsterAttack(g,nil,nil,m)
    assert(result.value==20 and not A.canSupport(m,"heal"))
    m.spnSleep=1;assert(step(g,m).blocked and A.resources(m).actions==1)
    assert(step(g,m).action=="attack" and not A.canSupport(m,"heal"))
    step(g,m)
    assert(A.resources(m).actions>=A.resources(m).healReadyAt)
    assert(step(g,m).action=="attack" and A.canSupport(m,"heal"))

    -- Potions/swaps cannot produce consecutive non-attack turns, nor reset budgets.
    g,m=fixture("normal",1000);L.start(m);m.maxHp=1000;m.hp=100;m.enemyResources=nil
    local bag=m.enemyInventory
    bag.base.maxHp=1000;bag.equipment={};bag.seal=nil;bag.spn=nil
    bag.backpack={equipment={{id="ward_stone",kind="equipment",power=1}},
        consumables={{id="healing_potion",kind="consumable",pct=.12}}}
    A.resources(m).charges={} -- Isolate potion/swap spacing from the smarter emergency heal priority.
    assert(step(g,m).action=="heal" and A.resources(m).healingLeft==230)
    assert(step(g,m).action=="attack" and step(g,m).action=="equip")
    assert(A.resources(m).healingLeft==230 and A.resources(m).armorLeft==400)
    assert(step(g,m).action=="attack")
    A.heal(m,1000);m.hp=1
    bag.backpack.consumables={{id="healing_potion",kind="consumable",pct=.12}}
    assert(A.plan(g,m).type~="consume","AI does not waste a potion when recovery is exhausted")

    -- All passive/gear recovery draws from the same pool as active skills.
    g,m=fixture("normal",1000);L.start(m);m.maxHp=1000;m.hp=1;m.enemyResources=nil
    bag=m.enemyInventory;bag.equipment={{id="vitality_gem",kind="equipment",power=1}}
    bag.seal={id="seal_blood",kind="seal",power=1};bag.spn=nil
    m.creatureKind="swamp_wraith";m.enemyAbility=A.types.swamp_wraith
    for i=1,100 do
        L.afterHit(m,1000,1000);L.afterAction(m,"speed",false);A.afterAttack(g,m,1000)
    end
    assert(m.hp==351 and A.resources(m).healingLeft==0)
    g,m=fixture("normal",1000);m.creatureKind="lava_golem";m.enemyAbility=A.types.lava_golem
    A.start(m)
    local generated=0
    for i=1,100 do
        m.creatureArmor=0;A.afterAttack(g,m,1000);generated=generated+m.creatureArmor
    end
    assert(generated==500 and A.resources(m).armorLeft==0,"breaking golem armor cannot regenerate it forever")

    -- Boss active healing and item-devouring healing cannot bypass the shared cap.
    local Boss=require("src.boss_abilities")
    g,m=fixture("boss",100)
    m.bossData=M.DISRUPTIVE_BOSSES.gem_devourer;Boss.start(g)
    local equipments={};for i=1,100 do equipments[i]="ward_stone" end
    g.hand={{id="meal",equipments=equipments}}
    local recovered=0
    for i=1,60 do
        m.hp=1
        step(g,m)
        local state=Boss.state(m);state.activeCountdown=1
        Boss.handEnd(g)
        recovered=recovered+m.hp-1
    end
    assert(recovered==60 and A.resources(m).healingLeft==0,"Boss healing sources share its 60% reserve")
    assert(Boss.activeDescription(m):find("hết lượt",1,true))

    -- A new encounter is the only reset; a corpse cannot spend recovery or be healed by it.
    g,m=fixture("normal",1000);m.hp=1;A.heal(m,1000);A.addArmor(m,1000)
    m.hp=0;assert(A.heal(m,100)==0 and A.addArmor(m,100)==0)
    m.hp=m.maxHp;A.start(m)
    assert(A.resources(m).healingLeft==350 and A.resources(m).armorLeft==500)
    assert(A.resources(m).charges.heal==1)
    print("Enemy support limits passed: 7-damage fight ended in "..turns.." turns; finite tier casts, shared ally/item/passive reserves, cooldown, forced attacks, no hand/swap reset")
end,debug.traceback)
R.random=random
assert(ok,err)
return true

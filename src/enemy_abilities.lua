local A = {}
-- Recovery belongs to the recipient, so several healers/items cannot refill it.
A.limits={
    normal={heal=1,armor=1,speed=1,damage=1,healing=.35,shielding=.50},
    elite={heal=2,armor=2,speed=1,damage=1,healing=.50,shielding=.75},
    boss={heal=2,armor=2,speed=2,damage=2,healing=.60,shielding=1},
}
function A.resources(m)
    if not m.enemyResources then
        local limits=A.limits[m.isBoss and "boss" or m.isElite and "elite" or "normal"]
        m.enemyResources={charges={heal=limits.heal,armor=limits.armor,speed=limits.speed,damage=limits.damage},
            healingLeft=math.floor(m.maxHp*limits.healing),armorLeft=math.floor(m.maxHp*limits.shielding),
            actions=0,healReadyAt=0,mustAttack=false}
    end
    return m.enemyResources
end
function A.canSupport(m,kind)
    local r=A.resources(m)
    return not r.mustAttack and (r.charges[kind] or 0)>0 and (kind~="heal" or r.actions>=r.healReadyAt)
end
function A.spendSupport(m,kind)
    local r=A.resources(m);r.charges[kind]=r.charges[kind]-1
    if kind=="heal" then r.healReadyAt=r.actions+3 end
end
function A.heal(m,amount)
    if m.hp<=0 then return 0 end
    local r=A.resources(m)
    local value=math.max(0,math.min(math.floor(amount),m.maxHp-m.hp,r.healingLeft))
    m.hp=m.hp+value;r.healingLeft=r.healingLeft-value
    return value
end
function A.addArmor(m,amount,cap)
    if m.hp<=0 then return 0 end
    local r=A.resources(m);local before=m.creatureArmor or 0
    local value=math.max(0,math.min(math.floor(amount),math.floor(cap or m.maxHp*.5)-before,r.armorLeft))
    m.creatureArmor=before+value;r.armorLeft=r.armorLeft-value
    m.creatureArmorMax=math.max(m.creatureArmorMax or 0,m.creatureArmor)
    return value
end
A.types = {
    forest_goblin={name="Đánh Cắp",suit="clubs",desc="Mỗi 2 lần ra đòn, lấy 1 Vàng. Không còn Vàng thì tăng sát thương."},
    lava_golem={name="Da Nham Thạch",suit="diamonds",desc="Có giáp bằng 12% HP. Sau mỗi đòn, phục hồi giáp từ dự trữ hữu hạn trong trận."},
    swamp_wraith={name="Hút Sinh Khí",suit="spades",desc="Hồi HP theo sát thương thực gây ra, dùng dự trữ hồi máu hữu hạn trong trận."},
    frost_wolf={name="Săn Theo Đàn",suit="hearts",desc="Tăng 20% tấn công cho mỗi đồng đội còn sống."},
    desert_scorpion={name="Nọc Ăn Mòn",suit="diamonds",desc="Đòn gây sát thương thêm Độc. Cuối tay mất HP theo Độc, tối đa 6."},
    ancient_skeleton={name="Tái Kết Xương",suit="spades",desc="Một lần mỗi trận: khi bị hạ, sống lại với 25% HP."},
}
local species={lock_royals="ancient_skeleton",black_tax_collector="forest_goblin",the_water="swamp_wraith",
    memory_eater="swamp_wraith",the_arm="lava_golem",gatekeeper="lava_golem",the_hook="forest_goblin",
    max_3_cards="lava_golem",the_needle="desert_scorpion",the_fish="swamp_wraith",echo_knight="frost_wolf",
    taxman="forest_goblin",gem_devourer="lava_golem",executioner="ancient_skeleton",faceless="swamp_wraith"}
function A.attach(m)
    if m.human or (m.regionId~="unknown" and (m.stage or 1)<=40) then return m end
    local key=m.artKey or m.bossData and (m.bossData.debuffId or m.bossData.id)
    m.creatureKind=A.types[key] and key or species[key] or "ancient_skeleton"
    m.enemyAbility=A.types[m.creatureKind]
    m.cardSuit=m.enemyAbility.suit
    local progress=m.regionId=="unknown" and m.areaStage or math.max(1,(m.stage or 41)-40)
    m.cardRank=math.min(13,(m.isBoss and 11 or m.isElite and 4 or 2)+math.floor((progress-1)/4))
    m.creatureCard=true
    m.title="QUÁI VẬT • CẤP "..require("src.expedition").rankName(m.cardRank)
    if not m.isBoss then m.desc=m.enemyAbility.name..": "..m.enemyAbility.desc end
    return m
end
function A.start(m)
    m.enemyActions=0;m.reassembled=false
    m.actionTurns=0;m.combatBuffs={};m.spnStolenSpeed=nil
    m.enemyResources=nil;m.enemyObservedDamage=nil
    m.creatureArmor=0;m.creatureArmorMax=0
    if m.creatureKind=="lava_golem" then m.creatureArmor=math.max(1,math.floor(m.maxHp*0.12));m.creatureArmorMax=m.creatureArmor end
end
function A.speed(m)
    local buffs=m.combatBuffs or {}
    local speed=math.min(m.bloodSovereign and math.huge or 999*(m.bloodDomainMultiplier or 1),require("src.enemy_loadout").speed(m)+((buffs.speed or {}).value or 0))
    speed=buffs.slow and math.max(1,math.floor(speed*(1-buffs.slow.value))) or speed
    return require("src.human_bosses").speed(m,math.max(1,speed-(m.spnStolenSpeed or 0)))*require("src.kingdom_bosses").factor(m)
end
function A.attack(m)
    return (require("src.enemy_loadout").attack(m)+(((m.combatBuffs or {}).damage or {}).value or 0))*require("src.kingdom_bosses").factor(m)*require("src.free_human_bosses").attackFactor(m)
end

local actionNames={armor="Gia cố",speed="Tăng tốc",damage="Cường hóa",heal="Hồi máu"}
local actionStats={armor="Giáp",speed="Tốc",damage="ST",heal="HP"}
local function recipient(game,m,kind,allies)
    local best
    for _,ally in ipairs(require("src.enemy_group").members(game)) do
        local available=kind~="heal" or ally.hp<ally.maxHp and A.resources(ally).healingLeft>0
        if kind=="armor" then available=(ally.creatureArmor or 0)<math.floor(ally.maxHp*.5) and A.resources(ally).armorLeft>0 end
        if ally.hp>0 and available and (not allies or ally~=m) then
            if not best or kind=="heal" and ally.hp/ally.maxHp<best.hp/best.maxHp
                or kind=="armor" and (ally.creatureArmor or 0)<(best.creatureArmor or 0)
                or kind=="speed" and A.speed(ally)>A.speed(best)
                or kind=="damage" and A.attack(ally)>A.attack(best) then best=ally end
        end
    end
    return best or m
end
function A.buffAmount(target,kind,caster)
    local power=caster and require("src.enemy_loadout").supportMultiplier(caster) or 1
    if kind=="armor" then return math.max(1,math.floor(target.maxHp*.25*power)) end
    if kind=="heal" then return math.max(1,math.floor(target.maxHp*.20*power)) end
    -- Recasting an active buff refreshes its snapshot instead of multiplying itself.
    local active=(target.combatBuffs or {})[kind]
    local value=active and active.value or math.max(1,math.floor((kind=="speed" and A.speed(target) or A.attack(target))*.25*power))
    if kind=="speed" then
        return math.max(0,math.min(999-require("src.enemy_loadout").speed(target),value))
    end
    return value
end
local function armorCap(target)
    return math.max(1,math.floor(target.maxHp*.50))
end

function A.playerSpeed(game,m)
    if game.lastPlayerAttackSpeed then return game.lastPlayerAttackSpeed end
    local fastest=0
    for _,card in ipairs(game.hand or {}) do
        fastest=math.max(fastest,require("src.deck").peekCardAttackSpeed(card,game))
    end
    return fastest>0 and fastest or A.speed(m)
end

-- Earlier squad members reserve their announced buff; planning never spends it.
function A.pendingSupport(game,m,target,kind)
    for _,ally in ipairs(require("src.enemy_group").members(game)) do
        local intent=ally.intent or {}
        if ally.hp>0 and (ally.groupIndex or 1)<(m.groupIndex or 1)
            and (intent.type==kind or intent.type=="consume" and intent.effect==kind)
            and (intent.team or intent.targetIndex==(target.groupIndex or 1)) then return true end
    end
    return false
end

function A.canSave(target,value)
    local threat=target.enemyObservedDamage
    return not threat or threat<target.hp+(target.creatureArmor or 0)+value
end

local function tacticalSupport(game,m)
    local C=require("src.combat");local role=m.enemyInventory.role
    local playerSpeed=A.playerSpeed(game,m)
    local ownDamage=math.max(1,A.attack(m)*C.getHitChance(A.speed(m),playerSpeed))
    local best,score=nil,45
    local strongest=1
    for _,ally in ipairs(require("src.enemy_group").members(game)) do if ally.hp>0 then strongest=math.max(strongest,A.attack(ally)) end end
    for _,target in ipairs(require("src.enemy_group").members(game)) do if target.hp>0 then
        local hp=target.hp/target.maxHp;local r=A.resources(target)
        for _,kind in ipairs({"heal","armor","speed","damage"}) do if A.canSupport(m,kind) and not A.pendingSupport(game,m,target,kind) then
            local value=A.buffAmount(target,kind,m);local rank=0
            local active=(target.combatBuffs or {})[kind]
            if kind=="heal" then
                value=math.min(value,target.maxHp-target.hp,r.healingLeft)
                if hp<=.65 and A.canSave(target,value) then rank=80+(1-hp)*40+(role=="Quân y" and 10 or 0) end
            elseif kind=="armor" then
                value=math.min(value,armorCap(target)-(target.creatureArmor or 0),r.armorLeft)
                rank=25+(1-hp)*30+(role=="Hộ vệ" and 25 or 0)-40*(target.creatureArmor or 0)/target.maxHp
                if not A.canSave(target,value) then rank=0
                elseif target.enemyObservedDamage and not A.canSave(target,0) then rank=110 end
            elseif not active then
                local hit=C.getHitChance(A.speed(target),playerSpeed)
                if kind=="speed" then
                    local gain=C.getHitChance(A.speed(target)+value,playerSpeed)-hit
                    rank=15+gain*120+15*A.attack(target)/strongest
                        +(A.speed(target)<=playerSpeed and A.speed(target)+value>playerSpeed and 65 or 0)
                else rank=15+math.min(90,35*math.sqrt(2*value*hit/ownDamage)) end
            end
            if value>0 and rank>score then score=rank;best={kind=kind,target=target,value=value,score=rank} end
        end end
    end end
    return best
end

function A.plan(game,m,turn)
    turn=turn or (m.actionTurns or 0)+1
    local Loadout=require("src.enemy_loadout")
    local resources=A.resources(m)
    local function attack()
        local echo=Loadout.attackBonus(m)*require("src.free_human_bosses").attackFactor(m)
        local value=A.attack(m)+A.attackBonus(game,m)+echo
        value=require("src.human_bosses").attack(game,m,value)
        m.intent={type="attack",value=value,label="Tấn công "..value.." ST"..(echo>0 and " · Vọng Âm" or "")
            ..(((m.enemyInventory or {}).guaranteedAttacks or 0)>0 and " · Trúng 100%" or "")}
        return m.intent
    end
    if m.spnAbilitiesSealed or resources.mustAttack then return attack() end
    local humanIntent=require("src.human_bosses").intent(game,m)
    if humanIntent then m.intent=humanIntent;return humanIntent end
    if m.enemyInventory then
        local value=A.attack(m)+A.attackBonus(game,m)+Loadout.attackBonus(m)*require("src.free_human_bosses").attackFactor(m)
        value=require("src.human_bosses").attack(game,m,value)
        local armor=game.playerArmor or game.playerShield or 0
        if require("src.human_bosses").number(m)==6 then armor=0 end
        local chance=(m.enemyInventory.guaranteedAttacks or 0)>0 and 1 or require("src.combat").getHitChance(A.speed(m),A.playerSpeed(game,m))
        if (game.playerHp or math.huge)<=value-math.min(armor,value*(1-Loadout.pierce(m))) and chance>=.8
            and not (game.potionCombat or {}).evasion then return attack() end
        if Loadout.attackBonus(m)>0 and chance>=.8 and not (game.potionCombat or {}).evasion then return attack() end
    end
    local choice=m.enemyInventory and tacticalSupport(game,m)
    local reserve=Loadout.plan(m,game)
    if choice and reserve and choice.score>=(reserve.score or 0) then reserve=nil end
    if reserve then m.intent=reserve;return reserve end
    if not m.enemyInventory and turn%2==1 then return attack()
    else
        if m.enemyInventory then
            if not choice then return attack() end
            local kind,target,value=choice.kind,choice.target,choice.value
            local to=target==m and "bản thân" or "đồng đội #"..(target.groupIndex or 1)
            m.intent={type=kind,value=value,targetIndex=target.groupIndex or 1,
                label=actionNames[kind].." "..to.." +"..value.." "..actionStats[kind]
                    ..((kind=="speed" or kind=="damage") and " (2 hành động)" or "").." · còn "..resources.charges[kind].." lần"}
            return m.intent
        end
        local support=math.floor(turn/2)
        local kind=({"armor","speed","damage"})[(support+(m.groupIndex or 1)-2)%3+1]
        local wounded=recipient(game,m,"heal")
        local target
        if wounded.hp/wounded.maxHp<=.65 and A.resources(wounded).healingLeft>0 and A.canSupport(m,"heal") then kind="heal";target=wounded
        else target=(support+(m.groupIndex or 1))%2==0 and m or recipient(game,m,kind,true) end
        if kind=="speed" and A.speed(target)>=999
            or kind=="armor" and ((target.creatureArmor or 0)>=armorCap(target) or A.resources(target).armorLeft<=0) then kind="damage" end
        if not A.canSupport(m,kind) then
            kind=nil
            for _,candidate in ipairs({"armor","speed","damage"}) do
                local receiver=recipient(game,m,candidate,true)
                if A.canSupport(m,candidate) and (candidate~="armor" or A.resources(receiver).armorLeft>0 and (receiver.creatureArmor or 0)<armorCap(receiver))
                    and (candidate~="speed" or A.speed(receiver)<999) then kind=candidate;target=receiver;break end
            end
            if not kind then return attack() end
        end
        local value=A.buffAmount(target,kind,m)
        if kind=="heal" then value=math.min(value,target.maxHp-target.hp,A.resources(target).healingLeft)
        elseif kind=="armor" then value=math.min(value,armorCap(target)-(target.creatureArmor or 0),A.resources(target).armorLeft) end
        if value<=0 then return attack() end
        local to=target==m and "bản thân" or "đồng đội #"..(target.groupIndex or 1)
        m.intent={type=kind,value=value,targetIndex=target.groupIndex or 1,
            label=actionNames[kind].." "..to.." +"..value.." "..actionStats[kind]
                ..((kind=="speed" or kind=="damage") and " (2 hành động)" or "").." · còn "..resources.charges[kind].." lần"}
    end
    return m.intent
end

function A.support(game,m)
    if m.spnAbilitiesSealed then return end
    local intent=m.intent or {};local kind=intent.type
    if not actionNames[kind] then return nil end
    local function exhausted(target)
        return {attack=0,absorbed=0,damage=0,killedPlayer=false,blocked=true,action=kind,target=target or m,value=0,label="Hỗ trợ đã hết lượt hoặc dự trữ"}
    end
    if not A.canSupport(m,kind) then return exhausted() end
    local target
    for _,ally in ipairs(require("src.enemy_group").members(game)) do
        if (ally.groupIndex or 1)==intent.targetIndex and ally.hp>0 then target=ally;break end
    end
    if not target or kind=="heal" and target.hp>=target.maxHp then target=recipient(game,m,kind) end
    local value=A.buffAmount(target,kind,m)
    if kind=="heal" then
        value=A.heal(target,value)
    elseif kind=="armor" then
        value=A.addArmor(target,value)
    else
        target.combatBuffs=target.combatBuffs or {}
        -- Refresh rather than stack; a self buff also survives the current action's tick.
        target.combatBuffs[kind]={value=value,turns=2+(target==m and 1 or 0)}
    end
    if value<=0 then return exhausted(target) end
    A.spendSupport(m,kind)
    return {attack=0,absorbed=0,damage=0,killedPlayer=false,action=kind,target=target,value=value,
        label=actionNames[kind]..(target==m and " bản thân" or " đồng đội #"..(target.groupIndex or 1))}
end

function A.finishAction(game,m,result)
    if result and not result.blocked then
        local r=A.resources(m);r.actions=r.actions+1;r.mustAttack=result.action~="attack"
    end
    for kind,buff in pairs(m.combatBuffs or {}) do
        buff.turns=buff.turns-1
        if buff.turns<=0 then m.combatBuffs[kind]=nil end
    end
    if m.actionTurns~=nil then
        m.actionTurns=m.actionTurns+1
        A.plan(game,m)
    end
end
function A.reduceDamage(m,damage)
    local absorbed=math.min(m.creatureArmor or 0,damage)
    m.creatureArmor=math.max(0,(m.creatureArmor or 0)-absorbed)
    return damage-absorbed
end
function A.revive(m)
    if m.spnAbilitiesSealed then return end
    if m.hp<=0 and m.creatureKind=="ancient_skeleton" and not m.reassembled then
        m.reassembled=true;m.hp=math.max(1,math.floor(m.maxHp*0.25));m.enemyFeedback="TÁI KẾT XƯƠNG"
        return true
    end
end
function A.attackBonus(game,m)
    if m.spnAbilitiesSealed then return 0 end
    local alive=0
    if m.creatureKind=="frost_wolf" then
        for _,ally in ipairs(require("src.enemy_group").members(game)) do if ally~=m and ally.hp>0 then alive=alive+1 end end
    end
    local hungry=m.creatureKind=="forest_goblin" and (game.gold or 0)==0 and 0.15 or 0
    local execution=m.bloodExecutioner and (game.playerHp or 100)<(game.maxPlayerHp or 100)*.4 and .35 or 0
    return math.floor((m.attack or 0)*(0.2*alive+hungry+execution))
end
function A.afterAttack(game,m,damage)
    if m.spnAbilitiesSealed then return end
    if not m.enemyAbility then return end
    m.enemyActions=(m.enemyActions or 0)+1
    if m.creatureKind=="forest_goblin" and m.enemyActions%2==0 then game.gold=math.max(0,(game.gold or 0)-1)
    elseif m.creatureKind=="lava_golem" then
        A.addArmor(m,math.max(1,math.floor(m.maxHp*0.03)),m.creatureArmorMax or 0)
    elseif m.creatureKind=="swamp_wraith" then
        A.heal(m,math.floor(damage*(0.5+(m.cardRank or 2)/13)))
    elseif m.creatureKind=="desert_scorpion" and damage>0 then
        game.enemyPoison=math.min(6,(game.enemyPoison or 0)+((m.cardRank or 2)>=10 and 2 or 1))
    end
end
function A.handEnd(game)
    local poison=game.enemyPoison or 0
    if poison>0 then
        local damage=require("src.card_abilities").damageGuard(game,require("src.spn_elements").absorb(game,poison))
        local hpBefore=game.playerHp or 100
        game.playerHp=math.max(0,hpBefore-damage)
        require("src.potions").payBlood(game,hpBefore)
        game.enemyPoison=math.max(0,poison-1)
        game.enemyFeedback="ĐỘC • -"..damage.." HP"
    end
end
return A

local A = {}
A.types = {
    forest_goblin={name="Đánh Cắp",suit="clubs",desc="Mỗi 2 lần ra đòn, lấy 1 Vàng. Không còn Vàng thì tăng sát thương."},
    lava_golem={name="Da Nham Thạch",suit="diamonds",desc="Có giáp bằng 12% HP. Sau mỗi đòn, phục hồi một phần giáp."},
    swamp_wraith={name="Hút Sinh Khí",suit="spades",desc="Hồi HP theo sát thương thực sự gây lên người chơi."},
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
    m.actionTurns=0;m.combatBuffs={}
    if m.creatureKind=="lava_golem" then m.creatureArmor=math.max(1,math.floor(m.maxHp*0.12));m.creatureArmorMax=m.creatureArmor end
end
function A.speed(m)
    local buffs=m.combatBuffs or {}
    local speed=math.min(999,(m.attackSpeed or 1)+((buffs.speed or {}).value or 0))
    return buffs.slow and math.max(1,math.floor(speed*(1-buffs.slow.value))) or speed
end
function A.attack(m)
    return (m.attack or 12)+(((m.combatBuffs or {}).damage or {}).value or 0)
end

local actionNames={armor="Gia cố",speed="Tăng tốc",damage="Cường hóa",heal="Hồi máu"}
local actionStats={armor="Giáp",speed="Tốc",damage="ST",heal="HP"}
local function recipient(game,m,kind,allies)
    local best
    for _,ally in ipairs(require("src.enemy_group").members(game)) do
        if ally.hp>0 and (not allies or ally~=m) then
            if not best or kind=="heal" and ally.hp/ally.maxHp<best.hp/best.maxHp
                or kind=="armor" and (ally.creatureArmor or 0)<(best.creatureArmor or 0)
                or kind=="speed" and A.speed(ally)>A.speed(best)
                or kind=="damage" and A.attack(ally)>A.attack(best) then best=ally end
        end
    end
    return best or m
end
function A.buffAmount(target,kind)
    if kind=="armor" then return math.max(1,math.floor(target.maxHp*.25)) end
    if kind=="heal" then return math.max(1,math.floor(target.maxHp*.20)) end
    -- Recasting an active buff refreshes its snapshot instead of multiplying itself.
    local active=(target.combatBuffs or {})[kind]
    local value=active and active.value or math.max(1,math.floor((kind=="speed" and A.speed(target) or A.attack(target))*.25))
    if kind=="speed" then
        return math.max(0,math.min(999-(target.attackSpeed or 1),value))
    end
    return value
end
local function armorCap(target)
    return math.max(1,math.floor(target.maxHp*.50))
end

function A.plan(game,m,turn)
    turn=turn or (m.actionTurns or 0)+1
    if turn%2==1 then
        m.intent={type="attack",value=A.attack(m)+A.attackBonus(game,m),label="Tấn công "..(A.attack(m)+A.attackBonus(game,m)).." ST"}
    else
        local support=math.floor(turn/2)
        local kind=({"armor","speed","damage"})[(support+(m.groupIndex or 1)-2)%3+1]
        local wounded=recipient(game,m,"heal")
        local target
        if wounded.hp/wounded.maxHp<=.65 then kind="heal";target=wounded
        else target=(support+(m.groupIndex or 1))%2==0 and m or recipient(game,m,kind,true) end
        if kind=="speed" and A.speed(target)>=999
            or kind=="armor" and (target.creatureArmor or 0)>=armorCap(target) then kind="damage" end
        local value=A.buffAmount(target,kind)
        local to=target==m and "bản thân" or "đồng đội #"..(target.groupIndex or 1)
        m.intent={type=kind,value=value,targetIndex=target.groupIndex or 1,
            label=actionNames[kind].." "..to.." +"..value.." "..actionStats[kind]
                ..((kind=="speed" or kind=="damage") and " (2 hành động)" or "")}
    end
    return m.intent
end

function A.support(game,m)
    local intent=m.intent or {};local kind=intent.type
    if not actionNames[kind] then return nil end
    local target
    for _,ally in ipairs(require("src.enemy_group").members(game)) do
        if (ally.groupIndex or 1)==intent.targetIndex and ally.hp>0 then target=ally;break end
    end
    if not target or kind=="heal" and target.hp>=target.maxHp then target=recipient(game,m,kind) end
    local value=A.buffAmount(target,kind)
    if kind=="heal" then
        value=math.min(value,target.maxHp-target.hp);target.hp=target.hp+value
    elseif kind=="armor" then
        local before=target.creatureArmor or 0
        target.creatureArmor=math.min(math.max(before,armorCap(target)),before+value)
        value=target.creatureArmor-before
        target.creatureArmorMax=math.max(target.creatureArmorMax or 0,target.creatureArmor)
    else
        target.combatBuffs=target.combatBuffs or {}
        if kind=="speed" then value=math.min(value,999-(target.attackSpeed or 1)) end
        -- Refresh rather than stack; a self buff also survives the current action's tick.
        target.combatBuffs[kind]={value=value,turns=2+(target==m and 1 or 0)}
    end
    return {attack=0,absorbed=0,damage=0,killedPlayer=false,action=kind,target=target,value=value,
        label=actionNames[kind]..(target==m and " bản thân" or " đồng đội #"..(target.groupIndex or 1))}
end

function A.finishAction(game,m)
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
    if m.hp<=0 and m.creatureKind=="ancient_skeleton" and not m.reassembled then
        m.reassembled=true;m.hp=math.max(1,math.floor(m.maxHp*0.25));m.enemyFeedback="TÁI KẾT XƯƠNG"
        return true
    end
end
function A.attackBonus(game,m)
    local alive=0
    if m.creatureKind=="frost_wolf" then
        for _,ally in ipairs(require("src.enemy_group").members(game)) do if ally~=m and ally.hp>0 then alive=alive+1 end end
    end
    local hungry=m.creatureKind=="forest_goblin" and (game.gold or 0)==0 and 0.15 or 0
    return math.floor((m.attack or 0)*(0.2*alive+hungry))
end
function A.afterAttack(game,m,damage)
    if not m.enemyAbility then return end
    m.enemyActions=(m.enemyActions or 0)+1
    if m.creatureKind=="forest_goblin" and m.enemyActions%2==0 then game.gold=math.max(0,(game.gold or 0)-1)
    elseif m.creatureKind=="lava_golem" then
        m.creatureArmor=math.min(m.creatureArmorMax or 0,(m.creatureArmor or 0)+math.max(1,math.floor(m.maxHp*0.03)))
    elseif m.creatureKind=="swamp_wraith" then
        m.hp=math.min(m.maxHp,m.hp+math.floor(damage*(0.5+(m.cardRank or 2)/13)))
    elseif m.creatureKind=="desert_scorpion" and damage>0 then
        game.enemyPoison=math.min(6,(game.enemyPoison or 0)+((m.cardRank or 2)>=10 and 2 or 1))
    end
end
function A.handEnd(game)
    local poison=game.enemyPoison or 0
    if poison>0 then
        local damage=require("src.card_abilities").damageGuard(game,poison)
        local hpBefore=game.playerHp or 100
        game.playerHp=math.max(0,hpBefore-damage)
        require("src.potions").payBlood(game,hpBefore)
        game.enemyPoison=math.max(0,poison-1)
        game.enemyFeedback="ĐỘC • -"..damage.." HP"
    end
end
return A

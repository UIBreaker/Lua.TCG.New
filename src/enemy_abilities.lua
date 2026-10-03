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
    if m.human or (m.stage or 1)<=40 then return m end
    local key=m.artKey or m.bossData and (m.bossData.debuffId or m.bossData.id)
    m.creatureKind=A.types[key] and key or species[key] or "ancient_skeleton"
    m.enemyAbility=A.types[m.creatureKind]
    m.cardSuit=m.enemyAbility.suit
    m.cardRank=math.min(13,(m.isBoss and 11 or m.isElite and 4 or 2)+math.floor(((m.stage or 41)-41)/4))
    m.creatureCard=true
    m.title="QUÁI VẬT • CẤP "..require("src.expedition").rankName(m.cardRank)
    if not m.isBoss then m.desc=m.enemyAbility.name..": "..m.enemyAbility.desc end
    return m
end
function A.start(m)
    m.enemyActions=0;m.reassembled=false
    if m.creatureKind=="lava_golem" then m.creatureArmor=math.max(1,math.floor(m.maxHp*0.12));m.creatureArmorMax=m.creatureArmor end
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
        game.playerHp=math.max(0,(game.playerHp or 100)-damage)
        game.enemyPoison=math.max(0,poison-1)
        game.enemyFeedback="ĐỘC • -"..damage.." HP"
    end
end
return A

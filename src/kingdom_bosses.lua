local K={definitions=require("config.kingdom_boss_data").list}
local aliases={valoria="hearts",sanguine_covenant="hearts",aurelia="diamonds",gilded_conclave="diamonds",elaris="clubs",feral_swarm="clubs",vharos="spades",iron_axiom="spades"}
function K.isEntity(m) return m and m.isBoss and m.bossData and m.bossData.kingdomEntity end
function K.matches(m,c) return K.isEntity(m) and c and (aliases[c.suit] or c.suit)==m.bossData.entitySuit end
function K.blocked(m,c)
    return K.matches(m,c) and (m.hp or 0)>0 and require("src.boss_abilities").passiveEnabled(m) or false
end
function K.start(g)
    for _,m in ipairs(require("src.enemy_group").members(g)) do if K.isEntity(m) then m.kingdomBossState={game=g} end end
end
function K.count(m)
    local state=m and m.kingdomBossState;local n=0
    if not state or not K.isEntity(m) or (m.hp or 0)<=0 or not require("src.boss_abilities").passiveEnabled(m) then return n end
    for _,c in ipairs(state.game.hand or {}) do if not c.destroyed and K.matches(m,c) then n=n+1 end end
    return n
end
function K.factor(m) return 1+K.count(m)*.1 end
function K.disabled(g,c)
    if not g then return false end
    for _,m in ipairs(require("src.enemy_group").members(g)) do if K.blocked(m,c) then return true end end
    return false
end
function K.notice(m)
    if not K.isEntity(m) then return end
    local n=K.count(m)
    return "KHÓA "..m.bossData.suitName.." · "..n.." LÁ TRÊN TAY\nTỐC / SÁT THƯƠNG +"..(n*10).."%"
end
return K

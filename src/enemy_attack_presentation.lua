local Combat = require("src.combat")
local Group = require("src.enemy_group")
local P = { timing = { pause = 0.18, prepare = 0.46, strike = 0.12, recover = 0.42 } }

function P.start(game, phase, speed, onHit, onDone)
    local attackers = {}
    for _, m in ipairs(Group.members(game)) do
        local fast = (m.attackSpeed or 1) > (speed or 0)
        if m.hp > 0 and (not phase or phase == "before" and fast or phase == "after" and not fast) then
            attackers[#attackers + 1] = m
        end
    end
    if #attackers == 0 then return nil end
    return { attackers = attackers, index = 1, phase = "pause", age = 0,
        onHit = onHit, onDone = onDone, order = phase, speed = speed }
end

function P.update(s, game, dt)
    -- Never compress the tell or consume several beats after a stalled frame.
    s.age = s.age + math.min(dt, 0.05)
    if s.age < P.timing[s.phase] then return false end
    s.age = 0
    if s.phase == "pause" then
        s.phase = "prepare"; require("src.sound").play("enemy_prepare")
    elseif s.phase == "prepare" then
        s.phase = "strike"; require("src.sound").play("enemy_strike")
    elseif s.phase == "strike" then
        s.phase = "recover"
        s.result = Combat.resolveMonsterAttack(game, s.order, s.speed, s.attackers[s.index])
        if s.result then s.onHit(s.result, s.attackers[s.index]) end
    elseif s.phase == "recover" then
        s.index = s.index + 1
        if (game.playerHp or 0) <= 0 or s.index > #s.attackers then return true end
        s.phase = "pause"
    end
    return false
end

function P.motion(s, m)
    if not s or s.attackers[s.index] ~= m then return 0 end
    local p = math.min(1, s.age / P.timing[s.phase])
    if s.phase == "prepare" then return -0.18 * (1 - (1-p)^3) end
    if s.phase == "strike" then return -0.18 + 1.33 * p * p end
    if s.phase == "recover" then
        local back = math.max(0, (s.age - 0.06) / (P.timing.recover - 0.06))
        return 1.15 * (1 - back)^3
    end
    return 0
end

return P

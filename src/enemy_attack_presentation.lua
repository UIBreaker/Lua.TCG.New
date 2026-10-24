local Combat = require("src.combat")
local Group = require("src.enemy_group")
local Motion = require("src.motion")
local Feedback = require("src.combat_feedback")
local Timing = require("src.combat_timing")
local P = { timing = { pause = 0.14, prepare = 0.40, strike = 0.18, recover = 0.56 } }
local function smooth(p) return p*p*(3-2*p) end
local function armor(game) return game.playerArmor or game.playerShield or 0 end

function P.start(game, phase, speed, onHit, onDone, options)
    if phase~="after" or not game.enemyActionPhases then Combat.beginEnemyTurn(game,speed) end
    local attackers = {}
    for _, m in ipairs(Group.members(game)) do
        if Combat.canEnemyAct(game,m,phase,speed) then
            attackers[#attackers + 1] = m
        end
    end
    if #attackers == 0 then return nil end
    return { attackers = attackers, index = 1, phase = "pause", age = 0,
        onHit = onHit, onDone = onDone, order = phase, speed = speed,
        reducedMotion = options and options.reducedMotion,
        interactive = options and options.interactive,
        hp = Feedback.updateMeter(nil,game.playerHp,0), armor = Feedback.updateMeter(nil,armor(game),0) }
end

local function nextPhase(s,game)
    s.age = 0
    if s.phase == "pause" then
        s.phase = "prepare";s.intent=s.attackers[s.index].intent
        if s.interactive and (not s.intent or s.intent.type=="attack") then
            s.timing=Timing.start("parry",s.speed or game.lastPlayerAttackSpeed,require("src.enemy_abilities").speed(s.attackers[s.index]),game)
        end
        require("src.sound").play("enemy_prepare")
    elseif s.phase == "prepare" then
        s.phase = "strike"
        if not s.intent or s.intent.type=="attack" then require("src.sound").play("enemy_strike") end
    elseif s.phase == "strike" then
        s.phase = "recover"
        s.reflectionAge=0
        local before={}
        for _,m in ipairs(Group.members(game)) do before[m]={hp=m.hp,armor=m.creatureArmor or 0} end
        s.result = Combat.resolveMonsterAttack(game, s.order, s.speed, s.attackers[s.index],s.parryResult)
        s.reactions={}
        for m,values in pairs(before) do
            if m.hp<values.hp or (m.creatureArmor or 0)<values.armor then
                local reaction={damage=math.max(0,values.hp-m.hp),
                    hp=Feedback.updateMeter(nil,values.hp,0),armor=Feedback.updateMeter(nil,values.armor,0)}
                reaction.hp=Feedback.updateMeter(reaction.hp,m.hp,0)
                reaction.armor=Feedback.updateMeter(reaction.armor,m.creatureArmor,0)
                s.reactions[m]=reaction
            end
        end
        s.hp=Feedback.updateMeter(s.hp,game.playerHp,0)
        s.armor=Feedback.updateMeter(s.armor,armor(game),0)
        if s.result then s.onHit(s.result, s.attackers[s.index]) end
    elseif s.phase == "recover" then
        s.index = s.index + 1
        if (game.playerHp or 0) <= 0 or s.index > #s.attackers then return true end
        s.phase = "pause";s.result=nil;s.intent=nil;s.reactions=nil;s.parryResult=nil
    end
    return false
end

function P.update(s, game, dt, fast, realDt)
    if s.finished then return true end
    local reflecting=s.phase=="recover" and s.result and (s.result.reflectedAttack or 0)>0
    if reflecting then
        s.reflectionAge=(s.reflectionAge or 0)+math.max(0,realDt or dt)
        if s.reflectionAge>=.22 then
            if s.onReflectionImpact then local impact=s.onReflectionImpact;s.onReflectionImpact=nil;impact() end
            for m,r in pairs(s.reactions or {}) do
                r.hp=Feedback.updateMeter(r.hp,m.hp,realDt or dt,0.24)
                r.armor=Feedback.updateMeter(r.armor,m.creatureArmor,realDt or dt,0.24)
            end
        end
    end
    if s.timing then
        if Timing.update(s.timing,realDt or dt) then
            s.parryResult=s.timing.result;s.timing=nil
        else return false end
    end
    -- Carry short-frame remainders; clamp stalls just like the player's score queue.
    local left=math.max(0,math.min(dt,0.05))*(fast and 2 or 1)
    while left>0 do
        local step=math.min(left,P.timing[s.phase]-s.age)
        s.age=s.age+step;left=left-step
        s.hp=Feedback.updateMeter(s.hp,game.playerHp,step,0.28)
        s.armor=Feedback.updateMeter(s.armor,armor(game),step,0.28)
        for m,r in pairs(s.reactions or {}) do
            if not s.result or (s.result.reflectedAttack or 0)==0 then
                r.hp=Feedback.updateMeter(r.hp,m.hp,step,0.28)
                r.armor=Feedback.updateMeter(r.armor,m.creatureArmor,step,0.28)
            end
        end
        if s.age>=P.timing[s.phase]-1e-9 then
            if s.phase=="prepare" and s.timing then return false end
            if s.phase=="recover" and s.result and (s.result.reflectedAttack or 0)>0 and (s.reflectionAge or 0)<.48 then return false end
            if nextPhase(s,game) then s.finished=true;return true end
            if s.timing then return false end
        end
    end
    return false
end

function P.reaction(s,m)
    if not s or s.reducedMotion or not (s.reactions and s.reactions[m]) then return 0,1,0 end
    local age=s.result and (s.result.reflectedAttack or 0)>0 and (s.reflectionAge or 0)-.22 or s.age
    local p=Motion.impact(age,0.32)
    local reflected=s.result and (s.result.reflectedAttack or 0)>0
    if reflected then
        -- Fast contact, a short compressed hold, then a firm release instead of a soft sine wobble.
        if age<0 then p=0
        elseif age<.025 then p=age/.025
        elseif age<.065 then p=1
        else p=math.exp(-(age-.065)*16)*math.max(0,1-(age-.065)/.25) end
    end
    local force=reflected and (s.parryResult and s.parryResult.grade=="divine" and 32 or s.parryResult and s.parryResult.grade=="apex" and 28 or 20) or 6
    return -force*p,1-(reflected and .11 or .035)*p,p
end

function P.motion(s, m)
    if not s or s.finished or s.reducedMotion or s.attackers[s.index] ~= m then return 0 end
    local p = math.min(1, s.age / P.timing[s.phase])
    if s.intent and s.intent.type~="attack" then
        if s.phase=="prepare" then return -0.10*smooth(p) end
        if s.phase=="strike" then return -0.10 end
        if s.phase=="recover" then return -0.10*(1-smooth(p)) end
        return 0
    end
    if s.phase == "prepare" then return -0.18 * smooth(p) end
    if s.phase == "strike" then return -0.18 + 1.33 * smooth(p) end
    if s.phase == "recover" then
        return 1.15*(1-Motion.settle(math.max(0,s.age-0.035),P.timing.recover-0.035))
    end
    return 0
end

function P.contact(s)
    local hit=s and s.phase=="recover" and s.result
    if not hit or hit.missed or hit.blocked or hit.action and hit.action~="attack" then return 0 end
    if (hit.damage or 0)<=0 and (hit.absorbed or 0)<=0 then return 0 end
    return Motion.impact(s.age,0.30)
end

function P.camera(s)
    if not s or s.reducedMotion then return 0,0 end
    local impact=P.contact(s)
    if impact==0 then return 0,0 end
    local strength=s.result and (s.result.damage>=8 and 2.5 or s.result.damage>0 and 1.6 or 1) or 0
    return math.sin(s.age*32)*impact*strength*0.35,impact*strength
end

function P.draw(s)
    if not s or s.finished or s.phase=="pause" then return end
    local g=love.graphics;local enemy=s.attackers[s.index]
    local x,y=enemy.screenX or 630,454
    local p=math.min(1,s.age/P.timing[s.phase])
    local attack=not s.intent or s.intent.type=="attack"
    g.push("all");g.setShader()
    if s.phase=="prepare" then
        local alpha=math.sin(p*math.pi)*0.30
        g.setColor(0.87,0.62,0.28,alpha);g.setLineWidth(1.5)
        g.ellipse("line",x,410,30+(s.reducedMotion and 0 or p*8),5)
    elseif s.phase=="strike" and attack and not s.reducedMotion then
        local head=smooth(p)
        g.setBlendMode("add")
        for lane=-1,1,2 do
            local points={}
            for i=0,8 do
                local t=math.max(0,head-0.32+i/8*0.32)
                points[#points+1]=x+lane*(25*(1-t)+3)+math.sin(t*math.pi)*8
                points[#points+1]=365+(y-365)*t
            end
            g.setColor(1,.65,.30,math.sin(p*math.pi)*0.6);g.setLineWidth(4);g.line(points)
            g.setColor(1,.88,.65,math.sin(p*math.pi)*0.85);g.setLineWidth(1.2);g.line(points)
        end
    end
    local impact=P.contact(s)
    if impact>0 then
        local shield=(s.result.damage or 0)==0
        local color=shield and {.40,.80,1} or {1,.32,.27}
        local alpha=impact*(s.reducedMotion and .32 or .65)
        g.setColor(color[1],color[2],color[3],alpha);g.setLineWidth(1.7)
        local radius=s.reducedMotion and 24 or 18+smooth(math.min(1,s.age/.30))*32
        if shield then
            -- A successful timing parry already owns the larger contact shield.
            if not s.parryResult or (s.parryResult.reduction or 0)<=0 then
                require("ui.components.shield").draw(x,y,38,color,alpha)
            end
        else g.arc("line","open",x,y,radius,math.pi*.08,math.pi*.92) end
        -- A restrained lower-edge tint places the hit on the player's side of the table.
        for i=1,6 do
            g.setColor(color[1],color[2],color[3],alpha*.022*(7-i))
            g.rectangle("fill",230,720-i*9,800,9)
        end
    end
    g.pop()
end

return P

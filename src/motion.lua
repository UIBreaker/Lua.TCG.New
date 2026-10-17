local Motion = {}

function Motion.response(speed, dt)
    return 1 - math.exp(-speed * math.max(0, dt))
end

function Motion.settle(elapsed, duration)
    local t = math.max(0, math.min(1, elapsed / duration))
    local travel = Motion.spring(0, 0, 1, 240, 24, t * 0.5)
    local tail = math.max(0, (t - 0.65) / 0.35)
    return travel + (1 - travel) * tail * tail * (3 - 2 * tail)
end

-- Exact damped spring: preserves momentum and the same timing at every FPS.
function Motion.spring(x, velocity, target, stiffness, damping, dt)
    if dt <= 0 then return x, velocity end
    local offset, half = x - target, damping * 0.5
    local discriminant = stiffness - half * half
    local decay = math.exp(-half * dt)
    if math.abs(discriminant) < 0.000001 then
        local b = velocity + half * offset
        return target + (offset + b * dt) * decay,
            (velocity - half * b * dt) * decay
    elseif discriminant > 0 then
        local frequency = math.sqrt(discriminant)
        local c, s = math.cos(frequency * dt), math.sin(frequency * dt)
        return target + decay * (offset * c + (velocity + half * offset) * s / frequency),
            decay * (velocity * c - (half * velocity + stiffness * offset) * s / frequency)
    end
    local root = math.sqrt(-discriminant)
    local r1, r2 = -half + root, -half - root
    local a = (velocity - r2 * offset) / (r1 - r2)
    local b = offset - a
    local e1, e2 = math.exp(r1 * dt), math.exp(r2 * dt)
    return target + a * e1 + b * e2, a * r1 * e1 + b * r2 * e2
end

return Motion

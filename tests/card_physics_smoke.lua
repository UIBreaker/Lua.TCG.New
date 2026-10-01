-- Run with lua tests/card_physics_smoke.lua; no LÖVE/GPU required.
local Physics = require("src.card_physics")
local Config = Physics.config

local function simulate(fps)
    local x, v, angle, av = 0, 0, 0, 0
    local p = Config.presets.MEDIUM
    for frame = 1, fps * 2 do
        local dt = 1 / fps
        local n = math.ceil(dt / Config.step)
        local target = frame <= fps and 100 or -100
        for _ = 1, n do
            x, v = Physics.spring(x, v, target, p.stiffness, p.damping, dt / n)
            angle, av = Physics.spring(angle, av, target / 1000, p.rotationStiffness, p.rotationDamping, dt / n)
        end
    end
    return x, angle
end
local x60, r60 = simulate(60)
for _, fps in ipairs({120, 144}) do
    local x, r = simulate(fps)
    assert(math.abs(x - x60) < 0.2 and math.abs(r - r60) < 0.001, "Physics changes with FPS")
end
local x, y = Physics.inversePoint(1.2, 0.4, -0.3, 0.9, 43, 85,
    43 + 1.2 * 32 - 0.3 * 78, 85 + 0.4 * 32 + 0.9 * 78)
assert(math.abs(x - 32) < 0.000001 and math.abs(y - 78) < 0.000001,
    "Inverse mouse coordinates must preserve rotation, scale, shear and pivot translation")
local p, v = 0, 500
p, v = Physics.spring(p, v, -30, 600, 32, 1 / 240)
assert(v > 0 and p > 0, "Changing direction must preserve momentum")
print("Card physics math passed: 60/120/144 FPS, inverse transforms, reversal momentum")

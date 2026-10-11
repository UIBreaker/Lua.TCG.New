local HandMotion = require("src.hand_motion")
local function simulate(fps)
    local card = { visualX = 300, visualY = 500, visualAngle = 0, visualScale = 1 }
    local function step(seconds, hover, selected)
        card.selected = selected
        for _ = 1, math.floor(seconds * fps + 0.5) do
            HandMotion.update(card, 300, 500, 0, 1 / fps, false, hover)
        end
    end
    step(0.5, true, false)
    assert(math.abs(card.visualY - 486) < 0.1 and card.visualScale < 1.04, "Hover must be subtle")
    card.selectPulse = 1
    step(0.5, true, true)
    assert(math.abs(card.visualY - 466) < 0.1 and card.visualScale < 1.05, "Selected hover must not double lift")
    step(0.5, false, true)
    assert(math.abs(card.visualY - 472) < 0.1, "Selection must stay raised after hover exits")
    step(0.5, false, false)
    local s = HandMotion.get(card)
    assert(s.hover < 0.001 and s.selected < 0.001, "Highlight must fade on exit")
    assert(math.abs(card.visualY - 500) < 0.1 and math.abs(card.visualScale - 1) < 0.001)
    return card.visualY
end
local baseline = simulate(60)
for _, fps in ipairs({30, 120, 144}) do
    assert(math.abs(simulate(fps) - baseline) < 0.02, "Hand timing must be FPS independent")
end
local card = { visualX = 0, visualY = 500, visualScale = 0.68 }
HandMotion.update(card, 300, 500, 0, 1 / 60, true, false)
assert(card.visualX == 0, "Delayed deal must remain at deck")
HandMotion.update(card, 300, 500, 0, 1 / 60, false, true)
local x = card.visualX
HandMotion.update(card, -300, 500, 0, 1 / 240, false, false)
assert(card.visualX > x, "Direction reversal must retain momentum")
for i = 1, 300 do
    HandMotion.update(card, i % 2 == 0 and 300 or -300, 500, 0.03, 1 / 30, false, i % 2 == 0)
    assert(card.visualX == card.visualX and card.visualScale > 0 and card.visualScale < 1.1)
end
print("Hand motion PASS: hover/select/exit at 30/60/120/144 FPS, deal delay, reversal, rapid sweep")

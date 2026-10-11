local Motion = require("src.motion")
local HandMotion = {}
-- Visual momentum belongs to the hand surface, never to saved card data.
local states = setmetatable({}, { __mode = "k" })

function HandMotion.get(card) return states[card] end

function HandMotion.update(card, x, y, angle, dt, waitingForDeal, hovering)
    local s = states[card]
    if not s then
        s = { vx = 0, vy = 0, angularVelocity = 0, scaleVelocity = 0, hover = 0, selected = 0 }
        states[card] = s
    end
    local response = Motion.response(22, dt)
    s.hover = s.hover + ((hovering and 1 or 0) - s.hover) * response
    s.selected = s.selected + ((card.selected and 1 or 0) - s.selected) * response
    y = y - (card.selected and 28 or 0) - (hovering and (card.selected and 6 or 14) or 0)
    if not card.visualX then
        card.visualX, card.visualY, card.visualAngle = x, y, angle
    elseif not waitingForDeal then
        card.visualX, s.vx = Motion.spring(card.visualX, s.vx, x, 900, 44, dt)
        card.visualY, s.vy = Motion.spring(card.visualY, s.vy, y, 900, 44, dt)
        card.visualAngle, s.angularVelocity = Motion.spring(card.visualAngle or angle,
            s.angularVelocity, angle, 500, 36, dt)
    end
    card.rotation = card.visualAngle
    card.selectPulse = math.max(0, (card.selectPulse or 0) - dt * 5.5)
    local scale = card.selected and 1.045 or hovering and 1.035 or 1
    scale = scale + math.sin(card.selectPulse * math.pi) * 0.018
    card.visualScale, s.scaleVelocity = Motion.spring(card.visualScale or 1,
        s.scaleVelocity, scale, 1100, 54, dt)
end

return HandMotion

local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Slot = {}

function Slot.draw(x, y, w, h, state, options)
    options = options or {}
    state = state or "empty"
    local accent = Theme.accent(options.variant or "gold")
    local g = love.graphics
    g.push("all")
    Core.gradient(x, y, w, h, Theme.colors.inset, Theme.colors.surface, Theme.radius.small)
    Core.color(state == "disabled" and Theme.colors.metal or accent,
        state == "selected" and 1 or state == "hover" and 0.82 or state == "occupied" and 0.69 or 0.43)
    g.setLineWidth(state == "selected" and 2 or 1)
    g.rectangle("line", x + 1, y + 1, w - 2, h - 2, Theme.radius.small)
    if state == "selected" or state == "hover" then
        Core.color(accent, state == "selected" and 0.16 or 0.09)
        g.rectangle("fill", x + 4, y + 4, w - 8, h - 8, Theme.radius.small)
    end
    if state == "empty" or state == "hover" then
        Core.text(options.label or "+", x + 2, y + h / 2 - 12, w - 4,
            options.font, Theme.colors.muted, "center")
    end
    g.pop()
end

return Slot

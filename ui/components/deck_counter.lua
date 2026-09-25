local Panel = require("ui.components.panel")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local DeckCounter = {}
function DeckCounter.draw(x, y, w, h, remaining, total, fonts, hovered)
    Panel.draw(x, y, w, h, {focused = hovered, variant = "cyan"})
    Core.text("BỘ BÀI", x + 8, y + 12, w - 16, fonts.tiny, Theme.colors.gold, "center")
    love.graphics.push("all")
    Core.color(Theme.colors.cyan)
    love.graphics.setLineWidth(2)
    local cx, cy = x + w / 2, y + h / 2 - 8
    love.graphics.polygon("line", cx, cy - 19, cx + 14, cy, cx, cy + 19, cx - 14, cy)
    love.graphics.pop()
    Core.text(tostring(remaining) .. " / " .. tostring(total), x + 5, y + h - 38,
        w - 10, fonts.medium, Theme.colors.text, "center")
end
return DeckCounter

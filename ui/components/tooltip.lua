local Theme = require("ui.theme")
local Panel = require("ui.components.panel")
local Core = require("ui.components.core")
local Tooltip = {}

function Tooltip.draw(x, y, w, h, title, body, fonts, variant)
    Panel.draw(x, y, w, h, {variant = variant or "gold"})
    Core.text(title, x + 10, y + 9, w - 20, fonts and fonts.small, Theme.accent(variant), "left")
    Core.text(body, x + 10, y + 30, w - 20, fonts and fonts.tiny, Theme.colors.text, "left")
end

return Tooltip

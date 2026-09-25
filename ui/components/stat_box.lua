local Theme = require("ui.theme")
local Panel = require("ui.components.panel")
local Core = require("ui.components.core")
local StatBox = {}

function StatBox.draw(x, y, w, h, label, value, variant, fonts)
    local accent = Theme.accent(variant)
    Panel.draw(x, y, w, h, {accent = accent})
    local tiny = fonts and fonts.tiny
    local medium = fonts and fonts.medium
    local display = tostring(value or "")
    if medium and medium:getWidth(display) > w - 12 then medium = fonts.small end
    if medium and medium:getWidth(display) > w - 12 then medium = fonts.tiny end
    Core.text(label, x + 5, y + 7, w - 10, tiny, accent, "center")
    Core.text(display, x + 5, y + h - (medium and medium:getHeight() or 22) - 8,
        w - 10, medium, Theme.colors.text, "center")
end

return StatBox

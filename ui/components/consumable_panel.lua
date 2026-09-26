local Panel = require("ui.components.panel")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Layout = require("ui.layout")
local ConsumablePanel = {}
function ConsumablePanel.draw(count, maxCount, fonts, _, frameImage)
    local rect = Layout.battle.consumables
    Panel.draw(rect[1], rect[2], rect[3], rect[4], {variant = "green", image = frameImage})
    Core.text("TIÊU HAO (" .. tostring(count) .. "/" .. tostring(maxCount) .. ")",
        rect[1] + 16, rect[2] + 8, rect[3] - 32, fonts.small, Theme.colors.green)
end
return ConsumablePanel

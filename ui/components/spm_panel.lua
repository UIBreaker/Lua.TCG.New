local Panel = require("ui.components.panel")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Layout = require("ui.layout")
local SPMPanel = {}
function SPMPanel.draw(count, maxCount, fonts, frameImage)
    local rect = Layout.battle.spm
    Panel.draw(rect[1], rect[2], rect[3], rect[4], {image = frameImage})
    Core.text("SPM (" .. tostring(count) .. "/" .. tostring(maxCount) .. ")",
        rect[1] + 16, rect[2] + 8, rect[3] - 32, fonts.small, Theme.colors.gold)
end
return SPMPanel

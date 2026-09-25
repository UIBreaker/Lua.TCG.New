local Panel = require("ui.components.panel")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local SPMPanel = {}
function SPMPanel.draw(count, maxCount, fonts)
    Panel.draw(1028, 73, 239, maxCount > 8 and 306 or 248)
    Core.text("SPM (" .. tostring(count) .. "/" .. tostring(maxCount) .. ")", 1044, 83,
        205, fonts.small, Theme.colors.gold)
end
return SPMPanel

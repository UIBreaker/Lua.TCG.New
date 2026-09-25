local Panel = require("ui.components.panel")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local ConsumablePanel = {}
function ConsumablePanel.draw(count, maxCount, fonts, spmSlots)
    local y = (spmSlots or 5) > 8 and 384 or 326
    Panel.draw(1028, y, 239, 146, {variant = "green"})
    Core.text("TIÊU HAO (" .. tostring(count) .. "/" .. tostring(maxCount) .. ")", 1044, y + 10,
        205, fonts.small, Theme.colors.green)
end
return ConsumablePanel

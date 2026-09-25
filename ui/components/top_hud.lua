local Panel = require("ui.components.panel")
local HealthBar = require("ui.components.health_bar")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local TopHUD = {}

function TopHUD.draw(data, fonts)
    Panel.draw(10, 8, 1260, 55)
    Core.text("ẢI " .. tostring(data.ante) .. "-" .. tostring(data.round), 24, 16, 125, fonts.small, Theme.colors.gold)
    Core.textLine(data.enemyName, 24, 38, 135, fonts.tiny, Theme.colors.text)
    HealthBar.draw(178, 19, 235, 32, data.hp, data.maxHp,
        {font = fonts.small, label = "MÁU  " .. tostring(data.hp) .. " / " .. tostring(data.maxHp)})
    Core.text("● " .. tostring(data.gold), 431, 27, 85, fonts.small, Theme.colors.gold)
    Core.text("LƯỢT " .. tostring(data.hands) .. "/" .. tostring(data.maxHands), 530, 27, 140, fonts.small)
    Core.text("BỎ " .. tostring(data.discards), 685, 27, 95, fonts.small)
end

return TopHUD

local HealthBar = require("ui.components.health_bar")
local Theme = require("ui.theme")
local Core = require("ui.components.core")
local EnemyPanel = {}

function EnemyPanel.draw(name, hp, maxHp, fonts, x)
    x = x or 630
    Core.textLine(name, x - 175, 85, 350, fonts.medium, Theme.colors.text, "center", fonts.small)
    HealthBar.draw(x - 168, 111, 336, 24, hp, maxHp, {variant = "red", font = fonts.small})
end

return EnemyPanel

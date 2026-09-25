local Theme = require("ui.theme")
local C = require("ui.components.core")
local Panel = require("ui.components.panel")
local Button = require("ui.components.button")
local Slot = require("ui.components.slot")
local StatBox = require("ui.components.stat_box")
local HealthBar = require("ui.components.health_bar")
local ProgressBar = require("ui.components.progress_bar")
local TopHUD = require("ui.components.top_hud")
local EnemyPanel = require("ui.components.enemy_panel")
local HandInfoPanel = require("ui.components.hand_info_panel")
local SPMPanel = require("ui.components.spm_panel")
local ConsumablePanel = require("ui.components.consumable_panel")
local DeckCounter = require("ui.components.deck_counter")
local Tooltip = require("ui.components.tooltip")
local TabButton = require("ui.components.tab_button")
local SortButton = require("ui.components.sort_button")
local IconButton = require("ui.components.icon_button")
local Gallery = {}

function Gallery.draw(fonts, mouseX, mouseY)
    love.graphics.push("all")
    C.color(Theme.colors.charcoal)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    TopHUD.draw({ante = 1, round = 1, enemyName = "Tiểu Yêu", hp = 82, maxHp = 100,
        gold = 76, hands = 3, maxHands = 3, discards = 3}, fonts)
    local close = {text = "ĐÓNG", x = 1152, y = 20, w = 96, h = 31, variant = "red", font = fonts.tiny}
    local closeOver = mouseX >= close.x and mouseX <= close.x + close.w
        and mouseY >= close.y and mouseY <= close.y + close.h
    Button.draw(close, closeOver and love.mouse.isDown(1) and "pressed"
        or closeOver and "hover" or "normal", fonts)
    Panel.draw(255, 76, 755, 610)
    HandInfoPanel.draw({handName = "Đơn Thủ", chips = 18, mult = 3, xMult = 1, aura = 54,
        enemyName = "Tiểu Yêu", enemyHp = 62, enemyMaxHp = 76, intent = "Tấn công 12 ST",
        debuff = "Không có hiệu ứng bất lợi"}, fonts)
    SPMPanel.draw(1, 5, fonts)
    ConsumablePanel.draw(1, 3, fonts)
    EnemyPanel.draw("Tiểu Yêu", 62, 76, fonts, 630)
    C.text("UI GALLERY — THEME & STATES", 283, 151, 650, fonts.small, Theme.colors.gold, "center")
    C.text("Panel • TopHUD • EnemyPanel • HandInfoPanel • SPMPanel • ConsumablePanel", 283, 180,
        650, fonts.tiny, Theme.colors.muted, "center")
    local states = {"normal", "hover", "pressed", "disabled", "selected"}
    local slotStates = {"empty", "hover", "selected", "occupied", "disabled"}
    for i, state in ipairs(states) do
        local x = 282 + (i - 1) * 138
        Button.draw({text = state, x = x, y = 215, w = 126, h = 42, variant = "cyan", disabled = state == "disabled"},
            state, fonts)
        Slot.draw(x + 25, 278, 76, 84, slotStates[i],
            {variant = slotStates[i] == "disabled" and "red" or "gold", font = fonts.medium})
    end
    Slot.draw(282, 373, 76, 76, "occupied", {variant = "purple", font = fonts.medium})
    C.text("occupied", 365, 399, 95, fonts.tiny, Theme.colors.muted)
    StatBox.draw(490, 373, 112, 76, "SÁT THƯƠNG", "18", "cyan", fonts)
    StatBox.draw(612, 373, 112, 76, "CƯỜNG HÓA", "3", "red", fonts)
    HealthBar.draw(748, 377, 220, 28, 62, 76, {variant = "red", font = fonts.tiny})
    ProgressBar.draw(748, 417, 220, 22, 3, 5, {variant = "purple", label = "3 / 5", font = fonts.tiny})
    Tooltip.draw(282, 474, 224, 86, "TOOLTIP", "Thông tin phụ trợ rõ ràng.", fonts, "purple")
    TabButton.draw({text = "TAB", x = 522, y = 484, w = 88, h = 39, selected = true}, "selected", fonts)
    SortButton.draw({text = "BẬC", x = 621, y = 484, w = 88, h = 39}, "hover", fonts)
    IconButton.draw({icon = "*", x = 720, y = 484, w = 48, h = 39, variant = "purple"}, "normal", fonts)
    C.text("TabButton  •  SortButton  •  IconButton", 522, 533, 260, fonts.tiny, Theme.colors.muted)
    local live = {text = "THỬ HOVER / NHẤN", x = 282, y = 586, w = 222, h = 54, variant = "cyan"}
    local over = mouseX >= live.x and mouseX <= live.x + live.w and mouseY >= live.y and mouseY <= live.y + live.h
    Button.draw(live, over and love.mouse.isDown(1) and "pressed" or over and "hover" or "normal", fonts)
    C.text("F8 hoặc ESC: đóng Gallery", 522, 603, 270, fonts.small, Theme.colors.muted)
    DeckCounter.draw(1140, 535, 115, 160, 49, 52, fonts, false)
    love.graphics.pop()
end

return Gallery

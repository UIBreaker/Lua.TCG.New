local Theme = require("ui.theme")
local Panel = require("ui.components.panel")
local StatBox = require("ui.components.stat_box")
local HealthBar = require("ui.components.health_bar")
local Core = require("ui.components.core")
local HandInfoPanel = {}

function HandInfoPanel.draw(data, fonts, formatNumber)
    local x, y, w, h = 12, 76, 222, 615
    local fmt = formatNumber or tostring
    Panel.draw(x, y, w, h)
    Core.text("TAY BÀI", x + 14, y + 16, w - 28, fonts.small, Theme.colors.gold)
    Core.textLine(data.handName, x + 14, y + 40, w - 28, fonts.small)
    StatBox.draw(x + 12, y + 78, 94, 66, "SÁT THƯƠNG", fmt(data.chips), "cyan", fonts)
    StatBox.draw(x + 116, y + 78, 94, 66, "CƯỜNG HÓA", fmt(data.mult), "red", fonts)
    Core.text(fmt(data.chips) .. " × " .. fmt(data.mult)
        .. ((data.xMult or 1) > 1 and ("  × " .. string.format("%.2f", data.xMult)) or ""),
        x + 12, y + 155, w - 24, fonts.small, Theme.colors.muted, "center")
    StatBox.draw(x + 12, y + 183, w - 24, 74,
        data.scoring and "AURA ĐANG CỘNG" or "AURA DỰ KIẾN", fmt(data.aura), "gold", fonts)
    local g = love.graphics
    g.push("all")
    Core.color(Theme.colors.goldDim, 0.65)
    g.line(x + 14, y + 270, x + w - 14, y + 270)
    g.pop()
    Core.text("QUÁI VẬT", x + 14, y + 284, w - 28, fonts.small, Theme.colors.gold)
    Core.textLine(data.enemyName, x + 14, y + 310, w - 28, fonts.small)
    Core.text("MÁU " .. tostring(data.enemyHp) .. "/" .. tostring(data.enemyMaxHp),
        x + 14, y + 337, w - 28, fonts.tiny, Theme.colors.muted)
    HealthBar.draw(x + 14, y + 359, w - 28, 18, data.enemyHp, data.enemyMaxHp,
        {variant = "red", label = ""})
    Core.text("CHIÊU TIẾP THEO", x + 14, y + 393, w - 28, fonts.tiny, Theme.colors.red)
    Core.text(data.intent, x + 14, y + 413, w - 28, fonts.small)
    Core.text(data.isBoss and "DEBUFF" or "ĐẶC ĐIỂM", x + 14, y + 465, w - 28, fonts.tiny, Theme.colors.gold)
    Core.text(data.debuff, x + 14, y + 486, w - 28, fonts.tiny, Theme.colors.muted)
    if data.scoring then
        Core.text(data.category or "ĐANG CỘNG AURA", x + 14, y + 552, w - 28, fonts.tiny, Theme.colors.gold)
        Core.text(data.detail or "", x + 14, y + 574, w - 28, fonts.tiny)
    end
end

return HandInfoPanel

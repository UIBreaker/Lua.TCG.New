local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Button = {}
local utf8 = require("utf8")

local function fitLabel(label, font, maxWidth, fonts)
    if font:getWidth(label) <= maxWidth then return label, font end
    if fonts and fonts.tiny and font ~= fonts.tiny then font = fonts.tiny end
    if font:getWidth(label) <= maxWidth then return label, font end
    local clipped = label
    while #clipped > 0 and font:getWidth(clipped .. "…") > maxWidth do
        local ok, last = pcall(utf8.offset, clipped, -1)
        clipped = clipped:sub(1, (ok and last or #clipped) - 1)
    end
    return clipped .. "…", font
end

function Button.draw(btn, state, fonts)
    if not btn or btn.invisible then return end
    local g = love.graphics
    state = state or (btn.disabled and "disabled" or btn.selected and "selected" or "normal")
    if btn.disabled then state = "disabled" end
    local accent = Theme.accent(Theme.buttonVariant(btn))
    local x, y, w, h = btn.x, btn.y, btn.w, btn.h
    local lift = state == "pressed" and 2 or 0
    local edge = state == "disabled" and Theme.colors.metal or accent
    g.push("all")
    Core.color(Theme.colors.shadow, 0.45)
    g.rectangle("fill", x + 2, y + 4, w, h, Theme.radius.small)
    Core.gradient(x, y + lift, w, h - lift, state == "disabled" and Theme.colors.surface or Theme.colors.raised,
        state == "pressed" and Theme.colors.inset or Theme.colors.surface, Theme.radius.small)
    Core.color(edge, state == "disabled" and 0.4 or state == "hover" and 1 or state == "selected" and 1 or 0.68)
    g.setLineWidth((state == "hover" or state == "selected") and Theme.border.focus or Theme.border.regular)
    g.rectangle("line", x + 1, y + lift + 1, w - 2, h - lift - 2, Theme.radius.small)
    if state == "hover" or state == "selected" then
        Core.color(accent, state == "hover" and Theme.glow.hover or Theme.glow.selected)
        g.rectangle("fill", x + 4, y + lift + 4, w - 8, h - lift - 8, Theme.radius.small)
    end
    local font = btn.font or (fonts and fonts.small) or g.getFont()
    local label = tostring(btn.text or "")
    local textX, textW = x + 7, w - 14
    if btn.menuStyle and btn.icon then
        Core.text(btn.icon, x + 14, y + (h - font:getHeight()) / 2, 42, font, accent, "center")
        textX, textW = x + 64, w - 76
    end
    label, font = fitLabel(label, font, textW, fonts)
    g.setFont(font)
    local textY = y + lift + (h - lift - font:getHeight()) / 2 - (btn.sub and 9 or 0)
    Core.text(label, textX, textY, textW, font, state == "disabled" and Theme.colors.muted or Theme.colors.text,
        btn.menuStyle and "left" or "center")
    if btn.sub then Core.text(btn.sub, textX, textY + font:getHeight() + 1, textW,
        fonts and fonts.tiny or font, Theme.colors.muted, btn.menuStyle and "left" or "center") end
    g.pop()
end

return Button

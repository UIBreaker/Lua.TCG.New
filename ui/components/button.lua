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
    local accent = btn.menuAccent or Theme.accent(Theme.buttonVariant(btn))
    local x, y, w, h = btn.x, btn.y, btn.w, btn.h
    local lift = state == "pressed" and 2 or 0
    local edge = state == "disabled" and Theme.colors.metal or accent
    g.push("all")
    if btn.backgroundImage then
        local image = btn.backgroundImage
        local iw, ih = image:getDimensions()
        local scale = math.min(w / iw, h / ih) * (state == "hover" and 1.012 or state == "pressed" and 0.99 or 1)
        local drawW, drawH = iw * scale, ih * scale
        local drawX, drawY = x + (w - drawW) / 2, y + (h - drawH) / 2 + lift
        if state == "hover" then
            g.setBlendMode("add", "alphamultiply")
            g.setColor(accent[1], accent[2], accent[3], 0.34)
            g.draw(image, drawX - 2, drawY - 2, 0, scale * 1.012, scale * 1.012)
            g.setBlendMode("alpha", "alphamultiply")
        end
        g.setColor(1, 1, 1, state == "pressed" and 0.9 or state == "disabled" and 0.45 or 1)
        g.draw(image, drawX, drawY, 0, scale, scale)
    else
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
    end
    local font = btn.font or (fonts and fonts.small) or g.getFont()
    local label = tostring(btn.text or "")
    local textX, textW = x + 7, w - 14
    if btn.menuStyle and btn.icon then
        local iconW = 34
        Core.text(btn.icon, x + 32, y + (h - font:getHeight()) / 2 + lift, iconW, font, accent, "center")
        textX, textW = x + 76, w - 152
    end
    label, font = fitLabel(label, font, textW, fonts)
    local subFont = fonts and (fonts.small or fonts.tiny) or font
    local sub = btn.sub
    if sub and subFont:getWidth(sub) > textW then sub, subFont = fitLabel(sub, subFont, textW, fonts) end
    local subHeight = sub and (subFont:getHeight() + 1) or 0
    local textY = y + lift + (h - lift - font:getHeight() - subHeight) / 2
    Core.text(label, textX, textY, textW, font,
        state == "disabled" and Theme.colors.muted or Theme.colors.text, "center")
    if sub then Core.text(sub, textX, textY + font:getHeight() + 1, textW, subFont,
        Theme.colors.muted, "center") end
    g.pop()
end

return Button

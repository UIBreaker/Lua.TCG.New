local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Button = {}
local utf8 = require("utf8")
local Motion = require("src.motion")
local animations, time, sweep = {}, 0, 0

function Button.update(dt)
    time = time + math.max(0, dt)
    if time - sweep < 1 then return end
    sweep = time
    for key, a in pairs(animations) do
        if time - a.last > 1 then animations[key] = nil end
    end
end

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
    -- Buttons are recreated by layouts; retain motion by identity and position.
    local key = table.concat({tostring(btn.id or btn.text or ""), x, y, w, h}, ":")
    local a = animations[key]
    if not a then a = {hover=0, press=0, last=time}; animations[key] = a end
    local response = Motion.response(24, time - a.last)
    a.last = time
    a.hover = a.hover + ((state == "hover" and 1 or 0) - a.hover) * response
    a.press = a.press + ((state == "pressed" and 1 or 0) - a.press) * response
    if state == "disabled" then a.hover, a.press = 0, 0 end
    local lift = 2 * a.press - 1.5 * a.hover
    local edge = state == "disabled" and Theme.colors.metal or accent
    g.push("all")
    local drawScale = (btn.animationScale or 1) * (1 + 0.012 * a.hover
        + ((btn.pressScale or 0.985) - 1) * a.press)
    if drawScale and drawScale ~= 1 then
        g.translate(x + w / 2, y + h / 2)
        g.scale(drawScale, drawScale)
        g.translate(-x - w / 2, -y - h / 2)
    end
    if btn.backgroundImage then
        local image = btn.backgroundImage
        local iw, ih = image:getDimensions()
        local scale = math.min(w / iw, h / ih)
        local drawW, drawH = iw * scale, ih * scale
        local drawX, drawY = x + (w - drawW) / 2, y + (h - drawH) / 2 + lift
        if a.hover > 0.001 then
            g.setBlendMode("add", "alphamultiply")
            g.setColor(accent[1], accent[2], accent[3], 0.34 * a.hover)
            g.draw(image, drawX - 2, drawY - 2, 0, scale * 1.012, scale * 1.012)
            g.setBlendMode("alpha", "alphamultiply")
        end
        g.setColor(1, 1, 1, state == "disabled" and 0.45 or 1 - 0.1 * a.press)
        g.draw(image, drawX, drawY, 0, scale, scale)
    else
        Core.color(Theme.colors.shadow, 0.45)
        g.rectangle("fill", x + 2, y + 4, w, h, Theme.radius.small)
        Core.gradient(x, y + lift, w, h - lift, state == "disabled" and Theme.colors.surface or Theme.colors.raised,
            state == "pressed" and Theme.colors.inset or Theme.colors.surface, Theme.radius.small)
        Core.color(edge, state == "disabled" and 0.4 or state == "selected" and 1 or 0.68 + 0.32 * a.hover)
        g.setLineWidth(Theme.border.regular + (Theme.border.focus - Theme.border.regular)
            * (state == "selected" and 1 or a.hover))
        g.rectangle("line", x + 1, y + lift + 1, w - 2, h - lift - 2, Theme.radius.small)
        if a.hover > 0.001 or state == "selected" then
            Core.color(accent, state == "selected" and Theme.glow.selected or Theme.glow.hover * a.hover)
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

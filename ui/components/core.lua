local Theme = require("ui.theme")
local Core = {}
local utf8 = require("utf8")

function Core.color(c, alpha)
    love.graphics.setColor(c[1], c[2], c[3], alpha or c[4] or 1)
end

function Core.mix(a, b, t)
    return {a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t, a[4] or 1}
end

function Core.gradient(x, y, w, h, top, bottom, radius)
    local g = love.graphics
    Core.color(top)
    g.rectangle("fill", x, y, w, h, radius, radius)
    if w <= 8 or h <= 8 then return end
    for i = 1, 12 do
        Core.color(Core.mix(top, bottom, i / 12), (top[4] or 1) * 0.72)
        g.rectangle("fill", x + 3, y + 3 + (i - 1) * (h - 6) / 12,
            w - 6, (h - 6) / 12 + 0.5)
    end
end

function Core.text(value, x, y, w, font, color, align)
    local g = love.graphics
    if font then g.setFont(font) end
    Core.color(color or Theme.colors.text)
    g.printf(tostring(value or ""), x, y, math.max(1, w), align or "left")
end

function Core.textLine(value, x, y, w, font, color, align, smallerFont)
    local label = tostring(value or "")
    local chosen = font or love.graphics.getFont()
    if chosen:getWidth(label) > w and smallerFont then chosen = smallerFont end
    if chosen:getWidth(label) > w then
        while #label > 0 and chosen:getWidth(label .. "…") > w do
            local ok, last = pcall(utf8.offset, label, -1)
            label = label:sub(1, (ok and last or #label) - 1)
        end
        label = label .. "…"
    end
    Core.text(label, x, y, w, chosen, color, align)
end

function Core.ornament(x, y, w, h, color)
    local g = love.graphics
    Core.color(color, 0.73)
    local s = math.min(9, w / 8, h / 5)
    g.line(x + 4, y + s + 3, x + 4, y + 4, x + s + 3, y + 4)
    g.line(x + w - s - 3, y + 4, x + w - 4, y + 4, x + w - 4, y + s + 3)
    g.line(x + 4, y + h - s - 3, x + 4, y + h - 4, x + s + 3, y + h - 4)
    g.line(x + w - s - 3, y + h - 4, x + w - 4, y + h - 4, x + w - 4, y + h - s - 3)
end

return Core

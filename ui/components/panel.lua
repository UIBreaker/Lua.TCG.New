local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Panel = {}

function Panel.draw(x, y, w, h, options)
    options = options or {}
    if w <= 0 or h <= 0 then return end
    local g = love.graphics
    local accent = options.accent or Theme.accent(options.variant)
    local r = math.min(options.radius or Theme.radius.medium, w / 4, h / 4)
    g.push("all")
    Core.color(Theme.colors.shadow, Theme.shadows.alpha)
    g.rectangle("fill", x + Theme.shadows.x, y + Theme.shadows.y, w, h, r, r)
    Core.gradient(x, y, w, h, Theme.colors.raised, Theme.colors.surface, r)
    Core.color(Theme.colors.metal, 0.52)
    g.setLineWidth(Theme.border.regular)
    g.rectangle("line", x + 1, y + 1, w - 2, h - 2, r, r)
    if w > 10 and h > 10 then
        Core.color(accent, options.focused and 0.96 or 0.72)
        g.setLineWidth(options.focused and Theme.border.focus or Theme.border.thin)
        g.rectangle("line", x + 3, y + 3, w - 6, h - 6, math.max(1, r - 2), math.max(1, r - 2))
    end
    if w > 38 and h > 30 then Core.ornament(x, y, w, h, accent) end
    g.pop()
end

return Panel

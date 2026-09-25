local Theme = require("ui.theme")
local Core = require("ui.components.core")
local ProgressBar = {}

function ProgressBar.draw(x, y, w, h, value, maxValue, options)
    options = options or {}
    local g = love.graphics
    local ratio = math.max(0, math.min(1, (value or 0) / math.max(1, maxValue or 1)))
    local accent = Theme.accent(options.variant or "cyan")
    g.push("all")
    Core.color(Theme.colors.inset)
    g.rectangle("fill", x, y, w, h, Theme.radius.small)
    if ratio > 0 then
        Core.color(accent, 0.82)
        g.rectangle("fill", x + 3, y + 3, (w - 6) * ratio, h - 6, 2, 2)
        Core.color(Theme.colors.text, 0.12)
        g.rectangle("fill", x + 3, y + 3, (w - 6) * ratio, math.max(1, (h - 6) / 3), 2, 2)
    end
    Core.color(accent, 0.66)
    g.rectangle("line", x + 1, y + 1, w - 2, h - 2, Theme.radius.small)
    if options.label then Core.text(options.label, x + 5, y + (h - (options.font or g.getFont()):getHeight()) / 2,
        w - 10, options.font, Theme.colors.text, "center") end
    g.pop()
end

return ProgressBar

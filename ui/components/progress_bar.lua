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
    if options.trailValue then
        local trail = math.max(0, math.min(1, options.trailValue / math.max(1, maxValue or 1)))
        Core.color(options.trailColor or Theme.colors.gold, 0.58)
        g.rectangle("fill", x + 3, y + 3, (w - 6) * trail, h - 6, 2, 2)
    end
    if ratio > 0 then
        if options.shield then
            Core.gradient(x+3,y+3,(w-6)*ratio,h-6,{0.16,0.72,0.94,1},{0.055,0.23,0.40,1},2)
            for i=1,7 do
                local sx=x+3+(w-6)*i/8
                if sx<x+3+(w-6)*ratio then
                    Core.color({0.025,0.095,0.14},0.35);g.line(sx,y+4,sx,y+h-4)
                end
            end
        else
            Core.color(accent, 0.82)
            g.rectangle("fill", x + 3, y + 3, (w - 6) * ratio, h - 6, 2, 2)
        end
        Core.color(Theme.colors.text, 0.12)
        g.rectangle("fill", x + 3, y + 3, (w - 6) * ratio, math.max(1, (h - 6) / 3), 2, 2)
    end
    Core.color(accent, 0.66)
    g.rectangle("line", x + 1, y + 1, w - 2, h - 2, Theme.radius.small)
    if options.shield then
        local flash=math.max(0,math.min(1,options.pulse or 0))
        Core.color({0.70,0.94,1},flash*0.24);g.rectangle("fill",x+2,y+2,w-4,h-4,2,2)
        Core.color({0.65,0.90,1},0.92);g.setLineWidth(1)
        local cx,cy,r=x+9,y+h/2,h*0.34
        g.polygon("line",cx-r*0.7,cy-r*0.6,cx,cy-r,cx+r*0.7,cy-r*0.6,cx+r*0.6,cy+r*0.2,cx,cy+r,cx-r*0.6,cy+r*0.2)
    end
    if options.label then Core.text(options.label, x + 5, y + (h - (options.font or g.getFont()):getHeight()) / 2,
        w - 10, options.font, Theme.colors.text, "center") end
    g.pop()
end

return ProgressBar

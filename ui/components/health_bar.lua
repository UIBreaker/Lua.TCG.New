local ProgressBar = require("ui.components.progress_bar")
local HealthBar = {}

function HealthBar.draw(x, y, w, h, hp, maxHp, options)
    options = options or {}
    options.variant = options.variant or "green"
    options.label = options.label or (tostring(math.max(0, math.floor(hp or 0))) .. " / " .. tostring(maxHp or 0) .. " HP")
    ProgressBar.draw(x, y, w, h, hp, maxHp, options)
end

return HealthBar

local Button = require("ui.components.button")
local TabButton = {}
function TabButton.draw(btn, state, fonts)
    btn.variant = btn.variant or "gold"
    Button.draw(btn, state, fonts)
end
return TabButton

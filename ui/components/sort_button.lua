local Button = require("ui.components.button")
local SortButton = {}
function SortButton.draw(btn, state, fonts)
    btn.variant = "cyan"
    Button.draw(btn, state, fonts)
end
return SortButton

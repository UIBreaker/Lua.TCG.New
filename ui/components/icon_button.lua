local Button = require("ui.components.button")
local IconButton = {}
function IconButton.draw(btn, state, fonts)
    btn.text = btn.icon or btn.text
    Button.draw(btn, state, fonts)
end
return IconButton

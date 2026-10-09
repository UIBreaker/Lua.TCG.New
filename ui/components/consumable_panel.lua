local P={}
function P.draw(count,maxCount,fonts)
 require("ui.combat_chrome").rail(require("ui.layout").battle.consumables,count,maxCount,fonts,"consumable","TIÊU HAO",require("ui.theme").colors.green)
end
return P

local P={}
function P.draw(count,maxCount,fonts)
 require("ui.combat_chrome").rail(require("ui.layout").battle.spm,count,maxCount,fonts,"spn","HỘ LINH",require("ui.theme").colors.gold)
end
return P

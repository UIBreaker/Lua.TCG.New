local Rail={}
function Rail.range(kind,game)
    local total=kind=="spn" and require("src.deities").getMaxSlots(game) or require("src.inventory").limit(game)
    return 1,total,total
end
function Rail.localIndex(kind,index,game)
    local first,last,total=Rail.range(kind,game)
    if index<first or index>last then return nil end
    return index,total
end
function Rail.rect(kind,index,game)
    local localIndex,total=Rail.localIndex(kind,index,game)
    if not localIndex then return -10000,-10000,1,1 end
    local Layout=require("ui.layout")
    return Layout.fanCardRect(kind=="spn" and Layout.battle.spm or Layout.battle.consumables,localIndex,total)
end
function Rail.hint(kind,game)
    local count=kind=="spn" and require("src.deities").getCount(game.deities) or #(game.consumables or {})
    return "Hiện "..count.." lá"
end
-- The full fan is always visible; scrolling is reserved for the expanded view.
function Rail.canSwipe() return false end
function Rail.scroll() return false end
return Rail

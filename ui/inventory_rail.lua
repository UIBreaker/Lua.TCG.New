local Rail={offsets={spn=0,consumable=0}}
function Rail.canSwipe(game,state,x,y)
    if state~="shop" and state~="playing" then return false end
    local spn,cons
    if state=="shop" then spn={1028,78,239,237};cons={1028,318,239,145}
    else local layout=require("ui.layout").battle;spn=layout.spm;cons=layout.consumables end
    for kind,rect in pairs({spn=spn,consumable=cons}) do
        local _,_,total=Rail.range(kind,game)
        if total>(kind=="spn" and 6 or 3) and x>=rect[1] and x<=rect[1]+rect[3] and y>=rect[2] and y<=rect[2]+rect[4] then return true end
    end
    return false
end
function Rail.range(kind,game)
    local total=kind=="spn" and require("src.deities").getMaxSlots(game) or require("src.inventory").limit(game)
    local visible=kind=="spn" and 6 or 3
    Rail.offsets[kind]=math.max(0,math.min(Rail.offsets[kind],total-visible))
    local first=Rail.offsets[kind]+1
    return first,math.min(total,first+visible-1),total
end
function Rail.localIndex(kind,index,game)
    local first,last=Rail.range(kind,game)
    if index<first or index>last then return nil end
    return index-first+1,last-first+1
end
function Rail.reveal(kind,index,game)
    local first,last=Rail.range(kind,game)
    if index<first then Rail.offsets[kind]=index-1
    elseif index>last then Rail.offsets[kind]=index-(kind=="spn" and 6 or 3) end
end
function Rail.scroll(game,state,mx,my,dy)
    if dy==0 then return false end
    local spn,cons
    if state=="shop" then spn={1028,78,239,237};cons={1028,318,239,145}
    else local layout=require("ui.layout").battle;spn=layout.spm;cons=layout.consumables end
    for kind,rect in pairs({spn=spn,consumable=cons}) do
        if mx>=rect[1] and mx<=rect[1]+rect[3] and my>=rect[2] and my<=rect[2]+rect[4] then
            local _,_,total=Rail.range(kind,game)
            local visible=kind=="spn" and 6 or 3
            Rail.offsets[kind]=math.max(0,math.min(total-visible,Rail.offsets[kind]-(dy>0 and visible or -visible)))
            return true
        end
    end
    return false
end
function Rail.hint(kind,game)
    local first,last,total=Rail.range(kind,game)
    if total>(kind=="spn" and 6 or 3) then return first.."–"..last.."/"..total.." ↕" end
    return ""
end
return Rail

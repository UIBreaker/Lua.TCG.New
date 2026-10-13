local T={}
local UI=require("src.ui")
local Rail=require("ui.inventory_rail")
local L=require("src.loadout")
local step,deadline=0,0
local drawnSpn,drawnCon={},{}
local function pointer(r,click,mouse)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(r[1]+r[3]/2)*s,(h-720*s)/2+(r[2]+r[4]/2)*s
    love.mouse.setPosition(x,y)
    if click then love.mousepressed(x,y,mouse or 1);love.mousereleased(x,y,mouse or 1) end
end
local function check(kind,game,total)
    local first,last=Rail.range(kind,game)
    assert(first==1 and last==total,"All current slots must be visible")
    local panel=kind=="spn" and require("ui.layout").battle.spm or require("ui.layout").battle.consumables
    local rects={}
    for slot=first,last do
        local x,y,w,h=Rail.rect(kind,slot,game)
        assert(w==82 and h==118,"Original card size")
        assert(x>=panel[1]+16 and x+w<=panel[1]+panel[3]-16+.001 and y==panel[2]+43 and y+h<=panel[2]+panel[4]-17,"Original panel bounds")
        if #rects>0 then
            local previous=rects[#rects]
            assert(x>previous[1] and y==previous[2],"All cards share the original fan row")
            if total>3 then assert(x<previous[1]+previous[3],"Original overlapping presentation") end
        end
        rects[#rects+1]={x,y,w,h}
    end
end
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        require("tests.inventory_expansion_smoke")
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.monster.hp=100000;game.monster.maxHp=100000
        game.extraDeitySlots=10;game.maxConsumables=7;game.deities={};game.consumables={}
        local ids={};for id in pairs(require("src.deities").CATALOG) do ids[#ids+1]=id end;table.sort(ids)
        for slot=1,15 do local d={};for k,v in pairs(require("src.deities").CATALOG[ids[slot]]) do d[k]=v end;game.deities[slot]=d end
        for _,slot in ipairs({1,2,3,7}) do local c=require("src.shop").healingItem("upper","healing_potion").consumable;c.loadoutSlot=slot;game.consumables[#game.consumables+1]=c end
        L.init(game)
        local draw,patron,consumable=love.draw,UI.drawPatronCard,UI.getConsumableImage
        UI.drawPatronCard=function(d,...) drawnSpn[d]=true;return patron(d,...) end
        UI.getConsumableImage=function(c,...) drawnCon[c]=true;return consumable(c,...) end
        love.draw=function(...) drawnSpn,drawnCon={},{};return draw(...) end
        pointer({0,0,1,1})
    elseif step==1 then
        check("spn",game,15);check("consumable",game,7)
        for _,d in pairs(game.deities) do assert(drawnSpn[d],"Every SPN actually renders") end
        for _,c in ipairs(game.consumables) do assert(drawnCon[c],"Every consumable actually renders") end
        assert(L.equipped(game,"consumable",7) and not L.equipped(game,"consumable",4))
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/inventory_rail_15_spn_7_consumables.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
        T.hoverSlot=15
        local x,y,w,h=UI.getDeitySlotRect(T.hoverSlot,"playing")
        pointer({x+w-2,y+h/2,1,1})
    elseif step==2 then
        assert(UI.descriptionCandidate==game.deities[T.hoverSlot],"Exposed edge hovers exact SPN "..T.hoverSlot)
        if T.hoverSlot>1 then
            T.hoverSlot=T.hoverSlot-1
            local x,y,w,h=UI.getDeitySlotRect(T.hoverSlot,"playing")
            pointer({x+w-2,y+h/2,1,1});deadline=love.timer.getTime()+.2;return
        end
        pointer({UI.getConsumableSlotRect(4,"playing")})
    elseif step==3 then
        assert(UI.descriptionCandidate==game.consumables[4],"Sparse consumable slot 7 stays accessible")
        game.playerHp=50;pointer({UI.getConsumableSlotRect(4,"playing")},true,2)
        assert(game.playerHp==75 and #game.consumables==3,"Exact consumable activates")
        game.extraDeitySlots=11
        game.deities[16]={};for k,v in pairs(game.deities[15]) do game.deities[16][k]=v end
    elseif step==4 then
        check("spn",game,16);assert(drawnSpn[game.deities[16]],"Extra SPN renders without paging")
        game.deities[16]=nil;game.extraDeitySlots=10
        cb.openPauseMenu()
    elseif step==5 then
        assert(UI.descriptionCandidate==nil,"Paused inventory cannot hover")
        cb.closePauseMenu();UI.ExpandedInventory.show("spn")
    elseif step==6 then
        assert(UI.ExpandedInventory.pages==2 and #UI.ExpandedInventory.slots==10)
        UI.ExpandedInventory.close()
    elseif step==7 then
        local first,last,hands=game.deities[1],game.deities[15],game.handsRemaining
        local x,y,w,h=UI.getDeitySlotRect(1,"playing")
        local tx,ty,tw,th=UI.getDeitySlotRect(15,"playing")
        local ww,wh=love.graphics.getDimensions();local s=math.min(ww/1280,wh/720)
        local px,py=(ww-1280*s)/2+(x+20)*s,(wh-720*s)/2+(y+h/2)*s
        local dx,dy=(ww-1280*s)/2+(tx+tw-2)*s,(wh-720*s)/2+(ty+th/2)*s
        love.mousepressed(px,py,1);love.mousemoved(dx,dy,dx-px,dy-py);love.mousereleased(dx,dy,1)
        assert(game.deities[15]==first and game.deities[1]==last and game.handsRemaining==hands-1,"Drop selects exact exposed fifteenth SPN")
        print("INVENTORY FAN PASS: original panels/overlap/size, all 15/16 SPN and 4 consumables rendered, every SPN edge hover, sparse slots, exact use/drop, expanded view, modal isolation")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+.8
end
return T

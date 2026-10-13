local T={};local step,deadline=0,0
local UI=require("src.ui")
local E=require("ui.inventory_expanded")
local L=require("src.loadout")
local D=require("src.deities")
local Shop=require("src.shop")
local function pointer(r)
    assert(r,"missing expanded inventory control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    return (w-1280*s)/2+(r.x+r.w/2)*s,(h-720*s)/2+(r.y+r.h/2)*s
end
local function click(r,mouse)
    local x,y=pointer(r);love.mouse.setPosition(x,y);love.mousepressed(x,y,mouse or 1);love.mousereleased(x,y,mouse or 1)
end
local function control(id)
    for _,b in ipairs(E.controls) do if b.id==id then return b end end
end
local function rail(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function drag(from,to)
    local x,y=pointer(from);love.mouse.setPosition(x,y);love.mousepressed(x,y,1)
    local tx,ty=pointer(to);love.mouse.setPosition(tx,ty);love.mousemoved(tx,ty,tx-x,ty-y);love.mousereleased(tx,ty,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/expanded_inventory_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime()
    assert(love.timer.getTime()-T.started<35,"expanded inventory timeout at "..step)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.monster.hp=10000;game.monster.maxHp=10000;game.extraDeitySlots=4;game.deities={}
        local ids={};for id in pairs(D.CATALOG) do ids[#ids+1]=id end;table.sort(ids)
        for i=1,9 do local instance={};for k,v in pairs(D.CATALOG[ids[i]]) do instance[k]=v end;game.deities[i]=instance end
        T.hands=game.handsRemaining;T.hp=game.playerHp;T.ninth=game.deities[9]
    elseif step==1 then click(rail(cb,"expand_spn"));assert(E.open)
    elseif step==2 then
        assert(#E.slots==9 and E.pages==1)
        for i,r in ipairs(E.slots) do
            assert(r.item==game.deities[i] and r.x>=30 and r.x+r.w<854 and r.y+r.h<649)
            for j=1,i-1 do local other=E.slots[j];assert(r.x>=other.x+other.w or other.x>=r.x+r.w or r.y>=other.y+other.h or other.y>=r.y+r.h,"cards must not overlap") end
        end
        click(E.slots[9]);love.keypressed("space");assert(game.handsRemaining==T.hands and game.playerHp==T.hp)
        shot("spn")
    elseif step==3 then
        assert(E.selectedItem==T.ninth)
        click(E.slots[9],2);assert(cb.getInspector()==T.ninth)
    elseif step==4 then love.keypressed("escape");assert(not cb.getInspector() and E.open)
    elseif step==5 then click(control("tab_consumable"))
    elseif step==6 then click(E.slots[1]);shot("consumables")
    elseif step==7 then
        game.playerHp=50;click(control("use"))
        assert(game.playerHp==75 and #game.consumables==2 and not E.open and game.handsRemaining==T.hands)
        local edition=Shop.getPackContents("edition")[1]
        for _,c in ipairs(Shop.getPackContents("edition")) do if c.edition=="foil" then edition=c end end
        local item={};for k,v in pairs(edition) do item[k]=v end;item.category="edition";item.loadoutSlot=1
        game.consumables[#game.consumables+1]=item;T.edition=item.edition
    elseif step==8 then click(rail(cb,"expand_consumable"))
    elseif step==9 then click(E.slots[1])
    elseif step==10 then click(control("use"));assert(E.open and E.kind=="spn");shot("edition_target")
    elseif step==11 then
        click(E.slots[9])
        assert(T.ninth.edition==T.edition and #game.consumables==2,"edition targets the exact ninth SPN")
        for i=1,8 do assert(not game.deities[i].edition,"other SPN retain their editions") end
        assert(game.handsRemaining==T.hands)
        local invalid
        for _,c in ipairs(Shop.getPackContents("edition")) do
            if not require("src.card_effects").getScoreBonus(c) then invalid={};for k,v in pairs(c) do invalid[k]=v end;break end
        end
        assert(invalid);invalid.category="edition";invalid.loadoutSlot=1
        game.consumables[#game.consumables+1]=invalid
        E.callbacks.activate(#game.consumables);E.callbacks.target(E.slots[9])
        assert(E.message and game.consumables[#game.consumables]==invalid and T.ninth.edition==T.edition,"incompatible edition explains the restriction and retains the card")
        love.keypressed("escape");assert(E.open and #game.consumables==3,"cancel target retains the imprint")
        table.remove(game.consumables)
    elseif step==12 then
        game.extraDeitySlots=9;love.keypressed("right")
    elseif step==13 then
        assert(E.page==2 and E.slots[1].slot==11 and #E.slots==4)
        love.keypressed("left")
    elseif step==14 then
        T.first=game.deities[1];T.second=game.deities[2]
        drag(E.slots[1],{x=5,y=5,w=5,h=5});assert(game.handsRemaining==T.hands and E.open)
        local Boss=require("src.boss_abilities");T.lock=Boss.isSlotLocked
        Boss.isSlotLocked=function(g,kind,slot) return kind=="spn" and slot==2 or T.lock(g,kind,slot) end
        drag(E.slots[1],E.slots[2]);assert(E.open and game.handsRemaining==T.hands and game.deities[1]==T.first)
        Boss.isSlotLocked=T.lock
        click(E.slots[1])
    elseif step==15 then click(control("reorder"));assert(E.moving==1)
    elseif step==16 then
        click(E.slots[2]);assert(not E.open and game.deities[2]==T.first and game.deities[1]==T.second and game.handsRemaining==T.hands-1)
    elseif step==17 then
        if not next(game.enemyActed or {}) then return end
        click(rail(cb,"expand_spn"));if not E.open then return end
    elseif step==18 then
        game.handsRemaining=0;drag(E.slots[1],E.slots[2]);assert(E.open and game.deities[1]==T.second)
        game.handsRemaining=2
        drag(E.slots[1],E.slots[3]);assert(not E.open and game.deities[3]==T.second and game.handsRemaining==1)
    elseif step==19 then
        print("PASS: expanded SPN/consumables, 9 separated slots, full details, inspector, exact edition target, pages, canceled/locked/no-turn drops, click and drag reorder with one enemy turn")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+(step==1 and 1.2 or .4)
end
return T

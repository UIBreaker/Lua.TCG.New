local T={};local step,deadline=0,0
local UI=require("src.ui")
local Shop=require("src.shop")
local L=require("src.loadout")
local function pointer(r)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    return (w-1280*s)/2+(r.x+r.w/2)*s,(h-720*s)/2+(r.y+r.h/2)*s
end
local function click(r,mouse)
    assert(r,"Missing backpack control");local x,y=pointer(r)
    love.mouse.setPosition(x,y);love.mousepressed(x,y,mouse or 1);love.mousereleased(x,y,mouse or 1)
end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function drag(from,to)
    local x,y=pointer(from);love.mouse.setPosition(x,y);love.mousepressed(x,y,1)
    local tx,ty=pointer(to);love.mouse.setPosition(tx,ty);love.mousemoved(tx,ty,tx-x,ty-y)
    love.mousereleased(tx,ty,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime()
    assert(love.timer.getTime()-T.started<35,"Backpack UI timed out at step "..step)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        require("tests.loadout_smoke")
        cb.startNewGame("red_deck");game.gold=1000;game.shopMode="medicine";cb.openShop()
        local shop=cb.getShopData();shop.items={Shop.healingItem(nil,"cons_accuracy")}
        assert(Shop.buyItem(shop,1,game) and #game.consumables==3 and #game.backpackConsumables==1)
        L.storeDeity(game,require("src.deities").CATALOG.spirit_fleet_wind)
        cb.startMonsterEncounter(1,false);game.monster.hp=10000;game.monster.maxHp=10000
        T.hands=game.handsRemaining;T.hp=game.playerHp;UI.Backpack.tab="consumable"
    elseif step==1 then click(button(cb,"open_backpack"));assert(UI.Backpack.open);shot("backpack_battle_consumables")
    elseif step==2 then
        assert(UI.Backpack.combat and #UI.Backpack.loadoutSlots==3 and #UI.Backpack.cells==1)
        love.keypressed("space");assert(game.handsRemaining==T.hands,"Viewing backpack blocks battle shortcuts")
        -- Invalid drop retains the card and does not spend a turn.
        drag(UI.Backpack.cells[1],{x=950,y=80,w=10,h=10})
        assert(game.handsRemaining==T.hands and #game.backpackConsumables==1)
        drag(UI.Backpack.cells[1],UI.Backpack.loadoutSlots[2])
        assert(not UI.Backpack.open and game.handsRemaining==T.hands-1)
        assert(L.equipped(game,"consumable",2).id=="cons_accuracy" and #game.backpackConsumables==1)
        assert(not UI.Backpack.transfer("spn","reserve",1,1),"Cannot change again while enemy acts")
    elseif step==3 then
        if not next(game.enemyActed or {}) then return end
        love.keypressed("i");if not UI.Backpack.open then return end
    elseif step==4 then
        click(button(cb,"bag_tab_spn"));assert(not game.deities[1] and #game.backpackDeities==1)
        shot("backpack_battle_spn")
    elseif step==5 then
        drag(UI.Backpack.cells[1],UI.Backpack.loadoutSlots[1])
        assert(game.handsRemaining==T.hands-2 and game.deities[1].id=="spirit_fleet_wind" and #game.backpackDeities==0)
        T.hp=game.playerHp
    elseif step==6 then
        if not next(game.enemyActed or {}) then return end
        love.keypressed("i");if not UI.Backpack.open then return end
    elseif step==7 then
        drag(UI.Backpack.loadoutSlots[1],{x=400,y=350,w=20,h=20})
        assert(game.handsRemaining==T.hands-3 and not game.deities[1] and #game.backpackDeities==1)
        T.hp=game.playerHp
    elseif step==8 then
        if not next(game.enemyActed or {}) then return end
        love.keypressed("i");if not UI.Backpack.open then return end
    elseif step==9 then
        drag(UI.Backpack.cells[1],UI.Backpack.loadoutSlots[1])
        assert(game.handsRemaining==0 and #game.backpackDeities==1 and not game.deities[1] and UI.Backpack.open)
        love.keypressed("escape");assert(not UI.Backpack.open)
        game.shopMode="spn";cb.openShop();T.hands=game.handsRemaining
        UI.Backpack.show();UI.Backpack.tab="spn"
    elseif step==10 then
        drag(UI.Backpack.cells[1],UI.Backpack.loadoutSlots[1])
        assert(UI.Backpack.open and game.deities[1] and game.handsRemaining==T.hands,"Shop arrangement is free")
        local loaded=require("src.persistence").restoreSnapshot(require("src.persistence").makeSnapshot(game,"shop"))
        assert(loaded.deities[1].id==game.deities[1].id and #loaded.backpackConsumables==1)
        UI.Backpack.close();cb.startMonsterEncounter(2,false);game.playerHp=50
        UI.Backpack.show();UI.Backpack.tab="consumable";T.hands=game.handsRemaining
    elseif step==11 then
        click(UI.Backpack.cells[1],2)
        assert(game.playerHp==50 and #game.consumables==3 and #game.backpackConsumables==1,"Reserved items can only be inspected")
        love.keypressed("escape");assert(UI.Backpack.open)
        click(UI.Backpack.loadoutSlots[1],2)
        assert(game.playerHp==75 and #game.consumables==2 and UI.Backpack.open and game.handsRemaining==T.hands,"Equipped potion uses its ordinary effect and returns to backpack")
    elseif step==12 then
        love.keypressed("i");assert(not UI.Backpack.open)
        local x,y=UI.getConsumableSlotRect(2,"playing")
        local expectedX,expectedY=UI.InventoryRail.rect("consumable",3,game)
        assert(x==expectedX and y==expectedY,"Consuming a potion must preserve the other equipped slots")
        print("Battle backpack UI PASS: live open/close, reserve + equipped rows, drag/replace/return, invalid drop free, 1 hand per change, enemy reaction, input lock, no-turn guard, free shop setup, real equipped-only use, stable potion slots, save retention")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+(step==1 and 1.6 or .6)
end
return T

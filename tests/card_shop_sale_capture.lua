local T={};local step,deadline=0,0
local UI=require("src.ui")
local Shop=require("src.shop")
local Deck=require("src.deck")
local function click(r,mouse)
    assert(r,"Missing sale control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(r.x+r.w/2)*s,(h-720*s)/2+(r.y+r.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,mouse or 1);love.mousereleased(x,y,mouse or 1)
end
function T.update(game,cb)
    if love.timer.getTime()<deadline or UI.Polish.busy() then return end
    if step==0 then
        require("tests.card_shop_smoke")
        cb.startNewGame("red_deck");game.shopMode="cards";game.gold=10
        local a,b,c=Deck.newCard(13,"valoria"),Deck.newCard(7,"elaris"),Deck.newCard(2,"aurelia")
        a.evolutionLevel=2;a.equipments={require("src.equipment").ITEMS.basic_feather}
        require("src.card_effects").setEffect(a,"ancient")
        game.persistentDeck={a,b,c};game.masterDeck=game.persistentDeck
        game.hand={Deck.cloneCard(a)};game.deck={Deck.cloneCard(a)};game.discardPile={Deck.cloneCard(a)}
        T.price=Shop.getCardSellPrice(a);cb.openShop()
        UI.Backpack.show();UI.Backpack.tab="cards"
    elseif step==1 then
        click(UI.Backpack.cellRect(1))
        assert(UI.Polish.focus.kind=="card_sale" and game.gold==10 and #game.persistentDeck==3)
    elseif step==2 then
        love.mouse.setPosition(2,2)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/card_shop_sale.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
    elseif step==3 then
        click({x=300,y=641,w=10,h=10},2)
        assert(not UI.Polish.focus and #game.persistentDeck==3 and game.gold==10,"Cancel must retain card and money")
        click(UI.Backpack.cellRect(1));click(UI.Polish.button(game))
        assert(game.gold==10+T.price and #game.persistentDeck==2)
        assert(#game.hand==0 and #game.deck==0 and #game.discardPile==0)
        assert(UI.Polish.job.kind=="sell" and not UI.Polish.job.soul and UI.Polish.job.delta==T.price)
    elseif step==4 then
        assert(not UI.Backpack.selected)
        UI.Backpack.close();cb.openDeckViewer()
    elseif step==5 then
        click({x=74,y=163,w=74,h=108});assert(UI.Polish.focus.kind=="card_sale")
        click(UI.Polish.button(game));assert(#game.persistentDeck==1 and game.gold==12+T.price)
    elseif step==6 then
        -- Selling leaves the viewer open for the next selection.
        click({x=74,y=163,w=74,h=108});assert(UI.Polish.button(game).disabled)
        click(UI.Polish.button(game));assert(#game.persistentDeck==1 and game.gold==12+T.price)
        cb.closeDeckViewer()
        T.modes={"small","consumable","equipment","spn","medicine","large","soul"}
    else
        local mode=T.modes[step-6]
        if not mode then
            local loaded,state=require("src.persistence").restoreSnapshot(require("src.persistence").makeSnapshot(game,"shop"))
            assert(state=="shop" and #loaded.persistentDeck==1 and loaded.gold==game.gold)
            print("Card resale UI PASS: hidden owned-card action, backpack + deck viewer, cancel/confirm, gold VFX, last-card guard, 7 other shops blocked, save retention")
            love.event.quit(0);return
        end
        game.shopMode=mode;cb.openShop();UI.Backpack.show();UI.Backpack.tab="cards"
        -- Draw the newly opened backpack before testing its real hitbox.
        T.pendingMode=mode
        T.updateMode=true
    end
    step=step+1;deadline=love.timer.getTime()+.4
end
local update=T.update
function T.update(game,cb)
    if T.updateMode and love.timer.getTime()>=deadline then
        T.updateMode=nil
        click(UI.Backpack.cellRect(1));assert(not UI.Polish.focus,"No sale action in "..T.pendingMode)
        UI.Polish.focusItem(game.persistentDeck[1],"card_sale",1,UI.Backpack.cellRect(1))
        assert(not UI.Polish.button(game) and not UI.Polish.confirm(cb.getShopData(),game))
        assert(not Shop.sellCard(game,game.persistentDeck[1]) and #game.persistentDeck==1)
    end
    update(game,cb)
end
return T

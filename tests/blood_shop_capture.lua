local T={};local step,deadline=0,0
local Shop=require("src.shop")
local UI=require("src.ui")
local Blood=require("src.blood_shop")
local function checkInterior(mode)
    local scene=require("render.scene")
    local path="assets/scene/shops/"..mode..".png"
    assert(require("config.shop_visuals").profiles[mode].background==path)
    assert(scene.definition.backgroundPath==path and scene.definition.base=="shop_"..mode)
    local art=assert(scene.art[scene.definition.base],"Missing dedicated blood shop background")
    local w,h=art:getDimensions();assert(w>=1536 and w/h>1.7 and w/h<1.9)
end
local function click(r)
    assert(r,"Missing blood shop control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(r.x+r.w/2)*s,(h-720*s)/2+(r.y+r.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function shot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/shop_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime()
    assert(love.timer.getTime()-T.started<40,"blood shop timeout at "..step)
    if love.timer.getTime()<deadline or UI.Polish.busy() then return end
    if step==0 then
        require("tests.blood_shop_smoke")
        cb.startNewGame("red_deck");game.playerHp=1500;game.maxPlayerHp=1500;game.gold=0;game.souls=0
        game.shopMode="blood_small";cb.openShop()
    elseif step==1 then
        local count=0;for _,b in ipairs(cb.getButtons()) do if b.stockItem then count=count+1 end end
        assert(count==8 and cb.getShopData().bloodMode)
        checkInterior("blood_small")
        T.item=cb.getShopData().items[1];T.hp=game.playerHp;shot("blood_small")
    elseif step==2 then click(button(cb,"buy_1"));assert(UI.Polish.focus.item==T.item)
    elseif step==3 then
        local confirm=UI.Polish.button(game);assert(not confirm.disabled and confirm.text:find("HP",1,true),"HP purchases must work with zero gold")
        click(confirm)
    elseif step==4 then
        assert(game.playerHp==T.hp-T.item.cost and game.gold==0 and #game.backpackDeities==1 and game.backpackDeities[1].bloodPower==5)
        T.hp=game.playerHp;T.cost=Shop.getRerollCost(cb.getShopData(),game);click(button(cb,"reroll"))
    elseif step==5 then
        assert(game.playerHp==T.hp-T.cost and game.gold==0 and #cb.getShopData().items==8)
        game.shopMode="blood_large";cb.openShop()
        UI.Polish.message=nil
    elseif step==6 then
        assert(#cb.getShopData().items==16);checkInterior("blood_large");shot("blood_large")
        step=6.1;deadline=love.timer.getTime()+.65;return
    elseif step==6.1 then
        click(button(cb,"blood_page_2"));shot("blood_large_page2")
        step=7;deadline=love.timer.getTime()+.65;return
    elseif step==7 then
        local count=0;for _,b in ipairs(cb.getButtons()) do if b.stockItem then count=count+1;assert(b.stockItem.bay>=9) end end
        assert(count==8 and cb.getShopData().page==2)
        game.playerHp=Shop.getRerollCost(cb.getShopData(),game)
    elseif step==8 then
        assert(button(cb,"reroll").disabled)
        T.hp=game.playerHp;T.item=cb.getShopData().items[9]
        game.playerHp=T.item.cost;click(button(cb,"buy_9"))
    elseif step==9 then
        assert(UI.Polish.button(game).disabled and UI.Polish.button(game).text:find("MÁU",1,true))
        assert(not UI.Polish.confirm(cb.getShopData(),game) and game.playerHp==T.item.cost and #cb.getShopData().items==16)
        UI.Polish.clearFocus();game.playerHp=500
        game.run.ante=3;game.run.currentBlindIndex=3
        local random=require("src.rng").random;require("src.rng").random=function() return .99 end
        assert(not Blood.roll(game) and game.maxPlayerHp==1503 and game.playerHp==500)
        require("src.rng").random=random
        game.shopMode="consumable";cb.openShop()
    elseif step==10 then shot("blood_miss_bonus")
    elseif step==11 then
        print("Blood shop UI PASS: both sizes and real interiors, HP labels/confirmation, buy/reroll with zero gold, 16-item pagination, insufficient-HP guards, max-HP miss notice")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+(step==1 and 1.4 or step==6 and 2 or step==10 and 3 or .65)
end
return T

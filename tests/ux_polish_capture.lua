-- lovec.exe . --test-ux-polish : real input, graphics/shader and timed shop flow; no player saves.
local UI=require("src.ui")
local P=UI.Polish
local Shop=require("src.shop")
local Deck=require("src.deck")
local Test={};local stage="start";local deadline=0
local shop,item,index,before,size,old,swap
local tooltipBody, tooltipCount, lastTooltipCount
local function watchTooltip()
    local view=require("ui.components.card_description")
    local render,draw=view.draw,love.draw
    view.draw=function(...)
        if tooltipBody then tooltipCount=tooltipCount+1 end
        return render(...)
    end
    love.draw=function(...)
        tooltipCount=0;draw(...);lastTooltipCount=tooltipCount
        assert(tooltipCount<=1,"no duplicate descriptions")
    end
end
local function pointer(x,y,click)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if click then love.mousepressed(px,py,1);love.mousereleased(px,py,1) end
end
local function nextStage(name,delay) stage=name;deadline=love.timer.getTime()+(delay or 0.15) end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(name,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function findCard()
    for i,v in ipairs(shop.items) do if v.card then index,item=i,v;return end end
    error("no card stock")
end
local function confirm(game)
    local b=assert(P.button(game));pointer(b.x+b.w/2,b.y+b.h/2,true)
end
local function dissolveCheck()
    local g=love.graphics;local c=g.newCanvas(80,120)
    local newCanvas,newShader=g.newCanvas,g.newShader
    local canvases,shaders=0,0
    g.newCanvas=function(...) canvases=canvases+1;return newCanvas(...) end
    g.newShader=function(...) shaders=shaders+1;return newShader(...) end
    local function draw(amount)
        g.push("all");g.setCanvas(c);g.origin();g.clear(0,0,0,0)
        P.dissolve(UI,0,0,80,120,amount,{1,0.8,0.3},function(x,y,w,h)
            g.setColor(0.7,0.8,1,1);g.rectangle("fill",x+10,y+10,w-20,h-20)
        end)
        g.pop();return c:newImageData()
    end
    local whole,partial,gone=draw(0),draw(0.55),draw(1)
    local function alpha(data) local total=0;for y=0,119 do for x=0,79 do local _,_,_,a=data:getPixel(x,y);total=total+a end end;return total end
    assert(alpha(whole)>alpha(partial) and alpha(partial)>0 and alpha(gone)==0,"organic dissolve coverage")
    for _,data in ipairs({whole,partial,gone}) do local r,gg,b,a=data:getPixel(0,0);assert(a==0 and r==0 and gg==0 and b==0,"transparent border") end
    for _,count in ipairs({5,10,20}) do for i=1,count do draw(0.35) end end
    assert(P.load() and canvases<=1 and shaders<=1,"one reused Canvas and shader, not per card/frame")
    g.newCanvas,g.newShader=newCanvas,newShader
    package.loaded["src.ux_polish"]=nil
    local fallback=require("src.ux_polish");package.loaded["src.ux_polish"]=P
    g.newShader=function() error("intentional shader failure test") end
    g.push("all");g.setCanvas(c);g.origin();g.clear()
    fallback.dissolve(UI,0,0,80,120,0.5,nil,function(x,y,w,h) g.setColor(1,1,1,1);g.rectangle("fill",x+20,y+20,w-40,h-40) end)
    g.pop();g.newShader=newShader
    local faded=c:newImageData();local _,_,_,a=faded:getPixel(40,60);assert(a>0.45 and a<0.55,"shader error must fall back to a faded normal card")
    print("[PASS] dissolve: compile/coverage/alpha, reuse at 5/10/20 cards, GPU fallback")
end
function Test.update(game,callbacks)
    if love.timer.getTime()<deadline then return end
    if stage=="start" then
        watchTooltip()
        require("tests.spectral_persistence_smoke")
        callbacks.startNewGame("red_deck");game.gold=100;game.playerHp=60
        callbacks.openShop();shop=callbacks.getShopData();P.ensureShop(shop)
        dissolveCheck();pointer(2,2);nextStage("arrival",0.55)
    elseif stage=="arrival" then
        shot("shot_ux_shop.png");findCard();before=game.gold;size=#game.persistentDeck
        tooltipBody=select(2,UI.Description.resolve(item,game));pointer(498,225)
        nextStage("hover_early",0.08)
    elseif stage=="hover_early" then
        assert(lastTooltipCount==0,"tooltip must not appear on a mouse fly-by")
        nextStage("hover_ready",0.26)
    elseif stage=="hover_ready" then
        assert(lastTooltipCount==1,"one delayed tooltip after stable hover")
        tooltipBody=nil
        pointer(498,225,true);assert(P.focus and game.gold==before,"click focuses without purchase")
        nextStage("focus",0.22)
    elseif stage=="focus" then
        shot("shot_ux_focus.png");nextStage("focus_confirm",0.15)
    elseif stage=="focus_confirm" then
        love.keypressed("escape");assert(not P.focus)
        pointer(498,225,true);game.gold=0;assert(P.button(game).disabled);confirm(game)
        assert(not P.busy() and #game.persistentDeck==size,"poor buy rejected")
        game.gold=before;pointer(498,225,true);confirm(game)
        assert(P.busy() and game.gold==before-item.cost and #game.persistentDeck==size+1)
        pointer(282,674,true);love.keypressed("escape")
        assert(P.job.kind=="buy","transaction blocks spam and Escape")
        nextStage("purchase",0.17)
    elseif stage=="purchase" then shot("shot_ux_purchase.png");nextStage("bought",0.48)
    elseif stage=="bought" then
        assert(not P.busy());callbacks.openDeckViewer();nextStage("sell_focus")
    elseif stage=="sell_focus" then
        local acquired=game.persistentDeck[#game.persistentDeck]
        local r=assert(UI.CardPhysics.getState(acquired),"owned card renderer")
        pointer(r.x+r.w/2,r.y+r.h/2,true)
        assert(P.focus and P.focus.kind=="card","inventory click focuses sale")
        before=game.gold;confirm(game);assert(P.job.kind=="sell" and game.gold>before)
        nextStage("selling",0.14)
    elseif stage=="selling" then shot("shot_ux_sell.png");nextStage("sold",0.50)
    elseif stage=="sold" then
        assert(not P.busy() and #game.persistentDeck==size);callbacks.closeDeckViewer()
        nextStage("reroll",0.15)
    elseif stage=="reroll" then
        old=shop.items;before=game.gold
        pointer(282,674,true)
        assert(P.job.kind=="flip" and shop.items==old)
        swap=P.job.swapAt;pointer(498,225,true);pointer(282,674,true)
        assert(shop.items==old and not P.focus,"flip locks focus and reroll")
        nextStage("backs",swap-0.035)
    elseif stage=="backs" then
        assert(not P.job.swapped and shop.items==old,"all backs before swap")
        shot("shot_ux_backs.png");nextStage("revealed",0.58)
    elseif stage=="revealed" then
        assert(not P.busy() and shop.items~=old);shot("shot_ux_reveal.png")
        findCard();pointer(498,225,true);assert(P.focus and P.focus.item==item)
        callbacks.setScoringSpeed(true);before=game.gold;confirm(game)
        assert(game.gold==before-item.cost);nextStage("fast",0.34)
    elseif stage=="fast" then
        assert(not P.busy() and #game.persistentDeck==size+1)
        print("[PASS] SHOP OPEN → FOCUS → BUY → SELL → REROLL → BUY; poor funds, cancel, spam, Fast, real input/render")
        love.event.quit(0)
    end
end
return Test

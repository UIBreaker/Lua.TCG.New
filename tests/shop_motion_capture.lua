local UI=require("src.ui")
local P=UI.Polish
local T={}
local stage,mode,started,frame,nextFrame=0,1,0,0,0
local modes={"small","large","soul","medicine","blood_large"}
local stock,balance,item,price
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function click(b)
    assert(b,"missing control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function shot(path)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    assert(love.timer.getTime()-started<35 or stage==0,"shop motion timeout at "..stage)
    if stage==0 then
        require("tests.shop_motion_smoke")
        local update=love.update
        love.update=function(dt) update(math.min(dt,1/30)) end -- Keep capture samples on the animation timeline during cold asset loads.
        cb.setScoringSpeed(false)
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.gold=10000;game.souls=10000
        T.enterAt=P.time+1.5
        love.mouse.setPosition(2,2);started=love.timer.getTime();stage=1
    elseif stage==1 and P.time>=T.enterAt then
        game.shopMode=modes[mode]
        if mode>1 then game.gold=10000;game.souls=10000;game.playerHp=100000 end
        cb.openShop();stock=cb.getShopData();P.ensureShop(stock)
        stage=2;started=love.timer.getTime();nextFrame=0;frame=0
    elseif stage==2 then
        if mode==1 and P.age>=nextFrame and frame<24 then
            shot(string.format(".tmp/animation-reference/game_%03d.png",frame))
            frame=frame+1;nextFrame=nextFrame+0.04
        end
        local b=button(cb,"buy_1")
        if b and P.age<0.55 then
            assert(b.disabled,"moving stock must reject logical hitboxes")
            click(b);assert(not P.focus,"moving stock must not acquire focus")
            love.mouse.setPosition(2,2)
            assert(not UI.CardPhysics.getState(b.stockItem),"moving stock must not register for dragging")
        end
        if P.age>1.2 then
            shot(".tmp/animation-reference/"..modes[mode].."_settled.png")
            b=assert(button(cb,"buy_1"));assert(not b.disabled)
            if stock.soulMode then
                for _,offer in ipairs(cb.getButtons()) do
                    if offer.stockItem and offer.stockItem.consumable then b=offer;break end
                end
            end
            item=b.stockItem;price=item.cost
            balance=item.currency=="blood" and game.playerHp or item.currency=="souls" and game.souls or game.gold
            click(b);assert(P.focus and P.focus.item==item,"settled stock focuses")
            click(assert(P.button(game)));assert(P.busy(),"purchase animates")
            stage=3
        end
    elseif stage==3 and not P.busy() then
        local after=item.currency=="blood" and game.playerHp or item.currency=="souls" and game.souls or game.gold
        assert(after==balance-price,"purchase charges exactly once")
        stage=31 -- Wait for the next draw to replace the transaction's disabled buttons.
    elseif stage==31 then
        local old=stock.items
        click(assert(button(cb,"reroll")));assert(P.job and P.job.kind=="flip" and stock.items==old)
        T.old=old;stage=4
    elseif stage==4 and not P.busy() then
        assert(stock.items~=T.old,"reroll swaps stock")
        print("Shop motion runtime PASS: "..modes[mode].." arrival/input/buy/reroll")
        mode=mode+1
        if mode>#modes then love.event.quit(0);return end
        stage=1;started=love.timer.getTime()-1
        T.enterAt=P.time+0.15
    end
end
return T

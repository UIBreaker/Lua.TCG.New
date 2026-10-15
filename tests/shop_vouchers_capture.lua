local T={}
local Shop=require("src.shop")
local UI=require("src.ui")
local step,deadline=0,0
local function click(button)
    assert(button,"Missing voucher button")
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local x,y=(w-1280*scale)/2+(button.x+button.w/2)*scale,(h-720*scale)/2+(button.y+button.h/2)*scale
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function screenshot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/vouchers_"..name..".png","wb"));file:write(data:encode("png"):getString());file:close()
    end)
end
local function offer(game,cb)
    local shop=cb.getShopData()
    for i,item in ipairs(shop.items) do if item.category=="voucher" then
        local v=Shop.voucherOffer(Shop.VOUCHERS[3],game)
        v.section=item.section;v.cost=v.cost*Shop.PRICE_MULTIPLIER
        shop.items[i]=v;T.index=i;T.offer=v;return
    end end
    error("All-owned shop must still contain a voucher")
end
function T.update(game,cb)
    if love.timer.getTime()<deadline or UI.Polish.busy() then return end
    if step==0 then
        cb.startNewGame("red_deck");game.gold=10000;game.shopMode="large"
        for _,v in ipairs(Shop.VOUCHERS) do
            local grant=Shop.new();grant.items={Shop.voucherOffer(v,game)};grant.items[1].cost=0
            assert(Shop.buyItem(grant,1,game))
        end
        cb.openShop();offer(game,cb)
    elseif step==1 then
        assert(T.offer.voucherLevel==2);screenshot("shop_level_2")
        for _,b in ipairs(cb.getButtons()) do if b.id=="buy_"..T.index then click(b);break end end
    elseif step==2 then
        assert(UI.Polish.focus and UI.Polish.focus.item==T.offer)
        screenshot("upgrade_preview");T.gold=game.gold
    elseif step==3 then click(assert(UI.Polish.button(game)))
    elseif step==4 then
        assert(Shop.voucherLevel("v_hand_plus",game)==2 and game.maxHands==5 and game.gold==T.gold-T.offer.cost)
        cb.openShop();offer(game,cb);assert(T.offer.voucherLevel==3)
        cb.openInspector(T.offer)
    elseif step==5 then screenshot("level_3_inspector")
    elseif step==6 then cb.closeInspector();cb.openCollection("vouchers")
    elseif step==7 then screenshot("collection_level_2")
    elseif step==8 then
        cb.closeCollection()
        local config=require("config.reward_loot");config.tables.voucher_capture={rolls={0,0},entries={}}
        cb.openReward("voucher_capture");require("src.reward_system").finishImmediately(cb.getRewardAnimation())
    elseif step==9 then screenshot("victory_income")
    elseif step==10 then
        print("Voucher UI PASS: all-owned shop, level 2 purchase through real buttons, cumulative level 3 preview, owned collection and victory income")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+1
end
return T

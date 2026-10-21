local T={};local step,deadline=0,0
local UI=require("src.ui")
local Shop=require("src.shop")
local Reward=require("src.reward_system")
local Run=require("src.run_manager")
local stallSteps=#Shop.AFTER_COMBAT_MARKETS*5
local function click(button)
    assert(button,"Missing shop button")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(button.x+button.w/2)*s,(h-720*s)/2+(button.y+button.h/2)*s
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
    if love.timer.getTime()<deadline or UI.Polish.busy() then return end
    if step==0 then
        require("tests.shop_markets_smoke")
        require("tests.card_shop_smoke")
        cb.startNewGame("red_deck");game.gold=10000;game.souls=500
        require("config.reward_loot").tables.market_test={rolls={0,0},entries={}}
    elseif step<=stallSteps then
        local mode=Shop.AFTER_COMBAT_MARKETS[math.ceil(step/5)]
        local phase=(step-1)%5
        if phase==0 then
            game.shopMode=mode;game.consumables={};game.deities={};game.backpackConsumables={};game.backpackDeities={};UI.Polish.clearFocus();cb.openShop()
            if mode=="small" then
                game.run.stats.blindsWon=1;game.run.stats.starterGearPurchased=nil;cb.openShop()
                assert(cb.getShopData().items[2].starterOffer,"first small shop includes starter gear in the equipment bay")
            end
            assert(cb.getShopData().mode==mode)
            if mode=="cards" then
                local card=cb.getShopData().items[1].card
                card.evolutionLevel=2
                local eq=require("src.equipment").ITEMS.basic_feather
                local copy={};for k,v in pairs(eq) do copy[k]=v end
                card.equipments={copy};require("src.card_effects").setEffect(card,"ancient")
                local offer=Shop.playingCardOffer(card);offer.section="stall";offer.bay=1
                cb.getShopData().items[1]=offer
            end
        elseif phase==1 then
            local profile=require("config.shop_visuals").profiles[mode]
            local scene=require("render.scene")
            assert(scene.definition.backgroundPath==profile.background and scene.art[scene.definition.base],"Shop must show its loaded interior instead of the battlefield")
            local count=0
            T.rects={}
            for _,b in ipairs(cb.getButtons()) do
                if b.stockItem then
                    count=count+1
                    assert(b.x>=292 and b.x+b.w<=1262 and b.y>=130 and b.y+b.h<=640)
                    T.rects[b.stockItem]={x=b.x,y=b.y}
                    if mode=="medicine" then
                        local c=b.stockItem.category
                        assert((b.y<360)==(c=="heal" or c=="bed"),"Medicine shop groups HP/bed above armor/speed")
                    end
                end
            end
            assert(count==(mode=="medicine" and 7 or #cb.getShopData().items),"Every offer in this cabinet needs a visible hitbox")
            shot(mode)
        elseif phase==2 then
            T.item=cb.getShopData().items[1];T.gold=game.gold;T.count=#cb.getShopData().items
            click(button(cb,"buy_1"));assert(UI.Polish.focus and UI.Polish.focus.item==T.item)
        elseif phase==3 then click(UI.Polish.button(game))
        else
            assert(game.gold==T.gold-T.item.cost and #cb.getShopData().items==T.count-1)
            for _,b in ipairs(cb.getButtons()) do if b.stockItem and b.stockItem~=T.item then
                local previous=assert(T.rects[b.stockItem])
                assert(b.x==previous.x and b.y==previous.y,"Buying one item must not move other display stands")
            end end
            if T.item.consumable then assert(game.backpackConsumables[1].id==T.item.id and #game.consumables==0)
            elseif T.item.deity then assert(game.backpackDeities[1].id==T.item.deity.id and not game.deities[1])
            elseif T.item.equipment then assert(game.backpackEquipment[#game.backpackEquipment].id==T.item.equipment.id) end
            if T.item.card then
                local bought=game.persistentDeck[#game.persistentDeck]
                assert(bought==T.item.card and bought.evolutionLevel==2 and bought.edition=="ancient")
                assert(#bought.equipments==1 and bought.equipments[1].id=="basic_feather" and bought.equipments[1].basic)
            end
        end
    elseif step==stallSteps+1 then
        game.deities={};game.consumables={};game.run.currentBlindIndex=3
        cb.openReward("market_test")
        local animation=cb.getRewardAnimation();Reward.finishImmediately(animation)
        assert(game.pendingSoulShop)
    elseif step==stallSteps+2 then click(button(cb,"cashout_continue"))
    elseif step==stallSteps+3 then
        local _,state=cb.getRunState();assert(state=="shop" and game.shopMode=="soul")
        T.ante=game.run.ante;T.index=game.run.currentBlindIndex;T.gold=game.gold;T.souls=game.souls
        shot("soul_before_large")
    elseif step==stallSteps+4 then click(button(cb,"leave_shop"))
    elseif step==stallSteps+5 then
        local _,state=cb.getRunState();assert(state=="shop" and game.shopMode=="large" and cb.getShopData().mode=="large")
        assert(game.run.ante==T.ante and game.run.currentBlindIndex==T.index and game.gold==T.gold and game.souls==T.souls)
        shot("large_after_soul")
    elseif step==stallSteps+6 then click(button(cb,"leave_shop"))
    elseif step==stallSteps+7 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and game.run.ante==T.ante+1)
        cb.openReward("market_test");local animation=cb.getRewardAnimation();Reward.finishImmediately(animation)
    elseif step==stallSteps+8 then love.keypressed("return")
    elseif step==stallSteps+9 then
        local _,state=cb.getRunState();assert(state=="shop" and not cb.getShopData().soulMode and game.shopMode~="large")
        T.mode=game.shopMode;T.gold=game.gold;T.rerollCost=Shop.getRerollCost(cb.getShopData(),game);click(button(cb,"reroll"))
    elseif step==stallSteps+10 then
        assert(game.shopMode==T.mode and cb.getShopData().mode==T.mode and game.gold==T.gold-T.rerollCost)
        click(button(cb,"leave_shop"))
    elseif step==stallSteps+11 then
        local _,state=cb.getRunState();assert(state=="shop" and game.shopMode~="small" and not game.pendingCompanionShop)
        click(button(cb,"leave_shop"))
    elseif step==stallSteps+12 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT")
        print("Shop markets UI PASS: 6 interiors/purchases, boss soul -> large preserved, normal small -> companion -> next fight, reroll preserves type")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+.7
end
return T

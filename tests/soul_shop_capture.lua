local T={}
local stage,deadline="start",0
local UI=require("src.ui")
local Shop=require("src.shop")
local E=require("src.equipment")
local function pointer(x,y,click,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if click then love.mousepressed(px,py,button or 1);love.mousereleased(px,py,button or 1) end
end
local function nextStage(name,delay) stage=name;deadline=love.timer.getTime()+(delay or 0.3) end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function confirm(game)
    local b=assert(UI.Polish.button(game));pointer(b.x+b.w/2,b.y+b.h/2,true)
end
function T.update(g,cb)
    if love.timer.getTime()<deadline then return end
    if stage=="start" then
        require("tests.soul_shop_smoke")
        require("tests.spectral_persistence_smoke")
        cb.startNewGame("red_deck")
        require("src.deck").addCardToDeck(g,require("src.deck").newCard(9,"valoria"))
        require("src.deck").addCardToDeck(g,require("src.deck").newCard(7,"valoria"))
        local card=g.persistentDeck[1]
        card.equipments={E.ITEMS.void_catalyst};card.evolutionLevel=2;card.edition="polychrome"
        g.souls=0;g.gold=50;g.playerHp=40;cb.openShop()
        local stock=cb.getShopData()
        for i,item in ipairs(stock.items) do
            if item.category=="destroy" or item.category=="heal" then stock.items[i]=Shop.healingItem("upper");break end
        end
        nextStage("normal",1)
    elseif stage=="normal" then
        shot("soul_normal_shop")
        nextStage("buy_heal",0.25)
    elseif stage=="buy_heal" then
        pointer(870,220,true);confirm(g)
        assert(g.gold==46 and g.playerHp==40 and g.consumables[1].id=="healing_potion")
        nextStage("use_heal",1)
    elseif stage=="use_heal" then
        g.playerHp=100;pointer(1074,430,true,2)
        assert(g.playerHp==100 and #g.consumables==1)
        g.playerHp=40;pointer(1074,430,true,2)
        assert(g.playerHp==65 and #g.consumables==0)
        cb.getShopData().items[#cb.getShopData().items+1]=Shop.destructionItem("upper")
        nextStage("buy_destroy",0.7)
    elseif stage=="buy_destroy" then
        pointer(870,220,true);confirm(g)
        assert(g.gold==42 and #g.consumables==1 and not g.soulDestroyActive)
        nextStage("activate",1)
    elseif stage=="activate" then
        pointer(1074,430,true,2);nextStage("cancel")
    elseif stage=="cancel" then
        assert(g.soulDestroyActive)
        love.keypressed("escape")
        assert(not g.soulDestroyActive and #g.consumables==1)
        nextStage("reactivate",0.5)
    elseif stage=="reactivate" then
        pointer(1074,430,true,2);nextStage("choose")
    elseif stage=="choose" then
        assert(g.soulDestroyActive)
        pointer(111,210,true);pointer(800,540,false);nextStage("preview")
    elseif stage=="preview" then
        local f=assert(UI.Polish.focus);assert(f.kind=="card")
        shot("soul_destruction_preview")
        local n=#g.persistentDeck;local value=Shop.getSoulValue(f.item)
        nextStage("destroy",0.3)
    elseif stage=="destroy" then
        local f=assert(UI.Polish.focus)
        local n=#g.persistentDeck;local value=Shop.getSoulValue(f.item)
        confirm(g);assert(#g.persistentDeck==n-1 and g.souls==value,
            "destroy: n="..n.." after="..#g.persistentDeck.." souls="..g.souls.." expected="..value.." active="..tostring(g.soulDestroyActive).." message="..tostring(UI.Polish.message))
        assert(#g.consumables==0);nextStage("boss",1)
    elseif stage=="boss" then
        g.souls=150;g.run.currentBlindIndex=3
        cb.openReward("boss");nextStage("reward",1)
    elseif stage=="reward" then
        local anim=cb.getRewardAnimation();require("src.reward_system").finishImmediately(anim)
        g.pendingRoundRewardChoice=nil;nextStage("continue")
    elseif stage=="continue" then
        love.keypressed("return")
        assert(cb.getShopData().soulMode,"boss reward must enter soul shop")
        nextStage("clear_packs",1)
    elseif stage=="clear_packs" then
        if cb.getShopData().currentPackOpening then
            for _,b in ipairs(cb.getButtons()) do
                if b.id=="skip_pack" then pointer(b.x+b.w/2,b.y+b.h/2,true);break end
            end
            nextStage("clear_packs",0.7)
        else nextStage("soul",0.7) end
    elseif stage=="soul" then
        pointer(2,2,false);shot("soul_shop")
        nextStage("select_relic",0.25)
    elseif stage=="select_relic" then
        pointer(127,278,true);nextStage("focus")
    elseif stage=="focus" then
        assert(UI.Polish.focus.item.currency=="souls")
        local gold=g.gold;confirm(g);assert(g.souls==118 and g.gold==gold)
        nextStage("socket",1)
    elseif stage=="socket" then
        assert(select(2,cb.getRewardAnimation())=="socketing")
        local button
        for _,b in ipairs(cb.getButtons()) do if b.id=="skip_socket" then button=b end end
        assert(button);pointer(button.x+button.w/2,button.y+button.h/2,true)
        nextStage("bought",0.7)
    elseif stage=="bought" then
        assert(cb.getShopData().soulMode and g.soulShopPurchased.soul_worldblade)
        pointer(2,2,false)
        shot("soul_shop_purchased")
        nextStage("buy_evolution",0.25)
    elseif stage=="buy_evolution" then
        pointer(91,531,true);confirm(g)
        assert(g.souls==106 and g.consumables[1].id=="cons_evolution")
        nextStage("buy_single",1)
    elseif stage=="buy_single" then
        pointer(341,531,true);confirm(g)
        assert(g.souls==100 and g.consumables[2].id=="cons_speed_single")
        nextStage("buy_team",1)
    elseif stage=="buy_team" then
        pointer(591,531,true);confirm(g)
        assert(g.souls==90 and g.consumables[3].id=="cons_speed_team")
        nextStage("exit",1)
    elseif stage=="exit" then
        pointer(108,674,true);assert(g.shopMode=="normal")
        cb.startMonsterEncounter(1,false)
        nextStage("battle_hud",1)
    elseif stage=="battle_hud" then
        assert(g.souls==90)
        shot("soul_battle_hud")
        print("Soul shop live UI passed: normal slot, preview, destruction, boss transition, soul purchase, socket return, exit")
        nextStage("done",0.3)
    elseif stage=="done" then love.event.quit(0) end
end
return T

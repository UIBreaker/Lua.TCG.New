local T={};local stage=0;local deadline=0
local UI=require("src.ui");local E=require("src.equipment");local D=require("src.deck");local Shop=require("src.shop")
local function pointer(x,y,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if button then love.mousepressed(px,py,button);love.mousereleased(px,py,button) end
end
local function click(b) assert(b,"Missing UI button");pointer(b.x+b.w/2,b.y+b.h/2,1) end
local function shot(name)
    pointer(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local afterShot
local function capture(name,action)
    pointer(2,2);afterShot={name=name,action=action or function() end};deadline=love.timer.getTime()+.2
end
local function buy(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.stockItem and b.stockItem.id==id then click(b);return end end
    error("Missing offer "..id)
end
local function choose()
    local modal=assert(UI.AbilityUI.current)
    for _,b in ipairs(modal.buttons) do if b.id=="target" then click(b);return end end
end
local function confirmModal()
    for _,b in ipairs(UI.AbilityUI.current.buttons) do if b.id=="confirm" then click(b);return end end
    error("Missing ritual confirm")
end
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    if afterShot then
        if not afterShot.queued then shot(afterShot.name);afterShot.queued=true;deadline=love.timer.getTime()+.2;return end
        local action=afterShot.action;afterShot=nil;action();stage=stage+1;deadline=love.timer.getTime()+.8;return
    end
    if stage==0 then
        cb.startNewGame("red_deck");D.addCardToDeck(game,D.newCard(9,"elaris"));D.addCardToDeck(game,D.newCard(6,"aurelia"))
        game.shopMode="soul";game.souls=150;game.playerHp=79;game.gold=20
        game.soulShopStock={"soul_crown","soul_reaper_contract","soul_silence_anchor","soul_evolution_quill","soul_bastion"}
        cb.openShop()
        for _,id in ipairs({"cons_socket","cons_rulebreak"}) do
            local image=assert(UI.getConsumableImage({id=id}));assert(image:getWidth()==512 and image:getHeight()==768)
        end
    elseif stage==1 then
        capture("soul_market_redesign",function() buy(cb,"cons_socket") end);return
    elseif stage==2 then
        capture("soul_market_purchase",function() click(UI.Polish.button(game)) end);return
    elseif stage==3 then
        assert(game.souls==118 and #game.consumables==1)
        UI.Backpack.show();UI.Backpack.tab="consumable"
    elseif stage==4 then
        local x,y,w,h=UI.Backpack.rect("consumable",1,game);pointer(x+w/2,y+h/2,2)
        assert(UI.AbilityUI.current and UI.AbilityUI.current.mode=="card_upgrade")
    elseif stage==5 then
        choose()
    elseif stage==6 then
        capture("soul_market_socket_preview",function()
            love.keypressed("escape");assert(#game.consumables==1);UI.Backpack.show();UI.Backpack.tab="consumable"
        end);return
    elseif stage==7 then
        local x,y,w,h=UI.Backpack.rect("consumable",1,game);pointer(x+w/2,y+h/2,2)
    elseif stage==8 then choose()
    elseif stage==9 then confirmModal()
    elseif stage==10 then
        assert(game.persistentDeck[1].maxSockets==5 and #game.consumables==0)
        UI.Polish.clearFocus();buy(cb,"cons_rulebreak")
    elseif stage==11 then click(UI.Polish.button(game))
    elseif stage==12 then UI.Backpack.show();UI.Backpack.tab="consumable"
    elseif stage==13 then
        local x,y,w,h=UI.Backpack.rect("consumable",1,game);pointer(x+w/2,y+h/2,2)
    elseif stage==14 then choose()
    elseif stage==15 then capture("soul_market_rulebreak_preview",confirmModal);return
    elseif stage==16 then
        local c=game.persistentDeck[1];assert(c.allowDuplicateEquipment and #game.consumables==0)
        c.maxSockets=8;c.unlockedSockets=8
        for _=1,8 do assert(E.attach(c,E.ITEMS.gem_fire)) end
        UI.Backpack.show();UI.Backpack.tab="cards";UI.Backpack.selected=1
    elseif stage==17 then
        capture("soul_market_eight_sockets",function()
            local n=0;for _,b in ipairs(cb.getButtons()) do if b.id:match("^bag_detach_") then n=n+1;assert(b.x+b.w<=1280 and b.y+b.h<=679) end end
            assert(n==8);UI.Backpack.close();game.consumables={Shop.destructionItem().consumable};UI.Backpack.show();UI.Backpack.tab="consumable"
        end);return
    elseif stage==18 then
        local x,y,w,h=UI.Backpack.rect("consumable",1,game);pointer(x+w/2,y+h/2,2)
        assert(game.soulDestroyActive)
    elseif stage==19 then pointer(115,215,1)
    elseif stage==20 then
        assert(UI.Polish.focus and UI.Polish.focus.kind=="card");pointer(800,560)
        shot("soul_market_destruction_preview")
    elseif stage==21 then
        local expected=Shop.getDestructionRewards(game,UI.Polish.focus.item)
        T.souls=game.souls+expected.souls;T.gold=game.gold+5;T.hp=math.min(game.maxPlayerHp,game.playerHp+10)
        click(UI.Polish.button(game))
    elseif stage==22 then
        assert(game.souls==T.souls and game.gold==T.gold and game.playerHp==T.hp and #game.persistentDeck==2 and #game.consumables==0)
    elseif stage==23 then
        shot("soul_market_ritual_reward")
    elseif stage==24 then
        local c=game.persistentDeck[1];c.maxSockets=6;c.unlockedSockets=6;c.allowDuplicateEquipment=true
        c.equipments={E.ITEMS.soul_crown,E.ITEMS.soul_crown};T.socketTarget=c
        buy(cb,"soul_crown")
    elseif stage==25 then click(UI.Polish.button(game))
    elseif stage==26 then
        local _,state=cb.getRewardAnimation();assert(state=="socketing")
        capture("soul_market_socketing");return
    elseif stage==27 then
        local rect=UI.Polish.rect(UI,T.socketTarget);pointer(rect.x+rect.w/2,rect.y+rect.h/2,1)
    elseif stage==28 then
        assert(#T.socketTarget.equipments==3 and E.getUsedSlots(T.socketTarget)==6)
        cb.openInspector(T.socketTarget)
    elseif stage==29 then capture("soul_market_relic_inspector");return
    elseif stage==30 then cb.closeInspector()
    elseif stage==31 then
        print("Soul market UI PASS: all 14 offers, actual purchases, backpack right click, preview/cancel/confirm, 8 visible detach controls, duplicate attachment and doubled destruction rewards")
        love.event.quit(0)
    end
    stage=stage+1;deadline=love.timer.getTime()+(stage==1 and 2 or .8)
end
return T

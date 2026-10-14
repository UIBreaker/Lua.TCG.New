local T={step=0,prefix=tostring(os.time())}
local Run=require("src.run_manager")
local E=require("src.expedition")
local UI=require("src.ui")
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function click(b,mouse)
    assert(b,"Missing travel control at step "..T.step)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,mouse or 1);love.mousereleased(x,y,mouse or 1)
end
local function shot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/travel_"..T.prefix.."_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function boss(game,cb,id,ante)
    game.monster=nil;game.enemies=nil
    game.run.regionId=id;game.run.ante=ante;game.run.areaStage=20;game.run.currentBlindIndex=3
    game.run.regionStagesWon[id]=19
    game.run.blinds=Run.generateAnteBlinds(ante,"red_deck",id,20)
    cb.openReward("travel_test")
    -- The four-stage draft has its own regression; show the journey documents here.
    game.pendingRoundRewardChoice=nil
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime();assert(love.timer.getTime()-T.started<65,"Travel UI timeout at "..T.step)
    if love.timer.getTime()<(T.deadline or 0) then return end
    local s=T.step
    if s==0 then
        require("tests.journey_routing_smoke")
        require("tests.backpack_qol_smoke")
        cb.startNewGame("red_deck");game.gold=10000
        require("config.reward_loot").tables.travel_test={rolls={0,0},entries={}}
        boss(game,cb,"human",20)
        for _,id in ipairs(E.recognitionIds) do assert(UI.getConsumableImage(E.recognitionCard(id))) end
        assert(UI.getConsumableImage(E.travelPermit()))
    elseif s==1 then
        require("src.reward_system").finishImmediately(cb.getRewardAnimation());shot("permit_ceremony")
    elseif s==2 then Run.advanceBlind(game.run,game);cb.setCaptureState("victory")
    elseif s==3 then
        assert(button(cb,"travel_unknown").disabled);click(button(cb,"travel_unknown"))
        local _,state=cb.getRunState();assert(state=="victory" and game.run.ante==20);shot("locked")
    elseif s==4 then
        click(button(cb,"travel_hearts"));assert(game.run.ante==21 and game.run.areaStage==1)
    elseif s==5 then shot("stage_21");click(button(cb,"fight_blind"))
    elseif s==6 then assert(game.monster.stage==21);shot("battle_21")
    elseif s>=7 and s<=22 then
        local i=math.floor((s-7)/4)+1;local phase=(s-7)%4;local id=E.recognitionIds[i]
        if phase==0 then boss(game,cb,id,20+i*20)
        elseif phase==1 then
            require("src.reward_system").finishImmediately(cb.getRewardAnimation());shot("recognition_"..id)
            assert(E.recognitionCount(game)==i)
        elseif phase==2 then Run.advanceBlind(game.run,game);cb.setCaptureState("victory")
        elseif i<4 then click(button(cb,"travel_"..E.recognitionIds[i+1]))
        else assert(not button(cb,"travel_unknown").disabled);shot("unlocked") end
    elseif s==23 then click(button(cb,"travel_unknown"));assert(game.run.ante==101 and game.run.regionId=="unknown")
    elseif s==24 then shot("mysterious_101")
    elseif s==25 then game.shopMode="consumable";cb.openShop()
    elseif s==26 then
        assert(cb.getShopData().items[8].cost==2000);T.gold=game.gold;shot("shop");click(button(cb,"buy_8"))
    elseif s==27 then click(UI.Polish.button(game));T.step=28;T.deadline=love.timer.getTime()+3;return
    elseif s==28 then
        assert(game.gold==T.gold-2000 and game.backpackConsumables[#game.backpackConsumables].id=="cons_travel_permit")
        love.keypressed("i")
    elseif s==29 then click(button(cb,"bag_tab_consumable"))
    elseif s==30 then
        for _,c in ipairs(UI.Backpack.cells) do if c.item.id=="cons_travel_permit" then T.cell=c;click(c);break end end
        assert(T.cell)
    elseif s==31 then click(button(cb,"bag_use_permit"));local _,state=cb.getRunState();assert(state=="travel")
    elseif s==32 then shot("purchased_permit")
    elseif s==33 then
        click(button(cb,"travel_cancel"));local _,state=cb.getRunState();assert(state=="shop" and #game.backpackConsumables==1)
    elseif s==34 then love.keypressed("i")
    elseif s==35 then click(UI.Backpack.cells[1],2)
    elseif s==36 then click(button(cb,"travel_hearts"));assert(game.run.ante==101 and #game.backpackConsumables==0)
    elseif s==37 then shot("return_101")
    elseif s==38 then cb.openShop();UI.Backpack.show()
    elseif s==39 then click(button(cb,"bag_tab_journey"))
    elseif s==40 then assert(#UI.Backpack.list(game)==4);shot("recognition_bag")
    else print("Travel UI PASS: stage 20 -> 21 HUD, five card assets, four certificates in ceremony/bag, locked/unlocked unknown, real 2000-gold shop purchase, reserve use, cancel and consume; capture prefix "..T.prefix);love.event.quit(0);return end
    T.step=s+1;T.deadline=love.timer.getTime()+((s==0 or s==4 or s==5 or s==25) and 1.1 or .45)
end
return T

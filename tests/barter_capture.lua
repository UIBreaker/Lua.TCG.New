local T={step=0}
local Barter=require("src.barter")
local D=require("src.deities")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local P=require("src.persistence")
local function copy(d)
    local item={};for k,v in pairs(d) do item[k]=v end;return item
end
local function click(b)
    assert(b and not b.disabled,"Missing or disabled barter control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function firstItem(cb)
    for _,b in ipairs(cb.getButtons()) do if b.id=="barter_item" and not b.disabled then return b end end
end
local function shot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/barter_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime()
    assert(love.timer.getTime()-T.started<45,"Barter capture timeout at "..T.step)
    if love.timer.getTime()<(T.deadline or 0) then return end
    local s=T.step
    if s==0 then
        require("tests.barter_smoke")
        cb.startNewGame("red_deck")
        game.run.ante=2;game.run.areaStage=2;game.run.currentBlindIndex=3
        game.run.blinds=require("src.run_manager").generateAnteBlinds(2,game.selectedFaction)
        for _,blind in ipairs(game.run.blinds) do blind.status="completed" end
        game.gold=41;game.playerHp=82;game.backpackDeities={copy(D.CATALOG.spirit_pebble),copy(D.CATALOG.spirit_pebble)}
        game.backpackDeities[1].rarity="rare";game.backpackDeities[1].baseRarityTier=3;game.backpackDeities[1].evolutionLevel=1;game.backpackDeities[1].edition="foil"
        game.backpackEquipment={};for i=1,7 do B.store(game,E.instance("basic_plate"),6) end
        game.pendingBarter=true;game.shopMode="small";cb.openShop()
    elseif s==1 then click(button(cb,"next_round") or button(cb,"leave_shop"))
    elseif s==2 then
        local _,state=cb.getRunState();assert(state=="barter" and game.run.ante==2)
        local scene=require("render.scene");assert(scene.name=="barter" and scene.definition.base==require("src.expedition").area(2,"human").background)
        local npc=love.image.newImageData(Barter.npcPath);local _,_,_,a=npc:getPixel(0,0);assert(a==0)
        assert(button(cb,"barter_accept").disabled);shot("encounter")
    elseif s==3 then click(firstItem(cb))
    elseif s==4 then
        assert(Barter.selected(game) and not button(cb,"barter_accept").disabled)
        shot("spn_preview");click(button(cb,"barter_accept"))
    elseif s==5 then
        assert(game.barterEvent.confirming and #game.backpackDeities==2 and game.gold==41 and game.playerHp==82)
        shot("confirm");click(button(cb,"barter_cancel"))
    elseif s==6 then
        assert(not game.barterEvent.confirming and not game.barterEvent.completed)
        local saved=P.makeSnapshot(game,"barter")
        local loaded,state=P.restoreSnapshot(saved);assert(state=="barter" and Barter.selected(loaded))
        game.barterEvent=loaded.barterEvent
        click(button(cb,"barter_offer_2"))
    elseif s==7 then
        assert(game.barterEvent.offers[game.barterEvent.offerIndex].kind=="equipment")
        click(button(cb,"barter_next"))
    elseif s==8 then
        assert(game.barterEvent.page==2);click(firstItem(cb))
    elseif s==9 then shot("equipment_preview");click(button(cb,"barter_accept"))
    elseif s==10 then assert(#game.backpackEquipment==7);click(button(cb,"barter_accept"))
    elseif s==11 then
        assert(game.barterEvent.completed and #game.backpackEquipment==7 and game.gold==41 and game.playerHp==82)
        assert(button(cb,"barter_accept").disabled and not Barter.accept(game));shot("complete")
    elseif s==12 then click(button(cb,"barter_leave"))
    elseif s==13 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and game.run.ante==3 and not game.barterEvent)
        game.run.ante=6;game.run.areaStage=6;game.run.regionId="spades";game.run.currentBlindIndex=3
        game.run.blinds=require("src.run_manager").generateAnteBlinds(6,game.selectedFaction)
        for _,blind in ipairs(game.run.blinds) do blind.status="completed" end
        Barter.create(game);cb.setCaptureState("barter")
    elseif s==14 then
        assert(require("render.scene").definition.base==require("src.expedition").area(6,"spades").background)
        shot("spades");click(button(cb,"barter_leave"))
    elseif s==15 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and not game.barterEvent and game.gold==41 and game.playerHp==82)
        print("Barter UI PASS: shop-event-next stage, combat backgrounds in human/spades, transparent faceless NPC, disabled invalid trades, SPN preview/confirmation/cancel/resume, equipment pagination/swap/receipt, no double swap, free refusal")
        love.event.quit(0)
    end
    T.step=s+1;T.deadline=love.timer.getTime()+((s==0 or s==1 or s==13) and 1.3 or .6)
end
return T

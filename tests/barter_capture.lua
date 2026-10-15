local T={step=0,prefix=tostring(os.time())}
local Barter=require("src.barter")
local D=require("src.deities")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local P=require("src.persistence")
local function copy(d) return require("src.blood_shop").clone(d) end
local function click(b)
    assert(b and not b.disabled,"Missing or disabled barter control at step "..T.step)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function button(cb,id,side,field,value)
    for _,b in ipairs(cb.getButtons()) do if b.id==id and (not side or b.side==side) and (not field or b[field]==value) then return b end end
end
local function filter(cb,side,kind)
    T.actions=T.actions or {}
    T.actions[#T.actions+1]=function() click(button(cb,"barter_filter_menu",side)) end
    T.actions[#T.actions+1]=function() click(button(cb,"barter_filter",side,"filter",kind)) end
end
local function shot(name,done)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/barter_"..T.prefix.."_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
        if done then done() end
    end)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime();assert(love.timer.getTime()-T.started<65,"Barter capture timeout at "..T.step)
    if love.timer.getTime()<(T.deadline or 0) then return end
    if T.actions and #T.actions>0 then
        table.remove(T.actions,1)();T.deadline=love.timer.getTime()+.28;return
    end
    local s=T.step;local e=game.barterEvent
    if s==0 then
        local view=require("ui.barter");local draw=view.draw
        view.draw=function(...)
            local depth=love.graphics.getStackDepth();draw(...)
            assert(love.graphics.getStackDepth()==depth,"Barter renderer must balance graphics state")
        end
        require("tests.barter_smoke");cb.startNewGame("red_deck")
        game.run.ante=2;game.run.areaStage=2;game.run.currentBlindIndex=3
        game.run.blinds=require("src.run_manager").generateAnteBlinds(2,game.selectedFaction)
        for _,blind in ipairs(game.run.blinds) do blind.status="completed" end
        game.gold=5000;game.playerHp=82;game.souls=30;game.voidTickets=6
        game.backpackDeities={copy(D.CATALOG.spirit_pebble),copy(D.CATALOG.spirit_pebble)}
        game.backpackDeities[1].rarity="rare";game.backpackDeities[1].evolutionLevel=1;game.backpackDeities[1].edition="foil"
        game.backpackEquipment={};for _=1,7 do B.store(game,E.instance("basic_plate"),6) end
        game.backpackConsumables={require("src.shop").healingItem(nil,"cons_draw").consumable,require("src.expedition").travelPermit()}
        game.pendingBarter=true;game.shopMode="small";cb.openShop()
    elseif s==1 then click(button(cb,"next_round") or button(cb,"leave_shop"))
    elseif s==2 then
        local _,state=cb.getRunState();assert(state=="barter" and game.run.ante==2)
        assert(require("render.scene").definition.base==require("src.expedition").area(2,"human").background)
        local npc=love.image.newImageData(Barter.npcPath);local _,_,_,a=npc:getPixel(0,0);assert(a==0)
        e.temper=1;e.stock[1].item.rarity="unique";e.stock[1].item.baseRarity="unique";e.stock[1].item.baseRarityTier=8;e.stock[1].item.bloodPower=5
        assert(button(cb,"barter_accept").disabled);shot("two_inventories")
        T.actions={
            function()
                click(button(cb,"barter_search","player"));love.textinput("tam sat")
                assert(#require("ui.barter").list(game,"player")==7,"accent-insensitive inventory search")
            end,
            function() shot("search") end,
            function()
                click(button(cb,"barter_search","player"));love.textinput(string.rep("ấ",80))
                assert(require("utf8").len(require("ui.barter").queries.player)==64,"long Vietnamese searches stay valid UTF-8")
            end,
            function()
                click(button(cb,"barter_search","player"));love.keypressed("backspace");love.keypressed("return")
                assert(#require("ui.barter").list(game,"player")>7)
                love.wheelmoved(0,-1);assert(game.barterEvent.pages.player==2)
                love.wheelmoved(0,1);assert(game.barterEvent.pages.player==1)
            end,
        }
    elseif s==3 then
        click(button(cb,"barter_item","npc"));click(button(cb,"barter_gold","player","delta",1))
    elseif s==4 then click(button(cb,"barter_propose"));assert(e.status=="thinking" and not Barter.accept(game));shot("thinking")
    elseif s==5 then
        assert(e.status=="counter" and e.counter and e.counter.playerGold>1 and require("ui.barter").modal)
        T.opening=e.counter.playerGold;shot("counter_offer")
    elseif s==6 then click(button(cb,"barter_use_counter"))
    elseif s==7 then
        assert(e.status=="agreed" and e.draft.playerGold==T.opening)
        T.floor=Barter.valuation(game,e.draft).take;assert(T.floor<T.opening)
        click(button(cb,"barter_gold_input","player"));love.textinput("abc")
        assert(require("ui.barter").input.value==tostring(T.opening),"letters do not clear a selected gold value")
        love.textinput("999999999");love.keypressed("escape");assert(e.draft.playerGold==T.opening,"Escape cancels gold editing")
        click(button(cb,"barter_gold_input","player"));love.textinput("999999999");love.keypressed("return")
        assert(e.draft.playerGold==game.gold,"gold input is capped by the actual wallet")
        click(button(cb,"barter_gold_input","player"));love.textinput(tostring(T.floor));love.keypressed("return")
        assert(e.draft.playerGold==T.floor,"direct gold entry commits on Enter")
        click(button(cb,"barter_propose"))
    elseif s==8 then assert(e.status=="agreed" and e.draft.playerGold==T.floor);shot("bargained")
    elseif s==9 then
        local loaded,state=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(game,"barter")))));assert(state=="barter" and loaded.barterEvent.status=="agreed")
        T.before=game.gold;T.stock=#e.stock;click(button(cb,"barter_accept"))
    elseif s==10 then
        assert(e.trades==1 and game.gold==T.before-T.floor and #e.stock==T.stock-1 and not Barter.accept(game))
        assert(game.playerHp==82);shot("completed")
        filter(cb,"player","consumable");filter(cb,"npc","equipment")
    elseif s==11 then
        for _,side in ipairs({"player","npc"}) do
            local count=0
            for _,b in ipairs(cb.getButtons()) do if b.id=="barter_item" and b.side==side and count<2 then click(b);count=count+1 end end
            assert(count==2)
        end
        click(button(cb,"barter_gold","player","delta",25))
    elseif s==12 then
        local count=0;for _ in pairs(e.draft.player) do count=count+1 end;assert(count==2)
        local tray
        for _,b in ipairs(cb.getButtons()) do if b.id=="barter_item" and b.side=="player" and b.y>600 then tray=b;break end end
        click(tray);assert(not e.draft.player[tray.key],"click a tray card to remove it from the deal")
        click(button(cb,"barter_item","player","key",tray.key));assert(e.draft.player[tray.key])
        shot("mixed_bundle",function()
            for _,entry in ipairs(Barter.owned(game)) do
                if count>=8 then break end
                if not e.draft.player[entry.key] then Barter.toggle(game,"player",entry.key);count=count+1 end
            end
            click(button(cb,"barter_review"))
        end)
    elseif s==13 then
        assert(require("ui.barter").modal and not button(cb,"barter_accept"))
        click(button(cb,"barter_dialogue_page",nil,"delta",1));assert(require("ui.barter").dialoguePage==2)
        shot("exact_terms",function() click(button(cb,"barter_close_dialogue")) end)
    elseif s==14 then
        filter(cb,"player","resource");filter(cb,"npc","card")
    elseif s==15 then
        click(button(cb,"barter_item","player","resource","voidTickets"))
        T.actions={
            function()
                click(button(cb,"barter_amount",nil,"delta",1))
                assert(game.barterEvent.amounts.voidTickets==2,"select a resource before adjusting its quantity")
            end,
            function() shot("cards_resources",function() click(button(cb,"barter_leave")) end) end,
        }
    elseif s==16 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and game.run.ante==3 and not game.barterEvent)
        game.run.ante=6;game.run.areaStage=6;game.run.regionId="spades";Barter.create(game);cb.setCaptureState("barter")
    elseif s==17 then
        assert(require("render.scene").definition.base==require("src.expedition").area(6,"spades").background)
        shot("spades",function() click(button(cb,"barter_leave")) end)
    elseif s==18 then
        print("Barter UI PASS: brass trade desk, dropdown filters, accent/UTF8 search, wheel pagination, direct gold/cancel/clamp, removable item trays, counter/full terms, real bargaining/commit/save, cards/resources/routing/scenery; screenshots "..T.prefix)
        love.event.quit(0)
    end
    T.step=s+1;T.deadline=love.timer.getTime()+((s==0 or s==1 or s==4 or s==7 or s==16) and 1.5 or .45)
end
return T

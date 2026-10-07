local T={};local UI=require("src.ui");local D=require("src.death_vfx")
local P=require("src.persistence");P.deleteRun=function() return true end;P.saveRun=function() return true end;P.saveSettings=function() return true end
local stage=0;local age=0;local shotIndex=1;local case=1
local shots={{0.34,"shards"},{0.94,"gather"},{1.35,"materialize"},{2.10,"choices"}}
local rewards;local initialCards;local stored
local function click(btn)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    love.mousepressed((w-1280*s)/2+(btn.x+btn.w/2)*s,(h-720*s)/2+(btn.y+btn.h/2)*s,1)
    love.mousereleased((w-1280*s)/2+(btn.x+btn.w/2)*s,(h-720*s)/2+(btn.y+btn.h/2)*s,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/chest_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function love.errorhandler(message)
    print(debug.traceback(message,2));return function() return 1 end
end
function T.update(game,cb)
    age=age+love.timer.getDelta();assert(age<10,"chest test timeout at "..stage)
    if stage==0 then
        if case==1 then require("tests.chest_reveal_smoke") end
        cb.startNewGame("red_deck")
        love.mouse.setPosition(4,4)
        local E=require("src.equipment");local card=require("src.deck").newCard(11,"hearts")
        rewards={{type="card",card=card,title="HIỆP SĨ",desc="Quân tiếp viện",color=card.color},
            {type="equipment",item=E.ITEMS[E.POOL[1]],title="TRANG BỊ",desc="Khảm vào quân bài",color=UI.COLORS.goldYellow},
            {type="equipment",item=E.ITEMS[E.POOL[2]],title="TRANG BỊ",desc="Khảm vào quân bài",color=UI.COLORS.goldYellow}}
        cb.previewChest(rewards,case%2==0);initialCards=#game.persistentDeck
        stage=1;age=0;shotIndex=1
    elseif stage==1 then
        if case==1 and shots[shotIndex] and age>shots[shotIndex][1] then shot(shots[shotIndex][2]);shotIndex=shotIndex+1 end
        if age<1.0 then
            local choices=0;for _,b in ipairs(cb.getButtons()) do if b.rewardIndex then choices=choices+1 end end
            assert(choices==0,"face-down choices must not be actionable")
        end
        if age>2.85 then
            local buttons=cb.getButtons();local chosen
            local index=(case==2 or case==4) and 2 or 1
            local keep=case~=1 and case~=4
            for _,b in ipairs(buttons) do if b.rewardIndex==index and b.keep==keep then chosen=b end end
            assert(chosen,"two actions per reward")
            if case==5 then
                assert(chosen.disabled,"full inventory disables keep")
                click(chosen);assert(#game.consumables==3);print("Chest full-inventory guard PASS");love.event.quit(0);stage=99;return
            end
            click(chosen)
            local _,state=cb.getScoringState()
            if case==1 then assert(state=="map" and #game.persistentDeck==initialCards+1);print("Chest use card PASS")
            elseif case==2 then
                assert(state=="map" and game.consumables[1].category=="stored_equipment")
                local roundtrip=assert(P.restoreSnapshot(P.makeSnapshot(game,"map")))
                assert(roundtrip.consumables[1].equipmentId==game.consumables[1].equipmentId,"stored equipment save roundtrip")
                stored=game.consumables[1];cb.setCaptureState("shop");assert(cb.activateStoredReward(1));assert(select(2,cb.getScoringState())=="socketing")
                stage=2;age=0;return
            elseif case==3 then
                assert(game.consumables[1].category=="stored_card");cb.setCaptureState("shop");assert(cb.activateStoredReward(1))
                assert(#game.consumables==0 and #game.persistentDeck==initialCards+1);print("Chest keep/use card PASS")
            elseif case==4 then assert(state=="socketing");print("Chest use equipment PASS") end
            case=case+1;stage=0;age=0
        end
    elseif stage==2 and age>0.2 then
        local skip;for _,b in ipairs(cb.getButtons()) do if b.id=="skip_socket" then skip=b end end
        click(assert(skip));assert(game.consumables[1]==stored,"cancel keeps stored equipment")
        print("Chest keep/use/cancel equipment PASS")
        assert(cb.activateStoredReward(1));stage=3;age=0
    elseif stage==3 and age>0.2 then
        click({x=312,y=198,w=104,h=150})
        assert(#game.consumables==0,"stored equipment consumed only after successful attach")
        assert(#game.persistentDeck[1].equipments==1,"equipment attached")
        assert(select(2,cb.getScoringState())=="shop","return to source screen")
        print("Chest stored equipment attach PASS");case=3;stage=0;age=0
    end
    if case==5 and stage==1 then game.consumables={{category="test"},{category="test"},{category="test"}} end
end
return T

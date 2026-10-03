local T={}; local step=0;local deadline=0;local pending
local Debug=require("src.debug_tools")
local stages={1,20,21,40,41,42}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/expedition/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    if pending then local action=pending;pending=nil;action();deadline=love.timer.getTime()+1;return end
    if love.timer.getTime()<deadline then return end
    if step==0 then
        cb.startNewGame("red_deck");love.mouse.setPosition(5,5)
        require("tests.expedition_smoke")
    elseif step<=#stages*2 then
        local stage=stages[math.ceil(step/2)]
        if step%2==1 then
            shot("select_"..stage)
            pending=function()
                local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
                local x=stage==20 or stage==40
                x=x and 1056 or 224
                love.mousepressed((w-1280*scale)/2+x*scale,(h-720*scale)/2+591*scale,1)
                assert(game.monster and game.monster.stage==stage,"Vào trận must start the selected stage")
                if stage==40 then assert(game.monster.bossData.active.name==require("src.expedition").shipBoss(40).skill) end
            end
        else shot("battle_"..stage) end
    elseif step==#stages*2+1 then
        Debug.setAnte(game,20,3)
        local Run=require("src.run_manager")
        Run.completeCurrentBlind(game.run,game);Run.advanceBlind(game.run,game)
        assert(game.run.victory and game.run.travelPermit)
        game.run.stats.blindsWon=60 -- Canonical campaign count for the visual fixture.
        cb.setCaptureState("victory")
    elseif step==#stages*2+2 then
        shot("travel_permit")
        pending=function()
            local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
            love.mousepressed((w-1280*scale)/2+805*scale,(h-720*scale)/2+563*scale,1)
            assert(game.run.ante==21 and game.run.endless and game.run.travelPermit,"Lên tàu must continue at 21 with permit")
        end
    else print("Expedition render capture passed: six stages, real fight input, ship skills, permit and boarding");love.event.quit();return end
    step=step+1
    if step<=#stages*2 and step%2==1 then
        local stage=stages[math.ceil(step/2)]
        pending=function() Debug.setAnte(game,stage,(stage==20 or stage==40) and 3 or 1);cb.setCaptureState("BLIND_SELECT") end
    end
    deadline=love.timer.getTime()+1.0
end
return T

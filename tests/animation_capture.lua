local UI=require("src.ui")
local Physics=UI.CardPhysics
local Test={}
local stage, deadline, card, surface=0,0
local function pointer(x,y,action)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if action=="press" then
        local held=love.keyboard.isDown
        love.keyboard.isDown=function() return true end -- Shift: reorder rather than sweep-select.
        love.mousepressed(px,py,1);love.keyboard.isDown=held
    elseif action=="release" then love.mousereleased(px,py,1)
    else love.mousemoved(px,py,0,0) end
end
local function after(seconds) stage=stage+1;deadline=love.timer.getTime()+seconds end
function Test.update(game,callbacks)
    if love.timer.getTime()<deadline then return end
    if stage==0 then
        callbacks.startNewGame("red_deck");callbacks.startMonsterEncounter(1,false)
        card=game.hand[1];after(0.8)
    elseif stage==1 then
        surface=assert(Physics.getState(card))
        pointer(surface.ox+surface.a*surface.w*0.2+surface.c*surface.h*0.4,
            surface.oy+surface.b*surface.w*0.2+surface.d*surface.h*0.4,"press")
        assert(Physics.isHeld(card));pointer(650,580);after(0.07)
    elseif stage==2 then
        assert(math.abs(surface.x-surface.targetX)>0.1,"drag must retain soft lag")
        local velocity=surface.vx;pointer(510,580)
        assert(surface.vx==velocity,"reversal must preserve momentum");after(0.14)
    elseif stage==3 then
        pointer(510,580,"release");assert(not Physics.isHeld(card));after(1.2)
    elseif stage==4 then
        assert(math.abs(surface.x-surface.homeX)<3 and math.abs(surface.y-surface.homeY)<3,"release must settle")
        for _,c in ipairs(game.hand) do
            assert(c.visualScale==c.visualScale and c.visualScale>0 and c.visualScale<2)
        end
        callbacks.openShop();pointer(1150,40);after(1.5)
    elseif stage==5 then
        love.graphics.captureScreenshot(function(data)
            local file=assert(io.open("docs/animation_polish.png","wb"))
            file:write(data:encode("png"):getString());file:close()
        end)
        after(0.2)
    else
        print("Animation runtime passed: real hand grab/lag/reversal/release/settle, finite hand motion, shop and button rendering")
        love.event.quit(0)
    end
end
return Test

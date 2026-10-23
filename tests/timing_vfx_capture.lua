local V=require("src.timing_vfx")
local T={index=1,started=false}
local cases={
    {"confirm","good",.10},{"confirm","perfect",.10},{"confirm","critical",.10},
    {"confirm","ultimate",.10},{"confirm","apex",.10},
    {"attack","good",.16},{"attack","perfect",.16},{"attack","critical",.16},
    {"attack","ultimate",.16},{"attack","apex",.16},
    {"block","good",.12},{"block","perfect",.12},{"block","apex",.12},
    {"reflect","ultimate",.13},{"reflect","ultimate",.36},{"reflect","apex",.13},{"reflect","apex",.36},
    {"miss","trap",.20},{"break","trap",.18},{"reflect","apex",.36,true},
}
function T.update(game,cb)
    if T.finished then return end
    if not T.started then
        -- Poses below own the clock; screenshot encoding must not advance their age.
        V.update=function() end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        cb.setReducedMotion(false);cb.setGameSpeed(1)
        game.monster.hp=100000;game.monster.maxHp=100000;game.monster.damageLagHp=100000
        love.mouse.setPosition(2,2)
        local draw=love.draw
        love.draw=function()
            draw()
            if T.rail then
                local g=love.graphics;local w,h=g.getDimensions()
                g.push("all");g.origin();g.scale(w/1280,h/720)
                require("src.combat_timing").draw(T.rail,require("src.ui"));V.draw("rail")
                g.pop()
            end
        end
        T.started=true;T.next=love.timer.getTime()+1
        return
    end
    if love.timer.getTime()<T.next then return end
    local spec=cases[T.index]
    if not spec then T.finished=true;print("Timing VFX gallery passed: 20 authored grade/outcome frames including rail bursts and reduced motion");love.event.quit(0);return end
    V.clear()
    local e=V.emit(spec[1],spec[2],630,270,{reducedMotion=spec[4]})
    e.age=spec[3];T.rail=nil
    if spec[1]=="confirm" then
        T.rail=require("src.combat_timing").start("attack",10,10)
        local band=T.rail.apex
        for _,zone in ipairs(T.rail.zones) do if zone.grade==spec[2] then band=zone;break end end
        T.rail.position=(band.from+band.to)/2;T.rail.age=1;T.rail.result={grade=spec[2]};T.rail.hold=e.age
        e.x=500+T.rail.position*370;e.y=667;e.railX=500;e.railW=370
    end
    local name="docs/timing_vfx_"..spec[1].."_"..spec[2].."_"..math.floor(spec[3]*100)..(spec[4] and "_reduced" or "")..".png"
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(name,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
    T.index=T.index+1;T.next=love.timer.getTime()+.12
end
return T

local V=require("src.timing_vfx")
local T={index=1,started=false}
local cases={
    {"confirm","normal",0,false,true,"attack"},{"confirm","normal",0,false,true,"parry"},
    {"confirm","good",.10},{"confirm","perfect",.10},{"confirm","critical",.10},
    {"confirm","ultimate",.10},{"confirm","apex",.10},{"confirm","divine",.10},
    {"attack","good",.16},{"attack","perfect",.16},{"attack","critical",.16},
    {"attack","ultimate",.16},{"attack","apex",.16},{"attack","divine",.16},
    {"block","good",.12},{"block","perfect",.12},{"block","apex",.12},
    {"reflect","ultimate",.13},{"reflect","ultimate",.36},{"reflect","apex",.13},{"reflect","apex",.36},{"reflect","divine",.13},{"reflect","divine",.36},
    {"miss","trap",.20},{"break","trap",.18},{"reflect","apex",.36,true},
}
for _,a in ipairs(arg or {}) do if a=="--hazards" then cases={
    {"confirm","normal",0,false,true,"attack"},{"confirm","normal",0,false,true,"parry"},
    {"confirm","riposte",.10,false,false,"attack"},{"confirm","exposed",.10,false,false,"parry"},
    {"enemy_reflect","riposte",.13},{"enemy_reflect","riposte",.30},{"break","exposed",.18},
    {"confirm","siphon",.10,false,false,"attack"},{"confirm","pierce",.10,false,false,"attack"},{"confirm","haste",.10,false,false,"attack"},
    {"confirm","mend",.10,false,false,"parry"},{"confirm","reserve",.10,false,false,"parry"},{"confirm","rebound",.10,false,false,"parry"},
} end end
for _,a in ipairs(arg or {}) do if a=="--utility-visuals" then cases={
    {"confirm","normal",0,false,true,"attack"},{"confirm","normal",0,false,true,"parry"},
    {"confirm","siphon",.10,false,false,"attack"},{"confirm","pierce",.10,false,false,"attack"},{"confirm","haste",.10,false,false,"attack"},
    {"confirm","mend",.10,false,false,"parry"},{"confirm","reserve",.10,false,false,"parry"},{"confirm","rebound",.10,false,false,"parry"},
    {"attack","siphon",.09},{"attack","pierce",.09},{"attack","haste",.09},
    {"block","mend",.10},{"block","reserve",.10},{"reflect","rebound",.13},{"reflect","rebound",.27},
    {"attack","siphon",.09,true},{"block","mend",.10,true},{"reflect","rebound",.27,true},
} end end
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
    if not spec then T.finished=true;print("Timing VFX gallery passed: "..#cases.." authored grade/outcome frames including rail bursts");love.event.quit(0);return end
    V.clear()
    local e=V.emit(spec[1],spec[2],630,270,{reducedMotion=spec[4]})
    e.age=spec[3];T.rail=nil
    if spec[1]=="confirm" then
        T.rail=require("src.combat_timing").start(spec[6] or "attack",99999,10,{timingChains={perfect=20,critical=2,ultimate=1,apex=3}})
        if require("src.combat_timing").utility[spec[2]] then
            repeat
                T.rail=require("src.combat_timing").start(spec[6],10,10)
                for _,zone in ipairs(T.rail.utilityZones) do if zone.grade==spec[2] then T.utilityBand=zone end end
            until T.utilityBand
        end
        local band=(spec[2]=="riposte" or spec[2]=="exposed") and T.rail.hazard or spec[2]=="divine" and T.rail.divine or T.rail.apex
        for _,zone in ipairs(T.rail.zones) do if zone.grade==spec[2] then band=zone;break end end
        if T.utilityBand then band=T.utilityBand;T.utilityBand=nil end
        T.rail.position=(band.from+band.to)/2;T.rail.age=1;T.rail.result={grade=spec[2]};T.rail.hold=e.age
        if spec[5] then
            T.rail.result=nil;T.rail.position=.97;e.age=1
        else T.rail.result.chain=3;e.chain=3 end
        local l=require("src.combat_timing").layout(require("src.ui"))
        e.x=l.bx+T.rail.position*l.bw;e.y=l.by+7;e.railX=l.bx;e.railW=l.bw
    end
    local name="docs/timing_vfx_"..spec[1].."_"..spec[2].."_"..math.floor(spec[3]*100)..(spec[4] and "_reduced" or "")..(spec[5] and "_"..spec[6] or "")..".png"
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(name,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
    T.index=T.index+1;T.next=love.timer.getTime()+.12
end
return T

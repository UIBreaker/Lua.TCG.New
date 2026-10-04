-- Run with: lua tests/weather_smoke.lua
local calls, stack = {}, 0
love = {graphics={}}
local g = love.graphics
g.push = function() stack=stack+1 end
g.pop = function() stack=stack-1; assert(stack>=0, "unbalanced graphics state") end
for _,name in ipairs({"setBlendMode","setColor","polygon","draw","setLineWidth","line","circle","ellipse","rectangle"}) do
    g[name] = function(...)
        local values={...}
        for _,v in ipairs(values) do
            if type(v)=="number" then assert(v==v and math.abs(v)<100000, "invalid draw coordinate") end
        end
        calls[#calls+1]={name=name, values=values}
    end
end
local C = require("config.visual_config")
local D = require("config.scene_definitions")
local L = require("render.lighting")
L.radial = {}
local W = require("render.weather")
local Scene = require("render.scene")
local rng = require("src.rng")
local before = rng.getState()
Scene.time=0
for i,profile in ipairs(W.profiles) do
    local kind=profile.kind
    Scene.update(0,"playing",{stage=i})
    assert(Scene.weather.kind==kind, "encounter weather selection")
    Scene.update(0,"scoring",{stage=i})
    assert(Scene.weather.kind==kind, "weather must persist through scoring")
    for _,quality in pairs(C.qualities) do
        for _,preset in pairs(D.presets) do
            for _,time in ipairs({0,1.2,4,8.2}) do
                calls={}
                W.draw("before",time,preset,Scene.weather,quality)
                W.draw("after",time,preset,Scene.weather,quality)
                assert(#calls>0 and stack==0)
            end
        end
    end
end
assert(W.resolve({stage=#W.profiles+1}).kind=="sun", "weather cycle repeats")
assert(W.resolve({stage=-10}).kind=="sun", "invalid stages use first profile")
local rainy=W.resolve({stage=3})
calls={}; W.draw("after",0,D.presets.ICE,rainy,C.qualities.HIGH)
local first=calls
calls={}; W.draw("after",1,D.presets.ICE,rainy,C.qualities.HIGH)
local animated=false
for i,call in ipairs(calls) do
    if call.name=="line" and call.values[2]~=first[i].values[2] then animated=true end
end
assert(animated, "rain must move over time")
for _,state in ipairs({"menu","shop","map","CASH_OUT"}) do
    Scene.update(0,state,{stage=3}); assert(not Scene.weather, "weather is battle-only")
end
C.enabled=false; calls={}
W.draw("before",2,D.presets.DESERT,W.resolve(),C.qualities.HIGH)
W.draw("after",2,D.presets.ICE,rainy,C.qualities.HIGH)
assert(#calls==0 and stack==0, "disabled cinematics must bypass weather")
C.enabled=true
C.effects.fog=false; C.effects.particles=false; C.effects.lighting=false; calls={}
W.draw("before",2,D.presets.DESERT,W.resolve(),C.qualities.HIGH)
W.draw("after",2,D.presets.ICE,rainy,C.qualities.HIGH)
assert(#calls==0 and stack==0, "individual effect toggles")
C.effects.fog=true; C.effects.particles=true; C.effects.lighting=true
assert(rng.getState()==before, "weather cannot consume gameplay RNG")
print("Weather smoke passed: "..#W.profiles.." types, 7 presets, 3 qualities, animation, battle-only, effect toggles, graphics state, RNG isolation")

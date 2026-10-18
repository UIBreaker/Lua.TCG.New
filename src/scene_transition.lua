-- Presentation only: observe the scene that will actually be drawn, never queue gameplay.
local C=require("config.visual_config").transition
local Motion=require("src.motion")
local T={}

function T.key(state,game)
    if state=="playing" or state=="scoring" or state=="defeating" or state=="gameover" then return "battle","battle" end
    local run=game and game.run or {}
    local place=tostring(run.regionId or "")..":"..tostring(run.ante or 1)
    if state=="shop" then return "shop:"..tostring(game and game.shopMode or "normal")..":"..place,"shop" end
    if state=="map" or state=="BLIND_SELECT" then return state..":"..place,"map" end
    return state,state
end

function T.observe(s,state,game,enabled,reduced)
    local key,kind=T.key(state,game)
    local changed=s.stateKey~=nil and s.stateKey~=key
    s.stateKey,s.transitionKind=key,kind
    if changed then
        s.transitionFrom=s.displayedScene
        s.transitionSerial=(s.transitionSerial or 0)+1
        s.transitionReduced=reduced==true
        s.transitionDuration=s.transitionReduced and C.reducedDuration or C.duration
        s.transitionAge=enabled and 0 or s.transitionDuration
    elseif s.transitionAge==nil then s.transitionAge=C.duration end
    s.displayedScene=state
    return changed and enabled
end

function T.update(s,dt,fast)
    local duration=s.transitionDuration or C.duration
    s.transitionAge=math.min(duration,(s.transitionAge or duration)+math.max(0,math.min(dt,.05))*(fast and 2 or 1))
end

function T.busy(s,state,game,enabled)
    if not enabled or not s.stateKey then return false end
    -- Also covers input delivered after a state change but before its first draw.
    return s.stateKey~=T.key(state,game) or (s.transitionAge or C.duration)<(s.transitionDuration or C.duration)
end

function T.pose(s)
    local duration=s.transitionDuration or C.duration
    local age=s.transitionAge or duration
    local p=math.max(0,math.min(1,age/duration))
    local fade=p*p*(3-2*p)
    local travel=Motion.settle(age,duration)
    return {opacity=1-fade,outY=s.transitionReduced and 0 or -C.exitLift*travel,
        mapY=s.transitionReduced and 0 or C.mapLift*(1-travel)}
end

return T

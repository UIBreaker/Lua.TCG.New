local S={base=.65}
function S.normalize(settings)
    local speed=settings.gameSpeed
    if speed~=1 and speed~=2 and speed~=4 then speed=1 end
    if settings.fastScoring and speed==1 then speed=2 end
    settings.gameSpeed=speed
    settings.fastScoring=false -- The shared clock replaces the old per-effect doubling.
    return speed
end
function S.set(settings,speed)
    settings.gameSpeed=speed;settings.fastScoring=false
    return S.normalize(settings)
end
function S.cycle(settings)
    return S.set(settings,settings.gameSpeed==1 and 2 or settings.gameSpeed==2 and 4 or 1)
end
function S.wrap(update,getSettings)
    return function(dt)
        local settings=getSettings()
        local rate=S.base*S.normalize(settings)
        local real=math.min(dt,.25)
        local count=math.max(1,math.ceil(real*rate*60))
        -- Small steps keep ×4 exact in animations that cap their frame delta.
        for _=1,count do update(real*rate/count,real/count) end
    end
end
return S

-- Original deterministic synthesis, preloaded through the existing mixer/voice limiter.
local A={}
local C=require("config.nen_vfx_config")
local tau=math.pi*2
local bases={enhancement=73,transmutation=510,emission=210,conjuration=112,manipulation=290,specialization=157}
function A.register(sound)
    if not love or not love.sound or not love.sound.newSoundData then return end
    for index,id in ipairs(C.order) do
        local p=C.hands[id]
        if p.ready then for _,kind in ipairs({"charge","release","beat","impact"}) do
            local duration=kind=="charge" and .32 or kind=="impact" and .36 or kind=="beat" and .11 or .16
            local rate=22050;local data=love.sound.newSoundData(math.floor(duration*rate),rate,16,1)
            local base=bases[p.nenType]+index*3;local peak=0
            for i=0,data:getSampleCount()-1 do
                local t=i/rate;local k=t/duration
                local noise=(math.sin((i+index*41)*12.9898)*43758.5453)%1*2-1
                local env=(1-math.exp(-t*(kind=="impact" and 850 or 100)))*math.exp(-t*(kind=="charge" and 7 or kind=="impact" and 15 or kind=="beat" and 38 or 27))
                local frequency=kind=="charge" and base*(.6+k*1.9) or kind=="impact" and base*(1.6-k) or kind=="beat" and base*3.2 or base*(2.6-1.2*k)
                local tone=math.sin(t*tau*frequency)*.34+math.sin(t*tau*frequency*1.497)*.15
                local texture
                if p.nenType=="emission" then texture=noise*.5*math.exp(-t*22)+math.sin(t*tau*1900)*.09
                elseif p.nenType=="transmutation" then texture=math.sin(t*tau*1600)*math.sin(t*tau*37)*.24+noise*.12
                elseif p.nenType=="conjuration" then texture=math.sin(t*tau*base*3.13)*.2+noise*.13*math.exp(-t*18)
                elseif p.nenType=="manipulation" then texture=math.sin(t*tau*base*2)*.18*(.5+.5*math.cos(t*tau*18))
                elseif p.nenType=="specialization" then texture=math.sin(t*tau*(base+75*k*k))*.22+noise*.09*(1-k)
                else texture=noise*.26*math.exp(-t*19)+math.sin(t*tau*42)*.23 end
                -- Materials carry their own transient, in addition to the six Nen families.
                if p.signature=="jackpot" then
                    texture=texture+(.18*math.sin(t*tau*1427)+.12*math.sin(t*tau*2182))*math.exp(-t*13)
                elseif p.signature=="world_gate" or p.signature=="fortress" or p.signature=="summoned_gate_sword" then
                    texture=texture+.26*math.sin(t*tau*37)+noise*.10*math.exp(-t*45)
                elseif p.signature=="red_tide" then
                    texture=.22*math.sin(t*tau*73)*math.sin(t*tau*690)+noise*.22*math.exp(-t*12)
                elseif p.signature=="obsidian_tide" then
                    texture=noise*.44*math.exp(-t*46)+.19*math.sin(t*tau*63)
                elseif p.signature=="growth_spiral" then
                    texture=texture+.18*math.sin(t*tau*(220+530*k*k))*(.65+.35*math.sin(k*tau*5))
                elseif p.conversion=="weapon_construction" then
                    texture=texture+(.15*math.sin(t*tau*1317.3)+.10*math.sin(t*tau*2710.1))*math.exp(-t*25)
                elseif p.signature=="endless_orbit" then
                    texture=.24*math.sin(t*tau*32)+.20*math.sin(t*tau*(140-65*k*k))+noise*.10
                    if kind=="charge" then env=env*(.35+.65*k) end
                end
                local value=math.max(-.78,math.min(.78,(tone+texture)*env));peak=math.max(peak,math.abs(value))
                data:setSample(i,value)
            end
            sound.registerProcedural("nen_"..id.."_"..kind,data,{gain=kind=="impact" and .77 or kind=="beat" and .38 or .50,
                priority=kind=="impact" and 5 or 3,cooldown=kind=="beat" and .035 or .06,peak=peak})
            if data.release then data:release() end
        end end
    end
end
return A

-- Original authored contact scores, rendered once at load; never uses gameplay RNG.
local A={profiles=require("config.attack_audio")}
local C=require("config.nen_vfx_config")
local tau,rate=math.pi*2,32000
local sin,exp,abs=math.sin,math.exp,math.abs

local function material(kind,t,phase,air,low,noise)
    if kind=="body" then return sin(phase)+.28*sin(phase*2)+low*.7+air*exp(-t*95)*.48 end
    if kind=="wind" then return air*2.4+low*1.7+sin(phase)*.12 end
    if kind=="lance" then return air*1.7+sin(phase)*.20+sin(phase*3.11)*.14 end
    if kind=="metal" or kind=="coin" or kind=="forge" then
        return sin(phase)*.60+sin(phase*2.756)*.29*exp(-t*9)
            +sin(phase*5.404)*.15*exp(-t*24)+sin(phase*8.933)*.06*exp(-t*45)+air*exp(-t*90)*.8
    end
    if kind=="blade" then return (air-low)*2+sin(phase)*.16+sin(phase*3.87)*exp(-t*35)*.12+noise*exp(-t*110)*.45 end
    if kind=="shot" then return air*exp(-t*70)*2.4+sin(phase)*.32+sin(phase*2.3)*.11 end
    if kind=="hoof" then return low*2.6+sin(phase)*.75+air*exp(-t*80)*.7 end
    if kind=="banner" then return air*2.8+low*1.2+sin(phase)*.17*(.6+.4*sin(t*31)) end
    if kind=="cannon" then return low*5+sin(phase)*.8+air*exp(-t*38)*1.6+noise*exp(-t*140)*.55 end
    if kind=="pillar" or kind=="earth" then return low*3.7+sin(phase)*.85+air*(.3+.7*sin(t*83)^8)+noise*exp(-t*65)*.3 end
    if kind=="royal" or kind=="army" then
        return sin(phase+.018*sin(t*29))*.7+sin(phase*2)*.23+sin(phase*3)*.14+sin(phase*4)*.07+air*.12
    end
    if kind=="lightning" then
        return air*(.3+1.7*math.max(0,sin(t*611))^8)+sin(phase)*.25*sin(t*137)+noise*exp(-t*110)*.9
    end
    if kind=="growth" then return sin(phase)*.70+sin(phase*2)*.19+sin(phase*3)*.09+low*.25 end
    if kind=="star" or kind=="map" then return sin(phase)*.65+sin(phase*2.01)*.2+air*exp(-t*120)*.40 end
    if kind=="sun" then return sin(phase)*.45+sin(phase*1.5)*.22+air*.65 end
    if kind=="ice" or kind=="prism" then
        return sin(phase)*.55+sin(phase*1.93)*.27*exp(-t*3)+sin(phase*3.07)*.13*exp(-t*12)
            +sin(phase*5.81)*.09*exp(-t*30)+air*(kind=="ice" and 1.6 or .40)*exp(-t*40)
    end
    if kind=="blood" then return low*3.6+sin(phase)*.65+air*.6*(.4+.6*sin(t*54)^2) end
    if kind=="obsidian" then return (air-low)*1.7*(.2+.8*sin(t*127)^6)+low*2+sin(phase)*.4 end
    if kind=="eclipse" then return sin(phase)*.48+sin(phase*1.022)*.48+sin(phase*.5)*.25 end
    if kind=="judgement" then return sin(phase)*.5+sin(phase*1.5)*.32+sin(phase*2)*.24+sin(phase*3)*.10 end
    if kind=="gate" then return low*4+sin(phase)*.6+sin(phase*1.48)*.27+air*.55*(.5+.5*sin(t*47)^4) end
    if kind=="falling" then return sin(phase)*.6+sin(phase*2.01)*.16+air*.7 end
    if kind=="vortex" then return sin(phase)*.60+sin(phase*1.498)*.3+low*2+air*.25 end
    error("Missing attack material: "..tostring(kind))
end

local function render(s,kind,tier,index)
    local boss=kind=="boss_finisher" or kind=="boss_armored_finisher"
    local fracture=kind=="armor_break" or kind=="armored_finisher" or kind=="boss_armored_finisher"
    local finish=kind=="finisher" or kind=="armored_finisher" or boss
    local impact=kind=="impact" or fracture or finish
    local windup=C.timing[tier][3]+C.timing[tier][4]+C.timing[tier][5]
    local duration=impact and math.max(.64,s.rhythm[#s.rhythm]+s.tail)+(tier==3 and .72 or tier==2 and .20 or 0)
        or kind=="charge" and windup or kind=="release" and (.18+(tier-1)*.07) or .17
    if fracture then duration=duration+.12+(tier-1)*.08 end
    if finish then duration=duration+.22+(tier-1)*.16 end
    if boss then duration=duration+.30+(tier-1)*.35 end
    local victoryAt=.65+(tier-1)*.45
    if boss then duration=math.max(duration,victoryAt+3.2+(tier-1)*.05) end
    if kind=="miss" then duration=({.34,.54,.78})[tier] end
    local count=math.floor(duration*rate)
    local left,right={},{}
    for i=1,count do left[i],right[i]=0,0 end
    local serial=0
    local function event(instrument,at,length,f,amplitude,pan,glide,attack,decay,rising)
        serial=serial+1
        local seed=index*1009+serial*7919+tier*379+(impact and 71 or kind=="release" and 97 or kind=="beat" and 131 or 151)
        local offset=math.floor(at*rate)
        local n=math.min(math.floor(length*rate),count-offset)
        local low,air=0,0
        for i=0,n-1 do
            local t=i/rate
            seed=seed*48271%2147483647
            local noise=seed/1073741823.5-1
            air=air+(noise-air)*.38;low=low+(noise-low)*.035
            local phase=tau*(f*t+f*((glide or 1)-1)*t*t/(2*length))
            local envelope=(1-exp(-t/(attack or .0012)))*exp(-t/(decay or length*.28))
                *math.min(1,(n-1-i)/96)
            if rising then envelope=envelope*(.12+.88*(i/math.max(1,n-1))^1.5) end
            local value=material(instrument,t,phase,air,low,noise)*envelope*amplitude
            local pos=offset+i+1
            left[pos]=left[pos]+value*math.sqrt(1-pan)
            right[pos]=right[pos]+value*math.sqrt(1+pan)
        end
    end
    if impact then
        -- The first body begins at contact; later accents are the hand's own cadence.
        event("body",0,.27+(tier-1)*.055,s.body*(1-(tier-1)*.045),.52+(tier-1)*.22,0,.58,.0007,.065+(tier-1)*.035)
        for j,at in ipairs(s.rhythm) do
            local f=s.tone*s.notes[(j-1)%#s.notes+1]
            local spread=tier==3 and .80 or tier==2 and .52 or .23
            local pan=#s.rhythm>1 and (j%2==0 and spread or -spread) or spread*.45
            local glide=s.material=="falling" and .35 or s.material=="vortex" and .55 or s.material=="growth" and 1.15 or .92
            event(s.material,at,s.tail,f,(.92+(tier-1)*.07)/math.sqrt(math.max(1,#s.rhythm*.45)),pan,glide,
                s.material=="banner" and .022 or s.material=="eclipse" and .010 or .0012,s.tail*.32)
        end
        if tier>=2 then
            event(s.material,.045,s.tail*.9,s.tone*.5,.28+(tier-2)*.13,0,.80,.006,s.tail*.42)
            event("body",.07,.32,s.body*.75,.32+(tier-2)*.13,0,.72,.002,.12)
            event(s.material,.16,s.tail+.25,s.tone*s.notes[#s.notes],.68+(tier-2)*.10,-.36,.94,.045,.27)
        end
        if tier==3 then
            -- An overtone crown and a widened answer reuse this hand's own intervals.
            event(s.material,.018,s.tail*.85,s.tone*s.notes[#s.notes],.33,-.60,1.02,.001,s.tail*.30)
            event(s.material,.035,s.tail,s.tone*2,.22,.60,.94,.003,s.tail*.36)
            for j,at in ipairs(s.rhythm) do
                event(s.material,.26+at*.85,s.tail*1.3,s.tone*s.notes[j]*.75,
                    .48/math.sqrt(#s.rhythm),j%2==0 and -.78 or .78,.82,.009,s.tail*.62)
            end
            event(s.material,.60+s.rhythm[#s.rhythm]*.4,.44,s.tone*.5,.27,0,.70,.015,.20)
        end
        if fracture then
            -- A sharp plate rupture, then fragments answering in this hand's intervals.
            event("blade",.004,.065,s.tone*1.7,.20+(tier-1)*.045,0,.38,.0003,.014)
            for j,at in ipairs(s.rhythm) do
                local f=s.tone*s.notes[j]
                local pan=(j%2==0 and 1 or -1)*(.30+(tier-1)*.24)
                event(s.material,.025+at*.72,.12+(tier-1)*.06,f*2.3,
                    (.66+(tier-1)*.15)/math.sqrt(#s.rhythm),pan,.48,.0005,.027+(tier-1)*.016)
                event(s.material,.19+at*.85,.18+(tier-1)*.10,f*1.37,
                    (.32+(tier-1)*.10)/math.sqrt(#s.rhythm),-pan,.62,.001,.055+(tier-1)*.035)
            end
            if tier==3 then
                event(s.material,.10,.48,s.tone*.36,.53,0,.46,.002,.16)
                event("body",.10,.40,s.body*.64,.42,0,.45,.001,.12)
            end
        end
        if finish then
            -- Collapse follows the first contact; its final cadence belongs to the hand.
            local collapse=.075+(tier-1)*.025
            event("body",collapse,.34+(tier-1)*.15,s.body*.72,.34+(tier-1)*.18,0,.30,.002,.10+(tier-1)*.05)
            for j,at in ipairs(s.rhythm) do
                local pan=(j%2==0 and -1 or 1)*(.28+(tier-1)*.26)
                event(s.material,collapse+.06+at,.36+(tier-1)*.20,s.tone*s.notes[j]*.5,
                    (.52+(tier-1)*.14)/math.sqrt(#s.rhythm),pan,.48,.004,.13+(tier-1)*.08)
            end
            if tier==3 then
                local seal=.42+s.rhythm[#s.rhythm]
                event(s.material,seal,.65,s.tone*.25,.42,-.66,.40,.016,.27)
                event(s.material,seal+.035,.65,s.tone*s.notes[#s.notes]*.5,.32,.66,.68,.022,.29)
            end
        end
        if boss then
            -- The verdict answers in the killing hand's material and intervals.
            event(s.material,0,.36+(tier-1)*.10,s.tone*.5,.34+(tier-1)*.14,0,.72,.001,.12+(tier-1)*.04)
            local verdict=.18+(tier-1)*.075
            event("body",verdict,.42+(tier-1)*.15,math.max(48,s.body*.85),.32+(tier-1)*.19,0,.60,.001,.14+(tier-1)*.06)
            for j,at in ipairs(s.rhythm) do
                local spread=.36+(tier-1)*.25
                event(s.material,verdict+at*.95,.48+(tier-1)*.22,s.tone*s.notes[j]*.75,
                    (.56+(tier-1)*.20)/math.sqrt(#s.rhythm),j%2==0 and spread or -spread,
                    .72,.003,.20+(tier-1)*.10)
            end
            if tier==3 then
                -- Pressure gathers behind the first strike, then the final seal opens wide.
                event(s.material,.10,.23,s.tone*.33,.40,0,1.65,.012,.6,true)
                local seal=.86+s.rhythm[#s.rhythm]*.8
                event(s.material,seal,.90,s.tone*.5,.56,-.88,.78,.018,.37)
                event(s.material,seal+.045,.90,s.tone*s.notes[#s.notes]*.75,.44,.88,.88,.024,.40)
            end
            -- The same voice carries the last resonance into this hand's victory phrase.
            event(s.material,victoryAt-.22,1.35,s.tone*.5,.22+(tier-1)*.04,0,1.05,.07,.65)
            event("royal",victoryAt-.22,1.40,s.tone*.5,.12,0,1,.09,.85)
            local span=s.rhythm[#s.rhythm]+.12
            for j,at in ipairs(s.rhythm) do
                local pan=(j%2==0 and 1 or -1)*(.40+(tier-1)*.20)
                local note=s.tone*s.notes[j]
                event(s.material,victoryAt+.18+at/span*.66,.65+(tier-1)*.16,note*.75,
                    (.28+(tier-1)*.08)/math.sqrt(#s.rhythm),pan,1.04,.028,.30+(tier-1)*.08)
                event("royal",victoryAt+.22+at/span*.66,.85+(tier-1)*.20,note*.5,
                    (.18+(tier-1)*.05)/math.sqrt(#s.rhythm),-pan*.5,1,.055,.40+(tier-1)*.12)
                if tier>=2 then
                    event(s.material,victoryAt+.92+at/span*.48,.76,note,
                        (.18+(tier-2)*.07)/math.sqrt(#s.rhythm),-pan,1.02,.038,.38)
                end
            end
            event("body",victoryAt+.24,.26,s.body*1.4,.13+(tier-1)*.07,0,.82,.006,.07)
            event("body",victoryAt+.95,.32,s.body*1.2,.12+(tier-1)*.06,0,.90,.012,.11)
            local crown=victoryAt+1.25
            event(s.material,crown,1.18+(tier-1)*.20,s.tone,.22+(tier-1)*.07,-.56,1,.055,.48+(tier-1)*.10)
            event(s.material,crown+.045,1.18+(tier-1)*.20,s.tone*s.notes[#s.notes]*1.5,
                .17+(tier-1)*.055,.56,1,.060,.50+(tier-1)*.10)
            event("royal",crown,1.5,s.tone*.5,.20+(tier-1)*.05,-.40,1,.075,.70)
            event("royal",crown+.045,1.5,s.tone*s.notes[#s.notes]*.75,.14+(tier-1)*.045,.40,1,.08,.72)
            if tier==3 then event(s.material,crown+.10,1.45,s.tone*2,.16,0,1,.075,.62) end
        end
    elseif kind=="release" then
        event("wind",0,duration*.65,s.body*2,.24+(tier-1)*.07,0,2.3,.0015,.035+(tier-1)*.012)
        event("body",0,duration*.55,s.body*1.6,.16+(tier-1)*.19,0,.55,.0006,.035+(tier-1)*.014)
        for j,at in ipairs(s.rhythm) do
            local spread=.18+(tier-1)*.28
            event(s.material,at*(.22+(tier-1)*.09),duration*.46,s.tone*s.notes[(j-1)%#s.notes+1],
                (.52+(tier-1)*.12)/math.sqrt(#s.rhythm),j%2==0 and spread or -spread,
                s.material=="falling" and .45 or 1.40,.0007,.032+(tier-1)*.012)
        end
        if tier>=2 then
            event(s.material,.018,duration*.65,s.tone*.5,.22+(tier-2)*.15,-.38,.80,.002,.065)
        end
        if tier==3 then
            event(s.material,.035,.23,s.tone*s.notes[#s.notes],.35,.72,1.12,.001,.065)
            event(s.material,.095,.20,s.tone*1.5,.24,-.72,.80,.004,.075)
        end
    elseif kind=="miss" then
        local spread=({.28,.56,.86})[tier]
        event("wind",0,duration,s.body*3,.24+(tier-1)*.11,-spread,1.8,.008,duration*.20)
        event("wind",.035+(tier-1)*.025,duration*.75,s.body*2,.16+(tier-1)*.09,spread,.32,.010,duration*.23)
        for j,at in ipairs(s.rhythm) do
            local pan=j%2==0 and spread or -spread
            event(s.material,.018+at*(.36+(tier-1)*.22),duration*.65,s.tone*s.notes[j]*1.20,
                (.48+(tier-1)*.10)/math.sqrt(#s.rhythm),pan,.38,.004,duration*.20)
            if tier>=2 then
                event(s.material,.13+at*.48,duration*.58,s.tone*s.notes[j]*.72,
                    (.23+(tier-2)*.12)/math.sqrt(#s.rhythm),-pan,.62,.012,duration*.27)
            end
            if tier==3 then
                event(s.material,.32+at*.60,duration*.48,s.tone*s.notes[j]*1.5,
                    .24/math.sqrt(#s.rhythm),pan,.48,.016,duration*.32)
            end
        end
    elseif kind=="charge" then
        event("body",0,duration,s.body*1.2,.17+(tier-1)*.055,0,1.35,.016,duration*4,true)
        event(s.material,0,duration,s.tone*.5,.40+(tier-1)*.08,-.32,1.45+(tier-1)*.25,.012,duration*3,true)
        local span=s.rhythm[#s.rhythm]+.07
        for j,at in ipairs(s.rhythm) do
            local start=duration*(.06+at/span*.65)
            event(s.material,start,duration*.28,s.tone*s.notes[j]*.6,.74/math.sqrt(#s.rhythm),
                j%2==0 and .60 or -.60,1.25,.004,duration*.22,true)
            if tier==3 then
                event(s.material,duration*(.60+at/span*.24),duration*.16,s.tone*s.notes[j]*.8,
                    .29/math.sqrt(#s.rhythm),j%2==0 and -.48 or .48,1.40,.002,duration*.12,true)
            end
        end
    else
        event(s.material,0,.15,s.tone,.60,.18,1.08,.001,.035)
        event("body",0,.09,s.body*1.5,.16,0,.65,.001,.022)
    end
    local dryL,dryR={},{}
    local peak=0
    for i=1,count do
        dryL[i],dryR[i]=left[i],right[i]
        local wet=impact and (tier==3 and .20 or tier==2 and .11 or .035) or .10
        local l=left[i]+(dryR[i-1184] or 0)*wet+(dryL[i-2784] or 0)*wet*.55
        local r=right[i]+(dryL[i-1504] or 0)*wet+(dryR[i-3552] or 0)*wet*.55
        if impact and tier==3 then
            l=l+(dryR[i-6592] or 0)*.12+(dryL[i-10016] or 0)*.075
            r=r+(dryL[i-7488] or 0)*.12+(dryR[i-11328] or 0)*.075
        end
        if kind=="charge" then
            local p=(i-1)/math.max(1,count-1)
            local center,side=(l+r)*.5,(l-r)*.5
            local aperture=tier==3 and (.025+1.4*(1-p)^1.3) or 1-p*(tier==2 and .80 or .35)
            local pressure=.18+.82*p^(tier==3 and 1.8 or tier==2 and 1.3 or .9)
            l,r=(center+side*aperture)*pressure,(center-side*aperture)*pressure
        elseif kind=="release" then
            local opening=math.min(1,(i-1)/(rate*.026))
            local center,side=(l+r)*.5,(l-r)*.5
            l,r=center+side*opening,center-side*opening
        end
        local contact=impact and 1+((tier-1)*.30+(boss and .18 or 0))*exp(-((i/rate-.055)/.12)^2) or 1
        if boss then contact=contact*(1+(.60+(tier-1)*.30)*math.min(1,math.max(0,(i/rate-.55)/.25))) end
        l,r=l*contact,r*contact
        local edge=math.min(1,(i-1)/20,(count-i)/384)
        local compression=impact and ((s.density and s.density[tier] or .18+(tier-1)*.18)
            +(fracture and .10 or 0)+(finish and .16 or 0)+(boss and (.25+(tier-1)*.20) or 0)) or .22
        left[i]=l/(1+compression*abs(l))*edge
        right[i]=r/(1+compression*abs(r))*edge
        peak=math.max(peak,abs(left[i]),abs(right[i]))
    end
    local ceiling=impact and (.70+(tier-1)*.04) or kind=="charge" and (.46+(tier-1)*.08)
        or kind=="release" and (.60+(tier-1)*.08) or kind=="miss" and ({.44,.58,.70})[tier] or .62
    local data=love.sound.newSoundData(count,rate,16,2)
    local gain=ceiling/math.max(.001,peak)
    for i=1,count do data:setSample(i-1,1,left[i]*gain);data:setSample(i-1,2,right[i]*gain) end
    return data,{gain=impact and math.min(1,.86+(tier-1)*.06+(finish and .02 or 0)) or kind=="charge" and (tier==3 and .73 or tier==2 and .63 or .48)
            or kind=="release" and (.54+(tier-1)*.11) or kind=="miss" and ({.48,.64,.80})[tier] or .35,
        priority=impact and 5 or kind=="release" and 4 or kind=="miss" and 4 or kind=="charge" and tier>=2 and 4 or 3,
        cooldown=kind=="beat" and .035 or .06,peak=ceiling,maxPitch=(kind=="charge" or kind=="release") and 4 or nil,
        duck=kind=="miss" and .80 or impact and (boss and (tier==3 and .14 or tier==2 and .30 or .46)
            or tier==3 and (finish and .22 or fracture and .25 or .30) or tier==2 and .46 or .62)
            or kind=="release" and (tier==3 and .38 or tier==2 and .55 or .75)
            or kind=="charge" and tier>=2 and (tier==3 and .72 or .84) or nil,
        bossVictory=boss and 1 or nil,
        duckDuration=kind=="miss" and .09 or impact and (boss and (tier==3 and 3.90 or tier==2 and 2.70 or 1.80)
            or tier==3 and (finish and .55 or fracture and .42 or .34) or tier==2 and .21 or .12)
            or kind=="release" and .10 or kind=="charge" and duration or nil}
end

function A.register(sound,forceRender)
    if not love or not love.sound or not love.sound.newSoundData then return end
    local baked=not forceRender and require("config.attack_outcome_audio") or {}
    for index,id in ipairs(C.order) do
        if C.hands[id].ready then
            local score=assert(A.profiles[id],"Missing attack score: "..id)
            for _,kind in ipairs({"charge","release","beat","impact","armor_break","finisher","armored_finisher","boss_finisher","boss_armored_finisher","miss"}) do
                for tier=1,kind=="beat" and 1 or 3 do
                    local suffix=tier==2 and "_strong" or tier==3 and "_extreme" or ""
                    local name="nen_"..id.."_"..kind..suffix
                    local registered=false
                    if baked[name] and sound.registerFileCue then
                        local path=require("src.runtime_assets").audio(baked[name].path)
                        if love.filesystem and love.filesystem.getInfo(path) then
                            sound.registerFileCue(name,baked[name]);registered=true
                        end
                    end
                    if not registered then
                    local data,cue
                    if baked[name] then
                        local ok,decoded=pcall(love.sound.newSoundData,require("src.runtime_assets").audio(baked[name].path))
                        if ok then data,cue=decoded,baked[name] end
                    end
                    if not data then data,cue=render(score,kind,tier,index) end
                    sound.registerProcedural(name,data,cue)
                    if data.release then data:release() end
                    end
                end
            end
        end
    end
end
return A

-- Original reward scores: rarity changes material and cadence, not just pitch.
local A={order={},root=196}
for i,r in ipairs(require("src.deities").RARITIES) do A.order[i]=r.id end
local patterns={{1},{1,1.5},{1,1.25,1.5},{1,1.189,1.5,2},{1,1.25,1.5,2,3},
    {1,1.5,1.25,2,1.5},{1,1.122,1.5,2,2.244},{1,1.333,1.5,2.667},
    {1,1.25,2,1.5,2.5,3},{1,1.25,1.5,2,2.5,3,4}}
function A.rarity(reward)
    local id=reward and (reward.rarity or reward.item and reward.item.rarity or reward.card and reward.card.rarity)
    for level,key in ipairs(A.order) do if key==id then return key,level end end
    return "common",1
end
function A.cue(phase,reward) return "reward_"..phase.."_"..A.rarity(reward) end
function A.play(phase,reward,pitch)
    local sound=require("src.sound")
    if sound.prepareRewards then sound.prepareRewards(A.rarity(reward)) end
    return sound.play(A.cue(phase,reward),pitch or 1)
end
function A.register(sound)
    if not love or not love.sound or not love.sound.newSoundData then return end
    if sound.registerFileCue and love.filesystem then
        local ok,baked=pcall(require,"config.reward_audio_baked")
        local complete=ok
        if ok then for _,cue in pairs(baked) do
            if not love.filesystem.getInfo(require("src.runtime_assets").audio(cue.path)) then complete=false;break end
        end end
        if complete then for name,cue in pairs(baked) do sound.registerFileCue(name,cue) end;return end
    end
    local rate,tau=32000,math.pi*2
    for level,id in ipairs(A.order) do for phaseIndex,phase in ipairs({"charge","open","receive","collect"}) do
        local charging=phase=="charge"
        local duration=charging and 1.2 or (phase=="open" and .65 or phase=="collect" and .36 or .50)+level*.105
        local count=math.floor(duration*rate)
        local l,r={},{};for i=1,count do l[i],r[i]=0,0 end
        local notes=patterns[level]
        local function tone(at,length,f,amp,pan,metal,slow)
            local start=math.floor(at*rate)
            for i=0,math.min(math.floor(length*rate),count-start)-1 do
                local t=i/rate
                local envelope=(1-math.exp(-t/(slow and .035 or .004)))*math.exp(-t/(length*(slow and .42 or .18)))
                    *math.min(1,(length-t)*rate/128)
                local a=tau*f*t
                local v=(math.sin(a+.012*math.sin(t*27))
                    +.30*math.sin(a*(metal and 2.756 or 2.003))*math.exp(-t*7)
                    +.16*math.sin(a*(metal and 5.404 or 3.009))*math.exp(-t*18)
                    +.07*math.sin(a*(metal and 8.933 or 4.013))*math.exp(-t*32))*envelope*amp
                local pos=start+i+1
                l[pos]=l[pos]+v*math.sqrt(1-pan);r[pos]=r[pos]+v*math.sqrt(1+pan)
            end
        end
        local seed=level*7919+phaseIndex*1009
        local low,air=0,0
        for i=1,count do
            local t=(i-1)/rate
            seed=seed*48271%2147483647
            local n=seed/1073741823.5-1
            low=low+(n-low)*.025;air=air+(n-air)*.30
            local envelope=charging and (.16+.84*t/duration)*(1-math.exp(-t/.02))
                or math.exp(-t/(phase=="open" and .065 or .022))
            local wood=(low*2+air*.45)*envelope*(phase=="open" and .85 or .28)
            if not charging then
                -- A latch, lid and settling metal precede the rarity's musical answer.
                local at=phase=="open" and .052 or phase=="collect" and .012 or .028
                local u=math.max(0,t-at)
                local contact=(1-math.exp(-u*1800))*math.exp(-u/(phase=="open" and .045 or .018))
                wood=wood+((n-air)*.22+low*.8+math.sin(tau*165*u)*.20)*contact
            end
            l[i],r[i]=wood,wood
        end
        for j,note in ipairs(notes) do
            local at=charging and (j-1)*.034 or .028+(j-1)*(level<=2 and .065 or level>=8 and .052 or .045)
            local f=A.root*note*(phase=="collect" and 1.5 or 1)
            local pan=(j%2==0 and 1 or -1)*math.min(.80,.14+level*.065)
            tone(at,charging and 1.1 or duration-at,f,(.44+level*.055)/math.sqrt(#notes),pan,level==2 or level==5,charging or level>=4)
            if level>=3 then tone(at+.025,duration-at-.025,f*2,.13+level*.012,-pan,false,true) end
        end
        if level>=4 then
            tone(charging and 0 or .14,duration-.14,A.root*.5,.23+level*.025,0,false,true)
            tone(charging and .04 or .26,duration-.26,A.root*(level==4 and 1.1892 or level==6 and 1.4983 or 2),
                .10+level*.015,.50,false,true)
        end
        local peak=0
        for i=1,count do
            local edge=math.min(1,(i-1)/24,(count-i)/400)
            local a,b=l[i],r[i]
            l[i]=(a+(r[i-1984] or 0)*.035)/(1+.35*math.abs(a))*edge
            r[i]=(b+(l[i-2528] or 0)*.035)/(1+.35*math.abs(b))*edge
            peak=math.max(peak,math.abs(l[i]),math.abs(r[i]))
        end
        peak=require("src.audio_finish").apply(l,r,rate)
        local ceiling=charging and .32 or .45+level*.025
        local data=love.sound.newSoundData(count,rate,16,2)
        for i=1,count do data:setSample(i-1,1,l[i]*ceiling/peak);data:setSample(i-1,2,r[i]*ceiling/peak) end
        sound.registerProcedural(A.cue(phase,{rarity=id}),data,{gain=charging and .14 or .25+level*.012,
            peak=ceiling,priority=charging and 3 or level>=3 and 4 or 3,cooldown=.035,
            duck=charging and .96 or .90,duckDuration=charging and .08 or .12})
        data:release()
    end end
end
return A

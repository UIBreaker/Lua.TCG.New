if not love or not love.sound or not love.sound.newSoundData then return true end
local count,fingerprints,impacts,charges,releases=0,{},{},{},{}
local outcomes={armor_break={},finisher={},armored_finisher={},boss_finisher={},boss_armored_finisher={}}
local baked=require("config.attack_outcome_audio")
local bakedCount=0
local victories={}
local signalProblems={}
require("src.nen_audio").register({registerProcedural=function(name,data,cue)
    assert(name:match("^nen_.*_.*$") and cue.gain>0 and cue.gain<=1)
    assert(data:getChannelCount()==2 and data:getSampleRate()==32000,"stereo Nen at 32kHz")
    local peak,energy,signature,width,early,total,late,side=0,0,0,0,0,0,0,0
    local bins={};for i=1,24 do bins[i]=0 end
    local low,mid,bands=0,0,{0,0,0}
    local first,last,firstSide,lastSide=0,0,0,0
    local firstCount,lastCount=0,0
    local level=name:match("_extreme$") and 3 or name:match("_strong$") and 2 or 1
    local victoryAt=.65+(level-1)*.45
    local victoryBins={};for i=1,30 do victoryBins[i]=0 end
    local victoryEnergy,joinEnergy=0,0
    local victoryLow,victoryMid,victoryBands=0,0,{0,0,0}
    for i=0,data:getSampleCount()-1 do
        local value=data:getSample(i,1)
        local right=data:getSample(i,2)
        peak=math.max(peak,math.abs(value),math.abs(right));energy=energy+value*value
        width=width+math.abs(value-right)
        local power=(value*value+right*right)*.5
        total=total+power;side=side+(value-right)^2*.25
        if i<data:getSampleCount()*.25 then
            first=first+power;firstSide=firstSide+(value-right)^2*.25;firstCount=firstCount+1
        elseif i>=data:getSampleCount()*.65 and i<data:getSampleCount()*.92 then
            last=last+power;lastSide=lastSide+(value-right)^2*.25;lastCount=lastCount+1
        end
        if i>=32000*.36 then late=late+power end
        if cue.bossVictory==1 then
            if i>=32000*victoryAt and i<32000*(victoryAt+2.4) then
                local bin=math.floor((i/32000-victoryAt)/.08)+1
                victoryBins[bin]=victoryBins[bin]+power
                victoryEnergy=victoryEnergy+power
                local mono=(value+right)*.5
                victoryLow=victoryLow+(mono-victoryLow)*.04
                victoryMid=victoryMid+(mono-victoryMid)*.18
                victoryBands[1]=victoryBands[1]+victoryLow^2
                victoryBands[2]=victoryBands[2]+(victoryMid-victoryLow)^2
                victoryBands[3]=victoryBands[3]+(mono-victoryMid)^2
            end
            if i>=32000*(victoryAt-.04) and i<32000*(victoryAt+.04) then joinEnergy=joinEnergy+power end
        end
        if i<32000*.16 then early=early+(value*value+right*right)*.5 end
        local mono=(value+right)*.5
        if i<32000*.72 then
            local bin=math.floor(i/(32000*.03))+1
            bins[bin]=bins[bin]+mono*mono
            low=low+(mono-low)*.04;mid=mid+(mono-mid)*.18
            bands[1]=bands[1]+low*low
            bands[2]=bands[2]+(mid-low)^2
            bands[3]=bands[3]+(mono-mid)^2
        end
        if i%127==0 then signature=signature+value*(i+1) end
    end
    assert(peak>.05 and peak<=cue.peak+.001 and cue.peak<=.781 and energy/data:getSampleCount()>.0001,name.." silence / clipping")
    assert(width>.1,"material must retain stereo depth")
    for _,i in ipairs({0,data:getSampleCount()-1}) do assert(data:getSample(i,1)==0 and data:getSample(i,2)==0,"click-free edges") end
    local key=string.format("%.3f",signature)
    assert(not fingerprints[key],name.." duplicates "..tostring(fingerprints[key]));fingerprints[key]=name
    local sum=0;for _,v in ipairs(bins) do sum=sum+v end
    local bandTotal=bands[1]+bands[2]+bands[3]
    local features={}
    for i,v in ipairs(bins) do features[i]=v/math.max(.00001,sum) end
    for i,v in ipairs(bands) do features[#bins+i]=v/math.max(.00001,bandTotal) end
    local charge=name:match("^nen_(.-)_charge")
    local release=name:match("^nen_(.-)_release")
    if charge then
        charges[charge]=charges[charge] or {}
        charges[charge][level]={duration=data:getSampleCount()/32000,rise=math.sqrt(last/lastCount)/math.sqrt(first/firstCount),
            startWidth=firstSide/math.max(.00001,first),endWidth=lastSide/math.max(.00001,last),
            rms=math.sqrt(total/data:getSampleCount())*cue.gain,features=features}
    end
    if release then
        releases[release]=releases[release] or {}
        releases[release][level]={rms=math.sqrt(early/(32000*.16))*cue.gain,total=total*cue.gain^2,
            width=side/math.max(.00001,total),duration=data:getSampleCount()/32000,features=features}
    end
    local id=name:match("^nen_(.-)_impact")
    if id then
        impacts[id]=impacts[id] or {}
        local tier=name:match("_extreme$") and 3 or name:match("_strong$") and 2 or 1
        local rms=math.sqrt(early/(32000*.16))*cue.gain
        assert(rms>.045,name.." must carry an audible contact body")
        impacts[id][tier]={rms=rms,features=features,duration=data:getSampleCount()/32000,
            total=total*cue.gain^2,late=late*cue.gain^2,width=side/math.max(.00001,total)}
    end
    for kind,bank in pairs(outcomes) do
        local hand=name:match("^nen_(.-)_"..kind)
        if hand and require("config.attack_audio")[hand] then
            bank[hand]=bank[hand] or {}
            bank[hand][level]={rms=math.sqrt(early/(32000*.16))*cue.gain,features=features,
                duration=data:getSampleCount()/32000,total=total*cue.gain^2,late=late*cue.gain^2}
            assert(cue.priority==5 and cue.duckDuration>0,"outcome must take foreground at contact")
            if kind:match("^boss_") then
                assert(cue.duck==({.46,.30,.14})[level] and cue.duckDuration==({1.80,2.70,3.90})[level],"boss verdict and victory must own their foreground window")
                assert(cue.bossVictory==1 and data:getDuration()>=victoryAt+2.19,"victory belongs to the same finishing voice")
                local joinRms=math.sqrt(joinEnergy/(32000*.08))*cue.gain
                local victoryRms=math.sqrt(victoryEnergy/(32000*2.4))*cue.gain
                if joinRms<=.008 then signalProblems[#signalProblems+1]=name..string.format(" silent gap into victory (%.3f)",joinRms) end
                if victoryRms<=.035 then signalProblems[#signalProblems+1]=name..string.format(" weak victory phrase (%.3f)",victoryRms) end
                if kind=="boss_finisher" then
                    victories[hand]=victories[hand] or {}
                    local features={}
                    for i,v in ipairs(victoryBins) do features[i]=v/math.max(.00001,victoryEnergy) end
                    local sum=victoryBands[1]+victoryBands[2]+victoryBands[3]
                    for i,v in ipairs(victoryBands) do features[#victoryBins+i]=v/math.max(.00001,sum) end
                    victories[hand][level]=features
                end
            end
        end
    end
    if baked[name] then
        local decoded=love.sound.newSoundData(baked[name].path)
        assert(decoded:getString()==data:getString(),name.." baked PCM is stale; rebuild outcomes")
        for key,value in pairs(cue) do assert(baked[name][key]==value,name.." stale mixer metadata: "..key) end
        decoded:release();bakedCount=bakedCount+1
    end
    count=count+1
end},true)
local order=require("config.nen_vfx_config").order
assert(count==#order*25)
assert(bakedCount==#order*15,"all outcome tiers must have verified baked assets")
local minimum=math.huge
local problems=signalProblems
local function check(ok,id,label,ratio)
    if not ok then problems[#problems+1]=id.." "..label..(ratio and string.format(" (%.3f)",ratio) or "") end
end
for i,id in ipairs(order) do
    local tiers=assert(impacts[id])
    local charge,release=assert(charges[id]),assert(releases[id])
    for tier=1,3 do
        local timing=require("config.nen_vfx_config").timing[tier]
        local expected=timing[3]+timing[4]+timing[5]
        assert(math.abs(charge[tier].duration-expected)<1/32000+.000001,id.." windup must meet the launch cue")
        check(charge[tier].rise>(tier==3 and 2.5 or tier==2 and 2 or 1.4),id,"charge must crescendo",charge[tier].rise)
        if tier==3 then check(charge[tier].endWidth<charge[tier].startWidth*.35,id,"extreme pressure must close the stereo field") end
        if tier>1 then
            check(charge[tier].rms>charge[tier-1].rms*1.08,id,"tier "..tier.." needs a denser windup",charge[tier].rms/charge[tier-1].rms)
            check(release[tier].rms>release[tier-1].rms*1.10,id,"higher tier needs a stronger launch",release[tier].rms/release[tier-1].rms)
            assert(release[tier].duration>release[tier-1].duration+.06,id.." launch tiers need distinct durations")
        end
    end
    check(tiers[2].rms>tiers[1].rms*1.08,id,"strong contact needs more weight",tiers[2].rms/tiers[1].rms)
    check(tiers[3].rms>tiers[2].rms*1.10,id,"extreme contact needs more weight",tiers[3].rms/tiers[2].rms)
    assert(tiers[2].duration>=tiers[1].duration+.19 and tiers[3].duration>=tiers[2].duration+.51,id.." tier scale must have distinct duration")
    check(tiers[2].total>tiers[1].total*1.30,id,"strong gesture needs more energy",tiers[2].total/tiers[1].total)
    check(tiers[3].total>tiers[2].total*1.40,id,"extreme gesture needs a grander body",tiers[3].total/tiers[2].total)
    check(tiers[3].late>tiers[2].late*2,id,"extreme needs an audible material aftershock",tiers[3].late/tiers[2].late)
    check(tiers[3].width>tiers[1].width*1.4,id,"extreme must open the stereo field",tiers[3].width/tiers[1].width)
    for kind,bank in pairs(outcomes) do
        local gesture=assert(bank[id],kind.." missing "..id)
        for tier=1,3 do
            local g=gesture[tier]
            assert(g.duration>tiers[tier].duration+.10,kind.." needs its own aftermath")
            local difference=0
            for k,v in ipairs(g.features) do difference=difference+(v-tiers[tier].features[k])^2 end
            check(math.sqrt(difference)>.012,id,kind.." must be distinct from a normal contact",math.sqrt(difference))
            if tier>1 then
                check(g.rms>gesture[tier-1].rms*1.06,id,kind.." tier "..tier.." needs more contact weight",g.rms/gesture[tier-1].rms)
                check(g.total>gesture[tier-1].total*1.20,id,kind.." needs more total energy",g.total/gesture[tier-1].total)
            end
        end
        check(gesture[3].late>gesture[2].late*1.7,id,kind.." extreme needs a longer material collapse",gesture[3].late/gesture[2].late)
    end
    for _,kinds in ipairs({{"boss_finisher","finisher"},{"boss_armored_finisher","armored_finisher"}}) do
        for tier=1,3 do
            local boss,ordinary=outcomes[kinds[1]][id][tier],outcomes[kinds[2]][id][tier]
            local difference=0
            for k,v in ipairs(boss.features) do difference=difference+(v-ordinary.features[k])^2 end
            check(math.sqrt(difference)>.020,id,kinds[1].." needs its own verdict",math.sqrt(difference))
            check(boss.total>ordinary.total*1.15,id,kinds[1].." tier "..tier.." needs a grander finish",boss.total/ordinary.total)
            check(boss.rms>ordinary.rms*.90,id,kinds[1].." must keep the first hit solid",boss.rms/ordinary.rms)
            assert(boss.duration>=ordinary.duration+({.299,.649,.999})[tier],"boss tiers need their own ending")
        end
    end
    for j=1,i-1 do
        for tier=1,3 do
            local other=impacts[order[j]][tier].features
            local distance=0
            for k,v in ipairs(tiers[tier].features) do distance=distance+(v-other[k])^2 end
            distance=math.sqrt(distance);minimum=math.min(minimum,distance)
            assert(distance>.025,id.." and "..order[j].." lose identity at tier "..tier)
            for _,bank in ipairs({charges,releases}) do
                local gesture=0
                for k,v in ipairs(bank[id][tier].features) do gesture=gesture+(v-bank[order[j]][tier].features[k])^2 end
                check(math.sqrt(gesture)>.015,id,(bank==charges and "charge" or "release").." loses identity against "..order[j].." at tier "..tier,math.sqrt(gesture))
            end
            for kind,bank in pairs(outcomes) do
                local gesture=0
                for k,v in ipairs(bank[id][tier].features) do gesture=gesture+(v-bank[order[j]][tier].features[k])^2 end
                check(math.sqrt(gesture)>.025,id,kind.." loses identity against "..order[j].." at tier "..tier,math.sqrt(gesture))
            end
            local victoryDistance=0
            for k,v in ipairs(victories[id][tier]) do victoryDistance=victoryDistance+(v-victories[order[j]][tier][k])^2 end
            check(math.sqrt(victoryDistance)>.012,id,"victory loses its identity against "..order[j].." at tier "..tier,math.sqrt(victoryDistance))
        end
    end
end
assert(#problems==0,table.concat(problems,"\n"))
print(string.format("NEN audio: %d authored cues / 27 hands / 3 full attack and armor/finisher tiers / timed crescendo, stereo, outcome identity, peak and edges passed; minimum impact feature distance %.3f",count,minimum))
return true

local A=require("src.reward_audio")
local count,signatures,banks=0,{},{}
A.register({registerProcedural=function(name,data,cue)
    local phase,id=name:match("^reward_(.-)_([^_]+)$")
    local peak,energy,width,signature=0,0,0,0
    local bins={};for i=1,24 do bins[i]=0 end
    local low,mid,bands=0,0,{0,0,0}
    for i=0,data:getSampleCount()-1 do
        local l,r=data:getSample(i,1),data:getSample(i,2)
        peak=math.max(peak,math.abs(l),math.abs(r));energy=energy+(l*l+r*r)*.5
        width=width+math.abs(l-r)
        local bin=math.min(24,math.floor(i/(32000*.05))+1)
        bins[bin]=bins[bin]+(l*l+r*r)*.5
        local mono=(l+r)*.5
        low=low+(mono-low)*.04;mid=mid+(mono-mid)*.18
        bands[1]=bands[1]+low^2;bands[2]=bands[2]+(mid-low)^2;bands[3]=bands[3]+(mono-mid)^2
        if i%113==0 then signature=signature+l*(i+1) end
    end
    assert(data:getChannelCount()==2 and data:getSampleRate()==32000)
    assert(peak>.20 and peak<=cue.peak+.001 and cue.peak<=.701 and energy/data:getSampleCount()>.0001,name)
    assert(width>.1,"reward must retain stereo depth")
    for _,i in ipairs({0,data:getSampleCount()-1}) do assert(data:getSample(i,1)==0 and data:getSample(i,2)==0,"clean reward edges") end
    local key=string.format("%.3f",signature);assert(not signatures[key],"duplicate rarity PCM");signatures[key]=name
    local bandTotal=bands[1]+bands[2]+bands[3]
    local features={};for i,v in ipairs(bins) do features[i]=v/energy end
    for i,v in ipairs(bands) do features[#bins+i]=v/bandTotal end
    banks[phase]=banks[phase] or {};banks[phase][id]={features=features,energy=energy,gain=cue.gain,duration=data:getDuration()}
    count=count+1
end})
assert(count==#A.order*4)
for phase,bank in pairs(banks) do
    for i,id in ipairs(A.order) do
        local x=bank[id]
        if i>1 and phase~="charge" then assert(x.duration>bank[A.order[i-1]].duration+.10,"rarity must alter the arrangement length") end
        for j=1,i-1 do
            local y=bank[A.order[j]];local d=0
            for k,v in ipairs(x.features) do d=d+(v-y.features[k])^2 end
            assert(math.sqrt(d)>.012,phase..": "..id.." and "..A.order[j].." lose their identity")
        end
    end
end
print("Reward PCM PASS: "..count.." stereo cues / 10 rarities / charge-open-receive-collect / distinct cadence, peak and edges")
return true

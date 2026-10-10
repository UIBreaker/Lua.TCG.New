if not love or not love.sound or not love.sound.newSoundData then return true end
local count,fingerprints=0,{}
require("src.nen_audio").register({registerProcedural=function(name,data,cue)
    assert(name:match("^nen_.*_.*$") and cue.gain>0 and cue.gain<=1)
    local peak,energy,signature=0,0,0
    for i=0,data:getSampleCount()-1 do
        local value=data:getSample(i);peak=math.max(peak,math.abs(value));energy=energy+value*value
        if i%127==0 then signature=signature+value*(i+1) end
    end
    assert(peak>.05 and peak<=.781 and energy/data:getSampleCount()>.0001,name.." silence / clipping")
    local key=string.format("%.3f",signature)
    assert(not fingerprints[key],name.." duplicates "..tostring(fingerprints[key]));fingerprints[key]=name
    count=count+1
end})
assert(count==#require("config.nen_vfx_config").order*4)
print("NEN audio: "..count.." distinct original PCM cues / audible energy / peak headroom passed")
return true

local Finish=require("src.audio_finish")
local function energy(f)
    local l,r={},{}
    for i=1,32000 do
        local x=math.sin(2*math.pi*f*(i-1)/32000)
        l[i],r[i]=x,x
    end
    local peak=Finish.apply(l,r,32000)
    local sum=0
    for i=1,#l do
        assert(l[i]==r[i] and l[i]==l[i],"centered sound must remain centered and finite")
        sum=sum+l[i]^2
    end
    assert(l[1]==0 and l[#l]==0 and peak>0,"clean edges and usable normalization peak")
    return sum/#l
end
local mid=energy(440)
assert(energy(7000)<mid*.025,"brittle highs must be attenuated before baking")
assert(energy(20)<mid*.13,"sustained sub-rumble must be attenuated")
assert(mid>.35,"paper and relic midrange must remain readable")
print("Quiet audio finish PASS: softened highs, controlled sub-bass, centered image and clean edges")
return true

local M=require("src.miss_feedback")
local graphics=love and love.graphics
love=love or {}
local depth,calls=0,0
love.graphics={push=function() depth=depth+1 end,pop=function() depth=depth-1 end,
    setShader=function() end,setBlendMode=function() end,setColor=function(...) for _,v in ipairs({...}) do assert(v==v) end end,
    setLineWidth=function(w) assert(w>0) end,transformPoint=function(x,y) return x,y end,
    intersectScissor=function() end,line=function(...)
        local points=type((...))=="table" and (...) or {...}
        for _,v in ipairs(points) do assert(v==v and math.abs(v)<10000,"finite miss ribbon") end
        calls=calls+1
    end}
local count=0
for _,id in ipairs(require("config.nen_vfx_config").order) do for tier=1,3 do
    for _,quality in ipairs({"low","medium","high"}) do for _,reduced in ipairs({false,true}) do
        local a={profile={id=id},cx=635,color={.3,.7,1},quality=quality,nen={tier=tier,reducedMotion=reduced}}
        local duration=M.duration(a)
        for _,age in ipairs({0,.03,.12,.28,duration-.01,duration,duration+.2}) do
            calls=0;M.draw(a,age)
            assert(depth==0 and calls<=30 and a.nen.particleCount<=(quality=="low" and 4 or 4+tier*2),"bounded, isolated miss drawing")
            local x,scale,flash=M.pose(a,age)
            assert(math.abs(x)<=24 and scale==1 and flash==0,"a dodge must not resemble a hit reaction")
            if reduced or age>=duration then assert(math.abs(x)<.00001) end
            if age>=duration then assert(calls==0 and a.nen.particleCount==0,"no residue after a miss") end
            count=count+1
        end
        a.nen.cancelled=true;calls=0;M.draw(a,.10);assert(calls==0 and depth==0)
    end end
end end
love.graphics=graphics
print("Miss VFX PASS: "..count.." hand/tier/quality/age/reduced-motion cases; bounded trails, dodge without hit flash, cleanup and cancellation")
return true

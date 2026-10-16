-- lua tests/death_vfx_smoke.lua: presentation timing without a graphics context.
local sounds,kicks={},0
package.loaded["src.sound"]={play=function(name) sounds[name]=(sounds[name] or 0)+1 end}
package.loaded["render.camera"]={kick=function() kicks=kicks+1 end}
package.loaded["render.lighting"]={flash=function() end}
package.loaded["src.enemy_art"]={}
local D=require("src.death_vfx")
for i=1,D.config.particles.max do D.pool[i]={} end
local function simulate(fps,reduced,quality)
    D.reset();sounds={};kicks=0;D.startPlayer(640,quality or "HIGH",reduced)
    for _=1,fps do D.update(1/fps) end
    assert(D.busy() and D.burst and D.ambience and not D.text)
    assert(D.count<=D.config.particles[quality or "HIGH"])
    local positions={}
    for i=1,D.count do positions[i]={D.pool[i].x,D.pool[i].y} end
    return positions
end
local slow=simulate(30,false)
local fast=simulate(144,false)
for i=1,#slow do
    assert(math.abs(slow[i][1]-fast[i][1])<0.000001,"horizontal trajectory changed with FPS")
    assert(math.abs(slow[i][2]-fast[i][2])<0.000001,"vertical trajectory changed with FPS")
end
local normalDistance=math.abs(D.pool[1].y-D.pool[1].oy)
simulate(60,true)
assert(kicks==0 and D.reducedMotion)
assert(math.abs(D.pool[1].y-D.pool[1].oy)<normalDistance*0.25)
for _,quality in ipairs({"LOW","MEDIUM","HIGH"}) do
    simulate(60,false,quality)
    assert(kicks==1)
    local lastInfo,lastUI=0,0
    for _=1,180 do
        D.update(1/60)
        local info,ui=D.infoProgress(),D.uiProgress()
        assert(info>=lastInfo and ui>=lastUI and info>=ui,"reveal order must be monotonic")
        lastInfo,lastUI=info,ui
    end
    assert(not D.busy() and D.cardProgress()==1 and lastInfo==1 and lastUI==1)
    for _,name in ipairs({"defeat_hit","defeat_collapse","defeat_ambience","defeat_text_reveal"}) do
        assert(sounds[name]==1,name.." must play once")
    end
end
assert(D.clock>D.duration,"settled dust clock must continue")
D.reset();assert(not D.busy() and D.infoProgress()==1 and D.uiProgress()==1)
print("Death VFX timing / frame independence / reduced motion / quality PASS")

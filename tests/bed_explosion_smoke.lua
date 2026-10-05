local E=require("src.bed_explosion")
local C=E.config
local sounds={}
package.loaded["src.sound"]={play=function(name) sounds[#sounds+1]={name=name,age=E.age} end}
local trials=0
local rng=require("src.rng");local rngBefore=rng.getState()
for _,quality in ipairs({"LOW","MEDIUM","HIGH"}) do
 for _,fps in ipairs({30,60,144}) do
  for repeatIndex=1,10 do
   sounds={};local identities={};for i,p in ipairs(E.pool) do identities[i]=p end
   E.start(635,410,quality,{rain=repeatIndex%2},1)
   assert(E.count<=64 and E.debrisCount==C.quality[quality].large+C.quality[quality].medium+C.quality[quality].small)
   local impact=0;local dt=1/fps
   while E.active do
    E.update(dt)
    if E.age<C.anticipation then assert(not E.detonated and not E.takeImpact()) end
    if E.takeImpact() then impact=impact+1;assert(E.age>=C.anticipation and E.age<C.anticipation+dt+.00001) end
    if E.active then
     local radius,strength=E.wave();assert(radius<=C.shockwave.radius+.001)
     if quality=="LOW" then assert(strength==0) end
     for i=1,E.count do local p=E.pool[i];assert(p==identities[i]);assert(p.x==p.x and p.y==p.y)
      if p.kind=="debris" then assert(p.bounceCount<=1 and p.y<=p.floor+.001) end
     end
    end
   end
   assert(impact==1 and #sounds==4)
   assert(sounds[1].name=="bed_explosion_charge" and sounds[2].name=="bed_explosion_boom")
   assert(sounds[2].age>=C.anticipation and sounds[4].age>=C.anticipation+.15)
   trials=trials+1
  end
 end
end
assert(rngBefore==rng.getState(),"VFX must not consume gameplay RNG")
E.start(635,410,"HIGH");E.update(.5);assert(E.active and E.detonated and E.age==C.anticipation and E.takeImpact(),"slow frame cannot skip contact")
E.clear()
E.debug=true;E.keypressed("c");E.keypressed("v");E.keypressed("]");E.keypressed("=");E.keypressed("b")
assert(E.active and not E.shake and not E.distortion and E.count<=64)
E.clear();E.shake=true;E.distortion=true;E.debug=false;E.debrisBias=0;E.radiusScale=1
print("Bed explosion: "..trials.." repeats / 3 qualities / 30,60,144 FPS / single contact / audio ordering / bounded reused pool / one bounce passed")

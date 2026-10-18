local P=require("src.card_physics")
local T={}
function T.verify()
 local g=love.graphics
 g.push("all");g.origin()
 local draw=P.wrap(function(card,x,y,w,h) g.setColor(.3,.5,.6,1);g.rectangle("fill",x,y,w,h) end)
 local heldX
 for _,fps in ipairs({30,60,120,144}) do
  for _,reduced in ipairs({false,true}) do
   for _,fast in ipairs({false,true}) do
    P.reset();P.reducedMotion=reduced;P.fast=fast
    local card={}
    local function step(x,y)
     P.update(1/fps,x,y);P.beginFrame(true);draw(card,300,150,100,150);P.endFrame()
    end
    step(-100,-100)
    for i=1,fps do step(-100,-100) end
    local s=assert(P.getState(card));P.press(345,220,1)
    for i=1,math.floor(fps*.3+.5) do step(345+i*100/fps,180) end
    assert(P.isHeld(card) and s.x>300,"drag follows the pointer")
    if fast then assert(math.abs(s.x-heldX)<1e-7,"fast mode cannot accelerate pointer tracking") else heldX=s.x end
    if reduced then assert(s.lift==0 and s.rotation==0 and s.stretch==0 and s.tiltY==0,"reduced drag translates without decorative motion") end
    local vx,vy,px,py=s.vx,s.vy,s.x,s.y
    P.release();assert(s.vx==vx and s.vy==vy and s.x==px and s.y==py,"release preserves position and momentum")
    for i=1,fps do step(-100,-100) end
    assert(not s.settling and math.abs(s.x-300)<1 and math.abs(s.y-150)<1,"return finishes in its own slot")
    P.pulse(card);step(-100,-100)
    if reduced then assert(not s.contactAge) else assert(s.contactAge>0) end
    P.reset();assert(not P.getState(card) and not P.isHolding(),"scene reset clears old geometry")
   end
  end
 end
 P.reset();P.reducedMotion=false;P.fast=false
 local Polish=require("src.ux_polish");local age,reduced=Polish.age,Polish.reducedMotion
 Polish.age=2;Polish.reducedMotion=true
 Polish.surface({},1,true,300,150,100,150,function()
  local x,y=g.transformPoint(300,150);local ex,ey=g.transformPoint(400,300)
  assert(math.abs(x-300)+math.abs(y-150)+math.abs(ex-400)+math.abs(ey-300)<1e-6,"reduced shop hover cannot add lift or scaling")
 end)
 Polish.age=age;Polish.reducedMotion=reduced;g.pop()
 print("Interaction GPU PASS: drag/return/contact/reset at four frame rates; fast pointer invariance; reduced translation only")
end
return T

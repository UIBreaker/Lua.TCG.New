local H=require("src.hand_motion")
local M=require("ui.equipment_motion")
local P=require("src.ux_polish")
local UI=require("src.ui")
local E=require("src.equipment")
local D=require("src.deck")
local function close(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." ~= "..tostring(b)) end
for _,fps in ipairs({30,60,120,144}) do
 for _,fast in ipairs({false,true}) do
  for _,reduced in ipairs({false,true}) do
   H.reset();H.fast=fast;H.reducedMotion=reduced
   local c={visualX=300,visualY=500,visualAngle=0,visualScale=1,selected=true,selectPulse=1}
   local first
   for i=1,fps do
    H.update(c,300,500,0,1/fps,false,true)
    if i==1 then first=c.visualY end
    assert(c.visualScale>0.99 and c.visualScale<1.065,"selection stays restrained")
   end
   assert(first>460 and math.abs(c.visualY-(reduced and 472 or 466))<.1)
   if reduced then close(c.visualScale,1) end
   c.selected=false
   for i=1,fps do H.update(c,300,500,0,1/fps,false,false) end
   assert(math.abs(c.visualY-500)<.1 and math.abs(c.visualScale-1)<.001)
   for _,kind in ipairs({"equip","unequip"}) do
    local card=D.newCard(7,"hearts")
    P.applications={};P.reducedMotion=reduced
    local a=P.application(UI,E.ITEMS.basic_lace,card,"ITM 0 → 1",{x=20,y=30,w=56,h=84},{x=340,y=220,w=100,h=150},kind)
    local x,y=M.position(a,0);local ex,ey=M.position(a,1)
    local from=kind=="equip" and a.source or a.rect;local to=kind=="equip" and a.rect or a.source
    close(ex,to.x+to.w/2);close(ey,to.y+to.h/2)
    if reduced then close(x,ex);close(y,ey)
    else
     close(x,from.x+from.w/2);close(y,from.y+from.h/2)
     local sx,sy=M.position(a,1e-5)
     assert(math.abs(sx-x)+math.abs(sy-y)<.001,"flight starts without a position/arc jump")
     local nx,ny=M.position(a,1-1e-5)
     assert(math.abs(nx-ex)+math.abs(ny-ey)<.001,"flight docks without a final jump")
    end
    local calls=0;a.onSettled=function() calls=calls+1 end
    for i=1,math.ceil(fps*1.5) do
     P.update(1/fps,fast,"socketing")
     if a.age<a.duration*.6 then assert(not a.hit,"contact cannot precede arrival") end
    end
    assert(a.hit and calls==1 and #P.applications==0,"completion must fire once at rest")
   end
  end
 end
end
H.fast=false;H.reducedMotion=false;P.reducedMotion=false
local owned=D.newCard(7,"hearts");local copy=D.newCard(7,"hearts");copy.id=owned.id
local game={hand={copy},persistentDeck={owned}};local before=P.snapshot(game)
assert(E.attach(owned,E.ITEMS.basic_plate))
local application=assert(P.changed(UI,game,before,E.ITEMS.basic_plate))
assert(application.target==owned and application.kind=="equip","an unchanged hand copy cannot hide an equipped deck target")
P.applications={}
print("Interaction math PASS: selection/return, exact docking, reduced motion, contact and one completion at 30/60/120/144 FPS; normal/fast")
return true

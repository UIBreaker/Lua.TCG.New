local T={};local stage=0;local waitUntil=0
local UI=require("src.ui");local P=UI.Polish;local Bag=UI.Backpack
local currentButtons
local function click(x,y)
 if x==428 and y==260 then local r=Bag.cellRect(1);x,y=r.x+r.w/2,r.y+r.h/2
 elseif x==489 and y==579 then
  local id=Bag.tab=="equipment" and "bag_equip" or "bag_detach_1"
  for _,b in ipairs(currentButtons) do if b.id==id then x,y=b.x+b.w/2,b.y+b.h/2;break end end
 end
 local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
 love.mousepressed(px,py,1);love.mousereleased(px,py,1)
end
local function step(n,delay) stage=n;waitUntil=love.timer.getTime()+(delay or .3) end
local function shot(name)
 love.graphics.captureScreenshot(function(data)
  local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
 end)
end
function T.update(g,cb)
 currentButtons=cb.getButtons()
 if love.timer.getTime()<waitUntil then return end
 if stage==0 then
  cb.startNewGame("red_deck");g.backpackEquipment={{id="basic_lace",investment=3}}
  cb.openShop();Bag.show();Bag.tab="equipment";P.applications={};step(1)
 elseif stage==1 then click(428,260);step(2)
 elseif stage==2 then click(489,579);assert(Bag.pendingItem.id=="basic_lace");step(3)
 elseif stage==3 then shot("equipment_choose_target");step(4)
 elseif stage==4 then
  click(428,260);assert(#g.persistentDeck[1].equipments==1 and #g.backpackEquipment==0)
  assert(#P.applications==1 and P.applications[1].kind=="equip" and P.applications[1].sourceItem.id=="basic_lace")
  step(5,.14)
 elseif stage==5 then shot("equipment_attach_flight");step(6,.42)
 elseif stage==6 then assert(P.applications[1].hit);shot("equipment_attached");step(7,1.6)
 elseif stage==7 then assert(#P.applications==0);click(489,579)
  assert(#g.persistentDeck[1].equipments==0 and #g.backpackEquipment==1 and P.applications[1].kind=="unequip")
  step(8,.16)
 elseif stage==8 then shot("equipment_detach_flight");step(9,.42)
 elseif stage==9 then assert(P.applications[1].hit);shot("equipment_detached");step(10,1.6)
 elseif stage==10 then
  assert(#P.applications==0 and #g.persistentDeck[1].equipments==0)
  print("Equipment feedback UI PASS: visible selection, attach flight/contact, detach return/contact, socket markers, five screenshots, expiry and exactly one mutation")
  love.event.quit(0)
 end
end
return T

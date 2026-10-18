local UI=require("src.ui")
local P=UI.CardPhysics
local Bag=UI.Backpack
local E=require("src.equipment")
local D=require("src.deck")
local Persistence=require("src.persistence")
Persistence.saveRun=function() return true end
Persistence.deleteRun=function() return true end
Persistence.saveSettings=function() return true end
local T={clock=0}
local cases={{name="normal"},{name="fast",fast=true},{name="reduced",reduced=true}}
local stage,index,started="start",0,0
local frame,nextShot=0,0
local card,pose,homeX,homeY,gold,hands,application,act
local preview=true
local record=true
for _,a in ipairs(arg or {}) do
 if a=="--no-motion-preview" then preview=false end
 local name=a:match("^%-%-interaction%-case=(.+)$")
 if name then
  local found;for _,c in ipairs(cases) do if c.name==name then found=c end end
  assert(found,"unknown interaction mode");cases={found}
 end
end
local function after(value) stage=value;started=T.clock end
local function pointer(x,y,action,shift)
 local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
 love.mouse.setPosition(px,py)
 if action=="press" then
  local down=love.keyboard.isDown
  if shift then love.keyboard.isDown=function(key,...) return key=="lshift" or key=="rshift" or down(key,...) end end
  love.mousepressed(px,py,1);love.keyboard.isDown=down
 elseif action=="release" then love.mousereleased(px,py,1)
 else love.mousemoved(px,py,0,0) end
end
local function click(x,y) pointer(x,y,"press");pointer(x,y,"release") end
local function button(cb,id)
 for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
 error("missing button "..id)
end
local function clickButton(cb,id) local b=button(cb,id);click(b.x+b.w/2,b.y+b.h/2) end
local function point(i)
 local spacing=math.min(106,(UI.BATTLE_ARENA_W-120)/7)
 local left=UI.BATTLE_ARENA_X+(UI.BATTLE_ARENA_W-(7*spacing+100))/2
 return left+(i-1)*spacing+8,536
end
local function total(g)
 local n=0;for _,c in ipairs(g.persistentDeck) do n=n+#(c.equipments or {}) end;return n
end
function T.update(game,cb)
 assert(T.clock-started<12,"interaction timeout "..stage.." / "..index)
 if preview and record and index==1 and T.clock>=nextShot then
  local path=string.format(".tmp/interaction-motion/frame_%04d.png",frame)
  love.graphics.captureScreenshot(function(data)
   local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
  end)
  frame=frame+1;nextShot=nextShot+.05
 end
 local age=T.clock-started
 if stage=="start" then
  require("tests.interaction_motion_smoke")
  require("tests.interaction_motion_render").verify()
  local update=love.update
  love.update=function(dt) local step=math.min(dt,preview and index==1 and 1/30 or .05);T.clock=T.clock+step;update(step) end
  after("case")
 elseif stage=="case" then
  index=index+1
  if not cases[index] then
   cb.setScoringSpeed(false);cb.setReducedMotion(false)
   print("Interaction runtime PASS: "..#cases.." mode(s); sweep/deselect/reorder, shop drag return, bag attach/detach, socket docking and duplicate/failure guards; "..frame.." preview frames")
   love.event.quit(0);return
  end
  cb.startNewGame("red_deck");cb.setScoringSpeed(cases[index].fast==true);cb.setReducedMotion(cases[index].reduced==true)
  game.maxHandSize=8;game.persistentDeck={}
  for i=1,12 do game.persistentDeck[i]=D.newCard(i+1,"spades") end
  cb.startMonsterEncounter(1,false);game.deities={};game.consumables={};game.unlockedHands={high_card=true,flush=true}
  gold,hands=game.gold,game.handsRemaining
  pointer(5,5);nextShot=T.clock;after("ready")
 elseif stage=="ready" and age>1.2 and not UI.HandMotion.busy(game.hand) and not UI.sceneTransitionBusy() then
  local x,y=point(1);pointer(x,y,"press");assert(game.hand[1].selected and not P.isHolding())
  after("sweep")
 elseif stage=="sweep" then
  local x,y=point(1);local tx=point(4);pointer(x+(tx-x)*math.min(1,age/.3),y)
  if age>.34 then pointer(tx,y,"release");assert(#game.selectedIndices==4,"four selected: "..#game.selectedIndices);after("selected") end
 elseif stage=="selected" and age>.45 then
  local x,y=point(4);pointer(x,y,"press");x,y=point(1);pointer(x,y);pointer(x,y,"release")
  assert(#game.selectedIndices==0);after("deselected")
 elseif stage=="deselected" and age>.4 then
  card=game.hand[2];pose=assert(P.getState(card))
  homeX,homeY=pose.ox+pose.a*pose.w*.45+pose.c*pose.h*.38,pose.oy+pose.b*pose.w*.45+pose.d*pose.h*.38
  pointer(homeX,homeY,"press",true);assert(P.isHeld(card),"shift grabs the visible face");after("reorder")
 elseif stage=="reorder" then
  local tx=point(5)+42;pointer(homeX+(tx-homeX)*math.min(1,age/.45),homeY-math.sin(math.min(1,age/.55)*math.pi)*64)
  if age>.55 then
   local vx,vy=pose.vx,pose.vy;pointer(tx,homeY,"release")
   assert(not P.isHolding() and pose.vx==vx and pose.vy==vy,"hand release retains momentum")
   assert(game.hand[5]==card and #game.selectedIndices==0,"reorder preserves identity and selection")
   pointer(5,5);after("hand_return")
  end
 elseif stage=="hand_return" and age>1 then
  assert(not pose.settling and math.abs(pose.x-pose.homeX)<2 and game.gold==gold and game.handsRemaining==hands)
  cb.openShop();after("shop")
 elseif stage=="shop" and age>1.2 and not UI.Polish.busy() and not UI.sceneTransitionBusy() then
  card=cb.getShopData().items[1];pose=assert(P.getState(card))
  homeX,homeY=pose.ox+pose.a*pose.w*.45+pose.c*pose.h*.4,pose.oy+pose.b*pose.w*.45+pose.d*pose.h*.4
  pointer(homeX,homeY,"press");assert(P.isHeld(card));after("shop_drag")
 elseif stage=="shop_drag" then
  pointer(homeX+math.sin(age*6)*100,homeY-age*100)
  if age>.55 then
   local vx,vy=pose.vx,pose.vy;pointer(15,710,"release")
   assert(not P.isHolding() and pose.vx==vx and pose.vy==vy and game.gold==gold)
   pointer(5,5);after("shop_return")
  end
 elseif stage=="shop_return" and age>1 then
  assert(not pose.settling and game.gold==gold,"return cannot buy a stock item")
  UI.Polish.clearFocus();UI.Polish.applications={}
  game.backpackEquipment={{id="basic_lace",investment=3}};Bag.show();Bag.tab="equipment";after("bag")
 elseif stage=="bag" and age>.3 then
  local r=Bag.cellRect(1);click(r.x+r.w/2,r.y+r.h/2);after("bag_selected")
 elseif stage=="bag_selected" and age>.2 then
  clickButton(cb,"bag_equip");assert(Bag.pendingItem.id=="basic_lace");after("bag_target")
 elseif stage=="bag_target" and age>.3 then
  local r=Bag.cellRect(1);click(r.x+r.w/2,r.y+r.h/2)
  assert(total(game)==1 and #game.backpackEquipment==0 and #UI.Polish.applications==1)
  application=UI.Polish.applications[1];assert(application.kind=="equip");pointer(5,5);after("bag_attach")
 elseif stage=="bag_attach" and age>2.1 then
  assert(application.hit and #UI.Polish.applications==0)
  clickButton(cb,"bag_detach_1")
  assert(total(game)==0 and #game.backpackEquipment==1 and UI.Polish.applications[1].kind=="unequip")
  assert(game.backpackEquipment[1].investment==3);pointer(5,5);after("bag_detach")
 elseif stage=="bag_detach" and age>2.1 then
  assert(#UI.Polish.applications==0 and total(game)==0)
  Bag.close();cb.openSocketing(E.ITEMS.basic_plate);after("socket")
 elseif stage=="socket" and age>.8 and not UI.sceneTransitionBusy() then
  click(320,270);assert(total(game)==1 and select(2,cb.getRunState())=="socketing","attach stays in picker")
  application=assert(UI.Polish.applications[1]);assert(application.fixedRect.x==312 and application.source.x==255)
  after("socket_flight")
 elseif stage=="socket_flight" then
  if not application.hit then assert(select(2,cb.getRunState())=="socketing","keep target visible through contact") end
  if age<.25 then
   for i=1,3 do click(455,270);clickButton(cb,"skip_socket") end
   assert(total(game)==1 and select(2,cb.getRunState())=="socketing","repeated input must not attach or leave twice")
  end
  if age>1.3 then
   assert(application.hit and select(2,cb.getRunState())=="map" and total(game)==1)
   cb.openSocketing(E.ITEMS.basic_plate);after("duplicate")
  end
 elseif stage=="duplicate" and age>.8 and not UI.sceneTransitionBusy() then
  click(320,270);assert(total(game)==1 and #UI.Polish.applications==0 and select(2,cb.getRunState())=="socketing","duplicate failure stays silent and keeps selection")
  clickButton(cb,"skip_socket");after("done")
 elseif stage=="done" and age>.6 then
  assert(select(2,cb.getRunState())=="map" and game.gold==gold and game.handsRemaining==hands)
  print("Interaction runtime PASS: "..cases[index].name.."; select/reorder/shop/bag/socket/failure; no duplicated equipment, spend or turn")
  if index==1 then record=false;cb.openSocketing(E.ITEMS.basic_stamp,"shop");after("shop_socket") else after("case") end
 elseif stage=="shop_socket" and age>.8 and not UI.sceneTransitionBusy() then
  click(455,270);assert(total(game)==2 and select(2,cb.getRunState())=="socketing");after("shop_dock")
 elseif stage=="shop_dock" and age>1.6 then
  assert(total(game)==2 and select(2,cb.getRunState())=="shop")
  cb.openSocketing(E.ITEMS.basic_bandage,"next_act");act=game.act;after("act_socket")
 elseif stage=="act_socket" and age>.8 and not UI.sceneTransitionBusy() then
  click(590,270);assert(total(game)==3);after("act_dock")
 elseif stage=="act_dock" and age>1.6 then
  assert(total(game)==3 and select(2,cb.getRunState())=="shop" and game.act==act+1,"advance the act once after docking")
  cb.setCaptureState("playing");game.consumables={{id="stored_equipment",category="stored_equipment",equipmentId="basic_lace",name="Dây Giày"}}
  after("stored_ready")
 elseif stage=="stored_ready" and age>.8 and not UI.sceneTransitionBusy() then
  UI.ExpandedInventory.callbacks.activate(1);assert(select(2,cb.getRunState())=="socketing" and #game.consumables==1)
  after("stored_socket")
 elseif stage=="stored_socket" and age>.8 and not UI.sceneTransitionBusy() then
  click(730,270);assert(total(game)==4 and #game.consumables==0 and select(2,cb.getRunState())=="socketing")
  for i=1,4 do click(865,270) end
  assert(total(game)==4);after("stored_dock")
 elseif stage=="stored_dock" and age>1.6 then
  assert(select(2,cb.getRunState())=="playing" and total(game)==4 and #game.consumables==0 and game.handsRemaining==hands)
  print("Socket return PASS: map/shop/next act/stored combat equipment; one consumption and no turn spent")
  after("case")
 end
end
return T

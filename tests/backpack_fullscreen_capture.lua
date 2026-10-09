local T={stage=0,deadline=0}
local UI=require("src.ui");local Bag=UI.Backpack;local Tree=require("ui.crafting_tree")
local B=require("src.basic_equipment");local E=require("src.equipment")
local function pointer(x,y,mouse)
 local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
 love.mouse.setPosition(px,py)
 if mouse then love.mousepressed(px,py,mouse);love.mousereleased(px,py,mouse) end
end
local function click(cb,id)
 for _,b in ipairs(cb.getButtons()) do if b.id==id then assert(not b.disabled,id);pointer(b.x+b.w/2,b.y+b.h/2,1);return end end
 error("Missing UI control "..id)
end
local function shot(name)
 pointer(2,2)
 love.graphics.captureScreenshot(function(data) local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close() end)
end
function T.update(game,cb)
 if love.timer.getTime()<T.deadline then return end
 local s=T.stage
 if s==0 then
  cb.startNewGame("red_deck");game.gold=218;game.souls=34;game.backpackEquipment={}
  for _,id in ipairs(B.basic) do B.store(game,E.ITEMS[id],E.ITEMS[id].cost) end
  game.persistentDeck={require("src.deck").newCard(7,"hearts"),require("src.deck").newCard(9,"spades"),require("src.deck").newCard(11,"diamonds")}
  cb.openShop();Bag.show();Bag.tab="equipment"
 elseif s==1 then local r=Bag.cellRect(1);pointer(r.x+r.w/2,r.y+r.h/2,1)
 elseif s==2 then shot("backpack_fullscreen_inventory")
 elseif s==3 then click(cb,"bag_view_tree");assert(Tree.id=="basic_bandage")
 elseif s==4 then shot("backpack_fullscreen_material_branches")
 elseif s==5 then click(cb,"bag_node_crafted_guard");assert(Tree.id=="crafted_guard")
 elseif s==6 then shot("backpack_fullscreen_crafting");T.gold=game.gold
 elseif s==7 then click(cb,"bag_craft_1");assert(game.gold==T.gold-4 and B.count(game,"crafted_guard")==1 and B.count(game,"basic_plate")==0 and B.count(game,"basic_bandage")==0)
 elseif s==8 then click(cb,"bag_tree_back");assert(Tree.id=="basic_bandage")
 elseif s==9 then
  click(cb,"bag_tab_craft")
  for i,r in ipairs(B.recipes) do if r.id=="void_catalyst" then Bag.recipeSelection=i;Tree.select(r.id);break end end
 elseif s==10 then shot("backpack_fullscreen_legendary")
 elseif s==11 then click(cb,"bag_tree_overview")
 elseif s==12 then click(cb,"bag_tree_fit")
 elseif s==13 then shot("backpack_fullscreen_full_tree")
 elseif s==14 then
  click(cb,"bag_tree_plus");pointer(800,390);love.wheelmoved(0,-2);assert(Tree.panY<0)
 elseif s==15 then
  click(cb,"bag_tab_equipment");local at
  for i,v in ipairs(game.backpackEquipment) do if v.id=="basic_lace" then at=i end end
  Bag.page=math.ceil(at/Bag.pageSize);T.equipmentSlot=at
 elseif s==16 then local r=Bag.cellRect(T.equipmentSlot);pointer(r.x+r.w/2,r.y+r.h/2,1)
 elseif s==17 then click(cb,"bag_equip");assert(Bag.pendingItem.id=="basic_lace")
 elseif s==18 then shot("backpack_fullscreen_equip_target")
 elseif s==19 then local r=Bag.cellRect(1);pointer(r.x+r.w/2,r.y+r.h/2,1);assert(#game.persistentDeck[1].equipments==1 and UI.Polish.applications[1].kind=="equip");T.deadline=love.timer.getTime()+.22;T.stage=20;return
 elseif s==20 then shot("backpack_fullscreen_equip_flight");T.deadline=love.timer.getTime()+.42;T.stage=21;return
 elseif s==21 then assert(UI.Polish.applications[1].hit);shot("backpack_fullscreen_equipped");T.deadline=love.timer.getTime()+1.6;T.stage=22;return
 elseif s==22 then click(cb,"bag_detach_1");assert(#game.persistentDeck[1].equipments==0 and UI.Polish.applications[1].kind=="unequip");T.deadline=love.timer.getTime()+.22;T.stage=23;return
 elseif s==23 then shot("backpack_fullscreen_unequip_flight");T.deadline=love.timer.getTime()+.42;T.stage=24;return
 elseif s==24 then assert(UI.Polish.applications[1].hit);shot("backpack_fullscreen_unequipped");T.deadline=love.timer.getTime()+1.6;T.stage=25;return
 elseif s==25 then
  local c=game.persistentDeck[1];c.maxSockets=E.SOCKET_CAP;c.allowDuplicateEquipment=true;c.equipments={}
  for _=1,E.SOCKET_CAP do assert(E.attach(c,E.ITEMS.basic_lace)) end
  Bag.selected=1
 elseif s==26 then
  local count=0;for _,b in ipairs(cb.getButtons()) do if b.id:match("^bag_detach_") then count=count+1;assert(b.x+b.w<=1280 and b.y+b.h<679) end end;assert(count==E.SOCKET_CAP)
  shot("backpack_fullscreen_all_sockets")
 elseif s==27 then click(cb,"open_pause_menu")
 elseif s==28 then click(cb,"pause_resume");assert(Bag.open)
 elseif s==29 then
  local r=Bag.cellRect(1);pointer(r.x+r.w/2,r.y+r.h/2,2);assert(cb.getInspector()==game.persistentDeck[1])
 elseif s==30 then cb.closeInspector()
 elseif s==31 then
  click(cb,"bag_close");assert(not Bag.open)
  print("Full-screen backpack UI PASS: inventory, material branches, recipe selection/crafting/back, legendary ancestry/zoom/scroll, equip/unequip flight/contact, all eight detach controls, pause/resume, right-click inspector and close")
  love.event.quit(0)
 end
 T.stage=s+1;T.deadline=love.timer.getTime()+(s==0 and 1.8 or .3)
end
return T

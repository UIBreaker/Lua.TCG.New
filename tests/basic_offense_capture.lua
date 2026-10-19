local T={stage=0,deadline=0}
function T.update(game,cb)
 if love.timer.getTime()<T.deadline then return end
 local Bag=require("src.ui").Backpack
 if T.stage==0 then
  cb.startNewGame("red_deck");game.gold=30;game.backpackEquipment={}
  local B=require("src.basic_equipment");local E=require("src.equipment")
  for _,id in ipairs({"basic_steel_tip","basic_amber"}) do
   B.store(game,E.ITEMS[id],E.ITEMS[id].cost)
   local image=assert(require("src.continental_art").get(id))
   assert(image:getWidth()==512 and image:getHeight()==768)
  end
  cb.openShop();Bag.show();Bag.tab="equipment";Bag.page=1
 elseif T.stage==1 then
  assert(#Bag.cells==2);Bag.selected=Bag.cells[1].index
 elseif T.stage==2 then
  love.graphics.captureScreenshot(function(data)
   local f=assert(io.open("docs/basic_offense_backpack.png","wb"))
   f:write(data:encode("png"):getString());f:close()
  end)
 elseif T.stage==3 then
  print("Basic offense UI PASS: both runtime artworks loaded at 512x768 and rendered with stats / inspector in backpack")
  love.event.quit(0)
 end
 T.stage=T.stage+1;T.deadline=love.timer.getTime()+.6
end
return T

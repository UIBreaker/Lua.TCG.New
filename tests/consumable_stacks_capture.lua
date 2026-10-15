local T={stage=0,deadline=0}
local UI=require("src.ui");local Bag=UI.Backpack
local L=require("src.loadout");local Shop=require("src.shop")
local function click(r)
 assert(r,"missing control");local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local x,y=(w-1280*scale)/2+(r.x+r.w/2)*scale,(h-720*scale)/2+(r.y+r.h/2)*scale
 love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function button(cb,id)
 for _,b in ipairs(cb.getButtons()) do if b.id==id then assert(not b.disabled);return b end end
 error("missing button "..id)
end
local function shot(name)
 love.graphics.captureScreenshot(function(data)local f=assert(io.open("docs/consumable_stacks_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()end)
end
local function normalCount(game)
 local total=0;for _,s in ipairs(L.consumableStacks(game)) do if s.item.id=="healing_potion" and s.item.healAmt==25 then total=total+s.count end end;return total
end
function T.update(game,cb)
 local now=love.timer.getTime();if now<T.deadline then return end
 local s=T.stage
 if s==0 then
  cb.startNewGame("red_deck");game.gold=100;game.playerHp=50;game.backpackConsumables={}
  for i=1,120 do local p=Shop.healingItem(nil,"healing_potion").consumable;p.victoryRewardReceipt="stack-test-"..i;L.storeConsumable(game,p) end
  local p=Shop.healingItem(nil,"healing_potion").consumable;p.healAmt=50;L.storeConsumable(game,p)
  for _=1,2 do L.storeConsumable(game,Shop.healingItem(nil,"armor_potion_small").consumable) end
  game.consumables={Shop.healingItem(nil,"armor_potion_small").consumable};L.init(game)
  cb.openShop();Bag.views={};Bag.tab="consumable";Bag.show()
 elseif s==1 then
  assert(#Bag.cells==4 and Bag.cells[1].count==99 and Bag.cells[2].count==21 and Bag.cells[2].index==100)
  shot("99_and_overflow")
 elseif s==2 then click(Bag.cells[2])
 elseif s==3 then
  click(Bag.loadoutSlots[1]);assert(L.equipped(game,"consumable",1).id=="healing_potion" and normalCount(game)==119)
 elseif s==4 then click(Bag.loadoutSlots[1])
 elseif s==5 then shot("take_one");T.stage=5.5;T.deadline=now+.3;return
 elseif s==5.5 then
  click(button(cb,"bag_use"));assert(game.playerHp==75 and #game.consumables==0 and normalCount(game)==119)
  T.stage=6;T.deadline=now+.5;return
 elseif s==6 then assert(Bag.open and Bag.tab=="consumable")
 elseif s==7 then
  assert(Bag.cells[1].count==99 and Bag.cells[2].count==20);click(Bag.cells[2])
 elseif s==8 then
  local sale=assert(UI.Polish.button(game));T.gold=game.gold;T.price=Shop.getSacrificePrice(Bag.cells[2].item,"consumable",game)
  click(sale);assert(normalCount(game)==118);T.stage=9;T.deadline=now+1.5;return
 elseif s==9 then
  assert(game.gold==T.gold+T.price and Bag.cells[1].count==99 and Bag.cells[2].count==19)
  local P=require("src.persistence");local saved=assert(P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(game,"shop"))))))
  assert(normalCount(saved)==118 and #L.consumableStacks(saved)==4)
  love.window.setMode(960,540,{resizable=true});love.resize(960,540)
 elseif s==10 then shot("960_after_use_sale_save")
 elseif s==11 then
  print("Consumable stacks UI PASS: 99/21 overflow, separate effect variants, actual reserve index 100, one-unit replacement/use/sale, save round-trip and 960 layout")
  love.event.quit(0)
 end
 T.stage=s+1;T.deadline=now+(s==0 and 1.5 or .3)
end
return T

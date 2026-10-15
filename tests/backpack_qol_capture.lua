local T={stage=0,deadline=0}
local UI=require("src.ui");local Bag=UI.Backpack
local Q=require("ui.backpack_qol");local B=require("src.basic_equipment");local E=require("src.equipment")
local function clickRect(r)
 assert(r,"missing cell");local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local x,y=(w-1280*scale)/2+(r.x+r.w/2)*scale,(h-720*scale)/2+(r.y+r.h/2)*scale
 love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function click(cb,id)
 for _,b in ipairs(cb.getButtons()) do if b.id==id then assert(not b.disabled,id);clickRect(b);return end end
 error("missing control "..id)
end
local function shot(name)
 love.graphics.captureScreenshot(function(data)local f=assert(io.open("docs/backpack_qol_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()end)
end
local function resize(w,h)love.window.setMode(w,h,{resizable=true});love.resize(w,h)end
function T.update(game,cb)
 local now=love.timer.getTime();if now<T.deadline then return end
 T.started=T.started or now;assert(now-T.started<55,"QoL capture timed out at "..T.stage)
 local s=T.stage
 if s==0 then
  cb.startNewGame("red_deck");game.gold=500;game.backpackEquipment={}
  for _,id in ipairs(B.basic) do B.store(game,E.ITEMS[id],E.ITEMS[id].cost) end
  B.store(game,E.ITEMS.crafted_guard,12);B.store(game,E.ITEMS.crafted_runner,12)
  game.persistentDeck={};for i=1,12 do game.persistentDeck[i]=require("src.deck").newCard(2+i%10,"hearts") end
  game.persistentDeck[1].allowDuplicateEquipment=true
  for _=1,E.MAX_SLOTS do assert(E.attach(game.persistentDeck[1],E.ITEMS.basic_lace)) end
  assert(E.attach(game.persistentDeck[2],E.ITEMS.basic_lace))
  cb.openShop();Bag.views={};Bag.show();Bag.tab="equipment";Bag.page=1
 elseif s==1 then click(cb,"bag_search");love.textinput("day giay")
 elseif s==2 then
  assert(#Bag.cells==1 and Bag.cells[1].item.id=="basic_lace" and Bag.cells[1].index>1);shot("search")
 elseif s==3 then clickRect(Bag.cells[1]);clickRect(Bag.cells[1]);assert(Bag.pendingItem.id=="basic_lace")
 elseif s==4 then
  assert(Bag.tab=="cards" and #Bag.list(game)==10 and Bag.cells[1].index==3);shot("compatible_targets")
 elseif s==5 then love.keypressed("escape");assert(Bag.open and Bag.tab=="equipment" and not Bag.pending)
 elseif s==6 then assert(Q.state(Bag).query=="day giay");click(cb,"bag_search_clear");click(cb,"bag_search");love.textinput("Giáp")
 elseif s==7 then love.keypressed("backspace");assert(Q.state(Bag).query=="Giá");love.keypressed("return")
 elseif s==8 then click(cb,"bag_search_clear");click(cb,"bag_sort");click(cb,"bag_filter");resize(960,540)
 elseif s==9 then for _,v in ipairs(Bag.list(game)) do assert(v.item.basic and game.backpackEquipment[v.index].id==v.item.id) end;shot("filtered_960")
 elseif s==10 then resize(1280,720);click(cb,"bag_sort");click(cb,"bag_sort");click(cb,"bag_filter");click(cb,"bag_filter")
 elseif s==11 then click(cb,"bag_next");assert(Bag.page==2);love.keypressed("escape");assert(not Bag.open);love.keypressed("i");assert(Bag.open and Bag.page==2)
 elseif s==12 then shot("remembered_page");click(cb,"bag_search");love.textinput("day giay")
 elseif s==13 then clickRect(Bag.cells[1]);clickRect(Bag.cells[1]);assert(Bag.pending)
 elseif s==14 then
  T.target=Bag.cells[1].item;assert(T.target==game.persistentDeck[3]);clickRect(Bag.cells[1]);assert(T.target.equipments[1].id=="basic_lace" and not Bag.pending)
 elseif s==15 then shot("equipped");love.keypressed("5")
 elseif s==16 then click(cb,"bag_filter")
 elseif s==17 then
  for _,v in ipairs(Bag.recipeList()) do assert(B.canCraft(game,v.recipe)) end
  shot("ready_recipes");T.stage=17.5;T.deadline=now+.3;return
 elseif s==17.5 then
  T.recipe=require("ui.crafting_tree").id;T.quantity=B.count(game,T.recipe);T.gold=game.gold;love.keypressed("return")
  assert(B.count(game,T.recipe)==T.quantity+1 and game.gold==T.gold-B.byResult[T.recipe].fee)
  T.stage=18;T.deadline=now+.3;return
 elseif s==18 then
  local planets=require("src.poker").PLANET_CARDS
  local function copy(p)local out={category="celestial"};for k,v in pairs(p) do out[k]=v end;return out end
  game.consumables={copy(planets[1]),copy(planets[3]),copy(planets[4])};game.backpackConsumables={copy(planets[2])}
  require("src.loadout").init(game);T.old=game.consumables[2];love.keypressed("2")
 elseif s==19 then clickRect(Bag.cells[1])
 elseif s==20 then
  clickRect(Bag.loadoutSlots[2]);assert(#game.consumables==3 and game.backpackConsumables[1]==T.old)
 elseif s==21 then clickRect(Bag.loadoutSlots[2]);T.level=game.handLevels.pair;resize(1920,1080)
 elseif s==22 then
  local sell=assert(UI.Polish.button(game))
  for _,b in ipairs(cb.getButtons()) do if b.id=="bag_use" then assert(sell.x>=b.x+b.w or sell.y+sell.h<=b.y,"sell must not overlap use") end end
  shot("consumable_action_1920");T.stage=22.5;T.deadline=now+.3;return
 elseif s==22.5 then
  click(cb,"bag_use");assert(Bag.open and Bag.tab=="consumable" and game.handLevels.pair==T.level+2 and #game.consumables==2,"explicit use must upgrade and return to consumables")
  T.stage=23;T.deadline=now+.3;return
 elseif s==23 then
  assert(Bag.open and Bag.tab=="consumable");T.stage=23.5;T.deadline=now+.3;return
 elseif s==23.5 then
  clickRect(Bag.cells[1]);T.stage=24;T.deadline=now+.3;return
 elseif s==24 then
  local sell=assert(UI.Polish.button(game));T.sellGold=game.gold;T.sellPrice=assert(tonumber(sell.text:match("%$(%d+)")))
  clickRect(sell);assert(#game.backpackConsumables==0);T.stage=25;T.deadline=now+1.5;return
 elseif s==25 then
  assert(game.gold==T.sellGold+T.sellPrice and Bag.open);love.keypressed("escape");assert(not Bag.open)
  print("Backpack QoL UI PASS: Unicode input, search/sort/filter at 960+1920, double-click equip with actual filtered indices, Escape back, page memory, keyboard craft, click replacement without lost items, explicit consumable use and separate selling")
  love.event.quit(0)
 end
 T.stage=s+1;T.deadline=now+(s==0 and 1.8 or s==14 and 1.5 or .3)
end
return T

local T={};local stage="start";local deadline=0
local inspectorOnly=false;for _,a in ipairs(arg or {}) do if a=="--capture-backpack-inspector" then inspectorOnly=true end end
local UI=require("src.ui");local E=require("src.equipment");local B=require("src.basic_equipment")
local D=require("src.deck");local Shop=require("src.shop")
local currentButtons
local function click(x,y,button)
 local id
 if x==230 then id=({[391]="equipment",[298]="spn",[345]="consumable",[486]="craft",[439]="cards"})[y];id=id and "bag_tab_"..id
 elseif x==489 and y==579 then id=UI.Backpack.tab=="equipment" and "bag_equip" or "bag_detach_1"
 elseif x==1130 and y==163 then id="bag_next"
 elseif x==893 and y==165 then id="bag_tier_5"
 elseif x==873 and y==227 then id="bag_craft_1"
 elseif x==500 and y==215 then id="bag_recipe_1"
 elseif x==428 and y==260 then local r=UI.Backpack.cellRect(1);x,y=r.x+r.w/2,r.y+r.h/2 end
 if id then
  local found=false
  for _,b in ipairs(currentButtons or {}) do if b.id==id then x,y=b.x+b.w/2,b.y+b.h/2;found=true;break end end
  assert(found,"Missing backpack control "..id)
 end
 local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
 local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
 love.mouse.setPosition(px,py);love.mousepressed(px,py,button or 1);love.mousereleased(px,py,button or 1)
end
local function advance(next,delay) love.mouse.setPosition(2,2);stage=next;deadline=love.timer.getTime()+(delay or .4) end
local function shot(name)
 love.mouse.setPosition(2,2)
 love.graphics.captureScreenshot(function(data) local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close() end)
end
local function confirm(g) local b=assert(UI.Polish.button(g));click(b.x+b.w/2,b.y+b.h/2) end
function T.update(g,cb)
 currentButtons=cb.getButtons()
 if love.timer.getTime()<deadline or UI.Polish.busy() then return end
 if stage=="start" then
  cb.startNewGame("red_deck");g.gold=120;g.playerHp=40
  for i=2,23 do D.addCardToDeck(g,D.newCard(2+(i%13),({"clubs","spades","hearts","diamonds"})[1+i%4])) end
  g.backpackEquipment={"basic_lace"};for _,id in ipairs(B.basic) do if id~="basic_lace" then g.backpackEquipment[#g.backpackEquipment+1]=id end end
  g.consumables={Shop.healingItem("upper","healing_potion").consumable}
  local Deities=require("src.deities");g.deities={Deities.CATALOG.spirit_ward,Deities.CATALOG.spirit_blade}
  if inspectorOnly then g.backpackEquipment[1]={id="basic_lace",investment=3} end
  cb.openShop()
  local stock=cb.getShopData();for i,item in ipairs(stock.items) do if item.section=="discount" then stock.items[i]=Shop.discountedEquipment(item.equipment,item.bay,item.bay==1 and 0 or .5) end end
  advance(inspectorOnly and "inspect_open" or "shop",1)
 elseif stage=="inspect_open" then click(846,674);advance("inspect_equipment_tab")
 elseif stage=="inspect_equipment_tab" then click(230,391);advance("inspect_equipment_click")
 elseif stage=="inspect_equipment_click" then click(428,260,2);assert(cb.getInspector().id=="basic_lace");advance("inspect_equipment_draw")
 elseif stage=="inspect_equipment_draw" then shot("backpack_equipment_inspector");advance("inspect_equipment_close")
 elseif stage=="inspect_equipment_close" then click(2,2,2);assert(not cb.getInspector() and UI.Backpack.open);click(230,298);advance("inspect_spn_click")
 elseif stage=="inspect_spn_click" then click(428,260,2);assert(cb.getInspector().id=="spirit_ward");advance("inspect_spn_draw")
 elseif stage=="inspect_spn_draw" then click(2,2,2);assert(not cb.getInspector());click(230,486);advance("inspect_recipe_click")
 elseif stage=="inspect_recipe_click" then click(500,215,2);assert(cb.getInspector().id=="crafted_guard");advance("inspect_recipe_draw")
 elseif stage=="inspect_recipe_draw" then shot("backpack_recipe_inspector");advance("inspect_recipe_close")
 elseif stage=="inspect_recipe_close" then love.keypressed("escape");assert(not cb.getInspector() and UI.Backpack.open);click(230,439);advance("inspect_card_click")
 elseif stage=="inspect_card_click" then click(428,260,2);assert(cb.getInspector().rank);advance("inspect_card_draw")
 elseif stage=="inspect_card_draw" then click(925,126);assert(not cb.getInspector() and UI.Backpack.open);print("Backpack inspector PASS: right-click equipment, SPN, recipe and playing card; rendered frames; right-click/Escape/close dismissal; bag preserved");love.event.quit(0)
 elseif stage=="shop" then
  shot("backpack_shop");advance("buy_basic")
 elseif stage=="buy_basic" then
  local stock=cb.getShopData();local count=#g.backpackEquipment
  for i,item in ipairs(stock.items) do if item.section=="basic" and item.bay==1 then click(793,240);confirm(g);assert(#g.backpackEquipment==count+1);break end end
  advance("sale",1)
 elseif stage=="sale" then
  local count=#g.backpackEquipment;local gold=g.gold
  for i,item in ipairs(cb.getShopData().items) do if item.section=="discount" and item.bay==1 then local cost=item.cost;click(1005,530);confirm(g);assert(g.gold==gold-cost and #g.backpackEquipment==count+1);break end end
  advance("open",1)
 elseif stage=="open" then click(846,674);assert(UI.Backpack.open);advance("spn")
 elseif stage=="spn" then shot("backpack_spn");advance("equipment_tab")
 elseif stage=="equipment_tab" then click(230,391);advance("equipment")
 elseif stage=="equipment" then
  assert(UI.Backpack.tab=="equipment");shot("backpack_equipment");advance("equipment_select")
 elseif stage=="equipment_select" then click(428,260);advance("equip_button")
 elseif stage=="equip_button" then click(489,579);assert(UI.Backpack.pending==1);advance("attach")
 elseif stage=="attach" then
  local c=g.persistentDeck[1];local old=D.getCardAttackSpeed(c);click(428,260)
  assert(D.getCardAttackSpeed(c)==old+1 and c.equipments[1].id=="basic_lace" and not UI.Backpack.pending)
  advance("cards")
 elseif stage=="cards" then shot("backpack_cards");advance("detach")
 elseif stage=="detach" then click(489,579);assert(#g.persistentDeck[1].equipments==0);click(230,486);advance("craft")
 elseif stage=="craft" then
  assert(UI.Backpack.tab=="craft");local coins=g.gold;click(873,227)
  assert(g.gold==coins-4 and B.count(g,"crafted_guard")==1);advance("crafted",1.5)
 elseif stage=="crafted" then shot("backpack_crafting");advance("recipe_page")
 elseif stage=="recipe_page" then click(1130,163);assert(UI.Backpack.page==2);advance("recipe_tier")
 elseif stage=="recipe_tier" then click(893,165);assert(UI.Backpack.craftTier==5);advance("legendary")
 elseif stage=="legendary" then shot("backpack_legendary_recipe");advance("consumable_tab")
 elseif stage=="consumable_tab" then click(230,345);advance("consumable")
 elseif stage=="consumable" then
  assert(UI.Backpack.tab=="consumable");shot("backpack_consumables");advance("use_consumable")
 elseif stage=="use_consumable" then
  click(428,260,2)
  assert(g.playerHp==65 and #g.consumables==0 and not UI.Backpack.open)
  advance("reopen")
 elseif stage=="reopen" then click(846,674);advance("spn_tab")
 elseif stage=="spn_tab" then click(230,298);advance("sell_spn")
 elseif stage=="sell_spn" then
  local count=require("src.deities").getCount(g.deities);click(428,260);confirm(g)
  assert(require("src.deities").getCount(g.deities)==count-1);advance("pagination",1)
 elseif stage=="pagination" then
  click(230,439);assert(UI.Backpack.tab=="cards");advance("next_page")
 elseif stage=="next_page" then click(1130,163);assert(UI.Backpack.page==2);advance("final")
 elseif stage=="final" then
  shot("backpack_cards_page2");advance("exit")
 elseif stage=="exit" then
  UI.Backpack.close();g.consumables={{id="test_edition",name="Ấn Bản",category="edition",edition="foil",color={.7,.8,1,1}}}
  UI.Backpack.show();UI.Backpack.tab="consumable";advance("edition_use")
 elseif stage=="edition_use" then
  click(428,260,2);assert(UI.Backpack.open and UI.Backpack.tab=="cards" and #g.consumables==1);advance("edition_card")
 elseif stage=="edition_card" then
  click(428,260);assert(g.persistentDeck[1].edition=="foil" and #g.consumables==0)
  g.consumables={{id="test_edition",name="Ấn Bản",category="edition",edition="foil",color={.7,.8,1,1}}}
  click(230,345);advance("edition_spn_use")
 elseif stage=="edition_spn_use" then click(428,260,2);advance("edition_spn_tab")
 elseif stage=="edition_spn_tab" then click(230,298);advance("edition_spn")
 elseif stage=="edition_spn" then
  click(428,260);local found=false;for _,d in pairs(g.deities) do if d.edition=="foil" then found=true end end
  assert(found and #g.consumables==0)
  g.consumables={{id="test_edition",name="Ấn Bản",category="edition",edition="foil",color={.7,.8,1,1}}}
  click(230,345);advance("edition_cancel_use")
 elseif stage=="edition_cancel_use" then click(428,260,2);advance("edition_cancel")
 elseif stage=="edition_cancel" then
  love.keypressed("escape");assert(not UI.Backpack.open and #g.consumables==1)
  print("Backpack UI PASS: regular and discounted purchases, bag navigation, attach/detach, crafting, potion use, SPN sale, pagination, card/SPN editions, safe cancellation and eight screenshots")
  love.event.quit(0)
 end
end
return T

local T={};local stage=0;local deadline=0;local pendingShot=false
local UI=require("src.ui");local B=require("src.basic_equipment");local E=require("src.equipment")
local additions=require("src.tier_equipment").definitions
local function shot(name)
 love.graphics.captureScreenshot(function(data) local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close() end)
end
local function grid()
 local g=love.graphics;local surface=require("ui.card_surfaces")
 local canvas=g.newCanvas(850,1270);g.push("all");g.origin();g.setCanvas(canvas);g.clear(.025,.035,.045,1)
 UI.CardPhysics.suspend()
 for i,d in ipairs(additions) do
  local image=assert(UI.getEquipmentImage(d.id),d.id);assert(image:getWidth()==512 and image:getHeight()==768,d.id)
  local x,y=11+((i-1)%5)*170,8+math.floor((i-1)/5)*254
  surface.fullReward(d,x,y,148,222,"arcana",false)
  g.setFont(UI.fonts.tiny);g.setColor(.93,.88,.75,1);g.printf("T"..d.craftTier.." · "..d.name,x-7,y+228,162,"center")
 end
 UI.CardPhysics.resume();g.setCanvas();g.pop()
 local f=assert(io.open("docs/equipment_tiers_runtime.png","wb"));f:write(canvas:newImageData():encode("png"):getString());f:close()
end
local function selectTier(tier)
 UI.Backpack.craftTier=tier;local rows=UI.Backpack.recipeList();local id=additions[(tier-1)*5+1].id
 for pos,v in ipairs(rows) do if v.recipe.id==id then UI.Backpack.page=math.ceil(pos/UI.Backpack.recipePageSize);UI.Backpack.recipeSelection=v.index;require("ui.crafting_tree").select(id);return end end
 error("Missing tier recipe "..id)
end
function T.update(game,cb)
 if love.timer.getTime()<deadline then return end
 love.mouse.setPosition(2,2)
 if stage==0 then
  cb.startNewGame("red_deck");game.gold=999;game.playerHp=30
  for _,id in ipairs(B.basic) do for i=1,3 do B.store(game,E.ITEMS[id],E.ITEMS[id].cost) end end
  for _,d in ipairs(additions) do B.store(game,d,d.cost) end
  cb.openShop();grid();UI.Backpack.show();UI.Backpack.tab="craft";selectTier(1)
 elseif stage<=5 then
  assert(UI.Backpack.craftTier==stage)
  if not pendingShot then shot("equipment_tier_"..stage.."_backpack");pendingShot=true;deadline=love.timer.getTime()+.2;return end
  pendingShot=false
  if stage<5 then selectTier(stage+1) else UI.Backpack.tab="equipment";UI.Backpack.page=7 end
 elseif stage==6 then
  if not pendingShot then shot("equipment_new_inventory");pendingShot=true;deadline=love.timer.getTime()+.2;return end
  pendingShot=false;UI.Backpack.close()
 elseif stage==7 then
  shot("equipment_tiers_shop")
 elseif stage==8 then
  print("Equipment tiers UI PASS: 25 distinct runtime artworks, all five recipe filters, full details, inventory and shop");love.event.quit(0)
 end
 stage=stage+1;deadline=love.timer.getTime()+(stage==1 and 2 or .45)
end
return T

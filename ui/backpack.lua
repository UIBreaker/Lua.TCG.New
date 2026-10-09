local Bag={open=false,tab="spn",page=1}
local E=require("src.equipment")
local B=require("src.basic_equipment")
local Tree=require("ui.crafting_tree")
local Style=require("ui.backpack_style")
Bag.pageSize=8
Bag.recipePageSize=6
Bag.pocket={x=80,y=552,w=56,h=84}
function Bag.cellRect(slot)
 local n=(slot-1)%Bag.pageSize
 return {x=254+(n%4)*165,y=169+math.floor(n/4)*230,w=112,h=168}
end
local tabs={{"spn","SPN ĐỒNG HÀNH"},{"consumable","TIÊU HAO"},{"equipment","TRANG BỊ"},{"cards","BỘ BÀI"},{"craft","BÀN GHÉP"}}
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
function Bag.show() Bag.open=true;Bag.page=1;Bag.selected=nil;Bag.message=nil;Bag.pending=nil;Bag.pendingItem=nil;Tree.history={};Tree.id=nil;Tree.overview=false;require("src.ui").Polish.clearFocus() end
function Bag.close() Bag.open=false;Bag.pending=nil;Bag.pendingItem=nil;require("src.ui").Polish.clearFocus() end
function Bag.list(game)
 local list={}
 if Bag.tab=="spn" then
  for i=1,require("src.deities").getMaxSlots(game) do if (game.deities or {})[i] then list[#list+1]={item=game.deities[i],index=i} end end
 elseif Bag.tab=="consumable" then for i,c in ipairs(game.consumables or {}) do list[#list+1]={item=c,index=i} end
 elseif Bag.tab=="equipment" then for i,entry in ipairs(game.backpackEquipment or {}) do local item=B.item(entry);if item then list[#list+1]={item=item,index=i,entry=entry} end end
 elseif Bag.tab=="cards" then for i,c in ipairs(game.persistentDeck or {}) do list[#list+1]={item=c,index=i} end end
 return list
end
function Bag.rect(kind,index,game)
 if not Bag.open or Bag.tab~=(kind=="spn" and "spn" or "consumable") then return -10000,-10000,1,1 end
 for slot,v in ipairs(Bag.list(game)) do
  if v.index==index and slot>(Bag.page-1)*Bag.pageSize and slot<=Bag.page*Bag.pageSize then
   local r=Bag.cellRect(slot);return r.x,r.y,r.w,r.h
  end
 end
 return -10000,-10000,1,1
end
local function label(UI,s,x,y,w,size,color,align)
 love.graphics.setFont(UI.fonts[size or "small"]);love.graphics.setColor(color or UI.COLORS.textLight);love.graphics.printf(s,x,y,w,align or "left")
end
local function button(UI,buttons,id,s,x,y,w,h,mx,my,disabled)
 local b={id=id,text=s,x=x,y=y,w=w,h=h,font=UI.fonts.small,color=UI.COLORS.btnSpecial,disabled=disabled}
 buttons[#buttons+1]=b;UI.drawButton(b,inside(mx,my,b));return b
end
function Bag.stats(UI,item,x,y,w,h)
 if not item.statSummary then return end
 local g=love.graphics;local value=item.statSummary:gsub("Vàng","V")
 g.setColor(.015,.025,.035,.94);g.rectangle("fill",x+4,y+h-19,w-8,15)
 g.setFont(UI.fonts.tiny)
 local fit=math.min(1,(w-12)/UI.fonts.tiny:getWidth(value))
 g.push();g.translate(x+w/2,y+h-17);g.scale(fit)
 g.setColor(item.color);g.printf(value,-(w-12)/fit/2,0,(w-12)/fit,"center");g.pop()
end
function Bag.icon(x,y,w,h)
 local g=love.graphics;g.push("all")
 g.setColor(.19,.10,.045,1);g.setLineWidth(w*.11);g.ellipse("line",x+w/2,y+h*.20,w*.28,h*.18)
 g.setColor(.40,.25,.12,1);g.rectangle("fill",x+w*.10,y+h*.15,w*.8,h*.77,w*.13)
 g.setColor(.15,.075,.03,1);g.rectangle("fill",x+w*.27,y+h*.59,w*.46,h*.27,w*.05)
 g.setColor(.55,.36,.19,1);g.rectangle("fill",x+w*.07,y+h*.10,w*.86,h*.38,w*.12)
 for _,sx in ipairs({.23,.66}) do
  g.setColor(.20,.11,.05,1);g.rectangle("fill",x+w*sx,y+h*.33,w*.10,h*.43)
  g.setColor(.87,.67,.32,1);g.setLineWidth(1.5);g.rectangle("line",x+w*(sx-.02),y+h*.43,w*.14,h*.14)
 end
 g.setColor(.73,.51,.28,1);g.setLineWidth(1);g.rectangle("line",x+w*.11,y+h*.16,w*.78,h*.74,w*.12)
 g.pop()
end
function Bag.recipeList()
 local list={};for i,r in ipairs(B.recipes) do if not Bag.craftTier or Bag.craftTier==0 or r.tier==Bag.craftTier then list[#list+1]={recipe=r,index=i} end end;return list
end
local function wrapped(UI,value,x,y,w,limit,color,size)
 local font=UI.fonts[size or "tiny"];local _,lines=font:getWrap(value or "",w)
 for i=1,math.min(#lines,limit) do label(UI,lines[i]..(i==limit and #lines>limit and "…" or ""),x,y+(i-1)*(font:getHeight()+3),w,size or "tiny",color) end
end
local function panel(UI,x,y,w,h)
 Style.panel(x,y,w,h)
end
local function details(UI,game,item,entry,buttons,mx,my)
 local g=love.graphics;local accent=item and (item.color or UI.COLORS.goldYellow) or UI.COLORS.goldYellow
 Style.panel(942,135,314,544,accent,true)
 Style.glow(997,246,88,accent,.13)
 label(UI,"HỒ SƠ HÀNH TRANG",960,152,278,"tiny",UI.COLORS.goldYellow)
 if not item then
  Bag.icon(1050,294,94,114)
  wrapped(UI,"Chọn một món để xem khả năng, giá trị và những thao tác có thể thực hiện.",965,439,266,5,UI.COLORS.textMuted,"small");return
 end
 local image=item.rank and UI.getCardImage(item.suit,item.rank) or UI.getEquipmentImage(item.id) or UI.getDeityImage(item.id) or UI.getConsumableImage(item)
 if image then g.setColor(1,1,1);UI.CardFrame.image(image,963,182,88,132);UI.drawCardBorder(963,182,88,132,nil,nil,item) end
 local title,description=require("src.card_description").resolve(item,game)
 local def=item.rank and require("src.card_abilities").definition(item)
 wrapped(UI,def and (def.characterName:match("^(.-) ·") or def.characterName) or title or item.name,1066,188,171,3,accent,def and "medium" or "small")
 if def then wrapped(UI,(item.rankName or "")..(item.suitSymbol or "").." · "..def.name,1066,229,171,2,UI.COLORS.textLight) end
 local eq=E.ITEMS[item.id]
 wrapped(UI,item.rank and (E.getUsedSlots(item).." / "..E.getMaxSlots(item).." hốc"..(item.allowDuplicateEquipment and " · Phá Luật" or "")) or eq and (eq.basic and "Nguyên liệu cơ bản" or "TẦNG "..E.getTier(eq)).." · "..(eq.slotsNeeded or 1).." hốc" or Bag.tab=="spn" and "Hiệu lực suốt hành trình" or "Thẻ dùng một lần",1066,272,171,2,UI.COLORS.textMuted)
 if item.rank then
  for i=1,E.getMaxSlots(item) do local x=1072+(i-1)*19;g.setColor(i<=E.getUsedSlots(item) and UI.COLORS.goldYellow or {.30,.37,.40,1});g.polygon(i<=E.getUsedSlots(item) and "fill" or "line",x,306,x+4,310,x,314,x-4,310) end
 end
 g.setColor(.58,.44,.26,.3);g.line(961,328,1238,328)
 if item.rank then
  wrapped(UI,require("src.card_abilities").description(item) or description,961,343,278,3,UI.COLORS.textLight)
  label(UI,"TRANG BỊ ĐANG KHẢM",961,403,275,"tiny",UI.COLORS.goldYellow)
  for i,gear in ipairs(item.equipments or {}) do
   local y=420+(i-1)*28
   local img=UI.getEquipmentImage(gear.id);g.setColor(1,1,1);if img then UI.CardFrame.image(img,963,y,16,24) end
   button(UI,buttons,"bag_detach_"..i,"THÁO "..i.." · "..gear.name,987,y,251,25,mx,my,not Bag.selected)
  end
  if #(item.equipments or {})==0 then wrapped(UI,"Các hốc còn trống. Chọn một món từ ngăn Trang bị để gắn lên lá này.",964,433,271,5,UI.COLORS.textMuted) end
 else
  wrapped(UI,eq and E.getDescription(eq) or description or item.desc,961,343,277,entry and 10 or 15,UI.COLORS.textLight,"small")
  if entry then
   label(UI,"ĐÃ ĐẦU TƯ",961,560,134,"tiny",UI.COLORS.textMuted)
   label(UI,B.investment(entry).." vàng",1098,559,137,"small",UI.COLORS.goldYellow,"right")
   label(UI,"BÁN LẠI",961,587,134,"tiny",UI.COLORS.textMuted)
   label(UI,B.resale(entry).." vàng",1098,586,137,"small",UI.COLORS.textLight,"right")
   button(UI,buttons,"bag_view_tree","XEM CÂY TRANG BỊ →",960,627,278,33,mx,my,eq.soulOnly)
  end
 end
end
function Bag.draw(UI,game,buttons,mx,my,drawConsumable)
 if not Bag.open then return end
 UI.CardPhysics.blockBehind();UI.descriptionCandidate=nil;for i=#buttons,1,-1 do buttons[i]=nil end
 local g=love.graphics;g.push("all");local time=UI.Polish.time
 Style.background(time)
 Style.compass(44,48,28,UI.COLORS.goldYellow,.75,time)
 Bag.icon(30,29,28,37)
 label(UI,"BALO VIỄN CHINH",85,25,502,"large",{.93,.80,.57,1})
 label(UI,"LIÊN MINH BỐN VƯƠNG QUỐC  /  NHẬT KÝ HÀNH TRANG",86,70,504,"tiny",UI.COLORS.textMuted)
 Style.panel(622,17,188,43,UI.COLORS.goldYellow)
 Style.glyph("gold",640,38,9,UI.COLORS.goldYellow)
 label(UI,tostring(game.gold or 0).." VÀNG",657,29,139,"medium",UI.COLORS.goldYellow,"right")
 Style.panel(825,17,210,43,{.76,.62,.94})
 Style.glyph("souls",844,38,10,{.76,.62,.94})
 label(UI,tostring(game.souls or 0).." LINH HỒN",861,33,160,"small",{.80,.67,1,1},"right")
 label(UI,"SPN "..require("src.deities").getCount(game.deities).."/"..require("src.deities").getMaxSlots(game).." · Tiêu hao "..#(game.consumables or {}).."/"..require("src.inventory").limit(game).." · "..#(game.persistentDeck or {}).." lá",622,69,406,"tiny",UI.COLORS.textMuted,"right")
 button(UI,buttons,"bag_close","ĐÓNG  ×",1122,64,134,32,mx,my)
 label(UI,"HÀNH TRANG",25,136,170,"small",{.87,.75,.56,1})
 label(UI,"CHỌN NGĂN ĐỂ KHÁM PHÁ",25,155,170,"tiny",UI.COLORS.textMuted)
 local tabNames={"Hộ linh","Tiêu hao","Trang bị","Bộ bài","Bàn ghép"}
 local subtitles={"Đồng hành","Dùng một lần","Di vật & vật liệu","Đoàn viễn chinh","Bản thiết kế"}
 local counts={require("src.deities").getCount(game.deities),#(game.consumables or {}),#(game.backpackEquipment or {}),#(game.persistentDeck or {}),#B.recipes}
 for i,t in ipairs(tabs) do
  local y=179+(i-1)*62;local active=Bag.tab==t[1]
  local b=button(UI,buttons,"bag_tab_"..t[1],"",19,y,174,48,mx,my)
  local accent=active and {.96,.78,.45,1} or {.59,.60,.56,1}
  if active then Style.glow(44,y+24,26,accent,.18);g.setColor(accent);g.rectangle("fill",19,y+9,3,30) end
  Style.glyph(t[1],41,y+24,10,accent)
  label(UI,tabNames[i],61,y+7,97,"small",active and UI.COLORS.textLight or UI.COLORS.textMuted)
  label(UI,subtitles[i],61,y+28,124,"tiny",{.64,.62,.55,1})
  label(UI,tostring(counts[i]),156,y+8,28,"tiny",accent,"right")
 end
 local returning
 for _,a in ipairs(UI.Polish.applications) do if a.kind=="unequip" and a.fixedRect and a.sourceItem then returning=a end end
 local pocketItem=Bag.pendingItem or returning and returning.sourceItem
 panel(UI,19,509,174,170)
 label(UI,pocketItem and (returning and "ĐANG THU HỒI" or "SẴN SÀNG GẮN") or "XƯỞNG VIỄN CHINH",28,524,156,"tiny",UI.COLORS.goldYellow,"center")
 if pocketItem then
  if not returning or returning.hit then local img=UI.getEquipmentImage(pocketItem.id);g.setColor(1,1,1);if img then local r=Bag.pocket;UI.CardFrame.image(img,r.x,r.y,r.w,r.h);UI.drawCardBorder(r.x,r.y,r.w,r.h,nil,nil,pocketItem) end end
  wrapped(UI,pocketItem.name,28,643,156,2,pocketItem.color,"tiny")
 else
  Bag.icon(82,554,48,58)
  label(UI,#B.recipes.." bản thiết kế · 5 tầng",28,634,156,"tiny",UI.COLORS.textLight,"center")
  label(UI,"Gắn và tháo tại cửa hàng",28,654,156,"tiny",UI.COLORS.textMuted,"center")
 end
 Bag.cells={}
 if Bag.tab=="craft" then
  local recipes=Bag.recipeList();Bag.pages=math.max(1,math.ceil(#recipes/Bag.recipePageSize));Bag.page=math.max(1,math.min(Bag.page,Bag.pages))
  if not Tree.overview then
  for tier=0,5 do button(UI,buttons,"bag_tier_"..tier,tier==0 and "TẤT CẢ" or "T"..tier,228+(tier%3)*73,133+math.floor(tier/3)*34,67,28,mx,my)
   if tier==(Bag.craftTier or 0) then g.setColor(UI.COLORS.goldYellow);g.line(234+(tier%3)*73,159+math.floor(tier/3)*34,288+(tier%3)*73,159+math.floor(tier/3)*34) end
  end
  local selected=Bag.recipeSelection and B.recipes[Bag.recipeSelection]
  if not Tree.id then Tree.select(selected and selected.id or recipes[1] and recipes[1].recipe.id) end
  for slot=(Bag.page-1)*Bag.recipePageSize+1,math.min(#recipes,Bag.page*Bag.recipePageSize) do
   local v=recipes[slot];local d=E.ITEMS[v.recipe.id];local y=216+((slot-1)%Bag.recipePageSize)*69
   Style.panel(228,y,222,62,E.getTierColor(d),Tree.id==d.id)
   local img=UI.getEquipmentImage(d.id);g.setColor(1,1,1);if img then UI.CardFrame.image(img,235,y+5,34,51) end
   wrapped(UI,d.name,279,y+8,160,2,E.getTierColor(d),"tiny")
   label(UI,"T"..v.recipe.tier.." · "..v.recipe.fee.." vàng"..(B.canCraft(game,v.recipe) and " · ✓" or ""),279,y+44,158,"tiny",B.canCraft(game,v.recipe) and UI.COLORS.hpGreen or UI.COLORS.textMuted)
   buttons[#buttons+1]={id="bag_recipe_"..v.index,x=228,y=y,w=222,h=62,invisible=true}
  end
  button(UI,buttons,"bag_prev","←",228,640,47,32,mx,my,Bag.page<=1)
  button(UI,buttons,"bag_next","→",403,640,47,32,mx,my,Bag.page>=Bag.pages)
  label(UI,Bag.page.." / "..Bag.pages,280,650,118,"tiny",UI.COLORS.textMuted,"center")
  g.setColor(.59,.44,.25,.25);g.line(465,132,465,680)
  end
  Tree.draw(UI,game,buttons,mx,my)
 else
  local list=Bag.list(game);Bag.pages=math.max(1,math.ceil(#list/Bag.pageSize));Bag.page=math.max(1,math.min(Bag.page,Bag.pages))
  label(UI,Bag.pending and "CHỌN LÁ ĐỂ GẮN · "..(Bag.pendingItem and Bag.pendingItem.name or "") or ({spn="HỘ LINH ĐỒNG HÀNH",consumable="DƯỢC LIỆU & THẺ HỖ TRỢ",equipment="NGUYÊN LIỆU & DI VẬT",cards="ĐOÀN VIỄN CHINH"})[Bag.tab],235,132,578,"small",UI.COLORS.goldYellow)
  button(UI,buttons,"bag_prev","←",813,127,43,29,mx,my,Bag.page<=1)
  button(UI,buttons,"bag_next","→",883,127,43,29,mx,my,Bag.page>=Bag.pages)
  label(UI,Bag.page.."/"..Bag.pages,853,136,33,"tiny",UI.COLORS.textMuted,"center")
  local detail,entry
  for slot=(Bag.page-1)*Bag.pageSize+1,math.min(#list,Bag.page*Bag.pageSize) do
   local v=list[slot];local r=Bag.cellRect(slot);local x,y,w,h=r.x,r.y,r.w,r.h;local item=v.item
   local hover=inside(mx,my,r);local selected=Bag.selected==v.index
   if hover then UI.descriptionCandidate=item end
   local accent=item.color or UI.COLORS.goldYellow
   Style.panel(x-11,y-7,134,217,accent,selected or hover)
   if selected or hover then Style.glow(x+w/2,y+h*.42,80,accent,.12) end
   if Bag.pending and Bag.tab=="cards" then
    local valid=E.canAttach(item,Bag.pendingItem)
    g.setColor(valid and {.4,.83,.64,.7} or {.8,.39,.34,.5});g.circle("fill",x+w+3,y+3,5)
   end
   if Bag.tab=="spn" then
    item.slotIndex=v.index;local D=require("src.deities");local copy=item.isCopyDeity and D.resolveDeity(game.deities,v.index)
    UI.drawPatronCard(item,x,y,w,h,hover,false,false,copy)
   elseif Bag.tab=="consumable" then drawConsumable(item,x,y,w,h,v.index,mx,my)
   elseif Bag.tab=="cards" then UI.drawCard(item,x,y,w,h,hover)
   else local img=UI.getEquipmentImage(item.id);g.setColor(1,1,1);if img then UI.CardFrame.image(img,x,y,w,h) end;UI.drawCardBorder(x,y,w,h,hover and UI.COLORS.goldYellow,nil,item);Bag.stats(UI,item,x,y,w,h) end
   local def=Bag.tab=="cards" and require("src.card_abilities").definition(item)
   wrapped(UI,def and (def.characterName:match("^(.-) ·") or def.characterName) or item.name or ((item.rankName or "")..(item.suitSymbol or "")),x-4,y+h+5,w+8,2,item.color,"tiny")
   if Bag.tab=="cards" then label(UI,(item.rankName or "")..(item.suitSymbol or "").." · "..E.getUsedSlots(item).."/"..E.getMaxSlots(item).." HỐC"..(item.allowDuplicateEquipment and " · PL" or ""),x-5,y+h+25,w+10,"tiny",UI.COLORS.goldYellow,"center") end
   r.item=item;r.index=v.index;Bag.cells[#Bag.cells+1]=r
   if selected then detail=item;entry=v.entry end
   if not Bag.selected and hover then detail=item;entry=v.entry end
  end
  if not detail and #list>0 then local v=list[(Bag.page-1)*Bag.pageSize+1];detail=v.item;entry=v.entry end
  details(UI,game,detail,entry,buttons,mx,my)
  if #list==0 then Bag.icon(532,272,91,115);label(UI,"NGĂN HÀNH TRANG CÒN TRỐNG",279,420,591,"small",UI.COLORS.goldYellow,"center");wrapped(UI,"Những món đồ bạn mua hoặc thu hồi sẽ được cất ở đây.",347,456,454,3,UI.COLORS.textMuted,"small") end
  if Bag.tab=="equipment" and Bag.selected and (game.backpackEquipment or {})[Bag.selected] then
   button(UI,buttons,"bag_equip","GẮN VÀO LÁ BÀI",243,641,337,38,mx,my)
   button(UI,buttons,"bag_sell","BÁN · "..B.resale(game.backpackEquipment[Bag.selected]).." VÀNG",594,641,330,38,mx,my)
  elseif Bag.tab=="spn" and Bag.selected then
   button(UI,buttons,"bag_spn_left","← ĐỔI VỊ TRÍ",243,641,337,38,mx,my,Bag.selected<=1)
   button(UI,buttons,"bag_spn_right","ĐỔI VỊ TRÍ →",594,641,330,38,mx,my,Bag.selected>=require("src.deities").getMaxSlots(game))
  elseif Bag.pending then button(UI,buttons,"bag_cancel_equip","HỦY GẮN TRANG BỊ",243,641,681,38,mx,my) end
 end
 g.setColor(.046,.052,.057,1);g.rectangle("fill",212,692,1068,28)
 label(UI,Bag.message or (Bag.tab=="consumable" and "Nhấp chọn để bán · Chuột phải để dùng" or Bag.tab=="craft" and "Nguyên liệu lấy từ balo · Trang bị đang gắn cần tháo trước khi ghép · Di vật linh hồn không ghép" or "Nhấp chọn để thao tác · Chuột phải xem chi tiết · Lăn chuột để chuyển trang"),232,700,1026,"tiny",UI.COLORS.textMuted)
 g.pop()
end
function Bag.mouse(UI,game,buttons,mx,my,mouse,callbacks)
 if not Bag.open then return false end
 if UI.Polish.busy() then return true end
 for _,b in ipairs(buttons) do if mouse==1 and b.id and b.id:sub(1,4)=="bag_" and inside(mx,my,b) and not b.disabled then
  if b.id=="bag_close" then if callbacks.cancel then callbacks.cancel() end;Bag.close()
  elseif b.id:sub(1,8)=="bag_tab_" then Bag.tab=b.id:sub(9);Bag.page=1;Bag.selected=nil;Bag.pending=nil;Bag.pendingItem=nil;UI.Polish.clearFocus()
  elseif b.id=="bag_prev" then Bag.page=math.max(1,Bag.page-1);Bag.selected=nil;UI.Polish.clearFocus()
  elseif b.id=="bag_next" then Bag.page=math.min(Bag.pages,Bag.page+1);Bag.selected=nil;UI.Polish.clearFocus()
  elseif b.id:sub(1,9)=="bag_tier_" then Bag.craftTier=tonumber(b.id:sub(10));Bag.page=1;Bag.recipeSelection=nil;Tree.id=nil;Tree.history={}
  elseif b.id:sub(1,11)=="bag_recipe_" then Bag.recipeSelection=tonumber(b.id:sub(12));Tree.select(B.recipes[Bag.recipeSelection].id,true)
  elseif Tree.mouse(b.id) then
  elseif b.id=="bag_view_tree" then
   local eq=B.item(game.backpackEquipment[Bag.selected]);if eq and not eq.soulOnly then Bag.tab="craft";Bag.page=1;Bag.craftTier=0;Tree.select(eq.id);Tree.history={} end
  elseif b.id=="bag_cancel_equip" then Bag.pending=nil;Bag.pendingItem=nil;Bag.tab="equipment";Bag.selected=nil
  elseif b.id:sub(1,10)=="bag_craft_" then Bag.recipeSelection=tonumber(b.id:sub(11));local ok,msg=B.craft(game,B.recipes[tonumber(b.id:sub(11))]);Bag.message=msg;if ok and callbacks.save then callbacks.save() end
  elseif b.id=="bag_equip" then Bag.pending=Bag.selected;Bag.pendingItem=B.item(game.backpackEquipment[Bag.selected]);Bag.selected=nil;Bag.tab="cards";Bag.page=1
  elseif b.id=="bag_spn_left" or b.id=="bag_spn_right" then
   local target=Bag.selected+(b.id=="bag_spn_left" and -1 or 1)
   game.deities[Bag.selected],game.deities[target]=game.deities[target],game.deities[Bag.selected]
   Bag.selected=target;UI.Polish.clearFocus();if callbacks.save then callbacks.save() end
  elseif b.id=="bag_sell" and Bag.selected then local entry=game.backpackEquipment[Bag.selected];game.gold=(game.gold or 0)+B.resale(entry);table.remove(game.backpackEquipment,Bag.selected);Bag.selected=nil;if callbacks.save then callbacks.save() end
  elseif b.id:sub(1,11)=="bag_detach_" then
   local card=game.persistentDeck[Bag.selected];local index=tonumber(b.id:sub(12));local eq=card and (card.equipments or {})[index];local rect;local oldSpeed=card and require("src.deck").getCardAttackSpeed(card)
   for _,cell in ipairs(Bag.cells or {}) do if cell.item==card then rect={x=cell.x,y=cell.y,w=cell.w,h=cell.h} end end
   if eq and B.detach(game,card,index) then
    local speed=require("src.deck").getCardAttackSpeed(card)
    UI.Polish.application(UI,eq,card,"Về balo · "..E.getUsedSlots(card).."/"..E.getMaxSlots(card).." hốc"..(speed~=oldSpeed and (" · Tốc "..oldSpeed.." → "..speed) or ""),Bag.pocket,rect,"unequip")
    UI.Polish.applications[#UI.Polish.applications].fixedRect=rect
    Bag.message="Đã tháo "..eq.name.." và cất vào balo.";if callbacks.save then callbacks.save() end
   end
  end
  return true
 end end
 if mouse==2 and Bag.tab=="craft" then
  for _,b in ipairs(buttons) do if b.id and b.id:sub(1,9)=="bag_node_" and inside(mx,my,b) then
   if callbacks.inspect then callbacks.inspect(E.ITEMS[b.id:sub(10)]) end;return true
  end end
  for _,b in ipairs(buttons) do if b.id and b.id:sub(1,11)=="bag_recipe_" and inside(mx,my,b) then
   local r=B.recipes[tonumber(b.id:sub(12))];if callbacks.inspect then callbacks.inspect(E.ITEMS[r.id]) end;return true
  end end
 end
 for _,c in ipairs(Bag.cells or {}) do if inside(mx,my,c) then
  if mouse==1 and (Bag.tab=="cards" or Bag.tab=="spn") and callbacks.target and callbacks.target(c.item) then return true end
  Bag.selected=c.index
  if Bag.tab=="cards" then
   if Bag.pending and mouse==1 then
    local eq=B.item(game.backpackEquipment[Bag.pending]);local oldSpeed=require("src.deck").getCardAttackSpeed(c.item)
    local ok,msg=B.attach(game,Bag.pending,c.item);Bag.message=msg
    if ok then
     local speed=require("src.deck").getCardAttackSpeed(c.item)
     UI.Polish.application(UI,eq,c.item,E.getUsedSlots(c.item).."/"..E.getMaxSlots(c.item).." hốc"..(speed~=oldSpeed and (" · Tốc "..oldSpeed.." → "..speed) or ""),Bag.pocket,c,"equip")
     UI.Polish.applications[#UI.Polish.applications].fixedRect={x=c.x,y=c.y,w=c.w,h=c.h}
     Bag.pending=nil;Bag.pendingItem=nil;if callbacks.save then callbacks.save() end
    end
   elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item) end
  elseif Bag.tab=="consumable" and mouse==2 then callbacks.activate(c.index)
  elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item)
  elseif Bag.tab=="spn" or Bag.tab=="consumable" then UI.Polish.focusItem(c.item,Bag.tab=="spn" and "deity" or "consumable",c.index,c) end
  return true
 end end
 return true
end
function Bag.wheel(mx,my,delta)
 if not Bag.open then return false end
 if delta==0 then return true end
 if Bag.tab=="craft" and Tree.wheel(mx,my,delta,love.keyboard.isDown("lshift","rshift")) then return true end
 Bag.page=math.max(1,math.min(Bag.pages or 1,Bag.page-(delta>0 and 1 or -1)));Bag.selected=nil
 require("src.ui").Polish.clearFocus();return true
end
return Bag

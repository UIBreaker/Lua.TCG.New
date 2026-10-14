local Bag={open=false,tab="spn",page=1}
local E=require("src.equipment")
local B=require("src.basic_equipment")
local Tree=require("ui.crafting_tree")
local Style=require("ui.backpack_style")
local Loadout=require("src.loadout")
local Slots=require("ui.backpack_loadout")
local Q=require("ui.backpack_qol")
Bag.pageSize=8
Bag.recipePageSize=6
Bag.pocket={x=80,y=552,w=56,h=84}
function Bag.cellRect(slot)
 local n=(slot-1)%Bag.pageSize
 if Bag.tab=="spn" or Bag.tab=="consumable" then return {x=265+(n%4)*165,y=298+math.floor(n/4)*190,w=90,h=135} end
 return {x=254+(n%4)*165,y=169+math.floor(n/4)*230,w=112,h=168}
end
local tabs={{"spn","SPN ĐỒNG HÀNH"},{"consumable","TIÊU HAO"},{"equipment","TRANG BỊ"},{"cards","BỘ BÀI"},{"craft","BÀN GHÉP"},{"journey","CÔNG NHẬN"}}
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
function Bag.show() Bag.open=true;Bag.page=Q.state(Bag).page;Bag.selected=nil;Bag.selectedSource=nil;Bag.drag=nil;Bag.message=nil;Bag.pending=nil;Bag.pendingItem=nil;Bag.searchFocus=false;Bag.searchSelectAll=false;Bag.lastClick=nil;Bag.cells={};Bag.loadoutSlots={};Bag.buttons={};require("src.ui").Polish.clearFocus() end
function Bag.close() if Bag.pending then Bag.cancelEquip() end;Q.state(Bag).page=Bag.page;Bag.open=false;Bag.searchFocus=false;love.keyboard.setTextInput(false);Bag.drag=nil;Bag.pending=nil;Bag.pendingItem=nil;require("src.ui").Polish.clearFocus() end
function Bag.list(game)
 local list={}
 if Bag.tab=="spn" then
  for i,c in ipairs(game.backpackDeities or {}) do list[#list+1]={item=c,index=i} end
 elseif Bag.tab=="consumable" then for i,c in ipairs(game.backpackConsumables or {}) do list[#list+1]={item=c,index=i} end
 elseif Bag.tab=="equipment" then for i,entry in ipairs(game.backpackEquipment or {}) do local item=B.item(entry);if item then list[#list+1]={item=item,index=i,entry=entry} end end
 elseif Bag.tab=="cards" then for i,c in ipairs(game.persistentDeck or {}) do list[#list+1]={item=c,index=i} end
 elseif Bag.tab=="journey" then
  for i,id in ipairs(require("src.expedition").recognitionIds) do
   if (game.regionRecognitions or {})[id] then list[#list+1]={item=require("src.expedition").recognitionCard(id),index=i} end
  end
 end
 return Q.list(Bag,game,list)
end
function Bag.rect(kind,index,game)
 if not Bag.open or Bag.tab~=(kind=="spn" and "spn" or "consumable") then return -10000,-10000,1,1 end
 for _,r in ipairs(Bag.loadoutSlots or {}) do
  if r.activeIndex==index then return r.x,r.y,r.w,r.h end
 end
 return -10000,-10000,1,1
end
local function label(UI,s,x,y,w,size,color,align)
 love.graphics.setFont(UI.fonts[size or "small"]);love.graphics.setColor(color or UI.COLORS.textLight);love.graphics.printf(s,x,y,w,align or "left")
end
local function button(UI,buttons,id,s,x,y,w,h,mx,my,disabled,size)
 local b={id=id,text=s,x=x,y=y,w=w,h=h,font=UI.fonts[size or "small"],color=UI.COLORS.btnSpecial,disabled=disabled}
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
 local list={};for i,r in ipairs(B.recipes) do if not Bag.craftTier or Bag.craftTier==0 or r.tier==Bag.craftTier then list[#list+1]={recipe=r,index=i} end end;return Q.list(Bag,Bag.game or {},list,true)
end
local function tools(UI,buttons,mx,my,x,y,w,craft)
 local state=Q.state(Bag);local narrow=craft
 local fieldW=narrow and w or 300
 button(UI,buttons,"bag_search", "",x,y,state.query~="" and fieldW-26 or fieldW,26,mx,my)
 local shown=state.query;local trimmed=false;local utf8=require("utf8")
 while UI.fonts.tiny:getWidth((trimmed and "…" or "")..shown)>fieldW-30 do shown=shown:sub(utf8.offset(shown,2));trimmed=true end
 if Bag.searchFocus and Bag.searchSelectAll and shown~="" then love.graphics.setColor(.27,.35,.33,.85);love.graphics.rectangle("fill",x+4,y+3,fieldW-32,20,3,3) end
 label(UI,state.query~="" and ((trimmed and "…" or "")..shown) or "Tìm tên / khả năng…",x+8,y+7,fieldW-30,"tiny",state.query~="" and UI.COLORS.textLight or UI.COLORS.textMuted)
 if Bag.searchFocus then love.graphics.setColor(UI.COLORS.goldYellow);love.graphics.line(x+4,y+25,x+fieldW-4,y+25) end
 if state.query~="" then button(UI,buttons,"bag_search_clear","×",x+fieldW-26,y,26,26,mx,my) end
 local sorts={"THỨ TỰ","TÊN A–Z",craft and "GHÉP ĐƯỢC" or Bag.tab=="cards" and "BẬC GIẢM" or "TẦNG GIẢM"}
 local filters=craft and {"MỌI CÔNG THỨC","ĐỦ ĐỂ GHÉP"} or Bag.pending and {"MỌI LÁ","GẮN ĐƯỢC"} or Bag.tab=="equipment" and {"TẤT CẢ","CƠ BẢN","ĐỒ LỚN"} or Bag.tab=="cards" and {"TẤT CẢ","CÓ TRANG BỊ","CHƯA GẮN"} or {"TẤT CẢ"}
 Bag.filterCount=#filters
 button(UI,buttons,"bag_sort",sorts[state.sort],narrow and x or x+310,narrow and y+30 or y,narrow and 103 or 126,26,mx,my,false,"tiny")
 button(UI,buttons,"bag_filter",filters[state.filter] or filters[1],narrow and x+109 or x+444,narrow and y+30 or y,narrow and 113 or 130,26,mx,my,#filters==1,"tiny")
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
 wrapped(UI,item.rank and (E.getUsedSlots(item).." / "..E.getMaxSlots(item).." hốc"..(item.allowDuplicateEquipment and " · Phá Luật" or "")) or eq and (eq.basic and "Nguyên liệu cơ bản" or "TẦNG "..E.getTier(eq)).." · "..(eq.slotsNeeded or 1).." hốc" or Bag.tab=="journey" and "Chứng nhận vĩnh viễn" or Bag.tab=="spn" and (Bag.selectedSource=="equipped" and "Đang trang bị · Có hiệu lực" or "Trong kho · Chưa kích hoạt") or "Thẻ dùng một lần",1066,272,171,2,UI.COLORS.textMuted)
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
   button(UI,buttons,"bag_detach_"..i,"THÁO "..i.." · "..gear.name,987,y,251,25,mx,my,not Bag.selected or Bag.combat)
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
function Bag.draw(UI,game,buttons,mx,my,drawConsumable,context)
 if not Bag.open then return end
 Bag.combat=context=="playing";Bag.game=game;Loadout.init(game)
 if Bag.combat and Bag.tab=="craft" then Q.switch(Bag,"equipment") end
 Bag.buttons=buttons
 UI.CardPhysics.blockBehind();UI.descriptionCandidate=nil;for i=#buttons,1,-1 do buttons[i]=nil end
 local g=love.graphics;g.push("all");g.setBlendMode("alpha");g.setShader();g.setScissor();local time=UI.Polish.time
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
 local tabNames={"Hộ linh","Tiêu hao","Trang bị","Bộ bài","Bàn ghép","Công nhận"}
 local subtitles={"Đồng hành","Dùng một lần","Di vật & vật liệu","Đoàn viễn chinh","Bản thiết kế","Bốn vương quốc"}
 local counts={#game.backpackDeities,#game.backpackConsumables,#(game.backpackEquipment or {}),#(game.persistentDeck or {}),#B.recipes,require("src.expedition").recognitionCount(game)}
 for i,t in ipairs(tabs) do
  local y=179+(i-1)*52;local active=Bag.tab==t[1]
 local b=button(UI,buttons,"bag_tab_"..t[1],"",19,y,174,48,mx,my,Bag.combat and t[1]=="craft")
  local accent=active and {.96,.78,.45,1} or {.59,.60,.56,1}
  if active then Style.glow(44,y+24,26,accent,.18);g.setColor(accent);g.rectangle("fill",19,y+9,3,30) end
  Style.glyph(t[1]=="journey" and "cards" or t[1],41,y+24,10,accent)
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
  for tier=0,5 do local tx= tier==0 and 228 or 275+(tier-1)*35;local tw=tier==0 and 43 or 31
   button(UI,buttons,"bag_tier_"..tier,tier==0 and "TẤT" or "T"..tier,tx,132,tw,25,mx,my,false,"tiny")
   if tier==(Bag.craftTier or 0) then g.setColor(UI.COLORS.goldYellow);g.line(tx+3,157,tx+tw-3,157) end
  end
  tools(UI,buttons,mx,my,228,162,222,true)
  local selected=Bag.recipeSelection and B.recipes[Bag.recipeSelection]
  if not Tree.id then Tree.select(selected and selected.id or recipes[1] and recipes[1].recipe.id) end
  for slot=(Bag.page-1)*Bag.recipePageSize+1,math.min(#recipes,Bag.page*Bag.recipePageSize) do
   local v=recipes[slot];local d=E.ITEMS[v.recipe.id];local y=224+((slot-1)%Bag.recipePageSize)*69
   Style.panel(228,y,222,62,E.getTierColor(d),Tree.id==d.id)
   local img=UI.getEquipmentImage(d.id);g.setColor(1,1,1);if img then UI.CardFrame.image(img,235,y+5,34,51) end
   wrapped(UI,d.name,279,y+8,160,2,E.getTierColor(d),"tiny")
   label(UI,"T"..v.recipe.tier.." · "..v.recipe.fee.." vàng"..(B.canCraft(game,v.recipe) and " · ✓" or ""),279,y+44,158,"tiny",B.canCraft(game,v.recipe) and UI.COLORS.hpGreen or UI.COLORS.textMuted)
   buttons[#buttons+1]={id="bag_recipe_"..v.index,x=228,y=y,w=222,h=62,invisible=true}
  end
  button(UI,buttons,"bag_prev","←",228,640,47,32,mx,my,Bag.page<=1)
  button(UI,buttons,"bag_next","→",403,640,47,32,mx,my,Bag.page>=Bag.pages)
  label(UI,Bag.page.." / "..Bag.pages,280,650,118,"tiny",UI.COLORS.textMuted,"center")
  if #recipes==0 then wrapped(UI,"Không có công thức phù hợp. Xóa tìm kiếm hoặc đổi bộ lọc.",240,270,195,6,UI.COLORS.textMuted) end
  g.setColor(.59,.44,.25,.25);g.line(465,132,465,680)
  end
  Tree.draw(UI,game,buttons,mx,my)
 else
  local list=Bag.list(game);Bag.pages=math.max(1,math.ceil(#list/Bag.pageSize));Bag.page=math.max(1,math.min(Bag.page,Bag.pages))
  local loadoutTab=Bag.tab=="spn" or Bag.tab=="consumable"
  if loadoutTab then Slots.draw(UI,Bag,game,buttons,mx,my) end
  local headingY=loadoutTab and 265 or 132
  tools(UI,buttons,mx,my,235,headingY-5,578)
  if not loadoutTab then label(UI,Bag.pending and "CHỌN LÁ GẮN · "..(Bag.pendingItem and Bag.pendingItem.name or "") or ("Tìm thấy "..#list..(Bag.tab=="cards" and " lá" or " món").." · Ctrl+F tìm"..(Bag.tab=="equipment" and " · Nhấp đúp để gắn" or "")),235,109,690,"tiny",UI.COLORS.goldYellow) end
  button(UI,buttons,"bag_prev","←",813,headingY-5,43,24,mx,my,Bag.page<=1)
  button(UI,buttons,"bag_next","→",883,headingY-5,43,24,mx,my,Bag.page>=Bag.pages)
  label(UI,Bag.page.."/"..Bag.pages,853,headingY+1,33,"tiny",UI.COLORS.textMuted,"center")
  local detail,entry
  for slot=(Bag.page-1)*Bag.pageSize+1,math.min(#list,Bag.page*Bag.pageSize) do
   local v=list[slot];local r=Bag.cellRect(slot);local x,y,w,h=r.x,r.y,r.w,r.h;local item=v.item
   local hover=inside(mx,my,r);local selected=Bag.selected==v.index and Bag.selectedSource~="equipped"
   if hover then UI.descriptionCandidate=item end
   local accent=item.color or UI.COLORS.goldYellow
   Style.panel(x-11,y-7,loadoutTab and 112 or 134,loadoutTab and 169 or 217,accent,selected or hover)
   if selected or hover then Style.glow(x+w/2,y+h*.42,80,accent,.12) end
   if Bag.pending and Bag.tab=="cards" then
    local valid=E.canAttach(item,Bag.pendingItem)
    g.setColor(valid and {.4,.83,.64,.7} or {.8,.39,.34,.5});g.circle("fill",x+w+3,y+3,5)
   end
   if loadoutTab and (UI.Polish.hiddenOwned(item) or Bag.drag and Bag.drag.moving and Bag.drag.item==item) then
   elseif Bag.tab=="spn" then
    UI.drawPatronCard(item,x,y,w,h,hover,false,false)
   elseif Bag.tab=="consumable" or Bag.tab=="journey" then UI.Polish.renderItem(UI,item,x,y,w,h)
   elseif Bag.tab=="cards" then if not UI.Polish.hiddenOwned(item) then UI.drawCard(item,x,y,w,h,hover) end
   else local img=UI.getEquipmentImage(item.id);g.setColor(1,1,1);if img then UI.CardFrame.image(img,x,y,w,h) end;UI.drawCardBorder(x,y,w,h,hover and UI.COLORS.goldYellow,nil,item);Bag.stats(UI,item,x,y,w,h) end
   local def=Bag.tab=="cards" and require("src.card_abilities").definition(item)
   wrapped(UI,def and (def.characterName:match("^(.-) ·") or def.characterName) or item.name or ((item.rankName or "")..(item.suitSymbol or "")),x-4,y+h+5,w+8,loadoutTab and 1 or 2,item.color,"tiny")
   if Bag.tab=="cards" then label(UI,(item.rankName or "")..(item.suitSymbol or "").." · "..E.getUsedSlots(item).."/"..E.getMaxSlots(item).." HỐC"..(item.allowDuplicateEquipment and " · PL" or ""),x-5,y+h+25,w+10,"tiny",UI.COLORS.goldYellow,"center") end
   r.item=item;r.index=v.index;r.source="reserve";Bag.cells[#Bag.cells+1]=r
   if selected then detail=item;entry=v.entry end
   if not Bag.selected and hover then detail=item;entry=v.entry end
  end
  if loadoutTab and Bag.selectedSource=="equipped" then detail=Loadout.equipped(game,Bag.tab,Bag.selected);entry=nil end
  if not detail and #list>0 then local v=list[(Bag.page-1)*Bag.pageSize+1];detail=v.item;entry=v.entry end
  details(UI,game,detail,entry,buttons,mx,my)
  if #list==0 then Bag.icon(532,loadoutTab and 350 or 272,91,115);label(UI,"KHÔNG CÓ MỤC PHÙ HỢP",279,loadoutTab and 490 or 420,591,"small",UI.COLORS.goldYellow,"center");wrapped(UI,Bag.pending and "Không tìm thấy lá gắn được. Chuyển bộ lọc sang MỌI LÁ để kiểm tra hốc hoặc hủy bằng Esc." or "Thử xóa tìm kiếm hoặc đổi bộ lọc. Đồ mua và thu hồi được cất trong ngăn tương ứng.",347,loadoutTab and 526 or 456,454,4,UI.COLORS.textMuted,"small") end
  if loadoutTab and Bag.selected then
   if Bag.tab=="consumable" and Bag.selectedSource~="equipped" and detail and detail.category=="travel_permit" then button(UI,buttons,"bag_use_permit","CHỌN ĐIỂM ĐẾN",594,641,330,38,mx,my,Bag.combat) end
   button(UI,buttons,"bag_loadout_action",Bag.selectedSource=="equipped" and "CẤT VÀO BALO" or "TRANG BỊ VÀO Ô TRỐNG",243,641,337,38,mx,my,Bag.combat and (game.handsRemaining or 0)<=0)
   if Bag.tab=="consumable" and Bag.selectedSource=="equipped" then button(UI,buttons,"bag_use","DÙNG VẬT PHẨM",594,641,330,38,mx,my) end
  elseif Bag.tab=="equipment" and Bag.selected and (game.backpackEquipment or {})[Bag.selected] and not Bag.combat then
   button(UI,buttons,"bag_equip","GẮN VÀO LÁ BÀI",243,641,337,38,mx,my)
   button(UI,buttons,"bag_sell","BÁN · "..B.resale(game.backpackEquipment[Bag.selected]).." VÀNG",594,641,330,38,mx,my)
  elseif Bag.pending then button(UI,buttons,"bag_cancel_equip","← QUAY LẠI TRANG BỊ · ESC",243,641,681,38,mx,my)
  elseif not Bag.combat and Bag.tab=="cards" and UI.Polish.focus and UI.Polish.focus.kind=="card_sale" then
   wrapped(UI,"Thu mua 50% giá trị lá, gồm tiến hóa, ấn bản và trang bị. Trang bị đi cùng lá khi bán.",485,641,439,2,UI.COLORS.goldYellow,"small")
  end
 end
 g.setColor(.046,.052,.057,1);g.rectangle("fill",212,692,1068,28)
 label(UI,Bag.message or "Ctrl+F: tìm · 1–6: đổi ngăn · PgUp/PgDn: trang · Enter: gắn / ghép · I: balo · Esc: quay lại",232,700,1026,"tiny",UI.COLORS.textMuted)
 Q.state(Bag).page=Bag.page
 Slots.drawDrag(UI,Bag)
 g.pop()
end
function Bag.beginEquip(game)
 local item=Bag.selected and B.item((game.backpackEquipment or {})[Bag.selected])
 if not item or Bag.combat then return false end
 local index=Bag.selected;Bag.equipReturnPage=Bag.page;Q.switch(Bag,"cards")
 local view=Q.state(Bag);Bag.savedCardView={query=view.query,filter=view.filter,page=view.page}
 view.query="";view.filter=2;Bag.page=1;Bag.pending=index;Bag.pendingItem=item
 return true
end
function Bag.cancelEquip()
 local saved=Bag.savedCardView
 Bag.pending=nil;Bag.pendingItem=nil
 Bag.savedCardView=nil;Q.switch(Bag,"equipment");Bag.page=Bag.equipReturnPage or Bag.page
 if saved then for k,v in pairs(saved) do Bag.views.cards[k]=v end end
end
function Bag.mouse(UI,game,buttons,mx,my,mouse,callbacks)
 if not Bag.open then return false end
 if UI.Polish.busy() then return true end
 for _,b in ipairs(buttons) do if mouse==1 and b.id and b.id:sub(1,4)=="bag_" and inside(mx,my,b) and not b.disabled then
  if b.id~="bag_search" and b.id~="bag_search_clear" then Bag.searchFocus=false;love.keyboard.setTextInput(false) end
  if b.id=="bag_close" then if callbacks.cancel then callbacks.cancel() end;Bag.close()
  elseif b.id:sub(1,8)=="bag_tab_" then if Bag.pending then Bag.cancelEquip() end;Q.switch(Bag,b.id:sub(9));Bag.loadoutOffset=0
  elseif b.id=="bag_search" then Bag.searchFocus=true;Bag.searchSelectAll=false;love.keyboard.setTextInput(true)
  elseif b.id=="bag_search_clear" then Q.state(Bag).query="";Q.resetPage(Bag)
  elseif b.id=="bag_sort" then Q.state(Bag).sort=Q.state(Bag).sort%3+1;Q.resetPage(Bag)
  elseif b.id=="bag_filter" then Q.state(Bag).filter=Q.state(Bag).filter%(Bag.filterCount or 1)+1;Q.resetPage(Bag)
  elseif b.id=="bag_use" and Bag.tab=="consumable" and Bag.selectedSource=="equipped" then
   local _,index=Loadout.equipped(game,Bag.tab,Bag.selected);if index and callbacks.activate then callbacks.activate(index) end
  elseif b.id=="bag_use_permit" and callbacks.travel then callbacks.travel(Bag.selected)
  elseif b.id=="bag_loadout_prev" then Bag.loadoutOffset=math.max(0,(Bag.loadoutOffset or 0)-6)
  elseif b.id=="bag_loadout_next" then Bag.loadoutOffset=(Bag.loadoutOffset or 0)+6
  elseif b.id=="bag_loadout_action" then
   if Bag.selectedSource=="equipped" then callbacks.transfer(Bag.tab,"equipped",Bag.selected,nil)
   else
    local limit=Loadout.limit(game,Bag.tab)
    local item=(game[Bag.tab=="spn" and "backpackDeities" or "backpackConsumables"] or {})[Bag.selected]
    if item and Bag.tab=="spn" and item.edition=="negative" then limit=limit+1 end
    local destination;for slot=1,limit do if not Loadout.equipped(game,Bag.tab,slot) then destination=slot;break end end
    if destination then callbacks.transfer(Bag.tab,"reserve",Bag.selected,destination) else Bag.message="Ô đã đầy. Kéo lá lên ô muốn thay thế." end
   end
  elseif b.id=="bag_prev" then Bag.page=math.max(1,Bag.page-1);Bag.selected=nil;Bag.drag=nil;UI.Polish.clearFocus()
  elseif b.id=="bag_next" then Bag.page=math.min(Bag.pages,Bag.page+1);Bag.selected=nil;Bag.drag=nil;UI.Polish.clearFocus()
  elseif b.id:sub(1,9)=="bag_tier_" then Bag.craftTier=tonumber(b.id:sub(10));Bag.page=1;Bag.recipeSelection=nil;Tree.id=nil;Tree.history={}
  elseif b.id:sub(1,11)=="bag_recipe_" then Bag.recipeSelection=tonumber(b.id:sub(12));Tree.select(B.recipes[Bag.recipeSelection].id,true)
  elseif Tree.mouse(b.id) then
  elseif b.id=="bag_view_tree" then
   local eq=B.item(game.backpackEquipment[Bag.selected]);if eq and not eq.soulOnly then Bag.tab="craft";Bag.page=1;Bag.craftTier=0;Tree.select(eq.id);Tree.history={} end
  elseif b.id=="bag_cancel_equip" then Bag.cancelEquip()
  elseif b.id:sub(1,10)=="bag_craft_" and not Bag.combat then Bag.recipeSelection=tonumber(b.id:sub(11));local ok,msg=B.craft(game,B.recipes[tonumber(b.id:sub(11))]);Bag.message=msg;if ok and callbacks.save then callbacks.save() end
  elseif b.id=="bag_equip" and not Bag.combat then Bag.beginEquip(game)
  elseif b.id=="bag_sell" and Bag.selected and not Bag.combat then local entry=game.backpackEquipment[Bag.selected];game.gold=(game.gold or 0)+B.resale(entry);table.remove(game.backpackEquipment,Bag.selected);Bag.selected=nil;if callbacks.save then callbacks.save() end
  elseif b.id:sub(1,11)=="bag_detach_" and not Bag.combat then
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
 if Bag.searchFocus then love.keyboard.setTextInput(false) end;Bag.searchFocus=false
 if (Bag.tab=="spn" or Bag.tab=="consumable") and Slots.press(UI,Bag,game,mx,my,mouse,callbacks) then return true end
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
  Bag.selected=c.index;Bag.selectedSource="reserve"
  if mouse==1 and Bag.tab=="equipment" and not Bag.combat then
   local now=love.timer.getTime();local previous=Bag.lastClick
   Bag.lastClick={index=c.index,time=now}
   if previous and previous.index==c.index and now-previous.time<.35 then Bag.beginEquip(game);return true end
  end
  if Bag.tab=="spn" or Bag.tab=="consumable" then
   if mouse==2 and c.item.category=="travel_permit" and callbacks.travel then callbacks.travel(c.index)
   elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item)
   elseif mouse==1 then Slots.select(UI,Bag,c,Bag.combat);Bag.drag={item=c.item,index=c.index,source="reserve",startX=mx,startY=my,x=mx,y=my,rect=c} end
   return true
  end
  if Bag.tab=="cards" then
   if Bag.pending and mouse==1 then
    local eq=B.item(game.backpackEquipment[Bag.pending]);local oldSpeed=require("src.deck").getCardAttackSpeed(c.item)
    local ok,msg=B.attach(game,Bag.pending,c.item);Bag.message=msg
    if ok then
     local speed=require("src.deck").getCardAttackSpeed(c.item)
     UI.Polish.application(UI,eq,c.item,E.getUsedSlots(c.item).."/"..E.getMaxSlots(c.item).." hốc"..(speed~=oldSpeed and (" · Tốc "..oldSpeed.." → "..speed) or ""),Bag.pocket,c,"equip")
     UI.Polish.applications[#UI.Polish.applications].fixedRect={x=c.x,y=c.y,w=c.w,h=c.h}
     Bag.pending=nil;Bag.pendingItem=nil;Bag.savedCardView=nil;Q.state(Bag).filter=1;Bag.page=1
     for i,v in ipairs(Bag.list(game)) do if v.item==c.item then Bag.page=math.ceil(i/Bag.pageSize);break end end
     if callbacks.save then callbacks.save() end
    end
   elseif mouse==1 and game.shopMode=="cards" and not Bag.combat then UI.Polish.focusItem(c.item,"card_sale",c.index,c)
   elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item) end
  elseif Bag.tab=="consumable" and mouse==2 then callbacks.activate(c.index)
  elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item)
  elseif Bag.tab=="spn" or Bag.tab=="consumable" then UI.Polish.focusItem(c.item,Bag.tab=="spn" and "deity" or "consumable",c.index,c) end
  return true
 end end
 return true
end
function Bag.textinput(text) return Q.text(Bag,text) end
function Bag.key(key)
 if not Bag.open then return false end
 if require("src.ui").Polish.busy() then return true end
 local ctrl=love.keyboard.isDown("lctrl","rctrl")
 if ctrl and key=="f" then if Bag.tab=="craft" then Tree.overview=false end;Bag.searchFocus=true;love.keyboard.setTextInput(true);return true end
 if Bag.searchFocus then
  if ctrl and key=="a" then Bag.searchSelectAll=true
  elseif ctrl and key=="v" then Q.text(Bag,love.system.getClipboardText())
  elseif key=="escape" or key=="return" or key=="kpenter" then Bag.searchFocus=false;Bag.searchSelectAll=false;love.keyboard.setTextInput(false)
  elseif key=="backspace" then if ctrl then Q.state(Bag).query="";Q.resetPage(Bag) else Q.erase(Bag) end end
  return true
 end
 if key=="escape" and Bag.pending then Bag.cancelEquip();return true end
 if key=="escape" and Bag.tab=="craft" and Tree.overview then Tree.mouse("bag_tree_overview");return true end
 if key=="escape" and Bag.tab=="craft" and #Tree.history>0 then Tree.mouse("bag_tree_back");return true end
 local tab=tonumber(key);if tab and tabs[tab] then
  if Bag.combat and tabs[tab][1]=="craft" then return true end
  if Bag.pending then Bag.cancelEquip() end;Q.switch(Bag,tabs[tab][1]);return true
 end
 if key=="pageup" or key=="pagedown" then
  local delta=key=="pageup" and 1 or -1
  if Bag.tab=="craft" and Tree.overview and Tree.viewport then Tree.wheel(Tree.viewport.x+1,Tree.viewport.y+1,delta*4,false);return true end
  return Bag.wheel(0,0,delta)
 end
 if key=="return" or key=="kpenter" then
  if Bag.pending and Bag.selected then for _,c in ipairs(Bag.cells or {}) do if c.index==Bag.selected then Bag.handle(c.x+c.w/2,c.y+c.h/2,1);return true end end end
  local wanted=Bag.tab=="equipment" and "bag_equip" or Bag.tab=="craft" and "bag_craft_" or "bag_loadout_action"
  for _,b in ipairs(Bag.buttons or {}) do if b.id and (b.id==wanted or wanted=="bag_craft_" and b.id:sub(1,10)==wanted) and not b.disabled then Bag.handle(b.x+b.w/2,b.y+b.h/2,1);break end end
  return true
 end
 return false
end
function Bag.wheel(mx,my,delta)
 if not Bag.open then return false end
 if delta==0 then return true end
 if Bag.tab=="craft" and Tree.wheel(mx,my,delta,love.keyboard.isDown("lshift","rshift")) then return true end
 Bag.page=math.max(1,math.min(Bag.pages or 1,Bag.page-(delta>0 and 1 or -1)));Bag.selected=nil
 Bag.drag=nil;Bag.selectedSource=nil
 require("src.ui").Polish.clearFocus();return true
end
return Bag

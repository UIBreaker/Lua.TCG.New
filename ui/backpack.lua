local Bag={open=false,tab="spn",page=1}
local E=require("src.equipment")
local B=require("src.basic_equipment")
local tabs={{"spn","SPN ĐỒNG HÀNH"},{"consumable","TIÊU HAO"},{"equipment","TRANG BỊ"},{"cards","BỘ BÀI"},{"craft","BÀN GHÉP"}}
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
function Bag.show() Bag.open=true;Bag.page=1;Bag.selected=nil;Bag.message=nil;require("src.ui").Polish.clearFocus() end
function Bag.close() Bag.open=false;Bag.pending=nil;require("src.ui").Polish.clearFocus() end
function Bag.list(game)
 local list={}
 if Bag.tab=="spn" then
  for i=1,require("src.deities").getMaxSlots(game) do if (game.deities or {})[i] then list[#list+1]={item=game.deities[i],index=i} end end
 elseif Bag.tab=="consumable" then for i,c in ipairs(game.consumables or {}) do list[#list+1]={item=c,index=i} end
 elseif Bag.tab=="equipment" then for i,id in ipairs(game.backpackEquipment or {}) do if E.ITEMS[id] then list[#list+1]={item=E.ITEMS[id],index=i} end end
 elseif Bag.tab=="cards" then for i,c in ipairs(game.persistentDeck or {}) do list[#list+1]={item=c,index=i} end end
 return list
end
function Bag.rect(kind,index,game)
 if not Bag.open or Bag.tab~=(kind=="spn" and "spn" or "consumable") then return -10000,-10000,1,1 end
 for slot,v in ipairs(Bag.list(game)) do
  if v.index==index and slot>(Bag.page-1)*10 and slot<=Bag.page*10 then
   local n=(slot-1)%10;return 380+(n%5)*148,191+math.floor(n/5)*182,96,144
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
function Bag.draw(UI,game,buttons,mx,my,drawConsumable)
 if not Bag.open then return end
 UI.CardPhysics.blockBehind()
 for i=#buttons,1,-1 do buttons[i]=nil end
 local g=love.graphics;g.setColor(.005,.008,.012,.83);g.rectangle("fill",0,0,1280,720)
 -- An expedition satchel: leather perimeter, stitched seams and brass rivets.
 g.setColor(.18,.115,.065,1);UI.drawRoundedRect("fill",90,73,1100,574,22)
 g.setColor(.045,.05,.055,1);UI.drawRoundedRect("fill",105,90,1070,541,14)
 g.setColor(.5,.35,.19,1);g.setLineWidth(2);UI.drawRoundedRect("line",98,82,1084,555,18)
 for x=120,1154,14 do g.line(x,84,x+5,84);g.line(x,637,x+5,637) end
 for y=105,618,14 do g.line(98,y,98,y+5);g.line(1182,y,1182,y+5) end
 for _,x in ipairs({106,1173}) do for _,y in ipairs({93,626}) do g.setColor(.75,.57,.29,1);g.circle("fill",x,y,4);g.setColor(.25,.17,.09,1);g.line(x-2,y,x+2,y) end end
 label(UI,"BALO VIỄN CHINH",125,112,480,"medium",UI.COLORS.goldYellow)
 label(UI,"SPN "..require("src.deities").getCount(game.deities).."/"..require("src.deities").getMaxSlots(game).." · Tiêu hao "..#(game.consumables or {}).."/"..require("src.inventory").limit(game),620,120,420,"small",UI.COLORS.textMuted,"right")
 button(UI,buttons,"bag_close","ĐÓNG",1062,105,90,35,mx,my)
 g.setColor(.11,.075,.045,1);UI.drawRoundedRect("fill",120,160,222,455,12)
 -- Coin pocket and an understated fan of cards, all counters remain live.
 for i=1,5 do g.setColor(.65,.43,.12,1);g.ellipse("fill",151+i*10,193-i%2*5,13,7);g.setColor(.97,.78,.35,1);g.ellipse("line",151+i*10,191-i%2*5,13,7) end
 label(UI,tostring(game.gold or 0).." VÀNG",134,218,194,"medium",UI.COLORS.goldYellow,"center")
 label(UI,tostring(game.souls or 0).." linh hồn · "..#(game.persistentDeck or {}).." lá bài",133,252,196,"tiny",UI.COLORS.textMuted,"center")
 for i,t in ipairs(tabs) do button(UI,buttons,"bag_tab_"..t[1],(Bag.tab==t[1] and "› " or "")..t[2],135,280+(i-1)*47,192,37,mx,my) end
 label(UI,"Gắn: 1 hốc / nguyên liệu\nTháo và ghép tại cửa hàng\nGhép dùng đồ rời trong balo",137,534,192,"tiny",UI.COLORS.textMuted)
 label(UI,Bag.pending and "CHỌN LÁ BÀI ĐỂ GẮN TRANG BỊ" or ({spn="Hộ linh đồng hành",consumable="Dược liệu và thẻ hỗ trợ",equipment="Nguyên liệu và di vật",cards="Đoàn viễn chinh",craft="Ghép hai nguyên liệu thành trang bị lớn"})[Bag.tab],380,155,760,"small",UI.COLORS.goldYellow)
 if Bag.tab=="craft" then
  for i,r in ipairs(B.recipes) do
   local y=188+(i-1)*65;local d=E.ITEMS[r.id]
   g.setColor(.1,.13,.14,1);UI.drawRoundedRect("fill",373,y,780,59,7)
   local image=UI.getEquipmentImage(d.id)
   if image then g.setColor(1,1,1);UI.CardFrame.image(image,384,y+4,32,48) end
   label(UI,d.name,428,y+6,200,"small",d.color)
   label(UI,E.ITEMS[r.ingredients[1]].name.." + "..E.ITEMS[r.ingredients[2]].name,428,y+29,280,"tiny")
   label(UI,d.statSummary,724,y+9,235,"tiny",d.color)
   label(UI,B.count(game,r.ingredients[1]).." / 1  ·  "..B.count(game,r.ingredients[2]).." / 1",724,y+31,235,"tiny",UI.COLORS.textMuted)
   button(UI,buttons,"bag_craft_"..i,"GHÉP ◉"..r.fee,1000,y+12,138,34,mx,my,not B.canCraft(game,r))
  end
 else
  local list=Bag.list(game);Bag.pages=math.max(1,math.ceil(#list/10));Bag.page=math.max(1,math.min(Bag.page,Bag.pages))
  Bag.cells={}
  for slot=(Bag.page-1)*10+1,math.min(#list,Bag.page*10) do
   local v=list[slot];local n=(slot-1)%10;local x,y=380+n%5*148,191+math.floor(n/5)*182
   g.setColor(.14,.105,.07,.65);UI.drawRoundedRect("fill",x-8,y-7,112,173,8)
   local hovered=mx>=x and mx<=x+96 and my>=y and my<=y+144
   local item=v.item
   if Bag.tab=="spn" then
    item.slotIndex=v.index
    local Deities=require("src.deities")
    local copyTarget=item.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities,v.index)
    UI.drawPatronCard(item,x,y,96,144,hovered,false,false,copyTarget)
   elseif Bag.tab=="consumable" then drawConsumable(item,x,y,96,144,v.index,mx,my)
   elseif Bag.tab=="cards" then UI.drawCard(item,x,y,96,144,hovered)
   else
    local img=UI.getEquipmentImage(item.id)
    if img then g.setColor(1,1,1);UI.CardFrame.image(img,x,y,96,144) end
    UI.drawCardBorder(x,y,96,144,hovered and UI.COLORS.goldYellow,nil,item)
    Bag.stats(UI,item,x,y,96,144)
   end
   label(UI,Bag.tab=="cards" and ((item.rankName or "")..(item.suitSymbol or "")) or item.name,x-6,y+147,108,"tiny",item.color,"center")
   if Bag.selected==v.index then g.setColor(UI.COLORS.goldYellow);g.setLineWidth(2);UI.drawRoundedRect("line",x-8,y-7,112,173,8) end
   local b={x=x,y=y,w=96,h=144,item=item,index=v.index};Bag.cells[#Bag.cells+1]=b
   if hovered then UI.descriptionCandidate=item end
  end
  if #list==0 then label(UI,"Ngăn này còn trống.\nĐồ đã mua sẽ được cất vào đúng ngăn.",480,325,560,"medium",UI.COLORS.textMuted,"center") end
  button(UI,buttons,"bag_prev","←",1020,151,40,28,mx,my,Bag.page<=1)
  button(UI,buttons,"bag_next","→",1110,151,40,28,mx,my,Bag.page>=Bag.pages)
  label(UI,Bag.page.."/"..Bag.pages,1065,157,42,"tiny",nil,"center")
  if Bag.tab=="equipment" and Bag.selected and (game.backpackEquipment or {})[Bag.selected] then
   button(UI,buttons,"bag_equip","GẮN VÀO LÁ BÀI",380,561,218,36,mx,my)
   local d=E.ITEMS[game.backpackEquipment[Bag.selected]]
   button(UI,buttons,"bag_sell","BÁN ◉"..math.floor(d.cost/3),612,561,145,36,mx,my)
  elseif Bag.tab=="spn" and Bag.selected then
   button(UI,buttons,"bag_spn_left","← ĐỔI VỊ TRÍ",380,561,218,36,mx,my,Bag.selected<=1)
   button(UI,buttons,"bag_spn_right","ĐỔI VỊ TRÍ →",612,561,218,36,mx,my,Bag.selected>=require("src.deities").getMaxSlots(game))
  elseif Bag.tab=="cards" and Bag.selected then
   local c=game.persistentDeck[Bag.selected]
   for i,eq in ipairs(c and c.equipments or {}) do button(UI,buttons,"bag_detach_"..i,"THÁO "..eq.name,380+(i-1)*252,561,240,36,mx,my) end
  end
 end
 label(UI,Bag.message or (Bag.tab=="consumable" and "Nhấp chọn để bán · Chuột phải để dùng" or Bag.tab=="spn" and "Nhấp chọn để bán · Hiệu ứng vẫn hoạt động khi cất trong balo" or "Mua nguyên liệu → cất vào balo → ghép hoặc gắn lên lá bài"),380,611,760,"tiny",UI.COLORS.textMuted)
end
function Bag.mouse(UI,game,buttons,mx,my,mouse,callbacks)
 if not Bag.open then return false end
 if UI.Polish.busy() then return true end
 for _,b in ipairs(buttons) do if mouse==1 and b.id and b.id:sub(1,4)=="bag_" and inside(mx,my,b) and not b.disabled then
  if b.id=="bag_close" then if callbacks.cancel then callbacks.cancel() end;Bag.close()
  elseif b.id:sub(1,8)=="bag_tab_" then Bag.tab=b.id:sub(9);Bag.page=1;Bag.selected=nil;Bag.pending=nil;UI.Polish.clearFocus()
  elseif b.id=="bag_prev" then Bag.page=math.max(1,Bag.page-1);Bag.selected=nil;UI.Polish.clearFocus()
  elseif b.id=="bag_next" then Bag.page=math.min(Bag.pages,Bag.page+1);Bag.selected=nil;UI.Polish.clearFocus()
  elseif b.id:sub(1,10)=="bag_craft_" then local ok,msg=B.craft(game,B.recipes[tonumber(b.id:sub(11))]);Bag.message=msg;if ok and callbacks.save then callbacks.save() end
  elseif b.id=="bag_equip" then Bag.pending=Bag.selected;Bag.selected=nil;Bag.tab="cards";Bag.page=1
  elseif b.id=="bag_spn_left" or b.id=="bag_spn_right" then
   local target=Bag.selected+(b.id=="bag_spn_left" and -1 or 1)
   game.deities[Bag.selected],game.deities[target]=game.deities[target],game.deities[Bag.selected]
   Bag.selected=target;UI.Polish.clearFocus();if callbacks.save then callbacks.save() end
  elseif b.id=="bag_sell" and Bag.selected then local d=E.ITEMS[game.backpackEquipment[Bag.selected]];game.gold=(game.gold or 0)+math.floor(d.cost/3);table.remove(game.backpackEquipment,Bag.selected);Bag.selected=nil;if callbacks.save then callbacks.save() end
  elseif b.id:sub(1,11)=="bag_detach_" then B.detach(game,game.persistentDeck[Bag.selected],tonumber(b.id:sub(12)));if callbacks.save then callbacks.save() end end
  return true
 end end
 for _,c in ipairs(Bag.cells or {}) do if inside(mx,my,c) then
  if mouse==1 and (Bag.tab=="cards" or Bag.tab=="spn") and callbacks.target and callbacks.target(c.item) then return true end
  Bag.selected=c.index
  if Bag.tab=="cards" then
   if Bag.pending then local ok,msg=B.attach(game,Bag.pending,c.item);Bag.message=msg;if ok then Bag.pending=nil;if callbacks.save then callbacks.save() end end
   elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item) end
  elseif Bag.tab=="consumable" and mouse==2 then callbacks.activate(c.index)
  elseif mouse==2 and callbacks.inspect then callbacks.inspect(c.item)
  elseif Bag.tab=="spn" or Bag.tab=="consumable" then UI.Polish.focusItem(c.item,Bag.tab=="spn" and "deity" or "consumable",c.index,c) end
  return true
 end end
 if mx<90 or mx>1190 or my<73 or my>647 then if callbacks.cancel then callbacks.cancel() end;Bag.close() end
 return true
end
return Bag

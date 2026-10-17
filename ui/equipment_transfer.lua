local T={page=1,onlyCompatible=true,query=""}
local E=require("src.equipment")
local Shop=require("src.shop")
local Deck=require("src.deck")
local Q=require("ui.backpack_qol")
local Style=require("ui.backpack_style")
local Core=require("ui.components.core")
local Sound=require("src.sound")
local utf8=require("utf8")
local function inside(x,y,r)return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
local function text(UI,value,x,y,w,size,color,align)
 Core.textLine(value,x,y,w,UI.fonts[size or "small"],color or UI.COLORS.textLight,align or "left",UI.fonts.tiny)
end
local function name(card)
 local d=require("src.card_abilities").definition(card)
 return d and (d.characterName:match("^(.-) ·") or d.characterName) or card.name or (card.rankName or "")..(card.suitSymbol or "")
end
function T.reset()
 T.source=nil;T.eqIndex=nil;T.page=1;T.query="";T.onlyCompatible=true;T.searchFocus=false;T.message=nil;T.history=nil;T.lastTarget=nil;T.rects={}
end
function T.selectedEquipment()return T.source and (T.source.equipments or {})[T.eqIndex] end
function T.selectSource(card)
 if #(card.equipments or {})==0 then T.message="Lá nguồn cần có trang bị đang gắn.";return false end
 T.source=card;T.eqIndex=#card.equipments==1 and 1 or nil;T.page=1;T.query="";T.searchFocus=false;T.message=nil;T.lastTarget=nil
 return true
end
function T.list(cards)
 local list={};local eq=T.selectedEquipment()
 for i,card in ipairs(cards) do
  local allowed=not T.source and #(card.equipments or {})>0 or T.source and card~=T.source
  if allowed and eq and T.onlyCompatible then allowed=E.canAttach(card,eq) end
  if allowed and Q.matches(card,T.query) then list[#list+1]={card=card,index=i} end
 end
 return list
end
local function owns(game,card)
 for _,c in ipairs(game.persistentDeck or T.deck or {}) do if c==card then return true end end
 return false
end
function T.move(game,target,UI,save)
 local eq=T.selectedEquipment();local source=T.source;local index=T.eqIndex
 if not eq or not owns(game,source) or not owns(game,target) then T.message="Chọn lại lá nguồn và trang bị còn trong bộ.";return false end
 local ok,message=Shop.transferEquipment(source,index,target);T.message=message
 if not ok then Sound.play("cant_afford");return false end
 T.history={source=source,target=target,eq=eq,index=index};T.lastTarget=target
 T.eqIndex=#source.equipments>0 and math.min(index,#source.equipments) or nil
 if UI then
  local from=T.equipmentRects and T.equipmentRects[index];local to=T.rects[target]
  UI.Polish.application(UI,eq,target,"Đã nhận · "..E.getUsedSlots(target).."/"..E.getMaxSlots(target).." hốc",from,to,"equip")
  if to then UI.Polish.applications[#UI.Polish.applications].fixedRect=to end
 end
 if save then save() end
 return true
end
function T.undo(game,UI,save)
 local h=T.history;if not h or not owns(game,h.source) or not owns(game,h.target) then return false end
 local index;for i,eq in ipairs(h.target.equipments or {}) do if eq==h.eq then index=i;break end end
 if not index then T.message="Trang bị đã đổi vị trí; hãy chọn lại nguồn.";return false end
 local ok,message=Shop.transferEquipment(h.target,index,h.source);T.message=message
 if not ok then return false end
 table.remove(h.source.equipments,#h.source.equipments);table.insert(h.source.equipments,math.min(h.index,#h.source.equipments+1),h.eq)
 T.source=h.source;T.eqIndex=h.index;T.history=nil;T.lastTarget=nil;T.message="Đã hoàn tác lần chuyển vừa rồi."
 if UI then UI.Polish.application(UI,h.eq,h.source,T.message,T.rects[h.target],{x=83,y=192,w=150,h=225},"equip") end
 if save then save() end;return true
end
function T.draw(UI,game,cards,buttons,mx,my)
 local g=love.graphics;T.deck=cards;T.buttons=buttons;T.rects={};T.equipmentRects={}
 UI.CardPhysics.blockBehind();UI.descriptionCandidate=nil;T.hoverEquipment=nil;g.push("all");g.setShader();g.setScissor();g.setBlendMode("alpha")
 Style.background(UI.Polish.time)
 local gold=UI.COLORS.goldYellow;local muted=UI.COLORS.textMuted
 Style.glyph("equipment",45,48,18,gold)
 text(UI,"HOÁN ĐỔI TRANG BỊ",80,24,710,"large",gold)
 text(UI,"XƯỞNG VIỄN CHINH · Chuyển miễn phí · Mỗi lần một món · Có thể hoàn tác",80,72,860,"tiny",muted)
 local function button(id,label,x,y,w,h,disabled,active,data)
  local b={id=id,text=label,x=x,y=y,w=w,h=h,disabled=disabled,font=UI.fonts.tiny,color=active and {.34,.29,.18,1} or UI.COLORS.btnSpecial,data=data}
  buttons[#buttons+1]=b;UI.drawButton(b,not disabled and inside(mx,my,b));return b
 end
 button("close_shop_transfer","XONG · VỀ CỬA HÀNG",1028,30,228,42)
 Style.panel(24,126,270,526,gold,true);Style.panel(310,126,300,526,{.49,.74,.82},true);Style.panel(626,126,630,526,gold,true)
 for i,v in ipairs({{44,"LÁ NGUỒN"},{330,"TRANG BỊ ĐANG MANG"},{646,T.source and "LÁ NHẬN TRANG BỊ" or "CHỌN LÁ NGUỒN"}}) do
  text(UI,"0"..i.."  /  "..v[2],v[1],145,i==3 and 590 or 260,"tiny",gold)
 end
 if T.source then
  local r={x=83,y=192,w=150,h=225};T.rects[T.source]=r
  Style.glow(158,300,110,gold,.16);UI.drawCard(T.source,r.x,r.y,r.w,r.h,false)
  buttons[#buttons+1]={id="transfer_source_detail",x=r.x,y=r.y,w=r.w,h=r.h,data=T.source,invisible=true}
  text(UI,name(T.source),44,442,230,"medium",gold,"center")
  text(UI,(T.source.rankName or "")..(T.source.suitSymbol or "").." · Tốc "..Deck.getCardAttackSpeed(T.source),44,475,230,"small",nil,"center")
  local used,max=E.getUsedSlots(T.source),E.getMaxSlots(T.source)
  text(UI,"Hốc trang bị: "..used.." / "..max,44,507,230,"small",UI.COLORS.chipsBlue,"center")
  for i=1,max do g.setColor(i<=used and gold or {.23,.30,.31,1});g.rectangle("fill",49+(i-1)*27,543,21,6,2,2) end
  button("transfer_reset","← ĐỔI LÁ NGUỒN",44,592,230,38)
 else
  require("ui.backpack").icon(123,260,70,88)
  text(UI,"Chọn quân bài đang mang",44,395,230,"small",muted,"center")
  text(UI,"trang bị ở bên phải.",44,420,230,"small",muted,"center")
 end
 text(UI,T.source and #T.source.equipments.." món · Nhấp để chọn" or "Trang bị hiện ở đây sau khi chọn nguồn",328,173,264,"tiny",muted)
 for index,eq in ipairs(T.source and T.source.equipments or {}) do
  local x,y=326+(index-1)%2*138,198+math.floor((index-1)/2)*108
  local r=button("transfer_equipment_"..index,"",x,y,130,100,false,T.eqIndex==index,index);T.equipmentRects[index]=r
  r.cardSurface=true
  Style.panel(x,y,130,100,eq.color,T.eqIndex==index)
  local img=UI.getEquipmentImage(eq.id)
  if img then g.setColor(1,1,1,1);require("ui.card_surfaces").image(eq,x+6,y+6,40,60,img) end
  local _,lines=UI.fonts.tiny:getWrap(eq.name,74)
  for row=1,math.min(3,#lines) do text(UI,lines[row],x+51,y+9+(row-1)*15,74,"tiny",eq.color) end
  text(UI,(eq.slotsNeeded or 1).." hốc · T"..E.getTier(eq),x+51,y+54,74,"tiny",muted)
  text(UI,eq.statSummary or E.getDescription(eq),x+7,y+77,116,"tiny",UI.COLORS.textLight)
  if inside(mx,my,r) then T.hoverEquipment=eq end
 end
 if T.source and #T.source.equipments==0 then text(UI,"Đã chuyển hết trang bị.",329,348,261,"small",muted,"center") end
 local eq=T.selectedEquipment()
 button("transfer_search","",644,176,T.query~="" and 242 or 276,28,false,T.searchFocus)
 if T.query~="" then button("transfer_clear","×",890,176,30,28) end
 local shown=T.query;while UI.fonts.tiny:getWidth(shown)>225 do shown=shown:sub(utf8.offset(shown,2)) end
 text(UI,shown~="" and shown or "Tìm tên nhân vật / bậc / khả năng…",653,185,225,"tiny",shown~="" and UI.COLORS.textLight or muted)
 button("transfer_filter",T.source and (T.onlyCompatible and "CHỈ LÁ GẮN ĐƯỢC" or "MỌI LÁ NHẬN") or "LÁ CÓ TRANG BỊ",928,176,170,28,not eq,T.onlyCompatible)
 local list=T.list(cards);local pages=math.max(1,math.ceil(#list/8));T.page=math.max(1,math.min(T.page,pages));T.pages=pages
 button("transfer_prev","←",1108,176,36,28,T.page<=1)
 text(UI,T.page.."/"..pages,1147,185,52,"tiny",muted,"center")
 button("transfer_next","→",1204,176,36,28,T.page>=pages)
 for pos=(T.page-1)*8+1,math.min(#list,T.page*8) do
  local v=list[pos];local slot=(pos-1)%8;local x,y=642+slot%4*151,218+math.floor(slot/4)*210
  local valid,reason;if eq then valid,reason=E.canAttach(v.card,eq) end;local active=eq and valid
  Style.panel(x,y,140,202,active and UI.COLORS.hpGreen or {.34,.39,.38,1},inside(mx,my,{x=x,y=y,w=140,h=202}))
  local r={x=x+20,y=y+8,w=100,h=150};T.rects[v.card]=r
  UI.drawCard(v.card,r.x,r.y,r.w,r.h,false)
  text(UI,name(v.card),x+6,y+163,128,"tiny",gold,"center")
  local status=active and " · NHẬN ĐƯỢC" or eq and (reason and reason:find("cùng loại",1,true) and " · TRÙNG LOẠI" or " · THIẾU HỐC") or " hốc"
  text(UI,E.getUsedSlots(v.card).."/"..E.getMaxSlots(v.card)..status,x+4,y+181,132,"tiny",active and UI.COLORS.hpGreen or eq and {.85,.48,.4,1} or muted,"center")
  buttons[#buttons+1]={id="transfer_card_"..v.index,x=x,y=y,w=140,h=202,data=v.card,invisible=true}
 end
 if #list==0 then
  local solo=T.source and #cards==1 and T.query==""
  text(UI,solo and "Bộ bài đang chỉ có một lá." or T.source and "Không có lá nhận phù hợp." or "Chưa có quân bài nào đang mang trang bị.",652,370,588,"small",gold,"center")
  text(UI,solo and "Cần thêm quân bài để chuyển. Có thể tháo đồ về balo trong ngăn Bộ bài." or T.source and "Đổi món ở giữa, đổi bộ lọc hoặc xóa tìm kiếm." or "Gắn trang bị trong balo rồi quay lại xưởng.",652,402,588,"tiny",muted,"center")
 end
 button("transfer_undo","HOÀN TÁC LẦN CUỐI",24,670,230,32,not T.history)
 text(UI,T.message or (eq and "Nhấp một lá nhận để chuyển ngay. Chuột phải xem chi tiết." or "Chọn nguồn → chọn món → nhấp lá nhận. Ctrl+F tìm · PgUp/PgDn trang · Esc quay lại"),272,681,982,"tiny",T.message and gold or muted)
 UI.descriptionCandidate=T.hoverEquipment
 g.pop()
end
function T.press(UI,game,x,y,mouse,callbacks)
 for _,b in ipairs(T.buttons or {}) do if inside(x,y,b) then
  if mouse==2 then
   local item=type(b.data)=="table" and b.data or b.id:match("^transfer_equipment_") and T.source and (T.source.equipments or {})[b.data]
   if item and callbacks.inspect then callbacks.inspect(item) end
   return true
  end
  if mouse~=1 or b.disabled then return true end
  T.searchFocus=b.id=="transfer_search";love.keyboard.setTextInput(T.searchFocus)
  if b.id=="close_shop_transfer" then callbacks.close()
  elseif b.id=="transfer_reset" then T.source=nil;T.eqIndex=nil;T.page=1;T.query="";T.message=nil
  elseif b.id=="transfer_prev" then T.page=math.max(1,T.page-1)
  elseif b.id=="transfer_next" then T.page=math.min(T.pages,T.page+1)
  elseif b.id=="transfer_filter" then T.onlyCompatible=not T.onlyCompatible;T.page=1
  elseif b.id=="transfer_clear" then T.query="";T.page=1
  elseif b.id=="transfer_undo" then T.undo(game,UI,callbacks.save)
  elseif b.id:match("^transfer_equipment_") then T.eqIndex=b.data;T.message=nil;T.page=1
  elseif b.id:match("^transfer_card_") then
   if not T.source then T.selectSource(b.data)
   elseif T.selectedEquipment() then T.move(game,b.data,UI,callbacks.save)
   else T.message="Chọn một trang bị ở khu giữa trước khi chọn lá nhận." end
  end
  return true
 end end
 return true
end
function T.textinput(value)
 if not T.searchFocus then return false end
 local query=T.query..value;if utf8.len(query)>60 then query=query:sub(1,utf8.offset(query,61)-1) end
 T.query=query;T.page=1;return true
end
function T.key(key)
 if love.keyboard.isDown("lctrl","rctrl") and key=="f" then T.searchFocus=true;love.keyboard.setTextInput(true);return true end
 if T.searchFocus then
  if key=="escape" or key=="return" then T.searchFocus=false;love.keyboard.setTextInput(false)
  elseif key=="backspace" then local at=utf8.offset(T.query,-1);if at then T.query=T.query:sub(1,at-1);T.page=1 end end
  return true
 end
 if key=="escape" and T.source then T.source=nil;T.eqIndex=nil;T.page=1;T.query="";return true end
 if key=="pageup" then T.page=math.max(1,T.page-1);return true end
 if key=="pagedown" then T.page=math.min(T.pages or 1,T.page+1);return true end
 return false
end
return T

local T={history={},upgradePage=1,zoom=1,panX=0,panY=0}
local E=require("src.equipment")
local B=require("src.basic_equipment")
local Style=require("ui.backpack_style")
local function inside(x,y,r) return x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h end
function T.ingredients(id)
 local out,seen={},{}
 for _,key in ipairs(B.byResult[id] and B.byResult[id].ingredients or {}) do
  if not seen[key] then seen[key]={id=key,count=0};out[#out+1]=seen[key] end
  seen[key].count=seen[key].count+1
 end
 return out
end
function T.upgrades(id)
 local out={}
 for i,r in ipairs(B.recipes) do
  for _,key in ipairs(r.ingredients) do if key==id then out[#out+1]={id=r.id,index=i};break end end
 end
 table.sort(out,function(a,b) local ra,rb=B.byResult[a.id],B.byResult[b.id];return ra.tier==rb.tier and a.index<b.index or ra.tier<rb.tier end)
 return out
end
function T.select(id,remember)
 if not E.ITEMS[id] or E.ITEMS[id].soulOnly then return end
 if remember and T.id and T.id~=id then T.history[#T.history+1]=T.id end
 T.id=id;T.overview=false;T.upgradePage=1;T.panX=0;T.panY=0
end
-- Keep occurrences separate: a component required in two branches must be made twice.
function T.build(id)
 local nodes,edges,raw,totals={}, {}, {}, {};local leaves,maxDepth=0,0
 local function visit(key,count,depth,parent)
  local node={id=key,count=count,depth=depth};nodes[#nodes+1]=node
  totals[key]=(totals[key] or 0)+count;maxDepth=math.max(maxDepth,depth)
  if parent then edges[#edges+1]={from=node,to=parent} end
  local children=T.ingredients(key)
  if #children==0 then leaves=leaves+1;node.y=(leaves-1)*76;raw[key]=(raw[key] or 0)+count
  else
   local first,last
   for _,v in ipairs(children) do local child=visit(v.id,v.count*count,depth+1,node);first=first or child.y;last=child.y end
   node.y=(first+last)/2
  end
  return node
 end
 visit(id,1,0)
 for _,n in ipairs(nodes) do n.x=(maxDepth-n.depth)*190 end
 return {nodes=nodes,edges=edges,raw=raw,totals=totals,w=maxDepth*190+164,h=math.max(62,leaves*76-14)}
end
function T.overviewModel(id)
 local expanded=T.build(id);local nodes,byId,columns={}, {}, {};local maxDepth,maxRows=0,0
 for _,n in ipairs(expanded.nodes) do
  local node=byId[n.id]
  if not node then node={id=n.id,count=expanded.totals[n.id],depth=n.depth};nodes[#nodes+1]=node;byId[n.id]=node else node.depth=math.max(node.depth,n.depth) end
  maxDepth=math.max(maxDepth,n.depth)
 end
 for _,n in ipairs(nodes) do
  if E.ITEMS[n.id].basic then n.depth=maxDepth end
  columns[n.depth]=columns[n.depth] or {};table.insert(columns[n.depth],n);maxRows=math.max(maxRows,#columns[n.depth])
 end
 local h=maxRows*80-14
 for depth,column in pairs(columns) do for i,n in ipairs(column) do n.x=(maxDepth-depth)*210;n.y=(h-(#column*80-14))/2+(i-1)*80 end end
 local edges,seen={},{}
 for _,e in ipairs(expanded.edges) do local key=e.from.id..":"..e.to.id;if not seen[key] then seen[key]=true;edges[#edges+1]={from=byId[e.from.id],to=byId[e.to.id]} end end
 return {nodes=nodes,edges=edges,raw=expanded.raw,totals=expanded.totals,w=maxDepth*210+184,h=h}
end
local function text(UI,s,x,y,w,color,size,align)
 love.graphics.setFont(UI.fonts[size or "tiny"]);love.graphics.setColor(color or UI.COLORS.textLight);love.graphics.printf(s,x,y,w,align or "left")
end
local function button(UI,buttons,id,s,x,y,w,h,mx,my,disabled)
 local b={id=id,text=s,x=x,y=y,w=w,h=h,font=UI.fonts.tiny,color=UI.COLORS.btnSpecial,disabled=disabled}
 buttons[#buttons+1]=b;UI.drawButton(b,inside(mx,my,b));return b
end
local function art(UI,id,x,y,w,h)
 local image=UI.getEquipmentImage(id);love.graphics.setColor(1,1,1)
 if image then UI.CardFrame.image(image,x,y,w,h);UI.drawCardBorder(x,y,w,h,nil,nil,E.ITEMS[id]) end
end
local function node(UI,game,buttons,id,count,x,y,w,h,mx,my,upgrade)
 local d=E.ITEMS[id];local g=love.graphics;local owned=B.count(game,id);local enough=owned>=count
 local r={x=x,y=y,w=w,h=h};local hovered=inside(mx,my,r)
 if hovered then UI.descriptionCandidate=d end
 local c=E.getTierColor(d);Style.panel(x,y,w,h,c,hovered)
 local ready=upgrade and B.canCraft(game,B.byResult[id]) or not upgrade and enough
 local status=ready and UI.COLORS.hpGreen or upgrade and UI.COLORS.goldYellow or {.93,.60,.44,1}
 g.setColor(status[1],status[2],status[3],.08);g.rectangle("fill",x+49,y+h-21,w-55,17,3,3)
 g.setColor(c[1],c[2],c[3],.7);g.line(x+7,y+12,x+7,y+h-12)
 art(UI,id,x+8,y+8,36,54)
 text(UI,d.name,x+52,y+9,w-60,c)
 text(UI,d.basic and "NGUYÊN LIỆU" or "TẦNG "..E.getTier(d),x+52,y+h-35,w-60,UI.COLORS.textMuted)
 text(UI,upgrade and ((ready and "Sẵn sàng · " or "Công ghép: ")..B.byResult[id].fee.." vàng  ›") or ("Có "..owned.." / Cần "..count..(enough and "  ✓" or "")),x+52,y+h-18,w-60,status)
 buttons[#buttons+1]={id="bag_node_"..id,x=x,y=y,w=w,h=h,invisible=true}
end
function T.draw(UI,game,buttons,mx,my)
 local g=love.graphics;local d=E.ITEMS[T.id];if not d then return end
 local r=B.byResult[T.id]
 local left=T.overview and 228 or 480
 text(UI,"XƯỞNG CHẾ TÁC / "..(d.basic and "NGUYÊN LIỆU" or "TẦNG "..E.getTier(d))..(T.overview and " · "..d.name or ""),left,139,1010,UI.COLORS.goldYellow,"small")
 button(UI,buttons,"bag_tree_back","← TRỞ LẠI",left,174,115,30,mx,my,#T.history==0)
 button(UI,buttons,"bag_tree_overview",T.overview and "CÂY GẦN" or "TOÀN BỘ CÂY",left+125,174,135,30,mx,my,d.basic)
 text(UI,"Nhấn vào một nút để xem công thức và nhánh nâng cấp",left+271,181,500,UI.COLORS.textMuted)
 if T.overview then
  local model=T.overviewModel(T.id);T.model=model
  local viewport={x=228,y=218,w=1028,h=394};T.viewport=viewport
  button(UI,buttons,"bag_tree_minus","−",1105,618,32,28,mx,my,T.zoom<=.4)
  button(UI,buttons,"bag_tree_plus","+",1142,618,32,28,mx,my,T.zoom>=1.6)
  button(UI,buttons,"bag_tree_fit","VỪA CÂY",1179,618,77,28,mx,my)
  button(UI,buttons,"bag_tree_left","←",228,618,32,28,mx,my)
  button(UI,buttons,"bag_tree_right","→",265,618,32,28,mx,my)
  text(UI,"Lăn chuột: cuộn cây · Shift + lăn: sang ngang · "..math.floor(T.zoom*100).."%",313,627,750,UI.COLORS.textMuted)
  T.panX=math.max(math.min(0,viewport.w-model.w*T.zoom-24),math.min(0,T.panX))
  T.panY=math.max(math.min(0,viewport.h-model.h*T.zoom-24),math.min(0,T.panY))
  local ox=viewport.x+math.max(12,(viewport.w-model.w*T.zoom)/2)+T.panX
  local oy=viewport.y+math.max(12,(viewport.h-model.h*T.zoom)/2)+T.panY
  local sx,sy,sw,sh=g.getScissor()
  -- Scissor uses physical coordinates; all node hit boxes remain in virtual coordinates.
  local px,py=g.transformPoint(viewport.x,viewport.y);local ex,ey=g.transformPoint(viewport.x+viewport.w,viewport.y+viewport.h)
  g.setScissor(px,py,ex-px,ey-py);g.push();g.translate(ox,oy);g.scale(T.zoom)
  for _,edge in ipairs(model.edges) do local a,b=edge.from,edge.to;local x=a.x+184;local bend=(x+b.x)/2;Style.link({x,a.y+33,bend,a.y+33,bend,b.y+33,b.x,b.y+33},E.getTierColor(E.ITEMS[b.id]),B.count(game,a.id)>=a.count,UI.Polish.time) end
  for _,n in ipairs(model.nodes) do
   node(UI,game,{},n.id,n.count,n.x,n.y,184,66,(mx-ox)/T.zoom,(my-oy)/T.zoom)
   local box={id="bag_node_"..n.id,x=ox+n.x*T.zoom,y=oy+n.y*T.zoom,w=184*T.zoom,h=66*T.zoom,invisible=true}
   local bx,by=math.max(box.x,viewport.x),math.max(box.y,viewport.y)
   box.w=math.min(box.x+box.w,viewport.x+viewport.w)-bx;box.h=math.min(box.y+box.h,viewport.y+viewport.h)-by;box.x=bx;box.y=by
   if box.w>0 and box.h>0 then buttons[#buttons+1]=box end
  end
  g.pop();g.setScissor(sx,sy,sw,sh)
  text(UI,"ĐỂ LÀM TỪ ĐẦU",228,657,153,UI.COLORS.goldYellow)
  local x,y=376,653
  for _,id in ipairs(B.basic) do if model.raw[id] then
   local value=E.ITEMS[id].name.." ×"..model.raw[id];local w=UI.fonts.tiny:getWidth(value)+18
   if x+w>1256 then x=228;y=y+20 end
   local c=B.count(game,id)>=model.raw[id] and UI.COLORS.hpGreen or UI.COLORS.textMuted
   g.setColor(c[1],c[2],c[3],.07);g.rectangle("fill",x,y,w,17,4,4)
   text(UI,value,x+9,y+3,w-18,c);x=x+w+7
  end end
  return
 end
 T.viewport=nil
 for i,step in ipairs({{480,"THÀNH PHẦN"},{719,"THÀNH PHẨM"},{969,"NÂNG CẤP TIẾP"}}) do
  local c=i==2 and UI.COLORS.goldYellow or UI.COLORS.textMuted
  g.setColor(c[1],c[2],c[3],.16);g.circle("fill",step[1]+10,230,10)
  text(UI,tostring(i),step[1],223,20,c,nil,"center");text(UI,step[2],step[1]+27,223,211,c)
 end
 local inputs=T.ingredients(T.id)
 local centerX,centerY=824,388
 for i,v in ipairs(inputs) do local y=258+(i-1)*91;Style.link({694,y+38,705,y+38,705,centerY,723,centerY},UI.COLORS.hpGreen,B.count(game,v.id)>=v.count,UI.Polish.time) end
 local upgrades=T.upgrades(T.id);local pages=math.max(1,math.ceil(#upgrades/4));T.upgradePage=math.min(T.upgradePage,pages)
 for i=(T.upgradePage-1)*4+1,math.min(#upgrades,T.upgradePage*4) do local y=258+(i-1)%4*91;local nextId=upgrades[i].id;Style.link({914,centerY,950,centerY,950,y+38,969,y+38},E.getTierColor(E.ITEMS[nextId]),B.canCraft(game,B.byResult[nextId]),UI.Polish.time) end
 for i,v in ipairs(inputs) do node(UI,game,buttons,v.id,v.count,480,258+(i-1)*91,214,78,mx,my) end
 if #inputs==0 then text(UI,"Mua ở ngăn Nguyên liệu cơ bản trong cửa hàng. Có thể gắn trực tiếp hoặc dùng để ghép.",480,295,214,UI.COLORS.textMuted) end
 for i=(T.upgradePage-1)*4+1,math.min(#upgrades,T.upgradePage*4) do node(UI,game,buttons,upgrades[i].id,1,969,258+(i-1)%4*91,287,78,mx,my,true) end
 if #upgrades==0 then text(UI,"Đã đạt đỉnh nhánh chế tác này. Khám phá các nhánh khác để phối hợp lối chơi.",978,302,267,UI.COLORS.textMuted) end
 if pages>1 then
  button(UI,buttons,"bag_tree_prev","←",969,627,38,27,mx,my,T.upgradePage==1)
  button(UI,buttons,"bag_tree_next","→",1218,627,38,27,mx,my,T.upgradePage==pages)
  text(UI,T.upgradePage.." / "..pages.." · "..#upgrades.." nhánh",1015,634,195,UI.COLORS.textMuted,nil,"center")
 end
 Style.stage(719,257,211,341,E.getTier(d)>1 and not d.basic and E.getTierColor(d) or UI.COLORS.goldYellow,UI.Polish.time)
 art(UI,T.id,762,267+math.sin(UI.Polish.time*1.3)*2,124,186)
 local _,titleLines=UI.fonts.small:getWrap(d.name,187)
 text(UI,d.name,731,464,187,E.getTierColor(d),#titleLines>2 and "tiny" or "small","center")
 text(UI,"Đang có "..B.count(game,T.id).." · "..(d.slotsNeeded or 1).." hốc",731,506,187,UI.COLORS.textMuted,nil,"center")
 text(UI,r and ("Từ gốc "..r.craftCost.." · Mua "..d.cost.." V") or ("Mua: "..d.cost.." vàng"),731,526,187,UI.COLORS.goldYellow,nil,"center")
 if r then
  local index;for i,v in ipairs(B.recipes) do if v==r then index=i;break end end
  local can,reason=B.canCraft(game,r)
  button(UI,buttons,"bag_craft_"..index,"GHÉP · "..r.fee.." VÀNG",734,549,181,35,mx,my,not can)
  text(UI,can and "Đủ nguyên liệu và công ghép" or reason,715,609,221,can and UI.COLORS.hpGreen or UI.COLORS.textMuted,nil,"center")
 end
 local descWidth=pages>1 and 449 or 765
 local _,lines=UI.fonts.tiny:getWrap(E.getDescription(d),descWidth)
 for i=1,math.min(3,#lines) do text(UI,lines[i],481,638+(i-1)*16,descWidth,UI.COLORS.textLight) end
end
function T.mouse(id)
 if id:sub(1,9)=="bag_node_" then T.select(id:sub(10),true)
 elseif id=="bag_tree_back" then local previous=table.remove(T.history);if previous then T.select(previous) end
 elseif id=="bag_tree_overview" then T.overview=not T.overview;local model=T.overviewModel(T.id);T.zoom=math.min(1,1004/model.w,370/model.h);T.panX=0;T.panY=0
 elseif id=="bag_tree_prev" then T.upgradePage=math.max(1,T.upgradePage-1)
 elseif id=="bag_tree_next" then T.upgradePage=T.upgradePage+1
 elseif id=="bag_tree_plus" then T.zoom=math.min(1.6,T.zoom+.15)
 elseif id=="bag_tree_minus" then T.zoom=math.max(.4,T.zoom-.15)
 elseif id=="bag_tree_fit" and T.model then T.zoom=math.min(1,(T.viewport.w-24)/T.model.w,(T.viewport.h-24)/T.model.h);T.panX=0;T.panY=0
 elseif id=="bag_tree_left" then T.panX=T.panX+140
 elseif id=="bag_tree_right" then T.panX=T.panX-140
 else return false end
 return true
end
function T.wheel(x,y,delta,horizontal)
 if not T.overview or not T.viewport or not inside(x,y,T.viewport) then return false end
 if horizontal then T.panX=T.panX+delta*60 else T.panY=T.panY+delta*60 end
 return true
end
return T

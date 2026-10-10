local S=require("ui.backpack_style")
local C=require("ui.components.core")
local T=require("ui.theme")
local H={}
local skins,plates={},{}
function H.resize()
 -- LÖVE clears Canvas pixels when the window's graphics context is recreated.
 for _,canvas in pairs(plates) do canvas:release() end
 plates={}
end
local function skin()
 if skins.plate then return skins.plate end
 local g=love.graphics;local image=g.newImage("assets/ui/generated/panels/spm_row_frame_v1.png")
 image:setFilter("linear","linear")
 local iw,ih=image:getDimensions();local xs={28,116,1420,1508};local ys={112,200,812,900}
 local quads={}
 for row=1,3 do for col=1,3 do
  quads[#quads+1]={quad=g.newQuad(xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row],iw,ih),
   w=xs[col+1]-xs[col],h=ys[row+1]-ys[row],row=row,col=col}
 end end
 skins.plate={image=image,quads=quads}
 return skins.plate
end
local function shape(x,y,w,h,cut)
 return {x+cut,y,x+w-cut,y,x+w,y+cut,x+w,y+h-cut,x+w-cut,y+h,x+cut,y+h,x,y+h-cut,x,y+cut}
end
local function nine(x,y,w,h)
 local g=love.graphics;local a=skin();local edge=math.min(17,h*.22,w*.12)
 local xs={x,x+edge,x+w-edge};local ys={y,y+edge,y+h-edge}
 local ws={edge,w-edge*2,edge};local hs={edge,h-edge*2,edge}
 for _,v in ipairs(a.quads) do g.draw(a.image,v.quad,xs[v.col],ys[v.row],0,ws[v.col]/v.w,hs[v.row]/v.h) end
end
local function plate(w,h,color,kind)
 local g=love.graphics;local c=color or T.colors.gold
 local key=table.concat({w,h,c[1],c[2],c[3],kind or "plate"},":")
 if plates[key] then return plates[key] end
 local canvas=g.newCanvas(math.ceil(w*2),math.ceil(h*2))
 g.push("all");g.setCanvas(canvas);g.origin();g.setScissor();g.setShader();g.setBlendMode("alpha","alphamultiply");g.clear(0,0,0,0);g.scale(2)
 if kind=="well" then
  -- A dark upper lip and a lit lower lip make the gauge read as an inset socket.
  g.setColor(.012,.018,.022);g.polygon("fill",shape(0,0,w,h,7))
  C.gradient(3,3,w-6,h-6,{.025,.037,.044,1},{.05,.065,.073,1},5)
  g.setColor(.005,.008,.01,.85);g.setLineWidth(3);g.line(8,3,w-8,3,w-3,8,w-3,h-8)
  g.setColor(.55,.60,.60,.28);g.setLineWidth(1);g.line(7,h-2,w-7,h-2,w-2,h-7)
  C.color(c,.55);g.setLineWidth(1);g.polygon("line",shape(4,4,w-8,h-8,4))

 elseif h<72 then
  C.gradient(1,1,w-2,h-2,{.11,.135,.143,1},{.025,.035,.043,1},5)
  g.setColor(.74,.59,.35,.80);g.setLineWidth(2);g.line(2,7,7,2,w-7,2,w-2,7)
  g.setColor(.44,.34,.20,.75);g.line(2,7,2,h-7)
  g.setColor(.018,.015,.012);g.setLineWidth(3);g.line(7,h-2,w-7,h-2,w-2,h-7,w-2,7)
  g.setColor(.92,.84,.65,.55);g.setLineWidth(.6);g.line(8,1,w*.61,1)
  C.color(c,.2);g.setLineWidth(.8);g.rectangle("line",5,5,w-10,h-10,3)
 else
  g.setColor(.29,.25,.19);g.polygon("fill",shape(0,0,w,h,8))
  g.setColor(.63,.50,.31);g.polygon("fill",0,8,8,0,w-8,0,w-12,5,11,5,5,11,5,h-12,0,h-8)
  g.setColor(.11,.09,.06);g.polygon("fill",0,h-8,8,h,w-8,h,w,h-8,w,8,w-5,11,w-5,h-11,w-11,h-5,11,h-5,5,h-11)
  g.setColor(.82,.80,.73);nine(3,3,w-6,h-6)
  g.setColor(.001,.007,.011,.22);g.rectangle("fill",11,11,w-22,h-22,5)
  -- Only a restrained accent lives on the inner rail; the material remains antique brass.
  C.color(c,.16);g.setLineWidth(1);g.line(15,9,w-15,9)
  g.setColor(1,.86,.60,.46);g.setLineWidth(.7);g.line(10,2,w*.42,2)
  g.setColor(.015,.012,.008,.8);g.setLineWidth(1);g.line(10,h-1,w-10,h-1)
 end
 g.pop();plates[key]=canvas;return canvas
end
local function shadow(x,y,w,h,depth)
 local g=love.graphics
 for i=3,1,-1 do g.setColor(.002,.006,.01,.09*i);g.rectangle("fill",x-i*2,y+depth-i,w+i*4,h+i*3,9) end
end
function H.panel(x,y,w,h,color)
 local g=love.graphics;g.push("all");shadow(x,y,w,h,h>90 and 8 or 4)
 g.setColor(1,1,1);g.setBlendMode("alpha","premultiplied");g.draw(plate(w,h,color),x,y,0,.5,.5);g.pop()
end
function H.well(x,y,w,h,color)
 local g=love.graphics;g.push("all");g.setColor(1,1,1);g.setBlendMode("alpha","premultiplied");g.draw(plate(w,h,color,"well"),x,y,0,.5,.5);g.pop()
end
function H.crest(x,y,r,color,kind)
 local g=love.graphics;g.push("all")
 g.setColor(.007,.012,.016,.7);g.ellipse("fill",x,y+4,r*1.05,r)
 g.setColor(.46,.37,.22);g.circle("fill",x,y,r)
 g.setColor(.105,.12,.11);g.circle("fill",x,y,r-2)
 g.setColor(.19,.18,.14);g.circle("fill",x,y-1,r-3)
 g.setColor(.065,.08,.082);g.circle("fill",x,y,r-5)
 C.color(color or T.colors.gold,.70);g.setLineWidth(1.2);g.circle("line",x,y,r-1)
 if kind then S.glyph(kind,x,y,r*.57,color or T.colors.gold)
 else S.compass(x,y,r*.73,color or T.colors.gold,.92,0) end
 g.setColor(1,.87,.60,.40);g.arc("line","open",x,y,r-3,math.pi,math.pi*1.8)
 g.pop()
end
function H.title(text,x,y,w,font,color,align)
 C.textLine(text,x+1,y+2,w,font,{.008,.012,.017},align)
 C.textLine(text,x,y,w,font,color or {1,.84,.56},align)
end
function H.rule(x,y,w,color)
 local g=love.graphics;g.push("all");C.color(color or T.colors.gold,.35)
 g.line(x,y,x+w,y);g.polygon("fill",x+w/2,y-3,x+w/2+3,y,x+w/2,y+3,x+w/2-3,y);g.pop()
end
function H.rail(rect,count,limit,fonts,kind,title,color)
 local x,y,w,h=unpack(rect);local g=love.graphics;g.push("all")
 H.panel(x,y,w,h,color)
 S.glyph(kind,x+29,y+23,8,color)
 H.title(title,x+47,y+15,w-122,fonts.small,color)
 C.text(count.." / "..limit,x+w-72,y+16,47,fonts.tiny,T.colors.text,"right")
 C.color(color,.23);g.line(x+17,y+35,x+w-17,y+35)
 if count==0 then
  S.glyph(kind,x+w/2,y+89,18,T.colors.goldDim)
  C.text(kind=="spn" and "Chưa có hộ linh" or "Chưa có vật phẩm",x+20,y+123,w-40,fonts.tiny,T.colors.muted,"center")
 end
 g.pop()
end
function H.table(game,UI)
 local g=love.graphics;g.push("all")
 local trayW=math.min(760,math.max(260,(#game.hand-1)*106+160))
 local trayX=630-trayW/2
 H.panel(trayX,450,trayW,177,T.colors.gold)
 g.setColor(.17,.105,.053,.18);g.rectangle("fill",trayX+24,478,trayW-48,124,6)
 H.panel(1027,467,237,230)
 H.title("KHO BÀI",1048,482,195,UI.fonts.bookChapter or UI.fonts.small,T.colors.gold,"center")
 C.color(T.colors.gold,.23);g.line(1044,513,1247,513)
 C.text("ĐÃ BỎ",1044,542,80,UI.fonts.tiny,T.colors.muted,"center")
 H.title(#game.discardPile,1044,565,80,UI.fonts.medium,T.colors.text,"center")
 C.text("Còn / Tổng",1140,514,115,UI.fonts.tiny,T.colors.muted,"center")
 local mx,my=UI.virtualMouseX or -1,UI.virtualMouseY or -1
 if mx>=1140 and mx<=1255 and my>=535 and my<=695 then
  C.text("Nhấn để xem bộ bài",1044,653,80,UI.fonts.tiny,T.colors.goldDim,"center")
 end
 g.pop()
end
function H.button(UI,b,mx,my,pressed,shortcut)
 local g=love.graphics;g.push("all")
 local over=mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h
 local down=pressed==b.id and not b.disabled
 local scale=b.animationScale or 1
 g.translate(b.x+b.w/2,b.y+b.h/2);g.scale(scale);g.translate(-b.x-b.w/2,-b.y-b.h/2)
 local color=T.accent(b.variant or "gold")
 local chosen=(b.selected or over) and not b.disabled
 local x,y,w,h=b.x,b.y+(down and 2 or 0),b.w,b.h
 shadow(x,y,w,h,down and 2 or 6)
 g.setColor(.07,.068,.057);g.polygon("fill",shape(x,y,w,h,8))
 local boost=chosen and 1.35 or b.disabled and .55 or .85
 C.gradient(x+3,y+3,w-6,h-8,{color[1]*.22*boost,color[2]*.26*boost,color[3]*.30*boost,1},
  {color[1]*.075,color[2]*.095,color[3]*.115,1},5)
 g.setColor(.84,.70,.47,b.disabled and .35 or .85);g.setLineWidth(2)
 g.line(x+2,y+9,x+9,y+2,x+w-9,y+2,x+w-2,y+9)
 g.setColor(.52,.42,.25,b.disabled and .25 or .75);g.line(x+2,y+9,x+2,y+h-9)
 g.setColor(.025,.027,.025);g.setLineWidth(3);g.line(x+9,y+h-2,x+w-9,y+h-2,x+w-2,y+h-9,x+w-2,y+9)
 g.setColor(1,.88,.62,b.disabled and .16 or .40);g.setLineWidth(.7);g.line(x+10,y+1,x+w*.67,y+1)
 C.color(color,b.disabled and .18 or chosen and .85 or .38);g.setLineWidth(1)
 g.polygon("line",shape(x+5,y+5,w-10,h-12,4))
 if chosen then S.glow(x+w/2,y+h/2,w*.45,color,.09) end
 local font=b.font or UI.fonts.small
 if font:getWidth(b.text)>w-20 then font=UI.fonts.small end
 if shortcut then
  H.title(b.text,x+10,y+8,w-20,font,b.disabled and T.colors.muted or {1,.94,.80},"center")
  C.text(shortcut,x+17,y+h-20,w-34,UI.fonts.tiny,b.disabled and T.colors.goldDim or color,"center")
 else
  H.title(b.text,x+10,y+(h-font:getHeight())/2,w-20,font,b.disabled and T.colors.muted or {1,.94,.80},"center")
 end
 g.pop()
end
return H

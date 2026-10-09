local M={}
local Style=require("ui.backpack_style")
local function clamp(t) return math.max(0,math.min(1,t)) end
local function ease(t) t=clamp(t);return t*t*(3-2*t) end
function M.position(a,t)
 local from,to=a.kind=="unequip" and a.rect or a.source,a.kind=="unequip" and a.source or a.rect
 local p=ease(t);local fx,fy=from.x+from.w/2,from.y+from.h/2;local tx,ty=to.x+to.w/2,to.y+to.h/2
 return fx+(tx-fx)*p,fy+(ty-fy)*p-math.sin(p*math.pi)*(a.kind=="unequip" and 92 or 58),p
end
local function ring(g,x,y,r,color,alpha,rotation,broken)
 g.setColor(color[1],color[2],color[3],alpha);g.setLineWidth(1.5)
 for i=1,broken and 4 or 8 do
  local angle=rotation+(i-1)*math.pi*2/(broken and 4 or 8)
  g.arc("line","open",x,y,r,angle,angle+(broken and .7 or .52),12)
 end
end
function M.draw(UI,a)
 local g=love.graphics;local remove=a.kind=="unequip";local c=a.color
 local travel=(a.duration or .9)*.6;local t=clamp(a.age/travel)
 local x,y,p=M.position(a,t);local contact=math.max(0,a.age-travel)
 local alpha=t<1 and 1 or math.max(0,1-contact/.28)
 local cx,cy=a.rect.x+a.rect.w/2,a.rect.y+a.rect.h/2
 g.push("all")
 -- The attachment locks inward; removal opens four halves before releasing the relic.
 if a.age<travel then
  local strength=remove and (1-t) or (.3+.7*p)
  ring(g,cx,cy,a.rect.w*.63+(remove and 38*t or 28*(1-p)),c,strength*.7,remove and -t*2 or t*3,remove)
  for i=1,4 do
   local angle=(i-1)*math.pi/2+math.pi/4
   local distance=remove and 20+45*t or 45*(1-p)+9
   local px,py=cx+math.cos(angle)*(a.rect.w*.48+distance),cy+math.sin(angle)*(a.rect.h*.4+distance)
   g.setColor(c[1],c[2],c[3],strength*.8);g.push();g.translate(px,py);g.rotate(angle+t*(remove and -1 or 1));g.polygon("line",0,-5,3,0,0,5,-3,0);g.pop()
  end
 end
 g.setBlendMode("add")
 if t<1 then
  local lastX,lastY=x,y
  for i=1,15 do
   local q=math.max(0,t-i*.021);local px,py=M.position(a,q)
   g.setColor(c[1],c[2],c[3],alpha*.44*(1-i/16));g.setLineWidth(5*(1-i/17));g.line(lastX,lastY,px,py);lastX,lastY=px,py
   if i%3==0 then g.circle("fill",px,py,1.8) end
  end
  for i=1,8 do
   local angle=a.age*(remove and -9 or 9)+i*math.pi/4;local radius=18+6*math.sin(i+a.age*7)
   g.setColor(c[1],c[2],c[3],.6*alpha);g.circle("fill",x+math.cos(angle)*radius,y+math.sin(angle)*radius*.65,i%2+1)
  end
  for side=-1,1,2 do
   local points={}
   for i=0,12 do
    local q=math.max(0,t-i*.015);local px,py=M.position(a,q)
    local wave=math.sin(q*math.pi*10+side*.8)*8*math.sin(p*math.pi)
    points[#points+1]=px+side*wave;points[#points+1]=py+side*wave*.4
   end
   g.setColor(c[1],c[2],c[3],alpha*.35);g.setLineWidth(1);g.line(unpack(points))
  end
 end
 for i=1,4 do g.setColor(c[1],c[2],c[3],alpha*.035*(5-i));g.circle("fill",x,y,22+i*7) end
 g.setBlendMode("alpha")
 local image=UI.getEquipmentImage(a.sourceItem.id)
 g.push();g.translate(x,y);g.rotate(math.sin(p*math.pi)*(remove and -.3 or .12));g.scale(1+.2*math.sin(p*math.pi)-.25*p)
 g.setColor(1,1,1,alpha)
 if image then UI.CardFrame.image(image,-28,-42,56,84);UI.drawCardBorder(-28,-42,56,84,{c[1],c[2],c[3],alpha},alpha,a.sourceItem) end
 g.pop()
 if a.hit then
  local fade=math.max(0,1-contact/.72);local ix,iy=remove and a.source.x+a.source.w/2 or cx,remove and a.source.y+a.source.h/2 or cy
  ring(g,ix,iy,24+contact*(remove and 64 or -15),c,fade,a.age*2,remove)
  if not remove then
   g.setColor(c[1],c[2],c[3],fade*.8);g.setLineWidth(2)
   local d=10*(1-fade)
   for _,corner in ipairs({{a.rect.x-d,a.rect.y-d,1,1},{a.rect.x+a.rect.w+d,a.rect.y-d,-1,1},{a.rect.x-d,a.rect.y+a.rect.h+d,1,-1},{a.rect.x+a.rect.w+d,a.rect.y+a.rect.h+d,-1,-1}}) do
    local px,py,sx,sy=unpack(corner);g.line(px,py+sy*16,px,py,px+sx*16,py)
   end
   for i=1,12 do local angle=i*math.pi/6;local radius=20+contact*65;g.setColor(c[1],c[2],c[3],fade*.7);g.circle("fill",cx+math.cos(angle)*radius,cy+math.sin(angle)*radius,1.5) end
   g.setBlendMode("add");g.setColor(c[1],c[2],c[3],math.exp(-contact*18)*.22)
   g.ellipse("fill",cx,cy,a.rect.w*.75,7);g.ellipse("fill",cx,cy,5,a.rect.h*.38)
  else
   for i=1,4 do
    local angle=i*math.pi/2+.5;local distance=contact*54
    g.setColor(c[1],c[2],c[3],fade*.65);g.line(cx+math.cos(angle)*distance,cy+math.sin(angle)*distance,cx+math.cos(angle)*(distance+13),cy+math.sin(angle)*(distance+13))
   end
  end
 end
 g.pop()
end
function M.confirmation(UI,a,alpha)
 local bag=UI.Backpack
 if not a.sourceItem or not a.fixedRect or not bag or not bag.open or bag.tab~="cards" or bag.pending then return false end
 local g=love.graphics;local c=a.color;local y=641+(1-alpha)*7
 Style.panel(243,y,681,38,c,true,alpha)
 local image=UI.getEquipmentImage(a.sourceItem.id)
 g.push("all");g.setColor(1,1,1,alpha)
 if image then UI.CardFrame.image(image,255,y+6,17,25);UI.drawCardBorder(255,y+6,17,25,{c[1],c[2],c[3],alpha},alpha,a.sourceItem) end
 local title,status=a.text:match("^([^\n]+)\n(.*)$")
 g.setColor(c[1],c[2],c[3],alpha);g.setFont(UI.fonts.small);g.printf(title or a.text,285,y+8,331,"left")
 g.setFont(UI.fonts.tiny);g.setColor(.89,.93,.94,alpha);g.printf(status or "",626,y+11,281,"right")
 g.pop();return true
end
return M

local S={}
local gold={.86,.68,.39}
local function tint(g,c,a) g.setColor(c[1],c[2],c[3],a or 1) end
function S.glow(x,y,r,c,alpha)
 local g=love.graphics;g.push("all");g.setBlendMode("add")
 for i=7,1,-1 do tint(g,c,(alpha or .12)*(8-i)/28);g.ellipse("fill",x,y,r*i/7,r*.65*i/7) end
 g.pop()
end
function S.compass(x,y,r,c,alpha,time)
 local g=love.graphics;g.push("all");tint(g,c,alpha);g.setLineWidth(1)
 g.circle("line",x,y,r);g.circle("line",x,y,r*.83)
 for i=0,15 do local a=i*math.pi/8;local inner=i%4==0 and .72 or .90;g.line(x+math.cos(a)*r*inner,y+math.sin(a)*r*inner,x+math.cos(a)*r,y+math.sin(a)*r) end
 g.push();g.translate(x,y);g.rotate((time or 0)*.035)
 for i=0,3 do g.push();g.rotate(i*math.pi/2);tint(g,c,alpha);g.polygon("fill",0,-r*.65,r*.11,0,0,-r*.16);tint(g,c,alpha*.4);g.polygon("fill",0,-r*.65,-r*.11,0,0,-r*.16);g.pop() end
 g.pop();g.pop()
end
local function wash(g,x,y,w,h,top,bottom)
 for i=0,23 do local t=i/23;g.setColor(top[1]*(1-t)+bottom[1]*t,top[2]*(1-t)+bottom[2]*t,top[3]*(1-t)+bottom[3]*t,1);g.rectangle("fill",x,y+i*h/24,w,h/24+1) end
end
function S.background(time)
 local g=love.graphics
 if not S.canvas then
  local previous=g.getCanvas();S.canvas=g.newCanvas(1280,720);g.push("all");g.setCanvas(S.canvas);g.origin();g.setShader();g.setScissor();g.clear()
  wash(g,0,0,1280,720,{.075,.115,.123},{.018,.035,.044})
  -- Stationary material detail is baked once; only light and dust move each frame.
  for i=1,46 do
   local y=112+i*13;g.setColor(.38,.48,.43,.025);g.line(212,y,1280,y-8)
  end
  for i=0,11 do g.setColor(.42,.58,.55,.038);g.ellipse("line",795,379,110+i*58,63+i*39) end
  S.compass(824,390,241,{.46,.61,.55},.045,0)
  wash(g,0,0,212,720,{.19,.125,.071},{.071,.045,.031})
  for y=0,719,4 do
   g.setColor(.42,.25,.12,.048);g.line(0,y,212,y+math.sin(y*.19)*2)
   for x=5,205,12 do g.setColor(.65,.46,.27,.024);g.points(x+math.sin(y+x)*3,y) end
  end
  for _,x in ipairs({8,204}) do
   g.setColor(.028,.016,.01,.5);g.rectangle("fill",x-3,0,6,720)
   for y=12,706,12 do g.setColor(.58,.38,.19,.35);g.line(x,y,x,y+4) end
  end
  wash(g,212,0,1068,109,{.10,.128,.134},{.039,.057,.065})
  g.setColor(.88,.68,.36,.45);g.line(0,108,1280,108)
  g.setColor(.008,.014,.02,.7);g.rectangle("fill",212,109,1068,5)
  for _,x in ipairs({16,196}) do for _,y in ipairs({16,703}) do g.setColor(.25,.16,.085,1);g.circle("fill",x,y,4);g.setColor(.74,.52,.25,1);g.circle("line",x,y,2.7);g.line(x-2,y,x+2,y) end end
  g.setCanvas(previous);g.pop()
 end
 g.setColor(1,1,1);g.draw(S.canvas)
 S.glow(821,359,260,{.20,.43,.43},.07)
 S.glow(247,103,130,gold,.075)
 for i=1,16 do
  local x=236+(i*79)%1000;local y=127+(i*47-time*(3+i%3))%543
  tint(g,gold,.10+.09*math.sin(time*.7+i)^2);g.circle("fill",x,y,i%3==0 and 1.2 or .6)
 end
end
function S.panel(x,y,w,h,c,selected,opacity)
 local g=love.graphics;c=c or gold;opacity=opacity or 1
 g.push("all");g.setColor(.003,.01,.018,.5*opacity);g.rectangle("fill",x+3,y+6,w,h,9,9)
 g.setColor(selected and .105 or .048,selected and .125 or .077,selected and .119 or .088,.98*opacity);g.rectangle("fill",x,y,w,h,9,9)
 tint(g,c,(selected and .65 or .24)*opacity);g.setLineWidth(1);g.rectangle("line",x+.5,y+.5,w-1,h-1,9,9)
 tint(g,c,(selected and .24 or .07)*opacity);g.line(x+11,y+2,x+w-11,y+2)
 tint(g,c,(selected and .52 or .20)*opacity)
 for _,corner in ipairs({{x+5,y+5,1,1},{x+w-5,y+5,-1,1},{x+5,y+h-5,1,-1},{x+w-5,y+h-5,-1,-1}}) do local px,py,sx,sy=unpack(corner);g.line(px,py+8*sy,px,py,px+8*sx,py) end
 if selected then S.glow(x+w/2,y+h*.37,math.min(w*.7,120),c,.08*opacity) end
 g.pop()
end
function S.glyph(kind,x,y,r,c)
 local g=love.graphics;g.push("all");tint(g,c or gold,1);g.setLineWidth(1.3)
 if kind=="spn" then g.ellipse("line",x,y,r,r*.55);g.circle("line",x,y,r*.31);g.line(x,y-r*.9,x,y-r*.7)
 elseif kind=="consumable" then g.line(x-r*.25,y-r,x+r*.25,y-r);g.line(x-r*.2,y-r,x-r*.2,y-r*.35);g.line(x+r*.2,y-r,x+r*.2,y-r*.35);g.arc("line","open",x,y+r*.1,r*.75,-math.pi*.3,math.pi*1.3);g.line(x-r*.66,y+r*.45,x+r*.66,y+r*.45)
 elseif kind=="equipment" then g.polygon("line",x-r*.8,y-r*.8,x+r*.8,y-r*.8,x+r*.68,y+r*.3,x,y+r,x-r*.68,y+r*.3);g.line(x,y-r*.4,x,y+r*.55)
 elseif kind=="cards" then g.rectangle("line",x-r*.85,y-r*.8,r*1.05,r*1.6,2);g.rectangle("line",x-r*.15,y-r*.55,r*1.05,r*1.6,2)
 elseif kind=="craft" then g.polygon("line",x-r,y-r*.35,x+r,y-r*.35,x+r*.65,y,x+r*.12,y+r*.2,x+r*.32,y+r*.65,x-r*.5,y+r*.65,x-r*.25,y+r*.2,x-r*.65,y);g.line(x-r*.4,y-r*.85,x+r*.35,y-r*.85)
 elseif kind=="gold" then g.ellipse("line",x,y,r*.7,r);g.ellipse("line",x,y,r*.48,r*.75);g.line(x,y-r*.42,x,y+r*.42)
 elseif kind=="souls" then g.polygon("line",x,y-r,x+r*.7,y,x,y+r,x-r*.7,y);g.circle("line",x,y,r*.28) end
 g.pop()
end
function S.link(points,c,ready,time)
 local g=love.graphics;g.push("all");c=c or gold
 tint(g,c,ready and .12 or .05);g.setLineWidth(5);g.line(unpack(points))
 tint(g,c,ready and .64 or .28);g.setLineWidth(1.2);g.line(unpack(points))
 local length=0;local spans={}
 for i=1,#points-2,2 do local dx,dy=points[i+2]-points[i],points[i+3]-points[i+1];local n=math.sqrt(dx*dx+dy*dy);spans[#spans+1]={i=i,n=n};length=length+n end
 if ready and length>0 then
  local remaining=(time*.19)%1*length
  for _,span in ipairs(spans) do if remaining<=span.n and span.n>0 then local i,t=span.i,remaining/span.n;local x=points[i]+(points[i+2]-points[i])*t;local y=points[i+1]+(points[i+3]-points[i+1])*t;S.glow(x,y,7,c,.24);tint(g,c,.9);g.circle("fill",x,y,1.7);break else remaining=remaining-span.n end end
 end
 tint(g,c,ready and .9 or .35);g.circle("fill",points[1],points[2],2);g.circle("fill",points[#points-1],points[#points],2)
 g.pop()
end
function S.stage(x,y,w,h,c,time)
 local g=love.graphics;g.push("all")
 S.panel(x,y,w,h,c,true);S.glow(x+w/2,y+103,100,c,.18)
 S.compass(x+w/2,y+130,96,c,.22,time)
 g.setColor(.011,.021,.026,.7);g.ellipse("fill",x+w/2,y+199,74,14)
 tint(g,c,.22);g.ellipse("line",x+w/2,y+199,73,11)
 for i=1,3 do tint(g,c,.06);g.line(x+18,y+h-24-i*4,x+w-18,y+h-24-i*4) end
 g.pop()
end
return S

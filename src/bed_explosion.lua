-- Presentation only. Deterministic local variation never consumes gameplay RNG.
local C=require("config.bed_explosion_config")
local E={config=C,age=0,active=false,serial=0,debug=false,shake=true,distortion=true,quality="HIGH",debrisBias=0,radiusScale=1}
local pool={};for i=1,64 do pool[i]={} end
E.pool=pool
local function clamp(t) return math.max(0,math.min(1,t)) end
local function out(t) return 1-(1-clamp(t))^3 end
local function noise(i) return (math.sin(i*12.9898+E.serial*7.1)*43758.5453)%1 end
function E.load()
 local ok,shader=pcall(love.graphics.newShader,"shaders/bed_explosion_fire.glsl")
 if ok then E.fireShader=shader else E.shaderError=tostring(shader);print("[BED VFX] fire fallback: "..E.shaderError) end
end
function E.clear() E.active=false;E.ready=false;E.pending=false;E.count=0 end
function E.start(x,y,quality,environment,power)
 E.serial=E.serial+1;E.x=x;E.y=y;E.age=0;E.active=true;E.ready=false;E.pending=false;E.detonated=false
 E.quality=quality or E.quality;E.q=C.quality[E.quality] or C.quality.HIGH
 E.intensity=math.min(1.25,math.max(.85,tonumber(power) or 1));E.wet=environment and (environment.rain or 0)>.3
 E.count=0;E.debrisCount=0;E.smokeCount=0
 local large,medium,small=E.q.large,E.q.medium,E.q.small
 small=math.max(0,math.min(22,small+E.debrisBias))
 for i=1,large+medium+small do
  E.count=E.count+1;local p=pool[E.count];local r=noise(i)
  p.kind="debris";p.size=i<=large and 25+r*16 or i<=large+medium and 9+r*10 or 2+r*3
  p.material=i%5==0 and "metal" or i%3==0 and "fabric" or "wood"
  p.x=x+(r-.5)*55;p.y=y+(noise(i+8)-.5)*18;p.floor=y+62+noise(i+13)*30
  local side=r<.5 and -1 or 1
  p.vx=side*(280+noise(i+5)*470)*E.intensity;p.vy=-(260+noise(i+17)*440)*E.intensity
  p.rotation=noise(i+21)*6.28;p.angularVelocity=(noise(i+24)-.5)*25;p.gravity=C.debris.gravity
  p.drag=p.material=="fabric" and 2.7 or C.debris.drag;p.lifetime=.70+noise(i+28)*.60;p.bounceCount=0
 end
 E.debrisCount=E.count
 for i=1,E.q.smoke do
  E.count=E.count+1;local p=pool[E.count];p.kind="smoke";p.x=x+(noise(i+31)-.5)*50;p.y=y
  p.vx=(noise(i+36)-.5)*95;p.vy=-48-noise(i+41)*40;p.size=26+noise(i+48)*24;p.lifetime=C.smoke.duration
 end
 E.smokeCount=E.q.smoke
 for i=1,E.q.ember do
  E.count=E.count+1;local p=pool[E.count];p.kind="ember";p.x=x;p.y=y;p.vx=(noise(i+54)-.5)*380
  p.vy=-140-noise(i+61)*180;p.size=1+noise(i+65)*2;p.lifetime=.45+noise(i+68)*.55
 end
 require("src.sound").play("bed_explosion_charge",.98+noise(92)*.04)
end
function E.takeImpact() if not E.ready then return false end;E.ready=false;return true end
function E.wave()
 if not E.active or not E.detonated then return 0,0 end
 local t=(E.age-C.anticipation-C.shockwave.delay)/C.shockwave.duration
 if t<0 or t>1 then return 0,0 end
 return out(t)*C.shockwave.radius*E.radiusScale,E.distortion and E.q.distortion and C.shockwave.strength*(1-t)^2 or 0
end
function E.camera()
 if not E.active or not E.detonated or not E.shake then return 0,0 end
 local t=E.age-C.anticipation;if t>C.camera.shake then return 0,0 end
 local a=C.camera.amplitude*(1-t/C.camera.shake)^3
 return math.sin(t*163)*a,math.cos(t*127)*a*.65
end
function E.reaction(x)
 if not E.active or not E.detonated then return 0,0,0 end
 local t=(E.age-C.anticipation)/.26
 if t>1 then return 0,0,0 end
 local fall=(1-t)^3;local side=x<E.x and -1 or 1
 return side*math.sin(t*math.pi)*27*fall,-math.sin(t*math.pi)*21*fall,fall*.65
end
function E.update(dt)
 if not E.active then return end
 local before=E.age;E.age=E.age+math.max(0,dt)
 if not E.detonated and E.age>=C.anticipation then
  -- Anchor the contact to its first rendered frame, even after a slow frame.
  E.age=C.anticipation;before=C.anticipation
  E.detonated=true;E.ready=true;E.pending=true
  require("src.sound").play("bed_explosion_boom",.88+noise(93)*.06)
  require("src.sound").play("bed_explosion_rumble",.89+noise(94)*.05)
  if E.shake then require("render.camera").kick(C.camera.kickX,C.camera.kickY) end
  require("render.lighting").flash(E.x,E.y,C.palette.fire,C.light.strength,C.light.duration,C.light.radius)
 end
 if E.detonated then
  local age=E.age-C.anticipation
  if before<C.anticipation+.15 and E.age>=C.anticipation+.15 then require("src.sound").play("bed_explosion_debris",.95+noise(95)*.1) end
  local step=math.max(0,E.age-math.max(before,C.anticipation))
  -- Fixed small substeps retain bounce/drag at 30/60/144 FPS and after a stall.
  local steps=math.max(1,math.ceil(math.min(step,.10)/.008));local h=math.min(step,.10)/steps
  for i=1,E.count do local p=pool[i]
   if p.kind=="debris" and age<p.lifetime then
    for j=1,steps do
     p.vx=p.vx*math.exp(-p.drag*h);p.vy=p.vy+p.gravity*h
     p.x=p.x+p.vx*h;p.y=p.y+p.vy*h;p.rotation=p.rotation+p.angularVelocity*h
     if p.y>p.floor then
      p.y=p.floor
      if p.bounceCount<1 then p.vy=-math.abs(p.vy)*C.debris.bounce;p.vx=p.vx*.62;p.bounceCount=p.bounceCount+1
      else p.vy=0;p.vx=p.vx*math.exp(-14*h);p.angularVelocity=p.angularVelocity*math.exp(-12*h) end
     end
    end
   elseif p.kind=="smoke" and age>C.smoke.delay then p.x=p.x+p.vx*h*steps;p.y=p.y+p.vy*h*steps
   elseif p.kind=="ember" then p.x=p.x+p.vx*h*steps;p.y=p.y+p.vy*h*steps;p.vx=p.vx*math.exp(-2*h*steps) end
  end
 end
 if E.age>=C.anticipation+C.duration then E.clear() end
end
local function soft(g,x,y,rx,ry)
 local image=require("render.lighting").radial
 if image then g.draw(image,x-rx,y-ry,0,rx/64,ry/64) end
end
local function bed(g,x,y,p)
 g.push("all");g.translate(x,y);g.rotate(math.sin(p*57)*.045*p)
 local s=1+.03*math.sin(p*math.pi*2)-.02*p;g.scale(s,s)
 g.setColor(.13,.075,.045,1);g.rectangle("fill",-43,-4,86,15,2,2)
 g.setColor(.40,.24,.13,1);g.rectangle("fill",-44,-14,5,42);g.rectangle("fill",38,-10,5,35)
 g.setColor(.36,.10,.13,1);g.polygon("fill",-37,-14,30,-14,39,-2,-39,-2)
 g.setColor(.67,.55,.40,1);g.rectangle("fill",-32,-20,20,10,3,3)
 g.setColor(.53,.36,.20,1);g.setLineWidth(2);g.line(-42,9,40,9)
 if p>0 then
  g.setBlendMode("add");g.setColor(1,.63,.22,p*.7);g.setLineWidth(1.5);g.line(-28,-7,-9,-12,1,-4,17,-10,33,-3)
  require("render.lighting").glow(0,-5,75,C.palette.hot,p*.42)
 end
 g.pop()
end
function E.drawBeds(game)
 local members=require("src.enemy_group").members(game)
 for _,m in ipairs(members) do if m.hasBed and (not E.active or E.x~=(m.screenX or 635)) then bed(love.graphics,m.screenX or 635,410,0) end end
end
function E.draw()
 if not E.active then return end
 local g=love.graphics;g.push("all");g.setShader();g.setBlendMode("alpha")
 if not E.detonated then
  local p=clamp(E.age/C.anticipation);bed(g,E.x,E.y,p)
  g.setBlendMode("add");g.setColor(1,.44,.12,p*.6);g.setLineWidth(1)
  for i=1,4 do local a=i*1.57;local r=42*(1-p)+8;g.line(E.x+math.cos(a)*r,E.y+math.sin(a)*r*.5,E.x+math.cos(a)*(r+4),E.y+math.sin(a)*(r+4)*.5) end
  g.pop();return
 end
 local age=E.age-C.anticipation
 local fade=1-clamp(age/C.scorch.duration)
 g.setColor(.045,.025,.02,fade*.48);soft(g,E.x,E.y+55,C.scorch.radius,23)
 -- Distinct horizontal dust and rising smoke; soft cached lighting sprite supplies edges.
 for i=1,E.smokeCount do
  local p=pool[E.debrisCount+i];local t=clamp((age-C.smoke.delay)/p.lifetime)
  if age>C.smoke.delay then
   g.setColor(E.wet and .33 or .11,E.wet and .34 or .10,E.wet and .36 or .105,math.sin(t*math.pi)*.65)
   local r=p.size*(1+t*1.6);soft(g,p.x+math.sin(age*3+i)*8,p.y,r*1.5,r*1.05)
   g.setColor(.28,.26,.24,math.sin(t*math.pi)*.075);soft(g,p.x-8,p.y-5,r*1.7,r*1.2)
  end
 end
 local dust=clamp((age-C.dust.delay)/C.dust.duration)
 if age>C.dust.delay and dust<1 then
  for i=1,6 do local side=i%2==0 and 1 or -1;local x=E.x+side*out(dust)*(C.dust.radius*(.15+i*.13))
   g.setColor(.27,.23,.19,(1-dust)^2*(E.wet and .15 or .48));soft(g,x,E.y+42+math.sin(i)*5,30+dust*40,13+dust*17)
  end
 end
 local radius=E.wave()
 if radius>0 then
  g.setBlendMode("add");g.setColor(1,.83,.53,.95*(1-clamp((age-C.shockwave.delay)/C.shockwave.duration))^2)
  g.setLineWidth(1.5+9*(1-radius/(C.shockwave.radius*E.radiusScale)));g.ellipse("line",E.x,E.y,radius,radius*.42)
 end
 local fire=clamp((age-C.fire.delay)/C.fire.duration)
 g.setBlendMode("add")
 if age>C.fire.delay and fire<1 then
  g.setBlendMode("alpha")
  local image=require("render.lighting").radial
  if E.fireShader and image then
   E.fireShader:send("phase",fire);E.fireShader:send("seed",E.serial*.73)
   E.fireShader:send("fireColor",C.palette.fire);E.fireShader:send("coreColor",C.palette.core)
   g.setShader(E.fireShader);g.setColor(1,1,1,1)
   local r=C.fire.radius;g.draw(image,E.x-r,E.y-r*.90-22,0,r/64,r*.9/64)
   g.setShader()
  else
   g.setColor(1,.38,.08,(1-fire)^2);soft(g,E.x,E.y-22,70+out(fire)*130,55+out(fire)*105)
  end
  g.setBlendMode("add")
  require("render.lighting").glow(E.x,E.y-20,140+fire*90,C.palette.fire,(1-fire)^2*.65)
 end
 if age<C.flash then
  local impact=1-age/C.flash
  g.setBlendMode("add");g.setColor(1,.90,.55,.095*impact);g.rectangle("fill",0,0,1280,720)
  require("render.lighting").glow(E.x,E.y-12,175,C.palette.core,1.2*impact)
  g.setColor(1,.97,.78,impact*.85)
  for i=1,8 do
   local a=i*2.399;local r=(95+noise(i+110)*75)*(1+age*9)
   local dx,dy=math.cos(a),math.sin(a)*.66
   g.polygon("fill",E.x-dy*9,E.y+dx*9,E.x+dx*r,E.y+dy*r,E.x+dy*9,E.y-dx*9)
  end
  g.setColor(1,1,.86,impact);g.circle("fill",E.x,E.y,18+age*300)
 end
 g.setBlendMode("alpha")
 for i=1,E.debrisCount do local p=pool[i]
  if age<p.lifetime then
   local a=clamp((p.lifetime-age)/.25);local color=C.palette[p.material]
   if age<.20 then
    g.setBlendMode("add");g.setColor(1,.48,.14,(1-age/.20)*.65)
    g.setLineWidth(p.size*.18);g.line(p.x,p.y,p.x-p.vx*.035,p.y-p.vy*.035)
    g.setBlendMode("alpha")
   end
   g.push();g.translate(p.x,p.y);g.rotate(p.rotation)
   local hot=math.max(0,1-age/.20)*.75
   g.setColor(math.min(1,color[1]+hot),color[2]+hot*.35,color[3]+hot*.06,a)
   if p.material=="fabric" then g.polygon("fill",-p.size*.6,-p.size*.25,p.size*.6,-p.size*.2,p.size*.35,p.size*.35,-p.size*.5,p.size*.2)
   else g.rectangle("fill",-p.size*.6,-p.size*.22,p.size*1.2,p.size*.44,1,1) end
   g.setColor(.68,.41,.20,a*.6);g.setLineWidth(1);g.line(-p.size*.5,-p.size*.12,p.size*.45,-p.size*.12)
   g.pop()
  end
 end
 g.setBlendMode("add")
 for i=E.debrisCount+E.smokeCount+1,E.count do local p=pool[i]
  local a=clamp((p.lifetime-age)/.22)*(.7+.3*math.sin(age*29+i))
  if age<p.lifetime then g.setColor(1,.35,.08,a);g.setLineWidth(1);g.line(p.x,p.y,p.x-p.vx*.025,p.y+4);g.circle("fill",p.x,p.y,p.size) end
 end
 g.pop()
end
function E.keypressed(key)
 if not E.debug then return false end
 if key=="b" then E.start(635,410,E.quality,nil,1)
 elseif key=="1" then E.quality="LOW" elseif key=="2" then E.quality="MEDIUM" elseif key=="3" then E.quality="HIGH"
 elseif key=="c" then E.shake=not E.shake elseif key=="v" then E.distortion=not E.distortion
 elseif key=="[" then E.debrisBias=math.max(-10,E.debrisBias-2) elseif key=="]" then E.debrisBias=math.min(2,E.debrisBias+2)
 elseif key=="-" then E.radiusScale=math.max(.5,E.radiusScale-.1) elseif key=="=" then E.radiusScale=math.min(1.4,E.radiusScale+.1)
 elseif key=="h" then C.hitStop=C.hitStop>=.079 and .04 or C.hitStop+.01
 elseif key=="k" then C.camera.kickY=C.camera.kickY>=8 and 4 or C.camera.kickY+1;C.camera.kickX=-C.camera.kickY*.875
 else return false end
 return true
end
function E.drawDebug(ui)
 if not E.debug then return end
 local g=love.graphics;g.push("all");g.setFont(ui.fonts.tiny);g.setColor(.03,.04,.05,.9);g.rectangle("fill",290,80,700,45,5,5)
 g.setColor(1,.8,.5,1);g.printf("BED EXPLOSION TEST · B replay · 1/2/3 quality · C camera · V distortion · [ ] debris · -/+ radius · H stop · K kick",300,85,680,"center");g.pop()
end
return E

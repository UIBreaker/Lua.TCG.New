-- Presentation only: never writes combat, rewards, save data or gameplay RNG.
local C=require("config.death_vfx_config")
local Sound=require("src.sound")
local Camera=require("render.camera")
local Light=require("render.lighting")
local EnemyArt=require("src.enemy_art")
local D={config=C,pool={},silhouettes={},count=0,age=0}
local function clamp(x) return math.max(0,math.min(1,x)) end
local function ramp(t,a,b) local p=clamp((t-a)/(b-a));return p*p*(3-2*p) end
local function random(i) return (math.sin(i*127.1+43.7)*43758.5453)%1 end
function D.load()
    local ok,shader=pcall(love.graphics.newShader,"shaders/enemy_ash_dissolve.glsl")
    if ok then D.shader=shader else D.shaderError=tostring(shader);print("[Death VFX] shader fallback: "..D.shaderError) end
    for i=1,C.particles.max do D.pool[i]={} end
    local paths={chest="assets/scene/treasure_chest.png",mini="assets/scene/enemy_small_lowpoly.png",elite="assets/scene/enemy_elite_lowpoly.png",boss="assets/scene/enemy_boss_lowpoly.png"}
    for _,list in ipairs({EnemyArt.normal,EnemyArt.bosses}) do
        for _,key in ipairs(list) do paths[key]=EnemyArt.path(key) end
    end
    for key,path in pairs(paths) do
        local loaded,data=pcall(love.image.newImageData,path)
        if loaded then
            local points={};local w,h=data:getDimensions();local longest=math.max(w,h)
            for y=1,23 do for x=1,23 do
                local px,py=math.floor(w*x/24),math.floor(h*y/24)
                local _,_,_,a=data:getPixel(px,py)
                if a>0.3 then points[#points+1]={(px-w/2)/longest,(py-h/2)/longest} end
            end end
            if #points>0 then D.silhouettes[key]=points end
            data:release()
        end
    end
end
function D.reset()
    D.kind,D.monster,D.seen,D.preset=nil,nil,nil,nil;D.count,D.age=0,0
    D.cards=nil
end
function D.busy() return D.kind~=nil and D.age<D.duration end
function D.enemyActive(monster) return D.kind=="enemy" and D.monster==monster end
function D.startEnemy(monster,x,quality)
    if not monster or D.seen==monster then return false end
    D.kind,D.monster,D.seen,D.age,D.count="enemy",monster,monster,0,0
    D.preset=monster.isBoss and C.enemy.boss or monster.isElite and C.enemy.elite or C.enemy.mini
    D.points=D.silhouettes[EnemyArt.key(monster)] or D.silhouettes[monster.isBoss and "boss" or monster.isElite and "elite" or "mini"]
    D.duration,D.stop,D.x,D.y=D.preset.duration,D.preset.stop,x or 640,270
    D.limit=math.min(C.particles.max,math.floor((C.particles[quality] or C.particles.HIGH)*D.preset.count))
    D.burst=false;Sound.play("enemy_death_hit")
    Camera.kick(-D.preset.kick,D.preset.kick*0.35)
    Light.flash(D.x,D.y,C.enemy.crack,0.38,0.26,240)
    return true
end
function D.startChest(quality)
    D.reset();D.kind="chest";D.preset=C.chest
    D.duration,D.stop,D.x,D.y=C.chest.duration,C.chest.stop,640,328
    D.limit=math.min(C.particles.max,math.floor((C.particles[quality] or C.particles.HIGH)*C.chest.count))
    D.points=D.silhouettes.chest;D.burst=false
    Sound.play("pack_open");Camera.kick(0,C.chest.kick)
    Light.flash(D.x,D.y,C.enemy.crack,0.26,0.42,220)
end
function D.startPlayer(x,quality)
    D.kind,D.age,D.count,D.duration,D.stop="player",0,0,C.player.duration,C.player.stop
    D.x,D.y=x or C.player.coreX,C.player.coreY
    D.clock=0
    D.limit=math.min(C.particles.max,C.particles[quality] or C.particles.HIGH);D.burst=false
    D.ambience,D.text=false,false
    Sound.play("defeat_hit");Camera.kick(0,3)
    Light.flash(D.x,D.y,C.player.soul,0.20,0.28,220)
end
function D.emit()
    D.count=D.limit
    local enemy=D.kind~="player"
    for i=1,D.count do
        local p=D.pool[i];local r,s=random(i),random(i+233)
        p.kind=D.kind=="chest" and (i%4==0 and "ember" or "shard")
            or (i%10<6 and "ash" or i%10<9 and "ember" or "smoke")
        local point=enemy and D.points and D.points[1+math.floor(r*#D.points)]
        local size=enemy and D.preset.size or 330
        p.x=D.x+(point and point[1] or (r-0.5)*0.75)*size
        p.y=D.y+(point and point[2] or (s-0.5)*0.8)*(enemy and size or 100)
        p.vx=(enemy and C.enemy.driftX or 0)+(r-0.5)*(enemy and 150 or 95)
        p.vy=(enemy and C.enemy.driftY or -55)-s*65
        p.life=(p.kind=="ash" and C.particles.ashLife or p.kind=="ember" and C.particles.emberLife or C.particles.smokeLife)*(enemy and D.duration/C.enemy.boss.duration or 1)
        p.delay=s*0.22;p.life=math.max(0.1,math.min(p.life,D.duration-D.age-p.delay-0.03))
        p.age=-p.delay;p.size=p.kind=="smoke" and 15+s*16 or 1+s*3
        p.spin=r*math.pi
    end
    Sound.play(D.kind=="chest" and "chest_dissolve" or enemy and "enemy_ash_break" or "defeat_collapse",enemy and 1 or 0.7)
end
function D.update(dt)
    if not D.kind then return end
    D.age=math.min(D.duration,D.age+dt)
    if D.kind=="player" then D.clock=(D.clock or 0)+dt end
    local burstAt=D.kind~="player" and C.enemy.burstAt or C.player.collapseAt
    if not D.burst and D.age>=burstAt then D.burst=true;D.emit() end
    if D.kind=="player" then
        if not D.ambience and D.age>=C.player.ambienceAt then D.ambience=true;Sound.play("defeat_ambience",0.5) end
        if not D.text and D.age>=C.player.textAt then D.text=true;Sound.play("defeat_text_reveal",0.7) end
    end
    for i=1,D.count do
        local p=D.pool[i];p.age=p.age+dt
        if p.age>0 and p.age<p.life then
            local drag=math.exp(-dt*2.3);p.vx=p.vx*drag
            p.x=p.x+p.vx*dt+math.sin(p.spin+D.age*3)*dt*7;p.y=p.y+p.vy*dt
            p.vy=p.vy+dt*(p.kind=="ash" and 22 or -9)
        end
    end
end
function D.dissolve()
    return D.kind~="player" and D.kind~=nil and ramp(D.age/D.duration,C.enemy.breakAt,C.enemy.dissolvedAt) or 0
end
local function fallbackMask()
    local g=love.graphics;local n=C.enemy.fallbackGrid
    for row=0,n-1 do for col=0,n-1 do
        if random(row*n+col+1)>D.maskAmount then
            g.rectangle("fill",(col/n-0.5)*D.maskW,(row/n-0.5)*D.maskH,D.maskW/n+0.3,D.maskH/n+0.3)
        end
    end end
end
function D.drawEnemy(image,x,y,size,card)
    if D.kind~="enemy" and D.kind~="chest" then return false end
    if image and card then
        -- The dissolve shader receives the whole card, including its live frame.
        D.framedCards=D.framedCards or setmetatable({}, {__mode="k"})
        local level=card.evolutionLevel or 0
        local cached=D.framedCards[image]
        if not cached or cached.level~=level then
            local g=love.graphics;local Frame=require("ui.components.card_frame")
            local canvas=g.newCanvas(512,768)
            g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.clear()
            g.setBlendMode("alpha");g.setColor(1,1,1,1);g.scale(4)
            Frame.image(image,0,0,128,192);Frame.draw(0,0,128,192,nil,nil,card);g.pop()
            canvas:setFilter("linear","linear")
            cached={level=level,image=canvas};D.framedCards[image]=cached
        end
        image=cached.image
    end
    local g=love.graphics;local p=math.max(0,D.age-D.stop)/(D.duration-D.stop);local dissolve=D.dissolve()
    local fit=image and math.min(size/image:getWidth(),size/image:getHeight()) or 1
    g.push("all")
    local remains=1-ramp(p,0.72,1)
    g.setColor(0.07,0.055,0.065,0.28*remains*ramp(p,0.20,0.55))
    g.ellipse("fill",x,C.enemy.floorY,C.enemy.floorRadius,12)
    g.setBlendMode("add");Light.glow(x,C.enemy.floorY,140,C.enemy.ember,0.14*remains*ramp(p,0.05,0.30));g.setBlendMode("alpha")
    if image and dissolve<1 then
        g.translate(x+C.enemy.recoil*math.sin(clamp(p/0.35)*math.pi),y+9*p)
        g.rotate(D.kind=="chest" and math.sin(p*26)*0.045*(1-dissolve)
            or -C.enemy.rotation*math.sin(clamp(p/0.65)*math.pi))
        if D.shader then
            D.shader:send("dissolveAmount",dissolve);D.shader:send("crackAmount",ramp(p,C.enemy.crackAt,C.enemy.breakAt)*(1-dissolve))
            D.shader:send("flashAmount",(1-ramp(p,0.04,0.14))*0.8)
            D.shader:send("emberColor",D.kind=="chest" and {1,0.82,0.43} or C.enemy.ember);D.shader:send("crackGlowColor",C.enemy.crack);g.setShader(D.shader)
        end
        if not D.shader then
            D.maskW,D.maskH,D.maskAmount=image:getWidth()*fit,image:getHeight()*fit,dissolve
            g.stencil(fallbackMask,"replace",1);g.setStencilTest("greater",0)
        end
        g.setColor(1,1,1,1)
        g.draw(image,0,0,0,fit*(1+p*0.025),fit,image:getWidth()/2,image:getHeight()/2)
    end
    g.pop();return true
end
function D.drawParticles()
    local g=love.graphics;g.push("all");g.setShader()
    for i=1,D.count do
        local p=D.pool[i]
        if p.age>0 and p.age<p.life then
            local a=math.sin(math.pi*clamp(p.age/p.life))
            local col=D.kind=="chest" and {1,0.82,0.43} or D.kind=="player" and C.player.soul or p.kind=="ash" and C.enemy.ash or p.kind=="ember" and C.enemy.ember or C.enemy.smoke
            if p.kind=="smoke" then
                g.setBlendMode("alpha");Light.glow(p.x,p.y,p.size*(1+p.age),col,a*0.16)
            elseif p.kind=="ember" then
                g.setBlendMode("add");Light.glow(p.x,p.y,p.size*4,col,a*0.3)
                g.setColor(col[1],col[2],col[3],a);g.circle("fill",p.x,p.y,p.size*0.55)
            elseif p.kind=="shard" then
                g.push();g.translate(p.x,p.y);g.rotate(p.spin+p.age*3)
                g.setBlendMode("add");g.setColor(col[1],col[2],col[3],a*0.16)
                g.circle("fill",0,0,p.size*3)
                g.setBlendMode("alpha");g.setColor(1,0.93,0.72,a)
                g.polygon("fill",-p.size,-p.size/2,p.size/2,-p.size,p.size,p.size/2,-p.size/2,p.size)
                g.pop()
            else
                g.setBlendMode("alpha");g.setColor(col[1],col[2],col[3],a*0.8)
                g.push();g.translate(p.x,p.y);g.rotate(p.spin+p.age*2);g.rectangle("fill",-p.size/2,-1,p.size,2);g.pop()
            end
        end
    end
    if D.kind=="enemy" and D.monster and (D.monster.isBoss or D.monster.isElite) then
        local a=(1-ramp(D.age,0.10,0.35))*ramp(D.age,0.035,0.09)
        g.setBlendMode("add");g.setLineWidth(2);g.setColor(1,0.63,0.26,a*0.4)
        g.ellipse("line",D.x,D.y,35+D.age*370,12+D.age*100)
    end
    g.pop()
end
function D.cardProgress() return D.kind=="player" and ramp(D.age,0.16,0.85) or 0 end
function D.uiProgress() return D.kind=="player" and ramp(D.age,C.player.buttonsAt,C.player.duration) or 1 end
function D.drawCard(UI,card,x,y,w,h,index)
    local g=love.graphics;local p=D.cardProgress()
    g.push("all");g.translate(x+w/2,y+h/2+C.player.cardDrop*p)
    g.rotate((index%2==0 and -1 or 1)*C.player.cardTilt*p);g.translate(-x-w/2,-y-h/2)
    UI.CardPhysics.suspend();UI.drawCard(card,x,y,w,h);UI.CardPhysics.resume()
    g.setShader();g.setColor(0.025,0.023,0.04,p*0.72);g.rectangle("fill",x,y,w,h,6,6)
    g.pop()
end
function D.drawPlayer(UI)
    if D.kind~="player" then return end
    local g=love.graphics;local t=D.age;local collapse=D.cardProgress()
    g.push("all");g.setShader()
    -- Layered bottom fog closes around the cards while the victor stays readable.
    local dim=ramp(t,0.08,1.2)*C.player.dim
    g.setColor(C.player.shadow[1],C.player.shadow[2],C.player.shadow[3],dim);g.rectangle("fill",0,0,1280,720)
    for i=1,18 do
        local a=ramp(t,0.15,0.95)*(i/18)*0.038
        g.setColor(0.008,0.009,0.018,a);g.rectangle("fill",0,720-i*27,1280,i*27)
    end
    for i=1,12 do
        local a=C.overlay.vignette*ramp(t,0.04,0.95)/12
        g.setColor(0.005,0.006,0.015,a)
        g.rectangle("fill",0,0,1280,i*9);g.rectangle("fill",0,720-i*9,1280,i*9)
        g.rectangle("fill",0,0,i*12,720);g.rectangle("fill",1280-i*12,0,i*12,720)
    end
    g.setBlendMode("add")
    Light.glow(D.x,D.y,C.player.coreRadius*(1+collapse*1.4),C.player.soul,(1-collapse)*0.34)
    g.setLineWidth(1.5);g.setColor(0.48,0.62,0.80,(1-collapse)*0.65)
    for i=1,7 do
        local angle=i*math.pi*2/7
        local r=C.player.coreRadius*(1-collapse*0.4)
        g.line(D.x+math.cos(angle)*r,D.y+math.sin(angle)*r,D.x+math.cos(angle)*(r+18+collapse*55),D.y+math.sin(angle)*(r+18+collapse*55))
    end
    g.setBlendMode("alpha");D.drawParticles()
    local reveal=ramp(t,C.player.textAt,C.player.textAt+C.player.textFade)
    if reveal>0 then
        -- A broken seal, title and lingering dust replace a flat modal.
        g.setColor(0.49,0.38,0.43,reveal*0.14);g.setLineWidth(1)
        for i=1,9 do local a=i*math.pi*2/9
            g.arc("line","open",640,C.overlay.sigilY,92,a,a+0.43)
        end
        for i=1,C.overlay.dust do
            local x=380+random(i)*520;local y=140+(random(i+32)*270-(D.clock or t)*(3+random(i)*5))%270
            g.setColor(0.63,0.55,0.52,reveal*0.16);g.circle("fill",x,y,1+random(i+5))
        end
        g.push();g.translate(640,C.overlay.textY);local scale=1+(1-reveal)*0.055;g.scale(scale)
        g.setFont(UI.fonts.huge);g.setColor(0,0,0,reveal*0.9);g.printf(C.overlay.title,-640,4,1280,"center")
        g.setColor(0.77,0.57,0.55,reveal);g.printf(C.overlay.title,-640,0,1280,"center");g.pop()
    end
    g.pop()
end
return D

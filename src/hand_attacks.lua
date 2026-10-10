-- Bounded procedural geometry, reused by the real scoring sequence and isolated Lab.
local A = {config=require("config.hand_vfx_config")}
local C=A.config
local clamp=function(x) return math.max(0,math.min(1,x)) end
local mix=function(a,b,p) return a+(b-a)*p end
local smooth=function(p) p=clamp(p);return p*p*(3-2*p) end
local flight=function(p) return clamp(p)^C.motion.releasePower end
local projectileCount, paths, sample

function A.power(aura,target)
    target=tonumber(target) or C.fallbackTarget
    if target<=0 then target=C.fallbackTarget end
    local ratio=math.max(0,tonumber(aura) or 0)/target
    local tier=1
    for _,edge in ipairs(C.auraTiers) do if ratio>=edge then tier=tier+1 end end
    return clamp(math.log(1+math.min(ratio,64))/math.log(5)),tier,ratio
end
function A.new(result,cards,ui,target,handId)
    local id=handId
    if not id then
        local name=result.steps[1].handName
        for _,h in pairs(require("src.poker").HAND_TYPES) do if h.name==name then id=h.id;break end end
    end
    local profile=C.hands[id] or C.hands.high_card
    local intensity,tier,ratio=A.power(result.finalScore,target)
    local a={profile=profile,intensity=intensity,tier=tier,ratio=ratio, color=profile.colorProfile,
        sources={},rankOrder={},launch={},ribbon={},wave={},seal={},sigil={},beat=0,charge=0,orbit=0,quality="high",cx=ui.BATTLE_CENTER_X}
    local groups={}
    for i,card in ipairs(cards) do
        groups[card.rank]=(groups[card.rank] or 0)+1
        a.rankOrder[i]=i
        a.sources[i]={x=ui.getScoringCardX(i,#cards)+48,y=C.arena.coreY,card=card}
    end
    local wheel=(id=="straight" or id=="straight_flush") and groups[14] and groups[2] and not groups[13]
    table.sort(a.rankOrder,function(i,j)
        local r1=wheel and cards[i].rank==14 and 1 or cards[i].rank
        local r2=wheel and cards[j].rank==14 and 1 or cards[j].rank
        return r1<r2
    end)
    a.strongest=a.rankOrder[#a.rankOrder]
    for order,i in ipairs(a.rankOrder) do a.sources[i].order=order end
    for _,s in ipairs(a.sources) do s.cluster=groups[s.card.rank]>=3 and -1 or 1 end
    if id=="flush" then a.color=C.suitColors[cards[1] and cards[1].suit] or a.color end
    return a
end
function A.enter(a,phase)
    a.phase=phase
    a.beat=0
    if phase=="ENERGY_CONVERSION" then a.charge,a.orbit=0,0;a.launch={} end
    if phase=="ATTACK" then
        -- Freeze precisely the last charge pose: origin must never move while its trail is flying.
        a.charge=1;a.orbit=1.2
        for i=1,projectileCount(a) do
            local x,y=sample(a,i,"ANTICIPATION",1)
            a.launch[i]={x=x,y=y}
        end
    end
    if phase=="CONVERGENCE" and a.tier==5 then require("src.sound").silence(C.silence) end
    local key=({ENERGY_CONVERSION="charge",ATTACK="release",ENEMY_IMPACT="impact"})[phase]
    if key then require("src.sound").play(a.profile.soundHooks[key],0.9+a.intensity*0.3) end
end
function A.update(a,phase,p)
    if phase=="ENERGY_CONVERSION" then a.charge=p*0.55
    elseif phase=="ANTICIPATION" then a.charge=0.55+p*0.45
    elseif phase=="CONVERGENCE" then a.charge=1 end
    a.orbit=a.charge*1.2
    if phase~=(a.profile.rhythmPhase or "ATTACK") then return end
    local beats=a.profile.soundHooks.beats
    local n=0
    for _,at in ipairs(a.profile.soundHooks.beatTimes) do if p>=at then n=n+1 end end
    while a.beat<n do a.beat=a.beat+1; require("src.sound").play(beats[a.beat],0.9+a.beat*0.06) end
end
local function glow(g,col,alpha,width,x1,y1,x2,y2)
    for layer=3,1,-1 do
        g.setColor(col[1],col[2],col[3],math.min(1,alpha*C.bloom.gain)/(layer*layer))
        g.setLineWidth(math.max(0.5,width*layer*(layer==1 and 1 or C.trail.glow/2.8)));g.line(x1,y1,x2,y2)
    end
end
local function blade(g,a,x,y,angle,size,alpha)
    g.push();g.translate(x,y);g.rotate(angle)
    local image=require("render.lighting").radial
    if image then
        g.setColor(a.color[1],a.color[2],a.color[3],alpha*0.17)
        g.draw(image,-size*.35,-size*1.2,0,size*.7/128,size*1.85/128)
    end
    g.setBlendMode("alpha")
    g.setColor(a.color[1]*.48,a.color[2]*.48,a.color[3]*.48,alpha*.88)
    g.polygon("fill",0,-size,-size*.13,-size*.2,-size*.09,size*.37,0,size*.53,size*.09,size*.37,size*.13,-size*.2)
    g.setBlendMode("add")
    g.setColor(.96,.99,1,alpha*C.motion.coreAlpha)
    g.polygon("fill",0,-size,-size*.026,-size*.16,0,size*.37,size*.035,-size*.18)
    g.setColor(a.color[1],a.color[2],a.color[3],alpha*.75)
    g.setLineWidth(math.max(.7,size*.025));g.line(-size*.22,size*.36,0,size*.30,size*.22,size*.36)
    g.pop()
end
local function band(g,a,x,y,rx,ry,start,sweep,width,alpha)
    local points=a.ribbon;local count=16
    width=math.min(width,rx*.75)
    for j=0,count do
        local angle=start+sweep*j/count
        points[j*2+1]=x+math.cos(angle)*rx;points[j*2+2]=y+math.sin(angle)*ry
    end
    for j=count-1,1,-1 do
        local t=j/count;local angle=start+sweep*t
        local thickness=math.sin(t*math.pi)^1.3*width
        local index=(count+1+count-1-j)*2+1
        points[index]=x+math.cos(angle)*(rx-thickness)
        points[index+1]=y+math.sin(angle)*(ry-thickness*ry/rx)
    end
    g.setBlendMode("alpha")
    g.setColor(a.color[1]*.82,a.color[2]*.82,a.color[3]*.82,alpha)
    g.polygon("fill",points)
    g.setBlendMode("add")
    g.setColor(.9+.1*a.color[1],.9+.1*a.color[2],1,alpha*.46)
    g.setLineWidth(.8);g.polygon("line",points)
end
local function slash(g,a,x,y,angle,size,alpha)
    g.push();g.translate(x,y);g.rotate(angle)
    band(g,a,-size*.65,0,size*1.10,size*1.10,-1.25,1.95,size*.24,alpha*.10)
    band(g,a,-size*.65,0,size,size,-1.25,1.95,size*.13,alpha*.78)
    g.pop()
end
paths={}
local counts={spear=1,fusion=2,twin_blades=2,triangle=3,crossfire=4,orbital_blades=4}
projectileCount=function(a)
    if a.profile.blades then return math.min(a.profile.blades[a.tier],C.quality[a.quality]) end
    if a.profile.emitters then return math.min(a.profile.emitters,C.quality[a.quality]) end
    return counts[a.profile.projectile] or #a.sources
end
paths.spear=function(a,i,p)
    local source=a.sources[a.strongest]
    return source and source.x or a.cx,365,a.cx,270-(a.tier>=4 and 40 or 0),flight(p),0
end
paths.twin_blades=function(a,i,p)
    local side=i%2==1 and -1 or 1
    return a.cx+side*135,350,a.cx-side*18,258,flight((p-(i-1)*0.30)/0.70),side*65
end
paths.orbital_blades=function(a,i,p)
    local angle=(i-1)*math.pi*2/projectileCount(a)+a.orbit
    return a.cx+math.cos(angle)*105,295+math.sin(angle)*75,a.cx,270,
        flight((p-(i-1)*0.10)/(1-(i-1)*0.10)),math.sin(angle)*35
end
paths.triangle=function(a,i,p)
    local angle=(i-1)*math.pi*2/projectileCount(a)-math.pi/2+a.orbit
    return a.cx+math.cos(angle)*85,300+math.sin(angle)*70,a.cx,270,flight(p),math.cos(angle)*12
end
paths.chain=function(a,i,p)
    local source=a.sources[a.rankOrder[i]];local start=(i-1)*0.13
    return source.x,source.y,a.cx+(i-3)*7,270,flight((p-start)/(1-start)),(i%2==0 and -1 or 1)*(35+a.intensity*35)
end
paths.wave=function(a,i,p)
    local source=a.sources[i]
    return source.x,source.y,a.cx+(i-(#a.sources+1)/2)*14,265,smooth(p),math.sin(i*1.7)*70
end
paths.fusion=function(a,i,p)
    local side=i==1 and -1 or 1
    local orbit=side*a.charge*math.pi*1.3
    local r=45*(1-0.65*smooth((a.charge-0.55)/0.45))
    return a.cx+math.cos(orbit)*r*side,350+math.sin(orbit)*r*0.4,a.cx,270,flight(p),side*10
end
paths.crossfire=function(a,i,p)
    local angle=(i-1)*math.pi*2/projectileCount(a)-math.pi/2
    return a.cx+math.cos(angle)*105,270+math.sin(angle)*95,a.cx,270,flight(p),0
end
paths.blade_storm=function(a,i,p)
    local n=projectileCount(a);local angle=i*math.pi*2/n+a.orbit
    local depth=0.65+(i%3)*0.22;local r=(110+35*a.intensity)*depth
    local start=(i-1)/n*0.24
    return a.cx+math.cos(angle)*r,300+math.sin(angle)*r*0.7,a.cx,270,
        flight((p-start)/(1-start)),math.cos(angle)*30
end
sample=function(a,i,phase,p)
    local x0,y0,x1,y1,k,bend=paths[a.profile.projectile](a,i,phase=="ATTACK" and p or 0)
    if a.profile.advanced then
        local spread=a.profile.spread
        x0=a.cx+(x0-a.cx)*spread;y0=300+(y0-300)*spread
        k=clamp(k)^(a.profile.releasePower/C.motion.releasePower)
        bend=bend*spread
    end
    if phase~="ATTACK" then
        local source=a.sources[(i-1)%#a.sources+1]
        local form=smooth(a.charge/0.55)
        local windup=smooth((a.charge-0.55)/0.45)
        local dx,dy=x0-x1,y0-y1;local length=math.max(1,math.sqrt(dx*dx+dy*dy))
        local pull=C.motion.pullback*windup*(0.5+a.intensity)
        local drift=math.sin(a.charge*math.pi)*C.motion.drift
        return mix(source.x,x0,form)+dx/length*pull+math.sin(i*2.3+a.charge*5)*drift,
            mix(source.y,y0,form)+dy/length*pull+math.cos(i*1.7+a.charge*4)*drift
    end
    local origin=a.launch[i]
    if origin then x0,y0=origin.x,origin.y end
    return mix(x0,x1,k)+math.sin(k*math.pi)*bend,mix(y0,y1,k)
end
A.position=sample -- Pure geometry also checked headlessly for phase continuity.
local function trail(g,a,i,p,width)
    local segments=math.min(C.trail.segments,C.quality[a.quality]+4)
    local length=C.trail.length*(0.6+a.intensity*0.65)
    for layer=2,1,-1 do
        local lastX,lastY=sample(a,i,"ATTACK",clamp(p-length))
        for j=1,segments do
            local t=clamp(p-length+(j/segments)*length)
            local x,y=sample(a,i,"ATTACK",t)
            local dx,dy=x-lastX,y-lastY;local len=math.max(0.001,math.sqrt(dx*dx+dy*dy))
            local nx,ny=-dy/len,dx/len
            local w=width*(j/segments)^1.4*(layer==2 and 2.6 or 1)
            local oldW=width*((j-1)/segments)^1.4*(layer==2 and 2.6 or 1)
            g.setColor(a.color[1],a.color[2],a.color[3],(j/segments)^1.5*(layer==2 and 0.09 or 0.52))
            g.polygon("fill",lastX+nx*oldW,lastY+ny*oldW,x+nx*w,y+ny*w,x-nx*w,y-ny*w,lastX-nx*oldW,lastY-ny*oldW)
            lastX,lastY=x,y
        end
    end
end
local structures={}
structures.triangle=function(g,a,p)
    local vertices=a.seal
    for i=1,projectileCount(a) do local x,y=sample(a,i,"ANTICIPATION",0);vertices[i*2-1]=x;vertices[i*2]=y end
    g.setColor(a.color[1],a.color[2],a.color[3],0.5*(1-p)*smooth(a.charge/0.55));g.setLineWidth(2+a.intensity*2)
    g.polygon("line",vertices)
end
structures.orbital_blades=function(g,a,p)
    g.setColor(a.color[1],a.color[2],a.color[3],0.3*(1-p));g.setLineWidth(2)
    g.ellipse("line",a.cx,270,105,65)
    g.ellipse("line",a.cx,270,65,105)
end
structures.chain=function(g,a,p)
    for i=1,#a.rankOrder-1 do
        local source=a.sources[a.rankOrder[i]];local nextSource=a.sources[a.rankOrder[i+1]]
        glow(g,a.color,(1-p)*0.5,2,source.x,source.y,nextSource.x,nextSource.y-6)
    end
end
structures.wave=function(g,a,p)
    if p>0.3 then
        g.setColor(a.color[1],a.color[2],a.color[3],0.45*(1-p))
        g.setLineWidth(4+a.intensity*8);g.ellipse("line",a.cx,365-p*100,25+p*85,8+p*15)
    end
end
structures.fusion=function(g,a,p)
    g.setColor(a.color[1],a.color[2],a.color[3],0.25*(1-p));g.setLineWidth(2)
    g.ellipse("line",a.cx,350,55*(1-p)+12,22*(1-p)+8)
end
structures.crossfire=function(g,a,p)
    for i=1,projectileCount(a) do
        local x,y=sample(a,i,"ANTICIPATION",0)
        g.setColor(a.color[1],a.color[2],a.color[3],0.7)
        g.setLineWidth(2);g.rectangle("line",x-10-a.intensity*6,y-10-a.intensity*6,20+a.intensity*12,20+a.intensity*12)
        if p>0 then glow(g,a.color,math.sin(p*math.pi)*0.8,2+a.intensity*7,x,y,a.cx,270) end
    end
end
structures.blade_storm=function(g,a,p)
    if p>0.78 then blade(g,a,a.cx,270,0,70+35*a.intensity,(p-0.78)/0.22) end
    g.setColor(a.color[1],a.color[2],a.color[3],0.22*(1-p));g.setLineWidth(2)
    g.ellipse("line",a.cx,300,135,95)
end
local impacts={}
impacts.pierce=function(g,a,r,k)
    local fade=(1-k)^2
    glow(g,a.color,fade,5+a.intensity*3,a.cx,298,a.cx,206-k*42)
    blade(g,a,a.cx,242-k*30,0,38*(1-k)+18,fade)
    band(g,a,a.cx,270,r*.68,r*.25,0.15,2.7,5,fade*.5)
end
impacts.cross=function(g,a,r,k)
    local fade=(1-k)^2
    slash(g,a,a.cx,270,-.85,r*.95+20,fade)
    slash(g,a,a.cx,270,.85,r*.95+20,fade*.8)
end
impacts.collapse=function(g,a,r,k)
    for i=1,4 do
        local angle=i*math.pi/2+k*.5
        band(g,a,a.cx,270,r,r*.62,angle,1.12,9+7*a.intensity,(1-k)^2*.8)
        glow(g,a.color,(1-k)^3,2,a.cx+math.cos(angle)*r,270+math.sin(angle)*r*.62,a.cx,270)
    end
end
impacts.triangle_seal=function(g,a,r,k)
    local points=a.seal;local spin=-k*.18
    for i=1,3 do
        local angle=i*math.pi*2/3-math.pi/2+spin
        points[i*2-1]=a.cx+math.cos(angle)*r;points[i*2]=270+math.sin(angle)*r*.8
    end
    g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^3*.07);g.polygon("fill",points)
    g.setLineWidth(2+3*(1-k));g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^2*.8);g.polygon("line",points)
    for i=1,3 do
        local x,y=points[i*2-1],points[i*2]
        blade(g,a,x,y,i*math.pi*2/3+spin,10+10*(1-k),(1-k)^2)
    end
end
impacts.long_wave=function(g,a,r,k)
    for i=1,5 do
        local age=clamp(k-(i-1)*.045);local x=a.cx+(i-3)*17
        slash(g,a,x,270+math.sin(i*1.7)*12,-.22+(i-3)*.13,r*.6+18,(1-age)^3*.65)
    end
end
impacts.tidal_wave=function(g,a,r,k)
    band(g,a,a.cx,270,r*1.65,r*.55,.05,2.95,13+10*a.intensity,(1-k)^2*.78)
    band(g,a,a.cx,276,r*1.15,r*.38,math.pi+.2,2.7,7,(1-k)^3*.5)
end
impacts.detonation=function(g,a,r,k)
    local image=require("render.lighting").radial
    if image then
        g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^3*.45)
        g.draw(image,a.cx-r,270-r*.8,0,r/64,r*.8/64)
    end
    for i=1,3 do
        band(g,a,a.cx,270,r*(.7+i*.17),r*(.28+i*.1),i*2.1+k,1.9,12*(1-k)+2,(1-k)^2*.65)
    end
    blade(g,a,a.cx,270,0,28*(1-k)+12,(1-k)^3)
end
impacts.square_seal=function(g,a,r,k)
    local size=r*.68;local gap=size*.32
    g.push();g.translate(a.cx,270);g.rotate(.785+k*.12)
    for i=1,4 do
        g.push();g.rotate(i*math.pi/2)
        glow(g,a.color,(1-k)^2,3+3*(1-k),-size+gap,-size,-size,-size)
        glow(g,a.color,(1-k)^2,3+3*(1-k),-size,-size,-size,-size+gap)
        g.pop()
    end
    g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^3*.45);g.setLineWidth(1)
    g.rectangle("line",-size*.48,-size*.48,size*.96,size*.96);g.pop()
end
impacts.grand_convergence=function(g,a,r,k)
    blade(g,a,a.cx,268-k*18,0,105*(1-k)+24,(1-k)^1.6)
    band(g,a,a.cx,270,r*1.5,r*.44,-.2,2.8,12,(1-k)^2*.65)
    band(g,a,a.cx,270,r*1.15,r*.34,math.pi+.15,2.8,8,(1-k)^3*.5)
    for i=1,6 do
        local angle=i*2.399
        glow(g,a.color,(1-k)^2,2,a.cx+math.cos(angle)*r*.5,270+math.sin(angle)*r*.4,a.cx+math.cos(angle)*r*1.1,270+math.sin(angle)*r*.6)
    end
end
local heads={}
heads.spear=function(g,a,x,y,angle,p) blade(g,a,x,y,angle,20+25*a.intensity,0.85) end
heads.twin_blades=function(g,a,x,y,angle,p)
    slash(g,a,x,y,angle,30+20*a.intensity,0.9)
    blade(g,a,x,y,angle,18+18*a.intensity,0.6)
end
heads.orbital_blades=function(g,a,x,y,angle,p)
    slash(g,a,x,y,angle,18+12*a.intensity,0.65)
    blade(g,a,x,y,angle,16+14*a.intensity,0.8)
end
heads.blade_storm=function(g,a,x,y,angle,p,i)
    local depth=0.65+((i or 1)%3)*0.20
    local fade=a.phase=="ATTACK" and 1-smooth((p-0.65)/0.32) or 1
    local shimmer=0.9+0.1*math.sin(a.charge*14+(i or 1)*2)
    blade(g,a,x,y,angle,(12+16*a.intensity)*depth,0.52*fade*shimmer)
end
heads.triangle=function(g,a,x,y,angle,p)
    g.setColor(a.color[1],a.color[2],a.color[3],0.25);g.circle("fill",x,y,12+8*a.intensity)
    g.setColor(1,0.9,1,0.85);g.circle("fill",x,y,3+4*a.intensity)
    g.circle("line",x,y,9+4*a.intensity)
end
heads.chain=function(g,a,x,y,angle,p)
    glow(g,a.color,0.9,3+a.intensity*4,x-10,y+14,x+6,y-16)
end
heads.wave=function(g,a,x,y,angle,p)
    g.push();g.translate(x,y);g.rotate(angle)
    band(g,a,0,0,26+16*a.intensity,14+10*a.intensity,math.pi+.15,2.85,6+5*a.intensity,.65)
    g.pop()
end
heads.fusion=function(g,a,x,y,angle,p)
    local radius=(10+12*a.intensity)*(1-math.sin(p*math.pi)*0.35)
    g.setColor(a.color[1],a.color[2],a.color[3],0.25);g.circle("fill",x,y,radius*1.6)
    g.setColor(a.color[1],a.color[2],a.color[3],0.85);g.circle("line",x,y,radius)
    g.setColor(1,0.93,0.8,0.9);g.circle("fill",x,y,radius*0.4)
end
heads.crossfire=function(g,a,x,y,angle,p)
    g.setColor(a.color[1],a.color[2],a.color[3],0.6);g.circle("line",x,y,5+a.intensity*4)
end
function A.draw(a,phase,p,impactAge)
    local g=love.graphics
    g.push("all")
    local left,top=g.transformPoint(C.arena.left,C.arena.top)
    local right,bottom=g.transformPoint(C.arena.left+C.arena.width,C.arena.top+C.arena.height)
    g.setScissor(left,top,right-left,bottom-top);g.setBlendMode("add")
    local active=phase=="ENERGY_CONVERSION" or phase=="ANTICIPATION" or phase=="CONVERGENCE" or phase=="ATTACK"
    if active then
        if a.profile.advanced then require("ui.advanced_hand_sigils").draw(g,a,a.charge,(phase=="ATTACK" and (1-p)^2 or 0.65)*0.8) end
        local structure=not a.profile.advanced and structures[a.profile.projectile]
        if structure then structure(g,a,phase=="ATTACK" and p or 0) end
        local n=projectileCount(a)
        for i=1,n do
            local x,y=sample(a,i,phase,p)
            local aheadX,aheadY=sample(a,i,phase,math.min(1,p+0.003))
            local dx,dy=aheadX-x,aheadY-y
            if math.abs(dx)+math.abs(dy)<0.001 then dx,dy=a.cx-x,270-y end
            local angle=math.atan2 and math.atan2(dx,-dy) or math.atan(dx/(-dy+0.001))
            local width=(2+a.intensity*4)*(a.profile.advanced and 1.15 or 1)
            if a.profile.projectile=="wave" then width=width*1.8 end
            if phase=="ATTACK" then trail(g,a,i,p,width) end
            g.push();g.translate(x,y)
            local build=0.15+0.85*smooth(a.charge/0.55)
            local compression=phase=="ANTICIPATION" and 1-0.15*smooth(p) or 1
            g.rotate(angle);g.scale(build*compression,build/compression);g.rotate(-angle);g.translate(-x,-y)
            heads[a.profile.projectile](g,a,x,y,angle,p,i)
            g.pop()
        end
    end
    if impactAge and impactAge<C.camera.duration then
        local k=clamp(impactAge/C.camera.duration)
        local expansion=1-(1-k)^C.motion.impactExpansion
        local radius=8+expansion*C.shockwave.radius*(0.3+a.intensity)
        g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^2*0.82)
        g.setLineWidth(C.shockwave.thickness*(1-k)+0.8)
        local ring=a.wave
        for i=0,24 do
            local angle=i*math.pi/12
            local ripple=1+0.025*math.sin(angle*7+a.tier)
            ring[i*2+1]=a.cx+math.cos(angle)*radius*ripple
            ring[i*2+2]=C.arena.targetY+math.sin(angle)*radius*0.48*ripple
        end
        g.polygon("line",ring)
        if k<0.62 then
            g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^3*0.48)
            g.setLineWidth(1+3*(1-k))
            g.ellipse("line",a.cx,C.arena.targetY,radius*0.48,radius*0.22)
        end
        if a.tier>=4 and a.profile.id=="high_card" and k>0.35 then
            g.circle("line",a.cx,C.arena.targetY-40,(k-0.35)*80)
        end
        -- A narrow hot contact, then the wider hand-specific silhouette and wave.
        -- Keeps the boss readable while making the very first frozen frame feel like a hit.
        g.setColor(0.96,0.99,1,0.9*(1-k)^6)
        g.ellipse("fill",a.cx,270,(17+19*a.intensity)*(1-k)^2,5+4*a.intensity)
        g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^2*0.75)
        if a.profile.advanced then
            require("ui.advanced_hand_sigils").draw(g,a,k,(1-k)^2*.9,true)
        else impacts[a.profile.impact](g,a,radius+(1-k)^3*14*a.intensity,k) end
        local burstCount=math.min(math.floor(6+(C.particle.count-6)*a.intensity),C.quality[a.quality])
        for i=1,burstCount do
            local spread=(i-0.5)/burstCount-0.5
            local angle=a.profile.advanced and i*2.399 or math.pi/2+spread*2.45
            local distance=(1-(1-k)^2)*(C.particle.length+((i*7)%11)*2)*(0.65+a.intensity)
            local x=a.cx+math.cos(angle)*distance;local y=270+math.sin(angle)*distance*0.72
            local trail=8+10*(1-k)
            glow(g,a.color,(1-k)^2,1.2,x,y,x-math.cos(angle)*trail,y-math.sin(angle)*trail*0.72)
        end
    end
    g.pop()
end
local conversions={}
conversions.edge_spear=function(a,i,p) return 0,-30*p,0 end
conversions.split=function(a,i,p) local sign=i%2==1 and -1 or 1;return sign*35*p,-12*p,sign*0.4*p end
conversions.orbit_pairs=function(a,i,p) local n=a.sources[i].order;return math.cos(n*math.pi/2+p)*55*p,math.sin(n*math.pi/2+p)*40*p,p*0.7 end
conversions.triangle_nodes=function(a,i,p) return math.cos(i*math.pi*2/3)*50*p,math.sin(i*math.pi*2/3)*40*p,p*0.2 end
conversions.rank_chain=function(a,i,p) return math.sin(p*math.pi)*20,-a.sources[i].order*9*p,p*0.12 end
conversions.ribbons=function(a,i,p) return math.sin(i+p*4)*65*p,-20*p,math.sin(p*math.pi)*0.65 end
conversions.dual_clusters=function(a,i,p) return a.sources[i].cluster*50*p,-18*p,a.sources[i].cluster*p*0.4 end
conversions.cardinal=function(a,i,p) local angle=(i-1)*math.pi/2;return math.cos(angle)*65*p,math.sin(angle)*65*p,p*0.3 end
conversions.blade_fragments=function(a,i,p) local angle=i*math.pi*2/5;return math.cos(angle)*85*p,math.sin(angle)*60*p,p*(i%2==0 and 1 or -1) end
function A.cardPose(a,i,p)
    local eased=smooth(p)
    local dx,dy,r=conversions[a.profile.cardConversion](a,i,eased)
    if a.profile.advanced then
        local tx,ty=sample(a,(i-1)%projectileCount(a)+1,"ANTICIPATION",1)
        dx=mix(dx,(tx-a.sources[i].x)*.52,eased)
        dy=mix(dy,(ty-a.sources[i].y)*.6,eased)
    end
    local lift=math.sin(p*math.pi)*8
    return dx,dy-lift,r,math.max(0.10,1-smooth((p-0.08)/0.92)*0.9)
end
function A.fragments(a,i,p,x,y)
    if p<=0 or p>=1 then return end
    local g=love.graphics
    local dest=i
    if a.profile.projectile=="fusion" then dest=a.sources[i].cluster==-1 and 1 or 2
    elseif a.profile.projectile=="spear" then dest=1 end
    local tx,ty=sample(a,dest,"ANTICIPATION",1)
    local dx,dy=A.cardPose(a,i,p)
    g.push("all");g.setBlendMode("add")
    for j=1,math.min(8,C.quality[a.quality]) do
        local k=clamp((p-(j-1)*0.04)/0.65)
        local bend=math.sin(i*2.1+j*0.8)*28*math.sin(k*math.pi)
        local fx=mix(x+dx*0.3,tx,k)+bend;local fy=mix(y+dy*0.3,ty,k)-math.sin(k*math.pi)*16
        local alpha=math.sin(k*math.pi)*(1-p)*1.3
        if a.profile.cardConversion=="blade_fragments" then blade(g,a,fx,fy,j*0.35,6+6*k,alpha)
        else glow(g,a.color,alpha,1.2,fx,fy,fx-(tx-x)*0.07,fy-(ty-y)*0.07) end
    end
    g.pop()
end
return A

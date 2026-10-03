-- Bounded procedural geometry, reused by the real scoring sequence and isolated Lab.
local A = {config=require("config.hand_vfx_config")}
local C=A.config
local clamp=function(x) return math.max(0,math.min(1,x)) end
local mix=function(a,b,p) return a+(b-a)*p end
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
        sources={},rankOrder={},beat=0,quality="high",cx=ui.BATTLE_CENTER_X}
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
    a.beat=0
    if phase=="CONVERGENCE" and a.tier==5 then require("src.sound").silence(C.silence) end
    local key=({ENERGY_CONVERSION="charge",ATTACK="release",ENEMY_IMPACT="impact"})[phase]
    if key then require("src.sound").play(a.profile.soundHooks[key],0.9+a.intensity*0.3) end
end
function A.update(a,phase,p)
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
    g.setColor(a.color[1],a.color[2],a.color[3],alpha*0.18)
    g.ellipse("fill",0,0,size*0.32,size*1.5)
    g.setColor(a.color[1],a.color[2],a.color[3],alpha)
    g.polygon("fill",0,-size,-size*0.12,size*0.55,0,size*0.38,size*0.12,size*0.55)
    g.setColor(1,1,1,alpha);g.line(0,-size,0,size*0.38);g.pop()
end
local function trail(g,a,x0,y0,x1,y1,p,bend,width)
    local segments=math.min(C.trail.segments,C.quality[a.quality])
    local length=C.trail.length*(0.6+a.intensity*0.8)
    for j=1,segments do
        local t=clamp(p-(segments-j)*length/segments)
        local prev=clamp(t-length/segments)
        local x=mix(x0,x1,t)+math.sin(t*math.pi)*bend
        local y=mix(y0,y1,t)
        glow(g,a.color,j/segments*0.65,width*j/segments,
            mix(x0,x1,prev)+math.sin(prev*math.pi)*bend,mix(y0,y1,prev),x,y)
    end
end
local paths={}
paths.spear=function(a,i,p)
    local source=a.sources[a.strongest]
    return source and source.x or a.cx,C.arena.coreY, a.cx,C.arena.targetY-(a.tier>=4 and 40 or 0), p^0.45,0
end
paths.twin_blades=function(a,i,p)
    local side=i%2==1 and -1 or 1
    return a.cx+side*135,370,a.cx-side*36,245,clamp((p-(i-1)*0.30)/0.70),side*30
end
paths.orbital_blades=function(a,i,p)
    local angle=(i-1)*math.pi/2+(1-p)*1.6+(a.orbit or 0)
    local r=100*(1-clamp((p-0.25)/0.75))
    return a.cx+math.cos(angle)*r,270+math.sin(angle)*r,a.cx,270,clamp((p-(i-1)*0.10)/0.7),math.sin(angle)*25
end
paths.triangle=function(a,i,p)
    local angle=(i-1)*math.pi*2/3-math.pi/2+(1-p)*0.25+(a.orbit or 0)
    return a.cx+math.cos(angle)*85,300+math.sin(angle)*85,a.cx,270,p,0
end
paths.chain=function(a,i,p)
    local source=a.sources[a.rankOrder[i]]
    local start=(i-1)*0.13
    return source.x,source.y,a.cx+(i-3)*8,270,clamp((p-start)/(1-start))^0.65,(i%2==0 and -1 or 1)*(35+a.intensity*35)
end
paths.wave=function(a,i,p)
    local source=a.sources[i]
    return source.x,source.y,a.cx+(i-(#a.sources+1)/2)*20,265,p,math.sin(i*1.7)*70*(1-p)
end
paths.fusion=function(a,i,p)
    local side=i==1 and -1 or 1
    local orbit=side*(1-p)*math.pi
    return a.cx+math.cos(orbit)*45*side*(1-p),350+math.sin(orbit)*25,a.cx,270,clamp((p-0.25)/0.75)^0.6,0
end
paths.crossfire=function(a,i,p)
    local angle=(i-1)*math.pi/2-math.pi/2
    return a.cx+math.cos(angle)*100,270+math.sin(angle)*100,a.cx,270,p,0
end
paths.blade_storm=function(a,i,p)
    local n=math.min(a.profile.blades[a.tier],C.quality[a.quality])
    local angle=i*math.pi*2/n+(1-p)*0.6+(a.orbit or 0)
    local depth=0.65+(i%3)*0.22
    local r=(100+35*a.intensity)*depth
    local k=clamp((p-(i-1)/n*0.24)/0.76)^0.65
    return a.cx+math.cos(angle)*r,300+math.sin(angle)*r*0.7,a.cx,270,k,math.cos(angle)*18
end
local structures={}
structures.triangle=function(g,a,p)
    local vertices={}
    for i=1,3 do local x,y=paths.triangle(a,i,0);vertices[#vertices+1]=x;vertices[#vertices+1]=y end
    g.setColor(a.color[1],a.color[2],a.color[3],0.5*(1-p));g.setLineWidth(2+a.intensity*2)
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
    for i=1,4 do
        local x,y=paths.crossfire(a,i,0)
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
    glow(g,a.color,(1-k)^2,3,a.cx,295,a.cx,225-k*30)
end
impacts.cross=function(g,a,r,k)
    glow(g,a.color,(1-k)^2,3+a.intensity*5,a.cx-r,270-r,a.cx+r,270+r)
    glow(g,a.color,(1-k)^2,3+a.intensity*5,a.cx+r,270-r,a.cx-r,270+r)
end
impacts.collapse=function(g,a,r,k)
    for i=1,4 do local t=i*math.pi/2;glow(g,a.color,1-k,3,a.cx+math.cos(t)*r,270+math.sin(t)*r,a.cx+math.cos(t)*r*0.3,270+math.sin(t)*r*0.3) end
end
impacts.triangle_seal=function(g,a,r,k)
    local points={}
    for i=1,3 do local t=i*math.pi*2/3-math.pi/2;points[#points+1]=a.cx+math.cos(t)*r;points[#points+1]=270+math.sin(t)*r end
    g.polygon("line",points)
end
impacts.long_wave=function(g,a,r,k)
    for i=1,5 do local x=a.cx+(i-3)*14;glow(g,a.color,(1-k)^2,2,x,300+k*20,x+math.sin(i)*r*0.3,220-k*30) end
end
impacts.tidal_wave=function(g,a,r,k)
    g.ellipse("line",a.cx,270,r*1.6,r*0.42)
    g.arc("line","open",a.cx,270,r,math.pi*0.1,math.pi*0.9)
end
impacts.detonation=function(g,a,r,k)
    g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^3*0.2);g.circle("fill",a.cx,270,r*0.7)
    g.setColor(1,0.85,0.6,(1-k)^2*0.8);g.circle("line",a.cx,270,r*0.45)
    g.circle("line",a.cx,270,r*1.25)
end
impacts.square_seal=function(g,a,r,k)
    g.push();g.translate(a.cx,270);g.rotate(k*0.35)
    g.rectangle("line",-r*0.6,-r*0.6,r*1.2,r*1.2)
    g.rectangle("line",-r*0.3,-r*0.3,r*0.6,r*0.6);g.pop()
end
impacts.grand_convergence=function(g,a,r,k)
    blade(g,a,a.cx,270,0,80*(1-k)+20,1-k)
    g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^2*0.6)
    g.ellipse("line",a.cx,270,r*1.6,r*0.4)
    for i=1,6 do local angle=i*math.pi/3;glow(g,a.color,(1-k)^2,2,a.cx+math.cos(angle)*r*0.5,270+math.sin(angle)*r*0.5,a.cx+math.cos(angle)*r,270+math.sin(angle)*r) end
end
local heads={}
heads.spear=function(g,a,x,y,angle,p) blade(g,a,x,y,angle,20+25*a.intensity,0.85) end
heads.twin_blades=heads.spear;heads.orbital_blades=heads.spear
heads.blade_storm=function(g,a,x,y,angle,p) blade(g,a,x,y,angle,12+16*a.intensity,0.65) end
heads.triangle=function(g,a,x,y,angle,p)
    g.setColor(a.color[1],a.color[2],a.color[3],0.25);g.circle("fill",x,y,12+8*a.intensity)
    g.setColor(1,0.9,1,0.85);g.circle("fill",x,y,3+4*a.intensity)
    g.circle("line",x,y,9+4*a.intensity)
end
heads.chain=function(g,a,x,y,angle,p)
    glow(g,a.color,0.9,3+a.intensity*4,x-10,y+14,x+6,y-16)
end
heads.wave=function(g,a,x,y,angle,p)
    g.setColor(a.color[1],a.color[2],a.color[3],0.6);g.setLineWidth(3+a.intensity*5)
    g.arc("line","open",x,y,12+a.intensity*10,math.pi,math.pi*2)
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
    a.orbit=phase=="ATTACK" and 0 or p*0.7
    g.push("all")
    local left,top=g.transformPoint(C.arena.left,C.arena.top)
    local right,bottom=g.transformPoint(C.arena.left+C.arena.width,C.arena.top+C.arena.height)
    g.setScissor(left,top,right-left,bottom-top);g.setBlendMode("add")
    local active=phase=="ENERGY_CONVERSION" or phase=="ANTICIPATION" or phase=="CONVERGENCE" or phase=="ATTACK"
    if active then
        local structure=structures[a.profile.projectile]
        if structure then structure(g,a,phase=="ATTACK" and p or 0) end
        local n= a.profile.projectile=="spear" and 1 or (a.profile.projectile=="fusion" and 2 or #a.sources)
        if a.profile.blades then n=math.min(a.profile.blades[a.tier],C.quality[a.quality]) end
        for i=1,n do
            local t=phase=="ATTACK" and p or 0
            local x0,y0,x1,y1,k,bend=paths[a.profile.projectile](a,i,t)
            local x=mix(x0,x1,k)+math.sin(k*math.pi)*bend
            local y=mix(y0,y1,k)
            local width=2+a.intensity*5
            if a.profile.projectile=="wave" then width=width*1.7 end
            if t>0 then trail(g,a,x0,y0,x1,y1,k,bend,width) end
            g.push();g.translate(x,y)
            local build=phase=="ENERGY_CONVERSION" and (0.25+0.75*p) or 1
            g.scale(build,build);g.translate(-x,-y)
            heads[a.profile.projectile](g,a,x,y,math.atan2 and math.atan2(x1-x0,y0-y1) or math.atan((x1-x0)/(y0-y1+0.001)),p)
            g.pop()
        end
    end
    if impactAge and impactAge<C.camera.duration then
        local k=clamp(impactAge/C.camera.duration)
        local radius=8+k*C.shockwave.radius*(0.3+a.intensity)
        g.setColor(a.color[1],a.color[2],a.color[3],(1-k)^2*0.7)
        g.setLineWidth(C.shockwave.thickness*(1-k)+0.5)
        g.circle("line",a.cx,C.arena.targetY,radius)
        if a.tier>=4 and a.profile.id=="high_card" and k>0.35 then
            g.circle("line",a.cx,C.arena.targetY-40,(k-0.35)*80)
        end
        impacts[a.profile.impact](g,a,radius,k)
        for i=1,math.min(math.floor(6+(C.particle.count-6)*a.intensity),C.quality[a.quality]) do
            local angle=-math.pi/2+(i%7-3)*0.22
            local distance=k*(C.particle.length+i*2)*(0.5+a.intensity)
            local x=a.cx+math.cos(angle)*distance;local y=270+math.sin(angle)*distance
            glow(g,a.color,(1-k)^3,1,x,y,x+math.cos(angle)*6,y+math.sin(angle)*6)
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
    local dx,dy,r=conversions[a.profile.cardConversion](a,i,p)
    return dx,dy,r,math.max(0.12,1-p*0.86)
end
function A.fragments(a,i,p,x,y)
    local g=love.graphics
    local dx,dy=A.cardPose(a,i,p)
    g.push("all");g.setBlendMode("add")
    for j=1,math.min(10,C.quality[a.quality]) do
        local k=j/10
        if a.profile.cardConversion=="blade_fragments" then blade(g,a,x+dx*k,y+dy*k,j*0.35,5+5*p,(1-p)*p) end
        local bend=a.profile.cardConversion=="ribbons" and math.sin(k*math.pi+p*5)*16 or 0
        glow(g,a.color,(1-p)*p,1,x+dx*k+bend,y+dy*k-j*p,x+dx*k+dx*0.15+bend,y+dy*k+dy*0.15-j*p)
    end
    g.pop()
end
return A

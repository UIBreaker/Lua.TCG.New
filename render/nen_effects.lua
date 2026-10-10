-- Shared preloaded materials; independent silhouettes and motion for every hand.
local N=require("src.nen_combat")
local C=N.config
local E={diagnostics={},shader=nil}
local clamp=function(p) return math.max(0,math.min(1,p)) end
local out=function(p) return 1-(1-clamp(p))^3 end
local smooth=function(p) p=clamp(p);return p*p*(3-2*p) end
local mix=function(a,b,p) return a+(b-a)*p end
function E.load()
    if E.shader and E.shader.release then E.shader:release() end
    E.diagnostics={};local ok,shader=pcall(love.graphics.newShader,"shaders/nen_material.glsl")
    E.shader=ok and shader or nil
    if not ok then E.diagnostics[1]=tostring(shader);print("[NEN] Material fallback: "..tostring(shader)) end
    if E.shader then
        -- Warm the material pipeline during load, before the first ultimate.
        local g=love.graphics;local old=g.getCanvas();g.push("all")
        local warmOK,canvas=pcall(g.newCanvas,1280,720)
        if warmOK then
            g.setCanvas(canvas);g.setShader(E.shader);g.setColor(1,1,1,1)
            E.shader:send("screenCenter",{4,4});E.shader:send("pixelScale",1)
            E.shader:send("clock",0);E.shader:send("charge",1)
            for material=1,8 do E.shader:send("material",material);g.rectangle("fill",0,0,8,8) end
            local ready,err=pcall(function()
                local attacks=require("src.hand_attacks")
                local ranks={high_card={14},pair={8,8},two_pair={8,8,11,11},three_of_a_kind={8,8,8},
                    straight={7,8,9,10,11},flush={2,5,8,11,14},full_house={8,8,8,11,11},four_of_a_kind={8,8,8,8},straight_flush={10,11,12,13,14}}
                local ui={BATTLE_CENTER_X=635,getScoringCardX=function(i,count)return 635-count*55+(i-1)*110 end}
                for _,id in ipairs(C.order) do
                    local cards={}
                    for i,rank in ipairs(ranks[id] or attacks.config.hands[id].previewCards) do cards[i]={id=i,rank=rank,suit="spades"} end
                    for tier,ratio in ipairs({.25,1,2.5}) do
                        local a=attacks.new({steps={{}},finalScore=1000},cards,ui,1000,id,{targetAura=1000/ratio})
                        local n=a.nen;n.charge=1
                        E.draw(a,"CHARGE",1)
                        for i=1,N.count(a) do local x,y=N.position(a,i,"CHARGE",1);n.launch[i]={x=x,y=y} end
                        n.travel=.65;E.draw(a,"TRAVEL",.65);E.draw(a,"ENEMY_IMPACT",.5,.08)
                        N.cancel(a)
                    end
                end
            end)
            if not ready then E.diagnostics[#E.diagnostics+1]=tostring(err);print("[NEN] Geometry warm-up: "..tostring(err)) end
            -- Complete queued warm-up work while loading, rather than on first present.
            local flushed,data=pcall(canvas.newImageData,canvas)
            if flushed and data.release then data:release() end
            g.setCanvas(old);canvas:release()
        end
        g.pop()
    end
end
local function color(g,a,alpha,mul)
    local c=a.color;g.setColor(c[1]*(mul or 1),c[2]*(mul or 1),c[3]*(mul or 1),alpha or 1)
end
local function stroke(g,a,alpha,width,...)
    g.setShader();g.setBlendMode("alpha");color(g,a,alpha*.16);g.setLineWidth(width*3);g.line(...)
    color(g,a,alpha);g.setLineWidth(width);g.line(...)
end
local function fill(g,a,alpha,...)
    g.setBlendMode("alpha");g.setShader(a.nen.materialShader);color(g,a,alpha)
    g.polygon("fill",...);g.setShader()
    local c=a.color;g.setColor(c[1]*.76+.24,c[2]*.76+.24,c[3]*.76+.24,alpha*.88)
    g.setLineWidth(1.2);g.polygon("line",...)
end
local function soft(g,a,x,y,r,alpha)
    local image=require("render.lighting").radial
    if not image then return end
    g.setShader();g.setBlendMode("add");color(g,a,alpha)
    g.draw(image,x-r,y-r*.72,0,r/64,r*.72/64);g.setBlendMode("alpha")
end
local function lance(g,a,x,y,size,alpha)
    fill(g,a,alpha,x,y-size,x-size*.15,y-size*.38,x-size*.06,y+size*.3,x+size*.06,y+size*.3,x+size*.15,y-size*.38)
    stroke(g,a,alpha,1.6,x,y-size,x,y+size*.45)
    stroke(g,a,alpha*.85,2,x-size*.24,y+size*.15,x+size*.24,y+size*.15)
end
local function guardian(g,a,x,y,size,alpha,side,armed)
    g.push();g.translate(x,y);g.scale(size,size)
    -- Helmet, pauldrons, tapering torso and split cloak remain readable without bloom.
    fill(g,a,alpha,-8,-41,-6,-56,6,-56,8,-41,0,-35)
    fill(g,a,alpha,-17,-32,-10,-41,10,-41,17,-32,11,-9,0,8,-11,-9)
    fill(g,a,alpha*.76,-13,-17,-24,15,-6,8,0,-8)
    fill(g,a,alpha*.76,13,-17,24,15,6,8,0,-8)
    stroke(g,a,alpha*.8,1,-5,-47,5,-47)
    if armed then
        if side<0 then fill(g,a,alpha,-24,-33,-9,-30,-9,-7,-18,4,-28,-12)
        else lance(g,a,24,-21,50,alpha) end
    else stroke(g,a,alpha,2,side*15,-29,side*35,-70) end
    g.pop()
end
local function rider(g,a,x,y,size,alpha,mounted)
    g.push();g.translate(x,y);g.scale(size,size)
    if mounted then
        local gait=a.nen.reducedMotion and 0 or math.sin(a.nen.travel*math.pi*5)*4
        -- Original expedition steed silhouette: long chest, angular mane, trailing legs.
        fill(g,a,alpha*.85,-24,19,-26,-8,-12,-23,2,-19,19,6,10,25,-13,30)
        fill(g,a,alpha,8,1,5,-30,14,-50,28,-48,31,-28,21,-14)
        stroke(g,a,alpha,4,-17,20,-23+gait,42,-8-gait,34)
        stroke(g,a,alpha,3,8,22,16-gait,38,25+gait,25)
    end
    guardian(g,a,-4,-14,.8,alpha,1,true)
    fill(g,a,alpha*.66,-11,-36,-43,-12,-28,2,-8,-3)
    lance(g,a,29,-28,74,alpha)
    g.pop()
end
local function crystal(g,a,x,y,size,angle,alpha)
    g.push();g.translate(x,y);g.rotate(angle)
    fill(g,a,alpha,0,-size,-size*.22,-size*.1,-size*.11,size*.38,0,size*.62,size*.19,size*.16,size*.22,-size*.1)
    stroke(g,a,alpha*.9,1,0,-size,0,size*.55)
    stroke(g,a,alpha*.65,1,-size*.2,-size*.08,0,size*.2,size*.2,-size*.08)
    g.pop()
end
local function bolt(g,a,x,y,tx,ty,alpha,width,seed,p,branching)
    local n=a.nen;local q=C.quality[a.quality] or C.quality.high
    local count=q.segments;local points=n.points
    local dx,dy=tx-x,ty-y;local length=math.max(1,math.sqrt(dx*dx+dy*dy));local nx,ny=-dy/length,dx/length
    for j=0,count do
        local k=j/count;local envelope=math.sin(k*math.pi)
        local flicker=n.reducedMotion and 0 or math.floor(p*24)*.47
        local zig=(math.sin(j*7.13+seed*2.71+flicker)+math.sin(j*2.83+seed)*.5)*envelope*(8+n.tier*5)
        points[j*2+1]=mix(x,tx,k)+nx*zig;points[j*2+2]=mix(y,ty,k)+ny*zig
    end
    for j=#points,(count+1)*2+1,-1 do points[j]=nil end
    stroke(g,a,alpha,width,points)
    g.setBlendMode("add");g.setColor(.8,.92,1,alpha*.7);g.setLineWidth(width*.35);g.line(points);g.setBlendMode("alpha")
    if branching then
        for b=1,q.branches+n.tier-1 do
            local j=math.floor(count*(.18+b/(q.branches+n.tier+1)*.58));local bx,by=points[j*2+1],points[j*2+2]
            local side=b%2==0 and -1 or 1
            stroke(g,a,alpha*.55,width*.5,bx,by,bx+nx*side*(12+b*3)+dx*.12,by+ny*side*(12+b*3)+dy*.12,
                bx+nx*side*(25+b*4)+dx*.23,by+ny*side*(25+b*4)+dy*.23)
        end
    end
end
local function ribbon(g,a,i,p,width)
    local q=C.quality[a.quality] or C.quality.high
    local x,y=N.position(a,i,"TRAVEL",math.max(0,p-.28))
    for j=1,q.segments do
        local t=math.max(0,p-.28+.28*j/q.segments);local tx,ty=N.position(a,i,"TRAVEL",t)
        stroke(g,a,.10+.52*j/q.segments,width*j/q.segments,x,y,tx,ty);x,y=tx,ty
    end
end
local function ring(g,a,x,y,rx,ry,alpha,width)
    g.setShader();g.setBlendMode("alpha");color(g,a,alpha);g.setLineWidth(width or 1.5);g.ellipse("line",x,y,math.max(.1,rx),math.max(.1,ry))
end
local function bind(a)
    local n=a.nen;local g=love.graphics;n.materialShader=a.quality~="low" and E.shader or nil
    if not n.materialShader then return end
    local material
    for _,kind in ipairs(C.types) do if kind.id==n.profile.nenType then material=kind.material;break end end
    if a.profile.id=="flush" or a.profile.id=="crimson_tide" then material=7 end
    if a.profile.id=="obsidian_tide" then material=8 end
    local x,y=g.transformPoint(a.cx,300);local sx,sy=g.transformPoint(a.cx+1,300)
    n.screenCenter[1],n.screenCenter[2]=x,y
    n.materialShader:send("screenCenter",n.screenCenter);n.materialShader:send("pixelScale",math.max(.1,math.abs(sx-x)+math.abs(sy-y)))
    n.materialShader:send("clock",n.charge+n.travel*2+n.phaseProgress*.2)
    n.materialShader:send("material",material or 1);n.materialShader:send("charge",.4+n.charge*.6)
end
local drawings={}
drawings.high_card=function(g,a,phase,p,alpha)
    local n=a.nen;local tier=n.tier;local x,y=N.position(a,1,phase,p)
    local scale=.65+tier*.25;soft(g,a,x,y-22,48*scale,alpha*.13)
    if tier==1 then
        fill(g,a,alpha,x-14,y-40,x+14,y-40,x+14,y+8,x-14,y+8)
        lance(g,a,x,y-8,42,alpha)
    else rider(g,a,x,y,scale,alpha,tier==3) end
    if phase=="TRAVEL" then
        ribbon(g,a,1,p,tier==3 and 5 or 3)
        if tier==3 then stroke(g,a,alpha*.65,1.2,x-17,y+32,x+9,y+45,x-7,y+63,x+14,y+82) end
    else
        ring(g,a,x,y+24,34*scale*(1-n.charge*.3),9*scale,alpha*.65,2)
        stroke(g,a,alpha*n.charge,2,x-29,y+26,x-17,y+22,x+17,y+22,x+29,y+26)
    end
end
drawings.pair=function(g,a,phase,p,alpha)
    local n=a.nen;local tier=n.tier
    for i=1,2 do
        local x,y=N.position(a,i,phase,p);local side=i==1 and -1 or 1
        guardian(g,a,x,y,.6+tier*.28,alpha,side,tier>=2)
        if phase=="TRAVEL" then ribbon(g,a,i,p,2+tier) end
        if tier>=2 and i==1 then
            local lock=phase=="TRAVEL" and smooth(p/.35) or n.charge*.35
            stroke(g,a,alpha*lock,3,x-side*35,y-15,x-side*35,y-58,x-side*8,y-70)
        end
    end
    if tier==3 then
        local lx,ly=N.position(a,1,phase,p);local rx,ry=N.position(a,2,phase,p)
        stroke(g,a,alpha*.55,1.5,lx,ly+15,a.cx,380,rx,ry+15)
        ring(g,a,a.cx,380,34,10,alpha*.8,2)
    end
end
drawings.even_frost=function(g,a,phase,p,alpha)
    local n=a.nen;local tier=n.tier
    if tier==1 then
        for i=1,5 do local x,y=N.position(a,i,phase,p);crystal(g,a,x,y,24,(i-3)*.09,alpha)
            if phase=="TRAVEL" then ribbon(g,a,i,p,2.2) end end
    else
        local x,y=N.position(a,1,phase,p);local tiers=tier==2 and 3 or 5
        if phase=="TRAVEL" then ribbon(g,a,1,p,7) end
        for j=tiers,1,-1 do
            local spin=n.charge*2+n.travel*8+j*1.8
            local radius=12+j*8
            for face=1,3 do local t=spin+face*math.pi*2/3
                crystal(g,a,x+math.cos(t)*radius,y+9*j+math.sin(t)*radius*.24,24+j*2,math.cos(t)*.22,alpha*.9) end
            ring(g,a,x,y+j*9,radius,radius*.3,alpha*.8,1.2)
        end
        lance(g,a,x,y,35+tier*10,alpha)
        if tier==3 then
            local reveal=smooth((n.charge-.3)/.5)*(phase=="TRAVEL" and (1-p)^1.5 or 1)
            for i=1,6 do local t=i*math.pi/3
                local bx,by=a.cx+math.cos(t)*128,290+math.sin(t)*48
                crystal(g,a,bx,by,30+18*(i%2),t*.08,alpha*reveal*.7) end
            ring(g,a,a.cx,295,138,50,alpha*reveal*.65,2)
        end
    end
end
drawings.tesla_369=function(g,a,phase,p,alpha)
    local n=a.nen;local tier=n.tier
    local charge=phase~="TRAVEL";local cx,cy=a.cx,270
    for i,role in ipairs(n.roles) do
        local c=n.snapshot.cards[role]
        local x,y=N.position(a,i,"CHARGE",1)
        if tier==3 then x=cx+math.cos(i*math.pi*2/3-.5)*115;y=cy+math.sin(i*math.pi*2/3-.5)*62 end
        local reveal=alpha*smooth((n.charge-.18)/.42)
        soft(g,a,x,y,30,reveal*.12)
        ring(g,a,x,y,12+tier*3,8+tier*2,reveal,1.5)
        if tier==3 then
            fill(g,a,reveal*.8,x-9,y+9,x-9,y-60,x,y-76,x+9,y-60,x+9,y+9)
            for band=1,4 do ring(g,a,x,y-48+band*12,13,4,reveal*.9,1.5) end
            bolt(g,a,c.x,c.y,x,y,reveal*.5,1,i,n.charge,false)
        end
        if tier>=2 then
            local j=i%3+1;local tx,ty=N.position(a,j,"CHARGE",1)
            bolt(g,a,x,y,tx,ty,reveal*(charge and .48 or .18),1.3,i,n.charge,false)
        end
        if not charge then
            local delay=(i-1)*(tier==1 and .23 or .17);local age=clamp((p-delay)/.28)
            local flash=p>=delay and 1-smooth((p-.94)/.06) or 0
            if flash>0 then local tx,ty=N.position(a,i,"TRAVEL",p)
                bolt(g,a,x,y,tx,ty,alpha*flash,1.8+tier*.7,i,p,tier>=2) end
        end
    end
    if tier==3 then
        ring(g,a,cx,330,58,17,alpha*.75,2)
        if phase=="TRAVEL" and p>.66 then
            local advance=smooth((p-.66)/.34)
            bolt(g,a,cx,177,cx,mix(177,cy,advance),alpha*advance,5,13,p,true)
        end
    end
end
drawings.straight=function(g,a,phase,p,alpha)
    local n=a.nen;local tier=n.tier;local previous
    for i=1,N.count(a) do
        local x,y=N.position(a,i,phase,p)
        if previous then stroke(g,a,alpha*.45,1.5,previous.x,previous.y,x,y) end
        previous=n.snapshot.cards[a.rankOrder[i]]
        if phase=="TRAVEL" then ribbon(g,a,i,p,1.7+tier*.7) end
        if tier==1 then lance(g,a,x,y,19,alpha)
        elseif tier==2 then guardian(g,a,x,y,.58,alpha,i%2==0 and -1 or 1,true)
        else rider(g,a,x,y,.67,alpha,true) end
    end
    if tier>=2 then
        local reveal=alpha*(phase=="TRAVEL" and (1-p) or smooth(n.charge))
        stroke(g,a,reveal*.55,2,a.cx-88,444,a.cx-39,358,a.cx-24,280)
        stroke(g,a,reveal*.55,2,a.cx+88,444,a.cx+39,358,a.cx+24,280)
        for i=1,5 do local y=440-i*29;stroke(g,a,reveal*.6,1,a.cx-13,y+5,a.cx,y,a.cx+13,y+5) end
    end
end
drawings.eclipse_duality=function(g,a,phase,p,alpha)
    local n=a.nen;local tier=n.tier;local cx,cy=a.cx,330
    local join
    if tier==1 then join=phase=="TRAVEL" and smooth(p/.62) or smooth((n.charge-.2)/.8)*.20
    else join=phase=="TRAVEL" and 1 or smooth((n.charge-.4)/.6) end
    local separation=50*(1-join)
    local compression=tier==3 and phase=="TRAVEL" and 1-.55*smooth(p/.7) or 1
    local r=(25+tier*12)*compression
    soft(g,a,cx,cy,r*2,alpha*.14)
    g.setShader(n.materialShader);g.setBlendMode("alpha");g.setColor(.65,.17,.22,alpha*.92);g.circle("fill",cx-separation,cy,r)
    local lunarY=cy-r*.08+(tier>=2 and math.sin((1-join)*math.pi)*r*.36 or 0)
    g.setShader();g.setColor(.02,.035,.065,alpha*.98);g.circle("fill",cx+separation,lunarY,r*.94)
    ring(g,a,cx+separation,lunarY,r*.98,r*.98,alpha,2)
    if tier>=2 then
        ring(g,a,cx,cy,r*1.6,r*.4,alpha*.65,1.4)
        g.push();g.translate(cx,cy);g.rotate(n.charge*.45+n.travel*.4)
        ring(g,a,0,0,r*1.9,r*.55,alpha*.5,1);g.pop()
    end
    if tier==3 then
        ring(g,a,cx,cy,r*1.12,r*1.12,alpha*.78,3)
        for j=1,4 do local t=j*math.pi/2+n.charge*.22
            stroke(g,a,alpha*.55,1,cx+math.cos(t)*r*1.2,cy+math.sin(t)*r*1.2,cx+math.cos(t)*r*1.7,cy+math.sin(t)*r*1.7) end
    end
    if phase=="TRAVEL" and p>.48 then
        local beam=out((p-.48)/.52);local width=(tier==1 and 4 or tier==2 and 8 or 13)*(1-.5*smooth((p-.83)/.17))
        stroke(g,a,alpha*beam,width,cx,cy-r*.2,cx,cy+(270-cy)*beam)
        ring(g,a,cx,cy,r*(1-beam*.7),r*(1-beam*.7),alpha,2.5)
    end
end
local function banner(g,a,x,y,size,alpha,clock)
    stroke(g,a,alpha,2,x,y+size*.3,x,y-size)
    for j=0,5 do
        local v=j/6;local wave=math.sin(clock*5+v*4)*size*.08
        local yy=y-size+v*size*.72
        fill(g,a,alpha*(1-v*.3),x,yy,x+size*(.85-v*.15),yy+wave,
            x+size*(.85-(v+1/6)*.15),yy+size*.12+wave,x,yy+size*.12)
    end
end
local function pillar(g,a,x,y,size,alpha)
    fill(g,a,alpha,x-size*.25,y-size,x+size*.25,y-size,x+size*.3,y,x-size*.3,y)
    fill(g,a,alpha*.65,x+size*.25,y-size,x+size*.43,y-size*.85,x+size*.43,y+size*.1,x+size*.3,y)
    stroke(g,a,alpha,2,x-size*.38,y-size,x+size*.38,y-size)
    stroke(g,a,alpha,2,x-size*.4,y+size*.1,x+size*.45,y+size*.1)
end
drawings.two_pair=function(g,a,phase,p,alpha)
    local tier=a.nen.tier
    for i=1,4 do
        local x,y=N.position(a,i,phase,p)
        if tier==1 then lance(g,a,x,y,27,alpha)
        else guardian(g,a,x,y,tier==3 and .86 or .63,alpha,i<=2 and -1 or 1,true)
            if tier==3 then banner(g,a,x-22,y-12,39,alpha*.8,a.nen.charge+p) end end
        if phase=="TRAVEL" then ribbon(g,a,i,p,2+tier)
        elseif tier>=2 then ring(g,a,x,y+15,25,8,alpha*.6,1.3) end
    end
end
drawings.three_of_a_kind=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local merge=tier==3 and phase=="TRAVEL" and smooth((p-.42)/.25) or 0
    for i=1,3 do
        local x,y=N.position(a,i,phase,p)
        lance(g,a,x,y,31+tier*8,alpha*(1-merge))
        if phase=="TRAVEL" then ribbon(g,a,i,p,3) end
        if tier>=2 then local tx,ty=N.position(a,i%3+1,phase,p);stroke(g,a,alpha*.6*(1-merge),1.5,x,y,tx,ty) end
    end
    if merge>0 then local x,y=N.position(a,1,phase,p);lance(g,a,a.cx,y,91,alpha*merge);soft(g,a,a.cx,y,45,alpha*merge*.1) end
end
drawings.flush=function(g,a,phase,p,alpha)
    local tier=a.nen.tier
    if tier==1 then
        for i=1,N.count(a) do local x,y=N.position(a,i,phase,p)
            stroke(g,a,alpha,5,x-8,y+30,x+math.sin(p*5+i)*14,y+10,x,y-27)
            if phase=="TRAVEL" then ribbon(g,a,i,p,4) end end
    else
        local x,y=N.position(a,1,phase,p);local size=tier==3 and 112 or 76
        banner(g,a,x,y,size,alpha,a.nen.charge+p)
        if phase=="TRAVEL" then
            ribbon(g,a,1,p,8)
            if tier==3 then for j=1,3 do g.push();g.translate(x,y-25);g.rotate(p*2+j*.8)
                ring(g,a,0,0,42+j*18,11+j*5,alpha*.65,3);g.pop() end end
        end
    end
end
drawings.full_house=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local opacity=alpha*(phase=="TRAVEL" and 1-smooth(p/.75) or 1)
    local width=tier==1 and 51 or tier==2 and 89 or 136
    local cx=a.cx-130
    fill(g,a,opacity,cx-width,405,cx-width,365,cx+width,365,cx+width,405)
    local towers=tier==3 and 5 or tier==2 and 2 or 1
    for j=1,towers do local x=cx+(j-(towers+1)/2)*(tier==3 and 52 or 108)
        pillar(g,a,x,389,42+tier*12,opacity)
        for k=-1,1 do fill(g,a,opacity,x+k*11-4,313-tier*3,x+k*11+4,313-tier*3,x+k*11+4,327-tier*3,x+k*11-4,327-tier*3) end
    end
    ring(g,a,cx,401,width+12,15,opacity*.65,2)
    if phase=="TRAVEL" then for i=1,N.count(a) do local x,y=N.position(a,i,phase,p)
        crystal(g,a,x,y,17+tier*5,0,alpha);ribbon(g,a,i,p,3+tier) end end
end
drawings.four_of_a_kind=function(g,a,phase,p,alpha)
    local tier=a.nen.tier
    for i=1,4 do local x,y=N.position(a,i,phase,p)
        pillar(g,a,x,y,37+tier*12,alpha)
        if phase=="TRAVEL" then ribbon(g,a,i,p,3+tier)
        elseif tier>=2 then stroke(g,a,alpha*.5,1.5,x,y,a.cx,315) end
    end
    if tier==3 then ring(g,a,a.cx,315,99*(1-a.nen.travel*.65),62*(1-a.nen.travel*.65),alpha*.65,3) end
end
drawings.straight_flush=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local merge=tier==2 and phase=="TRAVEL" and smooth((p-.35)/.4) or 0
    if tier==2 then for i=1,5 do local x,y=N.position(a,i,phase,p)
        lance(g,a,x,y,32,alpha*(1-merge));if phase=="TRAVEL" then ribbon(g,a,i,p,3) end end end
    if tier~=2 or merge>0 then local x,y=N.position(a,1,phase,p)
        if tier==2 then x=a.cx end
        local size=tier==3 and 136 or tier==2 and 88 or 55;local opacity=alpha*(tier==2 and merge or 1)
        lance(g,a,x,y,size,opacity)
        fill(g,a,opacity,x-28,y+10,x-20,y-13,x-8,y+1,x,y-23,x+8,y+1,x+20,y-13,x+28,y+10)
        if phase=="TRAVEL" then ribbon(g,a,1,p,tier==3 and 9 or 4)
        elseif tier==3 then ring(g,a,x,y-35,55*(1-a.nen.charge*.45),18,opacity,2) end
    end
end
local function star(g,a,x,y,r,alpha,rotation)
    g.push();g.translate(x,y);g.rotate(rotation or 0)
    fill(g,a,alpha,0,-r,r*.22,-r*.22,r,0,r*.22,r*.22,0,r,-r*.22,r*.22,-r,0,-r*.22,-r*.22)
    g.pop()
end
local function sword(g,a,x,y,r,alpha,angle)
    g.push();g.translate(x,y);g.rotate(angle or 0)
    fill(g,a,alpha,0,-r,-r*.1,-r*.68,-r*.075,r*.12,r*.075,r*.12,r*.1,-r*.68)
    stroke(g,a,alpha,2,-r*.25,0,r*.25,0);stroke(g,a,alpha,3,0,0,0,r*.35)
    ring(g,a,0,r*.35,r*.08,r*.08,alpha,1.5);g.pop()
end
local function seal(g,a,x,y,r,alpha,rotation)
    g.push();g.translate(x,y);g.rotate(rotation or 0)
    ring(g,a,0,0,r,r,alpha,2)
    fill(g,a,alpha*.5,0,-r*.7,r*.6,0,0,r*.7,-r*.6,0)
    stroke(g,a,alpha,1.5,-r*.32,-r*.3,r*.32,-r*.3,0,r*.38,-r*.32,-r*.3)
    g.pop()
end
local function slab(g,a,x,y,r,angle,alpha)
    g.push();g.translate(x,y);g.rotate(angle)
    fill(g,a,alpha,-r*.35,-r*.4,r*.04,-r*.67,r*.36,-r*.23,r*.28,r*.43,-r*.13,r*.61,-r*.44,r*.07)
    stroke(g,a,alpha*.8,1.5,-r*.21,-r*.31,r*.08,-r*.04,-r*.12,r*.25,r*.07,r*.49)
    g.pop()
end
local function swordAngle(a,x,y,p)
    if a.nen.reducedMotion then return -.25 end
    return (math.atan2(270-y,a.cx-x)+math.pi/2)*smooth(p/.22)
end
local function gate(g,a,x,y,r,alpha,opening)
    pillar(g,a,x-r*.65,y+r*.55,r*1.1,alpha);pillar(g,a,x+r*.65,y+r*.55,r*1.1,alpha)
    stroke(g,a,alpha,5,x-r*.85,y-r*.55,x-r*.55,y-r*.82,x+r*.55,y-r*.82,x+r*.85,y-r*.55)
    for side=-1,1,2 do
        fill(g,a,alpha*.68,x+side*r*.54,y-r*.51,x+side*r*.54,y+r*.45,x+side*r*.54*(1-opening),y+r*.35,x+side*r*.54*(1-opening),y-r*.4)
    end
    g.setShader();g.setColor(.035,.045,.07,alpha*opening*.75);g.ellipse("fill",x,y,r*.42*opening,r*.54)
    ring(g,a,x,y,r*.46*opening+.1,r*.58,alpha*opening,2)
end
drawings.jackpot_777=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local q=a.nen.charge;local cx,cy=a.cx-125,350
    local merge=tier>=2 and smooth((q-.5)/.5) or 0
    for i=1,3 do local x,y=N.position(a,i,phase,p)
        if phase~="TRAVEL" then x=mix(x,cx,merge*.8);y=mix(y,cy,merge*.8) end
        seal(g,a,x,y,19+(tier==3 and 9 or 0),alpha,tier==3 and p*5+i*2 or i*.3)
        if phase=="TRAVEL" then ribbon(g,a,i,p,3.5) end
    end
    if tier>=2 then
        local fade=alpha*(phase=="TRAVEL" and (1-p)^2 or 1)
        fill(g,a,fade*.8,cx-45,cy+32,cx-45,cy-26,cx+45,cy-26,cx+45,cy+32)
        ring(g,a,cx,cy+4,13,13,fade,3)
        stroke(g,a,fade,3,cx,cy+4,cx,cy+20)
        stroke(g,a,fade,2,cx-37,cy-26,cx-24,cy-45,cx+24,cy-45,cx+37,cy-26)
        if tier==3 then
            for j=1,3 do g.push();g.translate(cx,cy);g.rotate(q*2+j*.6)
                ring(g,a,0,0,57+j*12,20+j*7,fade*.6,2);g.pop() end
            for i=1,6 do local t=i*math.pi/3+q*3;seal(g,a,cx+math.cos(t)*81,cy+math.sin(t)*48,9,fade*.75,t) end
        end
    end
end
drawings.fibonacci=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local q=a.nen.charge;local fade=phase=="TRAVEL" and 1-p or 1
    local cx,cy=a.cx-120,350;local count=(C.quality[a.quality] or C.quality.high).segments
    local lastX,lastY=cx,cy
    for j=1,count*2 do local t=j/(count*2)*math.pi*(tier==3 and 5 or 3)
        local r=6*math.exp(t*.20)*q*(tier==3 and 1.2 or 1)
        local x,y=cx+math.cos(t-q)*r,cy+math.sin(t-q)*r*.7
        stroke(g,a,alpha*fade*.8,2,lastX,lastY,x,y);lastX,lastY=x,y end
    for i=1,5 do local x,y=N.position(a,i,phase,p)
        if tier==1 then star(g,a,x,y,10+i*1.5,alpha,q)
        elseif tier==2 then seal(g,a,x,y,9+i*2,alpha,q+i*.4)
        else crystal(g,a,x,y,12+i*3,q+i*.2,alpha) end
        if phase=="TRAVEL" then ribbon(g,a,i,p,2+i*.3) end
    end
    if tier==3 then ring(g,a,cx,cy,75*(1-q*.32),50*(1-q*.32),alpha*fade*.6,2) end
end
drawings.prime=function(g,a,phase,p,alpha)
    local tier=a.nen.tier
    for i=1,5 do local x,y=N.position(a,i,phase,p)
        star(g,a,x,y,12+tier*3,alpha,i*.47+a.nen.charge*(tier==2 and 2 or .2))
        if tier>=2 then ring(g,a,x,y,20,11,alpha*.7,1.5) end
        if phase=="TRAVEL" then ribbon(g,a,i,p,2.8) end
        if tier==3 and phase~="TRAVEL" then
            stroke(g,a,alpha*.45,1,x,y,a.cx,270)
            stroke(g,a,alpha,2,x-23,y-13,x-23,y-23,x-13,y-23,x+13,y+23,x+23,y+23,x+23,y+13)
        end
    end
end
drawings.odd_star=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local cx,cy=a.cx-125,350;local fade=phase=="TRAVEL" and 1-p or 1
    local r=tier==1 and 18 or tier==2 and 33 or 52
    soft(g,a,cx,cy,r*1.8,alpha*fade*.15);star(g,a,cx,cy,r,alpha*fade,a.nen.charge*.18)
    if tier>=2 then ring(g,a,cx,cy,r*1.15,r*1.15,alpha*fade,2.5) end
    for i=1,9 do local x,y=N.position(a,i,phase,p)
        if phase=="TRAVEL" then lance(g,a,x,y,tier==3 and 37 or 19,alpha);ribbon(g,a,i,p,2.3)
        else local t=(i-1)*math.pi*2/9
            stroke(g,a,alpha,2,cx+math.cos(t)*r*.7,cy+math.sin(t)*r*.7,x+math.cos(t)*20,y+math.sin(t)*20)
            if tier==3 then star(g,a,x,y,9,alpha,t) end end
    end
end
drawings.crimson_tide=function(g,a,phase,p,alpha)
    local tier=a.nen.tier
    for i=1,N.count(a) do local x,y=N.position(a,i,phase,p);local side=i%2==0 and 1 or -1
        local r=32+tier*12;g.push();g.translate(x,y);g.rotate(side*(.25+p*.9))
        for band=1,3 do local yy=band*9
            fill(g,a,alpha*(.95-band*.17),-r,yy,r,yy-14,r*.8,yy-34,r*.3,yy-48,-r*.25,yy-26,-r*.75,yy-18)
        end
        g.pop();if phase=="TRAVEL" then ribbon(g,a,i,p,6+tier) end
    end
    if tier==3 then local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
        ring(g,a,a.cx,315,105,40,fade*.8,3)
        g.setShader();g.setColor(.025,.02,.04,fade*.6);g.circle("fill",a.cx,315,28)
        ring(g,a,a.cx,315,29,29,fade,2) end
end
drawings.obsidian_tide=function(g,a,phase,p,alpha)
    local tier=a.nen.tier
    for i=1,N.count(a) do local x,y=N.position(a,i,phase,p)
        if tier==1 then slab(g,a,x,y,35,(i-3)*.24,alpha)
        elseif tier==2 then
            fill(g,a,alpha,x-57,y+8,x-44,y-20,x-27,y-9,x-10,y-41,x+8,y-19,x+26,y-49,x+40,y-18,x+57,y-9,x+45,y+18)
            stroke(g,a,alpha*.85,2,x-37,y+4,x-12,y-21,x+14,y-7,x+34,y-25)
        else
            crystal(g,a,x,y,98,-.18,alpha)
            for j=1,3 do crystal(g,a,x-(j-2)*23,y+12*j,43,j*.16,alpha*.7) end
            stroke(g,a,alpha,2,x-19,y-52,x+8,y-31,x-7,y,x+14,y+43)
        end
        if phase=="TRAVEL" then ribbon(g,a,i,p,3+tier*2) end
    end
end
drawings.four_kingdom_prism=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local cx,cy=a.cx-115,355
    local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
    fill(g,a,fade,cx,cy-47,cx-45,cy+26,cx+45,cy+26)
    stroke(g,a,fade,1.5,cx,cy-47,cx,cy+26,cx-45,cy+26)
    local original=a.color;local palette={{.95,.34,.31},{.25,.74,1},{.40,.85,.55},{.8,.5,1}}
    for i=1,4 do a.color=palette[i]
        local x,y=N.position(a,tier==2 and i or 1,phase,p)
        if tier==2 then crystal(g,a,x,y,29,(i-2.5)*.13,alpha)
        else local offset=(i-2.5)*6
            stroke(g,a,alpha,3,x+offset,y+20,x+offset*.6,y-30-(tier==3 and 30 or 0)) end
        if phase=="TRAVEL" then ribbon(g,a,tier==2 and i or 1,p,2.5) end
    end
    a.color=original
    if tier==3 then local x,y=N.position(a,1,phase,p);lance(g,a,x,y,70,alpha*.9);ring(g,a,cx,cy,66,23,fade*.6,2) end
end
drawings.four_kingdom_expedition=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
    for i=1,4 do local x,y=N.position(a,i,phase,p)
        if tier==1 then stroke(g,a,alpha,4,x-10,y+20,x,y,x+10,y-25)
        else
            banner(g,a,x,y,45,alpha,a.nen.charge+p+i)
            if tier==3 then guardian(g,a,x-17,y+12,.52,alpha,i%2==0 and 1 or -1,true) end
        end
        if phase=="TRAVEL" then ribbon(g,a,i,p,2+tier)
        elseif tier==3 then
            stroke(g,a,fade*.65,1.5,x,y+20,x+(a.cx-x)*.55,365,a.cx,270)
            for k=1,3 do ring(g,a,mix(x,a.cx,k/4),mix(y+20,270,k/4),5,3,fade,1) end
        end
    end
end
drawings.destiny_crown=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local cx,cy=a.cx+130,315
    local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
    fill(g,a,fade,cx-45,cy-32,cx-38,cy-61,cx-20,cy-43,cx,cy-74,cx+20,cy-43,cx+38,cy-61,cx+45,cy-32)
    stroke(g,a,fade,3,cx-41,cy-28,cx+41,cy-28)
    if tier==2 then
        for i=1,5 do local x,y=N.position(a,i,phase,p);sword(g,a,x,y,46,alpha,phase=="TRAVEL" and swordAngle(a,x,y,p) or (i-3)*.13)
            if phase=="TRAVEL" then ribbon(g,a,i,p,3) end end
    else local x,y=N.position(a,1,phase,p)
        sword(g,a,x,y,tier==3 and 123 or 56,alpha,phase=="TRAVEL" and swordAngle(a,x,y,p) or 0)
        if phase=="TRAVEL" then ribbon(g,a,1,p,tier==3 and 9 or 3) end
        if tier==3 then
            ring(g,a,cx,365,84,24,fade*.7,3)
            for j=1,5 do local t=j*math.pi*2/5-.4;seal(g,a,cx+math.cos(t)*83,330+math.sin(t)*49,10,fade*.75,t) end
        end
    end
end
drawings.continental_gate=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local cx,cy=a.cx-175,315;local q=a.nen.charge
    local fade=alpha*(phase=="TRAVEL" and (1-smooth((p-.6)/.4)) or 1)
    local r=tier==1 and 40 or tier==2 and 68 or 104
    if tier==1 then
        for i=1,4 do local t=(i-1)*math.pi/2;seal(g,a,cx+math.cos(t)*r,cy+math.sin(t)*r,13,fade,t) end
        stroke(g,a,fade,3,cx,cy-15,cx,cy+23,cx+10,cy+23);ring(g,a,cx,cy-15,10,10,fade,2)
    else
        gate(g,a,cx,cy,r,fade,smooth((q-.45)/.55))
        for i=1,4 do local t=(i-1)*math.pi/2;seal(g,a,cx+math.cos(t)*r*.87,cy+math.sin(t)*r*.65,10,fade,t) end
        if tier==3 then
            g.setShader();g.setColor(.15,.27,.34,fade*.5)
            for j=1,4 do local bx=cx-r*.3+j*r*.12;g.polygon("fill",bx,cy+25,bx+r*.1,cy-10-j*8,bx+r*.2,cy+25) end
            ring(g,a,cx,cy+r*.62,r*1.05,r*.22,fade*.7,2)
        end
    end
    if phase=="TRAVEL" then
        local x,y=N.position(a,1,phase,p)
        stroke(g,a,alpha,4+tier*3,cx,cy,x,y)
        crystal(g,a,x,y,19+tier*7,-math.pi/2,alpha)
        if tier==3 then for side=-1,1,2 do stroke(g,a,alpha*.65,2,cx,cy+side*14,x,y+side*10) end end
    end
end
drawings.answer_42=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local lastX,lastY
    for i=1,5 do local x,y=N.position(a,i,phase,p)
        if lastX then stroke(g,a,alpha*.65,1.5,lastX,lastY,x,y) end
        lastX,lastY=x,y
        ring(g,a,x,y,11+tier*2,6+tier*2,alpha,1.5)
        stroke(g,a,alpha,1.5,x-20,y,x+20,y);stroke(g,a,alpha,1.5,x,y-18,x,y+18)
        if phase=="TRAVEL" then ribbon(g,a,i,p,2.5)
        elseif tier>=2 then
            local tx,ty=N.position(a,i%5+1,phase,p)
            stroke(g,a,alpha*.3,1,x,y,tx,ty)
            if tier==3 then star(g,a,x,y,9,alpha,a.nen.charge+i) end
        end
    end
    if tier==3 then
        local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
        g.push();g.translate(a.cx,310);g.rotate(a.nen.charge*.12)
        ring(g,a,0,0,178,89,fade*.5,1.5)
        for j=1,4 do local t=j*math.pi/2;stroke(g,a,fade,2,math.cos(t)*166,math.sin(t)*80,math.cos(t)*187,math.sin(t)*95) end
        g.pop()
    end
end
drawings.sealed_gate=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local cx,cy=a.cx-160,310;local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
    gate(g,a,cx,cy,tier==3 and 82 or 45,fade,smooth((a.nen.charge-.5)/.5))
    if tier>=2 then
        for j=1,3 do local t=j*math.pi*2/3-math.pi/2;seal(g,a,cx+math.cos(t)*68,cy+math.sin(t)*48,13,fade,t) end
        stroke(g,a,fade*.7,2,cx-63,cy+46,cx,cy-64,cx+63,cy+46,cx-63,cy+46)
    end
    for i=1,N.count(a) do local x,y=N.position(a,i,phase,p)
        sword(g,a,x,y,tier==3 and 101 or 48,alpha,phase=="TRAVEL" and swordAngle(a,x,y,p) or -.35)
        if phase=="TRAVEL" then ribbon(g,a,i,p,tier==3 and 8 or 3.5) end
    end
    if tier==3 then
        for side=-1,1,2 do pillar(g,a,cx+side*100,375,108,fade*.8) end
        ring(g,a,cx,386,121,24,fade*.7,2)
    end
end
drawings.seven_stars=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local lx,ly
    for i=1,7 do local x,y=N.position(a,i,phase,p)
        if tier>=2 and lx then stroke(g,a,alpha*(phase=="TRAVEL" and .2 or .65),1.5,lx,ly,x,y) end
        star(g,a,x,y,tier==3 and 20 or 12,alpha,i*.2+a.nen.charge*.15)
        if tier==3 then ring(g,a,x,y,25,10,alpha*.55,1.5) end
        if phase=="TRAVEL" then ribbon(g,a,i,p,tier==3 and 4.5 or 2.5) end
        lx,ly=x,y
    end
end
drawings.five_ley_lines=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local fade=alpha*(phase=="TRAVEL" and 1-p or 1)
    for i=1,5 do local x,y=N.position(a,i,phase,p)
        local sourceX=a.cx+(i-3)*52
        stroke(g,a,fade*.8,2,sourceX,451,sourceX+(i-3)*10,417,sourceX-12,398,a.cx,370)
        if phase=="TRAVEL" then
            crystal(g,a,x,y,28+tier*13,(i-3)*.10,alpha);ribbon(g,a,i,p,3+tier)
        else
            ring(g,a,sourceX,415,17+tier*4,5+tier*2,fade,2)
            if tier>=2 then pillar(g,a,sourceX,419,27+i*4,fade*.8) end
        end
    end
    if tier==3 then
        local erupt=phase=="TRAVEL" and smooth(p/.6) or smooth((a.nen.charge-.7)/.3)*.2
        crystal(g,a,a.cx,370-erupt*85,18+erupt*88,0,alpha*erupt)
        ring(g,a,a.cx,397,92*(1-erupt*.35),24,alpha*.65,3)
    end
end
drawings.endless_cycle=function(g,a,phase,p,alpha)
    local tier=a.nen.tier;local x,y=N.position(a,1,phase,p);local q=a.nen.charge
    local compression=tier==3 and phase=="TRAVEL" and 1-.7*smooth(p/.75) or 1
    local r=(tier==1 and 37 or tier==2 and 50 or 78)*compression
    for j=1,tier do local angle=(q*.8+p*p*7)*(j%2==0 and -1 or 1)+j*.8
        g.push();g.translate(x,y);g.rotate(angle)
        ring(g,a,0,0,r,r*(tier==1 and .55 or .40),alpha,2.5)
        star(g,a,r,0,9,alpha,angle)
        if tier==3 then stroke(g,a,alpha*.65,1,-r*.7,-10,-r*.25,8,r*.25,-7,r*.7,10) end
        g.pop()
    end
    if tier>=2 then
        g.setShader();g.setColor(.025,.025,.065,alpha*.7);g.circle("fill",x,y,r*.36)
        ring(g,a,x,y,r*.45,r*.45,alpha,1.7)
    end
    if phase=="TRAVEL" then ribbon(g,a,1,p,3+tier)
        if tier==2 then local sx,sy=N.position(a,2,phase,p);ring(g,a,sx,sy,r,r*.45,alpha*.7,2) end end
end
local contacts={}
contacts.high_card=function(g,a,p,alpha)
    local tier=a.nen.tier;local stretch=out(p)
    lance(g,a,a.cx,264-p*25,34+tier*15,alpha*(1-p))
    stroke(g,a,alpha,2,a.cx-13,300,a.cx+10,270,a.cx-5,233,a.cx+12,208-stretch*25)
    ring(g,a,a.cx,287,18+stretch*(30+tier*15),6+stretch*13,alpha*.6,2)
end
contacts.pair=function(g,a,p,alpha)
    local r=25+out(p)*(35+a.nen.tier*15)
    stroke(g,a,alpha,3,a.cx-r,270+r*.62,a.cx+r,270-r*.62)
    stroke(g,a,alpha,3,a.cx+r,270+r*.62,a.cx-r,270-r*.62)
    if a.nen.tier==3 then
        for side=-1,1,2 do guardian(g,a,a.cx+side*(70+p*35),290,.95,alpha*.48,side,true) end
        ring(g,a,a.cx,270,r*.6,r*.36,alpha*.6,2)
    end
end
contacts.even_frost=function(g,a,p,alpha)
    local tier=a.nen.tier;local count=math.min((C.quality[a.quality] or C.quality.high).particles,6+tier*4)
    a.nen.particleCount=count
    for i=1,count do local t=i*2.399;local r=(18+out(p)*(50+tier*16))*(.6+(i%3)*.16)
        crystal(g,a,a.cx+math.cos(t)*r,270+math.sin(t)*r*.62,7+(i%3)*3,t+p*.8,alpha*.8) end
    if tier>=2 then for i=1,5 do local t=i*math.pi*2/5
        stroke(g,a,alpha*.75,1.3,a.cx,270,a.cx+math.cos(t)*40,270+math.sin(t)*25,a.cx+math.cos(t+.12)*(70+out(p)*25),270+math.sin(t+.12)*53) end end
end
contacts.tesla_369=function(g,a,p,alpha)
    local tier=a.nen.tier
    for i=1,3+tier do local t=i*2.399;local r=24+out(p)*(30+tier*18)
        bolt(g,a,a.cx,270,a.cx+math.cos(t)*r,270+math.sin(t)*r*.68,alpha,1.8,i+4,p,tier>=2) end
    if tier==3 then ring(g,a,a.cx,280,20+out(p)*95,8+out(p)*32,alpha*.8,2) end
end
contacts.straight=function(g,a,p,alpha)
    for i=1,#a.nen.snapshot.cards do local age=clamp((p-(i-1)*.07)/.72)
        local x=a.cx+(i-(#a.sources+1)/2)*13
        stroke(g,a,alpha*(1-age),2,x-10,300+age*25,x,270-age*13,x+8,230-age*40) end
    if a.nen.tier==3 then stroke(g,a,alpha*.8,3,a.cx-22,341,a.cx-12,262,a.cx,200,a.cx+12,262,a.cx+22,341) end
end
contacts.eclipse_duality=function(g,a,p,alpha)
    local r=14+out(p)*(44+a.nen.tier*18)
    g.setShader();g.setColor(.025,.03,.065,alpha*.65);g.circle("fill",a.cx,270,r*.55)
    ring(g,a,a.cx,270,r,r*.65,alpha,2.4)
    if a.nen.tier>=2 then
        g.push();g.translate(a.cx,270);g.rotate(p*.7)
        ring(g,a,0,0,r*1.3,r*.32,alpha*.6,1.5);g.pop()
    end
    if a.nen.tier==3 then stroke(g,a,alpha*.8,2,a.cx-r*.5,270,a.cx-r*.12,264,a.cx+r*.15,279,a.cx+r*.65,270) end
end
contacts.two_pair=function(g,a,p,alpha)
    local r=25+out(p)*(40+a.nen.tier*18)
    for side=-1,1,2 do stroke(g,a,alpha,3,a.cx+side*r,315,a.cx+side*r*.38,276,a.cx-side*r*.45,247)
        if a.nen.tier==3 then stroke(g,a,alpha*.65,2,a.cx+side*r,285,a.cx+side*r*.5,266,a.cx,270) end end
end
contacts.three_of_a_kind=function(g,a,p,alpha)
    local r=28+out(p)*(40+a.nen.tier*14)
    for i=1,3 do local t=i*math.pi*2/3-math.pi/2
        stroke(g,a,alpha,2.7,a.cx,270,a.cx+math.cos(t)*r,270+math.sin(t)*r) end
    if a.nen.tier==3 then lance(g,a,a.cx,267-p*40,73,alpha*.7) end
end
contacts.flush=function(g,a,p,alpha)
    local r=30+out(p)*(35+a.nen.tier*22)
    for j=1,a.nen.tier do g.push();g.translate(a.cx,275);g.rotate(p*(j%2==0 and -1 or 1))
        ring(g,a,0,0,r+j*8,r*.3,alpha/j,3);g.pop() end
    stroke(g,a,alpha*.65,4,a.cx-r,285,a.cx-r*.3,260,a.cx+r*.3,282,a.cx+r,252)
end
contacts.full_house=function(g,a,p,alpha)
    local count=a.nen.tier==3 and 5 or a.nen.tier
    for j=1,count do local age=clamp((p-(j-1)*.07)/.7);local x=a.cx+(j-(count+1)/2)*19
        ring(g,a,x,275,9+out(age)*23,4+out(age)*9,alpha*(1-age),2)
        pillar(g,a,x,288-out(age)*17,18,alpha*(1-age)*.7) end
end
contacts.four_of_a_kind=function(g,a,p,alpha)
    local r=17+out(p)*(30+a.nen.tier*17)
    stroke(g,a,alpha,3,a.cx-r,270-r*.65,a.cx+r,270-r*.65,a.cx+r,270+r*.65,a.cx-r,270+r*.65,a.cx-r,270-r*.65)
    for j=1,4 do local t=(j-1)*math.pi/2+.785
        stroke(g,a,alpha*.8,2,a.cx+math.cos(t)*15,270+math.sin(t)*10,a.cx+math.cos(t)*r*1.3,270+math.sin(t)*r*.9) end
end
contacts.straight_flush=function(g,a,p,alpha)
    local r=35+out(p)*(35+a.nen.tier*20)
    stroke(g,a,alpha,4,a.cx,325,a.cx,270-r)
    for side=-1,1,2 do stroke(g,a,alpha*.8,2,a.cx,270,a.cx+side*r*.3,254,a.cx+side*r,264) end
    if a.nen.tier==3 then ring(g,a,a.cx,270,r*.6,r*.18,alpha*.8,3) end
end
contacts.jackpot_777=function(g,a,p,alpha)
    local count=math.min((C.quality[a.quality] or C.quality.high).particles,3+a.nen.tier*3);a.nen.particleCount=count
    for i=1,count do local t=i*2.399;local r=15+out(p)*(30+a.nen.tier*15)
        seal(g,a,a.cx+math.cos(t)*r,270+math.sin(t)*r*.58,7+(i%3)*2,alpha,p*3+i) end
    if a.nen.tier==3 then ring(g,a,a.cx,280,26+out(p)*78,8+out(p)*25,alpha*.7,3) end
end
contacts.fibonacci=function(g,a,p,alpha)
    local lx,ly=a.cx,270
    for i=1,(C.quality[a.quality] or C.quality.high).segments*2 do
        local t=i*.27;local r=(4+out(p)*9)*math.exp(t*.08)
        local x,y=a.cx+math.cos(t+p)*r,270+math.sin(t+p)*r*.65
        stroke(g,a,alpha,2,lx,ly,x,y);lx,ly=x,y
    end
    if a.nen.tier>=2 then for j=1,5 do ring(g,a,a.cx,270,10+j*10*out(p),6+j*6*out(p),alpha*.3,1.4) end end
end
contacts.prime=function(g,a,p,alpha)
    for i=1,5 do local t=i*math.pi*2/5;local r=19+out(p)*(25+a.nen.tier*13)
        star(g,a,a.cx+math.cos(t)*r,270+math.sin(t)*r*.7,10+a.nen.tier*2,alpha,i*.8)
        if a.nen.tier==3 then stroke(g,a,alpha*.65,2,a.cx,270,a.cx+math.cos(t)*r,270+math.sin(t)*r*.7) end end
end
contacts.odd_star=function(g,a,p,alpha)
    local r=23+out(p)*(40+a.nen.tier*20)
    for i=1,9 do local t=i*math.pi*2/9
        stroke(g,a,alpha,2.5,a.cx+math.cos(t)*r*.25,270+math.sin(t)*r*.2,a.cx+math.cos(t)*r,270+math.sin(t)*r*.7) end
    if a.nen.tier>=2 then ring(g,a,a.cx,270,r*.57,r*.4,alpha*.7,2) end
end
contacts.crimson_tide=function(g,a,p,alpha)
    local r=27+out(p)*(35+a.nen.tier*20)
    for j=1,a.nen.tier+1 do
        stroke(g,a,alpha*(1-j*.13),4,a.cx-r,270+j*8,a.cx-r*.4,248+j*7,a.cx+r*.3,285+j*6,a.cx+r,255+j*8)
    end
    if a.nen.tier==3 then ring(g,a,a.cx,278,r,r*.34,alpha*.7,3) end
end
contacts.obsidian_tide=function(g,a,p,alpha)
    local count=math.min((C.quality[a.quality] or C.quality.high).particles,5+a.nen.tier*3);a.nen.particleCount=count
    for i=1,count do local t=i*2.399;local r=18+out(p)*(28+a.nen.tier*19)
        slab(g,a,a.cx+math.cos(t)*r,275+math.sin(t)*r*.6,13+i%3*5,t+p,alpha)
    end
    if a.nen.tier>=2 then stroke(g,a,alpha,2,a.cx-55,290,a.cx-28,265,a.cx-8,280,a.cx+12,249,a.cx+40,264,a.cx+65,247) end
end
contacts.four_kingdom_prism=function(g,a,p,alpha)
    local r=15+out(p)*(30+a.nen.tier*18)
    local original=a.color;local palette={{.95,.34,.31},{.25,.74,1},{.40,.85,.55},{.8,.5,1}}
    for i=1,4 do a.color=palette[i];local t=i*math.pi/2
        stroke(g,a,alpha,3,a.cx,270,a.cx+math.cos(t)*r,270+math.sin(t)*r*.75)
        crystal(g,a,a.cx+math.cos(t)*r,270+math.sin(t)*r*.75,13,t,alpha*.8)
    end
    a.color=original
    if a.nen.tier==3 then ring(g,a,a.cx,270,r*.7,r*.7,alpha*.7,2) end
end
contacts.four_kingdom_expedition=function(g,a,p,alpha)
    local r=23+out(p)*(30+a.nen.tier*14)
    for i=1,4 do local t=i*math.pi/2+.3
        local x,y=a.cx+math.cos(t)*r,270+math.sin(t)*r*.6
        stroke(g,a,alpha,2,a.cx,270,x,y)
        if a.nen.tier>=2 then banner(g,a,x,y,22,alpha*.8,p+i) end
    end
end
contacts.destiny_crown=function(g,a,p,alpha)
    local r=33+out(p)*(30+a.nen.tier*18)
    stroke(g,a,alpha,4,a.cx,270-r,a.cx,310)
    if a.nen.tier>=2 then for i=1,5 do local t=i*math.pi*2/5
        sword(g,a,a.cx+math.cos(t)*r*.6,270+math.sin(t)*r*.45,23,alpha*.8,t+math.pi/2) end end
    if a.nen.tier==3 then ring(g,a,a.cx,287,r,r*.25,alpha*.8,3) end
end
contacts.continental_gate=function(g,a,p,alpha)
    local r=12+out(p)*(38+a.nen.tier*20)
    ring(g,a,a.cx,270,r*.5,r,alpha,2.5)
    for side=-1,1,2 do stroke(g,a,alpha,2,a.cx+side*r*.3,270-r*.65,a.cx+side*r*.5,270-r*.25,a.cx+side*r*.4,270+r*.2,a.cx+side*r*.6,270+r*.6) end
    if a.nen.tier==3 then for i=1,4 do local t=i*math.pi/2;seal(g,a,a.cx+math.cos(t)*r,270+math.sin(t)*r*.7,11,alpha,t) end end
end
contacts.answer_42=function(g,a,p,alpha)
    local r=20+out(p)*(28+a.nen.tier*15)
    ring(g,a,a.cx,270,r,r*.6,alpha,1.8)
    for j=1,4 do local t=j*math.pi/2
        stroke(g,a,alpha,2,a.cx+math.cos(t)*r*.65,270+math.sin(t)*r*.4,a.cx+math.cos(t)*r*1.15,270+math.sin(t)*r*.75) end
    if a.nen.tier==3 then star(g,a,a.cx,270,24+out(p)*14,alpha*.8,p*.1) end
end
contacts.sealed_gate=function(g,a,p,alpha)
    local r=20+out(p)*(32+a.nen.tier*17)
    stroke(g,a,alpha,3,a.cx-r*.65,270+r*.55,a.cx+r*.5,270-r*.85)
    for j=1,3 do local t=j*math.pi*2/3-math.pi/2;seal(g,a,a.cx+math.cos(t)*r,270+math.sin(t)*r*.6,9,alpha,t) end
    if a.nen.tier==3 then ring(g,a,a.cx,285,r,r*.3,alpha*.8,3) end
end
contacts.seven_stars=function(g,a,p,alpha)
    for i=1,7 do local age=clamp((p-(i-1)*.06)/.62);local x=a.cx+(i-4)*17
        star(g,a,x,265-age*25,9+a.nen.tier*2,alpha*(1-age),i*.3)
        stroke(g,a,alpha*(1-age)*.7,2,x-16,239-age*33,x,276+age*24)
    end
    if a.nen.tier==3 then ring(g,a,a.cx,282,16+out(p)*85,5+out(p)*21,alpha*.7,2) end
end
contacts.five_ley_lines=function(g,a,p,alpha)
    local r=21+out(p)*(29+a.nen.tier*15)
    for i=1,5 do local x=a.cx+(i-3)*24
        stroke(g,a,alpha,2,x,308,x-8,285,a.cx+(i-3)*r*.35,270-r*(.5+((i+1)%3)*.12)) end
    if a.nen.tier==3 then crystal(g,a,a.cx,283,60,0,alpha*.6);ring(g,a,a.cx,304,r,r*.24,alpha*.8,3) end
end
contacts.endless_cycle=function(g,a,p,alpha)
    local r=(14+out(p)*(31+a.nen.tier*17))*(1-.25*smooth(p))
    for j=1,a.nen.tier do g.push();g.translate(a.cx,270);g.rotate((j%2==0 and -1 or 1)*p*2+j*.5)
        ring(g,a,0,0,r,r*.38,alpha,2);g.pop() end
    g.setShader();g.setColor(.025,.025,.055,alpha*.75);g.circle("fill",a.cx,270,r*.32)
    if a.nen.tier==3 then stroke(g,a,alpha,2,a.cx-r*.55,276,a.cx-r*.22,268,a.cx+r*.15,274,a.cx+r*.6,264) end
end
function E.draw(a,phase,p,impactAge)
    local n=a.nen;local g=love.graphics
    if n.cancelled then return end
    g.push("all")
    local x,y=g.transformPoint(242,150);local rx,ry=g.transformPoint(1022,565)
    g.setScissor(x,y,math.max(1,rx-x),math.max(1,ry-y));g.setShader();g.setBlendMode("alpha")
    bind(a)
    local active=phase=="PREPARE" or phase=="ANTICIPATION" or phase=="NEN_AWAKENING" or phase=="CARD_TRANSFORMATION" or phase=="CHARGE" or phase=="RELEASE" or phase=="TRAVEL"
    if active then
        local alpha=smooth((n.charge-.12)/.52)*(phase=="TRAVEL" and (1-smooth((p-.8)/.2)) or 1)
        -- Card-to-technique links persist through construction; artwork fades progressively.
        if n.charge>.2 and phase~="TRAVEL" then for i,c in ipairs(n.snapshot.cards) do
            local tx,ty=N.position(a,N.cardEmitter(a,i),"CHARGE",1)
            stroke(g,a,alpha*.38,1.5,c.x,c.y,tx,ty)
            ring(g,a,c.x,c.y,26*(1-n.charge*.5),36*(1-n.charge*.5),alpha*.52,1.3)
        end end
        drawings[a.profile.id](g,a,phase,p,alpha)
    end
    n.particleCount=0
    if impactAge and impactAge<C.camera.duration+.10 then
        local k=clamp(impactAge/(C.camera.duration+.10));local alpha=(1-k)^1.6
        soft(g,a,a.cx,270,34+out(k)*50,alpha*.11)
        contacts[a.profile.id](g,a,k,alpha)
        -- Local contact flash lasts a few frames; never covers the world or sharp HUD.
        g.setShader();g.setBlendMode("add");g.setColor(.9,.96,1,(1-k)^9*(n.reducedMotion and .13 or .68))
        g.ellipse("fill",a.cx,270,13+n.tier*4,4+n.tier)
    end
    g.pop()
end
function E.fragments(a,i,p,x,y)
    if p<=0 or p>=1 then return end
    local n=a.nen;local g=love.graphics;local c=n.snapshot.cards[i]
    local tx,ty=N.position(a,N.cardEmitter(a,i),"CHARGE",1)
    g.push("all");g.setShader();g.setBlendMode("alpha")
    local count=a.quality=="low" and 3 or 6
    for j=1,count do
        local k=clamp((p-(j-1)*.04)/.72)
        local fx=mix(x,tx,k)+math.sin(k*math.pi)*math.sin(i+j)*12
        local fy=mix(y,ty,k)-math.sin(k*math.pi)*8
        local alpha=math.sin(k*math.pi)*(1-p)
        if n.profile.conversion=="material_transformation" then crystal(g,a,fx,fy,5+3*k,j*.2,alpha)
        elseif n.profile.conversion=="rune_conversion" then
            ring(g,a,fx,fy,4,4,alpha,1);stroke(g,a,alpha,1,fx-3,fy,fx+3,fy)
        elseif n.profile.conversion=="spatial_collapse" then ring(g,a,fx,fy,6*(1-k)+1,3,alpha,1)
        else stroke(g,a,alpha,1.2,fx,fy,fx,fy+8) end
    end
    g.pop()
end
function E.supports(id) return drawings[id]~=nil and contacts[id]~=nil end
return E

local M=require("src.nen_magic")
local C=M.config
local R={enabled=true,diagnostics={},stats={draws=0,particles=0},forceFallback=false}
local pi=math.pi
local types={sword=1,crescent=2,spear=3,arrow=4,stone=5,pillar=6,lightning=7,coin=8,
    star5=9,ray=10,ice=11,orb=12,wave=13,ribbon=13,crown=14,infinity=15,star7=16,portal=17,compass=18,gate=19}
local function read(path)
    if love.filesystem.getInfo(path) then return love.filesystem.read(path) end
    local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
function R.load()
    if R.image then return end
    local data=love.image.newImageData(1,1);data:setPixel(0,0,1,1,1,1)
    R.image=love.graphics.newImage(data);data:release()
    local ok,shader=pcall(function()
        local source=read("shaders/nen_magic.glsl")
        return love.graphics.newShader(source)
    end)
    R.shader=ok and shader or nil
    if not ok then R.diagnostics[#R.diagnostics+1]=tostring(shader);print("[NEN MAGIC] Fallback: "..tostring(shader)) end
    if not require("render.lighting").radial then require("render.lighting").load() end
end
local function glow(x,y,rx,ry,c,alpha)
    local g=love.graphics;local image=require("render.lighting").radial
    g.setShader();g.setColor(c[1],c[2],c[3],alpha)
    g.draw(image,x,y,0,rx/64,ry/64,64,64)
end
local function line(c,alpha,width,points)
    local g=love.graphics;g.setShader();g.setLineJoin("bevel");g.setLineWidth(width)
    g.setColor(c[1],c[2],c[3],alpha);g.line(points)
end
-- CPU fallback keeps the same weapon and explosion silhouettes when GLSL is unavailable.
local function fallback(kind,burst,age,x,y,size,angle,c,alpha)
    local g=love.graphics;g.setShader();g.push();g.translate(x,y);g.rotate(angle)
    g.setColor(c[1],c[2],c[3],alpha);g.setLineWidth(2)
    if burst then
        local t=math.min(1,age/.42);local radius=size*(.14+.54*(1-(1-t)^3))
        local r=radius
        if kind==1 then g.rotate(.65);g.ellipse("line",0,0,r,r*.22);g.line(-r,0,r,0)
        elseif kind==2 then g.line(-r,-r,r,r);g.line(-r,r,r,-r)
        elseif kind==3 then g.arc("line","open",-r*.5,0,r*.6,-1.4,1.4,20);g.arc("line","open",r*.5,0,r*.6,1.7,4.6,20)
        elseif kind==4 then g.polygon("line",0,r,-r,-r*.7,r,-r*.7)
        elseif kind==5 or kind==21 or kind==23 or kind==26 then
            local n=kind==5 and 7 or kind==23 and 8 or 5
            for i=1,n do local a=kind==5 and -pi*.5+(i-(n+1)/2)*.22 or i/n*pi*2
                g.line(math.cos(a)*r*.15,math.sin(a)*r*.15,math.cos(a)*r,math.sin(a)*r) end
            if kind==21 then g.ellipse("line",0,0,r,r*.38) end
        elseif kind==7 or kind==8 or kind==9 then
            g.ellipse("line",0,0,r,r*.3)
            if kind==7 then g.circle("fill",0,0,r*.42,20)
            else g.setLineWidth(4);g.line(0,-r,0,r);if kind==8 then g.line(-r,0,r,0) end end
        elseif kind==16 or kind==18 or kind==22 then
            g.ellipse("line",0,0,r,r*(kind==18 and 1 or .6))
            if kind==22 then g.rotate(.9);g.ellipse("line",0,0,r*.8,r*.4) end
        elseif kind==24 then
            for side=-1,1,2 do for i=0,4 do g.line(side*r*.08,r*.18,side*r*(1.05-i*.10),r*(-.68+i*.2125)) end end
        elseif kind==11 or kind==13 or kind==15 or kind==17 or kind==19 or kind==25 then
            local n=kind==15 and 6 or (kind==17 or kind==25) and 7 or kind==19 and 4 or 5
            local points={};for i=0,n*2 do local a=i*pi/n-pi/2;local d=r*(i%2==0 and 1 or .4)
                points[#points+1]=math.cos(a)*d;points[#points+1]=math.sin(a)*d end;g.polygon("line",points)
        else
        local lobes=({[6]=3,[10]=13,[12]=5,[14]=27,[20]=4,[27]=2})[kind] or 3
        local points={}
        for i=0,48 do local a=i/48*pi*2;local r=radius*(.76+.24*math.cos(a*lobes+t*2))
            points[#points+1]=math.cos(a)*r;points[#points+1]=math.sin(a)*r end
        g.line(points)
        if kind==27 then g.circle("line",0,0,r*.4,24) end
        end
    elseif kind==1 or kind==3 or kind==4 or kind==10 then
        g.setLineWidth(kind==10 and 5 or 3);g.line(-size*.75,0,size*.8,0)
        if kind==1 then g.setLineWidth(5);g.line(-size*.29,-size*.2,-size*.29,size*.2)
        else g.line(size*.4,-size*.14,size*.8,0,size*.4,size*.14) end
    elseif kind==2 or kind==13 then g.arc("line","open",0,0,size*.6,-1.3,1.3,24)
    elseif kind==5 or kind==6 or kind==11 or kind==20 then
        g.ellipse("fill",0,0,size*.52,size*(kind==5 and .44 or .18),16)
        g.setColor(1,1,1,alpha*.65);g.line(-size*.35,-size*.03,size*.35,-size*.03)
    elseif kind==7 then local p={};for i=0,8 do p[#p+1]=(i/8-.5)*size*1.6;p[#p+1]=math.sin(i*12+age*5)*size*.06 end;g.line(p)
    elseif kind==9 or kind==16 then local points={};local n=kind==9 and 5 or 7
        for i=0,n*2 do local a=i*pi/n;local r=size*(i%2==0 and .65 or .3);points[#points+1]=math.cos(a)*r;points[#points+1]=math.sin(a)*r end;g.polygon("fill",points)
    elseif kind==14 then g.line(-size*.45,size*.2,-size*.45,-size*.2,-size*.22,0,0,-size*.4,size*.22,0,size*.45,-size*.2,size*.45,size*.2,-size*.45,size*.2)
    elseif kind==15 then local points={};for i=0,48 do local a=i/48*2*pi;points[#points+1]=math.cos(a)*size*.7;points[#points+1]=math.sin(a*2)*size*.28 end;g.line(points)
    elseif kind==19 then g.rectangle("line",-size*.4,-size*.65,size*.8,size*1.3)
    else g.circle("line",0,0,size*.53,32);g.circle("fill",-size*.16,-size*.15,size*.1,12) end
    g.pop()
end
local function surface(kind,burst,age,x,y,size,angle,c,accent,alpha,power)
    local g=love.graphics;local shader=not R.forceFallback and R.shader
    if shader then
        g.setShader(shader);shader:send("kind",kind);shader:send("burst",burst and 1 or 0)
        shader:send("clock",age);shader:send("power",power);shader:send("tint",c);shader:send("accent",accent)
        if not burst and (kind==5 or kind==20) then
            g.setBlendMode("alpha");shader:send("bodyPass",1);g.setColor(1,1,1,alpha)
            g.draw(R.image,x,y,angle,size*2,size*2,.5,.5)
        end
        g.setBlendMode("add","premultiplied");shader:send("bodyPass",0)
        g.setColor(1,1,1,alpha);g.draw(R.image,x,y,angle,size*2,size*2,.5,.5)
        g.setBlendMode("add")
    else fallback(kind,burst,age,x,y,size,angle,c,alpha) end
    R.stats.draws=R.stats.draws+1
end
local white={.90,.97,1}
local function trail(s,i,p,c,size,alpha,quality)
    local g=love.graphics;local samples=quality.segments;local points=s.points;local count=0
    local span=s.scale.trail
    for j=0,samples do
        local k=math.max(0,p-span*(1-j/samples));local x,y=M.position(s,i,k)
        count=count+1;points[count]=x;count=count+1;points[count]=y
    end
    for j=#points,count+1,-1 do points[j]=nil end
    -- Each short segment narrows into its predecessor; no long decorative guide lines.
    for j=1,samples do
        local n=(j-1)*2+1;local t=j/samples;local w=(.7+size*.055)*t
        if math.abs(points[n]-points[n+2])+math.abs(points[n+1]-points[n+3])>.02 then
            g.setShader();g.setLineWidth(w*3);g.setColor(c[1],c[2],c[3],alpha*t*.12)
            g.line(points[n],points[n+1],points[n+2],points[n+3])
            g.setLineWidth(math.max(.5,w));g.setColor(.55+c[1]*.45,.55+c[2]*.45,.55+c[3]*.45,alpha*t*.62)
            g.line(points[n],points[n+1],points[n+2],points[n+3])
        end
    end
end
local function sparkle(x,y,r,c,alpha,star)
    local g=love.graphics;glow(x,y,r*3,r*3,c,alpha*.30)
    g.setColor(.65+c[1]*.35,.65+c[2]*.35,.65+c[3]*.35,alpha)
    if star then g.ellipse("fill",x,y,r*.3,r*1.8,8);g.ellipse("fill",x,y,r*1.8,r*.3,8)
    else g.circle("fill",x,y,r*.55,8) end
end
local function motif(s,p,alpha)
    local h=s.profile;local mode=h.movementPattern;local c=h.colorPalette[1]
    local x,y=M.position(s,1,0);local size=62*s.scale.size
    local kind=mode=="portal" and 17 or mode=="compass" and 18 or mode=="gate" and 19
    if kind then surface(kind,false,p,x,y,size,mode=="portal" and p*.6 or 0,c,h.colorPalette[2] or c,alpha*.85,s.scale.power) end
    if mode=="ley" then
        for i=1,5 do
            local col=h.colorPalette[i];local points={};local angle=(i-1)/5*pi*2
            for j=0,20 do local k=j/20;local r=110*(1-k);points[#points+1]=x+math.cos(angle+k)*r;points[#points+1]=y+math.sin(angle+k)*r*.35 end
            line(col,alpha*.45,3,points)
            local k=p%1;local r=110*(1-k);sparkle(x+math.cos(angle+k)*r,y+math.sin(angle+k)*r*.35,2.5,col,alpha,false)
        end
    end
end
local function impact(s,age,alpha,budget)
    local h=s.profile;local power=s.scale.power;local c=h.colorPalette[1];local accent=h.colorPalette[2] or c
    local t=age/.42;if t<0 or t>=1 then return 0 end
    local fade=(1-t)^1.5;local size=(135+power*75);local cx,cy=s.cx,s.cy
    glow(cx,cy,size*.8,size*.55,c,math.exp(-age*17)*.34*s.scale.glow)
    if h.explosionType=="eclipse" then -- A dark centre survives the hot corona.
        love.graphics.setBlendMode("alpha");love.graphics.setColor(.025,.008,.055,fade*.85)
        love.graphics.circle("fill",cx,cy,size*(.12+.22*(1-(1-t)^3)),32);love.graphics.setBlendMode("add")
    end
    surface(h.explosionIndex,true,age,cx,cy,size,0,c,accent,alpha,power)
    if h.movementPattern=="lightning" then
        for i=1,3 do local strikeAge=age-(i-1)*.025
            if strikeAge>=0 and strikeAge<.10 then
                surface(7,false,i,cx+(i-2)*15,cy-43,67,pi/2,c,accent,math.exp(-strikeAge*35),power)
            end
        end
    end
    if s.scale.level>=3 and not s.reducedMotion then surface(h.explosionIndex,true,age+.035,cx,cy,size*.72,.13,accent,c,alpha*.27,power) end
    if s.scale.level==4 and not s.reducedMotion then surface(h.explosionIndex,true,age+.06,cx,cy,size*1.12,-.10,c,accent,alpha*.17,power) end
    local count=math.min(budget,s.scale.particles);local kind=h.particleParameters.kind
    for j=1,count do
        local f=(j*.61803398875+s.seed)%1;local a=f*2*pi
        if h.explosionType=="arrow_fan" then a=-pi*.5+(f-.5)*1.9
        elseif h.explosionType=="holy_column" then a=(j%2==0 and -pi*.5 or pi*.5)+(f-.5)*.35
        elseif h.explosionType=="blade_ring" then a=.65+(j%2)*pi+(f-.5)*.3
        elseif h.explosionType=="crossed_blades" then a=pi/4+(j%4)*pi/2+(f-.5)*.15 end
        local r=(24+f*size)*(1-math.exp(-t*5));local x=cx+math.cos(a)*r;local y=cy+math.sin(a)*r
        local col=h.colorPalette[(j-1)%#h.colorPalette+1];local radius=(1.2+f*2.2)*(1-t*.6)
        if kind=="ice" or kind=="stone" or kind=="crystal" or kind=="fire" then
            y=y+(kind=="fire" and -12 or 22)*t*t
            local material=kind=="fire" and 5 or kind=="stone" and 20 or 11
            surface(material,false,t,x,y,(5+f*9)*(1-t*.45),a+t,col,col,fade*.8,power)
        elseif h.explosionType=="coin_stars" and j%3==0 then
            surface(8,false,t,x,y,7,a+t*4,col,col,fade,power)
        elseif kind=="liquid" then
            local g=love.graphics;y=y+35*t*t;glow(x,y,radius*3,radius*4,col,fade*.24)
            g.setColor(col[1],col[2],col[3],fade);g.ellipse("fill",x,y,radius*.7,radius*(1.3+t),12)
            g.setColor(1,.8,.9,fade*.8);g.circle("fill",x-radius*.2,y-radius*.45,radius*.24,8)
        elseif kind=="electric" then
            local g=love.graphics;g.setShader();g.setColor(col[1],col[2],col[3],fade);g.setLineWidth(1.2)
            local dx,dy=math.cos(a)*radius*5,math.sin(a)*radius*5
            g.line(x-dx,y-dy,x-dx*.4-dy*.2,y-dy*.4+dx*.2,x,y)
            sparkle(x,y,radius*.7,col,fade,false)
        else
            local g=love.graphics;g.setShader();g.setLineWidth(1);g.setColor(col[1],col[2],col[3],fade*.40)
            g.line(x,y,x-math.cos(a)*radius*4,y-math.sin(a)*radius*4)
            sparkle(x,y,radius,col,fade*(.7+.3*math.sin(j+t*20)^2),kind=="star" or kind=="gold")
        end
    end
    return count
end
function R.draw(a,phase,p,impactAge)
    if not a.nen or not C.hands[a.nen.snapshot.handId] then return false end
    if not R.enabled then return true end
    local s=M.state(a);if not s then return true end
    s.reducedMotion=not not a.nen.reducedMotion
    if not R.image then R.load() end
    local g=love.graphics;local h=s.profile;local q=C.quality[a.quality] or C.quality.high
    R.stats.draws=0;R.stats.particles=0
    g.push("all");g.setShader();g.setBlendMode("add");g.setLineJoin("bevel")
    local left,top=g.transformPoint(242,150);local right,bottom=g.transformPoint(1022,565)
    g.intersectScissor(left,top,math.max(1,right-left),math.max(1,bottom-top))
    local active=phase=="PREPARE" or phase=="ANTICIPATION" or phase=="NEN_AWAKENING" or phase=="CARD_TRANSFORMATION" or phase=="CHARGE" or phase=="RELEASE" or phase=="TRAVEL"
    if active then
        local flying=phase=="TRAVEL";local progress=flying and math.max(0,math.min(1,p)) or 0
        local charge=math.max(0,math.min(1,a.nen.charge or p or 0));local alpha=math.min(1,charge*2)
        motif(s,flying and progress or charge,alpha*(1-progress)^2)
        local size=h.size*s.scale.size*h.auraScale*(flying and 1 or .75+.25*charge)
        for i=1,h.projectileCount do
            local x,y,k=M.position(s,i,progress);local c=h.colorPalette[(i-1)%#h.colorPalette+1]
            local nx,ny=M.position(s,i,math.min(.999,progress+.012));local angle=math.atan2(ny-y,nx-x)
            if not flying or math.abs(nx-x)+math.abs(ny-y)<.01 then angle=math.atan2(s.cy-y,s.cx-x) end
            local kind=h.movementPattern=="obsidian" and 20 or types[h.projectileType];local clock=progress*2+charge*.4
            if flying then trail(s,i,progress,c,size,alpha,q) end
            if h.projectileType=="coin" or h.projectileType=="star5" or h.projectileType=="star7" or h.projectileType=="stone" then angle=angle+clock*2+i end
            if h.projectileType=="crown" or h.projectileType=="infinity" then angle=math.sin(clock*3)*.16 end
            glow(x,y,size*.85,size*.58,c,alpha*.13*s.scale.glow*h.glowParameters.halo/.28)
            surface(kind,false,clock,x,y,size,angle,c,h.colorPalette[i%#h.colorPalette+1],alpha*h.glowParameters.core/.82,s.scale.power)
            if h.movementPattern=="judgement" then surface(17,false,clock,x,y,size*.57,clock,c,c,alpha*.32,s.scale.power) end
            if flying and s.scale.level>=3 and not s.reducedMotion then
                local ox,oy=M.position(s,i,math.max(0,progress-.06))
                surface(kind,false,clock,ox,oy,size*.9,angle,c,c,alpha*.14,s.scale.power)
            end
        end
        if flying then
            local count=math.min(q.particles,s.scale.particles)
            for j=1,count do
                local i=(j-1)%h.projectileCount+1;local f=(j*.6180339)%1
                local x,y=M.position(s,i,math.max(0,progress-s.scale.trail*f))
                local c=h.colorPalette[(i-1)%#h.colorPalette+1];local drift=f*7
                sparkle(x+math.sin(j*5)*drift,y+math.cos(j*5)*drift,1+f*1.4,c,alpha*(1-f)*(.5+.5*math.sin(progress*19+j)^2),j%3==0)
            end
            R.stats.particles=count
        end
    end
    if impactAge then R.stats.particles=impact(s,impactAge,1,q.particles) end
    s.particleCount=R.stats.particles;a.nen.particleCount=R.stats.particles
    g.pop();return true
end
return R

-- Presentation only: numbers always come from the resolved gameplay result.
local F = {config=require("config.action_vfx_config"),vfx={}}
local colors = {{1,0.88,0.72}, {1,0.75,0.32}, {1,0.48,0.20}, {0.56,0.82,1}, {0.88,0.65,1}}
local labels = {"BÌNH THƯỜNG", "CỰC MẠNH", "BÙNG NỔ", "SIÊU VIỆT", "TUYỆT ĐỈNH"}
local sizes = {1,1.08,1.16,1.25,1.34}

-- Display values follow resolved resources; labels and gameplay keep the exact totals.
function F.updateMeter(m, value, dt, duration)
    value=math.max(0,value or 0)
    if not m then return {value=value,shown=value,trail=value,from=value,trailFrom=value,age=1} end
    if value~=m.value then
        m.from,m.trailFrom=m.shown,math.max(m.trail,m.shown)
        m.loss=value<m.shown
        m.value,m.age=value,0
    end
    m.age=m.age+math.max(0,dt)
    local p=math.min(1,m.age/(duration or 0.32))
    m.shown=m.from+(m.value-m.from)*(1-(1-p)^3)
    if m.loss then
        local trail=math.max(0,math.min(1,(m.age-0.12)/0.38))
        m.trail=m.trailFrom+(m.value-m.trailFrom)*trail*trail*(3-2*trail)
    else m.trail=m.shown end
    return m
end

function F.tier(amount)
    amount = math.abs(amount or 0)
    if amount >= 100000 then return 5 end
    if amount >= 10000 then return 4 end
    if amount >= 1000 then return 3 end
    if amount >= 100 then return 2 end
    return 1
end

function F.prepareFoil()
    if F.foilPrepared or not (love and love.graphics) then return end
    F.foilPrepared=true
    local ok,shader=pcall(love.graphics.newShader,[[
        extern number clock;
        extern vec2 origin;
        extern number span;
        vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
            vec4 glyph=Texel(texture,uv);
            vec2 p=screen-origin;
            float phase=p.x/max(span,1.0)*4.0+p.y*0.018-clock*1.8;
            vec3 spectrum=0.65+0.35*cos(phase+vec3(0.0,2.094,4.188));
            float sheen=pow(0.5+0.5*sin(p.x*0.035+p.y*0.10-clock*3.0),12.0);
            vec3 foil=mix(color.rgb,spectrum,0.72)+vec3(sheen*0.16);
            return vec4(glyph.rgb*foil,glyph.a*color.a);
        }
    ]])
    if ok then F.foilShader=shader else F.foilError=tostring(shader) end
end

function F.prepareFire()
    if F.firePrepared or not (love and love.graphics) then return end
    F.firePrepared=true
    local ok,shader=pcall(love.graphics.newShader,"shaders/damage_fire.glsl")
    if ok then F.fireShader=shader else F.fireError=tostring(shader) end
end

function F.new(kind, amount, x, y, format)
    local tier = kind == "damage" and F.tier(amount) or 1
    local positive = amount >= 0
    local color = kind == "damage" and colors[tier]
        or kind == "gold" and (positive and {1,0.83,0.26} or {1,0.57,0.30})
        or kind == "armor" and {0.40,0.84,1}
        or (positive and {0.45,1,0.65} or {1,0.35,0.39})
    local number = (format or tostring)(math.abs(amount))
    local text = (kind == "damage" and "−" or positive and "+" or "−") .. number
    if kind == "gold" then text = text .. " VÀNG"
    elseif kind == "armor" then text = text .. " GIÁP"
    elseif kind == "heal" then text = text .. " HP"
    elseif kind == "speed" then text = text .. " TỐC" end
    local rewardLevel=math.abs(amount)>=100 and 4 or math.abs(amount)>=25 and 3 or math.abs(amount)>=10 and 2 or 1
    local duration = kind == "damage" and (1.25 + tier * 0.16) or kind=="gold" and (1.16+rewardLevel*0.12) or 1.24
    local apex=kind=="damage" and math.max(0,math.min(1,(math.log(math.max(1,math.abs(amount)))/math.log(10)-5)/10)) or 0
    local label=kind=="damage" and tier>=2 and labels[tier] or nil
    if kind=="damage" and tier>=2 then F.prepareFire() end
    if kind=="damage" and tier==5 then F.prepareFoil() end
    return {kind=kind, tier=tier, amount=amount, text=text, color=color, x=x, y=y,
        originX=x,originY=y,lane=0,apex=apex,
        age=0, life=duration, maxLife=duration, alpha=1, rewardLevel=rewardLevel,label=label}
end

function F.add(list, kind, amount, x, y, format)
    local ft = F.new(kind, amount, x, y, format)
    if kind=="damage" then
        -- Three readable lanes per target; a new hit replaces its oldest lane.
        for i=#list,1,-1 do
            local other=list[i]
            if other.kind==kind and math.abs((other.originX or other.x)-x)<80
                and math.abs((other.originY or other.y)-y)<80 and (other.life or 0)>0 then
                ft.lane=((other.lane or 0)+1)%3;ft.burst=true;break
            end
        end
        for i=#list,1,-1 do
            local other=list[i]
            if other.kind==kind and math.abs((other.originX or other.x)-x)<80
                and math.abs((other.originY or other.y)-y)<80 then
                if (other.lane or 0)==ft.lane then table.remove(list,i)
                else other.crowded=true end
            end
        end
        ft.x=x+({0,-16,16})[ft.lane+1];ft.y=y+ft.lane*64
    else
    -- Separate repeated hits without changing the position of older numbers.
    for i=#list,1,-1 do
        local other = list[i]
        if other.kind == kind and (other.age or 0) < 0.35 and math.abs(other.x-x) < 80 then
            ft.x = other.x + (other.x <= x and 42 or -42)
            ft.y = other.y + 42 + (ft.tier-1)*6
            break
        end
    end
    end
    list[#list+1] = ft
    if kind=="armor" or kind=="heal" then
        local effect=kind=="armor" and (amount>=0 and "armor_gain" or "armor_loss") or (amount>=0 and "heal" or "hurt")
        local vx,vy=x,y
        if kind=="heal" and y==114 then vx,vy=320,43
        elseif kind=="armor" and y==85 then vx,vy=245,23 end
        local silent=y>=450
        -- Contact and HUD describe the same hit; keep one transient.
        if amount<0 and y<150 then
            for _,e in ipairs(F.vfx) do if e.kind==effect and e.age<0.06 then silent=true;break end end
        end
        F.emit(effect,vx,vy,amount,nil,silent)
    end
    while #list > 24 do table.remove(list, 1) end
    return ft
end

function F.damagePose(ft)
    local age=math.max(0,ft.age or 0)
    local tier=ft.tier or 1
    local base=sizes[tier]+(ft.apex or 0)*0.06
    if ft.reducedMotion then return base,base,0,math.min(1,age/0.5)*8 end
    -- One small, uniform rebound keeps digit proportions intact at every frame.
    local scale=base*(1-0.12*math.exp(-age*22)+0.13*math.exp(-age*9)*math.sin(age*19))
    return scale,scale,0,(1-math.exp(-age*2.4))*(20+tier*4)
end

function F.update(ft, dt)
    ft.age = ft.age + dt
    ft.life = math.max(0, ft.maxLife-ft.age)
    ft.alpha = math.min(1, ft.life/0.32)
    return ft.life <= 0
end

local function outlined(g, text, x, y, width, color, alpha)
    g.setColor(0.015,0.02,0.035,alpha*0.95)
    g.printf(text,x+1,y+4,width,"center")
    for _,offset in ipairs({{-2,0},{2,0},{0,-2},{0,2},{-1,-1},{1,-1},{-1,1},{1,1}}) do
        g.printf(text,x+offset[1],y+offset[2],width,"center")
    end
    g.setColor(color[1],color[2],color[3],alpha)
    g.printf(text,x,y,width,"center")
end

local function sparkle(g,x,y,r,color,alpha)
    g.setColor(color[1],color[2],color[3],alpha)
    g.polygon("fill",x,y-r,x+r*0.22,y-r*0.22,x+r,y,x+r*0.22,y+r*0.22,
        x,y+r,x-r*0.22,y+r*0.22,x-r,y,x-r*0.22,y-r*0.22)
end

local function luminousText(g,text,color,alpha,strength)
    g.setBlendMode("add")
    for radius=8,4,-4 do
        g.setColor(color[1],color[2],color[3],alpha*strength*(radius==4 and 0.14 or 0.055))
        for i=1,8 do
            local angle=i*math.pi/4
            g.printf(text,-230+math.cos(angle)*radius,math.sin(angle)*radius,460,"center")
        end
    end
    g.setBlendMode("alpha")
end

local function resourceIcon(g,kind,x,y,color,alpha,negative)
    g.setColor(color[1],color[2],color[3],alpha);g.setLineWidth(1.5)
    if kind=="gold" then
        g.circle("fill",x,y,6);g.setColor(0.17,0.09,0.025,alpha);g.circle("line",x,y,4)
        g.line(x,y-2,x,y+2)
    elseif kind=="armor" then
        g.polygon("line",x-6,y-5,x,y-7,x+6,y-5,x+5,y+3,x,y+7,x-5,y+3)
        if negative then g.line(x-2,y-5,x+2,y-1,x-2,y+2,x+1,y+5)
        else g.line(x-3,y,x,y+3,x+3,y-2) end
    else g.setLineWidth(2);g.line(x-4,y,x+4,y);g.line(x,y-4,x,y+4) end
end

local function variation(n,seed) return (math.sin(n*12.9898+seed*78.233)*43758.5453)%1 end
function F.lightningGeometry(ft,width,height)
    local age=ft.reducedMotion and 0 or ft.age or 0
    local frame=math.floor(age*12+1e-7)
    local cache=ft.lightning or {paths={}}
    ft.lightning=cache
    if cache.frame==frame and cache.width==width and cache.height==height then return cache.paths end
    cache.frame,cache.width,cache.height=frame,width,height
    local seed=math.abs(ft.amount or 0)%991*0.071
    local count=ft.tier==5 and 8 or 3
    for i=1,count do
        local path=cache.paths[i] or {points={},branches={}};cache.paths[i]=path
        local start=(i-1)*math.pi*2/count+variation(i,seed+frame)*0.5
        local sweep=(count==3 and 1.5 or 0.65)+variation(i+17,seed+frame)*0.85
        for j=0,12 do
            local angle=start+j/12*sweep
            local cx,cy=math.cos(angle),math.sin(angle)
            local jitter=(variation(i*31+j,seed+frame)-0.5)*6
            path.points[j*2+1]=(cx<0 and -1 or 1)*math.abs(cx)^0.4*(width/2+7)+cx*jitter
            path.points[j*2+2]=height*0.5+(cy<0 and -1 or 1)*math.abs(cy)^0.6*(height*0.4+7)+cy*jitter
        end
        for b=1,(count==8 and 2 or 1) do
            local branch=path.branches[b] or {};path.branches[b]=branch
            local j=3+b*3
            local angle=start+j/12*sweep+(variation(i+b*41,seed+frame)-0.5)*0.9
            local dx,dy=math.cos(angle),math.sin(angle)
            local length=(count==8 and 13 or 8)+variation(i+b*13,seed+frame)*9
            local x,y=path.points[j*2+1],path.points[j*2+2]
            for k=0,4 do
                local bend=k>0 and k<4 and (variation(i*61+b*17+k,seed+frame)-0.5)*5 or 0
                branch[k*2+1]=x+dx*length*k/4-dy*bend
                branch[k*2+2]=y+dy*length*k/4+dx*bend
            end
        end
    end
    return cache.paths
end

local function electricStroke(g,points,alpha,branch)
    g.setColor(0.35,0.47,1,alpha*0.12);g.setLineWidth(branch and 3 or 5)
    g.line(points)
    g.setColor(0.48,0.76,1,alpha*0.45);g.setLineWidth(branch and 1.3 or 2.2)
    g.line(points)
    g.setColor(0.92,0.97,1,alpha);g.setLineWidth(branch and 0.55 or 0.85)
    g.line(points)
end

local function damageAura(g,ft,width,height,alpha)
    local tier=ft.tier or 1
    if tier<2 or ft.crowded then return end
    local age=ft.reducedMotion and 0 or ft.age or 0
    local intensity=math.min(1,(ft.age or 0)/0.06)*alpha
    local reach=tier==2 and 9 or tier==3 and 18 or tier==4 and 21 or 26
    g.setBlendMode("add")
    if F.fireShader then
        local cx,cy=g.transformPoint(0,height*0.5)
        local px,py=g.transformPoint(1,height*0.5)
        F.fireShader:send("clock",age)
        F.fireShader:send("seed",math.abs(ft.amount or 0)%991*0.017)
        F.fireShader:send("center",{cx,cy})
        F.fireShader:send("halfSize",{width/2+1,height*0.34})
        F.fireShader:send("pixelScale",math.sqrt((px-cx)^2+(py-cy)^2))
        F.fireShader:send("reach",reach)
        g.setShader(F.fireShader);g.setColor(1,1,1,intensity*0.80)
        local pad=reach+10
        g.rectangle("fill",-width/2-pad,-pad,width+pad*2,height+pad*2)
        g.setShader()
    else
        -- Keep a soft ember rim readable on devices without procedural shaders.
        for i=1,12 do
            local a=i*math.pi/6
            g.setColor(1,0.38,0.05,intensity*0.12)
            g.ellipse("fill",math.cos(a)*(width/2+3),height*0.5+math.sin(a)*height*0.4,reach*0.5,reach*0.6)
        end
    end
    if tier>=3 then
        for i=1,6 do
            local p=(age*0.7+i*0.618)%1
            local x=(variation(i,ft.amount%991)-0.5)*(width+20)
            local y=height*0.3-reach-p*22
            local ember=intensity*math.sin(p*math.pi)*0.5
            g.setColor(1,0.37,0.045,ember*0.25);g.circle("fill",x,y,2)
            g.setColor(1,0.85,0.39,ember);g.circle("fill",x,y,0.7)
        end
    end
    if tier>=4 then
        for i,path in ipairs(F.lightningGeometry(ft,width,height)) do
            local pulse=(age*5.5+i*0.31)%1
            local light=intensity*(0.15+0.85*math.exp(-pulse*6))
            electricStroke(g,path.points,light,false)
            for _,branch in ipairs(path.branches) do electricStroke(g,branch,light*0.72,true) end
        end
    end
    g.setBlendMode("alpha")
end

function F.draw(ft, ui)
    local g = love.graphics
    local age, tier = ft.age or 0, ft.tier or 1
    local alpha = ft.kind and ft.alpha or math.min(1, ft.life and ft.life/0.35 or ft.alpha or 1)
    local color = ft.color or {1,1,1}
    local crowded=ft.kind=="damage" and ft.crowded
    if crowded then alpha=alpha*0.62 end
    g.push("all")
    g.setShader()
    local rise = ft.kind and (1-math.exp(-age*2.5))*(ft.kind=="damage" and 30+tier*8 or ft.compact and 13 or 32) or 0
    if ft.kind == "gold" then
        -- Coin flight stays in HUD coordinates, independent of the number's spring.
        local target = ft.target or {x=ft.x,y=ft.y-58}
        local source = ft.coinSource or {x=ft.x,y=ft.y+22}
        local count = ft.compact and 3 or math.min(16,3+(ft.rewardLevel or 1)*2+math.floor(math.sqrt(math.abs(ft.amount))))
        for i=1,count do
            local p=math.max(0,math.min(1,(age-i*0.022)/0.66))
            local k=p*p*(3-2*p)
            local sx,sy,tx,ty=source.x+math.sin(i*2.4)*38,source.y,target.x,target.y
            if ft.amount<0 then sx,sy,tx,ty=target.x,target.y,source.x+math.sin(i*2.4)*38,source.y+4 end
            local x,y=sx+(tx-sx)*k,sy+(ty-sy)*k-math.sin(p*math.pi)*(30+i*2)
            local a=alpha*math.min(1,p*12,(1-p)*8)
            local w=1.2+4.4*math.abs(math.cos(age*17+i))
            g.setBlendMode("add")
            g.setColor(1,0.62,0.12,a*0.12);g.ellipse("fill",x,y,w+5,10)
            g.setColor(1,0.78,0.26,a*0.25);g.setLineWidth(2)
            g.line(x,y,x-(tx-sx)*0.045,y+9)
            g.setBlendMode("alpha")
            g.setColor(0.28,0.12,0.025,a);g.ellipse("fill",x+1,y+2,w,6)
            g.setColor(1,0.70,0.12,a);g.ellipse("fill",x,y,w,6)
            g.setColor(1,0.96,0.55,a);g.setLineWidth(1);g.ellipse("line",x,y,w,6)
            g.line(x-w*0.5,y-3,x+w*0.3,y-4)
            sparkle(g,x+8,y-7,3+math.sin(i+age*14),{1,0.94,0.62},a*0.65)
        end
        local arrival=math.max(0,1-math.abs(age-0.74)/0.26)
        g.setBlendMode("add");g.setColor(1,0.81,0.26,arrival*0.45);g.setLineWidth(1.2)
        g.ellipse("line",target.x,target.y,7+(1-arrival)*18,5+(1-arrival)*10)
        g.setBlendMode("alpha")
        sparkle(g,target.x,target.y,10,{1,0.93,0.5},arrival*0.8)
    end
    local font = ft.kind=="damage" and (tier>=4 and ui.fonts.title or ui.fonts.large)
        or (not ft.life and ui.fonts.large) or ft.kind and (ui.fonts.regular or ui.fonts.medium) or ui.fonts.medium
    font=font or ui.fonts.large
    local text = ui.sanitizeText and ui.sanitizeText(ft.text) or ft.text
    local pulse=ft.kind=="heal" and (ft.amount>0 and 0.12 or 0.25) or ft.kind=="armor" and 0.22 or 0.16
    local scale = ft.kind and (1+pulse*math.exp(-age*19)*math.sin(age*38)-0.06*math.exp(-age*40)) or ft.scale or 1
    if ft.compact then scale=scale*0.78 end
    local scaleY
    if ft.kind=="damage" then
        local tilt
        scale,scaleY,tilt,rise=F.damagePose(ft)
        if ft.compact then scale,scaleY=scale*0.78,scaleY*0.78 end
        if crowded then scale,scaleY=scale*0.82,scaleY*0.82 end
        if ft.burst and not crowded then scale,scaleY=scale*0.94,scaleY*0.94 end
    end
    local maxWidth=ft.kind=="damage" and 360 or 230
    local fit=math.min(1,maxWidth/math.max(1,font:getWidth(text)*scale))
    scale=scale*fit;scaleY=(scaleY or scale/fit)*fit
    local half=font:getWidth(text)*scale/2+(ft.kind=="damage" and 55 or 30)
    local x=ft.kind and math.max(half+8,math.min(1280-half-8,ft.x)) or ft.x
    g.translate(x,math.max(72,ft.y-rise))
    g.scale(scale,scaleY)
    if ft.kind=="damage" then
        damageAura(g,ft,font:getWidth(text),font:getHeight(),alpha)
    end
    g.setFont(font)
    local tw=font:getWidth(text)
    if ft.kind and ft.kind~="damage" then
        local left,right=-tw/2-29,tw/2+12
        local bottom=font:getHeight()+3
        g.setColor(0.012,0.024,0.039,alpha*0.94)
        g.polygon("fill",left+5,-4,right-5,-4,right,1,right,bottom-5,right-5,bottom,left+5,bottom,left,bottom-5,left,1)
        g.setColor(color[1],color[2],color[3],alpha*0.48);g.setLineWidth(0.8)
        g.line(left+5,bottom,right-5,bottom)
        g.setColor(color[1],color[2],color[3],alpha*0.16);g.rectangle("fill",left+2,0,20,bottom-3,3,3)
        resourceIcon(g,ft.kind,left+12,bottom/2-1,color,alpha,ft.amount<0)
    end
    if ft.kind then
        luminousText(g,text,color,alpha,ft.kind=="damage" and 0.26+tier*0.07 or ft.kind=="gold" and 0.95 or 0.5+tier*0.16)
    end
    local ink=ft.kind=="damage" and {1,0.95,0.84} or color
    outlined(g,text,-230,0,460,ink,alpha)
    if ft.kind=="gold" then
        sparkle(g,-tw/2-21,-5,4,{1,0.94,0.57},alpha*(0.55+0.25*math.sin(age*14)))
        sparkle(g,tw/2+9,14,3,{1,0.94,0.57},alpha*(0.55+0.25*math.cos(age*14)))
    end
    if ft.kind and not ft.reducedMotion then
        -- A brief ivory highlight sells impact without washing out the value.
        g.setColor(1,0.97,0.85,alpha*math.exp(-age*12)*0.75)
        g.printf(text,-230,-0.7,460,"center")
    end
    if ft.kind=="damage" and tier==5 and F.foilShader then
        local shader=g.getShader()
        local ox,oy=g.transformPoint(0,0)
        local right=g.transformPoint(tw,0)
        F.foilShader:send("clock",ft.reducedMotion and 0 or age)
        F.foilShader:send("origin",{ox,oy})
        F.foilShader:send("span",math.max(1,right-ox))
        g.setShader(F.foilShader);g.setColor(ink[1],ink[2],ink[3],alpha)
        g.printf(text,-230,0,460,"center")
        g.setShader(shader)
    end
    if ft.label and not crowded then
        g.setFont(ui.fonts.tiny or ui.fonts.small)
        local labelY=font:getHeight()+5
        if ft.kind~="damage" then
            local labelW=g.getFont():getWidth(ft.label)+24
            g.setColor(0.02,0.025,0.05,alpha*0.82)
            g.rectangle("fill",-labelW/2,labelY-1,labelW,17,4,4)
            g.setColor(color[1],color[2],color[3],alpha*0.55)
            g.setLineWidth(0.8);g.line(-labelW/2+6,labelY+16,labelW/2-6,labelY+16)
        end
        outlined(g,ft.label,-230,labelY,460,color,alpha*(ft.kind=="damage" and 0.78 or 0.92))
    end
    g.pop()
end

local clamp=function(v) return math.max(0,math.min(1,v)) end
local out=function(v) return 1-(1-clamp(v))^3 end
function F.emit(kind,x,y,amount,rect,silent)
    local profile=F.config.profiles[kind]
    if not profile or not x or not y or amount==0 then return end
    local e={kind=kind,x=x,y=y,amount=amount or 1,age=0,profile=profile,rect=rect,
        silent=silent,scale=math.min(F.config.maxScale,1+math.log(1+math.abs(amount or 1))*0.045)}
    F.vfx[#F.vfx+1]=e
    while #F.vfx>F.config.cap do table.remove(F.vfx,1) end
    if profile.contact==0 then F.contact(e) end
    return e
end
function F.contact(e)
    if not e or e.contacted then return false end
    e.contacted=true
    if not e.silent then require("src.sound").play(e.profile.sound,e.profile.pitch) end
    return true
end
function F.updateVfx(dt)
    for i=#F.vfx,1,-1 do
        local e=F.vfx[i]
        if not e.clocked then e.age=e.age+math.max(0,dt) end
        if e.age>=e.profile.contact then F.contact(e) end
        if e.age>=e.profile.duration then table.remove(F.vfx,i) end
    end
end
local destroyed=setmetatable({}, {__mode="k"})
function F.destroyCard(card,x,y,rect,silent)
    if not card or destroyed[card] then return end
    destroyed[card]=true
    return F.emit("destroy",x,y,1,rect,silent)
end
function F.clearVfx() F.vfx={};destroyed=setmetatable({}, {__mode="k"}) end
local function line(g,c,alpha,width,...)
    g.setColor(c[1],c[2],c[3],alpha*0.065);g.setLineWidth(width*2.6);g.line(...)
    g.setColor(c[1],c[2],c[3],alpha);g.setLineWidth(width);g.line(...)
end
local function shield(g,x,y,r,mode)
    g.polygon(mode,x-r*0.7,y-r*0.65,x,y-r,x+r*0.7,y-r*0.65,x+r*0.62,y+r*0.2,x,y+r,x-r*0.62,y+r*0.2)
end
local function contact(e)
    local age=math.max(0,e.age-e.profile.contact)
    return age,e.age>=e.profile.contact and math.exp(-age*26) or 0
end
local painters={}
painters.armor_gain=function(g,e,p,c,alpha)
    local age,hit=contact(e);local build=clamp(e.age/e.profile.contact)^2
    local r=17+hit*2
    g.setColor(c[1],c[2],c[3],alpha*(0.035+hit*0.055));shield(g,0,0,r*1.15,"fill")
    g.setColor(c[1],c[2],c[3],alpha*build);g.setLineWidth(1.8);shield(g,0,0,r,"line")
    for i=1,4 do local a=i*math.pi/2;local d=36*(1-build)+r
        line(g,c,alpha*(1-build),2,math.cos(a)*d,math.sin(a)*d,math.cos(a)*(d+6),math.sin(a)*(d+6)) end
    line(g,c,alpha*build,2,-6,0,0,6,8,-7)
    g.setColor(c[1],c[2],c[3],alpha*hit*0.6);g.setLineWidth(1)
    shield(g,0,0,r+out(age/0.24)*15,"line")
    sparkle(g,13,-13,2+hit*4,{0.85,0.98,1},alpha*hit)
end
painters.armor_loss=function(g,e,p,c,alpha)
    local age,hit=contact(e);local fly=clamp(age/0.32)
    if e.age<e.profile.contact then
        g.setColor(c[1],c[2],c[3],alpha);g.setLineWidth(2);shield(g,0,0,18,"line")
        line(g,c,alpha,1.8,-4,-17,3,-5,-4,3,5,17)
    else
        local points={{-13,-12},{0,-18},{13,-12},{11,4},{0,18},{-11,4}}
        for i=1,6 do
            local a,b=points[i],points[i%6+1];local dx,dy=(a[1]+b[1])*0.5,(a[2]+b[2])*0.5
            local travel=1-math.exp(-age*12)
            g.push();g.translate(dx*travel*1.6,dy*travel*1.3+fly*fly*30);g.rotate((i%2==0 and 1 or -1)*fly*0.85)
            g.setBlendMode("alpha");g.setColor(0.10,0.22,0.29,alpha*0.8);g.polygon("fill",0,0,a[1],a[2],b[1],b[2])
            g.setBlendMode("add");g.setColor(c[1],c[2],c[3],alpha*(0.65+hit*0.35));g.setLineWidth(1.3)
            g.polygon("line",0,0,a[1],a[2],b[1],b[2]);g.pop()
        end
    end
end
painters.heal=function(g,e,p,c,alpha)
    local age,hit=contact(e);local gather=clamp(e.age/0.28);local ease=gather*gather*(3-2*gather)
    for i=1,5 do local a=i*2.4+ease*1.5;local r=30*(1-ease)
        local x,y=math.cos(a)*r,math.sin(a)*r+12*(1-ease)-age*5
        g.setColor(c[1],c[2],c[3],alpha*0.65*math.sin(gather*math.pi));g.circle("fill",x,y,1.8)
        line(g,c,alpha*0.25*math.sin(gather*math.pi),1,x,y,x+math.sin(a)*4,y-math.cos(a)*4)
    end
    g.setColor(c[1],c[2],c[3],alpha*(0.025+hit*0.035));g.circle("fill",0,-age*5,16)
    line(g,c,alpha*ease,2.4,-7,-age*5,7,-age*5);line(g,c,alpha*ease,2.4,0,-7-age*5,0,7-age*5)
    g.setColor(c[1],c[2],c[3],alpha*0.22*ease);g.setLineWidth(1);g.ellipse("line",0,5,10+out(p)*17,4+out(p)*5)
end
painters.hurt=function(g,e,p,c,alpha)
    local cut=out(e.age/0.055);local tail=math.exp(-e.age*13);local r=10+cut*30
    line(g,c,alpha*tail,3.2,-r*0.65,-r*0.6,r*0.65,r*0.6)
    line(g,c,alpha*tail*0.4,1.5,-r*0.2,-r*0.65,r*0.8,r*0.25)
    for i=1,3 do local a=0.35+i*0.25;local d=out(p)*28
        line(g,c,alpha*tail,1,math.cos(a)*d,math.sin(a)*d,math.cos(a)*(d+5),math.sin(a)*(d+5)) end
end
painters.equip=function(g,e,p,c,alpha)
    local age,hit=contact(e);local spring=math.exp(-age*22)*math.sin(age*48)
    local release=e.equipmentAction=="unequip";local snap=out(age/.14)
    local r=release and 15+snap*18 or 31-snap*13+spring*2
    g.setColor(c[1],c[2],c[3],alpha*.09);g.circle("fill",0,0,r+9)
    g.setLineWidth(1.2);g.setColor(c[1],c[2],c[3],alpha*.7)
    for i=1,6 do
        local a=i*math.pi/3+(release and age or -age)*.6
        g.arc("line","open",0,0,r,a,a+.66,8)
        local x,y=math.cos(a)*(r+5),math.sin(a)*(r+5)
        g.polygon("line",x,y-3,x+2,y,x,y+3,x-2,y)
    end
    local core=release and (1-snap)*8 or snap*8
    g.setColor(c[1],c[2],c[3],alpha);g.setLineWidth(1.7)
    g.polygon("line",0,-core,core*.6,0,0,core,-core*.6,0)
    for i=0,3 do local a=i*math.pi/2;local d=release and 10+snap*17 or 21-snap*10
        line(g,c,alpha*(release and 1-snap or snap),1.4,math.cos(a)*d,math.sin(a)*d,math.cos(a)*(d+7),math.sin(a)*(d+7)) end
    g.setColor(1,.94,.73,alpha*math.exp(-age*16)*.18);g.ellipse("fill",0,0,34,7)
end
painters.destroy=function(g,e,p,c,alpha)
    local age,hit=contact(e);local spread=out(age/0.34)
    for i=1,6 do local a=i*2.39;local r=7+spread*(20+i*2)
        local x,y=math.cos(a)*r,math.sin(a)*r*0.55-spread*(16+i*3)
        line(g,c,alpha*(1-spread)*0.65,1,0,0,math.cos(a)*17,math.sin(a)*24)
        g.setBlendMode("alpha");g.setColor(0.12,0.04,0.02,alpha*0.8);g.polygon("fill",x,y,x+4,y+6,x-2,y+8)
        g.setBlendMode("add");g.setColor(1,0.18+hit*0.65,0.04+hit*0.35,alpha*(1-p*0.6))
        g.setLineWidth(1);g.line(x-2,y+8,x,y,x+4,y+6)
    end
    g.setColor(1,0.68,0.24,alpha*hit*0.09);g.ellipse("fill",0,0,17*(1-spread),24*(1-spread))
end
local function priority(g,e,p,c,alpha,direction)
    for i=1,3 do
        local t=clamp((e.age-(i-1)*0.025)/(direction<0 and 0.11 or 0.18))
        local k=direction<0 and out(t) or t*t*(3-2*t);local x=direction*(-30+45*k)+(i-2)*17
        line(g,c,alpha*(0.8-p*0.3),2,x-direction*7,-8,x,0,x-direction*7,8)
    end
    g.setColor(c[1],c[2],c[3],alpha*0.035);g.ellipse("fill",0,0,65,12)
end
painters.enemy_first=function(g,e,p,c,alpha) priority(g,e,p,c,alpha,-1) end
painters.player_first=function(g,e,p,c,alpha) priority(g,e,p,c,alpha,1) end
painters.buy=function(g,e,p,c,alpha)
    local age,hit=contact(e);local spring=math.exp(-age*19)*math.sin(age*32);local r=19+3*spring
    g.setColor(c[1],c[2],c[3],alpha*(0.025+hit*0.05));g.circle("fill",0,0,r+5)
    g.setColor(c[1],c[2],c[3],alpha);g.setLineWidth(1.8);g.circle("line",0,0,r)
    line(g,c,alpha*out(age/0.05),2.2,-7,0,-1,6,10,-7)
    for i=1,4 do local a=i*math.pi/2;local d=22+out(age/0.2)*13
        line(g,c,alpha*(1-p),1,math.cos(a)*d,math.sin(a)*d,math.cos(a)*(d+5),math.sin(a)*(d+5)) end
end
painters.sell=function(g,e,p,c,alpha)
    local age=math.max(0,e.age-e.profile.contact)
    for i=1,4 do
        local t=clamp((age-(i-1)*0.02)/0.32);local k=t*t*(3-2*t)
        local tx=e.target and (e.target.x-e.x)/e.scale or 0
        local ty=e.target and (e.target.y-e.y)/e.scale or -38
        local x=(i-2.5)*10*(1-k)+tx*k;local y=ty*k-math.sin(k*math.pi)*(18+i*2)
        local a=alpha*math.sin(t*math.pi);local w=2+2*math.abs(math.cos(age*22+i))
        g.setColor(c[1],c[2],c[3],a);g.ellipse("fill",x,y,w,5)
        g.setColor(1,0.93,0.65,a*0.8);g.setLineWidth(1);g.ellipse("line",x,y,w,5)
    end
    line(g,c,alpha*math.exp(-age*18),1.5,-18,10,18,10)
end
function F.drawVfx(ui)
    local g=love.graphics
    g.push("all");g.setShader();g.setBlendMode("add")
    for _,e in ipairs(F.vfx) do
        local p=clamp(e.age/e.profile.duration);local alpha=math.min(1,e.age/0.012)*(1-out((p-0.38)/0.62))
        g.push("all");g.translate(e.x,e.y);g.scale(e.scale,e.scale)
        if e.y<70 and (e.kind=="armor_gain" or e.kind=="armor_loss") then g.scale(0.5) end
        painters[e.kind](g,e,p,e.profile.color,alpha)
        if e.profile.label then
            g.setBlendMode("alpha");g.setFont(ui.fonts.tiny or ui.fonts.small)
            g.setColor(0.01,0.02,0.035,alpha*0.8);g.rectangle("fill",-115,15,230,24,5,5)
            g.setColor(e.profile.color[1],e.profile.color[2],e.profile.color[3],alpha)
            g.printf(e.profile.label,-115,19,230,"center")
        end
        g.pop()
    end
    g.pop()
end
return F

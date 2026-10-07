-- Presentation only: numbers always come from the resolved gameplay result.
local F = {config=require("config.action_vfx_config"),vfx={}}
local colors = {{1,0.88,0.72}, {1,0.75,0.32}, {1,0.48,0.20}, {1,0.28,0.38}, {0.88,0.65,1}}
local labels = {"SÁT THƯƠNG", "ĐÒN MẠNH", "BÙNG NỔ", "HỦY DIỆT", "SIÊU VIỆT"}

function F.tier(amount)
    amount = math.abs(amount or 0)
    if amount >= 100000 then return 5 end
    if amount >= 10000 then return 4 end
    if amount >= 1000 then return 3 end
    if amount >= 100 then return 2 end
    return 1
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
    elseif kind == "heal" then text = text .. " HP" end
    local duration = kind == "damage" and (1.25 + tier * 0.16) or 1.05
    return {kind=kind, tier=tier, amount=amount, text=text, color=color, x=x, y=y,
        age=0, life=duration, maxLife=duration, alpha=1,
        label=kind == "damage" and labels[tier] or nil}
end

function F.add(list, kind, amount, x, y, format)
    local ft = F.new(kind, amount, x, y, format)
    -- Separate repeated hits without changing the position of older numbers.
    for i=#list,1,-1 do
        local other = list[i]
        if other.kind == kind and (other.age or 0) < 0.35 and math.abs(other.x-x) < 80 then
            ft.x = other.x + (other.x <= x and 42 or -42)
            ft.y = other.y + 42 + (ft.tier-1)*6
            break
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

function F.draw(ft, ui)
    local g = love.graphics
    local age, tier = ft.age or 0, ft.tier or 1
    local alpha = ft.kind and ft.alpha or math.min(1, ft.life and ft.life/0.35 or ft.alpha or 1)
    local color = ft.color or {1,1,1}
    g.push("all")
    local rise = ft.kind and (1-math.exp(-age*2.5))*42 or 0
    if ft.kind == "gold" then
        -- Coin flight stays in HUD coordinates, independent of the number's spring.
        local target = ft.target or {x=ft.x,y=ft.y-58}
        local count = math.min(12,4+math.floor(math.sqrt(math.abs(ft.amount))))
        for i=1,count do
            local p=math.max(0,math.min(1,(age-i*0.026)/0.62))
            local k=p*p*(3-2*p)
            local sx,sy,tx,ty=ft.x+math.sin(i*2.4)*38,ft.y+22,target.x,target.y
            if ft.amount<0 then sx,sy,tx,ty=target.x,target.y,ft.x+math.sin(i*2.4)*38,ft.y+26 end
            local x,y=sx+(tx-sx)*k,sy+(ty-sy)*k-math.sin(p*math.pi)*(30+i*2)
            local a=alpha*math.sin(p*math.pi)
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
        local arrival=math.max(0,1-math.abs(age-0.66)/0.22)
        sparkle(g,target.x,target.y,10,{1,0.93,0.5},arrival*0.8)
    end
    g.translate(ft.x, math.max(72,ft.y-rise))
    local pulse=ft.kind=="heal" and (ft.amount>0 and 0.12 or 0.25) or ft.kind=="armor" and 0.22 or 0.16
    local scale = ft.kind=="damage" and (1+(tier-1)*0.16+(0.32+tier*0.065)*math.exp(-age*9)*math.sin(age*25)-0.15*math.exp(-age*35))
        or ft.kind and (1+pulse*math.exp(-age*19)*math.sin(age*38)-0.06*math.exp(-age*40)) or ft.scale or 1
    g.scale(scale)
    if ft.kind == "damage" and tier >= 2 then
        local p = math.min(1, age/0.56)
        g.setBlendMode("add")
        g.setColor(color[1],color[2],color[3],alpha*(1-p)*0.045)
        g.ellipse("fill",0,17,75+p*30,24)
        for ring=1,(tier>=4 and 2 or 1) do
            g.setColor(color[1],color[2],color[3],alpha*(1-p)*(0.5/ring))
            g.setLineWidth(ring==1 and 1.8 or 0.8)
            g.ellipse("line",0,17,(40+p*(38+tier*7))*ring,12+p*15)
        end
        for i=1,4+tier*2 do
            local angle=i*2.399
            local radius=35+p*(40+tier*7)
            local x,y=math.cos(angle)*radius,17+math.sin(angle)*radius*0.42
            sparkle(g,x,y,(2+tier*0.45)*(1-p),color,alpha*(1-p)*0.8)
            g.setColor(color[1],color[2],color[3],alpha*(1-p)*0.5)
            g.setLineWidth(1)
            g.line(x,y,x-math.cos(angle)*(6+tier),y-math.sin(angle)*(6+tier)*0.42)
        end
        g.setBlendMode("alpha")
    end
    local text = ui.sanitizeText and ui.sanitizeText(ft.text) or ft.text
    local font = (ft.kind == "damage" or not ft.life) and ui.fonts.large
        or ft.kind and (ui.fonts.regular or ui.fonts.medium) or ui.fonts.medium
    g.setFont(font)
    -- Long legacy notifications wrap; damage values stay on a single fitted line.
    if ft.kind and font:getWidth(text)>420 then g.scale(420/font:getWidth(text)) end
    local tw=math.min(420,font:getWidth(text))
    if ft.kind=="damage" and tier>=4 then
        for i=2,1,-1 do
            g.push();g.scale(1+i*0.035)
            g.setColor(color[1],color[2],color[3],alpha*math.exp(-age*8)*0.14/i)
            g.printf(text,-230-i*4,i*3,460,"center");g.pop()
        end
    end
    if ft.kind=="damage" or ft.kind=="gold" then
        luminousText(g,text,color,alpha,ft.kind=="gold" and 1.25 or 0.5+tier*0.16)
    end
    outlined(g,text,-230,0,460,color,alpha)
    if ft.kind=="gold" then
        sparkle(g,-tw/2-9,8,4,{1,0.94,0.57},alpha*(0.55+0.25*math.sin(age*14)))
        sparkle(g,tw/2+9,14,3,{1,0.94,0.57},alpha*(0.55+0.25*math.cos(age*14)))
    end
    if ft.kind then
        -- A brief ivory highlight sells impact without washing out the value.
        g.setColor(1,0.97,0.85,alpha*math.exp(-age*12)*0.75)
        g.printf(text,-230,-0.7,460,"center")
    end
    if ft.label then
        g.setFont(ui.fonts.tiny or ui.fonts.small)
        local labelY=font:getHeight()+5
        local labelW=g.getFont():getWidth(ft.label)+24
        g.setColor(0.02,0.025,0.05,alpha*0.82)
        g.rectangle("fill",-labelW/2,labelY-1,labelW,17,4,4)
        g.setColor(color[1],color[2],color[3],alpha*0.55)
        g.setLineWidth(0.8);g.line(-labelW/2+6,labelY+16,labelW/2-6,labelY+16)
        outlined(g,ft.label,-230,labelY,460,color,alpha*0.92)
        sparkle(g,-tw/2-11,14,3.5,color,alpha*math.exp(-age*3)*0.8)
        sparkle(g,tw/2+11,14,3.5,color,alpha*math.exp(-age*3)*0.8)
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
    local r=18-2*hit+2*spring
    g.push();g.rotate(spring*0.035);g.setColor(c[1],c[2],c[3],alpha);g.setLineWidth(2.2)
    g.rectangle("line",-r,-r,r*2,r*2,2,2);g.pop()
    for i=1,4 do local a=i*math.pi/2;local d=18+3*spring
        line(g,c,alpha,2,math.cos(a)*d,math.sin(a)*d,math.cos(a)*(d+6),math.sin(a)*(d+6)) end
    g.setColor(1,0.95,0.7,alpha*hit*0.22);g.setLineWidth(1.4);g.circle("line",0,0,20+out(age/0.16)*16)
    line(g,c,alpha*out(age/0.055),2.2,-5,0,0,5,7,-6)
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

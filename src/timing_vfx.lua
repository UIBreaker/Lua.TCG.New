-- Authored timing accents; all geometry is deterministic and presentation-only.
local V={active={},limit=8}
V.profiles={
    normal={rank=0,color={.58,.72,.78},duration=.48,radius=42,shards=5},
    good={rank=1,color={.12,1,.65},duration=.50,radius=46,shards=4},
    perfect={rank=2,color={1,.78,.12},duration=.58,radius=60,shards=6},
    critical={rank=3,color={.20,.70,1},duration=.64,radius=72,shards=8},
    ultimate={rank=4,color={.80,.36,1},duration=.72,radius=86,shards=10},
    apex={rank=5,color={.72,.96,1},duration=.80,radius=100,shards=12},
    divine={rank=6,color={1,.30,.53},duration=.86,radius=110,shards=12},
    trap={rank=0,color={.92,.23,.26},duration=.56,radius=45,shards=8},
    riposte={rank=0,color={1,.39,.13},duration=.62,radius=48,shards=7},
    exposed={rank=0,color={1,.39,.13},duration=.62,radius=48,shards=7},
    timeout={rank=0,color={.56,.64,.70},duration=.50,radius=40,shards=6},
}
for grade,u in pairs(require("src.combat_timing").utility) do
    V.profiles[grade]={rank=3,color=u.color,duration=.60,radius=64,shards=6}
end
function V.clear() V.active={} end
function V.emit(kind,grade,x,y,options)
    options=options or {}
    local profile=V.profiles[grade] or V.profiles.normal
    local e={kind=kind,grade=grade,profile=profile,x=x or 630,y=y or 270,age=0,
        reduced=options.reducedMotion==true,mobile=options.mobile==true,audio=options.audio==true,
        railX=options.railX,railW=options.railW,chain=options.chain or 1,
        duration=kind=="confirm" and .42 or kind=="reflect" and profile.duration+.22 or profile.duration}
    if #V.active>=V.limit then table.remove(V.active,1) end
    V.active[#V.active+1]=e
    return e
end
function V.update(dt)
    for i=#V.active,1,-1 do
        local e=V.active[i];e.age=e.age+math.max(0,dt)
        local mistake=e.kind=="enemy_reflect" or e.kind=="break" and e.grade=="exposed"
        local contact=e.kind=="enemy_reflect" and .22 or .045
        if mistake and e.audio and not e.impactPlayed and e.age>=contact then
            e.impactPlayed=true;require("src.sound").play("damage_heavy",.72);require("src.sound").play("armor_loss",.82)
        end
        if e.kind=="reflect" and e.audio and not e.impactPlayed and e.age>=.22 then
            e.impactPlayed=true;require("src.timing_audio").play("attack",e.grade)
        end
        if e.age>=e.duration then table.remove(V.active,i) end
    end
end
function V.envelope(e)
    local p=math.min(1,e.age/e.duration)
    return (1-math.exp(-e.age*90))*(1-p)^1.6,p
end
-- Real-time phases shared by rendering, impact pauses and the return projectile.
function V.parryPose(e,t)
    t=t or e.age
    if e.reduced then return {y=0,sx=1,sy=1,angle=-.10,flash=.15} end
    local depth=7+e.profile.rank
    if t<.075 then
        local k=1-(1-math.min(1,t/.055))^3
        return {y=depth*k,sx=1+.15*k,sy=1-.22*k,angle=-.10+.25*k,flash=(1-math.min(1,t/.075))*.8}
    elseif t<.145 then
        local k=1-(1-(t-.075)/.07)^3
        return {y=depth-(depth+7)*k,sx=1.15-.22*k,sy=.78+.38*k,angle=.15-.35*k,flash=math.sin(k*math.pi)*.35}
    end
    local k=math.min(1,(t-.145)/.19);k=k*k*(3-2*k)
    return {y=-7*(1-k),sx=.93+.07*k,sy=1.16-.16*k,angle=-.20+.10*k,flash=0}
end
function V.returnTravel(age)
    local q=math.max(0,math.min(1,(age-.09)/.13))
    return q*q*q
end
function V.pause()
    for _,e in ipairs(V.active) do
        local contact=e.kind=="enemy_reflect" and .22 or e.kind=="break" and e.grade=="exposed" and .045
        if contact and not e.reduced and e.age>=contact and e.age<contact+.045 then return true end
        if not e.reduced and (e.kind=="block" or e.kind=="reflect") and e.profile.rank>=2 then
            local t=e.age
            if t>=.012 and t<.035+e.profile.rank*.005 then return true end
            if e.kind=="reflect" and t>=.226 and t<.255+e.profile.rank*.007 then return true end
        end
    end
    return false
end
function V.camera()
    local x,y=0,0
    for _,e in ipairs(V.active) do
        if not e.reduced then
            local contact=e.kind=="enemy_reflect" and .22 or e.kind=="break" and e.grade=="exposed" and .045
            local t=contact and e.age-contact or -1
            if t>=0 and t<.15 then
                local force=math.sin(t/.15*math.pi)*(1-t/.15)*5
                if force>math.abs(y) then x=-force*.3;y=force end
            end
            local t=e.age-(e.kind=="reflect" and .22 or 0)
            if (e.kind=="attack" or e.kind=="reflect") and t>0 and t<.20 then
                local force=e.profile.rank>=5 and 3.4 or e.profile.rank*.48
                local a=math.sin(t/.20*math.pi)*(1-t/.20)*force
                if math.abs(a)>math.abs(y) then x=math.sin(t*54)*a*.35;y=-a end
            end
            if (e.kind=="block" or e.kind=="reflect") and e.age<.11 then
                local a=math.sin(e.age/.11*math.pi)*(1-e.age/.11)*(1+e.profile.rank*.22)
                if math.abs(a)>math.abs(y) then x=-a*.22;y=a end
            end
        end
    end
    return x,y
end
local function color(c,a) love.graphics.setColor(c[1],c[2],c[3],a) end
-- One crisp stroke per accent: no halos, decorative rings or trailing copies.
local function stroke(points,c,alpha,width)
    color(c,alpha);love.graphics.setLineWidth(width);love.graphics.line(points)
end
local function blade(x,y,length,angle,c,a,width,core)
    local g=love.graphics
    g.push("all");g.translate(x,y);g.rotate(angle)
    g.setBlendMode("alpha")
    color(c,a)
    g.polygon("fill",-length,0,-length*.10,-width,length,0,length*.10,width*.65)
    g.setBlendMode("add");core=core or {1,1,1};g.setColor(core[1],core[2],core[3],a)
    g.polygon("fill",-length*.55,0,0,-width*.25,length*.83,0)
    g.pop()
end
local function sparks(e,x,y,t,a,count)
    local c=e.profile.color
    count=math.min(7,e.mobile and math.ceil(count*.55) or count)
    for i=1,count do
        local angle=i*2.399963+e.profile.rank*.4
        local d=5+(38+(i%4)*16)*t
        local sx=x+math.cos(angle)*d;local sy=y+math.sin(angle)*d*.72+t*t*36
        local length=math.max(0,(2+i%3)*(1-t/.35))
        if length>0 then
            if e.profile.rank>=5 then
                love.graphics.push("all");love.graphics.translate(sx,sy);love.graphics.rotate(angle+t*4)
                color(i%2==0 and {1,1,1} or c,a)
                love.graphics.polygon("fill",-length*1.5,0,0,-2,length,0,0,1.2)
                love.graphics.pop()
            else stroke({sx,sy,sx-math.cos(angle)*length,sy-math.sin(angle)*length},c,a,1.5) end
            if e.profile.rank>=3 and e.profile.rank<5 and i%3==0 then
                local h=length*(.7+.3*math.sin(t*42+i))
                love.graphics.setColor(1,1,1,a*.9)
                love.graphics.polygon("fill",sx,sy-h,sx+h*.25,sy,sx,sy+h,sx-h*.25,sy)
            end
        end
    end
end
local function shield(e,t,alpha,broken)
    local g=love.graphics;local rank=e.profile.rank;local c=e.profile.color
    local pose=V.parryPose(e,t)
    if e.kind=="reflect" then alpha=alpha*math.min(1,math.max(0,(.31-t)/.165)) end
    g.push("all");g.translate(e.x,430+(broken and 0 or pose.y));g.rotate(broken and 0 or pose.angle)
    if not broken then g.scale(pose.sx,pose.sy) end
    g.setBlendMode("alpha")
    require("ui.components.shield").draw(0,3,74,c,alpha,{
        broken=broken,partial=rank<=1 and not broken,flash=broken and 0 or pose.flash,
        split=e.reduced and 5 or math.min(23,t*78),tilt=e.reduced and .10 or t*.9})
    if require("src.combat_timing").utility[e.grade] and not broken then
        local snap=e.reduced and 1 or 1+.16*math.max(0,1-t/.10)
        require("ui.components.timing_utility").draw(e.grade,0,5,15*snap,c,alpha)
    end
    if not broken then
        -- The contact bites into the upper face, rather than showing a UI checkmark.
        local flash=e.reduced and .3 or math.max(0,1-t/.20)
        g.setBlendMode("add")
        blade(1,-14,rank>=5 and 16 or 11,-.45,c,alpha*flash,rank>=5 and 4 or 2.5)
    end
    g.pop()
    if not e.reduced and require("src.combat_timing").utility[e.grade] then
        local fade=math.max(0,1-t/.28);local snap=math.min(1,t/.15)
        if e.grade=="mend" then
            for side=-1,1,2 do
                local x=e.x+side*(35-17*snap)
                stroke({x,424,x-side*7,424},c,alpha*fade,2.5)
            end
        elseif e.grade=="reserve" then
            for i=-1,1 do
                local x=e.x+i*14;local y=397+snap*19
                color(c,alpha*fade);g.polygon("fill",x-2,y-3,x+2,y-3,x+3,y+2,x-1,y+3)
            end
        elseif e.grade=="rebound" then
            for side=-1,1,2 do
                local x=e.x+side*(18+snap*12);local y=415-snap*20
                stroke({x,y,x-side*5,y+5},c,alpha*fade,2)
            end
        end
        return
    end
    if not e.reduced then
        local fade=math.max(0,1-t/.26)
        local count=e.mobile and 3 or rank>=5 and 7 or 5
        for i=1,count do
            local side=i%2==0 and -1 or 1
            local vx=side*(75+i*14);local vy=-95-(i%3)*23
            local sx=e.x+vx*t;local sy=408+vy*t+t*t*190
            stroke({sx,sy,sx-vx*.022*fade,sy-vy*.022*fade},c,alpha*fade,rank>=5 and 2 or 1.5)
        end
    end
end
local function utilityImpact(e,x,y,t,alpha)
    if t<0 or t>.34 then return end
    local g=love.graphics;local c=e.profile.color
    local fade=math.min(1,math.max(0,(.34-t)/.12));local a=alpha*fade
    local snap=e.reduced and 1 or 1-(1-math.min(1,t/.055))^3
    local lead=e.reduced and 0 or (1-snap)
    local grade=e.grade
    g.push("all")
    if grade=="siphon" then
        -- One blood drop gathers small cuts inward, then sinks into the hit.
        y=y+(e.reduced and 0 or math.min(10,t*36))
        if not e.reduced then
            for i=-1,1,2 do local d=15+13*lead;stroke({x+i*d,y-8,x+i*(d-6),y-4},c,a*.8,2) end
        end
    elseif grade=="pierce" then
        x=x-16*lead
        if not e.reduced then
            for i=-1,1,2 do local dx=i*(8+snap*10);stroke({x+dx,y-8,x+dx+i*4,y-3},c,a*.8,2) end
        end
    elseif grade=="haste" then
        y=y-(e.reduced and 0 or snap*10)
        if not e.reduced then
            for i=-1,1,2 do stroke({x+i*19,y+8,x+i*19,y-4},c,a*.7,1.5) end
        end
    elseif grade=="mend" then
        if not e.reduced then
            for i=-1,1,2 do local d=18+8*lead;stroke({x+i*d,y,x+i*(d-5),y},c,a*.8,2) end
        end
    elseif grade=="reserve" then
        y=y-6*lead
        if not e.reduced then
            for i=-1,1 do g.setColor(c[1],c[2],c[3],a*.75);g.rectangle("fill",x+i*15-1,y-12-snap*(5+i%2*3),2.5,4) end
        end
    elseif grade=="rebound" then
        y=y+7*lead
        if not e.reduced then
            stroke({x-21,y+10,x-15,y+4},c,a*.8,2)
            stroke({x+16,y-11,x+22,y-17},c,a*.8,2)
        end
    end
    require("ui.components.timing_utility").draw(grade,x,y,(grade=="pierce" and 20 or 16)*(.86+.14*snap),c,a)
    local flash=e.reduced and 0 or math.max(0,1-t/.075)*a
    stroke({x-4,y,x+4,y},{1,1,1},flash,1.5)
    g.pop()
end
local function violetCut(e,length,a,t)
    local g=love.graphics;local w=3.8
    local lead=e.reduced and 0 or (1-math.min(1,t/.075))^2
    g.push("all");g.translate(e.x-14*lead,e.y+10*lead);g.rotate(-.68);g.setBlendMode("alpha")
    color(e.profile.color,a)
    -- One hooked, needle-thin cut; the pale cutting edge belongs to this same blade.
    g.polygon("fill",-length,3,-length*.25,-w,length*.76,-w*.25,length,-4,length*.23,w,-length*.64,w*.7)
    g.setBlendMode("add");g.setColor(.96,.77,1,a)
    g.polygon("fill",-length*.65,1,-length*.20,-1.1,length*.82,-1.4,length*.20,1)
    g.pop()
end
local function whiteCleave(e,length,a,t)
    local g=love.graphics
    local lead=e.reduced and 0 or (1-math.min(1,t/.065))^2
    g.push("all");g.translate(e.x,e.y-18*lead);g.rotate(-.10);g.setBlendMode("alpha")
    color({.30,.74,1},a)
    -- A broad descending cleaver with a blue steel bevel and a clean white face.
    g.polygon("fill",-2,-length,8,-length*.30,6,length*.46,-3,length,-7,length*.20,-6,-length*.37)
    g.setColor(1,1,1,a)
    g.polygon("fill",-2,-length,4,-length*.25,2,length*.45,-3,length,-4,length*.17,-3,-length*.36)
    if not e.reduced then
        local flash=math.max(0,1-t/.15)*a
        g.setBlendMode("add");g.setColor(.94,1,1,flash)
        -- A brief chip of light at contact, never an expanding ring or second slash.
        g.polygon("fill",-19,1,-5,-4,15,-1,5,5)
    end
    g.pop()
end
local function impact(e,t,alpha)
    if require("src.combat_timing").utility[e.grade] then utilityImpact(e,e.x,e.y,t,alpha);return end
    local p=e.profile;local rank=p.rank
    local endTime=rank>=5 and .32 or .28
    local fade=math.min(1,math.max(0,(endTime-t)/.14))
    local length=e.reduced and 22+rank*3 or p.radius*(.62+.18*math.min(1,t/.065))
    local a=math.min(1,alpha*1.35)*fade
    if fade>0 then
        if rank==6 then
            local lead=e.reduced and 0 or (1-math.min(1,t/.055))^2
            blade(e.x-12*lead,e.y-14*lead,length,-.94,p.color,a,7,{1,.90,.54})
        elseif rank==5 then whiteCleave(e,length,a,t)
        elseif rank==4 then violetCut(e,length,a,t)
        else blade(e.x,e.y,length,-.50,p.color,a,2+rank*.46) end
    end
    if not e.reduced then sparks(e,e.x,e.y,t,alpha,p.shards) end
end
local function miss(e,t,alpha)
    local x,y=e.x,e.y;local c={.57,.73,.84}
    local fade=math.max(0,1-t/.30)
    -- The single swipe passes beside the target, with no contact sparks.
    blade(x+78,y+10, e.reduced and 18 or 29,-.55,c,alpha*fade*.65,1.8)
    local mx,my=x+108,y-12
    stroke({mx-4,my-4,mx+4,my+4},c,alpha*.7,1.3)
    stroke({mx+4,my-4,mx-4,my+4},c,alpha*.7,1.3)
end
local function confirm(e,alpha,p)
    local g=love.graphics;local c=e.profile.color;local rank=e.profile.rank
    local x,y=e.x,e.y;local t=e.age
    if require("src.combat_timing").utility[e.grade] then
        local reach=e.reduced and 24 or 54*(1-(1-math.min(1,t/.07))^3)
        local left=e.railX or x-54;local right=left+(e.railW or 108)
        stroke({math.max(left,x-reach),y,math.min(right,x+reach),y},c,alpha*.8,2.5)
        require("ui.components.timing_utility").draw(e.grade,x,y,8,c,alpha)
        return
    end
    if e.reduced or rank<1 then
        stroke({x,y-6,x,y+6},c,alpha,2);return
    end
    local left=e.railX or x-185;local right=left+(e.railW or 370)
    local reach=rank>=5 and right-left or math.min(right-left,(14+rank*22)*(1+math.min(5,e.chain-1)*.12))
    local grow=1-(1-math.min(1,t/.13))^3
    local strength=math.max(0,1-t/.36)
    -- A light pulse lives on the rail itself; tiered rays escape upwards at the stop.
    for band=3,1,-1 do
        local h=(1+rank*.55)*band
        local l=math.max(left,x-reach*grow);local r=math.min(right,x+reach*grow)
        color(c,alpha*strength*(band==1 and .72 or .10))
        g.rectangle("fill",l,y-h,r-l,h*2)
    end
    stroke({math.max(left,x-reach*grow),y,math.min(right,x+reach*grow),y},{1,1,1},alpha*strength,rank>=4 and 2 or 1)
    local count=e.mobile and math.min(4,rank+2) or rank+3
    for i=1,count do
        local side=i%2==0 and -1 or 1
        local vx=side*(30+i*(rank>=4 and 22 or 10))
        local vy=-(28+rank*8+(i%3)*13)
        local sx=math.max(left-6,math.min(right+6,x+vx*t))
        local sy=y+vy*t+t*t*75
        local fade=math.max(0,1-t/.34)
        local tail=rank>=4 and .028 or .014
        stroke({sx,sy,sx-vx*tail*fade,sy-vy*tail*fade},c,alpha*fade,rank>=4 and 1.5 or 1.2)
        if rank>=3 and i%2==0 then
            local h=(rank>=5 and 3.4 or 2.3)*fade
            g.setColor(1,1,1,alpha*fade)
            g.polygon("fill",sx,sy-h,sx+h*.28,sy,sx,sy+h,sx-h*.28,sy)
        end
    end
    if rank==3 then
        require("ui.components.shield").draw(x,y-12,20,c,alpha*strength,{flash=strength*.5})
    elseif rank==6 then
        blade(x,y,20,-.65,c,alpha*math.max(0,1-t/.20),2.8,{1,.90,.5})
    elseif rank==4 then
        blade(x,y,15,-.85,c,alpha*math.max(0,1-t/.20),1.8,{.97,.77,1})
    else blade(x,y,5+rank*2,-math.pi/2,c,alpha*math.max(0,1-t/.20),1.3+rank*.25) end
end
local function mistake(e,alpha)
    local g=love.graphics;local reflected=e.kind=="enemy_reflect"
    local contact=reflected and .22 or .045
    local t=e.age-contact;local c=e.profile.color
    if reflected and e.age<contact then
        shield(e,e.age,alpha*.9,false)
        local travel=V.returnTravel(e.age)
        if travel>0 and not e.reduced then blade(e.x,e.y+(440-e.y)*travel,21,math.pi/2,c,alpha,5) end
        return
    end
    if t<0 then return end
    local fade=math.max(0,1-t/.30);local a=alpha*fade
    if not reflected then
        local hit={x=e.x,y=440,age=t,profile=e.profile,reduced=e.reduced,mobile=e.mobile}
        shield(hit,t,a,true)
    end
    local length=e.reduced and 20 or 30+10*math.min(1,t/.04)
    blade(e.x,440,length,-.92,c,a,6,{1,.83,.57})
    if not e.reduced then
        sparks(e,e.x,440,t,a,6)
        g.setColor(1,.9,.72,a*math.max(0,1-t/.07))
        g.polygon("fill",e.x-20,440,e.x-3,435,e.x+24,440,e.x+4,445)
    end
    local font=require("src.ui").fonts.small
    if font then
        g.setBlendMode("alpha");g.setFont(font)
        g.setColor(.06,.012,.009,alpha*.92);g.rectangle("fill",e.x-126,394,252,24,3,3)
        g.setColor(c[1],c[2],c[3],alpha);g.rectangle("fill",e.x-126,394,3,24)
        g.printf(reflected and "ĐỊCH PHẢN ĐÒN · DỘI 100%" or "VỠ THẾ · SÁT THƯƠNG ×5",e.x-120,398,240,"center")
        g.setBlendMode("add")
    end
end
function V.draw(layer)
    local g=love.graphics
    g.push("all");g.setShader();g.setBlendMode("add")
    for _,e in ipairs(V.active) do
        if (layer=="rail")== (e.kind=="confirm") then
            local alpha,p=V.envelope(e)
            if e.kind=="confirm" then confirm(e,alpha,p)
            elseif e.kind=="enemy_reflect" or e.kind=="break" and e.grade=="exposed" then mistake(e,alpha)
            elseif e.kind=="miss" then miss(e,e.age,alpha)
            elseif e.kind=="break" then shield(e,e.age,alpha,true)
            elseif e.kind=="block" then shield(e,e.age,alpha,false)
            elseif e.kind=="reflect" then
                shield(e,e.age,alpha*.85,false)
                local travel=V.returnTravel(e.age)
                if travel>0 and e.age<.22 and not e.reduced then
                    local tip=440+(e.y-440)*travel
                    local length=(e.profile.rank>=5 and 30 or 20)*(0.4+travel*.6)
                    local tail=math.min(440,tip+length)
                    stroke({e.x,tail,e.x,tip},e.profile.color,alpha,e.profile.rank>=5 and 6 or 3)
                    blade(e.x,tip,e.profile.rank>=5 and 16 or 10,-math.pi/2,e.profile.color,alpha,e.profile.rank>=5 and 5 or 2.5)
                end
                if e.age>=.22 then
                    local t=e.age-.22
                    local contactAlpha=(1-math.exp(-t*90))*(1-math.min(1,t/e.profile.duration))^1.6
                    impact(e,t,contactAlpha)
                end
            else impact(e,e.age,alpha) end
        end
    end
    g.pop()
end
return V

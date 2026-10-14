local Potions=require("src.potions")
local Lighting=require("render.lighting")
local F={active={}}
local colors={heal={.26,1,.53},armor={.26,.66,1},speed={.18,.91,1},rest={.64,1,.74}}
for _,d in ipairs(Potions.definitions) do colors[d.kind]=d.color end
local artIds={heal="healing_potion",armor="armor_potion_large",speed="cons_speed_large",rest="cons_bed"}
for _,d in ipairs(Potions.definitions) do artIds[d.kind]=d.id end
local tau=math.pi*2
local function hash(i,s)
    local n=math.sin(i*127.1+s*311.7)*43758.5453
    return n-math.floor(n)
end

function F.update(game,dt,reducedMotion,state)
    if state=="menu" or state=="BLIND_SELECT" then F.active={};game.potionFeedback={} end
    for _,event in ipairs(game.potionFeedback or {}) do
        for i=#F.active,1,-1 do
            local previous=F.active[i]
            if previous.kind==event.kind then table.remove(F.active,i)
            elseif previous.age>.45 then previous.life=math.min(previous.life,previous.age+.3) end
        end
        event.age=0;event.life=2.2;event.reduced=reducedMotion
        event.reactive=event.target and (event.kind=="accuracy" or event.kind=="evasion")
            or event.kind=="gold_blood" and (event.value or 0)>0
        event.x=event.target and (event.target.screenX or 640) or 640
        event.y=event.target and 305 or 438
        if event.kind=="evasion" then event.x=640;event.y=448 end
        event.anchors={}
        for _,card in ipairs(event.cards or {}) do event.anchors[#event.anchors+1]={card=card} end
        event.particles={}
        local seed=0;for i=1,#event.kind do seed=seed+event.kind:byte(i) end
        for i=1,reducedMotion and 12 or 54 do
            event.particles[i]={angle=hash(i,seed)*tau,speed=28+hash(i,seed+1)*125,
                size=1+hash(i,seed+2)*2.7,delay=hash(i,seed+3)*.42,
                life=.75+hash(i,seed+4)*.9,phase=hash(i,seed+5)*tau}
        end
        Lighting.flash(event.x,event.y,colors[event.kind] or colors.heal,.22,.55,220)
        F.active[#F.active+1]=event
        if #F.active>6 then table.remove(F.active,1) end
    end
    game.potionFeedback={}
    for i=#F.active,1,-1 do
        local e=F.active[i];e.age=e.age+math.min(dt,.1)
        if e.age>=e.life then table.remove(F.active,i) end
    end
end

local function glow(x,y,r,c,a)
    Lighting.glow(x,y,r,c,a)
end
local function stroke(points,c,a,width)
    local g=love.graphics
    for _,layer in ipairs({{5,.07},{2.4,.21},{1,.82}}) do
        g.setLineWidth(width*layer[1]);g.setColor(c[1],c[2],c[3],a*layer[2]);g.line(points)
    end
    g.setLineWidth(math.max(.7,width*.32));g.setColor(1,.97,.89,a*.88);g.line(points)
end
local function ring(x,y,r,c,a,sy,start,span)
    local points={}
    for i=0,42 do
        local t=(start or 0)+(span or tau)*i/42
        points[#points+1]=x+math.cos(t)*r;points[#points+1]=y+math.sin(t)*r*(sy or 1)
    end
    stroke(points,c,a,1.5)
end
local function spark(x,y,size,c,a)
    glow(x,y,size*5,c,a*.38)
    local g=love.graphics;g.setColor(c[1],c[2],c[3],a)
    g.polygon("fill",x-size*.4,y,x,y-size*2,x+size*.4,y,x,y+size*2)
    g.setColor(1,1,1,a);g.circle("fill",x,y,size*.4)
end
local function pose(anchor)
    local card=anchor.card
    return (card.visualX or card.x or 590)+50,(card.visualY or card.y or 480)+72,card.visualAngle or 0
end
local function spiral(x,y,r,age,c,a,vertical)
    local points={}
    for i=0,56 do
        local t=i/56;local angle=t*tau*2.1-age*3
        points[#points+1]=x+math.cos(angle)*r*(.25+t*.7)
        points[#points+1]=y+(vertical and 42-t*118 or math.sin(angle)*r*.48)
    end
    stroke(points,c,a,1.5)
end
local function shield(x,y,c,a,r)
    stroke({x-r*.7,y-r*.78,x+r*.7,y-r*.78,x+r*.65,y+r*.22,x,y+r*.82,
        x-r*.65,y+r*.22,x-r*.7,y-r*.78},c,a,2)
    stroke({x-r*.43,y-r*.49,x+r*.43,y-r*.49,x+r*.37,y+r*.13,x,y+r*.51,
        x-r*.37,y+r*.13,x-r*.43,y-r*.49},c,a*.65,1)
end

local function motif(e,c,a)
    local g=love.graphics;local t=e.reduced and .55 or e.age
    local burst=1-math.exp(-e.age*6)
    local x,y=e.x,e.y
    if #e.anchors==0 then glow(x,y,145,c,a*.4);glow(x,y,48,c,a*.45) end
    if e.kind=="accuracy" then
        ring(x,y,58+22*(1-burst),c,a)
        ring(x,y,92,c,a*.65,1,t*1.2,math.pi*1.45)
        ring(x,y,110,c,a*.45,1,-t*1.5,math.pi*.7)
        for i=0,3 do
            local angle=i*math.pi/2
            stroke({x+math.cos(angle)*38,y+math.sin(angle)*38,x+math.cos(angle)*95,y+math.sin(angle)*95},c,a,2)
        end
        spark(x,y,7,c,a)
    elseif e.kind=="heal" or e.kind=="rest" then
        ring(x,y+30,85,c,a,.3,t,math.pi*1.8)
        spiral(x,y,63,t,c,a,true)
        for i=1,5 do
            local angle=t*.6+i*tau/5;local lx=x+math.cos(angle)*65;local ly=y+math.sin(angle)*35-28
            glow(lx,ly,24,c,a*.7)
            g.setColor(c[1],c[2],c[3],a*.7);g.ellipse("fill",lx,ly,5,12)
            stroke({lx,ly+7,lx,ly-7},c,a,1)
        end
        if e.kind=="rest" then ring(x,y-32,30,{1,.88,.5},a,1,.3,math.pi*1.5)
        else stroke({x-18,y-15,x+18,y-15},c,a,4);stroke({x,y-33,x,y+3},c,a,4) end
    elseif e.kind=="armor" then
        shield(x,y,c,a,62);ring(x,y,96,c,a*.7,1,t*.45,tau*.87)
        for i=0,5 do
            local angle=i*tau/6+t*.25
            spark(x+math.cos(angle)*96,y+math.sin(angle)*96,3,c,a)
        end
    elseif e.kind=="armor_break" then
        local r=30+burst*85
        ring(x,y,r,c,a*.65,.55);ring(x,y,r*.65,c,a*.5,.55)
        for i=1,12 do
            local angle=i*tau/12;local d=20+burst*(30+hash(i,4)*90)
            local px=x+math.cos(angle)*d;local py=y+math.sin(angle)*d*.8+t*t*25
            glow(px,py,18,c,a*.55)
            g.push();g.translate(px,py);g.rotate(angle+t*(i%2==0 and 1 or -1))
            g.setColor(c[1],c[2],c[3],a*.8);g.polygon("fill",-5,-11,8,-2,1,9)
            g.setColor(1,.92,.65,a);g.line(-4,-9,6,-2);g.pop()
        end
        stroke({x-24,y-41,x-5,y-12,x-21,y+6,x,y+34},c,a,3)
        stroke({x+30,y-40,x+5,y-8,x+23,y+14},c,a,3)
    elseif e.kind=="evasion" then
        for i=-1,1 do
            local offset=i*(28+burst*54)
            glow(x+offset,y,75,c,a*(i==0 and .35 or .22))
            ring(x+offset,y,65,c,a*(i==0 and .6 or .35),1.12,t+i*.8,math.pi*1.4)
        end
        stroke({x-120,y+35,x-52,y-5,x+5,y-28,x+85,y-36,x+130,y-25},c,a,2)
    elseif e.kind=="gold_blood" then
        local count=e.reduced and 5 or 10
        for i=1,count do
            local p=math.max(0,math.min(1,(t-(i-1)*.055)/1.2))
            local cx,cy
            if e.reactive then
                cx=x+(440-x)*p+math.sin(p*math.pi)*(i-count/2)*13
                cy=y+(33-y)*p-math.sin(p*math.pi)*70
            else
                cx=x+math.cos(i*tau/count+t*.55)*82
                cy=y+math.sin(i*tau/count+t*.55)*35-t*18
            end
            glow(cx,cy,24,c,a*.6);g.setColor(.85,.42,.05,a);g.ellipse("fill",cx,cy,7,10)
            g.setColor(1,.9,.46,a);g.setLineWidth(2);g.ellipse("line",cx,cy,6,8)
            spark(cx-2,cy-4,1.6,c,a)
        end
        spiral(x,y,58,t,{1,.26,.2},a*.7,false)
    elseif e.kind=="slow" then
        ring(x,y+38,90,c,a,.34);ring(x,y,83,c,a*.8,1,-t*.5,math.pi*1.6)
        for i=0,5 do
            local angle=i*tau/6;local dx,dy=math.cos(angle),math.sin(angle)
            stroke({x+dx*27,y+dy*27,x+dx*58,y+dy*58},c,a,2)
            for _,side in ipairs({-1,1}) do
                local sx,sy=x+dx*45,y+dy*45
                stroke({sx,sy,sx-dx*11-dy*side*11,sy-dy*11+dx*side*11},c,a,1.3)
            end
            spark(x+dx*83,y+dy*83,3,c,a)
        end
    elseif e.kind=="damage" or e.kind=="empower" or e.kind=="speed" or e.kind=="draw" then
        local previous
        for i,anchor in ipairs(e.anchors) do
            local cx,cy,angle=pose(anchor)
            glow(cx,cy,100,c,a*.32)
            if e.kind=="draw" then
                local progress=math.min(1,t*2)
                local points={}
                for j=0,20 do
                    local p=j/20*progress
                    points[#points+1]=1167+(cx-1167)*p
                    points[#points+1]=614+(cy-614)*p-math.sin(p*math.pi)*(70+i*6)
                end
                stroke(points,c,a*.8,2);ring(cx,cy+58,52,c,a,.27)
                spark(cx,cy-70,5,c,a)
            else
                g.push();g.translate(cx,cy);g.rotate(angle)
                for _,side in ipairs({-1,1}) do
                    local points={}
                    for j=0,18 do
                        local p=j/18
                        points[#points+1]=side*(48+math.sin(p*8-t*5)*6)
                        points[#points+1]=73-p*152
                    end
                    stroke(points,c,a,2)
                    glow(side*51,-26,40,c,a*.4);spark(side*47,-72,4,c,a)
                end
                if e.kind=="damage" then
                    for k=1,3 do
                        local vy=51-k*25-t*15
                        stroke({-15,vy+10,0,vy-8,15,vy+10},c,a*(1-k*.1),2)
                    end
                elseif e.kind=="empower" then
                    spiral(0,-8,37,t,c,a*.8,true)
                else
                    for k=1,4 do stroke({-45,40-k*20,0,28-k*20,45,40-k*20},c,a*.65,1.5) end
                end
                g.pop()
            end
            if previous and e.kind=="empower" then
                stroke({previous.x,previous.y-85,(previous.x+cx)/2,cy-104,cx,cy-85},c,a*.65,1.4)
            end
            previous={x=cx,y=cy}
        end
    end
end

function F.draw(UI,game,activeState)
    local g=love.graphics;g.push("all")
    local state=game.potionCombat or {};local labels={}
    for _,d in ipairs(Potions.definitions) do
        if state[d.kind] or d.kind=="damage" and state.damageCards or d.kind=="empower" and state.multCards then
            labels[#labels+1]=d.kind=="accuracy" and ("TRÚNG 100% · "..(state.accuracyTurns or 1).." LƯỢT") or d.kind=="evasion" and ("NÉ "..(state.evasionTurns or 1).." LƯỢT")
                or d.kind=="damage" and "TĂNG ST / LÁ" or d.kind=="empower" and "TĂNG CH / LÁ" or "MÁU → VÀNG"
        end
    end
    if #labels>0 and (activeState=="playing" or activeState=="scoring") then
        g.setFont(UI.fonts.tiny);g.setColor(.025,.031,.043,.9);g.rectangle("fill",330,425,590,24,5,5)
        g.setColor(.99,.86,.53,1);g.printf(table.concat(labels,"  ·  "),338,430,574,"center")
    end
    g.setBlendMode("add","alphamultiply")
    if activeState=="playing" or activeState=="scoring" then
        for _,enemy in ipairs(require("src.enemy_group").members(game)) do
            local slow=(enemy.combatBuffs or {}).slow
            if slow and enemy.hp>0 then
                local x=enemy.screenX or 640
                ring(x,363,62,colors.slow,.32,.28)
                glow(x,340,95,colors.slow,.12)
            end
        end
    end
    for _,e in ipairs(F.active) do
        local p=e.age/e.life
        local alpha=math.min(1,e.age/.1)*math.min(1,(1-p)*2.8)
        local c=colors[e.kind] or colors.heal
        motif(e,c,alpha)
        for _,particle in ipairs(e.particles) do
            local age=e.age-particle.delay
            if age>=0 and age<particle.life then
                local fade=(1-age/particle.life)^2*alpha
                local distance=e.reduced and 45 or particle.speed*age
                local x=e.x+math.cos(particle.angle)*distance
                local y=e.y+math.sin(particle.angle)*distance*.7-age*22
                if #e.anchors>0 then
                    local cx,cy=pose(e.anchors[math.floor(particle.phase/tau*#e.anchors)+1])
                    x=cx+math.cos(particle.angle)*distance*.6;y=cy+math.sin(particle.angle)*distance*.8-age*35
                end
                spark(x,y,particle.size,c,fade)
            end
        end
        if not e.reactive and e.age<.52 then
            local t=e.reduced and 1 or math.min(1,e.age/.4)
            local x=(e.sourceX or 1160)*(1-t)+e.x*t
            local y=(e.sourceY or 220)*(1-t)+e.y*t-(e.reduced and 0 or math.sin(t*math.pi)*80)
            glow(x,y,45,c,alpha*.45*(1-t))
            local image=UI.getConsumableImage({id=artIds[e.kind]})
            if image then
                g.setBlendMode("alpha");g.setColor(1,1,1,alpha*(1-t));UI.CardFrame.image(image,x-19,y-28,38,56)
                g.setBlendMode("add","alphamultiply")
            end
        end
    end
    g.setBlendMode("alpha")
    for _,e in ipairs(F.active) do
        local a=math.min(1,e.age/.1)*math.min(1,(1-e.age/e.life)*2.8)
        local c=colors[e.kind] or colors.heal
        local y=e.y-116
        g.setColor(.015,.025,.038,.8*a);g.rectangle("fill",e.x-220,y,440,30,5,5)
        g.setColor(c[1],c[2],c[3],a);g.setFont(UI.fonts.small);g.printf(e.label or "THUỐC",e.x-213,y+5,426,"center")
    end
    g.pop()
end
return F

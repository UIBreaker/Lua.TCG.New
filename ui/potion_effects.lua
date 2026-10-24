local Potions=require("src.potions")
local Lighting=require("render.lighting")
local Motion=require("src.motion")
local F={active={}}
local colors={heal={.26,1,.53},armor={.26,.66,1},speed={.18,.91,1},rest={.64,1,.74},rebirth={1,.74,.29},rank_drain={.77,.43,1}}
for _,d in ipairs(Potions.definitions) do colors[d.kind]=d.color end
local artIds={heal="healing_potion",armor="armor_potion_large",speed="cons_speed_large",rest="cons_bed"}
for _,d in ipairs(Potions.definitions) do artIds[d.kind]=d.id end
local tau=math.pi*2
local function hash(i,s)
    local n=math.sin(i*127.1+s*311.7)*43758.5453
    return n-math.floor(n)
end

local function clamp(t) return math.max(0,math.min(1,t)) end
function F.pose(e)
    local arrival=e.contactAt or (e.reactive and 0 or .42)
    local t=clamp(e.age/.42);local p=Motion.settle(t,1)
    local x,y=e.x,e.y
    if not e.reduced then
        x=(e.sourceX or 1160)+(x-(e.sourceX or 1160))*p
        y=(e.sourceY or 220)+(y-(e.sourceY or 220))*p-math.sin(t*math.pi)^2*36
    end
    local contact=math.max(0,e.age-arrival)
    return {x=x,y=y,travel=t,scale=e.reduced and 1 or 1-.55*p,
        iconAlpha=e.reduced and 0 or 1-clamp((t-.72)/.28),contact=contact,
        alpha=e.age>=arrival and Motion.settle(contact,.12)*clamp((e.life-e.age)/.45) or 0}
end
function F.update(game,dt,reducedMotion,state,fast)
    if state=="menu" or state=="BLIND_SELECT" then F.active={};game.potionFeedback={} end
    for _,event in ipairs(game.potionFeedback or {}) do
        for i=#F.active,1,-1 do
            local previous=F.active[i]
            if previous.kind==event.kind then table.remove(F.active,i)
            elseif previous.age>.45 then previous.life=math.min(previous.life,previous.age+.3) end
        end
        event.age=0;event.reduced=reducedMotion
        if event.kind=="discard" then event.combat=game.abilityCombat end
        event.reactive=event.kind=="discard" or event.kind=="rebirth" or event.kind=="rank_drain" or event.target and (event.kind=="accuracy" or event.kind=="evasion")
            or event.kind=="gold_blood" and (event.value or 0)>0
        event.contactAt=(event.reactive or reducedMotion) and 0 or .42
        event.life=event.contactAt+(event.kind=="discard" and 3.2 or 1.5)
        event.x=event.target and (event.target.screenX or 640) or 640
        event.y=event.target and 305 or 438
        if event.kind=="evasion" then event.x=640;event.y=448 end
        event.anchors={}
        for _,card in ipairs(event.cards or {}) do event.anchors[#event.anchors+1]={card=card} end
        event.particles={}
        local seed=0;for i=1,#event.kind do seed=seed+event.kind:byte(i) end
        for i=1,event.kind=="discard" and 0 or reducedMotion and 12 or 54 do
            event.particles[i]={angle=hash(i,seed)*tau,speed=28+hash(i,seed+1)*125,
                size=1+hash(i,seed+2)*2.7,delay=hash(i,seed+3)*.42,
                life=.75+hash(i,seed+4)*.9,phase=hash(i,seed+5)*tau}
        end
        F.active[#F.active+1]=event
        if #F.active>6 then table.remove(F.active,1) end
    end
    game.potionFeedback={}
    for i=#F.active,1,-1 do
        local e=F.active[i];e.age=e.age+math.min(dt,.05)*(fast and 2 or 1);e.reduced=reducedMotion
        if not e.contacted and e.age>=e.contactAt then
            e.contacted=true
            if e.kind~="discard" and e.kind~="speed" then Lighting.flash(e.x,e.y,colors[e.kind] or colors.heal,reducedMotion and .05 or .14,.36,160) end
        end
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
    local s=require("src.card_physics").getState(card)
    if s and s.ox then return s.ox+s.a*s.w/2+s.c*s.h/2,s.oy+s.b*s.w/2+s.d*s.h/2,card.visualAngle or 0 end
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
local function motif(e,c,a)
    local g=love.graphics;local t=e.reduced and .55 or math.max(0,e.age-e.contactAt)
    local burst=e.reduced and 1 or Motion.settle(t,.36)
    local x,y=e.x,e.y
    if #e.anchors==0 and e.kind~="armor" and e.kind~="armor_break" then glow(x,y,145,c,a*.4);glow(x,y,48,c,a*.45) end
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
    elseif e.kind=="rank_drain" then
        ring(x,y,100-burst*55,c,a,2,-t,tau*.88)
        spiral(x,y,68,-t,c,a,true)
        for i=1,2 do
            local dx=(i*2-3)*29;local dy=t*55
            stroke({x+dx,y-35+dy,x+dx+12,y-18+dy,x+dx,y+dy,x+dx-12,y-18+dy,x+dx,y-35+dy},c,a,2)
        end
    elseif e.kind=="rebirth" then
        ring(x,y,52+burst*65,c,a,2,-t,tau*.88)
        ring(x,y,42,c,a*.85,2,t*1.5,tau*.72)
        spiral(x,y,78,t,c,a,true)
        glow(x,y,32,c,a*.8)
        for i=1,8 do local angle=i*tau/8+t*.4;spark(x+math.cos(angle)*72,y+math.sin(angle)*88,5,c,a) end
    elseif e.kind=="armor" then
        require("ui.components.shield").draw(x,y,110,c,a)
        if not e.reduced then
            for i=1,3 do
                local dx=(i-2)*21;local fade=math.max(0,1-t/.30)
                spark(x+dx,y-30-t*20,2,c,a*fade)
            end
        end
    elseif e.kind=="armor_break" then
        require("ui.components.shield").draw(x,y,110,c,a,{
            broken=true,split=e.reduced and 7 or math.min(27,t*80),tilt=e.reduced and .1 or t*.9})
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
        local presentation=F.pose(e)
        local alpha=presentation.alpha
        local c=colors[e.kind] or colors.heal
        if alpha>0 and e.kind~="discard" and e.kind~="speed" then
            motif(e,c,alpha)
            for _,particle in ipairs(e.particles) do
                local age=e.age-e.contactAt-particle.delay
                if age>=0 and age<particle.life then
                    local fade=(1-age/particle.life)^2*alpha
                    local distance=e.reduced and 45 or particle.speed*age
                    local x=e.x+math.cos(particle.angle)*distance
                    local y=e.y+math.sin(particle.angle)*distance*.7-(e.reduced and 0 or age*22)
                    if #e.anchors>0 then
                        local cx,cy=pose(e.anchors[math.floor(particle.phase/tau*#e.anchors)+1])
                        x=cx+math.cos(particle.angle)*distance*.6;y=cy+math.sin(particle.angle)*distance*.8-(e.reduced and 0 or age*35)
                    end
                    spark(x,y,particle.size,c,fade)
                end
            end
        end
        if not e.reactive and presentation.iconAlpha>0 then
            local x,y=presentation.x,presentation.y
            g.push("all");g.setBlendMode("alpha");g.translate(x,y);g.scale(presentation.scale)
            local item=e.sourceItem or {id=artIds[e.kind]}
            local w,h=e.sourceW or 38,e.sourceH or 56
            UI.Polish.dissolve(UI,-w/2,-h/2,w,h,1-presentation.iconAlpha,c,function(ix,iy,iw,ih)
                UI.Polish.renderItem(UI,item,ix,iy,iw,ih)
            end)
            g.pop()
        end
    end
    g.setBlendMode("alpha")
    for _,e in ipairs(F.active) do
        if e.kind=="discard" then require("ui.discard_effects").draw(UI,e,game,activeState)
        else
            local a=F.pose(e).alpha
            local c=colors[e.kind] or colors.heal
            local y=e.y-116
            g.setColor(.015,.025,.038,.8*a);g.rectangle("fill",e.x-220,y,440,30,5,5)
            g.setColor(c[1],c[2],c[3],a);g.setFont(UI.fonts.small);g.printf(e.label or "THUỐC",e.x-213,y+5,426,"center")
        end
    end
    g.pop()
end
return F

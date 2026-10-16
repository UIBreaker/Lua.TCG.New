local Visual=require("config.visual_config")
local Rarities=require("config.reward_loot").rarities
local E={}
local purple,gold={.69,.39,1},{1,.79,.32}

function E.profile(reward)
    local rarity=Rarities[reward.rarity or (reward.item and reward.item.rarity)] or Rarities.common
    local kind,level,color="common",rarity.strength,rarity.color
    if reward.type=="VOID_TICKET" or reward.kind=="ticket" then
        local amount=reward.amount or 1
        level=amount==100 and 6 or amount>=75 and 5 or amount>=50 and 4 or amount>=25 and 3 or amount>=10 and 2 or 1
        return {kind="ticket",level=level,amount=amount,jackpot=amount==100,color=amount==100 and gold or purple,
            label=amount==100 and "JACKPOT · 100 VÉ" or ({"TÍN HIỆU HƯ KHÔNG","DÒNG VÉ HƯ KHÔNG","CỘNG HƯỞNG HƯ KHÔNG","BÃO VÉ HƯ KHÔNG","ĐẠI TIỆC HƯ KHÔNG"})[level],
            sound=({"card_activate","mult_pop","xmult_boom","round_win","round_win","jackpot"})[level],
            pitch=1.12-level*.04,particles=8+level*8,anticipation=.20+level*.06,
            hold=amount==100 and 2.35 or .24+level*.14,duration=amount==100 and 2.35 or .50+level*.18,
            gachaStrength=amount==100 and 9 or level+2}
    end
    if reward.type=="GOLD" or reward.kind=="gold" then kind,color="gold",gold
    elseif reward.type=="CHEST" or reward.packType or reward.kind=="pack" then kind="chest"
    elseif level>=3 then kind="rare" end
    return {kind=kind,level=level,color=color,
        label=kind=="gold" and "VÀNG THƯỞNG" or kind=="chest" and "RƯƠNG KHAI MỞ" or rarity.label,
        sound=kind=="gold" and "coin" or kind=="chest" and "reward_chest_open" or kind=="rare" and "reward_rare_reveal" or "reward_loot_reveal",
        pitch=kind=="gold" and 1.15 or 1,particles=kind=="common" and 4 or 8+level*4,
        anticipation=kind=="gold" and .12 or kind=="chest" and .30+level*.045 or kind=="rare" and .20+level*.045 or .14,
        hold=kind=="common" and .05 or kind=="gold" and .08 or kind=="chest" and .24 or .16,
        duration=kind=="common" and .45 or kind=="gold" and .48 or .60+level*.05}
end

local mesh
local function glow(x,y,rx,ry,color,alpha)
    local g=love.graphics
    if not mesh then
        local vertices={{0,0,.5,.5,1,1,1,1}}
        for i=0,40 do local a=i*math.pi/20;vertices[#vertices+1]={math.cos(a),math.sin(a),0,0,1,1,1,0} end
        mesh=g.newMesh(vertices,"fan","static")
    end
    g.setColor(color[1],color[2],color[3],alpha);g.draw(mesh,x,y,0,rx,ry)
end
local function tint(c,a) love.graphics.setColor(c[1],c[2],c[3],a) end
local function diamond(x,y,size,color,alpha)
    local g=love.graphics;tint(color,alpha);g.polygon("fill",x,y-size,x+size*.55,y,x,y+size,x-size*.55,y)
end

-- All paths are deterministic geometry; presentation never rolls gameplay RNG.
function E.drawSlot(p,x,y,age,anticipating,time)
    if not Visual.enabled then return end
    local g=love.graphics
    local progress=math.max(0,math.min(1,age/p.duration))
    local alpha=anticipating and .30 or (1-progress)^(p.kind=="ticket" and .7 or 1.4)
    if alpha<=0 then return end
    local low=Visual.quality=="LOW"
    local travel=anticipating and .1 or progress
    g.push("all");g.setBlendMode("add")
    glow(x,y,55+p.level*10,78+p.level*8,p.color,alpha*.27)
    g.setLineWidth(1.3)
    if p.kind=="common" then
        tint(p.color,alpha*.65);g.ellipse("line",x,y+48,28+travel*36,8+travel*9)
        for i=1,4 do local a=i*math.pi/2+.4;diamond(x+math.cos(a)*(30+travel*22),y+math.sin(a)*55,3,p.color,alpha*.7) end
    elseif p.kind=="gold" then
        for i=1,low and 5 or 10 do
            local a=i*2.399;local radius=20+travel*(38+i*3)
            local px,py=x+math.cos(a)*radius,y+math.sin(a)*radius*.5-travel*28
            tint(gold,alpha*.8);g.ellipse("fill",px,py,3+math.abs(math.sin(time*5+i))*3,7)
            g.setColor(1,.95,.65,alpha*.8);g.ellipse("line",px,py,3,5)
        end
        tint(gold,alpha*.6);g.ellipse("line",x,y+58,25+travel*80,8+travel*21)
    elseif p.kind=="chest" then
        for i=-1,1 do
            tint(p.color,alpha*.12)
            g.polygon("fill",x+i*15-4,y+42,x+i*15+4,y+42,x+i*52+20,y-116,x+i*52-20,y-116)
        end
        tint(p.color,alpha*.75);g.ellipse("line",x,y+58,22+travel*100,7+travel*26)
        for i=1,low and 6 or 12 do
            local a=i*2.399;local radius=26+travel*76
            diamond(x+math.cos(a)*radius,y+math.sin(a)*radius*.5-travel*25,4,p.color,alpha)
        end
    elseif p.kind=="rare" then
        local sides=4+p.level*2
        for i=1,sides do
            local a=i*math.pi*2/sides+time*.28
            local radius=48+travel*65
            tint(p.color,alpha*.15)
            g.polygon("fill",x+math.cos(a-.06)*22,y+math.sin(a-.06)*22,x+math.cos(a)*radius,y+math.sin(a)*radius,x+math.cos(a+.06)*22,y+math.sin(a+.06)*22)
            diamond(x+math.cos(a)*radius,y+math.sin(a)*radius,4,p.color,alpha*.8)
        end
        tint(p.color,alpha*.6);g.circle("line",x,y,24+travel*65)
    else
        if p.level>=4 then
            glow(x,y,120+p.level*4,130,purple,alpha*.32)
            for i=1,2 do
                local a=time*.8+i*math.pi;local radius=78+p.level*7
                tint(i==1 and gold or purple,alpha*.85);g.setLineWidth(2)
                g.arc("line","open",x,y,radius,a,a+math.pi*.65)
                diamond(x+math.cos(a)*radius,y+math.sin(a)*radius,5,i==1 and gold or purple,alpha)
            end
        end
        for ring=1,low and 2 or math.min(4,p.level+1) do
            local radius=45+ring*12+travel*26
            tint(ring%2==0 and gold or purple,alpha*(.65-ring*.08))
            g.push();g.translate(x,y);g.rotate(time*(ring%2==0 and -.8 or .7)+ring*.4)
            g.ellipse("line",0,0,radius,radius*.46);g.pop()
        end
        if p.level>=3 then
            for i=1,p.level+2 do
                local a=i*math.pi*2/(p.level+2)+time*.65;local radius=74+travel*36
                tint(p.color,alpha*.6);g.setLineWidth(1.4)
                g.line(x+math.cos(a)*30,y+math.sin(a)*30,x+math.cos(a+.07)*radius*.65,y+math.sin(a+.07)*radius*.65,
                    x+math.cos(a-.04)*radius,y+math.sin(a-.04)*radius)
            end
        end
        if Visual.effects.particles then
            for i=1,low and 6 or 6+p.level*3 do
                local a=i*2.399+time*.18;local radius=35+travel*(40+i*2)
                g.push();g.translate(x+math.cos(a)*radius,y+math.sin(a)*radius*.65-travel*28);g.rotate(a+travel)
                tint(i%3==0 and gold or purple,alpha*.8);g.rectangle("line",-3,-6,6,12,1);g.pop()
            end
        end
    end
    g.pop()
end

function E.counter(p,age,x,y,fonts)
    if p.kind~="ticket" then return end
    local progress=math.min(1,math.max(0,age/(.22+p.level*.12)))
    local amount=math.min(p.amount,math.max(1,math.floor(p.amount*(1-(1-progress)^3)+.001)))
    local g=love.graphics;g.push("all")
    g.setColor(.025,.015,.055,.94);g.rectangle("fill",x-42,y-13,84,26,6)
    tint(p.color,.8);g.setLineWidth(1);g.rectangle("line",x-42,y-13,84,26,6)
    g.setFont(fonts.medium);g.setColor(1,.94,1);g.printf("+"..amount,x-42,y-11,84,"center")
    g.pop()
end

function E.jackpot(p,age,width,height,fonts)
    if not p.jackpot or not Visual.enabled or age<0 or age>=p.duration then return end
    local g=love.graphics
    local alpha=math.min(1,age/.12,(p.duration-age)/.35)
    local cx,cy=width/2,height/2-20
    local bloom=1-math.exp(-age*7)
    g.push("all")
    g.setColor(.009,.004,.025,alpha*.86);g.rectangle("fill",0,0,width,height)
    g.setBlendMode("add")
    glow(cx,cy,430,300,purple,alpha*.43)
    glow(cx,cy,270,210,gold,alpha*.23)
    local rays=Visual.quality=="LOW" and 12 or 28
    for i=1,rays do
        local a=i*math.pi*2/rays+age*.11;local radius=(220+i%4*45)*bloom
        tint(i%3==0 and purple or gold,alpha*.13)
        g.polygon("fill",cx+math.cos(a-.015)*70,cy+math.sin(a-.015)*70,cx+math.cos(a)*radius,cy+math.sin(a)*radius,
            cx+math.cos(a+.015)*70,cy+math.sin(a+.015)*70)
    end
    for i=1,3 do
        g.push();g.translate(cx,cy);g.rotate(i*.55+age*(i%2==0 and -.2 or .17))
        tint(i==2 and gold or purple,alpha*.7);g.setLineWidth(i==2 and 2 or 1)
        g.ellipse("line",0,0,155+i*18+age*9,100+i*11);g.pop()
    end
    if Visual.effects.particles then
        for i=1,Visual.quality=="LOW" and 12 or 38 do
            local angle=i*2.399;local speed=40+(i*37)%150
            local t=age*.7;local px=cx+math.cos(angle)*(90+t*speed)
            local py=cy+math.sin(angle)*70-t*(65+i%5*14)+t*t*90
            g.push();g.translate(px,py);g.rotate(angle+age*.9)
            tint(i%3==0 and purple or gold,alpha*.85);g.rectangle("fill",-2,-5,4,10,1);g.pop()
        end
    end
    g.setBlendMode("alpha")
    local function centred(label,y,font,color,scale)
        g.push();g.translate(cx,y);g.scale(scale or 1);g.setFont(font);tint(color,alpha)
        g.printf(label,-width/2,0,width,"center");g.pop()
    end
    centred("THE VOID · MAY MẮN TUYỆT ĐỐI",cy-260,fonts.small,purple)
    centred("JACKPOT",cy-230,fonts.title,gold,1.45)
    local art=require("src.continental_art").get("void_ticket")
    if art then
        local frame=require("ui.components.card_frame")
        g.setColor(1,1,1,alpha);frame.image(art,cx-54,cy-116,108,162)
        frame.draw(cx-54,cy-116,108,162,nil,alpha,{rarity="legendary"})
    end
    local count=math.floor(100*(1-(1-math.min(1,age/.85))^3)+.001)
    centred(tostring(count),cy+64,fonts.huge,gold,1.85)
    centred("VÉ THE VOID",cy+168,fonts.medium,{.93,.85,1})
    centred("ĐÃ CHỐT PHẦN THƯỞNG · TẬN HƯỞNG NHÂN PHẨM!",cy+210,fonts.tiny,gold)
    g.pop()
end

return E

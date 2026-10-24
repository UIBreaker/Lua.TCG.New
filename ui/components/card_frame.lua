-- One base silhouette and metal rim for every card family.
local Frame = {}
Frame.color = {0.66, 0.55, 0.35, 1}
Frame.metal = {0.085, 0.075, 0.060, 1}
Frame.rimWidth = 2
local meshes = {}
local meshOrder={}

local function outline(x, y, w, h, inset)
    local bevel = math.min(w, h) * 0.06
    inset = inset or 0
    local c = math.max(0, bevel - inset * 0.5)
    x, y, w, h = x + inset, y + inset, w - inset * 2, h - inset * 2
    return {x+c,y, x+w-c,y, x+w,y+c, x+w,y+h-c,
        x+w-c,y+h, x+c,y+h, x,y+h-c, x,y+c}
end

function Frame.image(image, x, y, w, h)
    if not image or w<=0 or h<=0 then return end
    local ratio=h/w
    local key = tostring(ratio)
    local mesh = meshes[key]
    if not mesh then
        local points, vertices = outline(0, 0, 1, ratio), {{.5,ratio/2,0.5,0.5,1,1,1,1}}
        for i=1,16,2 do
            vertices[#vertices+1] = {points[i],points[i+1],points[i],points[i+1]/ratio,1,1,1,1}
        end
        vertices[#vertices+1] = vertices[2]
        mesh = love.graphics.newMesh(vertices, "fan", "static")
        meshes[key] = mesh
        meshOrder[#meshOrder+1]=key
        if #meshOrder>64 then local old=table.remove(meshOrder,1);meshes[old]:release();meshes[old]=nil end
    end
    mesh:setTexture(image)
    love.graphics.draw(mesh, x, y,0,w,w)
end
function Frame.meshCount() return #meshOrder end

-- Ancient metal mounts with sparse, readable ornament; every tier has its own profile.
Frame.styles = {
    {metal=Frame.color, gem={0.82,0.84,0.88}},                       -- C: plain bronze
    {metal={0.60,0.72,0.57}, gem={0.28,0.82,0.48}},                 -- UC: etched patina
    {metal={0.63,0.76,0.88}, gem={0.30,0.62,1.00}},                 -- R: silver, sapphire
    {metal={0.80,0.66,0.88}, gem={0.72,0.38,0.94}},                 -- E: amethyst filigree
    {metal={0.98,0.78,0.40}, gem={1.00,0.62,0.22}},                 -- L: gilded crest
    {metal={0.98,0.65,0.48}, gem={0.94,0.28,0.30}},                 -- M: ruby sunburst
    {metal={0.65,0.92,0.94}, gem={0.48,0.90,0.96}},                 -- T: astral silver
    {metal={0.91,0.83,1.00}, gem={0.82,0.70,1.00}},                 -- UQ: crowned constellation
    {metal={0.76,0.94,0.85}, gem={0.46,0.95,0.77}},                 -- VH: eternal silver knots
    {metal={1.00,0.91,0.65}, gem={1.00,0.85,0.43}},                 -- TT: white-gold solar crown
}
local Deities = require("src.deities")
local rarityTier = Deities.getRarityTier
function Frame.tier(card)
    local tier, overflow = rarityTier(card)
    -- Playing cards can gain ability levels temporarily during combat as well.
    local temporary = card and card.suit and math.max(0, math.floor(tonumber(card.temporaryAbilityLevels) or 0)) or 0
    local absolute = tier + overflow + temporary
    return math.min(#Frame.styles, absolute), math.max(0, absolute - #Frame.styles)
end

function Frame.socketPosition(index,w,h)
    local inset=math.min(w,h)*0.06
    local positions={{inset,inset},{w-inset,inset},{w-inset,h-inset},{inset,h-inset},
        {w/2,inset},{w-inset,h/2},{w/2,h-inset},{inset,h/2}}
    return positions[index][1],positions[index][2]
end

function Frame.socketGem(cx,cy,radius,color,alpha,pulse,linked,tier,time,reduced,mountTier)
    local g=love.graphics
    alpha,pulse=alpha or 1,pulse or 0
    if alpha<=0 or radius<=0 then return end
    tier=math.max(1,math.min(8,tier or 1))
    local visual=require("config.visual_config")
    local moving=visual.enabled and not reduced
    local t=moving and (time or 0) or 0
    pulse=moving and pulse or 0
    local low=visual.quality=="LOW"
    local style=Frame.styles[mountTier or tier]
    local metal=style.metal
    local breath=moving and (.5+.5*math.sin(t*(1.8+tier*.18)+cx*.09+cy*.07)) or .3
    local strength=linked and .72 or 1
    g.push("all");g.translate(cx,cy)
    local function tint(a,white)
        white=white or 0
        g.setColor((color[1]*(1-white)+white)*strength,(color[2]*(1-white)+white)*strength,
            (color[3]*(1-white)+white)*strength,alpha*a)
    end
    if color then
        for band=2,1,-1 do
            tint((.045+tier*.009+breath*.025+pulse*.10)/band)
            g.circle("fill",0,0,radius*(1.25+band*.19),16)
        end
    end
    g.setColor(.009,.015,.023,alpha);g.circle("fill",0,0,radius*1.32,8)
    g.setLineWidth(math.max(.55,radius*.22))
    g.setColor(metal[1],metal[2],metal[3],alpha*.95);g.circle("line",0,0,radius*1.17,8)
    g.setColor(1,.96,.84,alpha*.65);g.arc("line","open",0,0,radius*1.18,math.pi,math.pi*1.75,8)
    g.setColor(.09,.07,.04,alpha*.85);g.arc("line","open",0,0,radius*1.18,0,math.pi*.75,8)
    if not color then
        g.setColor(.10,.14,.18,alpha);g.circle("fill",0,0,radius*.69,8)
        g.setColor(.29,.36,.41,alpha*.9);g.setLineWidth(math.max(.5,radius*.13))
        g.line(-radius*.35,0,radius*.35,0);g.line(0,-radius*.35,0,radius*.35)
        g.pop();return
    end
    local r=radius*.84
    tint(1);g.polygon("fill",0,-r,r,0,0,r,-r,0)
    tint(.85,.68);g.polygon("fill",0,-r,0,0,-r,0)
    g.setColor(.015,.03,.05,alpha*.6);g.polygon("fill",0,0,r,0,0,r)
    tint(.95,.85);g.circle("fill",-r*.20,-r*.35,math.max(.4,r*.15),8)
    -- Four visible prongs distinguish a mounted jewel from a free-floating particle.
    g.setLineWidth(math.max(.6,radius*.17))
    g.setColor(metal[1],metal[2],metal[3],alpha)
    for i=0,3 do
        local angle=math.pi*.25+i*math.pi*.5
        g.line(math.cos(angle)*radius*.76,math.sin(angle)*radius*.76,
            math.cos(angle)*radius*1.08,math.sin(angle)*radius*1.08)
    end
    if tier>=2 or pulse>0 then
        g.setLineWidth(math.max(.55,radius*.13));tint(.45+breath*.3+pulse*.2,.25)
        local angle=t*(.8+tier*.12)
        g.arc("line","open",0,0,radius*1.42,angle,angle+math.pi*(.4+tier*.08),12)
        if tier>=5 then g.arc("line","open",0,0,radius*1.56,-angle,-angle+math.pi*.65,12) end
    end
    if tier>=3 then
        local count=low and 2 or math.min(6,tier-1)
        for i=1,count do
            local angle=t*(.5+tier*.07)+i*math.pi*2/count
            local orbit=radius*(tier>=6 and 1.55 or 1.40)
            local px,py=math.cos(angle)*orbit,math.sin(angle)*orbit
            local size=math.max(.25,radius*(.10+breath*.07))
            tint(.65+breath*.3,.65);g.polygon("fill",px-size,py,px,py-size,px+size,py,px,py+size)
        end
    end
    if tier>=6 or pulse>0 then
        local burst=math.max(pulse,moving and math.max(0,math.sin(t*2.2+cx*.1+cy*.13))^8 or .12)
        local rays=low and 4 or 8
        g.setLineWidth(math.max(.5,radius*.12));tint(.15+burst*.7,.45)
        for i=1,rays do
            local angle=i*math.pi*2/rays+t*.17
            local inner=radius*1.05;local outer=radius*(1.3+burst*.30)
            g.line(math.cos(angle)*inner,math.sin(angle)*inner,math.cos(angle)*outer,math.sin(angle)*outer)
        end
        if tier>=8 or pulse>0 then
            tint(.08+burst*.3,.6);g.circle("line",0,0,radius*(1.1+burst*.50),16)
        end
    end
    if linked then
        tint(.85,.5);g.setLineWidth(math.max(.6,radius*.14))
        g.ellipse("line",-radius*.22,radius*.6,radius*.32,radius*.18,12)
        g.ellipse("line",radius*.22,radius*.6,radius*.32,radius*.18,12)
    end
    g.pop()
end

function Frame.drawSockets(x,y,w,h,card,alpha,time,reduced)
    alpha=alpha or card and card.alpha or 1
    if not card or card.faceDown or not card.rank or not card.suit or alpha<=0 then return end
    local E=require("src.equipment")
    love.graphics.push("all");love.graphics.setShader()
    local entries=E.getSocketEntries(card)
    local radius=math.min(w,h)*0.025
    for i=1,E.getMaxSlots(card) do
        local cx,cy=Frame.socketPosition(i,w,h)
        local entry=entries[i]
        local color=entry and E.getTierColor(entry.equipment)
        local pulse=entry and require("src.card_effects").getEquipmentPulse(card,entry.equipmentIndex) or 0
        Frame.socketGem(x+cx,y+cy,radius,color,alpha,pulse,entry and entry.linked,
            entry and E.getTier(entry.equipment) or 1,(time or 0)+i*.37,reduced,Frame.tier(card))
    end
    love.graphics.pop()
end

local rimPaths={}
local rimOrder={}
local function rimPath(w,h,inset)
    local key=w..":"..h..":"..inset
    if rimPaths[key] then return rimPaths[key] end
    local p={points=outline(0,0,w,h,inset),lengths={},total=0}
    for i=1,16,2 do
        local j=i==15 and 1 or i+2
        local length=((p.points[j]-p.points[i])^2+(p.points[j+1]-p.points[i+1])^2)^.5
        p.lengths[#p.lengths+1]=length;p.total=p.total+length
    end
    rimPaths[key]=p;rimOrder[#rimOrder+1]=key
    if #rimOrder>128 then rimPaths[table.remove(rimOrder,1)]=nil end
    return p
end
local function rimPoint(path,phase)
    local distance=(phase%1)*path.total
    for segment,length in ipairs(path.lengths) do
        local i=(segment-1)*2+1;local j=i==15 and 1 or i+2
        if length>0 and distance<=length then
            local t=distance/length
            return path.points[i]+(path.points[j]-path.points[i])*t,path.points[i+1]+(path.points[j+1]-path.points[i+1])*t
        end
        distance=distance-length
    end
    return path.points[1],path.points[2]
end

function Frame.drawEnergy(x,y,w,h,card,alpha,time,reduced)
    if not card or card.faceDown then return end
    if not (card.rank and card.suit) and not Deities.CATALOG[card.deityId or card.id] then return end
    local tier,overflow=Frame.tier(card)
    local ascended=card.rank and card.suit and overflow>0
    if tier<2 or alpha<=0 then return end
    local visual=require("config.visual_config")
    local moving=visual.enabled and not reduced
    local t=moving and (time or 0) or 0
    local low=visual.quality=="LOW"
    local unit=math.max(.6,math.min(1.6,math.min(w,h)/128))
    local gem=Frame.styles[tier].gem
    local g=love.graphics
    local pulse=moving and math.max(0,math.sin(t*1.9+tier*.61))^6 or .18
    local path=rimPath(w,h,5*unit)
    g.push("all");g.translate(x,y);g.setBlendMode("add")
    local function tint(a,white)
        white=white or 0
        g.setColor(gem[1]*(1-white)+white,gem[2]*(1-white)+white,gem[3]*(1-white)+white,alpha*a)
    end
    local function star(cx,cy,r,a)
        tint(a)
        g.polygon("fill",cx-r,cy,cx-r*.18,cy-r*.18,cx,cy-r,cx+r*.18,cy-r*.18,
            cx+r,cy,cx+r*.18,cy+r*.18,cx,cy+r,cx-r*.18,cy+r*.18)
        tint(a,.85);g.circle("fill",cx,cy,r*.23,6)
    end
    if tier>=4 then
        tint(.025+(tier-4)*.008+pulse*.075)
        g.setLineWidth((4+tier*.35)*unit);g.polygon("line",path.points)
        tint(.10+pulse*.26);g.setLineWidth(.8*unit);g.polygon("line",path.points)
    end
    local streams=ascended and 6 or tier>=10 and 4 or tier>=8 and 3 or tier>=5 and 2 or 1
    if low then streams=math.min(streams,ascended and 3 or 2) end
    local segments=low and 5 or 8+tier
    local tail=.035+tier*.008
    for stream=1,streams do
        local direction=tier>=7 and stream%2==0 and -1 or 1
        local track=tier>=9 and stream%2==0 and rimPath(w,h,8*unit) or path
        local head=t*(.035+tier*.010)*direction+(stream-1)/streams+tier*.073
        for i=segments,1,-1 do
            local fade=(1-i/(segments+1))^1.6
            local ax,ay=rimPoint(track,head-direction*tail*i/segments)
            local bx,by=rimPoint(track,head-direction*tail*(i-1)/segments)
            tint(fade*(tier>=5 and .12 or .06));g.setLineWidth((tier>=7 and 5 or 3)*unit);g.line(ax,ay,bx,by)
            tint(fade*(.32+tier*.06),tier>=8 and .35 or .1);g.setLineWidth((.7+tier*.045)*unit);g.line(ax,ay,bx,by)
        end
        local hx,hy=rimPoint(track,head)
        star(hx,hy,(.7+tier*.17)*unit,.4+tier*.045)
        if tier>=8 and not low then
            for i=1,3 do
                local px,py=rimPoint(track,head-direction*tail*i/4)
                star(px,py,(.8+i*.12)*unit,(1-i/4)*.65)
            end
        end
    end
    if tier>=6 then
        for _,p in ipairs({{w/2,7*unit},{w/2,h-7*unit},{7*unit,h/2},{w-7*unit,h/2}}) do
            local radius=(tier>=9 and 4 or 2.8)*unit
            tint(.055+pulse*.16);g.circle("fill",p[1],p[2],radius*1.6,12)
            star(p[1],p[2],radius,.18+pulse*.8)
        end
    end
    if tier>=7 and not low then
        for wave=1,(tier>=9 and 2 or 1) do
            local phase=(t*.30+tier*.19+wave*.5)%1
            local strength=math.sin(phase*math.pi)^4
            tint(strength*(.06+(tier-7)*.045))
            g.setLineWidth((tier==10 and 1.6 or .8)*unit)
            g.polygon("line",outline(0,0,w,h,(4+phase*9)*unit))
        end
    end
    if tier>=8 then
        for _,p in ipairs({{12*unit,12*unit},{w-12*unit,12*unit},{12*unit,h-12*unit},{w-12*unit,h-12*unit}}) do
            if tier==10 then
                for ray=1,8 do
                    local angle=ray*math.pi/4+t*.15
                    local radius=(3+pulse*3)*unit
                    tint(.12+pulse*.58);g.setLineWidth(.8*unit)
                    g.line(p[1]+math.cos(angle)*radius,p[2]+math.sin(angle)*radius,
                        p[1]+math.cos(angle)*(radius+3*unit),p[2]+math.sin(angle)*(radius+3*unit))
                end
            end
            star(p[1],p[2],(2+pulse*(tier>=9 and 3 or 1.5))*unit,.35+pulse*.6)
        end
    end
    if ascended then
        local burst=moving and math.max(0,math.sin(t*2.4))^6 or .3
        -- Four radiant seals stay on the rim, leaving the portrait and labels clear.
        for _,p in ipairs({{w/2,10*unit},{w/2,h-10*unit},{9*unit,h*.48},{w-9*unit,h*.48}}) do
            local angle=t*.65
            local radius=(3.6+burst*2)*unit
            tint(.35+burst*.5,.65);g.setLineWidth(.85*unit)
            g.arc("line","open",p[1],p[2],radius,angle,angle+math.pi*1.4,20)
            g.arc("line","open",p[1],p[2],radius+unit,-angle,-angle+math.pi,16)
            for ray=1,(low and 4 or 8) do
                local a=ray*math.pi*2/(low and 4 or 8)+angle
                tint(.2+burst*.65,.45)
                g.line(p[1]+math.cos(a)*radius*.65,p[2]+math.sin(a)*radius*.65,
                    p[1]+math.cos(a)*(radius+1.5*unit),p[2]+math.sin(a)*(radius+1.5*unit))
            end
            star(p[1],p[2],(2+burst*1.5)*unit,.65+burst*.3)
        end
        if not low then
            local phase=(t*.55)%1
            tint(math.sin(phase*math.pi)^3*.42,.55);g.setLineWidth(1.2*unit)
            g.polygon("line",outline(0,0,w,h,(8+phase*6)*unit))
        end
    end
    g.pop()
end

local facet={1.08,.82,.61,.47,.42,.59,.84,1.13}
function Frame.draw(x, y, w, h, highlight, alpha, card, time, reduced,skipSockets)
    local g = love.graphics
    alpha = (alpha or card and card.alpha or 1) * (highlight and highlight[4] or 1)
    if alpha<=0 then return end
    local tier, overflow = Frame.tier(card)
    local ascended=card and card.rank and card.suit and overflow>0
    local style = Frame.styles[tier]
    local size = math.min(w,h)
    local unit = math.max(0.6, math.min(1.6, size/128))
    g.push("all");g.translate(x,y);x,y=0,0;g.setShader()
    local depth=tier==1 and Frame.rimWidth or (ascended and 7 or 1.8+tier*.23)*unit
    local outer, inner = rimPath(w,h,0).points, rimPath(w,h,depth).points
    local shoulder,ledge=rimPath(w,h,depth*.28).points,rimPath(w,h,depth*.73).points
    for i=1,16,2 do
        local j = i == 15 and 1 or i+2
        if tier==1 then g.setColor(Frame.metal[1],Frame.metal[2],Frame.metal[3],alpha)
        else
            local f=facet[(i+1)/2]
            g.setColor(style.metal[1]*f,style.metal[2]*f,style.metal[3]*f,alpha)
        end
        g.polygon("fill",outer[i],outer[i+1],outer[j],outer[j+1],inner[j],inner[j+1],inner[i],inner[i+1])
        -- Polish the same rail into a raised shoulder, satin face and recessed inner lip.
        local metal=tier==1 and Frame.color or style.metal
        local f=facet[(i+1)/2]
        g.setColor(math.min(1,metal[1]*f*1.12+.08),math.min(1,metal[2]*f*1.12+.07),math.min(1,metal[3]*f*1.12+.05),alpha)
        g.polygon("fill",outer[i],outer[i+1],outer[j],outer[j+1],shoulder[j],shoulder[j+1],shoulder[i],shoulder[i+1])
        g.setColor(metal[1]*f*.78,metal[2]*f*.78,metal[3]*f*.78,alpha)
        g.polygon("fill",shoulder[i],shoulder[i+1],shoulder[j],shoulder[j+1],ledge[j],ledge[j+1],ledge[i],ledge[i+1])
        g.setColor(metal[1]*f*.35,metal[2]*f*.35,metal[3]*f*.35,alpha)
        g.polygon("fill",ledge[i],ledge[i+1],ledge[j],ledge[j+1],inner[j],inner[j+1],inner[i],inner[i+1])
    end
    local color = style.metal
    -- Hover brightens the tier's metal without erasing its identity.
    local mix = highlight and 0.22 or 0
    local r,b,c = color[1]*(1-mix)+(highlight and highlight[1] or 0)*mix,
        color[2]*(1-mix)+(highlight and highlight[2] or 0)*mix,
        color[3]*(1-mix)+(highlight and highlight[3] or 0)*mix
    local stroke = (highlight and 2 or math.max(0.8,math.min(1.6,w*0.012))) + (tier-1)*0.10
    g.setColor(r,b,c,alpha); g.setLineWidth(tier==1 and stroke or stroke*.68)
    g.polygon("line",rimPath(w,h,.75).points)
    if tier>=2 then
        g.setColor(.97,.94,.83,alpha*.30);g.setLineWidth(math.max(.45,unit*.45))
        g.polygon("line",rimPath(w,h,depth*.32).points)
    end
    if tier == 1 then
        if not skipSockets then Frame.drawSockets(x,y,w,h,card,alpha,time,reduced) end
        g.pop(); return
    end
    g.setColor(.018,.025,.038,alpha*.95);g.setLineWidth(unit)
    g.polygon("line",inner)
    if tier>=3 then
        g.setColor(r,b,c,alpha*.60);g.setLineWidth(.7*unit)
        g.polygon("line",rimPath(w,h,4.5*unit).points)
    end
    if tier>=7 then
        g.setColor(style.gem[1],style.gem[2],style.gem[3],alpha*.35)
        g.setLineWidth(.65*unit);g.polygon("line",rimPath(w,h,7.5*unit).points)
    end
    local bevel, reach = size*0.06,size*(0.055+0.012*tier)
    g.setLineWidth(math.max(0.75,unit))
    for corner=1,4 do
        local right,bottom=corner%2==0,corner>2
        g.push();g.translate(right and w or 0,bottom and h or 0);g.scale(right and -1 or 1,bottom and -1 or 1)
        g.setColor(r,b,c,alpha)
        g.line(3*unit,bevel+reach,3*unit,bevel+2*unit,bevel+2*unit,3*unit,bevel+reach,3*unit)
        if tier >= 3 then
            g.setColor(r*.38,b*.38,c*.38,alpha)
            g.polygon("fill",2*unit,bevel+14*unit,2*unit,bevel+2*unit,bevel+2*unit,2*unit,
                bevel+14*unit,2*unit,bevel+5*unit,8*unit,8*unit,bevel+5*unit)
            g.setColor(r,b,c,alpha)
            g.polygon("fill",3*unit,bevel+10*unit,3*unit,bevel+3*unit,bevel+3*unit,3*unit,
                bevel+10*unit,3*unit,bevel+4*unit,6*unit,6*unit,bevel+4*unit)
            g.setColor(r*.22,b*.22,c*.22,alpha*.9);g.setLineWidth(.7*unit)
            g.line(4.6*unit,bevel+9*unit,4.6*unit,bevel+4*unit,bevel+4*unit,4.6*unit,bevel+9*unit,4.6*unit)
            g.setColor(1,.96,.84,alpha*.58);g.setLineWidth(.5*unit)
            g.line(3.3*unit,bevel+9*unit,3.3*unit,bevel+3.5*unit,bevel+3.5*unit,3.3*unit,bevel+9*unit,3.3*unit)
        end
        if tier >= 4 then
            g.setColor(r*.32,b*.32,c*.32,alpha);g.setLineWidth(1.6*unit)
            g.line(6*unit,bevel+reach*0.85,6*unit,bevel+6*unit,bevel+6*unit,6*unit,bevel+reach*0.85,6*unit)
            g.setColor(r,b,c,alpha*.85);g.setLineWidth(.55*unit)
            g.line(5.7*unit,bevel+reach*0.85,5.7*unit,bevel+5.7*unit,bevel+5.7*unit,5.7*unit,bevel+reach*0.85,5.7*unit)
        end
        if tier >= 6 then
            g.setColor(style.gem[1]*.65,style.gem[2]*.65,style.gem[3]*.65,alpha)
            g.polygon("fill",5*unit,bevel+7*unit,bevel+7*unit,5*unit,bevel+9*unit,7*unit,7*unit,bevel+9*unit)
            g.setColor(1,.96,.82,alpha*.7);g.line(3*unit,bevel+3*unit,bevel+3*unit,3*unit)
        end
        if tier >= 7 and not (card and card.suit) then
            g.setColor(style.gem[1],style.gem[2],style.gem[3],alpha*0.85)
            g.circle("fill",bevel+7*unit,bevel+7*unit,1.3*unit)
        end
        g.pop()
    end
    local function gem(cx,cy,radius)
        local jewel=style.gem
        g.setColor(0.035,0.045,0.060,alpha)
        g.polygon("fill",cx,cy-radius-unit,cx+radius+unit,cy,cx,cy+radius+unit,cx-radius-unit,cy)
        g.setColor(jewel[1],jewel[2],jewel[3],alpha)
        g.polygon("fill",cx,cy-radius,cx+radius,cy,cx,cy+radius,cx-radius,cy)
        g.setColor(jewel[1]*.42,jewel[2]*.42,jewel[3]*.42,alpha)
        g.polygon("fill",cx,cy,cx+radius,cy,cx,cy+radius)
        g.setColor(jewel[1]*.68,jewel[2]*.68,jewel[3]*.68,alpha)
        g.polygon("fill",cx,cy,cx,cy+radius,cx-radius,cy)
        g.setColor(jewel[1]*.5+.5,jewel[2]*.5+.5,jewel[3]*.5+.5,alpha)
        g.polygon("fill",cx,cy-radius,cx,cy,cx-radius,cy)
        g.setColor(jewel[1]*.83+.12,jewel[2]*.83+.12,jewel[3]*.83+.12,alpha)
        local tableRadius=radius*.42
        g.polygon("fill",cx,cy-tableRadius,cx+tableRadius,cy,cx,cy+tableRadius,cx-tableRadius,cy)
        g.setLineWidth(.55*unit)
        g.setColor(1,0.97,0.89,alpha*0.9);g.line(cx-radius*0.5,cy,cx,cy-radius*0.5)
        g.setColor(r*.85,b*.85,c*.85,alpha*.8);g.setLineWidth(.55*unit)
        g.polygon("line",cx,cy-radius-unit*.5,cx+radius+unit*.5,cy,cx,cy+radius+unit*.5,cx-radius-unit*.5,cy)
    end
    local radius=(tier>=8 and 4 or tier>=5 and 3 or 2)*unit
    if tier>=3 then
        for edge=1,2 do
            local cy,sign=edge==1 and y or y+h,edge==1 and 1 or -1
            local cx=x+w/2
            if tier>=5 then
                g.push();g.translate(cx,cy);g.scale(unit,unit*sign)
                g.setColor(r*.3,b*.3,c*.3,alpha)
                g.polygon("fill",-25,2,-16,3,-9,7,0,9,9,7,16,3,25,2,16,12,0,17,-16,12)
                g.setColor(r,b,c,alpha)
                g.polygon("fill",-23,2,-15,4,-8,8,0,10,8,8,15,4,23,2,14,10,0,14,-14,10)
                g.setColor(r*.46,b*.46,c*.46,alpha)
                g.polygon("fill",-23,2,-14,10,0,14,14,10,23,2,16,12,0,17,-16,12)
                g.setColor(r*.9,b*.9,c*.9,alpha);g.setLineWidth(.55)
                g.line(-17,7,-10,10,0,12,10,10,17,7)
                g.setLineWidth(.7)
                g.setColor(1,.97,.86,alpha*.75);g.line(-23,2,-15,4,-8,8,0,10,8,8,15,4,23,2)
                if tier>=8 then
                    g.setColor(style.gem[1],style.gem[2],style.gem[3],alpha*.85)
                    g.line(-17,8,-10,12,0,15,10,12,17,8)
                end
                if tier>=9 then
                    g.ellipse("line",-5,10,6,3);g.ellipse("line",5,10,6,3)
                end
                g.pop()
            end
            if not (card and card.suit) then gem(cx,cy+sign*6*unit,radius) end
        end
    end
    if tier>=6 and not (card and card.suit) then
        for edge=1,2 do
            local cx,sign=edge==1 and x or x+w,edge==1 and 1 or -1
            g.setColor(r*.4,b*.4,c*.4,alpha)
            g.polygon("fill",cx+sign*2*unit,y+h/2-18*unit,cx+sign*11*unit,y+h/2,
                cx+sign*2*unit,y+h/2+18*unit,cx+sign*5*unit,y+h/2)
            g.setColor(r,b,c,alpha);g.setLineWidth(unit)
            g.line(cx+sign*2*unit,y+h/2-18*unit,cx+sign*11*unit,y+h/2,cx+sign*2*unit,y+h/2+18*unit)
            gem(cx+sign*6*unit,y+h/2,radius)
        end
    end
    if ascended then
        -- White-gold exoskeleton and winged crown distinguish level 10 even without motion.
        g.setColor(.98,.70,.22,alpha);g.setLineWidth(1.4*unit)
        g.polygon("line",rimPath(w,h,3*unit).points)
        g.setColor(1,.98,.84,alpha*.9);g.setLineWidth(.7*unit)
        g.polygon("line",rimPath(w,h,6.4*unit).points)
        for _,side in ipairs({1,-1}) do
            g.push();g.translate(side==1 and 0 or w,h*.48);g.scale(unit*side,unit)
            g.setColor(.16,.10,.045,alpha)
            g.polygon("fill",2,-32,10,-21,7,-14,16,-7,13,0,16,7,7,14,10,21,2,32)
            g.setColor(1,.76,.31,alpha)
            for i=-2,2 do
                local yy=i*10
                g.polygon("fill",2,yy-7,12-math.abs(i)*2,yy-3,7,yy+5,3,yy+8)
                g.setColor(1,.97,.80,alpha*.85);g.line(3,yy-5,10-math.abs(i)*2,yy-2,5,yy+4)
                g.setColor(1,.76,.31,alpha)
            end
            g.pop()
        end
        for _,edge in ipairs({1,-1}) do
            g.push();g.translate(w/2,edge==1 and 0 or h);g.scale(unit,unit*edge)
            g.setColor(.17,.105,.035,alpha)
            g.polygon("fill",-24,2,-16,8,-12,3,-6,10,0,2,6,10,12,3,16,8,24,2,17,16,0,22,-17,16)
            g.setColor(1,.80,.36,alpha)
            g.polygon("fill",-22,3,-15,10,-12,6,-6,13,0,5,6,13,12,6,15,10,22,3,15,14,0,19,-15,14)
            g.setColor(1,.99,.84,alpha);g.setLineWidth(.9)
            g.line(-22,3,-15,10,-12,6,-6,13,0,5,6,13,12,6,15,10,22,3)
            g.pop()
            gem(w/2,edge==1 and 12*unit or h-12*unit,4*unit)
        end
    end
    Frame.drawEnergy(x,y,w,h,card,alpha,time,reduced)
    -- Overflow is still visible after TT; the badge retains the exact level.
    if overflow > 0 then
        g.setColor(1,0.94,0.76,alpha)
        for i=1,math.min(overflow,8) do
            local dx=(i-(math.min(overflow,8)+1)/2)*4*unit
            g.line(x+w/2+dx,y+h-16*unit,x+w/2+dx,y+h-14*unit)
        end
    end
    if not skipSockets then Frame.drawSockets(x,y,w,h,card,alpha,time,reduced) end
    g.pop()
end

function Frame.pennantRect(w, h, card)
    local margin = math.max(2, math.min(w,h)*0.05 + 1)
    local tier = card and Frame.tier(card) or 1
    local fw = math.min(36+(tier-1)*3.2,w*(0.30+(tier-1)*0.013))
    local fh = math.min(h*0.30,fw*(0.78+(tier-1)*0.037))
    return w-margin-fw, margin, fw, fh
end

-- The pennant is card-local geometry, so ornaments follow hover, flight and fade.
function Frame.drawRarityPennant(card,w,h,font,time,reduced)
    local g=love.graphics
    local tier,overflow=Frame.tier(card)
    local badge=require("src.deities").getRarityBadge(card)
    local style=Frame.styles[tier]
    local metal,jewel=style.metal,style.gem
    local x,y,bw,bh=Frame.pennantRect(w,h,card)
    local alpha=math.max(0,math.min(1,card.alpha or 1))
    if alpha==0 then return end
    local visual=require("config.visual_config")
    local animate=not reduced and visual.enabled
    local t=animate and (time or 0) or 0
    local pulse=animate and (0.5+0.5*math.sin(t*2.4+tier)) or 0.5
    local top=tier>=5 and 20 or tier>=3 and 12 or 4
    local cy=tier>=5 and 39 or tier>=3 and 33 or 28
    local function tint(c,a,f)
        f=f or 1;g.setColor(c[1]*f,c[2]*f,c[3]*f,alpha*(a or 1))
    end
    local function diamond(cx,yy,r)
        tint(metal,1,0.24);g.polygon("fill",cx,yy-r-1.2,cx+r+1.2,yy,cx,yy+r+1.2,cx-r-1.2,yy)
        tint(jewel);g.polygon("fill",cx,yy-r,cx+r,yy,cx,yy+r,cx-r,yy)
        g.setColor(1,1,1,alpha*.8);g.polygon("fill",cx,yy-r,cx,yy,cx-r,yy)
        tint(jewel,1,.36);g.polygon("fill",cx,yy,cx+r,yy,cx,yy+r)
    end
    local function star(cx,yy,r,a)
        tint(jewel,a)
        g.polygon("fill",cx,yy-r,cx+r*.22,yy-r*.22,cx+r,yy,cx+r*.22,yy+r*.22,
            cx,yy+r,cx-r*.22,yy+r*.22,cx-r,yy,cx-r*.22,yy-r*.22)
        g.setColor(1,1,.95,alpha*a);g.circle("fill",cx,yy,r*.18,6)
    end
    g.push("all");g.translate(x,y)
    g.push();g.scale(bw/64,bh/76)
    -- A localized halo never spills outside the card or obscures the illustration.
    if tier>=5 then
        g.setBlendMode("add")
        for layer=5,1,-1 do
            tint(jewel,(.016+(tier-5)*.008)*(0.6+pulse*.4))
            g.ellipse("fill",32,35,18+layer*3.7,23+layer*3.5)
        end
        if tier>=7 then
            tint(jewel,.35+pulse*.25);g.setLineWidth(.85)
            local angle=t*.55
            g.arc("line","open",32,34,34,angle,angle+math.pi*.74)
            g.arc("line","open",32,34,34,angle+math.pi,angle+math.pi*1.74)
        end
        if tier>=8 and animate then
            local burst=(t*.36+tier*.17)%1
            local radius=20+burst*18
            tint(jewel,(1-burst)^2*.65);g.setLineWidth(1.1)
            g.ellipse("line",32,35,radius,radius*1.07)
            for i=1,tier-3 do
                local angle=i*math.pi*2/(tier-3)
                star(32+math.cos(angle)*radius,35+math.sin(angle)*radius,2.2,(1-burst)^2*.75)
            end
        end
        if tier==10 then
            for i=1,12 do
                local a=i*math.pi/6+t*.10
                local r=34+(i%2)*4
                tint(jewel,.40+pulse*.30);g.setLineWidth(i%2==0 and 1.9 or 1)
                g.line(32+math.cos(a)*25,34+math.sin(a)*25,32+math.cos(a)*r,34+math.sin(a)*r)
            end
        end
        g.setBlendMode("alpha")
    end
    if tier>=6 then
        local feathers=tier>=9 and 3 or tier>=8 and 2 or 1
        for side=-1,1,2 do
            for i=1,feathers do
                local yy=24+i*6
                tint(metal,1,.26)
                g.polygon("fill",32+side*12,yy-5,32+side*31,yy-13,32+side*25,yy+2,32+side*13,yy+6)
                tint(metal,1,.85+i*.05)
                g.polygon("fill",32+side*13,yy-4,32+side*29,yy-11,32+side*23,yy+1,32+side*13,yy+4)
                g.setColor(1,.98,.87,alpha*.78)
                g.line(32+side*15,yy-3,32+side*28,yy-10)
                tint(jewel,.7);g.line(32+side*16,yy+1,32+side*24,yy-5)
            end
        end
    end
    -- Bevelled metal around a dark enamel face, with a split expedition ribbon.
    g.setColor(.005,.008,.014,alpha*.85)
    g.polygon("fill",10,top+2,54,top+2,58,top+10,55,75,33,66,11,75,7,top+10)
    tint(metal,1,.34)
    g.polygon("fill",9,top,55,top,59,top+8,54,73,32,64,10,73,5,top+8)
    tint(metal)
    g.polygon("fill",10,top+1,54,top+1,57,top+8,52,70,32,61,12,70,7,top+8)
    g.setColor(1,.98,.9,alpha*.72)
    g.polygon("fill",10,top+1,54,top+1,50,top+5,14,top+5,11,65,8,top+8)
    tint(metal,1,.48)
    g.polygon("fill",54,top+2,57,top+8,52,70,48,64,51,top+9)
    g.setColor(.018,.024,.038,alpha)
    g.polygon("fill",16,top+6,48,top+6,51,top+11,47,62,32,56,17,62,13,top+11)
    tint(jewel,tier>=5 and .32 or .18);g.polygon("fill",16,top+6,48,top+6,32,cy+7,15,cy+10)
    tint(jewel,tier>=5 and .18 or .08);g.polygon("fill",48,top+7,50,top+12,46,59,33,cy+8)
    if tier>=4 then
        g.setColor(.90,.96,1,alpha*.13)
        g.polygon("fill",18,top+8,45,top+8,18,cy+5)
        tint(jewel,.75);g.setLineWidth(.8);g.line(20,cy+12,32,cy+15,44,cy+12)
    end
    tint(metal,.8);g.setLineWidth(.8)
    g.line(16,top+7,48,top+7,50,top+12)
    g.line(15,cy+14,18,59,32,53,46,59,49,cy+14)
    if tier>=2 then
        for side=-1,1,2 do
            tint(metal,.75);g.line(32+side*19,cy-5,32+side*19,cy+8,32+side*15,cy+12)
            tint(jewel,.8);g.circle("fill",32+side*20,top+10,1.2,6)
        end
    end
    if tier>=3 then diamond(32,top+2,tier>=5 and 3.8 or 4.7) end
    if tier>=4 then
        tint(metal,.65);g.setLineWidth(.75)
        g.line(14,top+7,11,top+12,15,64);g.line(50,top+7,53,top+12,49,64)
        diamond(32,60,tier>=8 and 4 or 2.5)
    end
    if tier>=5 then
        tint(metal,1,.30)
        g.polygon("fill",15,20,10,6,23,12,32,1,41,12,54,6,49,20)
        tint(metal)
        g.polygon("fill",17,18,13,9,24,15,32,4,40,15,51,9,47,18)
        g.setColor(1,.98,.85,alpha*.9);g.line(14,9,24,15,32,4,40,15,50,9)
        tint(jewel,.7);g.rectangle("fill",18,19,28,2)
        diamond(32,12,tier>=8 and 4 or 2.7)
    end
    if tier>=8 then
        diamond(18,15,2.5);diamond(46,15,2.5)
        star(7,45,3,.8);star(57,45,3,.8)
    end
    if tier>=9 then
        tint(jewel,.9);g.setLineWidth(1.1)
        g.ellipse("line",27.5,66,5,2.7);g.ellipse("line",36.5,66,5,2.7)
    end
    if tier==10 then
        diamond(32,4,3.4);diamond(8,31,3);diamond(56,31,3)
        tint(metal,.85);g.line(20,69,32,73,44,69)
    end
    if tier>=5 and animate then
        g.setBlendMode("add")
        local phase=(t*.27+tier*.13)%1
        star(12+phase*40,top+2,2.3+(tier-5)*.25,.45+pulse*.4)
        if tier>=8 and visual.quality~="LOW" then
            for i=1,tier-6 do
                local angle=t*(.40+i*.06)+i*2.399
                star(32+math.cos(angle)*31.5,35+math.sin(angle)*31.5,1.5+i*.23,.35+pulse*.5)
            end
        end
        g.setBlendMode("alpha")
    end
    if overflow>0 then
        tint(jewel,.85)
        for i=1,math.min(overflow,4) do g.circle("fill",24+i*3.2,72,1,6) end
    end
    g.pop()
    local scale=math.min(bw*.66/math.max(1,font:getWidth(badge)),bh*.30/font:getHeight())
    local tx,ty=bw/2,bh*cy/76-font:getHeight()*scale/2
    g.translate(tx,ty);g.scale(scale)
    g.setFont(font)
    local tw=font:getWidth(badge)
    g.setColor(.005,.008,.015,alpha)
    g.print(badge,-tw/2+1.2,1.2)
    if tier>=5 then g.setColor(1,.96,.79,alpha) else g.setColor(.95,.97,1,alpha) end
    g.print(badge,-tw/2,0)
    g.pop()
end

return Frame

-- One base silhouette and metal rim for every card family.
local Frame = {}
Frame.color = {0.66, 0.55, 0.35, 1}
Frame.metal = {0.085, 0.075, 0.060, 1}
Frame.rimWidth = 2
local meshes = {}

local function outline(x, y, w, h, inset)
    local bevel = math.min(w, h) * 0.06
    inset = inset or 0
    local c = math.max(0, bevel - inset * 0.5)
    x, y, w, h = x + inset, y + inset, w - inset * 2, h - inset * 2
    return {x+c,y, x+w-c,y, x+w,y+c, x+w,y+h-c,
        x+w-c,y+h, x+c,y+h, x,y+h-c, x,y+c}
end

function Frame.image(image, x, y, w, h)
    if not image then return end
    local key = tostring(w) .. ":" .. tostring(h)
    local mesh = meshes[key]
    if not mesh then
        local points, vertices = outline(0, 0, w, h), {{w/2,h/2,0.5,0.5,1,1,1,1}}
        for i=1,16,2 do
            vertices[#vertices+1] = {points[i],points[i+1],points[i]/w,points[i+1]/h,1,1,1,1}
        end
        vertices[#vertices+1] = vertices[2]
        mesh = love.graphics.newMesh(vertices, "fan", "static")
        meshes[key] = mesh
    end
    mesh:setTexture(image)
    love.graphics.draw(mesh, x, y)
end

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
}
local rarityTier = require("src.deities").getRarityTier
function Frame.tier(card)
    local tier, overflow = rarityTier(card)
    -- Playing cards can gain ability levels temporarily during combat as well.
    local temporary = card and card.suit and math.max(0, math.floor(tonumber(card.temporaryAbilityLevels) or 0)) or 0
    local absolute = tier + overflow + temporary
    return math.min(#Frame.styles, absolute), math.max(0, absolute - #Frame.styles)
end

function Frame.socketPosition(index,w,h)
    local inset=math.min(w,h)*0.046
    local positions={{inset,inset},{w-inset,inset},{w-inset,h-inset},{inset,h-inset},
        {w/2,inset},{w-inset,h/2},{w/2,h-inset},{inset,h/2}}
    return positions[index][1],positions[index][2]
end

function Frame.socketGem(cx,cy,radius,color,alpha,pulse,linked)
    local g=love.graphics
    alpha,pulse=alpha or 1,pulse or 0
    g.setColor(0.018,0.026,0.038,alpha)
    g.circle("fill",cx,cy,radius*1.35,8)
    g.setLineWidth(math.max(0.7,radius*0.25))
    g.setColor(0.53,0.59,0.63,alpha*(color and 0.9 or 0.45))
    g.circle("line",cx,cy,radius*1.22,8)
    if not color then
        g.setColor(0.17,0.22,0.27,alpha*0.8);g.circle("fill",cx,cy,radius*0.65,4)
        return
    end
    if pulse>0 then
        g.setColor(color[1],color[2],color[3],alpha*pulse*0.25)
        g.circle("fill",cx,cy,radius*(1.8+pulse),12)
    end
    local strength=linked and 0.65 or 1
    g.setColor(color[1]*strength,color[2]*strength,color[3]*strength,alpha)
    g.polygon("fill",cx,cy-radius,cx+radius,cy,cx,cy+radius,cx-radius,cy)
    g.setColor(1,1,1,alpha*0.6)
    g.polygon("fill",cx,cy-radius,cx,cy,cx-radius,cy)
    g.setColor(0.01,0.025,0.045,alpha*0.45)
    g.polygon("fill",cx,cy,cx+radius,cy,cx,cy+radius)
    g.setColor(1,1,1,alpha*(0.7+pulse*0.3))
    g.circle("fill",cx-radius*0.2,cy-radius*0.4,math.max(0.5,radius*0.18),6)
end

function Frame.drawSockets(x,y,w,h,card,alpha)
    if not card or not card.rank or not card.suit then return end
    local E=require("src.equipment")
    local entries=E.getSocketEntries(card)
    local radius=math.min(w,h)*0.023
    for i=1,E.getMaxSlots(card) do
        local cx,cy=Frame.socketPosition(i,w,h)
        local entry=entries[i]
        local color=entry and E.getTierColor(entry.equipment)
        local pulse=entry and require("src.card_effects").getEquipmentPulse(card,entry.equipmentIndex) or 0
        Frame.socketGem(x+cx,y+cy,radius,color,alpha,pulse,entry and entry.linked)
    end
end

function Frame.draw(x, y, w, h, highlight, alpha, card)
    local g = love.graphics
    alpha = (alpha or 1) * (highlight and highlight[4] or 1)
    local tier, overflow = Frame.tier(card)
    local style = Frame.styles[tier]
    local size = math.min(w,h)
    local unit = math.max(0.6, math.min(1.6, size/128))
    local outer, inner = outline(x,y,w,h), outline(x,y,w,h,Frame.rimWidth)
    g.push("all"); g.setShader()
    g.setColor(Frame.metal[1],Frame.metal[2],Frame.metal[3],alpha)
    for i=1,16,2 do
        local j = i == 15 and 1 or i+2
        g.polygon("fill",outer[i],outer[i+1],outer[j],outer[j+1],inner[j],inner[j+1],inner[i],inner[i+1])
    end
    local color = style.metal
    -- Hover brightens the tier's metal without erasing its identity.
    local mix = highlight and 0.22 or 0
    local r,b,c = color[1]*(1-mix)+(highlight and highlight[1] or 0)*mix,
        color[2]*(1-mix)+(highlight and highlight[2] or 0)*mix,
        color[3]*(1-mix)+(highlight and highlight[3] or 0)*mix
    local stroke = (highlight and 2 or math.max(0.8,math.min(1.6,w*0.012))) + (tier-1)*0.10
    if tier >= 5 then
        -- Soft edge bloom stays INSIDE the face, including during dissolve.
        g.setColor(style.gem[1],style.gem[2],style.gem[3],alpha*0.12)
        g.setLineWidth(4*unit); g.polygon("line",outline(x,y,w,h,3*unit))
    end
    g.setColor(r,b,c,alpha); g.setLineWidth(stroke)
    g.polygon("line",outline(x,y,w,h,0.75))
    if tier == 1 then Frame.drawSockets(x,y,w,h,card,alpha);g.pop(); return end
    local bevel, reach = size*0.06,size*(0.055+0.012*tier)
    g.setLineWidth(math.max(0.75,unit))
    for _, corner in ipairs({{x,y,1,1},{x+w,y,-1,1},{x,y+h,1,-1},{x+w,y+h,-1,-1}}) do
        g.push(); g.translate(corner[1],corner[2]); g.scale(corner[3],corner[4])
        g.setColor(r,b,c,alpha)
        g.line(3*unit,bevel+reach,3*unit,bevel+2*unit,bevel+2*unit,3*unit,bevel+reach,3*unit)
        if tier >= 3 then
            g.polygon("fill",3*unit,bevel+3*unit,bevel+3*unit,3*unit,
                bevel+8*unit,3*unit,3*unit,bevel+8*unit)
        end
        if tier >= 4 then
            g.line(6*unit,bevel+reach*0.85,6*unit,bevel+6*unit,bevel+6*unit,6*unit,bevel+reach*0.85,6*unit)
        end
        if tier >= 6 then
            g.line(3*unit,bevel+reach,8*unit,bevel+reach-5*unit,6*unit,bevel+reach-10*unit)
            g.line(bevel+reach,3*unit,bevel+reach-5*unit,8*unit,bevel+reach-10*unit,6*unit)
        end
        if tier >= 7 and not (card and card.suit) then
            g.setColor(style.gem[1],style.gem[2],style.gem[3],alpha*0.85)
            g.circle("fill",bevel+7*unit,bevel+7*unit,1.3*unit)
        end
        g.pop()
    end
    local function gem(cx,cy,radius)
        g.setColor(0.035,0.045,0.060,alpha)
        g.polygon("fill",cx,cy-radius-unit,cx+radius+unit,cy,cx,cy+radius+unit,cx-radius-unit,cy)
        g.setColor(style.gem[1],style.gem[2],style.gem[3],alpha)
        g.polygon("fill",cx,cy-radius,cx+radius,cy,cx,cy+radius,cx-radius,cy)
        g.setColor(1,0.97,0.89,alpha*0.9);g.line(cx-radius*0.5,cy,cx,cy-radius*0.5)
    end
    local radius = (tier >= 5 and 3 or 2)*unit
    if tier >= 3 and not (card and card.suit) then gem(x+w/2,y+h-5*unit,radius) end
    if tier >= 4 and not (card and card.suit) then gem(x+w/2,y+5*unit,radius) end
    if tier >= 5 then
        g.setColor(r,b,c,alpha)
        for _, cy in ipairs({y+5*unit,y+h-5*unit}) do
            g.line(x+w/2-15*unit,cy,x+w/2-8*unit,cy+3*unit,x+w/2,cy)
            g.line(x+w/2+15*unit,cy,x+w/2+8*unit,cy+3*unit,x+w/2,cy)
        end
    end
    if tier >= 6 and not (card and card.suit) then gem(x+5*unit,y+h/2,radius); gem(x+w-5*unit,y+h/2,radius) end
    if tier >= 7 then
        g.setColor(r,b,c,alpha*0.55);g.setLineWidth(unit*0.7)
        for _, cx in ipairs({x+4*unit,x+w-4*unit}) do
            g.line(cx,y+h*0.32,cx,y+h*0.44);g.line(cx,y+h*0.56,cx,y+h*0.68)
        end
    end
    if tier == 8 then
        g.setColor(r,b,c,alpha);g.setLineWidth(unit)
        for _, cy in ipairs({y+6*unit,y+h-6*unit}) do
            g.line(x+w/2-22*unit,cy,x+w/2-13*unit,cy+5*unit,x+w/2-7*unit,cy,
                x+w/2,cy+7*unit,x+w/2+7*unit,cy,x+w/2+13*unit,cy+5*unit,x+w/2+22*unit,cy)
        end
    end
    -- Overflow is still visible after UQ; the badge retains the exact level.
    if overflow > 0 then
        g.setColor(1,0.94,0.76,alpha)
        for i=1,math.min(overflow,8) do
            local dx=(i-(math.min(overflow,8)+1)/2)*4*unit
            g.line(x+w/2+dx,y+h-16*unit,x+w/2+dx,y+h-14*unit)
        end
    end
    Frame.drawSockets(x,y,w,h,card,alpha)
    g.pop()
end

function Frame.pennantRect(w, h)
    local margin = math.max(2, math.min(w,h)*0.05 + 1)
    local fw, fh = math.min(36,w*0.30), math.min(28,h*0.20)
    return w-margin-fw, margin, fw, fh
end

return Frame

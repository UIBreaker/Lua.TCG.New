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

function Frame.draw(x, y, w, h, highlight, alpha, card)
    local g = love.graphics
    alpha = alpha or 1
    local level = math.max(0, math.floor(tonumber(card and card.evolutionLevel) or 0))
    local outer = outline(x, y, w, h)
    -- A narrow rim overlays the artwork edge; there is no inset matte.
    local inner = outline(x, y, w, h, Frame.rimWidth)
    g.push("all"); g.setShader()
    g.setColor(Frame.metal[1], Frame.metal[2], Frame.metal[3], alpha)
    for i=1,16,2 do
        local j = i == 15 and 1 or i+2
        g.polygon("fill", outer[i],outer[i+1],outer[j],outer[j+1],
            inner[j],inner[j+1],inner[i],inner[i+1])
    end
    local polish = 1 - 1 / (1 + level * 0.22)
    local color = highlight or {Frame.color[1]+0.30*polish,Frame.color[2]+0.34*polish,Frame.color[3]+0.40*polish,1}
    g.setColor(color[1],color[2],color[3],(color[4] or 1)*alpha)
    g.setLineWidth((highlight and 2 or math.max(0.8,math.min(1.6,w*0.012))) + polish * 0.8)
    g.polygon("line", outline(x,y,w,h,0.75))
    if level > 0 then
        -- Engravings share the face's local transform, so they never stay behind.
        local size = math.min(w,h)
        local bevel, reach = size*0.06, size*(0.06+0.008*math.min(level,8))
        g.setColor(0.95,0.80+0.12*polish,0.48+0.35*polish,alpha)
        g.setLineWidth(math.max(0.8,math.min(1.3,w*0.01)))
        for _, corner in ipairs({{x,y,1,1},{x+w,y,-1,1},{x,y+h,1,-1},{x+w,y+h,-1,-1}}) do
            g.push(); g.translate(corner[1],corner[2]); g.scale(corner[3],corner[4])
            g.line(2.5,bevel+reach,2.5,bevel+2,bevel+2,2.5,bevel+reach,2.5)
            if level >= 4 then
                g.line(4.5,bevel+reach*0.7,4.5,bevel+4,bevel+4,4.5,bevel+reach*0.7,4.5)
            end
            g.pop()
        end
        local function gem(cx,cy,r)
            g.setColor(0.085,0.075,0.060,alpha)
            g.polygon("fill",cx,cy-r-1,cx+r+1,cy,cx,cy+r+1,cx-r-1,cy)
            g.setColor(0.96,0.79+0.14*polish,0.42+0.45*polish,alpha)
            g.polygon("fill",cx,cy-r,cx+r,cy,cx,cy+r,cx-r,cy)
            g.setColor(1,0.98,0.83,alpha); g.line(cx-r*0.5,cy,cx,cy-r*0.5)
        end
        local radius = math.max(1.2, math.min(3,w*0.025))
        if level >= 2 then gem(x+w/2,y+h-4,radius) end
        if level >= 3 then gem(x+w/2,y+4,radius) end
        if level >= 5 then gem(x+4,y+h/2,radius);gem(x+w-4,y+h/2,radius) end
        -- One additional engraved mark per evolution; overflow remains explicit.
        g.setColor(color[1],color[2],color[3],alpha)
        for i=1,math.min(level,12) do
            local dx=(i-(math.min(level,12)+1)/2)*math.min(5,w*0.035)
            g.line(x+w/2+dx,y+h-9,x+w/2+dx,y+h-7)
        end
        if level>12 then
            g.push();g.translate(x+w/2,y+h-16);g.scale(0.55)
            g.printf("+"..level,-w/2,0,w,"center");g.pop()
        end
    end
    g.pop()
end

function Frame.pennantRect(w, h)
    local margin = math.max(2, math.min(w,h)*0.05 + 1)
    local fw, fh = math.min(36,w*0.30), math.min(28,h*0.20)
    return w-margin-fw, margin, fw, fh
end

return Frame

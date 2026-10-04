-- Presentation only: numbers always come from the resolved gameplay result.
local F = {}
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
    local duration = kind == "damage" and (1.25 + tier * 0.16) or 1.35
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
    for _,offset in ipairs({{-2,0},{2,0},{0,-2},{0,2}}) do
        g.printf(text,x+offset[1],y+offset[2],width,"center")
    end
    g.setColor(color[1],color[2],color[3],alpha)
    g.printf(text,x,y,width,"center")
end

function F.draw(ft, ui)
    local g = love.graphics
    local age, tier = ft.age or 0, ft.tier or 1
    local alpha = ft.kind and ft.alpha or math.min(1, ft.life and ft.life/0.35 or ft.alpha or 1)
    local color = ft.color or {1,1,1}
    g.push("all")
    local rise = ft.kind and (1-math.exp(-age*2.5))*42 or 0
    g.translate(ft.x, math.max(72,ft.y-rise))
    local scale = ft.kind and (1+(tier-1)*0.13+(0.24+tier*0.045)*math.exp(-age*10)*math.sin(age*24)) or ft.scale or 1
    g.scale(scale)
    if ft.kind == "damage" and tier >= 3 then
        local p = math.min(1, age/0.42)
        g.setColor(color[1],color[2],color[3],alpha*(1-p)*0.65)
        g.setLineWidth(2)
        g.ellipse("line",0,17,35+p*(35+tier*8),12+p*17)
        for i=1,4+tier*2 do
            local angle = i*math.pi*2/(4+tier*2)
            local radius = 24+p*(30+tier*9)
            g.line(math.cos(angle)*radius,17+math.sin(angle)*radius*0.5,
                math.cos(angle)*(radius+7),17+math.sin(angle)*(radius+7)*0.5)
        end
    elseif ft.kind == "gold" and ft.amount > 0 then
        local count = math.min(12, 4+math.floor(math.sqrt(ft.amount)))
        for i=1,count do
            local p = math.max(0,math.min(1,(age-i*0.025)/0.75))
            local target = ft.target or {x=ft.x,y=ft.y-58}
            local x = (target.x-ft.x)*p + math.sin(i*2.4)*(1-p)*48
            local y = (target.y-ft.y)*p+rise+36*(1-p)-math.sin(p*math.pi)*(28+i*2)
            g.setColor(1,0.70,0.12,alpha*math.sin(p*math.pi))
            g.ellipse("fill",x,y,3+math.abs(math.cos(age*12+i))*2,5)
            g.setColor(1,0.94,0.55,alpha*math.sin(p*math.pi))
            g.ellipse("line",x,y,3+math.abs(math.cos(age*12+i))*2,5)
        end
    end
    local text = ui.sanitizeText and ui.sanitizeText(ft.text) or ft.text
    local font = (ft.kind == "damage" or not ft.life) and ui.fonts.large
        or ft.kind and (ui.fonts.regular or ui.fonts.medium) or ui.fonts.medium
    g.setFont(font)
    -- Long legacy notifications wrap; damage values stay on a single fitted line.
    if ft.kind and font:getWidth(text)>420 then g.scale(420/font:getWidth(text)) end
    outlined(g,text,-230,0,460,color,alpha)
    if ft.label then
        g.setFont(ui.fonts.tiny or ui.fonts.small)
        outlined(g,ft.label,-230,font:getHeight()+3,460,color,alpha*0.85)
    end
    g.pop()
end

return F

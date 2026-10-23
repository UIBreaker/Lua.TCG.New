-- Canonical steel shield. All sizes share the parry silhouette and metal facets.
local S={}
local function color(c,a) love.graphics.setColor(c[1],c[2],c[3],a) end
local function stroke(points,c,a,width)
    color(c,a);love.graphics.setLineWidth(width);love.graphics.line(points)
end
function S.draw(x,y,height,c,alpha,options)
    options=options or {};alpha=alpha or 1
    if height<=0 or alpha<=0 then return end
    c=c or {.24,.90,1}
    local g=love.graphics;local broken=options.broken
    local flash=math.max(0,math.min(1,options.flash or 0))
    g.push("all");g.setShader();g.setBlendMode("alpha")
    g.translate(x,y);g.scale(height/74);g.translate(0,-3)
    -- A solid steel kite shield: beveled rim, two metal faces and a raised spine.
    -- Broken halves use the same silhouette, with no intact shield underneath.
    local sides=options.partial and {-1} or {-1,1}
    for _,side in ipairs(sides) do
        g.push("all")
        if broken then
            local split=options.split or 5
            g.translate(side*split,split*.3);g.rotate(side*(options.tilt or .10))
        end
        local rim=broken and {1,.30,.18} or side==-1 and {.78,.88,.95} or {.30,.46,.60}
        color(rim,alpha*.98)
        g.polygon("fill",0,-34,side*29,-26,side*26,7,side*15,25,0,40)
        local face=side==-1 and {.24,.35,.46} or {.075,.14,.22}
        color({face[1]+(1-face[1])*flash*.65,face[2]+(1-face[2])*flash*.65,face[3]+(1-face[3])*flash*.65},alpha*.98)
        g.polygon("fill",0,-29,side*24,-22,side*21,5,side*12,22,0,33)
        color(c,alpha*(broken and .35 or .55))
        g.polygon("fill",side*23,-21,side*20,4,side*11,20,side*14,3)
        color(side==-1 and {.64,.76,.86} or {.18,.29,.40},alpha)
        g.polygon("fill",0,-29,side*3,-24,side*3,20,0,33)
        stroke({0,-34,side*29,-26,side*26,-13},broken and c or {.92,.97,1},alpha,1.4)
        if broken then
            stroke({0,-29,side*5,-12,0,-3,side*4,10,0,33},c,alpha,1.3)
        end
        g.pop()
    end
    g.pop()
end

-- Replace shield emoji in UI text with the same native drawing, including wrapped lines.
function S.printf(value,x,y,width,align,hideShield)
    local g=love.graphics;local text=tostring(value or "")
    if not text:find("🛡",1,true) then return g.printf(text,x,y,width,align or "left") end
    local font=g.getFont();local _,lines=font:getWrap(text,width)
    local r,green,b,a=g.getColor();local h=font:getHeight()
    for row,line in ipairs(lines) do
        local runs={};local cursor=1;local total=0
        while cursor<=#line do
            local first,last=line:find("🛡",cursor,true)
            local part=first and line:sub(cursor,first-1) or line:sub(cursor)
            if #part>0 then
                local w=font:getWidth(part);runs[#runs+1]={text=part,width=w};total=total+w
            end
            if not first then break end
            if line:sub(last+1,last+3)=="️" then last=last+3 end
            local w=math.max(h*.72,font:getWidth(line:sub(first,last)))
            runs[#runs+1]={width=w};total=total+w;cursor=last+1
        end
        local px=x+(align=="center" and (width-total)/2 or align=="right" and width-total or 0)
        local py=y+(row-1)*h*font:getLineHeight()
        for _,run in ipairs(runs) do
            if run.text then g.print(run.text,px,py)
            elseif not hideShield then S.draw(px+run.width/2,py+h/2,h*.92,{r,green,b},a) end
            px=px+run.width
        end
    end
end
return S

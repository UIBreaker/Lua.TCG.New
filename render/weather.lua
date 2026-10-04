-- Analytic weather: independent of gameplay RNG, no particles allocated per frame.
local C = require("config.visual_config")
local Lighting = require("render.lighting")
local W = {}
local sunColor = {1, 0.85, 0.58}
local stormColor = {0.52, 0.72, 1}
local auroraColor = {0.24, 0.92, 0.72}
local violet = {0.65, 0.38, 1}
local ember = {1, 0.44, 0.12}
local sand = {0.86, 0.66, 0.36}
local crystal = {0.42, 0.85, 1}
local spores = {0.52, 0.95, 0.57}
local profiles = {
    {kind="sun", wind=0.35, sun=1, rain=0, fog=0.25},
    {kind="wind", wind=1, sun=0.35, rain=0, fog=0.4},
    {kind="rain", wind=0.7, sun=0, rain=1, fog=0.6},
    {kind="fog", wind=0.25, sun=0.12, rain=0, fog=1},
    {kind="storm", wind=0.85, sun=0, rain=1, fog=0.65, color=stormColor, shade=0.24},
    {kind="aurora", wind=0.2, sun=0, rain=0, fog=0.45, color=auroraColor, shade=0.48},
    {kind="meteor", wind=0.15, sun=0, rain=0, fog=0.2, color=sunColor, shade=0.38},
    {kind="sandstorm", wind=1, sun=0.25, rain=0, fog=0.85, color=sand},
    {kind="ash", wind=0.55, sun=0, rain=0, fog=0.55, color=ember, shade=0.18},
    {kind="crystal", wind=0.25, sun=0, rain=0, fog=0.4, color=crystal, shade=0.25},
    {kind="spores", wind=0.2, sun=0, rain=0, fog=0.7, color=spores, shade=0.3},
    {kind="eclipse", wind=0.3, sun=0, rain=0, fog=0.65, color=violet, shade=0.5},
    {kind="astral", wind=0.25, sun=0, rain=0, fog=0.35, color=violet, shade=0.38},
    {kind="fireflies", wind=0.15, sun=0.18, rain=0, fog=0.55, color=sunColor, shade=0.38},
}
W.profiles = profiles
function W.resolve(monster)
    local stage = math.max(1, math.floor(tonumber(monster and monster.stage) or 1))
    return profiles[(stage - 1) % #profiles + 1]
end

local function sky(time, weather, quality)
    local g, kind, color = love.graphics, weather.kind, weather.color or sunColor
    if weather.shade then
        -- Dusk only affects the painting: enemy cards and all UI stay sharp.
        g.setBlendMode("alpha")
        g.setColor(color[1]*0.025,color[2]*0.025,color[3]*0.025,weather.shade)
        g.rectangle("fill",0,0,1280,720)
    end
    g.setBlendMode("add", "alphamultiply")
    if kind == "aurora" then
        -- Overlapping translucent ribbons, with moving crests and feathered edges.
        local segments = math.floor(quality.particles * 0.45) + 8
        for ribbon = 1, 3 do
            for j = 0, segments-1 do
                local x, nextX = 120+j*1040/segments, 120+(j+1)*1040/segments
                local y = 93+ribbon*22+math.sin(x*0.007+time*0.22+ribbon)*26
                local nextY = 93+ribbon*22+math.sin(nextX*0.007+time*0.22+ribbon)*26
                local fade = math.sin((j+0.5)/segments*math.pi)^2
                for band=3,1,-1 do
                    local height=band*14
                    g.setColor(0.18+ribbon*0.08, 0.95-ribbon*0.15, 0.56+ribbon*0.14, fade*0.12)
                    g.polygon("fill",x,y-height,nextX,nextY-height,nextX,nextY+height,x,y+height)
                end
            end
        end
        Lighting.glow(650,155,370,color,0.14)
    elseif kind == "storm" then
        -- One distant strike every eight seconds; no full-screen white strobe.
        local phase = time % 8
        local flash = math.max(0,1-math.abs(phase-1.2)/0.32)
        if flash>0 then
            local x=320+(math.floor(time/8)*337)%680
            Lighting.glow(x,145,330,color,flash*0.35)
            for band=3,1,-1 do
                g.setLineWidth(band*2)
                g.setColor(color[1],color[2],color[3],flash*(band==1 and 0.8 or 0.12))
                g.line(x,75,x-22,119,x+5,143,x-31,183,x-12,194,x-54,243)
                g.line(x+5,143,x+39,160,x+48,188)
            end
        end
    elseif kind == "meteor" then
        for i=1,3 do
            local phase=(time+i*2.6)%9
            if phase<2 then
                local p=phase/2
                local x=280+i*190-p*245
                local y=76+p*195
                local fade=math.sin(p*math.pi)
                for tail=1,10 do
                    g.setLineWidth(1+(10-tail)*0.22)
                    g.setColor(1,0.58+tail*0.032,0.28+tail*0.05,fade*(1-tail/11)*0.6)
                    g.line(x+tail*9,y-tail*7,x+(tail+1)*9,y-(tail+1)*7)
                end
                Lighting.glow(x,y,25,color,fade*0.7)
                g.setColor(1,0.93,0.75,fade); g.circle("fill",x,y,2.2)
            end
        end
    elseif kind == "eclipse" then
        local x,y=890,110+math.sin(time*0.15)*4
        Lighting.glow(x,y,190,color,0.36)
        for i=4,1,-1 do
            g.setLineWidth(i*3)
            g.setColor(0.8,0.55,1,0.09+i*0.012)
            g.circle("line",x,y,42+math.sin(time*0.6)*1.5)
        end
        g.setBlendMode("alpha")
        g.setColor(0.035,0.025,0.065,0.96); g.circle("fill",x,y,40)
    elseif kind == "ash" or kind == "crystal" or kind == "spores" or kind == "astral" then
        Lighting.glow(680,370,300,color,0.10+0.025*math.sin(time*0.6))
    end
    g.setBlendMode("alpha")
end

local function unusualParticles(time, weather, quality)
    local g,kind,color=love.graphics,weather.kind,weather.color or sunColor
    if kind=="sun" or kind=="wind" or kind=="rain" or kind=="fog" or kind=="storm" then return end
    local count=quality.particles
    g.setBlendMode("add","alphamultiply")
    for i=1,count do
        local depth=(i%11)/11
        local x=(i*173.13+time*(8+weather.wind*35)+math.sin(time*0.7+i)*18)%1320-20
        local y=95+(i*91.7-time*(6+depth*13))%350
        local pulse=0.4+0.6*math.sin(time*(0.7+depth)+i)^2
        local alpha=(0.22+depth*0.5)*pulse
        local size=1+depth*2.4
        g.setColor(color[1],color[2],color[3],alpha)
        if kind=="crystal" then
            y=75+(i*91.7+time*(28+depth*40))%365
            local a=time*0.65+i
            local dx,dy=math.cos(a)*size,math.sin(a)*size
            g.polygon("fill",x-dx,y-dy,x-dy*0.5,y+dx*0.5,x+dx,y+dy,x+dy*0.5,y-dx*0.5)
            if i%5==0 then Lighting.glow(x,y,19,color,alpha*0.24) end
        elseif kind=="sandstorm" then
            g.setBlendMode("alpha")
            x=(i*193.13+time*(150+depth*130))%1420-70
            y=160+(i*73.7)%280+math.sin(time*1.8+i)*18
            g.setLineWidth(0.6+depth)
            g.line(x,y,x+16+depth*36,y-4)
            g.circle("fill",x,y,size*0.65)
        elseif kind=="astral" then
            y=80+(i*91.7-time*(45+depth*70))%350
            g.setLineWidth(0.6+depth)
            g.line(x,y,x-3,y+12+depth*14)
            g.setColor(0.85,0.72,1,alpha)
            g.line(x-size,y,x+size,y); g.line(x,y-size,x,y+size)
        elseif kind=="spores" then
            x=x+math.sin(time*0.6+i)*20
            g.setLineWidth(0.8)
            g.circle("line",x,y,size+1)
            g.circle("fill",x,y,0.7)
            if i%4==0 then Lighting.glow(x,y,23,color,alpha*0.3) end
        elseif kind=="ash" then
            y=115+(i*91.7-time*(23+depth*42))%320
            g.setLineWidth(0.7+depth)
            g.line(x,y,x-4,y+6+depth*10)
            g.circle("fill",x,y,size*0.65)
            if i%6==0 then Lighting.glow(x,y,24,color,alpha*0.28) end
        else
            -- Drifting stars / fireflies follow curved paths with breathing halos.
            x=x+math.sin(time*0.5+i)*24
            g.circle("fill",x,y,size*0.55)
            if i%3==0 then Lighting.glow(x,y,15+depth*16,color,alpha*0.35) end
        end
    end
    g.setBlendMode("alpha")
end

function W.draw(stage, time, preset, weather, quality, view)
    if not C.enabled or not weather then return end
    local g = love.graphics
    local gust = 0.65 + 0.35 * math.sin(time * 0.7)^2
    g.push("all")
    if stage == "before" and C.effects.lighting then
        sky(time,weather,quality)
        if weather.sun > 0 then
        -- Broad, feathered shafts and a soft source glow, behind enemies.
        g.setBlendMode("add", "alphamultiply")
        local strength = weather.sun * (0.85 + 0.15 * math.sin(time * 0.35))
        Lighting.glow(970, 95, 310, sunColor, strength * 0.15)
        for i = 1, 3 do
            local x = 820 + i * 88 + math.sin(time * 0.18 + i) * 18
            for band = 5, 1, -1 do
                local width = 10 + band * 9
                g.setColor(1, 0.87, 0.62, strength * 0.009)
                g.polygon("fill", x-width, 65, x+width, 65,
                    x-160+width*2.2, 455, x-160-width*2.2, 455)
            end
        end
        end
    elseif stage == "after" then
        if C.effects.fog and Lighting.radial and view ~= "PARTICLES" then
            -- Feathered mist banks near the ground instead of hard ellipse edges.
            local f = weather.color or preset.fogColor
            for i = 1, 8 do
                local x = (i * 179 + time * (8 + weather.wind * 20)) % 1580 - 150
                local y = 380 + math.sin(time * 0.2 + i * 1.8) * 26 + math.sin(time*0.55+i)*weather.wind*7
                local width = 190 + math.sin(i * 2.1) * 35
                local height = 36 + weather.fog * 36
                g.setColor(0.5+f[1]*0.5, 0.5+f[2]*0.5, 0.5+f[3]*0.5, weather.fog * preset.fogDensity * 0.34)
                g.draw(Lighting.radial, x-width, y-height, 0, width/64, height/64)
            end
        end
        if C.effects.particles and view ~= "FOG" then
            unusualParticles(time,weather,quality)
            local count = quality.particles
            local windCount = weather.color and 0 or math.floor(count * weather.wind * 0.55)
            if weather.kind=="storm" then windCount=math.floor(count*0.2) end
            -- Thin gust trails and airborne dust share the same moving flow.
            for i = 1, windCount do
                local depth = (i % 7) / 7
                local x = (i * 173.13 + time * (55 + depth * 60) * weather.wind) % 1380 - 50
                local y = 110 + (i * 91.7) % 310 + math.sin(time * 1.1 + i) * 8
                g.setColor(preset.fogColor[1], preset.fogColor[2], preset.fogColor[3], (0.12 + depth * 0.12) * gust)
                g.setLineWidth(0.6 + depth * 0.5)
                local length=12+depth*28
                g.line(x,y,x+length*0.45,y-2-math.sin(time*0.8+i)*2,x+length,y-2)
                g.circle("fill", x, y, 0.6 + depth)
            end
            for i = 1, math.floor((count - windCount) * weather.rain) do
                local depth = (i % 9) / 9
                local speed = 210 + depth * 190
                local x = (i * 137.3 + time * 75 * weather.wind) % 1340 - 30
                local y = 65 + (i * 83.7 + time * speed) % 390
                local length = 10 + depth * 15
                g.setLineWidth(0.7 + depth * 0.6)
                g.setColor(0.62, 0.78, 0.88, 0.16 + depth * 0.22)
                g.line(x, y, x + length * 0.25 * weather.wind, math.min(455, y + length))
                -- Small expanding rings suggest rain hitting the arena floor.
                if i % 4 == 0 then
                    local age = (time * 1.7 + i * 0.31) % 1
                    g.setColor(0.62, 0.78, 0.88, (1-age) * 0.16)
                    g.ellipse("line", 180 + (i * 113) % 920, 406 + (i * 17) % 38, 2+age*7, 0.7+age*2)
                end
            end
        end
    end
    g.pop()
end
return W

local C=require("config.visual_config")
local L={points={},events={}}
function L.load()
    local data=love.image.newImageData(128,128)
    for y=0,127 do for x=0,127 do
        local distance=math.sqrt(((x-63.5)/63.5)^2+((y-63.5)/63.5)^2)
        local a=math.max(0,1-distance)^2
        data:setPixel(x,y,1,1,1,a)
    end end
    L.radial=love.graphics.newImage(data); L.radial:setFilter("linear","linear"); data:release()
    L.addPoint("left_lamp",350,331,150,{1,0.62,0.28},C.lighting.practical)
    L.addPoint("right_lamp",930,331,150,{1,0.62,0.28},C.lighting.practical)
end
function L.addPoint(id,x,y,radius,color,strength)
    L.points[id]={x=x,y=y,radius=radius,color=color,strength=strength or 0.1}
end
function L.setAmbient(color) L.ambient=color end
function L.flash(x,y,color,strength,duration,radius)
    if #L.events>=8 then table.remove(L.events,1) end
    L.events[#L.events+1]={x=x,y=y,color=color,strength=strength,duration=duration or 0.3,
        age=0,radius=radius or 210}
end
function L.update(dt)
    for i=#L.events,1,-1 do
        local light=L.events[i]; light.age=light.age+dt
        if light.age>=light.duration then table.remove(L.events,i) end
    end
end
function L.glow(x,y,radius,color,strength)
    if not L.radial then return end
    local g=love.graphics
    g.setColor(color[1],color[2],color[3],strength)
    g.draw(L.radial,x-radius,y-radius,0,radius/64,radius/64)
end
function L.draw(preset,time,eventStrength,eventX,eventY)
    local g=love.graphics; g.setBlendMode("add","alphamultiply")
    for _,light in pairs(L.points) do
        L.glow(light.x,light.y,light.radius,preset.lightTint,light.strength*(0.95+0.05*math.sin(time*3.1+light.x))*(1-(L.presentationDim or 0)))
    end
    if eventStrength>0 then L.glow(eventX or 630,eventY or 300,250,C.palette.magic,eventStrength*C.lighting.event) end
    for _,light in ipairs(L.events) do
        L.glow(light.x,light.y,light.radius,light.color,light.strength*(1-light.age/light.duration)^2)
    end
    g.setBlendMode("alpha")
end
return L

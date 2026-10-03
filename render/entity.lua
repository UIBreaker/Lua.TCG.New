local C=require("config.visual_config")
local L=require("render.lighting")
local Entity={}
function Entity.load()
    local ok,shader=pcall(love.graphics.newShader,"shaders/world_entity.glsl")
    if ok then Entity.shader=shader else Entity.error=tostring(shader);print("[HD2D] Entity shader fallback: "..Entity.error) end
end
function Entity.shadow(x,y,size,height)
    local g=love.graphics; height=math.max(0,height or 0)
    for i=5,1,-1 do
        g.setColor(0.005,0.009,0.017,C.boss.shadow/(5+height*0.05))
        g.ellipse("fill",x+height*0.10,y+height*0.05,size*(0.22+i*0.032)*(1+height*0.002),5+i*3)
    end
    g.setColor(0.003,0.006,0.011,0.23/(1+height*0.08));g.ellipse("fill",x,y,size*0.20,7)
end
function Entity.draw(image,x,y,size,time,attack,hit,recoil,squash,preset,eventStrength)
    if not image then return end
    local g=love.graphics;local iw,ih=image:getDimensions(); local fit=math.min(size/iw,size/ih)
    g.push("all")
    Entity.shadow(x,414,size,math.abs(attack)*16)
    if C.enabled and C.effects.lighting then
        g.setBlendMode("add");L.glow(x,y,size*0.47,preset.lightTint,0.025+eventStrength*0.06);g.setBlendMode("alpha")
    end
    g.translate(x+attack*50-hit*5,y-attack*20+recoil)
    local breath=C.enabled and 1+math.sin(time*1.35)*C.boss.breath or 1
    g.scale(squash/breath,breath/squash)
    g.rotate(math.sin(time*0.7)*0.008-attack*0.08+hit*0.07)
    if Entity.shader and C.enabled and C.effects.lighting then
        local shader=Entity.shader;shader:send("texel",{1/iw,1/ih});shader:send("ambientTint",preset.ambientColor)
        shader:send("rimTint",preset.lightTint);shader:send("rimStrength",C.boss.rim)
        shader:send("tintStrength",C.boss.tint);shader:send("eventLight",eventStrength);g.setShader(shader)
    end
    g.setColor(1,1-hit*0.20,1-hit*0.25,1)
    g.draw(image,-iw*fit/2,-ih*fit/2,0,fit,fit);g.pop()
end
return Entity

local Definitions = require("config.scene_definitions")
local C = require("config.visual_config")
local Weather = require("render.weather")
local Scene = { definitions = Definitions }
function Scene.load(art)
    Scene.art = art; Scene.textures={}; Scene.time=0
    for _,definition in pairs(Definitions.scenes) do
        for _,layer in ipairs(definition.layers or Definitions.layers) do
            if layer.texture and not Scene.textures[layer.texture] and love.filesystem.getInfo(layer.texture) then
                local ok,texture=pcall(love.graphics.newImage,layer.texture)
                if ok then texture:setFilter("linear","linear"); Scene.textures[layer.texture]=texture end
            end
        end
    end
end
function Scene.update(dt, state, monster)
    Scene.time=Scene.time+dt
    Scene.name, Scene.definition, Scene.preset = Definitions.resolve(state, monster)
    Scene.weather = Scene.name == "battle" and Weather.resolve(monster) or nil
end
local function imageCover(image,brightness,tint)
    local g=love.graphics; local w,h=image:getDimensions(); local fit=math.max(1280/w,720/h)
    g.setColor(brightness*tint[1],brightness*tint[2],brightness*tint[3],1)
    g.draw(image,(1280-w*fit)/2,(720-h*fit)/2,0,fit,fit)
end
local function drawLayer(layer,particleCap)
    local g,d,p,t=love.graphics,Scene.definition,Scene.preset,Scene.time
    local image=layer.texture and Scene.textures[layer.texture]
    local b=layer.brightness or 1; local tint=layer.tint or {1,1,1}
    g.setColor(tint[1]*b,tint[2]*b,tint[3]*b,1)
    if image then imageCover(image,b,tint)
    elseif layer.kind=="base" then
        image=d.video and Scene.art.menuVideo or Scene.art[d.base] or Scene.art.background
        if image then imageCover(image,d.brightness*b,tint) end
    elseif layer.kind=="arches" then
        -- A separate distant silhouette, never a duplicate of the base painting.
        for _,x in ipairs({215,1000}) do
            g.setColor(0.12,0.16,0.21,0.30)
            g.rectangle("fill",x,155,24,245)
            g.rectangle("fill",x+55,155,24,245)
            g.arc("line","open",x+40,161,39,math.pi,2*math.pi)
        end
    elseif layer.kind=="columns" then
        for _,x in ipairs({252,995}) do
            g.setColor(tint[1]*b,tint[2]*b,tint[3]*b,0.66)
            g.polygon("fill",x,97,x+24,89,x+29,389,x-5,399)
            g.setColor(0.56,0.49,0.35,0.09); g.line(x+5,110,x+7,379)
        end
    elseif layer.kind=="arena" then
        g.setColor(0.02,0.03,0.048,0.16); g.ellipse("fill",630,417,228,43)
        g.setColor(tint[1],tint[2],tint[3],0.15); g.setLineWidth(1)
        g.ellipse("line",630,417,232,44); g.ellipse("line",630,417,215,38)
        for i=1,12 do
            local a=i*math.pi/6
            g.line(630+math.cos(a)*215,417+math.sin(a)*38,630+math.cos(a)*229,417+math.sin(a)*43)
        end
    elseif layer.kind=="fog" and not Scene.weather and C.effects.fog and C.enabled then
        local f=p.fogColor; local density=C.fog.density*p.fogDensity
        for i=1,9 do
            local x=160+i*106+math.sin(t*C.fog.speed+i*1.7)*50+math.sin(i*1.7)*(Scene.attackPulse or 0)*25
            local y=399+math.sin(t*0.17+i)*16
            for band=3,1,-1 do
                g.setColor(f[1],f[2],f[3],density*0.12)
                g.ellipse("fill",x,y,110+band*16,10+band*8)
            end
        end
    elseif layer.kind=="particles" and not Scene.weather and C.effects.particles and C.enabled then
        local color=p.particleType=="embers" and C.palette.reward or p.lightTint
        -- Deterministic analytic particles: no gameplay RNG or per-frame tables.
        for i=1,particleCap do
            local depth=(i%7)/7; local speed=p.particleType=="snow" and 12 or -5-depth*7
            local x=(i*173.13+t*(3+depth*5)+math.sin(t*0.3+i)*8)%1340-30
            local y=(i*91.7+t*speed)%690
            if x>12 and x<1268 and y>65 and y<665 then
                local alpha=(0.09+depth*0.20)*(0.6+0.4*math.sin(t+i)^2)
                g.setColor(color[1],color[2],color[3],alpha)
                g.circle("fill",x,y,0.65+depth*1.1)
            end
        end
    elseif layer.kind=="foreground" then
        -- Close stone fragments along the lower edges; gameplay remains clear.
        g.setColor(tint[1]*b,tint[2]*b,tint[3]*b,0.76)
        g.polygon("fill",-20,540,38,503,92,582,119,720,-20,740)
        g.polygon("fill",1184,650,1214,539,1286,516,1300,740,1164,740)
    end
end
function Scene.drawSingle(layer,camera,quality,depthShader)
    local g=love.graphics
    g.push("all"); camera.apply(C.enabled and layer.parallaxFactor or 0)
    g.translate(640,360); g.scale(layer.scale or 1); g.translate(-640,-360)
    g.translate(layer.offset[1],layer.offset[2])
    if depthShader and C.effects.dof and quality.dof and C.enabled and layer.blurAmount>0 then
        local texture=layer.texture and Scene.textures[layer.texture] or layer.kind=="base" and
            (Scene.definition.video and Scene.art.menuVideo or Scene.art[Scene.definition.base] or Scene.art.background)
        -- Video uses LÖVE's YCbCr decoder shader, not the image Texel() DOF pass.
        if texture and not texture:typeOf("Video") then
            depthShader:send("texel",{1/texture:getWidth(),1/texture:getHeight()})
            depthShader:send("radius",layer.blurAmount); g.setShader(depthShader)
        end
    end
    drawLayer(layer,quality.particles); g.pop()
end
function Scene.draw(stage,camera,quality,depthShader)
    local g=love.graphics
    if stage=="before" then
        g.setColor(0.018,0.026,0.043,1); g.rectangle("fill",0,0,1280,720)
    end
    for _,layer in ipairs(Scene.definition.layers or Definitions.layers) do
        if layer.stage==stage then
            Scene.drawSingle(layer,camera,quality,depthShader)
        end
    end
    if Scene.weather then
        g.push("all"); camera.apply(C.enabled and 0.4 or 0)
        Weather.draw(stage, Scene.time, Scene.preset, Scene.weather, quality)
        g.pop()
    end
end
return Scene

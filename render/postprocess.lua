local C=require("config.visual_config")
local P={shaders={},diagnostics={}}
function P.load()
    for _,name in ipairs({"depth","bright","blur","composite"}) do
        local ok,shader=pcall(love.graphics.newShader,"shaders/world_"..name..".glsl")
        if ok then P.shaders[name]=shader
        else P.diagnostics[#P.diagnostics+1]=name..": "..tostring(shader); print("[HD2D] Shader fallback: "..name..": "..tostring(shader)) end
    end
end
function P.resize(world,quality)
    if P.a then P.a:release(); P.b:release(); P.a,P.b=nil,nil end
    if not world then return end
    local w,h=math.max(1,math.floor(world:getWidth()*quality.bloomScale)),math.max(1,math.floor(world:getHeight()*quality.bloomScale))
    local ok,a,b=pcall(function() return love.graphics.newCanvas(w,h),love.graphics.newCanvas(w,h) end)
    if ok then P.a,P.b=a,b; a:setFilter("linear","linear"); b:setFilter("linear","linear")
    else P.diagnostics[#P.diagnostics+1]=tostring(a) end
end
function P.bloom(world,quality)
    P.bloomActive=C.enabled and C.effects.bloom and quality.bloom and P.a and P.shaders.bright and P.shaders.blur
    if not P.bloomActive then return end
    local g=love.graphics; local w,h=P.a:getDimensions()
    g.push("all");g.origin();g.setScissor();g.setBlendMode("replace")
    g.setCanvas(P.a);g.clear(0,0,0,1);g.setShader(P.shaders.bright)
    P.shaders.bright:send("threshold",C.bloom.threshold);P.shaders.bright:send("knee",C.bloom.knee)
    g.setColor(1,1,1,1);g.draw(world,0,0,0,w/world:getWidth(),h/world:getHeight())
    g.setCanvas(P.b);g.setShader(P.shaders.blur);P.shaders.blur:send("direction",{1/w,0});g.draw(P.a)
    g.setCanvas(P.a);P.shaders.blur:send("direction",{0,1/h});g.draw(P.b)
    g.pop()
end
function P.bind(preset,eventStrength,dim,crtEnabled,sequence)
    local shader=P.shaders.composite
    if not shader or not P.a or not C.enabled then return end
    shader:send("bloomTexture",P.a)
    shader:send("bloomStrength",P.bloomActive and (C.bloom.strength+C.bloom.eventStrength*eventStrength)*preset.bloomStrength or 0)
    local attack=sequence and sequence.attack
    local cfg=require("config.hand_vfx_config")
    local age=sequence and sequence.cameraAge or cfg.camera.duration
    local wave=attack and attack.tier>=3 and sequence.impactDispatched and age<cfg.camera.duration
    local progress=math.min(1,age/cfg.camera.duration)
    shader:send("waveAspect",1)
    shader:send("waveCenter",{(attack and attack.cx or 635)/1280,cfg.arena.targetY/720})
    shader:send("waveRadius",8+(1-(1-progress)^cfg.motion.impactExpansion)*cfg.shockwave.radius*(0.3+(attack and attack.intensity or 0)))
    shader:send("waveStrength",wave and cfg.shockwave.distortionStrength*attack.intensity*(1-progress)^2 or 0)
    local bed=require("src.bed_explosion")
    local radius,strength=bed.wave()
    if strength>0 then
        shader:send("waveAspect",1/.42)
        shader:send("waveCenter",{bed.x/1280,bed.y/720})
        shader:send("waveRadius",radius)
        shader:send("waveStrength",strength)
    end
    shader:send("grade",C.effects.grading and preset.colorGrade or {1,1,1})
    shader:send("ambient",C.effects.lighting and require("render.lighting").ambient or {1,1,1})
    shader:send("vignette",C.effects.grading and preset.vignette or 0)
    shader:send("dim",dim or 0); shader:send("crtStrength",crtEnabled and 0.035 or 0); love.graphics.setShader(shader)
end
return P

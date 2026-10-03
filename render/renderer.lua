-- World-only offscreen renderer. The established mainCanvas remains the sharp UI target.
local C = require("config.visual_config")
local Scene = require("render.scene")
local Camera = require("render.camera")
local Lighting = require("render.lighting")
local Post = require("render.postprocess")
local Entity = require("render.entity")
local R = { config=C, scene=Scene, camera=Camera, lighting=Lighting, post=Post,
    entity=Entity, eventStrength=0, dim=0, stats={frames=0, total=0, peak=0}, diagnostics={} }
function R.setQuality(name)
    R.quality=C.qualities[name] and name or C.quality
    local q=C.qualities[R.quality]
    local w,h=math.floor(1280*q.worldScale),math.floor(720*q.worldScale)
    if R.world and R.world:getWidth()==w and R.world:getHeight()==h then return end
    if R.world then R.world:release() end
    local ok,canvas=pcall(love.graphics.newCanvas,w,h)
    R.world=ok and canvas or nil
    if R.world then R.world:setFilter("linear","linear") end
    R.worldScale=q.worldScale
    if R.light then R.light:release() end
    local lightOk,light=pcall(love.graphics.newCanvas,640,360)
    R.light=lightOk and light or nil
    Post.resize(R.world,q)
    if not ok then R.diagnostics[#R.diagnostics+1]=tostring(canvas) end
end
function R.load(art, quality)
    Scene.load(art); Scene.update(0,"menu")
    Post.load(); Lighting.load(); Entity.load(); R.depthShader=Post.shaders.depth
    R.setQuality(quality)
    local ok,canvas=pcall(love.graphics.newCanvas,1920,1080)
    R.transitionCanvas=ok and canvas or nil; R.transitionAge=C.transition.duration
end
function R.update(dt,state,monster,sequence,impulseX,impulseY,attack,reward,death)
    local key=(state=="playing" or state=="scoring") and "battle" or state
    if R.stateKey and R.stateKey~=key then R.transitionPending=C.enabled end
    R.stateKey=key; R.transitionAge=math.min(C.transition.duration,(R.transitionAge or 0)+dt)
    Scene.update(dt,state,monster)
    local event=state=="scoring" and sequence and sequence.events[sequence.index]
    local kind=event and event.kind
    local bossFocus=kind=="AURA_PEAK" or kind=="ANTICIPATION" or kind=="ATTACK" or kind=="ENEMY_IMPACT"
    local cardsFocus=kind=="ENTRY" or kind=="TRIGGER" or kind=="AURA_COUNT"
    local intensity=sequence and sequence.intensity or 0.3
    local handAttack=event and sequence.attack
    R.attackSequence=handAttack and sequence or nil
    if handAttack then handAttack.quality=string.lower(R.quality) end
    
    local target=bossFocus and intensity or cardsFocus and intensity*0.3 or 0
    local response=1-math.exp(-8*math.min(dt,0.1))
    R.eventStrength=R.eventStrength+(target-R.eventStrength)*response
    Scene.attackPulse=handAttack and handAttack.tier>=4 and R.eventStrength or 0
    local dimTarget=event and kind~="SETTLE" and 0.10 or 0
    if handAttack then dimTarget=handAttack.tier>=3 and (0.05+0.05*intensity) or 0 end
    if kind=="SETTLE" then dimTarget=0 end
    R.dim=R.dim+(dimTarget-R.dim)*response
    if kind~=R.lastEvent and kind=="ENEMY_IMPACT" then
        Lighting.flash(630,270,handAttack and handAttack.color or C.palette.magic,0.22+intensity*0.25,0.24)
    end
    if (attack or 0)>0.8 and (R.lastAttack or 0)<=0.8 then
        Lighting.flash(630,285,C.palette.danger,0.22,0.30)
        Camera.kick(-2,4)
    end
    R.lastEvent,R.lastAttack=kind,attack
    local rewardState=state=="CASH_OUT" and reward and reward.state
    if rewardState and rewardState~=R.lastReward and (rewardState=="RARE_REVEAL" or rewardState=="LOOT_REVEAL") then
        Lighting.flash(820,470,C.palette.reward,C.reward.light,0.65,310)
    end
    R.lastReward=rewardState
    Lighting.setAmbient(Scene.preset.ambientColor); Lighting.update(dt)
    local zoom=bossFocus and (handAttack and require("config.hand_vfx_config").camera.zoom*(handAttack.tier>=3 and intensity or 0) or C.camera.zoom) or (attack or 0)*C.camera.attackZoom
    Camera.focus(C.enabled and bossFocus and C.camera.focusX or 0,C.enabled and (bossFocus and C.camera.focusY or cardsFocus and 3) or 0,
        C.enabled and 1+zoom or 1)
    local collapse=death and death.kind=="player" and death.cardProgress() or 0
    Lighting.presentationDim=collapse*(death and death.config.player.torchDim or 0)
    if collapse>0 and C.enabled then Camera.focus(0,death.config.player.drift*collapse,1+death.config.player.zoom*collapse) end
    Camera.update(dt,C.enabled and Scene.preset.cameraIdle or 0,C.enabled and impulseX or 0,C.enabled and impulseY or 0)
end
function R.beginFrame(previousFrame)
    if not R.transitionPending then return end
    R.transitionPending=false
    if not R.transitionCanvas or not previousFrame then return end
    local g=love.graphics
    g.push("all");g.origin();g.setScissor();g.setCanvas(R.transitionCanvas);g.setShader()
    g.setBlendMode("replace");g.setColor(1,1,1,1);g.draw(previousFrame);g.pop()
    R.transitionAge=0
end
function R.drawTransition()
    if not C.enabled or not R.transitionCanvas or R.transitionAge>=C.transition.duration then return end
    local p=math.max(0,math.min(1,R.transitionAge/C.transition.duration)); local smooth=p*p*(3-2*p)
    local g=love.graphics;g.push("all");g.setShader();g.setBlendMode("alpha","premultiplied")
    local opacity=1-smooth
    g.setColor(opacity,opacity,opacity,opacity);g.draw(R.transitionCanvas,0,0,0,1280/1920,720/1080);g.pop()
end
function R.veil(alpha,color)
    local g=love.graphics;local c=color or {0.009,0.017,0.030}
    g.setColor(c[1],c[2],c[3],alpha or C.ui.veil);g.rectangle("fill",0,0,1280,720)
end
function R.drawWorld(drawEntities,drawVfx)
    local g=love.graphics; local start=love.timer.getTime()
    if R.world then
        g.push("all"); g.setCanvas({R.world,stencil=true}); g.origin(); g.scale(R.worldScale)
        g.setShader(); g.setScissor(); g.setBlendMode("alpha"); g.clear(0,0,0,1)
    else g.push("all") end
    Scene.draw("before",Camera,C.qualities[R.quality],R.depthShader)
    if drawEntities then g.push("all"); Camera.apply(C.enabled and 0.4 or 0); drawEntities(); g.pop() end
    if drawVfx then g.push("all"); Camera.apply(C.enabled and 0.4 or 0); drawVfx(); g.pop() end
    Scene.draw("after",Camera,C.qualities[R.quality],R.depthShader)
    if R.light and C.enabled and C.effects.lighting then
        g.push("all");g.setCanvas(R.light);g.origin();g.scale(0.5);g.clear(0,0,0,0);g.setShader();g.setScissor()
        Camera.apply(0.4); Lighting.draw(Scene.preset,Scene.time,R.eventStrength)
        g.pop()
        g.setShader();g.setBlendMode("add","premultiplied");g.setColor(1,1,1,1);g.draw(R.light,0,0,0,2,2)
        g.setBlendMode("alpha")
    end
    g.pop()
    if R.world then
        Post.bloom(R.world,C.qualities[R.quality])
        g.push("all"); g.setShader(); g.setColor(1,1,1,1)
        Post.bind(Scene.preset,R.eventStrength,R.dim,R.crtEnabled,R.attackSequence)
        g.setBlendMode("alpha","premultiplied")
        g.draw(R.world,0,0,0,1/R.worldScale,1/R.worldScale); g.pop()
    end
    local ms=(love.timer.getTime()-start)*1000
    R.stats.frames=R.stats.frames+1; R.stats.total=R.stats.total+ms; R.stats.peak=math.max(R.stats.peak,ms)
end
function R.keypressed(key)
    if key~=C.debug.key then return false end
    R.debugIndex=((R.debugIndex or 0)+1)%(#C.debug.views+1)
    return true
end
function R.drawDebug(font)
    if not R.debugIndex or R.debugIndex==0 then return end
    local g=love.graphics; local view=C.debug.views[R.debugIndex]
    g.push("all");g.setShader();g.setScissor();g.setBlendMode("alpha")
    local target=view=="LIGHT" and R.light or view=="BLOOM" and Post.bloomActive and Post.a
    if target then
        g.setColor(0.005,0.008,0.015,1);g.rectangle("fill",0,0,1280,720)
        g.setColor(1,1,1,1);g.draw(target,0,0,0,1280/target:getWidth(),720/target:getHeight())
    elseif view=="FOG" or view=="PARTICLES" or view=="DOF" then
        g.setColor(0.008,0.014,0.025,1);g.rectangle("fill",0,0,1280,720)
        for _,layer in ipairs(Scene.definition.layers or Scene.definitions.layers) do
            local visible=view=="FOG" and layer.kind=="fog" or view=="PARTICLES" and layer.kind=="particles"
                or view=="DOF" and layer.blurAmount>0
            if visible then Scene.drawSingle(layer,Camera,C.qualities[R.quality],R.depthShader) end
        end
    end
    if font then g.setFont(font) end
    g.setColor(0.005,0.008,0.015,0.95);g.rectangle("fill",14,82,550,view=="LAYERS" and 214 or 114,6,6)
    g.setColor(0.90,0.78,0.54,1)
    g.print("HD2D / "..view.." / "..R.quality.."  [F1: next / off]",28,92)
    g.setColor(0.85,0.90,0.94,1)
    g.print(string.format("world %dx%d / bloom %s / CPU submit %.2f ms avg",R.world and R.world:getWidth() or 0,
        R.world and R.world:getHeight() or 0,Post.bloomActive and "ON" or "OFF",R.stats.total/math.max(1,R.stats.frames)),28,120)
    g.print(string.format("camera %.2f, %.2f / zoom %.3f / particles <= %d",Camera.offsetX or 0,Camera.offsetY or 0,
        Camera.zoom,C.qualities[R.quality].particles),28,145)
    g.print("world pass bypasses cards, HUD and tooltips",28,170)
    if view=="LAYERS" then
        for i,layer in ipairs(Scene.definition.layers or Scene.definitions.layers) do
            g.print(string.format("%s  depth %.2f / parallax %.2f / blur %.2f",layer.id,layer.depth,layer.parallaxFactor,layer.blurAmount),28,172+i*14)
        end
    end
    g.pop()
end
return R

local J={}
local textures={}
local shader
local function surfaceShader(tier,material)
    if not shader then shader=love.graphics.newShader("shaders/card_jewel_glints.glsl") end
    shader:send("uRank",tier)
    shader:send("uMaterial",material and 1 or 0)
    return shader
end

function J.texture(tier)
    if textures[tier] then return textures[tier] end
    local g=love.graphics
    local path=string.format("assets/ui/jewel_frames/tier_%02d.png",tier)
    local source=g.newImage(path)
    assert(math.abs(source:getHeight()-source:getWidth()*1.5)<2,"Jewel frame must be portrait 2:3: "..path)
    source:setFilter("linear","linear")
    -- Cache a supersampled UI-sized texture; the full-resolution originals remain in assets.
    local canvas=g.newCanvas(384,576,{format="rgba8",dpiscale=1})
    g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.setStencilTest();g.clear(0,0,0,0)
    g.setBlendMode("alpha","alphamultiply");g.setColor(1,1,1,1)
    g.draw(source,0,0,0,384/source:getWidth(),576/source:getHeight())
    g.pop();source:release();canvas:setFilter("linear","linear")
    textures[tier]=canvas
    return canvas
end

function J.material(drawImage,tier,x,y,w,h,alpha)
    if alpha<=0 then return end
    local g=love.graphics
    g.push("all")
    if not g.getShader() then g.setShader(surfaceShader(tier,true)) end
    g.setBlendMode("alpha","premultiplied")
    g.setColor(alpha,alpha,alpha,alpha)
    drawImage(J.texture(tier),x,y,w,h)
    g.pop()
end

function J.effects(drawImage,tier,x,y,w,h,alpha,time,reduced)
    if alpha<=0 or tier==1 then return end
    local g=love.graphics
    local visual=require("config.visual_config")
    surfaceShader(tier,false)
    local moving=visual.enabled and not reduced
    shader:send("uTime",moving and (time or 0) or 0)
    shader:send("uMoving",moving and 1 or 0)
    shader:send("uTier",math.min(1,(tier-1)/9))
    shader:send("uAscended",tier==11 and 1 or 0)
    shader:send("uLow",visual.quality=="LOW" and 1 or 0)
    g.push("all");g.setShader(shader);g.setBlendMode("add","premultiplied")
    g.setColor(alpha,alpha,alpha,alpha)
    drawImage(J.texture(tier),x,y,w,h)
    g.pop()
end
return J

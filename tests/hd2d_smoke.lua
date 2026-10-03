-- GPU integration invariants: live Canvas/shaders, state restoration, UI bypass,
-- allocation reuse, quality limits, missing GPU resources and deterministic RNG.
local R=require("render.renderer")
local C=R.config
local g=love.graphics
local rng=require("src.rng")
local rngBefore=rng.getState()
local target=g.newCanvas(1920,1080)
g.push("all");g.setCanvas(target);g.clear(0,0,0,1);g.scale(1.5)
for _,name in ipairs({"depth","bright","blur","composite"}) do assert(R.post.shaders[name],name) end
assert(R.entity.shader,"entity shader must compile")
local createCanvas,createShader=g.newCanvas,g.newShader
local function prohibit() error("GPU resource allocation during draw") end
g.newCanvas,g.newShader=prohibit,prohibit
for _,preset in ipairs({"ICE","FOREST","DESERT","VOID","VOLCANIC","RUINS","MYSTIC"}) do
    R.update(1/60,"playing",{environmentPreset=preset})
    R.drawWorld()
    assert(g.getCanvas()==target,"renderer must restore UI target")
    assert(g.getShader()==nil,"world shader must not leak into UI")
end
g.newCanvas,g.newShader=createCanvas,createShader
for _,quality in ipairs({"LOW","MEDIUM","HIGH"}) do
    R.setQuality(quality);local canvas=R.world;local bloom=R.post.a
    R.setQuality(quality);assert(canvas==R.world and bloom==R.post.a,"quality resource reuse")
    R.drawWorld();assert(g.getCanvas()==target)
    assert(R.world:getWidth()==math.floor(C.qualities[quality].worldScale*1280))
    if quality=="LOW" then assert(not R.post.bloomActive,"LOW bypasses bloom") end
end
local shaders=R.post.shaders; R.post.shaders={};R.depthShader=nil
R.drawWorld();R.post.shaders=shaders;R.depthShader=shaders.depth
local effectBefore=C.enabled;C.enabled=false;R.drawWorld();assert(not R.post.bloomActive);C.enabled=effectBefore
-- Missing Canvas also works, including correct sharp UI target restoration.
g.newCanvas=prohibit;R.setQuality("LOW");assert(R.world==nil);R.drawWorld()
g.newCanvas=createCanvas;R.setQuality("HIGH")
R.update(0,"playing")
g.setShader();g.setBlendMode("replace");g.setColor(0.18,0.85,0.33,1);g.rectangle("fill",8,8,12,12)
g.pop()
local pixels=target:newImageData();local red,green,blue=pixels:getPixel(16,16)
assert(math.abs(red-0.18)<0.02 and math.abs(green-0.85)<0.02 and math.abs(blue-0.33)<0.02,"sharp UI must bypass grade")
pixels:release()
assert(rng.getState()==rngBefore,"visual passes cannot consume gameplay RNG")
-- Premultiplied crossfade must interpolate, never add a full old-frame RGB.
g.push("all");g.setCanvas(R.transitionCanvas);g.origin();g.clear(0.8,0.8,0.8,1)
g.setCanvas(target);g.clear(0.2,0.2,0.2,1);g.scale(1.5)
R.transitionAge=C.transition.duration/2;R.drawTransition();g.pop()
local fadePixels=target:newImageData();local fade=fadePixels:getPixel(500,500)
assert(math.abs(fade-0.5)<0.025,"crossfade must interpolate old/new RGB")
fadePixels:release();target:release();R.transitionAge=C.transition.duration
-- Diagnostics from the deliberate GPU failure above are expected, not runtime errors.
R.diagnostics={};R.post.diagnostics={};R.stateKey=nil;R.transitionPending=false
print("HD2D GPU smoke passed: 5 shaders, 7 presets, 3 qualities, reuse, UI bypass, state restore, shader/Canvas fallback, RNG isolation")
return true

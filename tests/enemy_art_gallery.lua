-- Render the actual GPU textures on a dark backdrop for visual asset QA.
local Art=require("src.enemy_art")
local Run=require("src.run_manager")
local g=love.graphics
local canvas=g.newCanvas(1600,1600)
g.push("all");g.setCanvas(canvas);g.clear(0.045,0.055,0.075,1)
g.setFont(g.newFont(16))
local keys={}
for _,key in ipairs(Art.normal) do keys[#keys+1]=key end
for _,key in ipairs(Run.BOSS_KEYS) do keys[#keys+1]=key end
for i,key in ipairs(keys) do
    local image=assert(Art.images[key],"GPU image missing: "..key)
    local pixels=love.image.newImageData(Art.path(key))
    local _,_,_,corner=pixels:getPixel(0,0)
    local opaque,transparent=false,false
    for py=0,pixels:getHeight()-1,32 do
        for px=0,pixels:getWidth()-1,32 do
            local _,_,_,alpha=pixels:getPixel(px,py)
            opaque=opaque or alpha>0.9;transparent=transparent or alpha<0.01
        end
    end
    assert(corner<0.01 and opaque and transparent,"sprite must have visible content and true alpha: "..key)
    pixels:release()
    local x,y=((i-1)%4)*400,math.floor((i-1)/4)*400
    local w,h=image:getDimensions();local fit=math.min(360/w,340/h)
    g.setColor(1,1,1,1);g.draw(image,x+200-w*fit/2,y+180-h*fit/2,0,fit,fit)
    g.printf(key,x,y+370,400,"center")
end
g.pop()
local data=canvas:newImageData()
local file=assert(io.open("docs/enemy_art_gallery.png","wb"))
file:write(data:encode("png"):getString());file:close()
data:release();canvas:release()
print("GPU gallery saved: docs/enemy_art_gallery.png")
return true

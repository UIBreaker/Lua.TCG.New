-- Run: lovec.exe . --test-card-back-crop
local Test = {}
function Test.update()
    local Back = require("ui.components.deck_counter")
    local g = love.graphics
    local first = assert(Back.getImage())
    assert(first == Back.getImage(), "shared image must be reused")
    assert(first:getWidth() == 236, "outside matte must be cropped")
    for _, size in ipairs({{262,350},{128,176},{64,88}}) do
        local w,h = size[1],size[2]
        local canvas = g.newCanvas(w,h)
        g.push("all");g.setCanvas(canvas);g.origin();g.clear()
        Back.drawBack(0,0,w,h)
        g.pop()
        local pixels = canvas:newImageData()
        for _, p in ipairs({{0,0},{w-1,0},{0,h-1},{w-1,h-1}}) do
            local r,b,c,a = pixels:getPixel(p[1],p[2])
            assert(a == 0 and r == 0 and b == 0 and c == 0, "opaque/black outside corner")
        end
        local _,_,_,alpha = pixels:getPixel(math.floor(w/2),math.floor(h/2))
        assert(alpha > .99, "dark artwork must stay opaque")
        pixels:release();canvas:release()
    end
    local canvas = g.newCanvas(600,420)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(.14,.24,.31)
    Back.drawBack(60,35,262,350);Back.drawBack(370,95,128,176)
    g.pop()
    local bytes = canvas:newImageData():encode("png")
    local file=assert(io.open("shot_card_back_trim.png","wb"))
    file:write(bytes:getString());file:close()
    print("[PASS] Card back: transparent corners at 3 sizes, opaque artwork, shared cached image")
    love.event.quit()
end
return Test

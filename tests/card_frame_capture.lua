local T = {}

-- Check the visible rim across actual draw paths, including small inventory SPN.
function T.verify()
    local UI = require("src.ui")
    local Surfaces = require("ui.card_surfaces")
    local g, frame = love.graphics, UI.CardFrame
    local patron = {id="spirit_ember", rarity="common", name="Tàn Hỏa"}
    local cases = {
        {"Quân bài", function(w,h) UI.drawCardFace({suit="hearts",rank=2},0,0,w,h) end},
        {"SPN", function(w,h) UI.drawPatronCard(patron,0,0,w,h) end},
        {"ITM", function(w,h) Surfaces.image({},0,0,w,h,UI.getEquipmentImage("gem_fire")) end},
        {"Thế đánh", function(w,h) Surfaces.image({},0,0,w,h,UI.getHandImage("straight")) end},
        {"Tiêu hao", function(w,h) Surfaces.fullReward({id="spec_cryptid"},0,0,w,h,"spectral") end},
        {"Mặt sau", function(w,h) UI.drawCardBack(0,0,w,h) end},
    }
    local sheet = g.newCanvas(960,300)
    g.push("all"); g.setCanvas(sheet); g.origin(); g.clear(0.025,0.03,0.045,1); g.pop()
    UI.CardPhysics.suspend()
    for i, case in ipairs(cases) do
        local canvas = g.newCanvas(128,192)
        g.push("all"); g.setCanvas(canvas); g.origin(); g.clear(0,0,0,0)
        g.setColor(1,1,1,1); case[2](128,192); g.pop()
        local pixels = canvas:newImageData()
        local r,b,c,a = pixels:getPixel(0,96)
        local expected = frame.color
        assert(a > .99 and math.abs(r-expected[1]) < .01
            and math.abs(b-expected[2]) < .01 and math.abs(c-expected[3]) < .01,
            case[1] .. " must use the common edge stroke")
        r,b,c,a = pixels:getPixel(3,96)
        assert(a>.99 and math.abs(r-frame.metal[1])+math.abs(b-frame.metal[2])+math.abs(c-frame.metal[3])>.03,
            case[1] .. " artwork must reach the narrow rim without a dark gutter")
        g.push("all"); g.setCanvas(sheet); g.origin(); g.setColor(1,1,1,1)
        g.setBlendMode("alpha","premultiplied"); g.draw(canvas,(i-1)*160+16,18)
        g.setBlendMode("alpha"); g.setFont(UI.fonts.small)
        g.printf(case[1],(i-1)*160,222,160,"center"); g.pop()
        pixels:release(); canvas:release()
    end
    for _, size in ipairs({{64,88},{82,118},{200,300}}) do
        local w,h = size[1],size[2]
        local x,y,fw,fh = frame.pennantRect(w,h)
        assert(x>w/2 and x+fw<w and y>0 and y+fh<h/3, "pennant stays in top-right corner")
        local canvas = g.newCanvas(w,h)
        g.push("all"); g.setCanvas(canvas); g.origin(); g.clear(0,0,0,0)
        UI.drawPatronCard(patron,0,0,w,h); g.pop()
        local pixels = canvas:newImageData()
        local r,b,c,a = pixels:getPixel(math.floor(x+3),math.floor(y+3))
        assert(a>.99 and math.abs(r-.78)<.02 and math.abs(b-.82)<.02 and math.abs(c-.88)<.02,
            "rarity flag must render at the top-right anchor")
        pixels:release(); canvas:release()
    end
    UI.CardPhysics.resume()
    local file = assert(io.open("docs/card_frame_comparison.png","wb"))
    file:write(sheet:newImageData():encode("png"):getString()); file:close(); sheet:release()
    print("Card frame PASS: six card families share one rim; top-right pennant at three sizes")
    require("tests.card_frame_motion").verify()
end

return T

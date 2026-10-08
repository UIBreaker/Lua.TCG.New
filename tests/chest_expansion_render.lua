-- Run from project root: love . --test-chest-expansion
local T={}
function T.run()
    local root=love.filesystem.getSource():gsub("\\","/")
    package.path=root.."/?.lua;"..package.path
    assert(love.filesystem.load("tests/chest_expansion_smoke.lua"))()
    assert(love.filesystem.load("tests/spectral_persistence_smoke.lua"))()
    assert(love.filesystem.load("tests/chest_depth_smoke.lua"))()
    local UI=require("src.ui");UI.initFonts()
    for pass,X in ipairs({require("src.chest_expansion"),require("src.chest_depth")}) do
    local Surfaces=require("ui.card_surfaces")
    local Art=require("src.continental_art")
    local g=love.graphics;local canvas=g.newCanvas(1700,1000)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.035,0.05,1)
    UI.CardPhysics.suspend()
    for row,entry in ipairs({{X.equipment,"arcana"},{X.seals,"seal"},{X.spectral,"spectral"},{X.spells,"joker_edition"}}) do
        for col,item in ipairs(entry[1]) do
            local image=assert(Art.get(item.id),"Missing artwork: "..item.id)
            assert(image:getWidth()==512 and image:getHeight()==768)
            local x,y=(col-1)*170+11,(row-1)*250+8
            Surfaces.fullReward(item,x,y,148,222,entry[2],false)
            g.setFont(UI.fonts.tiny);g.setColor(0.94,0.9,0.82,1)
            g.printf(item.name:gsub("Phù Phép ",""),x-8,y+225,164,"center")
        end
    end
    UI.CardPhysics.resume();g.setCanvas();g.pop()
    local bytes=canvas:newImageData():encode("png"):getString()
    local name=pass==1 and "chest_expansion_runtime.png" or "chest_depth_runtime.png"
    local f=assert(io.open("docs/"..name,"wb"));f:write(bytes);f:close()
    end
    print("PASS: LuaJIT gameplay checks and all 80 expansion cards through real loaders and shared card frame")
    love.event.quit(0)
end
return T

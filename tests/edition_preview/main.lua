-- Run: lovec . --test-editions-render. Uses production loader, frame and imprint path.
local root,UI,E,catalog,stage,frames
function love.errorhandler(message)
    print(debug.traceback(message,2));return function() return 1 end
end
function love.load()
    root=love.filesystem.getSource():gsub("\\","/")
    love.window.setMode(1280,720)
    assert(love.filesystem.getInfo("config/card_effect_config.lua"),"Cannot read project: "..root)
    package.path=root.."/?.lua;"..root.."/?/init.lua;"..package.path
    UI=require("src.ui");UI.initFonts()
    E=require("src.card_effects");assert(E.load())
    catalog=E.getEditionCatalog();stage=1;frames=0
    for _,item in ipairs(catalog) do
        local art=assert(UI.getConsumableImage(item))
        assert(art:getWidth()==512 and art:getHeight()==768)
        assert(UI.getPackCardImage("edition",item)==art)
    end
    require("tests.editions_smoke")
end
function love.update(dt)
    frames=frames+1;E.update(dt)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/editions/"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function love.draw()
    local g=love.graphics;g.clear(.025,.04,.07,1)
    if stage==1 then
        for i,item in ipairs(catalog) do
            local x=140+((i-1)%3)*335;local y=12+math.floor((i-1)/3)*233
            require("ui.card_surfaces").fullReward(item,x,y,120,180,"edition",false)
            g.setFont(UI.fonts.small);g.setColor(.93,.83,.64,1);g.printf(item.name,x+134,y+32,158,"left")
            g.setFont(UI.fonts.tiny);g.setColor(.8,.82,.85,1);g.printf(item.desc,x+134,y+84,155,"left")
        end
        if frames>5 then shot("runtime_catalog");stage=2;frames=0 end
    elseif stage==2 then
        local rewards={catalog[7],catalog[8],catalog[9]}
        local buttons={}
        require("ui.chest_choices").draw(rewards,4,"RƯƠNG ẤN BẢN",0,0,buttons,false,"edition")
        assert(#buttons==6,"all use/keep actions must be visible")
        if frames>5 then shot("runtime_chest");stage=3;frames=0 end
    elseif frames>5 then
        print("Edition runtime PASS: nine production PNGs, nine shaders, shared frame, descriptions and six chest actions")
        love.event.quit(0)
    end
end

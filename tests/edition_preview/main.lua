-- Run: lovec . --test-editions-render. Uses production loader, frame and imprint path.
local root,UI,E,catalog,stage,frames,sharedArt,galleryCaptions,smallCards,smallCaptions
function love.errorhandler(message)
    print(debug.traceback(message,2));return function() return 1 end
end
local function prepareGallery()
    local galleryFont=love.graphics.newFont("fonts/arialbd.ttf",18)
    galleryCaptions={}
    local phases={"TĨNH","DI CHUỘT","CHỌN BÀI","TÍNH ĐIỂM"}
    local names={}
    for i,item in ipairs(catalog) do names[i]=item.name:match("— (.+)") or item.name end
    -- Warm every caption glyph before baking stable overlays for the capture.
    local glyphs=love.graphics.newText(galleryFont,table.concat(names," ")..table.concat(phases," ").."CONTINENTAL / EDITIONS")
    for phase=1,4 do
        local canvas=love.graphics.newCanvas(1200,1200)
        love.graphics.push("all");love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,0);love.graphics.setShader();love.graphics.setFont(galleryFont)
        love.graphics.setColor(.89,.80,.61,1)
        love.graphics.printf("C O N T I N E N T A L   /   E D I T I O N S",0,16,1200,"center")
        love.graphics.setColor(.54,.65,.76,1);love.graphics.printf(phases[phase],0,44,1200,"center")
        love.graphics.setColor(.91,.83,.68,1)
        for i,name in ipairs(names) do
            love.graphics.printf(name,((i-1)%3)*400,411+math.floor((i-1)/3)*367,400,"center")
        end
        love.graphics.pop();galleryCaptions[phase]=canvas
    end
end
function love.load()
    root=love.filesystem.getSource():gsub("\\","/")
    love.window.setMode(1280,720)
    assert(love.filesystem.getInfo("config/card_effect_config.lua"),"Cannot read project: "..root)
    package.path=root.."/?.lua;"..root.."/?/init.lua;"..package.path
    UI=require("src.ui");UI.initFonts()
    E=require("src.card_effects");assert(E.load())
    catalog=E.getEditionCatalog();stage=1;frames=0
    sharedArt=assert(UI.getConsumableImage(catalog[6]))
    local paths={}
    for _,name in ipairs(require("config.card_effect_config").catalogOrder) do
        local path=require("config.card_effect_config").effects[name].shader
        assert(not paths[path],"Edition shaders must be independent: "..path)
        paths[path]=true
    end
    for _,item in ipairs(catalog) do
        local art=assert(UI.getConsumableImage(item))
        assert(art:getWidth()==512 and art:getHeight()==768)
        assert(UI.getPackCardImage("edition",item)==art)
    end
    require("tests.editions_smoke")
    local rendered={}
    for i,item in ipairs(catalog) do
        local canvas=love.graphics.newCanvas(64,96)
        love.graphics.push("all");love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
        local active=E.beginCard(item);assert(active)
        love.graphics.draw(sharedArt,0,0,0,64/sharedArt:getWidth(),96/sharedArt:getHeight())
        E.endCard(active);love.graphics.pop()
        rendered[i]=canvas:newImageData()
    end
    for i=1,9 do for j=i+1,9 do
        local difference=0
        for y=8,88,8 do for x=8,56,8 do
            local r,g,b=rendered[i]:getPixel(x,y)
            local a,c,d=rendered[j]:getPixel(x,y)
            difference=difference+math.abs(r-a)+math.abs(g-c)+math.abs(b-d)
        end end
        assert(difference>.01,"Two Edition shaders rendered identically")
    end end
    -- Check the actual reward renderer, not only isolated shader output.
    for _,item in ipairs(catalog) do
        local art=UI.getConsumableImage(item)
        local canvas=love.graphics.newCanvas(120,180)
        love.graphics.push("all");love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,0)
        require("ui.card_surfaces").fullReward(item,0,0,120,180,"edition",false)
        love.graphics.pop()
        local face=canvas:newImageData()
        love.graphics.push("all");love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
        UI.CardFrame.image(art,0,0,120,180)
        love.graphics.pop()
        local plain=canvas:newImageData();local difference=0
        for y=15,165,10 do for x=15,105,10 do
            local r,g,b=face:getPixel(x,y);local a,c,d=plain:getPixel(x,y)
            difference=difference+math.abs(r-a)+math.abs(g-c)+math.abs(b-d)
        end end
        assert(difference>.03,"Reward shader missing: "..item.edition)
    end
    local translucent=love.image.newImageData(8,8)
    translucent:mapPixel(function(x,y) return .3,.4,.5,x==0 and 0 or .4 end)
    local image=love.graphics.newImage(translucent)
    for _,item in ipairs(catalog) do
        local canvas=love.graphics.newCanvas(8,8)
        love.graphics.push("all");love.graphics.setCanvas(canvas)
        love.graphics.clear(0,0,0,0);love.graphics.setColor(1,1,1,1)
        love.graphics.setBlendMode("replace")
        local active=E.beginCard(item);love.graphics.draw(image);E.endCard(active)
        love.graphics.pop()
        local data=canvas:newImageData()
        local _,_,_,alpha=data:getPixel(4,4);assert(math.abs(alpha-.4)<.01)
        local _,_,_,empty=data:getPixel(0,4);assert(empty==0)
    end
    print("GPU PASS: nine shaders, 36 distinct output pairs, nine reward effects and preserved transparency")
end
function love.update(dt)
    frames=frames+1
    if stage==4 then
        local phase=math.floor((frames-1)/24)%4
        for _,item in ipairs(catalog) do
            E.setInteraction(item,phase==1,phase==2)
            if phase==3 and frames%8==1 then E.triggerScorePulse(item) end
        end
    elseif stage==5 then
        for row=1,3 do for _,card in ipairs(smallCards[row]) do
            E.setInteraction(card,row==2,false)
            if row==3 and frames%8==1 then E.triggerScorePulse(card) end
        end end
    end
    E.update(stage==3 and 1/12 or (stage==4 or stage==5) and 1/24 or dt)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/editions/identity/"..name..".png","wb"))
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
    elseif stage==3 then
        g.setFont(UI.fonts.small);g.setColor(.93,.83,.64)
        g.printf("9 EDITION / SAME ARTWORK",0,8,1280,"center")
        for i,item in ipairs(catalog) do
            local x=178+((i-1)%3)*330;local y=42+math.floor((i-1)/3)*220
            E.setInteraction(item,true,false)
            local active=E.beginCard(item)
            UI.CardFrame.image(sharedArt,x,y,116,174)
            E.endCard(active)
            UI.drawCardBorder(x,y,116,174,nil,nil,item)
            g.setColor(.93,.83,.64);g.setFont(UI.fonts.small)
            g.printf(item.name,x+130,y+72,180,"left")
        end
        if frames==24 then shot("shader_comparison") end
        if frames>=24 and frames<72 then shot(string.format("animation_%02d",frames-24)) end
        if frames>=72 then
            stage=4;frames=0;love.window.setMode(1200,1200)
            -- setMode discards Canvas contents; build captions after resizing.
            prepareGallery()
        end
    elseif stage==4 then
        g.setShader();g.setBlendMode("alpha");g.setColor(1,1,1,1)
        for y=0,1199,6 do
            local light=math.exp(-math.abs(y-450)/500)
            g.setColor(.018+light*.012,.025+light*.014,.04+light*.025,1)
            g.rectangle("fill",0,y,1200,6)
        end
        local phase=math.floor((frames-1)/24)%4
        for i,item in ipairs(catalog) do
            local col=(i-1)%3;local row=math.floor((i-1)/3)
            local x=93+col*400;local y=82+row*367
            require("ui.card_surfaces").fullReward(item,x,y,214,321,"edition",phase==1)
            -- fullReward owns hover; selection and score still come from the update.
            if phase==2 then E.setInteraction(item,false,true) end
        end
        g.push("all");g.setShader();g.setColor(1,1,1,1)
        g.setBlendMode("alpha","premultiplied");g.draw(galleryCaptions[phase+1]);g.pop()
        if frames==18 then shot("edition_gallery_idle") end
        if frames==48 then shot("edition_gallery") end
        if frames<=96 then shot(string.format("gallery_%03d",frames-1)) end
        if frames>=97 then
            stage=5;frames=0;love.window.setMode(1200,660)
            local font=g.newFont("fonts/arialbd.ttf",14)
            local labels={}
            local titles={"TĨNH / 96 × 144","DI CHUỘT / 96 × 144","TÍNH ĐIỂM / 96 × 144"}
            for i,item in ipairs(catalog) do labels[i]=string.upper(item.edition) end
            local glyphs=g.newText(font,table.concat(labels," ")..table.concat(titles," "))
            smallCaptions=g.newCanvas(1200,660)
            g.push("all");g.setCanvas(smallCaptions);g.clear(0,0,0,0);g.setShader();g.setFont(font)
            for row=1,3 do
                g.setColor(.84,.83,.76,1);g.printf(titles[row],0,22+(row-1)*205,1200,"center")
                g.setColor(.90,.82,.65,1)
                for i,label in ipairs(labels) do g.printf(label,24+(i-1)*128,206+(row-1)*205,128,"center") end
            end
            g.pop()
            smallCards={{},{},{}}
            for row=1,3 do for i,item in ipairs(catalog) do
                smallCards[row][i]={edition=item.edition}
            end end
        end
    elseif stage==5 then
        g.setShader();g.setColor(1,1,1,1)
        for row=1,3 do
            for i,card in ipairs(smallCards[row]) do
                local x=40+(i-1)*128;local y=56+(row-1)*205
                g.setColor(1,1,1,1)
                local active=E.beginCard(card);assert(active)
                UI.CardFrame.image(sharedArt,x,y,96,144);E.endCard(active)
                UI.drawCardBorder(x,y,96,144,nil,nil,card)
            end
        end
        g.push("all");g.setShader();g.setColor(1,1,1,1)
        g.setBlendMode("alpha","premultiplied");g.draw(smallCaptions);g.pop()
        if frames==18 then shot("identity_at_96px");stage=6;frames=0 end
    elseif frames>5 then
        print("Edition runtime PASS: nine production PNGs, nine shaders, shared frame, descriptions and six chest actions")
        love.event.quit(0)
    end
end

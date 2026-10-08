local root = os.getenv("POKER_DESCRIPTION_ROOT") or love.filesystem.getWorkingDirectory()
io.stdout:setvbuf("no")
function love.errorhandler(message)
    io.stderr:write(tostring(message).."\n"..debug.traceback().."\n")
    os.exit(1)
end
package.path = root .. "/?.lua;" .. root .. "/?/init.lua;" .. package.path
local View, UI, Description, cases
function love.load()
    UI = require("src.ui")
    local newFont=love.graphics.newFont
    love.graphics.newFont=function(path,...)
        if type(path)=="string" and path:match("^fonts/") then
            local file=assert(io.open(root.."/"..path,"rb"))
            local data=file:read("*a"); file:close()
            return newFont(love.filesystem.newFileData(data,path),...)
        end
        return newFont(path,...)
    end
    UI.initFonts(); love.graphics.newFont=newFont
    View = require("ui.components.card_description")
    Description = require("src.card_description")
    local Deck = require("src.deck")
    local Deities = require("src.deities")
    local Equipment = require("src.equipment")
    local Shop = require("src.shop")
    local samples, total = {}, 0
    for _, suit in ipairs({"hearts","diamonds","clubs","spades"}) do
        for rank=2,14 do
            for level=0,require("src.card_abilities").config.maxEvolutionLevel do
                local card=Deck.newCard(rank,suit); card.evolutionLevel=level
                samples[#samples+1]=card
            end
        end
    end
    for _, catalog in ipairs({Deities.CATALOG,Equipment.ITEMS,Shop.SPECTRAL_CARDS,Shop.JOKER_SPELLS,Shop.PACK_CATALOG,Shop.VOUCHERS,require("src.poker").PLANET_CARDS}) do
        for _, item in pairs(catalog) do samples[#samples+1]=item end
    end
    for _, item in ipairs(samples) do
        local title, body = Description.resolve(item)
        local model=View.model(item,title,body)
        local layout=View.layout(model,UI.fonts)
        assert(layout.h*layout.scale<=680.001,"description must fit viewport")
        for i,row in ipairs(model.rows) do
            local _, lines=layout.font:getWrap(row.text,layout.w-40)
            assert(layout.rows[i].h>=layout.rows[i].textY+#lines*(layout.font:getHeight()+2)+8,"no clipped prose")
        end
        total=total+1
    end
    local jack=Deck.newCard(11,"diamonds")
    local modified=Deck.newCard(12,"hearts"); modified.evolutionLevel=4
    modified.equipments={Equipment.ITEMS.gem_fire,Equipment.ITEMS.gem_blast,Equipment.ITEMS.mirror_adjacent}
    modified.edition="foil"; modified.seal="gold"; modified.enhancement=next(Deck.ENHANCEMENTS)
    local longModel=View.model(modified,Description.resolve(modified))
    local longLayout=View.layout(longModel,UI.fonts)
    assert(longLayout.h<=440 and longLayout.scale==1,"compact viewport never shrinks text")
    local additions
    for _,row in ipairs(longModel.rows) do if row.kind=="additions" then additions=row.text end end
    assert(additions and additions:find("Đá Tiên Phong",1,true) and additions:find("Dấu ấn",1,true),"modifications grouped, never discarded")
    local title,body=Description.resolve(modified)
    local expanded=View.model(modified,title,body,true)
    assert(#expanded.rows>#longModel.rows,"secondary information available on Shift")
    for _,row in ipairs(longModel.rows) do assert(row.kind~="detail" and row.kind~="stats" and row.kind~="next","hide reference information by default") end
    local huge=View.model(jack,"Long",("Effect\n"):rep(100),true)
    local hugeLayout=View.layout(huge,UI.fonts)
    assert(hugeLayout.maxScroll>0 and hugeLayout.h<=600 and hugeLayout.scale==1,"long cards scroll with original font")
    local render,isDown=View.draw,love.keyboard.isDown
    local capturedModel,capturedLayout,capturedScroll
    View.draw=function(m,l,x,y,scroll) capturedModel,capturedLayout,capturedScroll=m,l,scroll end
    love.keyboard.isDown=function() return false end
    Description.reset();Description.draw(UI,modified,640,360);Description.update(1);Description.draw(UI,modified,640,360)
    local canScroll=capturedLayout.maxScroll>0
    assert(Description.wheelmoved(-999)==canScroll,"wheel handled only when content overflows")
    Description.draw(UI,modified,640,360)
    assert(capturedScroll==capturedLayout.maxScroll,"scroll clamps at final content")
    love.keyboard.isDown=function() return true end
    Description.draw(UI,modified,640,360)
    assert(capturedModel.expanded and capturedScroll==0,"Shift expands and resets scroll")
    Description.reset();assert(not Description.wheelmoved(-1),"inactive tooltip does not steal scrolling")
    View.draw,love.keyboard.isDown=render,isDown
    local spn=assert(next(Deities.CATALOG)); spn=Deities.CATALOG[spn]
    cases={jack,spn,Equipment.ITEMS.gem_fire,modified}
    assert(View.model(jack,Description.resolve(jack)).level=="0","evolution extracted")
    local warning=View.model(jack,"Test","Effect\nKHẢ NĂNG VÔ HIỆU trong tay này.")
    assert(warning.rows[1].kind=="warning","disabled ability has priority")
    print("PASS: "..total.." descriptions; all evolution levels, catalogs, compact/expanded content, warnings, scrolling and Shift")
end
local frames=0
function love.draw()
    love.graphics.clear(0.018,0.027,0.039,1)
    for i,item in ipairs(cases) do
        local title,body=Description.resolve(item)
        local model=View.model(item,title,body)
        local layout=View.layout(model,UI.fonts)
        View.draw(model,layout,20+(i-1)*385,40)
    end
    frames=frames+1
    if frames==2 then
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open(root.."/docs/card_description_preview.png","wb"))
            f:write(data:encode("png"):getString()); f:close()
            love.event.quit()
        end)
    end
end

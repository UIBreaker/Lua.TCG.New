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
            for level=0,5 do
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
            local _, lines=layout.font:getWrap(row.text,layout.w-56)
            assert(layout.rows[i].h>=layout.textY+#lines*(layout.font:getHeight()+2)+layout.bottom,"no clipped prose")
        end
        total=total+1
    end
    local jack=Deck.newCard(11,"diamonds")
    local modified=Deck.newCard(12,"hearts"); modified.evolutionLevel=4
    modified.equipments={Equipment.ITEMS.gem_fire,Equipment.ITEMS.gem_blast,Equipment.ITEMS.mirror_adjacent}
    modified.edition="foil"; modified.seal="gold"; modified.enhancement=next(Deck.ENHANCEMENTS)
    local longModel=View.model(modified,Description.resolve(modified))
    local longLayout=View.layout(longModel,UI.fonts)
    assert(longLayout.h*longLayout.scale<=680.001 and #longModel.rows>=9,"all modifications fit")
    local spn=assert(next(Deities.CATALOG)); spn=Deities.CATALOG[spn]
    cases={jack,spn,Equipment.ITEMS.gem_fire,modified}
    assert(View.model(jack,Description.resolve(jack)).level=="0","evolution extracted")
    local warning=View.model(jack,"Test","Effect\nKHẢ NĂNG VÔ HIỆU trong tay này.")
    assert(warning.rows[2].kind=="warning","disabled ability highlighted")
    print("PASS: "..total.." descriptions; 52 playing cards across 6 evolution levels, catalogs, wrapping, warnings")
end
local frames=0
function love.draw()
    love.graphics.clear(0.018,0.027,0.039,1)
    for i,item in ipairs(cases) do
        local title,body=Description.resolve(item)
        local model=View.model(item,title,body)
        local layout=View.layout(model,UI.fonts)
        -- Constrain preview columns while retaining the same runtime layout.
        local scale=math.min(layout.scale,360/layout.w)
        layout.scale=scale
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

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
    -- Load the real artwork while this standalone harness lives under tests/.
    local paths=require("config.continental_asset_paths")
    local images={}
    UI.getEquipmentImage=function(id)
        if images[id] then return images[id] end
        local path=paths[id];if not path then return nil end
        local runtime=path:gsub("assets/cards/continental/","assets/cards/continental/runtime/"):gsub("%.png$",".jpg")
        local file=io.open(root.."/"..runtime,"rb")
        if file then path=runtime else file=io.open(root.."/"..path,"rb") end
        if not file then return nil end
        local bytes=file:read("*a");file:close()
        images[id]=love.graphics.newImage(love.filesystem.newFileData(bytes,path))
        return images[id]
    end
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
        assert(layout.maxScroll==0,"default mode shows complete content without scrolling")
        for i,row in ipairs(model.rows) do
            assert(row.kind~="rules","global ability rules are omitted from default tooltips")
            local bounds=layout.rows[i]
            assert(bounds.x+bounds.w<=layout.w and bounds.y+bounds.h<=layout.viewportH+0.001,"all default rows visible inside the panel")
            local font=row.kind=="rules" and layout.referenceFont or (row.kind=="stats" or row.kind=="sockets") and layout.labelFont or layout.font
            if row.kind=="equipment" then
                local _,lines=font:getWrap(row.text,bounds.w-88)
                assert(layout.rows[i].h>=26+layout.rows[i].nameH+#lines*(font:getHeight()+2)+10,"equipment name and full effect fit")
            else
                local _,lines=font:getWrap(row.text,bounds.w-40)
                assert(layout.rows[i].h>=layout.rows[i].textY+#lines*(font:getHeight()+2)+8,"no clipped prose")
            end
        end
        total=total+1
    end
    local jack=Deck.newCard(11,"diamonds")
    local modified=Deck.newCard(12,"hearts"); modified.evolutionLevel=4
    modified.equipments={Equipment.ITEMS.gem_fire,Equipment.ITEMS.gem_blast,Equipment.ITEMS.mirror_adjacent}
    modified.edition="foil"; modified.seal="gold"; modified.enhancement=next(Deck.ENHANCEMENTS)
    local longModel=View.model(modified,Description.resolve(modified))
    local longLayout=View.layout(longModel,UI.fonts)
    assert(longLayout.h<=640 and longLayout.scale==1,"complete viewport never shrinks text")
    local additions
    for _,row in ipairs(longModel.rows) do if row.kind=="additions" then additions=row.text end end
    local foundEquipment=false;for _,row in ipairs(longModel.rows) do if row.kind=="equipment" and row.equipment.id=="gem_fire" then foundEquipment=true end end
    assert(foundEquipment and additions and additions:find("Dấu ấn",1,true),"equipment has its own tier/slot row; modifiers remain visible")
    local title,body=Description.resolve(modified)
    local expanded=View.model(modified,title,body,true)
    for _,row in ipairs(expanded.rows) do assert(row.kind~="rules","global ability rules are also omitted from Shift details") end
    assert(#expanded.rows>#longModel.rows,"secondary information available on Shift")
    local stats,role=longModel.stats~=nil,false
    for _,row in ipairs(longModel.rows) do
        assert(row.kind~="detail" and row.kind~="next","hide reference information by default")
        role=role or row.kind=="role"
    end
    assert(stats and role,"combat stats and royal bonus must be visible without Shift")
    local empty=View.model(jack,Description.resolve(jack))
    local sockets=false
    for _,row in ipairs(empty.rows) do sockets=sockets or row.kind=="sockets" end
    assert(sockets and empty.level=="0","show empty sockets and initial level explicitly")
    local boosted=Deck.newCard(7,"spades");boosted.speedBonus=2;boosted.temporarySpeedBonus=3
    boosted.temporaryAbilityLevels=2;boosted.equipments={Equipment.ITEMS.itm_horizonengine}
    local boostedModel=View.model(boosted,Description.resolve(boosted))
    assert(boostedModel.stats.speed==Deck.peekCardAttackSpeed(boosted) and boostedModel.temporary=="2","live buffs and equipment included")
    local phoenix=Equipment.ITEMS.itm_phoenixcradle
    local phoenixModel=View.model(phoenix,Description.resolve(phoenix))
    assert(phoenixModel.rows[1].kind=="equipment" and phoenixModel.rows[1].text:find("\n",1,true),"standalone equipment shares full presentation")
    local low=phoenix.onCardScore(Deck.newCard(7,"spades"),{},1,{gameState={playerHp=30,maxPlayerHp=100}})
    local high=phoenix.onCardScore(Deck.newCard(7,"spades"),{},1,{gameState={playerHp=31,maxPlayerHp=100}})
    assert(low.healHp==16 and low.extraDamagePct==0.25 and high.addChips==90,"phoenix description agrees with both HP branches")
    local eight=Deck.newCard(12,"hearts");eight.maxSockets=8;eight.equipments={}
    for _,id in ipairs({"gem_fire","gem_blast","mirror_adjacent","storm_eye","lucky_coin","ward_stone","vitality_gem","blood_ring"}) do eight.equipments[#eight.equipments+1]=Equipment.ITEMS[id] end
    local eightModel=View.model(eight,Description.resolve(eight))
    local equipmentCount=0
    for _,row in ipairs(eightModel.rows) do if row.kind=="equipment" then equipmentCount=equipmentCount+1 end end
    local eightLayout=View.layout(eightModel,UI.fonts)
    assert(equipmentCount==8 and eightLayout.maxScroll==0 and eightLayout.h<=640 and eightLayout.scale==1,"all eight equipment effects visible at once without shrinking text")
    local huge=View.model(jack,"Long",("Effect\n"):rep(100),true)
    local hugeLayout=View.layout(huge,UI.fonts)
    assert(hugeLayout.maxScroll>0 and hugeLayout.h<=640 and hugeLayout.scale==1,"long cards scroll with original font")
    local render,isDown=View.draw,love.keyboard.isDown
    local capturedModel,capturedLayout,capturedScroll,capturedX,capturedY
    View.draw=function(m,l,x,y,scroll) capturedModel,capturedLayout,capturedScroll,capturedX,capturedY=m,l,scroll,x,y end
    love.keyboard.isDown=function() return false end
    Description.reset();Description.draw(UI,eight,640,360);Description.update(1);Description.draw(UI,eight,640,360)
    assert(not Description.wheelmoved(-999) and capturedLayout.maxScroll==0,"normal tooltip never steals the wheel")
    love.keyboard.isDown=function() return true end
    Description.draw(UI,eight,640,360)
    assert(capturedModel.expanded and capturedScroll==0,"Shift expands and resets scroll")
    assert(capturedLayout.maxScroll>0 and Description.wheelmoved(-999),"Shift enables scrolling")
    local ax,ay=capturedX,capturedY
    local pinned=Description.candidate(nil)
    assert(pinned==eight and Description.candidate(jack)==eight,"Shift retains original card when pointer enters tooltip or another card")
    Description.finishFrame();Description.draw(UI,pinned,1200,700);Description.finishFrame()
    assert(capturedScroll==capturedLayout.maxScroll and capturedX==ax and capturedY==ay,"expanded panel stays anchored and scroll reaches the final content")
    assert(Description.candidate(jack,"new-scene")==jack and not Description.wheelmoved(-1),"changing scene clears the pinned tooltip even while Shift is held")
    love.keyboard.isDown=function() return false end
    assert(Description.candidate(nil)==nil and not Description.wheelmoved(-1),"releasing Shift returns hover and wheel to game")
    Description.finishFrame();assert(Description.candidate(nil)==nil,"lost hover closes panel after releasing Shift")
    Description.reset();assert(not Description.wheelmoved(-1),"inactive tooltip does not steal scrolling")
    View.draw,love.keyboard.isDown=render,isDown
    local spn=assert(next(Deities.CATALOG)); spn=Deities.CATALOG[spn]
    local astrid=Deck.newCard(7,"spades");astrid.equipments={phoenix}
    cases={eight}
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
        View.draw(model,layout,20+(i-1)*450,20)
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

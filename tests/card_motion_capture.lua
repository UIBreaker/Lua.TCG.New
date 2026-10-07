local UI = require("src.ui")
local P = UI.CardPhysics
local Frame = UI.CardFrame
local Deities = require("src.deities")
local function save(canvas,path)
    local data=canvas:newImageData()
    local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close();data:release()
end
function love.errorhandler(message)
    print(debug.traceback(message,2));return function() return 1 end
end
function love.load()
    UI.initFonts()
    local g=love.graphics
    local canvas=g.newCanvas(1440,420)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.03,0.045,1)
    local fingerprints={}
    for i,rarity in ipairs(Deities.RARITIES) do
        local card={id="spirit_ember",baseRarity="common",evolutionLevel=i-1}
        assert(Frame.tier(card)==i and Deities.getRarityBadge(card)==rarity.code)
        assert(Frame.tier({rarity=rarity.id})==i)
        local x=16+(i-1)*180
        UI.drawPatronCard(card,x,36,148,222)
        g.setCanvas()
        local data=canvas:newImageData(1,1,x,36,148,222)
        g.setCanvas(canvas)
        local bytes=data:getString();assert(not fingerprints[bytes],"tiers must look different")
        fingerprints[bytes]=true;data:release()
        -- Check that decoration remains readable on small inventory cards.
        UI.drawPatronCard(card,x+34,298,64,88)
        g.setFont(UI.fonts.medium);g.setColor(rarity.color);g.printf(rarity.code,x,266,148,"center")
    end
    g.pop();save(canvas,"docs/card_rarity_frames.png");canvas:release()
    canvas=g.newCanvas(1440,570)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.03,0.045,1)
    P.suspend()
    local maxLevel=require("config.card_ability_data").maxEvolutionLevel
    for i,rarity in ipairs(Deities.RARITIES) do
        local card=require("src.deck").newCard(3,({"hearts","diamonds","clubs","spades"})[(i-1)%4+1])
        card.evolutionLevel=math.min(i-1,maxLevel)
        card.temporaryAbilityLevels=math.max(0,i-1-maxLevel)
        assert(Frame.tier(card)==i,"playing-card rim must include permanent and temporary evolution")
        local x=16+(i-1)*180
        UI.drawCard(card,x,30,148,222)
        UI.drawCardFace(card,x+10,315,128,192)
        g.setColor(rarity.color);g.setFont(UI.fonts.medium);g.printf(rarity.code,x,267,148,"center")
        card.temporaryAbilityLevels=0
        assert(Frame.tier(card)==card.evolutionLevel+1,"temporary rim must return to permanent tier")
    end
    P.resume();g.pop();save(canvas,"docs/playing_card_rarity_frames.png");canvas:release()
    local surface=P.wrap(function(card,x,y,w,h)
        local faceX,faceY=g.transformPoint(x,y)
        local art=UI.getCardImage("hearts",3)
        Frame.image(art,x,y,w,h);Frame.draw(x,y,w,h,nil,nil,card)
        local rimX,rimY=g.transformPoint(x,y)
        assert(math.abs(faceX-rimX)+math.abs(faceY-rimY)<0.001)
    end)
    local last
    for _,fps in ipairs({30,60,120,144}) do
        local card={evolutionLevel=7}
        local function step(mx,my)
            P.update(1/fps,mx,my);P.beginFrame(true);surface(card,300,150,128,192);P.endFrame()
        end
        step(-500,-500)
        for i=1,fps do step(-500,-500) end
        local s=assert(P.getState(card))
        assert(s.active and math.abs(s.rotation)>0.00001,"idle cards must sway")
        for i=1,fps do step(410,200) end
        assert(s.hoverLift>0.98 and s.rotation>0.025,"pointer hover must ease into lift and tilt")
        if last then assert(math.abs(s.hoverLift-last)<0.002,"hover must be FPS independent") end
        last=s.hoverLift
        local angle=s.rotation
        step(-500,-500)
        assert(math.abs(s.rotation-angle)<0.012,"hover exit must preserve smooth motion")
        for i=1,fps do step(-500,-500) end
        assert(s.hoverLift<0.001 and math.abs(s.y-s.homeY)<1,"hover returns to idle slot")
        local cx=s.ox+s.a*64+s.c*96;local cy=s.oy+s.b*64+s.d*96
        assert(P.hit(card,cx,cy) and not P.hit(card,-1000,-1000),"hit area must follow animated face")
    end
    local Surfaces=require("ui.card_surfaces")
    local faces={
        {{suit="hearts",rank=3},function(c) UI.drawCard(c,300,150,128,192) end},
        {{id="spirit_ember",rarity="epic"},function(c) UI.drawPatronCard(c,300,150,128,192) end},
        {{id="gem_fire",rarity="rare"},function(c) Surfaces.image(c,300,150,128,192,UI.getEquipmentImage(c.id)) end},
        {{id="straight",handId="straight"},function(c) Surfaces.fullReward(c,300,150,128,192,"hand_styles") end},
        {{id="spec_cryptid"},function(c) Surfaces.round(c,300,150,128,192) end},
        {{id="gem_fire",rarity="legendary"},function(c) Surfaces.catalog(c,300,150,128,192,"equipment") end},
    }
    for _,case in ipairs(faces) do
        for i=1,60 do
            P.update(1/60,410,200);P.beginFrame(true);case[2](case[1]);P.endFrame()
        end
        local state=assert(P.getState(case[1]),"every card family needs a motion surface")
        assert(state.hoverLift>.98 and state.rotation>.02,"every card family must ease into hover: "..tostring(case[1].id or case[1].suit).." / "..state.hoverLift.." / "..state.rotation.." / "..tostring(state.hovered))
        local original=Frame.draw
        Frame.draw=function(x,y,...)
            local px,py=g.transformPoint(x,y)
            assert(math.abs(px-state.ox)+math.abs(py-state.oy)<0.001,"late rim must use face transform")
            return original(x,y,...)
        end
        UI.drawCardBorder(0,0,128,192,nil,nil,case[1])
        Frame.draw=original
    end
    require("tests.card_frame_capture").verify()
    print("Card motion PASS: 8 rarity tiers at two sizes; idle/hover/exit/hit area at 30/60/120/144 FPS; attached frame")
    love.event.quit(0)
end

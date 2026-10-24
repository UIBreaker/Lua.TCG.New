local F=require("ui.progression_effects")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local UI=require("src.ui")
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function love.load()
    UI.initFonts()
    local cards={};for i=1,5 do cards[i]=Deck.newCard(i+3,({"hearts","clubs","spades","diamonds"})[(i-1)%4+1]) end
    local master=Deck.cloneCard(cards[1]);master.id=cards[1].id
    local game={hand=cards,persistentDeck={master},deck={},discardPile={},deities={},gold=0}
    assert(A.upgrade(game,cards[1],2,false))
    assert(F.active[cards[1]].evolution.value==2 and F.active[master].evolution.value==2,"upgrade must reach both visible and master cards")
    A.upgrade(game,cards[1],-1,false)
    assert(F.active[cards[1]].evolution.value==2,"downgrade cannot report a new evolution")
    local spn={id="spirit_fleet_wind",name="Linh Phong",rarity="common",evolutionLevel=0}
    require("src.deities").evolve(spn);require("src.deities").evolve(spn)
    assert(F.active[spn].evolution.value==2,"multiple levels merge into one effect")
    for _,c in ipairs(cards) do Deck.applyAttackSpeedBonus(c,3) end
    F.team(cards)
    assert(F.active[cards[5]].speed.age<0 and F.active[cards[1]].speed.age==0,"team buffs ripple across the hand")
    local temp=Deck.newCard(5,"hearts");Deck.applyTemporaryAttackSpeedBonus(temp,2)
    assert(F.active[temp].speed.value==2)
    local capped=Deck.newCard(5,"hearts");capped.speedBonus=999
    Deck.applyAttackSpeedBonus(capped,3);F.team({capped})
    assert(not F.active[capped],"no fake gain at the speed cap")
    assert(Deck.applyAttackSpeedBonus(nil,2)==1)
    local rng=require("src.rng");local seed=rng.getState()
    local g=love.graphics;local canvas=g.newCanvas(960,620)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(.023,.033,.048,1)
    local function title(text,y,color)
        g.setFont(UI.fonts.medium);g.setColor(color or {.88,.91,.96});g.printf(text,20,y,920,"center")
    end
    title("TIẾN HÓA · ÁNH VÀNG / TÍM, TIA SÁNG GỌN",20,{1,.83,.48})
    F.emit(cards[2],"evolution",1);F.emit(cards[3],"evolution",3)
    for _,c in ipairs({cards[1],cards[2],cards[3]}) do F.active[c].speed=nil end
    F.update(.28,false)
    UI.drawCard(cards[1],126,64,128,185)
    UI.drawCard(cards[2],316,64,128,185)
    UI.drawCard(cards[3],506,64,128,185)
    UI.drawPatronCard(spn,696,64,128,185)
    title("TĂNG TỐC TOÀN ĐỘI · NHỊP LAN QUA TỪNG LÁ",286,{.31,.94,1})
    for i,c in ipairs(cards) do
        if F.active[c] then F.active[c].evolution=nil end
        F.emit(c,"speed",3);F.active[c].speed.value=3
    end
    F.team(cards);F.update(.32,false)
    for i,c in ipairs(cards) do UI.drawCard(c,60+(i-1)*174,338,128,185) end
    -- Native effect cannot leak transforms/blending or use a ring/ghost primitive.
    local circle,arc,ellipse=g.circle,g.arc,g.ellipse
    local function forbidden() error("progression effects cannot draw circular motifs") end
    g.circle=forbidden;g.arc=forbidden;g.ellipse=forbidden
    for _,reduced in ipairs({false,true}) do
        F.reduced=reduced;g.setColor(.2,.3,.4,.7);g.setLineWidth(3);g.setBlendMode("alpha")
        g.push();g.translate(-1000,-1000);g.rotate(.2);g.scale(.6)
        local bx,by=g.transformPoint(0,0)
        F.draw(UI,cards[1],128,185)
        local ax,ay=g.transformPoint(0,0);local r,green,b,a=g.getColor()
        assert(ax==bx and ay==by and g.getLineWidth()==3 and math.abs(r-.2)<.001 and math.abs(a-.7)<.001)
        g.pop()
    end
    g.circle=circle;g.arc=arc;g.ellipse=ellipse
    assert(rng.getState()==seed,"presentation must not consume combat randomness")
    F.update(3,false);assert(not next(F.active),"effects must expire")
    title("CÙNG HIỆU ỨNG CHO THẺ, KỸ NĂNG, SPN VÀ PHẦN THƯỞNG",565,{.65,.73,.82})
    g.pop()
    local data=canvas:newImageData();local file=assert(io.open("docs/progression_effects.png","wb"))
    file:write(data:encode("png"):getString());file:close()
    print("Progression effects PASS: evolution, SPN, synced copies, permanent/temporary speed, team ripple, cap, reduced motion, expiry, RNG and render state")
    love.event.quit(0)
end

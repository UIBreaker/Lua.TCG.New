local T={stage=0,deadline=0,case=1,impacts=0}
local UI=require("src.ui");local A=require("src.advanced_hands");local D=require("src.deck")
local function click(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then
        local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
        local x,y=(w-1280*scale)/2+(b.x+b.w/2)*scale,(h-720*scale)/2+(b.y+b.h/2)*scale
        love.mousepressed(x,y,1);love.mousereleased(x,y,1);return
    end end
    error("Missing button "..id)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)local f=assert(io.open("docs/advanced_hands_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()end)
end
local presets={
 tesla_369={3,6,9,2,4},jackpot_777={7,7,7,2,4},fibonacci={14,2,3,5,8},prime={2,3,5,7,11},odd_star={14,3,5,7,9},even_frost={2,4,6,8,10},
 crimson_tide={3,5,7,9,11},obsidian_tide={3,5,7,9,11},eclipse_duality={2,4,9,4,2},four_kingdom_prism={2,4,6,9,13},
 four_kingdom_expedition={14,2,4,6,13},destiny_crown={10,11,12,13,14},continental_gate={14,14,14,14,13},answer_42={4,6,9,10,13},
 sealed_gate={14,14,14,13,13},seven_stars={7,7,7,14,13},five_ley_lines={14,4,8,10,13},endless_cycle={2,3,4,5,6}}
function love.errorhandler(message) print(debug.traceback(message,2));return function()return 1 end end
function T.update(game,cb)
    local now=love.timer.getTime();if now<T.deadline then return end
    if T.stage==0 then
        cb.startNewGame("red_deck");cb.openShop()
        for _,h in ipairs(A.ordered) do
            local handArt,planetArt=UI.getHandImage(h.id),UI.getConsumableImage({id="planet_"..h.id})
            assert(handArt and planetArt and handArt~=planetArt);game.unlockedHands[h.id]=true
        end
        assert(UI.getPackImage("hand_styles_advanced"))
        cb.openPack({packType="hand_styles",name="RƯƠNG THẾ ĐÁNH"});T.stage=.5
    elseif T.stage==.5 then
        for _,b in ipairs(cb.getButtons()) do if b.id:match("^choose_pack_") then assert(b.text=="HỌC / +1 CẤP") end end
        shot("basic_chest");T.stage=.6
    elseif T.stage==.6 then
        for _,h in ipairs(require("src.poker").HAND_TYPES_ORDERED) do game.unlockedHands[h.id]=true end
        cb.openPack(require("src.shop").ADVANCED_HAND_CHEST);T.stage=1
    elseif T.stage==1 then
        for _,b in ipairs(cb.getButtons()) do if b.id:match("^choose_pack_") then assert(b.text=="HỌC / +1 CẤP") end end
        assert(#cb.getShopData().currentPackOpening.cards==3);shot("chest");T.stage=1.5
    elseif T.stage==1.5 then click(cb,"choose_pack_1");cb.openHandbook();T.stage=2
    elseif T.stage==2 then click(cb,"handbook_advanced");love.window.setMode(960,540,{resizable=true});love.resize(960,540);T.stage=3
    elseif T.stage==3 then shot("codex_page1");T.stage=3.5
    elseif T.stage==3.5 then click(cb,"handbook_next");love.window.setMode(1920,1080,{resizable=true});love.resize(1920,1080);T.stage=4
    elseif T.stage==4 then shot("codex_page2");T.stage=4.5
    elseif T.stage==4.5 then click(cb,"handbook_select_fibonacci");T.stage=4.6
    elseif T.stage==4.6 then shot("codex_fibonacci");T.stage=4.7
    elseif T.stage==4.7 then click(cb,"handbook_next");T.stage=5
    elseif T.stage==5 then shot("codex_page3");T.stage=5.5
    elseif T.stage==5.5 then cb.closeHandbook();love.window.setMode(1280,720,{resizable=true});love.resize(1280,720);T.stage=6
    elseif T.stage==6 then
        if T.case>#A.ordered then print("18 real advanced attacks / art / chest / codex pagination / one impact / 960+1920 layouts passed");love.event.quit(0);return end
        local h=A.ordered[T.case]
        cb.startMonsterEncounter(1,false);game.maxHandSize=5;game.hand={};game.deck={};game.discardPile={};game.selectedIndices={}
        game.unlockedHands={high_card=true,[h.id]=true}
        local suits=({crimson_tide={"hearts","diamonds","hearts","diamonds","hearts"},obsidian_tide={"spades","clubs","spades","clubs","spades"},tesla_369={"hearts","hearts","hearts","clubs","spades"}})[h.id] or {"hearts","clubs","spades","diamonds","hearts"}
        if h.id=="eclipse_duality" then suits={"hearts","diamonds","hearts","clubs","spades"} end
        for i,r in ipairs(presets[h.id]) do game.hand[i]=D.newCard(r,suits[i]);game.hand[i].disableFactionPassives=true end
        game.monster.hp=1000000;game.monster.maxHp=1000000;game.monster.damageLagHp=1000000;game.monster.attackSpeed=1
        game.monster.targetAura=1000;game.abilityApproved={};game.deities={};game.playerHp=75
        for i=1,5 do cb.selectCardIndex(i) end
        assert(#game.selectedIndices==5,"advanced unlock must allow all five selections")
        cb.playSelectedHand();local anim,state=cb.getScoringState();assert(state=="scoring")
        assert(anim.sequence.attack.profile.id==h.id);T.hp=game.monster.hp;T.impacts=0;T.shot=false;T.stage=7;T.started=now
    elseif T.stage==7 then
        local anim,state=cb.getScoringState();local s=anim.sequence;local e=s and s.events[s.index]
        assert(now-T.started<25,"advanced combat timed out")
        if game.monster.hp<T.hp then T.impacts=T.impacts+1;T.hp=game.monster.hp end
        if e and e.kind=="ANTICIPATION" and not T.shot then shot(A.ordered[T.case].id);T.shot=true end
        if s and UI.ScoringFeel.isFinished(anim) and state~="scoring" then
            assert(T.impacts==1 and game.advancedHand.resolved,"exactly one main impact")
            print("Advanced real combat "..A.ordered[T.case].id.." passed")
            T.case=T.case+1;T.stage=6
        end
    end
    T.deadline=now+(T.stage==7 and .03 or .4)
end
return T

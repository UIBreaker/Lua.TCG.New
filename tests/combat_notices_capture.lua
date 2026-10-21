local N=require("src.combat_notices")
local UI=require("src.ui")
local D=require("src.deities")
local Deck=require("src.deck")
local B=require("src.boss_abilities")
local A=require("src.spn_anomalies")
local T={stage=0,clock=0,at=0,overlays=0}
local record=false
for _,a in ipairs(arg or {}) do if a=="--record-combat-notices" then record=true end end
local function shot(path)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function nextStage() T.stage=T.stage+1;T.at=T.clock end
local function clickControl(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then
        assert(not b.disabled,id.." disabled")
        local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
        local x,y=(w-1280*scale)/2+(b.x+b.w/2)*scale,(h-720*scale)/2+(b.y+b.h/2)*scale
        love.mousepressed(x,y,1);love.mousereleased(x,y,1);return
    end end
    error("missing control "..id)
end
function T.update(game,cb)
    local age=T.clock-T.at
    assert(age<15,"notice stage timeout "..T.stage)
    if T.stage==0 then
        require("tests.combat_notices_smoke")
        local update=love.update
        love.update=function(dt) local step=math.min(dt,1/30);T.clock=T.clock+step;update(step) end
        local draw=N.draw
        N.draw=function(...)
            local rectangle=love.graphics.rectangle
            love.graphics.rectangle=function(mode,x,y,w,h,...)
                assert(w<260 or h<30,"no screen-wide notification or journal panel")
                return rectangle(mode,x,y,w,h,...)
            end
            draw(...);love.graphics.rectangle=rectangle
        end
        local overlay=N.overlay
        N.overlay=function(ui,card,...)
            if N.active and N.restriction(game,card) then T.overlays=T.overlays+1 end
            return overlay(ui,card,...)
        end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        local def=require("src.kingdom_bosses").definitions[4]
        local Run=require("src.run_manager")
        local blind=Run.generateAnteBlinds(40,"red_deck",def.entitySuit,20)[3];blind.debuff=def
        require("src.combat").start(game,Run.createBlindMonster(blind,game,true),40)
        game.hand={Deck.newCard(8,def.entitySuit),Deck.newCard(7,"hearts"),Deck.newCard(6,"clubs")}
        game.maxHandSize=3;game.deities={};game.spnFeedback={};game.spnCombat={}
        for i,id in ipairs({"spirit_hour_product","spirit_guardian_shell","spirit_parity"}) do assert(D.addDeity(game,D.CATALOG[id],i)) end
        T.clockCard=game.deities[1];T.victim=game.deities[2]
        love.mouse.setPosition(3,3);nextStage();return
    end
    if record and T.clock>=(T.nextShot or 0) then
        shot(string.format(".tmp/combat-notices/frame_%04d.png",T.frame or 0))
        T.frame=(T.frame or 0)+1;T.nextShot=T.clock+.05
    end
    if T.stage==1 and age>1 then
        assert(N.restriction(game,game.hand[1])=="VÔ HIỆU" and T.overlays>0)
        shot("docs/combat_notices_disabled.png");nextStage()
    elseif T.stage==2 and age>.3 then
        if not T.selected then cb.selectCardIndex(2);T.selected=true;return end
        clickControl(cb,"discard")
        assert(T.clockCard.spnGrowth.discards==1 and N.inspect(game).hits[T.clockCard]);nextStage()
    elseif T.stage==3 and age>.12 then
        assert(N.pose(T.clockCard)~=0,"discard activation must shake")
        shot("docs/combat_notices_growth.png");nextStage()
    elseif T.stage==4 and age>1 then
        D.destroyDeity(game,2,true,nil,"LINH GIÁP THỬ · đã kết thúc hiệu lực")
        local anim=cb.getScoringState();A.showFeedback(game,anim);nextStage()
    elseif T.stage==5 and age>.3 then
        assert(not game.deities[2] and #N.inspect(game).ghosts==1)
        shot("docs/combat_notices_destroyed.png");nextStage()
    elseif T.stage==6 and age>2.3/require("src.game_speed").base then
        assert(#N.inspect(game).ghosts==0)
        cb.startMonsterEncounter(20,true)
        game.hand={Deck.newCard(8,"hearts"),Deck.newCard(7,"hearts"),Deck.newCard(6,"clubs")}
        game.deities={};D.addDeity(game,D.CATALOG.spirit_hour_product,1)
        game.monster.bossData={id="notice_fixture",name=game.monster.name,expeditionActive=true,active={name="Phong Ấn",op="silence",description="Khóa kỹ năng lá được nhắm trong tay kế tiếp.",cooldown=1}}
        B.start(game);B.handStart(game);nextStage()
    elseif T.stage==7 and age>.6 then
        assert(N.warning(game,game.hand[1])=="BOSS NHẮM")
        shot("docs/combat_notices_boss_target.png");nextStage()
    elseif T.stage==8 and age>.4 then B.handEnd(game);nextStage()
    elseif T.stage==9 and age>.5 then
        assert(N.restriction(game,game.hand[1])=="KHÓA KỸ NĂNG")
        shot("docs/combat_notices_skill_lock.png");nextStage()
    elseif T.stage==10 and age>.5 then
        B.handEnd(game);assert(not N.restriction(game,game.hand[1]))
        local s=B.state(game.monster);s.slotLock={kind="spn",slot=1,untilHand=s.handIndex}
        cb.setReducedMotion(true);cb.setScoringSpeed(true)
        love.window.setMode(960,540,{resizable=true});love.resize(960,540);nextStage()
    elseif T.stage==11 and age>.7 then
        assert(N.restriction(game,game.deities[1])=="SPN BỊ KHÓA")
        N.activate(game.deities[1]);local a,b=N.pose(game.deities[1]);assert(a==0 and b==0)
        shot("docs/combat_notices_960.png");nextStage()
    elseif T.stage==12 and age>.2 then
        assert(not N.wheel and not N.containsLog and not N.inspect(game).history,"notification/journal removed")
        shot("docs/combat_notices_clean.png")
        assert(T.overlays>20)
        nextStage()
    elseif T.stage==13 and age>.3 then
        cb.setReducedMotion(false);cb.setScoringSpeed(false)
        love.window.setMode(1920,1080,{resizable=true});love.resize(1920,1080)
        cb.startMonsterEncounter(1,false)
        game.monster.hp=1000000;game.monster.maxHp=1000000;game.monster.damageLagHp=1000000
        game.monster.attack=0;game.monster.attackSpeed=0;game.monster.enemyInventory=nil;game.monster.enemyAbility=nil
        game.monster.isBoss=false;game.monster.bossData=nil
        game.hand={Deck.newCard(2,"hearts"),Deck.newCard(3,"hearts"),Deck.newCard(4,"clubs")}
        game.deities={};game.spnFeedback={}
        for i,id in ipairs({"spirit_right_echo","spirit_pebble","spirit_left_refrain"}) do D.addDeity(game,D.CATALOG[id],i) end
        require("src.combat").getHitChance=function() return 1 end
        T.scoreHits={};T.hands=game.handsRemaining
        nextStage()
    elseif T.stage==14 and age>.6 then
        cb.selectCardIndex(1);cb.playSelectedHand();nextStage()
    elseif T.stage==15 then
        for slot,d in pairs(game.deities) do if N.inspect(game).hits[d] then T.scoreHits[slot]=true end end
        local anim,screen=cb.getScoringState()
        if not T.scoreShot and T.scoreHits[1] and T.scoreHits[3] then shot("docs/combat_notices_scoring.png");T.scoreShot=true end
        if screen~="playing" or anim.active or anim.enemyTurn then return end
        assert(game.handsRemaining==T.hands-1 and game.monster.hp<1000000)
        assert(T.scoreHits[1] and T.scoreHits[2] and T.scoreHits[3],"score source, copier and repeat helper all react")
        print("COMBAT NOTICES RUNTIME PASS: actual discard/scoring, physical copier and repeat helper, full/skill/slot locks, boss target, removed SPN ghost/expiry, no banner/journal, reduced/fast motion and 960/1920; "..T.overlays.." rendered status overlays")
        love.event.quit(0)
    end
end
return T

local R=require("render.renderer")
local Transition=require("src.scene_transition")
local UI=require("src.ui")
local Reward=require("src.reward_system")
local Shop=require("src.shop")
local Combat=require("src.combat")
local Deck=require("src.deck")
local Rng=require("src.rng")
local Persistence=require("src.persistence")
Persistence.deleteRun=function() return true end
Persistence.saveRun=function() return true end
Persistence.saveSettings=function() return true end
local T={clock=0}
local preview=true
for _,a in ipairs(arg or {}) do if a=="--no-motion-preview" then preview=false end end
local cases={{name="normal"},{name="fast",fast=true},{name="reduced",reduced=true},
    {name="low",quality="LOW"},{name="no_canvas",noCanvas=true},{name="disabled",disabled=true}}
local index,stage,started,frame,nextShot,recordUntil=0,"start",0,0,0,0
local canvas,enabled,quality,serial,gold,owned,arenaSerial,checks= nil,nil,nil,nil,nil,nil,nil,0
local observed={}
local originalBegin=R.beginFrame
local originalChance=Combat.getHitChance
local originalEnter=Shop.enterAfterCombat
local function after(name) stage=name;started=T.clock end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function click(b,touch)
    assert(b,"missing button")
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local x,y=(w-1280*scale)/2+(b.x+b.w/2)*scale,(h-720*scale)/2+(b.y+b.h/2)*scale
    if touch then love.touchpressed("scene-test",x,y);love.touchreleased("scene-test",x,y)
    else love.mousepressed(x,y,1);love.mousereleased(x,y,1) end
end
local function spam(game,cb)
    local state=select(2,cb.getRunState());local money,hp,hands,receipt=game.gold,game.playerHp,game.handsRemaining,game.rewardClaimSerial
    love.keypressed("return");love.keypressed("space");love.mousepressed(800,660,1);love.mousereleased(800,660,1)
    love.touchpressed("blocked-scene",800,660);love.touchreleased("blocked-scene",800,660)
    cb.playSelectedHand()
    assert(select(2,cb.getRunState())==state and game.gold==money and game.playerHp==hp
        and game.handsRemaining==hands and game.rewardClaimSerial==receipt,"transition input cannot affect the arriving scene")
end
function T.update(game,cb)
    assert(T.clock-started<25,"scene timeout at "..stage.." / "..index)
    if preview and index==1 and T.clock<recordUntil and T.clock>=nextShot then
        local path=string.format(".tmp/scene-motion/frame_%04d.png",frame)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
        end)
        frame=frame+1;nextShot=nextShot+.05
    end
    if stage=="start" then
        require("tests.scene_motion_smoke")
        require("tests.hd2d_smoke")
        canvas,enabled,quality=R.transitionCanvas,R.config.enabled,R.quality
        local update=love.update
        love.update=function(dt)
            local step=math.min(dt,preview and index==1 and T.clock<recordUntil and 1/30 or .05)
            T.clock=T.clock+step;update(step)
        end
        Combat.getHitChance=function() return 1 end
        Shop.enterAfterCombat=function(g)
            originalEnter(g);g.shopMode="small";g.pendingBarter=nil;g.pendingBloodShop=nil;g.pendingSoulShop=nil
        end
        Reward.config.tables.normal_enemy={rolls={2,2},entries={{id="playing_card",weight=1}}}
        R.beginFrame=function(previous,state,g)
            local should=R.stateKey and R.stateKey~=Transition.key(state,g) and R.config.enabled and R.transitionCanvas and previous
            local pixels=should and previous:newImageData()
            local rng,amount,claim=Rng.getState(),g.gold,g.rewardClaimSerial
            local activeCanvas,shader=love.graphics.getCanvas(),love.graphics.getShader()
            local changed=originalBegin(previous,state,g)
            assert(Rng.getState()==rng and g.gold==amount and g.rewardClaimSerial==claim,"scene capture cannot mutate gameplay")
            assert(love.graphics.getCanvas()==activeCanvas and love.graphics.getShader()==shader,"snapshot must restore graphics state")
            if changed then
                assert(pixels and R.transitionAge==0 and Transition.pose(R).opacity==1,"outgoing frame starts intact")
                local spec=cases[index]
                if spec then
                    assert(R.transitionReduced==(spec.reduced==true),"first drawn frame uses the current motion preference")
                    if spec.reduced then assert(Transition.pose(R).outY==0 and R.mapOffset()==0) end
                end
                local copy=R.transitionCanvas:newImageData();local w,h=pixels:getDimensions()
                for _,p in ipairs({{.1,.1},{.5,.15},{.8,.35},{.4,.65},{.7,.85}}) do
                    local x,y=math.floor(w*p[1]),math.floor(h*p[2])
                    local r,gc,b,a=pixels:getPixel(x,y);local cr,cg,cb,ca=copy:getPixel(x,y)
                    assert(math.abs(r-cr)<.01 and math.abs(gc-cg)<.01 and math.abs(b-cb)<.01 and math.abs(a-ca)<.01,
                        "snapshot must contain the previous displayed composite, including an interrupted fade")
                end
                pixels:release();copy:release();checks=checks+1
                observed[state]=true
                if preview and index==1 then recordUntil=T.clock+1;nextShot=T.clock end
            end
            return changed
        end
        after("case")
    elseif stage=="case" then
        index=index+1
        R.transitionCanvas=canvas;R.config.enabled=enabled
        if not cases[index] then cb.setScoringSpeed(false);cb.setReducedMotion(false);after("rapid_start");return end
        local spec=cases[index]
        R.setQuality(spec.quality or "HIGH")
        cb.startNewGame("red_deck");cb.setScoringSpeed(spec.fast==true);cb.setReducedMotion(spec.reduced==true)
        if spec.noCanvas then R.transitionCanvas=nil end
        if spec.disabled then R.config.enabled=false end
        game.maxHandSize=3;game.persistentDeck={}
        for i=1,6 do game.persistentDeck[i]=Deck.newCard(i+3,"spades") end
        game.deities={};game.consumables={};game.abilityApproved={}
        serial=game.rewardClaimSerial or 0
        after("route")
    elseif stage=="route" then
        if R.transitionBusy(select(2,cb.getRunState()),game) then spam(game,cb) end
        if T.clock-started>.8 and not R.transitionBusy("BLIND_SELECT",game) then
            assert(R.mapOffset()==0)
            click(button(cb,"fight_blind"),index==2)
            assert(select(2,cb.getRunState())=="playing")
            local m=game.monster;m.hp=1;m.maxHp=1;m.damageLagHp=1;m.creatureArmor=0
            m.enemyInventory=nil;m.enemyAbility=nil;m.isBoss=false;m.bossData=nil
            m.attack=0;m.attackSpeed=0;m.intent={type="attack",value=0}
            game.playerHp=200;game.maxPlayerHp=200;game.playerArmor=0;game.playerShield=0;game.abilityApproved={}
            if R.config.enabled and R.transitionCanvas then
                assert(R.transitionBusy("playing",game),"lock begins before battle's first draw");spam(game,cb)
            end
            after("battle")
        end
    elseif stage=="battle" and T.clock-started>.9 and not UI.HandMotion.busy(game.hand) and not R.transitionBusy("playing",game) then
        arenaSerial=R.transitionSerial
        cb.selectCardIndex(1);assert(#game.selectedIndices==1);love.keypressed("space")
        assert(select(2,cb.getRunState())=="scoring");after("score")
    elseif stage=="score" then
        local _,state=cb.getScoringState()
        if state=="scoring" then assert(R.transitionSerial==arenaSerial,"playing/scoring must not replay the scene transition") end
        if state=="CASH_OUT" then
            assert(game.rewardClaimSerial==serial+1 and #game.hand==0)
            gold,owned=game.gold,#game.persistentDeck
            if R.config.enabled and R.transitionCanvas then spam(game,cb) end
            after("reward")
        end
    elseif stage=="reward" then
        if R.transitionBusy("CASH_OUT",game) then spam(game,cb) end
        if T.clock-started>.6 and not R.transitionBusy("CASH_OUT",game) then
            local a=cb.getRewardAnimation()
            if not a.finished then love.keypressed("return") end
            assert(a.finished and game.gold==gold and #game.persistentDeck==owned)
            after("continue")
        end
    elseif stage=="continue" and T.clock-started>.1 then
        love.keypressed("return");assert(select(2,cb.getRunState())=="shop")
        if R.config.enabled and R.transitionCanvas then spam(game,cb) end
        after("shop")
    elseif stage=="shop" then
        if R.transitionBusy("shop",game) then spam(game,cb) end
        if T.clock-started>1 and not UI.Polish.busy() and not R.transitionBusy("shop",game) then
            assert(R.scene.name=="shop" and game.gold==gold and #game.persistentDeck==owned)
            click(button(cb,"leave_shop"),index==2)
            assert(select(2,cb.getRunState())=="BLIND_SELECT")
            if R.config.enabled and R.transitionCanvas then spam(game,cb) end
            after("return_map")
        end
    elseif stage=="return_map" and T.clock-started>1 then
        assert(not R.transitionBusy("BLIND_SELECT",game) and R.mapOffset()==0)
        assert(game.gold==gold and #game.persistentDeck==owned and game.rewardClaimSerial==serial+1)
        print("Scene runtime PASS: "..cases[index].name.."; route → combat → reward → shop → route")
        after("case")
    elseif stage=="rapid_start" then
        cb.setCaptureState("shop");game.shopMode="large";after("rapid_shop")
    elseif stage=="rapid_shop" and R.displayedScene=="shop" and R.transitionAge>0 then
        cb.setCaptureState("BLIND_SELECT");after("rapid_route")
    elseif stage=="rapid_route" and R.displayedScene=="BLIND_SELECT" and R.transitionAge>0 then
        assert(R.transitionFrom=="shop");game.map=require("src.map").generate(1)
        cb.setCaptureState("map");after("legacy_map")
    elseif stage=="legacy_map" and T.clock-started>.8 then
        assert(R.displayedScene=="map" and not R.transitionBusy("map",game) and R.mapOffset()==0)
        for _,state in ipairs({"playing","CASH_OUT","shop","BLIND_SELECT","map"}) do assert(observed[state],state.." snapshot missing") end
        R.beginFrame=originalBegin;Combat.getHitChance=originalChance;Shop.enterAfterCombat=originalEnter
        R.setQuality(quality)
        print("Scene motion runtime PASS: six real round trips, touch/keyboard/mouse lock, rapid interruption, legacy map; "..checks.." exact GPU snapshots; "..frame.." preview frames")
        love.event.quit(0)
    end
end
return T

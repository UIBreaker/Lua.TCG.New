local UI=require("src.ui")
local Reward=require("src.reward_system")
local D=require("src.death_vfx")
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
local cases={{name="victory",win=true},{name="victory_fast",win=true,fast=true},
    {name="victory_reduced",win=true,reduced=true},{name="reward_skip",win=true,skip=true},
    {name="enemy_first_defeat",before=true},{name="counter_defeat_fast",fast=true},
    {name="end_turn_defeat_reduced",endTurn=true,reduced=true},{name="pages_exchange",pages=true,fast=true}}
local index,stage,started,frame,nextShot=0,"start",0,0,0
local recording,serial,reward,gold,rng,seenDeath,seenCollection,seenContact,defeatStart
local originalChance=Combat.getHitChance
local function after(name) stage=name;started=T.clock end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function click(b)
    assert(b,"missing button")
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local x,y=(w-1280*scale)/2+(b.x+b.w/2)*scale,(h-720*scale)/2+(b.y+b.h/2)*scale
    love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
function T.update(game,cb)
    assert(T.clock-started<30,"outcome timeout at "..stage.." case "..index)
    if recording and T.clock>=nextShot then
        local path=string.format(".tmp/outcome-motion/frame_%04d.png",frame)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
        end)
        frame=frame+1;nextShot=nextShot+.05
    end
    if stage=="start" then
        require("tests.outcome_motion_smoke")
        local update=love.update
        love.update=function(dt)
            local step=math.min(dt,recording and 1/30 or .05);T.clock=T.clock+step;update(step)
        end
        Combat.getHitChance=function() return 1 end
        Reward.config.tables.normal_enemy={rolls={2,2},entries={{id="playing_card",weight=1}}}
        Reward.config.tables.motion={rolls={3,3},entries={{id="chest",weight=1}}}
        Reward.config.tables.silver_chest={rolls={2,2},entries={{id="playing_card",weight=1}}}
        after("case")
    elseif stage=="case" then
        index=index+1
        if not cases[index] then
            Combat.getHitChance=originalChance
            print("Outcome motion runtime PASS: 8 flows; "..frame.." preview frames")
            love.event.quit(0);return
        end
        local spec=cases[index]
        cb.startNewGame("red_deck");cb.setScoringSpeed(spec.fast==true);cb.setReducedMotion(spec.reduced==true)
        game.maxHandSize=3;game.persistentDeck={}
        for i=1,6 do game.persistentDeck[i]=Deck.newCard(i+3,"spades") end
        cb.startMonsterEncounter(1,false)
        game.deities={};game.consumables={};game.abilityApproved={};game.potionCombat={}
        game.playerHp=(spec.win or spec.pages) and 200 or 1
        game.maxPlayerHp=200;game.playerArmor=0;game.playerShield=0
        for _,m in ipairs(require("src.enemy_group").members(game)) do
            m.hp=spec.win and 1 or 1000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.creatureArmor=0
            m.isBoss=false;m.bossData=nil;m.enemyInventory=nil;m.enemyAbility=nil
            m.attack=spec.win and 0 or 60;m.attackSpeed=spec.before and 999 or 0
            m.intent={type="attack",value=m.attack,label="Tấn công"}
        end
        serial=game.rewardClaimSerial or 0;seenDeath=false;seenCollection=false;seenContact=false
        reward=nil;defeatStart=nil;love.mouse.setPosition(2,2);after("deal")
    elseif stage=="deal" and T.clock-started>.9 and not UI.HandMotion.busy(game.hand) then
        local spec=cases[index]
        if spec.pages then cb.openReward("motion");after("reward")
        elseif spec.endTurn then game.handsRemaining=0;assert(cb.endPlayerTurn());after("combat")
        else cb.selectCardIndex(1);assert(#game.selectedIndices==1);love.keypressed("space");after("combat") end
    elseif stage=="combat" then
        local spec=cases[index];local a,state=cb.getScoringState()
        if spec.win then
            if D.kind=="enemy" then
                seenDeath=true
                if preview and index==1 and not recording then recording=true;nextShot=T.clock end
                if D.busy() then assert(state=="scoring" or state=="playing","reward waits for ash") end
            end
            if UI.HandMotion.onCollected then
                seenCollection=true;assert(state=="playing" or state=="scoring")
                UI.finishCombatVictory();assert(UI.HandMotion.onCollected,"one collection callback")
            end
            if state=="CASH_OUT" then
                assert(seenDeath and (spec.reduced or seenCollection) and #game.hand==0)
                assert(game.rewardClaimSerial==serial+1,"one reward transaction")
                UI.finishCombatVictory();assert(game.rewardClaimSerial==serial+1,"duplicate victory cannot complete another blind")
                after("reward")
            end
        else
            if a.enemyTurn and a.enemyTurn.phase=="recover" then seenContact=true end
            if state=="defeating" then
                assert(seenContact and game.playerHp==0 and not a.enemyTurn)
                if preview and index==5 then recording=true;nextShot=T.clock end
                defeatStart=T.clock;after("defeat")
            end
        end
    elseif stage=="reward" then
        local spec=cases[index];local a,state=cb.getRewardAnimation()
        assert(state=="CASH_OUT")
        if not reward then reward=a.result;gold=game.gold;rng=Rng.getState() end
        assert(a.result==reward and game.gold==gold and Rng.getState()==rng,"presentation cannot grant or roll rewards")
        if spec.skip and not a.finished and not UI.sceneTransitionBusy() then love.keypressed("return");assert(a.finished) end
        if a.finished then
            assert(a.displayTotal==reward.earnedGold and a.walletTotal==game.gold)
            for i=1,#a.slots do assert(Reward.slotPose(a,i).ready,"continue waits for faces") end
            if spec.reduced then assert(a.reducedMotion and #a.coins==0 and #a.sparks==0) end
            if spec.pages then
                assert(#a.slots>=9);love.keypressed("left");assert(a.lootPage==1)
                after("page")
            else after("continue") end
        end
    elseif stage=="page" and T.clock-started>.7 then
        local a=cb.getRewardAnimation();assert(Reward.slotPose(a,1).ready)
        local expected=Reward.getBulkExchangeGold(game,a.result)
        assert(expected>0);click(button(cb,"cashout_exchange_all"));click(button(cb,"cashout_exchange_all"))
        assert(game.gold==gold+expected and a.result.bulkExchanged)
        gold=game.gold;after("continue")
    elseif stage=="continue" and T.clock-started>.35 then
        recording=false
        local a=cb.getRewardAnimation();love.keypressed("return")
        assert(select(2,cb.getRunState())=="shop" and not game.pendingVictoryReward)
        assert(game.gold==gold and game.rewardClaimSerial==serial+1)
        print("Outcome runtime PASS: "..cases[index].name.."; earned="..a.result.earnedGold..", serial="..game.rewardClaimSerial)
        after("shop")
    elseif stage=="shop" and T.clock-started>.8 then
        assert(not UI.Polish.busy());after("case")
    elseif stage=="defeat" then
        local spec=cases[index];local _,state=cb.getScoringState()
        assert(D.kind=="player" and D.reducedMotion==(spec.reduced==true))
        local age=D.age;love.keypressed("space");love.mousepressed(1,1,1)
        assert(D.age>=age and game.rewardClaimSerial==serial,"defeat input cannot restart or grant rewards")
        if state=="gameover" then
            assert(not D.busy() and D.uiProgress()==1 and D.infoProgress()==1)
            assert(T.clock-defeatStart<=D.duration/(spec.fast and 2 or 1)+.1,"defeat follows combat speed")
            after("retry")
        end
    elseif stage=="retry" and T.clock-started>.35 then
        recording=false;click(button(cb,"retry"))
        assert(select(2,cb.getRunState())~="defeating" and not D.busy())
        print("Outcome runtime PASS: "..cases[index].name.."; settled defeat and real retry")
        after("case")
    end
end
return T

local UI=require("src.ui")
local M=UI.HandMotion
local Deck=require("src.deck")
local T={clock=0}
local preview=true
for _,a in ipairs(arg or {}) do if a=="--no-motion-preview" then preview=false end end
local stage,started,recording,nextShot,frame="start",0,false,0,0
local removed,beforeDiscards,beforeDeck,beforeOwned,pack,rewardCase
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function click(b)
    assert(b,"missing control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function after(name) stage=name;started=T.clock end
local function openPack(cb)
    cb.openShop();cb.openPack({packType="spectral",name="RƯƠNG BIẾN ĐỔI"},true)
    pack=cb.getShopData().currentPackOpening
end
function T.update(game,cb)
    assert(T.clock-started<12,"motion timeout at "..stage)
    if recording and T.clock>=nextShot then
        local path=string.format(".tmp/hand-chest-motion/frame_%04d.png",frame)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
        end)
        frame=frame+1;nextShot=nextShot+0.05
    end
    if stage=="start" then
        require("tests.hand_chest_motion_smoke")
        local update=love.update
        love.update=function(dt) local step=preview and math.min(dt,1/30) or dt;T.clock=T.clock+step;update(step) end
        cb.setScoringSpeed(false);cb.setReducedMotion(false)
        cb.startNewGame("red_deck");game.maxHandSize=5;game.persistentDeck={}
        for i=1,12 do
            local c=Deck.newCard(2+(i%10),"spades");c.disableFactionPassives=true
            game.persistentDeck[i]=c
        end
        game.unlockedHands.full_house=true
        cb.startMonsterEncounter(1,false);game.monster.hp=100000;game.monster.maxHp=100000
        game.consumables={};game.backpackConsumables={};love.mouse.setPosition(2,2)
        assert(M.busy(game.hand) and #game.hand==5)
        beforeOwned=#game.persistentDeck
        recording=preview;nextShot=T.clock;after("deal")
    elseif stage=="deal" then
        if M.busy(game.hand) then
            local mode=game.sortMode
            love.keypressed("1");love.keypressed(mode=="rank" and "s" or "r")
            assert(#game.selectedIndices==0 and game.sortMode==mode,"moving hand rejects selection/sort keys")
            click({x=590,y=470,w=100,h=145})
            assert(#game.selectedIndices==0,"airborne hand rejects selection")
            love.mouse.setPosition(2,2)
        elseif T.clock-started>1.1 then
            for i=1,2 do
                local c=game.hand[i];click({x=c.visualX+10,y=c.visualY+15,w=60,h=90})
            end
            assert(#game.selectedIndices==2,"settled hand selects with real mouse input")
            removed={game.hand[1],game.hand[2]};beforeDiscards=game.discardsRemaining;beforeDeck=#game.deck
            love.keypressed("d")
            assert(#game.discardPile==2 and #game.hand==5 and #game.deck==beforeDeck-2)
            assert(game.discardsRemaining==beforeDiscards-1 and M.returnDuration()>0)
            for _,c in ipairs(removed) do assert(M.hidden(c),"returned card's ghost owns the old face") end
            for _,c in ipairs(game.hand) do if M.isDealing(c) then assert(M.hidden(c),"replacement waits") end end
            love.keypressed("d");assert(game.discardsRemaining==beforeDiscards-1,"discard spam cannot spend twice")
            love.mouse.setPosition(2,2);after("discard")
        end
    elseif stage=="discard" and not M.busy(game.hand) and T.clock-started>1.3 then
        assert(#game.persistentDeck==beforeOwned and #game.discardPile==2)
        print("Hand motion runtime PASS: opening deal, input guard, select, collection, delayed replacement, discard accounting")
        openPack(cb);after("pack")
    elseif stage=="pack" then
        if pack.animationTimer<1 then assert(not button(cb,"choose_pack_1"),"unrevealed choices stay locked") end
        if pack.animationTimer>=UI.ChestChoices.finished() and T.clock-started>2.2 then
            recording=false
            after("pack_keep")
        end
    elseif stage=="pack_keep" then
        click(assert(button(cb,"keep_pack_2")))
        assert(not cb.getShopData().currentPackOpening and #game.backpackConsumables==1,"keep resolves once")
        print("Chest motion runtime PASS: shop ash, stagger, flip/materialization, settled input, keep")
        rewardCase=1;after("reward_start")
    elseif stage=="reward_start" then
        local c=Deck.newCard(12,"diamonds")
        local rewards={{type="card",card=c,title="TIẾP VIỆN",color=c.color},
            {type="equipment",item=require("src.equipment").ITEMS.gem_fire,title="DI VẬT",color=UI.COLORS.goldYellow},
            {type="equipment",item=require("src.equipment").ITEMS[require("src.equipment").POOL[2]],title="DI VẬT",color=UI.COLORS.chipsBlue}}
        beforeOwned=#game.persistentDeck
        cb.previewChest(rewards,rewardCase==2);after("reward")
    elseif stage=="reward" and T.clock-started>2.1 then
        click(assert(button(cb,"chest_choice_1_1")))
        assert(#game.persistentDeck==beforeOwned+1 and select(2,cb.getRunState())=="map")
        print("Chest motion runtime PASS: "..(rewardCase==1 and "treasure" or "boss").." shared reveal and one reward")
        rewardCase=rewardCase+1;after(rewardCase<=2 and "reward_start" or "fast_start")
    elseif stage=="fast_start" then
        cb.setScoringSpeed(true);openPack(cb);after("fast")
    elseif stage=="fast" and T.clock-started>1 then
        assert(pack.animationTimer>=UI.ChestChoices.finished(),"fast chest uses shared speed")
        click(assert(button(cb,"keep_pack_1")));assert(#game.backpackConsumables==2)
        cb.setReducedMotion(true);openPack(cb);after("reduced")
    elseif stage=="reduced" and T.clock-started>1 then
        assert(require("src.death_vfx").reducedMotion)
        local pose=UI.ChestChoices.pose(0.95,1)
        assert(pose.rotation==0 and pose.scale==1)
        click(assert(button(cb,"keep_pack_1")));assert(#game.backpackConsumables==3)
        cb.setReducedMotion(false);cb.setScoringSpeed(false)
        cb.startMonsterEncounter(1,false);after("victory_prepare")
    elseif stage=="victory_prepare" and not M.busy(game.hand) then
        beforeOwned=#game.persistentDeck
        T.owned={};for _,c in ipairs(game.persistentDeck) do T.owned[c.id]=true end
        T.rewardSerial=game.rewardClaimSerial or 0
        game.monster.hp=0;game.potionVictoryPending=true
        after("victory_wait")
    elseif stage=="victory_wait" and M.onCollected then
        assert(select(2,cb.getRunState())=="playing","victory keeps the arena until collection lands")
        UI.finishCombatVictory();assert(M.onCollected,"repeated victory notifications keep one callback")
        after("victory")
    elseif stage=="victory" and not M.onCollected then
        assert(select(2,cb.getRunState())=="CASH_OUT" and #game.hand==0)
        local remaining={};for _,c in ipairs(game.persistentDeck) do remaining[c.id]=true end
        for id in pairs(T.owned) do assert(remaining[id],"collection must not remove an owned card") end
        assert(game.rewardClaimSerial==T.rewardSerial+1,"victory grants its normal loot exactly once")
        print("Motion runtime PASS: fast/reduced chest, victory collection and one scene transition; "..frame.." preview frames")
        love.event.quit(0)
    end
end
return T

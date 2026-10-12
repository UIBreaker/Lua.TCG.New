local T={};local step,deadline=0,0
local UI=require("src.ui")
local Shop=require("src.shop")
local Deck=require("src.deck")
local PotionFx=require("ui.potion_effects")
local function click(button)
    assert(button,"Missing potion button")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x=(w-1280*s)/2+(button.x+button.w/2)*s
    local y=(h-720*s)/2+(button.y+button.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function targetButton(index)
    for _,b in ipairs(assert(UI.AbilityUI.current).buttons or {}) do if b.id=="target" and b.index==index then return b end end
end
local function shot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/potion_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function battle(game,cb)
    cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
    game.deities={};game.hand={Deck.newCard(8,"spades"),Deck.newCard(8,"diamonds"),Deck.newCard(8,"hearts")}
    game.persistentDeck={};for _,c in ipairs(game.hand) do game.persistentDeck[#game.persistentDeck+1]=Deck.cloneCard(c) end
    game.playerHp=200;game.maxPlayerHp=200;game.gold=0;game.playerArmor=0;game.playerShield=0
    game.potionCombat={};game.potionFeedback={};game.selectedIndices={};game.abilityApproved={}
    for _,m in ipairs(game.enemies) do
        m.hp=100000;m.maxHp=100000;m.damageLagHp=100000;m.attack=40;m.armor=80;m.creatureArmor=120
        m.intent={type="attack",value=40,label="Tấn Công 40 ST"};m.attackSpeed=8
    end
    game.monster=game.enemies[1];PotionFx.active={};cb.setScoringSpeed(true)
end
local function supply(game,id)
    game.consumables={Shop.healingItem("upper",id).consumable}
end
local function effect(kind)
    for _,e in ipairs(PotionFx.active) do if e.kind==kind then return e end end
    error("Missing visible potion effect: "..kind)
end
local function shelfCount(cb)
    local n=0;for _,b in ipairs(cb.getButtons()) do if b.stockItem then n=n+1 end end;return n
end
function T.update(game,cb)
    if love.timer.getTime()<deadline or UI.Polish.busy() then return end
    if T.nextAction then
        local action=T.nextAction;T.nextAction=nil;action()
        deadline=love.timer.getTime()+.55;return
    end
    local delay=.55
    if step==0 then
        require("tests.potions_smoke")
        cb.startNewGame("red_deck");game.gold=10000;game.shopMode="medicine";cb.openShop()
    elseif step==1 then
        assert(shelfCount(cb)==7 and #cb.getShopData().items==15)
        local path=require("config.continental_asset_paths").cons_speed_large
        assert(path:find("_potion.png",1,true) and UI.getConsumableImage({id="cons_speed_large"}))
        shot("shop_recovery");T.nextAction=function() click(button(cb,"medicine_page_2")) end
    elseif step==2 then
        assert(cb.getShopData().page==2 and shelfCount(cb)==8)
        for _,def in ipairs(require("src.potions").definitions) do assert(UI.getConsumableImage(def)) end
        shot("shop_tactical")
        supply(game,"cons_accuracy");assert(not cb.activateStoredReward(1) and #game.consumables==1,"Combat potions cannot be consumed in the shop")
        game.consumables={}
        T.nextAction=function()
            for _,b in ipairs(cb.getButtons()) do if b.stockItem and b.stockItem.id=="cons_accuracy" then click(b);break end end
        end
    elseif step==3 then click(UI.Polish.button(game))
    elseif step==4 then
        assert(#cb.getShopData().items==14 and game.consumables[1].id=="cons_accuracy")
        if shelfCount(cb)==8 then deadline=love.timer.getTime()+.1;return end
        assert(shelfCount(cb)==7 and cb.getShopData().page==2)
        click(button(cb,"medicine_page_1"))
    elseif step==5 then
        assert(shelfCount(cb)==7 and cb.getShopData().page==1)
        battle(game,cb);supply(game,"cons_accuracy")
    elseif step==6 then assert(cb.activateStoredReward(1) and #game.consumables==0)
    elseif step==7 then
        effect("accuracy");assert(game.potionCombat.accuracy);shot("accuracy")
        supply(game,"cons_evasion");assert(cb.activateStoredReward(1))
    elseif step==8 then
        effect("evasion");shot("evasion")
        supply(game,"cons_damage");assert(cb.activateStoredReward(1))
    elseif step==9 then
        effect("damage");shot("damage")
        supply(game,"cons_empower");assert(cb.activateStoredReward(1))
    elseif step==10 then
        effect("empower");shot("empower")
        supply(game,"cons_gold_blood");assert(cb.activateStoredReward(1))
    elseif step==11 then
        effect("gold_blood");shot("gold_blood")
        supply(game,"cons_armor_break");assert(cb.activateStoredReward(1) and UI.AbilityUI.current)
    elseif step==12 then
        shot("armor_target");love.keypressed("escape")
        assert(not UI.AbilityUI.current and #game.consumables==1)
        assert(cb.activateStoredReward(1))
    elseif step==13 then
        T.target=game.enemies[2];T.hp=T.target.hp
        click(targetButton(2))
    elseif step==14 then
        effect("armor_break");assert(T.target.armor==0 and T.target.creatureArmor==0 and T.target.hp==T.hp-50)
        assert(game.enemies[1].armor==80 and game.enemies[1].creatureArmor==120)
        shot("armor_break")
        for _,m in ipairs(game.enemies) do m.attackSpeed=99 end
        cb.selectCardIndex(1);cb.selectCardIndex(2);cb.selectCardIndex(3);cb.playSelectedHand()
        T.started=love.timer.getTime()
    elseif step==15 then
        local anim,state=cb.getScoringState()
        assert(love.timer.getTime()-T.started<30,"Potion hand timeline timed out")
        if state~="playing" or anim.active or anim.enemyTurn then deadline=love.timer.getTime()+.1;return end
        assert(game.playerHp==200 and game.gold==0,"Evasion blocks every enemy, so blood gold must pay zero")
        assert(not game.potionCombat.evasion and not game.potionCombat.accuracy and not game.potionCombat.damageCards and not game.potionCombat.multCards)
        assert(game.potionCombat.gold_blood)
        battle(game,cb);supply(game,"cons_gold_blood");assert(cb.activateStoredReward(1))
        game.abilityApproved={};cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
    elseif step==16 then
        local anim,state=cb.getScoringState()
        assert(love.timer.getTime()-T.started<30)
        if anim.enemyTurn and anim.enemyTurn.result and not T.paid then
            local lost=200-game.playerHp
            if lost>0 then
                assert(game.gold==lost);T.paid=true;shot("gold_payout")
            end
        end
        if state~="playing" or anim.active or anim.enemyTurn then deadline=love.timer.getTime()+.05;return end
        assert(T.paid)
        battle(game,cb);game.enemies={game.monster};game.monster.group=game.enemies
        game.monster.hp=25;game.monster.maxHp=25;game.monster.damageLagHp=25
        game.monster.armor=100;game.monster.creatureArmor=0
        supply(game,"cons_armor_break");assert(cb.activateStoredReward(1));T.started=love.timer.getTime()
    elseif step==17 then click(targetButton(1))
    elseif step==18 then
        local _,state=cb.getRunState()
        assert(love.timer.getTime()-T.started<15,"Lethal potion did not finish the fight")
        if state~="CASH_OUT" then deadline=love.timer.getTime()+.1;return end
        assert(game.pendingVictoryReward and game.run.blinds[1].status=="completed")
        T.gold=game.gold;T.rewards=game.pendingVictoryReward;shot("lethal_reward")
    elseif step==19 then
        assert(game.gold==T.gold and game.pendingVictoryReward==T.rewards,"Potion victory cannot pay out twice")
        battle(game,cb);game.enemies={game.monster};game.monster.group=game.enemies
        game.monster.hp=1;game.monster.maxHp=1;game.monster.damageLagHp=1
        game.monster.armor=0;game.monster.creatureArmor=0;game.monster.attackSpeed=1
        cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
    elseif step==20 then
        local _,state=cb.getRunState()
        assert(love.timer.getTime()-T.started<20,"Normal hand victory regression")
        if state~="CASH_OUT" then deadline=love.timer.getTime()+.1;return end
        assert(game.pendingVictoryReward and game.run.blinds[1].status=="completed")
        battle(game,cb)
        game.deck={};for i=1,9 do game.deck[i]=Deck.newCard(i+2,"clubs") end
        supply(game,"cons_draw");assert(cb.activateStoredReward(1))
        assert(#game.hand==8 and #game.deck==4,"Drink draws 5 immediately above the current hand cap")
    elseif step==21 then
        effect("draw");shot("draw")
        T.nextAction=function() supply(game,"cons_slow");assert(cb.activateStoredReward(1) and UI.AbilityUI.current) end
    elseif step==22 then
        love.keypressed("escape");assert(#game.consumables==1 and not UI.AbilityUI.current)
        assert(cb.activateStoredReward(1))
    elseif step==23 then click(targetButton(2))
    elseif step==24 then
        effect("slow");assert(#game.consumables==0)
        local enemy=require("src.enemy_abilities")
        assert(enemy.speed(game.enemies[2])==4 and enemy.speed(game.enemies[1])==8)
        shot("slow")
        T.nextAction=function()
        local rng=require("src.rng");local before=rng.getState()
        local F=require("ui.potion_effects")
        F.active={};require("src.potions").emit(game,"heal","HỒI MÁU",25)
        F.update(game,.1,true,"playing");assert(#F.active[1].particles==12 and rng.getState()==before)
        F.draw(UI,game,"playing");assert(rng.getState()==before,"VFX must never change combat randomness")
        print("Potions UI PASS: 15 shop items, 8 tactical VFX, target/cancel, immediate draw 5, targeted slow, reduced motion/RNG isolation, evasion, gold blood and both victory paths")
        love.event.quit(0)
        end
    end
    step=step+1;deadline=love.timer.getTime()+delay
end
return T

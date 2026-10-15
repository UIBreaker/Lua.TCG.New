local T={step=0,deadline=0}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/spn_elements_"..name..".png","wb"));file:write(data:encode("png"):getString());file:close()
    end)
end
local function setup(g,cb,ids)
    cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
    local Deck=require("src.deck");local D=require("src.deities")
    g.deities={};for slot,id in ipairs(ids) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    g.persistentDeck={};g.hand={};g.deck={};g.discardPile={};g.selectedIndices={};g.abilityApproved={}
    for i=1,7 do local c=Deck.newCard(3,"spades");c.disableFactionPassives=true;g.persistentDeck[i]=c
        if i==1 then g.hand[1]=Deck.cloneCard(c) else g.deck[#g.deck+1]=Deck.cloneCard(c) end
    end
    g.masterDeck=g.persistentDeck;g.playerHp=100;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0
    for _,m in ipairs(g.enemies) do m.hp=10000;m.maxHp=10000;m.damageLagHp=10000;m.attack=1;m.attackSpeed=999;m.armor=0;m.creatureArmor=0;m.enemyInventory=nil end
    cb.setScoringSpeed(true)
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    local E=require("src.spn_elements");local Combat=require("src.combat")
    if T.step==0 then
        setup(g,cb,{"spirit_phantom_heart","spirit_first_frost","spirit_cinder_confluence"})
    elseif T.step==1 then cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
    elseif T.step==2 then
        local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<25)
        if state~="playing" or anim.active or anim.enemyTurn then return end
        for _,m in ipairs(g.enemies) do assert(m.hp==10000 and not m.spnAuraBurns,"first freeze cannot deal splash or burn damage") end
        assert(E.remaining(g)<1000 and g.playerHp==100,"phantom absorbs the other enemies")
        shot("phantom_frost")
    elseif T.step==3 then
        g.potionCombat={accuracy=true,accuracyTurns=1}
        cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
    elseif T.step==4 then
        local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<25)
        if state~="playing" or anim.active or anim.enemyTurn then return end
        for _,m in ipairs(g.enemies) do assert(m.hp<10000 and math.abs(m.hp-g.enemies[1].hp)<1e-7 and #m.spnAuraBurns==1) end
        shot("shared_cinders")
    elseif T.step==5 then
        setup(g,cb,{"spirit_cinder_confluence"})
        g.monster.hp=105;g.monster.maxHp=105;g.monster.damageLagHp=105
        for i=2,#g.enemies do g.enemies[i].hp=0 end
        Combat.resolvePlayerAttack(g,100,{hitChance=1,missed=false});assert(g.monster.hp==5)
        Combat.onMonsterTurnEnd(g);assert(g.monster.hp==0);T.started=love.timer.getTime()
    elseif T.step==6 then
        local _,state=cb.getRunState();assert(love.timer.getTime()-T.started<15)
        if state~="CASH_OUT" then return end
        assert(g.pendingVictoryReward and g.run.blinds[1].status=="completed")
        T.gold=g.gold;T.receipt=g.pendingVictoryReward
    elseif T.step==7 then
        assert(g.gold==T.gold and g.pendingVictoryReward==T.receipt)
        shot("burn_victory")
    elseif T.step==8 then
        assert(g.gold==T.gold and g.pendingVictoryReward==T.receipt)
        print("SPN elements UI PASS: first real hand freezes/no damage, phantom HUD/absorption, second real hand splits AURA/burns all enemies, burn victory receipt once")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.6
end
return T

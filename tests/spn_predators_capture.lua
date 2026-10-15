local T={step=0,deadline=0}
local function setup(g,cb,ids)
    cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
    local Deck=require("src.deck");local D=require("src.deities")
    g.deities={};for slot,id in ipairs(ids) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    g.persistentDeck={};g.hand={};g.deck={};g.discardPile={};g.selectedIndices={};g.abilityApproved={}
    for i=1,7 do local c=Deck.newCard(3,"spades");c.disableFactionPassives=true;g.persistentDeck[i]=c
        if i==1 then g.hand[1]=Deck.cloneCard(c) else g.deck[#g.deck+1]=Deck.cloneCard(c) end
    end
    g.masterDeck=g.persistentDeck;g.playerHp=100;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0
    for _,m in ipairs(g.enemies) do m.hp=10000;m.maxHp=10000;m.damageLagHp=10000;m.attack=1;m.attackSpeed=12;m.armor=0;m.creatureArmor=0;m.enemyInventory=nil end
    T.card=g.hand[1];T.base=require("src.deck").peekCardAttackSpeed(T.card)
    cb.setScoringSpeed(true)
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    if T.step==0 then setup(g,cb,{"spirit_right_offering","spirit_wind_thief","spirit_left_refrain"})
    elseif T.step==1 then
        cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
        assert(g.monster.spnStolenSpeed==2 and g.lastPlayerAttackSpeed==T.base+2)
        assert(not g.monsterAttackedBeforePlayer,"stolen speed decides initiative before combat")
    elseif T.step==2 then
        local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<25)
        if state~="playing" or anim.active or anim.enemyTurn then return end
        assert(not g.deities[2] and g.deities[1].spnGrowth.offeringMult==.5)
        assert(T.card.speedBonus==2 and T.card.temporarySpeedBonus==0 and g.persistentDeck[1].speedBonus==2)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/spn_predators_battle.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
    elseif T.step==3 then
        setup(g,cb,{"spirit_primeval_product","spirit_left_refrain"})
    elseif T.step==4 then cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
    elseif T.step==5 then
        local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<25)
        if state~="playing" or anim.active or anim.enemyTurn then return end
        assert(g.deities[1].spnGrowth.layers==3,"real hand replays stateful source three times")
    elseif T.step==6 then
        print("SPN predators UI PASS: real initiative speed theft, adjacent sacrifice, immediate permanent conversion, leftmost stateful source replays three times")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.5
end
return T

local T={step=0,deadline=0}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/spn_reserves_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function setup(g,cb,ids,n)
    cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
    local Deck=require("src.deck");local D=require("src.deities")
    g.deities={};for slot,id in ipairs(ids) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    g.persistentDeck={};g.hand={};g.deck={};g.discardPile={};g.selectedIndices={};g.abilityApproved={}
    for i=1,15 do local c=Deck.newCard(3,"spades");c.disableFactionPassives=true;g.persistentDeck[i]=c
        if i<=n then g.hand[i]=Deck.cloneCard(c) else g.deck[#g.deck+1]=Deck.cloneCard(c) end
    end
    g.masterDeck=g.persistentDeck;g.playerHp=100;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0
    g.gold=2;g.discardsRemaining=3;g.potionCombat={accuracy=true,accuracyTurns=10}
    for _,m in ipairs(g.enemies) do m.hp=100000;m.maxHp=100000;m.damageLagHp=100000;m.attack=1;m.attackSpeed=1;m.armor=0;m.creatureArmor=0;m.enemyInventory=nil end
    cb.setScoringSpeed(true)
end
local function play(g,cb)
    local h=assert(require("src.poker").evaluate({g.hand[1]}))
    T.expected=require("src.scoring").calculate(h,g.deities,{gameState=g,monster=g.monster,preview=true}).finalScore
    cb.selectCardIndex(1);cb.playSelectedHand();T.started=love.timer.getTime()
end
local function settled(cb)
    local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<25)
    if state~="playing" or anim.active or anim.enemyTurn then return end
    assert(anim.scoringData.finalScore==T.expected,"real play matches isolated preview")
    return anim.scoringData
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    if T.step==0 then setup(g,cb,{"spirit_open_horizon","spirit_lone_procession","spirit_unspent_fury","spirit_gilded_weight"},4)
    elseif T.step==1 then
        play(g,cb);assert(g.abilityHand.spnHeldBeforePlay==4)
    elseif T.step==2 then
        local result=settled(cb);if not result then return end
        local cards,fury,factor=0
        for _,s in ipairs(result.steps) do
            if s.type=="card_scored" then cards=cards+1 end
            if s.type=="deity_hand" and s.slotIndex==3 then fury=s.addedChips end
            if s.type=="deity_hand" and s.slotIndex==4 then factor=s.xChips end
        end
        assert(cards==5 and fury==150 and factor==.5 and #g.hand==4)
        shot("held_echo_gold")
    elseif T.step==3 then
        g.gold=0;play(g,cb)
    elseif T.step==4 then
        local result=settled(cb);if not result then return end
        assert(result.totalChips==0 and result.finalScore==0,"zero gold keeps the exact zero factor through presentation")
    elseif T.step==5 then setup(g,cb,{"spirit_right_offering","spirit_pebble","spirit_ashen_legacy"},1)
    elseif T.step==6 then play(g,cb)
    elseif T.step==7 then
        local result=settled(cb);if not result then return end
        assert(not g.deities[2] and g.deities[3].spnGrowth.deathChips==.5)
        local factor;for _,s in ipairs(result.steps) do if s.type=="deity_hand" and s.slotIndex==3 then factor=s.xChips end end
        assert(factor==1.5,"sacrificial growth applies at its later slot in the same hand")
        shot("sacrifice_growth")
    elseif T.step==8 then
        print("SPN reserves UI PASS: real single-card five activations from four held, 4-slot draw/refill, +150 unused-discard damage, exact gold x0.5 and x0 animation, adjacent offering grows later damage source in same hand")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.5
end
return T

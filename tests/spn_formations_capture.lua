local T={step=0,deadline=0}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/spn_formations_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function setup(g,cb,ids,ranks,same)
    cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
    local Deck=require("src.deck");local D=require("src.deities")
    g.deities={};for slot,id in ipairs(ids) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    g.persistentDeck={};g.hand={};g.deck={};g.discardPile={};g.selectedIndices={};g.abilityApproved={};g.maxHandSize=5
    g.unlockedHands={high_card=true,straight=true,flush=true,full_house=true,four_of_a_kind=true};g.gold=10;g.playerHp=97;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0
    for i,rank in ipairs(ranks) do
        local c=Deck.newCard(rank,same and "spades" or ({"hearts","spades","clubs","diamonds","hearts"})[i]);c.disableFactionPassives=true
        g.persistentDeck[i]=c;g.hand[i]=Deck.cloneCard(c)
    end
    for i=1,10 do local c=Deck.newCard(3,"spades");c.disableFactionPassives=true;g.persistentDeck[#g.persistentDeck+1]=c;g.deck[#g.deck+1]=Deck.cloneCard(c) end
    g.masterDeck=g.persistentDeck;g.potionCombat={accuracy=true,accuracyTurns=10}
    for _,m in ipairs(g.enemies) do m.hp=100000;m.maxHp=100000;m.damageLagHp=100000;m.attack=0;m.attackSpeed=1;m.armor=0;m.creatureArmor=0;m.enemyInventory=nil end
    T.played={};for _,c in ipairs(g.hand) do T.played[#T.played+1]=c end;cb.setScoringSpeed(true)
end
local function play(g,cb)
    local h=assert(require("src.poker").evaluate(T.played,g.unlockedHands,g.handLevels))
    T.expected=require("src.scoring").calculate(h,g.deities,{gameState=g,monster=g.monster,preview=true}).finalScore
    for i=1,#T.played do cb.selectCardIndex(i) end;cb.playSelectedHand();T.started=love.timer.getTime()
end
local function settled(cb)
    local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<35)
    if state~="playing" or anim.active or anim.enemyTurn then return end
    assert(anim.scoringData.finalScore==T.expected,"real scoring matches isolated preview")
    assert(anim.displayChips==anim.scoringData.totalChips and anim.displayMult==anim.scoringData.totalMult)
    return anim.scoringData
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    if T.step==0 then setup(g,cb,{"spirit_march_covenant","spirit_vanguard_reprise","spirit_breath_of_mercy"},{2,3,4,5,6})
    elseif T.step==1 then play(g,cb)
    elseif T.step==2 then
        local result=settled(cb);if not result then return end
        local count,march=0,0
        for _,s in ipairs(result.steps) do if s.type=="card_scored" then count=count+1 end
            if s.type=="deity_hand" and s.slotIndex==1 then assert(s.addedChips==50 and s.healHp==5);march=march+1 end end
        assert(count==10 and march==1 and result.healHp==10 and g.playerHp==100,"percent healing caps at actual max HP")
        shot("march_reprise")
    elseif T.step==3 then setup(g,cb,{"spirit_fourfold_edge","spirit_quartet_oath"},{7,7,7,7},true)
    elseif T.step==4 then play(g,cb)
    elseif T.step==5 then
        local result=settled(cb);if not result then return end
        local count=0
        for _,s in ipairs(result.steps) do
            if s.type=="card_scored" then assert(s.addedChips==14);count=count+1 end
            if s.type=="deity_hand" and s.slotIndex==2 then assert(s.xChips==4 and s.xMult==1) end
        end
        assert(count==4);for i=1,4 do assert(g.persistentDeck[i].baseChips==7) end
        shot("same_suit_quartet")
    elseif T.step==6 then setup(g,cb,{"spirit_fourfold_edge","spirit_quartet_oath"},{7,7,7,7},false)
    elseif T.step==7 then play(g,cb)
    elseif T.step==8 then
        local result=settled(cb);if not result then return end
        for _,s in ipairs(result.steps) do if s.type=="deity_hand" and s.slotIndex==2 then assert(s.xMult==4 and s.xChips==1) end end
    elseif T.step==9 then
        print("SPN formations UI PASS: real five-card march / two full card activations / once-per-hand healing to HP cap; four local card multipliers; exclusive same-suit Chips and mixed-suit Mult; accurate Normal/Fast presentation")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.5
end
return T

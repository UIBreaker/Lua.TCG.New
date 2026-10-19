local T={step=0,deadline=0,cases={
    {{2,2},{"spirit_numeral_weaver"},22},
    {{9,9,9,9},{"spirit_numeral_weaver"},9999},
    {{2,3,4,5,6},{"spirit_numeral_weaver","spirit_aura_bifurcation"},46912},
}}
local function setup(g,cb,case)
    cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
    local Deck=require("src.deck");local D=require("src.deities")
    g.deities={};for slot,id in ipairs(case[2]) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    g.persistentDeck={};g.hand={};g.deck={};g.discardPile={};g.selectedIndices={};g.abilityApproved={};g.maxHandSize=5
    g.unlockedHands={high_card=true,straight=true,flush=true,full_house=true,four_of_a_kind=true};g.gold=100;g.playerHp=100;g.maxPlayerHp=100;g.playerArmor=0;g.playerShield=0
    for i,rank in ipairs(case[1]) do
        local c=Deck.newCard(rank,({"spades","hearts","clubs","diamonds","spades"})[i]);c.disableFactionPassives=true
        g.persistentDeck[i]=c;g.hand[i]=Deck.cloneCard(c)
    end
    for i=1,10 do local c=Deck.newCard(3,"spades");c.disableFactionPassives=true;g.persistentDeck[#g.persistentDeck+1]=c;g.deck[#g.deck+1]=Deck.cloneCard(c) end
    g.masterDeck=g.persistentDeck;g.potionCombat={accuracy=true,accuracyTurns=10}
    for _,m in ipairs(g.enemies) do m.hp=100000000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.attack=0;m.attackSpeed=1;m.armor=0;m.creatureArmor=0;m.enemyInventory=nil end
    local h=assert(require("src.poker").evaluate(g.hand,g.unlockedHands,g.handLevels))
    assert(require("src.scoring").calculate(h,g.deities,{gameState=g,monster=g.monster,preview=true}).finalScore==case[3])
    T.case=case;T.target=g.monster;cb.setScoringSpeed(true)
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    local index=math.floor(T.step/3)+1;local phase=T.step%3
    if not T.cases[index] then print("SPN Aura UI PASS: real pair 22, four nines 9999, ordered straight 23456 ×2 Aura =46912; preview/live agree, score axes bypassed, one real enemy hit");love.event.quit(0);return end
    if phase==0 then setup(g,cb,T.cases[index])
    elseif phase==1 then
        for i=1,#T.case[1] do cb.selectCardIndex(i) end
        cb.playSelectedHand();T.started=love.timer.getTime()
    else
        local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<35,"scoring timeout")
        local event=anim.sequence and anim.sequence.events[anim.sequence.index]
        if index==3 and event and event.kind=="FORMULA" and anim.sequence.entered and not T.formulaShot then
            T.formulaShot=true
            love.graphics.captureScreenshot(function(data)
                local f=assert(io.open("docs/spn_aura_formula.png","wb"));f:write(data:encode("png"):getString());f:close()
            end)
        end
        if state~="playing" or anim.active or anim.enemyTurn then return end
        assert(anim.scoringData.finalScore==T.case[3] and anim.displayAura==T.case[3])
        assert(anim.displayChips==0 and anim.displayMult==0,"written Aura does not display normal score axes")
        assert(T.target.hp==100000000-T.case[3],"exactly one authoritative hit")
        if index==3 then love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/spn_aura_battle.png","wb"));f:write(data:encode("png"):getString());f:close()
        end) end
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.5
end
return T

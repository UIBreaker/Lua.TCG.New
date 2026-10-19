local T={step=0,deadline=0}
local function trial(g) return assert(g.spnCombat[g.deities[1]].trial) end
local function play(g,cb,id)
    local Deck=require("src.deck");local ranks=({high_card={7},pair={2,2},straight={2,3,4}})[id]
    assert(ranks);g.hand={};g.selectedIndices={};g.abilityApproved={};g.maxHandSize=5
    for i,rank in ipairs(ranks) do
        local c=Deck.newCard(rank,({"spades","hearts","clubs"})[i]);c.disableFactionPassives=true
        g.hand[i]=c;g.persistentDeck[#g.persistentDeck+1]=c
    end
    for i=1,#ranks do cb.selectCardIndex(i) end
    cb.playSelectedHand();T.started=love.timer.getTime()
end
local function settled(cb)
    local anim,state=cb.getScoringState();assert(love.timer.getTime()-T.started<35)
    return state=="playing" and not anim.active and not anim.enemyTurn
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    if T.step==0 then
        cb.startNewGame("red_deck")
        g.deities={};assert(require("src.deities").addDeity(g,require("src.deities").CATALOG.spirit_trial_emissary,1))
        g.unlockedHands={high_card=true,pair=true,straight=true}
        cb.startMonsterEncounter(3,false);assert(trial(g).ids[1]~=trial(g).ids[2],"assigned at actual combat start")
        for _,m in ipairs(g.enemies) do m.hp=1000000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.attack=0;m.attackSpeed=1;m.armor=0;m.creatureArmor=0;m.enemyInventory=nil end
        g.potionCombat={accuracy=true,accuracyTurns=10};cb.setScoringSpeed(true)
        local _,description=require("src.card_description").resolve(g.deities[1],g)
        assert(description:find(trial(g).names[1],1,true) and description:find(trial(g).names[2],1,true),"live tooltip lists both requirements")
    elseif T.step==1 then play(g,cb,trial(g).ids[2])
    elseif T.step==2 then
        if not settled(cb) then return end
        assert(not trial(g).done and trial(g).seen[trial(g).ids[2]] and (g.deities[1].evolutionLevel or 0)==0)
    elseif T.step==3 then play(g,cb,trial(g).ids[1])
    elseif T.step==4 then
        if not settled(cb) then return end
        assert(trial(g).done and g.deities[1].evolutionLevel==1,"real second requested hand evolves the equipped self once")
        local _,description=require("src.card_description").resolve(g.deities[1],g)
        assert(description:find("ĐÃ THƯỞNG",1,true))
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/spn_trials_battle.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
    elseif T.step==5 then
        require("src.card_abilities").finishHand(g);assert(g.deities[1].evolutionLevel==1)
        print("SPN trials UI PASS: real combat start assigns two distinct unlocked hands; two requested hands in reverse order; live tooltip progress; exactly one self evolution and no repeated claim")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.5
end
return T

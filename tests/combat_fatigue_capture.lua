local T={stage=0}
local D=require("src.deck")
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/combat_reshuffle_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime();local anim,state=cb.getScoringState()
    if T.stage==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setGameSpeed(1)
        game.deities={};game.persistentDeck={};game.hand={};game.deck={};game.discardPile={};game.selectedIndices={}
        T.base={}
        for i=1,6 do
            local c=D.newCard(i+3,"clubs");c.baseMult=3;c.trainingEmpowerment=2;c.speedBonus=4
            c.disableFactionPassives=true;game.persistentDeck[i]=c
            T.base[c.id]={damage=D.getCardDamage(c),speed=D.peekCardAttackSpeed(c),empowerment=D.getCardEmpowerment(c)}
            local copy=D.cloneCard(c)
            if i<=3 then game.hand[i]=copy;anim.prepareDrawAnimation(copy,i)
            else game.deck[#game.deck+1]=copy end
        end
        game.playerHp=1000;game.maxPlayerHp=1000
        game.maxHands=1;game.turnHandLimit=1;game.handsRemaining=1;game.discardsRemaining=0
        local m=game.monster;m.hp=1000000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.attack=1;m.attackSpeed=1
        m.enemyInventory=nil;m.enemyAbility=nil;m.intent={type="attack"}
        T.stage=1;T.start=now;return
    end
    assert(now-T.start<35,"fatigue runtime stalled")
    local timing=anim.attackTiming or anim.enemyTurn and anim.enemyTurn.timing
    if timing and not timing.result and timing.age>=timing.ready+.02 then
        timing.position=0;love.keypressed("space",nil,false)
    end
    if T.stage==1 and not require("src.hand_motion").busy(game.hand) then
        cb.selectCardIndex(1);cb.playSelectedHand();T.stage=2
    elseif T.stage==2 or T.stage==4 then
        local expected=T.stage==2 and 1 or 2
        if (game.combatReshuffles or 0)<expected then return end
        assert(game.combatReshuffles==expected and game.handsRemaining==1)
        assert(game.discardsRemaining==game.spnDiscardCap and #game.hand==3 and #game.deck==3 and #game.discardPile==0)
        if require("src.hand_motion").busy(game.hand) or anim.enemyTurn or anim.active then return end
        assert(#game.selectedIndices==0,"old selections cannot auto-play after the shuffle")
        local ids={}
        for _,pile in ipairs({game.hand,game.deck}) do for _,c in ipairs(pile) do
            assert(not ids[c.id] and c.combatFatigue==expected);ids[c.id]=true
            assert(D.getCardDamage(c)==math.max(0,T.base[c.id].damage-expected))
            assert(D.peekCardAttackSpeed(c)==math.max(0,T.base[c.id].speed-expected))
            assert(D.getCardEmpowerment(c)==math.max(0,T.base[c.id].empowerment-expected))
        end end
        T.ready=now+.10;T.stage=T.stage+1
    elseif (T.stage==3 or T.stage==5) and now>=T.ready then
        shot(T.stage==3 and "fatigue_1" or "fatigue_2")
        if T.stage==3 then
            T.stage=6;T.ready=now+.15
        else T.stage=7;T.ready=now+.15 end
    elseif T.stage==6 and now>=T.ready then
            game.handsRemaining=0;game.discardsRemaining=0
            assert(cb.endPlayerTurn());T.stage=4
    elseif T.stage==7 and now>=T.ready then
            cb.startMonsterEncounter(2,false)
            assert(game.combatReshuffles==0)
            for _,c in ipairs(game.hand) do assert((c.combatFatigue or 0)==0) end
            for _,c in ipairs(game.persistentDeck) do assert(not c.combatFatigue and c.trainingEmpowerment==2 and c.speedBonus==4) end
            T.done=true
            print("Fatigue runtime PASS: automatic last-hand rollover, full discards, complete pile shuffle, cumulative weakening, selection reset, animated redeal and normal stats next battle")
            love.event.quit(0)
    end
end
return T

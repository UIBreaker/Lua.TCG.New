local T={}
function T.update(game,cb)
    if T.done then return end
    if not T.started then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setGameSpeed(1)
        local D=require("src.deck")
        game.hand={D.newCard(7,"hearts"),D.newCard(7,"clubs")};game.deck={};game.discardPile={};game.deities={}
        game.persistentDeck={D.cloneCard(game.hand[1]),D.cloneCard(game.hand[2])}
        local m=game.monster;m.isBoss=true;m.attackSpeed=1;m.bossData={debuffId="faceless"};m.enemyInventory=nil
        require("src.boss_abilities").start(game)
        game.hand[2].abilityDisabledUntil=1
        local anim=cb.getScoringState();for i,c in ipairs(game.hand) do anim.prepareDrawAnimation(c,i) end
        T.blocked=game.hand[2];T.started=love.timer.getTime();return
    end
    if love.timer.getTime()-T.started<1 then return end
    assert(love.timer.getTime()-T.started<20,"disabled-card play stalled")
    local _,state=cb.getScoringState()
    if require("render.renderer").transitionBusy(state,game) or require("src.hand_motion").busy(game.hand) then return end
    if T.played then
        local anim=cb.getScoringState()
        if anim.attackTiming and not anim.attackTiming.result then
            local rail=anim.attackTiming;rail.age=rail.ready
            rail.position=(rail.zones[1].from+rail.zones[1].to)/2
            require("src.combat_timing").press(rail)
        end
        if not anim.evalResult then return end
        assert(anim.evalResult.type.id=="high_card" and #anim.playedCards==1,"disabled half of pair must not join the play")
        print("Disabled runtime PASS: blocked-only play rejected; mixed pair becomes one-card attack; blocked card remains in hand")
        T.done=true;love.event.quit(0);return
    end
    local hands=game.handsRemaining
    game.selectedIndices={2};cb.playSelectedHand()
    assert(game.handsRemaining==hands and #game.hand==2,"all disabled selection cannot spend or play a hand")
    game.selectedIndices={1,2};cb.playSelectedHand()
    assert(#game.hand==1 and game.hand[1]==T.blocked and #game.discardPile==1)
    assert(game.handsRemaining==hands-1)
    T.played=true
end
return T

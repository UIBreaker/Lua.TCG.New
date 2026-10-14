-- Actual combat callbacks: lethal contact and replacing a scene mid-flight.
local T={case=0}
local RNG=require("src.rng")
local Deck=require("src.deck")
local function finish()
    RNG.random=T.random
    require("render.nen_magic").draw=T.draw
    local report="Native real combat edge cases PASS: lethal one-shot damages once and settles; existing Debug.clearScene during TRAVEL cancels the old sequence, cannot damage the new target, and accepts a new attack.\n"
    local f=assert(io.open("docs/nen_magic/edges.txt","wb"));f:write(report);f:close();print(report)
    love.event.quit(0)
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if not T.started then
        T.case=T.case+1;if T.case>2 then finish();return end
        if not T.draw then
            local renderer=require("render.nen_magic");T.draw=renderer.draw;T.staleDraws=0
            renderer.draw=function(a,...)
                if T.switched and T.sequence and a==T.sequence.attack then T.staleDraws=T.staleDraws+1 end
                return T.draw(a,...)
            end
        end
        T.random=T.random or RNG.random
        RNG.random=function(a,b) if a then return T.random(a,b) end;return 0 end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setScoringSpeed(false)
        local card=Deck.newCard(14,"spades");card.disableFactionPassives=true;card.speedBonus=50
        card.baseChips=T.case==1 and 500000 or 10
        game.hand={card};game.deck={};game.discardPile={};game.selectedIndices={};game.deities={};game.abilityApproved={}
        game.monster.attackSpeed=1;game.monster.creatureArmor=0
        T.target=game.monster;T.before=T.target.hp;T.lastHp=T.before;T.hits=0
        cb.selectCardIndex(1);cb.playSelectedHand()
        local anim,state=cb.getScoringState();assert(state=="scoring")
        T.sequence=anim.sequence;T.started=now;T.switched=false
        return
    end
    assert(now-T.started<20,"native edge timeout: "..T.case)
    local anim,state=cb.getScoringState()
    if T.case==1 then
        if T.target.hp~=T.lastHp then T.hits=T.hits+1;T.lastHp=T.target.hp end
        if T.sequence.damageApplied then
            assert(T.target.hp==0 and anim.damageDealt>=T.before and T.hits==1,"one-shot must dispatch once")
            if not anim.active then assert(T.sequence.finished);T.started=nil end
        end
    elseif not T.switched then
        local event=T.sequence.events[T.sequence.index]
        if event and event.kind=="TRAVEL" and T.sequence.age>.015 then
            assert(T.sequence.attack.nen.magic,"real attack was drawn before replacing scene")
            require("src.ui").Debug.clearScene()
            assert(T.sequence.attack.nen.cancelled,"scene clear did not cancel attack")
            cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
            local nextAnim,nextState=cb.getScoringState()
            assert(nextState=="playing" and not nextAnim.active,"scene replacement did not stop combat")
            T.switched=true;T.restartedAt=now;T.newHp=game.monster.hp
        end
    elseif now-T.restartedAt>.5 then
        assert(state=="playing" and not anim.active and game.monster.hp==T.newHp,"stale projectile damaged new target")
        assert(T.staleDraws==0,"stale attack drawn after scene replacement")
        local card=Deck.newCard(8,"spades");card.disableFactionPassives=true;card.speedBonus=50
        game.hand={card};game.selectedIndices={};game.abilityApproved={};game.deities={}
        cb.selectCardIndex(1);cb.playSelectedHand()
        local nextAnim,nextState=cb.getScoringState()
        assert(nextState=="scoring" and nextAnim.sequence~=T.sequence,"new encounter cannot accept another attack")
        T.started=nil
    end
end
return T

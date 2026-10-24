local T={stage=0}
local Timing=require("src.combat_timing")
function T.update(game,cb)
    if T.done then return end
    local anim,state=cb.getScoringState();local now=love.timer.getTime()
    if T.stage==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setGameSpeed(1)
        game.deities={};game.consumables={};game.selectedIndices={};game.hand={}
        game.persistentDeck={};game.deck={};game.discardPile={}
        for i=1,3 do
            local c=require("src.deck").newCard(i+1,"diamonds")
            c.speedBonus=50;c.disableFactionPassives=true
            game.hand[i]=c;game.persistentDeck[i]=require("src.deck").cloneCard(c);anim.prepareDrawAnimation(c,i)
        end
        game.playerHp=1000;game.maxPlayerHp=1000;game.playerArmor=0;game.playerShield=0
        game.timingChains={perfect=20}
        local m=game.monster
        m.hp=100000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.attack=20;m.attackSpeed=10
        m.enemyInventory=nil;m.enemyAbility=nil;m.intent={type="attack"}
        T.start=now;T.stage=1;return
    end
    assert(now-T.start<30,"hazard combat stalled")
    if T.stage==1 then
        if now-T.start<1 then return end
        if require("render.renderer").transitionBusy(state,game) or require("src.hand_motion").busy(game.hand) then return end
        cb.selectCardIndex(1);cb.playSelectedHand();T.stage=2;return
    end
    local rail=anim.attackTiming or anim.enemyTurn and anim.enemyTurn.timing
    if rail and not rail.result and rail.age>=rail.ready+.02 then
        rail.position=(rail.hazard.from+rail.hazard.to)/2
        love.keypressed("space",nil,false)
        assert(rail.result.grade==(rail.kind=="attack" and "riposte" or "exposed"))
        T[rail.kind]=true
    end
    for _,e in ipairs(require("src.timing_vfx").active) do if e.kind=="enemy_reflect" then T.counter=true end end
    if anim.enemyTurn and anim.enemyTurn.result and anim.enemyTurn.parryResult and anim.enemyTurn.parryResult.grade=="exposed" then
        assert(anim.enemyTurn.result.damage==100,"runtime parry must deal five times 20 damage")
        T.parryDamage=true
    end
    if T.attack and T.parry and state=="playing" and not anim.active and not anim.enemyTurn then
        assert(game.monster.hp==100000 and game.playerHp<900,"counter and x5 hazard must both affect the player")
        assert(T.counter and T.parryDamage and not next(game.timingChains))
        print("Timing hazard runtime PASS: real attack counter, x5 parry, preserved enemy HP, chain reset and next-hand recovery")
        T.done=true;love.event.quit(0)
    end
end
return T

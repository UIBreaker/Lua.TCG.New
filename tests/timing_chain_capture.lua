local T={stage=0,round=1}
local D=require("src.deck")
local grades={"critical","ultimate","divine","critical","normal"}
local function monster(game)
    local m=game.monster;m.hp=1000000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.attack=16;m.attackSpeed=50
    m.enemyInventory=nil;m.enemyAbility=nil;m.intent={type="attack"}
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime();local anim,state=cb.getScoringState()
    if T.stage==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setGameSpeed(1)
        game.deities={{id="spirit_life_bloom",rarity="common",evolutionLevel=0}}
        game.backpackDeities={{id="spirit_fleet_wind",rarity="common",evolutionLevel=0}}
        game.persistentDeck={};game.hand={};game.deck={};game.discardPile={};game.selectedIndices={}
        for i=1,8 do
            local c=D.newCard(i+1,"clubs");c.disableFactionPassives=true;c.speedBonus=10-D.getAttackSpeed(c.rank)
            game.persistentDeck[i]=c;local copy=D.cloneCard(c)
            if i<=3 then game.hand[i]=copy;anim.prepareDrawAnimation(copy,i) else game.deck[#game.deck+1]=copy end
        end
        game.maxHands=10;game.turnHandLimit=10;game.handsRemaining=10
        game.playerHp=1000;game.maxPlayerHp=1000;game.playerArmor=0;game.playerShield=0
        T.wallet=game.gold;T.souls=game.souls;monster(game)
        T.start=now;T.stage=1;return
    end
    assert(now-T.start<55,"chain runtime stalled at round "..T.round)
    local timing=anim.attackTiming or anim.enemyTurn and anim.enemyTurn.timing
    if timing and not timing.result and timing.age>=timing.ready+.02 then
        local grade=grades[T.round]
        local z=grade=="divine" and timing.divine
        for _,band in ipairs(timing.zones) do if band.grade==grade then z=band;break end end
        timing.position=z and (z.from+z.to)/2 or 0
        love.keypressed("space",nil,false)
        assert(timing.result.grade==grade)
        if grade=="critical" and T.round==4 and timing.kind=="parry" then
            assert(timing.result.chain==3,"new battle resumes the saved critical chain")
            love.graphics.captureScreenshot(function(data)
                local f=assert(io.open("docs/timing_chain_parry_3.png","wb"));f:write(data:encode("png"):getString());f:close()
            end)
        end
    end
    if T.stage==1 then
        if anim.active or anim.enemyTurn or require("src.hand_motion").busy(game.hand) then return end
        monster(game)
        if T.round==3 then T.held={game.hand[2],game.hand[3]} end
        cb.selectCardIndex(1);cb.playSelectedHand();T.stage=2
    elseif T.stage==2 and not anim.active and not anim.enemyTurn and state=="playing" and not require("src.hand_motion").busy(game.hand) then
        if T.round==1 then assert(game.timingChains.critical==2 and game.playerArmor==4)
        elseif T.round==2 then
            assert(game.timingChains.critical==2 and game.timingChains.ultimate==2)
            assert(game.souls==T.souls+15 and game.gold==T.wallet+15)
        elseif T.round==3 then
            assert(game.timingChains.divine==2 and game.timingRewardMultiplier==4)
            assert(game.souls==T.souls+30 and game.gold==T.wallet+30)
            assert(game.deities[1].evolutionLevel==3 and game.backpackDeities[1].evolutionLevel==3)
            for _,c in ipairs(T.held) do assert(c.evolutionLevel==3) end
            cb.startMonsterEncounter(1,false);monster(game)
            assert(game.timingChains.critical==2 and game.timingChains.divine==2 and game.timingRewardMultiplier==1)
        elseif T.round==4 then assert(game.timingChains.critical==4 and game.playerArmor==12)
        else
            assert(next(game.timingChains)==nil)
            T.done=true
            print("Timing chains runtime PASS: real shared attack/parry chains, 4-to-12 armor, fixed scaled wallets, all owned SPNs/held-card evolution, next-battle carry and normal reset")
            love.event.quit(0);return
        end
        T.round=T.round+1;T.stage=1
    end
end
return T

local T={stage=0,case=1,shots={},pressed={}}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/combat_timing_"..name..".png","wb"))
        file:write(data:encode("png"):getString());file:close()
    end)
end
function T.update(game,cb)
    if T.stage==3 then return end
    local anim,state=cb.getScoringState()
    if T.stage==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        local D=require("src.deck")
        game.hand={D.newCard(8,"spades")};game.selectedIndices={};game.deities={}
        game.playerHp=1000;game.maxPlayerHp=1000;game.playerArmor=0;game.playerShield=0
        local m=game.monster
        assert(m.attack>=8 and m.attackSpeed>=8 and m.maxHp>=80,"actual encounter uses stronger stats")
        m.hp=T.case==6 and 100 or 100000;T.victim=m;m.maxHp=m.hp;m.damageLagHp=m.hp;m.attack=20;m.attackSpeed=T.case==1 and 5 or 50
        m.enemyInventory=nil;m.enemyAbility=nil;m.intent={type="attack"}
        game.hand[1].speedBonus=5-D.peekCardAttackSpeed(game.hand[1])
        cb.setGameSpeed(4)
        T.stage=1;T.start=love.timer.getTime();return
    end
    assert(love.timer.getTime()-T.start<35,"timing runtime stalled")
    if T.stage==1 then
        if love.timer.getTime()-T.start<1 then return end
        cb.selectCardIndex(1);cb.playSelectedHand()
        if anim.attackTiming or anim.enemyTurn or state=="scoring" then T.stage=2 end
        return
    end
    local s=anim.attackTiming or anim.enemyTurn and anim.enemyTurn.timing
    if s and T.case==1 and not T.pauseChecked then
        if not T.pauseAt then
            cb.openPauseMenu();T.pauseAt=love.timer.getTime();T.pauseAge=s.age;return
        elseif love.timer.getTime()-T.pauseAt<.35 then
            assert(s.age==T.pauseAge,"pause must freeze the timing window");return
        end
        cb.closePauseMenu();T.pauseChecked=true
    end
    if s and not s.result then
        local name=s.kind..(T.case>2 and "_"..T.case or "")
        if not T.shots[name] and s.age>s.ready+.05 then shot(name);T.shots[name]=true end
        local target=s.zones[T.case>=5 and 7 or T.case==4 and 4 or T.case==3 and s.kind=="attack" and 6 or 1]
        local center=(target.from+target.to)/2
        if s.age>=s.ready and math.abs(s.position-center)<(target.to-target.from)*.4 then
            if s.kind=="attack" then love.keypressed("space",nil,false)
            else love.touchpressed("timing-test",640,400) end
            local expected=T.case>=5 and "ultimate" or T.case==4 and "critical" or T.case==3 and s.kind=="attack" and "trap" or "perfect"
            assert(s.result and s.result.grade==expected,"keyboard/touch must stop the real randomized bar")
            T.pressed[s.kind]=true
        end
    end
    if T.case==6 and T.pressed.parry and not anim.enemyTurn and state~="playing" and state~="scoring" then
        assert(T.victim.hp==0 and game.playerHp==1000 and not T.pressed.attack,"lethal reflection wins before the player attack")
        print("Combat timing runtime passed: real ultimate reflection damage and lethal parry victory before scoring")
        T.stage=3;love.event.quit(0);return
    end
    if T.pressed.attack and T.pressed.parry and not anim.active and not anim.enemyTurn and state=="playing" then
        assert(game.playerHp==1000,"perfect parry prevents HP loss")
        if T.case==3 then assert(game.monster.hp==100000,"red trap must make the real attack miss")
        else assert(game.monster.hp<100000,"timed player attack deals actual damage") end
        if T.case==5 then assert(game.monster.hp<=98000,"real ultimate parry reflects 2000 damage") end
        if T.case<6 then T.case=T.case+1;T.stage=0;T.pressed={};return end
        print("Combat timing runtime passed: before/after enemy initiative, keyboard attack, touch parry, pause, x4 speed, randomized targets, red forced miss, risky gold and ultimate attack/parry")
        T.stage=3
        love.event.quit(0)
    end
end
return T

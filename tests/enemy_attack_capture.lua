local T={}
local Deck=require("src.deck")
local case,started,hits,lastHp,seen=0,nil,0,nil,{}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    if not started then
        case=case+1
        if case>4 then print("Real enemy attack capture passed: fast enemy before score, counterattack after settle, end turn, three sequential attackers, HP at contact and input lock");love.event.quit();return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        if case==4 then
            game.monster.stage=3
            require("src.combat").start(game,game.monster,3)
        end
        cb.setScoringSpeed(case==2)
        game.hand={Deck.newCard(8,"spades")};game.selectedIndices={};game.deities={}
        game.playerHp=200;game.maxPlayerHp=200;game.playerArmor=0;game.playerShield=0
        game.monster.hp=10000000;game.monster.maxHp=10000000;game.monster.damageLagHp=10000000
        for _,m in ipairs(game.enemies) do
            m.hp=10000000;m.maxHp=10000000;m.damageLagHp=10000000
            m.attackSpeed=case==1 and 99 or 1
            -- Exceed the armor cap so every contact still changes HP after card balance updates.
            m.attack=40;m.intent={type="attack",value=40,label="Tấn Công 40 ST"}
        end
        game.abilityApproved={}
        if case==3 then game.handsRemaining=0;assert(cb.endPlayerTurn())
        else cb.selectCardIndex(1);cb.playSelectedHand() end
        lastHp=game.playerHp;hits=0;seen={};started=love.timer.getTime()
    else
        local a,state=cb.getScoringState()
        assert(love.timer.getTime()-started<25,"combat timeline timed out")
        if a.enemyTurn then
            local s=a.enemyTurn
            seen[s.phase]=true
            if s.phase~="recover" then assert(game.playerHp==lastHp,"HP loss before visible contact") end
            if case==1 then assert(not a.active,"fast enemy must finish before player scoring") end
            if case==2 then assert(a.sequence.finished,"counterattack must wait for player settle") end
            local hands=game.handsRemaining
            cb.playSelectedHand();assert(game.handsRemaining==hands,"input during enemy attack")
            if s.phase=="prepare" and s.age>0.3 and not seen.shotPrepare then
                seen.shotPrepare=true;shot("combat_tell_"..case)
            end
            if s.phase=="recover" and s.age<0.1 and not seen.shotImpact then
                seen.shotImpact=true;shot("combat_hit_"..case)
            end
        end
        if game.playerHp~=lastHp then hits=hits+1;lastHp=game.playerHp end
        if seen.recover and not a.enemyTurn and state=="playing" and not a.active then
            assert(hits==(case==4 and 3 or 1) and seen.prepare and seen.strike and seen.pause,
                string.format("case %d: HP contacts=%d; pause=%s prepare=%s strike=%s; armor=%s",case,hits,tostring(seen.pause),tostring(seen.prepare),tostring(seen.strike),tostring(game.playerArmor)))
            print("Combat timing case "..case.." passed");started=nil
        end
    end
end
return T

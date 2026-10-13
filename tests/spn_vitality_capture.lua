local T={};local step,deadline=0,0
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.deities={};game.hand={};game.deck={};game.discardPile={};game.persistentDeck={}
        local D=require("src.deities")
        assert(D.addDeity(game,D.CATALOG.spirit_armor_vitality,1));D.evolve(game.deities[1])
        game.playerHp=40;game.maxPlayerHp=100;game.playerArmor=20;game.playerShield=20
        game.monster.hp=0
        require("src.ui").finishCombatVictory()
        assert(game.playerHp==70 and game.maxPlayerHp==130 and game.playerArmor==0 and game.playerShield==0)
    elseif step==1 then
        local _,state=cb.getRunState();assert(state=="CASH_OUT")
        local hp,max=game.playerHp,game.maxPlayerHp
        require("src.card_abilities").combatWin(game)
        require("src.reward_system").calculate({baseReward=4},game,false)
        assert(game.playerHp==hp and game.maxPlayerHp==max,"reward screen cannot convert twice")
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/spn_vitality_victory.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
    elseif step==2 then
        print("SPN vitality UI PASS: shared live victory path consumes armor, raises capacity/heals, enters cash out and cannot pay twice")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+.6
end
return T

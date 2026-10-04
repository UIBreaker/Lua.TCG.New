local F = require("src.combat_feedback")
local UI = require("src.ui")
local T = {}
local index, started, captured, changed = 0, nil, false, false
function T.update(game, cb)
    local now = love.timer.getTime()
    if not started then
        if index==0 then require("tests.combat_feedback_smoke") end
        index=index+1
        if index>6 then print("Combat feedback GPU capture passed: all damage tiers, armor HUD, gold gain/spend");love.event.quit(0);return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.playerHp,game.maxPlayerHp=100,100
        game.playerArmor,game.playerShield=0,0
        game.gold=50
        if index==1 then game.monster.creatureArmor,game.monster.creatureArmorMax=250,500 end
        local a=cb.getScoringState()
        a.floatingTexts={}
        love.mouse.setPosition(4,4)
        started,captured,changed=now,false,false
    elseif not changed and now-started>1.6 then
        game.playerHp=75;game.playerArmor,game.playerShield=20,20
        game.gold=index==6 and 30 or 70
        local a=cb.getScoringState()
        F.add(a.floatingTexts,"damage",({25,250,2500,25000,250000,50})[index],
            UI.BATTLE_CENTER_X,214,UI.formatNumber)
        changed=true
    elseif not captured and now-started>1.77 then
        love.graphics.captureScreenshot(function(data)
            local file=assert(io.open("docs/combat_feedback/tier_"..index..".png","wb"))
            file:write(data:encode("png"):getString());file:close()
        end)
        captured=true
    elseif captured and now-started>2.1 then
        started=nil
    end
end
return T

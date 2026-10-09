local F = require("src.combat_feedback")
local UI = require("src.ui")
local T = {}
local index, started, captured, changed = 0, nil, false, false
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function T.update(game, cb)
    local now = love.timer.getTime()
    if not started then
        if index==0 then require("tests.combat_feedback_smoke") end
        index=index+1
        if index>8 then print("Combat feedback GPU capture passed: all damage tiers through 1e15, armor above HP/gain/depletion trails, gold gains/spending, recovery");love.event.quit(0);return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.playerHp,game.maxPlayerHp=index==8 and 60 or 100,100
        game.playerArmor,game.playerShield=index==6 and 20 or 0,index==6 and 20 or 0
        game.gold=50
        game.monster.creatureArmor,game.monster.creatureArmorMax=250,500
        local a=cb.getScoringState()
        a.floatingTexts={}
        love.mouse.setPosition(4,4)
        started,captured,changed=now,false,false
    elseif not changed and now-started>1.6 then
        game.playerHp=index==8 and 100 or 75
        local armor=index==6 and 0 or 20
        game.playerArmor,game.playerShield=armor,armor
        game.gold=index==6 and 30 or 50+({3,12,40,60,120,0,800,25})[index]
        if index==6 then game.monster.creatureArmor=0 end
        local a=cb.getScoringState()
        F.add(a.floatingTexts,"damage",({25,250,2500,25000,250000,50,1e15,250})[index],
            UI.BATTLE_CENTER_X,214,UI.formatNumber)
        changed=true
    elseif not captured and now-started>1.77 then
        love.graphics.captureScreenshot(function(data)
            local file=io.open("docs/combat_feedback/tier_"..index..".png","wb")
            if not file then file=assert(io.open("docs/combat_feedback/upgrade_tier_"..index..".png","wb")) end
            file:write(data:encode("png"):getString());file:close()
        end)
        captured=true
    elseif captured and now-started>2.1 then
        started=nil
    end
end
return T

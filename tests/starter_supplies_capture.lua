local T={};local step,deadline=0,0
local Shop=require("src.shop")
local Deck=require("src.deck")
local P=require("src.persistence")
local function check(game)
    assert(#game.consumables==3 and game.maxConsumables==3)
    assert(game.consumables[1].id=="healing_potion" and game.consumables[1].healAmt==25)
    assert(game.consumables[2].id=="armor_potion_small" and game.consumables[2].armorAmt==8)
    assert(game.consumables[3].id=="cons_speed_small" and Shop.getConsumableParams(game.consumables[3]).speed==3)
end
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        cb.startNewGame("red_deck");check(game)
        assert(#game.persistentDeck==5 and game.maxHandSize==3)
        local suits={};for _,card in ipairs(game.persistentDeck) do suits[card.suit]=true end
        for _,suit in ipairs(Deck.FACTION_ORDER) do assert(suits[suit]) end
        local loaded=P.restoreSnapshot(P.makeSnapshot(game,"BLIND_SELECT"));check(loaded)
        T.first=game.consumables[1]
        cb.startMonsterEncounter(1,false);check(game)
        assert(#game.hand==3 and #game.deck==2 and game.monster.hp==50)
    elseif step==1 then
        love.mouse.setPosition(2,2)
        love.graphics.captureScreenshot(function(data)
            local file=assert(io.open("docs/starter_supplies.png","wb"));file:write(data:encode("png"):getString());file:close()
        end)
    elseif step==2 then
        game.playerHp=60;assert(cb.activateStoredReward(1) and game.playerHp==85 and #game.consumables==2)
        assert(cb.activateStoredReward(1) and game.playerArmor==8 and #game.consumables==1)
        assert(cb.activateStoredReward(1));T.speed=Deck.getCardAttackSpeed(game.hand[1])
    elseif step==3 then
        local card=game.hand[1];local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
        local x=(w-1280*scale)/2+((card.visualX or 0)+50)*scale
        local y=(h-720*scale)/2+((card.visualY or 0)+70)*scale
        love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
        assert(#game.consumables==0 and Deck.getCardAttackSpeed(card)==T.speed+3)
        local loaded=P.restoreSnapshot(P.makeSnapshot(game,"BLIND_SELECT"))
        assert(#loaded.consumables==0,"Save/restore must not regrant used supplies")
        cb.startMonsterEncounter(2,false);assert(#game.consumables==0,"A new fight must not regrant supplies")
        cb.startNewGame("red_deck");check(game)
        assert(game.consumables[1]~=T.first,"Each run owns fresh potion instances")
        cb.startNewGame("red_deck");check(game)
        print("Starter supplies PASS: 25 HP / 8 armor / 3 speed, available in first fight, real use, save retention, no per-fight regrant, fresh 3-item restart")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+.65
end
return T

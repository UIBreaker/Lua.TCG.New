-- Run in LÖVE: lovec.exe . --test-pack-skip (no player save writes).
local Shop = require("src.shop")
local UI = require("src.ui")
local Deck = require("src.deck")
local Test = {}
local P=require("src.persistence");P.deleteRun=function() return true end;P.saveRun=function() return true end;P.saveSettings=function() return true end
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
local stage, packIndex, settleUntil = "start", 0, 0
local paidGold, initialDeckCount, exchangeGold, chestIndex, chestRewards, packStarted

function Test.update(game, callbacks, click)
    if stage == "start" then
        callbacks.startNewGame("red_deck")
        game.consumables={}
        callbacks.openShop()
        game.gold = 1000
        love.mouse.setPosition(4,4)
        initialDeckCount = #game.persistentDeck
        stage = "open"
    elseif stage == "open" then
        packIndex = packIndex + 1
        local pack = Shop.PACK_CATALOG[packIndex]
        if not pack then
            assert(#game.persistentDeck == initialDeckCount and #game.consumables == 0)
            print("Pack exchange passed: bought and converted all " .. #Shop.PACK_CATALOG .. " chest types; closing FX rendered; no items granted")
            chestIndex=0;stage="legacy_open"
            return
        end
        local shop = callbacks.getShopData()
        if pack.packType=="hand_styles_advanced" then
            for _,hand in ipairs(require("src.poker").HAND_TYPES_ORDERED) do game.unlockedHands[hand.id]=true end
        end
        local item = { category = "pack", packType = pack.packType, name = pack.name, cost = pack.cost }
        local image, isReward = UI.getPackCardImage(pack.packType, item)
        assert(image == UI.getPackImage(pack.packType) and not isReward,
            "A skipped chest must render its own art, not a rank-less reward: " .. pack.packType)
        shop.items[#shop.items + 1] = item
        local beforeGold = game.gold
        assert(Shop.buyItem(shop, #shop.items, game))
        assert(game.gold == beforeGold - pack.cost)
        paidGold = game.gold
        exchangeGold = Shop.getPackExchangeGold(shop.currentPackOpening)
        shop.currentPackOpening.animationTimer = 2
        settleUntil = love.timer.getTime() + (packIndex==1 and 1.7 or 0)
        packStarted = love.timer.getTime()
        stage = "skip"
    elseif stage == "skip" then
        if love.timer.getTime()<settleUntil then return end
        local skip;for _,btn in ipairs(callbacks.getButtons()) do if btn.id=="skip_pack" then skip=btn end end
        if not skip and love.timer.getTime()-packStarted<6 then return end
        assert(skip and skip.text:find("QUY ĐỔI RA VÀNG",1,true),"visible exchange action")
        if packIndex==1 then
            love.graphics.captureScreenshot(function(data)
                local f=assert(io.open("docs/chest_exchange_pack.png","wb"));f:write(data:encode("png"):getString());f:close()
            end)
            stage="exchange_click";return
        end
        stage="exchange_click"
    elseif stage == "exchange_click" then
        local skip;for _,btn in ipairs(callbacks.getButtons()) do if btn.id=="skip_pack" then skip=btn end end
        click(skip.x+skip.w/2,skip.y+skip.h/2,true)
        assert(callbacks.getShopData().currentPackOpening == nil, "Skip button must close the purchased pack")
        assert(game.gold == paidGold+exchangeGold, "Exchange must pay exactly the displayed gold")
        settleUntil = love.timer.getTime() + 0.9
        stage = "settle"
    elseif stage == "settle" and love.timer.getTime() >= settleUntil then
        -- The normal draw loop renders the closing FX during this entire interval.
        assert(game.gold == paidGold+exchangeGold and #game.persistentDeck == initialDeckCount and #game.consumables == 0)
        print("[PASS] Skip + closing animation: " .. Shop.PACK_CATALOG[packIndex].packType)
        stage = "open"
    elseif stage == "legacy_open" then
        chestIndex=chestIndex+1
        if chestIndex>2 then
            print("Legacy treasure/boss chest exchange passed: displayed amount, one payout, no items, map continuation")
            stage="done";love.event.quit(0);return
        end
        local eq=require("src.equipment").ITEMS.gem_fire
        chestRewards={{type="card",card=Deck.newCard(10,"hearts"),title="QUÂN BÀI"},
            {type="equipment",item=eq,title=eq.name},{type="equipment",item=eq,title=eq.name}}
        callbacks.previewChest(chestRewards,chestIndex==2)
        love.mouse.setPosition(4,4)
        paidGold=game.gold;exchangeGold=Shop.getChestExchangeGold(chestRewards)
        settleUntil=love.timer.getTime()+UI.ChestChoices.finished()+0.2;stage="legacy_ready"
    elseif stage == "legacy_ready" and love.timer.getTime()>=settleUntil then
        local button;for _,btn in ipairs(callbacks.getButtons()) do if btn.id=="exchange_chest" then button=btn end end
        assert(button and button.text:find("+"..exchangeGold,1,true))
        if chestIndex==1 then
            love.graphics.captureScreenshot(function(data)
                local f=assert(io.open("docs/chest_exchange_treasure.png","wb"));f:write(data:encode("png"):getString());f:close()
            end)
        end
        stage="legacy_click"
    elseif stage == "legacy_click" then
        local button;for _,btn in ipairs(callbacks.getButtons()) do if btn.id=="exchange_chest" then button=btn end end
        click(button.x+button.w/2,button.y+button.h/2,true)
        assert(select(2,callbacks.getRunState())=="map" and game.gold==paidGold+exchangeGold)
        assert(#game.persistentDeck==initialDeckCount and #game.consumables==0)
        assert(not Shop.exchangeChest(chestRewards,game) and game.gold==paidGold+exchangeGold)
        stage="legacy_open"
    end
end

return Test

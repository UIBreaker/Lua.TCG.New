-- Run in LÖVE: lovec.exe . --test-pack-skip (no player save writes).
local Shop = require("src.shop")
local UI = require("src.ui")
local Deck = require("src.deck")
local Test = {}
local stage, packIndex, settleUntil = "start", 0, 0
local paidGold, initialDeckCount

function Test.update(game, callbacks, click)
    if stage == "start" then
        -- Missing/nonnumeric input must not reach a numeric comparison.
        assert(Deck.getAttackSpeed(nil) == 1)
        assert(Deck.getAttackSpeed("8") == 8)
        assert(Deck.getAttackSpeed("invalid") == 1)
        for rank = 2, 14 do
            assert(Deck.getAttackSpeed(rank) == (rank == 14 and 11 or math.min(rank, 10)))
        end
        callbacks.startNewGame("red_deck")
        callbacks.openShop()
        game.gold = 1000
        initialDeckCount = #game.persistentDeck
        stage = "open"
    elseif stage == "open" then
        packIndex = packIndex + 1
        local pack = Shop.PACK_CATALOG[packIndex]
        if not pack then
            assert(#game.persistentDeck == initialDeckCount and #game.consumables == 0)
            print("Pack skip regression passed: bought and skipped all " .. #Shop.PACK_CATALOG .. " chest types; closing FX rendered; no rewards or refunds")
            love.event.quit(0)
            stage = "done"
            return
        end
        local shop = callbacks.getShopData()
        local item = { category = "pack", packType = pack.packType, name = pack.name, cost = pack.cost }
        local image, isReward = UI.getPackCardImage(pack.packType, item)
        assert(image == UI.getPackImage(pack.packType) and not isReward,
            "A skipped chest must render its own art, not a rank-less reward: " .. pack.packType)
        shop.items[#shop.items + 1] = item
        local beforeGold = game.gold
        assert(Shop.buyItem(shop, #shop.items, game))
        assert(game.gold == beforeGold - pack.cost)
        paidGold = game.gold
        shop.currentPackOpening.animationTimer = 2
        stage = "skip"
    elseif stage == "skip" then
        click(640, 509, true)
        assert(callbacks.getShopData().currentPackOpening == nil, "Skip button must close the purchased pack")
        assert(game.gold == paidGold, "Skipping must not charge again or refund the pack")
        settleUntil = love.timer.getTime() + 0.9
        stage = "settle"
    elseif stage == "settle" and love.timer.getTime() >= settleUntil then
        -- The normal draw loop renders the closing FX during this entire interval.
        assert(game.gold == paidGold and #game.persistentDeck == initialDeckCount and #game.consumables == 0)
        print("[PASS] Skip + closing animation: " .. Shop.PACK_CATALOG[packIndex].packType)
        stage = "open"
    end
end

return Test

local Shop = require("src.shop")
local GameState = require("src.game_state")
local Deck = require("src.deck")
local Collection = require("src.collection")
local Persistence = require("src.persistence")

local game = GameState.new()
game.gold, game.playerHp = 500, 40
local shop = Shop.new()
local function buy(id)
    local definition
    for _, voucher in ipairs(Shop.VOUCHERS) do
        if voucher.id == id then definition = voucher break end
    end
    assert(definition, "unknown voucher: " .. id)
    shop.items[#shop.items + 1] = { category = "voucher", voucherId = id,
        cost = definition.cost, name = definition.name }
    assert(Shop.buyItem(shop, #shop.items, game))
end

assert(#Shop.VOUCHERS == 9 and #Collection.getItems("vouchers") == 9)
buy("v_welcome")
local gold = game.gold
assert(Shop.getRerollCost(shop, game) == 0)
assert(Shop.reroll(shop, game) and game.gold == gold and shop.rerollCost == 5)
assert(Shop.getRerollCost(shop, game) == 5)
assert(Shop.reroll(shop, game) and game.gold == gold - 5 and shop.rerollCost == 7)
Shop.resetReroll(shop)
assert(shop.rerollCount == 0 and Shop.getRerollCost(shop, game) == 0)
game.freeRerolls = 1
assert(Shop.reroll(shop, game) and game.freeRerolls == 0 and not shop.welcomeRerollUsed)
assert(Shop.reroll(shop, game) and shop.welcomeRerollUsed)

buy("v_pack_discount")
for _, item in ipairs(shop.items) do
    if item.category == "pack" then assert(item.cost == math.max(1, item.baseCost - 2)) end
end
Shop.applyVoucherStock(shop, game)
for _, item in ipairs(shop.items) do
    if item.category == "pack" then assert(item.cost == math.max(1, item.baseCost - 2)) end
end
buy("v_apothecary")
for i, item in ipairs(shop.items) do
    if item.category == "heal" then
        assert(item.healAmt == 40 and item.cost == 4 and item.desc:find("40"))
        local hp = game.playerHp
        assert(Shop.buyItem(shop, i, game) and game.playerHp == hp + 40)
        break
    end
end
buy("v_vitality")
assert(game.maxPlayerHp == 120 and game.playerHp == 100)
buy("v_second_chance")
assert(game.maxDiscards == 4 and game.discardsRemaining == 4)
buy("v_altar")
game.consumables = { { cost = 6 } }
gold = game.gold
assert(Shop.sellConsumable(game, 1) and game.gold == gold + 5)
game.deities = { { cost = 8 } }
gold = game.gold
assert(Shop.sellDeity(game, 1) and game.gold == gold + 6)
game.persistentDeck = { Deck.newCard(2, "clubs"), Deck.newCard(3, "clubs") }
gold = game.gold
assert(Shop.sellCard(game, game.persistentDeck[1]) and game.gold == gold + 3)

-- Duplicate purchases cannot charge gold or apply the stat bonus twice.
shop.items = { { category = "voucher", voucherId = "v_vitality", cost = 12 } }
gold = game.gold
assert(not Shop.buyItem(shop, 1, game) and game.gold == gold and game.maxPlayerHp == 120)
for i = 1, 60 do
    Shop.refresh(shop, game)
    for _, item in ipairs(shop.items) do
        if item.category == "voucher" then assert(not game.vouchers[item.voucherId]) end
    end
end
local restored = assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(game, "shop")))
assert(restored.vouchers.v_altar and restored.vouchers.v_welcome and restored.maxPlayerHp == 120)
local restoredShop = Shop.new()
Shop.refresh(restoredShop, restored)
assert(Shop.getRerollCost(restoredShop, restored) == 0)
for _, voucher in ipairs(Shop.VOUCHERS) do game.vouchers[voucher.id] = true end
Shop.refresh(shop, game)
for _, item in ipairs(shop.items) do assert(item.category ~= "voucher") end
GameState.resetRun(game)
assert(next(game.vouchers) == nil and game.maxPlayerHp == 100 and game.maxDiscards == 3)
print("Shop voucher smoke test passed: 9 vouchers, prices, healing, rerolls, sacrifice, save and reset")

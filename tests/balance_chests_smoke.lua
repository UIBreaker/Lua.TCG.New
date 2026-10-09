package.path = "./?.lua;./?/init.lua;" .. package.path

local GameState = require("src.game_state")
local Poker = require("src.poker")
local Shop = require("src.shop")
local Reward = require("src.reward_system")
local Basics = require("src.basic_equipment")

local game = GameState.new()
local shop = Shop.new()
Shop.refresh(shop, game)
local function handChest()
    for i, item in ipairs(shop.items) do
        if item.packType == "hand_styles" or item.packType == "hand_styles_advanced" then return i, item end
    end
end
local _, firstChest = handChest()
assert(firstChest and firstChest.packType == "hand_styles")
local opening = Shop.openPack({packType="hand_styles"}, game)
assert(#opening.cards == 3)
for _, book in ipairs(opening.cards) do assert(book.handId ~= "high_card" and not game.unlockedHands[book.handId]) end

for _, hand in ipairs(Poker.HAND_TYPES_ORDERED) do game.unlockedHands[hand.id] = true end
game.unlockedHands.pair = nil
opening = Shop.openPack({packType="hand_styles"}, game)
assert(#opening.cards == 3 and opening.cards[1].handId == "pair")
game.unlockedHands.pair = true
Shop.refresh(shop, game)
local index, chest = handChest()
assert(index and chest.packType == "hand_styles_advanced")
game.gold = math.max(game.gold, chest.cost)
local beforeGold = game.gold
local ok, notice = Shop.buyItem(shop, index, game)
assert(ok and notice:find("đang phát triển") and notice:find("hoàn lại"))
assert(game.gold == beforeGold and not shop.currentPackOpening)

for _, planet in ipairs(Poker.PLANET_CARDS) do
    local state = GameState.new()
    local choice = {currentPackOpening={pack={packType="celestial"},cards={planet}}}
    local old = {}
    for _, hand in ipairs(Poker.HAND_TYPES_ORDERED) do old[hand.id] = state.handLevels[hand.id] end
    assert(Shop.choosePackCard(choice, 1, state))
    if planet.handId == "all" then
        for handId, level in pairs(old) do assert(state.handLevels[handId] == level + 2) end
    elseif planet.handId == "random" then
        local total = 0
        for handId, level in pairs(old) do total = total + state.handLevels[handId] - level end
        assert(total == 3)
    else
        assert(state.handLevels[planet.handId] == old[planet.handId] + 2)
        assert(Shop.getConsumableDescription(planet):find("+2 cấp", 1, true))
    end
end
assert(Shop.getConsumableDescription(Shop.getPackContents("hand_styles")[1]):find("+1 cấp", 1, true))
assert(Shop.getConsumableDescription(Poker.PLANET_CARDS[#Poker.PLANET_CARDS]):find("2 cấp", 1, true))

local rewardGame = GameState.new()
local config = Reward.config
config.tables.test_basic_equipment = {rolls={1,1},entries={{id="itm_pack",weight=1}}}
local result = Reward.begin(Reward.calculate({type="small",baseReward=3}, rewardGame), rewardGame, {lootTableId="test_basic_equipment"})
local rewardOpening = result.loot[1].opening
assert(rewardOpening and rewardOpening.pack.rewardPack and #rewardOpening.cards == 3)
local basic = {}
for _, id in ipairs(Basics.basic) do basic[id] = true end
for _, item in ipairs(rewardOpening.cards) do assert(basic[item.id] and item.basic) end
print("Balance chest smoke passed")

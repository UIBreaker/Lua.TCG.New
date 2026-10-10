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
-- Every missing basic hand, including the default one, keeps advanced stock gated.
for _,missing in ipairs(Poker.HAND_TYPES_ORDERED) do
    for _,hand in ipairs(Poker.HAND_TYPES_ORDERED) do game.unlockedHands[hand.id]=true end
    game.unlockedHands[missing.id]=nil
    for roll=1,12 do
        shop.lastPackTypes={}
        if roll==12 then
            for _,pack in ipairs(Shop.PACK_CATALOG) do shop.lastPackTypes[#shop.lastPackTypes+1]=pack.packType end
        end
        Shop.refresh(shop,game)
        local basicCount=0
        for _,item in ipairs(shop.items) do
            assert(item.packType~="hand_styles_advanced","advanced chest sold before all nine basic hands")
            if item.packType=="hand_styles" then basicCount=basicCount+1 end
        end
        assert(basicCount==1)
    end
end
game=GameState.new()
Shop.refresh(shop,game)
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
for _=1,24 do
    Shop.refresh(shop,game)
    local advancedCount=0
    for _,item in ipairs(shop.items) do
        assert(item.packType~="hand_styles","basic chest must be replaced")
        if item.packType=="hand_styles_advanced" then advancedCount=advancedCount+1 end
    end
    assert(advancedCount==1)
end
index,chest=handChest()
game.gold = math.max(game.gold, chest.cost)
local beforeGold = game.gold
local ok, notice = Shop.buyItem(shop, index, game)
assert(ok and notice=="open_pack")
assert(game.gold == beforeGold-chest.cost and shop.currentPackOpening and #shop.currentPackOpening.cards==3)

for _, planet in ipairs(Poker.PLANET_CARDS) do
    local state = GameState.new()
    local choice = {currentPackOpening={pack={packType="celestial"},cards={planet}}}
    local old = {}
    for _, hand in ipairs(Poker.ALL_HANDS_ORDERED) do old[hand.id] = state.handLevels[hand.id] end
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

local Debug = require("src.debug_tools")
local Game = require("src.game_state")
local Deck = require("src.deck")
local Run = require("src.run_manager")
local Shop = require("src.shop")
local Collection = require("src.collection")
local function fixture()
    local g = Game.new()
    g.run = Run.newRun(g.selectedFaction)
    g.persistentDeck = {Deck.newCard(7, "hearts"), Deck.newCard(12, "spades")}
    g.hand = {Deck.cloneCard(g.persistentDeck[1])}
    return g
end
local g = fixture()
for _, value in ipairs({"", "abc", "-1", "1.5", "inf", "9007199254740992"}) do
    local gold = g.gold
    local ok, message = Debug.setGold(g, value)
    assert(not ok and message and g.gold == gold)
    assert(not Debug.addGold(g, value) and g.gold == gold)
end
assert(Debug.setGold(g, "0") and g.gold == 0)
assert(Debug.addGold(g, "100") and g.gold == 100)
assert(Debug.setGold(g, "9007199254740991"))
assert(not Debug.addGold(g, 1) and g.gold == 9007199254740991)
assert(not Debug.addGold(g, math.huge))
assert(not Debug.setGold(g, 0 / 0))

for _, value in ipairs({0, 1000, 1.1, "", "bad", math.huge}) do
    local run = g.run
    assert(not Debug.setAnte(g, value) and g.run == run)
end
assert(not Debug.setAnte(g, 3, 0))
assert(not Debug.setAnte(g, 3, 1, "missing"))
for _, region in ipairs(require("src.expedition").regions) do
    for _, ante in ipairs({1, 20, 21, 40, 41, 999}) do
        for index = 1, 3 do
            assert(Debug.setAnte(g, tostring(ante), index, region.id))
            assert(g.run.regionId == region.id and g.run.ante == ante and g.currentBlind == g.run.blinds[index])
            assert(not g.run.victory and not g.run.travelPermit)
            for i, b in ipairs(g.run.blinds) do
                assert(b.status == (i < index and "completed" or i == index and "current" or "upcoming"))
                assert(b.regionId == region.id and b.hp > 0 and b.hp < math.huge)
            end
        end
    end
end

local count = 0
for _, category in ipairs(Collection.getCategories()) do
    for _, item in ipairs(Collection.getItems(category.id)) do
        g = fixture()
        local shop = Shop.new()
        shop.items = {{name = "keep", cost = 12}}
        local ok, message, payload = Debug.grantCollectionItem(g, shop, category.id, item, g.persistentDeck[1])
        assert(ok, category.id .. ": " .. item.name .. " -> " .. tostring(message))
        assert(#shop.items == 1 and shop.items[1].name == "keep", "grants must not alter market stock")
        if category.id == "enhancements" then assert(g.hand[1].enhancement == g.persistentDeck[1].enhancement)
        elseif category.id == "seals" then assert(g.hand[1].seal == g.persistentDeck[1].seal)
        elseif category.id == "editions" then assert(g.hand[1].edition == g.persistentDeck[1].edition)
        elseif category.id == "equipment" then assert(message == "socketing" and payload.id == item.id)
        elseif category.id == "playing_cards" then assert(#g.persistentDeck == 3)
        elseif category.id == "decks" then assert(message == "deck" and payload == item.id)
        elseif category.id == "packs" then assert(message == "pack" and payload == item.packType) end
        count = count + 1
    end
end
g = fixture()
g.persistentDeck[1].edition = "foil"; g.hand[1].edition = "foil"
assert(Debug.grantCollectionItem(g, {}, "editions", {id="ed_base", name="Chuẩn"}, g.persistentDeck[1]))
assert(not g.hand[1].edition and not g.persistentDeck[1].edition)
assert(not Debug.grantCollectionItem(g, {}, "editions", {id="invalid", name="?"}, g.persistentDeck[1]))
assert(not Debug.grantCollectionItem(g, {}, "seals", {id="seal_anchor",name="Neo"}))
g.pendingVictoryReward = {}; g.pendingRoundRewardChoice = {}; g.pendingRewardEquipment = {}
g.pendingBloodShop = "blood_small"; g.pendingBarter = true; g.voidEvent = {}; g.monster = {}
g.souls = 100; g.gold = 500; g.backpackEquipment = {{id="gem_fire"}}
local cards, run = g.persistentDeck, g.run
Debug.clearScene(g)
assert(g.run == run and g.persistentDeck == cards and #cards == 2 and cards[1].edition == nil)
assert(g.gold == 500 and g.souls == 100 and #g.backpackEquipment == 1)
assert(not g.monster and not g.pendingVictoryReward and not g.pendingRoundRewardChoice and not g.pendingRewardEquipment)
assert(not g.pendingBloodShop and not g.pendingBarter and not g.voidEvent and #g.hand == 0)
print("Debug tools PASS: gold validation, 108 route/ante/fight boundaries, " .. count .. " catalog grants, live-card sync, isolated vouchers, scene cleanup preserves ownership")
return true

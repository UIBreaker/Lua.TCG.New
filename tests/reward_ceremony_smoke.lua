package.path = "./?.lua;./?/init.lua;" .. package.path
local Reward = require("src.reward_system")
local Rng = require("src.rng")
local Deck = require("src.deck")
local Run = require("src.run_manager")
local Shop = require("src.shop")
local Persistence = require("src.persistence")
local Deities = require("src.deities")
local C = Reward.config
local function game()
    return {gold = 10, handsRemaining = 2, maxInterest = 3, selectedFaction = "aurelia",
        deities = {}, persistentDeck = {Deck.newCard(5, "hearts")}, consumables = {},
        run = Run.newRun("aurelia"), lastRoundDeityRewards = {bonusGold = 0, details = {}}}
end
local blind = {type = "small", baseReward = 3, name = "Tiểu Yêu"}
local function forced(g, id)
    C.tables.test = {rolls = {1, 1}, entries = {{id = id, weight = 1}}}
    return Reward.begin(Reward.calculate(blind, g, false), g, {lootTableId = "test"})
end

assert(Reward.weighted({{id = "a", weight = 2}, {id = "b", weight = 3}}, function() return 0 end) == "a")
assert(Reward.weighted({{id = "a", weight = 2}, {id = "b", weight = 3}}, function() return 0.4 end) == "b")
assert(Reward.weighted({{id = "a", weight = 0}}, function() return 0 end) == "gold_bonus")
for tableId, data in pairs(C.tables) do
    local total = 0
    for _, entry in ipairs(data.entries) do assert(C.definitions[entry.id], tableId); total = total + entry.weight end
    assert(total > 0)
end
local g = game()
local breakdown = Reward.calculate(blind, g)
assert(breakdown.basePayout == 3 and breakdown.unusedHandsBonus == 2 and breakdown.interestBonus == 2)
assert(breakdown.totalGold == 7)
g.selectedFaction = "valoria"
assert(Reward.calculate(blind, g).totalGold == 9)
g.selectedFaction, g.gold = "diamonds", 500
assert(Reward.calculate(blind, g).interestBonus == 125)
g = game(); g.lastRoundDeityRewards = {bonusGold = 4, details = {{name = "SPN", amount = 4}}}
assert(Reward.calculate(blind, g).totalGold == 11)

for _, id in ipairs({"gold_bonus", "playing_card", "card_pack", "spn_pack", "itm_pack", "consumable", "evolution", "consumable_pack", "chest", "rare_reward"}) do
    Rng.seed(17)
    g = game()
    local result = forced(g, id)
    local gold, cards, packs, consumables = g.gold, #g.persistentDeck, #g.rewardPacks, #g.consumables
    assert(result.claimed and result.loot[1].id == id)
    assert(g.gold == 10 + result.earnedGold)
    assert(Reward.begin(breakdown, g) == result)
    assert(g.gold == gold and #g.persistentDeck == cards and #g.rewardPacks == packs and #g.consumables == consumables)
    if id == "playing_card" then assert(cards == 2) end
    if C.definitions[id].packType then assert(packs == 1 and #g.rewardPacks[1].cards > 0) end
    if id == "consumable" or id == "evolution" then assert(consumables == 1) end
    if id == "chest" or id == "rare_reward" then assert(#result.loot[1].children == 2) end
    local state = Rng.getState()
    local anim = Reward.newAnimation(result.breakdown, result)
    local sawBounce, sawMagnet, sawCoin, maxActive = false, false, false, 0
    for _ = 1, 1500 do
        Reward.update(anim, 1 / 120)
        maxActive = math.max(maxActive, #anim.coins)
        assert(#anim.sparks <= C.presentation.maxSparks, "spark budget must hold")
        for _, coin in ipairs(anim.coins) do
            sawCoin = true
            sawBounce = sawBounce or coin.phase == "BOUNCE"
            sawMagnet = sawMagnet or coin.phase == "MAGNETIZE"
        end
        if anim.finished then break end
    end
    assert(anim.finished and anim.state == "SUMMARY", id .. " must settle")
    assert(anim.displayTotal == result.earnedGold and anim.walletTotal == gold)
    assert(sawCoin and sawBounce and sawMagnet, id .. " coin lifecycle")
    assert(maxActive <= C.maxCoins and anim.coinsSpawned <= C.maxCoins)
    assert(Rng.getState() == state, "presentation must not consume gameplay RNG")
    assert(g.gold == gold, "animation cannot grant gold")
    for _, delay in ipairs({0, 0.5, 1.5, 2.8}) do
        local fast = Reward.newAnimation(result.breakdown, result)
        Reward.update(fast, delay)
        local alreadySettled = fast.finished
        Reward.finishImmediately(fast); Reward.finishImmediately(fast); Reward.update(fast, 0.3)
        assert(fast.finished and fast.displayTotal == result.earnedGold and #fast.coins == 0)
        assert(alreadySettled or #fast.sparks == 0, "fast-forward clears unfinished reveal effects")
        assert(g.gold == gold and Rng.getState() == state)
    end
    local saved = Persistence.makeSnapshot(g, "CASH_OUT")
    local restored, restoredState = Persistence.restoreSnapshot(assert(Persistence.decode(Persistence.encode(saved))))
    assert(restoredState == "CASH_OUT" and restored.gold == gold)
    assert(restored.pendingVictoryReward.earnedGold == result.earnedGold)
    assert(Reward.begin(breakdown, restored).earnedGold == result.earnedGold and restored.gold == gold)
    assert(#restored.rewardPacks == packs)
    if packs > 0 then
        local shop = Shop.new()
        assert(Reward.openNextPack(restored, shop))
        assert(shop.currentPackOpening.cards[1].id == g.rewardPacks[1].cards[1].id)
        if shop.currentPackOpening.pack.packType == "buffoon" then
            local card = shop.currentPackOpening.cards[1]
            for k, v in pairs(Deities.CATALOG[card.id]) do if type(v) == "function" then assert(card[k] == v) end end
        end
        local opening = shop.currentPackOpening
        Shop.skipPack(shop)
        assert(Reward.completePack(restored, shop, opening) and #restored.rewardPacks == packs - 1)
        assert(not Reward.completePack(restored, shop, opening), "repeated completion cannot consume another pack")
    end
end

g = game(); g.consumables = {{}, {}, {}}
local full = forced(g, "consumable")
assert(full.loot[1].type == "GOLD" and full.bonusGold == C.fallbackGold)
g = game()
for i = 1, Deities.getMaxSlots(g) do g.deities[i] = Deities.CATALOG.spirit_blade end
assert(forced(g, "spn_pack").loot[1].type == "GOLD")
for bossId, tableId in pairs(C.bossOverrides) do
    g = game()
    g.monster = {bossData = {id = bossId}}
    local result = Reward.begin(Reward.calculate({type = "boss", baseReward = 5}, g), g)
    assert(result.tableId == tableId and #result.loot >= 1)
end
g = game()
local skipped = Reward.begin(Reward.calculate(blind, g, true), g)
assert(#skipped.loot == 0 and skipped.earnedGold == 2)
g = game(); g.gold = 5000
local large = forced(g, "gold_bonus")
local anim = Reward.newAnimation(large.breakdown, large)
Reward.update(anim, 10)
assert(anim.finished and anim.displayTotal == large.earnedGold and anim.coinsSpawned <= C.maxCoins)

-- Queue selection and socket hand-off are persisted separately from animation.
g = game(); forced(g, "card_pack"); g.pendingVictoryReward = nil
local shop = Shop.new(); Reward.openNextPack(g, shop)
local opening, before = shop.currentPackOpening, #g.persistentDeck
assert(Shop.choosePackCard(shop, 1, g))
assert(Reward.completePack(g, shop, opening) and #g.persistentDeck == before + 1)
g = game(); forced(g, "itm_pack"); g.pendingVictoryReward = nil
shop = Shop.new(); Reward.openNextPack(g, shop)
local ok, action, equipment = Shop.choosePackCard(shop, 1, g)
assert(ok and action == "open_socketing" and equipment.id)
g.pendingRewardEquipment = equipment
local saved = Persistence.makeSnapshot(g, "socketing")
local restored, restoredState = Persistence.restoreSnapshot(saved)
assert(restoredState == "socketing" and restored.pendingRewardEquipment.id == equipment.id)
assert(#restored.rewardPacks == 1)
g = game(); forced(g, "spn_pack"); g.pendingVictoryReward = nil
local savedShop = Persistence.makeSnapshot(g, "shop")
local resumed, resumeState = Persistence.restoreSnapshot(savedShop)
assert(resumeState == "shop" and #resumed.rewardPacks == 1)
for i = 1, Deities.getMaxSlots(resumed) do resumed.deities[i] = Deities.CATALOG.spirit_blade end
local beforeFallback = resumed.gold
local converted, reason = Reward.openNextPack(resumed, Shop.new())
assert(converted and reason and #resumed.rewardPacks == 0 and resumed.gold == beforeFallback + C.fallbackGold)
assert(not Reward.openNextPack(resumed, Shop.new()) and resumed.gold == beforeFallback + C.fallbackGold)
local savedCap = C.maxCoins
C.maxCoins = 1
local capped = Reward.newAnimation(large.breakdown, large)
Reward.update(capped, 10)
assert(capped.finished and capped.displayTotal == large.earnedGold and capped.coinsSpawned == 1)
C.maxCoins = savedCap
for _, fps in ipairs({30, 60, 144}) do
    local presented = Reward.newAnimation(large.breakdown, large)
    local rngBefore = Rng.getState()
    local previousGold = 0
    for _ = 1, fps * 12 do
        Reward.update(presented, 1 / fps)
        assert(presented.displayTotal >= previousGold, "counter must remain monotonic")
        assert(#presented.sparks <= C.presentation.maxSparks)
        previousGold = presented.displayTotal
        if presented.finished then break end
    end
    assert(presented.finished and presented.displayTotal == large.earnedGold)
    assert(Rng.getState() == rngBefore, "cinematic effects cannot alter gameplay RNG")
end
-- All seven supply cards retain their existing usable effects and artwork IDs.
for _, entry in ipairs(C.supplies.entries) do
    local supplyGame = game()
    local reward = forced(supplyGame, entry.id)
    local card = supplyGame.consumables[1]
    assert(card and card.id == entry.id and reward.loot[1].type == "CONSUMABLE")
    if entry.id:match("healing") then assert(card.healAmt == (entry.id:match("large") and 60 or 15)) end
    if entry.id:match("armor") then assert(card.armorAmt == (entry.id:match("large") and 20 or 8)) end
    if entry.id:match("speed") then assert(Shop.getConsumableParams(card).speed == (entry.id:match("large") and 10 or 3)) end
    local full = game(); for i=1,require("src.inventory").limit(full) do full.consumables[i]=Run.createSpeedSingleCard() end
    assert(forced(full,entry.id).loot[1].type=="GOLD", "full inventory must convert supplies")
end
local Souls = require("src.souls")
for _, count in ipairs({1,2,3}) do
    local squad = game(); squad.souls=5;squad.enemies={}
    for i=1,count do squad.enemies[i]={hp=10,group=squad.enemies} end
    squad.monster=squad.enemies[1]
    for i=1,count do
        squad.enemies[i].hp=0
        Souls.awardKills(squad); Souls.awardKills(squad)
        assert(squad.souls==5+i, "one soul per kill, no duplicate payout")
    end
    local result=forced(squad,"gold_bonus")
    assert(result.earnedSouls==count and result.soulsBefore==5 and squad.souls==5+count)
    local resumed=Persistence.restoreSnapshot(Persistence.makeSnapshot(squad,"CASH_OUT"))
    assert(Reward.begin(result.breakdown,resumed).earnedSouls==count and resumed.souls==5+count)
    local cinematic=Reward.newAnimation(result.breakdown,result)
    Reward.update(cinematic,10)
    assert(cinematic.finished and cinematic.soulsCollected==count and cinematic.soulTotal==5+count)
    local fast=Reward.newAnimation(result.breakdown,result);Reward.finishImmediately(fast)
    assert(fast.soulTotal==5+count and fast.soulsCollected==count)
end
local bossGame=game();bossGame.monster={hp=0,isBoss=true};bossGame.souls=7
Souls.awardKills(bossGame);assert(bossGame.souls==11)
assert(forced(bossGame,"gold_bonus").earnedSouls==4 and bossGame.souls==11)
assert(skipped.earnedSouls==0)
-- Exercise the independent supply roll without changing original loot odds.
local oldChance=C.supplies.normalChance;C.supplies.normalChance=1
local supplies=game();local drops=Reward.begin(Reward.calculate(blind,supplies),supplies)
assert(#drops.loot==2 and drops.loot[2].source=="TIẾP TẾ")
C.supplies.normalChance=oldChance
print("Reward ceremony smoke passed: loot, seven supplies, per-enemy souls, bosses, skip, RNG, save/load, capacity, packs, animation")

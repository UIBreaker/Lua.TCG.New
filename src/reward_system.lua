local Inventory = require("src.inventory")
local UI = require("src.ui")
local Sound = require("src.sound")
local Deities = require("src.deities")
local Visual = require("config.visual_config")

local RewardSystem = {}

-- Calculate cash out breakdown from the 5 sources
function RewardSystem.calculate(blind, gameState, wasSkipped)
    local wasSkip = (wasSkipped == true)
    local basePayout = 0
    if not wasSkip and blind then
        basePayout = blind.baseReward or (blind.type == "boss" and 5 or (blind.type == "big" and 4 or 3))
    end

    -- 1. Unused Hands (+1$ each)
    local handsLeft = (not wasSkip and (gameState.handsRemaining or 0)) or 0
    local unusedHandsBonus = handsLeft * 1

    -- 2. Interest (+1$ per 5$ stored, max 3$ default or 5$ with Seed Money voucher)
    -- Trần Lãi Siêu Việt: Gilded Conclave gets +1$ per 4$ stored with NO CAP!
    local isGilded = (gameState.selectedFaction == "diamonds" or gameState.selectedFaction == "gilded_conclave" or gameState.isGildedConclave == true)
    local maxInt = gameState.maxInterest or 3
    if gameState.vouchers and (gameState.vouchers["v_interest"] or gameState.vouchers["seed_money"]) then
        maxInt = math.max(maxInt, 5)
    end
    local currentGold = gameState.gold or 0
    local interestBonus
    if isGilded then
        interestBonus = math.floor(currentGold / 4)
    else
        interestBonus = math.min(maxInt, math.floor(currentGold / 5))
    end

    -- 3. Deities onRoundWin Bonuses (Use cached from main.lua if available to prevent double execution)
    local deityBonus = 0
    local deityDetails = {}
    if not wasSkip then
        if gameState.lastRoundDeityRewards then
            deityBonus = gameState.lastRoundDeityRewards.bonusGold or 0
            deityDetails = gameState.lastRoundDeityRewards.details or {}
        elseif gameState.deities then
            local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(gameState) or 10
            for di = 1, maxDeiSlots do
                local d = gameState.deities[di]
                if d then
                    local effectiveDeity = Deities.resolveDeity and Deities.resolveDeity(gameState.deities, di) or d
                    if effectiveDeity and effectiveDeity.onRoundWin then
                        local r = effectiveDeity.onRoundWin(gameState, effectiveDeity)
                        r = Deities.scaleEffect(effectiveDeity, r)
                        if r and r.addGold and r.addGold > 0 then
                            deityBonus = deityBonus + r.addGold
                            table.insert(deityDetails, {
                                slotIndex = di,
                                name = d.name,
                                amount = r.addGold,
                                message = r.message or ("+$" .. r.addGold .. " từ " .. d.name),
                            })
                        end
                    end
                end
            end
        end
    end

    -- Subtotal of items 1-4
    local subtotal = basePayout + unusedHandsBonus + interestBonus + deityBonus

    -- 4. Valoria Faction Passive: +25% Gold (math.ceil(subtotal * 0.25))
    local factionBonus = 0
    local isValoria = (gameState.selectedFaction == "valoria" or gameState.selectedSuit == "valoria")
    if isValoria and subtotal > 0 then
        factionBonus = math.ceil(subtotal * 0.25)
    end

    local totalGold = subtotal + factionBonus

    return {
        blind = blind,
        wasSkipped = wasSkip,
        tag = wasSkip and blind and blind.tag,
        basePayout = basePayout,
        handsLeft = handsLeft,
        unusedHandsBonus = unusedHandsBonus,
        currentGold = currentGold,
        maxInterest = maxInt,
        interestBonus = interestBonus,
        isGilded = isGilded,
        deityBonus = deityBonus,
        deityDetails = deityDetails,
        subtotal = subtotal,
        isValoria = isValoria,
        factionBonus = factionBonus,
        totalGold = totalGold,
    }
end

local Rng = require("src.rng")
local Deck = require("src.deck")
local Shop = require("src.shop")
local Run = require("src.run_manager")
local Config = require("config.reward_loot")
RewardSystem.config = Config

local function copy(t)
    local out = {}
    for k, v in pairs(t or {}) do out[k] = v end
    return out
end

-- One selection per roll, including arbitrary non-normalized weights.
function RewardSystem.weighted(entries, random, modifier)
    local total, weights = 0, {}
    for i, entry in ipairs(entries) do
        local weight = math.max(0, modifier and modifier(entry) or entry.weight or 0)
        weights[i], total = weight, total + weight
    end
    if total <= 0 then return "gold_bonus" end
    local value = (random or Rng.random)() * total
    for i, entry in ipairs(entries) do
        value = value - weights[i]
        if value < 0 then return entry.id end
    end
    return entries[#entries].id
end

local function fallback(reward, reason)
    reward.type, reward.packType, reward.card, reward.opening = "GOLD", nil, nil, nil
    reward.amount, reward.name, reward.rarity = Config.fallbackGold, "VÀNG BÙ", "common"
    reward.metadata = {reason = reason}
    return reward
end

local rollTable
local function createReward(id, game, source, depth)
    local reward = copy(Config.definitions[id] or Config.definitions.gold_bonus)
    reward.id, reward.source, reward.amount = id, source, 1
    if reward.type == "GOLD" then
        reward.amount = Rng.random(Config.goldBonus[1], Config.goldBonus[2])
    elseif reward.type == "PLAYING_CARD" then
        reward.card = Deck.newCard(Rng.random(2, 14), Deck.SUIT_ORDER[Rng.random(#Deck.SUIT_ORDER)])
        reward.name = reward.card.rankName .. reward.card.suitSymbol
    elseif reward.packType then
        if reward.packType == "buffoon" and Deities.getCount(game.deities or {}) >= Deities.getMaxSlots(game) then
            return fallback(reward, "Không còn ô SPN trống")
        end
        local pack
        for _, item in ipairs(Shop.PACK_CATALOG) do
            if item.packType == reward.packType then pack = copy(item); break end
        end
        if not pack then return fallback(reward, "Gói không còn hợp lệ") end
        if id == "itm_pack" then
            pack.name = reward.name
            pack.desc = "Mở 3 Trang Bị Cơ Bản, chọn 1 để gắn vào bài."
        end
        pack.cost, pack.category, pack.rewardPack = 0, "pack", true
        reward.opening = Shop.openPack(pack, game)
        if #reward.opening.cards == 0 then return fallback(reward, "Không còn nội dung gói hợp lệ") end
    elseif reward.type == "CONSUMABLE" then
        if reward.consumableId then
            local item = reward.consumableId == "soul_reaper" and Shop.destructionItem() or Shop.healingItem(nil, reward.consumableId)
            reward.card = item.consumable
        else
            local options = reward.consumable == "evolution" and {Run.createEvolutionCard()} or {Run.createSpeedSingleCard(), Run.createSpeedTeamCard()}
            reward.card = options[Rng.random(#options)]
        end
        reward.name = reward.card.name
        if #(game.consumables or {}) >= Inventory.limit(game) then return fallback(reward, "Ô tiêu hao đã đầy") end
    elseif reward.type == "CHEST" then
        if depth >= 2 then return fallback(reward, "Giới hạn rương lồng nhau") end
        reward.children = rollTable(reward.tableId, game, "RƯƠNG", depth + 1)
    end
    return reward
end

rollTable = function(tableId, game, source, depth, modifier)
    local tableData = Config.tables[tableId] or Config.tables.normal_enemy
    local rewards = {}
    for _ = 1, Rng.random(tableData.rolls[1], tableData.rolls[2]) do
        local id = RewardSystem.weighted(tableData.entries, nil, modifier)
        rewards[#rewards + 1] = createReward(id, game, source, depth or 0)
    end
    return rewards
end

local function visit(rewards, fn)
    for _, reward in ipairs(rewards or {}) do
        if reward.children then visit(reward.children, fn) else fn(reward) end
    end
end

-- The transaction is committed before presentation; animation never grants loot.
function RewardSystem.begin(breakdown, game, context)
    if game.pendingVictoryReward then return game.pendingVictoryReward end
    context = context or {}
    local boss = (breakdown.blind and breakdown.blind.type == "boss") or (game.monster and game.monster.isBoss)
    if boss and not breakdown.wasSkipped then game.pendingSoulShop = true end
    local bossData = game.monster and game.monster.bossData or {}
    local key = bossData.id or (breakdown.blind and breakdown.blind.debuff and breakdown.blind.debuff.id)
    local tableId = context.lootTableId or (breakdown.blind and breakdown.blind.lootTableId)
        or bossData.lootTableId or (boss and Config.bossOverrides[key]) or (boss and "boss" or "normal_enemy")
    local modifier = context.weightModifier or function(entry)
        local def = Config.definitions[entry.id]
        local pity = Config.pity
        return entry.weight + (pity.enabled and def and def.packType and (game.rewardPackDrought or 0) >= pity.after and pity.extraPackWeight or 0)
    end
    local result = {breakdown = breakdown, tableId = tableId, loot = {}, bonusGold = 0, claimed = false}
    if not breakdown.wasSkipped then
        result.loot = rollTable(tableId, game, boss and "BOSS" or "VICTORY", 0, modifier)
        if not context.lootTableId and Rng.random() < (boss and Config.supplies.bossChance or Config.supplies.normalChance) then
            result.loot[#result.loot + 1] = createReward(RewardSystem.weighted(Config.supplies.entries), game, "TIẾP TẾ", 0)
        end
    end
    result.earnedSouls = 0
    if not breakdown.wasSkipped then
        local _, total = require("src.souls").awardKills(game, true)
        result.earnedSouls = total
        if not game.monster then
            result.earnedSouls = boss and 4 or 1
            game.souls = (game.souls or 0) + result.earnedSouls
        end
    end
    result.soulsBefore = (game.souls or 0) - result.earnedSouls
    local hadPack = false
    game.rewardPacks = game.rewardPacks or {}
    game.consumables = game.consumables or {}
    visit(result.loot, function(reward)
        if reward.type == "CONSUMABLE" and #game.consumables >= Inventory.limit(game) then fallback(reward, "Ô tiêu hao đã đầy") end
        if reward.type == "GOLD" then
            result.bonusGold = result.bonusGold + reward.amount
        elseif reward.type == "PLAYING_CARD" then
            Deck.addCardToDeck(game, reward.card)
        elseif reward.type == "CONSUMABLE" then
            table.insert(game.consumables, reward.card)
        elseif reward.opening then
            table.insert(game.rewardPacks, reward.opening)
            hadPack = true
        end
        reward.claimed = true
    end)
    result.earnedGold = breakdown.totalGold + result.bonusGold
    game.gold = (game.gold or 0) + result.earnedGold
    result.claimed = true
    game.pendingVictoryReward = result
    if not breakdown.wasSkipped then game.rewardPackDrought = hadPack and 0 or (game.rewardPackDrought or 0) + 1 end
    return result
end

-- Saved candidates retain identity/rarity; restore SPN callbacks from the catalog.
function RewardSystem.openNextPack(game, shop)
    if shop.currentPackOpening then return false end
    local opening = game.rewardPacks and game.rewardPacks[1]
    if not opening then return false end
    if opening.pack.packType == "buffoon" and Deities.getCount(game.deities or {}) >= Deities.getMaxSlots(game) then
        game.gold = (game.gold or 0) + Config.fallbackGold
        table.remove(game.rewardPacks, 1)
        Sound.play("reward_gold_total")
        return true, "SPN đã đầy: +$" .. Config.fallbackGold .. " vàng bù"
    end
    if opening.pack.packType == "buffoon" then
        for _, card in ipairs(opening.cards) do
            for k, v in pairs(Deities.CATALOG[card.id] or {}) do
                if type(v) == "function" then card[k] = v end
            end
        end
    end
    opening.animationTimer = 0
    shop.currentPackOpening = opening
    Sound.play("pack_open")
    return true
end

function RewardSystem.completePack(game, shop, opening)
    if opening and opening.pack.rewardPack and not shop.currentPackOpening and game.rewardPacks and game.rewardPacks[1] == opening then
        table.remove(game.rewardPacks, 1)
        return true
    end
    return false
end

local function setState(anim, state)
    anim.state, anim.phaseTime = state, 0
end

function RewardSystem.newAnimation(breakdown, result)
    result = result or {loot = {}, bonusGold = 0, earnedGold = breakdown.totalGold}
    local lines = {
        {label = breakdown.wasSkipped and "ĐÃ BỎ QUA ẢI" or "THƯỞNG TRẬN", valNum = breakdown.basePayout},
        {label = "LƯỢT ĐÁNH CÒN DƯ", valNum = breakdown.unusedHandsBonus},
        {label = "TIỀN LÃI", valNum = breakdown.interestBonus, interest = true},
    }
    if breakdown.deityBonus > 0 then lines[#lines + 1] = {label = "THƯỞNG HỘ LINH", valNum = breakdown.deityBonus} end
    if breakdown.factionBonus > 0 then lines[#lines + 1] = {label = "VIỆN TRỢ VALORIA", valNum = breakdown.factionBonus} end
    local slots = {}
    for _, reward in ipairs(result.loot) do
        slots[#slots + 1] = {reward = reward, chest = reward.type == "CHEST"}
        local parentIndex = #slots
        for _, child in ipairs(reward.children or {}) do slots[#slots + 1] = {reward = child, parent = reward, parentIndex = parentIndex} end
    end
    return {breakdown = breakdown, result = result, lines = lines, slots = slots, coins = {},
        state = "ENTER", timer = 0, phaseTime = 0, revealedCount = 0, revealedLoot = 0,
        displayTotal = 0, walletTotal = breakdown.currentGold, totalRevealed = false,
        pulse = 0, finished = false, buttonActive = false, visualSeed = 17, coinsSpawned = 0,
        sparks = {}, flares = {}, goldFlare = 0,
        soulsCollected = 0, soulTotal = result.soulsBefore or 0, soulFlare = 0}
end

-- Local presentation RNG: effects cannot advance the saved gameplay generator.
local function visualRandom(anim)
    anim.visualSeed = (anim.visualSeed * 48271) % 2147483647
    return anim.visualSeed / 2147483647
end

local function burst(anim, anchor, color, count, power)
    if not Visual.effects.particles then return end
    local limit = Config.presentation.maxSparks
    for _ = 1, math.min(count, math.max(0, limit - #anim.sparks)) do
        local angle = visualRandom(anim) * math.pi * 2
        local speed = (35 + visualRandom(anim) * 85) * power
        anim.sparks[#anim.sparks + 1] = {anchor = anchor, color = color, x = 0, y = 0,
            vx = math.cos(angle) * speed, vy = math.sin(angle) * speed - 22,
            age = 0, life = 0.32 + visualRandom(anim) * 0.38, size = 1 + visualRandom(anim) * 1.5}
    end
end

local function updateSparks(anim, dt)
    anim.goldFlare = math.max(0, anim.goldFlare - dt)
    for i = #anim.sparks, 1, -1 do
        local p = anim.sparks[i]
        p.age = p.age + dt
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt
        p.vy = p.vy + 45 * dt
        if p.age >= p.life then table.remove(anim.sparks, i) end
    end
end

local function spawnCoins(anim, amount, row, interest)
    if amount <= 0 then return end
    local budget = math.max(1, math.floor(Config.maxCoins / (#anim.lines + #anim.slots + 1)))
    local count = math.min(amount, budget, math.max(0, Config.maxCoins - anim.coinsSpawned))
    if count == 0 then
        if #anim.coins > 0 then anim.coins[#anim.coins].amount = anim.coins[#anim.coins].amount + amount
        else
            anim.displayTotal = anim.displayTotal + amount
            anim.walletTotal = anim.breakdown.currentGold + anim.displayTotal
            anim.pulse = 0.07
        end
        return
    end
    for i = 1, count do
        local r = visualRandom(anim)
        local batch = math.floor(amount / count) + (i <= amount % count and 1 or 0)
        local startY = -35 + (row - 1) * 29
        local trail = {}
        for _ = 1, Config.presentation.trailPoints do trail[#trail + 1] = {x = -219, y = startY} end
        anim.coins[#anim.coins + 1] = {type = "reward_coin", x = -235 + r * 32,
            y = startY, floorY = startY + 40, vx = 80 + r * 180, vy = -150 - r * 100,
            rotation = r * 6.28, angularVelocity = 4 + r * 9, age = -i * 0.018,
            amount = batch, interest = interest, phase = "SPAWN", depth = 0.7 + r * 0.5,
            trail = trail, trailHead = 1, trailTime = 0}
        anim.coinsSpawned = anim.coinsSpawned + 1
    end
    Sound.play("reward_coin_spawn", 0.96 + visualRandom(anim) * 0.08)
end

local function updateCoins(anim, dt)
    for i = #anim.coins, 1, -1 do
        local coin = anim.coins[i]
        coin.age = coin.age + dt
        if coin.age >= 0 then
            coin.trailTime = coin.trailTime + dt
            if coin.trailTime >= 0.025 then
                local point = coin.trail[coin.trailHead]
                point.x, point.y = coin.x, coin.y
                coin.trailHead = coin.trailHead % #coin.trail + 1
                coin.trailTime = 0
            end
            coin.rotation = coin.rotation + coin.angularVelocity * dt
            if coin.phase == "SPAWN" then
                coin.vy = coin.vy + 1500 * dt
                coin.x, coin.y = coin.x + coin.vx * dt, coin.y + coin.vy * dt
                if coin.y >= coin.floorY and coin.vy > 0 then
                    coin.y, coin.vy, coin.phase = coin.floorY, -coin.vy * 0.27, "BOUNCE"
                    coin.bouncedAt = coin.age
                    Sound.play("reward_coin_land", 0.94 + visualRandom(anim) * 0.1)
                end
            elseif coin.phase == "BOUNCE" then
                coin.vy = coin.vy + 1200 * dt
                coin.x, coin.y = coin.x + coin.vx * dt, coin.y + coin.vy * dt
                if coin.age - coin.bouncedAt >= 0.1 then coin.phase = "MAGNETIZE" end
            else
                local blend = math.min(1, dt * 15)
                coin.x, coin.y = coin.x * (1 - blend), coin.y * (1 - blend)
                if math.abs(coin.x) + math.abs(coin.y) < 5 then
                    anim.displayTotal = anim.displayTotal + coin.amount
                    anim.walletTotal = anim.breakdown.currentGold + anim.displayTotal
                    anim.pulse = 0.07
                    burst(anim, "gold", {1, 0.82, 0.38}, 2, 0.4)
                    Sound.play("reward_coin_collect", 0.98 + (anim.displayTotal % 5) * 0.025)
                    table.remove(anim.coins, i)
                end
            end
        end
    end
end

local function revealSlot(anim, index)
    local slot = anim.slots[index]
    slot.revealedAt, anim.revealedLoot = anim.timer, index
    local reward = slot.reward
    local rarity = Config.rarities[reward.rarity] or Config.rarities.common
    anim.flares[index] = anim.timer
    if rarity.strength >= 3 then anim.highlightSlot, anim.highlightAt = index, anim.timer end
    burst(anim, index, rarity.color, 6 + rarity.strength * 3, 0.7 + rarity.strength * 0.16)
    Sound.play(slot.chest and "reward_chest_open" or (rarity.strength >= 3 and "reward_rare_reveal" or "reward_loot_reveal"))
    if reward.type == "GOLD" then spawnCoins(anim, reward.amount, #anim.lines + 1) end
end

function RewardSystem.update(anim, dt)
    if not anim then return end
    -- Fixed steps keep physics and transitions stable through slow frames.
    anim.accumulator = (anim.accumulator or 0) + dt
    while anim.accumulator >= 1 / 120 do
        local step = 1 / 120
        anim.accumulator = anim.accumulator - step
        anim.timer, anim.phaseTime = anim.timer + step, anim.phaseTime + step
        anim.pulse = math.max(0, anim.pulse - step * 0.55)
        anim.soulFlare = math.max(0, anim.soulFlare - step)
        updateCoins(anim, step)
        updateSparks(anim, step)
        local state = anim.state
        if state == "ENTER" and anim.phaseTime >= 0.12 then setState(anim, "GOLD_BREAKDOWN")
        elseif state == "GOLD_BREAKDOWN" and anim.phaseTime >= Config.rowInterval then
            anim.revealedCount = anim.revealedCount + 1
            local line = anim.lines[anim.revealedCount]
            line.revealedAt = anim.timer
            spawnCoins(anim, line.valNum, anim.revealedCount, line.interest)
            anim.phaseTime = 0
            if anim.revealedCount == #anim.lines then setState(anim, "COIN_RAIN") end
        elseif state == "COIN_RAIN" and #anim.coins == 0 then
            anim.totalRevealed, anim.pulse = true, 0.16
            anim.goldFlare = Config.presentation.flareDuration
            burst(anim, "gold", {1, 0.80, 0.34}, 20, 1)
            Sound.play("reward_gold_total")
            setState(anim, "GOLD_SETTLE")
        elseif state == "GOLD_SETTLE" and anim.phaseTime >= 0.15 then
            setState(anim, (anim.result.earnedSouls or 0) > 0 and "SOUL_GATHER" or "LOOT_PREPARE")
        elseif state == "SOUL_GATHER" then
            local earned = anim.result.earnedSouls or 0
            local collected = math.min(earned, math.max(0, math.floor((anim.phaseTime - 0.35) / 0.12) + 1))
            if collected > anim.soulsCollected then
                anim.soulsCollected, anim.soulFlare = collected, 0.45
                anim.soulTotal = (anim.result.soulsBefore or 0) + collected
                Sound.play("reward_rare_reveal", 0.9 + collected * 0.06)
            end
            if anim.phaseTime >= 0.65 + earned * 0.12 then setState(anim, "LOOT_PREPARE") end
        elseif state == "LOOT_PREPARE" then
            if anim.revealedLoot == #anim.slots then setState(anim, "SUMMARY")
            else
                local slot = anim.slots[anim.revealedLoot + 1]
                local rarity = Config.rarities[slot.reward.rarity] or Config.rarities.common
                setState(anim, rarity.strength >= 3 and "RARE_REVEAL" or "LOOT_REVEAL")
            end
        elseif (state == "LOOT_REVEAL" or state == "RARE_REVEAL") then
            local slot = anim.slots[anim.revealedLoot + 1]
            local wait = Config.lootInterval + (state == "RARE_REVEAL" and Config.rarePause or 0) + (slot.chest and 0.25 or 0)
            if anim.phaseTime >= wait then revealSlot(anim, anim.revealedLoot + 1); setState(anim, "LOOT_PREPARE") end
        elseif state == "SUMMARY" and #anim.coins == 0 and anim.phaseTime >= 0.24 then
            anim.displayTotal = anim.result.earnedGold
            anim.walletTotal = anim.breakdown.currentGold + anim.displayTotal
            anim.finished, anim.buttonActive = true, true
        end
    end
end

function RewardSystem.finishImmediately(anim)
    if not anim or anim.finished then return end
    anim.coins = {}
    anim.sparks, anim.flares, anim.goldFlare = {}, {}, 0
    anim.revealedCount, anim.revealedLoot = #anim.lines, #anim.slots
    for _, slot in ipairs(anim.slots) do slot.revealedAt = anim.timer - 1 end
    anim.totalRevealed, anim.finished, anim.buttonActive = true, true, true
    anim.displayTotal = anim.result.earnedGold
    anim.soulsCollected = anim.result.earnedSouls or 0
    anim.soulTotal = (anim.result.soulsBefore or 0) + anim.soulsCollected
    anim.soulFlare = 0
    anim.walletTotal, anim.pulse = anim.breakdown.currentGold + anim.displayTotal, 0.16
    setState(anim, "SUMMARY")
    Sound.play("reward_gold_total")
end

local coinSprite, chestArt, glowMesh
local function softGlow(cx, cy, rx, ry, color, alpha)
    local g = love.graphics
    if not glowMesh then
        local vertices = {{0, 0, 0.5, 0.5, 1, 1, 1, 1}}
        for i = 0, 32 do
            local angle = i * math.pi * 2 / 32
            vertices[#vertices + 1] = {math.cos(angle), math.sin(angle), 0, 0, 1, 1, 1, 0}
        end
        glowMesh = g.newMesh(vertices, "fan", "static")
    end
    g.setColor(color[1], color[2], color[3], alpha)
    g.draw(glowMesh, cx, cy, 0, rx, ry)
end
local function getCoinSprite()
    if coinSprite then return coinSprite end
    coinSprite = love.graphics.newCanvas(96, 96)
    love.graphics.push("all")
    love.graphics.setCanvas(coinSprite)
    love.graphics.clear(0, 0, 0, 0)
    local g = love.graphics
    g.origin()
    g.setScissor()
    g.setShader()
    g.scale(3)
    g.setColor(0.22, 0.11, 0.025); g.circle("fill", 16, 17.5, 13)
    g.setColor(0.69, 0.39, 0.07); g.circle("fill", 16, 16.5, 13)
    g.setColor(1, 0.78, 0.25); g.circle("fill", 16, 15, 12.5)
    g.setColor(1, 0.93, 0.60); g.setLineWidth(1); g.circle("line", 16, 15, 11)
    g.setColor(0.77, 0.47, 0.10); g.circle("fill", 16, 15, 8.7)
    g.setColor(0.96, 0.68, 0.19); g.circle("fill", 16, 14.6, 8)
    g.setFont(UI.fonts.small); g.setColor(0.42, 0.23, 0.045); g.printf("$", 2, 6.2, 28, "center")
    g.setColor(1, 0.96, 0.72); g.arc("line", "open", 16, 15, 11.2, -2.7, -0.8)
    g.setCanvas()
    g.pop()
    return coinSprite
end

local function inside(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function RewardSystem.draw(anim, width, height, mx, my, buttons)
    if not anim then return end
    local g = love.graphics
    local w, h = 1040, 660
    local x, y = (width - w) / 2, (height - h) / 2
    local gold = {1, 0.80, 0.39}
    local muted = {0.57, 0.65, 0.73}
    local sprite = getCoinSprite()
    local function coin(cx, cy, size, rotation, spin)
        g.setColor(1, 1, 1)
        g.draw(sprite, cx, cy, rotation or 0, size / 96 * (spin or 1), size / 96, 48, 48)
    end
    local function panel(px, py, pw, ph, warm)
        g.setColor(warm and 0.11 or 0.055, warm and 0.095 or 0.075, warm and 0.065 or 0.105, 1)
        UI.drawRoundedRect("fill", px, py, pw, ph, 12)
        g.setColor(warm and 0.64 or 0.22, warm and 0.47 or 0.29, warm and 0.21 or 0.37, warm and 0.6 or 0.5)
        g.setLineWidth(1); UI.drawRoundedRect("line", px, py, pw, ph, 12)
    end
    g.push("all")
    g.setColor(0.008, 0.016, 0.028, Visual.reward.veil); g.rectangle("fill", 0, 0, width, height)
    -- Soft stepped halos and a recessed frame keep the ceremony above the board.
    for i = 5, 1, -1 do
        g.setColor(0, 0, 0, 0.07); UI.drawRoundedRect("fill", x - i * 3, y + i * 2, w + i * 6, h + i * 4, 20)
    end
    g.setColor(0.04, 0.057, 0.083, Visual.reward.panelAlpha); UI.drawRoundedRect("fill", x, y, w, h, 18)
    g.setColor(0.62, 0.47, 0.23, 0.55); g.setLineWidth(1); UI.drawRoundedRect("line", x, y, w, h, 18)
    g.setColor(0.97, 0.76, 0.35, 0.8); g.rectangle("fill", x + 32, y, 90, 2)
    -- Quiet moving dust and broad light shafts, behind the readable UI.
    if Visual.effects.particles then
        for i = 1, Config.presentation.ambience do
            local px = x + 25 + (i * 79.31) % (w - 50)
            local py = y + 18 + (i * 53.73 - anim.timer * (6 + i % 4)) % (h - 40)
            local alpha = 0.08 + 0.05 * math.sin(anim.timer * 1.2 + i)
            g.setColor(1, 0.83, 0.48, alpha); g.circle("fill", px, py, i % 3 == 0 and 1.5 or 0.8)
        end
    end
    g.setColor(0.85, 0.68, 0.36, 0.025)
    g.polygon("fill", x + w * 0.64, y + 4, x + w * 0.77, y + 4, x + w * 0.48, y + 330, x + w * 0.37, y + 330)
    g.polygon("fill", x + w * 0.88, y + 4, x + w * 0.93, y + 4, x + w * 0.68, y + 330, x + w * 0.61, y + 330)
    -- Victory seal, drawn as geometry to stay sharp at every resolution.
    local cx, cy = x + 62, y + 61
    g.setColor(0.98, 0.73, 0.27, 0.09); g.circle("fill", cx, cy, 30)
    g.setColor(0.88, 0.68, 0.32, 0.55); g.circle("line", cx, cy, 29)
    for i = 1, 12 do
        local angle = i * math.pi / 6 + anim.timer * 0.035
        g.setColor(1, 0.79, 0.34, 0.13)
        g.line(cx + math.cos(angle) * 32, cy + math.sin(angle) * 32, cx + math.cos(angle) * 41, cy + math.sin(angle) * 41)
    end
    g.setColor(gold); g.polygon("fill", cx - 15, cy - 9, cx - 7, cy - 2, cx, cy - 15, cx + 7, cy - 2, cx + 15, cy - 9, cx + 12, cy + 10, cx - 12, cy + 10)
    g.setColor(0.99, 0.88, 0.59); g.rectangle("fill", cx - 11, cy + 13, 22, 3, 1)
    g.setFont(UI.fonts.tiny); g.setColor(muted); g.print("KẾT QUẢ TRẬN ĐẤU", x + 110, y + 24)
    g.setFont(UI.fonts.title); g.setColor(gold)
    local entrance = 1 - math.max(0, 1 - anim.timer / 0.35) ^ 3
    g.push(); g.translate(x + 108, y + 43 + (1 - entrance) * 8); g.scale(0.96 + entrance * 0.04)
    g.print(anim.breakdown.wasSkipped and "QUÂN LƯƠNG" or "CHIẾN THẮNG", 0, 0); g.pop()
    local blind = anim.breakdown.blind or {}
    g.setFont(UI.fonts.small); g.setColor(UI.COLORS.textLight)
    local encounterTitle = (blind.title or "ẢI CHIẾN THẮNG") .. "  /  " .. (blind.name or "")
    local titleLimit = 60
    while UI.fonts.small:getWidth(encounterTitle) > w - 614 and titleLimit > 8 do
        titleLimit = titleLimit - 1
        encounterTitle = UI.truncateUtf8((blind.title or "ẢI CHIẾN THẮNG") .. "  /  " .. (blind.name or ""), titleLimit)
    end
    g.printf(encounterTitle, x + 580, y + 38, w - 614, "right")
    g.setFont(UI.fonts.tiny); g.setColor(muted)
    g.printf(anim.finished and "PHẦN THƯỞNG ĐÃ ĐƯỢC CỘNG" or "ĐANG KIỂM KÊ PHẦN THƯỞNG", x + 580, y + 64, w - 614, "right")
    g.setColor(0.26, 0.32, 0.39, 0.45); g.line(x + 32, y + 99, x + w - 32, y + 99)

    local leftX, leftW = x + 32, 536
    local rightX, rightW = x + 586, 422
    panel(leftX, y + 118, leftW, 205)
    panel(rightX, y + 118, rightW, 141, true)
    panel(rightX, y + 269, rightW, 54)
    g.setFont(UI.fonts.tiny); g.setColor(muted); g.print("CHI TIẾT THƯỞNG", leftX + 20, y + 133)
    g.printf("XU VÀNG", leftX + leftW - 112, y + 133, 92, "right")
    local rowY = y + 160
    for i, line in ipairs(anim.lines) do
        local rowEntrance = line.revealedAt and math.min(1, (anim.timer - line.revealedAt) / 0.16) or 0
        local ry = rowY + (i - 1) * 29 + (1 - rowEntrance) * 4
        local revealed = i <= anim.revealedCount
        if revealed then
            g.setColor(line.interest and 0.13 or 0.11, line.interest and 0.32 or 0.16, line.interest and 0.23 or 0.22, 0.45)
            UI.drawRoundedRect("fill", leftX + 12, ry, leftW - 24, 26, 5)
        end
        g.setColor(revealed and gold or muted); g.circle("fill", leftX + 26, ry + 13, 2)
        g.setFont(UI.fonts.small); g.setColor(line.interest and revealed and {0.48, 0.89, 0.67} or revealed and UI.COLORS.textLight or muted)
        g.print(line.label, leftX + 40, ry + 5)
        if revealed then coin(leftX + leftW - 87, ry + 13, 21) end
        g.setFont(UI.fonts.regular); g.setColor(revealed and gold or muted)
        g.printf(revealed and "+" .. line.valNum or "—", leftX + leftW - 72, ry + 3, 50, "right")
        if revealed and inside(mx, my, leftX + 12, ry, leftW - 24, 26) then
            UI.descriptionCandidate = {hoverKey = line, name = line.label, desc = line.interest and (anim.breakdown.isGilded and "+1 xu mỗi 4 xu, không giới hạn." or "+1 xu mỗi 5 xu. Trần lãi: " .. anim.breakdown.maxInterest .. " xu" .. (anim.breakdown.interestBonus >= anim.breakdown.maxInterest and " · Lãi tối đa." or "")) or "Nguồn thưởng được cộng vào túi vàng khi kết thúc trận.", color = gold}
        end
    end
    local tx, ty = rightX + 114, y + 208
    softGlow(tx, ty, 83, 83, gold, 0.20)
    local flash = anim.goldFlare / Config.presentation.flareDuration
    g.setBlendMode("add")
    softGlow(tx, ty, 88, 88, gold, flash * 0.32)
    g.setColor(1, 0.83, 0.43, flash * 0.65); g.setLineWidth(1.5)
    g.circle("line", tx, ty, 45 + (1 - flash) * 45)
    g.setBlendMode("alpha")
    coin(tx, ty, 85)
    g.setFont(UI.fonts.tiny); g.setColor(gold); g.print("TỔNG XU NHẬN ĐƯỢC", rightX + 177, y + 139)
    g.push(); g.translate(rightX + 174, y + 162)
    local totalFont = UI.fonts.huge
    local totalScale = math.min(1, (rightW - 194) / math.max(1, totalFont:getWidth("+" .. anim.displayTotal)))
    g.scale((1 + anim.pulse) * totalScale)
    g.setFont(UI.fonts.huge); g.setColor(1, 0.87, 0.52)
    g.print("+" .. anim.displayTotal, 0, 0); g.pop()
    g.setFont(UI.fonts.tiny); g.setColor(muted)
    g.print("TÚI  " .. anim.breakdown.currentGold .. "  →  " .. anim.walletTotal, rightX + 179, y + 233)
    local soulColor = {0.38, 0.94, 0.88}
    local sx, sy = rightX + 35, y + 296
    local soulPulse = anim.soulFlare / 0.45
    softGlow(sx, sy, 32 + soulPulse * 12, 28 + soulPulse * 10, soulColor, 0.23 + soulPulse * 0.35)
    g.setColor(0.22, 0.68, 0.70, 0.7); g.circle("line", sx, sy, 18)
    g.setColor(soulColor); g.polygon("fill", sx, sy - 13, sx + 9, sy + 1, sx, sy + 12, sx - 9, sy + 1)
    g.setColor(0.87, 1, 0.97); g.ellipse("fill", sx - 2, sy - 2, 2.5, 5)
    g.setFont(UI.fonts.tiny); g.setColor(soulColor); g.print("LINH HỒN THU THẬP", rightX + 64, y + 279)
    g.setColor(muted); g.print("QUÁI +1  ·  BOSS +4", rightX + 64, y + 299)
    g.setFont(UI.fonts.medium); g.setColor(soulColor)
    g.printf("+" .. anim.soulsCollected, rightX + 244, y + 279, 60, "right")
    g.setFont(UI.fonts.tiny); g.setColor(UI.COLORS.textLight)
    g.printf("TỔNG " .. anim.soulTotal, rightX + 304, y + 298, 100, "right")
    if anim.state == "SOUL_GATHER" then
        -- Curved wisps converge on the crystal; tails fade without gameplay RNG.
        g.setBlendMode("add")
        for i = 1, anim.result.earnedSouls or 0 do
            local flight = math.max(0, math.min(1, (anim.phaseTime - (i - 1) * 0.12) / 0.35))
            if flight > 0 and flight < 1 then
                local px, py
                for j = 7, 0, -1 do
                    local t = math.max(0, flight - j * 0.035)
                    local ease = t * t * (3 - 2 * t)
                    local wx = sx - (1 - ease) * (310 + i * 26)
                    local wy = sy - (1 - ease) * 65 - math.sin(t * math.pi) * (45 + i * 12)
                    if px then
                        g.setColor(soulColor[1], soulColor[2], soulColor[3], (1 - j / 8) * 0.55)
                        g.setLineWidth(2 + (7 - j) * 0.4); g.line(px, py, wx, wy)
                    end
                    px, py = wx, wy
                end
                softGlow(px, py, 19, 19, soulColor, 0.55)
                g.setColor(0.8, 1, 0.95); g.circle("fill", px, py, 4)
            end
        end
        g.setBlendMode("alpha")
    end
    if inside(mx, my, rightX, y + 269, rightW, 54) then
        UI.descriptionCandidate = {hoverKey = anim.result, name = "LINH HỒN CHIẾN THẮNG", desc = "Mỗi quái thường: 1 linh hồn. Boss: 4 linh hồn.\nTrận này: " .. (anim.result.earnedSouls or 0) .. " linh hồn.\nDùng tại Chợ Linh Hồn; bỏ qua ải không nhận linh hồn.", color = soulColor}
    elseif inside(mx, my, rightX, y + 118, rightW, 141) then
        UI.descriptionCandidate = {hoverKey = anim, name = "TỔNG XU NHẬN ĐƯỢC", desc = "Thưởng bảo đảm: " .. anim.breakdown.totalGold .. " xu\nVàng thưởng từ chiến lợi phẩm: " .. anim.result.bonusGold .. " xu\nTổng cộng: " .. anim.result.earnedGold .. " xu. Tiền được cộng một lần; số dư bên dưới bao gồm tiền đang có.", color = gold}
    end
    for _, c in ipairs(anim.coins) do
        if c.age >= 0 then
            local tint = c.interest and {0.54, 0.95, 0.69} or gold
            if c.phase == "MAGNETIZE" and Visual.effects.particles then
                g.setBlendMode("add")
                local px, py = tx + c.x, ty + c.y
                for j = 1, #c.trail do
                    local point = c.trail[(c.trailHead - j - 1) % #c.trail + 1]
                    local alpha = (1 - j / (#c.trail + 1)) * 0.24
                    g.setColor(tint[1], tint[2], tint[3], alpha)
                    g.setLineWidth(4 * c.depth * (1 - j / (#c.trail + 1)))
                    g.line(px, py, tx + point.x, ty + point.y)
                    px, py = tx + point.x, ty + point.y
                end
                g.setBlendMode("alpha")
            end
            if c.phase ~= "MAGNETIZE" then
                local shadow = math.max(0.02, 0.15 - math.abs(c.y - c.floorY) / 600)
                g.setColor(0, 0, 0, shadow); g.ellipse("fill", tx + c.x, ty + c.floorY + 6, 12 * c.depth, 3)
            end
            softGlow(tx + c.x, ty + c.y, 21 * c.depth, 21 * c.depth, tint, 0.24)
            coin(tx + c.x, ty + c.y, 34 * c.depth, math.sin(c.rotation) * 0.24, 0.24 + math.abs(math.cos(c.rotation)) * 0.76)
            g.setColor(1, 0.96, 0.72, 0.6); g.circle("fill", tx + c.x - 4, ty + c.y - 7, 1.2 * c.depth)
        end
    end
    g.setFont(UI.fonts.medium); g.setColor(UI.COLORS.textLight); g.print("CHIẾN LỢI PHẨM", x + 32, y + 343)
    g.setFont(UI.fonts.tiny); g.setColor(muted)
    local highlight = anim.highlightSlot and anim.slots[anim.highlightSlot]
    if highlight and anim.timer - anim.highlightAt < 0.7 then
        local rarity = Config.rarities[highlight.reward.rarity] or Config.rarities.common
        g.setColor(rarity.color)
        g.printf("✦  " .. rarity.label .. "  ·  " .. highlight.reward.name, x + w - 522, y + 350, 490, "right")
    else
        g.printf(anim.finished and "ĐÃ THU THẬP  /  " .. #anim.slots .. " VẬT PHẨM" or "ĐANG MỞ PHẦN THƯỞNG", x + w - 332, y + 350, 300, "right")
    end
    local n = #anim.slots
    local slotW = math.min(188, (w - 80) / math.max(1, n) - 12)
    local slotH, gap = 190, 12
    local startX = x + (w - (n * (slotW + gap) - gap)) / 2
    if n == 0 then
        g.setColor(UI.COLORS.textMuted); g.printf(anim.breakdown.wasSkipped and "Đã nhận phần thưởng bỏ qua ải" or "Không có chiến lợi phẩm thêm", x, y + 447, w, "center")
    end
    for i, slot in ipairs(anim.slots) do
        local reward = slot.reward
        local rarity = Config.rarities[reward.rarity] or Config.rarities.common
        local sx, sy = startX + (i - 1) * (slotW + gap), y + 364
        local revealed = i <= anim.revealedLoot
        local active = i == anim.revealedLoot + 1 and (anim.state == "RARE_REVEAL" or anim.state == "LOOT_REVEAL")
        local progress = revealed and math.min(1, (anim.timer - (slot.revealedAt or 0)) / 0.24) or 0
        local isHovered = revealed and inside(mx, my, sx, sy, slotW, slotH)
        local flareAge = anim.timer - (anim.flares[i] or -100)
        local flare = math.max(0, 1 - flareAge / Config.presentation.flareDuration)
        panel(sx, sy, slotW, slotH)
        g.setBlendMode("add")
        if active or flare > 0 then
            local intensity = active and (0.45 + math.sin(anim.phaseTime * 12) * 0.08) or flare
            softGlow(sx + slotW / 2, sy + 90, 82, 86, rarity.color, intensity * 0.32)
            g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], intensity * 0.07)
            g.polygon("fill", sx + slotW * 0.4, sy + 90, sx + slotW * 0.6, sy + 90, sx + slotW * 0.85, sy - 24, sx + slotW * 0.15, sy - 24)
            if flare > 0 then
                local radius = 45 + (1 - flare) * 65
                g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], flare * 0.55)
                g.setLineWidth(1); g.ellipse("line", sx + slotW / 2, sy + 95, radius, radius * 0.4)
                softGlow(sx + slotW / 2, sy + 89, 62 + (1 - flare) * 18, 74, rarity.color, flare * 0.38)
                g.setColor(1, 0.95, 0.80, flare * 0.75)
                g.line(sx + slotW / 2 - 58, sy + 75, sx + slotW / 2 + 58, sy + 75)
                for ray = 1, rarity.strength * 3 do
                    local angle = ray * math.pi * 2 / (rarity.strength * 3)
                    g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], flare * 0.25)
                    g.line(sx + slotW / 2 + math.cos(angle) * 24, sy + 72 + math.sin(angle) * 24,
                        sx + slotW / 2 + math.cos(angle) * radius, sy + 72 + math.sin(angle) * radius)
                end
            end
        end
        g.setBlendMode("alpha")
        g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], active and 0.18 + math.sin(anim.timer * 16) * 0.06 or 0.07)
        UI.drawRoundedRect("fill", sx - 4, sy - 4, slotW + 8, slotH + 8, 12)
        g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], revealed and 0.9 or active and 0.7 or 0.2)
        g.setLineWidth(1); UI.drawRoundedRect("line", sx, sy, slotW, slotH, 12)
        g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], revealed and 0.85 or 0.25)
        g.rectangle("fill", sx + 14, sy, slotW - 28, 2)
        local chestDrop = slot.chest and active and math.max(0, 1 - anim.phaseTime / 0.18) or 0
        local chestShake = slot.chest and active and anim.phaseTime > 0.18 and math.sin(anim.phaseTime * 65) * 2 or 0
        g.push(); g.translate(sx + slotW / 2 + chestShake + (slot.parentIndex and revealed and (slot.parentIndex - i) * (slotW + gap) * (1 - progress) ^ 3 or 0),
            sy + 78 - chestDrop * 45 - (1 - progress) * (revealed and (slot.parent and 42 or 12) or 0) - (isHovered and 5 or 0))
        if isHovered then
            g.scale(1.05); g.rotate(math.max(-0.035, math.min(0.035, (mx - sx - slotW / 2) / slotW * 0.08)))
        end
        g.scale(revealed and not slot.chest and math.max(0.08, math.abs(math.cos(progress * math.pi))) or 1, 1)
        local art
        if slot.chest and (active or revealed) then
            if not chestArt then chestArt = g.newImage("assets/scene/treasure_chest.png") end
            art = chestArt
        elseif revealed and progress >= 0.5 then
            if reward.packType then art = UI.getPackImage(reward.packType)
            elseif reward.card and reward.type == "PLAYING_CARD" then
                UI.drawCardFace(reward.card, -36, -54, 72, 108, false)
            elseif reward.card then
                require("ui.card_surfaces").fullReward(reward.card, -36, -54, 72, 108, nil, false)
            else
                coin(0, 0, 67)
            end
        else
            UI.drawCardBack(-36, -54, 72, 108)
            g.setFont(UI.fonts.large); g.setColor(rarity.color); g.printf("?", -slotW / 2, -18, slotW, "center")
        end
        if art then
            g.setColor(1, 1, 1)
            local iw, ih = art:getDimensions()
            if reward.packType then
                UI.CardFrame.image(art, -36, -54, 72, 108)
                UI.CardFrame.draw(-36, -54, 72, 108, nil, 1, reward)
            else
                local artScale = math.min(slotW * 0.72 / iw, 100 / ih)
                g.draw(art, 0, -2, slot.chest and math.sin(anim.timer * 5) * (1 - progress) * 0.05 or 0, artScale, artScale, iw / 2, ih / 2)
                if flare > 0 then
                    g.setBlendMode("add"); g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], flare * 0.16)
                    g.polygon("fill", -9, -4, 9, -4, 32 + flare * 10, -78, -32 - flare * 10, -78)
                    g.setBlendMode("alpha")
                end
            end
        end
        g.pop()
        if slot.chest and active and anim.phaseTime > 0.18 then
            local dust = math.min(1, (anim.phaseTime - 0.18) / 0.3)
            for j = 1, 6 do
                g.setColor(0.85, 0.73, 0.52, (1 - dust) * 0.35)
                g.circle("fill", sx + slotW / 2 + (j - 3.5) * dust * 18, sy + 110 - math.sin(j) * dust * 7, 2 + dust * 3)
            end
        end
        if revealed then
            if rarity.strength >= 3 and progress < 1 then
                for j = 1, 8 do
                    local angle = j * math.pi / 4
                    local radius = 20 + progress * 65
                    g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], 1 - progress)
                    g.circle("fill", sx + slotW / 2 + math.cos(angle) * radius, sy + 65 + math.sin(angle) * radius, 2)
                end
            end
            g.setFont(UI.fonts.tiny); g.setColor(rarity.color)
            g.printf(rarity.label, sx + 4, sy + 6, slotW - 8, "center")
            g.setFont(UI.fonts.small); g.setColor(UI.COLORS.textLight)
            g.printf(reward.type == "GOLD" and "+" .. reward.amount .. " XU VÀNG" or reward.name, sx + 8, sy + 134, slotW - 16, "center")
            g.setFont(UI.fonts.tiny); g.setColor(rarity.color[1], rarity.color[2], rarity.color[3], 0.12)
            UI.drawRoundedRect("fill", sx + slotW / 2 - 40, sy + 167, 80, 18, 5)
            g.setColor(rarity.color); g.printf(slot.chest and "ĐÃ MỞ" or "ĐÃ NHẬN", sx + 4, sy + 169, slotW - 8, "center")
            if inside(mx, my, sx, sy, slotW, slotH) then
                if reward.type == "PLAYING_CARD" then UI.descriptionCandidate = reward.card
                else UI.descriptionCandidate = {hoverKey = reward, name = reward.name, desc = rarity.label .. " · " .. reward.source .. "\n" .. (reward.metadata and reward.metadata.reason or reward.card and reward.card.desc or reward.packType and "Mở miễn phí tại cửa hàng: chọn phần thưởng theo luật gói hiện tại." or slot.chest and "Rương đã mở; các món bên cạnh là nội dung đã nhận." or "Thêm $" .. reward.amount .. " vào túi vàng."), color = rarity.color} end
            end
        end
    end
    g.setBlendMode("add")
    for _, p in ipairs(anim.sparks) do
        local ax, ay = tx, ty
        if type(p.anchor) == "number" then
            ax, ay = startX + (p.anchor - 1) * (slotW + gap) + slotW / 2, y + 442
        end
        local alpha = (1 - p.age / p.life) ^ 2
        g.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.7)
        g.setLineWidth(1)
        local px, py = ax + p.x, ay + p.y
        g.line(px - p.size * 2, py, px + p.size * 2, py)
        g.line(px, py - p.size * 2, px, py + p.size * 2)
    end
    g.setBlendMode("alpha")
    g.setColor(0.26, 0.32, 0.39, 0.45); g.line(x + 32, y + h - 88, x + w - 32, y + h - 88)
    local btn = {id = "cashout_continue", text = anim.finished and "ĐẾN CỬA HÀNG  →" or "NHẬN NHANH PHẦN THƯỞNG", x = x + w - 362, y = y + h - 66, w = 330, h = 46,
        color = gold, font = UI.fonts.regular, variant = "gold"}
    if buttons then buttons[#buttons + 1] = btn end
    local hovered = inside(mx, my, btn.x, btn.y, btn.w, btn.h)
    g.setColor(hovered and 1 or 0.93, hovered and 0.84 or 0.73, hovered and 0.49 or 0.33)
    UI.drawRoundedRect("fill", btn.x, btn.y, btn.w, btn.h, 8)
    g.setColor(1, 0.91, 0.66, 0.8); UI.drawRoundedRect("line", btn.x, btn.y, btn.w, btn.h, 8)
    g.setFont(btn.font); g.setColor(0.13, 0.10, 0.055); g.printf(btn.text, btn.x, btn.y + 13, btn.w, "center")
    g.setFont(UI.fonts.small); g.setColor(UI.COLORS.textLight)
    g.print(anim.finished and "Phần thưởng đã được cất vào hành trang" or "Xu và vật phẩm đang được thu thập", x + 32, y + h - 64)
    g.setFont(UI.fonts.tiny); g.setColor(muted)
    g.print(anim.finished and "ENTER / SPACE  ·  Tiếp tục hành trình" or "ENTER / SPACE / CLICK  ·  Nhận ngay", x + 32, y + h - 40)
    g.pop()
end

return RewardSystem

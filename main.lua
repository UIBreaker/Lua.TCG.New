for _, a in ipairs(arg or {}) do
    if a == "--test" then
        local ok, err = pcall(require, "test_system")
        if not ok then
            print("TEST ERROR: " .. tostring(err))
            os.exit(1)
        end
        os.exit(0)
    elseif a == "--test-poker" then
        local ok, err = pcall(require, "test_poker")
        if not ok then
            print("TEST POKER ERROR: " .. tostring(err))
            os.exit(1)
        end
        os.exit(0)
    elseif a == "--test-features" then
        local ok, err = pcall(require, "test_features")
        if not ok then
            print("TEST FEATURES ERROR: " .. tostring(err))
            os.exit(1)
        end
        os.exit(0)
    end
end
local Deck = require("src.deck")
local Poker = require("src.poker")
local Deities = require("src.deities")
local Scoring = require("src.scoring")
local Shop = require("src.shop")
local Sound = require("src.sound")
local UI = require("src.ui")
local Monster = require("src.monster")
local Equipment = require("src.equipment")
local Map = require("src.map")
local Events = require("src.events")
local RunManager = require("src.run_manager")
local RewardSystem = require("src.reward_system")
local Collection = require("src.collection")
local Persistence = require("src.persistence")
local Rng = require("src.rng")
local GameState = require("src.game_state")
local Combat = require("src.combat")

io.stdout:setvbuf("no")
local isCaptureMode = false
for _, a in ipairs(arg or {}) do
    if a == "--capture" then
        isCaptureMode = true
    end
end
local Capture = isCaptureMode and require("capture_screens") or nil

-- Game States: "menu", "BLIND_SELECT", "map", "playing", "scoring", "CASH_OUT", "shop", "event", "boss_deity", "chest", "socketing", "gameover", "victory"
local state = "menu"

-- Virtual Resolution
local V_WIDTH = 1280
local V_HEIGHT = 720
local scale = 1
local offsetX = 0
local offsetY = 0

-- Graphics Pipeline: Canvas & Shaders
local mainCanvas = nil
local bgShader = nil
local crtShader = nil

local bgCurrentColors = {
    a = { 0.72, 0.10, 0.14 },
    b = { 0.08, 0.32, 0.75 },
    c = { 0.85, 0.20, 0.25 },
}

-- Run data
local game = GameState.new("red_deck")

local pendingCombatNode = nil -- For Encounter / Skip Blind modal
local cashOutAnim = nil -- For Cash Out Modal Breakdown
local shopData = nil
local chestRewards = {}
local pendingEquipment = nil
local socketingReturnState = "shop"
local socketingPage = 1
local socketingMessage = nil

-- Right-Click Card Inspector Modal
local inspectCardModal = nil

-- Handbook Modal State (Compendium of Unlocked Hands)
local isHandbookOpen = false

-- Shop Equipment Transfer
local isShopTransferOpen = false
local transferSourceCard = nil
local transferSourceEqIndex = nil
local transferMessage = nil

-- Rest Site & Forge State
local restStateData = {
    chosenAction = nil, -- "rest", "forge", nil
    selectedCard = nil,
    message = nil,
}

-- Treasure Site State
local treasureRewards = {}

-- Deck Viewer Modal State
local isDeckViewerOpen = false
local deckViewerFilter = "all" -- "all", "rank", "suit", "equipped"

-- Main Menu & Pause Menu State
local menuMode = "title" -- "title", "deck_select"
local isPauseMenuOpen = false
local isSettingsOpen = false
local lastActiveState = "map"
local hasRunStarted = false

-- Collection Compendium Modal State
local isCollectionOpen = false
local collectionCategory = nil -- nil: Category Hub, string: Category id for Detail view
local selectedCollectionItem = nil
local collectionScrollY = 0

-- Settings Data
local settings = {
    sfxVolume = 0.8,
    fastScoring = false,
    fullscreen = false,
    crtEnabled = true,
}

local function saveSettings()
    Persistence.saveSettings(settings)
end

local function saveRunAtSafePoint()
    if game and game.run and not isCaptureMode then
        Persistence.saveRun(game, state)
    end
end

-- Shop Drag & Drop State
local shopDrag = {
    active = false,
    isDragging = false,
    itemIndex = nil,
    item = nil,
    startX = 0,
    startY = 0,
    currentX = 0,
    currentY = 0,
    visualX = 0,
    visualY = 0,
    origX = 0,
    origY = 0,
    cardW = 124,
    cardH = 186,
    tiltX = 0,
    tiltY = 0,
    category = nil,
}

-- Top Bar Deity Drag & Drop State (Reordering)
local deityDrag = {
    active = false,
    isDragging = false,
    deityIndex = nil,
    startX = 0,
    startY = 0,
    currentX = 0,
    currentY = 0,
    visualX = 0,
    visualY = 0,
    origX = 0,
    origY = 0,
}

local buttons = {}
local juice = nil

local function getDeitySlotRect(i, currentState)
    currentState = currentState or state
    local slotW = 82
    local slotH = 118
    local gap = 14
    local startX = 295
    local slotY = 32
    return startX + (i - 1) * (slotW + gap), slotY, slotW, slotH
end

local function drawConsumableSlot(c, cx, cy, conSlotW, conSlotH, j, mx, my)
    if c then
        local isHover = (mx >= cx and mx <= cx + conSlotW and my >= cy and my <= cy + conSlotH)
        love.graphics.setColor(0.12, 0.16, 0.22, 0.95)
        UI.drawRoundedRect("fill", cx, cy, conSlotW, conSlotH, 6)
        love.graphics.setLineWidth(isHover and 2 or 1.5)
        love.graphics.setColor(c.color or UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", cx, cy, conSlotW, conSlotH, 6)

        -- Icon
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(c.icon or "✨", cx, cy + 10, conSlotW, "center")

        -- Name
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.printf(c.name or "Thẻ Phép", cx + 2, cy + 42, conSlotW - 4, "center")

        -- Use Button
        local btnUse = {
            id = "use_consumable_" .. j,
            text = "DÙNG",
            x = cx + 8,
            y = cy + conSlotH - 26,
            w = conSlotW - 16,
            h = 20,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.tiny,
            consumableIndex = j,
        }
        table.insert(buttons, btnUse)
        UI.drawButton(btnUse, mx >= btnUse.x and mx <= btnUse.x + btnUse.w and my >= btnUse.y and my <= btnUse.y + btnUse.h, juice and juice.buttonPressedId == btnUse.id)

        if isHover and my < cy + conSlotH - 26 then
            -- Tooltip
            local ttW = 210
            local ttH = 75
            local ttX = math.min(V_WIDTH - ttW - 10, math.max(10, cx - 40))
            local ttY = cy + conSlotH + 8
            love.graphics.setColor(0.08, 0.10, 0.14, 0.96)
            UI.drawRoundedRect("fill", ttX, ttY, ttW, ttH, 6)
            love.graphics.setColor(c.color or UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", ttX, ttY, ttW, ttH, 6)
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf(c.name, ttX + 6, ttY + 6, ttW - 12, "left")
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(c.desc or "", ttX + 6, ttY + 22, ttW - 12, "left")
        end
    else
        love.graphics.setColor(0.09, 0.11, 0.13, 0.6)
        UI.drawRoundedRect("fill", cx, cy, conSlotW, conSlotH, 6)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(0.24, 0.28, 0.34, 0.5)
        UI.drawRoundedRect("line", cx, cy, conSlotW, conSlotH, 6)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(0.32, 0.36, 0.42, 0.5)
        love.graphics.printf("Trống", cx, cy + conSlotH / 2 - 10, conSlotW, "center")
    end
end

-- Micro-Animation & Juice System
juice = {
    ambientTimer = 0,
    handRankBounce = 1.0,
    lastEvaluatedRank = nil,
    goldBounce = 1.0,
    lastGold = 6,
    hpBounce = 1.0,
    lastHp = 100,
    buttonPressedId = nil,
    lastHoveredButtonId = nil,
    floatingTexts = {},
    screenShake = 0,
}

local function spawnJuiceText(text, x, y, color, duration)
    table.insert(juice.floatingTexts, {
        text = UI.sanitizeText(text),
        x = x,
        y = y,
        color = color or { 1, 1, 1, 1 },
        life = duration or 1.2,
        maxLife = duration or 1.2,
        vy = -38,
    })
    while #juice.floatingTexts > 20 do
        table.remove(juice.floatingTexts, 1)
    end
end

-- Scoring Animation State
local anim = {
    active = false,
    timer = 0,
    scoringData = nil,
    currentStepIndex = 1,
    displayChips = 0,
    displayMult = 0,
    displayXMult = 1.0,
    displayFinalScore = 0,
    stepTimer = 0,
    playedCards = {},
    floatingTexts = {},
    monsterDefeated = false,
    playerKilled = false,
    earnedGold = 0,
    damageDealt = 0,
    -- Pacing & Rising Pitch
    pitchStep = 0,
    targetStepDelay = 0.36,
    -- Squash & Stretch + Dynamic Scale Bounce
    cardBounce = {},
    deityBounce = {},
    bounceScale = { chips = 1.0, mult = 1.0, xMult = 1.0, score = 1.0 },
    -- Particle & Fire System
    particles = {},
    fireParticles = {},
    impactFlash = 0,
    impactX = 0,
    impactY = 0,
    impactColor = { 1, 1, 1, 1 },
    entranceTimer = 0,
}

-- Hand Card Drag & Drop State
local handDrag = {
    active = false,
    cardIndex = nil,
    startX = 0,
    startY = 0,
    currentX = 0,
    currentY = 0,
    offsetX = 0,
    offsetY = 0,
    isDragging = false,
}

local getHandCardPosition

local function prepareDrawAnimation(card, order)
    if not card then return end
    order = order or 1
    card.visualX = 1180
    card.visualY = 620
    card.visualAngle = -0.12 + order * 0.025
    card.visualScale = 0.68
    card.dealPending = true
    card.dealDelay = (order - 1) * 0.075
    card.dealTrail = 0
end

local function spawnSparks(x, y, count, color)
    color = color or UI.COLORS.goldYellow
    count = count or 16
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = math.random(80, 240)
        table.insert(anim.particles, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            gravity = math.random(60, 160),
            size = math.random(3, 6),
            r = color[1],
            g = color[2],
            b = color[3],
            alpha = 1.0,
            life = 0.35 + math.random() * 0.30,
            maxLife = 0.65,
        })
    end
    while #anim.particles > 100 do
        table.remove(anim.particles, 1)
    end
end

local function spawnFireEmbers(bx, by, bw, bh, tier)
    tier = tier or 1
    local count = (tier >= 3) and 4 or ((tier == 2) and 3 or 2)
    for i = 1, count do
        local px = bx + math.random(4, bw - 4)
        local py = by + bh - math.random(2, 8)
        local isEmber = (math.random() < 0.35)
        local pType = isEmber and "ember" or "flame"

        -- Multi-temperature fire colors (Core white-hot, vibrant body, dark glowing boundary)
        local colCore, colBody, colOuter
        if tier >= 3 then
            -- Cosmic blue/plasma flame
            colCore = { 0.95, 0.98, 1.0 }
            colBody = (math.random() < 0.5) and { 0.20, 0.85, 1.0 } or { 0.45, 0.40, 1.0 }
            colOuter = { 0.10, 0.30, 0.80 }
        elseif tier == 2 then
            -- Blazing magenta/violet flame
            colCore = { 1.0, 0.95, 0.90 }
            colBody = (math.random() < 0.5) and { 0.98, 0.35, 0.15 } or { 0.90, 0.20, 0.65 }
            colOuter = { 0.65, 0.10, 0.30 }
        else
            -- Realistic natural inferno (white-hot -> gold -> orange -> deep red)
            colCore = { 1.0, 0.98, 0.88 }
            colBody = (math.random() < 0.5) and { 1.0, 0.60, 0.10 } or { 1.0, 0.35, 0.05 }
            colOuter = { 0.85, 0.12, 0.02 }
        end

        local pLife = isEmber and (0.45 + math.random() * 0.45) or (0.35 + math.random() * 0.35)
        table.insert(anim.fireParticles, {
            x = px,
            y = py,
            vx = (math.random() - 0.5) * (isEmber and 60 or 30),
            vy = - (isEmber and (100 + math.random() * 120) or (75 + math.random() * 85)),
            size = isEmber and (1.8 + math.random() * 2.2) or (5.5 + math.random() * 6.5),
            coreCol = colCore,
            bodyCol = colBody,
            outerCol = colOuter,
            alpha = 1.0,
            life = pLife,
            maxLife = pLife,
            age = 0,
            phase = math.random() * math.pi * 2,
            tier = tier,
            pType = pType,
        })
    end
    while #anim.fireParticles > 120 do
        table.remove(anim.fireParticles, 1)
    end
end

local function drawRealisticFireParticles()
    if not (anim.fireParticles and #anim.fireParticles > 0) then return end
    love.graphics.setBlendMode("add")
    for _, p in ipairs(anim.fireParticles) do
        local progress = p.life / p.maxLife
        local curAlpha = math.max(0, progress * (p.alpha or 0.85))
        local curSize = p.size * (0.3 + 0.7 * progress)

        if p.pType == "ember" then
            -- Intense glowing ember / spark
            love.graphics.setColor(p.outerCol[1], p.outerCol[2], p.outerCol[3], curAlpha * 0.5)
            love.graphics.circle("fill", p.x, p.y, curSize * 2.2)
            love.graphics.setColor(p.coreCol[1], p.coreCol[2], p.coreCol[3], curAlpha)
            love.graphics.circle("fill", p.x, p.y, curSize)
        else
            -- 3-layer organic flame: outer glow -> body flame -> white-hot core
            love.graphics.setColor(p.outerCol[1], p.outerCol[2], p.outerCol[3], curAlpha * 0.45)
            love.graphics.circle("fill", p.x, p.y, curSize * 1.8)
            love.graphics.setColor(p.bodyCol[1], p.bodyCol[2], p.bodyCol[3], curAlpha * 0.85)
            love.graphics.circle("fill", p.x, p.y, curSize)
            love.graphics.setColor(p.coreCol[1], p.coreCol[2], p.coreCol[3], curAlpha * 0.95)
            love.graphics.circle("fill", p.x, p.y, curSize * 0.45)
        end
    end
    love.graphics.setBlendMode("alpha")
end

-- Screen shake
local screenShake = 0

-- UI Elements
buttons = {}
local hoveredDeityTooltip = nil
local hoveredCardTooltip = nil

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

local function updateScale()
    local winW, winH = love.graphics.getDimensions()
    local scaleX = winW / V_WIDTH
    local scaleY = winH / V_HEIGHT
    scale = math.min(scaleX, scaleY)
    offsetX = (winW - V_WIDTH * scale) / 2
    offsetY = (winH - V_HEIGHT * scale) / 2
end

local function toVirtual(mx, my)
    return (mx - offsetX) / scale, (my - offsetY) / scale
end

local function syncCardSelections()
    for _, c in ipairs(game.hand) do
        c.selected = false
    end
    for _, idx in ipairs(game.selectedIndices) do
        if game.hand[idx] then
            game.hand[idx].selected = true
        end
    end
end

local function getAllDeckCards()
    if game.persistentDeck and #game.persistentDeck > 0 then
        return game.persistentDeck
    end
    local list = {}
    local seen = {}
    for _, pile in ipairs({ game.hand, game.deck, game.discardPile }) do
        for _, c in ipairs(pile) do
            if not seen[c.id] then
                seen[c.id] = true
                table.insert(list, c)
            end
        end
    end
    return list
end

local function clearAllSelections()
    game.selectedIndices = {}
    for _, c in ipairs(game.hand) do
        c.selected = false
    end
    for _, c in ipairs(game.deck) do
        c.selected = false
    end
    for _, c in ipairs(game.discardPile) do
        c.selected = false
    end
    if game.persistentDeck then
        for _, c in ipairs(game.persistentDeck) do
            c.selected = false
        end
    end
end

local function getCardGridPos(i, totalCards, cardW, cardH, gapX, gapY, maxCols, baseY)
    cardW = cardW or 100
    cardH = cardH or 145
    gapX = gapX or 16
    gapY = gapY or 32
    maxCols = maxCols or 8
    baseY = baseY or 240

    if totalCards <= maxCols then
        local totalW = totalCards * cardW + math.max(0, totalCards - 1) * gapX
        local startX = (V_WIDTH - totalW) / 2
        return startX + (i - 1) * (cardW + gapX), baseY, cardW, cardH
    else
        local cols = math.min(totalCards, maxCols)
        local totalW = cols * cardW + math.max(0, cols - 1) * gapX
        local startX = (V_WIDTH - totalW) / 2
        local col = (i - 1) % maxCols
        local row = math.floor((i - 1) / maxCols)
        return startX + col * (cardW + gapX), baseY - 45 + row * (cardH + gapY), cardW, cardH
    end
end

local function getMaxSelectableCards()
    local maxAllowed = 1
    if game.unlockedHands then
        for handId, unlocked in pairs(game.unlockedHands) do
            if unlocked then
                if handId == "straight_flush" or handId == "flush" or handId == "full_house" then
                    maxAllowed = math.max(maxAllowed, 5)
                elseif handId == "four_of_a_kind" or handId == "two_pair" then
                    maxAllowed = math.max(maxAllowed, 4)
                elseif handId == "three_of_a_kind" or handId == "straight" then
                    maxAllowed = math.max(maxAllowed, 3)
                elseif handId == "pair" then
                    maxAllowed = math.max(maxAllowed, 2)
                end
            end
        end
    end
    local maxCount = math.min(game.maxHandSize or 3, maxAllowed)
    if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.maxSelectedCards then
        maxCount = math.min(maxCount, game.monster.bossData.maxSelectedCards)
    end
    return math.max(1, maxCount)
end

local function initializeCombat(monster, round)
    local result = Combat.start(game, monster, round)
    if result.slaughterChips > 0 then
        table.insert(anim.floatingTexts, {
            text = "⚔️ SÁT KHÍ BỘC PHÁT (A♠): +" .. result.slaughterChips .. " Starting Chips!",
            color = UI.COLORS.goldYellow,
            x = 640,
            y = 350,
            alpha = 3.0,
        })
    end
    clearAllSelections()
    syncCardSelections()
    state = "playing"
    Sound.play("card_deal")
end

local function startMonsterEncounter(floor, isBossNode, isEliteNode)
    game.monsterEncounterCount = game.monsterEncounterCount or 1
    local round = floor or 1
    initializeCombat(Monster.create(round, isBossNode, isEliteNode, game.monsterEncounterCount), round)
end

local function startBlindCombat(blind)
    if not blind then return end
    game.currentBlind = blind
    initializeCombat(RunManager.createBlindMonster(blind, game), blind.ante or 1)
    lastActiveState = "playing"
end

local function startNewGame(chosenDeck)
    Persistence.deleteRun()
    GameState.resetRun(game, chosenDeck or "red_deck")
    pendingCombatNode = nil

    inspectCardModal = nil
    isShopTransferOpen = false
    isHandbookOpen = false
    transferSourceCard = nil
    transferSourceEqIndex = nil
    transferMessage = nil

    -- Red Deck contains a standard 52-card pool; each combat draws exactly
    -- three random cards from it as the opening hand.
    game.persistentDeck = Deck.createStarterDeck(game.starterDeckId)
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck

    clearAllSelections()
    syncCardSelections()

    -- The supported campaign is the Balatro-style 8-Ante loop. The legacy
    -- 20-floor map remains available to screenshot/dev tooling only.
    game.map = nil

    -- Initialize Balatro Run Loop (8 Ante, 3 Blinds per Ante)
    game.run = RunManager.newRun(game.selectedFaction)
    state = "BLIND_SELECT"
    hasRunStarted = true
    lastActiveState = "BLIND_SELECT"
    isPauseMenuOpen = false
    isSettingsOpen = false
    Sound.play("card_deal")
    saveRunAtSafePoint()
end

local function getSelectedCards()
    local selected = {}
    for _, idx in ipairs(game.selectedIndices) do
        if game.hand[idx] then
            table.insert(selected, game.hand[idx])
        end
    end
    return selected
end

local function toggleCardSelection(index)
    local found = nil
    for i, idx in ipairs(game.selectedIndices) do
        if idx == index then
            found = i
            break
        end
    end

    if found then
        table.remove(game.selectedIndices, found)
        if game.hand[index] then game.hand[index].visualScale = 0.96 end
        Sound.play("card_deselect")
    else
        local maxAllowed = getMaxSelectableCards()
        if #game.selectedIndices < maxAllowed then
            table.insert(game.selectedIndices, index)
            if game.hand[index] then game.hand[index].visualScale = 1.12 end
            Sound.play("card_select")
        else
            if maxAllowed == 1 then
                table.insert(anim.floatingTexts, {
                    text = "Mới vào chỉ đánh được 1 lá ĐƠN THỦ! Mua Sách Bí Tịch tại Shop để mở Đôi, Sảnh, Thùng!",
                    color = UI.COLORS.xmultGold,
                    x = 640,
                    y = 480,
                    alpha = 2.0,
                })
            else
                table.insert(anim.floatingTexts, {
                    text = "Tối đa được chọn " .. maxAllowed .. " lá theo các bí tịch đã mở khóa!",
                    color = UI.COLORS.xmultGold,
                    x = 640,
                    y = 480,
                    alpha = 1.5,
                })
            end
        end
    end
    syncCardSelections()
end

local function discardSelected()
    if #game.selectedIndices == 0 or game.discardsRemaining <= 0 then return end

    screenShake = math.max(screenShake or 0, 2.5)

    -- Check if any discarded card has Free Feather equipment
    local hasFreeDiscard = false
    for _, idx in ipairs(game.selectedIndices) do
        local c = game.hand[idx]
        if c and c.equipments then
            for _, eq in ipairs(c.equipments) do
                if eq.onDiscard and eq.onDiscard(c).freeDiscard then
                    hasFreeDiscard = true
                    break
                end
            end
        end
    end

    table.sort(game.selectedIndices, function(a, b) return a > b end)
    local discardedCards = {}
    for _, idx in ipairs(game.selectedIndices) do
        local card = table.remove(game.hand, idx)
        card.selected = false
        table.insert(discardedCards, card)
    end
    clearAllSelections()

    -- Process Grimdark Faction Passives on Discard
    game.discardBuffs = game.discardBuffs or { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    for _, card in ipairs(discardedCards) do
        local suit = card.suit or game.selectedFaction or "aurelia"
        local factionsEnabled = not card.disableFactionPassives and game.factionPassivesEnabled ~= false
        local isSpadeCard = factionsEnabled and (suit == "spades" or suit == "vharos" or suit == "iron_axiom")
        local isHeartCard = factionsEnabled and (suit == "hearts" or suit == "valoria" or suit == "sanguine_covenant")
        local isDiamondCard = factionsEnabled and (suit == "diamonds" or suit == "aurelia" or suit == "gilded_conclave")
        local isClubCard = factionsEnabled and (suit == "clubs" or suit == "elaris" or suit == "feral_swarm" or card.isWildSuit)

        -- 1. ♥️ GIÁO HỘI HUYẾT ƯỚC: Huyết Tế Discard, Dấu Ấn Tử Đạo, J♥ Hồi Hand
        if isHeartCard then
            table.insert(game.discardPile, card)

            -- J♥ Kẻ Hành Quyết Tội Lỗi: hồi +1 Hand (1 lần mỗi trận)
            if card.rank == 11 and not game.jHeartDiscardUsed then
                game.handsRemaining = (game.handsRemaining or 4) + 1
                game.jHeartDiscardUsed = true
                table.insert(anim.floatingTexts, {
                    text = "🩸 [Kẻ Hành Quyết] J♥ hồi +1 Hand!",
                    color = { 0.95, 0.25, 0.35, 1 },
                    x = 640,
                    y = 410,
                    alpha = 2.5,
                })
                Sound.play("jackpot")
            end

            -- Chiến Binh Cơ (2-10): Sát thương chuẩn = Rank trực tiếp vào máu quái
            if card.rank >= 2 and card.rank <= 10 then
                local trueDmg = card.rank
                if game.monster and game.monster.hp > 0 then
                    local actualDmg, defeated = Monster.takeDamage(game.monster, trueDmg)
                    table.insert(anim.floatingTexts, {
                        text = "🩸 [Huyết Tế] " .. card.rankName .. "♥: -" .. actualDmg .. " Sát Thương Chuẩn!",
                        color = { 0.95, 0.25, 0.35, 1 },
                        x = 640,
                        y = 440,
                        alpha = 2.2,
                    })
                    Sound.play("xmult_boom")
                    if defeated then
                        anim.monsterDefeated = true
                        Sound.play("round_win")
                    end
                end
            end

            -- Dấu Ấn Tử Đạo (+1 điểm mỗi lá Cơ hy sinh, max 5)
            game.martyrStacks = math.min(5, (game.martyrStacks or 0) + 1)
            table.insert(anim.floatingTexts, {
                text = "🩸 +1 Dấu Ấn Tử Đạo (" .. game.martyrStacks .. "/5)",
                color = { 0.95, 0.3, 0.4, 1 },
                x = 640,
                y = 470,
                alpha = 2.0,
            })

        -- 2. ♣️ BẦY NGUYÊN SINH: Tuần Hoàn Thể (chui xuống đáy bộ bài bốc)
        elseif isClubCard then
            table.insert(game.deck, 1, card)
            table.insert(anim.floatingTexts, {
                text = "🌿 [Tuần Hoàn Thể] " .. card.rankName .. "♣ chui xuống đáy bộ bài!",
                color = { 0.2, 0.85, 0.4, 1 },
                x = 640,
                y = 440,
                alpha = 2.0,
            })
            Sound.play("card_deal")

        -- 3. ♠️ THIẾT QUÂN THỨ: Rơi vào mộ bài
        elseif isSpadeCard then
            table.insert(game.discardPile, card)

        -- 4. ♦️ TRẬT TỰ HOÀNG KIM: Rơi vào mộ bài
        else
            table.insert(game.discardPile, card)
        end

        -- 5. 🟣 DẤU TÍM (Purple Seal / Medium): Tạo Thẻ Phép ngẫu nhiên khi bị bỏ bài
        if card.seal == "purple" then
            local spellPool = {
                { id = "spec_familiar", name = "Familiar", subtitle = "LINH THÚ", desc = "Hủy 1 lá ngẫu nhiên, thêm 3 lá Hoàng Gia (J, Q, K) có trang bị!" },
                { id = "spec_grim", name = "Grim", subtitle = "TỬ THẦN", desc = "Hủy 1 lá ngẫu nhiên, thêm 2 lá Át (A) có trang bị!" },
                { id = "spec_cryptid", name = "Cryptid", subtitle = "DỊ THỂ", desc = "Nhân bản 1 lá bài đã chọn trên tay thành 2 bản sao!" },
                { id = "spec_immolate", name = "Immolate", subtitle = "THIÊU RỤI", desc = "Hủy 5 lá, nhận ngay +$20 Tiền Vàng!" },
                { id = "spec_black_hole", name = "Black Hole", subtitle = "HỐ ĐEN", desc = "Tất cả các thế bài tăng +1 Cấp!" },
                { id = "spell_aura", name = "Aura", subtitle = "HÀO QUANG", desc = "Thêm Foil, Holo, hoặc Polychrome cho 1 Thần ngẫu nhiên!" },
                { id = "seal_deja_vu", name = "Deja Vu", subtitle = "DẤU ĐỎ", desc = "Đóng Dấu Đỏ lên 1 lá bài (kích hoạt lại điểm +1 lần)!" },
            }
            local chosen = spellPool[Rng.random(#spellPool)]
            game.consumables = game.consumables or {}
            if #game.consumables < 2 then
                table.insert(game.consumables, chosen)
                table.insert(anim.floatingTexts, {
                    text = "🟣 [DẤU TÍM] Tạo Thẻ Phép: " .. chosen.name .. " (" .. chosen.subtitle .. ")!",
                    color = { 0.85, 0.45, 0.95, 1 },
                    x = 640,
                    y = 390,
                    alpha = 2.5,
                })
            else
                table.insert(anim.floatingTexts, {
                    text = "🟣 [DẤU TÍM] Ô Tiêu Hao đã đầy (2/2)!",
                    color = { 0.85, 0.45, 0.95, 1 },
                    x = 640,
                    y = 390,
                    alpha = 2.0,
                })
            end
            Sound.play("round_win")
        end
    end

    if hasFreeDiscard then
        table.insert(anim.floatingTexts, {
            text = "MIỄN PHÍ ĐỔI BÀI (LÔNG VŨ)!",
            color = UI.COLORS.goldYellow,
            x = 640,
            y = 520,
            alpha = 1.5,
        })
    else
        game.discardsRemaining = game.discardsRemaining - 1
        game.discardsUsedInCombat = (game.discardsUsedInCombat or 0) + 1
    end

    -- Refill hand to maxHandSize cards while deck/discard has cards
    local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
    local dealOrder = 0
    while #game.hand < maxHandSize do
        if #game.deck == 0 and #game.discardPile > 0 then
            while #game.discardPile > 0 do
                table.insert(game.deck, table.remove(game.discardPile))
            end
            Deck.shuffle(game.deck)
        end
        if #game.deck == 0 then break end
        local drawn = table.remove(game.deck)
        if drawn then
            dealOrder = dealOrder + 1
            drawn.selected = false
            prepareDrawAnimation(drawn, dealOrder)
            if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.debuffId == "the_fish" then
                drawn.faceDown = true
            end
            table.insert(game.hand, drawn)
        end
    end

    if game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end

    clearAllSelections()
    syncCardSelections()
    Sound.play("card_deal")
end

local function useConsumable(idx)
    game.consumables = game.consumables or {}
    local c = game.consumables[idx]
    if not c then return false end

    -- 1. Celestial / Planet card
    if c.category == "celestial" or (c.id and c.id:find("planet_")) then
        game.handLevels = game.handLevels or {}
        if c.handId == "random" then
            local allHands = {}
            for _, ht in pairs(Poker.HAND_TYPES) do table.insert(allHands, ht) end
            local h = allHands[Rng.random(#allHands)]
            game.handLevels[h.id] = (game.handLevels[h.id] or 1) + 3
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "🌟 Siêu Tân Tinh: Nâng cấp " .. h.vnName .. " lên Cấp " .. game.handLevels[h.id] .. "!",
                color = UI.COLORS.goldYellow,
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        elseif c.handId == "all" then
            for _, ht in pairs(Poker.HAND_TYPES) do
                game.handLevels[ht.id] = (game.handLevels[ht.id] or 1) + 1
            end
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "🕳️ Hố Đen: TẤT CẢ 9 thế bài tăng +1 Cấp độ!",
                color = { 0.85, 0.45, 0.95, 1 },
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        else
            game.handLevels[c.handId] = (game.handLevels[c.handId] or 1) + 1
            local hType = nil
            for _, ht in pairs(Poker.HAND_TYPES) do if ht.id == c.handId then hType = ht break end end
            local vName = hType and hType.vnName or c.name
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "🪐 " .. c.name .. ": Thế bài " .. vName .. " lên Cấp " .. game.handLevels[c.handId] .. "!",
                color = UI.COLORS.goldYellow,
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        end

    -- 2. Joker Spells
    elseif c.category == "joker_spell" or (c.id and c.id:find("spell_")) then
        local deityList = {}
        for di = 1, 10 do
            if game.deities and game.deities[di] then
                table.insert(deityList, { slot = di, deity = game.deities[di] })
            end
        end
        if #deityList == 0 then
            Sound.play("cant_afford")
            table.insert(anim.floatingTexts, {
                text = "Không có Hộ Linh nào để dùng phép!",
                color = { 0.95, 0.35, 0.35, 1 },
                x = 640,
                y = 350,
                alpha = 2.5,
            })
            return false
        end

        if c.id == "spell_aura" then
            local chosen = deityList[Rng.random(#deityList)]
            local edPool = { "foil", "holo", "polychrome" }
            chosen.deity.edition = edPool[Rng.random(#edPool)]
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "✨ Aura: Thần [" .. chosen.deity.name .. "] nhận " .. chosen.deity.edition:upper() .. "!",
                color = UI.COLORS.goldYellow,
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        elseif c.id == "spell_ectoplasm" then
            local chosen = deityList[Rng.random(#deityList)]
            chosen.deity.edition = "negative"
            game.maxHandSize = math.max(1, (game.maxHandSize or 3) - 1)
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "🧪 Ectoplasm: [" .. chosen.deity.name .. "] nhận NEGATIVE (+1 Ô Thần), Hand Size: " .. game.maxHandSize .. "!",
                color = { 0.3, 0.9, 0.6, 1 },
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        elseif c.id == "spell_ankh" then
            local chosen = deityList[Rng.random(#deityList)]
            local cloned = {}
            for k, v in pairs(chosen.deity) do cloned[k] = v end
            game.deities = { [1] = chosen.deity, [2] = cloned }
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "🪞 Ankh: Nhân bản [" .. cloned.name .. "], hủy diệt các Thần còn lại!",
                color = UI.COLORS.xmultGold,
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        elseif c.id == "spell_hex" then
            local chosen = deityList[Rng.random(#deityList)]
            chosen.deity.edition = "polychrome"
            local kept = chosen.deity
            game.deities = { [1] = kept }
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, {
                text = "🔮 Hex: [" .. kept.name .. "] nhận POLYCHROME, hủy diệt các Thần còn lại!",
                color = UI.COLORS.xmultGold,
                x = 640,
                y = 350,
                alpha = 3.0,
            })
            return true
        end

    -- 3. Seals
    elseif c.category == "seal" or (c.id and c.id:find("seal_")) then
        local target = nil
        if game.selectedIndices and #game.selectedIndices > 0 and game.hand and game.hand[game.selectedIndices[1]] then
            target = game.hand[game.selectedIndices[1]]
        elseif game.hand and #game.hand > 0 then
            target = game.hand[1]
        elseif game.persistentDeck and #game.persistentDeck > 0 then
            target = game.persistentDeck[1]
        end
        if not target then
            Sound.play("cant_afford")
            return false
        end
        target.seal = c.sealType
        if game.persistentDeck then
            for _, pc in ipairs(game.persistentDeck) do
                if pc.id == target.id then pc.seal = c.sealType break end
            end
        end
        Sound.play("round_win")
        table.remove(game.consumables, idx)
        table.insert(anim.floatingTexts, {
            text = "Đóng ấn [" .. (c.sealName or c.name) .. "] lên lá " .. (target.rankName or "") .. (target.suitSymbol or "") .. "!",
            color = UI.COLORS.goldYellow,
            x = 640,
            y = 350,
            alpha = 3.0,
        })
        return true

    -- 4. Spectral cards
    elseif c.category == "spectral" or (c.id and c.id:find("spec_")) then
        local userFaction = game.selectedFaction or game.selectedSuit or "aurelia"
        if c.id == "spec_familiar" then
            if game.hand and #game.hand > 0 then table.remove(game.hand, Rng.random(#game.hand)) end
            if game.persistentDeck and #game.persistentDeck > 0 then table.remove(game.persistentDeck, Rng.random(#game.persistentDeck)) end
            local ranks = { 11, 12, 13 }
            for i = 1, 3 do
                local nc = Deck.newCard(ranks[i], userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(game, nc)
            end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "👻 Familiar: Thêm 3 lá J/Q/K có trang bị!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_grim" then
            if game.hand and #game.hand > 0 then table.remove(game.hand, Rng.random(#game.hand)) end
            if game.persistentDeck and #game.persistentDeck > 0 then table.remove(game.persistentDeck, Rng.random(#game.persistentDeck)) end
            for i = 1, 2 do
                local nc = Deck.newCard(14, userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(game, nc)
            end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "💀 Grim: Thêm 2 lá Át (A) có trang bị!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_incantation" then
            if game.hand and #game.hand > 0 then table.remove(game.hand, Rng.random(#game.hand)) end
            if game.persistentDeck and #game.persistentDeck > 0 then table.remove(game.persistentDeck, Rng.random(#game.persistentDeck)) end
            for i = 1, 4 do
                local r = Rng.random(2, 10)
                local nc = Deck.newCard(r, userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(game, nc)
            end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🕯️ Incantation: Thêm 4 lá Quân Số có trang bị!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_cryptid" then
            local target = nil
            if game.selectedIndices and #game.selectedIndices > 0 and game.hand and game.hand[game.selectedIndices[1]] then
                target = game.hand[game.selectedIndices[1]]
            elseif game.hand and #game.hand > 0 then
                target = game.hand[1]
            elseif game.persistentDeck and #game.persistentDeck > 0 then
                target = game.persistentDeck[1]
            end
            if not target then Sound.play("cant_afford") return false end
            local cl1 = Deck.cloneCard(target)
            local cl2 = Deck.cloneCard(target)
            Deck.addCardToDeck(game, cl1)
            Deck.addCardToDeck(game, cl2)
            if game.hand then table.insert(game.hand, cl1) table.insert(game.hand, cl2) end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🧬 Cryptid: Tạo 2 bản sao của lá " .. (target.rankName or "") .. (target.suitSymbol or "") .. "!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_immolate" then
            local destroyed = 0
            while game.hand and #game.hand > 0 and destroyed < 5 do
                table.remove(game.hand, 1)
                destroyed = destroyed + 1
            end
            if game.persistentDeck then
                local dDeck = 0
                while #game.persistentDeck > 3 and dDeck < destroyed do
                    table.remove(game.persistentDeck, 1)
                    dDeck = dDeck + 1
                end
            end
            game.gold = (game.gold or 0) + 20
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🔥 Immolate: Thiêu rụi " .. destroyed .. " lá, +$20 Vàng!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_sigil" then
            local suits = Deck.SUIT_ORDER
            local targetSuit = suits[Rng.random(#suits)]
            local fInfo = Deck.SUITS[targetSuit]
            if game.hand then
                for _, ch in ipairs(game.hand) do
                    ch.suit = targetSuit
                    ch.suitName = Deck.STANDARD_SUIT_NAMES[targetSuit] or fInfo.name
                    ch.suitSymbol = fInfo.symbol
                    ch.color = fInfo.color
                end
            end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🌀 Sigil: Tất cả lá bài đổi sang Chất " .. (Deck.STANDARD_SUIT_NAMES[targetSuit] or fInfo.name) .. "!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_ouija" then
            local r = Rng.random(2, 14)
            local rName = Deck.RANK_NAMES[r] or tostring(r)
            if game.hand then
                for _, ch in ipairs(game.hand) do
                    ch.rank = r
                    ch.rankName = rName
                    ch.baseChips = Deck.getChipValue(r)
                end
            end
            game.maxHandSize = math.max(1, (game.maxHandSize or 3) - 1)
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "👁️ Ouija: Đổi bài sang Rank " .. rName .. ", Hand Size: " .. game.maxHandSize .. "!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_black_hole" then
            game.handLevels = game.handLevels or {}
            for _, ht in pairs(Poker.HAND_TYPES) do
                game.handLevels[ht.id] = (game.handLevels[ht.id] or 1) + 1
            end
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🕳️ Black Hole: TẤT CẢ các thế bài tăng +1 Cấp độ!", color = { 0.85, 0.45, 0.95, 1 }, x = 640, y = 350, alpha = 3.0 })
            return true
        end
    end

    return false
end

local function playSelectedHand()
    if #game.selectedIndices == 0 or game.handsRemaining <= 0 then return end

    local playedCards = getSelectedCards()
    local evalResult = Poker.evaluate(playedCards, game.unlockedHands, game.handLevels)
    if not evalResult then return end
    game.lastPlayedHandId = evalResult.type and evalResult.type.id

    screenShake = math.max(screenShake or 0, 2.5)

    -- Ensure played cards don't draw with selection border and reveal if faceDown
    for _, c in ipairs(playedCards) do
        c.selected = false
        c.faceDown = false
        c.hovered = false
    end

    -- Deduct hand
    game.handsRemaining = game.handsRemaining - 1

    -- Remove played cards from hand
    table.sort(game.selectedIndices, function(a, b) return a > b end)
    for _, idx in ipairs(game.selectedIndices) do
        local c = table.remove(game.hand, idx)
        c.selected = false
        table.insert(game.discardPile, c)
    end
    clearAllSelections()
    syncCardSelections()

    -- The Hook: Boss automatically discards 2 random cards from player's remaining hand
    if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.debuffId == "the_hook" then
        if #game.hand > 0 then
            local hookedCount = math.min(2, #game.hand)
            for i = 1, hookedCount do
                local hIdx = Rng.random(#game.hand)
                local hooked = table.remove(game.hand, hIdx)
                if hooked then
                    hooked.selected = false
                    table.insert(game.discardPile, hooked)
                end
            end
            table.insert(anim.floatingTexts, {
                text = "[THE HOOK] Boss giật vứt bỏ " .. hookedCount .. " lá trên tay!",
                color = { 0.95, 0.45, 0.2, 1 },
                x = 640,
                y = 380,
                alpha = 2.5,
            })
            Sound.play("xmult_boom")
        end
    end

    -- Calculate scoring steps & equipment
    local context = {
        handsRemaining = game.handsRemaining,
        discardsRemaining = game.discardsRemaining,
        round = game.round,
        monster = game.monster,
        discardBuffs = game.discardBuffs,
        selectedSuit = game.selectedSuit,
        selectedFaction = game.selectedFaction,
        playedHandsHistory = game.playedHandsHistory,
        starterDeckId = game.starterDeckId,
        handsPlayedThisCombat = game.handsPlayedThisCombat or 0,
        martyrStacks = game.martyrStacks or 0,
        gold = game.gold or 0,
        unplayedCards = game.hand,
        gameState = game,
        drawCards = function(n)
            local drawnCount = 0
            local maxHand = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris" or game.selectedFaction == "clubs" or game.selectedFaction == "feral_swarm") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
            while #game.hand < maxHand and #game.deck > 0 and drawnCount < n do
                local drawn = table.remove(game.deck)
                if drawn then
                    drawn.selected = false
                    prepareDrawAnimation(drawn, drawnCount + 1)
                    table.insert(game.hand, drawn)
                    drawnCount = drawnCount + 1
                end
            end
            return drawnCount
        end,
    }
    local scoreResult = Scoring.calculate(evalResult, game.deities, context)
    game.handsPlayedThisCombat = (game.handsPlayedThisCombat or 0) + 1

    -- Pha Người Chơi: Kích hoạt Hiệu ứng Trang Bị/Ngọc Khảm sinh tồn trước (+Giáp, +Hồi Máu)
    if scoreResult.addArmor and scoreResult.addArmor > 0 then
        game.playerArmor = math.min(30, (game.playerArmor or 0) + scoreResult.addArmor)
        game.playerShield = game.playerArmor
    end
    if scoreResult.healHp and scoreResult.healHp > 0 then
        local maxHp = game.maxPlayerHp or 100
        game.playerHp = math.min(maxHp, (game.playerHp or 100) + scoreResult.healHp)
    end
    if scoreResult.hpCost and scoreResult.hpCost > 0 then
        game.playerHp = math.max(0, (game.playerHp or 100) - scoreResult.hpCost)
    end

    -- Overcharged enhancement: unplayed cards in hand gain +5 Chips (max +25)
    for _, c in ipairs(game.hand or {}) do
        if c.enhancement == "enh_overcharged" or c.enhancement == "overcharged" then
            c.overchargeStacks = math.min(25, (c.overchargeStacks or 0) + 5)
        end
    end

    -- Reset consumed martyr stacks
    game.martyrStacks = 0
    -- Record played hand in history for repeated hand bonuses (e.g. Thần Điệp Kích)
    game.playedHandsHistory = game.playedHandsHistory or {}
    if evalResult and evalResult.type and evalResult.type.id then
        game.playedHandsHistory[evalResult.type.id] = (game.playedHandsHistory[evalResult.type.id] or 0) + 1
    end
    -- Reset consumed discard buffs
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    -- Setup scoring animation
    anim.active = true
    anim.timer = 0
    anim.scoringData = scoreResult
    anim.playedCards = playedCards
    anim.currentStepIndex = 1
    anim.displayChips = scoreResult.baseChips
    anim.displayMult = scoreResult.baseMult
    anim.displayXMult = 1.0
    anim.displayFinalScore = scoreResult.baseChips * scoreResult.baseMult
    anim.activeCardIndex = nil
    anim.scoredCards = {}
    anim.stepLog = evalResult.type.vnName .. ": " .. scoreResult.baseChips .. " Chips × " .. scoreResult.baseMult .. " Mult"
    anim.stepCategory = "TAY BÀI GỐC"
    anim.stepTimer = 0
    anim.playedCards = playedCards
    anim.evalResult = evalResult
    anim.floatingTexts = {}
    anim.monsterDefeated = false
    anim.playerKilled = false
    anim.earnedGold = 0
    anim.damageDealt = 0
    anim.pitchStep = 0
    anim.targetStepDelay = 0.36
    anim.cardBounce = {}
    anim.deityBounce = {}
    anim.bounceScale = { chips = 1.35, mult = 1.35, xMult = 1.0, score = 1.35 }
    anim.particles = {}
    anim.fireParticles = {}
    anim.impactFlash = 0
    anim.entranceTimer = 0

    state = "scoring"
    Sound.play("card_play", 1.0)
end

local function generateBossChestRewards()
    chestRewards = {}
    -- Option 1: Cross-suit rare card
    local rewardCard = Deck.createRewardCard(game.selectedSuit)
    table.insert(chestRewards, {
        type = "card",
        card = rewardCard,
        title = "LÁ BÀI NGOẠI LAI: " .. rewardCard.rankName .. " " .. rewardCard.suitName,
        desc = "Thêm một lá bài chất " .. rewardCard.suitName .. " vào bộ bài để đa dạng hóa chiến thuật!",
        color = rewardCard.color,
    })

    -- Option 2 & 3: Random Equipments
    local eq1 = Equipment.getRandomEquipment()
    table.insert(chestRewards, {
        type = "equipment",
        item = eq1,
        title = "TRANG BỊ: " .. eq1.name,
        desc = eq1.desc,
        color = eq1.color,
    })

    local eq2 = Equipment.getRandomEquipment()
    while eq2.id == eq1.id do
        eq2 = Equipment.getRandomEquipment()
    end
    table.insert(chestRewards, {
        type = "equipment",
        item = eq2,
        title = "TRANG BỊ: " .. eq2.name,
        desc = eq2.desc,
        color = eq2.color,
    })
end

--------------------------------------------------------------------------------
-- SHADERS & CANVAS PIPELINE
--------------------------------------------------------------------------------

local bgShaderCode = [[
extern number u_time;
extern vec2 u_resolution;
extern vec3 u_color_a;
extern vec3 u_color_b;
extern vec3 u_color_c;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = screen_coords / u_resolution;
    vec2 p = uv * 2.0 - 1.0;
    p.x *= u_resolution.x / u_resolution.y;

    number t = u_time * 0.35;
    vec2 q = vec2(
        sin(p.x * 2.2 + t + sin(p.y * 1.8 - t * 0.5)),
        cos(p.y * 2.0 - t * 0.8 + cos(p.x * 1.6 + t * 0.4))
    );
    vec2 r = vec2(
        sin(q.x * 3.1 + p.y * 1.5 + t * 0.7),
        cos(q.y * 2.8 + p.x * 1.4 - t * 0.6)
    );

    number f = 0.5 + 0.5 * sin(r.x * 3.0 + r.y * 3.0 + t);
    number f2 = 0.5 + 0.5 * cos(length(q) * 4.0 - t * 1.2);

    vec3 col = mix(u_color_a, u_color_b, clamp(f * 1.2 - 0.1, 0.0, 1.0));
    col = mix(col, u_color_c, clamp(pow(f2, 3.0) * 0.6, 0.0, 1.0));

    number vignette = clamp(1.0 - length(p * 0.45) * 0.65, 0.0, 1.0);
    col *= vignette;

    return vec4(col, 1.0) * color;
}
]]

local crtShaderCode = [[
extern vec2 u_resolution;
extern number u_time;
extern number u_curvature;
extern number u_chroma;
extern number u_scanlines;
extern number u_vignette;

vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    vec2 offset = abs(uv.yx) / vec2(6.0, 4.5);
    uv = uv + uv * offset * offset * (u_curvature / 0.05);
    return uv * 0.5 + 0.5;
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec2 uv = texture_coords;
    vec2 curved_uv = curveUV(uv);

    if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
        return vec4(0.012, 0.012, 0.018, 1.0);
    }

    vec2 distFromCenter = curved_uv - 0.5;
    number aberration = length(distFromCenter) * u_chroma;

    number r = Texel(texture, curved_uv + distFromCenter * aberration).r;
    number g = Texel(texture, curved_uv).g;
    number b = Texel(texture, curved_uv - distFromCenter * aberration).b;
    vec3 sceneColor = vec3(r, g, b);

    number scanline = sin(curved_uv.y * u_resolution.y * 3.14159265);
    scanline = 1.0 - (1.0 - scanline * 0.5 - 0.5) * u_scanlines;
    sceneColor *= scanline;

    number roll = sin(curved_uv.y * 18.0 - u_time * 6.0) * 0.012;
    sceneColor += roll;

    number vig = curved_uv.x * curved_uv.y * (1.0 - curved_uv.x) * (1.0 - curved_uv.y);
    number vignetteAmount = clamp(pow(16.0 * vig, u_vignette), 0.0, 1.0);
    sceneColor *= vignetteAmount;

    return vec4(sceneColor, 1.0) * color;
}
]]

local function initShadersAndCanvas()
    if love.graphics and love.graphics.newCanvas then
        mainCanvas = love.graphics.newCanvas(V_WIDTH, V_HEIGHT)
        mainCanvas:setFilter("nearest", "nearest")
    end
    if love.graphics and love.graphics.newShader then
        local okBg, shaderBg = pcall(love.graphics.newShader, bgShaderCode)
        if okBg then bgShader = shaderBg end

        local okCrt, shaderCrt = pcall(love.graphics.newShader, crtShaderCode)
        if okCrt then crtShader = shaderCrt end
    end
end

--------------------------------------------------------------------------------
-- LÖVE Callbacks
--------------------------------------------------------------------------------

function love.load()
    Rng.seed(os.time())
    UI.initFonts()
    settings = Persistence.loadSettings(settings)
    Sound.init()
    Sound.setVolume(settings.sfxVolume)
    if settings.fullscreen then
        love.window.setFullscreen(true, "desktop")
    end
    updateScale()
    initShadersAndCanvas()
    shopData = Shop.new()
    if not isCaptureMode then
        local loadedGame, loadedState = Persistence.loadRun()
        if loadedGame then
            game = loadedGame
            state = loadedState or "BLIND_SELECT"
            lastActiveState = state
            hasRunStarted = true
        end
    end
end

function love.resize(w, h)
    updateScale()
end

function love.update(dt)
    if love.mouse and love.mouse.getPosition then
        local rawMx, rawMy = love.mouse.getPosition()
        UI.virtualMouseX, UI.virtualMouseY = toVirtual(rawMx, rawMy)
    end
    UI.currentPressedBtnId = juice and juice.buttonPressedId
    if juice and juice.screenShake and juice.screenShake > 0 then
        screenShake = math.max(screenShake, juice.screenShake)
        juice.screenShake = 0
    end

    if isCaptureMode and Capture then
        Capture.update(game, {
            startNewGame = startNewGame,
            openDeckViewer = function() isDeckViewerOpen = true end,
            closeDeckViewer = function() isDeckViewerOpen = false end,
            startMonsterEncounter = function(fl, isB)
                startMonsterEncounter(fl, isB)
                state = "playing"
            end,
            openShop = function()
                Shop.resetReroll(shopData)
                Shop.refresh(shopData, game)
                state = "shop"
            end,
            openBossDeity = function()
                game.bossDeityDraft = Deities.getBossDraftPool(game.deities, 2)
                state = "boss_deity"
            end,
            openInspector = function(card)
                inspectCardModal = card
            end,
            closeInspector = function()
                inspectCardModal = nil
            end,
            openShopTransfer = function()
                isShopTransferOpen = true
            end,
            closeShopTransfer = function()
                isShopTransferOpen = false
            end,
            openHandbook = function()
                isHandbookOpen = true
            end,
            closeHandbook = function()
                isHandbookOpen = false
            end,
            openRest = function()
                restStateData = { chosenAction = nil, selectedCard = nil, message = nil }
                state = "rest"
            end,
            openSocketing = function(eq)
                pendingEquipment = eq or Equipment.ITEMS.gem_fire
                socketingReturnState = "map"
                state = "socketing"
            end,
            selectCardIndex = function(idx)
                toggleCardSelection(idx)
            end,
            playSelectedHand = function()
                playSelectedHand()
            end,
            setMenuMode = function(m)
                menuMode = m
            end,
            openSettings = function()
                isSettingsOpen = true
            end,
            closeSettings = function()
                isSettingsOpen = false
            end,
            openPauseMenu = function()
                isPauseMenuOpen = true
            end,
            closePauseMenu = function()
                isPauseMenuOpen = false
            end,
            openCollection = function(cat)
                isCollectionOpen = true
                collectionCategory = cat
            end,
            closeCollection = function()
                isCollectionOpen = false
                collectionCategory = nil
            end,
            openPack = function(packItem)
                shopData.currentPackOpening = Shop.openPack(packItem, game)
                state = "shop"
            end,
            closePack = function()
                shopData.currentPackOpening = nil
            end,
        })
    end

    if screenShake > 0 then
        screenShake = math.max(0, screenShake - dt * 15)
    end

    -- Update Map horizontal scrolling camera
    if game.map then
        Map.update(game.map, dt)
    end

    -- Smooth Monster damage lag bar
    if game.monster and game.monster.damageLagHp > game.monster.hp then
        game.monster.damageLagHp = math.max(game.monster.hp, game.monster.damageLagHp - dt * (game.monster.maxHp * 0.75))
    end

    -- Smoothly update floating texts
    for i = #anim.floatingTexts, 1, -1 do
        local ft = anim.floatingTexts[i]
        ft.y = ft.y - dt * 40
        ft.alpha = ft.alpha - dt * 1.1
        if ft.alpha <= 0 then
            table.remove(anim.floatingTexts, i)
        end
    end

    -- Smoothly lerp number bounce scales
    if anim.bounceScale then
        for k, v in pairs(anim.bounceScale) do
            anim.bounceScale[k] = v + (1.0 - v) * math.min(1.0, dt * 10)
        end
    end

    -- Smoothly lerp deity bounce scales
    if anim.deityBounce then
        for idx, v in pairs(anim.deityBounce) do
            anim.deityBounce[idx] = v + (1.0 - v) * math.min(1.0, dt * 10)
        end
    end

    -- Smoothly lerp card squash & stretch
    if anim.cardBounce then
        for idx, b in pairs(anim.cardBounce) do
            b.scaleX = b.scaleX + (1.0 - b.scaleX) * math.min(1.0, dt * 12)
            b.scaleY = b.scaleY + (1.0 - b.scaleY) * math.min(1.0, dt * 12)
        end
    end

    -- Smoothly lerp player hand cards visual positions & rotation
    if game.hand and #game.hand > 0 then
        for i, c in ipairs(game.hand) do
            local waitingForDeal = false
            if c.dealPending then
                c.dealDelay = math.max(0, (c.dealDelay or 0) - dt)
                if c.dealDelay <= 0 then
                    c.dealPending = false
                    c.dealTrail = 0.18
                    c.visualScale = 0.76
                    Sound.play("card_draw", math.min(1.18, 0.92 + i * 0.035))
                else
                    waitingForDeal = true
                end
            end
            if c.dealTrail and c.dealTrail > 0 then
                c.dealTrail = math.max(0, c.dealTrail - dt)
            end

            local tx, ty, tw, th, tangle = getHandCardPosition(i, #game.hand)
            if c.selected then
                ty = ty - 28
            end
            if c.hovered and not (handDrag.active and handDrag.cardIndex == i and handDrag.isDragging) then
                ty = ty - 22
            end

            if not c.visualX then
                c.visualX = tx
                c.visualY = ty
                c.visualAngle = tangle or 0
                c.rotation = tangle or 0
            else
                if not waitingForDeal and not (handDrag.active and handDrag.cardIndex == i and handDrag.isDragging) then
                    c.visualX = c.visualX + (tx - c.visualX) * math.min(1.0, dt * 18)
                    c.visualY = c.visualY + (ty - c.visualY) * math.min(1.0, dt * 18)
                    local curAngle = c.visualAngle or 0
                    c.visualAngle = curAngle + ((tangle or 0) - curAngle) * math.min(1.0, dt * 18)
                    c.rotation = c.visualAngle
                end
            end
            local targetScale = c.selected and 1.08 or (c.hovered and 1.04 or 1.0)
            c.visualScale = (c.visualScale or 1.0) + (targetScale - (c.visualScale or 1.0)) * math.min(1.0, dt * 14)
        end
    end

    -- Check hand rank bounce when cards selected change hand evaluation
    if state == "playing" then
        local selCards = getSelectedCards()
        local curHand = (#selCards > 0) and Poker.evaluate(selCards, game.unlockedHands, game.handLevels) or nil
        local curName = (curHand and curHand.type) and curHand.type.vnName or ""
        if curName ~= juice.lastEvaluatedRank then
            if juice.lastEvaluatedRank ~= nil and curName ~= "" then
                juice.handRankBounce = 1.25
            end
            juice.lastEvaluatedRank = curName
        end
    end

    -- Ambient and bounce lerp updates
    juice.ambientTimer = juice.ambientTimer + dt
    juice.goldBounce = juice.goldBounce + (1.0 - juice.goldBounce) * math.min(1.0, dt * 10)
    juice.hpBounce = juice.hpBounce + (1.0 - juice.hpBounce) * math.min(1.0, dt * 10)
    juice.handRankBounce = juice.handRankBounce + (1.0 - juice.handRankBounce) * math.min(1.0, dt * 10)

    -- Gold change detection
    if game.gold and juice.lastGold and game.gold ~= juice.lastGold then
        if game.gold > juice.lastGold then
            juice.goldBounce = 1.35
            spawnJuiceText("+$" .. (game.gold - juice.lastGold) .. " Vàng", 175, 630, UI.COLORS.goldYellow, 1.2)
        end
        juice.lastGold = game.gold
    end

    -- HP change detection
    if game.playerHp and juice.lastHp and game.playerHp ~= juice.lastHp then
        if game.playerHp < juice.lastHp then
            juice.hpBounce = 1.30
            spawnJuiceText("-" .. (juice.lastHp - game.playerHp) .. " HP", 140, 580, UI.COLORS.hpRed, 1.2)
        elseif game.playerHp > juice.lastHp then
            juice.hpBounce = 1.30
            spawnJuiceText("+" .. (game.playerHp - juice.lastHp) .. " HP", 140, 580, UI.COLORS.hpGreen, 1.2)
        end
        juice.lastHp = game.playerHp
    end

    -- Update juice floating texts
    for i = #juice.floatingTexts, 1, -1 do
        local ft = juice.floatingTexts[i]
        ft.life = ft.life - dt
        ft.y = ft.y + ft.vy * dt
        if ft.life <= 0 then
            table.remove(juice.floatingTexts, i)
        end
    end

    -- If dragging a card, update its visual position
    if handDrag.active and handDrag.isDragging and handDrag.cardIndex then
        local c = game.hand[handDrag.cardIndex]
        if c then
            c.visualX = handDrag.currentX + handDrag.offsetX
            c.visualY = handDrag.currentY + handDrag.offsetY - 26
            c.rotation = math.max(-0.25, math.min(0.25, (handDrag.currentX - handDrag.startX) * 0.0015))
        end
    end

    -- Smooth background shader color interpolation based on active state / blind
    local targetA, targetB, targetC
    if state == "menu" then
        targetA = { 0.72, 0.10, 0.14 }
        targetB = { 0.08, 0.32, 0.75 }
        targetC = { 0.85, 0.20, 0.25 }
    elseif state == "shop" then
        targetA = { 0.11, 0.06, 0.18 }
        targetB = { 0.22, 0.10, 0.32 }
        targetC = { 0.55, 0.32, 0.12 }
    elseif state == "CASH_OUT" then
        targetA = { 0.14, 0.11, 0.05 }
        targetB = { 0.28, 0.22, 0.08 }
        targetC = { 0.60, 0.48, 0.14 }
    elseif state == "BLIND_SELECT" then
        targetA = { 0.05, 0.07, 0.14 }
        targetB = { 0.09, 0.14, 0.26 }
        targetC = { 0.18, 0.32, 0.55 }
    elseif (state == "playing" or state == "scoring") and game.monster and game.monster.isBoss then
        targetA = { 0.18, 0.04, 0.06 }
        targetB = { 0.38, 0.08, 0.10 }
        targetC = { 0.70, 0.15, 0.15 }
    elseif state == "playing" or state == "scoring" then
        targetA = { 0.05, 0.16, 0.11 }
        targetB = { 0.10, 0.32, 0.22 }
        targetC = { 0.18, 0.48, 0.30 }
    else
        targetA = { 0.06, 0.08, 0.14 }
        targetB = { 0.12, 0.15, 0.24 }
        targetC = { 0.25, 0.35, 0.50 }
    end

    if state == "CASH_OUT" and cashOutAnim then
        RewardSystem.update(cashOutAnim, dt)
    end

    local colLerp = math.min(1.0, dt * 4.0)
    for i = 1, 3 do
        bgCurrentColors.a[i] = bgCurrentColors.a[i] + (targetA[i] - bgCurrentColors.a[i]) * colLerp
        bgCurrentColors.b[i] = bgCurrentColors.b[i] + (targetB[i] - bgCurrentColors.b[i]) * colLerp
        bgCurrentColors.c[i] = bgCurrentColors.c[i] + (targetC[i] - bgCurrentColors.c[i]) * colLerp
    end

    -- Update tilt for hand cards
    if state == "playing" and game.hand and #game.hand > 0 then
        local mx, my = toVirtual(love.mouse.getPosition())
        local cardW = 95
        local cardH = 142
        for i, c in ipairs(game.hand) do
            local cx = c.visualX or 0
            local cy = c.visualY or 0
            local targetTiltX, targetTiltY = 0, 0
            if c.hovered or (handDrag.active and handDrag.cardIndex == i) then
                targetTiltX, targetTiltY = UI.calculateTilt(mx, my, cx, cy, cardW, cardH)
            end
            c.tiltX = (c.tiltX or 0) + (targetTiltX - (c.tiltX or 0)) * math.min(1.0, dt * 16)
            c.tiltY = (c.tiltY or 0) + (targetTiltY - (c.tiltY or 0)) * math.min(1.0, dt * 16)
        end
    end

    -- Update shop card drag position & tilt
    if shopDrag.active and shopDrag.isDragging then
        shopDrag.visualX = shopDrag.currentX - shopDrag.cardW / 2
        shopDrag.visualY = shopDrag.currentY - shopDrag.cardH / 2
        local mx, my = toVirtual(love.mouse.getPosition())
        local tX, tY = UI.calculateTilt(mx, my, shopDrag.visualX, shopDrag.visualY, shopDrag.cardW, shopDrag.cardH)
        shopDrag.tiltX = (shopDrag.tiltX or 0) + (tX - (shopDrag.tiltX or 0)) * math.min(1.0, dt * 16)
        shopDrag.tiltY = (shopDrag.tiltY or 0) + (tY - (shopDrag.tiltY or 0)) * math.min(1.0, dt * 16)
        shopDrag.rotation = math.max(-0.2, math.min(0.2, (shopDrag.currentX - shopDrag.startX) * 0.0015))
    end

    -- Update deity drag position
    if deityDrag.active and deityDrag.isDragging then
        deityDrag.visualX = deityDrag.currentX + (deityDrag.offsetX or -41)
        deityDrag.visualY = deityDrag.currentY + (deityDrag.offsetY or -59)
    end

    -- Smoothly update spark particles
    if anim.particles then
        for i = #anim.particles, 1, -1 do
            local p = anim.particles[i]
            p.life = p.life - dt
            if p.life <= 0 then
                table.remove(anim.particles, i)
            else
                p.x = p.x + p.vx * dt
                p.y = p.y + p.vy * dt + p.gravity * dt
                p.alpha = math.max(0, p.life / p.maxLife)
            end
        end
    end

    -- Fire Embers generation for Left Sidebar Mult & Score
    if state == "scoring" and anim.active then
        local multVal = anim.displayMult or 0
        if multVal >= 20 then
            local tier = (multVal >= 100) and 3 or ((multVal >= 50) and 2 or 1)
            -- Left Sidebar Mult box: x = 162, y = 229, w = 96, h = 50
            spawnFireEmbers(162, 229, 96, 50, tier)
        end

        local scoreVal = anim.displayFinalScore or 0
        if scoreVal >= 1000 then
            local tier = (scoreVal >= 50000) and 3 or ((scoreVal >= 10000) and 2 or 1)
            -- Left Sidebar Score panel: x = 25, y = 175, w = 245, h = 158
            spawnFireEmbers(25, 175, 245, 158, tier)
        end
    end

    if anim.fireParticles then
        for i = #anim.fireParticles, 1, -1 do
            local p = anim.fireParticles[i]
            p.life = p.life - dt
            p.age = (p.age or 0) + dt
            if p.life <= 0 then
                table.remove(anim.fireParticles, i)
            else
                p.x = p.x + (p.vx + math.sin(p.age * 12 + (p.phase or 0)) * 28) * dt
                p.y = p.y + p.vy * dt
                p.alpha = math.max(0, p.life / p.maxLife)
            end
        end
    end

    anim.impactFlash = math.max(0, (anim.impactFlash or 0) - dt)

    -- Scoring Animation Loop
    if state == "scoring" and anim.active then
        anim.entranceTimer = (anim.entranceTimer or 0) + dt
        anim.stepTimer = anim.stepTimer + (settings.fastScoring and dt * 2.0 or dt)
        local stepDelay = anim.targetStepDelay or 0.36

        if anim.stepTimer >= stepDelay then
            anim.stepTimer = 0
            anim.currentStepIndex = anim.currentStepIndex + 1
            anim.pitchStep = (anim.pitchStep or 0) + 1
            local pitch = math.min(2.2, 1.0 + (anim.pitchStep - 1) * 0.07)

            local steps = anim.scoringData.steps
            if anim.currentStepIndex <= #steps then
                local st = steps[anim.currentStepIndex]

                if st.type == "base_hand" then
                    anim.activeCardIndex = nil
                    anim.stepCategory = "TAY BÀI GỐC"
                    anim.stepLog = st.vnName .. ": " .. st.chips .. " Chips × " .. st.mult .. " Mult cơ bản"
                    anim.displayChips = st.chips
                    anim.displayMult = st.mult
                    anim.displayFinalScore = st.chips * st.mult
                    anim.bounceScale.chips = 1.35
                    anim.bounceScale.mult = 1.35
                    anim.bounceScale.score = 1.35
                    anim.targetStepDelay = 0.36
                    Sound.play("chip_tick", pitch)

                elseif st.type == "discard_buff_trigger" then
                    anim.activeCardIndex = nil
                    anim.stepCategory = "CHIẾN THUẬT BỎ BÀI"
                    anim.stepLog = st.message
                    if st.addedChips and st.addedChips > 0 then
                        anim.displayChips = anim.displayChips + st.addedChips
                        anim.bounceScale.chips = 1.35
                    end
                    if st.addedMult and st.addedMult > 0 then
                        anim.displayMult = anim.displayMult + st.addedMult
                        anim.bounceScale.mult = 1.35
                    end
                    if st.xMult and st.xMult > 1.0 then
                        anim.displayXMult = anim.displayXMult * st.xMult
                        anim.bounceScale.xMult = 1.45
                    end
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult * anim.displayXMult)
                    anim.bounceScale.score = 1.40
                    anim.targetStepDelay = 0.32
                    Sound.play("chip_tick", pitch)

                elseif st.type == "card_scored" then
                    anim.activeCardIndex = st.cardIndex
                    anim.scoredCards = anim.scoredCards or {}
                    anim.scoredCards[st.cardIndex] = { addedChips = st.addedChips, addedMult = st.addedMult }
                    anim.displayChips = anim.displayChips + st.addedChips
                    anim.displayMult = anim.displayMult + st.addedMult
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult * anim.displayXMult)
                    anim.stepCategory = "LÁ BÀI " .. st.cardIndex .. "/" .. #anim.playedCards
                    local trigStr = ""
                    if st.deityTriggers and #st.deityTriggers > 0 then
                        trigStr = " (" .. st.deityTriggers[1].message .. ")"
                    end
                    anim.stepLog = "Lá " .. st.card.rankName .. st.card.suitSymbol .. ": +" .. st.addedChips .. " Chips" .. (st.addedMult > 0 and (" & +" .. st.addedMult .. " Mult") or "") .. trigStr

                    -- Squash & Stretch + Spark burst
                    anim.cardBounce[st.cardIndex] = { scaleX = 0.84, scaleY = 1.28 }
                    anim.bounceScale.chips = 1.40
                    if st.addedMult > 0 then
                        anim.bounceScale.mult = 1.45
                    end
                    anim.bounceScale.score = 1.35
                    screenShake = math.max(screenShake, 2.0)

                    local cardW = 96
                    local cardGap = 16
                    local totalCardsW = #anim.playedCards * cardW + math.max(0, #anim.playedCards - 1) * cardGap
                    local startCX = 295 + (820 - totalCardsW) / 2
                    local cardCenterX = startCX + (st.cardIndex - 1) * (cardW + cardGap) + cardW / 2
                    local cardCenterY = 295 + 70 - 20
                    spawnSparks(cardCenterX, cardCenterY, 18, UI.COLORS.goldYellow)
                    anim.impactFlash = 0.18
                    anim.impactX = cardCenterX
                    anim.impactY = cardCenterY
                    anim.impactColor = UI.COLORS.goldYellow

                    anim.targetStepDelay = 0.34
                    Sound.play("chip_tick", pitch)

                elseif st.type == "equipment_trigger" then
                    anim.activeCardIndex = nil
                    if st.addedChips then
                        anim.displayChips = anim.displayChips + st.addedChips
                        anim.bounceScale.chips = 1.35
                        Sound.play("chip_tick", pitch)
                    end
                    if st.addedMult then
                        anim.displayMult = anim.displayMult + st.addedMult
                        anim.bounceScale.mult = 1.45
                        Sound.play("mult_pop", pitch)
                    end
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult * anim.displayXMult)
                    anim.bounceScale.score = 1.35
                    anim.stepCategory = "HIỆU ỨNG TRANG BỊ"
                    anim.stepLog = st.message
                    screenShake = math.max(screenShake, 3.0)
                    anim.targetStepDelay = 0.28

                elseif st.type == "armor_gain" then
                    anim.activeCardIndex = nil
                    anim.stepCategory = "PHÒNG NGỰ (GIÁP)"
                    anim.stepLog = st.message
                    Sound.play("chip_tick", pitch)
                    anim.targetStepDelay = 0.35
                    table.insert(anim.floatingTexts, {
                        text = "+" .. st.amount .. " GIÁP!",
                        color = { 0.35, 0.75, 1.0, 1 },
                        x = 140,
                        y = 540,
                        alpha = 2.0,
                    })

                elseif st.type == "heal_hp" then
                    anim.activeCardIndex = nil
                    anim.stepCategory = "HỒI SINH LỰC"
                    anim.stepLog = st.message
                    Sound.play("jackpot", pitch)
                    anim.targetStepDelay = 0.35
                    table.insert(anim.floatingTexts, {
                        text = "+" .. st.amount .. " HP!",
                        color = { 0.25, 0.95, 0.45, 1 },
                        x = 140,
                        y = 540,
                        alpha = 2.0,
                    })

                elseif st.type == "deity_hand" then
                    anim.activeCardIndex = nil
                    if st.addedChips > 0 then
                        anim.displayChips = anim.displayChips + st.addedChips
                        anim.bounceScale.chips = 1.35
                    end
                    if st.addedMult > 0 then
                        anim.displayMult = anim.displayMult + st.addedMult
                        anim.bounceScale.mult = 1.45
                    end

                    local dIdx = st.slotIndex
                    if not dIdx and st.deity then
                        local maxCheckSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 10
                        for di = 1, maxCheckSlots do
                            local d = game.deities and game.deities[di]
                            if d == st.deity or (d and d.id == st.deity.id) then dIdx = di break end
                        end
                    end
                    local dCenterX = 295 + 56
                    if dIdx then
                        anim.deityBounce[dIdx] = 1.45
                        dCenterX = 295 + (dIdx - 1) * (112 + 12) + 56
                    end
                    local dCenterY = 15 + 22 + 44

                    if st.xMult > 1.0 then
                        if st.resultingMult then
                            anim.displayMult = st.resultingMult
                        else
                            anim.displayMult = math.floor(anim.displayMult * st.xMult)
                        end
                        anim.bounceScale.xMult = 1.65
                        anim.bounceScale.mult = 1.65
                        anim.bounceScale.score = 1.70
                        screenShake = math.max(screenShake, math.min(5.5, 2.0 + st.xMult * 0.8))
                        Sound.play("xmult_boom", pitch)
                        spawnSparks(dCenterX, dCenterY, 28, UI.COLORS.xmultGold)
                        anim.targetStepDelay = 0.54 -- Suspense micro-pause!
                        table.insert(anim.floatingTexts, {
                            text = "x" .. string.format("%.2f", st.xMult) .. " XMult!",
                            color = UI.COLORS.xmultGold,
                            x = dCenterX,
                            y = dCenterY - 20,
                            alpha = 1.5,
                        })
                    else
                        if st.resultingMult then
                            anim.displayMult = st.resultingMult
                        end
                        anim.targetStepDelay = 0.30
                        Sound.play("mult_pop", pitch)
                        spawnSparks(dCenterX, dCenterY, 16, UI.COLORS.multRed)
                        table.insert(anim.floatingTexts, {
                            text = "+" .. st.addedMult .. " Mult!",
                            color = UI.COLORS.multRed,
                            x = dCenterX,
                            y = dCenterY - 20,
                            alpha = 1.3,
                        })
                    end
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult)
                    anim.stepCategory = "HỘ LINH: " .. (st.deity and st.deity.name or "BỔ TRỢ"):upper()
                    anim.stepLog = st.message

                elseif st.type == "seal_trigger" then
                    anim.activeCardIndex = st.cardIndex
                    anim.stepCategory = "CON DẤU (SEAL)"
                    anim.stepLog = st.message
                    Sound.play("jackpot", pitch)
                    anim.targetStepDelay = 0.34
                    table.insert(anim.floatingTexts, {
                        text = "KÍCH HOẠT LẠI (DẤU ĐỎ)!",
                        color = { 0.95, 0.25, 0.25, 1 },
                        x = 295 + (st.cardIndex - 1) * (96 + 16) + 48,
                        y = 300,
                        alpha = 1.8,
                    })

                elseif st.type == "deity_edition" then
                    anim.activeCardIndex = nil
                    local dIdx = st.slotIndex or 1
                    local dCenterX = 295 + (dIdx - 1) * (112 + 12) + 56
                    local dCenterY = 15 + 22 + 44
                    anim.deityBounce[dIdx] = 1.45

                    if st.edition == "foil" then
                        anim.displayChips = st.resultingChips or (anim.displayChips + (st.addedChips or 50))
                        anim.bounceScale.chips = 1.40
                        Sound.play("chip_tick", pitch)
                        spawnSparks(dCenterX, dCenterY, 20, { 0.4, 0.7, 1.0, 1 })
                        table.insert(anim.floatingTexts, {
                            text = "+50 CHIPS (FOIL)",
                            color = { 0.4, 0.7, 1.0, 1 },
                            x = dCenterX,
                            y = dCenterY - 20,
                            alpha = 1.6,
                        })
                    elseif st.edition == "holo" then
                        anim.displayMult = st.resultingMult or (anim.displayMult + (st.addedMult or 10))
                        anim.bounceScale.mult = 1.45
                        Sound.play("mult_pop", pitch)
                        spawnSparks(dCenterX, dCenterY, 20, { 0.9, 0.4, 0.9, 1 })
                        table.insert(anim.floatingTexts, {
                            text = "+10 MULT (HOLO)",
                            color = { 0.9, 0.4, 0.9, 1 },
                            x = dCenterX,
                            y = dCenterY - 20,
                            alpha = 1.6,
                        })
                    elseif st.edition == "polychrome" then
                        anim.displayMult = st.resultingMult or math.floor(anim.displayMult * 1.5)
                        anim.bounceScale.xMult = 1.65
                        anim.bounceScale.mult = 1.65
                        Sound.play("xmult_boom", pitch)
                        spawnSparks(dCenterX, dCenterY, 28, UI.COLORS.xmultGold)
                        table.insert(anim.floatingTexts, {
                            text = "x1.5 MULT (POLY)",
                            color = UI.COLORS.xmultGold,
                            x = dCenterX,
                            y = dCenterY - 20,
                            alpha = 1.8,
                        })
                    end
                    anim.displayFinalScore = math.floor(anim.displayChips * anim.displayMult)
                    anim.stepCategory = "PHÙ PHÉP HỘ LINH"
                    anim.stepLog = st.message
                    anim.targetStepDelay = 0.38

                elseif st.type == "final_score" then
                    anim.activeCardIndex = nil
                    local shakeAmt = math.min(6.5, 2.0 + math.log10(math.max(10, st.finalScore)) * 0.9)
                    screenShake = math.max(screenShake, shakeAmt)
                    anim.bounceScale.score = 1.85
                    Sound.play("score_impact", 0.95)
                    if st.finalScore >= 1000 then Sound.play("xmult_boom", 0.88) end
                    anim.displayFinalScore = st.finalScore
                    anim.stepCategory = "TỔNG SÁT THƯƠNG"
                    anim.stepLog = anim.displayChips .. " Chips × " .. anim.displayMult .. " Mult" .. (anim.displayXMult > 1.0 and (" × " .. anim.displayXMult .. " XMult") or "") .. " = " .. st.finalScore .. " Sát thương!"

                    local monsterHpBeforeHit = (game.monster and game.monster.hp) or 0
                    local actualDmg, defeated = Monster.takeDamage(game.monster, st.finalScore)
                    anim.damageDealt = actualDmg
                    anim.monsterDefeated = defeated

                    -- Damage projectile/impact directly into monster at top left
                    local mCenterX = 145
                    local mCenterY = 100
                    spawnSparks(mCenterX, mCenterY, 32, UI.COLORS.hpRed)
                    anim.impactFlash = 0.32
                    anim.impactX = mCenterX
                    anim.impactY = mCenterY
                    anim.impactColor = UI.COLORS.hpRed
                    table.insert(anim.floatingTexts, {
                        text = "-" .. UI.formatNumber(actualDmg) .. " HP!",
                        color = UI.COLORS.hpRed,
                        x = mCenterX,
                        y = mCenterY - 15,
                        alpha = 2.0,
                    })

                    if defeated then
                        Sound.play("jackpot")
                        spawnSparks(mCenterX, mCenterY, 40, UI.COLORS.goldYellow)
                        anim.targetStepDelay = 0.60

                        -- 1. A♠ Sát Khí tích lũy khi Overkill
                        if st.hasAceOfSpades then
                            local overkill = math.max(0, st.finalScore - monsterHpBeforeHit)
                            if overkill > 0 then
                                game.storedSlaughterChips = (game.storedSlaughterChips or 0) + overkill
                                table.insert(anim.floatingTexts, {
                                    text = "⚔️ SÁT KHÍ TÍCH LŨY (A♠): +" .. overkill .. " Chips ván sau!",
                                    color = UI.COLORS.goldYellow,
                                    x = 640,
                                    y = 330,
                                    alpha = 3.0,
                                })
                            end
                        end

                        -- 2. A♥ Chén Thánh Khát Máu (5% Máu tối đa của Boss thành Vàng, max $6)
                        if st.hasAceOfHearts then
                            local bloodGold = math.min(6, math.max(1, math.floor(((game.monster and game.monster.maxHp) or 100) * 0.05)))
                            game.gold = (game.gold or 0) + bloodGold
                            table.insert(anim.floatingTexts, {
                                text = "🩸 [Chén Thánh Khát Máu] Hút +" .. bloodGold .. "$ Vàng!",
                                color = UI.COLORS.goldYellow,
                                x = 640,
                                y = 360,
                                alpha = 3.0,
                            })
                        end

                        -- 3. ♣️ Bầy Nguyên Sinh: Tiến Hóa Nuốt Chửng (Predatory Evolution)
                        if anim.evalResult and anim.evalResult.scoringCards then
                            for _, sc in ipairs(anim.evalResult.scoringCards) do
                                local isClubSc = not sc.disableFactionPassives and (sc.suit == "clubs" or sc.suit == "elaris" or sc.suit == "feral_swarm" or sc.isWildSuit)
                                if isClubSc and sc.rank >= 2 and sc.rank <= 10 and not sc.isPrimalDrone then
                                    if sc.rank < 10 then
                                        sc.rank = sc.rank + 1
                                        sc.baseRank = sc.rank
                                        sc.rankName = Deck.RANK_NAMES[sc.rank] or tostring(sc.rank)
                                        sc.baseChips = Deck.getChipValue(sc.rank)
                                        table.insert(anim.floatingTexts, {
                                            text = "🧬 TIẾN HÓA: " .. sc.rankName .. "♣ lên Rank " .. sc.rank .. " vĩnh viễn!",
                                            color = { 0.2, 0.95, 0.4, 1 },
                                            x = 640,
                                            y = 390,
                                            alpha = 3.0,
                                        })
                                    elseif sc.rank == 10 then
                                        sc.isPrimalDrone = true
                                        sc.bonusBaseChips = (sc.bonusBaseChips or 0) + 50
                                        sc.bonusMult = (sc.bonusMult or 0) + 5
                                        sc.name = "Chân Rết Nguyên Thủy"
                                        sc.roleTitle = "Chân Rết Nguyên Thủy"
                                        sc.roleIcon = "🐛"
                                        table.insert(anim.floatingTexts, {
                                            text = "🦗 ĐỘT BIẾN TỘT CÙNG: Chân Rết Nguyên Thủy (+50c, +5m) vĩnh viễn!",
                                            color = UI.COLORS.goldYellow,
                                            x = 640,
                                            y = 390,
                                            alpha = 3.5,
                                        })
                                    end
                                    if game.persistentDeck then
                                        for _, pc in ipairs(game.persistentDeck) do
                                            if pc.id == sc.id then
                                                pc.baseRank = sc.baseRank or sc.rank
                                                pc.rank = pc.baseRank
                                                pc.rankName = Deck.RANK_NAMES[pc.baseRank] or tostring(pc.baseRank)
                                                pc.baseChips = Deck.getChipValue(pc.baseRank) + (sc.bonusBaseChips or 0)
                                                pc.bonusBaseChips = sc.bonusBaseChips or 0
                                                pc.bonusMult = sc.bonusMult or 0
                                                pc.isPrimalDrone = sc.isPrimalDrone
                                                pc.roleTitle = sc.roleTitle
                                                pc.roleIcon = sc.roleIcon
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        anim.targetStepDelay = 0.45
                    end

                    if st.bonusGold and st.bonusGold > 0 then
                        game.gold = game.gold + st.bonusGold
                    end

                    table.insert(anim.floatingTexts, {
                        text = "-" .. actualDmg .. " SÁT THƯƠNG!",
                        color = UI.COLORS.hpRed,
                        x = 160,
                        y = 230,
                        alpha = 1.5,
                    })

                    if defeated then
                        local baseReward = game.monster.isBoss and 15 or (game.monster.isElite and 10 or 4)
                        local unusedHandsBonus = game.handsRemaining * 1
                        local deityBonus = 0
                        local maxWinSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 10
                        for di = 1, maxWinSlots do
                            local d = game.deities and game.deities[di]
                            if d then
                                local effectiveDeity = Deities.resolveDeity and Deities.resolveDeity(game.deities, di) or d
                                if effectiveDeity and effectiveDeity.onRoundWin then
                                    local r = effectiveDeity.onRoundWin(game, effectiveDeity)
                                    if r and r.addGold then deityBonus = deityBonus + r.addGold end
                                    if r and r.message then
                                        local msg = d.isCopyDeity and (d.name .. " (Sao chép): " .. r.message) or r.message
                                        table.insert(anim.floatingTexts, {
                                            text = msg,
                                            color = UI.COLORS.goldYellow,
                                            x = 640,
                                            y = 190 - (di * 22),
                                            alpha = 2.8,
                                        })
                                    end
                                end
                                if d.extinct then
                                    game.deities[di] = nil
                                end
                            end
                        end

                        -- Tiền Lãi (Interest): Cứ mỗi $5 vàng tích trữ trong túi, sau trận được nhận thêm $1 tiền lãi (mặc định tối đa $3, voucher nâng lên $5)
                        local maxInt = game.maxInterest or 3
                        if game.vouchers and (game.vouchers["v_interest"] or game.vouchers["seed_money"]) then
                            maxInt = math.max(maxInt, 5)
                        end
                        local interestBonus = math.min(maxInt, math.floor(game.gold / 5))
                        if interestBonus > 0 then
                            table.insert(anim.floatingTexts, {
                                text = "[Tiền Lãi] +$" .. interestBonus .. " Vàng!",
                                color = UI.COLORS.goldYellow,
                                x = 640,
                                y = 230,
                                alpha = 2.5,
                            })
                        end

                        game.lastRoundDeityRewards = { bonusGold = deityBonus, details = deityDetails or {} }
                        if scoreResult and scoreResult.hasBountySeal and not game.bountySealClaimedThisCombat then
                            game.bountySealClaimedThisCombat = true
                            deityBonus = deityBonus + 2
                            table.insert(anim.floatingTexts, {
                                text = "💰 [ẤN TRUY NÃ] Kết liễu quái: +$2 Vàng!",
                                color = UI.COLORS.goldYellow,
                                x = 640,
                                y = 140,
                                alpha = 2.8,
                            })
                        end
                        anim.earnedGold = baseReward + unusedHandsBonus + deityBonus + interestBonus

                        -- Valoria Passive: +25% Gold on monster defeat
                        if game.selectedFaction == "valoria" or game.selectedSuit == "valoria" then
                            local valBonus = math.max(1, math.floor(anim.earnedGold * 0.25))
                            anim.earnedGold = anim.earnedGold + valBonus
                            table.insert(anim.floatingTexts, {
                                text = "[Hậu Cần Valoria] +" .. valBonus .. " Vàng (+25%)!",
                                color = UI.COLORS.goldYellow,
                                x = 640,
                                y = 280,
                                alpha = 2.5,
                            })
                        end

                        -- Elaris Passive: Lộc Biếc Đâm Chồi (Win within half of max hands upgrades a card)
                        if (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and game.handsRemaining >= math.ceil(game.maxHands / 2) then
                            if game.persistentDeck and #game.persistentDeck > 0 then
                                local targetCard = game.persistentDeck[Rng.random(#game.persistentDeck)]
                                Deck.upgradeCard(targetCard)
                                table.insert(anim.floatingTexts, {
                                    text = "[Lộc Biếc] Tôi luyện thành công lá " .. targetCard.rankName .. " " .. (targetCard.suitSymbol or "") .. " (+1 Rank)!",
                                    color = { 0.2, 0.85, 0.4, 1 },
                                    x = 640,
                                    y = 330,
                                    alpha = 3.0,
                                })
                            end
                        end

                        -- Blue Seal (Trance): Đóng Dấu Xanh Lam tạo lá bài Hành Tinh của thế bài chiến thắng cuối cùng nếu giữ trên tay
                        if game.hand and #game.hand > 0 and game.lastPlayedHandId then
                            for _, c in ipairs(game.hand) do
                                if c.seal == "blue" then
                                    local pScaling = Poker.HAND_LEVEL_SCALING[game.lastPlayedHandId]
                                    if pScaling and pScaling.planetId then
                                        local planetCard = nil
                                        for _, pc in ipairs(Poker.PLANET_CARDS) do
                                            if pc.id == pScaling.planetId then
                                                planetCard = pc
                                                break
                                            end
                                        end
                                        if planetCard then
                                            game.consumables = game.consumables or {}
                                            if #game.consumables < 2 then
                                                table.insert(game.consumables, {
                                                    id = planetCard.id,
                                                    category = "celestial",
                                                    name = planetCard.name,
                                                    handId = planetCard.handId,
                                                    desc = planetCard.desc,
                                                    icon = planetCard.icon,
                                                    color = planetCard.color,
                                                })
                                                table.insert(anim.floatingTexts, {
                                                    text = "🔵 [DẤU LAM] Tạo lá bài " .. planetCard.name .. "!",
                                                    color = { 0.35, 0.75, 1.0, 1 },
                                                    x = 640,
                                                    y = 360,
                                                    alpha = 3.0,
                                                })
                                            else
                                                table.insert(anim.floatingTexts, {
                                                    text = "🔵 [DẤU LAM] Ô Tiêu Hao đã đầy (2/2)!",
                                                    color = { 0.8, 0.8, 0.8, 1 },
                                                    x = 640,
                                                    y = 360,
                                                    alpha = 2.5,
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        -- Increment encounter count for next monster (starts at 10 HP, +50% each encounter indefinitely)
                        game.monsterEncounterCount = (game.monsterEncounterCount or 1) + 1

                        if not game.run then
                            game.gold = game.gold + anim.earnedGold
                        end
                        Sound.play("round_win")
                    else
                        -- 1. Boss Ability: The Arm degrades scoring cards by -1 rank
                        if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.debuffId == "the_arm" then
                            for _, sc in ipairs(anim.playedCards or {}) do
                                Deck.degradeCard(sc)
                            end
                            table.insert(anim.floatingTexts, {
                                text = "[THE ARM] Các lá bài bị suy đồi (-1 Rank)!",
                                color = { 0.85, 0.35, 0.35, 1 },
                                x = 640,
                                y = 400,
                                alpha = 2.5,
                            })
                        end

                        -- 2. Monster Counter-Attack on Player HP
                        local mAtk = (game.monster and game.monster.attack) or 12
                        local curArmor = (game.playerArmor or game.playerShield or 0)
                        local absorbed = math.min(curArmor, mAtk)
                        curArmor = curArmor - absorbed
                        -- Giáp còn lại sau đòn đánh của quái bị mất 50%
                        curArmor = math.floor(curArmor * 0.5)
                        game.playerArmor = curArmor
                        game.playerShield = curArmor
                        local dmgToPlayer = mAtk - absorbed

                        -- Anti-OneShot Protection: Hard cap single-hit damage to at most 60% of max HP
                        local maxDmgCap = math.floor((game.maxPlayerHp or 100) * 0.60)
                        if dmgToPlayer > maxDmgCap then
                            dmgToPlayer = maxDmgCap
                        end

                        game.playerHp = math.max(0, (game.playerHp or 100) - dmgToPlayer)

                        -- Monster Cuồng Nộ (Enrage) scaling: +8% Attack & +5% Armor each turn
                        if game.monster then
                            game.monster.attack = math.floor(game.monster.attack * 1.08 + 0.5)
                            game.monster.armor = math.floor((game.monster.armor or 0) * 1.05 + 2)
                        end

                        -- Escort Enhancement (Hộ Tống): unplayed cards in hand grant +5 Armor
                        for _, c in ipairs(game.hand or {}) do
                            if c.enhancement == "enh_escort" or c.enhancement == "escort" then
                                game.playerArmor = math.min(30, (game.playerArmor or 0) + 5)
                                game.playerShield = game.playerArmor
                            end
                        end

                        screenShake = 16
                        Sound.play("score_impact", 0.72)
                        local counterMsg = "[QUÁI PHẢN CÔNG] -" .. dmgToPlayer .. " HP!"
                        if absorbed > 0 then
                            counterMsg = "[QUÁI PHẢN CÔNG] Giáp đỡ " .. absorbed .. " | -" .. dmgToPlayer .. " HP!"
                        end
                        table.insert(anim.floatingTexts, {
                            text = counterMsg,
                            color = UI.COLORS.hpRed,
                            x = 640,
                            y = 350,
                            alpha = 2.5,
                        })

                        if game.playerHp <= 0 then
                            anim.playerKilled = true
                            Sound.play("game_over")
                        elseif game.handsRemaining <= 0 then
                            Sound.play("game_over")
                        end
                    end
                end
            else
                if anim.stepTimer >= 0.8 or anim.currentStepIndex > #steps + 1 then
                    anim.active = false
                    anim.playedCards = {}

                    -- Resolve from live HP/hand state so stale animation flags can
                    -- never turn a defeated monster into a game over.
                    local combatOutcome = Combat.getOutcome(game)
                    anim.monsterDefeated = combatOutcome == "victory"
                    anim.playerKilled = combatOutcome == "defeat" and game.playerHp ~= nil and game.playerHp <= 0

                    if anim.playerKilled then
                        state = "gameover"
                        Persistence.deleteRun()
                        Sound.play("game_over")
                        return
                    end
                    if combatOutcome == "defeat" then
                        state = "gameover"
                        Persistence.deleteRun()
                        Sound.play("game_over")
                        return
                    end

                    if anim.monsterDefeated then
                        -- Combat Victory: purge destroyed cards from persistent deck & restore base ranks
                        Combat.cleanupDestroyedCards(game)
                        if game.persistentDeck then
                            Deck.restoreDeck(game.persistentDeck)
                            game.masterDeck = game.persistentDeck
                            game.deck = {}
                            game.discardPile = {}
                            game.hand = {}
                            clearAllSelections()
                        end

                        if game.run then
                            local curBlind = RunManager.getCurrentBlind(game.run)
                            RunManager.completeCurrentBlind(game.run)
                            local breakdown = RewardSystem.calculate(curBlind, game, false)
                            game.gold = (game.gold or 0) + breakdown.totalGold
                            cashOutAnim = RewardSystem.newAnimation(breakdown)
                            state = "CASH_OUT"
                            lastActiveState = "CASH_OUT"
                            Sound.play("round_win")
                        elseif game.monster.isBoss then
                            -- Boss defeated: 2 Deities appear, pick 1 of 2!
                            game.bossDeityDraft = Deities.getBossDraftPool(game.deities, 2)
                            state = "boss_deity"
                            Sound.play("round_win")
                        elseif game.monster.isElite then
                            -- Elite monster defeated: complete node and open bonus treasure chest!
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            generateBossChestRewards()
                            socketingReturnState = "map"
                            state = "chest"
                            Sound.play("round_win")
                        else
                            -- Normal monster defeated: complete node and return to map!
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            state = "map"
                            Sound.play("round_win")
                        end
                    else
                        -- End of turn lifecycle:
                        Combat.cleanupDestroyedCards(game)
                        Combat.onPlayerTurnEnd(game)
                        local cleansed, cleanseMsg = Combat.onMonsterTurnEnd(game)
                        if cleansed then
                            table.insert(anim.floatingTexts, { text = "✨ " .. cleanseMsg, color = UI.COLORS.hpGreen, x = 640, y = 300, alpha = 3.0 })
                        end

                        -- Refill hand to maxHandSize cards while deck/discard has cards
                        local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
                        local dealOrder = 0
                        while #game.hand < maxHandSize do
                            if #game.deck == 0 and #game.discardPile > 0 then
                                while #game.discardPile > 0 do
                                    table.insert(game.deck, table.remove(game.discardPile))
                                end
                                Deck.shuffle(game.deck)
                            end
                            if #game.deck == 0 then break end
                            local drawn = table.remove(game.deck)
                            if drawn then
                                dealOrder = dealOrder + 1
                                drawn.selected = false
                                prepareDrawAnimation(drawn, dealOrder)
                                if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.debuffId == "the_fish" then
                                    drawn.faceDown = true
                                end
                                table.insert(game.hand, drawn)
                            end
                        end

                        if game.sortMode == "rank" then
                            Deck.sortByRank(game.hand)
                        else
                            Deck.sortBySuit(game.hand)
                        end

                        clearAllSelections()
                        syncCardSelections()
                        state = "playing"
                        Sound.play("card_deal")
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- DRAW FUNCTIONS
--------------------------------------------------------------------------------

local function drawMainMenu()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- 1. Dark vignette overlay allowing psychedelic background shader to pulse smoothly
    love.graphics.setColor(0.04, 0.05, 0.07, 0.45)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    -- Top corner subtle vignette
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, 120)

    -- 2. Top-right Version Indicators
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("1.0.1o-FULL", 0, 14, V_WIDTH - 24, "right")
    love.graphics.printf("1.0.0~BETA-1620a-TERRASUIT", 0, 28, V_WIDTH - 24, "right")

    -- 3. Majestic Gothic Title: "TERRA SUIT"
    local titleY = 44
    local fontLogo = UI.fonts.logo or UI.fonts.huge
    love.graphics.setFont(fontLogo)

    -- Extruded 3D Chiseled Metal Shadow
    for d = 8, 1, -1 do
        love.graphics.setColor(0.03, 0.04, 0.06, 0.95)
        love.graphics.printf("TERRA SUIT", d, titleY + d, V_WIDTH, "center")
    end

    -- 8-Direction Dark Outline
    love.graphics.setColor(0.08, 0.10, 0.14, 1)
    for ox = -3, 3, 3 do
        for oy = -3, 3, 3 do
            if ox ~= 0 or oy ~= 0 then
                love.graphics.printf("TERRA SUIT", ox, titleY + oy, V_WIDTH, "center")
            end
        end
    end

    -- Face Lettering: Weathered Ivory Gold
    love.graphics.setColor(0.96, 0.92, 0.82, 1)
    love.graphics.printf("TERRA SUIT", 0, titleY, V_WIDTH, "center")

    -- Inner Chiseled Gold Highlight Line
    love.graphics.setColor(0.98, 0.82, 0.28, 0.85)
    love.graphics.printf("TERRA SUIT", 0, titleY - 1, V_WIDTH, "center")

    -- Subtitle
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 0.9)
    love.graphics.printf("—  TÀN TÍCH VẬN MỆNH • ROGUELIKE POKER TCG  —", 0, titleY + 98, V_WIDTH, "center")

    ----------------------------------------------------------------------------
    -- 4. LEFT COLUMN: HỒ SƠ THỢ SĂN (Player Dossier)
    ----------------------------------------------------------------------------
    local dosX = 85
    local dosY = 185
    local dosW = 280
    local dosH = 435

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.6)
    UI.drawRoundedRect("fill", dosX + 5, dosY + 7, dosW, dosH, 10)

    -- Dossier Body
    love.graphics.setColor(0.10, 0.12, 0.15, 0.96)
    UI.drawRoundedRect("fill", dosX, dosY, dosW, dosH, 10)

    -- Double Gothic Frame
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(0.75, 0.62, 0.24, 0.9)
    UI.drawRoundedRect("line", dosX, dosY, dosW, dosH, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.45, 0.38, 0.20, 0.6)
    UI.drawRoundedRect("line", dosX + 4, dosY + 4, dosW - 8, dosH - 8, 8)

    -- Corner Fleuron Lines
    love.graphics.setColor(0.85, 0.72, 0.25, 0.85)
    love.graphics.line(dosX + 7, dosY + 12, dosX + 7, dosY + 7, dosX + 12, dosY + 7)
    love.graphics.line(dosX + dosW - 7, dosY + 12, dosX + dosW - 7, dosY + 7, dosX + dosW - 12, dosY + 7)
    love.graphics.line(dosX + 7, dosY + dosH - 12, dosX + 7, dosY + dosH - 7, dosX + 12, dosY + dosH - 7)
    love.graphics.line(dosX + dosW - 7, dosY + dosH - 12, dosX + dosW - 7, dosY + dosH - 7, dosX + dosW - 12, dosY + dosH - 7)

    -- Top Wax Seal
    local sealCX = dosX + dosW / 2
    local sealCY = dosY + 32
    local sR = 17
    love.graphics.setColor(0.55, 0.08, 0.10, 0.95)
    for a = 0, 5 do
        local ang = a * (math.pi / 3)
        love.graphics.circle("fill", sealCX + math.cos(ang) * (sR - 2), sealCY + math.sin(ang) * (sR - 2), 6)
    end
    love.graphics.setColor(0.72, 0.12, 0.15, 1)
    love.graphics.circle("fill", sealCX, sealCY, sR)
    love.graphics.setColor(0.52, 0.08, 0.10, 1)
    love.graphics.circle("fill", sealCX, sealCY, sR - 3.5)
    -- Stamped Crown
    love.graphics.setColor(0.95, 0.82, 0.35, 1)
    love.graphics.polygon("fill", sealCX - 7, sealCY + 4, sealCX - 8, sealCY - 4, sealCX - 3, sealCY - 1, sealCX, sealCY - 5, sealCX + 3, sealCY - 1, sealCX + 8, sealCY - 4, sealCX + 7, sealCY + 4)

    -- Dossier Text
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("HỒ SƠ KẺ THÁCH ĐẤU", dosX, dosY + 62, dosW, "center")

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Nhatnam", dosX, dosY + 84, dosW, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.bossPurple)
    love.graphics.printf("DANH HIỆU: ĐỒ TỆ CỔ TỘC", dosX, dosY + 116, dosW, "center")

    -- Divider
    love.graphics.setColor(0.35, 0.30, 0.22, 0.8)
    love.graphics.setLineWidth(1)
    love.graphics.line(dosX + 20, dosY + 138, dosX + dosW - 20, dosY + 138)

    -- Dossier Stats List
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    local statRows = {
        { label = "Ván cao nhất:", val = "Ante 8 (Thắng)" },
        { label = "Sát thương kỷ lục:", val = "1,234,567" },
        { label = "Hộ Linh mở khóa:", val = "9 / 9" },
        { label = "Trang bị khảm:", val = "8 / 8" },
        { label = "Bộ bài sở hữu:", val = "4 / 4 Cự Tộc" },
    }
    local rowY = dosY + 154
    for _, sr in ipairs(statRows) do
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf(sr.label, dosX + 16, rowY, dosW - 32, "left")
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(sr.val, dosX + 16, rowY, dosW - 32, "right")
        rowY = rowY + 28
    end

    -- Dossier Change Profile Button
    local btnProf = {
        id = "menu_profile",
        text = "Đổi Hồ Sơ",
        x = dosX + 20,
        y = dosY + dosH - 56,
        w = dosW - 40,
        h = 38,
        color = UI.COLORS.btnNormal,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnProf)

    ----------------------------------------------------------------------------
    -- 5. CENTERPIECE: THE FLOATING ELDRITCH TAROT CARD
    ----------------------------------------------------------------------------
    local emblemCX = 575
    local cardFloatY = 385 + math.sin((juice.ambientTimer or 0) * 2.0) * 8
    local cardTilt = math.sin((juice.ambientTimer or 0) * 1.5) * 0.04

    love.graphics.push()
    love.graphics.translate(emblemCX, cardFloatY)
    love.graphics.rotate(cardTilt)

    local cardW = 165
    local cardH = 245
    local halfW = cardW / 2
    local halfH = cardH / 2

    -- Card 3D drop shadow
    love.graphics.setColor(0, 0, 0, 0.65)
    UI.drawRoundedRect("fill", -halfW + 10, -halfH + 12, cardW, cardH, 10)

    -- Card Gilded Gold Frame
    love.graphics.setColor(0.92, 0.76, 0.22, 1)
    UI.drawRoundedRect("fill", -halfW, -halfH, cardW, cardH, 10)

    -- Card Body: Deep Obsidian Parchment
    love.graphics.setColor(0.10, 0.12, 0.15, 0.98)
    UI.drawRoundedRect("fill", -halfW + 5, -halfH + 5, cardW - 10, cardH - 10, 8)

    -- Inner Card Decorative Frame
    love.graphics.setColor(0.68, 0.55, 0.20, 0.75)
    love.graphics.setLineWidth(1)
    UI.drawRoundedRect("line", -halfW + 10, -halfH + 10, cardW - 20, cardH - 20, 6)

    -- Center Eldritch Sigil: Ancient Mystical Eye & Occult Radiance
    love.graphics.setColor(0.85, 0.25, 0.35, 0.22)
    love.graphics.circle("fill", 0, -10, 48)
    love.graphics.setColor(0.95, 0.82, 0.28, 0.40)
    love.graphics.circle("line", 0, -10, 50)

    -- Tarot Title Ribbon
    love.graphics.setColor(0.06, 0.07, 0.09, 0.95)
    love.graphics.rectangle("fill", -halfW + 14, -halfH + 16, cardW - 28, 24, 3)
    love.graphics.setColor(0.85, 0.72, 0.25, 0.8)
    love.graphics.rectangle("line", -halfW + 14, -halfH + 16, cardW - 28, 24, 3)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CỔ VẬT VẬN MỆNH", -halfW + 14, -halfH + 21, cardW - 28, "center")

    -- Crossed Dark Spectral Chains
    local function drawChainLink(lx, ly, lrot)
        love.graphics.push()
        love.graphics.translate(lx, ly)
        love.graphics.rotate(lrot)
        love.graphics.setColor(0.14, 0.17, 0.22, 0.95)
        love.graphics.rectangle("fill", -10, -5, 20, 10, 4, 4)
        love.graphics.setColor(0.78, 0.84, 0.92, 1)
        love.graphics.rectangle("fill", -8, -3, 16, 6, 3, 3)
        love.graphics.setColor(0.14, 0.17, 0.22, 1)
        love.graphics.rectangle("fill", -3, -1, 6, 2, 1, 1)
        love.graphics.pop()
    end

    local dAngle = math.atan2(cardH, cardW)
    for t = -0.42, 0.42, 0.14 do
        drawChainLink(t * cardW * 0.92, t * cardH * 0.92, dAngle)
        drawChainLink(-t * cardW * 0.92, t * cardH * 0.92, -dAngle)
    end

    -- Center Forged Padlock
    local lockW = 48
    local lockH = 42
    local shackleR = 15
    love.graphics.setColor(0.70, 0.76, 0.84, 1)
    love.graphics.setLineWidth(5)
    love.graphics.arc("line", "open", 0, -12, shackleR, math.pi, 2 * math.pi)

    love.graphics.setColor(0.24, 0.28, 0.35, 1)
    UI.drawRoundedRect("fill", -lockW / 2, -10, lockW, lockH, 6)
    love.graphics.setColor(0.85, 0.72, 0.25, 0.9)
    UI.drawRoundedRect("line", -lockW / 2, -10, lockW, lockH, 6)

    -- Keyhole
    love.graphics.setColor(0.06, 0.08, 0.12, 1)
    love.graphics.circle("fill", 0, 7, 5)
    love.graphics.polygon("fill", -3, 7, 3, 7, 1.5, 18, -1.5, 18)

    love.graphics.pop()

    ----------------------------------------------------------------------------
    -- 6. RIGHT COLUMN: HERO ACTION STACK (Tactile 3D Buttons)
    ----------------------------------------------------------------------------
    local btnStackX = 775
    local btnStackW = 390
    local startBtnY = 195

    -- 1. Hero Button: VÀO TRẬN (PLAY)
    local playText = hasRunStarted and "TIẾP TỤC TRẬN [Space]" or "VÀO TRẬN [Space]"
    local btnPlay = {
        id = "menu_play",
        text = playText,
        x = btnStackX,
        y = startBtnY,
        w = btnStackW,
        h = 76,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.title or UI.fonts.large,
    }
    table.insert(buttons, btnPlay)

    -- 2. Button: BỘ SƯU TẬP (COLLECTION)
    local btnCollection = {
        id = "menu_collection",
        text = "BỘ SƯU TẬP [C]",
        x = btnStackX,
        y = startBtnY + 92,
        w = btnStackW,
        h = 64,
        color = UI.COLORS.btnSpecial,
        font = UI.fonts.large,
    }
    table.insert(buttons, btnCollection)

    -- 3. Button: TUỲ CHỌN (SETTINGS)
    local btnOptions = {
        id = "menu_settings",
        text = "TUỲ CHỌN [Tab]",
        x = btnStackX,
        y = startBtnY + 172,
        w = btnStackW,
        h = 64,
        color = UI.COLORS.btnNormal,
        font = UI.fonts.large,
    }
    table.insert(buttons, btnOptions)

    -- 4. Button: THOÁT (QUIT)
    local btnQuit = {
        id = "menu_quit",
        text = "THOÁT [Esc]",
        x = btnStackX,
        y = startBtnY + 252,
        w = btnStackW,
        h = 64,
        color = UI.COLORS.btnDestruct,
        font = UI.fonts.large,
    }
    table.insert(buttons, btnQuit)

    -- Render all interactive 3D buttons
    for _, btn in ipairs(buttons) do
        local isH = (mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
        local isP = (juice.buttonPressedId == btn.id)
        UI.drawButton(btn, isH, isP)
    end

    ----------------------------------------------------------------------------
    -- 7. FOOTER BAR: MODS, LANGUAGE & COMMUNITY
    ----------------------------------------------------------------------------
    local footY = 652
    local footH = 34

    -- Left: Version & Engine Info
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("TERRA SUIT v1.0.1o • ENGINE POKER ROGUELIKE", 85, footY + 8, 400, "left")

    -- Right Footer Buttons
    local btnMod = {
        id = "menu_mod",
        text = "MOD",
        x = 815,
        y = footY,
        w = 80,
        h = footH,
        color = { 0.32, 0.38, 0.52, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnMod)
    UI.drawButton(btnMod, mx >= btnMod.x and mx <= btnMod.x + btnMod.w and my >= btnMod.y and my <= btnMod.y + btnMod.h, juice.buttonPressedId == btnMod.id)

    local btnLang = {
        id = "menu_lang",
        text = "A文 Tiếng Việt",
        x = 905,
        y = footY,
        w = 150,
        h = footH,
        color = { 0.16, 0.24, 0.28, 1 },
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnLang)
    UI.drawButton(btnLang, mx >= btnLang.x and mx <= btnLang.x + btnLang.w and my >= btnLang.y and my <= btnLang.y + btnLang.h, juice.buttonPressedId == btnLang.id)

    local btnDiscord = {
        id = "menu_discord",
        text = "Dc",
        x = 1065,
        y = footY,
        w = 46,
        h = footH,
        color = { 0.32, 0.40, 0.88, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnDiscord)
    UI.drawButton(btnDiscord, mx >= btnDiscord.x and mx <= btnDiscord.x + btnDiscord.w and my >= btnDiscord.y and my <= btnDiscord.y + btnDiscord.h, juice.buttonPressedId == btnDiscord.id)

    local btnX = {
        id = "menu_x",
        text = "𝕏",
        x = 1120,
        y = footY,
        w = 46,
        h = footH,
        color = { 0.14, 0.14, 0.16, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnX)
    UI.drawButton(btnX, mx >= btnX.x and mx <= btnX.x + btnX.w and my >= btnX.y and my <= btnX.y + btnH, juice.buttonPressedId == btnX.id)
end

local function drawCollectionModal()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {} -- Clear previous menu buttons so they don't draw or capture clicks inside the modal!
    -- Dim background
    love.graphics.setColor(0.06, 0.07, 0.10, 1.0)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    local modalW = 820
    local modalH = 590
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal background & border
    love.graphics.setColor(0, 0, 0, 0.5)
    UI.drawRoundedRect("fill", modalX + 4, modalY + 6, modalW, modalH, 12)
    love.graphics.setColor(0.22, 0.28, 0.31, 0.98) -- #38464d
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setColor(0.31, 0.39, 0.44, 1)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    local colW = 340
    local colLX = modalX + 26
    local colRX = modalX + modalW - 26 - colW

    -- LEFT COLUMN
    -- 1. Joker (Thần Hộ Mệnh)
    local jokersCount = #Collection.getItems("jokers")
    local btnJoker = {
        id = "coll_cat_jokers",
        catId = "jokers",
        text = "Hộ Linh",
        sub = jokersCount .. " / " .. jokersCount,
        x = colLX,
        y = modalY + 24,
        w = colW,
        h = 76,
        color = { 0.55, 0.16, 0.14, 1 },
        font = UI.fonts.large,
    }
    table.insert(buttons, btnJoker)

    -- 2. Bộ Bài (Factions)
    local decksCount = #Collection.getItems("decks")
    local btnDecks = {
        id = "coll_cat_decks",
        catId = "decks",
        text = "Bộ Bài",
        sub = decksCount .. " / " .. decksCount,
        x = colLX,
        y = modalY + 112,
        w = colW,
        h = 48,
        color = { 0.92, 0.28, 0.22, 1 },
        font = UI.fonts.medium,
    }
    table.insert(buttons, btnDecks)

    -- 3. Phiếu (Vouchers)
    local vouchersCount = #Collection.getItems("vouchers")
    local btnVouchers = {
        id = "coll_cat_vouchers",
        catId = "vouchers",
        text = "Phiếu",
        sub = vouchersCount .. " / " .. vouchersCount,
        x = colLX,
        y = modalY + 172,
        w = colW,
        h = 48,
        color = { 0.92, 0.28, 0.22, 1 },
        font = UI.fonts.medium,
        alert = true,
    }
    table.insert(buttons, btnVouchers)

    -- 4. Section Lá Tiêu Thụ / Trang Bị Khảm (Dark inset with vertical tab and large orange card)
    local boxY = modalY + 232
    local boxH = 270
    love.graphics.setColor(0.12, 0.16, 0.18, 1)
    UI.drawRoundedRect("fill", colLX, boxY, colW, boxH, 8)
    love.graphics.setColor(0.22, 0.28, 0.32, 1)
    UI.drawRoundedRect("line", colLX, boxY, colW, boxH, 8)

    -- Vertical label "LÁ TIÊU THỤ"
    love.graphics.push()
    love.graphics.translate(colLX + 14, boxY + boxH - 25)
    love.graphics.rotate(-math.pi / 2)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("LÁ TIÊU THỤ", 0, 0)
    love.graphics.pop()

    -- Large orange card button inside
    local eqCount = #Collection.getItems("consumables")
    local btnConsumables = {
        id = "coll_cat_consumables",
        catId = "consumables",
        text = "Lá Tiêu Thụ",
        sub = "Trang Bị Khảm\n" .. eqCount .. " / " .. eqCount,
        x = colLX + 44,
        y = boxY + 12,
        w = colW - 56,
        h = boxH - 24,
        color = { 0.96, 0.54, 0.08, 1 },
        font = UI.fonts.large,
        isMultiLine = true,
    }
    table.insert(buttons, btnConsumables)

    -- RIGHT COLUMN
    local rButtons = {
        { id = "coll_cat_enhancements", catId = "enhancements", text = "Lá Cường Hoá", y = modalY + 24, h = 46 },
        { id = "coll_cat_seals", catId = "seals", text = "Con Dấu", y = modalY + 76, h = 46 },
        { id = "coll_cat_editions", catId = "editions", text = "Ấn Bản", y = modalY + 128, h = 46, alert = true },
        { id = "coll_cat_packs", catId = "packs", text = "Gói Bài", y = modalY + 180, h = 46 },
        { id = "coll_cat_tags", catId = "tags", text = "Khế Ước Bỏ Ải", y = modalY + 232, h = 46, alert = true },
        { id = "coll_cat_blinds", catId = "blinds", text = "Blind", y = modalY + 284, h = 86, alert = true },
        { id = "coll_cat_other", catId = "other", text = "Khác", sub = "Tổ Hợp & Điểm Số", y = modalY + 376, h = 46 },
    }
    for _, rb in ipairs(rButtons) do
        rb.x = colRX
        rb.w = colW
        rb.color = { 0.92, 0.28, 0.22, 1 }
        rb.font = UI.fonts.regular
        if not rb.sub then
            local count = #Collection.getItems(rb.catId)
            rb.sub = count .. " / " .. count
        end
        table.insert(buttons, rb)
    end

    -- BOTTOM: Trở Lại (Orange button spanning full modal width)
    local btnBack = {
        id = "coll_close",
        text = "Trở Lại",
        x = modalX + 26,
        y = modalY + modalH - 60,
        w = modalW - 52,
        h = 44,
        color = { 0.96, 0.54, 0.08, 1 },
        font = UI.fonts.medium,
    }
    table.insert(buttons, btnBack)

    -- Draw all buttons in this modal
    for _, btn in ipairs(buttons) do
        local isH = (mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
        local isP = (juice and juice.buttonPressedId == btn.id)
        UI.drawButton(btn, isH, isP)
    end
end

local function drawCollectionDetailView()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Dim background
    love.graphics.setColor(0.06, 0.07, 0.10, 1.0)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    local cat = Collection.getCategoryById(collectionCategory) or { title = "Danh Mục", sub = "" }
    local items = Collection.getItems(collectionCategory)

    local modalW = 1180
    local modalH = 640
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal box
    love.graphics.setColor(0.14, 0.18, 0.21, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setColor(0.28, 0.38, 0.44, 1)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header Navigation
    local btnBack = {
        id = "coll_back_to_hub",
        text = "< QUAY LẠI BỘ SƯU TẬP",
        x = modalX + 24,
        y = modalY + 16,
        w = 230,
        h = 38,
        color = { 0.96, 0.54, 0.08, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnBack)
    local isBackH = (mx >= btnBack.x and mx <= btnBack.x + btnBack.w and my >= btnBack.y and my <= btnBack.y + btnBack.h)
    UI.drawButton(btnBack, isBackH, juice.buttonPressedId == btnBack.id)

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print(string.upper(cat.title) .. " • " .. cat.sub, modalX + 270, modalY + 20)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print(#items .. " Mục đã mở khóa • Nhấp hoặc rê chuột vào thẻ để xem chi tiết", modalX + 272, modalY + 48)

    -- Layout: Left Area is Grid (width ~ 750), Right Area is Inspector (width ~ 360)
    local gridX = modalX + 24
    local gridY = modalY + 75
    local gridW = 750
    local gridH = modalH - 95

    local hoveredItem = nil

    -- Render Cards in Grid
    local cardW = 112
    local cardH = 158
    local cols = 6
    local padX = 14
    local padY = 16
    local rows = math.ceil(#items / cols)
    local totalContentH = rows * (cardH + padY)
    local maxScroll = math.max(0, totalContentH - (gridH - 10))
    collectionScrollY = math.max(0, math.min(maxScroll, collectionScrollY or 0))

    love.graphics.intersectScissor(gridX, gridY, gridW, gridH)

    for i, item in ipairs(items) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = gridX + col * (cardW + padX)
        local cy = gridY + row * (cardH + padY) - collectionScrollY

        if cy + cardH >= gridY - 20 and cy <= gridY + gridH + 20 then
            local isH = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH and my >= gridY and my <= gridY + gridH)
            if isH then hoveredItem = item end

            -- 3D Tilt calculation
            local tX, tY = 0, 0
            if isH then
                tX, tY = UI.calculateTilt(mx, my, cx, cy, cardW, cardH)
            end

            love.graphics.push()
            love.graphics.translate(cx + cardW / 2, cy + cardH / 2)
            if isH then
                love.graphics.shear(tX * 0.08, tY * 0.08)
                love.graphics.scale(1.05, 1.05)
            end
            love.graphics.translate(-cardW / 2, -cardH / 2)

            -- Card Body
            local dImg = (collectionCategory == "jokers") and UI.getDeityImage(item.id)
            if dImg then
                love.graphics.setColor(0, 0, 0, 0.35)
                UI.drawRoundedRect("fill", 2, 4, cardW, cardH, 8)

                love.graphics.setColor(1, 1, 1, 1)
                local iw, ih = dImg:getDimensions()
                love.graphics.draw(dImg, 0, 0, 0, cardW / iw, cardH / ih)

                if isH then
                    love.graphics.setLineWidth(2.5)
                    love.graphics.setColor(UI.COLORS.goldYellow)
                    UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)
                end
            else
                local itemCol = item.color or { 0.3, 0.4, 0.5, 1 }
                love.graphics.setColor(0, 0, 0, 0.35)
                UI.drawRoundedRect("fill", 2, 4, cardW, cardH, 8)

                love.graphics.setColor(0.18, 0.22, 0.26, 1)
                UI.drawRoundedRect("fill", 0, 0, cardW, cardH, 8)

                -- Card Header Banner
                love.graphics.setColor(itemCol[1], itemCol[2], itemCol[3], 0.9)
                UI.drawRoundedRect("fill", 0, 0, cardW, 26, 8)
                UI.drawRoundedRect("fill", 0, 16, cardW, 10, 0)

                -- Card Border
                love.graphics.setLineWidth(isH and 2.5 or 1.5)
                love.graphics.setColor(isH and UI.COLORS.goldYellow or { itemCol[1], itemCol[2], itemCol[3], 0.8 })
                UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)

                -- Card Icon
                love.graphics.setFont(UI.fonts.large)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(item.icon or "🃏", 0, 48, cardW, "center")

                -- Card Name
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(1, 1, 1, 1)
                local cleanName = UI.truncateUtf8(item.name, 16)
                love.graphics.printf(cleanName, 4, 100, cardW - 8, "center")

                -- Rarity / Cost pill
                if item.cost then
                    love.graphics.setFont(UI.fonts.tiny)
                    love.graphics.setColor(UI.COLORS.goldYellow)
                    love.graphics.printf("$" .. item.cost, 0, 134, cardW, "center")
                elseif item.rarity then
                    love.graphics.setFont(UI.fonts.tiny)
                    love.graphics.setColor(UI.COLORS.textMuted)
                    love.graphics.printf(item.rarity, 0, 134, cardW, "center")
                end
            end

            love.graphics.pop()
        end
    end

    -- Scrollbar track & thumb if scrollable
    if maxScroll > 0 then
        local trackX = gridX + gridW - 6
        local trackY = gridY + 4
        local trackH = gridH - 8
        love.graphics.setColor(0.12, 0.15, 0.18, 0.6)
        UI.drawRoundedRect("fill", trackX, trackY, 4, trackH, 2)
        local thumbH = math.max(24, trackH * (gridH / totalContentH))
        local thumbY = trackY + (collectionScrollY / maxScroll) * (trackH - thumbH)
        love.graphics.setColor(0.45, 0.55, 0.65, 0.8)
        UI.drawRoundedRect("fill", trackX, thumbY, 4, thumbH, 2)
    end

    love.graphics.setScissor()

    -- Right Area: Item Inspector / Detail Preview
    local inspItem = hoveredItem or selectedCollectionItem or items[1]
    if inspItem then
        local inspX = modalX + gridW + 40
        local inspY = gridY
        local inspW = modalW - gridW - 64
        local inspH = gridH

        -- Inspector Box
        love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
        UI.drawRoundedRect("fill", inspX, inspY, inspW, inspH, 10)
        love.graphics.setColor(0.25, 0.35, 0.42, 1)
        UI.drawRoundedRect("line", inspX, inspY, inspW, inspH, 10)

        -- Large Preview Card (Center of top half)
        local lcw = 140
        local lch = 195
        local lcx = inspX + (inspW - lcw) / 2
        local lcy = inspY + 20
        local lcol = inspItem.color or { 0.3, 0.4, 0.5, 1 }

        local inspImg = (collectionCategory == "jokers") and UI.getDeityImage(inspItem.id)
        if inspImg then
            love.graphics.setColor(1, 1, 1, 1)
            local iw, ih = inspImg:getDimensions()
            love.graphics.draw(inspImg, lcx, lcy, 0, lcw / iw, lch / ih)
            love.graphics.setLineWidth(2)
            love.graphics.setColor(lcol)
            UI.drawRoundedRect("line", lcx, lcy, lcw, lch, 10)
        else
            love.graphics.setColor(0.16, 0.20, 0.24, 1)
            UI.drawRoundedRect("fill", lcx, lcy, lcw, lch, 10)
            love.graphics.setColor(lcol[1], lcol[2], lcol[3], 0.95)
            UI.drawRoundedRect("fill", lcx, lcy, lcw, 32, 10)
            UI.drawRoundedRect("fill", lcx, lcy + 18, lcw, 14, 0)
            love.graphics.setLineWidth(2)
            love.graphics.setColor(lcol)
            UI.drawRoundedRect("line", lcx, lcy, lcw, lch, 10)

            love.graphics.setFont(UI.fonts.huge)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(inspItem.icon or "🃏", lcx, lcy + 55, lcw, "center")
        end

        -- Item Header Info below card
        local infoY = lcy + lch + 18
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(lcol)
        love.graphics.printf(inspItem.name, inspX + 16, infoY, inspW - 32, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf(inspItem.subtitle or inspItem.rarity or "", inspX + 16, infoY + 28, inspW - 32, "center")

        -- Stats banner
        if inspItem.cost then
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("GIÁ MUA: $" .. inspItem.cost, inspX + 16, infoY + 52, inspW - 32, "center")
        end

        -- Detailed Description
        local descY = infoY + (inspItem.cost and 78 or 58)
        love.graphics.setColor(0.14, 0.18, 0.22, 1)
        UI.drawRoundedRect("fill", inspX + 14, descY, inspW - 28, inspH - (descY - inspY) - 16, 8)
        love.graphics.setColor(0.24, 0.32, 0.38, 1)
        UI.drawRoundedRect("line", inspX + 14, descY, inspW - 28, inspH - (descY - inspY) - 16, 8)

        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(inspItem.desc, inspX + 24, descY + 14, inspW - 48, "left")
    end
end

local function drawFactionSelect()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(UI.COLORS.bg)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Back button
    local btnBack = {
        id = "back_to_title",
        text = "< QUAY LẠI MENU CHÍNH",
        x = 40,
        y = 35,
        w = 220,
        h = 38,
        font = UI.fonts.small,
        color = UI.COLORS.btnNormal,
    }
    table.insert(buttons, btnBack)
    local isBackH = (mx >= btnBack.x and mx <= btnBack.x + btnBack.w and my >= btnBack.y and my <= btnBack.y + btnBack.h)
    local isBackP = (juice.buttonPressedId == btnBack.id)
    UI.drawButton(btnBack, isBackH, isBackP)

    -- Header Title
    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("LỰA CHỌN PHE PHÁI KHỞI ĐẦU", 0, 35, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Mỗi phe sở hữu bộ bài và ban ơn thần thánh đặc trưng (Bắt đầu với 3 lá ngẫu nhiên):", 0, 85, V_WIDTH, "center")

    -- 4 Faction Selection Cards (Grimdark Archetypes)
    local factions = {
        {
            id = "vharos",
            title = "THIẾT QUÂN THỨ",
            color = Deck.FACTIONS.vharos.color,
            badge = "The Iron Axiom ♠",
            blessing = "• Chỉ Số Thép: +20 Chips & Miễn nhiễm 100% debuff Boss.\n• Quân Lực Phalanx: Chuỗi Rank tăng dần thưởng +(ΔRank×10) Chips.\n• Axiom Lock: Cố định bài Bích trên tay theo Rank tăng dần.",
        },
        {
            id = "valoria",
            title = "GIÁO HỘI HUYẾT ƯỚC",
            color = Deck.FACTIONS.valoria.color,
            badge = "Sanguine Covenant ♥",
            blessing = "• Huyết Tế: Discard Chiến Binh Cơ gây True Damage = Rank.\n• Dấu Ấn Tử Đạo: Discard tích ấn (max 5), bùng nổ +8 Mult & x(1+0.15×ấn).\n• Huyết Ước: +5 Mult mỗi lá Cơ.",
        },
        {
            id = "aurelia",
            title = "TRẬT TỰ HOÀNG KIM",
            color = Deck.FACTIONS.aurelia.color,
            badge = "Gilded Conclave ♦",
            blessing = "• Kim Ngân: +$1 Vàng mỗi lá Rô ghi điểm.\n• Trần Lãi Siêu Việt: +$1 lãi mỗi $4 sở hữu (Không giới hạn trần!).\n• Khảm Nén Quặng: Mở sẵn 2 Lỗ Khảm, đá khảm tăng +50% hiệu lực.",
        },
        {
            id = "elaris",
            title = "BẦY NGUYÊN SINH",
            color = Deck.FACTIONS.elaris.color,
            badge = "The Feral Swarm ♣",
            blessing = "• Bầy Đàn: Cầm 9 lá bài trên tay.\n• Tuần Hoàn Thể: Discard Chuồn chui xuống đáy bộ bài.\n• Tiến Hóa Nuốt Chửng: Dứt điểm tăng +1 Rank (Rank 10 -> Chân Rết +50c/+5m).",
        },
    }

    local cardW = 240
    local cardH = 370
    local startX = (V_WIDTH - (4 * cardW + 3 * 24)) / 2
    local cardY = 140

    for i, s in ipairs(factions) do
        local cx = startX + (i - 1) * (cardW + 24)
        local isHovered = (mx >= cx and mx <= cx + cardW and my >= cardY and my <= cardY + cardH)

        love.graphics.setColor(0, 0, 0, 0.4)
        UI.drawRoundedRect("fill", cx + 3, cardY + 5, cardW, cardH, 12)

        love.graphics.setColor(isHovered and { 0.16, 0.22, 0.26, 1 } or { 0.12, 0.16, 0.19, 1 })
        UI.drawRoundedRect("fill", cx, cardY, cardW, cardH, 12)

        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(isHovered and s.color or { 0.35, 0.42, 0.5, 0.8 })
        UI.drawRoundedRect("line", cx, cardY, cardW, cardH, 12)

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(s.color)
        love.graphics.printf(s.title, cx, cardY + 14, cardW, "center")

        UI.drawSuitSymbol(s.id, cx + cardW / 2, cardY + 70, 52, s.color)

        love.graphics.setColor(s.color[1], s.color[2], s.color[3], 0.25)
        UI.drawRoundedRect("fill", cx + 16, cardY + 110, cardW - 32, 30, 6)
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(s.badge, cx, cardY + 115, cardW, "center")

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(s.blessing, cx + 14, cardY + 150, cardW - 28, "left")

        local btnY = cardY + cardH - 48
        local btnFaction = {
            id = "faction_" .. s.id,
            factionId = s.id,
            text = "CHỌN PHE NÀY",
            x = cx + 24,
            y = btnY,
            w = cardW - 48,
            h = 36,
            color = isHovered and s.color or UI.COLORS.btnNormal,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnFaction)
        UI.drawButton(btnFaction, isHovered, juice.buttonPressedId == btnFaction.id)
    end

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Khởi đầu với 3 lá ngẫu nhiên. Đánh bại BOSS để chọn thêm Hộ Linh!", 0, V_HEIGHT - 35, V_WIDTH, "center")
end

local function drawStarterDeckSelect()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(UI.COLORS.bg)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    local btnBack = {
        id = "back_to_title", text = "< QUAY LẠI MENU CHÍNH",
        x = 40, y = 35, w = 220, h = 38,
        font = UI.fonts.small, color = UI.COLORS.btnNormal,
    }
    table.insert(buttons, btnBack)
    UI.drawButton(btnBack, mx >= btnBack.x and mx <= btnBack.x + btnBack.w and my >= btnBack.y and my <= btnBack.y + btnBack.h, juice.buttonPressedId == btnBack.id)

    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CHỌN BỘ BÀI KHỞI ĐẦU", 0, 40, V_WIDTH, "center")
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Không còn phe phái — chất bài chỉ dùng để tạo thế Poker.", 0, 88, V_WIDTH, "center")

    local deckInfo = Deck.STARTER_DECKS.red_deck
    local cardW, cardH = 390, 430
    local cardX, cardY = (V_WIDTH - cardW) / 2, 135
    local hovered = mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH
    love.graphics.setColor(0, 0, 0, 0.45)
    UI.drawRoundedRect("fill", cardX + 5, cardY + 7, cardW, cardH, 16)
    love.graphics.setColor(hovered and { 0.24, 0.08, 0.10, 1 } or { 0.17, 0.08, 0.10, 1 })
    UI.drawRoundedRect("fill", cardX, cardY, cardW, cardH, 16)
    love.graphics.setLineWidth(hovered and 4 or 2)
    love.graphics.setColor(deckInfo.color)
    UI.drawRoundedRect("line", cardX, cardY, cardW, cardH, 16)

    love.graphics.setFont(UI.fonts.title)
    love.graphics.setColor(deckInfo.color)
    love.graphics.printf("BỘ BÀI ĐỎ", cardX, cardY + 24, cardW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(0.95, 0.15, 0.20, 1)
    love.graphics.printf("♦  ♥", cardX, cardY + 85, cardW, "center")
    love.graphics.setColor(0.75, 0.78, 0.84, 1)
    love.graphics.printf("♠  ♣", cardX, cardY + 145, cardW, "center")

    love.graphics.setColor(0.30, 0.07, 0.09, 0.95)
    UI.drawRoundedRect("fill", cardX + 34, cardY + 220, cardW - 68, 105, 10)
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 0.86, 0.48, 1)
    love.graphics.printf("TAY ĐẦU TIÊN: +10 MULT", cardX + 40, cardY + 238, cardW - 80, "center")
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Mỗi combat xáo bộ bài và chỉ rút 3 lá ngẫu nhiên lên tay.", cardX + 50, cardY + 278, cardW - 100, "center")

    local choose = {
        id = "deck_red", deckId = "red_deck", text = "CHỌN BỘ BÀI ĐỎ",
        x = cardX + 65, y = cardY + cardH - 70, w = cardW - 130, h = 44,
        color = deckInfo.color, font = UI.fonts.medium,
    }
    table.insert(buttons, choose)
    UI.drawButton(choose, hovered, juice.buttonPressedId == choose.id)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Bộ bài chuẩn 52 lá • Không có kỹ năng phe • Hand Size khởi đầu: 3", 0, V_HEIGHT - 50, V_WIDTH, "center")
end

local function drawMenu()
    if menuMode == "title" then
        drawMainMenu()
    else
        drawStarterDeckSelect()
    end
end

getHandCardPosition = function(index, totalCards)
    local cardW = 100
    local cardH = 145
    local handAreaX = 295
    local handAreaW = 820

    if totalCards <= 1 then
        local cx = handAreaX + (handAreaW - cardW) / 2
        return cx, 470, cardW, cardH, 0
    end

    -- Dynamic spacing: when hand card count increases, cards overlap cleanly (as in Balatro)
    local maxSpacing = 106
    local maxHandW = handAreaW - 20
    local spacing = math.min(maxSpacing, (maxHandW - cardW) / (totalCards - 1))
    local totalW = (totalCards - 1) * spacing + cardW
    local startX = handAreaX + (handAreaW - totalW) / 2

    local t = (index - 1) / (totalCards - 1) - 0.5 -- from -0.5 (left) to +0.5 (right)
    local angle = t * 0.14 -- gentle arc rotation (-4 deg to +4 deg)
    local archY = (t * 2)^2 * 10 -- parabolic curve: cards at ends dip down slightly

    local cx = startX + (index - 1) * spacing
    local cy = 466 + archY

    return cx, cy, cardW, cardH, angle
end

local function drawPlayingState()
    syncCardSelections()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(UI.COLORS.felt)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    hoveredDeityTooltip = nil
    hoveredCardTooltip = nil
    buttons = {}

    local m = game.monster
    local isBoss = m and m.isBoss
    local isElite = m and m.isElite

    ----------------------------------------------------------------------------
    -- 1. LEFT SIDEBAR (Balatro Layout: Width 265, Height 690)
    ----------------------------------------------------------------------------
    local panelX = 15
    local panelY = 15
    local panelW = 265
    local panelH = 690

    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", panelX, panelY, panelW, panelH, 8)
    love.graphics.setColor(UI.COLORS.panelBorder)
    UI.drawRoundedRect("line", panelX, panelY, panelW, panelH, 8)

    -- A. Monster / Blind Box (Top)
    local mbX = panelX + 10
    local mbY = panelY + 10
    local mbW = panelW - 20
    local mbH = 175

    love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", mbX, mbY, mbW, mbH, 6)
    love.graphics.setColor(0.24, 0.32, 0.40, 1)
    UI.drawRoundedRect("line", mbX, mbY, mbW, mbH, 6)

    -- Monster Banner Header
    local curAnte = (game.currentRun and game.currentRun.ante) or 1
    local anteTag = game.currentRun and (game.currentRun.endless and (" (Ante " .. curAnte .. " - Vô Tận)") or (" (Ante " .. curAnte .. ")")) or ""
    local bannerColor = isBoss and { 0.85, 0.22, 0.25, 1 } or (isElite and { 0.88, 0.55, 0.15, 1 } or { 0.90, 0.45, 0.15, 1 })
    local bannerPrefix = isBoss and "BOSS BLIND" or (isElite and "BIG BLIND" or "SMALL BLIND")
    local bannerText = bannerPrefix .. anteTag .. ": " .. (m and m.name or "Quái")
    love.graphics.setColor(bannerColor)
    UI.drawRoundedRect("fill", mbX, mbY, mbW, 30, 6)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(bannerText, mbX, mbY + 6, mbW, "center")

    -- Monster Emblem / Badge
    local emblemCX = mbX + 30
    local emblemCY = mbY + 60
    local emblemR = 18
    love.graphics.setColor(0.16, 0.20, 0.25, 1)
    love.graphics.circle("fill", emblemCX, emblemCY, emblemR)
    love.graphics.setColor(bannerColor)
    love.graphics.circle("line", emblemCX, emblemCY, emblemR)
    UI.drawSuitSymbol(game.selectedSuit, emblemCX, emblemCY, 20, bannerColor)

    -- Target HP info right of emblem (Uncrowded, full width)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("Đạt ít nhất:", mbX + 58, mbY + 40)

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(isBoss and UI.COLORS.hpRed or UI.COLORS.goldYellow)
    local targetHpStr = m and (UI.formatNumber(m.hp) .. " HP") or "0 HP"
    love.graphics.print(targetHpStr, mbX + 58, mbY + 56)

    -- Status & Intent Row (Y = mbY + 92 to mbY + 118)
    -- Left: Reward pill
    local curBlind = game.currentRun and RunManager.getCurrentBlind(game.currentRun)
    local baseReward = curBlind and curBlind.reward or ((m and m.isBoss) and 5 or ((m and m.isElite) and 4 or 3))
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local rewStr = "Thưởng: +$" .. baseReward
    love.graphics.print(rewStr, mbX + 12, mbY + 96)

    -- Right: Monster Intent Badge
    local intentW = 118
    local intentH = 26
    local intentX = mbX + mbW - intentW - 10
    local intentY = mbY + 92
    love.graphics.setColor(0.24, 0.08, 0.10, 0.95)
    UI.drawRoundedRect("fill", intentX, intentY, intentW, intentH, 4)
    love.graphics.setColor(0.85, 0.30, 0.30, 1)
    UI.drawRoundedRect("line", intentX, intentY, intentW, intentH, 4)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.hpRed)
    love.graphics.printf("Ý ĐỊNH: " .. (m and m.attack or 12) .. " DMG", intentX, intentY + 5, intentW, "center")

    -- HP Bar
    if m then
        UI.drawMonsterHpBar(mbX + 10, mbY + 124, mbW - 20, 20, m.hp, m.maxHp, m.damageLagHp)
    end

    -- Trait / Desc line
    if m and m.desc and m.desc ~= "" then
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf(m.desc, mbX + 6, mbY + 148, mbW - 12, "center")
    end

    -- B. Score Box ("Điểm Ván" / Round Score)
    local sbX = panelX + 10
    local sbY = panelY + 195
    local sbW = panelW - 20
    local sbH = 145

    love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", sbX, sbY, sbW, sbH, 6)
    love.graphics.setColor(0.24, 0.32, 0.40, 1)
    UI.drawRoundedRect("line", sbX, sbY, sbW, sbH, 6)

    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Điểm Ván", sbX, sbY + 8, sbW, "center")

    -- Check selected hand
    local selectedCards = getSelectedCards()
    local eval = (#selectedCards > 0) and Poker.evaluate(selectedCards, game.unlockedHands, game.handLevels) or nil
    local scPreview = eval and Scoring.calculate(eval, game.deities, {
        handsRemaining = game.handsRemaining,
        discardsRemaining = game.discardsRemaining,
        round = game.round,
        monster = game.monster,
        discardBuffs = game.discardBuffs,
        selectedSuit = game.selectedSuit,
        selectedFaction = game.selectedFaction,
        playedHandsHistory = game.playedHandsHistory,
        starterDeckId = game.starterDeckId,
        handsPlayedThisCombat = game.handsPlayedThisCombat or 0,
    }) or nil

    if state == "scoring" and anim.active then
        local handTitle = (anim.evalResult and anim.evalResult.type and ((anim.evalResult.type.vnName) .. " (Lv. " .. (anim.evalResult.level or 1) .. ")")) or "ĐIỂM VÁN"
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(handTitle, sbX, sbY + 30, sbW, "center")

        -- Chips box (Blue)
        local cbX = sbX + 12
        local cbY = sbY + 54
        local cbW = 96
        local cbH = 50
        love.graphics.setColor(0.12, 0.32, 0.65, 0.95)
        UI.drawRoundedRect("fill", cbX, cbY, cbW, cbH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        UI.drawRoundedRect("line", cbX, cbY, cbW, cbH, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Chips", cbX, cbY + 4, cbW, "center")
        UI.drawAnimatedNumber(UI.formatNumber(anim.displayChips), cbX, cbY, cbW, cbH, UI.COLORS.chipsBlue, anim.bounceScale and anim.bounceScale.chips or 1.0)

        -- Multiplication X
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.printf("X", sbX + 108, cbY + 12, 28, "center")

        -- Mult box (Red)
        local mbX2 = sbX + 137
        local mbY2 = cbY
        local mbW2 = 96
        local mbH2 = 50
        love.graphics.setColor(0.65, 0.18, 0.22, 0.95)
        UI.drawRoundedRect("fill", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setColor(UI.COLORS.multRed)
        UI.drawRoundedRect("line", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Mult", mbX2, mbY2 + 4, mbW2, "center")
        UI.drawAnimatedNumber(UI.formatNumber(anim.displayMult), mbX2, mbY2, mbW2, mbH2, UI.COLORS.multRed, anim.bounceScale and anim.bounceScale.mult or 1.0)

        -- Fire particles around Left Sidebar Mult box if displayMult >= 20
        if anim.fireParticles and #anim.fireParticles > 0 and (anim.displayMult or 0) >= 20 then
            drawRealisticFireParticles()
        end

        -- Sát thương dự kiến / đã tích tụ
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        local scoreText = "Sát thương: " .. UI.formatNumber(anim.displayFinalScore) .. " HP"
        if anim.displayXMult and anim.displayXMult > 1.0 then
            scoreText = scoreText .. " (x" .. string.format("%.1f", anim.displayXMult):gsub("%.0$", "") .. ")"
        end
        love.graphics.printf(scoreText, sbX, sbY + 108, sbW, "center")

    elseif eval and scPreview then
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        local hNameWithLvl = eval.type.vnName .. (eval.level and (" (Lv. " .. eval.level .. ")") or "")
        if juice.handRankBounce and juice.handRankBounce > 1.01 then
            local bCX = sbX + sbW / 2
            local bCY = sbY + 36
            love.graphics.push()
            love.graphics.translate(bCX, bCY)
            love.graphics.scale(juice.handRankBounce, juice.handRankBounce)
            love.graphics.translate(-bCX, -bCY)
            love.graphics.printf(hNameWithLvl, sbX, sbY + 30, sbW, "center")
            love.graphics.pop()
        else
            love.graphics.printf(hNameWithLvl, sbX, sbY + 30, sbW, "center")
        end

        -- Chips box (Blue)
        local cbX = sbX + 12
        local cbY = sbY + 54
        local cbW = 96
        local cbH = 50
        love.graphics.setColor(0.12, 0.32, 0.65, 0.95)
        UI.drawRoundedRect("fill", cbX, cbY, cbW, cbH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        UI.drawRoundedRect("line", cbX, cbY, cbW, cbH, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Chips", cbX, cbY + 4, cbW, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(scPreview.totalChips), cbX, cbY + 16, cbW, "center")

        -- Multiplication X
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.printf("X", sbX + 108, cbY + 12, 28, "center")

        -- Mult box (Red)
        local mbX2 = sbX + 137
        local mbY2 = cbY
        local mbW2 = 96
        local mbH2 = 50
        love.graphics.setColor(0.65, 0.18, 0.22, 0.95)
        UI.drawRoundedRect("fill", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setColor(UI.COLORS.multRed)
        UI.drawRoundedRect("line", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.printf("Mult", mbX2, mbY2 + 4, mbW2, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(scPreview.totalMult), mbX2, mbY2 + 16, mbW2, "center")

        -- Damage projection
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.hpRed)
        love.graphics.printf("Dự kiến: " .. scPreview.finalScore .. " HP", sbX, sbY + 108, sbW, "center")
    else
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Chọn bài để tính điểm", sbX, sbY + 30, sbW, "center")

        -- Chips box 0
        local cbX = sbX + 12
        local cbY = sbY + 54
        local cbW = 96
        local cbH = 50
        love.graphics.setColor(0.12, 0.22, 0.35, 0.6)
        UI.drawRoundedRect("fill", cbX, cbY, cbW, cbH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue[1], UI.COLORS.chipsBlue[2], UI.COLORS.chipsBlue[3], 0.4)
        UI.drawRoundedRect("line", cbX, cbY, cbW, cbH, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Chips", cbX, cbY + 4, cbW, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("0", cbX, cbY + 16, cbW, "center")

        -- X
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
        love.graphics.printf("X", sbX + 108, cbY + 12, 28, "center")

        -- Mult box 0
        local mbX2 = sbX + 137
        local mbY2 = cbY
        local mbW2 = 96
        local mbH2 = 50
        love.graphics.setColor(0.28, 0.14, 0.16, 0.6)
        UI.drawRoundedRect("fill", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setColor(UI.COLORS.multRed[1], UI.COLORS.multRed[2], UI.COLORS.multRed[3], 0.4)
        UI.drawRoundedRect("line", mbX2, mbY2, mbW2, mbH2, 6)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Mult", mbX2, mbY2 + 4, mbW2, "center")
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("0", mbX2, mbY2 + 16, mbW2, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Dự kiến: 0 HP", sbX, sbY + 108, sbW, "center")
    end

    -- Discard Buff Indicator Pill in Score Box
    local db = game.discardBuffs
    if db and (db.chips > 0 or db.mult > 0 or (db.xMult and db.xMult > 1.0) or (db.bonusDamagePct and db.bonusDamagePct > 0)) then
        local parts = {}
        if db.chips > 0 then table.insert(parts, "+" .. db.chips .. "c") end
        if db.mult > 0 then table.insert(parts, "+" .. db.mult .. "m") end
        if db.xMult and db.xMult > 1.0 then table.insert(parts, "x" .. string.format("%.2f", db.xMult)) end
        if db.bonusDamagePct and db.bonusDamagePct > 0 then table.insert(parts, "+" .. math.floor(db.bonusDamagePct * 100) .. "%") end

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("Buff Bỏ Bài: " .. table.concat(parts, " | "), sbX, sbY + 126, sbW, "center")
    end

    -- C. Player HP Bar
    UI.drawPlayerHpBar(panelX + 10, panelY + 346, panelW - 20, 32, game.playerHp, game.maxPlayerHp, game.playerArmor or game.playerShield or 0)

    -- D. Sidebar Action Buttons
    local btnHandbookPlay = {
        id = "open_handbook",
        text = "T.tin Trận Này [H]",
        x = panelX + 10,
        y = panelY + 384,
        w = panelW - 20,
        h = 32,
        color = { 0.82, 0.26, 0.24, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnHandbookPlay)
    UI.drawButton(btnHandbookPlay, mx >= btnHandbookPlay.x and mx <= btnHandbookPlay.x + btnHandbookPlay.w and my >= btnHandbookPlay.y and my <= btnHandbookPlay.y + btnHandbookPlay.h)

    local btnDeckPlay = {
        id = "open_deck_viewer",
        text = "Tuỳ Chọn [Tab]",
        x = panelX + 10,
        y = panelY + 420,
        w = panelW - 20,
        h = 32,
        color = { 0.88, 0.52, 0.18, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnDeckPlay)
    UI.drawButton(btnDeckPlay, mx >= btnDeckPlay.x and mx <= btnDeckPlay.x + btnDeckPlay.w and my >= btnDeckPlay.y and my <= btnDeckPlay.y + btnDeckPlay.h)

    -- E. Stats Matrix (Bottom)
    local matrixY = panelY + 458

    -- Hands Remaining (Blue Box)
    local handBoxW = 118
    local handBoxH = 65
    love.graphics.setColor(0.12, 0.28, 0.55, 0.95)
    UI.drawRoundedRect("fill", panelX + 10, matrixY, handBoxW, handBoxH, 6)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    UI.drawRoundedRect("line", panelX + 10, matrixY, handBoxW, handBoxH, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(0.85, 0.92, 1.0, 1)
    love.graphics.printf("Tay Bài", panelX + 10, matrixY + 6, handBoxW, "center")
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.handsRemaining), panelX + 10, matrixY + 22, handBoxW, "center")

    -- Discards Remaining (Red Box)
    local discBoxY = matrixY + 73
    love.graphics.setColor(0.55, 0.18, 0.20, 0.95)
    UI.drawRoundedRect("fill", panelX + 10, discBoxY, handBoxW, handBoxH, 6)
    love.graphics.setColor(UI.COLORS.multRed)
    UI.drawRoundedRect("line", panelX + 10, discBoxY, handBoxW, handBoxH, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(1.0, 0.85, 0.85, 1)
    love.graphics.printf("Lượt Bỏ", panelX + 10, discBoxY + 6, handBoxW, "center")
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.discardsRemaining), panelX + 10, discBoxY + 22, handBoxW, "center")

    -- Gold Cash Box (Right Box)
    local goldBoxX = panelX + 136
    local goldBoxW = panelW - 146
    local goldBoxH = 138
    love.graphics.setColor(0.12, 0.15, 0.18, 0.95)
    UI.drawRoundedRect("fill", goldBoxX, matrixY, goldBoxW, goldBoxH, 6)
    love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 0.8)
    UI.drawRoundedRect("line", goldBoxX, matrixY, goldBoxW, goldBoxH, 6)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("Tiền Vàng", goldBoxX, matrixY + 8, goldBoxW, "center")
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("$" .. game.gold, goldBoxX, matrixY + 36, goldBoxW, "center")

    -- Interest Info
    local curInterest = math.min(5, math.floor(game.gold / 5))
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("Lãi: +$" .. curInterest .. "/trận (Max $5)", goldBoxX, matrixY + 110, goldBoxW, "center")

    -- Round Info (Footer)
    local footerY = matrixY + 146
    local footerH = 76
    love.graphics.setColor(0.10, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", panelX + 10, footerY, panelW - 20, footerH, 6)
    love.graphics.setColor(0.24, 0.32, 0.40, 1)
    UI.drawRoundedRect("line", panelX + 10, footerY, panelW - 20, footerH, 6)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("VÁN ĐẤU HIỆN TẠI", panelX + 10, footerY + 14, panelW - 20, "center")
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Ván " .. tostring(game.round or 1), panelX + 10, footerY + 36, panelW - 20, "center")

    ----------------------------------------------------------------------------
    -- 2. TOP BAR: DEITIES & CONSUMABLES (0/2)
    ----------------------------------------------------------------------------
    local topStartX = 295
    local topStartY = 15

    -- Deities Section
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local curDeiCount = Deities.getCount(game.deities)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    love.graphics.print("HỘ LINH (" .. curDeiCount .. "/" .. maxDeiSlots .. ")", topStartX + 4, topStartY)

    local deitySlotW = 82
    local deitySlotH = 118
    local deityGap = 14
    local deityY = 32

    for i = 1, maxDeiSlots do
        local dx = getDeitySlotRect(i, "playing")
        local d = game.deities and game.deities[i]
        local isDraggedSource = (deityDrag.active and deityDrag.isDragging and deityDrag.deityIndex == i)
        local isHoveredSlot = (mx >= dx and mx <= dx + deitySlotW and my >= deityY and my <= deityY + deitySlotH)
        local isDropTarget = (deityDrag.active and deityDrag.isDragging and isHoveredSlot and deityDrag.deityIndex ~= i)

        if isDraggedSource then
            -- Ghost / Placeholder at original position
            love.graphics.setColor(0.10, 0.12, 0.15, 0.45)
            UI.drawRoundedRect("fill", dx, deityY, deitySlotW, deitySlotH, 6)
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(0.35, 0.40, 0.48, 0.5)
            UI.drawRoundedRect("line", dx, deityY, deitySlotW, deitySlotH, 6)
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf("Vị trí cũ", dx + 4, deityY + deitySlotH / 2 - 6, deitySlotW - 8, "center")
        elseif d then
            if isHoveredSlot and not (deityDrag.active and deityDrag.isDragging) then
                hoveredDeityTooltip = d
                d.slotIndex = i
            end

            -- Slot bounce effect
            local bScale = anim.deityBounce and anim.deityBounce[i] or 1.0
            love.graphics.push()
            love.graphics.translate(dx + deitySlotW / 2, deityY + deitySlotH / 2)
            if bScale > 1.01 then
                love.graphics.scale(bScale, bScale)
            end
            love.graphics.translate(-dx - deitySlotW / 2, -deityY - deitySlotH / 2)

            local copyTarget = d.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, i)
            UI.drawPatronCard(d, dx, deityY, deitySlotW, deitySlotH, isHoveredSlot, juice.buttonPressedId == ("deity_" .. i), isDropTarget, copyTarget)
            love.graphics.pop()
        else
            -- Empty Tarot Slot
            love.graphics.setColor(0.09, 0.11, 0.13, isDropTarget and 0.85 or 0.6)
            UI.drawRoundedRect("fill", dx, deityY, deitySlotW, deitySlotH, 6)
            love.graphics.setLineWidth(isDropTarget and 2.5 or 1)
            love.graphics.setColor(isDropTarget and UI.COLORS.hpGreen or { 0.25, 0.28, 0.35, 0.5 })
            UI.drawRoundedRect("line", dx, deityY, deitySlotW, deitySlotH, 6)

            if isDropTarget then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.hpGreen)
                love.graphics.printf("THẢ VÀO\nĐÂY", dx + 4, deityY + deitySlotH / 2 - 14, deitySlotW - 8, "center")
            else
                love.graphics.setFont(UI.fonts.large)
                love.graphics.setColor(0.28, 0.32, 0.38, 0.5)
                love.graphics.printf("+", dx, deityY + deitySlotH / 2 - 18, deitySlotW, "center")
            end
        end
    end

    -- Consumables Section (0/2)
    local conStartX = topStartX + maxDeiSlots * (deitySlotW + deityGap) + 20
    game.consumables = game.consumables or {}
    local conCount = #game.consumables
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor({ 0.45, 0.85, 0.65, 1 })
    love.graphics.print("TIÊU HAO (" .. conCount .. "/2)", conStartX + 4, topStartY)

    local conSlotW = 82
    local conSlotH = 118
    local conGap = 14
    for j = 1, 2 do
        local cx = conStartX + (j - 1) * (conSlotW + conGap)
        local c = game.consumables[j]
        drawConsumableSlot(c, cx, deityY, conSlotW, conSlotH, j, mx, my)
    end

    ----------------------------------------------------------------------------
    -- 3. CENTER FELT TABLE: PLAYED / SELECTED HINTS
    ----------------------------------------------------------------------------
    if eval and scPreview then
        -- Subtle highlight banner above player cards
        local hbW = 540
        local hbH = 34
        local hbX = 295 + (820 - hbW) / 2
        local hbY = 412
        love.graphics.setColor(0.10, 0.14, 0.18, 0.85)
        UI.drawRoundedRect("fill", hbX, hbY, hbW, hbH, 6)
        love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 0.7)
        UI.drawRoundedRect("line", hbX, hbY, hbW, hbH, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(eval.type.vnName .. ": " .. scPreview.totalChips .. " Chips × " .. scPreview.totalMult .. " Mult = " .. scPreview.finalScore .. " Sát Thương!", hbX, hbY + 8, hbW, "center")
    elseif state ~= "scoring" then
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.85, 0.90, 0.95, 0.75)
        love.graphics.printf("[Chuột trái]: Chọn hoặc Giữ kéo thả sắp xếp | [Chuột phải]: Xem chi tiết | [F11]: Toàn màn hình", 295, 420, 820, "center")
    end

    ----------------------------------------------------------------------------
    -- 4. PLAYER HAND CARDS
    ----------------------------------------------------------------------------
    local cardW = 100
    local cardH = 145
    local hoveredCard = nil
    local hoveredIdx = nil

    -- Find hovered card from right to left (top-most in z-order)
    for i = #game.hand, 1, -1 do
        local c = game.hand[i]
        local cx = c.visualX or 0
        local cy = c.visualY or 0
        local isHovered = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH)
        c.hovered = isHovered
        if isHovered and not hoveredCard and not (handDrag.active and handDrag.isDragging) then
            hoveredCard = c
            hoveredIdx = i
            if c.equipments and #c.equipments > 0 then
                hoveredCardTooltip = c
            end
        end
    end

    -- Draw non-dragged cards in order 1 to #game.hand
    for i, c in ipairs(game.hand) do
        if not (handDrag.active and handDrag.isDragging and handDrag.cardIndex == i) then
            local cx = c.visualX or 0
            local cy = c.visualY or 0
            if c.dealTrail and c.dealTrail > 0 then
                local trailAlpha = math.min(0.7, c.dealTrail / 0.18)
                love.graphics.setBlendMode("add")
                love.graphics.setLineWidth(3)
                love.graphics.setColor(0.45, 0.75, 1.0, trailAlpha)
                love.graphics.line(1180, 620, cx + cardW / 2, cy + cardH / 2)
                love.graphics.circle("fill", cx + cardW / 2, cy + cardH / 2, 5 + trailAlpha * 5)
                love.graphics.setLineWidth(1)
                love.graphics.setBlendMode("alpha")
            end
            UI.drawCard(c, cx, cy, cardW, cardH)
        end
    end

    -- Draw dragged card on top of everything with extra elevation shadow
    if handDrag.active and handDrag.isDragging and handDrag.cardIndex then
        local dc = game.hand[handDrag.cardIndex]
        if dc then
            love.graphics.setColor(0, 0, 0, 0.45)
            UI.drawRoundedRect("fill", dc.visualX + 6, dc.visualY + 14, cardW, cardH, 8)
            UI.drawCard(dc, dc.visualX, dc.visualY, cardW, cardH)
        end
    end

    -- Draw Balatro hover badge above hovered card
    if hoveredCard and not (handDrag.active and handDrag.isDragging) then
        UI.drawCardHoverBadge(hoveredCard, hoveredCard.visualX or 0, hoveredCard.visualY or 0, cardW, cardH)
    end

    -- Hand count badge (e.g. 3/3) above action buttons
    local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
    local handCountText = #game.hand .. "/" .. maxHandSize
    local hcW = 60
    local hcH = 22
    local hcX = 705 - hcW / 2
    local hcY = 608
    love.graphics.setColor(0.12, 0.16, 0.20, 0.9)
    UI.drawRoundedRect("fill", hcX, hcY, hcW, hcH, 4)
    love.graphics.setColor(0.35, 0.45, 0.55, 0.8)
    UI.drawRoundedRect("line", hcX, hcY, hcW, hcH, 4)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(handCountText, hcX, hcY + 3, hcW, "center")

    ----------------------------------------------------------------------------
    -- 5. BALATRO ACTION BUTTONS ROW
    ----------------------------------------------------------------------------
    local hasSelection = (#selectedCards >= 1 and #selectedCards <= getMaxSelectableCards())
    local actionY = 636

    -- Left: Chơi Tay Bài [Space]
    local btnPlay = {
        id = "play",
        text = "Chơi Tay Bài [Space]",
        x = 445,
        y = actionY,
        w = 175,
        h = 58,
        color = UI.COLORS.chipsBlue,
        font = UI.fonts.small,
        disabled = not hasSelection or game.handsRemaining <= 0,
    }
    table.insert(buttons, btnPlay)
    UI.drawButton(btnPlay, mx >= btnPlay.x and mx <= btnPlay.x + btnPlay.w and my >= btnPlay.y and my <= btnPlay.y + btnPlay.h)

    -- Center: Sắp Xếp Container Box
    local sortBoxX = 635
    local sortBoxY = actionY - 8
    local sortBoxW = 145
    local sortBoxH = 68
    love.graphics.setColor(0.12, 0.16, 0.20, 0.95)
    UI.drawRoundedRect("fill", sortBoxX, sortBoxY, sortBoxW, sortBoxH, 6)
    love.graphics.setColor(0.30, 0.38, 0.46, 1)
    UI.drawRoundedRect("line", sortBoxX, sortBoxY, sortBoxW, sortBoxH, 6)

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("SẮP XẾP BÀI", sortBoxX, sortBoxY + 4, sortBoxW, "center")

    local btnSortRank = {
        id = "sort_rank",
        text = "Bậc [R]",
        x = sortBoxX + 6,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        color = (game.sortMode == "rank") and { 0.28, 0.48, 0.72, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnSortRank)
    UI.drawButton(btnSortRank, mx >= btnSortRank.x and mx <= btnSortRank.x + btnSortRank.w and my >= btnSortRank.y and my <= btnSortRank.y + btnSortRank.h)

    local btnSortSuit = {
        id = "sort_suit",
        text = "Chất [S]",
        x = sortBoxX + 76,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        color = (game.sortMode == "suit") and { 0.28, 0.48, 0.72, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnSortSuit)
    UI.drawButton(btnSortSuit, mx >= btnSortSuit.x and mx <= btnSortSuit.x + btnSortSuit.w and my >= btnSortSuit.y and my <= btnSortSuit.y + btnSortSuit.h)

    -- Right: Bỏ Bài [D]
    local btnDiscard = {
        id = "discard",
        text = "Bỏ Bài [D]",
        x = 795,
        y = actionY,
        w = 160,
        h = 58,
        color = UI.COLORS.multRed,
        font = UI.fonts.small,
        disabled = not hasSelection or game.discardsRemaining <= 0,
    }
    table.insert(buttons, btnDiscard)
    UI.drawButton(btnDiscard, mx >= btnDiscard.x and mx <= btnDiscard.x + btnDiscard.w and my >= btnDiscard.y and my <= btnDiscard.y + btnDiscard.h)

    ----------------------------------------------------------------------------
    -- 6. BOTTOM-RIGHT FACEDOWN DRAW DECK PILE
    ----------------------------------------------------------------------------
    local deckPileX = 1140
    local deckPileY = 535
    local deckPileW = 115
    local deckPileH = 160

    local isDeckHovered = (mx >= deckPileX and mx <= deckPileX + deckPileW and my >= deckPileY and my <= deckPileY + deckPileH)

    -- Layer 1 & 2 shadow stack
    love.graphics.setColor(0.08, 0.10, 0.12, 0.7)
    UI.drawRoundedRect("fill", deckPileX - 4, deckPileY + 4, deckPileW, deckPileH, 8)
    UI.drawRoundedRect("fill", deckPileX - 2, deckPileY + 2, deckPileW, deckPileH, 8)

    -- Top Deck Card Back
    love.graphics.setColor(isDeckHovered and { 0.22, 0.32, 0.42, 1 } or { 0.16, 0.20, 0.26, 1 })
    UI.drawRoundedRect("fill", deckPileX, deckPileY, deckPileW, deckPileH, 8)
    love.graphics.setLineWidth(isDeckHovered and 2.5 or 1.5)
    love.graphics.setColor(isDeckHovered and UI.COLORS.goldYellow or { 0.35, 0.45, 0.55, 1 })
    UI.drawRoundedRect("line", deckPileX, deckPileY, deckPileW, deckPileH, 8)

    -- Card back pattern: inner decorative border & crest
    love.graphics.setColor(0.24, 0.32, 0.40, 0.7)
    UI.drawRoundedRect("line", deckPileX + 6, deckPileY + 6, deckPileW - 12, deckPileH - 12, 6)

    -- Faction symbol on card back
    UI.drawSuitSymbol(game.selectedSuit, deckPileX + deckPileW / 2, deckPileY + deckPileH / 2 - 10, 36)

    -- Deck Pile Label & Counter
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("BỘ BÀI [Tab]", deckPileX, deckPileY + 12, deckPileW, "center")

    local totalCardsInGame = #game.deck + #game.discardPile + #game.hand
    local deckCountStr = #game.deck .. " / " .. totalCardsInGame
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(deckCountStr, deckPileX, deckPileY + deckPileH - 34, deckPileW, "center")

    local btnDeckPile = {
        id = "open_deck_viewer",
        x = deckPileX,
        y = deckPileY,
        w = deckPileW,
        h = deckPileH,
    }
    table.insert(buttons, btnDeckPile)

    ----------------------------------------------------------------------------
    -- 7. TOOLTIPS (Deity & Card Equipment)
    ----------------------------------------------------------------------------
    if hoveredDeityTooltip then
        local copyTarget = hoveredDeityTooltip.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, hoveredDeityTooltip.slotIndex or 1)
        UI.drawPatronTooltip(hoveredDeityTooltip, mx, my, copyTarget)
    end

    if hoveredCardTooltip then
        local c = hoveredCardTooltip
        local ttW = 280
        local ttH = 30 + #c.equipments * 26
        local ttx = math.min(V_WIDTH - ttW - 10, math.max(10, mx + 12))
        local tty = math.max(10, my - ttH - 10)

        love.graphics.setColor(0.08, 0.10, 0.12, 0.96)
        UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 6)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.print("Trang bị trên lá (" .. Equipment.getUsedSlots(c) .. "/" .. Equipment.MAX_SLOTS .. " ô):", ttx + 10, tty + 6)

        for s, eq in ipairs(c.equipments) do
            love.graphics.setColor(eq.color or UI.COLORS.textLight)
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.print("• " .. eq.name .. ": " .. eq.desc, ttx + 12, tty + 14 + s * 22)
        end
    end
end

local function drawScoringState()
    -- 1. Draw the underlying playing table completely untouched (NO dark overlay, NO modal popup!)
    drawPlayingState()

    -- 2. Center Play Zone: Played Cards Staging Area (y = 295)
    local cards = anim.playedCards or {}
    local cardW = 96
    local cardH = 140
    local cardGap = 16
    local totalCardsW = #cards * cardW + math.max(0, #cards - 1) * cardGap
    local playAreaX = 295
    local playAreaW = 820
    local startCX = playAreaX + (playAreaW - totalCardsW) / 2
    local playY = 295

    -- Hand Name Header & Step Log Banner above played cards in Play Zone
    local bannerW = math.max(480, totalCardsW + 60)
    local bannerH = 50
    local bannerX = playAreaX + (playAreaW - bannerW) / 2
    local bannerY = playY - 62

    love.graphics.setColor(0.08, 0.10, 0.14, 0.92)
    UI.drawRoundedRect("fill", bannerX, bannerY, bannerW, bannerH, 8)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", bannerX, bannerY, bannerW, bannerH, 8)

    local handNameText = (anim.evalResult and anim.evalResult.type and anim.evalResult.type.vnName or "TAY BÀI") .. " (" .. (anim.evalResult and anim.evalResult.type and anim.evalResult.type.name or "") .. ")"
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(handNameText, bannerX, bannerY + 6, bannerW, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(anim.stepLog or "", bannerX + 10, bannerY + 28, bannerW - 20, "center")

    -- Render Played Cards in Play Zone
    for i, c in ipairs(cards) do
        local cx = startCX + (i - 1) * (cardW + cardGap)
        local entrance = math.max(0, math.min(1, ((anim.entranceTimer or 0) - (i - 1) * 0.055) / 0.24))
        local easedEntrance = 1 - (1 - entrance) ^ 3
        local cy = 610 + (playY - 610) * easedEntrance
        local isActive = (anim.activeCardIndex == i)
        local isScored = (anim.scoredCards and anim.scoredCards[i] ~= nil)

        c.visualScale = 0.72 + easedEntrance * 0.28
        c.rotation = (1 - easedEntrance) * ((i % 2 == 0) and 0.10 or -0.10)

        if isActive then
            cy = cy - 20 -- Lift active card
        end

        if anim.cardBounce and anim.cardBounce[i] then
            c.scaleX = anim.cardBounce[i].scaleX
            c.scaleY = anim.cardBounce[i].scaleY
        else
            c.scaleX = 1.0
            c.scaleY = 1.0
        end

        -- Dim cards not yet scored
        if not isActive and not isScored and anim.currentStepIndex <= #anim.scoringData.steps then
            love.graphics.setColor(1, 1, 1, 0.65)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        UI.drawCard(c, cx, cy, cardW, cardH)

        -- If actively scoring: Draw golden highlight ring and floating pill above
        if isActive then
            love.graphics.setLineWidth(3)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", cx - 2, cy - 2, cardW + 4, cardH + 4, 8)

            -- Floating pill above card
            local pillW = 104
            local pillH = 26
            local pillX = cx + (cardW - pillW) / 2
            local pillY = cy - 32

            love.graphics.setColor(0.12, 0.16, 0.22, 0.95)
            UI.drawRoundedRect("fill", pillX, pillY, pillW, pillH, 6)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", pillX, pillY, pillW, pillH, 6)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            local bonusText = "+" .. (c.baseChips or 0) .. " Chips"
            if anim.scoredCards and anim.scoredCards[i] then
                local sc = anim.scoredCards[i]
                if sc.addedMult and sc.addedMult > 0 then
                    bonusText = "+" .. sc.addedChips .. "c/+" .. sc.addedMult .. "m"
                else
                    bonusText = "+" .. sc.addedChips .. " Chips"
                end
            end
            love.graphics.printf(bonusText, pillX, pillY + 4, pillW, "center")

        elseif isScored then
            -- Small green check badge below scored card
            local badgeW = 76
            local badgeH = 20
            local badgeX = cx + (cardW - badgeW) / 2
            local badgeY = cy + cardH + 4

            love.graphics.setColor(0.10, 0.25, 0.16, 0.90)
            UI.drawRoundedRect("fill", badgeX, badgeY, badgeW, badgeH, 4)
            love.graphics.setColor(UI.COLORS.hpGreen)
            UI.drawRoundedRect("line", badgeX, badgeY, badgeW, badgeH, 4)

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.hpGreen)
            local scoredInfo = anim.scoredCards[i]
            love.graphics.printf("✓ +" .. scoredInfo.addedChips .. "c", badgeX, badgeY + 2, badgeW, "center")
        end
    end

    -- 3. Sparks and Fire Particles directly on board
    drawRealisticFireParticles()

    if anim.particles and #anim.particles > 0 then
        love.graphics.setBlendMode("add")
        for _, p in ipairs(anim.particles) do
            local alpha = math.max(0, p.alpha or (p.life / p.maxLife))
            local col = p.color or UI.COLORS.goldYellow
            love.graphics.setColor(col[1], col[2], col[3], alpha)
            love.graphics.circle("fill", p.x, p.y, p.size * (p.life / p.maxLife))
        end
        love.graphics.setBlendMode("alpha")
    end

    -- Expanding impact ring ties each score tick to its card/monster target.
    if (anim.impactFlash or 0) > 0 then
        local col = anim.impactColor or UI.COLORS.goldYellow
        local alpha = math.min(1, anim.impactFlash * 4.5)
        local radius = 18 + (0.32 - math.min(0.32, anim.impactFlash)) * 150
        love.graphics.setBlendMode("add")
        love.graphics.setLineWidth(4)
        love.graphics.setColor(col[1], col[2], col[3], alpha)
        love.graphics.circle("line", anim.impactX or 640, anim.impactY or 360, radius)
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(1, 1, 1, alpha * 0.65)
        love.graphics.circle("line", anim.impactX or 640, anim.impactY or 360, radius * 0.62)
        love.graphics.setLineWidth(1)
        love.graphics.setBlendMode("alpha")
    end

    -- 4. Floating Texts directly on board
    for _, ft in ipairs(anim.floatingTexts) do
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], ft.alpha)
        love.graphics.printf(ft.text, ft.x - 200, ft.y, 400, "center")
    end

    -- 5. Footer Hint & Fast-Forward Prompt
    local footerY = 442
    if anim.currentStepIndex > #anim.scoringData.steps then
        if anim.monsterDefeated then
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(UI.COLORS.btnPlay)
            love.graphics.printf("⚔ TIÊU DIỆT QUÁI VẬT! (+ $" .. anim.earnedGold .. " Vàng)", playAreaX, footerY - 4, playAreaW, "center")
        elseif game.handsRemaining <= 0 then
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(UI.COLORS.multRed)
            love.graphics.printf("HẾT LƯỢT ĐÁNH — BẠN ĐÃ BỊ ĐÁNH BẠI!", playAreaX, footerY - 4, playAreaW, "center")
        else
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("Đã gây " .. UI.formatNumber(anim.displayFinalScore) .. " Sát thương vào Quái Vật!", playAreaX, footerY, playAreaW, "center")
        end
    else
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf("Bước " .. math.min(anim.currentStepIndex, #anim.scoringData.steps) .. "/" .. #anim.scoringData.steps .. "  •  [Nhấp chuột hoặc bấm Phím Cách để tua nhanh]", playAreaX, footerY, playAreaW, "center")
    end
end

local function drawBlindSelectState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.06, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Top Header Panel
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", 20, 15, V_WIDTH - 40, 75, 8)
    love.graphics.setColor(UI.COLORS.panelBorder)
    UI.drawRoundedRect("line", 20, 15, V_WIDTH - 40, 75, 8)

    local currentAnte = game.run and game.run.ante or 1
    local maxAnte = game.run and game.run.maxAnte or 8
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("VÒNG ANTE " .. currentAnte .. " / " .. maxAnte .. " — CHỌN ẢI THỬ THÁCH", 40, 22)

    local interestVal = math.min(5, math.floor(game.gold / 5))
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("MÁU: " .. (game.playerHp or 100) .. "/" .. (game.maxPlayerHp or 100) .. " HP   |   TIỀN VÀNG: $" .. game.gold .. " (Lãi: +$" .. interestVal .. "/trận)   |   HỘ LINH: " .. Deities.getCount(game.deities) .. "/" .. maxDeiSlots .. "   |   BỘ BÀI: " .. #(game.persistentDeck or {}) .. " lá", 40, 56)

    -- Right Action Buttons (Handbook, Deck Viewer, Options)
    local btnHandbook = {
        id = "open_handbook",
        text = "SỔ TAY [H]",
        x = V_WIDTH - 440,
        y = 25,
        w = 120,
        h = 55,
        color = { 0.22, 0.45, 0.35, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnHandbook)
    UI.drawButton(btnHandbook, mx >= btnHandbook.x and mx <= btnHandbook.x + btnHandbook.w and my >= btnHandbook.y and my <= btnHandbook.y + btnHandbook.h)

    local btnDeck = {
        id = "open_deck_viewer",
        text = "XEM BÀI [D]",
        x = V_WIDTH - 305,
        y = 25,
        w = 125,
        h = 55,
        color = { 0.25, 0.35, 0.55, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnDeck)
    UI.drawButton(btnDeck, mx >= btnDeck.x and mx <= btnDeck.x + btnDeck.w and my >= btnDeck.y and my <= btnDeck.y + btnDeck.h)

    local btnOpts = {
        id = "open_options",
        text = "CÀI ĐẶT",
        x = V_WIDTH - 165,
        y = 25,
        w = 125,
        h = 55,
        color = { 0.28, 0.32, 0.38, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnOpts)
    UI.drawButton(btnOpts, mx >= btnOpts.x and mx <= btnOpts.x + btnOpts.w and my >= btnOpts.y and my <= btnOpts.y + btnOpts.h)

    -- Center 3 Blind Cards
    local blinds = (game.run and game.run.blinds) or {}
    local cardW = 360
    local cardH = 550
    local gap = 40
    local totalW = 3 * cardW + 2 * gap
    local startX = (V_WIDTH - totalW) / 2
    local startY = 115

    for i = 1, 3 do
        local blind = blinds[i]
        if blind then
            local bx = startX + (i - 1) * (cardW + gap)
            local by = startY
            local isCurrent = (blind.status == "current")
            local isCompleted = (blind.status == "completed")
            local isSkipped = (blind.status == "skipped")
            local isUpcoming = (blind.status == "upcoming")

            -- Card Body
            if isCurrent then
                love.graphics.setColor(0.12, 0.15, 0.21, 0.98)
            elseif isCompleted or isSkipped then
                love.graphics.setColor(0.08, 0.10, 0.13, 0.85)
            else
                love.graphics.setColor(0.09, 0.11, 0.15, 0.90)
            end
            UI.drawRoundedRect("fill", bx, by, cardW, cardH, 14)

            -- Border
            love.graphics.setLineWidth(isCurrent and 3 or 2)
            if isCurrent then
                love.graphics.setColor(blind.color or UI.COLORS.goldYellow)
            elseif isCompleted then
                love.graphics.setColor(0.25, 0.65, 0.35, 0.8)
            elseif isSkipped then
                love.graphics.setColor(0.55, 0.55, 0.55, 0.5)
            else
                love.graphics.setColor(0.22, 0.26, 0.34, 0.6)
            end
            UI.drawRoundedRect("line", bx, by, cardW, cardH, 14)

            -- Header Ribbon / Badge
            local headerColor = blind.color or { 0.3, 0.6, 0.9, 1 }
            love.graphics.setColor(headerColor[1], headerColor[2], headerColor[3], isCurrent and 0.9 or 0.4)
            UI.drawRoundedRect("fill", bx + 12, by + 12, cardW - 24, 44, 8)

            love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(blind.title, bx + 12, by + 22, cardW - 24, "center")

            -- Icon
            love.graphics.setFont(UI.fonts.huge or UI.fonts.title)
            love.graphics.printf(blind.icon or "⚔️", bx, by + 70, cardW, "center")

            -- Blind Name
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(isCurrent and (blind.color or UI.COLORS.goldYellow) or UI.COLORS.textLight)
            love.graphics.printf(blind.name, bx + 10, by + 130, cardW - 20, "center")

            -- HP Requirement Section
            love.graphics.setColor(0.07, 0.09, 0.12, 0.9)
            UI.drawRoundedRect("fill", bx + 24, by + 175, cardW - 48, 75, 8)
            love.graphics.setColor(0.20, 0.24, 0.30, 0.8)
            UI.drawRoundedRect("line", bx + 24, by + 175, cardW - 48, 75, 8)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf("MỤC TIÊU HP", bx + 24, by + 185, cardW - 48, "center")

            love.graphics.setFont(UI.fonts.large or UI.fonts.title)
            love.graphics.setColor(UI.COLORS.chipsBlue or { 0.3, 0.7, 1, 1 })
            love.graphics.printf(UI.formatNumber(blind.hp) .. " HP", bx + 24, by + 210, cardW - 48, "center")

            -- Base Reward
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("Thưởng thắng: +$" .. blind.baseReward .. " Vàng", bx + 20, by + 265, cardW - 40, "center")

            -- Tag or Boss Debuff Details Box
            local detailY = by + 300
            local detailH = 150
            love.graphics.setColor(0.06, 0.08, 0.11, 0.95)
            UI.drawRoundedRect("fill", bx + 18, detailY, cardW - 36, detailH, 8)

            if blind.type == "boss" and blind.debuff then
                love.graphics.setColor(0.85, 0.25, 0.35, 0.8)
                UI.drawRoundedRect("line", bx + 18, detailY, cardW - 36, detailH, 8)

                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(0.95, 0.35, 0.35, 1)
                love.graphics.printf("⚠️ HIỆU ỨNG ÁP CHẾ (DEBUFF)", bx + 24, detailY + 12, cardW - 48, "center")

                love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
                love.graphics.setColor(1, 0.9, 0.9, 1)
                love.graphics.printf(blind.debuff.title or blind.debuff.name, bx + 24, detailY + 38, cardW - 48, "center")

                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(blind.debuff.desc or "", bx + 26, detailY + 68, cardW - 52, "center")
            else
                -- Tag reward for skip
                love.graphics.setColor(0.25, 0.35, 0.45, 0.6)
                UI.drawRoundedRect("line", bx + 18, detailY, cardW - 36, detailH, 8)

                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(UI.COLORS.goldYellow)
                love.graphics.printf("KHẾ ƯỚC BỎ ẢI", bx + 24, detailY + 6, cardW - 48, "center")

                local pact = blind.skipPact or blind.tag
                if pact then
                    love.graphics.setFont(UI.fonts.small)
                    love.graphics.setColor(pact.color or UI.COLORS.textLight)
                    love.graphics.printf((pact.icon or "📜") .. " " .. pact.name, bx + 24, detailY + 26, cardW - 48, "center")

                    love.graphics.setFont(UI.fonts.tiny)
                    if pact.instantDesc and pact.debtDesc then
                        love.graphics.setColor(UI.COLORS.hpGreen)
                        love.graphics.printf("🎁 Nhận ngay: " .. pact.instantDesc, bx + 24, detailY + 48, cardW - 48, "left")
                        love.graphics.setColor(UI.COLORS.multRed)
                        love.graphics.printf("⚠️ Món nợ: " .. pact.debtDesc, bx + 24, detailY + 68, cardW - 48, "left")
                        love.graphics.setColor(UI.COLORS.textMuted)
                        love.graphics.printf("⏳ Thời hạn: " .. (pact.durationDesc or "1 trận"), bx + 24, detailY + 88, cardW - 48, "left")
                    else
                        love.graphics.setColor(UI.COLORS.textLight)
                        love.graphics.printf(pact.desc or "", bx + 26, detailY + 54, cardW - 52, "center")
                    end
                end
            end

            -- Status Stamp or Interactive Buttons
            if isCompleted then
                love.graphics.setColor(0.18, 0.65, 0.32, 0.95)
                UI.drawRoundedRect("fill", bx + 30, by + cardH - 72, cardW - 60, 52, 8)
                love.graphics.setFont(UI.fonts.medium)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf("✓ ĐÃ VƯỢT QUA", bx + 30, by + cardH - 58, cardW - 60, "center")
            elseif isSkipped then
                love.graphics.setColor(0.35, 0.38, 0.42, 0.85)
                UI.drawRoundedRect("fill", bx + 30, by + cardH - 72, cardW - 60, 52, 8)
                love.graphics.setFont(UI.fonts.medium)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf("⏭ ĐÃ BỎ QUA", bx + 30, by + cardH - 58, cardW - 60, "center")
            elseif isUpcoming then
                love.graphics.setColor(0.15, 0.18, 0.22, 0.7)
                UI.drawRoundedRect("fill", bx + 30, by + cardH - 72, cardW - 60, 52, 8)
                love.graphics.setFont(UI.fonts.regular)
                love.graphics.setColor(UI.COLORS.textMuted)
                love.graphics.printf("CHƯA MỞ KHÓA", bx + 30, by + cardH - 58, cardW - 60, "center")
            elseif isCurrent then
                local btnFightW = blind.canSkip and ((cardW - 48) * 0.58) or (cardW - 48)
                local btnFight = {
                    id = "fight_blind",
                    text = "CHIẾN ĐẤU ⚔️",
                    x = bx + 24,
                    y = by + cardH - 72,
                    w = btnFightW,
                    h = 52,
                    color = { 0.22, 0.70, 0.38, 1 },
                    textColor = { 1, 1, 1, 1 },
                    font = UI.fonts.medium or UI.fonts.regular,
                }
                table.insert(buttons, btnFight)
                UI.drawButton(btnFight, mx >= btnFight.x and mx <= btnFight.x + btnFight.w and my >= btnFight.y and my <= btnFight.y + btnFight.h)

                if blind.canSkip then
                    local btnSkipW = (cardW - 48) * 0.38
                    local btnSkip = {
                        id = "skip_blind",
                        text = "BỎ QUA ⏭️",
                        x = bx + 24 + btnFightW + 8,
                        y = by + cardH - 72,
                        w = btnSkipW,
                        h = 52,
                        color = { 0.85, 0.55, 0.20, 1 },
                        textColor = { 1, 1, 1, 1 },
                        font = UI.fonts.small,
                    }
                    table.insert(buttons, btnSkip)
                    UI.drawButton(btnSkip, mx >= btnSkip.x and mx <= btnSkip.x + btnSkip.w and my >= btnSkip.y and my <= btnSkip.y + btnSkip.h)
                end
            end
        end
    end
end

local function drawVictoryState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.05, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    local modalW = 700
    local modalH = 500
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    love.graphics.setColor(0.10, 0.14, 0.18, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 16)
    love.graphics.setLineWidth(3)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 16)

    love.graphics.setFont(UI.fonts.title or UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CHIẾN THẮNG HUYỀN THOẠI! 🏆", modalX, modalY + 35, modalW, "center")

    love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Bạn đã chinh phục hoàn toàn 8 Vòng Ante của LUA.TCG!", modalX, modalY + 95, modalW, "center")

    -- Divider
    love.graphics.setColor(0.3, 0.4, 0.5, 0.5)
    love.graphics.line(modalX + 40, modalY + 140, modalX + modalW - 40, modalY + 140)

    -- Stats summary
    local stats = game.run and game.run.stats or {}
    local statRows = {
        { label = "BỘ BÀI KHỞI ĐẦU:", val = "BỘ BÀI ĐỎ", color = { 0.95, 0.28, 0.30, 1 } },
        { label = "VÒNG ĐẠT ĐƯỢC:", val = "ANTE 8 / 8 (HOÀN THÀNH)", color = UI.COLORS.goldYellow },
        { label = "SỐ ẢI ĐÃ CHIẾN THẮNG:", val = tostring(stats.blindsWon or 0) .. " Ải", color = { 0.35, 0.85, 0.45, 1 } },
        { label = "SỐ ẢI ĐÃ BỎ QUA (SKIP):", val = tostring(stats.blindsSkipped or 0) .. " Ải", color = { 0.85, 0.65, 0.35, 1 } },
        { label = "TỔNG TIỀN VÀNG CÒN LẠI:", val = "$" .. tostring(game.gold or 0), color = UI.COLORS.goldYellow },
        { label = "SỐ HỘ LINH:", val = tostring(Deities.getCount(game.deities)) .. " Hộ Linh", color = { 0.85, 0.45, 0.95, 1 } },
    }

    local rY = modalY + 160
    for _, row in ipairs(statRows) do
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.print(row.label, modalX + 60, rY + 4)

        love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
        love.graphics.setColor(row.color or UI.COLORS.textLight)
        love.graphics.printf(row.val, modalX + modalW - 360, rY, 300, "right")

        rY = rY + 42
    end

    local btnW = 280
    local btnH = 50
    local btnY = modalY + modalH - 72

    local btnMenu = {
        id = "victory_menu",
        text = "VỀ MÀN HÌNH CHÍNH",
        x = modalX + 45,
        y = btnY,
        w = btnW,
        h = btnH,
        color = { 0.32, 0.38, 0.46, 1 },
        font = UI.fonts.regular,
    }
    local btnEndless = {
        id = "victory_endless",
        text = "CHẾ ĐỘ VÔ TẬN ➔",
        x = modalX + modalW - 45 - btnW,
        y = btnY,
        w = btnW,
        h = btnH,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnMenu)
    table.insert(buttons, btnEndless)
    UI.drawButton(btnMenu, mx >= btnMenu.x and mx <= btnMenu.x + btnMenu.w and my >= btnMenu.y and my <= btnMenu.y + btnMenu.h, juice.buttonPressedId == btnMenu.id)
    UI.drawButton(btnEndless, mx >= btnEndless.x and mx <= btnEndless.x + btnEndless.w and my >= btnEndless.y and my <= btnEndless.y + btnEndless.h, juice.buttonPressedId == btnEndless.id)
end

local function drawMap()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.06, 0.08, 0.11, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Top Header Panel
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", 20, 15, V_WIDTH - 40, 75, 8)
    love.graphics.setColor(UI.COLORS.panelBorder)
    UI.drawRoundedRect("line", 20, 15, V_WIDTH - 40, 75, 8)

    -- Title & Subtitle
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("BẢN ĐỒ HÀNH TRÌNH — VÙNG ĐẤT " .. game.act .. " (TẦNG " .. (game.map and game.map.currentFloor or 1) .. "/20)", 40, 22)

    local interestVal = math.min(5, math.floor(game.gold / 5))
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("MÁU: " .. (game.playerHp or 100) .. "/" .. (game.maxPlayerHp or 100) .. " HP   |   TIỀN VÀNG: $" .. game.gold .. " (Lãi: +$" .. interestVal .. "/trận)   |   HỘ LINH: " .. Deities.getCount(game.deities) .. "/" .. maxDeiSlots, 40, 56)

    -- Button Handbook & Deck Viewer
    local btnHandbookMap = {
        id = "open_handbook",
        text = "SỔ TAY [H]",
        x = V_WIDTH - 440,
        y = 25,
        w = 180,
        h = 55,
        color = { 0.22, 0.45, 0.35, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnHandbookMap)
    UI.drawButton(btnHandbookMap, mx >= btnHandbookMap.x and mx <= btnHandbookMap.x + btnHandbookMap.w and my >= btnHandbookMap.y and my <= btnHandbookMap.y + btnHandbookMap.h)

    local btnDeck = {
        id = "open_deck_viewer",
        text = "XEM BỘ BÀI [Tab]",
        x = V_WIDTH - 240,
        y = 25,
        w = 200,
        h = 55,
        color = { 0.22, 0.40, 0.60, 1 },
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnDeck)
    UI.drawButton(btnDeck, mx >= btnDeck.x and mx <= btnDeck.x + btnDeck.w and my >= btnDeck.y and my <= btnDeck.y + btnDeck.h)

    -- Draw the Map Nodes and Connections
    Map.draw(game.map, mx, my, UI)

    -- Map Navigation & Scroll Buttons at Bottom
    local btnScrollStart = {
        id = "map_scroll_start",
        text = "◄ ĐẦU BẢN ĐỒ (T1)",
        x = 40,
        y = V_HEIGHT - 58,
        w = 180,
        h = 42,
        color = { 0.20, 0.28, 0.38, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnScrollStart)
    UI.drawButton(btnScrollStart, mx >= btnScrollStart.x and mx <= btnScrollStart.x + btnScrollStart.w and my >= btnScrollStart.y and my <= btnScrollStart.y + btnScrollStart.h)

    local btnScrollFocus = {
        id = "map_scroll_focus",
        text = "TẦNG HIỆN TẠI (T" .. (game.map and game.map.currentFloor or 1) .. ")",
        x = 235,
        y = V_HEIGHT - 58,
        w = 200,
        h = 42,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnScrollFocus)
    UI.drawButton(btnScrollFocus, mx >= btnScrollFocus.x and mx <= btnScrollFocus.x + btnScrollFocus.w and my >= btnScrollFocus.y and my <= btnScrollFocus.y + btnScrollFocus.h)

    local btnScrollEnd = {
        id = "map_scroll_end",
        text = "TRÙM TỐI CAO (T20) ►",
        x = 450,
        y = V_HEIGHT - 58,
        w = 200,
        h = 42,
        color = { 0.55, 0.22, 0.22, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnScrollEnd)
    UI.drawButton(btnScrollEnd, mx >= btnScrollEnd.x and mx <= btnScrollEnd.x + btnScrollEnd.w and my >= btnScrollEnd.y and my <= btnScrollEnd.y + btnScrollEnd.h)

    -- Modal: Chuẩn Bị Giao Chiến / Bỏ Qua Nhận Thưởng (Skip Blind)
    if pendingCombatNode then
        love.graphics.setColor(0, 0, 0, 0.78)
        love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

        local mw = 640
        local mh = 390
        local mx0 = (V_WIDTH - mw) / 2
        local my0 = (V_HEIGHT - mh) / 2

        love.graphics.setColor(0.10, 0.13, 0.17, 0.98)
        UI.drawRoundedRect("fill", mx0, my0, mw, mh, 12)
        local borderCol = pendingCombatNode.type == "elite" and { 0.98, 0.55, 0.15, 1 } or { 0.85, 0.35, 0.35, 1 }
        love.graphics.setColor(borderCol)
        love.graphics.setLineWidth(2.5)
        UI.drawRoundedRect("line", mx0, my0, mw, mh, 12)

        local bannerText = (pendingCombatNode.type == "elite" and "[!] QUÁI TINH ANH TẦNG " or "GIAO CHIẾN TẦNG ") .. pendingCombatNode.floor
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(borderCol)
        love.graphics.printf(bannerText, mx0, my0 + 20, mw, "center")

        local nextHp = Monster.getHpByEncounter(game.monsterEncounterCount or 1, false, pendingCombatNode.type == "elite")
        local nextAtk = Monster.getAttackByEncounter(game.monsterEncounterCount or 1, false, pendingCombatNode.type == "elite")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(pendingCombatNode.title or "Quái Vật", mx0, my0 + 60, mw, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.hpRed)
        love.graphics.printf("Mục tiêu HP: " .. nextHp .. " HP   |   Phản công: " .. nextAtk .. " HP/lượt", mx0, my0 + 95, mw, "center")

        -- Divider
        love.graphics.setColor(0.30, 0.38, 0.45, 0.8)
        love.graphics.line(mx0 + 35, my0 + 128, mx0 + mw - 35, my0 + 128)

        -- Skip Tag Section
        local tag = pendingCombatNode.skipTag
        if tag then
            love.graphics.setFont(UI.fonts.regular)
            love.graphics.setColor(tag.color or UI.COLORS.goldYellow)
            love.graphics.printf("Thẻ Thưởng Bỏ Qua (Skip Tag): " .. tag.name, mx0 + 20, my0 + 144, mw - 40, "center")

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(tag.desc .. "\n(Rủi ro: Bỏ qua ải = Không có thưởng vàng ván & Quái sau mạnh hơn!)", mx0 + 30, my0 + 175, mw - 60, "center")
        end

        -- Action Buttons
        local btnFight = {
            id = "modal_fight_node",
            text = "VÀO CHIẾN ĐẤU",
            x = mx0 + 40,
            y = my0 + 245,
            w = 260,
            h = 52,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
        }
        local btnSkip = {
            id = "modal_skip_node",
            text = ">> BỎ QUA NHẬN THƯỞNG",
            x = mx0 + mw - 300,
            y = my0 + 245,
            w = 260,
            h = 52,
            color = { 0.88, 0.52, 0.18, 1 },
            font = UI.fonts.regular,
        }
        local btnClose = {
            id = "modal_close_preview",
            text = "Quay Lại Bản Đồ",
            x = mx0 + (mw - 180) / 2,
            y = my0 + 316,
            w = 180,
            h = 42,
            color = UI.COLORS.btnNormal,
            font = UI.fonts.small,
        }
        table.insert(buttons, btnFight)
        table.insert(buttons, btnSkip)
        table.insert(buttons, btnClose)

        UI.drawButton(btnFight, mx >= btnFight.x and mx <= btnFight.x + btnFight.w and my >= btnFight.y and my <= btnFight.y + btnFight.h)
        UI.drawButton(btnSkip, mx >= btnSkip.x and mx <= btnSkip.x + btnSkip.w and my >= btnSkip.y and my <= btnSkip.y + btnSkip.h)
        UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h)
    end
end

local function drawEventState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.07, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    local evt = game.currentEvent
    if not evt then return end

    -- Event Title & Subtitle
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(evt.title, 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(evt.subtitle, 0, 95, V_WIDTH, "center")

    -- Story panel
    local storyW = 880
    local storyH = 80
    local storyX = (V_WIDTH - storyW) / 2
    local storyY = 135

    love.graphics.setColor(0.12, 0.14, 0.18, 0.85)
    UI.drawRoundedRect("fill", storyX, storyY, storyW, storyH, 8)
    love.graphics.setColor(0.28, 0.35, 0.45, 0.6)
    UI.drawRoundedRect("line", storyX, storyY, storyW, storyH, 8)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(evt.desc, storyX + 20, storyY + 16, storyW - 40, "center")

    if game.eventOutcomeText then
        -- Outcome Box
        local outW = 740
        local outH = 170
        local outX = (V_WIDTH - outW) / 2
        local outY = 260

        love.graphics.setColor(0.12, 0.18, 0.16, 0.95)
        UI.drawRoundedRect("fill", outX, outY, outW, outH, 10)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(UI.COLORS.hpGreen)
        UI.drawRoundedRect("line", outX, outY, outW, outH, 10)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("KẾT QUẢ KỲ NGỘ", outX, outY + 22, outW, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(game.eventOutcomeText, outX + 24, outY + 68, outW - 48, "center")

        local btnContinue = {
            id = "event_continue",
            text = "TIẾP TỤC HÀNH TRÌNH ->",
            x = (V_WIDTH - 300) / 2,
            y = 480,
            w = 300,
            h = 55,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnContinue)
        UI.drawButton(btnContinue, mx >= btnContinue.x and mx <= btnContinue.x + btnContinue.w and my >= btnContinue.y and my <= btnContinue.y + btnContinue.h)
    else
        -- 3 Option Cards
        local optW = 350
        local optH = 340
        local startX = (V_WIDTH - (3 * optW + 2 * 25)) / 2
        local optY = 250

        for i, opt in ipairs(evt.options) do
            local ox = startX + (i - 1) * (optW + 25)
            local isHovered = (mx >= ox and mx <= ox + optW and my >= optY and my <= optY + optH)

            love.graphics.setColor(0.14, 0.17, 0.22, 1)
            UI.drawRoundedRect("fill", ox, optY, optW, optH, 10)
            love.graphics.setLineWidth(isHovered and 3 or 1.5)
            love.graphics.setColor(isHovered and UI.COLORS.goldYellow or { 0.32, 0.40, 0.50, 0.8 })
            UI.drawRoundedRect("line", ox, optY, optW, optH, 10)

            -- Option Number & Title
            love.graphics.setFont(UI.fonts.medium)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("Lựa chọn " .. i, ox, optY + 18, optW, "center")

            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(opt.title, ox + 15, optY + 52, optW - 30, "center")

            -- Option Desc
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(opt.desc, ox + 20, optY + 125, optW - 40, "center")

            -- Select button
            local btnOpt = {
                id = "event_opt_" .. i,
                text = "CHỌN HƯỚNG NÀY",
                x = ox + 40,
                y = optY + optH - 60,
                w = optW - 80,
                h = 44,
                color = UI.COLORS.btnPlay,
                font = UI.fonts.regular,
                optIndex = i,
            }
            table.insert(buttons, btnOpt)
            UI.drawButton(btnOpt, mx >= btnOpt.x and mx <= btnOpt.x + btnOpt.w and my >= btnOpt.y and my <= btnOpt.y + btnOpt.h)
        end
    end
end

local function drawBossDeityDraftState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.05, 0.10, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CHIẾN THẮNG TRÙM KHU VỰC!", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Hai Hộ Linh Xuất Hiện — Hãy Chọn 1:", 0, 100, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Thần bài sở hữu sức mạnh tối thượng giúp nhân bội số Mult, cấp thêm Chips hoặc bảo hộ lượt chơi!", 0, 135, V_WIDTH, "center")

    local deities = game.bossDeityDraft or {}
    local cardW = 390
    local cardH = 430
    local startX = (V_WIDTH - (2 * cardW + 60)) / 2
    local cardY = 185

    for i, d in ipairs(deities) do
        local dx = startX + (i - 1) * (cardW + 60)
        local isHovered = (mx >= dx and mx <= dx + cardW and my >= cardY and my <= cardY + cardH)

        love.graphics.setColor(0.14, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", dx, cardY, cardW, cardH, 12)

        local borderCol = UI.COLORS.goldYellow
        if d.rarity == "legendary" then borderCol = { 0.95, 0.75, 0.10, 1 }
        elseif d.rarity == "rare" then borderCol = { 0.20, 0.60, 1.0, 1 }
        end

        love.graphics.setLineWidth(isHovered and 3.5 or 2)
        love.graphics.setColor(borderCol)
        UI.drawRoundedRect("line", dx, cardY, cardW, cardH, 12)

        -- Patron Card Visual (custom sprite or vector frame)
        local cw, ch = 96, 138
        local cx = dx + (cardW - cw) / 2
        local cy = cardY + 20
        UI.drawPatronCard(d, cx, cy, cw, ch, isHovered)

        -- Name
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(d.name, dx + 10, cardY + 170, cardW - 20, "center")

        -- Rarity tag
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(borderCol)
        love.graphics.printf(d.rarity:upper() .. " DEITY", dx, cardY + 204, cardW, "center")

        -- Description
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(d.desc, dx + 24, cardY + 230, cardW - 48, "center")

        -- Choose Button
        local btnChoose = {
            id = "boss_deity_" .. i,
            text = "THỈNH VỊ THẦN NÀY",
            x = dx + 40,
            y = cardY + cardH - 65,
            w = cardW - 80,
            h = 48,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
            deityIndex = i,
        }
        table.insert(buttons, btnChoose)
        UI.drawButton(btnChoose, mx >= btnChoose.x and mx <= btnChoose.x + btnChoose.w and my >= btnChoose.y and my <= btnChoose.y + btnChoose.h)
    end
end

local function drawDeckViewerModal()
    -- Overlay dimming
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 1180
    local modalH = 650
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal background & border
    love.graphics.setColor(0.10, 0.12, 0.16, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(2.5)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("TOÀN BỘ BỘ BÀI HIỆN TẠI & BẢNG BÍ TỊCH", modalX + 24, modalY + 18)

    -- Close button
    local closeBtn = {
        id = "close_deck_viewer",
        text = "ĐÓNG [Esc]",
        x = modalX + modalW - 160,
        y = modalY + 15,
        w = 140,
        h = 38,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.regular,
    }
    UI.drawButton(closeBtn, mx >= closeBtn.x and mx <= closeBtn.x + closeBtn.w and my >= closeBtn.y and my <= closeBtn.y + closeBtn.h)

    -- Gather all cards in the full deck
    local allCards = {}
    if (state == "playing" or state == "scoring") and (#game.hand > 0 or #game.deck > 0 or #game.discardPile > 0) then
        for _, c in ipairs(game.hand) do table.insert(allCards, c) end
        for _, c in ipairs(game.deck) do table.insert(allCards, c) end
        for _, c in ipairs(game.discardPile) do table.insert(allCards, c) end
    else
        for _, c in ipairs(game.persistentDeck or {}) do table.insert(allCards, c) end
    end

    -- Filter cards
    local filteredCards = {}
    local suitCounts = { aurelia = 0, elaris = 0, vharos = 0, valoria = 0 }
    local equippedCount = 0

    for _, c in ipairs(allCards) do
        local s = c.suit
        if s == "hearts" then s = "aurelia"
        elseif s == "diamonds" then s = "valoria"
        elseif s == "clubs" then s = "elaris"
        elseif s == "spades" then s = "vharos" end

        if suitCounts[s] then
            suitCounts[s] = suitCounts[s] + 1
        end
        local hasEq = (c.equipments and #c.equipments > 0)
        if hasEq then equippedCount = equippedCount + 1 end

        if deckViewerFilter == "all" then
            table.insert(filteredCards, c)
        elseif deckViewerFilter == "equipped" and hasEq then
            table.insert(filteredCards, c)
        elseif deckViewerFilter == s or deckViewerFilter == c.suit then
            table.insert(filteredCards, c)
        end
    end

    -- Left Column: Cards (Width 680)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Tổng cộng: " .. #allCards .. " lá  (Rô ♦: " .. suitCounts.aurelia .. " | Tép ♣: " .. suitCounts.elaris .. " | Bích ♠: " .. suitCounts.vharos .. " | Cơ ♥: " .. suitCounts.valoria .. " | Đã khảm: " .. equippedCount .. " lá)", modalX + 24, modalY + 58)

    -- Filter Tabs
    local filterTabs = {
        { id = "all", text = "Tất cả (" .. #allCards .. ")" },
        { id = "aurelia", text = "Rô ♦ (" .. suitCounts.aurelia .. ")" },
        { id = "elaris", text = "Tép ♣ (" .. suitCounts.elaris .. ")" },
        { id = "vharos", text = "Bích ♠ (" .. suitCounts.vharos .. ")" },
        { id = "valoria", text = "Cơ ♥ (" .. suitCounts.valoria .. ")" },
        { id = "equipped", text = "Đã Khảm (" .. equippedCount .. ")" },
    }
    local tabStartX = modalX + 24
    local tabY = modalY + 86
    local tabW = 108
    local tabH = 30

    for idx, tab in ipairs(filterTabs) do
        local tx = tabStartX + (idx - 1) * (tabW + 6)
        local isSelected = (deckViewerFilter == tab.id)
        local isHovered = (mx >= tx and mx <= tx + tabW and my >= tabY and my <= tabY + tabH)

        love.graphics.setColor(isSelected and UI.COLORS.btnPlay or (isHovered and { 0.25, 0.35, 0.45, 1 } or { 0.18, 0.22, 0.28, 1 }))
        UI.drawRoundedRect("fill", tx, tabY, tabW, tabH, 5)
        love.graphics.setColor(isSelected and UI.COLORS.goldYellow or { 0.35, 0.45, 0.55, 0.8 })
        UI.drawRoundedRect("line", tx, tabY, tabW, tabH, 5)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tab.text, tx, tabY + 8, tabW, "center")
    end

    -- Draw Filtered Cards Grid
    local cardGridX = modalX + 24
    local cardGridY = modalY + 128
    local cw = 74
    local ch = 108
    local cgap = 10
    local cols = 8
    local hoveredDeckCard = nil

    for i, c in ipairs(filteredCards) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = cardGridX + col * (cw + cgap)
        local cy = cardGridY + row * (ch + cgap)

        if cy + ch <= modalY + modalH - 20 then
            local isHov = (mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch)
            if isHov then hoveredDeckCard = c end

            c.hovered = isHov
            UI.drawCard(c, cx, cy, cw, ch)
        end
    end

    -- Divider Line
    love.graphics.setLineWidth(2)
    love.graphics.setColor(UI.COLORS.panelBorder)
    love.graphics.line(modalX + 710, modalY + 70, modalX + 710, modalY + modalH - 25)

    -- Right Column: Poker Hand Books / Progression
    local rightX = modalX + 725
    local rightW = modalW - (rightX - modalX) - 20

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("BẢNG BÍ TỊCH CÁC TAY BÀI", rightX, modalY + 65)

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("Chỉ các tay bài đã mở khóa mới có thể đánh ra và kích hoạt điểm!", rightX, modalY + 92)

    -- List of Poker Hands
    local handList = {
        { id = "high_card", name = "ĐƠN THỦ", poker = "High Card", req = 1, base = "5 Chip x 1 Mult" },
        { id = "pair", name = "SONG ĐAO", poker = "Đôi (Pair)", req = 2, base = "10 Chip x 2 Mult" },
        { id = "two_pair", name = "SONG ĐÔI", poker = "Hai Đôi (Two Pair)", req = 4, base = "20 Chip x 2 Mult" },
        { id = "three_of_a_kind", name = "TAM HOA", poker = "Sám Cô (3 of a Kind)", req = 3, base = "30 Chip x 3 Mult" },
        { id = "straight", name = "TRƯỜNG LONG", poker = "Sảnh (Straight)", req = 5, base = "30 Chip x 4 Mult" },
        { id = "flush", name = "ĐỒNG KHÍ", poker = "Thùng (Flush)", req = 5, base = "35 Chip x 4 Mult" },
        { id = "full_house", name = "HỖN NGUYÊN", poker = "Cù Lũ (Full House)", req = 5, base = "40 Chip x 4 Mult" },
        { id = "four_of_a_kind", name = "TỨ TƯỢNG", poker = "Tứ Quý (4 of a Kind)", req = 4, base = "60 Chip x 7 Mult" },
        { id = "straight_flush", name = "VẠN KIẾM QUY TÔNG", poker = "Thùng Phá Sảnh", req = 5, base = "100 Chip x 8 Mult" },
    }

    local handItemY = modalY + 115
    local handItemH = 52

    for idx, h in ipairs(handList) do
        local hy = handItemY + (idx - 1) * (handItemH + 6)
        local isUnlocked = (game.unlockedHands[h.id] == true)

        love.graphics.setColor(isUnlocked and { 0.14, 0.20, 0.16, 0.9 } or { 0.14, 0.15, 0.18, 0.7 })
        UI.drawRoundedRect("fill", rightX, hy, rightW, handItemH, 6)

        love.graphics.setLineWidth(1)
        love.graphics.setColor(isUnlocked and UI.COLORS.hpGreen or { 0.3, 0.35, 0.4, 0.5 })
        UI.drawRoundedRect("line", rightX, hy, rightW, handItemH, 6)

        -- Hand Title
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(isUnlocked and UI.COLORS.goldYellow or UI.COLORS.textMuted)
        love.graphics.print(h.name .. " (" .. h.poker .. ")", rightX + 12, hy + 8)

        -- Hand Stats & Status Tag
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.print("Cần: " .. h.req .. " lá   |   Cơ bản: " .. h.base, rightX + 12, hy + 28)

        if isUnlocked then
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.hpGreen)
            love.graphics.printf("[ĐÃ MỞ]", rightX + rightW - 90, hy + 16, 80, "right")
        else
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.multRed)
            love.graphics.printf("[CHƯA MỞ]", rightX + rightW - 120, hy + 16, 110, "right")
        end
    end

    -- Card Equipment Hover Tooltip inside Modal
    if hoveredDeckCard then
        local c = hoveredDeckCard
        local ttW = 280
        local ttH = 30 + (c.equipments and #c.equipments or 0) * 26 + 30
        local ttx = math.min(V_WIDTH - ttW - 20, math.max(20, mx + 15))
        local tty = math.max(30, my - ttH - 10)

        love.graphics.setColor(0.08, 0.10, 0.12, 0.98)
        UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 6)
        love.graphics.setColor(UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Lá: " .. c.rankName .. " " .. c.suitSymbol .. " (Gốc: +" .. c.baseChips .. " Chips)", ttx + 10, tty + 8)

        local eqCount = c.equipments and #c.equipments or 0
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.print("Trang bị khảm trên lá (" .. Equipment.getUsedSlots(c) .. "/" .. Equipment.MAX_SLOTS .. " ô):", ttx + 10, tty + 30)

        if eqCount == 0 then
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.print("(Chưa khảm trang bị nào)", ttx + 15, tty + 48)
        else
            for s, eq in ipairs(c.equipments) do
                love.graphics.setColor(eq.color or UI.COLORS.textLight)
                love.graphics.print("• " .. eq.name .. ": " .. eq.desc, ttx + 12, tty + 32 + s * 22)
            end
        end
    end
end

local function drawChestState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.06, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("👑 RƯƠNG THƯỞNG BOSS CHIẾN THẮNG! 👑", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Chọn 1 trong 3 phần thưởng để bổ sung vào kho báu của bạn:", 0, 105, V_WIDTH, "center")

    buttons = {}
    local boxW = 340
    local boxH = 380
    local startX = (V_WIDTH - (3 * boxW + 2 * 30)) / 2
    local boxY = 160

    for i, rew in ipairs(chestRewards) do
        local bx = startX + (i - 1) * (boxW + 30)
        local isHovered = (mx >= bx and mx <= bx + boxW and my >= boxY and my <= boxY + boxH)

        love.graphics.setColor(0.14, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", bx, boxY, boxW, boxH, 12)

        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", bx, boxY, boxW, boxH, 12)

        -- Title
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        love.graphics.printf(rew.title, bx + 10, boxY + 20, boxW - 20, "center")

        -- Card or Gem Display
        if rew.type == "card" then
            local cw = 90
            local ch = 130
            UI.drawCard(rew.card, bx + (boxW - cw) / 2, boxY + 65, cw, ch)
        else
            -- Gem icon box
            love.graphics.setColor(rew.item.color[1], rew.item.color[2], rew.item.color[3], 0.25)
            UI.drawRoundedRect("fill", bx + (boxW - 120) / 2, boxY + 70, 120, 100, 8)
            love.graphics.setColor(rew.item.color)
            love.graphics.circle("fill", bx + boxW / 2, boxY + 120, 32)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(UI.fonts.large)
            love.graphics.printf(rew.item.name, bx + 10, boxY + 175, boxW - 20, "center")
        end

        -- Description
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(rew.desc, bx + 16, boxY + 225, boxW - 32, "center")

        -- Select Button
        local btnChoose = {
            id = "chest_" .. i,
            text = (rew.type == "card") and "NHẬN VÀO BỘ BÀI" or "GẮN VÀO LÁ BÀI",
            x = bx + 40,
            y = boxY + boxH - 55,
            w = boxW - 80,
            h = 42,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
            rewardIndex = i,
        }
        table.insert(buttons, btnChoose)
        UI.drawButton(btnChoose, mx >= btnChoose.x and mx <= btnChoose.x + btnChoose.w and my >= btnChoose.y and my <= btnChoose.y + btnChoose.h)
    end
end

local SOCKETING_PAGE_SIZE = 10

local function getSocketingCardRect(pageIndex)
    local cols = 5
    local cardW, cardH = 104, 150
    local gapX, gapY = 34, 48
    local totalW = cols * cardW + (cols - 1) * gapX
    local startX = (V_WIDTH - totalW) / 2
    local col = (pageIndex - 1) % cols
    local row = math.floor((pageIndex - 1) / cols)
    return startX + col * (cardW + gapX), 198 + row * (cardH + gapY), cardW, cardH
end

local function drawSocketingView()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.08, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local equipment = pendingEquipment
    if not equipment then return end

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("KHẢM TRANG BỊ VÀO BỘ BÀI", 0, 22, V_WIDTH, "center")

    -- Equipment summary panel
    local panelX, panelY, panelW, panelH = 225, 62, 830, 104
    local eqColor = equipment.color or UI.COLORS.goldYellow
    love.graphics.setColor(0.10, 0.12, 0.17, 0.96)
    UI.drawRoundedRect("fill", panelX, panelY, panelW, panelH, 10)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(eqColor)
    UI.drawRoundedRect("line", panelX, panelY, panelW, panelH, 10)

    love.graphics.setColor(eqColor[1], eqColor[2], eqColor[3], 0.22)
    love.graphics.circle("fill", panelX + 58, panelY + panelH / 2, 34)
    love.graphics.setColor(eqColor)
    love.graphics.circle("line", panelX + 58, panelY + panelH / 2, 34)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(equipment.icon or "◆", panelX + 24, panelY + 31, 68, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(eqColor)
    love.graphics.print(equipment.name, panelX + 112, panelY + 14)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(equipment.desc or "", panelX + 112, panelY + 44, panelW - 136, "left")
    local slotsNeeded = equipment.slotsNeeded or 1
    local rarityText = equipment.rarity == "legendary" and "HUYỀN THOẠI" or "TRANG BỊ"
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print(rarityText .. "  •  Cần " .. slotsNeeded .. " ô  •  Không thể gắn trùng loại", panelX + 112, panelY + 78)

    local allCards = getAllDeckCards()
    local totalPages = math.max(1, math.ceil(#allCards / SOCKETING_PAGE_SIZE))
    socketingPage = math.max(1, math.min(socketingPage, totalPages))
    local firstCard = (socketingPage - 1) * SOCKETING_PAGE_SIZE + 1
    local lastCard = math.min(#allCards, firstCard + SOCKETING_PAGE_SIZE - 1)

    for _, c in ipairs(allCards) do c.hovered = false end
    for deckIndex = firstCard, lastCard do
        local c = allCards[deckIndex]
        local pageIndex = deckIndex - firstCard + 1
        local cx, cy, cardW, cardH = getSocketingCardRect(pageIndex)
        local isHovered = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH)
        local canAttach, reason = Equipment.canAttach(c, equipment)

        c.hovered = isHovered
        UI.drawCard(c, cx, cy, cardW, cardH)

        if not canAttach then
            love.graphics.setColor(0.08, 0.04, 0.06, 0.58)
            UI.drawRoundedRect("fill", cx, cy, cardW, cardH, 8)
            love.graphics.setLineWidth(2)
            love.graphics.setColor(UI.COLORS.multRed)
            UI.drawRoundedRect("line", cx, cy, cardW, cardH, 8)
            love.graphics.setFont(UI.fonts.medium)
            love.graphics.printf(reason and reason:find("cùng loại") and "ĐÃ CÓ" or "THIẾU Ô", cx, cy + cardH / 2 - 12, cardW, "center")
        elseif isHovered then
            love.graphics.setLineWidth(3)
            love.graphics.setColor(UI.COLORS.hpGreen)
            UI.drawRoundedRect("line", cx - 2, cy - 2, cardW + 4, cardH + 4, 9)
        end

        local usedSlots = Equipment.getUsedSlots(c)
        local freeSlots = Equipment.MAX_SLOTS - usedSlots
        love.graphics.setColor(canAttach and 0.10 or 0.20, canAttach and 0.20 or 0.08, canAttach and 0.16 or 0.10, 0.95)
        UI.drawRoundedRect("fill", cx, cy + cardH + 5, cardW, 24, 5)
        love.graphics.setColor(canAttach and UI.COLORS.hpGreen or UI.COLORS.multRed)
        UI.drawRoundedRect("line", cx, cy + cardH + 5, cardW, 24, 5)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.printf(usedSlots .. "/" .. Equipment.MAX_SLOTS .. " ô  •  còn " .. freeSlots, cx, cy + cardH + 10, cardW, "center")
    end

    buttons = {}
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Nhấp vào lá còn đủ ô để khảm  •  Trang " .. socketingPage .. "/" .. totalPages .. "  •  " .. #allCards .. " lá trong bộ bài", 0, 590, V_WIDTH, "center")
    if socketingMessage then
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.printf(socketingMessage, 0, 614, V_WIDTH, "center")
    end

    local btnPrev = {
        id = "socket_prev", text = "← TRANG TRƯỚC", x = 250, y = 642, w = 190, h = 44,
        color = UI.COLORS.btnNormal, font = UI.fonts.small, disabled = socketingPage <= 1,
    }
    local btnSkip = {
        id = "skip_socket",
        text = "BỎ QUA TRANG BỊ",
        x = (V_WIDTH - 260) / 2,
        y = 642,
        w = 260,
        h = 44,
        color = UI.COLORS.btnNormal,
        font = UI.fonts.regular,
    }
    local btnNext = {
        id = "socket_next", text = "TRANG SAU →", x = 840, y = 642, w = 190, h = 44,
        color = UI.COLORS.btnNormal, font = UI.fonts.small, disabled = socketingPage >= totalPages,
    }
    table.insert(buttons, btnPrev)
    table.insert(buttons, btnSkip)
    table.insert(buttons, btnNext)
    for _, btn in ipairs(buttons) do
        local hovered = mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h
        UI.drawButton(btn, hovered and not btn.disabled, false)
    end
end

local function generateTreasureRewards()
    treasureRewards = {}
    local rewardCard = (Rng.random() < 0.5) and Deck.createRewardCard(game.selectedSuit) or Deck.newCard(Rng.random(9, 13), game.selectedSuit)
    table.insert(treasureRewards, {
        type = "card",
        card = rewardCard,
        title = "TIẾP VIỆN: " .. rewardCard.rankName .. " " .. rewardCard.suitName,
        desc = "Nhận lá " .. rewardCard.rankName .. rewardCard.suitSymbol .. " (" .. rewardCard.baseChips .. " Chips, bền " .. rewardCard.rank .. " lần đánh) vào bộ bài!",
        color = rewardCard.color,
    })

    local eq1 = Equipment.getRandomEquipment()
    table.insert(treasureRewards, {
        type = "equipment",
        item = eq1,
        title = "CỔ VẬT: " .. eq1.name,
        desc = eq1.desc,
        color = eq1.color,
    })

    local eq2 = Equipment.getRandomEquipment()
    while eq2.id == eq1.id do
        eq2 = Equipment.getRandomEquipment()
    end
    table.insert(treasureRewards, {
        type = "equipment",
        item = eq2,
        title = "CỔ VẬT: " .. eq2.name,
        desc = eq2.desc,
        color = eq2.color,
    })
end

local function drawTreasureState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.06, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("RƯƠNG BÁU CỔ ĐẠI (TẦNG " .. (game.map and game.map.currentFloor or 1) .. ")", 0, 40, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Bạn khai mở một rương báu cổ xưa. Hãy chọn 1 phần thưởng miễn phí:", 0, 105, V_WIDTH, "center")

    buttons = {}
    local boxW = 340
    local boxH = 380
    local startX = (V_WIDTH - (3 * boxW + 2 * 30)) / 2
    local boxY = 160

    for i, rew in ipairs(treasureRewards) do
        local bx = startX + (i - 1) * (boxW + 30)
        local isHovered = (mx >= bx and mx <= bx + boxW and my >= boxY and my <= boxY + boxH)

        love.graphics.setColor(0.14, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", bx, boxY, boxW, boxH, 12)

        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", bx, boxY, boxW, boxH, 12)

        -- Title
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(rew.color or UI.COLORS.goldYellow)
        love.graphics.printf(rew.title, bx + 10, boxY + 20, boxW - 20, "center")

        -- Card or Gem Display
        if rew.type == "card" then
            local cw = 90
            local ch = 130
            UI.drawCard(rew.card, bx + (boxW - cw) / 2, boxY + 65, cw, ch)
        else
            love.graphics.setColor(rew.item.color[1], rew.item.color[2], rew.item.color[3], 0.25)
            UI.drawRoundedRect("fill", bx + (boxW - 120) / 2, boxY + 70, 120, 100, 8)
            love.graphics.setColor(rew.item.color)
            love.graphics.circle("fill", bx + boxW / 2, boxY + 120, 32)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(UI.fonts.large)
            love.graphics.printf(rew.item.name, bx + 10, boxY + 175, boxW - 20, "center")
        end

        -- Description
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(rew.desc, bx + 16, boxY + 225, boxW - 32, "center")

        -- Select Button
        local btnChoose = {
            id = "treasure_" .. i,
            text = (rew.type == "card") and "NHẬN VÀO BỘ BÀI" or "GẮN VÀO LÁ BÀI",
            x = bx + 40,
            y = boxY + boxH - 55,
            w = boxW - 80,
            h = 42,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
            rewardIndex = i,
        }
        table.insert(buttons, btnChoose)
        UI.drawButton(btnChoose, mx >= btnChoose.x and mx <= btnChoose.x + btnChoose.w and my >= btnChoose.y and my <= btnChoose.y + btnChoose.h)
    end
end

local function drawRestState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.12, 0.10, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.hpGreen)
    love.graphics.printf("TRẠM NGHỈ & LÒ RÈN CỔ ĐẠI (TẦNG " .. (game.map and game.map.currentFloor or 1) .. ")", 0, 35, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Nơi lữ khách dừng chân để hồi phục thể lực hoặc mài sắc binh khí trước thềm đại chiến!", 0, 95, V_WIDTH, "center")

    if not restStateData.chosenAction then
        -- Display 2 big choices
        local choiceW = 540
        local choiceH = 360
        local gap = 40
        local startX = (V_WIDTH - (2 * choiceW + gap)) / 2
        local choiceY = 160

        -- Choice 1: Rest (Dưỡng Sức)
        local isHov1 = (mx >= startX and mx <= startX + choiceW and my >= choiceY and my <= choiceY + choiceH)
        love.graphics.setColor(0.12, 0.18, 0.15, 0.95)
        UI.drawRoundedRect("fill", startX, choiceY, choiceW, choiceH, 12)
        love.graphics.setLineWidth(isHov1 and 3 or 1.5)
        love.graphics.setColor(isHov1 and UI.COLORS.goldYellow or UI.COLORS.hpGreen)
        UI.drawRoundedRect("line", startX, choiceY, choiceW, choiceH, 12)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.hpGreen)
        love.graphics.printf("[ DƯỠNG THƯƠNG & DƯỠNG SỨC ]", startX, choiceY + 28, choiceW, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Hồi +35 HP, +1 Max Hand & +1 Discard", startX, choiceY + 80, choiceW, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Hồi phục ngay +35 HP sinh lực (Máu hiện tại: " .. (game.playerHp or 100) .. "/" .. (game.maxPlayerHp or 100) .. " HP)!\nĐồng thời tăng vĩnh viễn giới hạn Lượt Đánh (" .. game.maxHands .. " -> " .. (game.maxHands + 1) .. ") và Lượt Đổi bài (" .. game.maxDiscards .. " -> " .. (game.maxDiscards + 1) .. ")!", startX + 30, choiceY + 130, choiceW - 60, "center")

        local btnRest = {
            id = "rest_action_heal",
            text = "CHỌN HỒI MÁU (+35 HP) & DƯỠNG SỨC",
            x = startX + 40,
            y = choiceY + choiceH - 65,
            w = choiceW - 80,
            h = 46,
            color = UI.COLORS.hpGreen,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnRest)
        UI.drawButton(btnRest, mx >= btnRest.x and mx <= btnRest.x + btnRest.w and my >= btnRest.y and my <= btnRest.y + btnRest.h)

        -- Choice 2: Forge (Mài Sắc Bài)
        local cx2 = startX + choiceW + gap
        local isHov2 = (mx >= cx2 and mx <= cx2 + choiceW and my >= choiceY and my <= choiceY + choiceH)
        love.graphics.setColor(0.18, 0.14, 0.12, 0.95)
        UI.drawRoundedRect("fill", cx2, choiceY, choiceW, choiceH, 12)
        love.graphics.setLineWidth(isHov2 and 3 or 1.5)
        love.graphics.setColor(isHov2 and UI.COLORS.goldYellow or { 0.95, 0.55, 0.2, 1 })
        UI.drawRoundedRect("line", cx2, choiceY, choiceW, choiceH, 12)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("[ LÒ RÈN TÔI LUYỆN: RANK +1 ]", cx2, choiceY + 28, choiceW, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Nâng Cấp & Phục Hồi Độ Bền Lá Bài", cx2, choiceY + 80, choiceW, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Chọn 1 lá bài trong bộ bài để tăng +1 Rank (Ví dụ: 3 -> 4, A -> 2, 8 -> 9).\nGiúp lá bài tăng thêm Chips cơ bản và kéo dài độ bền thêm 1 lần đánh nữa!", cx2 + 30, choiceY + 130, choiceW - 60, "center")

        local btnForge = {
            id = "rest_action_forge",
            text = "CHỌN TÔI LUYỆN BÀI (+1 RANK)",
            x = cx2 + 40,
            y = choiceY + choiceH - 65,
            w = choiceW - 80,
            h = 46,
            color = { 0.85, 0.45, 0.15, 1 },
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnForge)
        UI.drawButton(btnForge, mx >= btnForge.x and mx <= btnForge.x + btnForge.w and my >= btnForge.y and my <= btnForge.y + btnForge.h)

    elseif restStateData.chosenAction == "forge" and not restStateData.selectedCard then
        -- Select a card to upgrade
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("Nhấp trực tiếp vào lá bài bạn muốn nâng cấp Rank (+1 Rank & hồi bền):", 0, 150, V_WIDTH, "center")

        local allCards = getAllDeckCards()
        for i, c in ipairs(allCards) do
            local cx, cy, cw, ch = getCardGridPos(i, #allCards, 100, 145, 16, 32, 8, 250)
            local isHovered = (mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch)
            c.hovered = isHovered
            UI.drawCard(c, cx, cy, cw, ch)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            local nextRank = Deck.RANK_NAMES[c.rank + 1] or "Max"
            love.graphics.printf("➔ " .. nextRank, cx, cy + ch + 10, cw, "center")
        end

    else
        -- Outcome confirmation
        love.graphics.setColor(0.12, 0.16, 0.20, 0.95)
        UI.drawRoundedRect("fill", 240, 200, V_WIDTH - 480, 240, 12)
        love.graphics.setColor(UI.COLORS.hpGreen)
        UI.drawRoundedRect("line", 240, 200, V_WIDTH - 480, 240, 12)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.hpGreen)
        love.graphics.printf("✨ THỰC HIỆN THÀNH CÔNG! ✨", 240, 230, V_WIDTH - 480, "center")

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(restStateData.message or "Đã hoàn tất nghỉ ngơi!", 260, 285, V_WIDTH - 520, "center")

        local btnLeaveRest = {
            id = "leave_rest",
            text = "TIẾP TỤC HÀNH TRÌNH (VỀ BẢN ĐỒ) ->",
            x = (V_WIDTH - 380) / 2,
            y = 370,
            w = 380,
            h = 50,
            color = UI.COLORS.btnPlay,
            font = UI.fonts.regular,
        }
        table.insert(buttons, btnLeaveRest)
        UI.drawButton(btnLeaveRest, mx >= btnLeaveRest.x and mx <= btnLeaveRest.x + btnLeaveRest.w and my >= btnLeaveRest.y and my <= btnLeaveRest.y + btnLeaveRest.h)
    end
end

local function drawShopTransferView()
    -- Overlay
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.10, 0.13, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    -- Title
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("HOÁN ĐỔI TRANG BỊ GIỮA CÁC LÁ BÀI (SHOP TRANSFER)", 0, 25, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("1. Chọn Lá Nguồn -> 2. Chọn Trang Bị Muốn Gỡ -> 3. Chọn Lá Đích Để Gắn Sang (Tối đa " .. Equipment.MAX_SLOTS .. " ô/lá)", 0, 62, V_WIDTH, "center")

    local allCards = getAllDeckCards()

    -- Auto select first equipped card if none selected
    if not transferSourceCard then
        for _, c in ipairs(allCards) do
            if c.equipments and #c.equipments > 0 then
                transferSourceCard = c
                break
            end
        end
    end

    -- Section 1: Choose Source Card
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("BƯỚC 1: Chọn lá bài nguồn (Đang mang trang bị):", 80, 95)

    local cw = 90
    local ch = 130
    local gap = 18
    local totalW = #allCards * cw + math.max(0, #allCards - 1) * gap
    local startX = math.max(80, (V_WIDTH - totalW) / 2)
    local cardY = 125

    for i, c in ipairs(allCards) do
        local cx = startX + (i - 1) * (cw + gap)
        local isSelected = (transferSourceCard == c)
        local isHovered = (mx >= cx and mx <= cx + cw and my >= cardY and my <= cardY + ch)
        c.hovered = isHovered

        UI.drawCard(c, cx, cardY, cw, ch)

        if isSelected then
            love.graphics.setLineWidth(3.5)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", cx - 3, cardY - 3, cw + 6, ch + 6, 10)
        end

        local eqCount = Equipment.getUsedSlots(c)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(eqCount > 0 and UI.COLORS.chipsBlue or UI.COLORS.textMuted)
        love.graphics.printf(eqCount .. "/" .. Equipment.MAX_SLOTS .. " ô", cx, cardY + ch + 6, cw, "center")
    end

    -- Section 2: Choose Equipment slot from transferSourceCard
    if transferSourceCard then
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BƯỚC 2: Chọn trang bị muốn gỡ từ Lá " .. transferSourceCard.rankName .. transferSourceCard.suitSymbol .. ":", 80, 285)

        local eqList = transferSourceCard.equipments or {}
        if #eqList == 0 then
            love.graphics.setFont(UI.fonts.regular)
            love.graphics.setColor(UI.COLORS.multRed)
            love.graphics.print("Lá bài này hiện không có trang bị nào để gỡ!", 100, 320)
        else
            local eqBoxW = 210
            local eqBoxH = 65
            for idx, eq in ipairs(eqList) do
                local ex = 80 + (idx - 1) * (eqBoxW + 16)
                local ey = 320
                local isEqSel = (transferSourceEqIndex == idx)
                local isEqHov = (mx >= ex and mx <= ex + eqBoxW and my >= ey and my <= ey + eqBoxH)

                love.graphics.setColor(isEqSel and { 0.25, 0.35, 0.45, 1 } or { 0.16, 0.20, 0.25, 0.9 })
                UI.drawRoundedRect("fill", ex, ey, eqBoxW, eqBoxH, 8)
                love.graphics.setLineWidth(isEqSel and 3 or 1.5)
                love.graphics.setColor(isEqSel and UI.COLORS.goldYellow or (eq.color or UI.COLORS.panelBorder))
                UI.drawRoundedRect("line", ex, ey, eqBoxW, eqBoxH, 8)

                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(eq.color or 1, 1, 1, 1)
                love.graphics.print("[Ô " .. idx .. "] " .. eq.name, ex + 10, ey + 8)

                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(eq.desc, ex + 10, ey + 30, eqBoxW - 20, "left")
            end
        end
    end

    -- Section 3: Choose Target Card
    if transferSourceCard and transferSourceEqIndex and transferSourceCard.equipments and transferSourceCard.equipments[transferSourceEqIndex] then
        local chosenEq = transferSourceCard.equipments[transferSourceEqIndex]
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("BƯỚC 3: Chọn lá bài đích để nhận [" .. chosenEq.name .. "]:", 80, 410)

        local targetY = 445
        for i, c in ipairs(allCards) do
            local cx = startX + (i - 1) * (cw + gap)
            local isSameCard = (c == transferSourceCard)
            local isFull = (c.equipments and #c.equipments >= 5)
            local canTransfer = not isSameCard and not isFull
            local isHovered = (canTransfer and mx >= cx and mx <= cx + cw and my >= targetY and my <= targetY + ch)
            c.hovered = isHovered

            UI.drawCard(c, cx, targetY, cw, ch)

            if isSameCard then
                love.graphics.setColor(0, 0, 0, 0.6)
                UI.drawRoundedRect("fill", cx, targetY, cw, ch, 8)
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textMuted)
                love.graphics.printf("[Nguồn]", cx, targetY + ch / 2 - 8, cw, "center")
            elseif isFull then
                love.graphics.setColor(0, 0, 0, 0.6)
                UI.drawRoundedRect("fill", cx, targetY, cw, ch, 8)
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.multRed)
                love.graphics.printf("[Đã Đầy 5/5]", cx, targetY + ch / 2 - 8, cw, "center")
            else
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.hpGreen)
                love.graphics.printf("Gắn vào đây", cx, targetY + ch + 6, cw, "center")
            end
        end
    end

    -- Message banner
    if transferMessage then
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(transferMessage, 80, 630, V_WIDTH - 420, "left")
    end

    -- Close / Return button
    local btnCloseTransfer = {
        id = "close_shop_transfer",
        text = "XONG / QUAY LẠI CỬA HÀNG [Esc]",
        x = V_WIDTH - 320,
        y = 615,
        w = 280,
        h = 50,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.regular,
    }
    table.insert(buttons, btnCloseTransfer)
    UI.drawButton(btnCloseTransfer, mx >= btnCloseTransfer.x and mx <= btnCloseTransfer.x + btnCloseTransfer.w and my >= btnCloseTransfer.y and my <= btnCloseTransfer.y + btnCloseTransfer.h)
end

local function drawCardInspectorModal(card)
    if not card then return end
    -- Overlay dimming
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 860
    local modalH = 540
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal Box
    love.graphics.setColor(0.09, 0.11, 0.15, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(2.5)
    love.graphics.setColor(card.color or UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Title (Shortened to not overlap close button)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("CHI TIẾT LÁ BÀI & TRANG BỊ KHẢM", modalX + 28, modalY + 20)

    -- Close button
    local btnClose = {
        id = "close_inspector",
        text = "ĐÓNG [Esc / Chuột Phải]",
        x = modalX + modalW - 240,
        y = modalY + 18,
        w = 210,
        h = 36,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h)

    -- Left side: Card Art & Durability
    local cardArtW = 150
    local cardArtH = 220
    local cardArtX = modalX + 40
    local cardArtY = modalY + 80
    UI.drawCard(card, cardArtX, cardArtY, cardArtW, cardArtH)

    -- Role & Faction details block under card art
    local durY = cardArtY + cardArtH + 15
    local durH = 175
    love.graphics.setColor(0.14, 0.17, 0.22, 0.9)
    UI.drawRoundedRect("fill", cardArtX, durY, cardArtW, durH, 8)
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(card.color or UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", cardArtX, durY, cardArtW, durH, 8)

    local role = card.role and Deck.CARD_ROLES[card.role] or Deck.getCardRole(card.rank)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(role.icon .. " " .. role.name, cardArtX, durY + 10, cardArtW, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(card.color or UI.COLORS.textLight)
    love.graphics.printf("Chất: " .. (card.suitSymbol or "?"), cardArtX + 8, durY + 32, cardArtW - 16, "center")

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(role.desc, cardArtX + 8, durY + 54, cardArtW - 16, "left")

    love.graphics.setColor(UI.COLORS.hpGreen)
    love.graphics.printf("Điểm: +" .. card.baseChips .. " Chips", cardArtX + 8, durY + durH - 24, cardArtW - 16, "center")

    -- Right side: Equipment Sockets
    local rightX = modalX + 230
    local rightW = modalW - 260
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textLight)
    local currentEqCount = card.equipments and #card.equipments or 0
    local maxSockets = card.maxSockets or (Equipment and Equipment.MAX_SLOTS) or 3
    love.graphics.print("CÁC Ô KHẢM TRANG BỊ (" .. currentEqCount .. "/" .. maxSockets .. " Ô):", rightX, modalY + 80)

    local slotH = 68
    local slotStartY = modalY + 115
    for s = 1, maxSockets do
        local sy = slotStartY + (s - 1) * (slotH + 12)
        local isUnlocked = s <= (card.unlockedSockets or 1)
        local eq = card.equipments and card.equipments[s]

        if eq then
            love.graphics.setColor(0.16, 0.20, 0.26, 0.95)
            UI.drawRoundedRect("fill", rightX, sy, rightW, slotH, 8)
            love.graphics.setLineWidth(2)
            love.graphics.setColor(eq.color or UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", rightX, sy, rightW, slotH, 8)

            -- Slot badge & name
            love.graphics.setFont(UI.fonts.regular)
            love.graphics.setColor(eq.color or UI.COLORS.goldYellow)
            love.graphics.print("[Ô " .. s .. "/" .. maxSockets .. "] " .. eq.name, rightX + 16, sy + 10)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(eq.desc, rightX + 20, sy + 38, rightW - 40, "left")
        elseif not isUnlocked then
            love.graphics.setColor(0.10, 0.10, 0.12, 0.5)
            UI.drawRoundedRect("fill", rightX, sy, rightW, slotH, 8)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.22, 0.22, 0.26, 0.4)
            UI.drawRoundedRect("line", rightX, sy, rightW, slotH, 8)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.35, 0.38, 0.45, 0.6)
            love.graphics.print("[Ô " .. s .. "/" .. maxSockets .. "] 🔒 Hốc Khảm Chưa Mở Khóa", rightX + 16, sy + 14)

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.print("Mở khóa thêm hốc khảm bài bằng Khế Ước hoặc sự kiện đặc biệt.", rightX + 20, sy + 40)
        else
            love.graphics.setColor(0.11, 0.13, 0.17, 0.6)
            UI.drawRoundedRect("fill", rightX, sy, rightW, slotH, 8)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.28, 0.32, 0.38, 0.4)
            UI.drawRoundedRect("line", rightX, sy, rightW, slotH, 8)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.4, 0.45, 0.52, 0.7)
            love.graphics.print("[Ô " .. s .. "/" .. maxSockets .. "] Ô Khảm Trống", rightX + 16, sy + 14)

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.print("Mua trang bị tại Cửa Hàng hoặc nhặt từ Rương Báu để khảm vào ô này.", rightX + 20, sy + 40)
        end
    end
end

local function drawHandbookModal()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 960
    local modalH = 650
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal Box
    love.graphics.setColor(0.08, 0.10, 0.14, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(2.5)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header Title
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("SỔ TAY CÁC THẾ BÀI POKER", modalX + 30, modalY + 16)

    -- Subtitle
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("9 Tuyệt Kỹ Võ Đạo Thẻ Bài - Kiểm tra điều kiện kích hoạt & trạng thái Mở Khóa Bí Tịch", modalX + 32, modalY + 48)

    -- Close Button
    local btnClose = {
        id = "close_handbook",
        text = "ĐÓNG [Esc / H]",
        x = modalX + modalW - 190,
        y = modalY + 16,
        w = 160,
        h = 36,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h)

    local handDescriptions = {
        straight_flush = "5 lá bài vừa có số liên tiếp vừa cùng một chất (Thùng phá sảnh)",
        four_of_a_kind = "4 lá bài có cùng một cấp số / Rank (Tứ quý uy lực)",
        full_house     = "1 bộ ba lá cùng số kết hợp 1 bộ đôi lá cùng số (Cù lũ hỗn nguyên)",
        flush          = "5 lá bài có cùng một chất bài (Thùng đồng khí)",
        straight       = "5 lá bài có cấp số liên tiếp nhau (Sảnh trường long)",
        three_of_a_kind= "3 lá bài có cùng một cấp số / Rank (Sám cô tam hoa)",
        two_pair       = "2 cặp lá bài có cấp số giống nhau (Hai đôi song đôi)",
        pair           = "2 lá bài có cùng một cấp số / Rank (Đôi song đao)",
        high_card      = "1 lá bài có giá trị số cao nhất (Mậu thầu - Luôn mở khóa)",
    }

    local rowY = modalY + 74
    local rowH = 56
    local rowGap = 6

    for idx, h in ipairs(Poker.HAND_TYPES_ORDERED) do
        local cy = rowY + (idx - 1) * (rowH + rowGap)
        local isUnlocked = (game.unlockedHands[h.id] == true)

        -- Row Container
        if isUnlocked then
            love.graphics.setColor(0.12, 0.17, 0.22, 0.95)
            UI.drawRoundedRect("fill", modalX + 25, cy, modalW - 50, rowH, 8)
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(0.25, 0.65, 0.45, 0.8)
            UI.drawRoundedRect("line", modalX + 25, cy, modalW - 50, rowH, 8)
        else
            love.graphics.setColor(0.10, 0.11, 0.14, 0.8)
            UI.drawRoundedRect("fill", modalX + 25, cy, modalW - 50, rowH, 8)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(0.25, 0.28, 0.35, 0.4)
            UI.drawRoundedRect("line", modalX + 25, cy, modalW - 50, rowH, 8)
        end

        local handLvl = (game.handLevels and game.handLevels[h.id]) or 1
        local stats = Poker.getHandStats(h.id, handLvl)

        -- Status Badge (Left)
        local badgeW = 95
        local badgeH = 30
        local badgeX = modalX + 38
        local badgeY = cy + (rowH - badgeH) / 2
        if isUnlocked then
            love.graphics.setColor(0.15, 0.45, 0.25, 0.9)
            UI.drawRoundedRect("fill", badgeX, badgeY, badgeW, badgeH, 6)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.3, 1.0, 0.5, 1)
            love.graphics.printf("ĐÃ MỞ", badgeX, badgeY + 5, badgeW, "center")
        else
            love.graphics.setColor(0.35, 0.15, 0.15, 0.85)
            UI.drawRoundedRect("fill", badgeX, badgeY, badgeW, badgeH, 6)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(0.95, 0.4, 0.4, 1)
            love.graphics.printf("ĐANG KHÓA", badgeX, badgeY + 5, badgeW, "center")
        end

        -- Level Badge (Lv. X)
        local lvlBadgeW = 58
        local lvlBadgeX = badgeX + badgeW + 8
        love.graphics.setColor(handLvl > 1 and { 0.20, 0.45, 0.85, 0.95 } or { 0.18, 0.22, 0.28, 0.9 })
        UI.drawRoundedRect("fill", lvlBadgeX, badgeY, lvlBadgeW, badgeH, 6)
        love.graphics.setColor(handLvl > 1 and UI.COLORS.goldYellow or { 0.35, 0.45, 0.55, 0.8 })
        UI.drawRoundedRect("line", lvlBadgeX, badgeY, lvlBadgeW, badgeH, 6)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(handLvl > 1 and UI.COLORS.goldYellow or UI.COLORS.textLight)
        love.graphics.printf("Lv. " .. stats.level, lvlBadgeX, badgeY + 5, lvlBadgeW, "center")

        -- Hand Title & Requirements
        local textX = lvlBadgeX + lvlBadgeW + 14
        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(isUnlocked and UI.COLORS.goldYellow or { 0.6, 0.65, 0.7, 0.7 })
        love.graphics.print(h.vnName .. " (" .. h.name .. ")", textX, cy + 6)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(isUnlocked and UI.COLORS.textLight or UI.COLORS.textMuted)
        local reqStr = handDescriptions[h.id] or (h.subtitle .. " (" .. h.requiredCards .. " lá)")
        love.graphics.print(reqStr, textX, cy + 32)

        -- Leveled Stats (Right)
        local statsW = 210
        local statsX = modalX + modalW - 25 - statsW - 15
        love.graphics.setColor(0.07, 0.08, 0.11, 0.8)
        UI.drawRoundedRect("fill", statsX, cy + 8, statsW, rowH - 16, 6)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.chipsBlue)
        love.graphics.printf(stats.chips .. " Chips", statsX + 6, cy + 18, 85, "center")
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.print(" × ", statsX + 93, cy + 18)
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.printf(stats.mult .. " Mult", statsX + 115, cy + 18, 85, "center")
    end
end

local function drawPauseMenuModal()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.72)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 380
    local modalH = 430
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal Box
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setColor(UI.COLORS.panelBorder)
    love.graphics.setLineWidth(2)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("TẠM DỪNG", modalX, modalY + 24, modalW, "center")
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Nhấn [ESC] để quay lại ván đấu", modalX, modalY + 58, modalW, "center")

    -- Buttons inside Pause Modal
    local btnW = 300
    local btnH = 44
    local startY = modalY + 95
    local spacing = 58
    local cx = modalX + (modalW - btnW) / 2

    local pauseButtons = {
        { id = "pause_resume", text = "TIẾP TỤC TRẬN ĐẤU", color = UI.COLORS.btnPlay, y = startY },
        { id = "pause_handbook", text = "SỔ TAY CHIẾN THUẬT", color = UI.COLORS.btnNormal, y = startY + spacing },
        { id = "pause_settings", text = "CÀI ĐẶT TRÒ CHƠI", color = UI.COLORS.btnNormal, y = startY + spacing * 2 },
        { id = "pause_abandon", text = "TỪ BỎ VÁN ĐẤU (VỀ MENU)", color = { 0.45, 0.22, 0.24, 1 }, y = startY + spacing * 3 },
        { id = "pause_quit", text = "THOÁT RA DESKTOP", color = { 0.32, 0.16, 0.18, 1 }, y = startY + spacing * 4 },
    }

    for _, pb in ipairs(pauseButtons) do
        pb.x = cx
        pb.w = btnW
        pb.h = btnH
        pb.font = UI.fonts.regular
        table.insert(buttons, pb)
        local isH = (mx >= pb.x and mx <= pb.x + pb.w and my >= pb.y and my <= pb.y + pb.h)
        local isP = (juice.buttonPressedId == pb.id)
        UI.drawButton(pb, isH, isP)
    end
end

local function drawSettingsModal()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    local modalW = 500
    local modalH = 430
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    -- Modal Box
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setColor(UI.COLORS.panelBorder)
    love.graphics.setLineWidth(2)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("CÀI ĐẶT TRÒ CHƠI", modalX, modalY + 24, modalW, "center")

    -- 1. SFX Volume Option
    local row1Y = modalY + 80
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Âm Lượng Hiệu Ứng (SFX):", modalX + 35, row1Y + 6)

    local volPct = math.floor(settings.sfxVolume * 100 + 0.5) .. "%"
    local btnVolDown = { id = "setting_voldown", text = "-", x = modalX + 300, y = row1Y, w = 40, h = 34, font = UI.fonts.medium }
    local btnVolUp = { id = "setting_volup", text = "+", x = modalX + 410, y = row1Y, w = 40, h = 34, font = UI.fonts.medium }
    table.insert(buttons, btnVolDown)
    table.insert(buttons, btnVolUp)
    UI.drawButton(btnVolDown, mx >= btnVolDown.x and mx <= btnVolDown.x + btnVolDown.w and my >= btnVolDown.y and my <= btnVolDown.y + btnVolDown.h, juice.buttonPressedId == btnVolDown.id)
    UI.drawButton(btnVolUp, mx >= btnVolUp.x and mx <= btnVolUp.x + btnVolUp.w and my >= btnVolUp.y and my <= btnVolUp.y + btnVolUp.h, juice.buttonPressedId == btnVolUp.id)

    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(volPct, modalX + 340, row1Y + 7, 70, "center")

    -- 2. Fast Scoring Speed Option
    local row2Y = modalY + 138
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Tốc Độ Tính Điểm:", modalX + 35, row2Y + 6)

    local speedText = settings.fastScoring and "Siêu Tốc (2x)" or "Bình Thường (1x)"
    local btnSpeed = { id = "setting_speed", text = speedText, x = modalX + 300, y = row2Y, w = 150, h = 34, color = settings.fastScoring and UI.COLORS.xmultGold or UI.COLORS.btnNormal, font = UI.fonts.small }
    table.insert(buttons, btnSpeed)
    UI.drawButton(btnSpeed, mx >= btnSpeed.x and mx <= btnSpeed.x + btnSpeed.w and my >= btnSpeed.y and my <= btnSpeed.y + btnSpeed.h, juice.buttonPressedId == btnSpeed.id)

    -- 3. Fullscreen Option
    local row3Y = modalY + 196
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Chế Độ Hiển Thị:", modalX + 35, row3Y + 6)

    local fsText = settings.fullscreen and "Toàn Màn Hình" or "Cửa Sổ"
    local btnFs = { id = "setting_fullscreen", text = fsText, x = modalX + 300, y = row3Y, w = 150, h = 34, color = settings.fullscreen and UI.COLORS.btnPlay or UI.COLORS.btnNormal, font = UI.fonts.small }
    table.insert(buttons, btnFs)
    UI.drawButton(btnFs, mx >= btnFs.x and mx <= btnFs.x + btnFs.w and my >= btnFs.y and my <= btnFs.y + btnFs.h, juice.buttonPressedId == btnFs.id)

    -- 4. CRT Retro Filter Option
    local row4Y = modalY + 254
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Bộ Lọc CRT Retro:", modalX + 35, row4Y + 6)

    local crtText = settings.crtEnabled and "BẬT (Retro CRT)" or "TẮT (Sắc Nét)"
    local btnCrt = { id = "setting_crt", text = crtText, x = modalX + 300, y = row4Y, w = 150, h = 34, color = settings.crtEnabled and UI.COLORS.btnPlay or UI.COLORS.btnNormal, font = UI.fonts.small }
    table.insert(buttons, btnCrt)
    UI.drawButton(btnCrt, mx >= btnCrt.x and mx <= btnCrt.x + btnCrt.w and my >= btnCrt.y and my <= btnCrt.y + btnCrt.h, juice.buttonPressedId == btnCrt.id)

    -- Close Button
    local btnClose = { id = "close_settings", text = "LƯU & ĐÓNG", x = modalX + (modalW - 180) / 2, y = modalY + modalH - 52, w = 180, h = 40, color = UI.COLORS.btnPlay, font = UI.fonts.regular }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h, juice.buttonPressedId == btnClose.id)
end

local function drawShopState()
    local winW, winH = love.graphics.getDimensions()
    -- Casino felt green table
    love.graphics.setColor(0.06, 0.16, 0.12, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)
    love.graphics.setColor(0, 0, 0, 0.25)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    local interestBonus = math.min(game.maxInterest or 5, math.floor((game.gold or 0) / 5))
    local hoveredShopItem = nil
    local hoveredItemPos = nil
    hoveredDeityTooltip = nil

    ----------------------------------------------------------------------------
    -- 1. LEFT SIDEBAR HUD (Marquee Sign, Score, Chips/Mult, Round, Gold, Options)
    ----------------------------------------------------------------------------
    local hx, hy, hw, hh = 20, 16, 255, 688
    love.graphics.setColor(0.10, 0.12, 0.14, 0.95)
    UI.drawRoundedRect("fill", hx, hy, hw, hh, 8)
    love.graphics.setColor(0.35, 0.18, 0.18, 0.8)
    love.graphics.setLineWidth(1.5)
    UI.drawRoundedRect("line", hx, hy, hw, hh, 8)

    -- A. MARQUEE "SHOP" SIGN WITH GLOWING BULBS
    local mqX, mqY, mqW, mqH = hx + 10, hy + 10, hw - 20, 108
    love.graphics.setColor(0.18, 0.08, 0.08, 1)
    UI.drawRoundedRect("fill", mqX, mqY, mqW, mqH, 8)
    love.graphics.setColor(0.85, 0.22, 0.22, 1)
    love.graphics.setLineWidth(2.5)
    UI.drawRoundedRect("line", mqX, mqY, mqW, mqH, 8)

    -- Marquee incandescent bulb lights
    local bulbStep = math.floor((juice.ambientTimer or 0) * 4)
    for i = 0, 10 do
        local bx = mqX + 12 + i * ((mqW - 24) / 10)
        local isLitTop = ((bulbStep + i) % 2 == 0)
        if isLitTop then
            love.graphics.setColor(1, 0.92, 0.45, 1)
            love.graphics.circle("fill", bx, mqY + 5, 4.5)
            love.graphics.setColor(1, 1, 0.85, 1)
            love.graphics.circle("fill", bx, mqY + 5, 2)
        else
            love.graphics.setColor(0.42, 0.15, 0.10, 0.7)
            love.graphics.circle("fill", bx, mqY + 5, 3.5)
        end

        local isLitBot = ((bulbStep + i + 1) % 2 == 0)
        if isLitBot then
            love.graphics.setColor(1, 0.92, 0.45, 1)
            love.graphics.circle("fill", bx, mqY + mqH - 5, 4.5)
            love.graphics.setColor(1, 1, 0.85, 1)
            love.graphics.circle("fill", bx, mqY + mqH - 5, 2)
        else
            love.graphics.setColor(0.42, 0.15, 0.10, 0.7)
            love.graphics.circle("fill", bx, mqY + mqH - 5, 3.5)
        end
    end
    for j = 1, 3 do
        local by = mqY + 5 + j * ((mqH - 10) / 4)
        local isLitL = ((bulbStep + j) % 2 == 0)
        love.graphics.setColor(isLitL and { 1, 0.92, 0.45, 1 } or { 0.42, 0.15, 0.10, 0.7 })
        love.graphics.circle("fill", mqX + 5, by, isLitL and 4.5 or 3.5)
        local isLitR = ((bulbStep + j + 1) % 2 == 0)
        love.graphics.setColor(isLitR and { 1, 0.92, 0.45, 1 } or { 0.42, 0.15, 0.10, 0.7 })
        love.graphics.circle("fill", mqX + mqW - 5, by, isLitR and 4.5 or 3.5)
    end

    -- Bold 3D "SHOP" Text
    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(0.35, 0.12, 0.12, 0.9)
    love.graphics.printf("SHOP", mqX + 2, mqY + 16, mqW, "center")
    love.graphics.setColor(1, 0.88, 0.38, 1)
    love.graphics.printf("SHOP", mqX, mqY + 14, mqW, "center")

    -- Subtitle
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(1, 0.82, 0.45, 1)
    love.graphics.printf("Cải thiện trận của bạn!", mqX, mqY + 76, mqW, "center")

    -- B. "Điểm Ván" Box
    local scBoxY = hy + 128
    love.graphics.setColor(0.08, 0.10, 0.13, 0.9)
    UI.drawRoundedRect("fill", hx + 10, scBoxY, hw - 20, 52, 6)
    love.graphics.setColor(0.20, 0.24, 0.30, 0.6)
    UI.drawRoundedRect("line", hx + 10, scBoxY, hw - 20, 52, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("Điểm Ván", hx + 18, scBoxY + 6)
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("0", hx + 18, scBoxY + 24)

    -- C. Chips x Mult Box
    local cmY = hy + 188
    local cmHalfW = (hw - 32) / 2
    love.graphics.setColor(0.12, 0.42, 0.78, 0.95)
    UI.drawRoundedRect("fill", hx + 10, cmY, cmHalfW, 46, 6)
    love.graphics.setColor(0.35, 0.65, 0.95, 1)
    UI.drawRoundedRect("line", hx + 10, cmY, cmHalfW, 46, 6)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("0", hx + 10, cmY + 8, cmHalfW, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print("X", hx + 10 + cmHalfW + 3, cmY + 12)

    love.graphics.setColor(0.85, 0.25, 0.22, 0.95)
    UI.drawRoundedRect("fill", hx + hw - 10 - cmHalfW, cmY, cmHalfW, 46, 6)
    love.graphics.setColor(0.95, 0.45, 0.42, 1)
    UI.drawRoundedRect("line", hx + hw - 10 - cmHalfW, cmY, cmHalfW, 46, 6)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("0", hx + hw - 10 - cmHalfW, cmY + 8, cmHalfW, "center")

    -- D. Round Details: T.tin Trận Này, Tay Bài, Lượt Bỏ
    local rdY = hy + 244
    local btnInfo = {
        id = "shop_round_info",
        text = "T.tin\nTrận Này",
        x = hx + 10,
        y = rdY,
        w = 100,
        h = 52,
        color = { 0.88, 0.30, 0.26, 1 },
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnInfo)
    UI.drawButton(btnInfo, mx >= btnInfo.x and mx <= btnInfo.x + btnInfo.w and my >= btnInfo.y and my <= btnInfo.y + btnInfo.h, juice.buttonPressedId == btnInfo.id)

    -- Tay Bài Pill
    local statBoxW = 58
    local statX1 = hx + 116
    love.graphics.setColor(0.12, 0.24, 0.38, 0.9)
    UI.drawRoundedRect("fill", statX1, rdY, statBoxW, 52, 6)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    UI.drawRoundedRect("line", statX1, rdY, statBoxW, 52, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Tay Bài", statX1, rdY + 4, statBoxW, "center")
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.handsRemaining or 4), statX1, rdY + 22, statBoxW, "center")

    -- Lượt Bỏ Pill
    local statX2 = statX1 + statBoxW + 6
    love.graphics.setColor(0.38, 0.16, 0.18, 0.9)
    UI.drawRoundedRect("fill", statX2, rdY, statBoxW, 52, 6)
    love.graphics.setColor(UI.COLORS.multRed)
    UI.drawRoundedRect("line", statX2, rdY, statBoxW, 52, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Lượt Bỏ", statX2, rdY + 4, statBoxW, "center")
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(game.discardsRemaining or 3), statX2, rdY + 22, statBoxW, "center")

    -- E. Tiền Vàng Box (Huge Gold Pill)
    local goldY = hy + 304
    love.graphics.setColor(0.24, 0.18, 0.06, 0.95)
    UI.drawRoundedRect("fill", hx + 10, goldY, hw - 20, 60, 6)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", hx + 10, goldY, hw - 20, 60, 6)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("$" .. (game.gold or 0), hx + 10, goldY + 8, hw - 20, "center")
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor({ 0.85, 0.75, 0.40, 1 })
    love.graphics.printf("(Lãi: +$" .. interestBonus .. "/trận)", hx + 10, goldY + 38, hw - 20, "center")

    -- F. Tuỳ Chọn Button & Ante Box
    local optY = hy + 372
    local btnOptions = {
        id = "shop_options",
        text = "Tuỳ Chọn",
        x = hx + 10,
        y = optY,
        w = 100,
        h = 46,
        color = { 0.92, 0.58, 0.18, 1 },
        font = UI.fonts.small,
    }
    table.insert(buttons, btnOptions)
    UI.drawButton(btnOptions, mx >= btnOptions.x and mx <= btnOptions.x + btnOptions.w and my >= btnOptions.y and my <= btnOptions.y + btnOptions.h, juice.buttonPressedId == btnOptions.id)

    -- Ante Box
    local anteW = hw - 20 - 108
    local anteX = hx + 118
    love.graphics.setColor(0.12, 0.15, 0.18, 0.9)
    UI.drawRoundedRect("fill", anteX, optY, anteW, 46, 6)
    love.graphics.setColor(0.28, 0.34, 0.42, 0.6)
    UI.drawRoundedRect("line", anteX, optY, anteW, 46, 6)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("Ante " .. (game.act or 1) .. "/8", anteX, optY + 6, anteW, "center")
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Ván " .. (game.round or 1), anteX, optY + 24, anteW, "center")

    -- G. Hoán Đổi Trang Bị Button & Player HP Pill
    local trY = hy + 428
    local btnTransfer = {
        id = "open_shop_transfer",
        text = "Hoán Đổi Trang Bị [T]",
        x = hx + 10,
        y = trY,
        w = hw - 20,
        h = 36,
        color = UI.COLORS.btnSpecial,
        font = UI.fonts.tiny,
    }
    table.insert(buttons, btnTransfer)
    UI.drawButton(btnTransfer, mx >= btnTransfer.x and mx <= btnTransfer.x + btnTransfer.w and my >= btnTransfer.y and my <= btnTransfer.y + btnTransfer.h, juice.buttonPressedId == btnTransfer.id)

    local hpY = hy + 472
    love.graphics.setColor(0.10, 0.25, 0.15, 0.9)
    UI.drawRoundedRect("fill", hx + 10, hpY, hw - 20, 36, 6)
    love.graphics.setColor(UI.COLORS.hpGreen)
    UI.drawRoundedRect("line", hx + 10, hpY, hw - 20, 36, 6)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.hpGreen)
    love.graphics.printf("SINH LỰC: " .. (game.playerHp or 100) .. "/" .. (game.maxPlayerHp or 100) .. " HP", hx + 10, hpY + 9, hw - 20, "center")

    ----------------------------------------------------------------------------
    -- 2. TOP SLOTS: HỘ LINH & TIÊU HAO (0/2)
    ----------------------------------------------------------------------------
    local deiCount = Deities.getCount(game.deities)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    local deiSlotW = 82
    local deiSlotH = 118
    local deiGap = 14
    local deiStartX = 295
    local deiSlotY = 32

    local deiBoxW = maxDeiSlots * (deiSlotW + deiGap) + 2
    love.graphics.setColor(0.08, 0.10, 0.13, 0.6)
    UI.drawRoundedRect("fill", deiStartX - 8, 14, deiBoxW, 140, 8)
    love.graphics.setColor(0.20, 0.26, 0.32, 0.4)
    UI.drawRoundedRect("line", deiStartX - 8, 14, deiBoxW, 140, 8)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("HỘ LINH (" .. deiCount .. "/" .. maxDeiSlots .. ")", deiStartX + 4, 14)

    for i = 1, maxDeiSlots do
        local sx = deiStartX + (i - 1) * (deiSlotW + deiGap)
        local sy = deiSlotY
        local d = game.deities and game.deities[i]
        local isDeiDragged = (deityDrag.active and deityDrag.isDragging and deityDrag.deityIndex == i)
        local isDeiHovered = (mx >= sx and mx <= sx + deiSlotW and my >= sy and my <= sy + deiSlotH)
        local isDropTarget = (deityDrag.active and deityDrag.isDragging and isDeiHovered and deityDrag.deityIndex ~= i)

        if isDeiDragged then
            love.graphics.setColor(0.10, 0.12, 0.15, 0.45)
            UI.drawRoundedRect("fill", sx, sy, deiSlotW, deiSlotH, 6)
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(0.35, 0.40, 0.48, 0.5)
            UI.drawRoundedRect("line", sx, sy, deiSlotW, deiSlotH, 6)
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf("Vị trí cũ", sx + 4, sy + deiSlotH / 2 - 6, deiSlotW - 8, "center")
        elseif d then
            if isDeiHovered and not (deityDrag.active and deityDrag.isDragging) then
                hoveredDeityTooltip = d
                d.slotIndex = i
            end

            local copyTarget = d.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, i)
            UI.drawPatronCard(d, sx, sy, deiSlotW, deiSlotH, isDeiHovered, juice.buttonPressedId == ("deity_" .. i), isDropTarget, copyTarget)

            if not isDropTarget then
                local sellPrice = math.max(1, math.floor((d.cost or 4) / 2))
                local btnSell = {
                    id = "sell_" .. i,
                    text = "Bán +$" .. sellPrice,
                    x = sx + 6,
                    y = sy + deiSlotH - 22,
                    w = deiSlotW - 12,
                    h = 18,
                    color = UI.COLORS.btnDiscard,
                    font = UI.fonts.tiny,
                    deityIndex = i,
                }
                table.insert(buttons, btnSell)
                UI.drawButton(btnSell, mx >= btnSell.x and mx <= btnSell.x + btnSell.w and my >= btnSell.y and my <= btnSell.y + btnSell.h, juice.buttonPressedId == btnSell.id)
            end

            -- Drag button covering the card body
            local btnDei = {
                id = "deity_" .. i,
                text = "",
                x = sx,
                y = sy,
                w = deiSlotW,
                h = deiSlotH - 24,
                invisible = true,
                deityIndex = i,
            }
            table.insert(buttons, btnDei)
        else
            love.graphics.setColor(0.09, 0.11, 0.13, isDropTarget and 0.85 or 0.6)
            UI.drawRoundedRect("fill", sx, sy, deiSlotW, deiSlotH, 6)
            love.graphics.setLineWidth(isDropTarget and 2.5 or 1)
            love.graphics.setColor(isDropTarget and UI.COLORS.hpGreen or { 0.25, 0.28, 0.35, 0.5 })
            UI.drawRoundedRect("line", sx, sy, deiSlotW, deiSlotH, 6)
            if isDropTarget then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.hpGreen)
                love.graphics.printf("THẢ VÀO\nĐÂY", sx + 4, sy + deiSlotH / 2 - 14, deiSlotW - 8, "center")
            else
                love.graphics.setFont(UI.fonts.large)
                love.graphics.setColor(0.28, 0.32, 0.38, 0.5)
                love.graphics.printf("+", sx, sy + deiSlotH / 2 - 18, deiSlotW, "center")
            end
        end
    end

    -- Consumables (0/2)
    local conStartX = deiStartX + maxDeiSlots * (deiSlotW + deiGap) + 16
    local conSlotW = 82
    local conSlotH = 118
    local conGap = 14
    love.graphics.setColor(0.08, 0.10, 0.13, 0.6)
    UI.drawRoundedRect("fill", conStartX - 8, 14, 196, 140, 8)
    love.graphics.setColor(0.20, 0.26, 0.32, 0.4)
    UI.drawRoundedRect("line", conStartX - 8, 14, 196, 140, 8)

    game.consumables = game.consumables or {}
    local conCount = #game.consumables
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor({ 0.45, 0.85, 0.65, 1 })
    love.graphics.print("TIÊU HAO (" .. conCount .. "/2)", conStartX + 4, 14)

    for i = 1, 2 do
        local cx = conStartX + (i - 1) * (conSlotW + conGap)
        local cy = deiSlotY
        local c = game.consumables[i]
        drawConsumableSlot(c, cx, cy, conSlotW, conSlotH, i, mx, my)
    end

    -- Top Right [MENU] button
    local btnMenu = { id = "open_pause_menu", text = "MENU", x = V_WIDTH - 86, y = 14, w = 72, h = 30, color = { 0.20, 0.28, 0.36, 1 }, font = UI.fonts.tiny }
    table.insert(buttons, btnMenu)
    UI.drawButton(btnMenu, mx >= btnMenu.x and mx <= btnMenu.x + btnMenu.w and my >= btnMenu.y and my <= btnMenu.y + btnMenu.h, juice.buttonPressedId == btnMenu.id)

    ----------------------------------------------------------------------------
    -- 3. MAIN SHOP BOARD (Upper: Cards On Sale | Lower: Voucher & Packs)
    ----------------------------------------------------------------------------
    local shopX, shopY, shopW, shopH = 295, 156, 785, 548
    love.graphics.setColor(0.10, 0.12, 0.15, 0.96)
    UI.drawRoundedRect("fill", shopX, shopY, shopW, shopH, 12)
    love.graphics.setColor(0.85, 0.28, 0.24, 0.85)
    love.graphics.setLineWidth(2.5)
    UI.drawRoundedRect("line", shopX, shopY, shopW, shopH, 12)

    ----------------------------------------------------------------------------
    -- A. UPPER COMPARTMENT (Next Round & Reroll + Upper Cards On Sale)
    ----------------------------------------------------------------------------
    local upX, upY, upW, upH = shopX + 12, shopY + 12, shopW - 24, 252
    love.graphics.setColor(0.13, 0.16, 0.20, 0.95)
    UI.drawRoundedRect("fill", upX, upY, upW, upH, 10)
    love.graphics.setColor(0.24, 0.30, 0.38, 0.7)
    UI.drawRoundedRect("line", upX, upY, upW, upH, 10)

    -- 1. [Ván Kế Tiếp] Button
    local btnNextRound = {
        id = "leave_shop",
        text = "Ván\nKế Tiếp",
        x = upX + 12,
        y = upY + 12,
        w = 136,
        h = 104,
        color = UI.COLORS.btnDestruct,
        font = UI.fonts.medium,
    }
    table.insert(buttons, btnNextRound)
    UI.drawButton(btnNextRound, mx >= btnNextRound.x and mx <= btnNextRound.x + btnNextRound.w and my >= btnNextRound.y and my <= btnNextRound.y + btnNextRound.h, juice.buttonPressedId == btnNextRound.id)

    -- 2. [Gieo Lại] Button
    local rCost = shopData.rerollCost or 5
    local canReroll = (game.gold or 0) >= rCost
    local btnReroll = {
        id = "reroll",
        text = "Gieo lại",
        sub = "$" .. rCost,
        isMultiLine = true,
        x = upX + 12,
        y = upY + 124,
        w = 136,
        h = 114,
        color = canReroll and UI.COLORS.btnSpecial or UI.COLORS.btnNormal,
        font = UI.fonts.medium,
        disabled = not canReroll,
    }
    table.insert(buttons, btnReroll)
    UI.drawButton(btnReroll, mx >= btnReroll.x and mx <= btnReroll.x + btnReroll.w and my >= btnReroll.y and my <= btnReroll.y + btnReroll.h, juice.buttonPressedId == btnReroll.id)

    -- 3. Upper Cards On Sale
    local upperItems = {}
    for idx, it in ipairs(shopData.items or {}) do
        if it.section == "upper" or (not it.section and idx <= 3) then
            table.insert(upperItems, { item = it, globalIndex = idx })
        end
    end

    local cardStartX = upX + 170
    local cardW = 124
    local cardH = 186
    local cardGap = 26

    for cIdx, entry in ipairs(upperItems) do
        local it = entry.item
        local gIdx = entry.globalIndex
        local cx = cardStartX + (cIdx - 1) * (cardW + cardGap)
        local cy = upY + 36

        local isCardHovered = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH)
        local drawY = isCardHovered and (cy - 12) or cy
        local isDragged = (shopDrag.active and shopDrag.isDragging and shopDrag.itemIndex == gIdx)

        if isDragged then
            love.graphics.setColor(0.24, 0.30, 0.38, 0.45)
            UI.drawRoundedRect("line", cx, cy, cardW, cardH, 8)
        else
            local tX, tY = 0, 0
            if isCardHovered then
                tX, tY = UI.calculateTilt(mx, my, cx, drawY, cardW, cardH)
            end

            love.graphics.push()
            love.graphics.translate(cx + cardW / 2, drawY + cardH / 2)
            if isCardHovered then
                love.graphics.shear(tX * 0.10, tY * 0.10)
            end
            love.graphics.translate(-cardW / 2, -cardH / 2)

            -- Floating Price Tag Pill above card
            local priceTagW = 54
            local priceTagH = 22
            local priceTagX = (cardW - priceTagW) / 2
            local priceTagY = -26
            love.graphics.setColor(0.18, 0.14, 0.06, 0.98)
            UI.drawRoundedRect("fill", priceTagX, priceTagY, priceTagW, priceTagH, 4)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", priceTagX, priceTagY, priceTagW, priceTagH, 4)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("$" .. it.cost, priceTagX, priceTagY + 2, priceTagW, "center")

            -- Card Soft Drop Shadow
            if isCardHovered then
                love.graphics.setColor(0, 0, 0, 0.4)
                UI.drawRoundedRect("fill", -4 + tX * 8, 8 + tY * 8, cardW + 8, cardH, 8)
            end

            local dImg = (it.category == "deity" and it.deity) and UI.getDeityImage(it.deity.id)
            if dImg then
                love.graphics.setColor(1, 1, 1, 1)
                local iw, ih = dImg:getDimensions()
                love.graphics.draw(dImg, 0, 0, 0, cardW / iw, cardH / ih)
                if isCardHovered then
                    love.graphics.setLineWidth(2.5)
                    love.graphics.setColor(UI.COLORS.goldYellow)
                    UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)
                end
            else
                -- Card Body
                local cardColor = it.color or { 0.95, 0.85, 0.35, 1 }
                love.graphics.setColor(0.18, 0.22, 0.28, 0.98)
                UI.drawRoundedRect("fill", 0, 0, cardW, cardH, 8)
                love.graphics.setColor(isCardHovered and UI.COLORS.goldYellow or { cardColor[1] * 0.7, cardColor[2] * 0.7, cardColor[3] * 0.7, 0.8 })
                love.graphics.setLineWidth(isCardHovered and 2.5 or 1.5)
                UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)

                -- Top subtitle banner
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(cardColor)
                love.graphics.printf(it.subtitle or "THẺ BÀI", 4, 8, cardW - 8, "center")

                -- Card Icon / Art
                love.graphics.setFont(UI.fonts.large)
                love.graphics.printf(it.icon or "🃏", 0, 40, cardW, "center")

                -- Card Title
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(it.name or "Vật Phẩm", 4, 85, cardW - 8, "center")

                -- Bottom effect bar
                love.graphics.setColor(0.12, 0.15, 0.19, 0.9)
                UI.drawRoundedRect("fill", 6, cardH - 46, cardW - 12, 38, 4)
                love.graphics.setFont(UI.fonts.tiny)
                local shortDesc = UI.truncateUtf8(it.desc, 32)
                love.graphics.printf(shortDesc, 8, cardH - 42, cardW - 16, "center")
            end

            love.graphics.pop()

            -- Buy button covering the card
            local btnCard = {
                id = "buy_" .. gIdx,
                text = "",
                x = cx,
                y = drawY - 26,
                w = cardW,
                h = cardH + 26,
                invisible = true,
                itemIndex = gIdx,
            }
            table.insert(buttons, btnCard)

            if isCardHovered and not (shopDrag.active and shopDrag.isDragging) then
                hoveredShopItem = it
                hoveredItemPos = { x = cx + cardW + 12, y = drawY - 10 }
            end
        end
    end

    ----------------------------------------------------------------------------
    -- B. LOWER COMPARTMENT (Voucher Slot on Left | Booster Packs on Right)
    ----------------------------------------------------------------------------
    local lowX, lowY, lowW, lowH = shopX + 12, shopY + 274, shopW - 24, shopH - 286
    love.graphics.setColor(0.13, 0.16, 0.20, 0.95)
    UI.drawRoundedRect("fill", lowX, lowY, lowW, lowH, 10)
    love.graphics.setColor(0.24, 0.30, 0.38, 0.7)
    UI.drawRoundedRect("line", lowX, lowY, lowW, lowH, 10)

    -- 1. Left Slot: PHIẾU ANTE 1 / VOUCHER
    local vSlotX = lowX + 14
    local vSlotY = lowY + 12
    local vSlotW = 220
    local vSlotH = 236

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(0.40, 0.46, 0.54, 0.7)
    local anteLabel = "PHIẾU ANTE " .. (game.act or 1)
    love.graphics.print(anteLabel, vSlotX + 4, vSlotY + 10)

    local voucherEntry = nil
    for idx, it in ipairs(shopData.items or {}) do
        if it.section == "lower_voucher" or it.category == "book" or it.category == "voucher" then
            voucherEntry = { item = it, globalIndex = idx }
            break
        end
    end

    if voucherEntry then
        local it = voucherEntry.item
        local gIdx = voucherEntry.globalIndex
        local vx = vSlotX + 30
        local vy = vSlotY + 22
        local vw = 130
        local vh = 195

        local isVHovered = (mx >= vx and mx <= vx + vw and my >= vy and my <= vy + vh)
        local drawVY = isVHovered and (vy - 10) or vy
        local isVDragged = (shopDrag.active and shopDrag.isDragging and shopDrag.itemIndex == gIdx)

        if isVDragged then
            love.graphics.setColor(0.24, 0.30, 0.38, 0.45)
            UI.drawRoundedRect("line", vx, vy, vw, vh, 8)
        else
            local tX, tY = 0, 0
            if isVHovered then
                tX, tY = UI.calculateTilt(mx, my, vx, drawVY, vw, vh)
            end

            love.graphics.push()
            love.graphics.translate(vx + vw / 2, drawVY + vh / 2)
            if isVHovered then
                love.graphics.shear(tX * 0.10, tY * 0.10)
            end
            love.graphics.translate(-vw / 2, -vh / 2)

            -- Floating Price Tag
            local pw = 52
            local ph = 22
            local px = (vw - pw) / 2
            local py = -24
            love.graphics.setColor(0.18, 0.14, 0.06, 0.98)
            UI.drawRoundedRect("fill", px, py, pw, ph, 4)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", px, py, pw, ph, 4)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("$" .. it.cost, px, py + 2, pw, "center")

            -- Voucher Card Body
            love.graphics.setColor(0.15, 0.28, 0.42, 0.98)
            UI.drawRoundedRect("fill", 0, 0, vw, vh, 8)
            love.graphics.setColor(isVHovered and UI.COLORS.goldYellow or { 0.35, 0.65, 0.95, 0.9 })
            love.graphics.setLineWidth(isVHovered and 2.5 or 1.5)
            UI.drawRoundedRect("line", 0, 0, vw, vh, 8)

            -- Ticket notches
            love.graphics.setColor(0.13, 0.16, 0.20, 1)
            love.graphics.circle("fill", 0, vh / 2, 7)
            love.graphics.circle("fill", vw, vh / 2, 7)

            -- Header
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor({ 0.65, 0.85, 1.0, 1 })
            love.graphics.printf(it.subtitle or "VOUCHER", 4, 10, vw - 8, "center")

            -- Icon
            love.graphics.setFont(UI.fonts.huge)
            love.graphics.printf(it.icon or "📜", 0, 42, vw, "center")

            -- Name
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(it.name or "Bí Tịch", 6, 110, vw - 12, "center")

            love.graphics.pop()

            local btnVoucher = {
                id = "buy_" .. gIdx,
                text = "",
                x = vx,
                y = drawVY - 24,
                w = vw,
                h = vh + 24,
                invisible = true,
                itemIndex = gIdx,
            }
            table.insert(buttons, btnVoucher)

            if isVHovered and not (shopDrag.active and shopDrag.isDragging) then
                hoveredShopItem = it
                hoveredItemPos = { x = vx + vw + 12, y = drawVY - 10 }
            end
        end
    else
        local vx = vSlotX + 30
        local vy = vSlotY + 22
        love.graphics.setColor(0.10, 0.12, 0.15, 0.4)
        UI.drawRoundedRect("fill", vx, vy, 130, 195, 8)
        love.graphics.setColor(0.20, 0.24, 0.30, 0.3)
        UI.drawRoundedRect("line", vx, vy, 130, 195, 8)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.35, 0.40, 0.45, 0.5)
        love.graphics.printf("ĐÃ MUA\nPHIẾU ANTE", vx, vy + 85, 130, "center")
    end

    -- 2. Right Slots: GÓI BÀI (Booster Packs)
    local packItems = {}
    for idx, it in ipairs(shopData.items or {}) do
        if it.section == "lower_pack" or it.category == "pack" or it.category == "heal" then
            table.insert(packItems, { item = it, globalIndex = idx })
        end
    end

    local packStartX = lowX + 270
    local packW = 140
    local packH = 195
    local packGap = 36

    for pIdx, entry in ipairs(packItems) do
        local it = entry.item
        local gIdx = entry.globalIndex
        local px = packStartX + (pIdx - 1) * (packW + packGap)
        local py = lowY + 32

        local isPackHovered = (mx >= px and mx <= px + packW and my >= py and my <= py + packH)
        local drawPY = isPackHovered and (py - 10) or py
        local isPackDragged = (shopDrag.active and shopDrag.isDragging and shopDrag.itemIndex == gIdx)

        if isPackDragged then
            love.graphics.setColor(0.24, 0.30, 0.38, 0.45)
            UI.drawRoundedRect("line", px, py, packW, packH, 8)
        else
            local tX, tY = 0, 0
            if isPackHovered then
                tX, tY = UI.calculateTilt(mx, my, px, drawPY, packW, packH)
            end

            love.graphics.push()
            love.graphics.translate(px + packW / 2, drawPY + packH / 2)
            if isPackHovered then
                love.graphics.shear(tX * 0.10, tY * 0.10)
            end
            love.graphics.translate(-packW / 2, -packH / 2)

            -- Floating Price Tag
            local pw = 52
            local ph = 22
            local tagX = (packW - pw) / 2
            local tagY = -24
            love.graphics.setColor(0.18, 0.14, 0.06, 0.98)
            UI.drawRoundedRect("fill", tagX, tagY, pw, ph, 4)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", tagX, tagY, pw, ph, 4)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("$" .. it.cost, tagX, tagY + 2, pw, "center")

            -- Metallic Foil Pack Body
            local packColor = it.color or { 0.88, 0.35, 0.35, 1 }
            love.graphics.setColor(packColor[1] * 0.4, packColor[2] * 0.4, packColor[3] * 0.4, 0.98)
            UI.drawRoundedRect("fill", 0, 0, packW, packH, 8)
            love.graphics.setColor(isPackHovered and UI.COLORS.goldYellow or packColor)
            love.graphics.setLineWidth(isPackHovered and 2.5 or 1.5)
            UI.drawRoundedRect("line", 0, 0, packW, packH, 8)

            -- Crimped Foil Ridges (Top & Bottom)
            love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
            for ridge = 0, 11 do
                local rx = 6 + ridge * 11
                love.graphics.line(rx, 3, rx + 4, 10)
                love.graphics.line(rx, packH - 10, rx + 4, packH - 3)
            end

            -- Metallic Shimmer Band in center
            love.graphics.setColor(packColor[1], packColor[2], packColor[3], 0.25)
            UI.drawRoundedRect("fill", 8, 36, packW - 16, 120, 6)

            -- Icon
            love.graphics.setFont(UI.fonts.huge)
            love.graphics.printf(it.icon or "📦", 0, 50, packW, "center")

            -- Pack Title
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(it.name or "Gói Bài", 4, 116, packW - 8, "center")

            -- Subtitle
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(packColor)
            love.graphics.printf(it.subtitle or "BOOSTER", 4, 138, packW - 8, "center")

            love.graphics.pop()

            -- Invisible buy button
            local btnPack = {
                id = "buy_" .. gIdx,
                text = "",
                x = px,
                y = drawPY - 24,
                w = packW,
                h = packH + 24,
                invisible = true,
                itemIndex = gIdx,
            }
            table.insert(buttons, btnPack)

            if isPackHovered and not (shopDrag.active and shopDrag.isDragging) then
                hoveredShopItem = it
                hoveredItemPos = { x = px - 260, y = drawPY - 10 }
            end
        end
    end

    ----------------------------------------------------------------------------
    -- 4. BOTTOM RIGHT: 3D DECK PILE (Click to open Deck Viewer [Tab])
    ----------------------------------------------------------------------------
    local deckPileX = shopX + shopW + 18
    local deckPileY = shopY + 416
    local deckPileW = 106
    local deckPileH = 158

    local isDeckHovered = (mx >= deckPileX and mx <= deckPileX + deckPileW and my >= deckPileY and my <= deckPileY + deckPileH)
    local drawDeckY = isDeckHovered and (deckPileY - 6) or deckPileY

    -- 3D Stack Offset Cards
    love.graphics.setColor(0.35, 0.08, 0.08, 0.7)
    UI.drawRoundedRect("fill", deckPileX, drawDeckY + 6, deckPileW, deckPileH, 6)
    love.graphics.setColor(0.55, 0.12, 0.12, 0.8)
    UI.drawRoundedRect("fill", deckPileX, drawDeckY + 3, deckPileW, deckPileH, 6)

    -- Top Card (Balatro Red Card Back Pattern)
    love.graphics.setColor(0.78, 0.18, 0.18, 1)
    UI.drawRoundedRect("fill", deckPileX, drawDeckY, deckPileW, deckPileH, 6)
    love.graphics.setColor(isDeckHovered and UI.COLORS.goldYellow or { 0.95, 0.85, 0.85, 0.9 })
    love.graphics.setLineWidth(isDeckHovered and 2.5 or 1.5)
    UI.drawRoundedRect("line", deckPileX, drawDeckY, deckPileW, deckPileH, 6)

    love.graphics.setColor(0.95, 0.85, 0.85, 0.25)
    love.graphics.rectangle("line", deckPileX + 8, drawDeckY + 8, deckPileW - 16, deckPileH - 16)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.printf("🂠", deckPileX, drawDeckY + 42, deckPileW, "center")

    local deckCountStr = tostring(#(game.deck or {})) .. " / " .. tostring(#(game.persistentDeck or {}))
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(deckCountStr, deckPileX, drawDeckY + deckPileH - 24, deckPileW, "center")

    local btnDeck = {
        id = "open_deck_viewer",
        text = "",
        x = deckPileX,
        y = drawDeckY,
        w = deckPileW,
        h = deckPileH,
        invisible = true,
    }
    table.insert(buttons, btnDeck)

    if isDeckHovered then
        local tipW = 150
        local tipH = 34
        local tipX = deckPileX - 22
        local tipY = drawDeckY - 42
        love.graphics.setColor(0.12, 0.15, 0.18, 0.95)
        UI.drawRoundedRect("fill", tipX, tipY, tipW, tipH, 4)
        love.graphics.setColor(UI.COLORS.goldYellow)
        UI.drawRoundedRect("line", tipX, tipY, tipW, tipH, 4)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Xem Toàn Bộ Bài [Tab]", tipX, tipY + 9, tipW, "center")
    end

    ----------------------------------------------------------------------------
    -- 4b. DRAGGED SHOP ITEM & DEITY ON TOP WITH 3D TILT & DROP ZONE
    ----------------------------------------------------------------------------
    if shopDrag.active and shopDrag.isDragging and shopDrag.item then
        -- Drop purchase zone indicator at the top
        local dropZoneX = shopX + 20
        local dropZoneY = shopY + 12
        local dropZoneW = shopW - 40
        local dropZoneH = 46
        local isOverDropZone = (my < 380 or my < (shopDrag.origY - 40))
        local canAfford = (game.gold or 0) >= (shopDrag.item.cost or 0)

        if isOverDropZone then
            love.graphics.setColor(canAfford and { 0.15, 0.65, 0.35, 0.95 } or { 0.75, 0.18, 0.18, 0.95 })
        else
            love.graphics.setColor(0.12, 0.16, 0.22, 0.85)
        end
        UI.drawRoundedRect("fill", dropZoneX, dropZoneY, dropZoneW, dropZoneH, 8)
        love.graphics.setColor(isOverDropZone and (canAfford and UI.COLORS.btnPlay or UI.COLORS.multRed) or UI.COLORS.goldYellow)
        love.graphics.setLineWidth(2)
        UI.drawRoundedRect("line", dropZoneX, dropZoneY, dropZoneW, dropZoneH, 8)

        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        local dropText
        if not canAfford then
            dropText = "KHÔNG ĐỦ TIỀN - $" .. shopDrag.item.cost
        elseif isOverDropZone then
            dropText = "THẢ TẠI ĐÂY ĐỂ MUA - $" .. shopDrag.item.cost
        else
            dropText = "KÉO LÊN TRÊN ĐỂ MUA - $" .. shopDrag.item.cost
        end
        love.graphics.printf(dropText, dropZoneX, dropZoneY + 10, dropZoneW, "center")

        -- Draw the dragged card floating on top with 3D tilt & elevation
        local dcw = shopDrag.cardW or 124
        local dch = shopDrag.cardH or 186
        local dcx = shopDrag.visualX
        local dcy = shopDrag.visualY
        local dItem = shopDrag.item

        love.graphics.push()
        love.graphics.translate(dcx + dcw / 2, dcy + dch / 2)
        if shopDrag.rotation and shopDrag.rotation ~= 0 then
            love.graphics.rotate(shopDrag.rotation)
        end
        if shopDrag.tiltX or shopDrag.tiltY then
            love.graphics.shear((shopDrag.tiltX or 0) * 0.12, (shopDrag.tiltY or 0) * 0.12)
        end
        love.graphics.scale(1.15, 1.15)
        love.graphics.translate(-dcw / 2, -dch / 2)

        -- Elevation drop shadow
        love.graphics.setColor(0, 0, 0, 0.5)
        UI.drawRoundedRect("fill", 10 + (shopDrag.tiltX or 0) * 12, 16 + (shopDrag.tiltY or 0) * 12, dcw, dch, 10)

        -- Card Body
        local dColor = dItem.color or { 0.95, 0.85, 0.35, 1 }
        love.graphics.setColor(0.18, 0.22, 0.28, 1)
        UI.drawRoundedRect("fill", 0, 0, dcw, dch, 8)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.setLineWidth(2.5)
        UI.drawRoundedRect("line", 0, 0, dcw, dch, 8)

        -- Subtitle banner
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(dColor)
        love.graphics.printf(dItem.subtitle or "THẺ BÀI", 4, 8, dcw - 8, "center")

        -- Icon
        love.graphics.setFont(UI.fonts.large)
        love.graphics.printf(dItem.icon or "🃏", 0, 40, dcw, "center")

        -- Name
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(dItem.name or "Vật Phẩm", 4, 85, dcw - 8, "center")

        -- Price badge
        love.graphics.setColor(0.12, 0.15, 0.19, 0.9)
        UI.drawRoundedRect("fill", 6, dch - 40, dcw - 12, 32, 4)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("$" .. dItem.cost, 6, dch - 34, dcw - 12, "center")

        love.graphics.pop()
    end



    ----------------------------------------------------------------------------
    -- 5. BALATRO TOOLTIP BADGE (Floating Info for Hovered Card)
    ----------------------------------------------------------------------------
    if hoveredShopItem and hoveredItemPos then
        local it = hoveredShopItem
        local tipW = 250
        local tipH = 135
        local tipX = math.max(280, math.min(V_WIDTH - tipW - 20, hoveredItemPos.x))
        local tipY = math.max(20, math.min(V_HEIGHT - tipH - 20, hoveredItemPos.y))

        love.graphics.setColor(0, 0, 0, 0.6)
        UI.drawRoundedRect("fill", tipX + 4, tipY + 4, tipW, tipH, 8)
        love.graphics.setColor(0.11, 0.14, 0.18, 0.98)
        UI.drawRoundedRect("fill", tipX, tipY, tipW, tipH, 8)
        love.graphics.setColor(it.color or UI.COLORS.goldYellow)
        love.graphics.setLineWidth(2)
        UI.drawRoundedRect("line", tipX, tipY, tipW, tipH, 8)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(it.color or UI.COLORS.goldYellow)
        love.graphics.print(it.name or "Vật Phẩm", tipX + 14, tipY + 12)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.print(it.subtitle or "CHI TIẾT", tipX + 14, tipY + 34)

        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(it.desc or "", tipX + 14, tipY + 54, tipW - 28, "left")

        love.graphics.setColor(UI.COLORS.goldYellow)
        local pStr = it.isSell and ("Giá Bán Lại: +$" .. it.cost) or ("Giá Mua: $" .. it.cost)
        love.graphics.printf(pStr, tipX + 14, tipY + tipH - 24, tipW - 28, "right")
    end

    ----------------------------------------------------------------------------
    -- 6. PACK OPENING MODAL OVERLAY (When a Booster Pack is active)
    ----------------------------------------------------------------------------
    if shopData.currentPackOpening then
        local pData = shopData.currentPackOpening
        local pack = pData.pack
        local cards = pData.cards or {}

        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("MỞ " .. (pack.name or "GÓI BÀI") .. " — CHỌN 1 THẺ BÀI", 0, 120, V_WIDTH, "center")

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Nhấp vào 1 thẻ bài bạn muốn nhận để đưa vào hành trang của bạn:", 0, 168, V_WIDTH, "center")

        local totalCardsW = #cards * 150 + (#cards - 1) * 32
        local startCardX = (V_WIDTH - totalCardsW) / 2
        local cardY = 210
        local cW = 150
        local cH = 260

        for i, card in ipairs(cards) do
            local cx = startCardX + (i - 1) * (cW + 32)
            local isChoiceHovered = (mx >= cx and mx <= cx + cW and my >= cardY and my <= cardY + cH)
            local drawCY = isChoiceHovered and (cardY - 14) or cardY

            love.graphics.setColor(0.16, 0.20, 0.26, 0.98)
            UI.drawRoundedRect("fill", cx, drawCY, cW, cH, 10)
            love.graphics.setColor(isChoiceHovered and UI.COLORS.goldYellow or { 0.45, 0.55, 0.70, 0.8 })
            love.graphics.setLineWidth(isChoiceHovered and 3 or 1.5)
            UI.drawRoundedRect("line", cx, drawCY, cW, cH, 10)

            if pack.packType == "buffoon" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor({ 0.85, 0.65, 0.95, 1 })
                love.graphics.printf("HỘ LINH", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf("👑", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")

            elseif pack.packType == "standard" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(card.color or UI.COLORS.goldYellow)
                love.graphics.printf(card.roleTitle or "QUÂN BÀI", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.suitSymbol or "♠", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.medium)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.rankName .. " " .. card.suitSymbol, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf("+" .. (card.baseChips or 10) .. " Chips\nChất " .. (card.suitSymbol or "?"), cx + 8, drawCY + 140, cW - 16, "center")

            elseif pack.packType == "arcana" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(card.color or UI.COLORS.goldYellow)
                love.graphics.printf("TRANG BỊ KHẢM", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.icon or "💎", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")

            elseif pack.packType == "joker_edition" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor({ 0.95, 0.45, 0.85, 1 })
                love.graphics.printf("PHÙ PHÉP HỘ LINH", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.icon or "✨", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")

            elseif pack.packType == "seal" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(card.color or { 0.85, 0.75, 0.35, 1 })
                love.graphics.printf(card.subtitle or "CON DẤU", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.icon or "🔴", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")

            elseif pack.packType == "spectral" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor({ 0.45, 0.85, 0.85, 1 })
                love.graphics.printf("QUANG PHỔ", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.icon or "👻", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")

            elseif pack.packType == "celestial" then
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(card.color or { 0.35, 0.75, 0.95, 1 })
                love.graphics.printf(card.subtitle or "HÀNH TINH", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.icon or "🪐", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name, cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")

            else
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(card.color or UI.COLORS.goldYellow)
                love.graphics.printf(card.subtitle or "THẺ BÀI", cx + 4, drawCY + 10, cW - 8, "center")
                love.graphics.setFont(UI.fonts.huge)
                love.graphics.printf(card.icon or "🃏", cx, drawCY + 36, cW, "center")
                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name or "Thẻ", cx + 6, drawCY + 105, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(card.desc or "", cx + 8, drawCY + 132, cW - 16, "center")
            end

            local isConsumablePack = (pack.packType == "joker_edition" or pack.packType == "seal" or pack.packType == "spectral" or pack.packType == "celestial")
            if isConsumablePack then
                local btnUse = {
                    id = "choose_pack_" .. i,
                    text = "DÙNG NGAY",
                    x = cx + 8,
                    y = drawCY + cH - 56,
                    w = cW - 16,
                    h = 24,
                    color = UI.COLORS.btnPlay,
                    font = UI.fonts.tiny,
                    cardIndex = i,
                }
                table.insert(buttons, btnUse)
                UI.drawButton(btnUse, mx >= btnUse.x and mx <= btnUse.x + btnUse.w and my >= btnUse.y and my <= btnUse.y + btnUse.h, juice and juice.buttonPressedId == btnUse.id)

                local btnKeep = {
                    id = "keep_pack_" .. i,
                    text = "GIỮ LẠI",
                    x = cx + 8,
                    y = drawCY + cH - 28,
                    w = cW - 16,
                    h = 24,
                    color = { 0.20, 0.48, 0.75, 1 },
                    font = UI.fonts.tiny,
                    cardIndex = i,
                }
                table.insert(buttons, btnKeep)
                UI.drawButton(btnKeep, mx >= btnKeep.x and mx <= btnKeep.x + btnKeep.w and my >= btnKeep.y and my <= btnKeep.y + btnKeep.h, juice and juice.buttonPressedId == btnKeep.id)
            else
                local btnPick = {
                    id = "choose_pack_" .. i,
                    text = "CHỌN LÁ NÀY",
                    x = cx + 12,
                    y = drawCY + cH - 36,
                    w = cW - 24,
                    h = 28,
                    color = UI.COLORS.btnPlay,
                    font = UI.fonts.tiny,
                    cardIndex = i,
                }
                table.insert(buttons, btnPick)
                UI.drawButton(btnPick, mx >= btnPick.x and mx <= btnPick.x + btnPick.w and my >= btnPick.y and my <= btnPick.y + btnPick.h, juice and juice.buttonPressedId == btnPick.id)
            end
        end

        local btnSkip = {
            id = "skip_pack",
            text = "BỎ QUA GÓI BÀI",
            x = (V_WIDTH - 200) / 2,
            y = cardY + cH + 20,
            w = 200,
            h = 38,
            color = UI.COLORS.btnDiscard,
            font = UI.fonts.small,
        }
        table.insert(buttons, btnSkip)
        UI.drawButton(btnSkip, mx >= btnSkip.x and mx <= btnSkip.x + btnSkip.w and my >= btnSkip.y and my <= btnSkip.y + btnSkip.h, juice.buttonPressedId == btnSkip.id)
    end

    if isShopTransferOpen then
        drawShopTransferView()
    end

    if hoveredDeityTooltip then
        local copyTarget = hoveredDeityTooltip.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, hoveredDeityTooltip.slotIndex or 1)
        UI.drawPatronTooltip(hoveredDeityTooltip, mx, my, copyTarget)
    end
end

local function drawGameOverState()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.08, 0.05, 0.05, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())

    love.graphics.setFont(UI.fonts.huge)
    love.graphics.setColor(UI.COLORS.multRed)
    love.graphics.printf("BẠN ĐÃ BỊ ĐÁNH BẠI!", 0, 160, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Dừng bước tại Round " .. game.round .. " trước " .. (game.monster and game.monster.name or "Quái Vật"), 0, 240, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Máu quái còn lại: " .. (game.monster and game.monster.hp or 0) .. " HP", 0, 290, V_WIDTH, "center")

    buttons = {}
    local btnRetry = {
        id = "retry",
        text = "CHƠI LẠI TỪ ĐẦU",
        x = (V_WIDTH - 260) / 2,
        y = 380,
        w = 260,
        h = 60,
        color = UI.COLORS.btnPlay,
        font = UI.fonts.medium,
    }
    table.insert(buttons, btnRetry)
    UI.drawButton(btnRetry, mx >= btnRetry.x and mx <= btnRetry.x + btnRetry.w and my >= btnRetry.y and my <= btnRetry.y + btnRetry.h)
end

function love.draw()
    if love.mouse and love.mouse.getPosition then
        local rawMx, rawMy = love.mouse.getPosition()
        UI.virtualMouseX, UI.virtualMouseY = toVirtual(rawMx, rawMy)
    end
    UI.currentPressedBtnId = juice and juice.buttonPressedId

    -- 1. If Canvas is enabled, render the game into mainCanvas
    if mainCanvas then
        love.graphics.setCanvas({ mainCanvas, stencil = true })
        love.graphics.clear(0, 0, 0, 1)
    else
        love.graphics.push()
        love.graphics.translate(offsetX, offsetY)
        love.graphics.scale(scale, scale)
    end

    -- Psychedelic dynamic domain-warping background shader
    if bgShader then
        love.graphics.setShader(bgShader)
        if bgShader:hasUniform("u_time") then bgShader:send("u_time", juice.ambientTimer or 0) end
        if bgShader:hasUniform("u_resolution") then bgShader:send("u_resolution", { V_WIDTH, V_HEIGHT }) end
        if bgShader:hasUniform("u_color_a") then bgShader:send("u_color_a", bgCurrentColors.a) end
        if bgShader:hasUniform("u_color_b") then bgShader:send("u_color_b", bgCurrentColors.b) end
        if bgShader:hasUniform("u_color_c") then bgShader:send("u_color_c", bgCurrentColors.c) end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
        love.graphics.setShader()
    end

    love.graphics.push()
    if screenShake > 0 then
        local sx = (love.math.random() * 2 - 1) * screenShake
        local sy = (love.math.random() * 2 - 1) * screenShake
        love.graphics.translate(sx, sy)
    end

    if state == "menu" then
        drawMenu()
    elseif state == "BLIND_SELECT" then
        drawBlindSelectState()
    elseif state == "map" then
        drawMap()
    elseif state == "playing" then
        drawPlayingState()
    elseif state == "scoring" then
        drawScoringState()
    elseif state == "CASH_OUT" then
        local mx, my = toVirtual(love.mouse.getPosition())
        buttons = {}
        RewardSystem.draw(cashOutAnim, V_WIDTH, V_HEIGHT, mx, my, buttons)
    elseif state == "event" then
        drawEventState()
    elseif state == "boss_deity" then
        drawBossDeityDraftState()
    elseif state == "chest" then
        drawChestState()
    elseif state == "socketing" then
        drawSocketingView()
    elseif state == "shop" then
        drawShopState()
    elseif state == "rest" then
        drawRestState()
    elseif state == "treasure" then
        drawTreasureState()
    elseif state == "gameover" then
        drawGameOverState()
    elseif state == "victory" then
        drawVictoryState()
    end

    if isDeckViewerOpen then
        drawDeckViewerModal()
    end

    if isHandbookOpen then
        drawHandbookModal()
    end

    if inspectCardModal then
        drawCardInspectorModal(inspectCardModal)
    end

    if isSettingsOpen then
        drawSettingsModal()
    end

    if isPauseMenuOpen then
        drawPauseMenuModal()
    end

    if isCollectionOpen then
        if collectionCategory then
            drawCollectionDetailView()
        else
            drawCollectionModal()
        end
    end

    -- In-game sleek Pause / Menu button at top right
    if state ~= "menu" and not isPauseMenuOpen and not isSettingsOpen and not isDeckViewerOpen and not isHandbookOpen and not inspectCardModal and not isCollectionOpen then
        local mx, my = toVirtual(love.mouse.getPosition())
        local btnMenu = {
            id = "open_pause_menu",
            text = "MENU",
            x = V_WIDTH - 86,
            y = 14,
            w = 72,
            h = 30,
            color = UI.COLORS.panelBg,
            font = UI.fonts.small,
        }
        table.insert(buttons, btnMenu)
        local isH = (mx >= btnMenu.x and mx <= btnMenu.x + btnMenu.w and my >= btnMenu.y and my <= btnMenu.y + btnMenu.h)
        UI.drawButton(btnMenu, isH, juice.buttonPressedId == btnMenu.id)
    end

    -- Floating juice notifications
    if juice.floatingTexts and #juice.floatingTexts > 0 then
        for _, ft in ipairs(juice.floatingTexts) do
            local alpha = math.max(0, math.min(1.0, ft.life / 0.35))
            love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], (ft.color[4] or 1) * alpha)
            love.graphics.setFont(UI.fonts.medium)
            local cleanStr = UI.sanitizeText(ft.text)
            local tw = UI.fonts.medium:getWidth(cleanStr)
            love.graphics.print(cleanStr, ft.x - tw / 2, ft.y)
        end
    end

    -- Dragged Deity floating on top with shadow & glowing border
    if deityDrag.active and deityDrag.isDragging and game.deities and game.deities[deityDrag.deityIndex] then
        local d = game.deities[deityDrag.deityIndex]
        local dw = deityDrag.cardW or 82
        local dh = deityDrag.cardH or 118
        local dx = deityDrag.visualX
        local dy = deityDrag.visualY

        love.graphics.push()
        love.graphics.translate(dx + dw / 2, dy + dh / 2)
        love.graphics.scale(1.12, 1.12)
        love.graphics.translate(-dw / 2, -dh / 2)

        local copyTarget = d.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, deityDrag.deityIndex)
        UI.drawPatronCard(d, 0, 0, dw, dh, true, false, false, copyTarget)

        love.graphics.pop()
    end

    love.graphics.pop()

    -- 2. If Canvas is enabled, present to screen via CRT Post-Processing Shader
    if mainCanvas then
        love.graphics.setCanvas()
        local winW, winH = love.graphics.getDimensions()
        love.graphics.setColor(0.02, 0.02, 0.03, 1)
        love.graphics.rectangle("fill", 0, 0, winW, winH)

        if settings.crtEnabled and crtShader then
            love.graphics.setShader(crtShader)
            if crtShader:hasUniform("u_resolution") then crtShader:send("u_resolution", { V_WIDTH, V_HEIGHT }) end
            if crtShader:hasUniform("u_time") then crtShader:send("u_time", juice.ambientTimer or 0) end
            if crtShader:hasUniform("u_curvature") then crtShader:send("u_curvature", 0.040) end
            if crtShader:hasUniform("u_chroma") then crtShader:send("u_chroma", 0.0020) end
            if crtShader:hasUniform("u_scanlines") then crtShader:send("u_scanlines", 0.16) end
            if crtShader:hasUniform("u_vignette") then crtShader:send("u_vignette", 0.28) end
        else
            love.graphics.setShader()
        end

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(mainCanvas, offsetX, offsetY, 0, scale, scale)
        love.graphics.setShader()
    else
        love.graphics.pop()
    end
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

local function handlePlayingMousepressed(mx, my, button)
    for _, btn in ipairs(buttons) do
        if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            if btn.id == "play" then
                playSelectedHand()
                return true
            elseif btn.id == "discard" then
                discardSelected()
                return true
            elseif btn.id == "sort_rank" then
                game.sortMode = "rank"
                Deck.sortByRank(game.hand)
                clearAllSelections()
                syncCardSelections()
                Sound.play("card_deal")
                return true
            elseif btn.id == "sort_suit" then
                game.sortMode = "suit"
                Deck.sortBySuit(game.hand)
                clearAllSelections()
                syncCardSelections()
                Sound.play("card_deal")
                return true
            elseif btn.id == "open_handbook" then
                isHandbookOpen = true
                Sound.play("card_deal")
                return true
            elseif btn.id == "open_deck_viewer" then
                isDeckViewerOpen = true
                Sound.play("card_deal")
                return true
            elseif btn.id:sub(1, 15) == "use_consumable_" then
                useConsumable(btn.consumableIndex)
                return true
            end
        end
    end

    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5

    -- Check Consumable slots (clicking anywhere on the slot card in combat/blind)
    local conStartX = 295 + maxDeiSlots * (82 + 14) + 20
    for j = 1, 2 do
        local cx = conStartX + (j - 1) * (82 + 14)
        local cy = 32
        if mx >= cx and mx <= cx + 82 and my >= cy and my <= cy + 118 then
            if game.consumables and game.consumables[j] then
                useConsumable(j)
                return true
            end
        end
    end

    -- Check Deity Slots in Top Bar for Drag & Drop Reordering
    for i = 1, maxDeiSlots do
        local dx, dy, dw, dh = getDeitySlotRect(i, "playing")
        if mx >= dx and mx <= dx + dw and my >= dy and my <= dy + dh then
            if game.deities and game.deities[i] then
                deityDrag.active = true
                deityDrag.isDragging = false
                deityDrag.deityIndex = i
                deityDrag.startX = mx
                deityDrag.startY = my
                deityDrag.currentX = mx
                deityDrag.currentY = my
                deityDrag.cardW = dw
                deityDrag.cardH = dh
                deityDrag.offsetX = dx - mx
                deityDrag.offsetY = dy - my
                deityDrag.visualX = dx
                deityDrag.visualY = dy
                return true
            end
        end
    end

    for i = #game.hand, 1, -1 do
        local c = game.hand[i]
        local cx = c.visualX or 0
        local cy = c.visualY or 0
        local cardW = 100
        local cardH = 145

        if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH then
            handDrag.active = true
            handDrag.cardIndex = i
            handDrag.startX = mx
            handDrag.startY = my
            handDrag.currentX = mx
            handDrag.currentY = my
            handDrag.offsetX = cx - mx
            handDrag.offsetY = cy - my
            handDrag.isDragging = false
            return true
        end
    end

    return false
end

local function handleShopMousepressed(mx, my, button)
    if isShopTransferOpen then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "close_shop_transfer" then
                    isShopTransferOpen = false
                    transferSourceCard = nil
                    transferSourceEqIndex = nil
                    transferMessage = nil
                    Sound.play("card_deal")
                    return true
                end
            end
        end

        local allCards = getAllDeckCards()

        local cw = 90
        local ch = 130
        local gap = 18
        local totalW = #allCards * cw + math.max(0, #allCards - 1) * gap
        local startX = math.max(80, (V_WIDTH - totalW) / 2)
        local cardY = 125

        -- Step 1 click: source card
        for i, c in ipairs(allCards) do
            local cx = startX + (i - 1) * (cw + gap)
            if mx >= cx and mx <= cx + cw and my >= cardY and my <= cardY + ch then
                transferSourceCard = c
                transferSourceEqIndex = nil
                transferMessage = nil
                Sound.play("card_select")
                return true
            end
        end

        -- Step 2 click: equipment slot
        if transferSourceCard and transferSourceCard.equipments then
            local eqBoxW = 210
            local eqBoxH = 65
            for idx, eq in ipairs(transferSourceCard.equipments) do
                local ex = 80 + (idx - 1) * (eqBoxW + 16)
                local ey = 320
                if mx >= ex and mx <= ex + eqBoxW and my >= ey and my <= ey + eqBoxH then
                    transferSourceEqIndex = idx
                    transferMessage = nil
                    Sound.play("card_select")
                    return true
                end
            end
        end

        -- Step 3 click: target card
        if transferSourceCard and transferSourceEqIndex and transferSourceCard.equipments and transferSourceCard.equipments[transferSourceEqIndex] then
            local targetY = 445
            for i, c in ipairs(allCards) do
                local cx = startX + (i - 1) * (cw + gap)
                if c ~= transferSourceCard and (not c.equipments or #c.equipments < 5) and mx >= cx and mx <= cx + cw and my >= targetY and my <= targetY + ch then
                    local ok, msg = Shop.transferEquipment(transferSourceCard, transferSourceEqIndex, c)
                    transferMessage = msg
                    if ok then
                        transferSourceEqIndex = nil
                    end
                    return true
                end
            end
        end

        return true
    end

    -- Intercept clicks if Booster Pack is currently being opened
    if shopData and shopData.currentPackOpening then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id:sub(1, 12) == "choose_pack_" then
                    local ok, action, eq = Shop.choosePackCard(shopData, btn.cardIndex, game)
                    if ok and action == "open_socketing" and eq then
                        pendingEquipment = eq
                        socketingReturnState = "shop"
                        state = "socketing"
                    elseif ok and type(action) == "string" then
                        table.insert(anim.floatingTexts, {
                            text = action,
                            color = UI.COLORS.goldYellow,
                            x = 640,
                            y = 200,
                            alpha = 3.0,
                        })
                    elseif not ok and type(action) == "string" then
                        table.insert(anim.floatingTexts, {
                            text = action,
                            color = { 0.95, 0.35, 0.35, 1 },
                            x = 640,
                            y = 200,
                            alpha = 2.5,
                        })
                    end
                    return true
                elseif btn.id:sub(1, 10) == "keep_pack_" then
                    local ok, msg = Shop.keepPackCard(shopData, btn.cardIndex, game)
                    if ok and type(msg) == "string" then
                        table.insert(anim.floatingTexts, {
                            text = msg,
                            color = UI.COLORS.goldYellow,
                            x = 640,
                            y = 200,
                            alpha = 3.0,
                        })
                    elseif not ok and type(msg) == "string" then
                        table.insert(anim.floatingTexts, {
                            text = msg,
                            color = { 0.95, 0.35, 0.35, 1 },
                            x = 640,
                            y = 200,
                            alpha = 2.5,
                        })
                    end
                    return true
                elseif btn.id == "skip_pack" then
                    Shop.skipPack(shopData)
                    return true
                end
            end
        end
        return true
    end

    -- Check Consumable slots (clicking anywhere on the slot card in shop)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    local conStartX = 295 + maxDeiSlots * (82 + 14) + 16
    for j = 1, 2 do
        local cx = conStartX + (j - 1) * (82 + 14)
        local cy = 32
        if mx >= cx and mx <= cx + 82 and my >= cy and my <= cy + 118 then
            if game.consumables and game.consumables[j] then
                useConsumable(j)
                return true
            end
        end
    end

    for _, btn in ipairs(buttons) do
        if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            if btn.id:sub(1, 4) == "buy_" then
                local gIdx = btn.itemIndex
                local it = shopData.items and shopData.items[gIdx]
                if it then
                    shopDrag.active = true
                    shopDrag.isDragging = false
                    shopDrag.itemIndex = gIdx
                    shopDrag.item = it
                    shopDrag.startX = mx
                    shopDrag.startY = my
                    shopDrag.currentX = mx
                    shopDrag.currentY = my
                    shopDrag.origX = btn.x
                    shopDrag.origY = btn.y
                    shopDrag.visualX = btn.x
                    shopDrag.visualY = btn.y
                    shopDrag.cardW = btn.w
                    shopDrag.cardH = btn.h
                    shopDrag.tiltX = 0
                    shopDrag.tiltY = 0
                    return true
                end
            elseif btn.id:sub(1, 6) == "deity_" then
                local dIdx = btn.deityIndex
                if game.deities and game.deities[dIdx] then
                    deityDrag.active = true
                    deityDrag.isDragging = false
                    deityDrag.deityIndex = dIdx
                    deityDrag.startX = mx
                    deityDrag.startY = my
                    deityDrag.currentX = mx
                    deityDrag.currentY = my
                    deityDrag.origX = btn.x
                    deityDrag.origY = btn.y
                    deityDrag.cardW = 82
                    deityDrag.cardH = 118
                    deityDrag.offsetX = btn.x - mx
                    deityDrag.offsetY = btn.y - my
                    deityDrag.visualX = btn.x
                    deityDrag.visualY = btn.y
                    return true
                end
            elseif btn.id:sub(1, 5) == "sell_" then
                Shop.sellDeity(game, btn.deityIndex)
                return true
            elseif btn.id:sub(1, 15) == "use_consumable_" then
                useConsumable(btn.consumableIndex)
                return true
            elseif btn.id == "reroll" then
                Shop.reroll(shopData, game)
                return true
            elseif btn.id == "open_shop_transfer" then
                isShopTransferOpen = true
                transferSourceCard = nil
                transferSourceEqIndex = nil
                transferMessage = nil
                Sound.play("card_deal")
                return true
            elseif btn.id == "open_handbook" or btn.id == "shop_round_info" then
                isHandbookOpen = true
                Sound.play("card_deal")
                return true
            elseif btn.id == "open_deck_viewer" then
                isDeckViewerOpen = true
                Sound.play("card_deal")
                return true
            elseif btn.id == "shop_options" then
                isPauseMenuOpen = true
                Sound.play("ui_click")
                return true
            elseif btn.id == "leave_shop" or btn.id == "next_round" then
                if game.run then
                    local continues, reason = RunManager.advanceBlind(game.run, game)
                    if not continues and reason == "victory" then
                        state = "victory"
                        lastActiveState = "victory"
                        Sound.play("round_win")
                    else
                        game.currentBlind = RunManager.getCurrentBlind(game.run)
                        state = "BLIND_SELECT"
                        lastActiveState = "BLIND_SELECT"
                        Sound.play("card_deal")
                    end
                    saveRunAtSafePoint()
                    return true
                end
                if game.currentNodeId and game.map then
                    Map.onNodeCompleted(game.map, game.currentNodeId)
                end
                state = "map"
                Sound.play("card_deal")
                return true
            end
        end
    end

    return false
end

local function handleModalsMousepressed(mx, my, button)
    -- 0. Settings Modal Handling
    if isSettingsOpen then
        if button == 1 then
            for _, btn in ipairs(buttons) do
                if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    if btn.id == "close_settings" then
                        isSettingsOpen = false
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_voldown" then
                        settings.sfxVolume = math.max(0, settings.sfxVolume - 0.1)
                        Sound.setVolume(settings.sfxVolume)
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_volup" then
                        settings.sfxVolume = math.min(1.0, settings.sfxVolume + 0.1)
                        Sound.setVolume(settings.sfxVolume)
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_speed" then
                        settings.fastScoring = not settings.fastScoring
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_fullscreen" then
                        settings.fullscreen = not settings.fullscreen
                        love.window.setFullscreen(settings.fullscreen, "desktop")
                        updateScale()
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_crt" then
                        settings.crtEnabled = not settings.crtEnabled
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    end
                end
            end
            local modalW = 500
            local modalH = 430
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                isSettingsOpen = false
                Sound.play("ui_click")
            end
            return true
        end
        return true
    end

    -- 0b. Pause Menu Modal Handling
    if isPauseMenuOpen then
        if button == 1 then
            for _, btn in ipairs(buttons) do
                if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    if btn.id == "pause_resume" then
                        isPauseMenuOpen = false
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "pause_handbook" then
                        isHandbookOpen = true
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "pause_settings" then
                        isSettingsOpen = true
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "pause_abandon" then
                        isPauseMenuOpen = false
                        state = "menu"
                        menuMode = "title"
                        hasRunStarted = false
                        Persistence.deleteRun()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "pause_quit" then
                        love.event.quit()
                        return true
                    end
                end
            end
            local modalW = 380
            local modalH = 430
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                isPauseMenuOpen = false
                Sound.play("ui_click")
            end
            return true
        end
        return true
    end

    -- 0c. Handbook Modal Dismissal
    if isHandbookOpen then
        if button == 1 then
            for _, btn in ipairs(buttons) do
                if btn.id == "close_handbook" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    isHandbookOpen = false
                    Sound.play("card_deal")
                    return true
                end
            end
            local modalW = 960
            local modalH = 650
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                isHandbookOpen = false
                Sound.play("card_deal")
                return true
            end
            return true
        end
        return true
    end

    -- 0d. Collection Compendium Modal Dismissal & Interaction
    if isCollectionOpen then
        if button == 1 then
            if collectionCategory then
                -- Detail View
                for _, btn in ipairs(buttons) do
                    if btn.id == "coll_back_to_hub" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                        collectionCategory = nil
                        selectedCollectionItem = nil
                        collectionScrollY = 0
                        Sound.play("card_deal")
                        return true
                    end
                end
                -- Check card clicks to select inspector item
                local items = Collection.getItems(collectionCategory)
                local modalW = 1180
                local modalH = 640
                local modalX = (V_WIDTH - modalW) / 2
                local modalY = (V_HEIGHT - modalH) / 2
                local gridX = modalX + 24
                local gridY = modalY + 75
                local gridH = modalH - 95
                local cardW = 112
                local cardH = 158
                local cols = 6
                local padX = 14
                local padY = 16
                for i, it in ipairs(items) do
                    local col = (i - 1) % cols
                    local row = math.floor((i - 1) / cols)
                    local cx = gridX + col * (cardW + padX)
                    local cy = gridY + row * (cardH + padY) - (collectionScrollY or 0)
                    if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH and my >= gridY and my <= gridY + gridH then
                        selectedCollectionItem = it
                        Sound.play("ui_click")
                        return true
                    end
                end
            else
                -- Category Hub
                for _, btn in ipairs(buttons) do
                    if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                        if btn.id == "coll_close" then
                            isCollectionOpen = false
                            collectionScrollY = 0
                            Sound.play("card_deal")
                            return true
                        elseif btn.catId then
                            collectionCategory = btn.catId
                            selectedCollectionItem = nil
                            collectionScrollY = 0
                            Sound.play("ui_click")
                            return true
                        end
                    end
                end
                local modalW = 760
                local modalH = 590
                local modalX = (V_WIDTH - modalW) / 2
                local modalY = (V_HEIGHT - modalH) / 2
                if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                    isCollectionOpen = false
                    Sound.play("card_deal")
                    return true
                end
            end
            return true
        end
        return true
    end

    -- 1. Right-Click Inspector Modal Dismissal
    if inspectCardModal then
        if button == 2 then
            inspectCardModal = nil
            Sound.play("card_deal")
            return true
        elseif button == 1 then
            for _, btn in ipairs(buttons) do
                if btn.id == "close_inspector" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    inspectCardModal = nil
                    Sound.play("card_deal")
                    return true
                end
            end
            local modalW = 860
            local modalH = 540
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
                inspectCardModal = nil
                Sound.play("card_deal")
                return true
            end
            return true
        end
        return true
    end

    -- 2. Right-Click (button == 2) on any card opens Card Inspector Modal
    if button == 2 then
        -- In Deck Viewer Modal
        if isDeckViewerOpen then
            local modalW = 1180
            local modalH = 650
            local modalX = (V_WIDTH - modalW) / 2
            local modalY = (V_HEIGHT - modalH) / 2
            local cardGridX = modalX + 24
            local cardGridY = modalY + 128
            local cw = 74
            local ch = 108
            local cgap = 10
            local cols = 8

            local allCards = {}
            for _, c in ipairs(game.deck) do table.insert(allCards, c) end
            for _, c in ipairs(game.hand) do table.insert(allCards, c) end
            for _, c in ipairs(game.discardPile) do table.insert(allCards, c) end

            local filteredCards = {}
            for _, c in ipairs(allCards) do
                local hasEq = (c.equipments and #c.equipments > 0)
                if deckViewerFilter == "all" then
                    table.insert(filteredCards, c)
                elseif deckViewerFilter == "equipped" and hasEq then
                    table.insert(filteredCards, c)
                elseif deckViewerFilter == c.suit then
                    table.insert(filteredCards, c)
                end
            end

            for i, c in ipairs(filteredCards) do
                local col = (i - 1) % cols
                local row = math.floor((i - 1) / cols)
                local cx = cardGridX + col * (cw + cgap)
                local cy = cardGridY + row * (ch + cgap)
                if cy + ch <= modalY + modalH - 20 then
                    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                        inspectCardModal = c
                        Sound.play("card_deal")
                        return true
                    end
                end
            end
        end

        -- In playing or other states: check hand cards
        if #game.hand > 0 then
            for i = #game.hand, 1, -1 do
                local c = game.hand[i]
                local cx = c.visualX or 0
                local cy = c.visualY or 0
                local cardW = 100
                local cardH = 145

                if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH then
                    inspectCardModal = c
                    Sound.play("card_deal")
                    return true
                end
            end
        end

        return true
    end

    -- Check in-game Pause Menu button at top right
    if state ~= "menu" then
        for _, btn in ipairs(buttons) do
            if btn.id == "open_pause_menu" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                isPauseMenuOpen = true
                Sound.play("ui_click")
                return true
            end
        end
    end

    -- Intercept all clicks when Deck Viewer Modal is open
    if isDeckViewerOpen then
        local modalW = 1180
        local modalH = 650
        local modalX = (V_WIDTH - modalW) / 2
        local modalY = (V_HEIGHT - modalH) / 2

        -- Close button
        local closeX = modalX + modalW - 160
        local closeY = modalY + 15
        if mx >= closeX and mx <= closeX + 140 and my >= closeY and my <= closeY + 38 then
            isDeckViewerOpen = false
            Sound.play("card_deal")
            return true
        end

        -- Filter tabs
        local tabStartX = modalX + 24
        local tabY = modalY + 86
        local tabW = 108
        local tabH = 30
        local filterIds = { "all", "aurelia", "elaris", "vharos", "valoria", "equipped" }
        for idx, fid in ipairs(filterIds) do
            local tx = tabStartX + (idx - 1) * (tabW + 6)
            if mx >= tx and mx <= tx + tabW and my >= tabY and my <= tabY + tabH then
                deckViewerFilter = fid
                Sound.play("card_deal")
                return true
            end
        end

        -- Click outside modal closes it
        if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
            isDeckViewerOpen = false
            Sound.play("card_deal")
            return true
        end

        return true
    end

    return false
end

function love.mousepressed(x, y, button)
    local mx, my = toVirtual(x, y)

    -- Track pressed button id for juice animation, tactile mechanical sound & micro-screenshake
    for _, btn in ipairs(buttons or {}) do
        if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            juice.buttonPressedId = btn.id
            Sound.play("ui_click")
            if btn.id == "play" or btn.id == "discard" or btn.id == "fight" or btn.id == "fight_blind"
               or btn.id == "reroll" or btn.id == "leave_shop" or btn.id == "btn_select_combat"
               or btn.id == "cashout_continue" or btn.id == "skip_blind" or btn.id == "start_game" then
                juice.screenShake = math.max(juice.screenShake or 0, 2.5)
            end
            break
        end
    end

    -- Modals & Popups Handling
    if handleModalsMousepressed(mx, my, button) then
        return
    end

    if state == "menu" then
        if menuMode == "title" then
            for _, btn in ipairs(buttons) do
                if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    if btn.id == "menu_play" or btn.id == "menu_new_run" then
                        if hasRunStarted then
                            state = lastActiveState or "map"
                        else
                            menuMode = "deck_select"
                        end
                        Sound.play("ui_click")
                        return
                    elseif btn.id == "menu_continue" and hasRunStarted then
                        state = lastActiveState or "map"
                        Sound.play("ui_click")
                        return
                    elseif btn.id == "menu_collection" then
                        isCollectionOpen = true
                        collectionCategory = nil
                        Sound.play("ui_click")
                        return
                    elseif btn.id == "menu_handbook" then
                        isHandbookOpen = true
                        Sound.play("ui_click")
                        return
                    elseif btn.id == "menu_settings" then
                        isSettingsOpen = true
                        Sound.play("ui_click")
                        return
                    elseif btn.id == "menu_mod" then
                        Sound.play("ui_click")
                        table.insert(juice.floatingTexts, {
                            text = "MOD: Terra Suit v1.0.1 Modding Engine sẵn sàng!",
                            x = V_WIDTH / 2,
                            y = V_HEIGHT - 120,
                            color = { 0.85, 0.65, 0.95, 1 },
                            life = 2.5,
                            vy = -25,
                        })
                        return
                    elseif btn.id == "menu_discord" then
                        Sound.play("ui_click")
                        table.insert(juice.floatingTexts, {
                            text = "Discord: discord.gg/terrasuit",
                            x = V_WIDTH / 2,
                            y = V_HEIGHT - 120,
                            color = { 0.45, 0.65, 0.95, 1 },
                            life = 2.5,
                            vy = -25,
                        })
                        return
                    elseif btn.id == "menu_x" then
                        Sound.play("ui_click")
                        table.insert(juice.floatingTexts, {
                            text = "X (Twitter): @TerraSuitGame",
                            x = V_WIDTH / 2,
                            y = V_HEIGHT - 120,
                            color = { 0.85, 0.85, 0.90, 1 },
                            life = 2.5,
                            vy = -25,
                        })
                        return
                    elseif btn.id == "menu_lang" then
                        Sound.play("ui_click")
                        table.insert(juice.floatingTexts, {
                            text = "Ngôn ngữ: Tiếng Việt (Mặc Định)",
                            x = V_WIDTH / 2,
                            y = V_HEIGHT - 120,
                            color = { 0.35, 0.85, 0.55, 1 },
                            life = 2.5,
                            vy = -25,
                        })
                        return
                    elseif btn.id == "menu_quit" then
                        love.event.quit()
                        return
                    end
                end
            end
            return
        else -- menuMode == "deck_select"
            for _, btn in ipairs(buttons) do
                if btn.id == "back_to_title" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    menuMode = "title"
                    Sound.play("ui_click")
                    return
                elseif btn.id == "deck_red" and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    startNewGame(btn.deckId or "red_deck")
                    return
                end
            end
            return
        end

    elseif state == "BLIND_SELECT" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "fight_blind" then
                    local blind = RunManager.getCurrentBlind(game.run)
                    if blind and blind.status == "current" then
                        startBlindCombat(blind)
                        return
                    end
                elseif btn.id == "skip_blind" then
                    local blind = RunManager.getCurrentBlind(game.run)
                    if blind and blind.canSkip and blind.status == "current" then
                        local ok, msg, tag = RunManager.skipCurrentBlind(game.run, game)
                        if ok then
                            local breakdown = RewardSystem.calculate(blind, game, true)
                            game.gold = (game.gold or 0) + breakdown.totalGold
                            cashOutAnim = RewardSystem.newAnimation(breakdown)
                            state = "CASH_OUT"
                            lastActiveState = "CASH_OUT"
                            Sound.play("coin")
                            return
                        end
                    end
                elseif btn.id == "open_handbook" then
                    isHandbookOpen = true
                    Sound.play("ui_click")
                    return
                elseif btn.id == "open_deck_viewer" then
                    isDeckViewerOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_options" then
                    isPauseMenuOpen = true
                    Sound.play("ui_click")
                    return
                end
            end
        end
        return

    elseif state == "map" then
        -- Handle clicks on Encounter / Skip Blind modal if open
        if pendingCombatNode then
            for _, btn in ipairs(buttons) do
                if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                    if btn.id == "modal_fight_node" then
                        local node = pendingCombatNode
                        pendingCombatNode = nil
                        game.currentNodeId = node.id
                        if node.type == "monster" then
                            startMonsterEncounter(node.floor, false, false)
                            state = "playing"
                            Sound.play("card_deal")
                        elseif node.type == "elite" then
                            startMonsterEncounter(node.floor, false, true)
                            state = "playing"
                            Sound.play("card_deal")
                        end
                        return
                    elseif btn.id == "modal_skip_node" then
                        local node = pendingCombatNode
                        pendingCombatNode = nil
                        local ok, rewardMsg, tag = Map.skipCombatNode(game, node.id)
                        table.insert(anim.floatingTexts, {
                            text = "🎁 BỎ QUA ẢI: " .. rewardMsg,
                            color = (tag and tag.color) or UI.COLORS.goldYellow,
                            x = 640,
                            y = 360,
                            alpha = 3.0,
                        })
                        Sound.play("round_win")
                        return
                    elseif btn.id == "modal_close_preview" then
                        pendingCombatNode = nil
                        Sound.play("card_deal")
                        return
                    end
                end
            end
            return
        end

        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "open_handbook" then
                    isHandbookOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "open_deck_viewer" then
                    isDeckViewerOpen = true
                    Sound.play("card_deal")
                    return
                elseif btn.id == "map_scroll_start" then
                    if game.map then Map.scroll(game.map, -9999) end
                    Sound.play("card_deal")
                    return
                elseif btn.id == "map_scroll_focus" then
                    if game.map then Map.focusFloor(game.map, game.map.currentFloor) end
                    Sound.play("card_deal")
                    return
                elseif btn.id == "map_scroll_end" then
                    if game.map then Map.scroll(game.map, 9999) end
                    Sound.play("card_deal")
                    return
                end
            end
        end

        local clickedNode = Map.getNodeAt(game.map, mx, my)
        if clickedNode and clickedNode.available then
            if clickedNode.type == "monster" or clickedNode.type == "elite" then
                pendingCombatNode = clickedNode
                Sound.play("card_deal")
                return
            elseif clickedNode.type == "boss" then
                game.currentNodeId = clickedNode.id
                startMonsterEncounter(clickedNode.floor, true, false)
                state = "playing"
                Sound.play("round_win")
                return
            elseif clickedNode.type == "shop" then
                game.currentNodeId = clickedNode.id
                Shop.resetReroll(shopData)
                Shop.refresh(shopData, game)
                state = "shop"
                Sound.play("card_deal")
                return
            elseif clickedNode.type == "event" then
                game.currentNodeId = clickedNode.id
                game.currentEvent = Events.getRandomEvent(game)
                game.eventOutcomeText = nil
                state = "event"
                Sound.play("card_deal")
                return
            elseif clickedNode.type == "rest" then
                game.currentNodeId = clickedNode.id
                restStateData = { chosenAction = nil, selectedCard = nil, message = nil }
                state = "rest"
                Sound.play("card_deal")
                return
            elseif clickedNode.type == "treasure" then
                game.currentNodeId = clickedNode.id
                generateTreasureRewards()
                state = "treasure"
                Sound.play("card_deal")
                return
            end
            return
        end

    elseif state == "playing" then
        if handlePlayingMousepressed(mx, my, button) then
            return
        end

    elseif state == "scoring" then
        -- Fast-forward scoring step on click
        anim.stepTimer = 999
        return

    elseif state == "CASH_OUT" then
        if cashOutAnim then
            if not cashOutAnim.finished then
                RewardSystem.finishImmediately(cashOutAnim)
                Sound.play("shop_buy")
                return
            else
                for _, btn in ipairs(buttons) do
                    if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                        if btn.id == "cashout_continue" then
                            local curBlind = game.currentBlind or (game.run and game.run.blinds and game.run.blinds[game.run.currentBlindIndex])
                            local isSmall = curBlind and (curBlind.type == "small" or curBlind.index == 1)
                            if isSmall and game.run then
                                -- Small Blind skips Shop, proceeds to Blind Select
                                local continues, reason = RunManager.advanceBlind(game.run, game)
                                if not continues and reason == "victory" then
                                    state = "victory"
                                    lastActiveState = "victory"
                                    Sound.play("round_win")
                                else
                                    game.currentBlind = RunManager.getCurrentBlind(game.run)
                                    state = "BLIND_SELECT"
                                    lastActiveState = "BLIND_SELECT"
                                end
                                saveRunAtSafePoint()
                            else
                                if not shopData then shopData = Shop.new() end
                                Shop.resetReroll(shopData)
                                Shop.refresh(shopData, game)
                                state = "shop"
                                lastActiveState = "shop"
                            end
                            Sound.play("card_deal")
                            return
                        end
                    end
                end
            end
        end
        return

    elseif state == "event" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "event_continue" then
                    if game.currentNodeId and game.map then
                        Map.onNodeCompleted(game.map, game.currentNodeId)
                    end
                    game.currentEvent = nil
                    game.eventOutcomeText = nil
                    state = "map"
                    Sound.play("card_deal")
                    return
                elseif btn.id:sub(1, 10) == "event_opt_" then
                    local optIndex = btn.optIndex
                    local evt = game.currentEvent
                    if evt and evt.options and evt.options[optIndex] then
                        local opt = evt.options[optIndex]
                        local msg, eq = opt.action(game)
                        if eq then
                            pendingEquipment = eq
                            socketingReturnState = "map"
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            game.currentEvent = nil
                            game.eventOutcomeText = nil
                            state = "socketing"
                        else
                            game.eventOutcomeText = msg
                            Sound.play("round_win")
                        end
                        return
                    end
                end
            end
        end

    elseif state == "boss_deity" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id:sub(1, 11) == "boss_deity_" then
                    local chosen = game.bossDeityDraft[btn.deityIndex]
                    if chosen then
                        Deities.addDeity(game, chosen)
                        Sound.play("round_win")
                        generateBossChestRewards()
                        socketingReturnState = "next_act"
                        state = "chest"
                        return
                    end
                end
            end
        end

    elseif state == "chest" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                local rew = chestRewards[btn.rewardIndex]
                if rew then
                    if rew.type == "card" then
                        Deck.addCardToDeck(game, rew.card)
                        Sound.play("card_deal")
                        if socketingReturnState == "next_act" then
                            if game.currentNodeId and game.map then
                                Map.onNodeCompleted(game.map, game.currentNodeId)
                            end
                            game.act = game.act + 1
                            game.map = Map.generate(game.act)
                            game.currentNodeId = nil
                            state = "map"
                        else
                            state = "map"
                        end
                    elseif rew.type == "equipment" then
                        pendingEquipment = rew.item
                        state = "socketing"
                    end
                    return
                end
            end
        end

    elseif state == "treasure" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                local rew = treasureRewards[btn.rewardIndex]
                if rew then
                    if rew.type == "card" then
                        Deck.addCardToDeck(game, rew.card)
                        Sound.play("card_deal")
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    elseif rew.type == "equipment" then
                        pendingEquipment = rew.item
                        socketingReturnState = "map"
                        state = "socketing"
                    end
                    return
                end
            end
        end

    elseif state == "rest" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "rest_action_heal" then
                    game.maxHands = game.maxHands + 1
                    game.maxDiscards = game.maxDiscards + 1
                    game.handsRemaining = game.maxHands
                    game.discardsRemaining = game.maxDiscards
                    game.playerHp = math.min(game.maxPlayerHp or 100, (game.playerHp or 100) + 35)
                    restStateData.chosenAction = "rest"
                    restStateData.message = "Đã Dưỡng Sức & Hồi Phục! Hồi +35 HP (" .. game.playerHp .. "/" .. game.maxPlayerHp .. ") & Tăng giới hạn Lượt Đánh / Đổi bài!"
                    Sound.play("round_win")
                    return
                elseif btn.id == "rest_action_forge" then
                    restStateData.chosenAction = "forge"
                    Sound.play("card_deal")
                    return
                elseif btn.id == "leave_rest" then
                    if game.currentNodeId and game.map then
                        Map.onNodeCompleted(game.map, game.currentNodeId)
                    end
                    state = "map"
                    Sound.play("card_deal")
                    return
                end
            end
        end

        -- If choosing card to forge
        if restStateData.chosenAction == "forge" and not restStateData.selectedCard then
            local allCards = getAllDeckCards()
            for i, c in ipairs(allCards) do
                local cx, cy, cw, ch = getCardGridPos(i, #allCards, 100, 145, 16, 32, 8, 250)
                if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                    Deck.upgradeCard(c)
                    restStateData.selectedCard = c
                    restStateData.message = "Đã tôi luyện thành công lá " .. c.suitSymbol .. " lên Rank " .. c.rankName .. " (+1 Rank vĩnh viễn, bền " .. c.rank .. " lần đánh)!"
                    Sound.play("round_win")
                    return
                end
            end
        end

    elseif state == "socketing" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "socket_prev" and not btn.disabled then
                    socketingPage = math.max(1, socketingPage - 1)
                    socketingMessage = nil
                    Sound.play("card_deal", 0.9)
                    return
                elseif btn.id == "socket_next" and not btn.disabled then
                    socketingPage = socketingPage + 1
                    socketingMessage = nil
                    Sound.play("card_deal", 1.05)
                    return
                elseif btn.id == "skip_socket" then
                    pendingEquipment = nil
                    socketingPage = 1
                    socketingMessage = nil
                    if socketingReturnState == "next_act" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        game.act = game.act + 1
                        game.map = Map.generate(game.act)
                        game.currentNodeId = nil
                        state = "map"
                    elseif socketingReturnState == "shop" then
                        state = "shop"
                    elseif socketingReturnState == "map" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    else
                        state = "map"
                    end
                    return
                end
            end
        end

        -- Check which card is clicked to attach equipment
        local allCards = getAllDeckCards()
        local firstCard = (socketingPage - 1) * SOCKETING_PAGE_SIZE + 1
        local lastCard = math.min(#allCards, firstCard + SOCKETING_PAGE_SIZE - 1)
        for deckIndex = firstCard, lastCard do
            local c = allCards[deckIndex]
            local pageIndex = deckIndex - firstCard + 1
            local cx, cy, cardW, cardH = getSocketingCardRect(pageIndex)
            if mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH then
                local success, msg = Equipment.attach(c, pendingEquipment)
                if success then
                    -- Sync equipment to persistentDeck if c is not already pc
                    if game.persistentDeck then
                        for _, pc in ipairs(game.persistentDeck) do
                            if pc.id == c.id and pc ~= c then
                                pc.equipments = {}
                                for _, eq in ipairs(c.equipments) do
                                    table.insert(pc.equipments, eq)
                                end
                                break
                            end
                        end
                    end
                    Sound.play("shop_buy")
                    pendingEquipment = nil
                    socketingPage = 1
                    socketingMessage = nil
                    if socketingReturnState == "next_act" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        game.act = game.act + 1
                        game.map = Map.generate(game.act)
                        game.currentNodeId = nil
                        state = "map"
                    elseif socketingReturnState == "shop" then
                        state = "shop"
                    elseif socketingReturnState == "map" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    else
                        state = "map"
                    end
                    return
                else
                    Sound.play("card_deselect")
                    socketingMessage = msg or "Không thể gắn trang bị!"
                    table.insert(anim.floatingTexts, {
                        text = msg or "Không thể gắn trang bị!",
                        color = UI.COLORS.multRed,
                        x = 640,
                        y = 400,
                        alpha = 2.0,
                    })
                end
            end
        end

    elseif state == "shop" then
        if handleShopMousepressed(mx, my, button) then
            return
        end

    elseif state == "gameover" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "retry" then
                    state = "menu"
                    menuMode = "title"
                    hasRunStarted = false
                    Persistence.deleteRun()
                    return
                end
            end
        end

    elseif state == "victory" then
        for _, btn in ipairs(buttons) do
            if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id == "victory_menu" then
                    state = "menu"
                    menuMode = "title"
                    hasRunStarted = false
                    Persistence.deleteRun()
                    return
                elseif btn.id == "victory_endless" then
                    if game.run then
                        game.run.endless = true
                        game.run.victory = false
                        game.run.maxAnte = 999
                        game.run.ante = (game.run.ante or 8) + 1
                        game.run.currentBlindIndex = 1
                        game.run.shopsVisitedInAnte = 0
                        game.run.blinds = RunManager.generateAnteBlinds(game.run.ante, game.selectedFaction)
                        state = "BLIND_SELECT"
                        lastActiveState = "BLIND_SELECT"
                        Sound.play("card_deal")
                        hasRunStarted = true
                        saveRunAtSafePoint()
                    else
                        state = "menu"
                        menuMode = "title"
                        hasRunStarted = false
                    end
                    return
                end
            end
        end
    end
end

function love.keypressed(key)
    -- Global Fullscreen Toggle
    if key == "f11" then
        settings.fullscreen = not settings.fullscreen
        love.window.setFullscreen(settings.fullscreen, "desktop")
        updateScale()
        saveSettings()
        return
    end

    -- Toggle Deck Viewer Modal
    if key == "tab" or key == "b" then
        isDeckViewerOpen = not isDeckViewerOpen
        Sound.play("card_deal")
        return
    end

    -- Toggle Handbook Modal
    if key == "h" then
        isHandbookOpen = not isHandbookOpen
        Sound.play("card_deal")
        return
    end

    -- Escape closes Modals or toggles In-Game Pause Menu
    if key == "escape" then
        if isCollectionOpen then
            if collectionCategory then
                collectionCategory = nil
                selectedCollectionItem = nil
            else
                isCollectionOpen = false
            end
            Sound.play("ui_click")
            return
        end
        if isSettingsOpen then
            isSettingsOpen = false
            Sound.play("ui_click")
            return
        end
        if inspectCardModal then
            inspectCardModal = nil
            Sound.play("card_deal")
            return
        end
        if isHandbookOpen then
            isHandbookOpen = false
            Sound.play("card_deal")
            return
        end
        if isShopTransferOpen then
            isShopTransferOpen = false
            Sound.play("card_deal")
            return
        end
        if isDeckViewerOpen then
            isDeckViewerOpen = false
            Sound.play("card_deal")
            return
        end
        if state == "menu" then
            if menuMode == "deck_select" then
                menuMode = "title"
                Sound.play("ui_click")
                return
            end
        else
            isPauseMenuOpen = not isPauseMenuOpen
            Sound.play("ui_click")
            return
        end
    end

    if state == "playing" then
        if key == "space" or key == "return" then
            playSelectedHand()
        elseif key == "d" then
            discardSelected()
        elseif key == "r" then
            game.sortMode = "rank"
            Deck.sortByRank(game.hand)
            clearAllSelections()
            syncCardSelections()
            Sound.play("card_deal")
        elseif key == "s" then
            game.sortMode = "suit"
            Deck.sortBySuit(game.hand)
            clearAllSelections()
            syncCardSelections()
            Sound.play("card_deal")
        elseif key >= "1" and key <= "8" then
            local idx = tonumber(key)
            if idx and idx <= #game.hand then
                toggleCardSelection(idx)
            end
        end
    elseif state == "scoring" then
        if key == "space" or key == "return" then
            anim.stepTimer = 999
        end
    elseif state == "CASH_OUT" then
        if key == "space" or key == "return" then
            if cashOutAnim and not cashOutAnim.finished then
                RewardSystem.finishImmediately(cashOutAnim)
                Sound.play("shop_buy")
            elseif cashOutAnim and cashOutAnim.finished then
                local curBlind = game.currentBlind or (game.run and game.run.blinds and game.run.blinds[game.run.currentBlindIndex])
                local isSmall = curBlind and (curBlind.type == "small" or curBlind.index == 1)
                if isSmall and game.run then
                    -- Small Blind skips Shop, proceeds to Blind Select
                    local continues, reason = RunManager.advanceBlind(game.run, game)
                    if not continues and reason == "victory" then
                        state = "victory"
                        lastActiveState = "victory"
                        Sound.play("round_win")
                    else
                        game.currentBlind = RunManager.getCurrentBlind(game.run)
                        state = "BLIND_SELECT"
                        lastActiveState = "BLIND_SELECT"
                    end
                    saveRunAtSafePoint()
                else
                    if not shopData then shopData = Shop.new() end
                    Shop.resetReroll(shopData)
                    Shop.refresh(shopData, game)
                    state = "shop"
                    lastActiveState = "shop"
                end
                Sound.play("card_deal")
            end
        end
    elseif state == "BLIND_SELECT" then
        if key == "space" or key == "return" then
            local blind = RunManager.getCurrentBlind(game.run)
            if blind and blind.status == "current" then
                startBlindCombat(blind)
            end
        end
    end
end

function love.wheelmoved(x, y)
    if isCollectionOpen and collectionCategory then
        collectionScrollY = (collectionScrollY or 0) - y * 45
        local items = Collection.getItems(collectionCategory)
        local cols = 6
        local rows = math.ceil(#items / cols)
        local maxScroll = math.max(0, rows * (158 + 16) - (640 - 95 - 20))
        collectionScrollY = math.max(0, math.min(maxScroll, collectionScrollY))
    elseif state == "map" and game.map then
        Map.scroll(game.map, -y * 120)
    end
end

function love.mousemoved(x, y, dx, dy)
    local mx, my = toVirtual(x, y)

    -- Button hover sound tracking
    local currentHoveredBtn = nil
    for _, btn in ipairs(buttons or {}) do
        if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            currentHoveredBtn = btn.id
            break
        end
    end
    if currentHoveredBtn and currentHoveredBtn ~= juice.lastHoveredButtonId then
        Sound.play("ui_hover")
    end
    juice.lastHoveredButtonId = currentHoveredBtn

    if handDrag.active and handDrag.cardIndex and state == "playing" then
        handDrag.currentX = mx
        handDrag.currentY = my
        local dist = math.sqrt((mx - handDrag.startX)^2 + (my - handDrag.startY)^2)
        if dist > 7 then
            handDrag.isDragging = true
        end

        if handDrag.isDragging then
            local idx = handDrag.cardIndex
            local c = game.hand[idx]
            local isAxiomSpade = c and (c.suit == "spades" or c.suit == "vharos" or c.suit == "iron_axiom")
            if c and not isAxiomSpade then
                -- Check left neighbor
                if idx > 1 then
                    local leftCard = game.hand[idx - 1]
                    local isLeftAxiom = leftCard and (leftCard.suit == "spades" or leftCard.suit == "vharos" or leftCard.suit == "iron_axiom")
                    if not isLeftAxiom then
                        local prevSlotX = getHandCardPosition(idx - 1, #game.hand)
                        if c.visualX < prevSlotX + 35 then
                            game.hand[idx], game.hand[idx - 1] = game.hand[idx - 1], game.hand[idx]
                            handDrag.cardIndex = idx - 1
                            Sound.play("card_slide")
                        end
                    end
                end
                -- Check right neighbor
                if idx < #game.hand then
                    local rightCard = game.hand[idx + 1]
                    local isRightAxiom = rightCard and (rightCard.suit == "spades" or rightCard.suit == "vharos" or rightCard.suit == "iron_axiom")
                    if not isRightAxiom then
                        local nextSlotX = getHandCardPosition(idx + 1, #game.hand)
                        if c.visualX > nextSlotX - 35 then
                            game.hand[idx], game.hand[idx + 1] = game.hand[idx + 1], game.hand[idx]
                            handDrag.cardIndex = idx + 1
                            Sound.play("card_slide")
                        end
                    end
                end
            end
        end
    end

    if shopDrag.active and state == "shop" then
        shopDrag.currentX = mx
        shopDrag.currentY = my
        local dist = math.sqrt((mx - shopDrag.startX)^2 + (my - shopDrag.startY)^2)
        if dist > 6 then
            shopDrag.isDragging = true
        end
    end

    if deityDrag.active then
        deityDrag.currentX = mx
        deityDrag.currentY = my
        local dist = math.sqrt((mx - deityDrag.startX)^2 + (my - deityDrag.startY)^2)
        if dist > 5 then
            deityDrag.isDragging = true
        end
        deityDrag.visualX = mx + (deityDrag.offsetX or 0)
        deityDrag.visualY = my + (deityDrag.offsetY or 0)
    end
end

function love.mousereleased(x, y, button)
    local mx, my = toVirtual(x, y)
    juice.buttonPressedId = nil

    if button == 1 and handDrag.active then
        if not handDrag.isDragging and handDrag.cardIndex then
            local card = game.hand[handDrag.cardIndex]
            if card then
                card.visualScale = 1.15
            end
            toggleCardSelection(handDrag.cardIndex)
            if card and card.selected then
                Sound.play("card_select")
            else
                Sound.play("card_deselect")
            end
        elseif handDrag.isDragging then
            Sound.play("card_slide")
        end
        handDrag.active = false
        handDrag.cardIndex = nil
        handDrag.isDragging = false
    end

    if button == 1 and shopDrag.active then
        if not shopDrag.isDragging and shopDrag.itemIndex then
            local success, msg, eq = Shop.buyItem(shopData, shopDrag.itemIndex, game)
            if success and msg == "open_socketing" and eq then
                pendingEquipment = eq
                socketingReturnState = "shop"
                state = "socketing"
            end
        elseif shopDrag.isDragging and shopDrag.item then
            if my < 380 or my < (shopDrag.origY - 40) then
                if (game.gold or 0) >= (shopDrag.item.cost or 0) then
                    local success, msg, eq = Shop.buyItem(shopData, shopDrag.itemIndex, game)
                    if success and msg == "open_socketing" and eq then
                        pendingEquipment = eq
                        socketingReturnState = "shop"
                        state = "socketing"
                    end
                else
                    Sound.play("cant_afford")
                    screenShake = 7
                    table.insert(juice.floatingTexts, {
                        text = "Không đủ tiền!",
                        color = UI.COLORS.multRed,
                        x = mx,
                        y = my - 20,
                        vy = -45,
                        life = 1.0,
                    })
                end
            else
                Sound.play("card_slide")
            end
        end
        shopDrag.active = false
        shopDrag.isDragging = false
        shopDrag.itemIndex = nil
        shopDrag.item = nil
    end

    if button == 1 and deityDrag.active then
        if deityDrag.isDragging and deityDrag.deityIndex and game.deities then
            local srcSlot = deityDrag.deityIndex
            local foundDest = nil
            local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
            for i = 1, maxDeiSlots do
                local sx, sy, sw, sh = getDeitySlotRect(i, state)
                if mx >= sx - 10 and mx <= sx + sw + 10 and my >= sy - 10 and my <= sy + sh + 10 then
                    foundDest = i
                    break
                end
            end
            if foundDest and foundDest ~= srcSlot then
                local temp = game.deities[srcSlot]
                game.deities[srcSlot] = game.deities[foundDest]
                game.deities[foundDest] = temp
                Sound.play("card_slide")
                if not anim.deityBounce then anim.deityBounce = {} end
                anim.deityBounce[foundDest] = 1.40
                anim.deityBounce[srcSlot] = 1.25
                local targetName = game.deities[foundDest] and game.deities[foundDest].name or "Thần"
                table.insert(anim.floatingTexts, {
                    text = "Đã xếp " .. targetName .. " vào Ô " .. foundDest .. "!",
                    color = UI.COLORS.goldYellow,
                    x = mx,
                    y = my - 25,
                    alpha = 1.5,
                })
            else
                Sound.play("card_deselect")
            end
        end
        deityDrag.active = false
        deityDrag.isDragging = false
        deityDrag.deityIndex = nil
    end
end

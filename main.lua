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
local DebugTools = require("src.debug_tools")
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
local transferPage = 1
local drawShopTransferView -- Called by drawShopState; implemented after the shop layout.

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
local deckViewerPage = 1

-- Main Menu & Pause Menu State
local menuMode = "title" -- "title", "deck_select"
local isPauseMenuOpen = false
local isSettingsOpen = false
local isDebugOpen = false
local debugTab = "gold"
local debugGoldInput = "100"
local debugAnteInput = "1"
local debugInputFocus = nil
local debugCategory = "jokers"
local debugItemPage = 1
local debugTargetCardIndex = 1
local debugMessage = nil
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
    crtEnabled = false,
    debugEnabled = false,
}

local function saveSettings()
    if isCaptureMode then return end
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
local battleArt = {}
local monsterMotion = { attack = 0, hit = 0 }

local function getDeitySlotRect(i, currentState)
    currentState = currentState or state
    if currentState == "playing" or currentState == "scoring" or currentState == "shop" then
        local maxSlots = game and Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
        if maxSlots > 6 then
            local column = (i - 1) % 4
            local row = math.floor((i - 1) / 4)
            return 1041 + column * 55, 110 + row * 78, 50, 72
        end
        local column = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        return 1042 + column * 72, 112 + row * 106, 64, 88
    end
    local slotW = 82
    local slotH = 118
    local gap = 14
    local startX = 295
    local slotY = 32
    return startX + (i - 1) * (slotW + gap), slotY, slotW, slotH
end
UI.getDeitySlotRect = getDeitySlotRect

local function drawConsumableSlot(c, cx, cy, conSlotW, conSlotH, j, mx, my)
    if c then
        cy = cy + math.sin(((juice and juice.ambientTimer) or 0) * 1.35 + j * 0.9) * 2
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
        local emptyImg = UI.getButtonImage("slot_item_empty")
        if emptyImg then
            local ew, eh = emptyImg:getDimensions()
            love.graphics.setColor(1, 1, 1, 0.90)
            love.graphics.draw(emptyImg, cx, cy, 0, conSlotW / ew, conSlotH / eh)
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
    cardHit = {},
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

-- Short-lived visual feedback shared by shop purchases, sales and pack picks.
local shopFx = {}

local function spawnShopFx(kind, item, x, y)
    local category = item and item.category
    local targetX, targetY = 1110, 630
    if category == "deity" or (item and item.id and Deities.CATALOG[item.id]) then
        targetX, targetY = 420, 86
    elseif category == "equipment" then
        targetX, targetY = 720, 92
    elseif category == "consumable" then
        targetX, targetY = 980, 92
    end
    if kind == "sell" then
        targetX, targetY = 205, 570
    elseif kind == "destroy" then
        targetX, targetY = x or 640, (y or 360) - 28
    end
    table.insert(shopFx, {
        kind = kind,
        item = item or {},
        x = x or 640,
        y = y or 360,
        life = 0,
        targetX = targetX,
        targetY = targetY,
        duration = kind == "destroy" and 0.72 or (kind == "sell" and 0.82 or 0.92),
    })
end

local function getConsumableSlotRect(i, currentState)
    if currentState == "playing" or currentState == "scoring" or currentState == "shop" then
        return 1042 + (i - 1) * 72, 358, 64, 88
    end
    return 295 + (i - 1) * 96, 32, 82, 118
end

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
        local fadeIn = math.min(1, (p.age or 0) * 10)
        local curAlpha = math.max(0, progress * fadeIn * (p.alpha or 0.85))
        local curSize = p.size * (0.35 + 0.65 * progress)

        if p.pType == "ember" then
            -- Sparks have a glowing head and a velocity trail, making large
            -- Aura bursts feel energetic without covering the numbers.
            love.graphics.setColor(p.outerCol[1], p.outerCol[2], p.outerCol[3], curAlpha * 0.5)
            love.graphics.setLineWidth(math.max(1, curSize * 0.65))
            love.graphics.line(p.x, p.y, p.x - p.vx * 0.035, p.y - p.vy * 0.035)
            love.graphics.setColor(p.coreCol[1], p.coreCol[2], p.coreCol[3], curAlpha)
            love.graphics.circle("fill", p.x, p.y, curSize * 0.75)
        else
            -- Three tapered layers read as a flame rather than a stack of dots.
            local sway = math.sin((p.age or 0) * 15 + (p.phase or 0)) * curSize * 0.8
            local tipY = p.y - curSize * (2.8 + (p.tier or 1) * 0.35)
            love.graphics.setColor(p.outerCol[1], p.outerCol[2], p.outerCol[3], curAlpha * 0.45)
            love.graphics.polygon("fill", p.x - curSize * 1.45, p.y + curSize, p.x + curSize * 1.45, p.y + curSize, p.x + sway, tipY)
            love.graphics.circle("fill", p.x, p.y + curSize * 0.45, curSize * 1.45)
            love.graphics.setColor(p.bodyCol[1], p.bodyCol[2], p.bodyCol[3], curAlpha * 0.85)
            love.graphics.polygon("fill", p.x - curSize * 0.85, p.y + curSize * 0.7, p.x + curSize * 0.85, p.y + curSize * 0.7, p.x + sway * 0.55, tipY + curSize * 0.85)
            love.graphics.setColor(p.coreCol[1], p.coreCol[2], p.coreCol[3], curAlpha * 0.95)
            love.graphics.polygon("fill", p.x - curSize * 0.32, p.y + curSize * 0.55, p.x + curSize * 0.32, p.y + curSize * 0.55, p.x + sway * 0.22, tipY + curSize * 1.55)
        end
    end
    love.graphics.setLineWidth(1)
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
            if #game.consumables < 3 then
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
                    text = "🟣 [DẤU TÍM] Ô Tiêu Hao đã đầy (3/3)!",
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

local function destroyHandCard(index)
    local card = game.hand and game.hand[index]
    if not card then return nil end
    local x = (card.visualX or 590) + 50
    local y = (card.visualY or 470) + 72
    table.remove(game.hand, index)
    if game.persistentDeck then
        for i = #game.persistentDeck, 1, -1 do
            if game.persistentDeck[i].id == card.id then
                table.remove(game.persistentDeck, i)
                break
            end
        end
    end
    game.selectedIndices = {}
    for i, remaining in ipairs(game.hand) do
        if remaining.selected then table.insert(game.selectedIndices, i) end
    end
    spawnShopFx("destroy", { category = "card", card = card }, x, y)
    Sound.play("card_destroy")
    return card
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
            if game.hand and #game.hand > 0 then destroyHandCard(Rng.random(#game.hand)) end
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
            if game.hand and #game.hand > 0 then destroyHandCard(Rng.random(#game.hand)) end
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
            if game.hand and #game.hand > 0 then destroyHandCard(Rng.random(#game.hand)) end
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
                destroyHandCard(1)
                destroyed = destroyed + 1
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
    anim.cardHit = {}
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
        mainCanvas:setFilter("linear", "linear")
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
    local nativePrint, nativePrintf = love.graphics.print, love.graphics.printf
    love.graphics.print = function(value, ...)
        return nativePrint(UI.localizeText(value), ...)
    end
    love.graphics.printf = function(value, ...)
        return nativePrintf(UI.localizeText(value), ...)
    end
    for key, path in pairs({ background = "assets/scene/shrine_lowpoly.png", menuWorld = "assets/scene/menu_world_v2.png", menuLogo = "assets/scene/menu_logo_v2.png", enemySmall = "assets/scene/enemy_small_lowpoly.png", enemyElite = "assets/scene/enemy_elite_lowpoly.png", enemyBoss = "assets/scene/enemy_boss_lowpoly.png", chest = "assets/scene/treasure_chest.png" }) do
        if love.filesystem.getInfo(path) then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok then
                image:setFilter("linear", "linear")
                battleArt[key] = image
            end
        end
    end
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
    monsterMotion.attack = math.max(0, monsterMotion.attack - dt)
    monsterMotion.hit = math.max(0, monsterMotion.hit - dt)
    if game and game.monster then
        if monsterMotion.target ~= game.monster then
            monsterMotion.target = game.monster
        elseif monsterMotion.lastHp and game.monster.hp < monsterMotion.lastHp then
            monsterMotion.hit = 0.35
        end
        monsterMotion.lastHp = game.monster.hp
    else
        monsterMotion.target = nil
        monsterMotion.lastHp = nil
    end
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
            getShopTransferState = function()
                return isShopTransferOpen, transferPage, transferSourceCard, transferSourceEqIndex
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
            isDebugEnabled = function()
                return settings.debugEnabled
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
                shopData.currentPackOpening.animationTimer = 2
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
    if anim.cardHit then
        for idx, age in pairs(anim.cardHit) do
            age = age + dt
            anim.cardHit[idx] = age < 0.36 and age or nil
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
            local idle = math.sin(juice.ambientTimer * 1.75 + i * 0.82) * 2.5
            ty = ty + idle
            tangle = tangle + math.sin(juice.ambientTimer * 1.25 + i * 0.67) * 0.008
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
            c.selectPulse = math.max(0, (c.selectPulse or 0) - dt * 4.5)
            local targetScale = c.selected and 1.11 or (c.hovered and 1.075 or 1.0)
            targetScale = targetScale + math.sin((c.selectPulse or 0) * math.pi) * 0.07
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

    if shopData and shopData.currentPackOpening then
        local opening = shopData.currentPackOpening
        opening.animationTimer = math.min(3.0, (opening.animationTimer or 0) + dt)
    end
    for i = #shopFx, 1, -1 do
        local fx = shopFx[i]
        fx.life = fx.life + dt
        if fx.life >= fx.duration then table.remove(shopFx, i) end
    end
    for _, card in ipairs(anim.playedCards or {}) do
        if card.destroyFxActive then
            card.destroyFx = math.min(1, (card.destroyFx or 0) + dt * 1.9)
        end
    end

    -- Gold change detection
    if game.gold and juice.lastGold and game.gold ~= juice.lastGold then
        if game.gold > juice.lastGold then
            juice.goldBounce = 1.35
            spawnJuiceText("+$" .. (game.gold - juice.lastGold) .. " Vàng", 485, 89, UI.COLORS.goldYellow, 1.2)
        end
        juice.lastGold = game.gold
    end

    -- HP change detection
    if game.playerHp and juice.lastHp and game.playerHp ~= juice.lastHp then
        if game.playerHp < juice.lastHp then
            juice.hpBounce = 1.30
            spawnJuiceText("-" .. (juice.lastHp - game.playerHp) .. " HP", 285, 89, UI.COLORS.hpRed, 1.2)
        elseif game.playerHp > juice.lastHp then
            juice.hpBounce = 1.30
            spawnJuiceText("+" .. (game.playerHp - juice.lastHp) .. " HP", 285, 89, UI.COLORS.hpGreen, 1.2)
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

    -- Scoring embers now frame the arena instead of the removed sidebar.
    if state == "scoring" and anim.active then
        local multVal = anim.displayMult or 0
        if multVal >= 20 then
            local tier = (multVal >= 100) and 3 or ((multVal >= 50) and 2 or 1)
            spawnFireEmbers(534, 229, 210, 42, tier)
        end

        local scoreVal = anim.displayFinalScore or 0
        if scoreVal >= 1000 then
            local tier = (scoreVal >= 50000) and 3 or ((scoreVal >= 10000) and 2 or 1)
            spawnFireEmbers(424, 335, 360, 94, tier)
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
                    anim.cardHit[st.cardIndex] = 0
                    anim.bounceScale.chips = 1.40
                    if st.addedMult > 0 then
                        anim.bounceScale.mult = 1.45
                    end
                    anim.bounceScale.score = 1.35
                    screenShake = math.max(screenShake, 2.0)

                    local cardCenterX = UI.getScoringCardX(st.cardIndex, #anim.playedCards) + 48
                    local cardCenterY = 295 + 70 - 20
                    spawnSparks(cardCenterX, cardCenterY, 18, UI.COLORS.goldYellow)
                    if st.card.destroyed then
                        st.card.destroyFx = 0
                        st.card.destroyFxActive = true
                        spawnSparks(cardCenterX, cardCenterY, 34, { 1.0, 0.32, 0.08, 1 })
                        Sound.play("xmult_boom", 1.15)
                    end
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
                    local dCenterX = 1074
                    if dIdx then
                        anim.deityBounce[dIdx] = 1.45
                        local dx, _, dw = UI.getDeitySlotRect(dIdx, "playing")
                        dCenterX = dx + dw / 2
                    end
                    local dCenterY = 156

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
                        x = UI.getScoringCardX(st.cardIndex, #anim.playedCards) + 48,
                        y = 300,
                        alpha = 1.8,
                    })

                elseif st.type == "deity_edition" then
                    anim.activeCardIndex = nil
                    local dIdx = st.slotIndex or 1
                    local dx, dy, dw, dh = UI.getDeitySlotRect(dIdx, "playing")
                    local dCenterX = dx + dw / 2
                    local dCenterY = dy + dh / 2
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

                    -- Keep the impact on the monster, not the removed left HUD.
                    local mCenterX = UI.BATTLE_CENTER_X
                    local mCenterY = 270
                    spawnSparks(mCenterX, mCenterY, 32, UI.COLORS.hpRed)
                    anim.impactFlash = 0.32
                    anim.impactX = mCenterX
                    anim.impactY = mCenterY
                    anim.impactColor = UI.COLORS.hpRed
                    table.insert(anim.floatingTexts, {
                        text = "-" .. UI.formatNumber(actualDmg) .. " HP!",
                        color = UI.COLORS.hpRed,
                        x = mCenterX,
                        y = mCenterY - 58,
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
                                            if #game.consumables < 3 then
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
                                                    text = "🔵 [DẤU LAM] Ô Tiêu Hao đã đầy (3/3)!",
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
                        monsterMotion.attack = 0.42

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
    local g = love.graphics
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    if battleArt.menuWorld then
        local bw, bh = battleArt.menuWorld:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(battleArt.menuWorld, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
    end
    g.setColor(0.01, 0.02, 0.05, 0.18)
    g.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    if battleArt.menuLogo then
        local lw = battleArt.menuLogo:getWidth()
        g.setColor(1, 1, 1, 1)
        g.draw(battleArt.menuLogo, 40, 4, 0, 590 / lw, 590 / lw)
    else
        g.setFont(UI.fonts.logo)
        g.setColor(UI.COLORS.goldYellow)
        g.print("TERRA SUIT", 46, 46)
    end
    g.setFont(UI.fonts.medium)
    g.setColor(UI.COLORS.goldYellow)
    g.print("LỤC ĐỊA THỨC TỈNH", 76, 168)
    g.setFont(UI.fonts.tiny)
    g.setColor(UI.COLORS.textLight)
    g.print("ROGUELIKE POKER TCG", 78, 194)

    local px, py, pw, ph = 62, 225, 300, 322
    UI.drawGildedPanel(px, py, pw, ph)
    g.setFont(UI.fonts.small)
    g.setColor(UI.COLORS.goldYellow)
    g.print("✦  HỒ SƠ KẺ THÁCH ĐẤU", px + 22, py + 20)
    g.setFont(UI.fonts.large)
    g.setColor(UI.COLORS.textLight)
    g.print("Nhatnam", px + 22, py + 50)
    g.setFont(UI.fonts.tiny)
    g.setColor(0.8, 0.59, 0.9, 1)
    g.print(hasRunStarted and "HÀNH TRÌNH ĐANG DIỄN RA" or "SẴN SÀNG KHÁM PHÁ", px + 22, py + 89)
    g.setColor(UI.COLORS.goldYellow)
    g.line(px + 20, py + 116, px + pw - 20, py + 116)

    local rows = {
        { "Ải hiện tại", hasRunStarted and ("Ải " .. tostring((game.run and game.run.ante) or game.act or 1)) or "Chưa bắt đầu" },
        { "Tiền vàng", tostring(game.gold or 0) },
        { "SPM đang mang", tostring(Deities.getCount(game.deities)) .. "/" .. tostring(Deities.getMaxSlots(game)) },
        { "Lá trong bộ bài", tostring(#(game.persistentDeck or {})) },
        { "Tay bài tối đa", tostring(game.maxHandSize or 3) },
    }
    g.setFont(UI.fonts.small)
    for i, row in ipairs(rows) do
        local ry = py + 132 + (i - 1) * 32
        g.setColor(UI.COLORS.textLight)
        g.print(row[1], px + 22, ry)
        g.setColor(UI.COLORS.goldYellow)
        g.printf(row[2], px + 22, ry, pw - 44, "right")
        if i < #rows then
            g.setColor(0.72, 0.60, 0.39, 0.22)
            g.line(px + 22, ry + 24, px + pw - 22, ry + 24)
        end
    end

    local menuItems = {
        { id = "menu_play", text = hasRunStarted and "TIẾP TỤC" or "VÀO TRẬN",
            sub = "KHÁM PHÁ LỤC ĐỊA", icon = "⚔", color = { 0.05, 0.26, 0.49, 1 },
            menuAccent = { 0.55, 0.81, 1, 1 }, assetId = "btn_main_vao_tran" },
        { id = "menu_collection", text = "BỘ SƯU TẬP",
            sub = "BÀI • SPM • TRANG BỊ", icon = "▣", color = { 0.32, 0.21, 0.07, 1 },
            menuAccent = UI.COLORS.goldYellow, assetId = "btn_main_bo_suu_tap" },
        { id = "menu_settings", text = "TÙY CHỌN",
            sub = "CÀI ĐẶT TRÒ CHƠI", icon = "✦", color = { 0.28, 0.09, 0.39, 1 },
            menuAccent = { 0.83, 0.55, 0.95, 1 }, assetId = "btn_main_tuy_chon" },
        { id = "menu_quit", text = "THOÁT",
            sub = "TẠM BIỆT", icon = "⇥", color = { 0.42, 0.08, 0.10, 1 },
            menuAccent = { 1, 0.47, 0.45, 1 }, assetId = "btn_main_thoat" },
    }
    for i, item in ipairs(menuItems) do
        local btn = {
            id = item.id, text = item.text, sub = item.sub, icon = item.icon,
            x = 808, y = 234 + (i - 1) * 91, w = 426, h = 78,
            color = item.color, menuAccent = item.menuAccent, menuStyle = true,
            font = UI.fonts.large, assetId = item.assetId,
        }
        table.insert(buttons, btn)
        UI.drawButton(btn, mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h,
            juice.buttonPressedId == btn.id)
    end

    g.setFont(UI.fonts.tiny)
    g.setColor(UI.COLORS.textLight)
    g.print("TERRA SUIT  •  POKER ROGUELIKE", 38, 683)
    local footer = {
        { id = "menu_mod", text = "MOD", x = 827, w = 78 },
        { id = "menu_lang", text = "TIẾNG VIỆT", x = 913, w = 150 },
        { id = "menu_discord", text = "DISCORD", x = 1071, w = 100 },
        { id = "menu_x", text = "X", x = 1179, w = 55 },
    }
    for _, item in ipairs(footer) do
        local btn = {
            id = item.id, text = item.text, x = item.x, y = 662, w = item.w, h = 36,
            color = UI.COLORS.btnNormal, font = UI.fonts.tiny,
        }
        table.insert(buttons, btn)
        UI.drawButton(btn, mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h,
            juice.buttonPressedId == btn.id)
    end
end

local function drawCollectionModal()
    local g = love.graphics
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}
    if battleArt.menuWorld then
        local bw, bh = battleArt.menuWorld:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(battleArt.menuWorld, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
    end
    g.setColor(0.01, 0.02, 0.04, 0.78)
    g.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
    UI.drawGildedPanel(60, 34, 1160, 640)

    g.setFont(UI.fonts.title)
    g.setColor(UI.COLORS.goldYellow)
    g.printf("BỘ SƯU TẬP", 90, 56, 1100, "center")
    g.setFont(UI.fonts.small)
    g.setColor(UI.COLORS.textMuted)
    g.printf("Khám phá toàn bộ bài, SPM, trang bị và thử thách", 90, 98, 1100, "center")

    local categories = {
        { id = "jokers", title = "SPM", icon = "✦", accent = { 0.62, 0.80, 1, 1 } },
        { id = "decks", title = "BỘ BÀI", icon = "▣", accent = UI.COLORS.goldYellow },
        { id = "vouchers", title = "PHIẾU", icon = "◈", accent = { 0.55, 0.86, 0.70, 1 } },
        { id = "consumables", title = "TRANG BỊ KHẢM", icon = "◇", accent = { 0.64, 0.86, 0.95, 1 } },
        { id = "enhancements", title = "LÁ CƯỜNG HÓA", icon = "✧", accent = { 0.95, 0.68, 0.50, 1 } },
        { id = "seals", title = "CON DẤU", icon = "✦", accent = { 0.75, 0.62, 0.94, 1 } },
        { id = "editions", title = "ẤN BẢN", icon = "◇", accent = UI.COLORS.goldYellow },
        { id = "packs", title = "RƯƠNG BÀI", icon = "▣", accent = { 0.55, 0.80, 0.98, 1 } },
        { id = "tags", title = "KHẾ ƯỚC BỎ ẢI", icon = "✧", accent = { 0.95, 0.55, 0.55, 1 } },
        { id = "blinds", title = "QUÁI VẬT", icon = "⚔", accent = { 0.95, 0.55, 0.55, 1 } },
        { id = "other", title = "THẾ ĐÁNH", icon = "✦", accent = { 0.70, 0.88, 0.70, 1 } },
    }
    for i, cat in ipairs(categories) do
        local count = #Collection.getItems(cat.id)
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        local btn = {
            id = "coll_cat_" .. cat.id, catId = cat.id, text = cat.title,
            sub = tostring(count) .. " mục", icon = cat.icon,
            x = 94 + col * 367, y = 132 + row * 113, w = 350, h = 98,
            color = { 0.10, 0.15, 0.21, 1 }, menuAccent = cat.accent,
            menuStyle = true, font = UI.fonts.medium,
        }
        table.insert(buttons, btn)
        UI.drawButton(btn, mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h,
            juice.buttonPressedId == btn.id)
    end
    local close = {
        id = "coll_close", text = "TRỞ LẠI", x = 515, y = 596, w = 250, h = 50,
        color = UI.COLORS.btnNormal, font = UI.fonts.medium,
    }
    table.insert(buttons, close)
    UI.drawButton(close, mx >= close.x and mx <= close.x + close.w and my >= close.y and my <= close.y + close.h,
        juice.buttonPressedId == close.id)
end

local function drawCollectionDetailView()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    if battleArt.menuWorld then
        local bw, bh = battleArt.menuWorld:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(battleArt.menuWorld, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
    end
    love.graphics.setColor(0.01, 0.02, 0.04, 0.84)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    local cat = Collection.getCategoryById(collectionCategory) or { title = "Danh Mục", sub = "" }
    local items = Collection.getItems(collectionCategory)

    local modalW = 1180
    local modalH = 640
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    UI.drawGildedPanel(modalX, modalY, modalW, modalH)

    -- Header Navigation
    local btnBack = {
        id = "coll_back_to_hub",
        text = "< QUAY LẠI BỘ SƯU TẬP",
        x = modalX + 24,
        y = modalY + 16,
        w = 230,
        h = 38,
        color = UI.COLORS.btnNormal,
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
            local dImg = ((collectionCategory == "jokers") and UI.getDeityImage(item.id))
                      or ((collectionCategory == "consumables") and UI.getEquipmentImage(item.id))
                      or ((collectionCategory == "packs") and (item.isPackContent and UI.getPackCardImage(item.packType, item) or UI.getPackImage(item.packType or item.id)))
                      or ((collectionCategory == "other") and UI.getHandImage(item.handId or item.id))
                      or ((collectionCategory == "vouchers") and (UI.getVoucherImage(item.id) or UI.getHandImage(item.handId or item.id) or UI.getHandImage(item.id)))
            if not UI.useLegacyPixelArt and collectionCategory ~= "packs" then dImg = nil end
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

                UI.drawItemEmblem(item, cardW / 2, 69, 19, itemCol)

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

        local inspImg = ((collectionCategory == "jokers") and UI.getDeityImage(inspItem.id))
                     or ((collectionCategory == "consumables") and UI.getEquipmentImage(inspItem.id))
                     or ((collectionCategory == "packs") and (inspItem.isPackContent and UI.getPackCardImage(inspItem.packType, inspItem) or UI.getPackImage(inspItem.packType or inspItem.id)))
                     or ((collectionCategory == "other") and UI.getHandImage(inspItem.handId or inspItem.id))
                     or ((collectionCategory == "vouchers") and (UI.getVoucherImage(inspItem.id) or UI.getHandImage(inspItem.handId or inspItem.id) or UI.getHandImage(inspItem.id)))
        if not UI.useLegacyPixelArt and collectionCategory ~= "packs" then inspImg = nil end
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

            UI.drawItemEmblem(inspItem, lcx + lcw / 2, lcy + 92, 36, lcol)
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
    if battleArt.menuWorld then
        local bw, bh = battleArt.menuWorld:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(battleArt.menuWorld, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
    end
    love.graphics.setColor(0.01, 0.02, 0.04, 0.74)
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
    UI.drawGildedPanel(cardX, cardY, cardW, cardH, deckInfo.color)

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
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(1, 0.86, 0.48, 1)
    love.graphics.printf("LƯỢT ĐẦU: +10 CƯỜNG HÓA", cardX + 40, cardY + 233, cardW - 80, "center")
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Mỗi trận xáo bộ bài và rút 3 lá ngẫu nhiên lên tay.", cardX + 50, cardY + 274, cardW - 100, "center")

    local choose = {
        id = "deck_red", deckId = "red_deck", text = "CHỌN BỘ BÀI ĐỎ",
        x = cardX + 65, y = cardY + cardH - 70, w = cardW - 130, h = 44,
        color = deckInfo.color, font = UI.fonts.medium,
    }
    table.insert(buttons, choose)
    UI.drawButton(choose, hovered, juice.buttonPressedId == choose.id)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Bộ bài chuẩn 52 lá • Không có kỹ năng phe • Tay bài khởi đầu: 3", 0, V_HEIGHT - 50, V_WIDTH, "center")
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
    local handAreaX = UI.BATTLE_ARENA_X
    local handAreaW = UI.BATTLE_ARENA_W

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

local function drawBattleHud(m, mx, my)
    local g = love.graphics
    UI.drawGildedPanel(10, 8, 1260, 55)
    g.setFont(UI.fonts.small)
    g.setColor(UI.COLORS.goldYellow)
    g.print("ẢI " .. tostring((game.run and game.run.ante) or game.act or 1) .. "-" .. tostring((game.run and game.run.blindIndex) or game.round or 1), 24, 16)
    g.setColor(UI.COLORS.textLight)
    g.print(m and (m.isBoss or m.isElite) and m.name or "Tiểu Yêu", 24, 38)

    local crestImg = UI.getButtonImage("crest_top_monster")
    if crestImg then
        local cw, ch = crestImg:getDimensions()
        g.setColor(1, 1, 1, 0.92)
        g.draw(crestImg, 120, 18, 0, 26 / cw, 30 / ch)
    end

    UI.drawPlayerHpBar(178, 19, 235, 32, game.playerHp, game.maxPlayerHp, game.playerArmor or game.playerShield or 0)

    local coinImg = UI.getButtonImage("icon_top_coin")
    if coinImg then
        local iw, ih = coinImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(coinImg, 430, 23, 0, 20 / iw, 24 / ih)
        g.setFont(UI.fonts.small)
        g.setColor(UI.COLORS.goldYellow)
        g.print(tostring(game.gold or 0), 456, 27)
    else
        g.setColor(UI.COLORS.goldYellow)
        g.print("◉ " .. tostring(game.gold or 0), 436, 27)
    end

    local cardsImg = UI.getButtonImage("icon_top_cards")
    if cardsImg then
        local iw, ih = cardsImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(cardsImg, 532, 23, 0, 20 / iw, 24 / ih)
        g.setFont(UI.fonts.small)
        g.setColor(UI.COLORS.textLight)
        g.print("LƯỢT " .. tostring(game.handsRemaining or 0) .. "/" .. tostring(game.maxHands or 0), 558, 27)
    else
        g.setFont(UI.fonts.small)
        g.setColor(UI.COLORS.textLight)
        g.print("LƯỢT " .. tostring(game.handsRemaining or 0) .. "/" .. tostring(game.maxHands or 0), 550, 27)
    end

    local skullImg = UI.getButtonImage("icon_top_skull")
    if skullImg then
        local iw, ih = skullImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(skullImg, 676, 23, 0, 20 / iw, 24 / ih)
        g.setFont(UI.fonts.small)
        g.setColor(UI.COLORS.textLight)
        g.print("BỎ " .. tostring(game.discardsRemaining or 0), 702, 27)
    else
        g.setFont(UI.fonts.small)
        g.setColor(UI.COLORS.textLight)
        g.print("BỎ " .. tostring(game.discardsRemaining or 0), 700, 27)
    end

    local info = { id = "open_handbook", text = "TRẬN", x = 805, y = 19, w = 82, h = 33, color = UI.COLORS.btnNormal, font = UI.fonts.tiny, assetId = "btn_top_tran_active", activeAssetId = "btn_top_tran_active" }
    local deck = { id = "open_deck_viewer", text = "BỘ BÀI", x = 896, y = 19, w = 93, h = 33, color = UI.COLORS.btnNormal, font = UI.fonts.tiny, assetId = "btn_top_bo_bai_active", activeAssetId = "btn_top_bo_bai_active" }
    for _, btn in ipairs({ info, deck }) do
        table.insert(buttons, btn)
        UI.drawButton(btn, mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
    end
end

local function drawBattleEnemy(m)
    if not m then return end
    local g = love.graphics
    local t = (juice and juice.ambientTimer) or 0
    local attack = monsterMotion.attack / 0.42
    local hit = monsterMotion.hit / 0.35
    local cx, cy = UI.BATTLE_CENTER_X, 270 + math.sin(t * 1.9) * 5
    local size = m.isBoss and 355 or (m.isElite and 325 or 290)
    g.setColor(0, 0, 0, 0.38)
    g.ellipse("fill", cx, 414, size * 0.38, 23)
    local enemyImage = m.isBoss and battleArt.enemyBoss or (m.isElite and battleArt.enemyElite or battleArt.enemySmall)
    if enemyImage then
        local iw, ih = enemyImage:getDimensions()
        local fit = math.min(size / iw, size / ih)
        g.push()
        g.translate(cx + attack * 50 - hit * 14, cy - attack * 20)
        g.rotate(math.sin(t * 1.4) * 0.018 - attack * 0.08 + hit * 0.07)
        g.setColor(1, 1 - hit * 0.58, 1 - hit * 0.58, 1)
        g.draw(enemyImage, -iw * fit / 2, -ih * fit / 2, 0, fit, fit)
        g.pop()
    end
    g.setFont(UI.fonts.medium)
    g.setColor(1, 1, 1, 1)
    g.printf((m.isBoss or m.isElite) and (m.name or "Quái") or "Tiểu Yêu", UI.BATTLE_CENTER_X - 175, 85, 350, "center")
    UI.drawMonsterHpBar(UI.BATTLE_CENTER_X - 168, 111, 336, 24, m.hp, m.maxHp, m.damageLagHp)
end

local function drawBattleInfoPanel(m, eval, preview)
    local g = love.graphics
    local scoring = state == "scoring" and anim.active
    local chips = scoring and (anim.displayChips or 0) or (preview and preview.totalChips or 0)
    local mult = scoring and (anim.displayMult or 0) or (preview and preview.totalMult or 0)
    local xMult = scoring and (anim.displayXMult or 1) or (preview and preview.xMultTotal or 1)
    local aura = scoring and (anim.displayFinalScore or 0) or (preview and preview.finalScore or 0)
    local handName = scoring and (anim.evalResult and anim.evalResult.type and anim.evalResult.type.vnName)
        or (eval and eval.type and eval.type.vnName) or "Chọn bài để xem"
    local x, y, w, h = 12, 76, 222, 615
    UI.drawGildedPanel(x, y, w, h)

    local crestStar = UI.getButtonImage("crest_star_compass")
    if crestStar then
        local cw, ch = crestStar:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(crestStar, x + (w - 36) / 2, y - 10, 0, 36 / cw, 36 / ch)
    end

    g.setFont(UI.fonts.small)
    g.setColor(UI.COLORS.goldYellow)
    g.print("TAY BÀI", x + 14, y + 14)
    g.setColor(UI.COLORS.textLight)
    g.printf(UI.truncateUtf8(handName, 24), x + 14, y + 39, w - 28, "left")

    local statY = y + 72
    local satImg = UI.getButtonImage("badge_sat_thuong")
    local cuongImg = UI.getButtonImage("badge_cuong_hoa")
    local badgeW = 98
    local badgeH = 62

    if satImg and cuongImg then
        local sx = x + 10
        local sw, sh = satImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(satImg, sx, statY, 0, badgeW / sw, badgeH / sh)
        if chips > 0 then
            g.setColor(0.04, 0.08, 0.14, 0.92)
            g.rectangle("fill", sx + 50, statY + 24, 42, 32, 3)
            g.setFont(UI.fonts.medium)
            g.setColor(UI.COLORS.chipsBlue)
            g.printf(UI.formatNumber(chips), sx + 48, statY + 28, 46, "center")
        end

        local cx = x + 114
        local cw, ch = cuongImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(cuongImg, cx, statY, 0, badgeW / cw, badgeH / sh)
        if mult > 0 then
            g.setColor(0.14, 0.04, 0.06, 0.92)
            g.rectangle("fill", cx + 50, statY + 24, 42, 32, 3)
            g.setFont(UI.fonts.medium)
            g.setColor(UI.COLORS.multRed)
            g.printf(UI.formatNumber(mult), cx + 48, statY + 28, 46, "center")
        end
    else
        for _, stat in ipairs({
            { label = "SÁT THƯƠNG", value = chips, color = UI.COLORS.chipsBlue, offset = 0 },
            { label = "CƯỜNG HÓA", value = mult, color = UI.COLORS.multRed, offset = 100 },
        }) do
            local sx = x + 12 + stat.offset
            g.setColor(stat.color[1], stat.color[2], stat.color[3], 0.26)
            UI.drawRoundedRect("fill", sx, statY, 96, 66, 5)
            g.setColor(stat.color)
            UI.drawRoundedRect("line", sx, statY, 96, 66, 5)
            g.setFont(UI.fonts.tiny)
            g.printf(stat.label, sx + 3, statY + 8, 90, "center")
            g.setFont(UI.fonts.medium)
            g.printf(UI.formatNumber(stat.value), sx + 3, statY + 31, 90, "center")
        end
    end

    local pwrY = statY + badgeH + 6
    local pwrImg = UI.getButtonImage("badge_power")
    local pwrBoxW = 104
    local pwrBoxH = 40
    local px = x + (w - pwrBoxW) / 2
    if pwrImg then
        local pw, ph = pwrImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(pwrImg, px, pwrY, 0, pwrBoxW / pw, pwrBoxH / ph)
        if chips > 0 or mult > 0 then
            g.setColor(0.04, 0.06, 0.08, 0.90)
            g.rectangle("fill", px + 30, pwrY + 8, 44, 24, 3)
            g.setFont(UI.fonts.small)
            g.setColor(UI.COLORS.textLight)
            g.printf(UI.formatNumber(chips) .. " × " .. UI.formatNumber(mult), px + 10, pwrY + 11, pwrBoxW - 20, "center")
        end
    else
        g.setFont(UI.fonts.small)
        g.setColor(UI.COLORS.textMuted)
        g.printf(UI.formatNumber(chips) .. " × " .. UI.formatNumber(mult), x + 12, pwrY + 8, w - 24, "center")
    end
    if xMult > 1 then
        g.setFont(UI.fonts.tiny)
        g.setColor(UI.COLORS.goldYellow)
        g.printf("Hệ số phụ ×" .. string.format("%.2f", xMult), x + 12, pwrY + 42, w - 24, "center")
    end

    local auraY = pwrY + (xMult > 1 and 58 or 46)
    local auraImg = UI.getButtonImage("badge_aura")
    local auraBoxW = 202
    local auraBoxH = 68
    local ax = x + (w - auraBoxW) / 2

    if auraImg then
        local aw, ah = auraImg:getDimensions()
        g.setColor(1, 1, 1, 1)
        g.draw(auraImg, ax, auraY, 0, auraBoxW / aw, auraBoxH / ah)
        if aura > 0 then
            g.setColor(0.12, 0.10, 0.06, 0.92)
            g.rectangle("fill", ax + 90, auraY + 26, 98, 34, 3)
            g.setFont(UI.fonts.large)
            g.setColor(UI.COLORS.goldYellow)
            g.printf(UI.formatNumber(aura), ax + 88, auraY + 28, 102, "center")
        end
    else
        g.setColor(0.57, 0.41, 0.22, 0.30)
        UI.drawRoundedRect("fill", ax, auraY, auraBoxW, auraBoxH, 5)
        g.setColor(UI.COLORS.goldYellow)
        g.setFont(UI.fonts.tiny)
        g.printf(scoring and "AURA ĐANG CỘNG" or "AURA DỰ KIẾN", ax + 4, auraY + 7, auraBoxW - 8, "center")
        g.setFont(UI.fonts.large)
        g.printf(UI.formatNumber(aura), ax + 4, auraY + 25, auraBoxW - 8, "center")
    end

    local monY = auraY + auraBoxH + 10
    g.setColor(UI.COLORS.panelBorder)
    g.line(x + 14, monY, x + w - 14, monY)

    local dragonImg = UI.getButtonImage("art_dragon_head")
    if dragonImg then
        local dw, dh = dragonImg:getDimensions()
        g.setColor(1, 1, 1, 0.90)
        g.draw(dragonImg, x + w - 95, monY + 6, 0, 88 / dw, 68 / dh)
    end

    g.setFont(UI.fonts.small)
    g.setColor(UI.COLORS.goldYellow)
    g.print("✦ QUÁI VẬT", x + 14, monY + 12)
    g.setColor(UI.COLORS.textLight)
    g.print(UI.truncateUtf8((m and m.name) or "Không rõ", 13), x + 14, monY + 34)
    g.setFont(UI.fonts.tiny)
    g.setColor(UI.COLORS.textMuted)
    g.print("MÁU  " .. tostring(m and m.hp or 0) .. "/" .. tostring(m and m.maxHp or 0), x + 14, monY + 54)

    local hpBarY = monY + 76
    local hpBarW = w - 28
    local hpBarH = 14
    local mCurHp = math.max(0, (m and m.hp) or 0)
    local mMaxHp = math.max(1, (m and m.maxHp) or 1)
    local mPct = math.min(1.0, mCurHp / mMaxHp)
    g.setColor(0.08, 0.05, 0.05, 0.95)
    UI.drawRoundedRect("fill", x + 14, hpBarY, hpBarW, hpBarH, 3)
    if mPct > 0 then
        g.setColor(0.85, 0.22, 0.22, 0.95)
        UI.drawRoundedRect("fill", x + 15, hpBarY + 1, math.floor((hpBarW - 2) * mPct), hpBarH - 2, 2)
    end
    g.setColor(0.45, 0.15, 0.15, 1)
    g.setLineWidth(1.2)
    UI.drawRoundedRect("line", x + 14, hpBarY, hpBarW, hpBarH, 3)

    g.setFont(UI.fonts.tiny)
    g.setColor(UI.COLORS.hpRed)
    g.print("CHIÊU TIẾP THEO", x + 14, hpBarY + 22)
    g.setColor(UI.COLORS.textLight)
    g.printf(UI.localizeText((m and m.intent and m.intent.label) or "Chưa rõ"), x + 14, hpBarY + 38, w - 28, "left")

    g.setColor(UI.COLORS.goldYellow)
    g.print(m and m.bossData and "DEBUFF" or "ĐẶC ĐIỂM", x + 14, hpBarY + 74)
    g.setColor(UI.COLORS.textMuted)
    local debuff = m and m.bossData and m.bossData.desc or "Không có hiệu ứng bất lợi"
    g.printf(UI.truncateUtf8(debuff, 150), x + 14, hpBarY + 92, w - 28, "left")
    if scoring then
        g.setColor(UI.COLORS.panelBorder)
        g.line(x + 14, y + 548, x + w - 14, y + 548)
        g.setColor(UI.COLORS.goldYellow)
        g.setFont(UI.fonts.tiny)
        local finished = anim.currentStepIndex > #anim.scoringData.steps
        local category = finished and "KẾT QUẢ" or (anim.stepCategory or "ĐANG CỘNG AURA")
        g.printf(UI.truncateUtf8(category, 26), x + 14, y + 558, w - 28, "left")
        g.setColor(UI.COLORS.textLight)
        local detail = finished and (anim.monsterDefeated and ("Hạ quái • +$" .. tostring(anim.earnedGold or 0))
            or (game.handsRemaining <= 0 and "Hết lượt đánh • bạn đã thua"
                or ("Đã gây " .. UI.formatNumber(anim.displayFinalScore or 0) .. " sát thương")))
            or UI.localizeText(anim.stepLog or "")
        g.printf(UI.truncateUtf8(detail, 55), x + 14, y + 576, w - 28, "left")
    end
end

local function drawPlayingState()
    syncCardSelections()
    local winW, winH = love.graphics.getDimensions()
    if battleArt.background then
        love.graphics.setColor(1, 1, 1, 1)
        local bw, bh = battleArt.background:getDimensions()
        love.graphics.draw(battleArt.background, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
    else
        love.graphics.setColor(UI.COLORS.felt)
        love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)
    end

    local mx, my = toVirtual(love.mouse.getPosition())
    hoveredDeityTooltip = nil
    hoveredCardTooltip = nil
    buttons = {}

    local m = game.monster
    -- Preview uses the same scoring logic as the attack animation.
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
    drawBattleEnemy(m)
    drawBattleHud(m, mx, my)
    drawBattleInfoPanel(m, eval, scPreview)
    UI.drawGildedPanel(1028, 73, 239, 248)
    UI.drawGildedPanel(1028, 318, 239, 145, { 0.45, 0.85, 0.65, 1 })

    -- 2. RIGHT RAIL: SPM & CONSUMABLES
    ----------------------------------------------------------------------------
    local topStartX = 1042
    local topStartY = 82

    -- Deities Section
    local spmEyeImg = UI.getButtonImage("icon_spm_eye")
    if spmEyeImg then
        local iw, ih = spmEyeImg:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(spmEyeImg, topStartX, topStartY - 2, 0, 24 / iw, 24 / ih)
    end
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local curDeiCount = Deities.getCount(game.deities)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    love.graphics.print("SPM (" .. curDeiCount .. "/" .. maxDeiSlots .. ")", topStartX + (spmEyeImg and 28 or 4), topStartY)

    local deitySlotW = 64
    local deitySlotH = 88
    local deityGap = 14
    local deityY = 112

    for i = 1, maxDeiSlots do
        local dx, deityY, deitySlotW, deitySlotH = getDeitySlotRect(i, "playing")
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
            local deityFloat = math.sin(((juice and juice.ambientTimer) or 0) * 1.15 + i * 0.72) * 2
            love.graphics.translate(dx + deitySlotW / 2, deityY + deitySlotH / 2 + deityFloat)
            love.graphics.rotate(math.sin(((juice and juice.ambientTimer) or 0) * 0.75 + i) * 0.008)
            if bScale > 1.01 then
                love.graphics.scale(bScale, bScale)
            end
            love.graphics.translate(-dx - deitySlotW / 2, -deityY - deitySlotH / 2)

            local copyTarget = d.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, i)
            UI.drawPatronCard(d, dx, deityY, deitySlotW, deitySlotH, isHoveredSlot, juice.buttonPressedId == ("deity_" .. i), isDropTarget, copyTarget)
            love.graphics.pop()
        else
            -- Empty Tarot Slot
            local emptyDeiImg = UI.getButtonImage("slot_spm_empty")
            if emptyDeiImg and not isDropTarget then
                local ew, eh = emptyDeiImg:getDimensions()
                love.graphics.setColor(1, 1, 1, 0.90)
                love.graphics.draw(emptyDeiImg, dx, deityY, 0, deitySlotW / ew, deitySlotH / eh)
            else
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
    end

    -- Consumables Section (0/3)
    local conStartX = 1042
    game.consumables = game.consumables or {}
    local conCount = #game.consumables
    local potionImg = UI.getButtonImage("icon_consumable_potion")
    if potionImg then
        local iw, ih = potionImg:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(potionImg, conStartX, 325, 0, 24 / iw, 24 / ih)
    end
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor({ 0.45, 0.85, 0.65, 1 })
    love.graphics.print("TIÊU HAO (" .. conCount .. "/3)", conStartX + (potionImg and 28 or 4), 327)

    local conSlotW = 64
    local conSlotH = 88
    local conGap = 14
    for j = 1, 3 do
        local cx, cy = getConsumableSlotRect(j, "playing")
        local c = game.consumables[j]
        drawConsumableSlot(c, cx, cy, conSlotW, conSlotH, j, mx, my)
    end

    ----------------------------------------------------------------------------
    -- PLAYER HAND CARDS
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
            if c.hovered or c.selected then
                local glow = c.selected and UI.COLORS.goldYellow or UI.COLORS.chipsBlue
                local pulse = 0.28 + math.sin(juice.ambientTimer * 5 + i) * 0.08
                love.graphics.setBlendMode("add")
                love.graphics.setColor(glow[1], glow[2], glow[3], pulse)
                UI.drawRoundedRect("fill", cx - 6, cy - 6, cardW + 12, cardH + 14, 11)
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
    local hcX = UI.BATTLE_CENTER_X - hcW / 2
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
        text = "Chơi Tay Bài",
        x = UI.BATTLE_CENTER_X - 255,
        y = actionY,
        w = 175,
        h = 58,
        color = UI.COLORS.chipsBlue,
        font = UI.fonts.small,
        assetId = "btn_combat_play",
        disabled = not hasSelection or game.handsRemaining <= 0,
    }
    table.insert(buttons, btnPlay)
    UI.drawButton(btnPlay, mx >= btnPlay.x and mx <= btnPlay.x + btnPlay.w and my >= btnPlay.y and my <= btnPlay.y + btnPlay.h)

    -- Center: Sắp Xếp Container Box
    local sortBoxX = UI.BATTLE_CENTER_X - 65
    local sortBoxY = actionY - 8
    local sortBoxW = 145
    local sortBoxH = 68
    love.graphics.setColor(0.12, 0.16, 0.20, 0.95)
    UI.drawRoundedRect("fill", sortBoxX, sortBoxY, sortBoxW, sortBoxH, 6)
    love.graphics.setColor(0.30, 0.38, 0.46, 1)
    UI.drawRoundedRect("line", sortBoxX, sortBoxY, sortBoxW, sortBoxH, 6)

    local sortHeaderImg = UI.getButtonImage("btn_combat_sort_header")
    if sortHeaderImg then
        local shw, shh = sortHeaderImg:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(sortHeaderImg, sortBoxX + (sortBoxW - 124) / 2, sortBoxY + 2, 0, 124 / shw, 20 / shh)
    else
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("SẮP XẾP BÀI", sortBoxX, sortBoxY + 4, sortBoxW, "center")
    end

    local btnSortRank = {
        id = "sort_rank",
        text = "Bậc",
        x = sortBoxX + 6,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        color = (game.sortMode == "rank") and { 0.28, 0.48, 0.72, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.tiny,
        assetId = (game.sortMode == "rank") and "btn_combat_sort_rank_active" or "btn_combat_sort_rank_inactive",
    }
    table.insert(buttons, btnSortRank)
    UI.drawButton(btnSortRank, mx >= btnSortRank.x and mx <= btnSortRank.x + btnSortRank.w and my >= btnSortRank.y and my <= btnSortRank.y + btnSortRank.h)

    local btnSortSuit = {
        id = "sort_suit",
        text = "Chất",
        x = sortBoxX + 76,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        color = (game.sortMode == "suit") and { 0.28, 0.48, 0.72, 1 } or UI.COLORS.btnNormal,
        font = UI.fonts.tiny,
        assetId = (game.sortMode == "suit") and "btn_combat_sort_suit_active" or "btn_combat_sort_suit_inactive",
    }
    table.insert(buttons, btnSortSuit)
    UI.drawButton(btnSortSuit, mx >= btnSortSuit.x and mx <= btnSortSuit.x + btnSortSuit.w and my >= btnSortSuit.y and my <= btnSortSuit.y + btnSortSuit.h)

    -- Right: Bỏ Bài [D]
    local btnDiscard = {
        id = "discard",
        text = "Bỏ Bài",
        x = UI.BATTLE_CENTER_X + 95,
        y = actionY,
        w = 160,
        h = 58,
        color = UI.COLORS.multRed,
        font = UI.fonts.small,
        assetId = "btn_combat_discard",
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
    love.graphics.printf("BỘ BÀI", deckPileX, deckPileY + 12, deckPileW, "center")

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
    -- Reuse the arena and live left-side breakdown while cards resolve.
    drawPlayingState()

    -- Played cards share the same arena center as the hand and monster.
    local cards = anim.playedCards or {}
    local cardW = 96
    local cardH = 140
    local playY = 295

    -- Render Played Cards in Play Zone
    for i, c in ipairs(cards) do
        local cx = UI.getScoringCardX(i, #cards)
        local entrance = math.max(0, math.min(1, ((anim.entranceTimer or 0) - (i - 1) * 0.04) / 0.16))
        local easedEntrance = 1 - (1 - entrance) ^ 3
        local cy = 490 + (playY - 490) * easedEntrance
        local isActive = (anim.activeCardIndex == i)
        local isScored = (anim.scoredCards and anim.scoredCards[i] ~= nil)

        c.visualScale = 0.72 + easedEntrance * 0.28
        c.rotation = (1 - easedEntrance) * ((i % 2 == 0) and 0.10 or -0.10)

        if isActive then
            cy = cy - 20 -- Lift active card
        end

        local hitAge = anim.cardHit and anim.cardHit[i]
        if hitAge then
            local force = math.max(0, 1 - hitAge / 0.36)
            cx = cx + math.sin(hitAge * 118) * 7 * force
            cy = cy - math.sin(hitAge * 62) * 4 * force
            c.rotation = c.rotation + math.sin(hitAge * 95) * 0.045 * force
            c.visualScale = c.visualScale * (1 + 0.11 * force)
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

        local dissolve = c.destroyFxActive and (c.destroyFx or 0) or 0
        if dissolve > 0 then
            local shrink = math.max(0.18, 1 - dissolve * 0.72)
            love.graphics.push()
            love.graphics.translate(cx + cardW / 2, cy + cardH / 2)
            love.graphics.rotate(dissolve * ((i % 2 == 0) and 0.22 or -0.22))
            love.graphics.scale(shrink, shrink)
            UI.drawCard(c, -cardW / 2, -cardH / 2, cardW, cardH)
            love.graphics.pop()

            love.graphics.setBlendMode("add")
            for shard = 1, 18 do
                local phase = shard * 2.37
                local sx = cx + cardW / 2 + math.cos(phase) * dissolve * (24 + shard * 1.6)
                local sy = cy + cardH * (1 - dissolve) + math.sin(phase) * 18 - dissolve * shard * 1.3
                love.graphics.setColor(1, 0.22 + (shard % 3) * 0.16, 0.05, 1 - dissolve)
                love.graphics.rectangle("fill", sx, sy, 2 + shard % 4, 2 + shard % 3)
            end
            love.graphics.setBlendMode("alpha")
        else
            UI.drawCard(c, cx, cy, cardW, cardH)
        end

        -- If actively scoring: Draw golden highlight ring and floating pill above
        if isActive then
            love.graphics.setBlendMode("add")
            love.graphics.setColor(1, 0.72, 0.18, 0.16 + math.sin(juice.ambientTimer * 18) * 0.05)
            UI.drawRoundedRect("fill", cx - 9, cy - 9, cardW + 18, cardH + 18, 12)
            love.graphics.setBlendMode("alpha")
            love.graphics.setLineWidth(3)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", cx - 2, cy - 2, cardW + 4, cardH + 4, 8)

            -- Floating pill above card
            local pillW = 120
            local pillH = 26
            local pillX = cx + (cardW - pillW) / 2
            local pillY = cy - 32

            love.graphics.setColor(0.12, 0.16, 0.22, 0.95)
            UI.drawRoundedRect("fill", pillX, pillY, pillW, pillH, 6)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", pillX, pillY, pillW, pillH, 6)

            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow)
            local bonusText = "+" .. (c.baseChips or 0) .. " ST"
            if anim.scoredCards and anim.scoredCards[i] then
                local sc = anim.scoredCards[i]
                if sc.addedMult and sc.addedMult > 0 then
                    bonusText = "+" .. sc.addedChips .. " ST / +" .. sc.addedMult .. " C.H"
                else
                    bonusText = "+" .. sc.addedChips .. " ST"
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
        text = "SỔ TAY",
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
        text = "XEM BÀI",
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
        text = "SỔ TAY",
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
        text = "XEM BỘ BÀI",
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

local function getDeckViewerCards()
    local cards = {}
    if (state == "playing" or state == "scoring") and (#game.hand > 0 or #game.deck > 0 or #game.discardPile > 0) then
        for _, card in ipairs(game.hand) do table.insert(cards, card) end
        for _, card in ipairs(game.deck) do table.insert(cards, card) end
        for _, card in ipairs(game.discardPile) do table.insert(cards, card) end
    else
        for _, card in ipairs(game.persistentDeck or {}) do table.insert(cards, card) end
    end
    return cards
end

local function getDeckViewerFilteredCards()
    local filtered = {}
    for _, card in ipairs(getDeckViewerCards()) do
        local suit = card.suit
        if suit == "hearts" then suit = "valoria"
        elseif suit == "diamonds" then suit = "aurelia"
        elseif suit == "clubs" then suit = "elaris"
        elseif suit == "spades" then suit = "vharos" end
        local equipped = card.equipments and #card.equipments > 0
        if deckViewerFilter == "all" or (deckViewerFilter == "equipped" and equipped) or deckViewerFilter == suit then
            table.insert(filtered, card)
        end
    end
    return filtered
end

local function getDeckViewerCardAt(mx, my, modalX, modalY)
    local cards = getDeckViewerFilteredCards()
    local first = (deckViewerPage - 1) * 32 + 1
    for sourceIndex = first, math.min(#cards, first + 31) do
        local visibleIndex = sourceIndex - first + 1
        local col = (visibleIndex - 1) % 8
        local row = math.floor((visibleIndex - 1) / 8)
        local cx = modalX + 24 + col * 84
        local cy = modalY + 128 + row * 118
        if mx >= cx and mx <= cx + 74 and my >= cy and my <= cy + 108 then
            return cards[sourceIndex]
        end
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
        text = "ĐÓNG",
        x = modalX + modalW - 160,
        y = modalY + 15,
        w = 140,
        h = 38,
        color = UI.COLORS.btnDiscard,
        font = UI.fonts.regular,
    }
    UI.drawButton(closeBtn, mx >= closeBtn.x and mx <= closeBtn.x + closeBtn.w and my >= closeBtn.y and my <= closeBtn.y + closeBtn.h)

    -- Gather all cards in the full deck
    local allCards = getDeckViewerCards()

    -- Filter cards
    local filteredCards = getDeckViewerFilteredCards()
    local suitCounts = { aurelia = 0, elaris = 0, vharos = 0, valoria = 0 }
    local equippedCount = 0

    for _, c in ipairs(allCards) do
        local s = c.suit
        if s == "hearts" then s = "valoria"
        elseif s == "diamonds" then s = "aurelia"
        elseif s == "clubs" then s = "elaris"
        elseif s == "spades" then s = "vharos" end

        if suitCounts[s] then
            suitCounts[s] = suitCounts[s] + 1
        end
        local hasEq = (c.equipments and #c.equipments > 0)
        if hasEq then equippedCount = equippedCount + 1 end

    end

    -- Left Column: Cards (Width 680)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Tổng cộng: " .. #allCards .. " lá  (Rô ♦: " .. suitCounts.aurelia .. " | Tép ♣: " .. suitCounts.elaris .. " | Bích ♠: " .. suitCounts.vharos .. " | Cơ ♥: " .. suitCounts.valoria .. " | Đã khảm: " .. equippedCount .. " lá)", modalX + 24, modalY + 58)

    local cardsPerPage = 32
    local totalPages = math.max(1, math.ceil(#filteredCards / cardsPerPage))
    deckViewerPage = math.max(1, math.min(deckViewerPage, totalPages))
    local pagePrev = { id = "deck_page_prev", text = "‹", x = modalX + 570, y = modalY + 50, w = 34, h = 26, color = UI.COLORS.btnNormal, font = UI.fonts.small, disabled = deckViewerPage <= 1 }
    local pageNext = { id = "deck_page_next", text = "›", x = modalX + 654, y = modalY + 50, w = 34, h = 26, color = UI.COLORS.btnNormal, font = UI.fonts.small, disabled = deckViewerPage >= totalPages }
    table.insert(buttons, pagePrev)
    table.insert(buttons, pageNext)
    UI.drawButton(pagePrev, not pagePrev.disabled and mx >= pagePrev.x and mx <= pagePrev.x + pagePrev.w and my >= pagePrev.y and my <= pagePrev.y + pagePrev.h)
    UI.drawButton(pageNext, not pageNext.disabled and mx >= pageNext.x and mx <= pageNext.x + pageNext.w and my >= pageNext.y and my <= pageNext.y + pageNext.h)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(deckViewerPage .. "/" .. totalPages, modalX + 604, modalY + 57, 50, "center")

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

    local firstCard = (deckViewerPage - 1) * cardsPerPage + 1
    local lastCard = math.min(#filteredCards, firstCard + cardsPerPage - 1)
    for sourceIndex = firstCard, lastCard do
        local c = filteredCards[sourceIndex]
        local i = sourceIndex - firstCard + 1
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = cardGridX + col * (cw + cgap)
        local cy = cardGridY + row * (ch + cgap)

        if cy + ch <= modalY + modalH - 20 then
            local isHov = (mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch)
            if isHov then hoveredDeckCard = c end

            c.hovered = isHov
            local driftY = math.sin(((juice and juice.ambientTimer) or 0) * 1.1 + i * 0.57) * 1.8
            local driftR = math.sin(((juice and juice.ambientTimer) or 0) * 0.72 + i * 0.41) * 0.006
            love.graphics.push()
            love.graphics.translate(cx + cw / 2, cy + ch / 2 + driftY - (isHov and 4 or 0))
            love.graphics.rotate(driftR)
            love.graphics.translate(-cw / 2, -ch / 2)
            UI.drawCard(c, 0, 0, cw, ch)
            love.graphics.pop()
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
    love.graphics.print("Chỉ các Thế Đánh đã mở khóa mới có thể đánh ra và tạo Aura!", rightX, modalY + 92)

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

        -- Hand stats include the current permanent level, not only base values.
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textLight)
        local handType = Poker.HAND_TYPES[h.id]
        local level = (game.handLevels and game.handLevels[h.id]) or 1
        local stats = handType and Poker.getHandStats(handType, level)
        local statText = stats and (stats.chips .. " Chips × " .. stats.mult .. " Mult") or h.base
        love.graphics.print("Lv." .. level .. "  •  Cần " .. h.req .. " lá  •  " .. statText, rightX + 12, hy + 28)

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

    local eqImg = UI.getEquipmentImage(equipment.id)
    eqImg = UI.visualImage(eqImg)
    if eqImg then
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = eqImg:getDimensions()
        love.graphics.draw(eqImg, panelX + 30, panelY + 12, 0, 56 / iw, 80 / ih)
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(eqColor)
        UI.drawRoundedRect("line", panelX + 30, panelY + 12, 56, 80, 6)
    else
        love.graphics.setColor(eqColor[1], eqColor[2], eqColor[3], 0.22)
        love.graphics.circle("fill", panelX + 58, panelY + panelH / 2, 34)
        love.graphics.setColor(eqColor)
        love.graphics.circle("line", panelX + 58, panelY + panelH / 2, 34)
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(equipment.icon or "◆", panelX + 24, panelY + 31, 68, "center")
    end

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
        text = "ĐÓNG",
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
    love.graphics.printf("Aura: +" .. card.baseChips .. " Chips", cardArtX + 8, durY + durH - 24, cardArtW - 16, "center")

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
        text = "ĐÓNG",
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

        -- Hand Card Miniature Thumbnail
        local hImg = UI.getHandImage(h.id)
        hImg = UI.visualImage(hImg)
        local thumbW = 34
        local thumbH = 46
        local thumbX = modalX + 34
        local thumbY = cy + (rowH - thumbH) / 2
        if hImg then
            if isUnlocked then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(0.35, 0.35, 0.40, 0.6)
            end
            local hiw, hih = hImg:getDimensions()
            love.graphics.draw(hImg, thumbX, thumbY, 0, thumbW / hiw, thumbH / hih)
            love.graphics.setColor(isUnlocked and { 0.3, 0.7, 0.9, 0.7 } or { 0.3, 0.3, 0.35, 0.4 })
            love.graphics.setLineWidth(1)
            UI.drawRoundedRect("line", thumbX, thumbY, thumbW, thumbH, 4)
        end

        -- Status Badge (Left)
        local badgeW = 92
        local badgeH = 30
        local badgeX = modalX + 76
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
        local textX = lvlBadgeX + lvlBadgeW + 12
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

    UI.drawGildedPanel(modalX, modalY, modalW, modalH)

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
    local modalH = 515
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2

    UI.drawGildedPanel(modalX, modalY, modalW, modalH)

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
    love.graphics.print("Tốc Độ Aura:", modalX + 35, row2Y + 6)

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

    local crtText = settings.crtEnabled and "CRT NHẸ: BẬT" or "CRT NHẸ: TẮT"
    local btnCrt = { id = "setting_crt", text = crtText, x = modalX + 300, y = row4Y, w = 150, h = 34, color = settings.crtEnabled and UI.COLORS.btnPlay or UI.COLORS.btnNormal, font = UI.fonts.small }
    table.insert(buttons, btnCrt)
    UI.drawButton(btnCrt, mx >= btnCrt.x and mx <= btnCrt.x + btnCrt.w and my >= btnCrt.y and my <= btnCrt.y + btnCrt.h, juice.buttonPressedId == btnCrt.id)

    local row5Y = modalY + 312
    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Chế Độ Debug:", modalX + 35, row5Y + 6)
    local btnDebugToggle = { id = "setting_debug_toggle", text = settings.debugEnabled and "BẬT" or "TẮT", x = modalX + 300, y = row5Y, w = 150, h = 34, color = settings.debugEnabled and UI.COLORS.btnPlay or UI.COLORS.btnNormal, font = UI.fonts.small }
    buttons[#buttons + 1] = btnDebugToggle
    UI.drawButton(btnDebugToggle, mx >= btnDebugToggle.x and mx <= btnDebugToggle.x + btnDebugToggle.w and my >= btnDebugToggle.y and my <= btnDebugToggle.y + btnDebugToggle.h)
    if settings.debugEnabled then
        local btnDebugOpen = { id = "setting_debug_open", text = "MỞ BẢNG DEBUG", x = modalX + 150, y = modalY + 365, w = 200, h = 34, color = UI.COLORS.chipsBlue, font = UI.fonts.small }
        buttons[#buttons + 1] = btnDebugOpen
        UI.drawButton(btnDebugOpen, mx >= btnDebugOpen.x and mx <= btnDebugOpen.x + btnDebugOpen.w and my >= btnDebugOpen.y and my <= btnDebugOpen.y + btnDebugOpen.h)
    end

    -- Close Button
    local btnClose = { id = "close_settings", text = "LƯU & ĐÓNG", x = modalX + (modalW - 180) / 2, y = modalY + modalH - 52, w = 180, h = 40, color = UI.COLORS.btnPlay, font = UI.fonts.regular }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h, juice.buttonPressedId == btnClose.id)
end

local function drawShopState()
    local winW, winH = love.graphics.getDimensions()
    if battleArt.background then
        love.graphics.setColor(1, 1, 1, 1)
        local bw, bh = battleArt.background:getDimensions()
        love.graphics.draw(battleArt.background, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
    else
        love.graphics.setColor(UI.COLORS.felt)
        love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)
    end
    love.graphics.setColor(0.01, 0.03, 0.06, 0.76)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)

    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    local interestBonus = math.min(game.maxInterest or 5, math.floor((game.gold or 0) / 5))
    local hoveredShopItem = nil
    local hoveredItemPos = nil
    hoveredDeityTooltip = nil

    -- SPM and consumables live in a compact right-side rail.
    local deiCount = Deities.getCount(game.deities)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    local deiSlotW = 64
    local deiSlotH = 88
    local deiGap = 14
    local deiStartX = 1042
    local deiSlotY = 112

    UI.drawGildedPanel(deiStartX - 14, 73, 239, 248)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("SPM (" .. deiCount .. "/" .. maxDeiSlots .. ")", deiStartX + 4, 82)

    for i = 1, maxDeiSlots do
        local sx, sy, deiSlotW, deiSlotH = getDeitySlotRect(i, "shop")
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
            love.graphics.push()
            love.graphics.translate(sx + deiSlotW / 2, sy + deiSlotH / 2 + math.sin(((juice and juice.ambientTimer) or 0) * 1.15 + i * 0.72) * 2)
            love.graphics.rotate(math.sin(((juice and juice.ambientTimer) or 0) * 0.75 + i) * 0.008)
            love.graphics.translate(-sx - deiSlotW / 2, -sy - deiSlotH / 2)
            UI.drawPatronCard(d, sx, sy, deiSlotW, deiSlotH, isDeiHovered, juice.buttonPressedId == ("deity_" .. i), isDropTarget, copyTarget)
            love.graphics.pop()

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
    local conStartX = 1042
    local conSlotW = 64
    local conSlotH = 88
    local conGap = 14
    UI.drawGildedPanel(conStartX - 14, 318, 239, 145, { 0.45, 0.85, 0.65, 1 })

    game.consumables = game.consumables or {}
    local conCount = #game.consumables
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor({ 0.45, 0.85, 0.65, 1 })
    love.graphics.print("TIÊU HAO (" .. conCount .. "/3)", conStartX + 4, 327)

    for i = 1, 3 do
        local cx, cy = getConsumableSlotRect(i, "shop")
        local c = game.consumables[i]
        drawConsumableSlot(c, cx, cy, conSlotW, conSlotH, i, mx, my)
    end

    ----------------------------------------------------------------------------
    -- 3. MAIN SHOP BOARD (Upper: Cards On Sale | Lower: Voucher & Packs)
    ----------------------------------------------------------------------------
    -- Horizontal shop HUD and small navigation replace the former left column.
    UI.drawGildedPanel(14, 8, 1252, 56)
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("CỬA HÀNG", 30, 24)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.print("◉ " .. tostring(game.gold or 0) .. "   •   Lãi +" .. tostring(interestBonus), 260, 28)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Ải " .. tostring((game.run and game.run.ante) or game.act or 1) .. "   •   Sinh lực " .. tostring(game.playerHp or 0) .. "/" .. tostring(game.maxPlayerHp or 100), 530, 28)

    local shopX, shopY, shopW, shopH = 20, 76, 985, 560
    UI.drawGildedPanel(shopX, shopY, shopW, shopH)

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
        text = "ẢI TIẾP →",
        x = 45,
        y = 653,
        w = 146,
        h = 42,
        color = UI.COLORS.btnDestruct,
        font = UI.fonts.small,
    }
    table.insert(buttons, btnNextRound)
    UI.drawButton(btnNextRound, mx >= btnNextRound.x and mx <= btnNextRound.x + btnNextRound.w and my >= btnNextRound.y and my <= btnNextRound.y + btnNextRound.h, juice.buttonPressedId == btnNextRound.id)

    -- 2. [Gieo Lại] Button
    local rCost = shopData.rerollCost or 5
    local canReroll = (game.gold or 0) >= rCost
    local btnReroll = {
        id = "reroll",
        text = "ĐỔI HÀNG  ◉" .. rCost,
        x = 203,
        y = 653,
        w = 170,
        h = 42,
        color = canReroll and UI.COLORS.btnSpecial or UI.COLORS.btnNormal,
        font = UI.fonts.small,
        disabled = not canReroll,
    }
    table.insert(buttons, btnReroll)
    UI.drawButton(btnReroll, mx >= btnReroll.x and mx <= btnReroll.x + btnReroll.w and my >= btnReroll.y and my <= btnReroll.y + btnReroll.h, juice.buttonPressedId == btnReroll.id)

    for _, action in ipairs({
        { id = "open_shop_transfer", text = "HOÁN ĐỔI TRANG BỊ", x = 385, w = 208 },
        { id = "shop_round_info", text = "THÔNG TIN", x = 605, w = 130 },
        { id = "shop_options", text = "TÙY CHỌN", x = 747, w = 130 },
    }) do
        local btn = { id = action.id, text = action.text, x = action.x, y = 653, w = action.w, h = 42, color = UI.COLORS.btnNormal, font = UI.fonts.small }
        table.insert(buttons, btn)
        UI.drawButton(btn, mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
    end

    -- 3. Upper Cards On Sale
    local upperItems = {}
    for idx, it in ipairs(shopData.items or {}) do
        if it.section == "upper" or (not it.section and idx <= 3) then
            table.insert(upperItems, { item = it, globalIndex = idx })
        end
    end

    local cardStartX = upX + 44
    local cardW = 124
    local cardH = 186
    local cardGap = 26

    for cIdx, entry in ipairs(upperItems) do
        local it = entry.item
        local gIdx = entry.globalIndex
        local cx = cardStartX + (cIdx - 1) * (cardW + cardGap)
        local cy = upY + 36

        local idlePhase = juice.ambientTimer * 1.55 + gIdx * 1.31
        local idleY = math.sin(idlePhase) * 3.5
        local isCardHovered = (mx >= cx and mx <= cx + cardW and my >= cy + idleY and my <= cy + idleY + cardH)
        local drawY = isCardHovered and (cy - 14) or (cy + idleY)
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
            else
                love.graphics.rotate(math.sin(idlePhase * 0.72) * 0.009)
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

            local dImg = ((it.category == "deity" and it.deity) and UI.getDeityImage(it.deity.id))
                      or ((it.category == "equipment" and it.equipment) and UI.getEquipmentImage(it.equipment.id))
                      or ((it.category == "card" and it.card) and UI.getCardImage(it.card.suit, it.card.rank or it.card.rankName))
                      or ((it.category == "hand_expansion" or it.id == "v_hand_size" or it.id == "hand_expansion") and UI.getVoucherImage("v_hand_size"))
                      or ((it.category == "book" or it.category == "skill_book" or it.handId) and (UI.getHandImage(it.handId or it.id) or UI.getHandImage(it.id)))
                      or UI.getVoucherImage(it.id)
                      or UI.getHandImage(it.id)
            dImg = UI.visualImage(dImg)
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

                UI.drawItemEmblem(it, cardW / 2, 57, 23, cardColor)

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

        local idlePhase = juice.ambientTimer * 1.42 + gIdx * 1.17
        local idleY = math.sin(idlePhase) * 3
        local isVHovered = (mx >= vx and mx <= vx + vw and my >= vy + idleY and my <= vy + idleY + vh)
        local drawVY = isVHovered and (vy - 12) or (vy + idleY)
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
            else
                love.graphics.rotate(math.sin(idlePhase * 0.68) * 0.008)
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

            local bImg = (it.category == "book" or it.handId or (it.id and tostring(it.id):find("book_"))) and (UI.getHandImage(it.handId or it.id) or UI.getHandImage(it.id))
                      or ((it.category == "voucher" or it.voucherId or it.id) and (UI.getVoucherImage(it.voucherId or it.id) or UI.getHandImage(it.voucherId or it.id)))
            bImg = UI.visualImage(bImg)
            if bImg then
                love.graphics.setColor(1, 1, 1, 1)
                local biw, bih = bImg:getDimensions()
                love.graphics.draw(bImg, 0, 0, 0, vw / biw, vh / bih)
                if isVHovered then
                    love.graphics.setLineWidth(2.5)
                    love.graphics.setColor(UI.COLORS.goldYellow)
                    UI.drawRoundedRect("line", 0, 0, vw, vh, 8)
                end
            else
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
            end

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

        local idlePhase = juice.ambientTimer * 1.35 + gIdx * 1.43
        local idleY = math.sin(idlePhase) * 4
        local isPackHovered = (mx >= px and mx <= px + packW and my >= py + idleY and my <= py + idleY + packH)
        local drawPY = isPackHovered and (py - 12) or (py + idleY)
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
            else
                love.graphics.rotate(math.sin(idlePhase * 0.74) * 0.01)
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

            local packImg = battleArt.chest or UI.getPackImage(it.packType or it.id)
            if packImg then
                local packColor = it.color or UI.COLORS.goldYellow
                love.graphics.setColor(0.09, 0.15, 0.20, 0.97)
                UI.drawRoundedRect("fill", 0, 0, packW, packH, 8)
                love.graphics.setColor(packColor)
                UI.drawRoundedRect("line", 0, 0, packW, packH, 8)
                love.graphics.setColor(1, 1, 1, 1)
                local iw, ih = packImg:getDimensions()
                love.graphics.draw(packImg, 7, 24, 0, (packW - 14) / iw, 126 / ih)
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                love.graphics.printf(it.name or "Rương", 5, 158, packW - 10, "center")
                if isPackHovered then
                    love.graphics.setLineWidth(2.5)
                    love.graphics.setColor(UI.COLORS.goldYellow)
                    UI.drawRoundedRect("line", 0, 0, packW, packH, 8)
                end
            else
                -- Metallic Foil Pack Body Fallback
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
            end

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
        love.graphics.printf("Xem Toàn Bộ Bài", tipX, tipY + 9, tipW, "center")
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
        local dragImg = ((dItem.category == "deity" and dItem.deity) and UI.getDeityImage(dItem.deity.id))
                     or ((dItem.category == "equipment" and dItem.equipment) and UI.getEquipmentImage(dItem.equipment.id))
                     or ((dItem.category == "card" and dItem.card) and UI.getCardImage(dItem.card.suit, dItem.card.rank or dItem.card.rankName))
                     or ((dItem.category == "hand_expansion" or dItem.id == "v_hand_size" or dItem.id == "hand_expansion") and UI.getVoucherImage("v_hand_size"))
                     or ((dItem.category == "book" or dItem.handId or (dItem.id and tostring(dItem.id):find("book_"))) and (UI.getHandImage(dItem.handId or dItem.id) or UI.getHandImage(dItem.id)))
                     or UI.getVoucherImage(dItem.id)
                     or UI.getHandImage(dItem.id)
        dragImg = UI.visualImage(dragImg)
        if dragImg then
            love.graphics.setColor(1, 1, 1, 1)
            local iw, ih = dragImg:getDimensions()
            love.graphics.draw(dragImg, 0, 0, 0, dcw / iw, dch / ih)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.setLineWidth(2.5)
            UI.drawRoundedRect("line", 0, 0, dcw, dch, 8)
        else
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
        end

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

        local packImg = UI.getPackImage(pack.packType or pack.id)
        local timer = pData.animationTimer or 0
        if timer < 0.90 then
            local entrance = math.min(1, timer / 0.42)
            local eased = 1 - (1 - entrance) ^ 3
            local charge = math.max(0, (timer - 0.42) / 0.48)
            local shake = charge * math.sin(timer * 70) * 7
            local pulse = 0.70 + eased * 0.30 + math.sin(timer * 24) * 0.018 * charge
            local pw, ph = 184 * pulse, 248 * pulse
            local px, py = (V_WIDTH - pw) / 2 + shake, 500 + (150 - 500) * eased

            love.graphics.setBlendMode("add")
            for ring = 1, 3 do
                local radius = 75 + charge * (70 + ring * 26)
                love.graphics.setColor(1, 0.58 + ring * 0.08, 0.12, charge * (0.22 - ring * 0.035))
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", 640, 278, radius)
            end
            love.graphics.setLineWidth(1)
            love.graphics.setBlendMode("alpha")
            if packImg then
                love.graphics.setColor(0, 0, 0, 0.5)
                UI.drawRoundedRect("fill", px + 9, py + 15, pw, ph, 10)
                love.graphics.setColor(1, 1, 1, 1)
                local iw, ih = packImg:getDimensions()
                love.graphics.draw(packImg, px + pw / 2, py + ph / 2, shake * 0.002, pw / iw, ph / ih, iw / 2, ih / 2)
            end
            love.graphics.setBlendMode("add")
            for ray = 1, 20 do
                local angle = ray * math.pi * 2 / 20 + timer * 0.8
                local radius = 95 + charge * 190
                love.graphics.setColor(1, 0.72, 0.18, charge * 0.62)
                love.graphics.line(640 + math.cos(angle) * 62, 278 + math.sin(angle) * 82, 640 + math.cos(angle) * radius, 278 + math.sin(angle) * radius)
            end
            love.graphics.setBlendMode("alpha")
            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf(charge < 0.65 and (pack.name or "GÓI BÀI") or "XÉ NIÊM PHONG...", 0, 446, V_WIDTH, "center")
        else
            local flash = math.max(0, 1 - (timer - 0.90) / 0.22)
            if flash > 0 then
                love.graphics.setColor(1, 0.88, 0.55, flash * 0.55)
                love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
            end
            if packImg then
                local pw, ph = 64, 84
                local px, py = (V_WIDTH - pw) / 2, 26
                love.graphics.setColor(1, 1, 1, 1)
                local iw, ih = packImg:getDimensions()
                love.graphics.draw(packImg, px, py, 0, pw / iw, ph / ih)
                love.graphics.setColor(UI.COLORS.goldYellow)
                UI.drawRoundedRect("line", px, py, pw, ph, 4)
            end

            love.graphics.setFont(UI.fonts.large)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("MỞ " .. (pack.name or "GÓI BÀI") .. " — CHỌN 1 THẺ BÀI", 0, 120, V_WIDTH, "center")
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf("Mỗi lựa chọn đều hiển thị artwork và hiệu ứng trước khi nhận.", 0, 168, V_WIDTH, "center")

            local totalCardsW = #cards * 150 + (#cards - 1) * 32
            local startCardX = (V_WIDTH - totalCardsW) / 2
            local cardY, cW, cH = 210, 150, 260
            local labels = { buffoon = "HỘ LINH", standard = "QUÂN BÀI", arcana = "TRANG BỊ KHẢM", joker_edition = "PHÙ PHÉP", seal = "CON DẤU", spectral = "BIẾN ĐỔI", celestial = "HÀNH TINH" }

            for i, card in ipairs(cards) do
                local cx = startCardX + (i - 1) * (cW + 32)
                local reveal = math.max(0, math.min(1, (timer - 0.94 - (i - 1) * 0.14) / 0.46))
                local eased = 1 - (1 - reveal) ^ 3
                local flipX = math.max(0.035, math.sin(eased * math.pi / 2))
                local ready = reveal >= 0.99
                local isChoiceHovered = ready and mx >= cx and mx <= cx + cW and my >= cardY and my <= cardY + cH
                local idleY = ready and math.sin(juice.ambientTimer * 1.8 + i * 1.4) * 3 or 0
                local drawCY = isChoiceHovered and (cardY - 16) or (cardY + idleY + (1 - eased) * 75)

                love.graphics.push()
                love.graphics.translate(cx + cW / 2, drawCY + cH / 2)
                love.graphics.scale(flipX, 0.82 + eased * 0.18)
                love.graphics.rotate((1 - eased) * ((i - 2) * 0.24))
                love.graphics.translate(-cx - cW / 2, -drawCY - cH / 2)

                love.graphics.setColor(0.16, 0.20, 0.26, 0.98)
                UI.drawRoundedRect("fill", cx, drawCY, cW, cH, 10)
                love.graphics.setColor(isChoiceHovered and UI.COLORS.goldYellow or (card.color or { 0.45, 0.55, 0.70, 0.8 }))
                love.graphics.setLineWidth(isChoiceHovered and 3 or 1.5)
                UI.drawRoundedRect("line", cx, drawCY, cW, cH, 10)

                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(card.color or UI.COLORS.goldYellow)
                love.graphics.printf(labels[pack.packType] or "THẺ BÀI", cx + 4, drawCY + 9, cW - 8, "center")

                local art = UI.getPackCardImage(pack.packType, card)
                if art then
                    local iw, ih = art:getDimensions()
                    local artW, artH = 104, 104
                    local artScale = math.min(artW / iw, artH / ih)
                    local drawW, drawH = iw * artScale, ih * artScale
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(art, cx + (cW - drawW) / 2, drawCY + 28 + (artH - drawH) / 2, 0, artScale, artScale)
                end

                love.graphics.setFont(UI.fonts.small)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.printf(card.name or ((card.rankName or "") .. (card.suitSymbol or "")), cx + 6, drawCY + 138, cW - 12, "center")
                love.graphics.setFont(UI.fonts.tiny)
                love.graphics.setColor(UI.COLORS.textLight)
                local desc = card.desc or ("+" .. (card.baseChips or 0) .. " Chips • " .. (card.suitName or card.suitSymbol or ""))
                love.graphics.printf(desc, cx + 8, drawCY + 163, cW - 16, "center")

                local isConsumablePack = (pack.packType == "joker_edition" or pack.packType == "seal" or pack.packType == "spectral" or pack.packType == "celestial")
                if ready and isConsumablePack then
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
                elseif ready then
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
                love.graphics.pop()

                if reveal > 0 and reveal < 0.72 then
                    love.graphics.setBlendMode("add")
                    for spark = 1, 8 do
                        local a = spark * 2.41 + i
                        local radius = reveal * 52
                        love.graphics.setColor(1, 0.78, 0.22, (1 - reveal) * 0.8)
                        love.graphics.circle("fill", cx + cW / 2 + math.cos(a) * radius, drawCY + cH / 2 + math.sin(a) * radius, 2.5)
                    end
                    love.graphics.setBlendMode("alpha")
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
    end

    if isShopTransferOpen then
        drawShopTransferView()
    end

    if hoveredDeityTooltip then
        local copyTarget = hoveredDeityTooltip.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, hoveredDeityTooltip.slotIndex or 1)
        UI.drawPatronTooltip(hoveredDeityTooltip, mx, my, copyTarget)
    end
end

local DEBUG_CATEGORIES = { "jokers", "consumables", "vouchers", "enhancements", "seals", "editions", "packs", "other", "tags", "blinds", "decks" }
local DEBUG_SCREENS = {
    { id = "menu", text = "MENU" }, { id = "BLIND_SELECT", text = "CHỌN BLIND" },
    { id = "small", text = "ĐẤU TIỂU YÊU" }, { id = "big", text = "ĐẤU ĐẠI QUÁI" },
    { id = "boss", text = "ĐẤU BOSS" }, { id = "shop", text = "CỬA HÀNG" },
    { id = "rest", text = "NGHỈ NGƠI" }, { id = "treasure", text = "KHO BÁU" },
    { id = "event", text = "SỰ KIỆN" }, { id = "boss_deity", text = "CHỌN HỘ LINH" },
    { id = "chest", text = "RƯƠNG BOSS" }, { id = "map", text = "BẢN ĐỒ" },
    { id = "socketing", text = "KHẢM TRANG BỊ" }, { id = "CASH_OUT", text = "TRẢ THƯỞNG" },
    { id = "scoring", text = "TÍNH AURA" },
    { id = "gameover", text = "THUA CUỘC" }, { id = "victory", text = "CHIẾN THẮNG" },
}

local function drawDebugModal()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}
    local function add(id, label, x, y, w, h, color, font)
        local btn = { id = id, text = label, x = x, y = y, w = w, h = h, color = color or UI.COLORS.btnNormal, font = font or UI.fonts.small }
        buttons[#buttons + 1] = btn
        UI.drawButton(btn, mx >= x and mx <= x + w and my >= y and my <= y + h)
    end
    love.graphics.setColor(0, 0, 0, 0.86)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
    love.graphics.setColor(UI.COLORS.panelBg)
    UI.drawRoundedRect("fill", 55, 32, 1170, 652, 12)
    love.graphics.setColor(UI.COLORS.panelBorder)
    UI.drawRoundedRect("line", 55, 32, 1170, 652, 12)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("BẢNG DEBUG — KIỂM THỬ GAME", 80, 48)
    add("debug_close", "ĐÓNG", 1080, 48, 116, 36, UI.COLORS.btnDiscard)
    for i, tab in ipairs({ { "gold", "TIỀN" }, { "teleport", "DỊCH CHUYỂN" }, { "items", "BỘ SƯU TẬP" } }) do
        add("debug_tab_" .. tab[1], tab[2], 80 + (i - 1) * 190, 102, 176, 38,
            debugTab == tab[1] and UI.COLORS.btnPlay or UI.COLORS.btnNormal)
    end

    if debugTab == "gold" then
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.print("Vàng hiện tại: $" .. tostring(game.gold or 0), 110, 185)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.print("Nhập số vàng (tối đa 9 triệu tỷ), rồi chọn đặt hoặc cộng:", 110, 240)
        add("debug_focus_gold", (debugInputFocus == "gold" and "▸ " or "") .. debugGoldInput, 110, 280, 420, 52)
        add("debug_set_gold", "ĐẶT SỐ VÀNG", 560, 280, 220, 52, UI.COLORS.btnPlay)
        add("debug_add_gold", "CỘNG SỐ VÀNG", 800, 280, 220, 52, UI.COLORS.goldYellow)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Chế độ Debug chỉ nên dùng để kiểm thử. Tiến trình sau khi chỉnh sửa vẫn có thể được lưu.", 110, 390, 950, "left")
    elseif debugTab == "teleport" then
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.print("Ante muốn tới (1–999):", 90, 169)
        add("debug_focus_ante", (debugInputFocus == "ante" and "▸ " or "") .. debugAnteInput, 300, 156, 135, 38)
        add("debug_set_ante", "ÁP DỤNG ANTE", 455, 156, 170, 38, UI.COLORS.btnPlay)
        love.graphics.print("Chọn màn — trận đấu sẽ được khởi tạo đúng với Ante và loại Blind:", 90, 218)
        for i, screen in ipairs(DEBUG_SCREENS) do
            local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
            add("debug_screen_" .. screen.id, screen.text, 90 + col * 270, 255 + row * 78, 240, 55,
                UI.COLORS.btnNormal)
        end
    else
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.print("Chọn mục để nhận/dùng ngay. Hiệu ứng trên bài áp dụng cho lá đích bên dưới.", 80, 151)
        for i, catId in ipairs(DEBUG_CATEGORIES) do
            local cat = Collection.getCategoryById(catId)
            local col, row = (i - 1) % 6, math.floor((i - 1) / 6)
            add("debug_category_" .. catId, cat and cat.title or catId, 80 + col * 188, 178 + row * 40, 178, 34,
                debugCategory == catId and UI.COLORS.btnPlay or UI.COLORS.btnNormal, UI.fonts.tiny)
        end
        local deckCards = getAllDeckCards()
        debugTargetCardIndex = math.max(1, math.min(debugTargetCardIndex, #deckCards))
        local target = deckCards[debugTargetCardIndex]
        add("debug_target_prev", "‹", 80, 270, 38, 32)
        add("debug_target_next", "›", 574, 270, 38, 32)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Lá đích " .. debugTargetCardIndex .. "/" .. #deckCards .. ": " .. (target and ((target.rankName or "") .. (target.suitSymbol or "")) or "trống"), 126, 277, 440, "center")
        local items = Collection.getItems(debugCategory)
        local perPage = 12
        local totalPages = math.max(1, math.ceil(#items / perPage))
        debugItemPage = math.max(1, math.min(debugItemPage, totalPages))
        for slot = 1, perPage do
            local itemIndex = (debugItemPage - 1) * perPage + slot
            local item = items[itemIndex]
            if item then
                local col, row = (slot - 1) % 2, math.floor((slot - 1) / 2)
                add("debug_grant_" .. itemIndex, item.name, 80 + col * 570, 318 + row * 46, 540, 38,
                    UI.COLORS.btnNormal, UI.fonts.small)
            end
        end
        add("debug_items_prev", "‹", 400, 604, 48, 36)
        add("debug_items_next", "›", 714, 604, 48, 36)
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Trang " .. debugItemPage .. "/" .. totalPages .. " • " .. #items .. " mục", 462, 612, 238, "center")
    end
    if debugMessage then
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(debugMessage, 80, 652, 1120, "center")
    end
end

local TRANSFER_PER_PAGE = 16

local function getTransferPageCards()
    local allCards = getAllDeckCards()
    local totalPages = math.max(1, math.ceil(#allCards / TRANSFER_PER_PAGE))
    transferPage = math.max(1, math.min(transferPage, totalPages))
    local first = (transferPage - 1) * TRANSFER_PER_PAGE + 1
    local visible = {}
    for i = first, math.min(#allCards, first + TRANSFER_PER_PAGE - 1) do
        visible[#visible + 1] = allCards[i]
    end
    return visible, totalPages, #allCards
end

local function getTransferCardRect(index)
    local cw, ch, gap, cols = 70, 102, 14, 8
    local gridW = cols * cw + (cols - 1) * gap
    local x = (V_WIDTH - gridW) / 2 + ((index - 1) % cols) * (cw + gap)
    local y = 128 + math.floor((index - 1) / cols) * 132
    return x, y, cw, ch
end

local function getTransferEquipmentRect(index)
    return 250 + (index - 1) * 275, 430, 255, 76
end

drawShopTransferView = function()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0.06, 0.08, 0.11, 1)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / scale, winW / scale, winH / scale)
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("HOÁN ĐỔI TRANG BỊ", 0, 22, V_WIDTH, "center")
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Chọn lá nguồn • chọn trang bị • chọn lá đích", 0, 58, V_WIDTH, "center")

    local visible, totalPages, totalCards = getTransferPageCards()
    local chosenEq = transferSourceCard and transferSourceEqIndex and transferSourceCard.equipments and transferSourceCard.equipments[transferSourceEqIndex]
    local stepText = not transferSourceCard and "1  CHỌN LÁ ĐANG MANG TRANG BỊ"
        or not chosenEq and ("2  CHỌN TRANG BỊ TỪ " .. (transferSourceCard.rankName or "") .. (transferSourceCard.suitSymbol or ""))
        or ("3  CHỌN LÁ ĐÍCH CHO " .. chosenEq.name)
    love.graphics.setColor(0.12, 0.16, 0.21, 0.96)
    UI.drawRoundedRect("fill", 210, 88, V_WIDTH - 420, 28, 7)
    love.graphics.setColor(chosenEq and UI.COLORS.hpGreen or UI.COLORS.chipsBlue)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.printf(stepText, 220, 96, V_WIDTH - 440, "center")

    for i, card in ipairs(visible) do
        local x, y, w, h = getTransferCardRect(i)
        local hovered = mx >= x and mx <= x + w and my >= y and my <= y + h
        local isSource = card == transferSourceCard
        local canReceive = false
        if chosenEq and not isSource then canReceive = Equipment.canAttach(card, chosenEq) end
        local float = math.sin((juice and juice.ambientTimer or 0) * 1.2 + i * 0.55) * 1.5
        love.graphics.push()
        love.graphics.translate(0, float - (hovered and 5 or 0))
        card.hovered = hovered
        UI.drawCard(card, x, y, w, h)
        love.graphics.pop()

        love.graphics.setLineWidth(isSource and 3 or 2)
        if isSource then
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", x - 3, y - 3, w + 6, h + 6, 8)
        elseif chosenEq then
            love.graphics.setColor(canReceive and UI.COLORS.hpGreen or { 0.65, 0.18, 0.20, 0.8 })
            UI.drawRoundedRect("line", x - 2, y - 2, w + 4, h + 4, 8)
        end
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(Equipment.getUsedSlots(card) > 0 and UI.COLORS.chipsBlue or UI.COLORS.textMuted)
        love.graphics.printf(Equipment.getUsedSlots(card) .. "/" .. Equipment.MAX_SLOTS .. " hốc", x, y + h + 5, w, "center")
    end

    local prev = { id = "transfer_prev", text = "‹", x = 450, y = 386, w = 42, h = 30, color = UI.COLORS.btnNormal, font = UI.fonts.medium, disabled = transferPage <= 1 }
    local next = { id = "transfer_next", text = "›", x = 788, y = 386, w = 42, h = 30, color = UI.COLORS.btnNormal, font = UI.fonts.medium, disabled = transferPage >= totalPages }
    buttons[#buttons + 1] = prev
    buttons[#buttons + 1] = next
    UI.drawButton(prev, not prev.disabled and mx >= prev.x and mx <= prev.x + prev.w and my >= prev.y and my <= prev.y + prev.h)
    UI.drawButton(next, not next.disabled and mx >= next.x and mx <= next.x + next.w and my >= next.y and my <= next.y + next.h)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Trang " .. transferPage .. "/" .. totalPages .. "  •  " .. totalCards .. " lá", 500, 394, 280, "center")

    if transferSourceCard then
        for index, eq in ipairs(transferSourceCard.equipments or {}) do
            local x, y, w, h = getTransferEquipmentRect(index)
            local selected = index == transferSourceEqIndex
            love.graphics.setColor(selected and { 0.20, 0.32, 0.29, 1 } or { 0.13, 0.17, 0.22, 1 })
            UI.drawRoundedRect("fill", x, y, w, h, 8)
            love.graphics.setLineWidth(selected and 3 or 1.5)
            love.graphics.setColor(selected and UI.COLORS.hpGreen or (eq.color or UI.COLORS.panelBorder))
            UI.drawRoundedRect("line", x, y, w, h, 8)
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(eq.color or UI.COLORS.goldYellow)
            love.graphics.print(eq.name, x + 12, y + 9)
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textLight)
            love.graphics.printf(eq.desc or "", x + 12, y + 33, w - 24, "left")
        end
    else
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Các lá không có trang bị vẫn được hiển thị để làm đích nhận.", 0, 453, V_WIDTH, "center")
    end

    if transferMessage then
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf(transferMessage, 160, 535, V_WIDTH - 320, "center")
    end

    local reset = { id = "transfer_reset", text = "CHỌN LẠI NGUỒN", x = 250, y = 615, w = 230, h = 44, color = UI.COLORS.btnNormal, font = UI.fonts.small }
    local close = { id = "close_shop_transfer", text = "XONG / VỀ CỬA HÀNG", x = V_WIDTH - 480, y = 615, w = 230, h = 44, color = UI.COLORS.btnPlay, font = UI.fonts.small }
    buttons[#buttons + 1] = reset
    buttons[#buttons + 1] = close
    UI.drawButton(reset, mx >= reset.x and mx <= reset.x + reset.w and my >= reset.y and my <= reset.y + reset.h)
    UI.drawButton(close, mx >= close.x and mx <= close.x + close.w and my >= close.y and my <= close.y + close.h)
end

local function drawShopFx()
    for _, fx in ipairs(shopFx) do
        local p = math.min(1, fx.life / fx.duration)
        local item = fx.item or {}
        local travel = 1 - (1 - p) ^ 3
        local x = fx.x + ((fx.targetX or fx.x) - fx.x) * travel
        local y = fx.y + ((fx.targetY or fx.y) - fx.y) * travel - math.sin(p * math.pi) * (fx.kind == "sell" and 55 or 92)
        local pop = math.sin(math.min(1, p / 0.24) * math.pi) * 0.16
        local size = fx.kind == "destroy" and math.max(0.06, 1 + pop - p * 0.96)
            or (fx.kind == "sell" and math.max(0.12, 1 + pop - p * 0.82) or math.max(0.42, 1 + pop - travel * 0.48))
        local w, h = 92, 130

        love.graphics.setBlendMode("add")
        love.graphics.setLineWidth(4)
        local trailColor = (fx.kind == "sell" or fx.kind == "destroy") and { 1, 0.28, 0.08 } or { 1, 0.82, 0.22 }
        love.graphics.setColor(trailColor[1], trailColor[2], trailColor[3], (1 - p) * 0.34)
        love.graphics.line(fx.x, fx.y, x, y)
        love.graphics.setLineWidth(1)
        love.graphics.setBlendMode("alpha")

        love.graphics.push()
        love.graphics.translate(x, y)
        local spin = fx.kind == "destroy" and 1.55 or (fx.kind == "sell" and -1.05 or 0.24)
        love.graphics.rotate(spin * p + math.sin(p * math.pi) * 0.08)
        love.graphics.scale(size, size)
        if item.category == "deity" or item.id and Deities.CATALOG[item.id] then
            UI.drawPatronCard(item.deity or item, -w / 2, -h / 2, w, h, false, false, false)
        elseif item.category == "card" or item.rank then
            UI.drawCard(item.card or item, -w / 2, -h / 2, w, h)
        else
            love.graphics.setColor(0.12, 0.16, 0.22, 0.98)
            UI.drawRoundedRect("fill", -w / 2, -h / 2, w, h, 8)
            local art = item.packType and UI.getPackCardImage(item.packType, item.reward or item)
                or (item.category == "equipment" and UI.getEquipmentImage(item.equipment and item.equipment.id or item.id))
                or (item.category == "pack" and UI.getPackImage(item.packType))
                or (item.category == "book" and UI.getHandImage(item.handId))
                or ((item.category == "voucher" or item.category == "hand_expansion") and UI.getVoucherImage(item.voucherId or item.category))
            if not item.packType and item.category ~= "pack" then art = UI.visualImage(art) end
            if art then
                local iw, ih = art:getDimensions()
                local s = math.min(76 / iw, 82 / ih)
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(art, -iw * s / 2, -50, 0, s, s)
            end
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf(item.name or (item.reward and item.reward.name) or "VẬT PHẨM", -w / 2 + 4, 38, w - 8, "center")
        end
        love.graphics.pop()

        love.graphics.setBlendMode("add")
        for i = 1, 12 do
            local angle = i * 2.17
            local radius = p * (20 + i * 2.4)
            local color = (fx.kind == "sell" or fx.kind == "destroy") and { 1, 0.22, 0.08 } or { 1, 0.82, 0.22 }
            love.graphics.setColor(color[1], color[2], color[3], 1 - p)
            love.graphics.rectangle("fill", x + math.cos(angle) * radius, y + math.sin(angle) * radius, 3, 3)
        end
        love.graphics.setBlendMode("alpha")

        if fx.kind == "sell" and p > 0.58 then
            local coinP = (p - 0.58) / 0.42
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 1 - coinP * 0.35)
            local sellPrice = math.max(1, math.floor((item.cost or 4) / 2))
            love.graphics.printf("+$" .. sellPrice, x - 40, y - 30 - coinP * 18, 80, "center")
        end
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

    -- A single restrained environment replaces the old shifting neon backdrop.
    if battleArt.background then
        local bw, bh = battleArt.background:getDimensions()
        love.graphics.setColor(0.48, 0.55, 0.56, 1)
        love.graphics.draw(battleArt.background, 0, 0, 0, V_WIDTH / bw, V_HEIGHT / bh)
        love.graphics.setColor(0.02, 0.04, 0.05, 0.56)
        love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
    else
        love.graphics.setColor(UI.COLORS.bg)
        love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
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

    drawShopFx()

    if isDeckViewerOpen then
        drawDeckViewerModal()
    end

    if isHandbookOpen then
        drawHandbookModal()
    end

    if inspectCardModal then
        drawCardInspectorModal(inspectCardModal)
    end

    if isPauseMenuOpen then
        drawPauseMenuModal()
    end

    if isSettingsOpen then
        drawSettingsModal()
    end

    if isCollectionOpen then
        if collectionCategory then
            drawCollectionDetailView()
        else
            drawCollectionModal()
        end
    end

    -- In-game sleek Pause / Menu button at top right
    if state ~= "menu" and not isPauseMenuOpen and not isSettingsOpen and not isDebugOpen and not isDeckViewerOpen and not isHandbookOpen and not inspectCardModal and not isCollectionOpen and not isShopTransferOpen then
        local mx, my = toVirtual(love.mouse.getPosition())
        local btnMenu = {
            id = "open_pause_menu",
            text = "TÙY CHỌN",
            x = 1142,
            y = 18,
            w = 108,
            h = 34,
            color = UI.COLORS.panelBg,
            font = UI.fonts.small,
            assetId = "btn_top_tuy_chon_active",
            activeAssetId = "btn_top_tuy_chon_active",
        }
        table.insert(buttons, btnMenu)
        local isH = (mx >= btnMenu.x and mx <= btnMenu.x + btnMenu.w and my >= btnMenu.y and my <= btnMenu.y + btnMenu.h)
        UI.drawButton(btnMenu, isH, juice.buttonPressedId == btnMenu.id)
    end

    if isDebugOpen then
        drawDebugModal()
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
            if crtShader:hasUniform("u_curvature") then crtShader:send("u_curvature", 0.002) end
            if crtShader:hasUniform("u_chroma") then crtShader:send("u_chroma", 0.0003) end
            if crtShader:hasUniform("u_scanlines") then crtShader:send("u_scanlines", 0.035) end
            if crtShader:hasUniform("u_vignette") then crtShader:send("u_vignette", 0.04) end
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
            elseif btn.id == "open_settings" then
                isSettingsOpen = true
                Sound.play("ui_click")
                return true
            elseif btn.id:sub(1, 15) == "use_consumable_" then
                if useConsumable(btn.consumableIndex) then Sound.play("consume") end
                return true
            end
        end
    end

    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5

    -- Check Consumable slots (clicking anywhere on the slot card in combat/blind)
    for j = 1, 3 do
        local cx, cy, cw, ch = getConsumableSlotRect(j, "playing")
        if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
            if game.consumables and game.consumables[j] then
                if useConsumable(j) then Sound.play("consume") end
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
                    transferPage = 1
                    Sound.play("card_deal")
                    return true
                elseif btn.id == "transfer_prev" and not btn.disabled then
                    transferPage = math.max(1, transferPage - 1)
                    Sound.play("card_select")
                    return true
                elseif btn.id == "transfer_next" and not btn.disabled then
                    transferPage = transferPage + 1
                    Sound.play("card_select")
                    return true
                elseif btn.id == "transfer_reset" then
                    transferSourceCard = nil
                    transferSourceEqIndex = nil
                    transferMessage = nil
                    Sound.play("card_select")
                    return true
                end
            end
        end

        local visible = getTransferPageCards()
        if transferSourceCard and transferSourceCard.equipments then
            for idx, eq in ipairs(transferSourceCard.equipments) do
                local ex, ey, ew, eh = getTransferEquipmentRect(idx)
                if mx >= ex and mx <= ex + ew and my >= ey and my <= ey + eh then
                    transferSourceEqIndex = idx
                    transferMessage = nil
                    Sound.play("card_select")
                    return true
                end
            end
        end

        local chosenEq = transferSourceCard and transferSourceEqIndex and transferSourceCard.equipments and transferSourceCard.equipments[transferSourceEqIndex]
        for i, c in ipairs(visible) do
            local cx, cy, cw, ch = getTransferCardRect(i)
            if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
                if chosenEq and c ~= transferSourceCard then
                    local canAttach, reason = Equipment.canAttach(c, chosenEq)
                    if not canAttach then
                        transferMessage = reason
                        Sound.play("cant_afford")
                        return true
                    end
                    local ok, msg = Shop.transferEquipment(transferSourceCard, transferSourceEqIndex, c)
                    transferMessage = msg
                    if ok then
                        transferSourceEqIndex = nil
                    end
                    return true
                elseif c.equipments and #c.equipments > 0 then
                    transferSourceCard = c
                    transferSourceEqIndex = nil
                    transferMessage = nil
                    Sound.play("card_select")
                    return true
                else
                    transferMessage = "Lá này chưa có trang bị; hãy chọn làm đích sau khi chọn trang bị nguồn."
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
                    local opening = shopData.currentPackOpening
                    local reward = opening.cards and opening.cards[btn.cardIndex]
                    local ok, action, eq = Shop.choosePackCard(shopData, btn.cardIndex, game)
                    if ok then
                        spawnShopFx("buy", { packType = opening.pack.packType, reward = reward, name = reward and reward.name }, btn.x + btn.w / 2, btn.y)
                    end
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
                    local opening = shopData.currentPackOpening
                    local reward = opening.cards and opening.cards[btn.cardIndex]
                    local ok, msg = Shop.keepPackCard(shopData, btn.cardIndex, game)
                    if ok then
                        spawnShopFx("buy", { packType = opening.pack.packType, reward = reward, name = reward and reward.name }, btn.x + btn.w / 2, btn.y)
                    end
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
                    local skippedPack = shopData.currentPackOpening.pack
                    Shop.skipPack(shopData)
                    spawnShopFx("sell", { category = "pack", packType = skippedPack.packType, name = skippedPack.name }, btn.x + btn.w / 2, btn.y)
                    return true
                end
            end
        end
        return true
    end

    -- Check Consumable slots (clicking anywhere on the slot card in shop)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    for j = 1, 3 do
        local cx, cy, cw, ch = getConsumableSlotRect(j, "shop")
        if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
            if game.consumables and game.consumables[j] then
                if useConsumable(j) then Sound.play("consume") end
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
                    deityDrag.cardW = btn.w
                    deityDrag.cardH = btn.h
                    deityDrag.offsetX = btn.x - mx
                    deityDrag.offsetY = btn.y - my
                    deityDrag.visualX = btn.x
                    deityDrag.visualY = btn.y
                    return true
                end
            elseif btn.id:sub(1, 5) == "sell_" then
                local sold = game.deities and game.deities[btn.deityIndex]
                if Shop.sellDeity(game, btn.deityIndex) then
                    spawnShopFx("sell", sold, btn.x + btn.w / 2, btn.y - 42)
                end
                return true
            elseif btn.id:sub(1, 15) == "use_consumable_" then
                if useConsumable(btn.consumableIndex) then Sound.play("consume") end
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

local function debugTeleport(screenId)
    if not hasRunStarted and screenId ~= "menu" then startNewGame("red_deck") end
    local blindIndex = screenId == "big" and 2 or (screenId == "boss" and 3 or 1)
    local ok, message = DebugTools.setAnte(game, debugAnteInput, blindIndex)
    if not ok then debugMessage = message return end
    pendingCombatNode = nil
    isShopTransferOpen = false
    isDeckViewerOpen = false
    inspectCardModal = nil
    isDebugOpen = false
    isSettingsOpen = false
    isPauseMenuOpen = false
    if screenId == "small" or screenId == "big" or screenId == "boss" then
        startBlindCombat(RunManager.getCurrentBlind(game.run))
    elseif screenId == "shop" then
        Shop.resetReroll(shopData)
        Shop.refresh(shopData, game)
        state = "shop"
    elseif screenId == "rest" then
        restStateData = { chosenAction = nil, selectedCard = nil, message = nil }
        state = "rest"
    elseif screenId == "treasure" then
        generateTreasureRewards()
        state = "treasure"
    elseif screenId == "event" then
        game.currentEvent = Events.getRandomEvent(game)
        game.eventOutcomeText = nil
        state = "event"
    elseif screenId == "boss_deity" then
        game.bossDeityDraft = Deities.getBossDraftPool(game.deities, 2)
        state = "boss_deity"
    elseif screenId == "chest" then
        generateBossChestRewards()
        socketingReturnState = "shop"
        state = "chest"
    elseif screenId == "map" then
        game.map = Map.generate(game.act or 1)
        state = "map"
    elseif screenId == "socketing" then
        pendingEquipment = Equipment.ITEMS[Equipment.POOL[1]]
        socketingReturnState = "shop"
        state = "socketing"
    elseif screenId == "CASH_OUT" then
        local blind = RunManager.getCurrentBlind(game.run)
        local breakdown = RewardSystem.calculate(blind, game, false)
        RunManager.completeCurrentBlind(game.run)
        game.gold = (game.gold or 0) + breakdown.totalGold
        cashOutAnim = RewardSystem.newAnimation(breakdown)
        state = "CASH_OUT"
    elseif screenId == "scoring" then
        startBlindCombat(RunManager.getCurrentBlind(game.run))
        toggleCardSelection(1)
        playSelectedHand()
    else
        state = screenId
    end
    if state ~= "menu" then lastActiveState = state end
    saveRunAtSafePoint()
    Sound.play("card_deal")
end

local function handleDebugMousepressed(mx, my, button)
    if button ~= 1 then return true end
    for _, btn in ipairs(buttons) do
        if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            local id = btn.id
            if id == "debug_close" then
                isDebugOpen = false
                isSettingsOpen = true
            elseif id:sub(1, 10) == "debug_tab_" then
                debugTab = id:sub(11)
                debugInputFocus = nil
                debugMessage = nil
            elseif id == "debug_focus_gold" then
                if debugInputFocus ~= "gold" then debugGoldInput = "" end
                debugInputFocus = "gold"
            elseif id == "debug_set_gold" or id == "debug_add_gold" then
                local ok, message = id == "debug_set_gold" and DebugTools.setGold(game, debugGoldInput)
                    or DebugTools.addGold(game, debugGoldInput)
                debugMessage = message
                if ok then saveRunAtSafePoint() end
            elseif id == "debug_focus_ante" then
                if debugInputFocus ~= "ante" then debugAnteInput = "" end
                debugInputFocus = "ante"
            elseif id == "debug_set_ante" then
                if not hasRunStarted then startNewGame("red_deck") end
                local ok, message = DebugTools.setAnte(game, debugAnteInput, 1)
                debugMessage = message
                if ok then
                    state = "BLIND_SELECT"
                    lastActiveState = state
                    saveRunAtSafePoint()
                end
            elseif id:sub(1, 13) == "debug_screen_" then
                debugTeleport(id:sub(14))
            elseif id:sub(1, 15) == "debug_category_" then
                debugCategory = id:sub(16)
                debugItemPage = 1
                debugMessage = nil
            elseif id == "debug_target_prev" then
                debugTargetCardIndex = math.max(1, debugTargetCardIndex - 1)
            elseif id == "debug_target_next" then
                debugTargetCardIndex = math.min(#getAllDeckCards(), debugTargetCardIndex + 1)
            elseif id == "debug_items_prev" then
                debugItemPage = math.max(1, debugItemPage - 1)
            elseif id == "debug_items_next" then
                debugItemPage = debugItemPage + 1
            elseif id:sub(1, 12) == "debug_grant_" then
                if not hasRunStarted then startNewGame("red_deck") end
                local item = Collection.getItems(debugCategory)[tonumber(id:sub(13))]
                local target = getAllDeckCards()[debugTargetCardIndex]
                local ok, result, payload = DebugTools.grantCollectionItem(game, shopData, debugCategory, item, target)
                debugMessage = result
                if ok and result == "socketing" and payload then
                    pendingEquipment = payload
                    socketingReturnState = state == "menu" and "map" or state
                    if socketingReturnState ~= "shop" and socketingReturnState ~= "map" then socketingReturnState = "shop" end
                    state = "socketing"
                    isDebugOpen = false
                    isSettingsOpen = false
                    isPauseMenuOpen = false
                elseif ok and result == "pack" then
                    Shop.resetReroll(shopData)
                    Shop.refresh(shopData, game)
                    shopData.currentPackOpening = Shop.openPack({ packType = payload or item.packType, name = item.name }, game)
                    state = "shop"
                    isDebugOpen = false
                    isSettingsOpen = false
                    isPauseMenuOpen = false
                elseif ok and result == "blind" then
                    local targetScreen = payload == "blind_small" and "small" or (payload == "blind_big" and "big" or "boss")
                    debugTeleport(targetScreen)
                    if targetScreen == "boss" and RunManager.BOSS_DEBUFFS[payload] then
                        local blind = RunManager.getCurrentBlind(game.run)
                        blind.debuff = RunManager.BOSS_DEBUFFS[payload]
                        blind.name = blind.debuff.name
                        startBlindCombat(blind)
                    end
                elseif ok then
                    saveRunAtSafePoint()
                end
            end
            Sound.play("ui_click")
            return true
        end
    end
    return true
end

local function handleModalsMousepressed(mx, my, button)
    if isDebugOpen then return handleDebugMousepressed(mx, my, button) end
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
                    elseif btn.id == "setting_debug_toggle" then
                        settings.debugEnabled = not settings.debugEnabled
                        if not settings.debugEnabled then isDebugOpen = false end
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_debug_open" and settings.debugEnabled then
                        debugAnteInput = tostring(game.run and game.run.ante or 1)
                        debugMessage = nil
                        isDebugOpen = true
                        isSettingsOpen = false
                        Sound.play("ui_click")
                        return true
                    end
                end
            end
            local modalW = 500
            local modalH = 515
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

    -- Transfer owns the full shop screen, so its cards and controls take
    -- priority over generic inspector and drag input.
    if state == "shop" and isShopTransferOpen and not isDeckViewerOpen then
        return handleShopMousepressed(mx, my, button)
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
            local card = getDeckViewerCardAt(mx, my, modalX, modalY)
            if card then
                inspectCardModal = card
                Sound.play("card_deal")
                return true
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
                deckViewerPage = 1
                Sound.play("card_deal")
                return true
            end
        end

        if mx >= modalX + 570 and mx <= modalX + 604 and my >= modalY + 50 and my <= modalY + 76 then
            deckViewerPage = math.max(1, deckViewerPage - 1)
            Sound.play("card_slide")
            return true
        elseif mx >= modalX + 654 and mx <= modalX + 688 and my >= modalY + 50 and my <= modalY + 76 then
            local pages = math.max(1, math.ceil(#getDeckViewerFilteredCards() / 32))
            deckViewerPage = math.min(pages, deckViewerPage + 1)
            Sound.play("card_slide")
            return true
        end

        local card = getDeckViewerCardAt(mx, my, modalX, modalY)
        if card then
            inspectCardModal = card
            Sound.play("card_deal")
            return true
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
                elseif btn.id == "open_options" or btn.id == "open_settings" then
                    isSettingsOpen = true
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
                            if not shopData then shopData = Shop.new() end
                            Shop.resetReroll(shopData)
                            Shop.refresh(shopData, game)
                            state = "shop"
                            lastActiveState = "shop"
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
                    Sound.play("equip")
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
    if isDebugOpen then
        if key == "escape" then
            isDebugOpen = false
            isSettingsOpen = true
        elseif key == "backspace" and debugInputFocus == "gold" then
            debugGoldInput = debugGoldInput:sub(1, -2)
        elseif key == "backspace" and debugInputFocus == "ante" then
            debugAnteInput = debugAnteInput:sub(1, -2)
        elseif key == "return" or key == "kpenter" then
            debugInputFocus = nil
        end
        return
    end
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
                if not shopData then shopData = Shop.new() end
                Shop.resetReroll(shopData)
                Shop.refresh(shopData, game)
                state = "shop"
                lastActiveState = "shop"
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

function love.textinput(text)
    if not isDebugOpen or not debugInputFocus then return end
    local digits = text:gsub("%D", "")
    if debugInputFocus == "gold" then
        debugGoldInput = (debugGoldInput .. digits):sub(1, 16)
    elseif debugInputFocus == "ante" then
        debugAnteInput = (debugAnteInput .. digits):sub(1, 3)
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
            local nearest, nearestDistance = handDrag.cardIndex, math.huge
            for slot = 1, #game.hand do
                local slotX, _, slotW = getHandCardPosition(slot, #game.hand)
                local distance = math.abs(mx - (slotX + slotW / 2))
                if distance < nearestDistance then
                    nearest, nearestDistance = slot, distance
                end
            end
            local selectedCards = {}
            for _, card in ipairs(game.hand) do
                if card.selected then selectedCards[card] = true end
            end
            if nearest ~= handDrag.cardIndex and Deck.moveCard(game.hand, handDrag.cardIndex, nearest) then
                handDrag.cardIndex = nearest
                game.selectedIndices = {}
                for index, card in ipairs(game.hand) do
                    if selectedCards[card] then table.insert(game.selectedIndices, index) end
                end
                Sound.play("card_slide", 0.96 + nearest * 0.015)
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
                card.selectPulse = 1
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
            local boughtItem = shopDrag.item
            local success, msg, eq = Shop.buyItem(shopData, shopDrag.itemIndex, game)
            if success then
                spawnShopFx("buy", boughtItem, shopDrag.origX + shopDrag.cardW / 2, shopDrag.origY + shopDrag.cardH / 2)
            end
            if success and msg == "open_socketing" and eq then
                pendingEquipment = eq
                socketingReturnState = "shop"
                state = "socketing"
            end
        elseif shopDrag.isDragging and shopDrag.item then
            if my < 380 or my < (shopDrag.origY - 40) then
                if (game.gold or 0) >= (shopDrag.item.cost or 0) then
                    local boughtItem = shopDrag.item
                    local success, msg, eq = Shop.buyItem(shopData, shopDrag.itemIndex, game)
                    if success then
                        spawnShopFx("buy", boughtItem, mx, my)
                    end
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

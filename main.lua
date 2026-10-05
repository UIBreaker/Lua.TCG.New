local cardEffectsSmokeMode = false
for _, a in ipairs(arg or {}) do
    if a == "--test-editions-render" then require("tests.edition_preview.main"); return end
    if a == "--test-feature-parity" then
        require("tests.inventory_expansion_smoke")
        require("tests.bed_speed_smoke")
        require("tests.soul_shop_smoke")
        require("tests.spectral_persistence_smoke")
        os.exit(0)
    end
    if a == "--test-mobile-layout" then require("tests.mobile_layout_smoke"); os.exit(0) end
    if a == "--test-touch" then
        require("tests.touch_input_smoke")
        os.exit(0)
    end
    if a == "--test-card-effects" then
        -- Defer graphics/shader testing until love.load has a live graphics context.
        cardEffectsSmokeMode = true
    end
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
local Touch = require("src.touch_input")
local Poker = require("src.poker")
local Deities = require("src.deities")
local Scoring = require("src.scoring")
local CardEffects = require("src.card_effects")
local Shop = require("src.shop")
local Sound = require("src.sound")
local UI = require("src.ui")
UI.Inventory=require("src.inventory")
UI.InventoryRail=require("ui.inventory_rail")
local Motion = require("src.motion")
local Theme = require("ui.theme")
local Renderer = require("render.renderer")
local DeathVFX = require("src.death_vfx")
local EnemyArt = require("src.enemy_art")
local EnemyGroup = require("src.enemy_group")
local EnemyFormation = require("ui.enemy_formation")
require("src.expedition")
local ExpeditionSelect = require("ui.expedition_select")
UI.ChestChoices = require("ui.chest_choices")
local Layout = require("ui.layout")
local Gallery = require("ui.gallery")
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
UI.BedExplosion = require("src.bed_explosion")
local EnemyAttack = require("src.enemy_attack_presentation")
local Feedback = require("src.combat_feedback")

io.stdout:setvbuf("no")
local isCaptureMode = false
local chestAnimationCaptureMode = false
for _, a in ipairs(arg or {}) do
    if a == "--test-chest-expansion" then
        function love.load() require("tests.chest_expansion_render").run() end
        function love.errorhandler(message)
            print(debug.traceback(message,2));return function() return 1 end
        end
        return
    end
    if a == "--test-animation" then isCaptureMode = true end
    if a == "--test-hand-drag-select" then isCaptureMode = true end
    if a == "--test-expedition" then isCaptureMode = true end
    if a == "--test-soul-shop" then isCaptureMode = true end
    if a == "--test-bed-explosion" then isCaptureMode = true end
    if a == "--test-bed-speed" then isCaptureMode = true end
    if a == "--test-enemy-attacks" then isCaptureMode = true end
    if a == "--test-enemy-groups" then isCaptureMode = true end
    if a == "--test-evolution-ui" then isCaptureMode = true end
    if a == "--test-shop-chest" then isCaptureMode = true end
    if a == "--test-consumable-art" then isCaptureMode = true end
    if a == "--test-illustrated-art" then isCaptureMode = true end
    if a == "--test-chest-vfx" then isCaptureMode = true; chestAnimationCaptureMode = true end
    if a == "--test-death-vfx" then isCaptureMode = true end
    if a == "--test-weather" then isCaptureMode = true end
    if a == "--test-combat-feedback" or a == "--test-action-vfx" or a == "--test-action-vfx-juice" then isCaptureMode = true end
    if a == "--test-hand-vfx-combat" or a == "--test-hand-vfx" or a == "--test-hd2d" or a == "--test-card-back-crop" or a == "--test-ux-polish" or a == "--test-reward-ceremony" or a == "--capture" or a == "--capture-shop" or a == "--test-pack-skip" or a == "--test-card-physics" or a == "--test-scoring-feel" or a == "--test-shop-deck-drop" or a == "--test-gameplay-expansion" then
        isCaptureMode = true
    end
end
local Capture = isCaptureMode and require("capture_screens") or nil

-- Game States: "menu", "BLIND_SELECT", "map", "playing", "scoring", "CASH_OUT", "shop", "event", "boss_deity", "chest", "socketing", "gameover", "victory"
local state = "menu"

-- Virtual Resolution
local V_WIDTH = 1280
local V_HEIGHT = 720
-- Keep the established 1280x720 layout coordinates, but rasterize to the
-- requested 1920x1080 virtual canvas for sharper typography and UI sprites.
local RENDER_SCALE = Layout.width / V_WIDTH
local RENDER_WIDTH = Layout.width
local RENDER_HEIGHT = Layout.height
local scale = 1
Layout.scaleY = 1
local offsetX = 0
local offsetY = 0

-- Graphics Pipeline: Canvas & Shaders
local mainCanvas = nil

-- Run data
local game = GameState.new("red_deck")

local pendingCombatNode = nil -- For encounter preview
local cashOutAnim = nil -- For Cash Out Modal Breakdown
local shopData = nil
local chestRewards = {}
local pendingEquipment = nil

local pendingEvolutionCard = nil
local pendingSpeedCard = nil
local pendingEditionCard = nil
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
local isUiGalleryOpen = false
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
    graphicsQuality = Touch.lowPower and "LOW" or "HIGH",
    cinematicEnabled = true,
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
    sourceKind = nil,
    sacrificeZone = { x = 1120, y = 492, w = 145, h = 158 },
    purchaseZone = { x = 1023, y = 502, w = 84, h = 138 },
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
    if currentState=="playing" or currentState=="scoring" or currentState=="shop" then
        local localIndex,visible=UI.InventoryRail.localIndex("spn",i,game)
        if not localIndex then return -10000,-10000,1,1 end
        if currentState=="shop" then
            return 1042+((localIndex-1)%3)*72,112+math.floor((localIndex-1)/3)*106,64,88
        end
        return Layout.fanCardRect(Layout.battle.spm,localIndex,visible)
    end
    return 295+(i-1)*96,32,82,118
end
UI.getDeitySlotRect = getDeitySlotRect

local function drawConsumableSlot(c, cx, cy, conSlotW, conSlotH, j, mx, my)
    if c and c.faceDown then return UI.drawCardBack(cx, cy, conSlotW, conSlotH, c.alpha) end
    if c and (c.category=="stored_card" or c.category=="stored_equipment") then
        local item=c.card or Equipment.ITEMS[c.equipmentId]
        if item then
            local hovered=mx>=cx and mx<=cx+conSlotW and my>=cy and my<=cy+conSlotH
            require("ui.card_surfaces").fullReward(item,cx,cy,conSlotW,conSlotH,c.card and "standard" or "arcana",hovered)
            return
        end
    end
    if c then
        cy = cy + math.sin(((juice and juice.ambientTimer) or 0) * 1.35 + j * 0.9) * 2
        local isHover = (mx >= cx and mx <= cx + conSlotW and my >= cy and my <= cy + conSlotH)
        if UI.getConsumableImage(c) or (c.handId and UI.getHandImage(c.handId)) then
            return require("ui.card_surfaces").fullReward(c, cx, cy, conSlotW, conSlotH, c.packType, isHover)
        end
        if isHover then
            UI.descriptionCandidate = c cy = cy - 2 end
        if not UI.drawSlot(isHover and "hover" or "occupied", "consumable", cx, cy, conSlotW, conSlotH) then
            love.graphics.setColor(0.12, 0.16, 0.22, 0.95)
            UI.drawRoundedRect("fill", cx, cy, conSlotW, conSlotH, 6)
            love.graphics.setLineWidth(isHover and 2 or 1.5)
            love.graphics.setColor(c.color or UI.COLORS.goldYellow)
            UI.drawCardBorder(cx, cy, conSlotW, conSlotH, isHover and UI.COLORS.goldYellow)
        end

        -- Icon
        love.graphics.setFont(UI.fonts.medium)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(c.icon or "✨", cx, cy + 10, conSlotW, "center")

        -- Name
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.printf(c.name or "Thẻ Phép", cx + 2, cy + 42, conSlotW - 4, "center")

    else
        local isHover = mx >= cx and mx <= cx + conSlotW and my >= cy and my <= cy + conSlotH
        if not UI.drawSlot(isHover and "hover" or "empty", "consumable", cx, cy, conSlotW, conSlotH) then
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

local function drawBattleConsumableCard(c, cx, cy, cardW, cardH, index, mx, my, isTopHovered, effectOnly, opacity)
    if not c then return end
    if state == "shop" and not effectOnly and UI.Polish.hiddenOwned(c) then return end
    if c.faceDown then return UI.drawCardBack(cx, cy, cardW, cardH, opacity or c.alpha) end
    local g = love.graphics
    local hovered = isTopHovered == true
    opacity = opacity or 1
    local drawY = cy + math.sin(((juice and juice.ambientTimer) or 0) * 1.35 + index * 0.9) * 1.5
    if hovered then drawY = drawY - 2 end
    local accent = c.color or UI.COLORS.hpGreen
    local scale = hovered and 1.04 or 1

    g.push("all")
    g.translate(cx + cardW / 2, drawY + cardH / 2)
    g.scale(scale)
    g.translate(-cardW / 2, -cardH / 2)
    UI.CardPhysics.capture(c, 0, 0, cardW, cardH)
    local artwork = UI.getConsumableImage(c) or (c.handId and UI.getHandImage(c.handId))
    if artwork or c.category == "stored_card" or c.category == "stored_equipment" then
        local item = c.card or (c.equipmentId and Equipment.ITEMS[c.equipmentId]) or c
        require("ui.card_surfaces").fullReward(item, 0, 0, cardW, cardH,
            c.card and "standard" or (c.equipmentId and "arcana" or c.packType), hovered, opacity)
        g.pop()
        if hovered then UI.descriptionCandidate = c end
        return
    end
    g.setColor(0, 0, 0, 0.45 * opacity)
    UI.drawRoundedRect("fill", 3, 4, cardW, cardH, 6)
    g.setColor(0.055, 0.085, 0.09, 0.98 * opacity)
    UI.drawRoundedRect("fill", 0, 0, cardW, cardH, 6)
    g.setColor(accent[1], accent[2], accent[3], (hovered and 0.3 or 0.14) * opacity)
    UI.drawRoundedRect("fill", 3, 3, cardW - 6, 30, 4)
    g.setColor(accent[1], accent[2], accent[3], (accent[4] or 1) * opacity)
    g.setLineWidth(hovered and 2 or 1.25)
    UI.drawCardBorder(0, 0, cardW, cardH, hovered and UI.COLORS.goldYellow, opacity)
    g.setFont(UI.fonts.medium)
    g.setColor(1, 1, 1, opacity)
    g.printf(c.icon or "✦", 3, 6, cardW - 6, "center")
    g.setFont(UI.fonts.tiny)
    g.setColor(UI.COLORS.textLight[1], UI.COLORS.textLight[2], UI.COLORS.textLight[3], opacity)
    g.printf(UI.truncateUtf8(c.name or "Thẻ phép", 7), 5, 39, cardW - 10, "center")

    g.pop()
    if effectOnly then return end

    if hovered then UI.descriptionCandidate = c end
end

drawConsumableSlot = UI.CardPhysics.wrap(drawConsumableSlot)
drawBattleConsumableCard = UI.CardPhysics.wrap(drawBattleConsumableCard, nil, 9)

-- Micro-Animation & Juice System
juice = {
    ambientTimer = 0,
    handRankBounce = 1.0,
    lastEvaluatedRank = nil,
    goldBounce = 1.0,
    lastGold = 6,
    hpBounce = 1.0,
    armorBounce = 1.0,
    lastHp = 100,
    lastArmor = 0,
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
    displayAuraEditionMultiplier = 1.0,
    displayFlatDamage = 0,
    displayFinalScore = 0,
    displayAura = 0,
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
    entryCompleteAt = 0,
    playButtonPulse = 0,
    cardTransform = {},
    energyBolts = {},
    energyVolleyPending = 0,
    hitStop = 0,
    screenFlash = 0,
    screenDistortion = 0,
    exitStarted = false,
    exitProgress = 0,
    consumableUseCooldown = 0,
    chestReveal = { state = nil, timer = 0 },
}

-- Short-lived visual feedback shared by shop purchases, sales and pack picks.
local shopFx = {}
UI.Polish.drawConsumable = drawBattleConsumableCard

local function spawnShopFx(kind, item, x, y, w, h)
    if kind=="destroy" then Feedback.destroyCard(item and (item.card or item),x or 640,y or 360)
    elseif kind=="sell" or kind=="sacrifice" then
        local accent=Feedback.emit("sell",x or 640,y or 360,1,nil,true)
        accent.target=state=="shop" and UI.Polish.config.gold or {x=475,y=38}
    end
    local category = item and item.category
    local targetX, targetY = state == "shop" and (shopDrag.purchaseZone.x + shopDrag.purchaseZone.w / 2) or 1110,
        state == "shop" and (shopDrag.purchaseZone.y + (shopDrag.purchaseZone.h - 24) / 2) or 630
    if category == "deity" or (item and item.id and Deities.CATALOG[item.id]) then
        if state == "shop" then
            local sx, sy, sw, sh = getDeitySlotRect(math.max(1, Deities.getCount(game.deities)), "shop")
            targetX, targetY = sx + sw / 2, sy + sh / 2
        else targetX, targetY = 420, 86 end
    elseif category == "equipment" then
        targetX, targetY = 720, 92
    elseif category == "consumable" then
        targetX, targetY = 980, 92
    end
    if kind == "sell" then
        targetX, targetY = 205, 570
    elseif kind == "sacrifice" then
        targetX, targetY = shopDrag.sacrificeZone.x + shopDrag.sacrificeZone.w / 2, shopDrag.sacrificeZone.y + shopDrag.sacrificeZone.h / 2
    elseif kind == "destroy" then
        targetX, targetY = x or 640, (y or 360) - 28
    elseif kind == "consume" then
        targetX, targetY = x or 640, (y or 360) - 26
    end
    table.insert(shopFx, {
        kind = kind,
        item = item or {},
        x = x or 640,
        y = y or 360,
        life = 0,
        targetX = targetX,
        targetY = targetY,
        w = w,
        h = h,
        duration = kind == "consume" and UI.Polish.config.dissolve or (kind == "destroy" and 0.56 or ((kind == "sell" or kind == "sacrifice") and 0.48 or 0.58)),
        accentPending = kind=="buy",
    })
end

local function getConsumableSlotRect(i,currentState)
    if currentState=="playing" or currentState=="scoring" or currentState=="shop" then
        local localIndex,visible=UI.InventoryRail.localIndex("consumable",i,game)
        if not localIndex then return -10000,-10000,1,1 end
        if currentState=="shop" then return 1042+(localIndex-1)*72,358,64,88 end
        return Layout.fanCardRect(Layout.battle.consumables,localIndex,visible)
    end
    return 295+(i-1)*96,32,82,118
end
UI.getConsumableSlotRect=getConsumableSlotRect

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

function anim.prepareDrawAnimation(card, order)
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
    scale, offsetX, offsetY, Layout.scaleY = Layout.scale(winW, winH, Touch.fillScreen)
end

local function toVirtual(mx, my)
    return Layout.toLogical(mx, my, scale, Layout.scaleY, offsetX, offsetY, RENDER_SCALE)
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
    local maxCount = math.min(UI.Abilities.handSize(game), maxAllowed)
    if game.monster and game.monster.isBoss and game.monster.bossData and game.monster.bossData.maxSelectedCards and UI.BossAbilities.passiveEnabled(game.monster) then
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
    UI.BedExplosion.clear(); anim.pendingBedScore=nil
    anim.pendingStoredEquipment=nil
    if not isCaptureMode then Persistence.deleteRun() end
    GameState.resetRun(game, chosenDeck or "red_deck")
    Feedback.clearVfx()
    juice.lastGold, juice.lastHp, juice.lastArmor = game.gold or 0, game.playerHp or 100, game.playerArmor or 0
    juice.floatingTexts = {}
    pendingCombatNode = nil

    inspectCardModal = nil
    isShopTransferOpen = false
    isHandbookOpen = false
    transferSourceCard = nil
    transferSourceEqIndex = nil
    transferMessage = nil

    -- Red Deck begins with one card sampled uniformly from the standard 52.
    game.persistentDeck = Deck.createStarterDeck(game.starterDeckId)
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck

    clearAllSelections()
    syncCardSelections()

    -- The supported campaign is the Balatro-style 8-Ante loop. The legacy
    -- 20-floor map remains available to screenshot/dev tooling only.
    game.map = nil

    -- Initialize expedition campaign (20 stages, 3 encounters per stage).
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
    table.sort(game.selectedIndices)
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

local function handInputBlocked()
    return state ~= "playing" or anim.enemyTurn or UI.AbilityUI.current
        or isPauseMenuOpen or isSettingsOpen or isHandbookOpen or isCollectionOpen
        or isDeckViewerOpen or inspectCardModal or isDebugOpen or isUiGalleryOpen
        or UI.ScoringFeel.labOpen or UI.CardPhysics.isLabOpen()
        or (DeathVFX.enemyActive(game.monster) and DeathVFX.busy())
end

local function selectHandDragCard(index)
    local card = game.hand[index]
    if not card or handDrag.visited[card] then return end
    handDrag.visited[card] = true
    if (card.selected == true) == handDrag.selecting then return end
    if handDrag.selecting and #game.selectedIndices >= getMaxSelectableCards() then
        if not handDrag.limitNotified then
            handDrag.limitNotified = true
            table.insert(anim.floatingTexts, {
                text = "Tối đa " .. getMaxSelectableCards() .. " lá",
                color = UI.COLORS.goldYellow, x = UI.BATTLE_CENTER_X or 640,
                y = 405, alpha = 1.2, scale = 0.65,
            })
        end
        return
    end
    toggleCardSelection(index)
    card.selectPulse = 1
    CardEffects.triggerSelectPulse(card)
end

local function sweepHandSelection(mx, my)
    if not handDrag.isDragging then
        local dx, dy = mx - handDrag.startX, my - handDrag.startY
        if dx * dx + dy * dy <= 10 * 10 then return end
        handDrag.isDragging = true
    end
    local fromX, fromY = handDrag.currentX, handDrag.currentY
    local steps = math.max(1, math.ceil(math.max(math.abs(mx - fromX), math.abs(my - fromY)) / 4))
    -- Sample the whole mouse path so a fast swipe cannot skip intervening cards.
    for step = 1, steps do
        local x, y = fromX + (mx - fromX) * step / steps, fromY + (my - fromY) * step / steps
        for i = #handDrag.hitRects, 1, -1 do
            local rect = handDrag.hitRects[i]
            if x >= rect.x and x <= rect.right and y >= rect.y and y <= rect.bottom then
                selectHandDragCard(i)
                break
            end
        end
    end
    handDrag.currentX, handDrag.currentY = mx, my
end

local function beginHandDrag(mx, my, index, reorder)
    handDrag.active, handDrag.isDragging = true, false
    handDrag.cardIndex = index
    handDrag.startX, handDrag.startY = mx, my
    handDrag.currentX, handDrag.currentY = mx, my
    handDrag.mode = reorder and "reorder" or "select"
    handDrag.selecting = not (index and game.hand[index].selected)
    handDrag.visited, handDrag.hitRects, handDrag.limitNotified = {}, {}, false
    for i, card in ipairs(game.hand) do
        local x, y, w, h = getHandCardPosition(i, #game.hand)
        handDrag.hitRects[i] = {
            x = x - 4, right = x + w + 4,
            y = y - 56,
            bottom = y + h + 8,
        }
    end
    if not reorder then
        -- Selection never picks up a card or waits for a direction threshold.
        UI.CardPhysics.release()
        if index then selectHandDragCard(index) end
    end
end

-- Input stays anchored to the hand slots while lift, scale and tilt animate.
-- Rightmost slot owns overlaps, consistently for hover, press and sweep.
handDrag.cardAt = function(mx, my)
    for i = #game.hand, 1, -1 do
        local x, y, w, h = getHandCardPosition(i, #game.hand)
        if mx >= x - 4 and mx <= x + w + 4 and my >= y - 56 and my <= y + h + 8 then
            return i
        end
    end
end

local function beginPlayerDefeat(played)
    if state == "defeating" then return end
    DeathVFX.startPlayer(UI.BATTLE_CENTER_X, Renderer.quality)
    DeathVFX.monster = game.monster
    DeathVFX.cards = {}
    if #(game.hand or {}) == 0 then
        for i,c in ipairs(played or anim.playedCards or {}) do DeathVFX.cards[i] = c end
    end
    state = "defeating"
    buttons = {}
    screenShake = 0
    isPauseMenuOpen, isSettingsOpen, isDeckViewerOpen, isHandbookOpen = false, false, false, false
    inspectCardModal = nil
    UI.CardPhysics.release()
end

function anim.showMonsterDamage(actualDamage, defeated, isTrueDamage)
    if not actualDamage or actualDamage <= 0 then return end
    local cx, cy = (game.monster and game.monster.screenX) or UI.BATTLE_CENTER_X, 270
    local color = isTrueDamage and { 1, 0.30, 0.46, 1 } or UI.COLORS.hpRed
    local heavy = defeated or actualDamage >= (game.monster.maxHp or math.huge) * 0.30
    spawnSparks(cx, cy, heavy and 42 or 28, color)
    if defeated then DeathVFX.startEnemy(game.monster, cx, Renderer.quality) end
    anim.impactFlash = heavy and 0.38 or 0.32
    anim.impactX, anim.impactY, anim.impactColor = cx, cy, color
    monsterMotion.hit = 0.35
    screenShake = math.max(screenShake, heavy and 3.8 or 2.2)
    Feedback.add(anim.floatingTexts, "damage", actualDamage, cx, cy - 58, UI.formatNumber)
    Sound.play(heavy and "damage_heavy" or "damage_hit")
end

local function maxCombatHandSize()
    return (game.selectedFaction == "elaris" or game.selectedSuit == "elaris")
        and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
end

local function dealCombatHand(recycleDiscard)
    local drawn = Combat.drawCards(game, maxCombatHandSize(), function(card, order)
        anim.prepareDrawAnimation(card, order)
        if game.monster and game.monster.isBoss and game.monster.bossData
            and game.monster.bossData.debuffId == "the_fish" and UI.BossAbilities.passiveEnabled(game.monster) then
            card.faceDown = true
        end
    end, recycleDiscard)
    if game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end
    clearAllSelections()
    syncCardSelections()
    return drawn
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

    UI.Abilities.discard(game, discardedCards)

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
                    anim.showMonsterDamage(actualDmg, defeated, true)
                    table.insert(anim.floatingTexts, {
                        text = "🩸 [Huyết Tế] " .. card.rankName .. "♥: -" .. actualDmg .. " Sát Thương Chuẩn!",
                        color = { 0.95, 0.25, 0.35, 1 },
                        x = 640,
                        y = 440,
                        alpha = 2.2,
                    })
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
            if #game.consumables < UI.Inventory.limit(game) then
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
                    text = "🟣 [DẤU TÍM] Ô Tiêu Hao đã đầy!",
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

    -- Draw only from the remaining deck; the discard pile returns on explicit end turn.
    dealCombatHand(false)
    Sound.play("card_deal")
end

local function destroyHandCard(index)
    local card = game.hand and game.hand[index]
    if not card then return nil end
    UI.Abilities.destroy(game, card)
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
    return card
end

local function useConsumable(idx)
    game.consumables = game.consumables or {}
    local c = game.consumables[idx]
    if not c then return false end
    local p=Shop.getConsumableParams(c)

    if UI.BossAbilities.isSlotLocked(game, "consumable", idx) then return false end
    if c.category=="bed" then
        if state=="shop" then
            local used=UI.Inventory.useBed(game,idx)
            if used then Sound.play("round_win");saveRunAtSafePoint() end
            return used
        end
        if state~="playing" or anim.enemyTurn or anim.active or UI.AbilityUI.current then return false end
        local options={}
        if (game.playerHp or 100)<(game.maxPlayerHp or 100) then
            options[#options+1]={target={id="bed_self",artId="cons_bed",name="Bản thân",color=c.color},label="Bản thân"}
        end
        for enemyIndex,enemy in ipairs(require("src.enemy_group").members(game)) do
            if enemy.hp>0 and not enemy.hasBed then options[#options+1]={target=enemy,label="Quái "..enemyIndex.." · "..(enemy.kingdom or enemy.name)} end
        end
        if #options==0 then return false end
        UI.AbilityUI.openChoices(game,{{card=c,title="CÁI GIƯỜNG · CHỌN NGƯỜI NGỦ",
            description="Ngủ hồi đầy HP và bỏ một lượt. Đặt lên quái để hồi máu cho chúng hoặc kích bẫy Ngủ Dưới Địa Ngục.",options=options}},function(decisions)
            local choice=decisions[1];if not choice then return end
            local index;for i,card in ipairs(game.consumables) do if card==c then index=i;break end end
            if not index then return end
            local enemy=choice.target.id~="bed_self" and choice.target or nil
            if UI.Inventory.useBed(game,index,enemy) then
                UI.Abilities.consumableUsed(game);Sound.play("round_win")
                if not enemy then UI.endBedTurn() end
                saveRunAtSafePoint()
            end
        end)
        return true
    end
    local utilityUsed=UI.Inventory.useUtility(game,idx)
    if utilityUsed~=nil then
        if utilityUsed then Sound.play("round_win");saveRunAtSafePoint() end
        return utilityUsed
    end
    local expansion=require("src.chest_expansion")
    if expansion.byId[c.id] and (c.id:match("^spec_") or c.id:match("^spell_")) then
        local target=game.hand and game.hand[(game.selectedIndices or {})[1] or 1]
            or (game.persistentDeck or {})[1]
        local ok,message=expansion.apply(game,c,target)
        table.insert(anim.floatingTexts,{text=message,color=c.color or UI.COLORS.goldYellow,x=640,y=350,alpha=3})
        if ok then
            table.remove(game.consumables,idx)
            Sound.play("round_win");saveRunAtSafePoint()
        end
        return ok
    end
    if c.id == "cons_vitality" then
        local bonus=c.hpBonus or 20
        game.maxPlayerHp=(game.maxPlayerHp or 100)+bonus
        game.playerHp=math.min(game.maxPlayerHp,(game.playerHp or 100)+bonus)
        table.remove(game.consumables,idx)
        Sound.play("round_win")
        saveRunAtSafePoint()
        return true
    end
    if c.id == "soul_reaper" then
        if state ~= "shop" then
            table.insert(anim.floatingTexts, {text="Dùng Lá Tiêu Hủy trong shop để chọn bài từ cả bộ.",
                color=c.color,x=640,y=350,alpha=2.2})
            return false
        end
        if not Shop.activateDestruction(game,c) then return false end
        isDeckViewerOpen=true;deckViewerPage=1;UI.Polish.clearFocus()
        Sound.play("card_select")
        return true
    end
    if c.category == "stored_card" then
        Deck.addCardToDeck(game, c.card)
        table.remove(game.consumables, idx)
        Sound.play("card_deal")
        return true
    elseif c.category == "stored_equipment" then
        local equipment = Equipment.ITEMS[c.equipmentId]
        if not equipment then return false end
        pendingEquipment, anim.pendingStoredEquipment = equipment, c
        socketingReturnState = state == "playing" and "playing" or "shop"
        state = "socketing"
        Sound.play("card_select")
        return true
    end
    if c.category == "evolution" or c.id == "cons_evolution" then
        local x,y,w,h = getConsumableSlotRect(idx,state)
        return UI.AbilityUI.openEvolution(game, c, function(evolved)
            spawnShopFx("consume", c, x+w/2, y+h/2, w, h)
            saveRunAtSafePoint()
        end, {x=x,y=y,w=w,h=h})
    end

    if c.category == "speed_single" then
        if state ~= "playing" or not game.hand or #game.hand == 0 then
            table.insert(anim.floatingTexts, {
                text = "Tăng Tốc Đơn chỉ dùng được khi đang có bài trên tay.",
                color = { 0.48, 0.78, 1, 1 }, x = 640, y = 350, alpha = 2.2,
            })
            return false
        end
        pendingSpeedCard = c
        table.insert(anim.floatingTexts, {
            text = "CHỌN LÁ BÀI TRÊN TAY ĐỂ TĂNG +"..p.speed.." TỐC ĐÁNH · ESC ĐỂ HỦY",
            color = { 0.48, 0.78, 1, 1 }, x = 640, y = 310, alpha = 2.4,
        })
        Sound.play("card_select")
        return true
    elseif c.category == "speed_team" then
        if state ~= "playing" or not game.hand or #game.hand == 0 then
            table.insert(anim.floatingTexts, {
                text = "Tăng Tốc Đội chỉ dùng được khi đang có bài trên tay.",
                color = { 0.38, 0.90, 0.68, 1 }, x = 640, y = 350, alpha = 2.2,
            })
            return false
        end
        local affected, seenIds = 0, {}
        for _, handCard in ipairs(game.hand) do
            local key = handCard.id or handCard
            if not seenIds[key] then
                seenIds[key] = true
                local seenCards = {}
                for _, pile in ipairs({ game.persistentDeck or {}, game.hand or {}, game.deck or {}, game.discardPile or {} }) do
                    for _, copy in ipairs(pile or {}) do
                        if copy and not seenCards[copy] and (copy == handCard or (handCard.id and copy.id == handCard.id)) then
                            seenCards[copy] = true
                            Deck.applyAttackSpeedBonus(copy, p.speed)
                        end
                    end
                end
                affected = affected + 1
            end
        end
        table.remove(game.consumables, idx)
        Sound.play("round_win")
        table.insert(anim.floatingTexts, {
            text = "TĂNG TỐC ĐỘI · +2 TỐC ĐÁNH CHO " .. affected .. " LÁ",
            color = { 0.38, 0.90, 0.68, 1 }, x = 640, y = 350, alpha = 2.8,
        })
        return true
    end

    if c.category == "edition" then
        pendingEditionCard = c
        table.insert(anim.floatingTexts, {
            text = (require("src.card_effects").getScoreBonus({edition=c.edition}) and "CHỌN LÁ BÀI HOẶC SPN" or "CHỌN LÁ BÀI") .. " ĐỂ ÁP DỤNG " .. tostring(c.name or "ẤN BẢN") .. " · ESC ĐỂ HỦY",
            color = c.color or UI.COLORS.goldYellow, x = 640, y = 310, alpha = 2.8,
        })
        Sound.play("card_select")
        return true
    end

    -- 1. Celestial / Planet card
    if c.category == "celestial" or (c.id and c.id:find("planet_")) then
        game.handLevels = game.handLevels or {}
        if c.handId == "random" then
            local allHands = {}
            for _, ht in pairs(Poker.HAND_TYPES) do table.insert(allHands, ht) end
            local h = allHands[Rng.random(#allHands)]
            game.handLevels[h.id] = (game.handLevels[h.id] or 1) + p.levels
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
                game.handLevels[ht.id] = (game.handLevels[ht.id] or 1) + p.levels
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
            game.handLevels[c.handId] = (game.handLevels[c.handId] or 1) + p.levels
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
            game.maxHandSize = math.max(1, (game.maxHandSize or 3) - p.handLoss)
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
            for _, entry in ipairs(deityList) do
                if entry.deity ~= chosen.deity then require("src.souls").award(game,entry.deity) end
            end
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
            for _, entry in ipairs(deityList) do
                if entry.deity ~= kept then require("src.souls").award(game,entry.deity) end
            end
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
            for i = 1, p.count do
                local nc = Deck.newCard(ranks[(i-1)%#ranks+1], userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(game, nc)
            end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "👻 Familiar: Thêm 3 lá J/Q/K có trang bị!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_grim" then
            if game.hand and #game.hand > 0 then destroyHandCard(Rng.random(#game.hand)) end
            for i = 1, p.count do
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
            for i = 1, p.count do
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
            for _ = 1, p.count do
                local clone = Deck.cloneCard(target)
                clone.id = Deck.newCard(target.rank, target.suit).id
                Deck.addCardToDeck(game, clone)
                if game.hand then table.insert(game.hand, clone) end
            end
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🧬 Cryptid: Tạo " .. p.count .. " bản sao của lá " .. (target.rankName or "") .. (target.suitSymbol or "") .. "!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_immolate" then
            local destroyed = 0
            while game.hand and #game.hand > 0 and destroyed < p.count do
                destroyHandCard(1)
                destroyed = destroyed + 1
            end
            game.gold = (game.gold or 0) + p.gold
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
                    Deck.transformCard(game, ch, nil, targetSuit)
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
                    Deck.transformCard(game, ch, r)
                end
            end
            game.maxHandSize = math.max(1, (game.maxHandSize or 3) - p.handLoss)
            Sound.play("round_win")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "👁️ Ouija: Đổi bài sang Rank " .. rName .. ", Hand Size: " .. game.maxHandSize .. "!", color = UI.COLORS.goldYellow, x = 640, y = 350, alpha = 3.0 })
            return true
        elseif c.id == "spec_black_hole" then
            game.handLevels = game.handLevels or {}
            for _, ht in pairs(Poker.HAND_TYPES) do
                game.handLevels[ht.id] = (game.handLevels[ht.id] or 1) + p.levels
            end
            Sound.play("xmult_boom")
            table.remove(game.consumables, idx)
            table.insert(anim.floatingTexts, { text = "🕳️ Black Hole: TẤT CẢ các thế bài tăng +1 Cấp độ!", color = { 0.85, 0.45, 0.95, 1 }, x = 640, y = 350, alpha = 3.0 })
            return true
        end
    end

    return false
end

local function activateConsumable(idx, currentState)
    if anim.consumableUseCooldown > 0 then return false end
    local card = game.consumables and game.consumables[idx]
    if not card then return false end
    local x, y, w, h = getConsumableSlotRect(idx, currentState)
    local before = UI.Polish.snapshot(game)
    if not useConsumable(idx) then return false end
    UI.Polish.changed(UI, game, before, card, {x=x,y=y,w=w,h=h})
    local stillStored = false
    for _, remaining in ipairs(game.consumables or {}) do if remaining == card then stillStored = true end end
    if not stillStored then UI.Abilities.consumableUsed(game) end
    anim.consumableUseCooldown = 0.20
    Sound.play("card_activate")
    if card.category ~= "evolution" and card.id ~= "cons_evolution"
        and card.category ~= "speed_single" and card.category ~= "bed" and card.category ~= "edition" and card.id ~= "soul_reaper" then
        spawnShopFx("consume", card, x + w / 2, y + h / 2, w, h)
    end
    return true
end

local function applyPendingEvolutionAt(mx, my, currentState)
    if not pendingEvolutionCard then return false end
    local maxSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    for i = 1, maxSlots do
        local x, y, w, h = getDeitySlotRect(i, currentState)
        local deity = game.deities and game.deities[i]
        if deity and mx >= x and mx <= x + w and my >= y and my <= y + h then
            local cardIndex
            for index, card in ipairs(game.consumables or {}) do
                if card == pendingEvolutionCard then cardIndex = index; break end
            end
            if not cardIndex then
                pendingEvolutionCard = nil
                return true
            end

            local evolved, badge = Deities.evolve(deity)
            if evolved then
                local card = table.remove(game.consumables, cardIndex)
                pendingEvolutionCard = nil
                spawnShopFx("consume", card, x + w / 2, y + h / 2, w, h)
                table.insert(anim.floatingTexts, {
                    text = deity.name .. "  →  " .. badge .. "  ·  " .. (deity.desc or "Chỉ số đã tăng"),
                    color = { 0.82, 0.70, 1, 1 }, x = x + w / 2, y = y - 8, alpha = 2.5,
                })
                Sound.play("xmult_boom")
            end
            return true
        end
    end
    return false
end

local function applyPendingEditionAt(mx, my, currentState)
    if not pendingEditionCard then return false end
    local before = UI.Polish.snapshot(game)
    local consumableIndex
    for index, item in ipairs(game.consumables or {}) do
        if item == pendingEditionCard then consumableIndex = index break end
    end
    if not consumableIndex then pendingEditionCard = nil; return true end

    local maxSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    for i = 1, maxSlots do
        local x, y, w, h = getDeitySlotRect(i, currentState)
        local deity = game.deities and game.deities[i]
        if deity and mx >= x and mx <= x + w and my >= y and my <= y + h then
            if not Shop.applyEdition(deity, pendingEditionCard.edition) then
                table.insert(anim.floatingTexts,{text="ẤN BẢN NÀY CẦN LÁ BÀI CÓ BẬC VÀ CHẤT",color=UI.COLORS.goldYellow,x=640,y=310,alpha=2.2})
                Sound.play("cant_afford");return true
            end
            local used = table.remove(game.consumables, consumableIndex)
            UI.Abilities.consumableUsed(game)
            pendingEditionCard = nil
            local cx,cy,cw,ch = getConsumableSlotRect(consumableIndex,currentState)
            spawnShopFx("consume", used, cx+cw/2, cy+ch/2, cw, ch)
            UI.Polish.changed(UI, game, before, used, {x=cx,y=cy,w=cw,h=ch})
            Sound.play("round_win")
            return true
        end
    end

    if currentState == "playing" then
        for i = #game.hand, 1, -1 do
            local card = game.hand[i]
            local x, y = card.visualX or 0, card.visualY or 0
            if mx >= x and mx <= x + 100 and my >= y and my <= y + 145 then
                local applied = false
                for _, pile in ipairs({ game.persistentDeck or {}, game.hand or {}, game.deck or {}, game.discardPile or {} }) do
                    for _, copy in ipairs(pile) do
                        if copy and (copy == card or (card.id and copy.id == card.id)) then
                            Shop.applyEdition(copy, pendingEditionCard.edition)
                            applied = true
                        end
                    end
                end
                if not applied then Shop.applyEdition(card, pendingEditionCard.edition) end
                local used = table.remove(game.consumables, consumableIndex)
            UI.Abilities.consumableUsed(game)
                pendingEditionCard = nil
                local cx, cy, cw, ch = getConsumableSlotRect(consumableIndex, currentState)
                spawnShopFx("consume", used, cx + cw / 2, cy + ch / 2, cw, ch)
                UI.Polish.changed(UI, game, before, used, {x=cx,y=cy,w=cw,h=ch})
                Sound.play("round_win")
                return true
            end
        end
    end
    return false
end

local function applyPendingSpeedAt(mx, my)
    if not pendingSpeedCard then return false end
    local before = UI.Polish.snapshot(game)
    for i = #game.hand, 1, -1 do
        local card = game.hand[i]
        local x, y = card.visualX or 0, card.visualY or 0
        if mx >= x and mx <= x + 100 and my >= y and my <= y + 145 then
            local rewardIndex
            for index, item in ipairs(game.consumables or {}) do
                if item == pendingSpeedCard then rewardIndex = index; break end
            end
            if not rewardIndex then pendingSpeedCard = nil; return true end

            local seenCards, selectedSpeed = {}, nil
            for _, pile in ipairs({ game.persistentDeck or {}, game.hand or {}, game.deck or {}, game.discardPile or {} }) do
                for _, copy in ipairs(pile or {}) do
                    if copy and not seenCards[copy] and (copy == card or (card.id and copy.id == card.id)) then
                        seenCards[copy] = true
                        local result = Deck.applyAttackSpeedBonus(copy, Shop.getConsumableParams(pendingSpeedCard).speed)
                        if copy == card then selectedSpeed = result end
                    end
                end
            end
            local usedCard = table.remove(game.consumables, rewardIndex)
            UI.Abilities.consumableUsed(game)
            pendingSpeedCard = nil
            local cx, cy = getConsumableSlotRect(rewardIndex, "playing")
            spawnShopFx("consume", usedCard, cx + 40, cy + 55, 80, 110)
            UI.Polish.changed(UI, game, before, usedCard, {x=cx,y=cy,w=80,h=110})
            Sound.play("round_win")
            return true
        end
    end
    return false
end

local function startEnemyAttack(phase, speed, done, played)
    anim.enemyTurn = EnemyAttack.start(game, phase, speed, function(hit, enemy)
        require("src.spn_anomalies").showFeedback(game,anim)
        local heavy = hit.damage >= 8
        screenShake = math.max(screenShake or 0, heavy and 4.2 or 2.8)
        anim.hitStop = heavy and 0.060 or 0.040
        anim.screenFlash, anim.screenDistortion = 0.045, 0.065
        anim.impactFlash = 0.14
        local hitX = enemy.screenX or UI.BATTLE_CENTER_X
        anim.impactX, anim.impactY, anim.impactColor = hitX, 454, UI.COLORS.hpRed
        spawnSparks(hitX, 454, heavy and 8 or 5, UI.COLORS.hpRed)
        Sound.play(heavy and "damage_heavy" or "damage_hit", 0.78)
        if hit.absorbed > 0 then
            local ft = Feedback.add(anim.floatingTexts, "armor", -hit.absorbed, hitX, 458, UI.formatNumber)
            ft.label = "GIÁP HẤP THỤ"
        end
        if hit.damage > 0 then
            Feedback.add(anim.floatingTexts, "heal", -hit.damage, hitX, 500, UI.formatNumber)
        elseif hit.absorbed == 0 then
            table.insert(anim.floatingTexts, {text="ĐÒN BỊ CHẶN",color={0.4,0.84,1},x=hitX,y=478,alpha=1.6})
        end
    end, function()
        if (game.playerHp or 0) <= 0 then
            beginPlayerDefeat(played)
            Persistence.deleteRun()
        else done() end
    end)
    if anim.enemyTurn and phase=="before" then Feedback.emit("enemy_first",UI.BATTLE_CENTER_X,260) end
    return anim.enemyTurn ~= nil
end

local function playSelectedHand()
    if anim.enemyTurn then return end
    if state ~= "playing" or anim.active or #game.selectedIndices == 0 or game.handsRemaining <= 0 then return end

    local playedCards = getSelectedCards()
    local evalForChoices = Poker.evaluate(playedCards, game.unlockedHands, game.handLevels)
    if not evalForChoices then return end
    if not game.abilityApproved then
        local choices = UI.Abilities.choices(game, evalForChoices, playedCards)
        if #choices > 0 then
            UI.AbilityUI.openChoices(game, choices, function(decisions)
                game.abilityApproved = decisions
                playSelectedHand()
            end)
            return
        end
    end
    local playedCardStarts = {}
    for i, card in ipairs(playedCards) do
        playedCardStarts[i] = {
            x = card.visualX or (UI.BATTLE_CENTER_X - 48),
            y = card.visualY or 466,
            scale = card.visualScale or 1.0,
            rotation = card.rotation or card.visualAngle or 0,
        }
    end
    local playerSpeed = Combat.getAverageAttackSpeed(playedCards)
    local monsterSpeed = game.monster and (game.monster.attackSpeed or 1) or 1
    game.lastPlayerAttackSpeed = playerSpeed
    game.monsterAttackedBeforePlayer = playerSpeed < monsterSpeed
    local evalResult = Poker.evaluate(playedCards, game.unlockedHands, game.handLevels)
    if not evalResult then return end
    UI.Abilities.beginHand(game, evalResult, playedCards, game.abilityApproved)
    game.abilityApproved = nil
    game.lastPlayedHandId = evalResult.type and evalResult.type.id
    anim.playButtonPulse = UI.ScoringFeel.config.timing.button

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

    -- Boss-forced discards share the normal ability event.
    local hookedCount=UI.BossAbilities.onPlay(game)
    if hookedCount>0 then
        table.insert(anim.floatingTexts,{text="[THE HOOK] Boss giật bỏ "..hookedCount.." lá!",color={0.95,0.45,0.2,1},x=640,y=380,alpha=2.5})
        Sound.play("xmult_boom")
    end

    local function beginScoring()
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
            hand = game.hand,
            gameState = game,
            drawCards = function(n)
                local drawnCount = 0
                local maxHand = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris" or game.selectedFaction == "clubs" or game.selectedFaction == "feral_swarm") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
                while #game.hand < maxHand and #game.deck > 0 and drawnCount < n do
                    local drawn = table.remove(game.deck)
                    if drawn then
                        drawn.selected = false
                        anim.prepareDrawAnimation(drawn, drawnCount + 1)
                        table.insert(game.hand, drawn)
                        drawnCount = drawnCount + 1
                    end
                end
                return drawnCount
            end,
        }
        anim.hpBeforeScoring = game.monster and game.monster.hp or 0
        local scoreResult = Scoring.calculate(evalResult, game.deities, context)
        game.handsPlayedThisCombat = (game.handsPlayedThisCombat or 0) + 1

        -- Pha Người Chơi: Kích hoạt Hiệu ứng Trang Bị/Ngọc Khảm sinh tồn trước (+Giáp, +Hồi Máu)
        if scoreResult.addArmor and scoreResult.addArmor > 0 then
            game.playerArmor = math.min(UI.Abilities.config.armorCap, (game.playerArmor or 0) + scoreResult.addArmor)
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
                c.overchargeStacks = math.min(Deck.ENHANCEMENTS.enh_overcharged.params.maxStacks, (c.overchargeStacks or 0) + Deck.ENHANCEMENTS.enh_overcharged.params.gain)
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

        -- Setup existing visual state; the queue consumes the already-calculated result.
        anim.active = true
        anim.timer = 0
        anim.scoringData = scoreResult
        anim.playedCards = playedCards
        anim.cardEntryFrom = playedCardStarts
        anim.evalResult = evalResult
        anim.displayXMult, anim.displayAuraEditionMultiplier, anim.displayFlatDamage = 1, 1, 0
        anim.activeCardIndex, anim.scoredCards = nil, {}
        anim.stepTimer, anim.targetStepDelay = 0, 0.2
        anim.floatingTexts = {}
        anim.playerAttackSpeed, anim.monsterAttackSpeed = playerSpeed, monsterSpeed
        anim.monsterAttackedBeforePlayer = game.monsterAttackedBeforePlayer
        anim.counterAttackStarted = false
        anim.monsterDefeated, anim.playerKilled, anim.earnedGold, anim.damageDealt = false, false, 0, 0
        anim.pitchStep, anim.cardBounce, anim.cardHit, anim.deityBounce = 0, {}, {}, {}
        anim.bounceScale = {chips = 1, mult = 1, xMult = 1, score = 1}
        anim.particles, anim.fireParticles = {}, {}
        anim.impactFlash, anim.hitStop, anim.screenFlash, anim.screenDistortion = 0, 0, 0, 0
        anim.energyVolleyPending, anim.exitProgress, anim.exitStarted = 0, 0, false
        UI.ScoringFeel.start(anim, scoreResult, UI, game.deities, anim.hpBeforeScoring, game.monster)
        anim.entryCompleteAt = UI.ScoringFeel.config.timing.lift + UI.ScoringFeel.config.timing.travel
            + math.max(0, #playedCards - 1) * UI.ScoringFeel.config.timing.stagger

        state = "scoring"
        Sound.play("card_play", 1.0)
    end
    if not startEnemyAttack("before", playerSpeed, beginScoring, playedCards) then
        Feedback.emit("player_first",UI.BATTLE_CENTER_X,260)
        beginScoring()
    end
end

local function endPlayerTurn(force)
    if anim.enemyTurn then return true end
    if not game or not game.monster then return false end
    local handLimitIsFinal = game.monster.isBoss and game.monster.bossData
        and game.monster.bossData.debuffId == "the_needle" and UI.BossAbilities.passiveEnabled(game.monster)
    if handLimitIsFinal and (game.handsRemaining or 0) <= 0 then return false end
    local canEndTurn = #game.hand == 0 or (game.handsRemaining or 0) <= 0
    local availableCards = #(game.hand or {}) + #(game.deck or {}) + #(game.discardPile or {})
    if (not canEndTurn and not force) or availableCards == 0 then return false end
    Combat.cleanupDestroyedCards(game)
    availableCards = #(game.hand or {}) + #(game.deck or {}) + #(game.discardPile or {})
    if availableCards == 0 then return false end

    UI.Abilities.roundEnd(game)
    local function finishTurn()
        Combat.onPlayerTurnEnd(game)
        local cleansed, cleanseMsg = Combat.onMonsterTurnEnd(game)
        if cleansed then
            table.insert(anim.floatingTexts, {
                text = "✨ " .. cleanseMsg, color = UI.COLORS.hpGreen,
                x = 640, y = 300, alpha = 2.5,
            })
        end
        game.handsRemaining = game.turnHandLimit or game.maxHands or game.handsRemaining or 0
        local drawnCards = 0
        if #game.hand == 0 then
            drawnCards = dealCombatHand(true)
        else
            clearAllSelections()
            syncCardSelections()
        end
        UI.BossAbilities.handEnd(game)
        UI.Abilities.resolveBossDamage(game)
        require("src.enemy_abilities").handEnd(game)
        if (game.playerHp or 0) <= 0 then
            beginPlayerDefeat()
            Persistence.deleteRun()
            return true
        end
        UI.Abilities.roundStart(game)
        UI.Abilities.handStart(game)
        state = "playing"
        Sound.play(drawnCards > 0 and "card_deal" or "ui_click")
    end
    if not startEnemyAttack(nil, nil, finishTurn) then return false end
    return true
end

UI.endBedTurn=function() return endPlayerTurn(true) end

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

local function initShadersAndCanvas()
    if love.graphics and love.graphics.newCanvas then
        local ok, canvas = pcall(love.graphics.newCanvas, RENDER_WIDTH, RENDER_HEIGHT)
        mainCanvas = ok and canvas or nil
        if mainCanvas then mainCanvas:setFilter("linear", "linear") end
    end

end

--------------------------------------------------------------------------------
-- LÖVE Callbacks
--------------------------------------------------------------------------------

function love.load()
    Rng.seed(os.time())
    UI.initFonts()
    for _, argument in ipairs(arg or {}) do
        if argument == "--test-spn-art" or argument == "--test-spn-anomalies-art" then
            local ok, err = pcall(function()
                local ids,output
                if argument=="--test-spn-anomalies-art" then
                    ids={};for _,row in ipairs(require("src.spn_anomalies").entries) do ids[#ids+1]=row[1] end
                    output="docs/spn_anomalies_runtime.png"
                end
                require("tests.spn_art_smoke").verify(ids,output)
            end)
            if not ok then print("SPN ART ERROR: " .. tostring(err)) end
            os.exit(ok and 0 or 1)
        end
    end
    UI.Polish.load()
    local nativePrint, nativePrintf = love.graphics.print, love.graphics.printf
    love.graphics.print = function(value, ...)
        return nativePrint(UI.localizeText(value), ...)
    end
    love.graphics.printf = function(value, ...)
        return nativePrintf(UI.localizeText(value), ...)
    end
    for key, path in pairs({ background = "assets/scene/shrine_lowpoly.png", humanContinent = "assets/scene/expedition_human.png", expeditionShip = "assets/scene/expedition_ship.png", mysteriousCoast = "assets/scene/expedition_coast.png", menuWorld = "assets/scene/menu_world_v2.png", menuLogo = "assets/scene/menu_logo_v2.png", enemySmall = "assets/scene/enemy_small_lowpoly.png", enemyElite = "assets/scene/enemy_elite_lowpoly.png", enemyBoss = "assets/scene/enemy_boss_lowpoly.png", chest = "assets/scene/treasure_chest.png" }) do
        if love.filesystem.getInfo(path) then
            local ok, image = pcall(love.graphics.newImage, path)
            if ok then
                image:setFilter("linear", "linear")
                battleArt[key] = image
            end
        end
    end
    EnemyArt.load()
    local menuVideoPath = "assets/scene/menu_background.ogv"
    if love.filesystem.getInfo(menuVideoPath) then
        local ok, video = pcall(love.graphics.newVideo, menuVideoPath, { audio = false })
        if ok then
            battleArt.menuVideo = video
            UI.menuBackgroundVideo = video
            video:play()
        end
    end
    settings = Persistence.loadSettings(settings)
    if Touch.nativeMobile then settings.fullscreen = true end
    for _, value in ipairs(arg or {}) do
        if value == "--capture-mobile-fullscreen" then
            settings.fullscreen, settings.graphicsQuality = false, "LOW"
            love.window.setMode(1512, 690, {resizable=true, fullscreen=false})
        end
    end
    Sound.init()
    Sound.setVolume(settings.sfxVolume)
    if settings.fullscreen then
        love.window.setFullscreen(true, "desktop")
    end
    updateScale()
    initShadersAndCanvas()
    Renderer.config.enabled = settings.cinematicEnabled
    Renderer.crtEnabled = settings.crtEnabled
    Renderer.load(battleArt, settings.graphicsQuality)
    UI.BedExplosion.load()
    DeathVFX.load()
    for _, value in ipairs(arg or {}) do
        if value == "--test-enemy-art" then
            require("tests.enemy_art_smoke")
            require("tests.enemy_art_gallery")
            love.event.quit()
            return
        end
    end
    local allCardShadersLoaded, cardShaderCount = CardEffects.load()
    if cardEffectsSmokeMode then
        if not allCardShadersLoaded then
            print("CARD EFFECT TEST FAILED: loaded " .. tostring(cardShaderCount) .. "/" .. #require("config.card_effect_config").catalogOrder .. " shaders")
            love.event.quit(1)
            return
        end
        local testOk, testErr = pcall(require, "tests.card_effects_smoke")
        if not testOk then
            print("CARD EFFECT TEST FAILED: " .. tostring(testErr))
            love.event.quit(1)
        else
            print("Card shaders and gameplay effects smoke test passed (3/3 shaders)")
            love.event.quit(0)
        end
        return
    end
    shopData = Shop.new()
    if not isCaptureMode and not Touch.previewMobile then
        local loadedGame, loadedState = Persistence.loadRun()
        if loadedGame then
            game = loadedGame
            state = loadedState or "BLIND_SELECT"
            lastActiveState = state
            hasRunStarted = true
            if state == "CASH_OUT" and game.pendingVictoryReward then
                local result = game.pendingVictoryReward
                cashOutAnim = RewardSystem.newAnimation(result.breakdown, result)
            elseif state == "socketing" and game.pendingRewardEquipment then
                pendingEquipment = game.pendingRewardEquipment
                socketingReturnState = "shop"
                Shop.refresh(shopData, game)
            elseif state == "shop" then
                Shop.refresh(shopData, game)
                RewardSystem.openNextPack(game, shopData)
            end
        end
    end
end

function love.resize(w, h)
    updateScale()
end

function love.focus(focused)
    if focused then
        if Touch.nativeMobile then love.window.setFullscreen(true, "desktop"); updateScale() end
        return
    end
    Touch.cancel()
    UI.CardPhysics.release()
    handDrag.active, handDrag.isDragging, handDrag.cardIndex = false, false, nil
    shopDrag.active, shopDrag.isDragging, shopDrag.item = false, false, nil
    shopDrag.itemIndex, shopDrag.sourceKind, shopDrag.sourceIndex = nil, nil, nil
    deityDrag.active, deityDrag.isDragging, deityDrag.deityIndex = false, false, nil
    juice.buttonPressedId = nil
end

local function updateCaptureMode()
    if not isCaptureMode or not Capture then return end
    Capture.update(game, {
        startNewGame = startNewGame,
        openDeckViewer = function() isDeckViewerOpen = true end,
        closeDeckViewer = function() isDeckViewerOpen = false;game.soulDestroyActive=false;game.soulDestroyConsumable=nil;UI.Polish.clearFocus() end,
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
        openInspector = function(card) inspectCardModal = card end,
        closeInspector = function() inspectCardModal = nil end,
        openShopTransfer = function() isShopTransferOpen = true end,
        closeShopTransfer = function() isShopTransferOpen = false end,
        getShopTransferState = function()
            return isShopTransferOpen, transferPage, transferSourceCard, transferSourceEqIndex
        end,
        openHandbook = function() isHandbookOpen = true end,
        closeHandbook = function() isHandbookOpen = false end,
        openRest = function()
            restStateData = { chosenAction = nil, selectedCard = nil, message = nil }
            state = "rest"
        end,
        openSocketing = function(eq)
            pendingEquipment = eq or Equipment.ITEMS.gem_fire
            socketingReturnState = "map"
            state = "socketing"
        end,
        selectCardIndex = function(idx) toggleCardSelection(idx) end,
        playSelectedHand = function() playSelectedHand() end,
        getScoringState = function() return anim, state end,
        previewPlayerDefeat = beginPlayerDefeat,
        endPlayerTurn = endPlayerTurn,
        setScoringSpeed = function(fast) settings.fastScoring = fast end,
        setMenuMode = function(m) menuMode = m end,
        setCaptureState = function(value) state = value end,
        openSettings = function() isSettingsOpen = true end,
        isDebugEnabled = function() return settings.debugEnabled end,
        closeSettings = function() isSettingsOpen = false end,
        openPauseMenu = function() isPauseMenuOpen = true end,
        closePauseMenu = function() isPauseMenuOpen = false end,
        openCollection = function(cat)
            isCollectionOpen = true
            collectionCategory = cat
        end,
        closeCollection = function()
            isCollectionOpen = false
            collectionCategory = nil
        end,
        openPack = function(packItem, animated)
            shopData.currentPackOpening = Shop.openPack(packItem, game)
            shopData.currentPackOpening.animationTimer = animated and 0 or UI.ChestChoices.finished()
            state = "shop"
        end,
        closePack = function() shopData.currentPackOpening = nil end,
        getShopData = function() return shopData end,
        getButtons = function() return buttons end,
        previewChest = function(rewards,boss)
            if boss then chestRewards=rewards else treasureRewards=rewards end
            socketingReturnState="map";anim.chestReveal.state=nil
            state=boss and "chest" or "treasure"
        end,
        activateStoredReward = useConsumable,
        getRewardAnimation = function() return cashOutAnim, state end,
        openReward = function(tableId)
            local blind = RunManager.getCurrentBlind(game.run)
            RunManager.completeCurrentBlind(game.run, game)
            game.pendingVictoryReward = nil
            local breakdown = RewardSystem.calculate(blind, game, false)
            local result = RewardSystem.begin(breakdown, game, {lootTableId = tableId})
            cashOutAnim = RewardSystem.newAnimation(breakdown, result)
            state, lastActiveState = "CASH_OUT", "CASH_OUT"
        end,
    })
end

function love.update(dt)
    Touch.update(dt)
    UI.components.Button.update(dt)
    if handDrag.active and handInputBlocked() then
        UI.CardPhysics.release()
        handDrag.active, handDrag.isDragging, handDrag.cardIndex = false, false, nil
    end
    if DeathVFX.kind and state ~= "playing" and state ~= "scoring" and state ~= "defeating" and state ~= "gameover" and state ~= "chest" and state ~= "treasure" and not (state == "shop" and shopData and shopData.currentPackOpening) then DeathVFX.reset() end
    if DeathVFX.monster and DeathVFX.monster ~= game.monster then DeathVFX.reset() end
    if (state == "playing" or state == "scoring") and game.monster and (game.monster.hp or 1) <= 0 then
        DeathVFX.startEnemy(game.monster, game.monster.screenX or UI.BATTLE_CENTER_X, Renderer.quality)
    end
    DeathVFX.update(dt)
    if state=="playing" or state=="scoring" or UI.BedExplosion.debug then UI.BedExplosion.update(dt) end
    if UI.BedExplosion.pending then
        UI.BedExplosion.pending=false
        anim.hitStop=math.max(anim.hitStop or 0,UI.BedExplosion.config.hitStop)
    end
    if state=="playing" then require("src.souls").awardKills(game) end
    if state=="playing" and game.monster and game.monster.hp<=0 and not DeathVFX.busy() then EnemyGroup.ensureTarget(game) end
    local cameraX, cameraY = 0, 0
    if state == "scoring" then cameraX, cameraY = UI.ScoringFeel.camera(anim) end
    local bedCameraX,bedCameraY=UI.BedExplosion.camera()
    cameraX,cameraY=cameraX+bedCameraX,cameraY+bedCameraY
    Renderer.update(dt, (state == "defeating" or (state == "gameover" and DeathVFX.kind == "player")) and "playing" or state,
        game and ((state == "BLIND_SELECT" or state == "shop" or state == "victory") and {stage=game.run and game.run.ante or 1} or game.monster), anim.sequence, cameraX, cameraY, monsterMotion.attack / 0.42, cashOutAnim, DeathVFX)
    if state == "defeating" then
        if DeathVFX.age > DeathVFX.stop then monsterMotion.attack = math.max(0,monsterMotion.attack-dt) end
        juice.ambientTimer = juice.ambientTimer + dt
        updateCaptureMode()
        if not DeathVFX.busy() then state = "gameover" end
        return
    end
    local physicsMx, physicsMy = toVirtual(love.mouse.getPosition())
    UI.CardPhysics.update(dt, physicsMx, physicsMy)
    CardEffects.update(dt)
    Feedback.updateVfx(dt)
    UI.Polish.update(dt, settings.fastScoring, state, shopData)
    UI.Description.update(dt)
    UI.AbilityUI.update(dt)
    if UI.AbilityUI.current then updateCaptureMode(); return end
    UI.ScoringFeel.updateLab(dt)
    if UI.ScoringFeel.labOpen then updateCaptureMode(); return end
    local hitStopped = (state == "scoring" or state == "playing") and (anim.hitStop or 0) > 0
    if hitStopped then anim.hitStop = math.max(0, anim.hitStop - dt) end
    local motionDt = hitStopped and 0 or dt
    Sound.setMenuMusicEnabled(state == "menu" and menuMode == "title")
    if state=="playing" and game and game.abilityCombat then
        local notices=UI.Abilities.takeFeedback(game)
        for _,notice in ipairs(notices) do
            if notice.kind=="destroy" then
                local r=UI.Polish.rect(UI,notice.card,{x=590,y=410,w=100,h=140})
                local fx=Feedback.destroyCard(notice.card,r.x+r.w/2,r.y+r.h/2)
                if fx then spawnShopFx("destroy",{category="card",card=notice.card},fx.x,fx.y,r.w,r.h) end
            end
        end
        for i=math.max(1,#notices-2),#notices do
            table.insert(anim.floatingTexts,{text=notices[i].message,color=UI.COLORS.goldYellow,x=640,y=195+(i-math.max(1,#notices-2))*22,alpha=1.4})
        end
    end
    anim.consumableUseCooldown = math.max(0, anim.consumableUseCooldown - dt)
    anim.playButtonPulse = math.max(0, (anim.playButtonPulse or 0) - dt)
    RunManager.deliverEvolutionRewards(game.run, game)
    if pendingEvolutionCard and state ~= "playing" and state ~= "shop" then
        pendingEvolutionCard = nil
    end
    if pendingEditionCard and state ~= "playing" and state ~= "shop" then pendingEditionCard = nil end
    if pendingSpeedCard and state ~= "playing" then pendingSpeedCard = nil end
    if state == "chest" or state == "treasure" then
        if anim.chestReveal.state ~= state then
            anim.chestReveal.state = state
            anim.chestReveal.timer = isCaptureMode and not chestAnimationCaptureMode and UI.ChestChoices.finished() or 0
            if anim.chestReveal.timer == 0 then DeathVFX.startChest(Renderer.quality) end
        end
        local previous = anim.chestReveal.timer
        anim.chestReveal.timer = math.min(UI.ChestChoices.finished(), previous + dt)
        for i=1,3 do
            local flipAt = DeathVFX.config.chest.flipAt + (i-1)*DeathVFX.config.chest.stagger
            if previous < flipAt and anim.chestReveal.timer >= flipAt then Sound.play("card_deal", 0.85+i*0.08) end
        end
    else
        anim.chestReveal.state = nil
        anim.chestReveal.timer = UI.ChestChoices.finished()
    end
    monsterMotion.attack = math.max(0, monsterMotion.attack - motionDt)
    monsterMotion.hit = math.max(0, monsterMotion.hit - motionDt)
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

    updateCaptureMode()

    if screenShake > 0 then
        screenShake = math.max(0, screenShake - motionDt * 15)
    end

    -- Update Map horizontal scrolling camera
    if game.map then
        Map.update(game.map, dt)
    end

    -- Smooth Monster damage lag bar
    if game.monster and game.monster.damageLagHp and game.monster.damageLagHp > game.monster.hp then
        game.monster.damageLagHp = game.monster.hp
            + (game.monster.damageLagHp - game.monster.hp) * math.exp(-motionDt * 5.5)
    end

    -- Smoothly update floating texts
    for i = #anim.floatingTexts, 1, -1 do
        local ft = anim.floatingTexts[i]
        if ft.kind then Feedback.update(ft, dt)
        else
            ft.y = ft.y - dt * 40
            ft.alpha = ft.alpha - dt * 1.1
            if ft.scale then ft.scale = ft.scale + (1 - ft.scale) * Motion.response(12, dt) end
        end
        if ft.alpha <= 0 then
            table.remove(anim.floatingTexts, i)
        end
    end

    -- Smoothly lerp number bounce scales
    if anim.bounceScale then
        for k, v in pairs(anim.bounceScale) do
            anim.bounceScale[k] = v + (1.0 - v) * Motion.response(10, dt)
        end
    end

    -- Smoothly lerp deity bounce scales
    if anim.deityBounce then
        for idx, v in pairs(anim.deityBounce) do
            anim.deityBounce[idx] = v + (1.0 - v) * Motion.response(10, dt)
        end
    end

    -- Smoothly lerp card squash & stretch
    if anim.cardBounce then
        for idx, b in pairs(anim.cardBounce) do
            b.scaleX = b.scaleX + (1.0 - b.scaleX) * Motion.response(12, dt)
            b.scaleY = b.scaleY + (1.0 - b.scaleY) * Motion.response(12, dt)
        end
    end
    if anim.cardHit then
        for idx, age in pairs(anim.cardHit) do
            age = age + dt
            anim.cardHit[idx] = age < 0.36 and age or nil
        end
    end

    -- ScoringPresentation owns conversion and projectile timing; sprites never advance independently.

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
                if not waitingForDeal then
                    c.visualX = c.visualX + (tx - c.visualX) * Motion.response(18, dt)
                    c.visualY = c.visualY + (ty - c.visualY) * Motion.response(18, dt)
                    local curAngle = c.visualAngle or 0
                    c.visualAngle = curAngle + ((tangle or 0) - curAngle) * Motion.response(18, dt)
                    c.rotation = c.visualAngle
                end
            end
            c.selectPulse = math.max(0, (c.selectPulse or 0) - dt * 4.5)
            local targetScale = c.selected and 1.11 or (c.hovered and 1.075 or 1.0)
            targetScale = targetScale + math.sin((c.selectPulse or 0) * math.pi) * 0.07
            c.visualScale = (c.visualScale or 1.0) + (targetScale - (c.visualScale or 1.0)) * Motion.response(14, dt)
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
    juice.goldBounce = juice.goldBounce + (1.0 - juice.goldBounce) * Motion.response(10, dt)
    juice.hpBounce = juice.hpBounce + (1.0 - juice.hpBounce) * Motion.response(18, dt)
    juice.armorBounce = juice.armorBounce + (1.0 - juice.armorBounce) * Motion.response(22, dt)
    juice.handRankBounce = juice.handRankBounce + (1.0 - juice.handRankBounce) * Motion.response(10, dt)

    if state == "shop" and shopData and not UI.Polish.busy() and not shopData.currentPackOpening then
        local opened, message = RewardSystem.openNextPack(game, shopData)
        if opened then
            saveRunAtSafePoint()
            if message then table.insert(anim.floatingTexts, {text = message, color = UI.COLORS.goldYellow, x = 640, y = 200, alpha = 2}) end
        end
    end
    if shopData and shopData.currentPackOpening and not UI.Polish.busy() then
        local opening = shopData.currentPackOpening
        local previous = opening.animationTimer or 0
        if not opening.ashStarted then
            opening.ashStarted = true
            if previous < DeathVFX.config.chest.duration then DeathVFX.startChest(Renderer.quality) end
        end
        opening.animationTimer = math.min(UI.ChestChoices.finished(), previous + dt)
        for i=1,3 do
            local flipAt=DeathVFX.config.chest.flipAt+(i-1)*DeathVFX.config.chest.stagger
            if previous<flipAt and opening.animationTimer>=flipAt then Sound.play("card_deal",0.85+i*0.08) end
        end
    end
    for i = #shopFx, 1, -1 do
        local fx = shopFx[i]
        fx.life = fx.life + dt * (settings.fastScoring and UI.Polish.config.fastFactor or 1)
        if fx.accentPending and fx.life>=fx.duration*0.82 then
            fx.accentPending=false;Feedback.emit("buy",fx.targetX,fx.targetY)
        end
        if fx.life >= fx.duration then table.remove(shopFx, i) end
    end
    for _, card in ipairs(anim.playedCards or {}) do
        if card.destroyFxActive then
            card.destroyFx = math.min(1, (card.destroyFx or 0) + dt * 1.9)
        end
    end

    -- Gold change detection
    if game.gold and juice.lastGold and game.gold ~= juice.lastGold then
        local delta = game.gold - juice.lastGold
        juice.goldBounce = delta > 0 and 1.24 or 1.12
        if not UI.Polish.busy() then
            local pos = state == "shop" and UI.Polish.config.gold
                or isDeckViewerOpen and UI.Polish.config.viewerGold or {x=475,y=38}
            local ft = Feedback.add(juice.floatingTexts, "gold", delta, pos.x, pos.y+58, UI.formatNumber)
            ft.target = pos
        end
        juice.lastGold = game.gold
    end

    -- HP change detection
    if game.playerHp and juice.lastHp and game.playerHp ~= juice.lastHp then
        if game.playerHp < juice.lastHp then
            juice.hpBounce = 1.10
            Feedback.add(juice.floatingTexts, "heal", game.playerHp-juice.lastHp, 300, 114, UI.formatNumber)
        elseif game.playerHp > juice.lastHp then
            juice.hpBounce = 1.055
            Feedback.add(juice.floatingTexts, "heal", game.playerHp-juice.lastHp, 300, 114, UI.formatNumber)
        end
        juice.lastHp = game.playerHp
    end

    local armor = game.playerArmor or game.playerShield or 0
    if armor ~= juice.lastArmor then
        juice.armorBounce = armor < juice.lastArmor and 1.12 or 1.08
        Feedback.add(juice.floatingTexts, "armor", armor-juice.lastArmor, 375, 85, UI.formatNumber)
        juice.lastArmor = armor
    end

    -- Update juice floating texts
    for i = #juice.floatingTexts, 1, -1 do
        local ft = juice.floatingTexts[i]
        if ft.kind then Feedback.update(ft, dt)
        else ft.life = ft.life - dt; ft.y = ft.y + ft.vy * dt end
        if ft.life <= 0 then
            table.remove(juice.floatingTexts, i)
        end
    end

    -- CardPhysics owns held visuals; drag controllers only handle logical input.

    if state == "CASH_OUT" and cashOutAnim then
        RewardSystem.update(cashOutAnim, dt * (settings.fastScoring and 2 or 1))
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
            c.tiltX = (c.tiltX or 0) + (targetTiltX - (c.tiltX or 0)) * Motion.response(16, dt)
            c.tiltY = (c.tiltY or 0) + (targetTiltY - (c.tiltY or 0)) * Motion.response(16, dt)
        end
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

    -- Scoring feedback is event-bound; no frame-rate-dependent continuous particle emission.

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
    anim.screenFlash = math.max(0, (anim.screenFlash or 0) - dt)
    anim.screenDistortion = math.max(0, (anim.screenDistortion or 0) - dt)
    if anim.enemyTurn then
        local turn = anim.enemyTurn
        if EnemyAttack.update(turn, game, motionDt) then
            anim.enemyTurn = nil
            turn.onDone()
        end
        return
    end
    -- The presentation queue yields only when energy has physically reached the enemy.
    if state == "scoring" and anim.active then
        local deathStop = DeathVFX.enemyActive(game.monster) and DeathVFX.age < DeathVFX.stop
        local st
        if anim.pendingBedScore then
            if UI.BedExplosion.takeImpact() then st=anim.pendingBedScore;anim.pendingBedScore=nil end
        else
            st=UI.ScoringFeel.update(anim, deathStop and 0 or motionDt, settings.fastScoring)
            if st and st.type=="final_score" and #Combat.bedExplosions(game,st.finalScore)>0 then
                anim.pendingBedScore=st
                UI.BedExplosion.start(game.monster.screenX or UI.BATTLE_CENTER_X,410,Renderer.quality,Renderer.scene.weather)
                st=nil
            end
        end
        local steps = anim.scoringData.steps
        if st or UI.ScoringFeel.isFinished(anim) then
            if st then
                if st.type == "final_score" then
                    local monsterHpBeforeHit = (game.monster and game.monster.hp) or 0
                    local armorBeforeHit = game.monster.creatureArmor or 0
                    local actualDmg, defeated, splashHits = Combat.resolvePlayerAttack(game, st.finalScore)
                    require("src.spn_anomalies").showFeedback(game,anim)
                    for _, hit in ipairs(splashHits) do
                        local x = hit.enemy.screenX or UI.BATTLE_CENTER_X
                        local ft = Feedback.add(anim.floatingTexts, "damage", hit.damage, x, 214, UI.formatNumber)
                        ft.label = hit.deity.name .. (hit.explosion and " · NỔ GIƯỜNG" or " · AURA LAN")
                        hit.enemy.hitFlash = 0.24
                        CardEffects.triggerScorePulse(hit.deity)
                        anim.deityBounce[hit.slotIndex] = 1.15
                        if hit.enemy.hp <= 0 then DeathVFX.startEnemy(hit.enemy, x, Renderer.quality) end
                    end
                    for _,enemy in ipairs(require("src.enemy_group").members(game)) do
                        if enemy.bedHeal then
                            local ft=Feedback.add(anim.floatingTexts,"heal",enemy.bedHeal,enemy.screenX or UI.BATTLE_CENTER_X,184,UI.formatNumber)
                            ft.label="GIƯỜNG · HỒI ĐẦY HP";enemy.bedHeal=nil
                        end
                    end
                    anim.damageDealt = actualDmg
                    anim.monsterDefeated = defeated
                    UI.ScoringFeel.damageApplied(anim, game.monster.hp, actualDmg)
                    if armorBeforeHit > (game.monster.creatureArmor or 0) then
                        local ft = Feedback.add(anim.floatingTexts, "armor", -(armorBeforeHit-game.monster.creatureArmor),
                            game.monster.screenX or UI.BATTLE_CENTER_X, 176, UI.formatNumber)
                        ft.label = "GIÁP HẤP THỤ"
                    end
                    monsterMotion.hit = 0.24
                    -- HandAttacks draws capped directional impact sparks; avoid duplicate radial burst.

                    if defeated then
                        DeathVFX.startEnemy(game.monster, game.monster.screenX or UI.BATTLE_CENTER_X, Renderer.quality)
                        Sound.play("jackpot")
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
                                    r = Deities.scaleEffect(effectiveDeity, r)
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
                            deityBonus = deityBonus + Deck.SEALS.seal_bounty.params.gold
                            table.insert(anim.floatingTexts, {
                                text = "💰 [ẤN TRUY NÃ] Kết liễu quái: +"..Deck.SEALS.seal_bounty.params.gold.." Vàng!",
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
                                            if #game.consumables < UI.Inventory.limit(game) then
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
                                                    text = "🔵 [DẤU LAM] Ô Tiêu Hao đã đầy!",
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
                        if UI.BossAbilities.afterScore(game,anim.evalResult and anim.evalResult.scoringCards) then
                            table.insert(anim.floatingTexts,{text="[THE ARM] Lá tính điểm -1 Rank lâu dài!",color={0.85,0.35,0.35,1},x=640,y=400,alpha=2.5})
                        end

                        if game.playerHp <= 0 then
                            anim.playerKilled = true
                    end
                    end
                end
            else
                if UI.ScoringFeel.isFinished(anim) then
                    if DeathVFX.enemyActive(game.monster) and DeathVFX.busy() then return end
                    if not anim.counterAttackStarted and Combat.getOutcome(game) ~= "victory" then
                        anim.counterAttackStarted = true
                        if startEnemyAttack("after", anim.playerAttackSpeed, function() end) then return end
                    end
                    anim.active = false
                    if game.monster then game.monster.damageLagHp = game.monster.hp end
                    UI.Abilities.finishHand(game)
                    -- Resolve from live HP/hand state so stale animation flags can
                    -- never turn a defeated monster into a game over.
                    local combatOutcome = Combat.getOutcome(game)
                    anim.monsterDefeated = combatOutcome == "victory"
                    anim.playerKilled = combatOutcome == "defeat" and game.playerHp ~= nil and game.playerHp <= 0

                    if anim.playerKilled then
                        beginPlayerDefeat()
                        Persistence.deleteRun()
                        return
                    end
                    if combatOutcome == "defeat" then
                        beginPlayerDefeat()
                        Persistence.deleteRun()
                        return
                    end

                    anim.playedCards = {}

                    if anim.monsterDefeated then
                        UI.Abilities.combatWin(game)
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
                            local evolutionReward = RunManager.completeCurrentBlind(game.run, game)
                            if evolutionReward then
                                table.insert(anim.floatingTexts, {
                                    text = "Hoàn tất vòng ải " .. tostring(game.run.ante) .. " · Chọn một trong ba phần thưởng",
                                    color = { 0.82, 0.70, 1, 1 }, x = 640, y = 205, alpha = 2.6,
                                })
                            end
                            local breakdown = RewardSystem.calculate(curBlind, game, false)
                            local rewardResult = RewardSystem.begin(breakdown, game)
                            cashOutAnim = RewardSystem.newAnimation(breakdown, rewardResult)
                            state = "CASH_OUT"
                            lastActiveState = "CASH_OUT"
                            saveRunAtSafePoint()
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
                        -- Preserve per-hand lifecycle effects; turn recycling itself
                        -- only happens when the player explicitly ends the turn.
                        Combat.cleanupDestroyedCards(game)
                        Combat.onPlayerTurnEnd(game)
                        local cleansed, cleanseMsg = Combat.onMonsterTurnEnd(game)
                        if cleansed then
                            table.insert(anim.floatingTexts, {
                                text = "✨ " .. cleanseMsg,
                                color = UI.COLORS.hpGreen,
                                x = 640,
                                y = 300,
                                alpha = 3.0,
                            })
                        end
                        EnemyGroup.ensureTarget(game)
                        dealCombatHand(false)
                        UI.Abilities.handStart(game)
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

    -- Menu video / painting is rendered in the shared World Canvas.
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
    g.print("beta 0.88.7", 48, 185)
    -- g.print("LỤC ĐỊA THỨC TỈNH", 76, 168)
    -- g.setFont(UI.fonts.tiny)
    -- g.setColor(UI.COLORS.textLight)
    -- g.print("ROGUELIKE POKER TCG", 78, 194)

    local menuItems = {
        { id = "menu_play", text = hasRunStarted and "TIẾP TỤC" or "VÀO TRẬN",
            sub = "KHÁM PHÁ LỤC ĐỊA", icon = "⚔", color = { 0.05, 0.26, 0.49, 1 },
            menuAccent = { 0.55, 0.81, 1, 1 }, assetId = "menu_frame_blue" },
        { id = "menu_collection", text = "BỘ SƯU TẬP",
            sub = "BÀI • SPN • TRANG BỊ", icon = "▣", color = { 0.32, 0.21, 0.07, 1 },
            menuAccent = UI.COLORS.goldYellow, assetId = "menu_frame_gold" },
        { id = "menu_settings", text = "TÙY CHỌN",
            sub = "CÀI ĐẶT TRÒ CHƠI", icon = "✦", color = { 0.28, 0.09, 0.39, 1 },
            menuAccent = { 0.83, 0.55, 0.95, 1 }, assetId = "menu_frame_violet" },
        { id = "menu_quit", text = "THOÁT",
            sub = "TẠM BIỆT", icon = "⇥", color = { 0.42, 0.08, 0.10, 1 },
            menuAccent = { 1, 0.47, 0.45, 1 }, assetId = "menu_frame_red" },
    }
    for i, item in ipairs(menuItems) do
        local btn = {
            id = item.id, text = item.text, sub = item.sub, icon = item.icon,
            x = 808, y = 234 + (i - 1) * 91, w = 426, h = 74,
            color = item.color, menuAccent = item.menuAccent, menuStyle = true,
            font = UI.fonts.large, backgroundImage = UI.getButtonImage(item.assetId),
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
    -- World backdrop is supplied by Renderer.
    Renderer.veil()
    UI.drawGildedPanel(60, 34, 1160, 640)

    g.setFont(UI.fonts.title)
    g.setColor(UI.COLORS.goldYellow)
    g.printf("BỘ SƯU TẬP", 90, 56, 1100, "center")
    g.setFont(UI.fonts.small)
    g.setColor(UI.COLORS.textMuted)
    g.printf("Khám phá toàn bộ bài, SPN, trang bị và thử thách", 90, 98, 1100, "center")

    local categories = {
        { id = "jokers", title = "SPN", icon = "✦", accent = { 0.62, 0.80, 1, 1 } },
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

    -- World backdrop is supplied by Renderer.
    love.graphics.setColor(0.01, 0.02, 0.04, Renderer.config.ui.veil)
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

    local collectionHeaderX = modalX + 270
    local collectionHeaderW = modalW - 294
    local collectionTitle = string.upper(cat.title) .. " • " .. cat.sub
    local collectionTitleFont = UI.fonts.large
    local collectionTitleScale = math.min(1, collectionHeaderW / math.max(1, collectionTitleFont:getWidth(collectionTitle)))
    love.graphics.setFont(collectionTitleFont)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print(collectionTitle, collectionHeaderX, modalY + 20, 0, collectionTitleScale, collectionTitleScale)

    local collectionSubtitle = #items .. " Mục đã mở khóa • Nhấp hoặc rê chuột vào thẻ để xem chi tiết"
    local collectionSubtitleFont = UI.fonts.small
    local collectionSubtitleScale = math.min(1, collectionHeaderW / math.max(1, collectionSubtitleFont:getWidth(collectionSubtitle)))
    love.graphics.setFont(collectionSubtitleFont)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.print(collectionSubtitle, collectionHeaderX + 2, modalY + 50, 0, collectionSubtitleScale, collectionSubtitleScale)

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

    if mainCanvas then
        love.graphics.intersectScissor(gridX * RENDER_SCALE, gridY * RENDER_SCALE,
            gridW * RENDER_SCALE, gridH * RENDER_SCALE)
    else
        local outputScale = scale * RENDER_SCALE
        local outputScaleY = Layout.scaleY * RENDER_SCALE
        love.graphics.intersectScissor(offsetX + gridX * outputScale, offsetY + gridY * outputScaleY,
            gridW * outputScale, gridH * outputScaleY)
    end

    for i, item in ipairs(items) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = gridX + col * (cardW + padX)
        local cy = gridY + row * (cardH + padY) - collectionScrollY

        if cy + cardH >= gridY - 20 and cy <= gridY + gridH + 20 then
            local isH = (mx >= cx and mx <= cx + cardW and my >= cy and my <= cy + cardH and my >= gridY and my <= gridY + gridH)
            if isH then hoveredItem = item end

            require("ui.card_surfaces").catalog(item, cx, cy, cardW, cardH, collectionCategory, isH, mx, my)
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

        require("ui.card_surfaces").preview(inspItem, lcx, lcy, lcw, lch, collectionCategory)

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
    Renderer.veil()

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
    love.graphics.printf("Bắt đầu với 1 lá bài ngẫu nhiên; mở rộng bộ bài trong hành trình.", 0, 85, V_WIDTH, "center")

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
    love.graphics.printf("Khởi đầu với 1 lá ngẫu nhiên. Đánh bại BOSS để chọn thêm Hộ Linh!", 0, V_HEIGHT - 35, V_WIDTH, "center")
end

local function drawStarterDeckSelect()
    local winW, winH = love.graphics.getDimensions()
    -- World backdrop is supplied by Renderer.
    Renderer.veil()
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
    local cardW, cardH = 262, 350
    local cardX, cardY = (V_WIDTH - cardW) / 2, 135
    local hovered = mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH
    require("ui.card_surfaces").starter(deckInfo, cardX, cardY, cardW, cardH)

    local choose = {
        id = "deck_red", deckId = "red_deck", text = "BẮT ĐẦU HÀNH TRÌNH",
        x = cardX - 24, y = cardY + cardH + 30, w = cardW + 48, h = 44,
        color = deckInfo.color, font = UI.fonts.medium,
    }
    table.insert(buttons, choose)
    UI.drawButton(choose, hovered, juice.buttonPressedId == choose.id)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("1 lá ban đầu • Thu thập thêm bài trong hành trình • Tốc đánh từ 1 đến 999", 0, V_HEIGHT - 50, V_WIDTH, "center")
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
    local hudButtons = UI.components.TopHUD.draw({
        ante = (game.run and game.run.ante) or game.act or 1,
        round = (game.run and game.run.currentBlindIndex) or game.round or 1,
        enemyName = m and m.name or "Đối thủ",
        hp = game.playerHp, maxHp = game.maxPlayerHp, gold = game.gold or 0, souls = game.souls or 0,
        armor = game.playerArmor or game.playerShield or 0,
        armorCap = UI.Abilities.config.armorCap, goldBounce = juice.goldBounce,
        hpBounce = juice.hpBounce, armorBounce = juice.armorBounce,
        hands = game.handsRemaining or 0, maxHands = game.maxHands or 0,
        discards = game.discardsRemaining or 0,
    }, UI.fonts, mx, my, juice.buttonPressedId)
    for _, btn in ipairs(hudButtons) do table.insert(buttons, btn) end
end

local function drawBattleEnemyWorld(m)
    if not m then return end
    EnemyFormation.world(game,UI,Renderer,EnemyArt,DeathVFX,battleArt,juice.ambientTimer or 0,monsterMotion,state=="scoring" and anim or nil,anim.enemyTurn)
end

local function drawBattleEnemy(m)
    if not m then return end
    local mx,my=toVirtual(love.mouse.getPosition())
    EnemyFormation.hud(game,UI,mx,my,anim.enemyTurn)
end

local function drawBattleInfoPanel(m, eval, preview)
    local scoring = state == "scoring" and anim.active
    local chips = scoring and (anim.displayChips or 0) or (preview and preview.totalChips or 0)
    local mult = scoring and (anim.displayMult or 0) or (preview and preview.totalMult or 0)
    local xMult = scoring and (anim.displayXMult or 1) or (preview and preview.xMultTotal or 1)
    local aura = scoring and (anim.displayAura or anim.displayFinalScore or 0) or 0
    local handName = scoring and (anim.sequence and anim.sequence.handName)
        or (eval and eval.type and eval.type.vnName) or "Chọn bài để xem"
    local finished = scoring and anim.scoringData and anim.currentStepIndex > #anim.scoringData.steps
    local detail = scoring and (finished and (anim.monsterDefeated and ("Hạ quái • +$" .. tostring(anim.earnedGold or 0))
        or ("Đã gây " .. UI.formatNumber(anim.displayFinalScore or 0) .. " sát thương"))
        or UI.localizeText(anim.stepLog or "")) or ""
    UI.components.HandInfoPanel.draw({
        handName = UI.truncateUtf8(handName, 24), chips = chips, mult = mult, xMult = xMult, aura = aura,
        scoring = scoring, enemyName = UI.truncateUtf8((m and m.name) or "Không rõ", 13),
        enemyHp = math.floor(math.max(0, scoring and anim.sequence.hp or (m and m.hp) or 0)), enemyMaxHp = (m and m.maxHp) or 1,
        enemyBarHp = scoring and anim.sequence.hp or (m and (m.damageLagHp or m.hp) or 0),
        enemyTrailHp = scoring and anim.sequence.hpTrail,
        auraIntensity = scoring and anim.sequence.intensity or 0,
        formula = scoring and anim.sequence.events[anim.sequence.index]
            and anim.sequence.events[anim.sequence.index].kind == "FORMULA"
            and UI.ScoringFeel.formula(anim.sequence) or nil,
        intent = UI.localizeText((m and m.intent and m.intent.label) or "Chưa rõ"),
        playerSpeed = scoring and anim.playerAttackSpeed
            or (#(game.selectedIndices or {}) > 0 and Combat.getAverageAttackSpeed(getSelectedCards()) or nil),
        enemySpeed = m and (m.attackSpeed or 1),
        humanEnemy = m and m.human,
        chipsBounce = scoring and anim.bounceScale.chips or 1,
        multBounce = scoring and anim.bounceScale.mult or 1,
        auraBounce = scoring and anim.bounceScale.score or 1,
        debuff = m and m.enemyAbility and (m.enemyAbility.name..": "..m.enemyAbility.desc) or UI.truncateUtf8(m and m.bossData and m.bossData.desc or "Không có hiệu ứng bất lợi", 55),
        boss = m,
        isBoss = m and m.bossData ~= nil,
        category = finished and "KẾT QUẢ" or (anim.stepCategory or "ĐANG CỘNG AURA"),
        detail = UI.truncateUtf8(detail, 55),
    }, UI.fonts, UI.formatNumber)
end

local function drawCombatFeedback()
    local turn = anim.enemyTurn
    if not turn and state == "scoring" and anim.sequence then
        local ev = anim.sequence.events[anim.sequence.index]
        local label = ev and (ev.kind == "ANTICIPATION" and "BẠN CHUẨN BỊ RA ĐÒN"
            or ev.kind == "ATTACK" and "BẠN TẤN CÔNG!"
            or ev.kind == "ENEMY_IMPACT" and "BẠN ĐÁNH TRÚNG QUÁI")
        if label then
            love.graphics.setFont(UI.fonts.medium)
            love.graphics.setColor(1, 0.83, 0.42, 1)
            love.graphics.printf(label, 310, 438, 640, "center")
        end
    end
    if anim.particles and #anim.particles > 0 then
        love.graphics.setBlendMode("add")
        for _, p in ipairs(anim.particles) do
            local alpha = math.max(0, p.alpha or (p.life / p.maxLife))
            local col = p.color or UI.COLORS.goldYellow
            love.graphics.setColor(p.r or col[1], p.g or col[2], p.b or col[3], alpha)
            love.graphics.circle("fill", p.x, p.y, p.size * (p.life / p.maxLife))
        end
        love.graphics.setBlendMode("alpha")
    end

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

    if (anim.screenFlash or 0) > 0 then
        local alpha = math.min(0.12, (anim.screenFlash / 0.105) * 0.12)
        love.graphics.setBlendMode("add")
        love.graphics.setColor(1, 0.90, 0.72, alpha)
        love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)
        love.graphics.setBlendMode("alpha")
    end

    for _, ft in ipairs(anim.floatingTexts) do
        Feedback.draw(ft, UI)
    end
end

local function drawPlayingState()
    syncCardSelections()
    local mx, my = toVirtual(love.mouse.getPosition())
    if state == "defeating" or state == "gameover" then mx,my=-1000,-1000 end
    hoveredDeityTooltip = nil
    hoveredCardTooltip = nil
    buttons = {}

    local m = game.monster
    -- Preview uses the same scoring logic as the attack animation.
    local selectedCards = getSelectedCards()
    local eval = (#selectedCards > 0) and Poker.evaluate(selectedCards, game.unlockedHands, game.handLevels) or nil
    local scPreview = eval and Scoring.calculate(eval, game.deities, {
        preview = true,
        gameState = game,
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
    local curDeiCount = Deities.getCount(game.deities)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    local firstDei,lastDei=UI.InventoryRail.range("spn",game)
    local firstCon,lastCon=UI.InventoryRail.range("consumable",game)
    UI.components.SPMPanel.draw(curDeiCount, maxDeiSlots, UI.fonts, UI.getPanelImage("spm_row_frame_v1"))
    game.consumables = game.consumables or {}
    local conCount = #game.consumables
    local maxConsumableSlots = UI.Inventory.limit(game)
    UI.components.ConsumablePanel.draw(conCount, UI.Inventory.limit(game), UI.fonts, maxDeiSlots,
        UI.getPanelImage("consumable_row_frame_v1"))
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local spnRect,consRect=Layout.battle.spm,Layout.battle.consumables
    love.graphics.printf(UI.InventoryRail.hint("spn",game),spnRect[1]+130,spnRect[2]+10,spnRect[3]-140,"right")
    love.graphics.printf(UI.InventoryRail.hint("consumable",game),consRect[1]+130,consRect[2]+10,consRect[3]-140,"right")

    -- 2. RIGHT RAIL: SPM & CONSUMABLES
    ----------------------------------------------------------------------------
    local topStartX = 1042
    local topStartY = 82

    -- Deities Section
    -- Heading is owned by the reusable SPMPanel.

    local hoveredDeityIndex = nil
    if not (deityDrag.active and deityDrag.isDragging) then
        -- The fan exposes right corners, where rarity pennants are anchored.
        for i = firstDei, lastDei do
            local dx, dy, dw, dh = getDeitySlotRect(i, "playing")
            local d = game.deities and game.deities[i]
            if d and mx >= dx and mx <= dx + dw and my >= dy and my <= dy + dh then
                hoveredDeityIndex = i
                break
            end
        end
    end
    for i = lastDei, firstDei, -1 do
        local dx, deityY, deitySlotW, deitySlotH = getDeitySlotRect(i, "playing")
        local d = game.deities and game.deities[i]
        local isDraggedSource = (deityDrag.active and deityDrag.isDragging and deityDrag.deityIndex == i)
        local isHoveredSlot = (mx >= dx and mx <= dx + deitySlotW and my >= deityY and my <= deityY + deitySlotH)
        local isDropTarget = (deityDrag.active and deityDrag.isDragging and isHoveredSlot and deityDrag.deityIndex ~= i)

        if d then
            local isHoveredCard = hoveredDeityIndex == i
            if isHoveredCard then
                hoveredDeityTooltip = d
                d.slotIndex = i
            end

            -- Slot bounce effect
            local bScale = math.min(state == "scoring" and 1.16 or 1.02, anim.deityBounce and anim.deityBounce[i] or 1.0)
            love.graphics.push()
            local deityFloat = math.sin(((juice and juice.ambientTimer) or 0) * 1.15 + i * 0.72) * 2
            love.graphics.translate(dx + deitySlotW / 2, deityY + deitySlotH / 2 + deityFloat - (bScale - 1) * 45)
            love.graphics.rotate(math.sin(((juice and juice.ambientTimer) or 0) * 0.75 + i) * 0.008)
            if bScale > 1.01 then
                love.graphics.scale(bScale, bScale)
            end
            love.graphics.translate(-dx - deitySlotW / 2, -deityY - deitySlotH / 2)

            local copyTarget = d.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, i)
            UI.drawPatronCard(d, dx, deityY, deitySlotW, deitySlotH, isHoveredCard,
                juice.buttonPressedId == ("deity_" .. i), isDropTarget, copyTarget)
            if pendingEvolutionCard then
                love.graphics.setLineWidth(2.5)
                love.graphics.setColor(0.84, 0.68, 1, 0.95)
                UI.drawCardBorder(dx, deityY, deitySlotW, deitySlotH, UI.COLORS.goldYellow)
            end
            love.graphics.pop()
        elseif isDropTarget then
            UI.drawSlot("selected", "spm", dx, deityY, deitySlotW, deitySlotH)
        end
    end

    -- Consumables Section (0/3)
    -- Empty capacity is intentionally invisible; occupied cards share one fan row.
    local hoveredConsumableIndex = nil
    for j = lastCon, firstCon, -1 do
        local cx, cy = getConsumableSlotRect(j, "playing")
        local c = game.consumables[j]
        if c and mx >= cx and mx <= cx + 82 and my >= cy and my <= cy + 118 then
            hoveredConsumableIndex = j
            break
        end
    end
    for j = firstCon, lastCon do
        local cx, cy, cardW, cardH = getConsumableSlotRect(j, "playing")
        local c = game.consumables[j]
        if c then
            drawBattleConsumableCard(c, cx, cy, cardW, cardH, j, mx, my, j == hoveredConsumableIndex)
        end
    end

    ----------------------------------------------------------------------------
    -- PLAYER HAND CARDS
    ----------------------------------------------------------------------------
    local cardW = 100
    local cardH = 145
    local hoveredCard = nil
    local hoveredIdx = nil

    if not handInputBlocked() and not (handDrag.active and handDrag.isDragging) then
        hoveredIdx = handDrag.cardAt(mx, my)
    end
    for i, c in ipairs(game.hand) do
        c.hovered = i == hoveredIdx
    end
    if hoveredIdx then
        hoveredCard = game.hand[hoveredIdx]
        hoveredCardTooltip = hoveredCard
    end

    -- Draw non-dragged cards in order 1 to #game.hand
    for i, c in ipairs(game.hand) do
        do -- Physics lifts the single held card into the shared overlay.
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
            if state == "defeating" or (state == "gameover" and DeathVFX.kind == "player") then
                DeathVFX.drawCard(UI, c, cx, cy, cardW, cardH, i)
            else UI.drawCard(c, cx, cy, cardW, cardH, false, c.hovered) end
        end
    end



    -- Draw Balatro hover badge above hovered card
    if state == "defeating" or (state == "gameover" and DeathVFX.kind == "player") then
        hoveredCard = nil
        for i,c in ipairs(DeathVFX.cards or {}) do
            DeathVFX.drawCard(UI,c,UI.BATTLE_CENTER_X-50+(i-(#DeathVFX.cards+1)/2)*110,466,cardW,cardH,i)
        end
    end
    if hoveredCard and not (handDrag.active and handDrag.isDragging) then
        UI.drawCardHoverBadge(hoveredCard, hoveredCard.visualX or 0, hoveredCard.visualY or 0, cardW, cardH)
    end

    -- Hand count badge (e.g. 3/3) above action buttons
    local maxHandSize = (game.selectedFaction == "elaris" or game.selectedSuit == "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
    local handCountText = #game.hand .. "/" .. maxHandSize .. "  •  Chọn "
        .. #game.selectedIndices .. "/" .. getMaxSelectableCards()
    local hcW = 150
    local hcH = 22
    local hcX = UI.BATTLE_CENTER_X - hcW / 2
    local hcY = 608
    UI.components.Panel.draw(hcX, hcY, hcW, hcH)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf(handCountText, hcX, hcY + 3, hcW, "center")
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf(Touch.enabled and "Chạm: chọn • Rê: chọn nhiều • Giữ: xem / dùng • Đổi chỗ: kéo sắp xếp"
        or "Giữ chuột: rê chọn • Shift + kéo: đổi vị trí", UI.BATTLE_ARENA_X,
        704, UI.BATTLE_ARENA_W, "center")

    ----------------------------------------------------------------------------
    -- 5. BALATRO ACTION BUTTONS ROW
    ----------------------------------------------------------------------------
    local hasSelection = (#selectedCards >= 1 and #selectedCards <= getMaxSelectableCards())
    local actionY = 636
    UI.components.Panel.draw(365, 626, 530, 72)

    -- Left: Chơi Tay Bài [Space]
    local handLimitIsFinal = game.monster and game.monster.isBoss and game.monster.bossData
        and game.monster.bossData.debuffId == "the_needle" and UI.BossAbilities.passiveEnabled(game.monster)
    local canEndTurn = not (handLimitIsFinal and (game.handsRemaining or 0) <= 0)
        and (#game.hand == 0 or (game.handsRemaining or 0) <= 0)
        and (#(game.hand or {}) + #(game.deck or {}) + #(game.discardPile or {}) > 0)
    local btnPlay = {
        id = canEndTurn and "end_turn" or "play",
        text = state == "scoring" and not anim.enemyTurn and "ĐANG TÍNH AURA" or (canEndTurn and "KẾT THÚC LƯỢT" or "Chơi Tay Bài"),
        x = UI.BATTLE_CENTER_X - 255,
        y = actionY,
        w = 175,
        h = 58,
        font = UI.fonts.small,
        variant = "cyan",
        disabled = anim.enemyTurn ~= nil or state == "scoring" or (not canEndTurn and (not hasSelection or game.handsRemaining <= 0)),
        pressScale = 0.95,
    }
    if anim.playButtonPulse > 0 then
        local pulseProgress = 1 - anim.playButtonPulse / UI.ScoringFeel.config.timing.button
        btnPlay.animationScale = 1 - 0.05 * (1 - pulseProgress) * math.cos(pulseProgress * math.pi * 2)
    end
    table.insert(buttons, btnPlay)
    UI.drawButton(btnPlay, mx >= btnPlay.x and mx <= btnPlay.x + btnPlay.w and my >= btnPlay.y and my <= btnPlay.y + btnPlay.h,
        juice.buttonPressedId == btnPlay.id)

    -- Center: Sắp Xếp Container Box
    local sortBoxX = UI.BATTLE_CENTER_X - 65
    local sortBoxY = actionY - 8
    local sortBoxW = 145
    local sortBoxH = 68
    UI.components.Panel.draw(sortBoxX, sortBoxY, sortBoxW, sortBoxH)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(Theme.colors.muted)
    love.graphics.printf("SẮP XẾP BÀI", sortBoxX, sortBoxY + 4, sortBoxW, "center")

    local btnSortRank = {
        id = "sort_rank",
        text = "Bậc",
        x = sortBoxX + 6,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        font = UI.fonts.tiny,
        selected = game.sortMode == "rank",
    }
    table.insert(buttons, btnSortRank)
    UI.drawButton(btnSortRank, mx >= btnSortRank.x and mx <= btnSortRank.x + btnSortRank.w and my >= btnSortRank.y and my <= btnSortRank.y + btnSortRank.h,
        juice.buttonPressedId == btnSortRank.id)

    local btnSortSuit = {
        id = "sort_suit",
        text = "Chất",
        x = sortBoxX + 76,
        y = sortBoxY + 24,
        w = 62,
        h = 36,
        font = UI.fonts.tiny,
        selected = game.sortMode == "suit",
    }
    table.insert(buttons, btnSortSuit)
    UI.drawButton(btnSortSuit, mx >= btnSortSuit.x and mx <= btnSortSuit.x + btnSortSuit.w and my >= btnSortSuit.y and my <= btnSortSuit.y + btnSortSuit.h,
        juice.buttonPressedId == btnSortSuit.id)

    -- Right: Bỏ Bài [D]
    local btnDiscard = {
        id = "discard",
        text = "Bỏ Bài",
        x = UI.BATTLE_CENTER_X + 95,
        y = actionY,
        w = 160,
        h = 58,
        font = UI.fonts.small,
        variant = "red",
        disabled = not hasSelection or game.discardsRemaining <= 0,
    }
    table.insert(buttons, btnDiscard)
    UI.drawButton(btnDiscard, mx >= btnDiscard.x and mx <= btnDiscard.x + btnDiscard.w and my >= btnDiscard.y and my <= btnDiscard.y + btnDiscard.h,
        juice.buttonPressedId == btnDiscard.id)

    if Touch.enabled then
        local btnTouch = {id="touch_reorder",text=Touch.reorder and "ĐANG ĐỔI CHỖ" or "ĐỔI CHỖ",
            x=900,y=636,w=110,h=58,font=UI.fonts.tiny,selected=Touch.reorder,
            disabled=state~="playing" or anim.enemyTurn~=nil}
        buttons[#buttons+1]=btnTouch
        UI.drawButton(btnTouch,false,false)
    end

    ----------------------------------------------------------------------------
    -- 6. BOTTOM-RIGHT FACEDOWN DRAW DECK PILE
    ----------------------------------------------------------------------------
    local deckPileX = 1140
    local deckPileY = 535
    local deckPileW = 115
    local deckPileH = 160

    local isDeckHovered = (mx >= deckPileX and mx <= deckPileX + deckPileW and my >= deckPileY and my <= deckPileY + deckPileH)

    local totalCardsInGame = #game.deck + #game.discardPile + #game.hand
    UI.components.DeckCounter.draw(deckPileX, deckPileY, deckPileW, deckPileH,
        #game.deck, totalCardsInGame, UI.fonts, isDeckHovered)

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
        UI.descriptionCandidate = copyTarget or hoveredDeityTooltip
    end

    if hoveredCardTooltip then
        UI.descriptionCandidate = hoveredCardTooltip
    end
    if state == "playing" then drawCombatFeedback() end
end

local function drawScoringState()
    -- Reuse the arena and live left-side breakdown while cards resolve.
    drawPlayingState()
    -- World dimming is handled before sharp gameplay/UI in Renderer.

    -- Played cards share the same arena center as the hand and monster.
    local cards = anim.playedCards or {}
    local cardW = 96
    local cardH = 140
    local playY = 295

    -- Render Played Cards in Play Zone
    for i, c in ipairs(cards) do
        local targetX = UI.getScoringCardX(i, #cards)
        local start = anim.cardEntryFrom and anim.cardEntryFrom[i] or nil
        local fromX = start and start.x or targetX
        local fromY = start and start.y or 490
        local timing = UI.ScoringFeel.config.timing
        local cardEntryTime = math.max(0, (anim.entranceTimer or 0) - (i - 1) * timing.stagger)
        local liftProgress = math.min(1, cardEntryTime / timing.lift)
        local entrance = math.max(0, math.min(1, (cardEntryTime - timing.lift) / timing.travel))
        local easedEntrance = 1 - (1 - entrance) ^ 3
        local cx = fromX + (targetX - fromX) * easedEntrance
        local cy
        if cardEntryTime < timing.lift then
            local lift = 12 * liftProgress * liftProgress * (3 - 2 * liftProgress)
            cy = fromY - lift
        else
            local launchY = fromY - 12
            cy = launchY + (playY - launchY) * easedEntrance - math.sin(entrance * math.pi) * 12
        end
        local isActive = (anim.activeCardIndex == i)
        local isScored = (anim.scoredCards and anim.scoredCards[i] ~= nil)

        c.visualScale = (start and start.scale or 1.0) + (0.96 - (start and start.scale or 1.0)) * easedEntrance
        c.rotation = ((start and start.rotation) or ((i % 2 == 0) and 0.10 or -0.10)) * (1 - easedEntrance)

        local exit = anim.exitProgress or 0
        if exit > 0 then
            local easedExit = 1 - (1 - exit) ^ 3
            local deckX, deckY = 1140 - cardW / 2, 535
            cx = cx + (deckX - cx) * easedExit
            cy = cy + (deckY - cy) * easedExit
            c.visualScale = c.visualScale * (1 - easedExit * 0.54)
            c.rotation = c.rotation + ((i % 2 == 0) and 0.16 or -0.16) * easedExit
        end

        if isActive then
            cy = cy - 6 * math.exp(-(anim.sequence.age or 0) * 16) -- Soft scoring lift
        end

        local hitAge = anim.cardHit and anim.cardHit[i]
        if hitAge then
            local force = math.max(0, 1 - hitAge / 0.18)
            cx = cx + math.sin(hitAge * 118) * 1.8 * force
            cy = cy - math.sin(hitAge * 62) * 1.5 * force
            c.rotation = c.rotation + math.sin(hitAge * 95) * 0.015 * force
            c.visualScale = c.visualScale * (1 + 0.055 * force)
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

        local transformAge = anim.cardTransform and anim.cardTransform[i]
        local transformProgress = transformAge and math.min(1, transformAge / 0.42) or 0
        local dissolve = transformProgress -- Destruction visuals wait for energy conversion too.
        if dissolve > 0 then
            local dx, dy, rotation, shrink = UI.ScoringFeel.Attacks.cardPose(anim.sequence.attack, i, dissolve)
            if transformProgress < 1 then
                love.graphics.push()
                love.graphics.translate(cx + cardW / 2 + dx, cy + cardH / 2 + dy)
                love.graphics.rotate(rotation)
                love.graphics.scale(shrink, shrink)
                UI.Polish.dissolve(UI, -cardW/2, -cardH/2, cardW, cardH, transformProgress, CardEffects.getBeamColor(c),
                    function(x,y,w,h) UI.drawCardFace(c,x,y,w,h) end)
                love.graphics.pop()
            end

            UI.ScoringFeel.Attacks.fragments(anim.sequence.attack, i, dissolve, cx+cardW/2, cy+cardH/2)
        elseif c.destroyFxActive then
            UI.Polish.dissolve(UI,cx,cy,cardW,cardH,c.destroyFx or 0,{1,0.43,0.16},
                function(x,y,w,h) UI.drawCardFace(c,x,y,w,h) end)
        else
            UI.drawCard(c, cx, cy, cardW, cardH)
        end

        -- If actively scoring: Draw golden highlight ring and floating pill above
        if isActive and transformProgress < 0.45 then
            love.graphics.setBlendMode("add")
            love.graphics.setColor(1, 0.72, 0.18, 0.16 + math.sin(juice.ambientTimer * 18) * 0.05)
            UI.drawRoundedRect("fill", cx - 9, cy - 9, cardW + 18, cardH + 18, 12)
            love.graphics.setBlendMode("alpha")
            love.graphics.setLineWidth(3)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawCardBorder(cx, cy, cardW, cardH, UI.COLORS.goldYellow)

            -- Floating pill above card
            local pillW = 120
            local pillH = 26
            local pillX = cx + (cardW - pillW) / 2
            local pillY = cy - 32

            UI.components.Panel.draw(pillX, pillY, pillW, pillH)

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

        elseif isScored and transformProgress < 0.45 then
            -- Small green check badge below scored card
            local badgeW = 76
            local badgeH = 20
            local badgeX = cx + (cardW - badgeW) / 2
            local badgeY = cy + cardH + 4

            UI.components.Panel.draw(badgeX, badgeY, badgeW, badgeH, {variant = "green"})

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.hpGreen)
            local scoredInfo = anim.scoredCards[i]
            love.graphics.printf("✓ +" .. scoredInfo.addedChips .. " ST", badgeX, badgeY + 2, badgeW, "center")
        end
    end

    -- 3. Sparks and Fire Particles directly on board
    drawRealisticFireParticles()
    drawCombatFeedback()
    UI.ScoringFeel.draw(anim, UI)

end

local function drawBlindSelectState()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = ExpeditionSelect.draw(game, UI, mx, my)
end

local function drawVictoryState()
    local winW, winH = love.graphics.getDimensions()
    Renderer.veil()

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
    love.graphics.printf("GIẤY PHÉP VIỄN CHINH", modalX, modalY + 35, modalW, "center")

    love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf("Đã vượt 20 ải. Liên minh cấp giấy phép viễn chinh!", modalX, modalY + 95, modalW, "center")

    -- Divider
    love.graphics.setColor(0.3, 0.4, 0.5, 0.5)
    love.graphics.line(modalX + 40, modalY + 140, modalX + modalW - 40, modalY + 140)

    -- Stats summary
    local stats = game.run and game.run.stats or {}
    local statRows = {
        { label = "BỘ BÀI KHỞI ĐẦU:", val = "BỘ BÀI ĐỎ", color = { 0.95, 0.28, 0.30, 1 } },
        { label = "VÒNG ĐẠT ĐƯỢC:", val = "ẢI 20 / 20 (HOÀN THÀNH)", color = UI.COLORS.goldYellow },
        { label = "SỐ TRẬN ĐÃ CHIẾN THẮNG:", val = tostring(stats.blindsWon or 0) .. " Trận", color = { 0.35, 0.85, 0.45, 1 } },
        { label = "GIẤY PHÉP DI CHUYỂN:", val = "ĐÃ CẤP • LÊN TÀU", color = { 0.35, 0.80, 0.85, 1 } },
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
        text = "LÊN TÀU • ẢI 21 ➔",
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
    Renderer.veil()

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

    -- Modal: Chuẩn bị giao chiến
    if pendingCombatNode then
        love.graphics.setColor(0, 0, 0, 0.78)
        love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

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

        love.graphics.setFont(UI.fonts.regular)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf("Vượt trận đấu để nhận chiến lợi phẩm và mở đường tiếp theo.", mx0+30, my0+160, mw-60, "center")

        -- Action Buttons
        local btnFight = {
            id = "modal_fight_node",
            text = "VÀO CHIẾN ĐẤU",
            x = mx0 + 40,
            y = my0 + 245,
            w = mw - 80,
            h = 52,
            color = UI.COLORS.btnPlay,
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
        table.insert(buttons, btnClose)

        UI.drawButton(btnFight, mx >= btnFight.x and mx <= btnFight.x + btnFight.w and my >= btnFight.y and my <= btnFight.y + btnFight.h)
        UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h)
    end
end

local function drawEventState()
    local winW, winH = love.graphics.getDimensions()
    Renderer.veil()

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
    Renderer.veil()

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
        if UI.CardPhysics.hit(cards[sourceIndex], mx, my,
            mx >= cx and mx <= cx + 74 and my >= cy and my <= cy + 108) then
            return cards[sourceIndex]
        end
    end
end

local function drawDeckViewerModal()
    -- Overlay dimming
    local winW, winH = love.graphics.getDimensions()
    love.graphics.setColor(0, 0, 0, 0.80)
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

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
    love.graphics.print(game.soulDestroyActive and "NGHI LỄ TIÊU HỦY · CHỌN MỘT LÁ BÀI" or "TOÀN BỘ BỘ BÀI HIỆN TẠI & BẢNG BÍ TỊCH", modalX + 24, modalY + 18)

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

    if state == "shop" then
        UI.Polish.goldPosition=UI.Polish.config.viewerGold
        love.graphics.setFont(UI.fonts.small);love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.push()
        love.graphics.translate(970,72);love.graphics.scale(UI.Polish.goldPulse());love.graphics.translate(-970,-72)
        love.graphics.printf(tostring(game.souls or 0).." LH",905,61,130,"center")
        love.graphics.pop()
    end

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
            if not (state == "shop" and UI.Polish.hiddenOwned(c)) then UI.drawCard(c, 0, 0, cw, ch) end
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
    if game.soulDestroyActive then
        love.graphics.setColor(0.78,0.62,1,1)
        love.graphics.print("GIÁ TRỊ LINH HỒN",rightX,modalY+65)
        love.graphics.setFont(UI.fonts.small)
        local focus=UI.Polish.focus
        local card=focus and focus.kind=="card" and focus.item
        if card then
            local total,eq,evo,edition=Shop.getSoulValue(card)
            love.graphics.printf((card.rankName or "")..(card.suitSymbol or "").." · "..total.." LINH HỒN",rightX,modalY+115,rightW,"left")
            love.graphics.setFont(UI.fonts.small)
            love.graphics.printf("Bản thân lá: 1 LH\nTrang bị đang khảm: +"..eq.." LH\nTiến hóa bậc "..(card.evolutionLevel or 0)..": +"..evo.." LH\nẤn bản: +"..edition.." LH",rightX,modalY+175,rightW,"left")
        else
            love.graphics.printf("Chọn một lá bên trái để xem giá trị linh hồn trước khi tiêu hủy.",rightX,modalY+120,rightW,"left")
        end
        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(UI.COLORS.textMuted)
        love.graphics.printf("Foil: +3 · Holographic: +6\nPolychrome: +10 · Negative: +12\n\nTrang bị trên lá bị tiêu hủy cùng lá.\nBộ bài phải giữ ít nhất một lá.\n\nĐóng để hủy nghi lễ; chưa xác nhận thì không mất bài.",rightX,modalY+345,rightW,"left")
        return
    end
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

    -- Use the same complete description as shop, hand and reward cards.
    if hoveredDeckCard then UI.descriptionCandidate = hoveredDeckCard end
end

function UI.ChestChoices.claim(rew, keep, isBossChest)
    if keep then
        game.consumables=game.consumables or {}
        if #game.consumables>=UI.Inventory.limit(game) then Sound.play("cant_afford");return false end
        local item=rew.card or rew.item
        game.consumables[#game.consumables+1]={category=rew.type=="card" and "stored_card" or "stored_equipment",
            card=rew.card,equipmentId=rew.item and rew.item.id,name=item.name or rew.title,
            desc=rew.desc,color=rew.color,icon=rew.type=="card" and "♠" or "◆"}
        Sound.play("shop_buy")
    elseif rew.type=="card" then
        Deck.addCardToDeck(game,rew.card);Sound.play("card_deal")
    else
        pendingEquipment=rew.item;anim.pendingStoredEquipment=nil
        if not isBossChest then socketingReturnState="map" end
        state="socketing";return true
    end
    if game.currentNodeId and game.map then Map.onNodeCompleted(game.map,game.currentNodeId) end
    if isBossChest and socketingReturnState=="next_act" then
        game.act=game.act+1;game.map=Map.generate(game.act);game.currentNodeId=nil
        game.pendingSoulShop=true;Shop.enterSoulShop(game);Shop.refresh(shopData,game)
        state="shop";saveRunAtSafePoint();return true
    end
    state="map";saveRunAtSafePoint();return true
end

local function drawChestState()
    Renderer.veil()
    local mx,my=toVirtual(love.mouse.getPosition())
    buttons={}
    UI.ChestChoices.draw(chestRewards,anim.chestReveal.state==state and anim.chestReveal.timer or 0,"RƯƠNG CHIẾN THẮNG",mx,my,buttons,#(game.consumables or {})>=UI.Inventory.limit(game))
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
    Renderer.veil()

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
    if eqImg then
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = eqImg:getDimensions()
        require("ui.card_surfaces").image(equipment, panelX + 30, panelY + 12, 56, 80, eqImg)
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
            UI.drawCardBorder(cx, cy, cardW, cardH, UI.COLORS.multRed)
            love.graphics.setFont(UI.fonts.medium)
            love.graphics.printf(reason and reason:find("cùng loại") and "ĐÃ CÓ" or "THIẾU Ô", cx, cy + cardH / 2 - 12, cardW, "center")
        elseif isHovered then
            love.graphics.setLineWidth(3)
            love.graphics.setColor(UI.COLORS.hpGreen)
            UI.drawCardBorder(cx, cy, cardW, cardH, UI.COLORS.hpGreen)
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
    Renderer.veil()
    local mx,my=toVirtual(love.mouse.getPosition())
    buttons={}
    UI.ChestChoices.draw(treasureRewards,anim.chestReveal.state==state and anim.chestReveal.timer or 0,"RƯƠNG BÁU CỔ ĐẠI",mx,my,buttons,#(game.consumables or {})>=UI.Inventory.limit(game))
end

local function drawRestState()
    local winW, winH = love.graphics.getDimensions()
    Renderer.veil()

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
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

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
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

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
            require("ui.card_surfaces").image(h, thumbX, thumbY, thumbW, thumbH, hImg)
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
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

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
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

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

    -- Separate visual controls preserve all established settings hit regions.
    local visualX, visualY = modalX + modalW + 14, modalY + 70
    UI.drawGildedPanel(visualX, visualY, 220, 208)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("THẾ GIỚI ĐIỆN ẢNH", visualX + 12, visualY + 16, 196, "center")
    local qualityButton = {id="setting_quality", text="CHẤT LƯỢNG: "..Renderer.quality,
        x=visualX+12,y=visualY+52,w=196,h=34,font=UI.fonts.small}
    local cinemaButton = {id="setting_cinematic", text=settings.cinematicEnabled and "HIỆU ỨNG: BẬT" or "HIỆU ỨNG: TẮT",
        x=visualX+12,y=visualY+98,w=196,h=34,font=UI.fonts.small}
    for _,btn in ipairs({qualityButton,cinemaButton}) do
        buttons[#buttons+1]=btn
        UI.drawButton(btn,mx>=btn.x and mx<=btn.x+btn.w and my>=btn.y and my<=btn.y+btn.h)
    end
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("F1: kiểm tra render\nUI luôn sắc nét",visualX+12,visualY+151,196,"center")

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
    local btnFs = { id = "setting_fullscreen", text = Touch.nativeMobile and "Tràn viền" or fsText, disabled = Touch.nativeMobile, x = modalX + 300, y = row3Y, w = 150, h = 34, color = settings.fullscreen and UI.COLORS.btnPlay or UI.COLORS.btnNormal, font = UI.fonts.small }
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

    local btnGallery = { id = "setting_gallery", text = "UI GALLERY", x = modalX + 150,
        y = modalY + 407, w = 200, h = 34, variant = "purple", font = UI.fonts.small }
    buttons[#buttons + 1] = btnGallery
    UI.drawButton(btnGallery, mx >= btnGallery.x and mx <= btnGallery.x + btnGallery.w
        and my >= btnGallery.y and my <= btnGallery.y + btnGallery.h)

    -- Close Button
    local btnClose = { id = "close_settings", text = "LƯU & ĐÓNG", x = modalX + (modalW - 180) / 2, y = modalY + modalH - 52, w = 180, h = 40, color = UI.COLORS.btnPlay, font = UI.fonts.regular }
    table.insert(buttons, btnClose)
    UI.drawButton(btnClose, mx >= btnClose.x and mx <= btnClose.x + btnClose.w and my >= btnClose.y and my <= btnClose.y + btnClose.h, juice.buttonPressedId == btnClose.id)
end

local function drawShopState()
    if shopData.soulMode then require("ui.shop_display").drawSoulBackground(juice.ambientTimer) end
    local winW, winH = love.graphics.getDimensions()
    local mx, my = toVirtual(love.mouse.getPosition())
    buttons = {}
    UI.Polish.goldPosition = UI.Polish.config.gold

    local interestBonus = math.min(game.maxInterest or 5, math.floor((game.gold or 0) / 5))
    local hoveredShopItem = nil
    hoveredDeityTooltip = nil

    -- SPM and consumables live in a compact right-side rail.
    local deiCount = Deities.getCount(game.deities)
    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
    local firstDei,lastDei=UI.InventoryRail.range("spn",game)
    local firstCon,lastCon=UI.InventoryRail.range("consumable",game)
    local deiSlotW = 64
    local deiSlotH = 88
    local deiGap = 14
    local deiStartX = 1042
    local deiSlotY = 112

    UI.drawGildedPanel(deiStartX - 14, 73, 239, 248)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.print("SPN (" .. deiCount .. "/" .. maxDeiSlots .. ")", deiStartX + 4, 82)

    for i = firstDei, lastDei do
        local sx, sy, deiSlotW, deiSlotH = getDeitySlotRect(i, "shop")
        local d = game.deities and game.deities[i]
        local isDeiDragged = (deityDrag.active and deityDrag.isDragging and deityDrag.deityIndex == i)
        local isDeiHovered = (mx >= sx and mx <= sx + deiSlotW and my >= sy and my <= sy + deiSlotH)
        local isDropTarget = (deityDrag.active and deityDrag.isDragging and isDeiHovered and deityDrag.deityIndex ~= i)

        if d then
            if isDeiHovered and not (deityDrag.active and deityDrag.isDragging) then
                hoveredDeityTooltip = d
                d.slotIndex = i
            end

            local copyTarget = d.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, i)
            love.graphics.push()
            love.graphics.translate(sx + deiSlotW / 2, sy + deiSlotH / 2 + math.sin(((juice and juice.ambientTimer) or 0) * 1.15 + i * 0.72) * 2)
            love.graphics.rotate(math.sin(((juice and juice.ambientTimer) or 0) * 0.75 + i) * 0.008)
            love.graphics.translate(-sx - deiSlotW / 2, -sy - deiSlotH / 2)
            if not UI.Polish.hiddenOwned(d) then
                UI.drawPatronCard(d, sx, sy, deiSlotW, deiSlotH, isDeiHovered, juice.buttonPressedId == ("deity_" .. i), isDropTarget, copyTarget)
            end
            if pendingEvolutionCard then
                love.graphics.setLineWidth(2.5)
                love.graphics.setColor(0.84, 0.68, 1, 0.95)
                UI.drawCardBorder(sx, sy, deiSlotW, deiSlotH, UI.COLORS.goldYellow)
            end
            love.graphics.pop()

            -- Drag the whole card to reorder it or offer it at the altar.
            local btnDei = {
                id = "deity_" .. i,
                text = "",
                x = sx,
                y = sy,
                w = deiSlotW,
                h = deiSlotH,
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
    love.graphics.print("TIÊU HAO (" .. conCount .. "/"..UI.Inventory.limit(game)..")", conStartX + 4, 327)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.printf(UI.InventoryRail.hint("spn",game),1042,99,210,"right")
    love.graphics.printf(UI.InventoryRail.hint("consumable",game),1042,344,210,"right")

    for i = firstCon, lastCon do
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
    love.graphics.print(shopData.soulMode and "CHỢ LINH HỒN" or "CỬA HÀNG", 30, 24)
    love.graphics.setFont(UI.fonts.small)
    love.graphics.push()
    love.graphics.translate(325,35);love.graphics.scale(UI.Polish.goldPulse());love.graphics.translate(-325,-35)
    love.graphics.print(shopData.soulMode and (tostring(game.souls or 0).." LINH HỒN")
        or ("◉ " .. tostring(game.gold or 0) .. "   •   "..tostring(game.souls or 0).." LH"), 310, 28)
    love.graphics.pop()
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("Ải " .. tostring((game.run and game.run.ante) or game.act or 1) .. "   •   Sinh lực " .. tostring(game.playerHp or 0) .. "/" .. tostring(game.maxPlayerHp or 100), 530, 28)

    local shopX, shopY, shopW, shopH = 20, 76, 985, 560
    UI.components.Panel.draw(shopX, shopY, shopW, shopH, {worldBackdrop=true})

    ----------------------------------------------------------------------------
    -- A. UPPER COMPARTMENT (Next Round & Reroll + Upper Cards On Sale)
    ----------------------------------------------------------------------------

    -- 1. [Ván Kế Tiếp] Button
    local btnNextRound = {
        id = "leave_shop",
        text = shopData.soulMode and "RỜI CHỢ →" or "ẢI TIẾP →",
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
    local rCost = Shop.getRerollCost(shopData, game)
    local canReroll = (shopData.soulMode and (game.souls or 0) or (game.gold or 0)) >= rCost
    local btnReroll = {
        id = "reroll",
        text = shopData.soulMode and ("ĐỔI HÀNG · "..rCost.." LH") or (rCost == 0 and "ĐỔI HÀNG · MIỄN PHÍ" or ("ĐỔI HÀNG  ◉" .. rCost)),
        x = 203,
        y = 653,
        w = 170,
        h = 42,
        color = canReroll and UI.COLORS.btnSpecial or UI.COLORS.btnNormal,
        font = UI.fonts.small,
        animationScale = UI.Polish.job and UI.Polish.job.kind == "flip" and (1-0.05*math.sin(math.min(1,UI.Polish.job.age/0.12)*math.pi)) or 1,
        disabled = not canReroll or UI.Polish.busy(),
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

    -- Stock rendering is isolated from inventory, drag/drop and modal handling.
    hoveredShopItem = require("ui.shop_display").draw(
        shopData, game, buttons, shopDrag, mx, my, juice.ambientTimer)

    ----------------------------------------------------------------------------
    -- Deck is now a viewer, not a purchase drop target.
    local deck = shopDrag.purchaseZone
    local isDeckHovered = mx >= deck.x and mx <= deck.x+deck.w and my >= deck.y and my <= deck.y+deck.h
    UI.components.DeckCounter.draw(deck.x,deck.y,deck.w,deck.h,#(game.deck or {}),#(game.persistentDeck or {}),UI.fonts,isDeckHovered)
    table.insert(buttons,{id="open_deck_viewer",text="",x=deck.x,y=deck.y,w=deck.w,h=deck.h,invisible=true})
    love.graphics.setFont(UI.fonts.tiny);love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("NHẤP ĐỂ XEM BỘ BÀI", deck.x-20,deck.y+deck.h+6,deck.w+40,"center")
    love.graphics.setFont(UI.fonts.small);love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("GIAO DỊCH",1125,520,130,"center")
    love.graphics.setFont(UI.fonts.tiny);love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Quân bài: dùng\nLá Tiêu Hủy để\nnhận linh hồn.\nSPN / tiêu hao:\nchọn để bán.",1125,556,130,"center")
    if hoveredShopItem then UI.descriptionCandidate = hoveredShopItem end

    ----------------------------------------------------------------------------
    -- 6. PACK OPENING MODAL OVERLAY (When a Booster Pack is active)
    ----------------------------------------------------------------------------
    if shopData.currentPackOpening and not UI.Polish.busy() then
        UI.CardPhysics.blockBehind()
        local pData = shopData.currentPackOpening
        local pack = pData.pack
        local cards = pData.cards or {}

        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)

        local packImg = UI.getPackImage(pack.packType or pack.id)
        local timer = pData.animationTimer or 0
        UI.ChestChoices.draw(cards,timer,pack.name or "MỞ RƯƠNG",mx,my,buttons,#game.consumables>=UI.Inventory.limit(game),pack.packType)
        if timer < DeathVFX.config.chest.duration and DeathVFX.kind=="chest" then
            DeathVFX.drawEnemy(packImg,640,328,DeathVFX.config.chest.size)
            DeathVFX.drawParticles()
        end
        if timer >= DeathVFX.config.chest.cardsAt then
            local btn={id="skip_pack",text="BỎ QUA RƯƠNG BÀI",x=540,y=674,w=200,h=34,color=UI.COLORS.btnDiscard,font=UI.fonts.small}
            buttons[#buttons+1]=btn
            UI.drawButton(btn,mx>=btn.x and mx<=btn.x+btn.w and my>=btn.y and my<=btn.y+btn.h)
        end
    end

    if isShopTransferOpen then
        drawShopTransferView()
    end

    if hoveredDeityTooltip then
        local copyTarget = hoveredDeityTooltip.isCopyDeity and Deities.resolveDeity and Deities.resolveDeity(game.deities, hoveredDeityTooltip.slotIndex or 1)
        UI.descriptionCandidate = copyTarget or hoveredDeityTooltip
    end
    drawCombatFeedback()
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
    love.graphics.rectangle("fill", -offsetX / scale, -offsetY / Layout.scaleY, winW / scale, winH / Layout.scaleY)
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
            UI.drawCardBorder(x, y + float - (hovered and 5 or 0), w, h, UI.COLORS.goldYellow)
        elseif chosenEq then
            love.graphics.setColor(canReceive and UI.COLORS.hpGreen or { 0.65, 0.18, 0.20, 0.8 })
            UI.drawCardBorder(x, y + float - (hovered and 5 or 0), w, h, canReceive and UI.COLORS.hpGreen or { 0.65, 0.18, 0.20, 0.8 })
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
        local hop = fx.kind == "destroy" and 0 or fx.kind == "consume" and 18 or (fx.kind == "sell" and 40 or 70)
        local y = fx.y + ((fx.targetY or fx.y) - fx.y) * travel - math.sin(p * math.pi) * hop
        local pop = math.sin(math.min(1, p / 0.24) * math.pi) * (fx.kind == "consume" and 0.06 or 0.12)
        local size = fx.kind=="destroy" and (1-0.12*travel) or fx.kind == "consume" and math.max(0.90, 1 + pop - p * 0.08)
            or (fx.kind == "sell" and math.max(0.12, 1 + pop - p * 0.82) or math.max(0.42, 1 + pop - travel * 0.48))
        local w, h = fx.w or 92, fx.h or 130

        love.graphics.setBlendMode("add")
        love.graphics.setLineWidth(4)
        local trailColor = fx.kind == "consume" and (item.color or UI.COLORS.hpGreen)
            or (fx.kind=="destroy" and {1,0.43,0.16} or {1,0.82,0.22})
        love.graphics.setColor(trailColor[1], trailColor[2], trailColor[3], (1 - p) * (fx.kind=="destroy" and 0.12 or 0.20))
        love.graphics.line(fx.x, fx.y, x, y)
        love.graphics.setLineWidth(1)
        love.graphics.setBlendMode("alpha")

        love.graphics.push()
        love.graphics.translate(x, y)
        local spin = fx.kind == "destroy" and 0.10 or (fx.kind == "consume" and 0.05 or ((fx.kind == "sell" or fx.kind == "sacrifice") and -1.05 or 0.24))
        love.graphics.rotate(spin * p + math.sin(p * math.pi) * 0.08)
        love.graphics.scale(size, size)
        if fx.kind == "consume" or fx.kind == "destroy" or fx.kind=="sell" or fx.kind=="sacrifice" then
            love.graphics.setBlendMode("add")
            love.graphics.setColor(trailColor[1],trailColor[2],trailColor[3],math.sin(math.min(1,p/0.34)*math.pi)*0.22)
            UI.drawCardBorder(-w/2,-h/2,w,h,{trailColor[1],trailColor[2],trailColor[3],math.sin(math.min(1,p/0.34)*math.pi)*0.22})
            love.graphics.setBlendMode("alpha")
            UI.Polish.dissolve(UI, -w/2, -h/2, w, h, ((fx.kind=="destroy" or fx.kind=="sell" or fx.kind=="sacrifice") and math.max(0,(p-0.08)/0.72)^0.85 or math.max(0,(p-0.34)/0.66)^1.5),
                trailColor, function(x,y,cw,ch) UI.Polish.renderItem(UI,item,x,y,cw,ch) end)
        elseif item.faceDown or (item.reward and item.reward.faceDown) then
            UI.drawCardBack(-w / 2, -h / 2, w, h)
        elseif fx.kind == "consume" then
            drawBattleConsumableCard(item, -w / 2, -h / 2, w, h, 1, -1000, -1000, false, true, 1 - p)
        elseif item.category == "deity" or item.id and Deities.CATALOG[item.id] then
            UI.drawPatronCard(item.deity or item, -w / 2, -h / 2, w, h, false, false, false)
        elseif item.category == "card" or item.rank then
            UI.drawCard(item.card or item, -w / 2, -h / 2, w, h)
        elseif UI.getConsumableImage(item) or (item.handId and UI.getHandImage(item.handId)) then
            require("ui.card_surfaces").fullReward(item, -w / 2, -h / 2, w, h, item.packType, false)
        else
            love.graphics.setColor(0.12, 0.16, 0.22, 0.98)
            UI.drawRoundedRect("fill", -w / 2, -h / 2, w, h, 8)
            local art = item.packType and UI.getPackCardImage(item.packType, item.reward or item)
                or (item.category == "equipment" and UI.getEquipmentImage(item.equipment and item.equipment.id or item.id))
                or (item.category == "pack" and UI.getPackImage(item.packType))
                or (item.category == "book" and UI.getHandImage(item.handId))
                or ((item.category == "voucher" or item.category == "hand_expansion") and UI.getVoucherImage(item.voucherId or item.category))
            if not item.packType and item.category ~= "pack" and item.category ~= "equipment" and item.category ~= "hand_expansion" then
                art = UI.visualImage(art)
            end
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
        for i = 1, (fx.kind=="consume" and UI.Polish.config.shards or fx.kind=="buy" and 3 or 0) do
            local angle = i * 2.17
            local radius = p * (20 + i * 2.4)
            local color = fx.kind == "consume" and (item.color or UI.COLORS.hpGreen)
                or ((fx.kind == "sell" or fx.kind == "sacrifice" or fx.kind == "destroy") and { 1, 0.22, 0.08 } or { 1, 0.82, 0.22 })
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

local function drawChestReveal()
    if DeathVFX.kind ~= "chest" then return end
    local timer=anim.chestReveal.timer
    if timer>=DeathVFX.config.chest.duration then return end
    local g=love.graphics;g.push("all")
    local veil=math.max(0,1-timer/DeathVFX.config.chest.cardsAt)
    g.setColor(0.009,0.013,0.025,veil*0.72);g.rectangle("fill",0,0,V_WIDTH,V_HEIGHT)
    DeathVFX.drawEnemy(battleArt.chest,640,328,DeathVFX.config.chest.size)
    DeathVFX.drawParticles()
    g.pop()
end

local function drawGameOverState()
    local winW, winH = love.graphics.getDimensions()
    if DeathVFX.kind == "player" then
        DeathVFX.drawPlayer(UI)
    else Renderer.veil() end

    local mx, my = toVirtual(love.mouse.getPosition())
    local reveal = DeathVFX.uiProgress()

    if DeathVFX.kind ~= "player" then
        love.graphics.setFont(UI.fonts.huge)
        love.graphics.setColor(UI.COLORS.multRed)
        love.graphics.printf("BẠN ĐÃ BỊ ĐÁNH BẠI!", 0, 160, V_WIDTH, "center")
    end

    love.graphics.setFont(UI.fonts.large)
    love.graphics.setColor(0.85, 0.82, 0.83, reveal)
    love.graphics.printf("Dừng bước tại Round " .. game.round .. " trước " .. (game.monster and game.monster.name or "Quái Vật"), 0, 240, V_WIDTH, "center")

    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(0.63,0.61,0.67,reveal)
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
    if reveal > 0 then
        table.insert(buttons, btnRetry)
        UI.drawButton(btnRetry, state == "gameover" and mx >= btnRetry.x and mx <= btnRetry.x + btnRetry.w and my >= btnRetry.y and my <= btnRetry.y + btnRetry.h)
        love.graphics.setColor(0.012,0.013,0.024,(1-reveal)*0.97)
        love.graphics.rectangle("fill",btnRetry.x-2,btnRetry.y-2,btnRetry.w+4,btnRetry.h+4,6,6)
    end
end

local function chooseRoundReward(index)
    local ok, item = RunManager.chooseRoundReward(game, index)
    if not ok then return false end
    Sound.play("round_win")
    table.insert(anim.floatingTexts, {
        text = "ĐÃ NHẬN: " .. (item.name or "PHẦN THƯỞNG") .. (#(game.pendingRewardCards or {}) > 0 and " · ĐANG CHỜ Ô TIÊU HAO TRỐNG" or ""),
        color = item.color or UI.COLORS.goldYellow, x = 640, y = 150, alpha = 2.8,
    })
    saveRunAtSafePoint()
    return true
end

function love.draw()
    UI.descriptionCandidate = nil
    UI.descriptionGame = game
    if UI.menuBackgroundVideo then
        if state == "menu" then
            if not UI.menuBackgroundVideo:isPlaying() then
                UI.menuBackgroundVideo:rewind()
                UI.menuBackgroundVideo:play()
            end
        elseif UI.menuBackgroundVideo:isPlaying() then
            UI.menuBackgroundVideo:pause()
        end
    end
    if love.mouse and love.mouse.getPosition then
        local rawMx, rawMy = love.mouse.getPosition()
        UI.virtualMouseX, UI.virtualMouseY = toVirtual(rawMx, rawMy)
    end
    UI.currentPressedBtnId = juice and juice.buttonPressedId

    Renderer.beginFrame(mainCanvas)

    -- 1. If Canvas is enabled, render the game into mainCanvas
    if mainCanvas then
        love.graphics.setCanvas({ mainCanvas, stencil = true })
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.push()
        love.graphics.scale(RENDER_SCALE, RENDER_SCALE)
    else
        love.graphics.push()
        love.graphics.translate(offsetX, offsetY)
        love.graphics.scale(scale * RENDER_SCALE, Layout.scaleY * RENDER_SCALE)
    end

    UI.CardPhysics.beginFrame(UI.CardPhysics.isLabOpen() or (state ~= "scoring" and state ~= "defeating" and state ~= "gameover"
        and not isPauseMenuOpen and not isSettingsOpen and not isDebugOpen))

    Renderer.drawWorld(function()
        if state == "playing" or state == "scoring" or state == "defeating" or (state == "gameover" and DeathVFX.kind == "player") then drawBattleEnemyWorld(game.monster) end
        if state == "shop" then require("ui.shop_display").drawWorld(shopData, Renderer.scene.time) end
    end, function()
        if state == "scoring" then UI.ScoringFeel.drawWorld(anim, UI) end
        if state=="playing" or state=="scoring" then UI.BedExplosion.drawBeds(game) end
        UI.BedExplosion.draw()
        if DeathVFX.enemyActive(game.monster) and (state == "playing" or state == "scoring") then DeathVFX.drawParticles() end
    end)

    UI.BedExplosion.drawDebug(UI)
    love.graphics.push()

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
    elseif state == "defeating" then
        drawPlayingState()
        if DeathVFX.age >= DeathVFX.config.player.textAt then drawGameOverState() else DeathVFX.drawPlayer(UI) end
        buttons = {}
    elseif state == "CASH_OUT" then
        local mx, my = toVirtual(love.mouse.getPosition())
        buttons = {}
        RewardSystem.draw(cashOutAnim, V_WIDTH, V_HEIGHT, mx, my, buttons)
        if game.pendingRoundRewardChoice and cashOutAnim and cashOutAnim.finished then
            UI.drawRoundRewardChoice(game.pendingRoundRewardChoice, mx, my, buttons, V_WIDTH, V_HEIGHT)
        end
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
        if DeathVFX.kind == "player" then drawPlayingState() end
        drawGameOverState()
    elseif state == "victory" then
        drawVictoryState()
    end

    UI.CardPhysics.suspend()
    drawShopFx()
    if state == "chest" or state == "treasure" then drawChestReveal() end
    UI.CardPhysics.resume()

    if isDeckViewerOpen then
        UI.CardPhysics.blockBehind()
        drawDeckViewerModal()
    end

    if isHandbookOpen then
        UI.CardPhysics.blockBehind()
        drawHandbookModal()
    end

    if inspectCardModal then
        UI.CardPhysics.blockBehind()
        drawCardInspectorModal(inspectCardModal)
    end

    if isPauseMenuOpen then
        UI.CardPhysics.blockBehind()
        drawPauseMenuModal()
    end

    if isSettingsOpen then
        UI.CardPhysics.blockBehind()
        drawSettingsModal()
    end

    if isCollectionOpen then
        UI.CardPhysics.blockBehind()
        if collectionCategory then
            drawCollectionDetailView()
        else
            drawCollectionModal()
        end
    end

    -- In-game sleek Pause / Menu button at top right
    if state ~= "menu" and state ~= "BLIND_SELECT" and state ~= "playing" and state ~= "defeating" and state ~= "gameover" and not isPauseMenuOpen and not isSettingsOpen and not isDebugOpen and not isDeckViewerOpen and not isHandbookOpen and not inspectCardModal and not isCollectionOpen and not isShopTransferOpen then
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
            assetId = "btn_top_tuy_chon",
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
    if state ~= "CASH_OUT" and state ~= "defeating" and state ~= "gameover" and juice.floatingTexts and #juice.floatingTexts > 0 then
        for _, ft in ipairs(juice.floatingTexts) do
            Feedback.draw(ft, UI)
        end
    end



    if isUiGalleryOpen then
        local galleryMx, galleryMy = toVirtual(love.mouse.getPosition())
        Gallery.draw(UI.fonts, galleryMx, galleryMy)
    end

    UI.CardPhysics.drawLab(UI, CardEffects)
    UI.ScoringFeel.drawLab(UI)
    if state == "scoring" and not UI.ScoringFeel.labOpen then UI.ScoringFeel.drawDebug(anim, UI) end
    UI.CardPhysics.endFrame()
    UI.CardPhysics.drawDebug()
    UI.drawCardEffectsDebug()

    if state == "shop" and not isSettingsOpen and not isPauseMenuOpen and not isHandbookOpen
        and not isCollectionOpen and not isShopTransferOpen and not inspectCardModal and not isDebugOpen and not isUiGalleryOpen then
        UI.Polish.draw(UI, game, buttons, UI.virtualMouseX or 0, UI.virtualMouseY or 0)
        Feedback.drawVfx(UI)
    elseif state ~= "defeating" and state ~= "gameover" and not UI.AbilityUI.current and not isSettingsOpen and not isPauseMenuOpen and not isHandbookOpen
        and not isCollectionOpen and not inspectCardModal and not isDebugOpen and not isUiGalleryOpen then
        UI.Polish.draw(UI, game, {}, -1000, -1000)
        Feedback.drawVfx(UI)
    end
    love.graphics.pop()

    if UI.descriptionCandidate and state ~= "scoring" and state ~= "defeating" and state ~= "gameover" and UI.Polish.tooltipAllowed(UI.descriptionCandidate)
        and not UI.AbilityUI.current and not UI.CardPhysics.isHolding() then
        UI.Description.draw(UI, UI.descriptionCandidate, UI.virtualMouseX or 0, UI.virtualMouseY or 0, game)
    end
    UI.AbilityUI.draw(UI, UI.virtualMouseX or 0, UI.virtualMouseY or 0)
    UI.Description.finishFrame()
    Renderer.drawTransition()
    Renderer.drawDebug(UI.fonts.tiny)
    -- The game layout remains expressed in 1280x720 units; undo that logical
    -- scale before presenting the 1920x1080 render target.
    if mainCanvas then love.graphics.pop() end

    -- 2. If Canvas is enabled, present to screen via CRT Post-Processing Shader
    if mainCanvas then
        love.graphics.setCanvas()
        local winW, winH = love.graphics.getDimensions()
        love.graphics.setColor(0.02, 0.02, 0.03, 1)
        love.graphics.rectangle("fill", 0, 0, winW, winH)

        -- Present with the same per-axis transform used for pointer hit testing.
        love.graphics.setShader()

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(mainCanvas, offsetX, offsetY, 0, scale, Layout.scaleY)
        love.graphics.setShader()
    else
        love.graphics.pop()
    end
    for _, value in ipairs(arg or {}) do
        if value == "--capture-mobile-fullscreen" then require("tests.mobile_fullscreen_capture").draw() end
    end
end

--------------------------------------------------------------------------------
-- INPUT HANDLING
--------------------------------------------------------------------------------

local function handlePlayingMousepressed(mx, my, button)
    if button ~= 1 then return false end
    if button==1 and EnemyFormation.press(game,mx,my) then Sound.play("ui_click");return true end
    if pendingSpeedCard and button == 1 then
        applyPendingSpeedAt(mx, my)
        return true
    end
    if pendingEditionCard and button == 1 then
        applyPendingEditionAt(mx, my, "playing")
        return true
    end
    if pendingEvolutionCard and button == 1 then
        applyPendingEvolutionAt(mx, my, "playing")
        return true
    end

    for _, btn in ipairs(buttons) do
        if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            if btn.id == "play" then
                playSelectedHand()
                return true
            elseif btn.id == "end_turn" then
                endPlayerTurn()
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
            elseif btn.id == "touch_reorder" then
                Touch.reorder = not Touch.reorder
                Sound.play("ui_click")
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
            end
        end
    end

    local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5

    -- Left-click never activates a consumable; activation is deliberately right-click only.
    local maxConsumableSlots = UI.Inventory.limit(game)
    for j = maxConsumableSlots, 1, -1 do
        local cx, cy, cw, ch = getConsumableSlotRect(j, "playing")
        if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
            return true
        end
    end

    -- Check Deity Slots in Top Bar for Drag & Drop Reordering
    for i = 1, maxDeiSlots do
        local dx, dy, dw, dh = getDeitySlotRect(i, "playing")
        if UI.CardPhysics.hit(game.deities and game.deities[i], mx, my,
            mx >= dx and mx <= dx + dw and my >= dy and my <= dy + dh) then
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

    local handIndex = handDrag.cardAt(mx, my)
    if handIndex then
        beginHandDrag(mx, my, handIndex, Touch.enabled and Touch.reorder or love.keyboard.isDown("lshift", "rshift"))
        return true
    end

    -- A sweep may start in a gap or just beside the hand.
    if #game.hand > 0 then
        local left, top, _, height = getHandCardPosition(1, #game.hand)
        local right, lastY, width = getHandCardPosition(#game.hand, #game.hand)
        if mx >= left - 18 and mx <= right + width + 18
            and my >= math.min(top, lastY) - 56 and my <= math.max(top, lastY) + height + 8 then
            beginHandDrag(mx, my, nil, false)
            return true
        end
    end

    return false
end

local function handleShopMousepressed(mx, my, button)
    if UI.Polish.busy() then return true end
    if pendingEditionCard and button == 1 and not isShopTransferOpen then
        applyPendingEditionAt(mx, my, "shop")
        return true
    end
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
                    local before = UI.Polish.snapshot(game)
                    local ok, msg = Shop.transferEquipment(transferSourceCard, transferSourceEqIndex, c)
                    transferMessage = msg
                    if ok then
                        UI.Polish.changed(UI, game, before, chosenEq)
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
            if not btn.disabled and (not btn.cardIndex or UI.ChestChoices.ready(shopData.currentPackOpening.animationTimer or 0,btn.cardIndex)) and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                if btn.id:sub(1, 12) == "choose_pack_" then
                    local opening = shopData.currentPackOpening
                    local reward = opening.cards and opening.cards[btn.cardIndex]
                    local before = UI.Polish.snapshot(game)
                    local ok, action, eq = Shop.choosePackCard(shopData, btn.cardIndex, game)
                    if ok and action == "open_socketing" and opening.pack.rewardPack then
                        game.pendingRewardEquipment = eq
                    elseif ok and RewardSystem.completePack(game, shopData, opening) then saveRunAtSafePoint() end
                    if ok then
                        UI.Polish.changed(UI, game, before, reward)
                        spawnShopFx("buy", { packType = opening.pack.packType, reward = reward, name = reward and reward.name }, btn.x + btn.w / 2, btn.y)
                    end
                    if ok and action == "open_socketing" and eq then
                        pendingEquipment = eq
                        socketingReturnState = "shop"
                        state = "socketing"
                        if game.pendingRewardEquipment then saveRunAtSafePoint() end
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
                    if ok and RewardSystem.completePack(game, shopData, opening) then saveRunAtSafePoint() end
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
                    local skippedOpening = shopData.currentPackOpening
                    local skippedPack = skippedOpening.pack
                    Shop.skipPack(shopData)
                    if RewardSystem.completePack(game, shopData, skippedOpening) then saveRunAtSafePoint() end
                    spawnShopFx("sell", { category = "pack", packType = skippedPack.packType, name = skippedPack.name }, btn.x + btn.w / 2, btn.y)
                    return true
                end
            end
        end
        return true
    end

    if pendingEvolutionCard and button == 1 then
        applyPendingEvolutionAt(mx, my, "shop")
        return true
    end

    -- Left click focuses; right click activation remains handled by the input router.
    if button ~= 1 then return true end
    for j = 1, UI.Inventory.limit(game) do
        local cx, cy, cw, ch = getConsumableSlotRect(j, "shop")
        if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
            UI.Polish.focusItem(game.consumables and game.consumables[j], "consumable", j, {x=cx,y=cy,w=cw,h=ch})
            return true
        end
    end
    for _, btn in ipairs(buttons) do
        if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            if btn.id:sub(1, 4) == "buy_" then
                local item = shopData.items and shopData.items[btn.itemIndex]
                if item ~= btn.stockItem then return true end -- Reject a hitbox from the previous stock frame.
                UI.Polish.focusItem(item, "stock", btn.itemIndex, {x=btn.x,y=btn.y,w=btn.w,h=btn.h})
                return true
            elseif btn.id:sub(1, 6) == "deity_" then
                UI.Polish.focusItem(game.deities and game.deities[btn.deityIndex], "deity", btn.deityIndex,
                    {x=btn.x,y=btn.y,w=btn.w,h=btn.h})
                return true
            elseif btn.id == "reroll" then
                UI.Polish.reroll(shopData, game)
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
                game.shopMode="normal";game.soulDestroyActive=false
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
        local evolutionReward = RunManager.completeCurrentBlind(game.run, game)
        if evolutionReward then
            table.insert(anim.floatingTexts, {
                text = "Hoàn tất vòng ải " .. tostring(game.run.ante) .. " · Chọn một trong ba phần thưởng",
                color = { 0.82, 0.70, 1, 1 }, x = 640, y = 205, alpha = 2.6,
            })
        end
        local rewardResult = RewardSystem.begin(breakdown, game)
        cashOutAnim = RewardSystem.newAnimation(breakdown, rewardResult)
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
                        settings.fullscreen = Touch.nativeMobile or not settings.fullscreen
                        love.window.setFullscreen(settings.fullscreen, "desktop")
                        updateScale()
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_crt" then
                        settings.crtEnabled = not settings.crtEnabled
                        Renderer.crtEnabled = settings.crtEnabled
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_quality" then
                        local nextQuality = {LOW="MEDIUM",MEDIUM="HIGH",HIGH="LOW"}
                        settings.graphicsQuality = nextQuality[Renderer.quality]
                        Renderer.setQuality(settings.graphicsQuality)
                        saveSettings()
                        Sound.play("ui_click")
                        return true
                    elseif btn.id == "setting_cinematic" then
                        settings.cinematicEnabled = not settings.cinematicEnabled
                        Renderer.config.enabled = settings.cinematicEnabled
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
                    elseif btn.id == "setting_gallery" then
                        isSettingsOpen = false
                        isUiGalleryOpen = true
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
        if (state == "playing" or state == "shop") and not isDeckViewerOpen
            and not (shopData and shopData.currentPackOpening) then
            local count = UI.Inventory.limit(game)
            for i = count, 1, -1 do
                local x, y, w, h = getConsumableSlotRect(i, state)
                if game.consumables and game.consumables[i]
                    and mx >= x and mx <= x + w and my >= y and my <= y + h then
                    activateConsumable(i, state)
                    return true
                end
            end
        end
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
            isDeckViewerOpen = false;game.soulDestroyActive=false;game.soulDestroyConsumable=nil;UI.Polish.clearFocus()
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
            if state == "shop" and game.soulDestroyActive and button == 1 then
                UI.Polish.focusItem(card, "card", nil, UI.Polish.rect(UI, card, {x=mx-37,y=my-54,w=74,h=108}))
                return true
            end
            inspectCardModal = card
            Sound.play("card_deal")
            return true
        end

        -- Click outside modal closes it
        if mx < modalX or mx > modalX + modalW or my < modalY or my > modalY + modalH then
            isDeckViewerOpen = false;game.soulDestroyActive=false;game.soulDestroyConsumable=nil;UI.Polish.clearFocus()
            Sound.play("card_deal")
            return true
        end

        return true
    end

    return false
end

function love.mousepressed(x, y, button, istouch)
    if istouch then return end
    Touch.mouseInput()
    if anim.enemyTurn then return end
    if state == "defeating" or (DeathVFX.enemyActive(game.monster) and DeathVFX.busy()) then return end
    if UI.ScoringFeel.labOpen then return end
    local mx, my = toVirtual(x, y)
    if UI.AbilityUI.press(mx, my, button) then return end
    if state == "shop" and UI.Polish.busy() then return end
    if button == 2 and UI.Polish.focus then UI.Polish.clearFocus() end
    if state == "shop" and button == 1 and not isSettingsOpen and not isPauseMenuOpen
        and not isHandbookOpen and not isCollectionOpen and not isShopTransferOpen
        and not inspectCardModal and not isDebugOpen and not isUiGalleryOpen then
        local confirm = UI.Polish.button(game)
        if confirm and mx >= confirm.x and mx <= confirm.x+confirm.w and my >= confirm.y and my <= confirm.y+confirm.h then
            UI.Polish.confirm(shopData, game, function(action, equipment)
                if action == "open_socketing" and equipment then
                    pendingEquipment=equipment;game.pendingRewardEquipment=equipment;game.pendingShopEquipment=true
                    socketingReturnState="shop";state="socketing";saveRunAtSafePoint()
                elseif type(action)=="number" then
                    isDeckViewerOpen=false;saveRunAtSafePoint()
                end
            end)
            return
        end
        UI.Polish.clearFocus()
    end
    if UI.CardPhysics.isLabOpen() then
        UI.CardPhysics.press(mx, my, button)
        return
    end
    local physicsButton = false
    for _, btn in ipairs(buttons or {}) do
        if not btn.invisible and not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w
            and my >= btn.y and my <= btn.y + btn.h then physicsButton = true; break end
    end
    if not physicsButton and state ~= "shop" then UI.CardPhysics.press(mx, my, button) end
    if isUiGalleryOpen then
        if button == 1 and mx >= 1152 and mx <= 1248 and my >= 20 and my <= 51 then
            isUiGalleryOpen = false
            Sound.play("ui_click")
        end
        return
    end
    if not isCaptureMode and (state == "chest" or state == "treasure")
        and (anim.chestReveal.state ~= state or anim.chestReveal.timer < DeathVFX.config.chest.cardsAt) then
        return
    end

    -- Track pressed button id for juice animation, tactile mechanical sound & micro-screenshake
    if button == 1 then
        for _, btn in ipairs(buttons or {}) do
            if not btn.disabled and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                juice.buttonPressedId = btn.id
                Sound.play("ui_click")
                if btn.id == "play" or btn.id == "discard" or btn.id == "fight" or btn.id == "fight_blind"
                   or btn.id == "leave_shop" or btn.id == "btn_select_combat"
                   or btn.id == "cashout_continue" or btn.id == "start_game" then
                    juice.screenShake = math.max(juice.screenShake or 0, 2.5)
                end
                break
            end
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
        -- Handle clicks on encounter preview if open
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
        UI.ScoringFeel.skipOrFastForward(anim)
        return

    elseif state == "CASH_OUT" then
        if cashOutAnim then
            if not cashOutAnim.finished then
                RewardSystem.finishImmediately(cashOutAnim)
                Sound.play("shop_buy")
                return
            else
                if game.pendingRoundRewardChoice then
                    for _, btn in ipairs(buttons) do
                        if btn.id and btn.id:sub(1, 13) == "round_reward_"
                            and mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                            chooseRoundReward(btn.rewardIndex)
                            return
                        end
                    end
                    return
                end
                for _, btn in ipairs(buttons) do
                    if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
                        if btn.id == "cashout_continue" then
                            if not shopData then shopData = Shop.new() end
                            Shop.resetReroll(shopData)
                            Shop.enterSoulShop(game)
                            Shop.refresh(shopData, game)
                            state = "shop"
                            cashOutAnim.state = "EXIT"
                            game.pendingVictoryReward = nil
                            RewardSystem.openNextPack(game, shopData)
                            saveRunAtSafePoint()
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

    elseif state == "chest" or state == "treasure" then
        local isBossChest=state=="chest"
        local rewards=isBossChest and chestRewards or treasureRewards
        for _,btn in ipairs(buttons) do
            if btn.rewardIndex and not btn.disabled and UI.ChestChoices.ready(anim.chestReveal.timer,btn.rewardIndex)
                and mx>=btn.x and mx<=btn.x+btn.w and my>=btn.y and my<=btn.y+btn.h then
                local rew=rewards[btn.rewardIndex]
                if rew then UI.ChestChoices.claim(rew,btn.keep,isBossChest);return end
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
                    anim.pendingStoredEquipment=nil
                    if game.pendingRewardEquipment then
                        game.pendingRewardEquipment = nil
                        if not game.pendingShopEquipment then table.remove(game.rewardPacks, 1) end
                        game.pendingShopEquipment=nil
                    end
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
                        game.pendingSoulShop=true;Shop.enterSoulShop(game);Shop.refresh(shopData,game)
                        state = "shop"
                    elseif socketingReturnState == "shop" then
                        state = "shop"
                    elseif socketingReturnState == "playing" then
                        state = "playing"
                    elseif socketingReturnState == "map" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    else
                        state = "map"
                    end
                    if state == "shop" then saveRunAtSafePoint() end
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
                local before = UI.Polish.snapshot(game)
                local success, msg = Equipment.attach(c, pendingEquipment)
                if success then
                    UI.Polish.changed(UI, game, before, pendingEquipment)
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
                    Sound.play("card_slide",0.92)
                    if anim.pendingStoredEquipment then
                        for i,c in ipairs(game.consumables or {}) do
                            if c==anim.pendingStoredEquipment then table.remove(game.consumables,i);break end
                        end
                        anim.pendingStoredEquipment=nil
                        UI.Abilities.consumableUsed(game)
                    end
                    if game.pendingRewardEquipment then
                        game.pendingRewardEquipment = nil
                        if not game.pendingShopEquipment then table.remove(game.rewardPacks, 1) end
                        game.pendingShopEquipment=nil
                    end
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
                        game.pendingSoulShop=true;Shop.enterSoulShop(game);Shop.refresh(shopData,game)
                        state = "shop"
                    elseif socketingReturnState == "shop" then
                        state = "shop"
                    elseif socketingReturnState == "playing" then
                        state = "playing"
                    elseif socketingReturnState == "map" then
                        if game.currentNodeId and game.map then
                            Map.onNodeCompleted(game.map, game.currentNodeId)
                        end
                        state = "map"
                    else
                        state = "map"
                    end
                    if state == "shop" then saveRunAtSafePoint() end
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
                        game.run.maxAnte = RunManager.MAX_ANTE
                        game.run.travelPermit = true
                        game.run.ante = (game.run.ante or 20) + 1
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
    if key=="f8" then UI.BedExplosion.debug=not UI.BedExplosion.debug;return end
    if UI.BedExplosion.keypressed(key) then return end
    if handDrag.active then
        UI.CardPhysics.release()
        handDrag.active, handDrag.isDragging, handDrag.cardIndex = false, false, nil
    end
    if anim.enemyTurn and key ~= "escape" then return end
    if state == "defeating" or (DeathVFX.enemyActive(game.monster) and DeathVFX.busy()) then return end
    if Renderer.keypressed(key) then return end
    if state == "shop" and UI.Polish.busy() then return end
    if key == "escape" and UI.Polish.focus then UI.Polish.clearFocus();UI.Description.reset();return end
    if (key == "tab" or key == "b" or key == "h") and UI.Polish.focus then UI.Polish.clearFocus() end
    if UI.AbilityUI.key(key) then return end
    if UI.ScoringFeel.labKeypressed(key, UI) then return end
    UI.CardPhysics.labAction(key, CardEffects)
    if UI.CardPhysics.keypressed(key) then return end
    if isUiGalleryOpen then
        if key == "escape" or key == "f8" then isUiGalleryOpen = false end
        return
    end
    if key == "f8" then
        isUiGalleryOpen = true
        return
    end
    if key == CardEffects.debugToggleKey then
        CardEffects.toggleDebug()
        return
    end
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
        settings.fullscreen = Touch.nativeMobile or not settings.fullscreen
        love.window.setFullscreen(settings.fullscreen, "desktop")
        updateScale()
        saveSettings()
        return
    end

    -- Toggle Deck Viewer Modal
    if key == "tab" or key == "b" then
        isDeckViewerOpen = not isDeckViewerOpen
        if not isDeckViewerOpen then game.soulDestroyActive=false;game.soulDestroyConsumable=nil;UI.Polish.clearFocus() end
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
        if pendingEvolutionCard or pendingSpeedCard or pendingEditionCard then
            pendingEvolutionCard = nil
            pendingSpeedCard = nil
            pendingEditionCard = nil
            Sound.play("ui_click")
            return
        end
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
            isDeckViewerOpen = false;game.soulDestroyActive=false;game.soulDestroyConsumable=nil;UI.Polish.clearFocus()
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
            if #game.hand == 0 or (game.handsRemaining or 0) <= 0 then endPlayerTurn() else playSelectedHand() end
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
            UI.ScoringFeel.skipOrFastForward(anim)
        end
    elseif state == "CASH_OUT" then
        if key == "space" or key == "return" then
            if cashOutAnim and not cashOutAnim.finished then
                RewardSystem.finishImmediately(cashOutAnim)
                Sound.play("shop_buy")
            elseif cashOutAnim and cashOutAnim.finished and not game.pendingRoundRewardChoice then
                if not shopData then shopData = Shop.new() end
                Shop.resetReroll(shopData)
                Shop.enterSoulShop(game)
                Shop.refresh(shopData, game)
                state = "shop"
                cashOutAnim.state = "EXIT"
                game.pendingVictoryReward = nil
                RewardSystem.openNextPack(game, shopData)
                saveRunAtSafePoint()
                lastActiveState = "shop"
                Sound.play("card_deal")
            end
        elseif game.pendingRoundRewardChoice and key >= "1" and key <= "3" and cashOutAnim and cashOutAnim.finished then
            chooseRoundReward(tonumber(key))
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
    if (state=="shop" or state=="playing") and not isCollectionOpen and not isDeckViewerOpen
        and not isSettingsOpen and not isPauseMenuOpen and not isHandbookOpen
        and not (shopData and shopData.currentPackOpening) and not UI.Polish.busy() then
        local mx,my=toVirtual(love.mouse.getPosition())
        if UI.InventoryRail.scroll(game,state,mx,my,y) then UI.Polish.clearFocus();return end
    end
    if state == "defeating" or (DeathVFX.enemyActive(game.monster) and DeathVFX.busy()) then return end
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

function love.mousemoved(x, y, dx, dy, istouch)
    if istouch then return end
    Touch.mouseInput()
    if handDrag.active and handInputBlocked() then
        UI.CardPhysics.release()
        handDrag.active, handDrag.isDragging, handDrag.cardIndex = false, false, nil
    end
    if state == "defeating" or (DeathVFX.enemyActive(game.monster) and DeathVFX.busy()) then return end
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

    if handDrag.active and state == "playing" then
        local deltaX, deltaY = mx - handDrag.startX, my - handDrag.startY
        if deltaX * deltaX + deltaY * deltaY > 10 * 10 then
            handDrag.isDragging = true
        end

        if handDrag.mode == "select" then
            sweepHandSelection(mx, my)
        elseif handDrag.mode == "reorder" and handDrag.isDragging then
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
        if handDrag.mode ~= "select" then handDrag.currentX, handDrag.currentY = mx, my end
    end

    if shopDrag.active and state == "shop" then
        shopDrag.currentX = mx
        shopDrag.currentY = my
        local dist = math.sqrt((mx - shopDrag.startX)^2 + (my - shopDrag.startY)^2)
        if dist > 6 then
            shopDrag.isDragging = true
            if shopDrag.sourceKind == "card" and isDeckViewerOpen then
                isDeckViewerOpen = false;game.soulDestroyActive=false;game.soulDestroyConsumable=nil;UI.Polish.clearFocus()
                Sound.play("card_slide")
            end
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

function love.mousereleased(x, y, button, istouch)
    if istouch then return end
    if button == 1 then
        UI.CardPhysics.release()
        if handDrag.active and handInputBlocked() then
            handDrag.active, handDrag.isDragging, handDrag.cardIndex = false, false, nil
        end
    end
    if state == "defeating" or (DeathVFX.enemyActive(game.monster) and DeathVFX.busy()) then return end
    local mx, my = toVirtual(x, y)
    juice.buttonPressedId = nil

    if button == 1 and handDrag.active then
        if handDrag.mode == "select" then
            sweepHandSelection(mx, my)
        elseif not handDrag.isDragging and handDrag.cardIndex then
            local card = game.hand[handDrag.cardIndex]
            if card then
                card.visualScale = 1.15
                card.selectPulse = 1
            end
            toggleCardSelection(handDrag.cardIndex)
            if card then CardEffects.triggerSelectPulse(card) end
        elseif handDrag.isDragging then
            Sound.play("card_slide")
        end
        handDrag.active = false
        handDrag.cardIndex = nil
        handDrag.isDragging = false
    end

    if button == 1 and shopDrag.active then
        if shopDrag.sourceKind then
            if not shopDrag.isDragging and shopDrag.sourceKind == "card" then
                inspectCardModal = shopDrag.item
                Sound.play("card_deal")
            elseif shopDrag.isDragging then
                local altar = shopDrag.sacrificeZone
                local droppedOnAltar = state == "shop" and mx >= altar.x and mx <= altar.x + altar.w and my >= altar.y and my <= altar.y + altar.h
                if droppedOnAltar then
                    local success, value
                    if shopDrag.sourceKind == "card" then
                        success, value = Shop.sellCard(game, shopDrag.item)
                    elseif shopDrag.sourceKind == "consumable" then
                        success, value = Shop.sellConsumable(game, shopDrag.sourceIndex)
                    end
                    if success then
                        local item = shopDrag.sourceKind == "card"
                            and { category = "card", card = shopDrag.item, rank = shopDrag.item.rank, name = shopDrag.item.name }
                            or { category = "consumable", name = shopDrag.item.name, icon = shopDrag.item.icon, color = shopDrag.item.color }
                        spawnShopFx("sacrifice", item, mx, my)
                        table.insert(anim.floatingTexts, {
                            text = "Hiến tế thành công: +$" .. value,
                            color = UI.COLORS.goldYellow,
                            x = altar.x + altar.w / 2,
                            y = altar.y - 18,
                            alpha = 1.8,
                        })
                    else
                        Sound.play("cant_afford")
                    end
                else
                    Sound.play("card_slide")
                    if shopDrag.sourceKind == "card" and not isDeckViewerOpen then
                        for _, btn in ipairs(buttons or {}) do
                            if btn.id == "open_deck_viewer" then
                                UI.CardPhysics.returnTo(btn.x, btn.y)
                                break
                            end
                        end
                    end
                end
            end
        end
        shopDrag.active = false
        shopDrag.isDragging = false
        shopDrag.itemIndex = nil
        shopDrag.item = nil
        shopDrag.sourceKind = nil
        shopDrag.sourceIndex = nil
    end

    if button == 1 and deityDrag.active then
        if deityDrag.isDragging and deityDrag.deityIndex and game.deities then
            local srcSlot = deityDrag.deityIndex
            local altar = shopDrag.sacrificeZone
            if state == "shop" and mx >= altar.x and mx <= altar.x + altar.w and my >= altar.y and my <= altar.y + altar.h then
                local sold = game.deities[srcSlot]
                local price = Shop.getSacrificePrice(sold, "deity", game)
                if Shop.sellDeity(game, srcSlot) then
                    spawnShopFx("sacrifice", { category = "deity", deity = sold, id = sold.id, name = sold.name }, mx, my)
                    table.insert(anim.floatingTexts, {
                        text = "Hiến tế thành công: +$" .. price,
                        color = UI.COLORS.goldYellow,
                        x = altar.x + altar.w / 2,
                        y = altar.y - 18,
                        alpha = 1.8,
                    })
                end
                deityDrag.active = false
                deityDrag.isDragging = false
                deityDrag.deityIndex = nil
                return
            end
            local foundDest = nil
            local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(game) or 5
            local first, last, step = 1, maxDeiSlots, 1
            -- Prefer the visually exposed cards; only use an invisible empty
            -- destination when the pointer is outside every occupied card.
            for i = first, last, step do
                local sx, sy, sw, sh = getDeitySlotRect(i, state)
                if game.deities[i] and mx >= sx - 10 and mx <= sx + sw + 10
                    and my >= sy - 10 and my <= sy + sh + 10 then
                    foundDest = i
                    break
                end
            end
            if not foundDest then
                for i = first, last, step do
                    local sx, sy, sw, sh = getDeitySlotRect(i, state)
                    if not game.deities[i] and mx >= sx - 10 and mx <= sx + sw + 10
                        and my >= sy - 10 and my <= sy + sh + 10 then
                        foundDest = i
                        break
                    end
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

Touch.install({press=love.mousepressed,move=love.mousemoved,release=love.mousereleased,
    canScroll=function(dx,dy)
        Touch.wheelY=0
        if isCollectionOpen and collectionCategory~=nil or state=="map" then return true end
        return math.abs(dy or 0)>math.abs(dx or 0) and UI.InventoryRail.canSwipe(game,state,toVirtual(Touch.x,Touch.y))
    end,
    scroll=function(dy)
        if state=="shop" or state=="playing" then
            Touch.wheelY=(Touch.wheelY or 0)+dy/(Layout.scaleY*RENDER_SCALE)
            if math.abs(Touch.wheelY)>=45 then
                love.wheelmoved(0,Touch.wheelY>0 and 1 or -1);Touch.wheelY=0
            end
        else love.wheelmoved(0,dy/Layout.scaleY/45) end
    end,
    cancel=function()
        UI.CardPhysics.release()
        handDrag.active,handDrag.isDragging,handDrag.cardIndex=false,false,nil
        shopDrag.active,shopDrag.isDragging=false,false
        deityDrag.active,deityDrag.isDragging=false,false
        juice.buttonPressedId=nil
    end})
love.touchpressed = Touch.press
love.touchmoved = Touch.move
love.touchreleased = Touch.release

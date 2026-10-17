local Deck = require("src.deck")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local RunManager = require("src.run_manager")
local Rng = require("src.rng")

local Persistence = {
    SAVE_VERSION = 2,
    RUN_FILE = "run_save.lua",
    SETTINGS_FILE = "settings.lua",
}

local TRANSIENT_GAME_KEYS = {
    map = true,
    abilityCombat = true,
    depthCombat = true,
    enchantmentCombat = true,
    spnCombat = true,
    spnAttack = true,
    spnFeedback = true,
    spnDiscardCap = true,
    spnBasicArmorGranted = true,
    spnOpeningAttackUsed = true,
    abilityHand = true,
    advancedHand = true,
    advancedCombat = true,
    advancedFeedback = true,
    abilityApproved = true,
    monster = true,
    enemies = true,
    enemyPoison = true,
    enemyFeedback = true,
    potionCombat = true,
    potionFeedback = true,
    potionVictoryPending = true,
    enemyActed = true,
    enemyActionPhases = true,
    deck = true,
    hand = true,
    discardPile = true,
    selectedIndices = true,
    currentEvent = true,
    eventOutcomeText = true,
    bossDeityDraft = true,
    currentNodeId = true,
    soulDestroyActive = true,
    soulDestroyConsumable = true,
    soulRelicCombat = true,
}

local function sanitize(value, seen)
    local valueType = type(value)
    if valueType == "nil" or valueType == "boolean" or valueType == "number" or valueType == "string" then
        return value
    end
    if valueType ~= "table" then return nil end

    seen = seen or {}
    if seen[value] then return nil end
    seen[value] = true

    local result = {}
    for key, child in pairs(value) do
        local cleanKey = sanitize(key, seen)
        local cleanValue = sanitize(child, seen)
        if cleanKey ~= nil and cleanValue ~= nil then
            result[cleanKey] = cleanValue
        end
    end
    seen[value] = nil
    return result
end

local function keyRank(key)
    if type(key) == "number" then return 1 end
    if type(key) == "string" then return 2 end
    if type(key) == "boolean" then return 3 end
    return 4
end

local function serialize(value, indent, seen)
    indent = indent or ""
    local valueType = type(value)
    if valueType == "nil" then return "nil" end
    if valueType == "boolean" or valueType == "number" then return tostring(value) end
    if valueType == "string" then return string.format("%q", value) end
    if valueType ~= "table" then return "nil" end

    seen = seen or {}
    if seen[value] then error("Cannot serialize cyclic table") end
    seen[value] = true

    local keys = {}
    for key in pairs(value) do table.insert(keys, key) end
    table.sort(keys, function(a, b)
        local ar, br = keyRank(a), keyRank(b)
        if ar ~= br then return ar < br end
        return tostring(a) < tostring(b)
    end)

    local childIndent = indent .. "  "
    local parts = { "{" }
    for _, key in ipairs(keys) do
        local encodedKey = "[" .. serialize(key, childIndent, seen) .. "]"
        local encodedValue = serialize(value[key], childIndent, seen)
        table.insert(parts, "\n" .. childIndent .. encodedKey .. " = " .. encodedValue .. ",")
    end
    if #keys > 0 then table.insert(parts, "\n" .. indent) end
    table.insert(parts, "}")
    seen[value] = nil
    return table.concat(parts)
end

local function snapshotRun(run)
    if not run then return nil end
    local result = {
        faction = run.faction,
        selectedFaction = run.selectedFaction,
        ante = run.ante,
        regionId = run.regionId,
        areaStage = run.areaStage,
        maxAnte = run.maxAnte,
        currentBlindIndex = run.currentBlindIndex,
        victory = run.victory,
        endless = run.endless,
        travelPermit = run.travelPermit,
        regionStagesWon = sanitize(run.regionStagesWon),
        difficultyCap = run.difficultyCap,
        regionStartAnte = run.regionStartAnte,
        travelRulesVersion = 2,
        shopsVisitedInAnte = run.shopsVisitedInAnte,
        stats = sanitize(run.stats),
        blinds = {},
    }
    for i, blind in ipairs(run.blinds or {}) do
        result.blinds[i] = {
            status = blind.status,
            tagId = blind.tag and blind.tag.id or nil,
        }
    end
    return result
end

local function restoreRun(saved, faction)
    if not saved then return RunManager.newRun(faction) end
    local run = RunManager.newRun(saved.selectedFaction or saved.faction or faction)
    run.ante = math.max(1, tonumber(saved.ante) or 1)
    local Expedition=require("src.expedition")
    run.regionId=Expedition.byId[saved.regionId] and saved.regionId~="voyage" and saved.regionId or (run.ante>40 and "unknown" or "human")
    run.areaStage=math.max(1,math.floor(tonumber(saved.areaStage) or (run.regionId=="unknown" and run.ante-40 or ((run.ante-1)%20)+1)))
    if run.regionId~="unknown" then run.areaStage=math.min(20,run.areaStage) end
    run.maxAnte = RunManager.MAX_ANTE
    run.currentBlindIndex = math.max(1, math.min(3, tonumber(saved.currentBlindIndex) or 1))
    run.victory = saved.victory == true
    run.endless = saved.endless == true or run.ante > 20
    run.travelPermit = saved.travelPermit == true and (saved.regionId~=nil or run.ante<=20)
    run.regionStagesWon=sanitize(saved.regionStagesWon) or {}
    run.regionStartAnte=tonumber(saved.regionStartAnte) or run.ante-run.areaStage+1
    if run.regionId~="unknown" then
        local cap=tonumber(saved.difficultyCap)
        if cap and cap>=1 then run.difficultyCap=math.min(run.ante,math.floor(cap)) end
        if saved.travelRulesVersion~=2 and run.victory and run.areaStage==20 then run.difficultyCap=run.ante end
    end
    if run.areaStage<20 or run.regionId=="unknown" then run.victory=false end
    run.shopsVisitedInAnte = tonumber(saved.shopsVisitedInAnte) or 0
    run.stats = sanitize(saved.stats) or run.stats
    run.blinds = RunManager.generateAnteBlinds(run.ante, run.selectedFaction,run.regionId,run.areaStage,run.difficultyCap)
    for i, blind in ipairs(run.blinds) do
        local savedBlind = saved.blinds and saved.blinds[i]
        blind.status = savedBlind and savedBlind.status or (i == run.currentBlindIndex and "current" or "upcoming")
        if blind.status ~= "completed" then blind.status = i == run.currentBlindIndex and "current" or "upcoming" end
    end
    if saved.victory and run.ante < 20 and run.blinds[run.currentBlindIndex].status == "completed" then
        RunManager.advanceBlind(run)
    end
    -- Old victory saves represent an earned, unspent permit.
    if run.victory and run.blinds[3].status=="completed" then run.travelPermit=true end
    if run.regionStagesWon[run.regionId]==nil then
        run.regionStagesWon[run.regionId]=run.areaStage-1+(run.blinds[3].status=="completed" and 1 or 0)
    end
    return run
end

local function restoreEquipment(savedEquipment)
    if not savedEquipment or not savedEquipment.id then return nil end
    local definition=Equipment.ITEMS[savedEquipment.id]
    if not definition then return nil end
    return Equipment.instance(savedEquipment.id,savedEquipment)
end

local function restoreCard(savedCard)
    local card = Deck.newCard(savedCard.baseRank or savedCard.rank or 2, savedCard.suit or "aurelia")
    for key, value in pairs(savedCard) do
        if key ~= "equipments" then card[key] = sanitize(value) end
    end
    card.seal=Deck.normalizeSeal(card.seal)
    card.isAnchor=card.seal=="seal_anchor"
    card.equipments = {}
    for _, savedEquipment in ipairs(savedCard.equipments or {}) do
        local equipment = restoreEquipment(savedEquipment)
        if equipment then table.insert(card.equipments, equipment) end
    end
    card.evolutionLevel = math.max(0, math.min(require("config.card_ability_data").maxEvolutionLevel, tonumber(card.evolutionLevel) or 0))
    card.temporaryAbilityLevels, card.abilityState, card.abilityDisabledUntil = nil, nil, nil
    card.disableFactionPassives=true;card.isWildSuit=false;card.isDualRankAce=false
    card.maxSockets = Equipment.getMaxSlots(card)
    card.unlockedSockets = card.maxSockets
    card.allowDuplicateEquipment = card.allowDuplicateEquipment == true
    card.selected = false
    card.hovered = false
    card.faceDown = false
    Deck.ensureNextCardId(card.id)
    return card
end

local function restoreDeity(savedDeity)
    if not savedDeity or not savedDeity.id then return nil end
    local catalogEntry = Deities.CATALOG[savedDeity.id]
    if not catalogEntry then return nil end
    local deity = {}
    for key, value in pairs(catalogEntry) do deity[key] = value end
    for key, value in pairs(savedDeity) do
        if type(value) ~= "function" then deity[key] = sanitize(value) end
    end
    require("src.spn_convergence").migrate(deity)
    require("src.spn_enchantments").migrateDeity(deity)
    return deity
end

function Persistence.makeSnapshot(game, activeState)
    if game then require("src.void_tickets").count(game) end
    local savedGame = {}
    for key, value in pairs(game or {}) do
        if not TRANSIENT_GAME_KEYS[key] and key ~= "run" then
            savedGame[key] = sanitize(value)
        end
    end
    savedGame.run = snapshotRun(game and game.run)
    return {
        version = Persistence.SAVE_VERSION,
        rngState = Rng.getState(),
        activeState = activeState == "victory" and "victory"
            or (activeState == "travel" and game.travelRequest and "travel")
            or (activeState == "CASH_OUT" and game.pendingVictoryReward and "CASH_OUT")
            or (activeState == "socketing" and game.pendingRewardEquipment and "socketing")
            or (activeState == "shop" and "shop")
            or (activeState == "barter" and game.barterEvent and "barter")
            or (activeState == "void" and game.voidEvent and "void")
            or "BLIND_SELECT",
        game = savedGame,
    }
end

function Persistence.restoreSnapshot(snapshot)
    if type(snapshot) ~= "table" or snapshot.version ~= Persistence.SAVE_VERSION or type(snapshot.game) ~= "table" then
        return nil, "Phiên bản save không hợp lệ hoặc không còn được hỗ trợ."
    end

    local game = sanitize(snapshot.game)
    game.selectedFaction = game.selectedFaction or game.selectedSuit or "aurelia"
    game.selectedSuit = game.selectedFaction
    game.persistentDeck = {}
    for _, savedCard in ipairs(snapshot.game.persistentDeck or {}) do
        table.insert(game.persistentDeck, restoreCard(savedCard))
    end
    for _, opening in ipairs(game.rewardPacks or {}) do
        if opening.pack and opening.pack.packType == "standard" then
            for i, card in ipairs(opening.cards or {}) do opening.cards[i] = restoreCard(card) end
        end
    end
    local function migrateStamp(item)
        if not item then return end
        local id=Deck.normalizeSeal(item.sealType or item.id)
        local d=Deck.SEALS[id]
        if d then
            for _,field in ipairs({"id","sealType","sealName","name","subtitle","desc","icon","color","symbol","params"}) do item[field]=d[field] end
            item.category="seal"
        end
    end
    for _,item in ipairs(game.consumables or {}) do migrateStamp(item) end
    for _,item in ipairs(game.backpackConsumables or {}) do migrateStamp(item) end
    for _,opening in ipairs(game.rewardPacks or {}) do
        if opening.pack and opening.pack.packType=="seal" then
            local seen={}
            for i=#(opening.cards or {}),1,-1 do
                local item=opening.cards[i];migrateStamp(item)
                if seen[item.id] then table.remove(opening.cards,i) else seen[item.id]=true end
            end
        end
    end
    local Enchantments=require("src.spn_enchantments")
    for _,list in ipairs({game.consumables or {},game.backpackConsumables or {}}) do
        for _,item in ipairs(list) do Enchantments.migrateItem(item) end
    end
    for _,opening in ipairs(game.rewardPacks or {}) do
        if opening.pack and opening.pack.packType=="joker_edition" then
            local seen={}
            for i=#(opening.cards or {}),1,-1 do
                local item=opening.cards[i];Enchantments.migrateItem(item)
                if seen[item.id] then table.remove(opening.cards,i) else seen[item.id]=true end
            end
        end
    end
    local Spectral=require("src.spectral")
    for _,list in ipairs({game.consumables or {},game.backpackConsumables or {}}) do
        for _,item in ipairs(list) do Spectral.migrateItem(item) end
    end
    for _,opening in ipairs(game.rewardPacks or {}) do
        if opening.pack and opening.pack.packType=="spectral" then
            local seen={}
            for i=#(opening.cards or {}),1,-1 do
                local item=opening.cards[i];Spectral.migrateItem(item)
                if seen[item.id] then table.remove(opening.cards,i) else seen[item.id]=true end
            end
        end
    end
    game.masterDeck = game.persistentDeck
    game.deities = {}
    for slot, savedDeity in pairs(snapshot.game.deities or {}) do
        local deity = restoreDeity(savedDeity)
        if deity then game.deities[slot] = deity end
    end
    game.backpackDeities={}
    for _,savedDeity in ipairs(snapshot.game.backpackDeities or {}) do
        local deity=restoreDeity(savedDeity)
        if deity then game.backpackDeities[#game.backpackDeities+1]=deity end
    end
    for _,list in ipairs({game.consumables or {},game.backpackConsumables or {}}) do
        for _,item in ipairs(list) do
            if item.card then item.card=restoreCard(item.card) end
            if item.id=="cons_travel_permit" then item.desc=require("src.expedition").travelPermit().desc end
        end
    end
    require("src.loadout").init(game)
    require("src.void_tickets").count(game)
    game.run = restoreRun(snapshot.game.run, game.selectedFaction)
    if game.barterEvent then require("src.barter").restore(game) end
    game.regionRecognitions=game.regionRecognitions or {}
    if game.run.travelPermit and snapshot.game.run.travelRulesVersion~=2 then
        local found=false
        for _,list in ipairs({game.backpackConsumables or {},game.consumables or {}}) do
            for _,item in ipairs(list) do if item.id=="cons_travel_permit" then found=true end end
        end
        if not found then require("src.loadout").storeConsumable(game,require("src.expedition").travelPermit()) end
        local card=require("src.expedition").recognitionCard(game.run.regionId)
        if card then game.regionRecognitions[game.run.regionId]=true end
    end
    -- Rebuilding the run may consume random values; restore the exact saved
    -- gameplay RNG state afterwards so future outcomes remain reproducible.
    if snapshot.rngState then Rng.setState(snapshot.rngState) end
    game.map = nil
    game.monster = nil
    game.enemies = nil
    game.deck = {}
    game.hand = {}
    game.discardPile = {}
    game.selectedIndices = {}
    game.currentNodeId = nil
    Deck.restoreDeck(game.persistentDeck)
    local restoredState = snapshot.activeState or "BLIND_SELECT"
    if restoredState=="travel" and game.travelRequest and game.travelRequest.returnState=="playing" then
        game.travelRequest.returnState="BLIND_SELECT"
    end
    if restoredState=="victory" and game.run.victory and game.run.difficultyCap then
        RunManager.advanceBlind(game.run,game);restoredState="BLIND_SELECT"
    end
    game.souls = math.max(0, tonumber(game.souls) or 0)
    local markets=require("src.shop").MARKETS
    game.shopMode = markets[game.shopMode] and game.shopMode or "small"
    game.soulDestroyActive = false
    if game.pendingRewardEquipment then game.pendingRewardEquipment = restoreEquipment(game.pendingRewardEquipment) end
    if restoredState == "victory" and not game.run.victory then restoredState = "BLIND_SELECT" end
    -- Older saves collapsed ordinary shops to BLIND_SELECT while leaving the
    -- just-won fight completed. Resume its post-fight step, without replaying
    -- combat, paying rewards again, or advancing before the shop is left.
    if restoredState == "BLIND_SELECT" then
        local current = RunManager.getCurrentBlind(game.run)
        if game.run.victory then restoredState = "victory"
        elseif current and current.status == "completed" then
            restoredState = game.pendingVictoryReward and "CASH_OUT"
                or game.pendingRewardEquipment and "socketing" or "shop"
        end
    end
    game.currentBlind = RunManager.getCurrentBlind(game.run)
    return game, restoredState
end

function Persistence.encode(value)
    return "return " .. serialize(sanitize(value))
end

function Persistence.decode(source, chunkName)
    if type(source) ~= "string" then return nil, "Save data must be a string" end
    local loader = loadstring or load
    local chunk, err = loader(source, chunkName or "save")
    if not chunk then return nil, err end
    -- Save files contain only a returned table. On Lua 5.1/LuaJIT, remove
    -- access to globals so a modified save cannot call OS or LÖVE APIs.
    if setfenv then setfenv(chunk, {}) end
    local ok, value = pcall(chunk)
    if not ok then return nil, value end
    return value
end

function Persistence.saveRun(game, activeState)
    if not love or not love.filesystem then return false, "LÖVE filesystem unavailable" end
    return love.filesystem.write(Persistence.RUN_FILE, Persistence.encode(Persistence.makeSnapshot(game, activeState)))
end

function Persistence.loadRun()
    if not love or not love.filesystem or not love.filesystem.getInfo(Persistence.RUN_FILE) then return nil end
    local source, readError = love.filesystem.read(Persistence.RUN_FILE)
    if not source then return nil, readError end
    local snapshot, decodeError = Persistence.decode(source, "@" .. Persistence.RUN_FILE)
    if not snapshot then return nil, decodeError end
    return Persistence.restoreSnapshot(snapshot)
end

function Persistence.deleteRun()
    if love and love.filesystem and love.filesystem.getInfo(Persistence.RUN_FILE) then
        return love.filesystem.remove(Persistence.RUN_FILE)
    end
    return true
end

function Persistence.saveSettings(settings)
    if not love or not love.filesystem then return false, "LÖVE filesystem unavailable" end
    local payload = { version = Persistence.SAVE_VERSION, settings = sanitize(settings) }
    return love.filesystem.write(Persistence.SETTINGS_FILE, Persistence.encode(payload))
end

function Persistence.loadSettings(defaults)
    local merged = sanitize(defaults) or {}
    if not love or not love.filesystem or not love.filesystem.getInfo(Persistence.SETTINGS_FILE) then return merged end
    local source = love.filesystem.read(Persistence.SETTINGS_FILE)
    local payload = source and Persistence.decode(source, "@" .. Persistence.SETTINGS_FILE) or nil
    if payload and payload.version == Persistence.SAVE_VERSION and type(payload.settings) == "table" then
        for key, value in pairs(payload.settings) do
            if merged[key] ~= nil and type(value) == type(merged[key]) then merged[key] = value end
        end
    end
    return merged
end

return Persistence

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
    monster = true,
    deck = true,
    hand = true,
    discardPile = true,
    selectedIndices = true,
    currentEvent = true,
    eventOutcomeText = true,
    bossDeityDraft = true,
    currentNodeId = true,
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

local function findTag(tagId)
    for _, tag in ipairs(RunManager.TAGS) do
        if tag.id == tagId then return tag end
    end
end

local function snapshotRun(run)
    if not run then return nil end
    local result = {
        faction = run.faction,
        selectedFaction = run.selectedFaction,
        ante = run.ante,
        maxAnte = run.maxAnte,
        currentBlindIndex = run.currentBlindIndex,
        victory = run.victory,
        endless = run.endless,
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
    run.maxAnte = math.max(run.ante, tonumber(saved.maxAnte) or RunManager.MAX_ANTE)
    run.currentBlindIndex = math.max(1, math.min(3, tonumber(saved.currentBlindIndex) or 1))
    run.victory = saved.victory == true
    run.endless = saved.endless == true
    run.shopsVisitedInAnte = tonumber(saved.shopsVisitedInAnte) or 0
    run.stats = sanitize(saved.stats) or run.stats
    run.blinds = RunManager.generateAnteBlinds(run.ante, run.selectedFaction)
    for i, blind in ipairs(run.blinds) do
        local savedBlind = saved.blinds and saved.blinds[i]
        blind.status = savedBlind and savedBlind.status or (i == run.currentBlindIndex and "current" or "upcoming")
        if savedBlind and savedBlind.tagId then
            blind.tag = findTag(savedBlind.tagId) or blind.tag
        end
    end
    return run
end

local function restoreEquipment(savedEquipment)
    if not savedEquipment or not savedEquipment.id then return nil end
    return Equipment.ITEMS[savedEquipment.id]
end

local function restoreCard(savedCard)
    local card = Deck.newCard(savedCard.baseRank or savedCard.rank or 2, savedCard.suit or "aurelia")
    for key, value in pairs(savedCard) do
        if key ~= "equipments" then card[key] = sanitize(value) end
    end
    card.equipments = {}
    for _, savedEquipment in ipairs(savedCard.equipments or {}) do
        local equipment = restoreEquipment(savedEquipment)
        if equipment then table.insert(card.equipments, equipment) end
    end
    card.maxSockets = Equipment.MAX_SLOTS
    card.unlockedSockets = Equipment.MAX_SLOTS
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
    return deity
end

function Persistence.makeSnapshot(game, activeState)
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
        activeState = activeState == "victory" and "victory" or "BLIND_SELECT",
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
    game.masterDeck = game.persistentDeck
    game.deities = {}
    for slot, savedDeity in pairs(snapshot.game.deities or {}) do
        local deity = restoreDeity(savedDeity)
        if deity then game.deities[slot] = deity end
    end
    game.run = restoreRun(snapshot.game.run, game.selectedFaction)
    -- Rebuilding the run may consume random values; restore the exact saved
    -- gameplay RNG state afterwards so future outcomes remain reproducible.
    if snapshot.rngState then Rng.setState(snapshot.rngState) end
    game.map = nil
    game.monster = nil
    game.deck = {}
    game.hand = {}
    game.discardPile = {}
    game.selectedIndices = {}
    game.currentNodeId = nil
    Deck.restoreDeck(game.persistentDeck)
    return game, snapshot.activeState or "BLIND_SELECT"
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

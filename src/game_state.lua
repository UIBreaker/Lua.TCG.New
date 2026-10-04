local GameState = {}

local HAND_IDS = {
    "high_card", "pair", "two_pair", "three_of_a_kind", "straight",
    "flush", "full_house", "four_of_a_kind", "straight_flush",
}

function GameState.resetRun(game, faction)
    game = game or {}
    faction = faction or "red_deck"

    -- Persistent run state.
    game.selectedFaction = faction
    game.selectedSuit = faction
    game.starterDeckId = faction
    game.factionPassivesEnabled = faction ~= "red_deck"
    game.round = 1
    game.act = 1
    game.gold = 6
    game.souls = 0
    game.soulDestroyedIds = {}
    game.shopMode = "normal"
    game.pendingSoulShop = false
    game.soulShopPurchased = {}
    game.soulDestroyActive = false
    game.soulDestroyConsumable = nil
    game.pendingShopEquipment = nil
    game.pendingRewardEquipment = nil
    game.playerHp = 100
    game.maxPlayerHp = 100
    game.maxHands = 3
    game.handsRemaining = 3
    game.maxDiscards = faction == "valoria" and 4 or 3
    game.discardsRemaining = game.maxDiscards
    game.maxHandSize = 3
    game.maxInterest = 5
    game.hasSeedMoney = false
    game.freeRerolls = 0
    game.vouchers = {}
    game.unlockedHands = { high_card = true }
    game.handLevels = {}
    for _, handId in ipairs(HAND_IDS) do game.handLevels[handId] = 1 end
    game.consumables = {}
    game.pendingEvolutionCards = 0
    game.deities = {}
    game.persistentDeck = {}
    game.masterDeck = game.persistentDeck
    game.run = nil

    -- Faction flags use the legacy ids retained by the content catalog.
    game.isGildedConclave = faction == "diamonds" or faction == "aurelia" or faction == "gilded_conclave"
    game.isAxiom = faction == "spades" or faction == "vharos" or faction == "iron_axiom"
    game.isSanguine = faction == "hearts" or faction == "valoria" or faction == "sanguine_covenant"
    game.isSwarm = faction == "clubs" or faction == "elaris" or faction == "feral_swarm"

    -- Run-scoped counters/unlocks.
    game.monsterEncounterCount = 1
    game.martyrStacks = 0
    game.storedSlaughterChips = 0
    game.jHeartDiscardUsed = false
    game.sacredFruitExtinct = false
    game.playedHandsHistory = {}
    game.handsPlayedThisCombat = 0
    game.sortMode = "rank"

    -- Transient combat/map state must never leak between runs.
    game.map = nil
    game.currentNodeId = nil
    game.currentEvent = nil
    game.eventOutcomeText = nil
    game.bossDeityDraft = {}
    game.monster = nil
    game.enemies = nil
    game.enemyPoison = 0
    game.playerShield = 0
    game.playerArmor = 0
    game.deck = {}
    game.discardPile = {}
    game.hand = {}
    game.selectedIndices = {}
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }
    game.maxSelectableCards = nil
    return game
end

function GameState.new(faction)
    return GameState.resetRun({}, faction)
end

return GameState

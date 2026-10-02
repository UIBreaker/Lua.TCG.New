local Deck = require("src.deck")
local Deities = require("src.deities")

local Abilities = require("src.card_abilities")
local Boss = require("src.boss_abilities")
local Combat = { Abilities = Abilities, Boss = Boss }

function Combat.getOutcome(game)
    if not game or not game.monster then return "continue" end
    if game.playerHp and game.playerHp <= 0 then return "defeat" end
    if game.monster.hp and game.monster.hp <= 0 then return "victory" end
    local noCards = #(game.hand or {}) + #(game.deck or {}) + #(game.discardPile or {}) == 0
    local handLimitIsFinal = game.monster.isBoss and game.monster.bossData
        and game.monster.bossData.debuffId == "the_needle" and Boss.passiveEnabled(game.monster)
    if game.handsRemaining and game.handsRemaining <= 0 and (noCards or handLimitIsFinal) then return "defeat" end
    return "continue"
end

function Combat.getAverageAttackSpeed(cards)
    local total, count = 0, 0
    for _, card in ipairs(cards or {}) do
        total = total + Deck.getCardAttackSpeed(card)
        count = count + 1
    end
    return count > 0 and (total / count) or 0
end

function Combat.resolveMonsterAttack(game)
    local monster = game and game.monster
    if not monster or (monster.hp or 0) <= 0 then return nil end

    if not Boss.beforeAttack(game) then return {attack=0,absorbed=0,damage=0,killedPlayer=false,blocked=true} end
    local baseAttack = (monster.attack or 12)
    local attack = baseAttack
    local bossState = Boss.state(monster)
    if bossState and Boss.passiveEnabled(monster) then attack=attack+(bossState.excess or 0)*Boss.config.gateAttackPerCard end
    local execution = Boss.key(monster)=="executioner" and Boss.passiveEnabled(monster)
        and (game.playerHp or 100)<(game.maxPlayerHp or 100)*Boss.config.executionThreshold
    if execution then attack=attack*Boss.config.executionMultiplier end
    local armor = execution and 0 or (game.playerArmor or game.playerShield or 0)
    local absorbed = math.min(armor, attack)
    armor = math.floor((armor - absorbed) * 0.5)
    local damage = math.min(attack - absorbed, math.floor((game.maxPlayerHp or 100) * 0.60))

    damage = Abilities.damageGuard(game, damage)
    game.playerArmor = execution and (game.playerArmor or game.playerShield or 0) or armor
    game.playerShield = game.playerArmor
    game.playerHp = math.max(0, (game.playerHp or 100) - damage)
    monster.attack = math.floor(baseAttack * 1.08 + 0.5)
    monster.armor = math.floor((monster.armor or 0) * 1.05 + 2)

    for _, card in ipairs(game.hand or {}) do
        if card.enhancement == "enh_escort" or card.enhancement == "escort" then
            game.playerArmor = math.min(30, (game.playerArmor or 0) + Deck.ENHANCEMENTS.enh_escort.params.armor)
            game.playerShield = game.playerArmor
        end
    end

    return {
        attack = attack,
        absorbed = absorbed,
        damage = damage,
        killedPlayer = game.playerHp <= 0,
        playerSpeed = game.lastPlayerAttackSpeed or 0,
        monsterSpeed = monster.attackSpeed or 1,
    }
end

function Combat.drawCards(game, maxHandSize, prepareDraw, recycleDiscard)
    if not game then return 0 end
    game.deck = game.deck or {}
    game.discardPile = game.discardPile or {}
    game.hand = game.hand or {}

    if recycleDiscard and #game.deck == 0 and #game.discardPile > 0 then
        while #game.discardPile > 0 do
            table.insert(game.deck, table.remove(game.discardPile))
        end
        Deck.shuffle(game.deck)
    end

    local drawnCount = 0
    while #game.hand < Abilities.handSize(game, maxHandSize) and #game.deck > 0 do
        local card = table.remove(game.deck)
        card.selected = false
        drawnCount = drawnCount + 1
        if prepareDraw then prepareDraw(card, drawnCount) end
        table.insert(game.hand, card)
    end
    if Boss.passiveEnabled(game.monster) and (Boss.key(game.monster)=="faceless" or Boss.key(game.monster)=="the_fish") then
        for _,c in ipairs(game.hand) do c.faceDown=true end
    end
    return drawnCount
end

local function isFaction(game, id)
    return game.selectedFaction == id or game.selectedSuit == id
end

function Combat.start(game, monster, round)
    assert(game and monster, "Combat.start requires game state and monster")
    game.round = round or 1
    game.monster = monster
    game.maxSelectableCards = nil
    game.abilityHand = nil
    Boss.start(game)
    game.handsRemaining = game.maxHands
    game.playerArmor = 0
    game.playerShield = 0
    game.discardsUsedInCombat = 0
    game.discardsRemaining = isFaction(game, "valoria") and (game.maxDiscards + 1) or game.maxDiscards
    game.martyrStacks = 0
    game.jHeartDiscardUsed = false
    game.playedHandsHistory = {}
    game.handsPlayedThisCombat = 0
    game.selectedIndices = {}
    game.discardBuffs = { chips = 0, mult = 0, xMult = 1.0, bonusDamagePct = 0 }

    -- Boss modifiers and deity round-start effects are intentionally combat
    -- scoped. Persistent limits such as maxHands/maxDiscards are never reset.
    if monster.isBoss and monster.bossData and monster.bossData.applyModifier then
        monster.bossData.applyModifier(game)
    end
    local maxSlots = Deities.getMaxSlots(game)
    for slot = 1, maxSlots do
        local deity = game.deities and game.deities[slot]
        if deity and deity.onRoundStart then
            local result = deity.onRoundStart(game)
            game.discardsRemaining = game.discardsRemaining + (result and result.addDiscards or 0)
            game.handsRemaining = game.handsRemaining + (result and result.addHands or 0)
        end
    end
    game.turnHandLimit = game.handsRemaining

    local slaughterChips = game.storedSlaughterChips or 0
    if slaughterChips > 0 then
        game.discardBuffs.chips = slaughterChips
        game.storedSlaughterChips = 0
    end

    game.combatFlags = {
        bloodSealUsed = false,
        bloodSealUsedThisCombat = false,
        vitalityGemUsed = false,
        holyRelicTriggered = false,
        purifyingSealUsed = false,
    }

    if not game.persistentDeck or #game.persistentDeck == 0 then
        game.persistentDeck = Deck.createStarterDeck(game.selectedFaction or game.selectedSuit or "aurelia")
    end
    Deck.restoreDeck(game.persistentDeck)
    game.masterDeck = game.persistentDeck
    game.deck = {}
    for _, card in ipairs(game.persistentDeck) do
        table.insert(game.deck, Deck.cloneCard(card))
    end
    game.discardPile = {}
    game.hand = {}
    Deck.shuffle(game.deck)

    -- Anchor Seal (Ấn Neo): Prioritize cards with Anchor Seal to be dealt in the opening hand
    local anchors = {}
    local nonAnchors = {}
    for _, c in ipairs(game.deck) do
        if c.isAnchor or c.seal == "seal_anchor" or c.seal == "anchor" then
            table.insert(anchors, c)
        else
            table.insert(nonAnchors, c)
        end
    end
    if #anchors > 0 then
        game.deck = {}
        for _, c in ipairs(nonAnchors) do table.insert(game.deck, c) end
        for _, c in ipairs(anchors) do table.insert(game.deck, c) end -- popped first from the end
    end

    Abilities.start(game)
    local maxHandSize = isFaction(game, "elaris") and ((game.maxHandSize or 3) + 1) or (game.maxHandSize or 3)
    local dealOrder = 0
    while #game.hand < Abilities.handSize(game, maxHandSize) and #game.deck > 0 do
        local card = table.remove(game.deck)
        dealOrder = dealOrder + 1
        card.selected = false
        card.visualX = 1180
        card.visualY = 620
        card.visualAngle = -0.12 + dealOrder * 0.025
        card.visualScale = 0.68
        card.dealPending = true
        card.dealDelay = (dealOrder - 1) * 0.075
        card.dealTrail = 0
        local isAxiomCard = not card.disableFactionPassives and (card.suit == "spades" or card.suit == "vharos" or card.suit == "iron_axiom")
        local bossData = monster.bossData
        if not isAxiomCard and monster.isBoss and bossData and (bossData.id == "the_fish" or bossData.debuffId == "the_fish") then
            card.faceDown = true
        end
        table.insert(game.hand, card)
    end

    -- Prophecy Seal (Ấn Tiên Tri): If any card in opening hand has Prophecy Seal, reveal 2 next intents
    for _, c in ipairs(game.hand) do
        if c.seal == "seal_prophecy" or c.seal == "prophecy" or c.seal == "blue" then
            monster.showNextIntent = true
            monster.revealedIntents = 2
        end
    end

    if isFaction(game, "vharos") or isFaction(game, "spades") or isFaction(game, "iron_axiom") or game.sortMode == "rank" then
        Deck.sortByRank(game.hand)
    else
        Deck.sortBySuit(game.hand)
    end
    Abilities.handStart(game)
    return { slaughterChips = slaughterChips }
end

-- Purification Seal (Ấn Thanh Tẩy): Cleanses 1 debuff when held in hand during monster action
function Combat.onMonsterTurnEnd(game)
    if not game or not game.hand then return false end
    game.combatFlags = game.combatFlags or {}
    if not game.combatFlags.purifyingSealUsed then
        for _, c in ipairs(game.hand) do
            if c.seal == "seal_purifying" or c.seal == "purifying" then
                game.combatFlags.purifyingSealUsed = true
                if game.monster and game.monster.bossData then
                    game.monster.bossDebuffCleansed = true
                end
                return true, "Ấn Thanh Tẩy đã giải trừ 1 hiệu ứng áp chế!"
            end
        end
    end
    return false
end

-- End of turn lifecycle: recovers exhausted cards and checks persistent states
function Combat.onPlayerTurnEnd(game)
    if not game or not game.hand then return end
    for _, c in ipairs(game.hand) do
        if c.exhausted then
            if c.justExhausted then
                c.justExhausted = nil
            else
                c.exhausted = false
            end
        end
    end
end

-- Permadeath: Cleanly and permanently destroys cards marked with card.destroyed from combat & persistent deck
function Combat.cleanupDestroyedCards(game)
    if not game then return {} end
    local destroyedIds = {}
    local function filterDestroyed(tbl)
        if not tbl then return end
        for i = #tbl, 1, -1 do
            local c = tbl[i]
            if c and c.destroyed then
                Abilities.destroy(game, c)
                if c.id then
                    destroyedIds[c.id] = true
                    if tonumber(c.id) then destroyedIds[tonumber(c.id)] = true end
                    destroyedIds[tostring(c.id)] = true
                end
                table.remove(tbl, i)
            end
        end
    end

    filterDestroyed(game.hand)
    filterDestroyed(game.deck)
    filterDestroyed(game.discardPile)

    if game.persistentDeck then
        for i = #game.persistentDeck, 1, -1 do
            local pc = game.persistentDeck[i]
            local isDestroyed = pc and (pc.destroyed or (pc.id and (destroyedIds[pc.id] or (tonumber(pc.id) and destroyedIds[tonumber(pc.id)]) or destroyedIds[tostring(pc.id)])))
            if isDestroyed then
                table.remove(game.persistentDeck, i)
            end
        end
    end
    return destroyedIds
end

return Combat

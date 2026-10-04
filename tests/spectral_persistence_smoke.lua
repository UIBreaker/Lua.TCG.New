local Deck = require("src.deck")
local Shop = require("src.shop")
local GameState = require("src.game_state")
local Persistence = require("src.persistence")
local Combat = require("src.combat")
local Monster = require("src.monster")
local Rng = require("src.rng")
local A = require("src.card_abilities")

-- Exercise the actual stored-consumable handler without starting the graphical app.
local file = assert(io.open("main.lua", "r"))
local source = file:read("*a"); file:close()
local first = assert(source:find("local function useConsumable(idx)", 1, true))
local last = assert(source:find("local function activateConsumable", first, true))
local handler = assert(loadstring(source:sub(first, last - 1) .. "\nreturn useConsumable"))
local function applyStored(game, card)
    local env = setmetatable({ game = game, Shop = Shop, Deck = Deck, Rng = Rng,
        Equipment = require("src.equipment"), Poker = require("src.poker"),
        Sound = require("src.sound"), UI = { COLORS = { goldYellow = {} }, BossAbilities = require("src.boss_abilities") },
        anim = { floatingTexts = {} }, destroyHandCard = function(index)
            A.destroy(game, game.hand[index]); Combat.cleanupDestroyedCards(game)
        end }, { __index = _G })
    setfenv(handler, env)
    game.consumables = { card }
    assert(handler()(1))
    assert(#game.consumables == 0)
end
local function contains(cards, id)
    for _, card in ipairs(cards) do if card.id == id then return card end end
end
local function assertSame(expected, actual)
    assert(actual, "persistent card disappeared")
    for _, key in ipairs({ "id", "rank", "baseRank", "suit", "suitSymbol", "baseChips",
        "speedBonus", "evolutionLevel", "edition", "seal", "role" }) do
        assert(expected[key] == actual[key], "lost persistent field: " .. key)
    end
    assert((expected.bonusBaseChips or 0) == (actual.bonusBaseChips or 0))
    assert(#expected.equipments == #actual.equipments, "equipment was lost")
end
for _, stored in ipairs({ false, true }) do
    for _, definition in ipairs(Shop.SPECTRAL_CARDS) do
        Rng.seed(72)
        local game = GameState.new()
        game.persistentDeck = {}
        for rank = 2, 9 do game.persistentDeck[#game.persistentDeck + 1] = Deck.newCard(rank, "hearts") end
        game.masterDeck = game.persistentDeck
        local target = game.persistentDeck[7]
        target.bonusBaseChips, target.baseChips = 15, 23
        target.speedBonus, target.evolutionLevel, target.edition, target.seal = 5, 2, "foil", "seal_bounty"
        game.hand = { Deck.cloneCard(target), Deck.cloneCard(game.persistentDeck[3]) }
        game.deck, game.discardPile = {}, {}
        game.selectedIndices = { 1 }
        A.start(game)
        local oldSuit, oldGold, oldSize = target.suit, game.gold, game.maxHandSize
        local firstId = game.persistentDeck[1].id
        local originalValues={}
        for _,card in ipairs(game.persistentDeck) do originalValues[card.id]=Shop.getSoulValue(card) end
        local id = definition.id
        if stored then applyStored(game, definition)
        else
            local shop = Shop.new()
            shop.currentPackOpening = { pack = { packType = "spectral" }, cards = { definition } }
            assert(Shop.choosePackCard(shop, 1, game))
        end
        if id == "spec_sigil" then
            assert(target.suit == game.hand[1].suit)
            assert(game.persistentDeck[1].suit == oldSuit, "untouched card changed")
        elseif id == "spec_ouija" then
            assert(target.baseRank == game.hand[1].rank and target.rank == target.baseRank)
            assert(target.baseChips == Deck.getChipValue(target.rank) + 15)
            assert(game.persistentDeck[1].rank == 2, "untouched card changed")
            assert(game.maxHandSize == oldSize - 1)
        elseif id == "spec_cryptid" then
            assert(#game.persistentDeck == 10)
            for i = 9, 10 do
                local copy = game.persistentDeck[i]
                assert(copy.id ~= target.id and copy.baseChips == target.baseChips)
                assert(copy.edition == target.edition and copy.evolutionLevel == target.evolutionLevel)
            end
            assert(game.persistentDeck[9].id ~= game.persistentDeck[10].id)
        elseif id == "spec_immolate" then
            assert(#game.persistentDeck == 6 and #game.hand == 0)
            assert(not contains(game.persistentDeck, target.id))
            assert(game.gold == oldGold + 20)
        elseif id == "spec_black_hole" then
            for _, hand in pairs(require("src.poker").HAND_TYPES) do assert(game.handLevels[hand.id] == 2) end
        else
            local count = Shop.getConsumableParams(definition).count
            assert(#game.persistentDeck == 8 - 1 + count and #game.hand == 1, id .. " counts: " .. #game.persistentDeck .. "/" .. #game.hand)
            for _, survivor in ipairs(game.hand) do assert(contains(game.persistentDeck, survivor.id)) end
            assert(contains(game.persistentDeck, firstId), "destroyed an unrelated master card")
            for i = #game.persistentDeck - count + 1, #game.persistentDeck do
                assert(#game.persistentDeck[i].equipments == 1)
            end
        end
        local expected = {}
        for _, card in ipairs(game.persistentDeck) do expected[#expected + 1] = Deck.cloneCard(card) end
        local expectedSouls=0
        for id,value in pairs(originalValues) do
            if not contains(game.persistentDeck,id) then expectedSouls=expectedSouls+value end
        end
        assert(game.souls==expectedSouls,"spectral destruction must award souls exactly once")
        local restored = assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(game, "shop")))
        assert(restored.souls==game.souls)
        assert(restored.maxHandSize == game.maxHandSize and restored.gold == game.gold)
        for key, level in pairs(game.handLevels) do assert(restored.handLevels[key] == level) end
        Combat.start(restored, Monster.create(1, false, false, 1), 2)
        assert(#restored.persistentDeck == #expected)
        for _, card in ipairs(expected) do
            assertSame(card, contains(restored.persistentDeck, card.id))
            assertSame(card, contains(restored.hand, card.id) or contains(restored.deck, card.id))
        end
    end
end
print("Spectral persistence smoke passed: all 8 cards, direct/stored use, save/load and next combat")

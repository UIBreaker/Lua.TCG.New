local CardEffects = require("src.card_effects")
local Deck = require("src.deck")
local Rng = require("src.rng")
local Scoring = require("src.scoring")
local Shop = require("src.shop")
local Deities = require("src.deities")

local function scoreCard(effectName)
    local card = Deck.newCard(4, "valoria")
    if effectName then assert(CardEffects.setEffect(card, effectName)) end
    local result = Scoring.calculate({
        type = { id = "high_card", name = "High Card", vnName = "Đơn Thủ", baseChips = 8, baseMult = 1 },
        chips = 8,
        mult = 1,
        level = 1,
        scoringCards = { card },
        unscoredCards = {},
    }, {}, {})
    return card, result
end

local plainCard, plain = scoreCard(nil)
local foilCard, foil = scoreCard("foil")
local holoCard, holo = scoreCard("holographic")
local polyCard, poly = scoreCard("polychrome")

assert(foil.totalChips == plain.totalChips, "Foil must not change Chips")
assert(foil.totalMult == plain.totalMult, "Foil must not change Mult")
assert(foil.flatDamageBonus == 50 and foil.finalScore == plain.finalScore + 50,
    "Foil should add exactly 50 flat damage after Aura multipliers")
assert(holo.totalMult == plain.totalMult + 10, "Holographic should add 10 Mult")
assert(poly.auraEditionMultiplier == 1.5, "Polychrome should multiply final Aura by 1.5")
assert(poly.finalScore == math.floor(plain.rawScore * (1 + plain.totalExtraDamagePct) * 1.5),
    "Polychrome should apply after the normal Aura calculation")
assert(Deck.cloneCard(foilCard).edition == "foil", "card editions must survive combat cloning")
assert(Deck.cloneCard(holoCard).edition == "holographic", "Holographic must survive combat cloning")
assert(Deck.cloneCard(polyCard).edition == "polychrome", "Polychrome must survive combat cloning")

local rareDeity = {}
for key, value in pairs(Deities.CATALOG.spirit_blade) do rareDeity[key] = value end
assert(Deities.setRarity(rareDeity, "rare"), "shop rarity should initialize an SPN tier")
assert(rareDeity.desc == "Mỗi lá tạo Aura nhận +16 Chips",
    "rare SPN description should show its actual tier-scaled value")
local rareEffect = Deities.scaleEffect(rareDeity, { addChips = 8, message = "+8 Chips" })
assert(rareEffect.addChips == 16 and rareEffect.message == "+16 Chips",
    "rare SPN scoring should scale by its rarity, not stay at Common strength")
local rareScore = Scoring.calculate({
    type = { id = "high_card", name = "High Card", vnName = "Đơn Thủ", baseChips = 8, baseMult = 1 },
    chips = 8, mult = 1, level = 1,
    scoringCards = { Deck.newCard(4, "valoria") },
    unscoredCards = {},
}, { rareDeity }, {})
local commonScore = Scoring.calculate({
    type = { id = "high_card", name = "High Card", vnName = "Đơn Thủ", baseChips = 8, baseMult = 1 },
    chips = 8, mult = 1, level = 1,
    scoringCards = { Deck.newCard(4, "valoria") },
    unscoredCards = {},
}, {}, {})
assert(rareScore.bonusChips == commonScore.bonusChips + 16,
    "rarity multiplier should apply inside the real scoring flow")
assert(Deities.evolve(rareDeity) and rareDeity.rarity == "epic"
    and rareDeity.desc == "Mỗi lá tạo Aura nhận +20 Chips",
    "evolving a rare SPN should retain rarity scaling and apply the next +50% base step")

local nonCardItem = { category = "equipment", card = Deck.newCard(8, "clubs") }
assert(CardEffects.rollShopItem(nonCardItem) == nil and nonCardItem.card.edition == nil,
    "shop edition rolls should affect card stock only")

Rng.seed(81723)
local rolledEffects = 0
for _ = 1, 2000 do
    local item = { category = "card", card = Deck.newCard(8, "clubs"), name = "8♣" }
    if CardEffects.rollShopItem(item) then rolledEffects = rolledEffects + 1 end
end
assert(rolledEffects > 190 and rolledEffects < 290,
    "small cumulative edition odds should occasionally affect rerolled card stock")

local deityStock = { category = "deity", deity = { id = "test_spn", name = "SPN" }, name = "SPN" }
assert(#Shop.STANDARD_CARDS == 52, "retail and chest pools must contain all 52 playing cards")
assert(#Shop.getPackContents("hand_styles") == 9, "the hand-style chest must contain all nine poker hands")
assert(#Shop.getPackContents("edition") == 3, "the edition chest must offer all three edition consumables")

local validSuit = { valoria = true, aurelia = true, elaris = true, vharos = true }
local seenCards = {}
for _ = 1, 450 do
    local opening = Shop.openPack({ packType = "standard" }, { selectedFaction = "aurelia" })
    assert(#opening.cards == 3, "playing-card chest should reveal three cards")
    for _, card in ipairs(opening.cards) do
        assert(card.rank >= 2 and card.rank <= 14 and validSuit[card.suit], "playing-card chest yielded an invalid rank or suit")
        seenCards[card.suit .. ":" .. card.rank] = true
    end
end
for suit in pairs(validSuit) do
    for rank = 2, 14 do
        assert(seenCards[suit .. ":" .. rank], "playing-card chest did not sample the full 52-card range")
    end
end

local shopState = { deities = {}, unlockedHands = {}, maxHandSize = 3, playerHp = 70, maxPlayerHp = 100 }
local shop = Shop.new()
local editionChestCount, spnEditionCount = 0, 0
Rng.seed(41027)
for _ = 1, 600 do
    Shop.refresh(shop, shopState)
    local upperCount, handChestSeen, randomChests = 0, false, 0
    local upperCategories, randomPackTypes = {}, {}
    local voucherSeen, bookTicketSeen = false, false
    local spnItem
    for _, item in ipairs(shop.items) do
        if item.section == "upper" then
            upperCount = upperCount + 1
            upperCategories[item.category] = true
        end
        if item.section == "lower_voucher" then
            voucherSeen = item.category == "voucher"
        end
        if item.category == "book" then bookTicketSeen = true end
        if item.category == "heal" then
            assert(item.section == "upper", "healing potion must only appear in the upper row")
        end
        if item.category == "deity" then
            spnItem = item
            if item.deity.edition then spnEditionCount = spnEditionCount + 1 end
        end
        if item.packType == "hand_styles" then handChestSeen = true end
        if item.category == "pack" and item.packType ~= "hand_styles" and item.packType ~= "edition" then
            randomChests = randomChests + 1
            assert(not randomPackTypes[item.packType], "random chests should be unique within one shop")
            randomPackTypes[item.packType] = true
        end
        if item.packType == "edition" then editionChestCount = editionChestCount + 1 end
    end
    assert(upperCount == 5, "upper shop must stock SPN, ITM, one card, hand expansion, and potion")
    assert(upperCategories.deity and upperCategories.equipment and upperCategories.card
        and upperCategories.hand_expansion and upperCategories.heal,
        "upper retail row is missing a requested shop category")
    assert(voucherSeen and not bookTicketSeen,
        "lower voucher slot should contain a permanent voucher, not a hand-style ticket")
    assert(handChestSeen and randomChests == 3, "lower shop must stock the hand-style chest and three random chests")
    local rarityMultiplier = spnItem and Shop.SPN_RARITY_PRICE_MULTIPLIERS[spnItem.deity.rarity]
    local expectedSpnPrice = spnItem and math.ceil(Deities.CATALOG[spnItem.deity.id].cost * rarityMultiplier)
    assert(spnItem and spnItem.cost == expectedSpnPrice,
        "SPN stock must retain its rarity-scaled shop price")
end
assert(editionChestCount > 110 and editionChestCount < 190, "edition chest should appear at approximately 25% per refresh")
assert(spnEditionCount > 35, "SPN shop stock must receive Foil/Holographic/Polychrome rolls")

local styleOpening = Shop.openPack({ packType = "hand_styles" }, shopState)
assert(#styleOpening.cards == 3, "hand-style chest should offer three hand types at once")
local styleIds = {}
for _, book in ipairs(styleOpening.cards) do
    assert(not styleIds[book.handId], "hand-style chest choices should be distinct")
    styleIds[book.handId] = true
end
local editionOpening = Shop.openPack({ packType = "edition" }, shopState)
assert(#editionOpening.cards == 3 and editionOpening.cards[1].category == "edition",
    "edition chest should reveal consumables that apply the selected effect")

local target = Deck.newCard(7, "clubs")
local persistentTarget = Deck.cloneCard(target)
local editionPackShop = { currentPackOpening = editionOpening }
shopState.hand = { target }
shopState.selectedIndices = { 1 }
shopState.persistentDeck = { persistentTarget }
shopState.deck, shopState.discardPile = {}, {}
local applied = Shop.choosePackCard(editionPackShop, 1, shopState)
assert(applied and target.edition == "foil" and persistentTarget.edition == "foil",
    "choosing an edition must update the selected card and its saved deck copy")
editionPackShop.currentPackOpening = editionOpening
shopState.consumables = {}
assert(Shop.keepPackCard(editionPackShop, 2, shopState) and shopState.consumables[1].category == "edition",
    "edition chest rewards must be storable as targeted consumables")

print("Card effects smoke test passed")

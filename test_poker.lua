-- Standalone unit test for poker hand recognition and scoring formula
local Deck = require("src.deck")
local Poker = require("src.poker")
local Deities = require("src.deities")
local Scoring = require("src.scoring")

local logFile = io.open("test_result.txt", "w")
local function printLog(...)
    local args = {...}
    local str = table.concat(args, " ")
    print(str)
    if logFile then logFile:write(str .. "\n") end
end

printLog("=== RUNNING POKER & SCORING TESTS ===")

-- Helper to make a card
local function C(rank, suit)
    return Deck.newCard(rank, suit)
end

-- Test 1: High Card
local h1 = Poker.evaluate({ C(14, "hearts"), C(10, "spades"), C(8, "clubs"), C(4, "diamonds"), C(2, "hearts") })
assert(h1.type.id == "high_card", "Expected high_card, got " .. h1.type.id)
assert(h1.type.baseChips == 5 and h1.type.baseMult == 1)
assert(#h1.scoringCards == 1 and h1.scoringCards[1].rank == 14)
printLog(" Test 1 Passed: High Card")

-- Test 2: Pair
local h2 = Poker.evaluate({ C(9, "hearts"), C(9, "spades"), C(4, "clubs"), C(3, "diamonds") })
assert(h2.type.id == "pair", "Expected pair, got " .. h2.type.id)
assert(h2.type.baseChips == 10 and h2.type.baseMult == 2)
assert(#h2.scoringCards == 2)
printLog(" Test 2 Passed: Pair")

-- Test 3: Two Pair
local h3 = Poker.evaluate({ C(12, "hearts"), C(12, "diamonds"), C(4, "clubs"), C(4, "spades"), C(2, "hearts") })
assert(h3.type.id == "two_pair", "Expected two_pair, got " .. h3.type.id)
assert(h3.type.baseChips == 20 and h3.type.baseMult == 2)
assert(#h3.scoringCards == 4)
printLog(" Test 3 Passed: Two Pair")

-- Test 4: Three of a Kind
local h4 = Poker.evaluate({ C(7, "hearts"), C(7, "diamonds"), C(7, "clubs"), C(3, "spades") })
assert(h4.type.id == "three_of_a_kind", "Expected three_of_a_kind, got " .. h4.type.id)
assert(h4.type.baseChips == 30 and h4.type.baseMult == 3)
assert(#h4.scoringCards == 3)
printLog(" Test 4 Passed: Three of a Kind")

-- Test 5: Straight (Ace high: 10, J, Q, K, A)
local h5 = Poker.evaluate({ C(14, "hearts"), C(13, "diamonds"), C(12, "clubs"), C(11, "spades"), C(10, "hearts") })
assert(h5.type.id == "straight", "Expected straight, got " .. h5.type.id)
assert(h5.type.baseChips == 30 and h5.type.baseMult == 4)
assert(#h5.scoringCards == 5)
printLog(" Test 5 Passed: Straight (Ace High)")

-- Test 6: Straight (Ace low: A, 2, 3, 4, 5)
local h6 = Poker.evaluate({ C(14, "hearts"), C(5, "diamonds"), C(4, "clubs"), C(3, "spades"), C(2, "hearts") })
assert(h6.type.id == "straight", "Expected straight, got " .. h6.type.id)
assert(h6.type.baseChips == 30 and h6.type.baseMult == 4)
assert(#h6.scoringCards == 5)
printLog(" Test 6 Passed: Straight (Ace Low)")

-- Test 7: Flush
local h7 = Poker.evaluate({ C(14, "hearts"), C(10, "hearts"), C(8, "hearts"), C(6, "hearts"), C(2, "hearts") })
assert(h7.type.id == "flush", "Expected flush, got " .. h7.type.id)
assert(h7.type.baseChips == 35 and h7.type.baseMult == 4)
assert(#h7.scoringCards == 5)
printLog(" Test 7 Passed: Flush")

-- Test 8: Full House
local h8 = Poker.evaluate({ C(10, "hearts"), C(10, "diamonds"), C(10, "clubs"), C(5, "spades"), C(5, "hearts") })
assert(h8.type.id == "full_house", "Expected full_house, got " .. h8.type.id)
assert(h8.type.baseChips == 40 and h8.type.baseMult == 4)
assert(#h8.scoringCards == 5)
printLog(" Test 8 Passed: Full House")

-- Test 9: Four of a Kind
local h9 = Poker.evaluate({ C(8, "hearts"), C(8, "diamonds"), C(8, "clubs"), C(8, "spades"), C(2, "hearts") })
assert(h9.type.id == "four_of_a_kind", "Expected four_of_a_kind, got " .. h9.type.id)
assert(h9.type.baseChips == 60 and h9.type.baseMult == 7)
assert(#h9.scoringCards == 4)
printLog(" Test 9 Passed: Four of a Kind")

-- Test 10: Straight Flush
local h10 = Poker.evaluate({ C(9, "spades"), C(8, "spades"), C(7, "spades"), C(6, "spades"), C(5, "spades") })
assert(h10.type.id == "straight_flush", "Expected straight_flush, got " .. h10.type.id)
assert(h10.type.baseChips == 100 and h10.type.baseMult == 8)
assert(#h10.scoringCards == 5)
printLog(" Test 10 Passed: Straight Flush")

-- Test 11: Scoring Formula with Deities
-- Formula: (Base Chips + Bonus Chips) * (Base Mult + Bonus Mult) * XMult
local testHand = Poker.evaluate({ C(9, "hearts"), C(9, "spades") })
local testDeities = {
    Deities.CATALOG.spirit_pebble, -- +20 Chips
    Deities.CATALOG.spirit_ember,  -- +4 Mult
    Deities.CATALOG.spirit_blade,  -- +8 Chips per scored card (2 * 8 = +16 Chips)
    Deities.CATALOG.spirit_pair,   -- +6 Mult for Pair
}
local calc = Scoring.calculate(testHand, testDeities, { handsRemaining = 3 })
printLog("Scoring calculation result: " .. calc.totalChips .. " Chips x " .. calc.totalMult .. " Mult x " .. calc.xMultTotal .. " XMult = " .. calc.finalScore)
-- Base Pair: 10 Chips, 2 Mult. Cards: 9 + 9 = 18 Chips. Vharos Spades faction: +40 Chips.
-- Total Chips: 10 + 18 + 40 + 20 + 16 = 104 Chips.
-- Total Mult: 2 + 4 + 6 = 12 Mult.
-- Final Score: 104 * 12 = 1248.
assert(calc.totalChips == 104, "Expected 104 chips, got " .. calc.totalChips)
assert(calc.totalMult == 12, "Expected 12 mult, got " .. calc.totalMult)
assert(calc.finalScore == 1248, "Expected 1248 final score, got " .. calc.finalScore)
printLog(" Test 11 Passed: Scoring Formula & Deities Integration")

printLog("=== ALL 11 TESTS PASSED SUCCESSFULLY! ===")
if logFile then logFile:close() end
if love and love.audio then love.audio.stop() end
if love and love.event then love.event.quit(0) end

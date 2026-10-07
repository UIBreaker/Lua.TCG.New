local Deck = require("src.deck")
local Poker = require("src.poker")
local Deities = require("src.deities")
local Scoring = require("src.scoring")
local Monster = require("src.monster")
local Equipment = require("src.equipment")
local RunManager = require("src.run_manager")

print("=== RUNNING ADVANCED FEATURES TEST ===")

-- Test 1: Mono-suit deck
local monoDeck = Deck.createMonoSuitDeck("hearts")
assert(#monoDeck == 52, "Expected 52 cards in mono-suit deck, got " .. #monoDeck)
for _, c in ipairs(monoDeck) do
    assert(c.suit == "valoria", "Hearts alias must canonicalize to valoria, got " .. c.suit)
end
print(" Test 1 Passed: Mono-Suit Deck (52 cards all Hearts)")

-- Test 2: Monster and Boss stage logic
local m1 = Monster.create(1)
assert(m1.isBoss == false, "Round 1 should be normal monster")
assert(m1.hp == 21, "Encounter 1 HP should be 21")

local m3 = Monster.create(3)
assert(m3.isBoss == false, "Round 3 should be normal monster")

local m4 = Monster.create(4, true, false, 4)
assert(m4.isBoss == true, "Round 4 should be BOSS")
assert(m4.hp == 142, "Encounter 4 Boss HP should be 142")

local m8 = Monster.create(8, true, false, 8)
assert(m8.isBoss == true, "Round 8 should be BOSS 2")
assert(m8.hp > m4.hp, "Later boss encounters must scale above earlier bosses")
print(" Test 2 Passed: Explicit normal/boss encounters and HP scaling")

-- Test 3: Card Equipment attachment (3 slots, no duplicates)
local card = Deck.newCard(14, "hearts")
assert(#card.equipments == 0)
assert(Equipment.attach(card, Equipment.ITEMS.gem_fire) == true)
assert(Equipment.attach(card, Equipment.ITEMS.gem_blast) == true)
assert(Equipment.attach(card, Equipment.ITEMS.ward_stone) == true)
assert(Equipment.attach(card, Equipment.ITEMS.lucky_coin) == false, "Fourth slot should be rejected")
assert(Equipment.attach(card, Equipment.ITEMS.gem_fire) == false, "Duplicate equipment should be rejected")
print(" Test 3 Passed: 3 Equipment Slots and Duplicate Guard")

-- Test 4: Scoring with Equipment
-- Two-card pair: outer Fire Gem gives +30 Chips; Blast Gem gives +4 Mult.
local baseC1 = Deck.newCard(10, "hearts")
local baseC2 = Deck.newCard(10, "hearts")
local basePair = Poker.evaluate({ baseC1, baseC2 })
local baseCalc = Scoring.calculate(basePair, {}, {})

local c1 = Deck.newCard(10, "hearts")
Equipment.attach(c1, Equipment.ITEMS.gem_fire)

local c2 = Deck.newCard(10, "hearts")
Equipment.attach(c2, Equipment.ITEMS.gem_blast)
Equipment.attach(c2, Equipment.ITEMS.lucky_coin)

local pairHand = Poker.evaluate({ c1, c2 })
local calc = Scoring.calculate(pairHand, {}, {})
assert(calc.totalChips == baseCalc.totalChips + 30, "Fire Gem must add exactly 30 chips")
assert(calc.totalMult == baseCalc.totalMult + 4, "Blast Gem must add exactly 4 mult")
assert(calc.finalScore > baseCalc.finalScore, "Equipment must increase final score")
assert(calc.bonusGoldAwarded == 0, "Lucky Coin only triggers on an Ace")
print(" Test 4 Passed: Equipment Chips, Mult, and Gold Integration")

-- Test 5: Adjacent Mirror equipment
-- cA (9), cB (9 with mirror), cC (9)
-- cB should buff two adjacent cards of different suits (+12 each).
local ca = Deck.newCard(9, "hearts")
local cb = Deck.newCard(9, "spades")
Equipment.attach(cb, Equipment.ITEMS.mirror_adjacent)
local cc = Deck.newCard(9, "clubs")

local mirrorBuffs = Equipment.ITEMS.mirror_adjacent.onHandEvaluate(cb, { ca, cb, cc }, 2)
assert(mirrorBuffs[1].addChips == 12 and mirrorBuffs[3].addChips == 12, "Adjacent mirror must add exactly 24 chips")
print(" Test 5 Passed: Spillover Mirror Adjacent Buff")

-- Test 6: SPN evolution rarity, concrete stats, round reward choice, and attack speed
local evolvingGame = { deities = {} }
assert(Deities.addDeity(evolvingGame, Deities.CATALOG.spirit_drum))
local evolvingDeity = evolvingGame.deities[1]
local raritySteps = { "UC", "R", "E", "L", "M", "T", "UQ", "UQ+1" }
for _, expectedBadge in ipairs(raritySteps) do
    local ok, badge = Deities.evolve(evolvingDeity)
    assert(ok and badge == expectedBadge, "Expected evolved rarity " .. expectedBadge .. ", got " .. tostring(badge))
end
local scaledEffect = Deities.scaleEffect(evolvingDeity, { addMult = 1, message = "+1 Mult" })
assert(scaledEffect.addMult == 5, "UQ+1 evolution must apply +50% of base power per evolution")
assert(evolvingDeity.desc:find("+5 Mult", 1, true), "Evolved SPN description should show its concrete current stat")
assert(not evolvingDeity.desc:find("×", 1, true), "Evolved SPN description should not show a multiplier")
local scoringGame = { deities = {} }
assert(Deities.addDeity(scoringGame, Deities.CATALOG.spirit_drum))
local scoringDeity = scoringGame.deities[1]
local testHand = Poker.evaluate({ Deck.newCard(2, "hearts") })
local baseSpnScore = Scoring.calculate(testHand, scoringGame.deities, {})
assert(Deities.evolve(scoringDeity))
local evolvedSpnScore = Scoring.calculate(testHand, scoringGame.deities, {})
assert(evolvedSpnScore.totalMult == baseSpnScore.totalMult + 0.5,
    "One SPN evolution must increase its original +1 Mult effect by 50%")

local rewardRun = RunManager.newRun()
rewardRun.ante = 4
rewardRun.currentBlindIndex = 3
rewardRun.blinds = RunManager.generateAnteBlinds(4, "aurelia")
local rewardGame = { consumables = {} }
assert(RunManager.completeCurrentBlind(rewardRun, rewardGame), "Completing Ante 4 boss should open the reward choice")
assert(rewardGame.pendingRoundRewardChoice and #rewardGame.pendingRoundRewardChoice.options == 3,
    "Ante 4 reward must offer Evolution, single speed, and team speed")
assert(RunManager.chooseRoundReward(rewardGame, 2), "Player should be able to choose the single-card speed reward")
assert(#rewardGame.consumables == 1 and rewardGame.consumables[1].category == "speed_single",
    "Chosen speed reward should enter the consumable inventory")

local normalRun = RunManager.newRun()
normalRun.stats.blindsWon = 3
local normalGame = { consumables = {} }
assert(not RunManager.completeCurrentBlind(normalRun, normalGame), "The fourth blind win inside an ante must not trigger a round reward")

local fullRewardRun = RunManager.newRun()
fullRewardRun.ante = 4
fullRewardRun.currentBlindIndex = 3
fullRewardRun.blinds = RunManager.generateAnteBlinds(4, "aurelia")
local fullRewardGame = { consumables = { {}, {}, {} } }
RunManager.completeCurrentBlind(fullRewardRun, fullRewardGame)
assert(RunManager.chooseRoundReward(fullRewardGame, 1), "Player should be able to choose evolution even with full slots")
assert(#fullRewardGame.consumables == 3 and #fullRewardGame.pendingRewardCards == 1,
    "Chosen reward must queue safely when all consumable slots are full")
table.remove(fullRewardGame.consumables, 1)
RunManager.deliverEvolutionRewards(fullRewardRun, fullRewardGame)
assert(#fullRewardGame.consumables == 3 and #fullRewardGame.pendingRewardCards == 0,
    "Queued round reward should enter the first free consumable slot")

local speedCard = Deck.newCard(2, "hearts")
assert(Deck.applyAttackSpeedBonus(speedCard, 5) == 17, "Rank 2 base speed 12 plus potion 5")
local speedClone = Deck.cloneCard(speedCard)
assert(Deck.getCardAttackSpeed(speedClone) == 17, "Attack speed bonus should copy into combat cards")
Deck.restoreDeck({ speedCard })
assert(Deck.getCardAttackSpeed(speedCard) == 17, "Attack speed bonus should survive combat deck restoration")
assert(Deck.applyAttackSpeedBonus(speedCard, 2000) == 999, "Card attack speed must cap at 999")
assert(Monster.rollAttackSpeed(10000) <= 999, "Monster attack speed must also cap at 999")
print(" Test 6 Passed: Concrete SPN Stats, Ante 4 Reward Choice, and Attack Speed Range")

print("=== ALL 6 ADVANCED TESTS PASSED! ===")
love.filesystem.write("adv_test_result.txt", "ALL_PASSED")
if love and love.audio then love.audio.stop() end
if love and love.event then love.event.quit(0) end

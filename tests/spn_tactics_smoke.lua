local D = require("src.deities")
local Scoring = require("src.scoring")
local Deck = require("src.deck")
local Poker = require("src.poker")
local Persistence = require("src.persistence")
local GameState = require("src.game_state")
local Combat = require("src.combat")
local Monster = require("src.monster")
local Rng = require("src.rng")
local function card(rank, suit, equipped)
    local c = Deck.newCard(rank, suit or "hearts")
    c.disableFactionPassives = true
    c.equipments = equipped and {{id="test_socket"}} or {}
    return c
end
local function hand(scoring, unscored, kind)
    return {type=Poker.HAND_TYPES[kind or "HIGH_CARD"], scoringCards=scoring, unscoredCards=unscored or {}}
end
local function effect(id, h, game)
    local d = D.CATALOG[id]
    return d.onHandScored(h, {gameState=game or {}})
end
local solo = hand({card(3)})
assert(effect("spirit_lone",solo).xMult == 1.8)
assert(not effect("spirit_lone",hand({card(3)}, {card(5)})))
assert(effect("spirit_confluence",hand({card(2,"hearts"),card(3,"clubs"),card(4,"spades")})).addMult == 9)
assert(not effect("spirit_confluence",hand({card(2,"hearts"),card(3,"valoria"),card(4,"clubs")})))
assert(effect("spirit_rearguard",hand({card(5)}, {card(2),card(3)})).addArmor == 8)
assert(not effect("spirit_rearguard",solo))
assert(effect("spirit_wound",solo,{playerHp=10,maxPlayerHp=100}).addChips == 60)
assert(not effect("spirit_wound",solo,{playerHp=100,maxPlayerHp=100}))
assert(effect("spirit_bastion",solo,{playerArmor=100}).xMult == 1.6)
assert(not effect("spirit_bastion",solo,{playerArmor=0}))
assert(effect("spirit_stillness",solo,{discardsRemaining=3}).addChips == 24)
assert(not effect("spirit_stillness",solo,{discardsRemaining=3,discardsUsedInCombat=1}))
assert(effect("spirit_molt",solo,{discardsUsedInCombat=8}).addMult == 6)
assert(not effect("spirit_molt",solo))
assert(effect("spirit_pivot",solo,{abilityCombat={previousHandType="pair"}}).xMult == 1.4)
assert(not effect("spirit_pivot",solo,{abilityCombat={previousHandType="high_card"}}))
assert(not effect("spirit_pivot",solo))
local equipped = hand({card(3,"hearts",true),card(3,"clubs",true)}, {}, "PAIR")
assert(effect("spirit_mender",equipped).addHealHp == 4)
assert(not effect("spirit_mender",hand({card(3,"hearts",true),card(3)})))
assert(effect("spirit_gleaner",hand({card(5)}, {card(7)})).addGold == 1)
assert(not effect("spirit_gleaner",hand({card(6)}, {card(7)})))
assert(not effect("spirit_gleaner",hand({card(11)})))

local game = GameState.new()
game.playerHp, game.playerArmor = 40, 20
game.discardsRemaining, game.discardsUsedInCombat = 2, 1
game.abilityCombat = {previousHandType="high_card"}
local cases = {
    {"spirit_lone",solo,"xMult",1.8},
    {"spirit_confluence",hand({card(2,"hearts"),card(3,"clubs"),card(4,"spades")}),"addMult",9},
    {"spirit_rearguard",hand({card(5)}, {card(2),card(3)}),"addArmor",8},
    {"spirit_wound",solo,"addChips",60},
    {"spirit_bastion",solo,"xMult",1.4},
    {"spirit_stillness",solo,"addChips",16},
    {"spirit_molt",solo,"addMult",2},
    {"spirit_pivot",equipped,"xMult",1.4},
    {"spirit_mender",equipped,"healHp",4},
    {"spirit_gleaner",solo,"bonusGold",1},
}
for _, case in ipairs(cases) do
    local id,h,key,value = table.unpack(case)
    game.discardsUsedInCombat = id == "spirit_stillness" and 0 or 1
    local owned = {deities={}}
    assert(D.addDeity(owned,D.CATALOG[id],5))
    local d = owned.deities[5]
    local state, gold, hp, armor = Rng.getState(), game.gold, game.playerHp, game.playerArmor
    local preview = Scoring.calculate(h,owned.deities,{preview=true,gameState=game})
    local actual = Scoring.calculate(h,owned.deities,{gameState=game})
    assert(preview.finalScore == actual.finalScore and preview.healHp == actual.healHp and preview.addArmor == actual.addArmor)
    assert(state == Rng.getState() and game.gold == gold and game.playerHp == hp and game.playerArmor == armor)
    local trigger
    for _,step in ipairs(actual.steps) do if step.type=="deity_hand" then trigger=step end end
    local stepKey = key == "addChips" and "addedChips" or key == "addMult" and "addedMult" or key
    assert(trigger and math.abs(trigger[stepKey]-value)<0.00001,id .. " scoring integration")
    assert(D.evolve(d))
    local scaled = D.scaleEffect(d,d.onHandScored(h,{gameState=game}))
    local effectKey = key == "healHp" and "addHealHp" or key == "bonusGold" and "addGold" or key
    local expected = key == "xMult" and 1+(value-1)*1.5 or value*1.5
    assert(math.abs(scaled[effectKey]-expected)<0.00001,id .. " evolution")
    assert(not D.getDescription(d):find("{",1,true))
    game.deities = owned.deities
    local restored = assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(game,"shop")))
    assert(restored.deities[5].id == id and restored.deities[5].onHandScored)
    assert(D.getDescription(restored.deities[5]) == D.getDescription(d))
end
-- Locked SPNs contribute neither score nor survival/economy in previews or play.
game.monster={isBoss=true,hp=100,maxHp=100,bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=5,untilHand=1}}}
game.deities={[5]=D.CATALOG.spirit_gleaner}
for _,preview in ipairs({true,false}) do
    local result=Scoring.calculate(solo,game.deities,{preview=preview,gameState=game,monster=game.monster})
    for _,step in ipairs(result.steps) do assert(step.type~="deity_hand") end
end
game.monster=nil
game.deities={}
-- The HUD now passes gameState to previews; a King must not spend real gold.
game.gold=20
local king=hand({Deck.newCard(13,"diamonds")})
local bribeMonster={hp=100000,maxHp=100000}
local preview=Scoring.calculate(king,{}, {preview=true,gameState=game,monster=bribeMonster})
assert(game.gold==20 and preview.bribeDollarsSpent>0)
local actual=Scoring.calculate(king,{}, {gameState=game,monster=bribeMonster})
assert(actual.finalScore==preview.finalScore and game.gold==20-actual.bribeDollarsSpent)
Combat.start(game,Monster.create(1,false,false,1),1)
assert(not effect("spirit_molt",solo,game) and not effect("spirit_pivot",solo,game))
assert(#D.getRandomShopPool({},50)==32)
print("SPN tactics: all 10 conditions, caps, scoring, preview safety, evolution, sparse slots, boss locks, persistence and battle reset passed")

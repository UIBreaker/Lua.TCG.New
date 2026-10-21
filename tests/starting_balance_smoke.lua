local Deck=require("src.deck")
local Game=require("src.game_state")
local Combat=require("src.combat")
local Monster=require("src.monster")
local Run=require("src.run_manager")
local Rng=require("src.rng")
local P=require("src.persistence")
local seen={}
for seed=1,200 do
    Rng.seed(seed)
    local game=Game.new("red_deck")
    game.persistentDeck=Deck.createStarterDeck("red_deck")
    assert(#game.persistentDeck==5 and game.maxHandSize==3)
    local suits,identities,ids={},{},{}
    for _,card in ipairs(game.persistentDeck) do
        local identity=card.suit..":"..card.rank
        assert(card.rank>=2 and card.rank<=14 and not identities[identity] and not ids[card.id])
        assert(card.starterDeckId=="red_deck" and card.disableFactionPassives)
        assert(not card.isWildSuit and not card.isDualRankAce)
        identities[identity]=true;ids[card.id]=true;suits[card.suit]=true;seen[identity]=true
    end
    for _,suit in ipairs(Deck.FACTION_ORDER) do assert(suits[suit]) end
    game.run=Run.newRun("red_deck")
    local blind=Run.getCurrentBlind(game.run)
    assert(blind.hp==50 and Monster.getHpByEncounter(1)==50)
    Combat.start(game,Run.createBlindMonster(blind,game),1)
    assert(#game.hand==3 and #game.deck==2 and #game.persistentDeck==5)
    assert(#game.enemies==1 and game.monster.hp==50 and game.monster.maxHp==50)
    if seed==1 then
        local restored=P.restoreSnapshot(P.makeSnapshot(game,"playing"))
        assert(#restored.persistentDeck==5 and restored.maxHandSize==3)
        local savedIds={};for _,card in ipairs(restored.persistentDeck) do assert(ids[card.id]);savedIds[card.id]=true end
        for id in pairs(ids) do assert(savedIds[id]) end
    end
end
local count=0;for _ in pairs(seen) do count=count+1 end
assert(count==52,"every printed card remains reachable across seeded starts")
assert(Monster.getHpByEncounter(2)==100 and Monster.getHpByEncounter(3)==150)
assert(Run.calculateBlindHp(2,"small")==75)
assert(Run.calculateBlindHp(1,"big")==100 and Run.calculateBlindHp(1,"boss")==150)
print("Starting balance PASS: 200 random five-card decks, all four suits/52 identities, no duplicates, three drawn/two reserved, actual 50 HP first enemy, save ownership")

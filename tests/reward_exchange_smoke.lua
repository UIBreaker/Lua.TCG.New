local Shop=require("src.shop")
local G=require("src.game_state")
local Reward=require("src.reward_system")
local P=require("src.persistence")
local Rng=require("src.rng")
for _,pack in ipairs(Shop.PACK_CATALOG) do
    local game=G.new();game.gold=100-pack.cost
    local shop=Shop.new();local opening=Shop.openPack(pack,game)
    shop.currentPackOpening=opening
    local expected=math.max(1,math.floor(pack.cost/2))
    assert(Shop.getPackExchangeGold(opening)==expected)
    local before=game.gold;local rng=Rng.getState()
    local ok,gold=Shop.skipPack(shop,game)
    assert(ok and gold==expected and game.gold==before+expected and not shop.currentPackOpening)
    assert(Rng.getState()==rng, "exchange cannot reroll candidates")
    assert(not Shop.skipPack(shop,game))
    shop.currentPackOpening=opening
    local _,again=Shop.skipPack(shop,game)
    assert(again==0 and game.gold==before+expected, "opening receipt prevents repeated gold")

    local free=G.new();free.gold=7
    local reward=Shop.openPack({packType=pack.packType,cost=0,rewardPack=true},free)
    free.rewardPacks={reward}
    local resumed=P.restoreSnapshot(P.makeSnapshot(free,"shop"))
    shop=Shop.new();assert(Reward.openNextPack(resumed,shop))
    local savedOpening=shop.currentPackOpening
    assert(Shop.skipPack(shop,resumed) and resumed.gold==7+expected)
    assert(Reward.completePack(resumed,shop,savedOpening) and #resumed.rewardPacks==0)
    assert(not Reward.completePack(resumed,shop,savedOpening))
    local saved=P.restoreSnapshot(P.makeSnapshot(resumed,"BLIND_SELECT"))
    assert(saved.gold==7+expected and #saved.rewardPacks==0)
end
assert(Shop.getPackExchangeGold({pack={packType="arcana",cost=3}})==1)
assert(Shop.getPackExchangeGold({pack={packType="arcana",cost=0}})==1)
local rewards={{card={}},{item={cost=12}},{item={cost=8}}}
local game={gold=9};assert(Shop.getChestExchangeGold(rewards)==6)
assert(Shop.exchangeChest(rewards,game) and game.gold==15)
assert(not Shop.exchangeChest(rewards,game) and game.gold==15)
assert(not Shop.exchangeChest({},game))
assert(not Shop.exchangeChest({resolved=true,{card={}}},game))
print("Reward exchange passed: all pack types, paid/free/discounted, queue, save/reload, one payout, no reroll, legacy chests")

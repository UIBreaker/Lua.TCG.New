local Reward=require("src.reward_system")
local Shop=require("src.shop")
local Deck=require("src.deck")
local Run=require("src.run_manager")
local P=require("src.persistence")
local Rng=require("src.rng")
local C=Reward.config
local originalChest=C.tables.golden_chest
C.tables.golden_chest={rolls={2,2},entries={{id="itm_pack",weight=1}}}
local function stripReceipts(value)
    if type(value)~="table" then return end
    value.receipt=nil;value.victoryRewardReceipt=nil
    for _,child in pairs(value) do stripReceipts(child) end
end
for _,id in ipairs({"playing_card","healing_potion","card_pack","rare_reward"}) do
    for _,legacy in ipairs({false,true}) do
        Rng.seed(17)
        local owned=Deck.newCard(5,"hearts")
        local potion=Shop.healingItem(nil,"healing_potion").consumable
        local oldPack=Shop.openPack({packType=id=="rare_reward" and "arcana" or "standard",rewardPack=true,cost=0},{deities={}})
        local game={gold=20,souls=8,handsRemaining=2,deities={},selectedFaction="aurelia",run=Run.newRun("aurelia"),
            persistentDeck={owned},consumables={potion},backpackConsumables={potion},rewardPacks={oldPack}}
        C.tables.bulk_test={rolls={3,3},entries={{id=id,weight=1}}}
        local result=Reward.begin(Reward.calculate({type="small",baseReward=3},game),game,{lootTableId="bulk_test"})
        local expected=id=="rare_reward" and 12 or 6
        assert(Reward.getBulkExchangeGold(game,result)==expected,id.." got "..Reward.getBulkExchangeGold(game,result))
        local snapshot=P.makeSnapshot(game,"CASH_OUT")
        if legacy then stripReceipts(snapshot) end
        local resumed,state=P.restoreSnapshot(assert(P.decode(P.encode(snapshot))))
        assert(state=="CASH_OUT")
        local savedResult=resumed.pendingVictoryReward
        assert(Reward.getBulkExchangeGold(resumed,savedResult)==expected)
        local before=resumed.gold;local souls=resumed.souls;local rng=Rng.getState()
        local earned=savedResult.earnedGold
        local ok,gold=Reward.exchangeAll(resumed,savedResult)
        assert(ok and gold==expected and resumed.gold==before+expected)
        assert(savedResult.earnedGold==earned+expected and savedResult.exchangeGold==expected)
        assert(resumed.souls==souls and Rng.getState()==rng)
        assert(#resumed.persistentDeck==1 and resumed.persistentDeck[1].id==owned.id)
        assert(#resumed.consumables==1 and #resumed.backpackConsumables==1)
        assert(#resumed.rewardPacks==1 and resumed.rewardPacks[1].pack.packType==oldPack.pack.packType)
        assert(Reward.getBulkExchangeGold(resumed,savedResult)==0 and not Reward.exchangeAll(resumed,savedResult))
        assert(not Reward.exchangeAll(resumed,result), "old result reference cannot convert inventory")
        local again=P.restoreSnapshot(P.makeSnapshot(resumed,"CASH_OUT"))
        assert(again.gold==before+expected and not Reward.exchangeAll(again,again.pendingVictoryReward))
        local anim=Reward.newAnimation(again.pendingVictoryReward.breakdown,again.pendingVictoryReward)
        Reward.finishImmediately(anim)
        assert(anim.walletTotal==again.gold and anim.displayTotal==earned+expected)
    end
end
C.tables.golden_chest=originalChest
-- Missing granted items must never sell older items with an identical ID.
local potion=Shop.healingItem(nil,"healing_potion").consumable
local game={gold=10,backpackConsumables={potion}}
game.pendingVictoryReward={earnedGold=5,loot={{type="CONSUMABLE",card=potion,receipt="missing"}}}
assert(Reward.getBulkExchangeGold(game,game.pendingVictoryReward)==0)
assert(not Reward.exchangeAll(game,game.pendingVictoryReward) and #game.backpackConsumables==1 and game.gold==10)
print("Bulk reward exchange passed: cards, consumables, packs, nested chests, all pages, existing inventory, legacy/current saves, no double gold, no soul/RNG changes")

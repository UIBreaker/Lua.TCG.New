local Void=require("src.void_gacha")
local Reward=require("src.reward_system")
local Game=require("src.game_state")
local Run=require("src.run_manager")
local P=require("src.persistence")
local Rng=require("src.rng")
local original=Rng.random
for amount=1,100 do
    Rng.random=function(a,b)
        if not a then return .999 end
        assert(a==1 and b==100,"boss ticket quantity must use the full inclusive range")
        return amount
    end
    local ticket=assert(Void.ticketReward(true),"every boss must grant tickets")
    assert(ticket.amount==amount and ticket.name=="+"..amount.." VÉ THE VOID")
    assert(not Void.ticketReward(false),"ordinary encounters still use their drop chance")
end
Reward.config.tables.boss_ticket_test={rolls={1,1},entries={{id="playing_card",weight=1}}}
for _,amount in ipairs({1,47,100}) do
    Rng.random=function(a,b)
        if not a then return .999 end
        if a==1 and b==100 then return amount end
        return b and a or 1
    end
    local game=Game.new();game.run=Run.newRun();game.voidTickets=9
    local breakdown=Reward.calculate({type="boss",baseReward=5},game)
    local result=Reward.begin(breakdown,game,{lootTableId="boss_ticket_test"})
    local count=0
    for _,reward in ipairs(result.loot) do
        if reward.type=="VOID_TICKET" then count=count+1;assert(reward.amount==amount) end
    end
    assert(count==1 and game.voidTickets==9+amount)
    assert(Reward.begin(breakdown,game)==result and game.voidTickets==9+amount)
    local restored,state=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(game,"CASH_OUT")))))
    assert(state=="CASH_OUT" and restored.voidTickets==9+amount)
    local saved=restored.pendingVictoryReward
    assert(Reward.begin(breakdown,restored)==saved and restored.voidTickets==9+amount)
    local anim=Reward.newAnimation(saved.breakdown,saved)
    Reward.update(anim,20);Reward.finishImmediately(anim)
    assert(anim.finished and restored.voidTickets==9+amount)
    assert(Reward.exchangeAll(restored,saved) and restored.voidTickets==9+amount)
    restored.pendingVictoryReward=nil
    Reward.begin(Reward.calculate({type="boss",baseReward=5},restored,true),restored)
    assert(restored.voidTickets==9+amount,"skipping a boss cannot award tickets")
end
Rng.random=original
print("Boss Void tickets passed: guaranteed, every amount 1–100, ordinary chance, one payout, save/reload, reveal/skip, bulk exchange preserves tickets")

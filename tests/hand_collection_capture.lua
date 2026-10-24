local T={}
local UI=require("src.ui")
local M=UI.HandMotion
local Deck=require("src.deck")
local cases={{count=5},{count=12,fast=true},{count=30},{count=5,reduced=true},{count=0}}
local index,stage,started=0,"start",0
function T.update(game,cb)
    local now=love.timer.getTime()
    assert(now-started<15 or stage=="start","victory collection timeout at "..stage)
    if stage=="start" then
        require("tests.hand_collection_smoke")
        index=index+1
        local spec=cases[index]
        if not spec then
            print("Victory collection runtime PASS: 0/5/12/30 cards, normal/fast/reduced, every frame hidden until completion, all owned cards retained, one reward")
            love.event.quit(0);return
        end
        cb.startNewGame("red_deck");cb.setReducedMotion(spec.reduced==true);cb.setScoringSpeed(spec.fast==true)
        game.pendingVictoryReward=nil -- Each case skips claiming the previous ceremony.
        cb.startMonsterEncounter(1,false)
        M.reset();game.hand={};game.deck={};game.discardPile={};game.persistentDeck={}
        for i=1,math.max(1,spec.count) do
            local c=Deck.newCard(2+(i-1)%13,({"hearts","diamonds","clubs","spades"})[1+(i-1)%4])
            game.persistentDeck[i]=c
            if i<=spec.count then
                c.visualX=250+i*8;c.visualY=470;c.visualScale=1;c.rotation=0
                game.hand[#game.hand+1]=c
            end
        end
        game.masterDeck=game.persistentDeck;game.deities={};game.monster.hp=100000;game.monster.maxHp=100000
        T.owned={};for _,c in ipairs(game.persistentDeck) do T.owned[c.id]=true end
        T.rewardSerial=game.rewardClaimSerial or 0;T.observed=false
        stage="kill";started=now
    elseif stage=="kill" and now-started>.3 then
        game.monster.hp=0;game.potionVictoryPending=true
        stage="collect";started=now
    elseif stage=="collect" then
        if M.onCollected then
            T.observed=true
            for _,c in ipairs(game.hand) do assert(M.hidden(c),"Already returned card reappeared on the hand") end
        end
        if select(2,cb.getRunState())=="CASH_OUT" then
            assert(#game.hand==0 and not M.busy(game.hand) and not M.onCollected)
            local remaining={};for _,c in ipairs(game.persistentDeck) do remaining[c.id]=true end
            for id in pairs(T.owned) do assert(remaining[id],"Collection removed an owned card") end
            assert(game.rewardClaimSerial==T.rewardSerial+1,"Victory reward paid more than once")
            if cases[index].count>0 and not cases[index].reduced then assert(T.observed,"Collection animation was skipped") end
            UI.finishCombatVictory();assert(game.rewardClaimSerial==T.rewardSerial+1)
            print("Victory collection PASS: "..cases[index].count.." cards"..(cases[index].fast and " fast" or cases[index].reduced and " reduced" or " normal"))
            stage="start";started=now
        end
    end
end
return T

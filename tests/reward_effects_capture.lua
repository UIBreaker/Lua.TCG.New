local Reward=require("src.reward_system")
local Rng=require("src.rng")
local Visual=require("config.visual_config")
local Sound=require("src.sound")
local Test={}
local cases={
    {name="ticket_1",amount=1},{name="ticket_12",amount=12},{name="ticket_35",amount=35},
    {name="ticket_65",amount=65},{name="ticket_90",amount=90},{name="jackpot_100",amount=100},
    {name="common",id="playing_card"},{name="rare",id="fx_rare"},{name="gold",id="gold_bonus"},
    {name="chest",id="rare_reward"},{name="jackpot_low",amount=100,quality="LOW"},
    {name="jackpot_reduced",amount=100,reduced=true},
}
local index,stage,deadline=1,"start",0
local savedGold,savedTickets,rngBefore
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local path="docs/reward_fx_"..name..".png"
        local f=io.open(path,"wb")
        if f then f:write(data:encode("png"):getString());f:close()
        else love.filesystem.createDirectory("reward_capture");assert(love.filesystem.write("reward_capture/reward_fx_"..name..".png",data:encode("png"))) end
    end)
end
function Test.update(game,cb)
    if love.timer.getTime()<deadline then return end
    if stage=="start" then
        require("tests.reward_effects_smoke")
        cb.startNewGame("red_deck");love.mouse.setPosition(2,2)
        Reward.config.definitions.fx_rare={type="CONSUMABLE",consumableId="healing_potion",rarity="rare"}
        for _,sound in ipairs({"coin","reward_loot_reveal","reward_rare_reveal","reward_chest_open","score_charge","jackpot"}) do assert(Sound.has(sound),sound) end
        stage="prepare"
    elseif stage=="prepare" then
        local case=cases[index]
        if not case then print("Reward effects UI passed: six ticket tiers/jackpot, common/rare/gold/chest, LOW/reduced, actual receipts unchanged");love.event.quit(0);stage="done";return end
        Visual.quality=case.quality or "HIGH";Visual.enabled=not case.reduced
        game.monster={hp=0,maxHp=100,isBoss=case.amount~=nil,stage=1}
        game.rewardPacks={};game.consumables={};game.backpackConsumables={}
        Reward.config.tables.fx_capture={rolls={1,1},entries={{id=case.id or "gold_bonus",weight=1}}}
        local original=Rng.random
        Rng.random=function(a,b) if not a then return .99 elseif case.amount and a==1 and b==100 then return case.amount else return original(a,b) end end
        cb.openReward("fx_capture");Rng.random=original
        local anim=cb.getRewardAnimation()
        local target=1
        if case.amount then for i,slot in ipairs(anim.slots) do if slot.reward.type=="VOID_TICKET" then target=i end end end
        savedGold,savedTickets,rngBefore=game.gold,game.voidTickets,Rng.getState()
        for i=1,2400 do Reward.update(anim,1/120);if anim.revealedLoot==target then break end end
        assert(anim.revealedLoot==target)
        local effect=anim.slots[target].effect
        Reward.update(anim,case.amount and (case.amount==100 and .95 or .24+effect.level*.12) or case.id=="rare_reward" and .16 or .27)
        assert(game.gold==savedGold and game.voidTickets==savedTickets and Rng.getState()==rngBefore)
        stage="shot";deadline=love.timer.getTime()+.025
    elseif stage=="shot" then
        assert(game.gold==savedGold and game.voidTickets==savedTickets and Rng.getState()==rngBefore)
        shot(cases[index].name)
        stage="next";deadline=love.timer.getTime()+.04
    elseif stage=="next" then index=index+1;stage="prepare" end
end
return Test

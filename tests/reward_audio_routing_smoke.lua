local oldSound,oldReward=package.loaded["src.sound"],package.loaded["src.reward_system"]
local plays,stops,current={},{},nil
package.loaded["src.sound"]={play=function(name,pitch) plays[#plays+1]={name=name,pitch=pitch,at=current and current.audioTime or 0};return true end,
    stopCue=function(name) stops[#stops+1]=name end,rewardPitch=function() return .8,2.4 end}
package.loaded["src.reward_system"]=nil
local Reward=require("src.reward_system")
local A=require("src.reward_audio")
local Rng=require("src.rng")
local b={basePayout=0,unusedHandsBonus=0,interestBonus=0,deityBonus=0,factionBonus=0,currentGold=0,totalGold=0}
local loot={}
for i=1,#A.order do
    loot[#loot+1]={type="CHEST",rarity=A.order[i]}
    loot[#loot+1]={type="PLAYING_CARD",rarity=A.order[i]}
end
local result={loot=loot,earnedGold=0,earnedSouls=0}
current=Reward.newAnimation(b,{loot={},earnedGold=0,earnedSouls=0})
Reward.update(current,1.8)
assert(current.finished,"an empty ceremony must not wait for a chest that does not exist")
for _,fps in ipairs({30,60,144}) do for _,reduced in ipairs({false,true}) do for _,speed in ipairs({1,2}) do
    plays,stops={},{};current=Reward.newAnimation(b,result,{reducedMotion=reduced})
    local rng=Rng.getState()
    for i=1,30*fps do Reward.update(current,speed/fps,speed);if current.finished then break end end
    assert(current.finished and current.audioPitch==.8 and Rng.getState()==rng)
    local seen={}
    for _,p in ipairs(plays) do
        if p.name:match("^reward_open_") or p.name:match("^reward_receive_") then
            assert(p.at>=2.4 and p.pitch==.8,"loot must follow the triumph and use its key")
            seen[p.name]=(seen[p.name] or 0)+1
        end
    end
    for i=1,#A.order do
        assert(seen[A.cue("open",loot[(i-1)*2+1])]==1)
        assert(seen[A.cue("receive",loot[i*2])]==1)
    end
    assert(#stops==#A.order*2-2,"each chest/rare anticipation stops at the real reveal")
end end end
plays,stops={},{};current=Reward.newAnimation(b,result)
for i=1,600 do Reward.update(current,1/120);if current.rewardCharge then break end end
local charging=assert(current.rewardCharge)
Reward.finishImmediately(current)
assert(stops[#stops]==charging and current.rewardCharge==nil and current.finished,"skip cancels its own charge")
local after=#plays;Reward.update(current,2);assert(#plays==after,"skip must not replay missed rewards")
local Shop=require("src.shop");local Deck=require("src.deck")
for _,rarity in ipairs(A.order) do
    local card=Deck.newCard(5,"hearts");card.rarity=rarity
    local game={persistentDeck={},deck={},hand={},discardPile={}}
    local shop={rewardAudioPitch=.8,currentPackOpening={pack={packType="standard",rewardPack=true},cards={card}}}
    plays={};assert(Shop.choosePackCard(shop,1,game))
    assert(#plays==1 and plays[1].name==A.cue("collect",card) and plays[1].pitch==.8,"actual pack selection must sound its item's rarity")
    plays={};assert(not Shop.choosePackCard(shop,1,game) and #plays==0,"duplicate/invalid pick must stay silent")
end
package.loaded["src.sound"],package.loaded["src.reward_system"]=oldSound,oldReward
print("Reward routing PASS: 10 ceremony + collectible rarities / 30,60,144 FPS / normal-fast-reduced motion / real-time triumph timing+key / skip / one sound per selection / unchanged RNG")
return true

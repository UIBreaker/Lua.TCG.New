local E=require("ui.reward_effects")
local Reward=require("src.reward_system")
local Visual=require("config.visual_config")
local Rng=require("src.rng")
local amounts={1,9,10,24,25,49,50,74,75,99,100}
local previous=0
for _,amount in ipairs(amounts) do
    local p=E.profile({type="VOID_TICKET",amount=amount})
    assert(p.level>=previous and p.jackpot==(amount==100))
    assert(p.particles<=Reward.config.presentation.maxSparks)
    assert(p.gachaStrength>=3 and p.gachaStrength<=9)
    previous=p.level
end
local common=E.profile({type="PLAYING_CARD",rarity="common"})
local rare=E.profile({type="PLAYING_CARD",rarity="rare"})
local gold=E.profile({type="GOLD"})
local chest=E.profile({type="CHEST",rarity="legendary"})
assert(common.kind=="common" and rare.kind=="rare" and gold.kind=="gold" and chest.kind=="chest")
assert(common.particles<rare.particles and common.anticipation<chest.anticipation)
assert(common.sound~=rare.sound and rare.sound~=chest.sound and gold.sound~=common.sound)
local breakdown={basePayout=0,unusedHandsBonus=0,interestBonus=0,deityBonus=0,factionBonus=0,currentGold=10,totalGold=0}
local before=Rng.getState()
for _,quality in ipairs({"LOW","MEDIUM","HIGH"}) do
    Visual.quality=quality
    for _,fps in ipairs({30,60,144}) do
        local result={loot={{type="VOID_TICKET",amount=100,rarity="rare",name="+100 VÉ THE VOID"}},earnedGold=0,bonusGold=0}
        local anim=Reward.newAnimation(breakdown,result)
        local held=0;local sawJackpot=false
        for i=1,fps*10 do
            Reward.update(anim,1/fps)
            assert(#anim.sparks<=Visual.qualities[quality].particles)
            if anim.state=="REWARD_HOLD" then held=held+1/fps;sawJackpot=anim.revealEvent.profile.jackpot end
            if anim.finished then break end
        end
        assert(anim.finished and sawJackpot and held>=2.25)
        assert(anim.displayTotal==0 and anim.walletTotal==10 and Rng.getState()==before)
        local skip=Reward.newAnimation(breakdown,result)
        Reward.update(skip,1);Reward.finishImmediately(skip)
        assert(skip.finished and not skip.revealEvent and #skip.sparks==0 and skip.slots[1].suppressEffects)
    end
end
Visual.enabled=false
local calm=Reward.newAnimation(breakdown,{loot={{type="VOID_TICKET",amount=100,rarity="rare"}},earnedGold=0})
Reward.update(calm,3)
assert(calm.finished and #calm.sparks==0 and Rng.getState()==before)
Visual.enabled=true;Visual.quality="HIGH"
print("Reward effects passed: six ticket tiers, exactly-100 jackpot, distinct reward families, bounded LOW/MEDIUM/HIGH particles, 30/60/144 FPS, skip/reduced effects, unchanged RNG/economy")

local Reward=require("src.reward_system")
local D=require("src.death_vfx")
local Rng=require("src.rng")
local function close(a,b) assert(math.abs(a-b)<1e-6,tostring(a).." ~= "..tostring(b)) end
local breakdown={currentGold=10,totalGold=7,basePayout=3,unusedHandsBonus=2,interestBonus=2,
    deityBonus=0,factionBonus=0,bossVictoryBonus=0}
local result={earnedGold=12,bonusGold=5,earnedSouls=2,soulsBefore=3,loot={}}
for i=1,8 do result.loot[i]={type=i==1 and "GOLD" or "CARD_PACK",packType=i>1 and "standard" or nil,
    amount=i==1 and 5 or 1,rarity=i%3==0 and "rare" or "common",source="VICTORY",name="Chiến lợi phẩm"} end
for _,reduced in ipairs({false,true}) do
    for _,fps in ipairs({30,60,120,144}) do
        for _,fast in ipairs({false,true}) do
            local a=Reward.newAnimation(breakdown,result,{reducedMotion=reduced})
            close(Reward.panelPose(a),reduced and 0 or 32)
            if not reduced then
                a.timer=Reward.config.presentation.stagger
                assert(Reward.slotPose(a,1).enter>Reward.slotPose(a,2).enter,"tile stagger")
                a.timer=0
            end
            local rng=Rng.getState();local elapsed=0
            repeat
                elapsed=elapsed+1/fps;Reward.update(a,(fast and 2 or 1)/fps)
                assert(elapsed<20,"ceremony must settle")
                assert(a.displayTotal<=result.earnedGold and a.walletTotal==breakdown.currentGold+a.displayTotal)
                if reduced then assert(#a.coins==0 and #a.sparks==0,"reduced reward avoids flight and bursts") end
            until a.finished
            close(Reward.panelPose(a),0)
            assert(a.buttonActive and a.displayTotal==12 and a.soulTotal==5)
            for i=1,#a.slots do assert(Reward.slotPose(a,i).ready,"continue waits for the last face to settle") end
            assert(Rng.getState()==rng and result.earnedGold==12,"animation cannot roll or award loot")
            assert(Reward.changePage(a,-1) and a.lootPage==1)
            if not reduced then assert(not Reward.slotPose(a,1).ready,"new page settles before hover") end
            Reward.update(a,.7)
            assert(Reward.slotPose(a,1).ready)
            for _,delay in ipairs({0,.15,1.5,4}) do
                local skip=Reward.newAnimation(breakdown,result,{reducedMotion=reduced})
                Reward.update(skip,delay);Reward.finishImmediately(skip);Reward.finishImmediately(skip)
                close(Reward.panelPose(skip),0)
                assert(skip.finished and skip.displayTotal==12 and skip.soulTotal==5 and #skip.coins==0)
                for i=1,#skip.slots do assert(Reward.slotPose(skip,i).ready) end
            end
        end
    end
end
for i=1,D.config.particles.max do D.pool[i]={} end
for _,reduced in ipairs({false,true}) do
    D.reset();D.startPlayer(640,"LOW",reduced)
    local rng=Rng.getState()
    close(D.camera(),0)
    D.age=.08;local cx,cy=D.camera()
    if reduced then close(cx,0);close(cy,0) else assert(cx<0 and cy>0) end
    D.age=.30;close(D.camera(),0)
    for i=1,8 do
        D.age=0;local x,y,r,p=D.cardPose(i);close(x,0);close(y,0);close(r,0);close(p,0)
        D.age=1.12+math.min(i-1,7)*D.config.player.cardStagger
        x,y,r,p=D.cardPose(i);close(p,1)
        close(math.abs(x),reduced and 0 or D.config.player.cardSpread)
        close(y,reduced and 0 or D.config.player.cardDrop)
        close(math.abs(r),reduced and 0 or D.config.player.cardTilt)
    end
    assert(Rng.getState()==rng)
end
D.reset();local enemy={hp=0,isBoss=true}
D.startEnemy(enemy,640,"HIGH",true);assert(D.reducedMotion and D.limit<=D.config.particles.HIGH*.3)
assert(not D.startEnemy(enemy,640,"HIGH",true),"death must not restart on a duplicate notification")
D.reset()
print("Outcome motion PASS: 30/60/120/144 FPS normal/2x/reduced, panel/tile endpoints, settled inputs, pages, skip, exact totals, no gameplay RNG, defeat card continuity")

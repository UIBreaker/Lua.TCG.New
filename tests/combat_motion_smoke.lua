local F=require("src.scoring_presentation")
local M=require("src.motion")
local Deck=require("src.deck")
local C=F.config.timing
local function close(a,b) assert(math.abs(a-b)<0.000001,"motion endpoint mismatch") end
local ui={BATTLE_CENTER_X=640,formatNumber=tostring,localizeText=function(s)return s end,
    getScoringCardX=function(i,n)return 640-n*55+(i-1)*110 end}
local cards={Deck.newCard(8,"spades"),Deck.newCard(8,"hearts")}
local enemy={hp=1000,maxHp=1000,creatureArmor=50,targetAura=100}
local result={totalChips=40,totalMult=2,rawScore=80,finalScore=80,
    steps={{type="base_hand",chips=10,mult=2,vnName="Đôi",handName="Pair"},
        {type="card_scored",card=cards[1],addedChips=15,addedMult=0},
        {type="equipment_trigger",card=cards[1],addedChips=0,addedMult=0,message="Di vật liên tiếp"},
        {type="card_scored",card=cards[2],addedChips=15,addedMult=0},
        {type="final_score",finalScore=80}}}
local function fixture(reduced)
    local a={playedCards=cards,cardBounce={},cardHit={},deityBounce={},scoredCards={},
        bounceScale={},floatingTexts={},cardEntryFrom={{x=410,y=450,rotation=-0.06,scale=1.07},
            {x=520,y=460,rotation=0.05,scale=1.04}}}
    F.start(a,result,ui,{},1000,enemy,"pair",{lab=true,reducedMotion=reduced})
    return a
end
local a=fixture(false)
local p=F.cardPose(a,1)
close(p.x,410);close(p.y,450);close(p.scale,1.07);close(p.rotation,-0.06)
a.entranceTimer=C.lift+C.travel+C.stagger
for i=1,2 do
    p=F.cardPose(a,i);close(p.x,ui.getScoringCardX(i,2));close(p.y,295)
    close(p.scale,0.96);close(p.rotation,0)
end
a.cardHit[1]=0;local initial=F.cardPose(a,1)
close(initial.y,295);close(initial.scale,0.96)
a.cardHit[1]=0.07;assert(F.cardPose(a,1).y<295)
a.cardHit[1]=C.cardPulse;close(F.cardPose(a,1).y,295)
close(M.impact(0,0.3),0);close(M.impact(0.3,0.3),0)
local impactRng=require("src.rng").getState()
for _,fps in ipairs({30,60,120,144}) do
    a=fixture(false)
    local contacts=0;local previousHp,previousArmor=1000,50
    local time=0
    while not F.isFinished(a) do
        local pulse=a.cardHit[1]
        local hit=F.update(a,1/fps,false);time=time+1/fps
        if pulse and pulse+1/fps<C.cardPulse and a.cardHit[1] then
            assert(a.cardHit[1]>=pulse,"consecutive triggers must not reset an active lift")
        end
        local s=a.sequence
        assert(s.hp<=previousHp+1e-8 and s.armor<=previousArmor+1e-8,"bars must not rebound")
        if not s.damageApplied then assert(s.hp==1000 and s.armor==50,"bars hold until contact") end
        if hit then
            contacts=contacts+1
            F.damageApplied(a,970,30,false,0)
            F.damageApplied(a,1,999,false,0)
            local recoil,scale=F.enemyReaction(a);close(recoil,0);close(scale,1)
            local x,y=F.camera(a);close(x,0);close(y,0)
        end
        previousHp,previousArmor=s.hp,s.armor
        assert(time<10)
    end
    assert(contacts==1 and a.sequence.actualDamage==30 and a.sequence.enemy==enemy)
    close(a.sequence.hp,970);close(a.sequence.hpTrail,970)
    close(a.sequence.armor,0);close(a.sequence.armorTrail,0)
    close(F.cardPose(a,1).y,295)
    local recoil,scale=F.enemyReaction(a);close(recoil,0);close(scale,1)
end
assert(require("src.rng").getState()==impactRng,"animation must not consume gameplay RNG")
a=fixture(true);p=F.cardPose(a,1)
close(p.x,ui.getScoringCardX(1,2));close(p.y,295);close(p.rotation,0)
F.damageApplied(a,970,30,false,0);a.sequence.cameraAge=0.05
local recoil,scale=F.enemyReaction(a);close(recoil,0);close(scale,1)
local x,y=F.camera(a);close(x,0);close(y,0)
a=fixture(false);F.damageApplied(a,1000,0,true,50)
recoil,scale=F.enemyReaction(a);close(recoil,0);close(scale,1)
assert(a.sequence.missed and a.sequence.armorTarget==50)
print("Combat motion PASS: start/land/trigger continuity, shared impact envelope, 30/60/120/144 FPS, contact-only HP/armor, exact trails, one damage, no RNG, reduced/miss")

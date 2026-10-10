local F=require("src.scoring_presentation")
local N=require("src.nen_combat")
local UI=require("src.ui")
local E=require("render.nen_effects")
local count,profiles=0,0
collectgarbage("collect");local memoryBefore=collectgarbage("count")
local wasOpen=F.labOpen;F.labOpen=true;F.labFilter=0
-- Warm every profile before measuring retained heap; LuaJIT traces are a one-time cost.
for pass=1,2 do
count,profiles=0,0
for _,id in ipairs(N.config.order) do if N.config.hands[id].ready then
    profiles=profiles+1
    assert(E.supports(id),id.." missing renderer / contact")
    for index,hand in ipairs(F.Attacks.config.labOrder) do if hand==id then F.labHand=index;break end end
    for tier=1,3 do
        F.labKeypressed(tostring(tier),UI)
        local preview=F.labAnim.sequence
        local result,cards=preview.result,F.labAnim.playedCards
        for repeatIndex=1,10 do
            local fps=({30,60,144})[(repeatIndex-1)%3+1];local dt=1/fps
            local anim={playedCards=cards,cardBounce={},cardHit={},deityBounce={},scoredCards={},floatingTexts={},bounceScale={chips=1,mult=1,score=1}}
            F.start(anim,result,UI,{},10000000,{maxHp=1000,hp=1000,targetAura=result.finalScore/({.25,1,2.5})[tier]},id,{lab=true,reducedMotion=repeatIndex%3==0})
            local attack=anim.sequence.attack;local n=assert(attack.nen)
            assert(n.tier==tier and n.profile.id==id and n.variant.choreography==N.config.hands[id].tiers[tier].choreography)
            attack.quality=({"low","medium","high"})[(repeatIndex-1)%3+1]
            if repeatIndex%4==0 then F.skipOrFastForward(anim) end
            local hits=0
            for frame=1,fps*30 do
                local contact=F.update(anim,dt,repeatIndex%2==0)
                if contact then hits=hits+1;F.damageApplied(anim,10000000-result.finalScore,result.finalScore) end
                if F.isFinished(anim) then break end
            end
            assert(F.isFinished(anim) and hits==1 and n.releaseCount==1,id.." single contact / finish")
            assert(anim.displayAura==result.finalScore and math.abs(anim.sequence.hpTrail-anim.sequence.hpTarget)<.001)
            local x,y=F.camera(anim);assert(math.abs(x)+math.abs(y)<.001,id.." camera settle")
            N.update(attack,"CHARGE",1);n.launch={};local origins={}
            for i=1,N.count(attack) do origins[i]={N.position(attack,i,"CHARGE",1)} end
            N.enter(attack,"RELEASE")
            for i=1,N.count(attack) do
                local px,py=N.position(attack,i,"TRAVEL",0)
                assert(math.abs(px-origins[i][1])+math.abs(py-origins[i][2])<.001,id.." origin continuity")
                for k=0,20 do local ax,ay=N.position(attack,i,"TRAVEL",k/20);assert(ax==ax and ay==ay and math.abs(ax)<1e4 and math.abs(ay)<1e4) end
                local ax,ay=N.position(attack,i,"TRAVEL",1);assert(ay==270,id.." arrival")
            end
            for i,c in ipairs(n.snapshot.cards) do assert(c.id==cards[i].id and c.rank==cards[i].rank and c.suit==cards[i].suit);assert(N.cardEmitter(attack,i)>=1 and N.cardEmitter(attack,i)<=N.count(attack)) end
            N.cancel(attack);count=count+1
        end
    end
end end
if pass==1 then collectgarbage("collect");memoryBefore=collectgarbage("count") end
end
F.labOpen=wasOpen
collectgarbage("collect")
local memoryGrowth=collectgarbage("count")-memoryBefore
assert(memoryGrowth<250,"all 27 profiles retain snapshots / particles: "..memoryGrowth.." KB")
print("NEN all-ready: "..profiles.." actual profiles / "..profiles*3 .." variants / "..count.." sequences (10 consecutive per variant), 3 FPS and qualities, fast/skip/reduced, single contact, snapshot IDs, origins/arrival and camera settle passed")
print(string.format("NEN mixed-profile stress: %d warm-up + %d measured sequences, collected heap growth %.1f KB (<250 KB)",count,count,memoryGrowth))
return true

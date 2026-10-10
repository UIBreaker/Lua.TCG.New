local N=require("src.nen_combat")
local F=require("src.scoring_presentation")
local D=require("src.deck")
local P=require("src.poker")
local S=require("src.scoring")
local ui={BATTLE_CENTER_X=635,formatNumber=tostring,localizeText=function(s)return s end,
    getScoringCardX=function(i,n)return 635-n*55+(i-1)*110 end}
local C=N.config
local types,ready,variants={},{},{}
assert(#C.order==27 and #C.types==6)
for _,hand in ipairs(P.ALL_HANDS_ORDERED) do assert(C.hands[hand.id],"missing authoritative hand ID "..hand.id) end
for _,id in ipairs(C.order) do
    local p=assert(C.hands[id]);assert(p.id==id)
    types[p.nenType]=(types[p.nenType] or 0)+1
    assert(#p.tiers==3)
    for _,tier in ipairs(p.tiers) do assert(not variants[tier.choreography]);variants[tier.choreography]=true end
    for _,sample in ipairs(C.samples) do if sample==id then ready[#ready+1]=id end end
end
assert(types.enhancement==4 and types.transmutation==5 and types.emission==5 and types.conjuration==5 and types.manipulation==4 and types.specialization==4)
assert(#ready==6)
for _,case in ipairs({{0,1},{.69999,1},{.70,2},{1.7999,2},{1.8,3},{1e300,3}}) do
    local tier,ratio,intensity=N.power(case[1]*1000,1000)
    assert(tier==case[2] and ratio<=C.power.maxRatio and intensity>=0 and intensity<=1)
end
for _,reference in ipairs({0,-1,1,1e200,math.huge}) do
    local tier,ratio=N.power(1e200,reference);assert(tier>=1 and tier<=3 and ratio==ratio)
end
assert(N.power(0/0,0)==1 and N.power(math.huge,1)==1)
local group={{hp=0,maxHp=500,creatureArmor=20},{hp=100,maxHp=300,creatureArmor=30}}
local ref=N.reference(group[1],{enemies=group})
assert(ref==425 and ref==N.reference(group[2],{enemies=group}),"same encounter reference for every target")
group[1].hp=0;group[2].hp=0;assert(N.reference(group[2],{enemies=group})==ref,"no tier inflation as enemy HP falls")
assert(N.reference({hp=0,maxHp=0})==C.power.fallbackReference)
local shuffled={D.newCard(9,"hearts"),D.newCard(2,"spades"),D.newCard(3,"hearts"),D.newCard(4,"clubs"),D.newCard(6,"hearts")}
local electric=require("src.hand_attacks").new({steps={{}},finalScore=100},shuffled,ui,100,"tesla_369")
assert(N.cardEmitter(electric,3)==1 and N.cardEmitter(electric,5)==2 and N.cardEmitter(electric,1)==3,"Tesla emitters stay attached to their 3/6/9 cards in any play order")
local fixtures={high_card={{14}},pair={{8,8}},straight={{7,8,9}},even_frost={{2,4,6,8,10}},
    tesla_369={{3,6,9,2,4},{"hearts","hearts","hearts","clubs","spades"}},
    eclipse_duality={{2,4,9,4,2},{"hearts","diamonds","hearts","clubs","spades"}}}
local count=0
for _,id in ipairs(ready) do
    local cards={}
    for i,rank in ipairs(fixtures[id][1]) do
        cards[i]=D.newCard(rank,(fixtures[id][2] or {"hearts","clubs","spades","diamonds","hearts"})[i]);cards[i].disableFactionPassives=true
    end
    local evaluated=P.evaluate(cards,{high_card=true,[id]=true})
    assert(evaluated.type.id==id,"real resolver mapping "..id)
    local result=S.calculate(evaluated,{},{})
    for tier,ratio in ipairs({.25,1,2.5}) do
        for _,fps in ipairs({30,60,144}) do for _,speed in ipairs({"normal","fast","skip","reduced"}) do
            local a={playedCards=evaluated.scoringCards,cardBounce={},cardHit={},deityBounce={},scoredCards={},floatingTexts={},bounceScale={chips=1,mult=1,score=1}}
            F.start(a,result,ui,{},10000000,{targetAura=result.finalScore/ratio,screenX=700},id,{lab=true,reducedMotion=speed=="reduced"})
            local n=a.sequence.attack.nen;assert(n.tier==tier and n.snapshot.targetX==700)
            assert(n.snapshot.aura==result.finalScore and #n.snapshot.cards==#evaluated.scoringCards)
            if speed=="skip" then F.skipOrFastForward(a) end
            local hits=0
            for frame=1,fps*30 do
                if (a.hitStop or 0)>0 then a.hitStop=math.max(0,a.hitStop-1/fps)
                else local contact=F.update(a,1/fps,speed=="fast")
                    if contact then hits=hits+1;F.damageApplied(a,10000000-result.finalScore,result.finalScore) end
                end
                if not a.sequence.impactDispatched then assert(a.sequence.hp==10000000) end
                if F.isFinished(a) then break end
            end
            assert(F.isFinished(a) and hits==1 and n.releaseCount==1,"single release/contact on "..id.." / "..speed)
            assert(a.displayAura==result.finalScore and math.abs(a.sequence.hpTrail-a.sequence.hpTarget)<.001)
            local dx,dy=F.camera(a);assert(math.abs(dx)+math.abs(dy)<.0001,"camera settles")
            assert(F.update(a,1)==nil)
            count=count+1
        end end
        local a=require("src.hand_attacks").new(result,evaluated.scoringCards,ui,100,id,{targetAura=result.finalScore/ratio})
        N.enter(a,"CARD_TRANSFORMATION");N.update(a,"CARD_TRANSFORMATION",1)
        N.enter(a,"CHARGE");N.update(a,"CHARGE",1)
        local origins={};for i=1,N.count(a) do origins[i]={N.position(a,i,"CHARGE",1)} end
        N.enter(a,"RELEASE")
        for i=1,N.count(a) do
            local x,y=N.position(a,i,"TRAVEL",0);assert(math.abs(x-origins[i][1])+math.abs(y-origins[i][2])<.001)
            local fx,fy=N.position(a,i,"TRAVEL",1);assert(fx==fx and fy==270,"all lanes arrive")
        end
        local rank=a.nen.snapshot.cards[1].rank;local original=a.sources[1].card.rank
        a.sources[1].card.rank=2;assert(a.nen.snapshot.cards[1].rank==rank,"snapshot does not follow card mutations");a.sources[1].card.rank=original
        N.cancel(a);assert(a.nen.cancelled and #a.nen.points==0)
    end
end
-- Cancellation during any phase drops presentation; it is not the gameplay Skip API.
for _,stage in ipairs(C.stages) do
    local card=D.newCard(14,"spades")
    local result={steps={{type="base_hand",chips=10,mult=1},{type="final_score",finalScore=10}},totalChips=10,totalMult=1,rawScore=10,finalScore=10}
    local a={playedCards={card},cardBounce={},cardHit={},deityBounce={},scoredCards={},floatingTexts={},bounceScale={chips=1,mult=1,score=1}}
    F.start(a,result,ui,{},0,{hp=0,maxHp=0},"high_card",{lab=true})
    for i,e in ipairs(a.sequence.events) do if e.kind==stage then a.sequence.index=i;break end end
    F.cancel(a);assert(F.isFinished(a) and F.update(a,1)==nil and a.hitStop==0)
end
F.labOpen=true
for _,id in ipairs(ready) do
    for index,hand in ipairs(F.Attacks.config.labOrder) do if hand==id then F.labHand=index end end
    for tier=1,3 do F.labKeypressed(tostring(tier),ui);assert(F.labAnim.sequence.attack.nen.tier==tier) end
end
F.labKeypressed("=",ui);assert(F.labAnim.sequence.attack.nen.snapshot.aura==F.labAura)
F.labOpen=false
collectgarbage("collect")
local memoryBefore=collectgarbage("count")
for i=1,1200 do
    local card=D.newCard(14,"spades")
    local a=require("src.hand_attacks").new({steps={{}},finalScore=i},{card},ui,100,"high_card",{hp=0,maxHp=1000})
    N.enter(a,"CHARGE");N.update(a,"CHARGE",1);N.enter(a,"RELEASE");N.update(a,"TRAVEL",.5);N.cancel(a)
end
collectgarbage("collect")
assert(collectgarbage("count")-memoryBefore<64,"Niệm retains cancelled attack snapshots")
print("NEN foundation: 27 IDs / 6 types / 81 registry variants; 6 foundation samples / 18 choreographies / "..count.." scoring sequences, relative tiers, 3-card straight, snapshot, normal/fast/skip/reduced, single contact, dead target, cancellation and lab passed")
print("NEN memory: 1200 create/release/cancel cycles; collected heap growth <64 KB")
return true

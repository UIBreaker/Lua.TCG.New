local A=require("src.hand_attacks")
local F=require("src.scoring_presentation")
local D=require("src.deck")
local P=require("src.poker")
local S=require("src.scoring")
local ui={BATTLE_CENTER_X=635,formatNumber=tostring,localizeText=function(s)return s end,
    getScoringCardX=function(i,n)return 635-n*55+(i-1)*110 end}
for _,case in ipairs({{0,1},{0.499,1},{0.5,2},{0.999,2},{1,3},{1.999,3},{2,4},{3.999,4},{4,5},{1e15,5}}) do
    local intensity,tier=A.power(case[1]*1000,1000)
    assert(tier==case[2] and intensity>=0 and intensity<=1)
end
for _,target in ipairs({-1,0,1,1e15}) do local intensity=A.power(1e30,target);assert(intensity<=1) end
local shapes,conversions,impacts={},{},{}
local presets={{14},{8,8},{8,8,11,11},{8,8,8},{7,8,9,10,11},{2,5,8,11,14},{8,8,8,11,11},{8,8,8,8},{10,11,12,13,14}}
local count=0
for index,id in ipairs(A.config.order) do
    local profile=A.config.hands[id]
    assert(not shapes[profile.projectile] and not conversions[profile.cardConversion] and not impacts[profile.impact])
    shapes[profile.projectile],conversions[profile.cardConversion],impacts[profile.impact]=true,true,true
    local hand
    for _,h in pairs(P.HAND_TYPES) do if h.id==id then hand=h end end
    local cards={}
    for i,rank in ipairs(presets[index]) do cards[i]=D.newCard(rank,(id=="flush" or id=="straight_flush") and "spades" or ({"spades","hearts","clubs","diamonds"})[(i-1)%4+1]) end
    local result=S.calculate({type=hand,scoringCards=cards,unscoredCards={}},{},{})
    for _,ratio in ipairs({0.25,0.75,1.5,3,5}) do
        for _,fps in ipairs({30,60,144}) do
            for _,fast in ipairs({false,true}) do
                local a={playedCards=cards,cardBounce={},cardHit={},deityBounce={},scoredCards={},floatingTexts={},bounceScale={chips=1,mult=1,score=1}}
                F.start(a,result,ui,{},10000000,{targetAura=result.finalScore/ratio})
                assert(a.sequence.attack.profile.id==id,"real resolver profile mapping")
                local hits=0
                for frame=1,fps*30 do
                    if (a.hitStop or 0)>0 then a.hitStop=math.max(0,a.hitStop-1/fps)
                    else
                        local step=F.update(a,1/fps,fast)
                        if step then hits=hits+1;F.damageApplied(a,10000000-result.finalScore,result.finalScore) end
                    end
                    if not a.sequence.impactDispatched then assert(a.sequence.hp==10000000) end
                    if F.isFinished(a) then break end
                end
                assert(F.isFinished(a) and hits==1 and a.displayAura==result.finalScore)
                assert(math.abs(a.sequence.hpTrail-a.sequence.hpTarget)<0.001)
                count=count+1
            end
        end
    end
end
-- Regression: formations used to teleport at phase boundaries, and moving launch
-- origins bent the trail underneath the projectile. All quality/tier combinations.
for index,id in ipairs(A.config.order) do
    local cards={}
    for i,rank in ipairs(presets[index]) do cards[i]=D.newCard(rank,"spades") end
    for _,quality in ipairs({"low","medium","high"}) do
        for tier=1,5 do
            local a=A.new({steps={{}},finalScore=100},cards,ui,100,id)
            a.quality,a.tier=quality,tier
            local n=a.profile.blades and math.min(a.profile.blades[tier],A.config.quality[quality]) or (id=="high_card" and 1 or (id=="full_house" and 2 or #cards))
            A.enter(a,"ENERGY_CONVERSION");A.update(a,"ENERGY_CONVERSION",1)
            local before={}
            for i=1,n do local x,y=A.position(a,i,"ENERGY_CONVERSION",1);before[i]={x,y} end
            A.enter(a,"ANTICIPATION");A.update(a,"ANTICIPATION",0)
            for i=1,n do
                local x,y=A.position(a,i,"ANTICIPATION",0)
                assert(math.abs(x-before[i][1])+math.abs(y-before[i][2])<0.001,"conversion/charge teleport: "..id)
            end
            A.update(a,"ANTICIPATION",1)
            for i=1,n do local x,y=A.position(a,i,"ANTICIPATION",1);before[i]={x,y} end
            A.enter(a,"ATTACK");A.update(a,"ATTACK",0)
            for i=1,n do
                local x,y=A.position(a,i,"ATTACK",0)
                assert(math.abs(x-before[i][1])+math.abs(y-before[i][2])<0.001,"charge/release teleport: "..id)
                local firstX,firstY=A.position(a,i,"ATTACK",0.5)
                A.update(a,"ATTACK",1)
                local againX,againY=A.position(a,i,"ATTACK",0.5)
                assert(firstX==againX and firstY==againY,"trajectory changed behind the trail")
                local endX,endY=A.position(a,i,"ATTACK",1)
                assert(endX==endX and endY==endY)
            end
        end
    end
end
print("Motion continuity: 135 hand/tier/quality cases passed; no phase teleport or moving launch origins")
local wheel={D.newCard(14,"spades"),D.newCard(5,"hearts"),D.newCard(2,"clubs"),D.newCard(4,"diamonds"),D.newCard(3,"spades")}
local a=A.new({steps={{}},finalScore=100},wheel,ui,100,"straight")
assert(a.rankOrder[1]==1 and a.sources[1].order==1,"Ace-low visual rank order")
for suit,color in pairs(A.config.suitColors) do
    local flush=A.new({steps={{}},finalScore=100},{D.newCard(8,suit)},ui,100,"flush")
    assert(flush.color==color)
end
print("Hand attacks: "..count.." real scoring sequences passed; tier boundaries, caps, nine silhouettes/conversions/impacts, Ace-low, four suits, FPS/speed, single damage and HP ordering")

-- Advanced formations used to reuse five card indexes on 2/3/4-lane paths.
local advancedCases=0
for _,h in ipairs(require("src.advanced_hands").ordered) do
    local cards={}
    for i,rank in ipairs({2,4,6,8,10}) do cards[i]=D.newCard(rank,"spades") end
    for _,quality in ipairs({"low","medium","high"}) do for tier=1,5 do
        local a=A.new({steps={{}},finalScore=100},cards,ui,100,h.id)
        a.quality,a.tier=quality,tier
        local n=math.min(a.profile.blades and a.profile.blades[tier] or a.profile.emitters,A.config.quality[quality])
        A.enter(a,"ENERGY_CONVERSION");A.update(a,"ENERGY_CONVERSION",1)
        local before={}
        for i=1,n do local x,y=A.position(a,i,"ENERGY_CONVERSION",1);before[i]={x,y} end
        A.enter(a,"ANTICIPATION");A.update(a,"ANTICIPATION",0)
        for i=1,n do local x,y=A.position(a,i,"ANTICIPATION",0)
            assert(math.abs(x-before[i][1])+math.abs(y-before[i][2])<.001,"advanced formation teleport "..h.id)
        end
        A.update(a,"ANTICIPATION",1)
        for i=1,n do local x,y=A.position(a,i,"ANTICIPATION",1);before[i]={x,y} end
        for i=1,n do for j=i+1,n do
            assert(math.abs(before[i][1]-before[j][1])+math.abs(before[i][2]-before[j][2])>1,"overlapping advanced lanes "..h.id)
        end end
        A.enter(a,"ATTACK")
        for i=1,n do
            local x,y=A.position(a,i,"ATTACK",0)
            assert(math.abs(x-before[i][1])+math.abs(y-before[i][2])<.001,"advanced release teleport "..h.id)
            local endX,endY=A.position(a,i,"ATTACK",1)
            assert(endX==endX and endY==endY and endY<280,"unfinished advanced projectile "..h.id)
        end
        advancedCases=advancedCases+1
    end end
end
print("Advanced VFX continuity: "..advancedCases.." hand/tier/quality cases; unique lanes and all projectiles reach impact passed")

F.labOpen=true
for index,id in ipairs(A.config.labOrder) do for tier=1,5 do
    F.labHand=index;F.labKeypressed(tostring(tier),ui)
    assert(F.labAnim.sequence.attack.profile.id==id and F.labAnim.sequence.attack.tier==tier)
end end
F.labOpen=false
print("All 27 isolated VFX Lab previews / all 5 tiers passed")

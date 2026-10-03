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
local wheel={D.newCard(14,"spades"),D.newCard(5,"hearts"),D.newCard(2,"clubs"),D.newCard(4,"diamonds"),D.newCard(3,"spades")}
local a=A.new({steps={{}},finalScore=100},wheel,ui,100,"straight")
assert(a.rankOrder[1]==1 and a.sources[1].order==1,"Ace-low visual rank order")
for suit,color in pairs(A.config.suitColors) do
    local flush=A.new({steps={{}},finalScore=100},{D.newCard(8,suit)},ui,100,"flush")
    assert(flush.color==color)
end
print("Hand attacks: "..count.." real scoring sequences passed; tier boundaries, caps, nine silhouettes/conversions/impacts, Ace-low, four suits, FPS/speed, single damage and HP ordering")

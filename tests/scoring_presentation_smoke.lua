local Feel = require("src.scoring_presentation")
local Scoring = require("src.scoring")
local Deck = require("src.deck")
local Deities = require("src.deities")
local Effects = require("src.card_effects")
local Poker = require("src.poker")
_G.Rng = require("src.rng")
local ui = {BATTLE_CENTER_X = 635, formatNumber = tostring, localizeText = function(s) return s end,
    getScoringCardX = function(i,n) return 635-(n*110)/2+(i-1)*110 end,
    getDeitySlotRect = function(i) return 1042+(i-1)%3*72,112,64,88 end}
local function run(result,cards,deities,fps,fast)
    local a = {playedCards=cards, cardBounce={}, cardHit={}, deityBounce={}, scoredCards={},
        bounceScale={chips=1,mult=1,score=1}, floatingTexts={},
        displayFlatDamage=0, displayAuraEditionMultiplier=1, displayXMult=1}
    Feel.start(a,result,ui,deities,10000000)
    assert(a.displayChips==0 and a.displayMult==0 and a.displayAura==0)
    local hits, time, countSeen, afterTriggers = 0,0,false,false
    while not Feel.isFinished(a) do
        local st = Feel.update(a,1/fps,fast)
        time = time+1/fps
        local ev = a.sequence.events[a.sequence.index]
        assert(#a.sequence.links<=18,"contribution effects remain bounded")
        if ev and (ev.kind=="TRIGGER" or ev.kind=="BASE_DAMAGE" or ev.kind=="BASE_ENHANCE" or ev.kind=="FORMULA") and a.sequence.entered then
            for _,metric in ipairs({{"displayChips","fromChips","toChips"},{"displayMult","fromMult","toMult"}}) do
                local value,from,to=a[metric[1]],a.sequence[metric[2]],a.sequence[metric[3]]
                local tolerance=math.max(1,math.abs(to))*1e-9
                assert(value>=math.min(from,to)-tolerance and value<=math.max(from,to)+tolerance,"smooth count must not overshoot")
            end
        end
        if ev and ev.kind=="FORMULA" then
            assert(math.abs(a.displayChips-result.totalChips)<0.001, "damage must match before reconciliation")
            assert(math.abs(a.displayMult-result.totalMult)<0.001, "enhance must match before reconciliation")
            afterTriggers=true
        end
        if ev and ev.kind=="AURA_COUNT" and a.sequence.age>0 then
            countSeen = countSeen or (a.displayAura>0 and a.displayAura<result.finalScore)
        end
        if not a.sequence.impactDispatched then
            assert(a.sequence.hp==10000000 and a.sequence.hpTrail==10000000,"HP held until arrival")
        end
        if a.displayAura==0 then assert(next(a.cardTransform)==nil,"no dissolve while scoring") end
        if st then
            assert(st.type=="final_score" and a.displayAura==result.finalScore)
            assert(next(a.cardTransform),"energy conversion precedes hit")
            hits=hits+1
            Feel.damageApplied(a,math.max(0,10000000-result.finalScore),result.finalScore)
        end
        assert(time<30,"sequence should finish")
    end
    assert(hits==1 and countSeen and afterTriggers)
    assert(a.displayChips==result.totalChips and a.displayMult==result.totalMult)
    assert(a.displayAura==result.finalScore)
    assert(math.abs(a.sequence.hpTrail-a.sequence.hpTarget)<0.001,"HP trail settles before unlock")
    assert(Feel.update(a,1)==nil,"never re-apply damage")
    return time,a
end
local deities = {Deities.CATALOG.spirit_blade, Deities.CATALOG.thunder_drum}
for _, suit in ipairs({"spades","hearts","diamonds","clubs"}) do
    for _, rank in ipairs({2,8,11,12,13,14}) do
        local cards = {Deck.newCard(rank,suit),Deck.newCard(rank,suit)}
        cards[1].equipments={{name="Test gem",onCardScore=function() return {addChips=7,addMult=2,xMultBonus=0.3,extraDamagePct=0.1} end}}
        cards[1].enhancement="enh_blood"
        Effects.setEffect(cards[1],"holographic"); Effects.setEffect(cards[2],"foil")
        local r=Scoring.calculate({type=Poker.HAND_TYPES.PAIR,chips=10,mult=2,scoringCards=cards,unscoredCards={}},deities,{gold=0,handsRemaining=2})
        local normal=run(r,cards,deities,60,false)
        local fast=run(r,cards,deities,144,true)
        assert(fast<normal*0.6 and fast>normal*0.4)
    end
end
local cards={Deck.newCard(8,"hearts")}
local multiplierSPN={name="Test ×2",onHandScored=function() return {addChips=3,addMult=2,xMult=2} end, edition="polychrome"}
local r=Scoring.calculate({type=Poker.HAND_TYPES.HIGH_CARD,scoringCards=cards,unscoredCards={}}, {multiplierSPN},{})
local times={}
for _,fps in ipairs({30,60,120,144}) do times[#times+1]=run(r,cards,{multiplierSPN},fps,false) end
local unpack = table.unpack or unpack
assert(math.max(unpack(times))-math.min(unpack(times))<0.15,"frame-rate independent timing")
for _,aura in ipairs({100,1000,10000,100000,1000000,1e15}) do
    local simulated={steps={{type="base_hand",chips=100,mult=1,vnName="Lab"},
        {type="card_scored",card=cards[1],addedChips=0,addedMult=0},
        {type="deity_hand",addedMult=aura/100-1,addedChips=0,resultingMult=aura/100,resultingChips=100},
        {type="final_score",finalScore=aura}},totalChips=100,totalMult=aura/100,rawScore=aura,finalScore=aura}
    local _,a=run(simulated,cards,{},120,false)
    assert(a.sequence.intensity>=0 and a.sequence.intensity<=1)
    for _,ev in ipairs(a.sequence.events) do if ev.kind=="AURA_COUNT" then assert(ev.duration<=0.65) end end
end
Feel.labKeypressed("f6",ui)
for key=1,5 do
    Feel.labKeypressed(tostring(key),ui)
    for frame=1,1500 do Feel.updateLab(1/120); if Feel.isFinished(Feel.labAnim) then break end end
    assert(Feel.isFinished(Feel.labAnim) and Feel.labAnim.sequence.actualDamage==Feel.labAura)
end
Feel.labKeypressed("escape",ui)
assert(not Feel.labOpen)
print("Scoring presentation: 24 real hands + editions/equipment/SPN, 30/60/120/144 FPS, Normal/Fast, 100..1e15 AURA, one impact, HP settle and all three Nen Lab tiers passed")

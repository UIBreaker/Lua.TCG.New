local D=require("src.deities")
local W=require("src.free_human_bosses")
local B=require("src.boss_abilities")
local C=require("src.combat")
local R=require("src.rng")
local Run=require("src.run_manager")
local P=require("src.persistence")
local Mimic=require("src.spn_mimic")
local definition=require("config.free_human_boss_data").byId.human_rank_inquisitor
local function spn(tier,id)
    local d={};for k,v in pairs(D.CATALOG[id or "spirit_blade"]) do d[k]=v end
    d.evolutionLevel=0;assert(D.setRarity(d,D.RARITIES[tier].id));return d
end
local function fixture(tier)
    local g=require("src.game_state").new("red_deck");g.run=Run.newRun("red_deck")
    g.run.ante=7;g.run.areaStage=7;g.run.regionId="human";g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(7,nil,"human",7)
    local def={};for k,v in pairs(definition) do def[k]=v end;def.sealedSpnTier=tier
    g.run.blinds[3].debuff=def
    local m=Run.createBlindMonster(g.run.blinds[3],g,true);C.start(g,m,7)
    g.deities={};g.backpackDeities={};return g,m
end
for chosen=1,#D.RARITIES do
    local g,m=fixture(chosen)
    for tier=1,#D.RARITIES do
        g.deities[1]=spn(tier)
        assert(B.isSlotLocked(g,"spn",1)==(tier==chosen))
        local count=0;Mimic.each(g,g.deities,1,function() count=count+1 end)
        assert((count==0)==(tier==chosen),"Locked normal SPNs cannot bypass the shared activation gate")
    end
    assert(not B.isSlotLocked(g,"consumable",1))
    g.deities[1]=spn(chosen);B.disable(g,1)
    assert(not B.isSlotLocked(g,"spn",1));m.bossState.passiveUntil=0
    m.hp=0;assert(not B.isSlotLocked(g,"spn",1))
end
for tier=1,#D.RARITIES do
    local d=spn(tier);d.voidPower=5;d.edition="holographic";d.evolutionCredits=3
    local changed,amount=D.downgrade(d,2)
    assert(D.getRarityTier(d)==math.max(1,tier-2) and amount==math.min(2,tier-1) and changed==(tier>1))
    assert(d.voidPower==5 and d.edition=="holographic" and d.evolutionCredits==3)
end
local evolved=spn(1);D.evolve(evolved);D.evolve(evolved);D.evolve(evolved);D.downgrade(evolved,2)
assert(D.getRarityTier(evolved)==2 and evolved.evolutionLevel==1)
local over=spn(10);D.evolve(over);D.evolve(over);D.downgrade(over,2)
local tier,overflow=D.getRarityTier(over);assert(tier==10 and overflow==0)
D.downgrade(over,2);assert(D.getRarityTier(over)==8)

local g,m=fixture(3);g.deities={spn(3)}
local card=require("src.deck").newCard(5,"hearts");g.hand={card}
local info=require("src.poker").evaluate({card},g.unlockedHands,g.handLevels)
local function score() return require("src.scoring").calculate(info,g.deities,{gameState=g,monster=m,hand={},preview=true}).finalScore end
local locked=score();local before=P.encode(g.deities)
score();assert(P.encode(g.deities)==before,"Preview cannot downgrade or alter SPNs")
B.disable(g,1);assert(score()>locked);m.bossState.passiveUntil=0
g.deities={spn(1,"spirit_right_echo"),spn(3)};assert(not Mimic.resolve(g.deities,1,g),"Cannot copy a sealed source")
g.deities={spn(3,"spirit_right_echo"),spn(1)};assert(not Mimic.resolve(g.deities,1,g),"Sealed copier cannot activate")
g.deities={spn(3,"spirit_phantom_heart")};assert(#require("src.spn_elements").pools(g)==0,"Passive HP pools must be sealed too")

g,m=fixture(3);local common,active,bag=spn(1),spn(3),spn(6)
g.deities={[1]=common,[3]=active};g.backpackDeities={bag}
local random=R.random;R.random=function(a,b) return b or a end
B.handEnd(g);R.random=random
assert(D.getRarityTier(bag)==4 and D.getRarityTier(active)==3 and D.getRarityTier(common)==1,"One eligible owned SPN, including the backpack, loses two tiers")
g.backpackDeities={};B.handEnd(g)
assert(D.getRarityTier(active)==1 and not B.isSlotLocked(g,"spn",3),"Leaving the sealed tier releases the SPN immediately")
local remaining=P.encode(g.deities);B.handEnd(g);assert(P.encode(g.deities)==remaining,"All-C inventory is immune")
g.deities[3]=spn(7);B.disable(g,1,true);B.handEnd(g);assert(D.getRarityTier(g.deities[3])==7)
B.handEnd(g);assert(D.getRarityTier(g.deities[3])==5)
local loaded=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"playing")))))
assert(loaded.run.blinds[3].debuff.sealedSpnTier==3 and D.getRarityTier(loaded.deities[3])==5)
C.start(loaded,Run.createBlindMonster(loaded.run.blinds[3],loaded,true),7)
assert(loaded.monster.bossData.sealedSpnTier==3,"Save/load cannot reroll the chosen rarity")
assert(definition.sealedSpnTier==nil,"Do not mutate shared boss definitions")
g,m=fixture(1);g.deities={spn(3)};B.handEnd(g);assert(B.isSlotLocked(g,"spn",1),"Downgrading into the sealed tier applies the lock immediately")
local seen={}
for seed=1,100 do R.seed(seed*104729+17);local x,y=fixture();local picked=y.bossData.sealedSpnTier;assert(picked>=1 and picked<=#D.RARITIES);seen[picked]=true end
for i=1,#D.RARITIES do assert(seen[i],"Every tier C through TT must be selectable") end
print("Rank Inquisitor PASS: all ten rarity locks, scoring/passive/mimic gates, dynamic tier changes, random owned -2 tiers, C floor, TT overflow, counters, permanent metadata and stable save/load")

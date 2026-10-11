local Run=require("src.run_manager")
local E=require("src.expedition")
local Group=require("src.enemy_group")
local Persistence=require("src.persistence")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Scene=require("config.scene_definitions")
local Art=require("src.enemy_art")
local function fresh()
    local g=Game.new("red_deck")
    g.persistentDeck={Deck.newCard(4,"hearts")};g.gold=27
    g.run=Run.newRun(g.selectedFaction);return g
end
local function completeRegion(g)
    for stage=1,20 do
        assert(g.run.areaStage==stage)
        for i=1,3 do
            Run.completeCurrentBlind(g.run,g)
            local wins=g.run.stats.blindsWon
            Run.completeCurrentBlind(g.run,g);assert(g.run.stats.blindsWon==wins)
            local ok,why=Run.advanceBlind(g.run,g)
            assert(stage==20 and i==3 and not ok and why=="victory" or (stage<20 or i<3) and ok)
        end
    end
    assert(g.run.victory and g.run.travelPermit)
end
local checked=0
for _,r in ipairs(E.regions) do
    for stage=1,20 do
        local global=40+stage
        local blinds=Run.generateAnteBlinds(global,"aurelia",r.id,stage)
        for _,b in ipairs(blinds) do
            local m=Run.createBlindMonster(b,{},true)
            for _,member in ipairs(Group.build(m)) do
                assert(member.regionId==r.id and member.areaStage==stage)
                assert(member.cardRank>=2 and member.cardRank<=13)
                if r.id=="human" then
                    assert(member.human and member.neutralHuman and member.cardSuit==nil)
                    assert(member.artKey=="human_"..member.cardRank and Art.key(member)==member.artKey)
                elseif r.suit then assert(member.human and not member.neutralHuman and member.cardSuit==r.suit)
                else assert(not member.human and member.creatureCard and member.enemyAbility) end
                checked=checked+1
            end
            local _,d=Scene.resolve("playing",m)
            assert(d.base==E.area(stage,r.id).background)
        end
        local area=E.area(stage,r.id)
        assert(area.index==math.floor((stage-1)/5)+1)
        if r.areas then assert(E.backgroundPaths[area.background]) end
    end
end
local g=fresh()
assert(not Run.resolveTravel(g.run,g,"sell") and g.gold==27)
completeRegion(g)
local saved=Persistence.makeSnapshot(g,"victory")
local restored,state=Persistence.restoreSnapshot(saved)
assert(state=="victory" and restored.run.regionId=="human" and restored.run.areaStage==20 and restored.run.travelPermit)
local deck=g.persistentDeck;local hp=g.playerHp;local items=g.consumables
assert(not Run.resolveTravel(g.run,g,"bad_destination") and g.run.travelPermit and g.gold==27)
assert(Run.resolveTravel(g.run,g,"sell") and g.gold==1027)
assert(g.run.regionId=="human" and g.run.ante==21 and g.run.areaStage==1 and not g.run.travelPermit and not g.run.victory)
assert(g.persistentDeck==deck and g.consumables==items and g.playerHp==hp)
assert(not Run.resolveTravel(g.run,g,"sell") and not Run.resolveTravel(g.run,g,"hearts") and g.gold==1027)
saved=Persistence.makeSnapshot(g,"BLIND_SELECT")
restored,state=Persistence.restoreSnapshot(saved)
assert(state=="BLIND_SELECT" and not restored.run.travelPermit and restored.run.regionId=="human")
assert(not Run.resolveTravel(restored.run,restored,"sell") and restored.gold==1027)
completeRegion(g)
assert(Run.resolveTravel(g.run,g,"hearts") and g.run.areaStage==1 and g.run.ante==41 and g.gold==1027)
for _,id in ipairs({"diamonds","clubs","spades","human","unknown"}) do
    completeRegion(g)
    assert(Run.resolveTravel(g.run,g,id) and g.run.regionId==id and g.run.areaStage==1 and not g.run.travelPermit)
    saved=Persistence.makeSnapshot(g,"BLIND_SELECT")
    restored,state=Persistence.restoreSnapshot(saved)
    assert(restored.run.regionId==id and restored.run.areaStage==1 and restored.run.ante==g.run.ante)
end
-- Mysterious continent stays endless rather than issuing a human travel permit.
for stage=1,25 do
    for i=1,3 do Run.completeCurrentBlind(g.run,g);assert(Run.advanceBlind(g.run,g)) end
end
assert(g.run.regionId=="unknown" and g.run.areaStage==26 and not g.run.victory and not g.run.travelPermit)
-- Old saves keep cards and progress, without inventing a spendable permit.
saved=Persistence.makeSnapshot(g,"BLIND_SELECT")
saved.game.run.regionId=nil;saved.game.run.areaStage=nil;saved.game.run.ante=26;saved.game.run.travelPermit=true
restored=Persistence.restoreSnapshot(saved)
assert(restored.run.regionId=="human" and restored.run.areaStage==6 and not restored.run.travelPermit and #restored.persistentDeck==1)
print("Journey routing passed: "..checked.." opponent identities, 20-area boundaries, full campaigns, one-time sales, all destinations, inventory and save migration")

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
assert(E.recognitionCount(g)==0 and not E.canEnter(g,"unknown"))
local permits=#g.backpackConsumables
assert(not Run.resolveTravel(g.run,g,"unknown") and #g.backpackConsumables==permits and g.run.ante==20)
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
assert(E.recognitionCount(g)==4 and E.canEnter(g,"unknown"))
assert(g.run.regionStagesWon.hearts==20 and g.run.regionStagesWon.spades==20)
for stage=1,25 do
    for i=1,3 do Run.completeCurrentBlind(g.run,g);assert(Run.advanceBlind(g.run,g)) end
end
assert(g.run.regionId=="unknown" and g.run.areaStage==26 and not g.run.victory and not g.run.travelPermit)
-- Old saves keep cards and progress, without inventing a spendable permit.
saved=Persistence.makeSnapshot(g,"BLIND_SELECT")
saved.game.run.regionId=nil;saved.game.run.areaStage=nil;saved.game.run.ante=26;saved.game.run.travelPermit=true
restored=Persistence.restoreSnapshot(saved)
assert(restored.run.regionId=="human" and restored.run.areaStage==6 and not restored.run.travelPermit and #restored.persistentDeck==1)
local Shop=require("src.shop");local Loadout=require("src.loadout");local Reward=require("src.reward_system")
g=fresh();g.shopMode="consumable";g.gold=1999
local shop=Shop.new();Shop.refresh(shop,g)
local permitIndex;for i,item in ipairs(shop.items) do if item.id=="cons_travel_permit" then permitIndex=i;assert(item.cost==2000 and item.consumable) end end
assert(permitIndex and not Shop.buyItem(shop,permitIndex,g) and #g.backpackConsumables==0)
g.gold=2000;assert(Shop.buyItem(shop,permitIndex,g) and g.gold==0 and #g.backpackConsumables==1)
assert(not Run.beginTravel(g,"backpackConsumables",1,"playing"))
assert(Run.beginTravel(g,"backpackConsumables",1,"shop"))
assert(not Run.resolveTravel(g.run,g,"unknown") and #g.backpackConsumables==1)
saved=Persistence.makeSnapshot(g,"travel");restored,state=Persistence.restoreSnapshot(saved)
assert(state=="travel" and restored.travelRequest and #restored.backpackConsumables==1)
local ok,back=Run.resolveTravel(restored.run,restored,"cancel");assert(ok and back=="shop" and #restored.backpackConsumables==1)
assert(Run.resolveTravel(g.run,g,"hearts") and g.run.ante==1 and g.run.areaStage==1 and #g.backpackConsumables==0)
completeRegion(g);assert(g.run.ante==20 and g.regionRecognitions.hearts and E.recognitionCount(g)==1)
local receipt=Reward.begin(Reward.calculate(Run.getCurrentBlind(g.run),g),g,{lootTableId="normal_enemy"})
local recognized=false;for _,r in ipairs(receipt.loot) do if r.id=="recognition_hearts" then recognized=true end end
assert(recognized and g.pendingJourneyRewards==nil)
Reward.exchangeAll(g,receipt);assert(g.regionRecognitions.hearts)
assert(Run.resolveTravel(g.run,g,"diamonds") and g.run.ante==21 and g.run.areaStage==1)
Loadout.storeConsumable(g,E.travelPermit());assert(Run.beginTravel(g,"backpackConsumables",#g.backpackConsumables,"BLIND_SELECT"))
assert(Run.resolveTravel(g.run,g,"hearts") and g.run.ante==21 and g.run.areaStage==1)
assert(g.regionRecognitions.hearts and g.run.regionStagesWon.hearts==20)
print("Journey routing passed: "..checked.." opponents, global stage 20 -> 21, four permanent recognitions, locked unknown, 2000-gold permit purchase, cancellation, consumption, ceremony, return progress and save migration")

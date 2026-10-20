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
local function finishStage(g)
    for _=1,3 do
        Run.completeCurrentBlind(g.run,g);local wins=g.run.stats.blindsWon
        Run.completeCurrentBlind(g.run,g);assert(g.run.stats.blindsWon==wins)
        assert(Run.advanceBlind(g.run,g))
    end
end
local function completeRegion(g)
    for stage=1,20 do assert(g.run.areaStage==stage);finishStage(g) end
    assert(g.run.difficultyCap and not g.run.victory and E.hasTravelPermit(g))
end
local function travel(g,destination,screen)
    for _,source in ipairs({"backpackConsumables","consumables"}) do
        for i,item in ipairs(g[source] or {}) do if item.id=="cons_travel_permit" then
            assert(Run.beginTravel(g,source,i,screen or "BLIND_SELECT"))
            return Run.resolveTravel(g.run,g,destination)
        end end
    end
    return false
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
                    local expectedArt=member.isBoss and member.bossData and member.bossData.humanBoss and member.bossData.artKey or "human_"..member.cardRank
                    assert(member.artKey==expectedArt and Art.key(member)==expectedArt)
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
assert(not Run.resolveTravel(g.run,g,"sell"))
completeRegion(g)
assert(g.run.ante==21 and g.run.areaStage==20 and g.run.difficultyCap==20 and #g.backpackConsumables==1)
assert(E.recognitionCount(g)==0 and not travel(g,"unknown"))
assert(#g.backpackConsumables==1 and g.run.ante==21)
assert(Run.resolveTravel(g.run,g,"stay") and not g.travelRequest and #g.backpackConsumables==1)
assert(travel(g,"hearts") and g.run.ante==21 and g.run.areaStage==1 and not g.run.difficultyCap and #g.backpackConsumables==0)
completeRegion(g)
assert(g.run.ante==41 and g.run.difficultyCap==40 and g.regionRecognitions.hearts)
local reserved=#g.backpackConsumables;local documents=#g.pendingJourneyRewards
local baseline=Run.generateAnteBlinds(40,g.selectedFaction,"hearts",20,40)
local Loadout=require("src.enemy_loadout")
for _=1,15 do
    for i,blind in ipairs(g.run.blinds) do
        local m=Run.createBlindMonster(blind,g,true);local b=Run.createBlindMonster(baseline[i],g,true)
        assert(blind.ante==g.run.ante and blind.difficultyAnte==40 and blind.hp==baseline[i].hp)
        assert(m.attack==b.attack and m.encounterCount==b.encounterCount and m.cardRank==b.cardRank)
        assert(blind.debuff and blind.debuff.id==baseline[i].debuff.id or not blind.debuff)
        assert(#Group.build(m)==#Group.build(b) and Persistence.encode(Loadout.profile(m))==Persistence.encode(Loadout.profile(b)))
        assert(Persistence.encode(Loadout.generate(m))==Persistence.encode(Loadout.generate(b)))
        require("src.rng").seed(91);local speed=Run.createBlindMonster(blind,g).attackSpeed
        require("src.rng").seed(91);assert(speed==Run.createBlindMonster(baseline[i],g).attackSpeed)
    end
    finishStage(g)
end
assert(g.run.ante==56 and g.run.areaStage==20 and g.run.difficultyCap==40)
assert(#g.backpackConsumables==reserved and #g.pendingJourneyRewards==documents and g.run.regionStagesWon.hearts==20)
local saved=Persistence.makeSnapshot(g,"BLIND_SELECT")
local restored,state=Persistence.restoreSnapshot(assert(Persistence.decode(Persistence.encode(saved))))
assert(state=="BLIND_SELECT" and restored.run.ante==56 and restored.run.difficultyCap==40 and restored.run.blinds[1].hp==baseline[1].hp)
local gold=g.gold;assert(travel(g,"sell") and g.gold==gold+250 and g.run.ante==56 and g.run.difficultyCap==40)
assert(not E.hasTravelPermit(g));restored=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"BLIND_SELECT"))
assert(not E.hasTravelPermit(restored),"Spent permit must never respawn on reload")
local Shop=require("src.shop")
g.shopMode="consumable";g.gold=7999
local shop=Shop.new();Shop.refresh(shop,g)
local index;for i,item in ipairs(shop.items) do if item.id=="cons_travel_permit" then index=i;assert(item.cost==8000) end end
assert(index and not Shop.buyItem(shop,index,g));g.gold=8000;assert(Shop.buyItem(shop,index,g) and g.gold==0)
assert(travel(g,"diamonds") and g.run.ante==56 and not g.run.difficultyCap and g.run.blinds[1].difficultyAnte==56)
for _,id in ipairs({"diamonds","clubs","spades"}) do
    assert(g.run.regionId==id);completeRegion(g)
    assert(g.regionRecognitions[id] and g.run.difficultyCap==g.run.ante-1)
    if id~="spades" then assert(travel(g,id=="diamonds" and "clubs" or "spades")) end
end
assert(E.unlimitedTravel(g) and E.recognitionCount(g)==4)
reserved=#g.backpackConsumables
for _,id in ipairs({"unknown","hearts","diamonds","unknown"}) do
    local ante=g.run.ante;assert(travel(g,id))
    assert(g.run.ante==ante and not g.run.difficultyCap and #g.backpackConsumables==reserved and g.run.blinds[1].difficultyAnte==ante)
end
for _=1,25 do finishStage(g);assert(not g.run.difficultyCap) end
assert(g.run.regionId=="unknown" and #g.backpackConsumables==reserved)
local monster=Run.createBlindMonster(g.run.blinds[1],g);g.monster=monster
assert(Run.beginTravel(g,"backpackConsumables",1,"playing"))
local ok,back=Run.resolveTravel(g.run,g,"stay");assert(ok and back=="playing" and g.monster==monster and #g.backpackConsumables==reserved)
assert(Run.beginTravel(g,"backpackConsumables",1,"playing"))
restored,state=Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"travel"))
assert(state=="travel" and restored.travelRequest.returnState=="BLIND_SELECT")
assert(Run.resolveTravel(g.run,g,"clubs") and not g.monster and #g.backpackConsumables==reserved)
local Reward=require("src.reward_system")
local ceremony=fresh();ceremony.run.regionId="hearts";completeRegion(ceremony)
local result=Reward.begin(Reward.calculate({type="boss",baseReward=5},ceremony),ceremony,{lootTableId="normal_enemy"})
local found=false;for _,r in ipairs(result.loot) do if r.id=="recognition_hearts" then found=true end end;assert(found)
Reward.exchangeAll(ceremony,result);assert(ceremony.regionRecognitions.hearts and E.hasTravelPermit(ceremony))
local legacy=fresh();legacy.run.ante=40;legacy.run.regionId="hearts";legacy.run.areaStage=20;legacy.run.currentBlindIndex=3
legacy.run.blinds=Run.generateAnteBlinds(40,legacy.selectedFaction,"hearts",20);legacy.run.blinds[3].status="completed"
legacy.run.travelPermit=true;legacy.run.victory=true
saved=Persistence.makeSnapshot(legacy,"victory");saved.game.run.travelRulesVersion=nil
restored,state=Persistence.restoreSnapshot(saved)
assert(state=="BLIND_SELECT" and restored.run.ante==41 and restored.run.difficultyCap==40 and E.hasTravelPermit(restored) and restored.regionRecognitions.hearts)
print("Journey PASS: "..checked.." opponents, earned permit stored, stay 41-56 at difficulty 40 (HP/attack/speed/squad/boss/gear), no repeat gifts, resumed scaling after travel, four recognitions/unlimited reuse, combat cancel/travel, purchases and legacy saves")

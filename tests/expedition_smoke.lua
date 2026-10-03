local Run=require("src.run_manager")
local E=require("src.expedition")
local Boss=require("src.boss_abilities")
local Art=require("src.enemy_art")
local Rng=require("src.rng")
local Persistence=require("src.persistence")
local Deck=require("src.deck")
local Scene=require("config.scene_definitions")
local Map=require("src.map")
assert(Run.MAX_ANTE==20)
local g={gold=10,persistentDeck={Deck.newCard(2,"hearts")},deities={},consumables={},selectedFaction="aurelia",playerHp=100,maxPlayerHp=100}
local run=Run.newRun("aurelia");g.run=run
assert(not Run.advanceBlind(run,g) and run.currentBlindIndex==1,"unbeaten encounter cannot advance")
assert(not Run.skipCurrentBlind(run,g) and run.stats.blindsWon==0 and g.gold==10)
local map=Map.generate(1);g.map=map
assert(not Map.skipCombatNode(g,"f1_1") and not map.nodes.f1_1.visited and not map.nodes.f1_1.skipTag)
for stage=1,40 do
    local blinds=Run.generateAnteBlinds(stage,"aurelia")
    for _,b in ipairs(blinds) do
        assert(not b.canSkip and not b.tag and not b.skipPact)
        local state=Rng.getState()
        local m=Run.createBlindMonster(b,g,true)
        assert(Rng.getState()==state,"preview cannot consume RNG")
        assert(m.human and m.cardRank>=2 and m.cardRank<=13 and m.stage==stage)
        local f=assert(io.open(Art.path(Art.key(m)),"rb"));f:close()
        local _,d=Scene.resolve("playing",m)
        assert(d.base==E.region(stage).background)
        if stage>20 and m.isBoss then
            assert(m.bossData.active and m.bossData.active.cooldown==1)
            assert(m.bossData~=Run.BOSS_DEBUFFS[m.bossData.debuffId],"ship variants must not mutate shared bosses")
            g.monster=m;Boss.start(g)
            assert(m.bossState and Boss.passiveDescription(m)~="")
            assert(m.bossData.active.cooldown==1 and m.bossData.active.name==E.shipBoss(stage).skill,"combat startup must preserve ship skills")
        end
    end
end
-- Full campaign: sixty required encounters, one license, victory exactly at 20.
for stage=1,20 do
    assert(run.ante==stage)
    for fight=1,3 do
        Run.completeCurrentBlind(run,g)
        local wins=run.stats.blindsWon
        Run.completeCurrentBlind(run,g)
        assert(run.stats.blindsWon==wins,"victory reward cannot duplicate")
        local ok,why=Run.advanceBlind(run,g)
        if stage==20 and fight==3 then assert(not ok and why=="victory" and run.travelPermit)
        else assert(ok and not run.victory) end
    end
end
assert(run.stats.blindsWon==60)
local saved=Persistence.makeSnapshot(g,"victory")
local restored,state=Persistence.restoreSnapshot(saved)
assert(restored.run.travelPermit and restored.run.maxAnte==20 and state=="victory")
run.endless=true;run.victory=false
assert(Run.advanceBlind(run,g) and run.ante==21)
run.ante=40;run.currentBlindIndex=3;run.blinds=Run.generateAnteBlinds(40)
Run.completeCurrentBlind(run,g);assert(Run.advanceBlind(run,g) and run.ante==41)
for _,b in ipairs(run.blinds) do
    local m=Run.createBlindMonster(b,g,true)
    assert(not m.human and m.stage==41 and m.regionId=="unknown")
    local _,d=Scene.resolve("playing",m);assert(d.base=="mysteriousCoast")
end
local migrated=Persistence.makeSnapshot(g,"BLIND_SELECT")
migrated.game.run.ante=8;migrated.game.run.maxAnte=8;migrated.game.run.endless=false
local old=assert(Persistence.restoreSnapshot(migrated));assert(old.run.maxAnte==20 and not old.run.victory)
migrated.activeState="victory";migrated.game.run.victory=true;migrated.game.run.currentBlindIndex=3
migrated.game.run.blinds[3].status="completed"
local winner,oldState=Persistence.restoreSnapshot(migrated)
assert(winner.run.ante==9 and oldState=="BLIND_SELECT" and not winner.run.victory,"old 8-stage victory must resume the new campaign")
print("Expedition smoke passed: mandatory combat, 60 campaign fights, permit, 20/21/40/41 boundaries, card assets, boss variants, RNG, save migration")

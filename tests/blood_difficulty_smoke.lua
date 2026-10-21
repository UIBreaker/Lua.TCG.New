local S=require("src.ancient_statue")
local Run=require("src.run_manager")
local GS=require("src.game_state")
local Rng=require("src.rng")
local P=require("src.persistence")
local Clone=require("src.blood_shop").clone
local function reload(g,state) return P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,state))))) end
for _,route in ipairs({{ante=2,region="human",area=2},{ante=80,region="hearts",area=20,cap=40},{ante=62,region="unknown",area=22}}) do
    local g=GS.new();g.run=Run.newRun("red_deck")
    local r=g.run;r.ante=route.ante;r.regionId=route.region;r.areaStage=route.area;r.difficultyCap=route.cap
    r.currentBlindIndex=3;r.blinds=Run.generateAnteBlinds(r.ante,"red_deck",r.regionId,r.areaStage,r.difficultyCap);r.blinds[3].status="completed"
    local original=Clone(r);local anchor=route.cap or route.ante
    assert(S.enter(g) and g.run.difficultyCap==anchor)
    for stage=1,8 do
        local b=Run.getCurrentBlind(g.run);local index=stage==8 and 3 or stage==7 and 2 or 1
        local reference=original.blinds[index]
        assert(b.difficultyAnte==anchor and g.run.difficultyCap==anchor)
        assert(b.hp==reference.hp*2,"HP must be x2 the main route, without eight stages of exponential growth")
        local rng=Rng.getState();local base=Run.createBlindMonster(reference,{},false)
        Rng.setState(rng);local blood=Run.createBlindMonster(b,g,false)
        assert(blood.maxHp==base.maxHp*2 and blood.attack==base.attack*2 and blood.attackSpeed==base.attackSpeed*2)
        assert(blood.encounterCount==base.encounterCount and blood.bloodDomainMultiplier==2)
        local mainGame=GS.new();mainGame.run=Clone(original)
        rng=Rng.getState();require("src.combat").start(mainGame,base,route.ante)
        Rng.setState(rng);require("src.combat").start(g,blood,g.run.ante)
        assert(#g.enemies==#mainGame.enemies)
        for i,m in ipairs(g.enemies) do assert(m.attackSpeed==mainGame.enemies[i].attackSpeed*2,"Squad members also need doubled rolled speed") end
        assert(g.bloodDomain.returnRun.ante==original.ante and g.bloodDomain.returnRun.difficultyCap==original.difficultyCap)
        Run.completeCurrentBlind(g.run,g)
        if stage<8 then
            g=reload(g,"shop");assert(g.run.difficultyCap==anchor and Run.getCurrentBlind(g.run).hp==reference.hp*2)
            assert(Run.advanceBlind(g.run,g))
        end
    end
    g=reload(g,"blood_statue");assert(S.claim(g,1) and not S.claim(g,1))
    assert(g.run.ante==original.ante and g.run.regionId==original.regionId and g.run.areaStage==original.areaStage and g.run.difficultyCap==original.difficultyCap)
    for i,b in ipairs(g.run.blinds) do assert(b.hp==original.blinds[i].hp and b.status==original.blinds[i].status) end
    assert(Run.advanceBlind(g.run,g) and g.run.ante==original.ante+1)
    local nextNormal=Run.generateAnteBlinds(g.run.ante,"red_deck",g.run.regionId,g.run.areaStage,g.run.difficultyCap)
    assert(g.run.blinds[1].hp==nextNormal[1].hp and not g.run.blinds[1].bloodDomainMultiplier)
end
local legacy=GS.new();legacy.run=Run.newRun("red_deck");legacy.run.currentBlindIndex=3;legacy.run.blinds[3].status="completed"
S.enter(legacy);legacy.run.difficultyCap=nil
legacy=reload(legacy,"BLIND_SELECT");assert(legacy.run.difficultyCap==1 and Run.getCurrentBlind(legacy.run).hp==100)
print("Blood difficulty PASS: x2 HP/attack/rolled speed for all eight stages and squad members, frozen main-route anchor/cap, save/load and legacy migration, one reward, exact return route without x2 leaking")

local T=require("src.combat_timing")
local C=require("src.combat")
local function fixture()
    local m={hp=1000,maxHp=1000,attack=20,attackSpeed=10,intent={type="attack"}}
    return {monster=m,playerHp=100,maxPlayerHp=100,playerArmor=10,playerShield=10,
        hand={},deities={},lastPlayerAttackSpeed=99999},m
end
local function hazard(game,kind)
    local s=T.start(kind,99999,10,game)
    s.age=s.ready;s.position=(s.hazard.from+s.hazard.to)/2
    assert(T.press(s));return s.result
end
local game,m=fixture();game.timingChains={perfect=20,ultimate=3}
local r=hazard(game,"attack")
assert(r.grade=="riposte" and r.selfReflect and r.chainBroken and not next(game.timingChains))
game.potionCombat={accuracy=true};game.spnAttack={guaranteeHit=true}
local damage,dead,splash,hit=C.resolvePlayerAttack(game,40,{missed=true},r)
assert(damage==0 and not dead and #splash==0 and m.hp==1000)
assert(hit.enemyCounter and hit.damage==30 and hit.absorbed==10 and game.playerHp==70 and game.playerArmor==0)
assert((game.gold or 0)==0 and (game.souls or 0)==0,"enemy counter cannot claim success rewards")
game,m=fixture();game.playerArmor=0;game.playerShield=0;game.playerHp=10
_,_,_,hit=C.resolvePlayerAttack(game,40,nil,hazard(game,"attack"))
assert(game.playerHp==0 and hit.killedPlayer and C.getOutcome(game)=="defeat")
game,m=fixture();game.potionCombat={evasion=true}
local danger=hazard(game,"parry")
assert(danger.grade=="exposed" and danger.reduction==-4)
hit=C.resolveMonsterAttack(game,nil,99999,m,danger)
assert(not hit.missed and hit.damage==90 and hit.absorbed==10 and game.playerHp==10,"x5 hazard bypasses speed/evasion, then respects armor")
game,m=fixture();game.playerArmor=0;game.playerShield=0
hit=C.resolveMonsterAttack(game,nil,99999,m,hazard(game,"parry"))
assert(hit.damage==100 and game.playerHp==0)
assert(not C.resolveMonsterAttack(game,"after",99999,m,danger),"hazard still consumes one enemy action")
local baseline=T.start("attack",99999,10)
local pressured=T.start("attack",99999,10,{timingChains={perfect=20}})
assert(baseline.speed==.95 and math.abs(pressured.speed-.95*1.25)<1e-9)
local rng=require("src.rng")
for cadence=1,3 do
    for _,reverse in ipairs({false,true}) do
        local reference
        for _,fps in ipairs({30,60,144}) do
            local s=T.start("attack",10,10);s.cadence=cadence;s.reverse=reverse
            local previous=reverse and 1 or 0
            local layout={}
            for _,zone in ipairs(s.zones) do layout[zone]={zone.from,zone.to} end
            for _,zone in ipairs({s.apex,s.divine,s.hazard}) do layout[zone]={zone.from,zone.to} end
            local seed=rng.getState()
            for frame=1,fps do
                T.update(s,1/fps)
                assert(reverse and s.position<=previous or not reverse and s.position>=previous,"cadence cannot secretly reverse")
                previous=s.position
                for zone,bounds in pairs(layout) do assert(zone.from==bounds[1] and zone.to==bounds[2],"all targets must stay fixed during the attempt") end
                assert(T.grade(s,(s.zones[4].from+s.zones[4].to)/2)=="critical")
                assert(T.grade(s,(s.zones[7].from+s.zones[7].to)/2)=="ultimate")
                assert(T.grade(s,(s.divine.from+s.divine.to)/2)=="divine")
            end
            assert(rng.getState()==seed,"movement must not consume gameplay randomness")
            if reference then assert(math.abs(s.position-reference)<1e-10) end
            reference=s.position
            s.position=(s.divine.from+s.divine.to)/2;T.press(s)
            local frozen=s.divine.from;T.update(s,.1);assert(s.divine.from==frozen)
        end
    end
end
local V=require("src.timing_vfx")
for _,spec in ipairs({{"enemy_reflect","riposte",.22},{"break","exposed",.045}}) do
    V.clear();local e=V.emit(spec[1],spec[2],630,270);e.age=spec[3]+.02
    assert(V.pause(),"heavy mistakes get a short contact pause")
    local x,y=V.camera();assert(y>0 and math.abs(x)<5 and y<5,"mistake camera stays compact")
    e.reduced=true;assert(not V.pause());x,y=V.camera();assert(x==0 and y==0)
end
V.clear()
print("Timing hazards PASS: enemy counter damage/armor/death, x5 parry bypasses speed/evasion, no rewards, consumed action, compact impact/reduced motion, pressure, cadence and fixed targets at 30/60/144 FPS")

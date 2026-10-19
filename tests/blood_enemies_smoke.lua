local S=require("src.ancient_statue")
local A=require("src.enemy_abilities")
local Art=require("src.enemy_art")
local paths=require("config.continental_asset_paths")
local seen={}
local function fixture(stage)
    local m=S.decorate({hp=1000,maxHp=1000,attack=100,attackSpeed=10,regionId="blood_domain",stage=20+stage,areaStage=stage},stage)
    A.start(m)
    local g={monster=m,enemies={m},playerHp=100,maxPlayerHp=100,gold=20}
    m.group=g.enemies
    return g,m
end
for stage,e in ipairs(S.enemies) do
    assert(not seen[e.key],"Each of the eight stages needs a distinct enemy illustration")
    seen[e.key]=true
    assert(paths[e.key]==Art.path(e.key),"Blood enemy must resolve to canonical Continental art")
    local f=assert(io.open(paths[e.key],"rb"),"Missing production artwork for "..e.key);assert(f:read(8)=="\137PNG\r\n\26\n");f:close()
    local g,m=fixture(stage)
    assert(m.cardRank==e.rank and m.artKey==e.key and m.name==e.name and m.isBoss==(stage==8))
    assert(m.enemyAbility and m.enemyAbility.desc and m.desc)
end
assert(#S.enemies==8 and #Art.blood==8)
local g,m=fixture(1);g.enemies[2]={hp=100}
assert(A.attackBonus(g,m)==20);g.enemies[2].hp=0;assert(A.attackBonus(g,m)==0)
g,m=fixture(2);assert(m.creatureArmor==120);m.creatureArmor=90;A.afterAttack(g,m,10);assert(m.creatureArmor==120)
g,m=fixture(3);A.afterAttack(g,m,10);assert(g.gold==20);A.afterAttack(g,m,10);assert(g.gold==19)
g.gold=0;assert(A.attackBonus(g,m)==15)
g,m=fixture(4);m.hp=500;A.afterAttack(g,m,100);assert(m.hp>500)
for _=1,10 do A.afterAttack(g,m,1000) end
assert(m.hp==850 and A.resources(m).healingLeft==0,"Leech life steal shares finite recovery reserve")
g,m=fixture(5);g.playerHp=40;assert(A.attackBonus(g,m)==0);g.playerHp=39;assert(A.attackBonus(g,m)==35)
g,m=fixture(6);A.afterAttack(g,m,0);assert(not g.enemyPoison)
A.afterAttack(g,m,1);assert(g.enemyPoison==2)
for _=1,10 do A.afterAttack(g,m,1) end;assert(g.enemyPoison==6)
g,m=fixture(7);m.hp=0;assert(A.revive(m) and m.hp==250);m.hp=0;assert(not A.revive(m))
g,m=fixture(8);assert(m.bloodSovereign and not m.creatureKind and not m.bloodExecutioner)
require("src.player_health").heal(g,10);assert(not m.bloodHealTriggers)
g.playerHp=50;require("src.player_health").heal(g,1);assert(m.bloodHealTriggers==1 and m.maxHp==2000)
print("Blood enemies PASS: eight unique Continental PNGs, correct stage/rank, pack/armor/tax/life steal/execution/poison/revival, final boss unchanged")

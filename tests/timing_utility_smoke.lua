local T=require("src.combat_timing")
local C=require("src.combat")
local D=require("src.deck")
local function fixture()
    return {monster={hp=1000,maxHp=1000,attack=20,attackSpeed=10,intent={type="attack"}},
        hand={D.newCard(4,"clubs")},deities={},playerHp=50,maxPlayerHp=100,playerArmor=0,playerShield=0,
        lastPlayerAttackSpeed=10,discardsRemaining=0,maxDiscards=3}
end
local function press(g,kind,grade)
    for _=1,30 do
        local s=T.start(kind,10,10,g)
        assert(#s.utilityZones==2 and s.utilityZones[1].grade~=s.utilityZones[2].grade)
        for _,zone in ipairs(s.utilityZones) do
            assert(T.grade(s,(zone.from+zone.to)/2)==zone.grade)
            if zone.grade==grade then s.age=s.ready;s.position=(zone.from+zone.to)/2;T.press(s);return s.result end
        end
    end
    error("utility not offered: "..grade)
end
local g=fixture();local r=press(g,"attack","siphon")
assert(C.resolvePlayerAttack(g,40,nil,r)==48 and g.playerHp==54)
T.awardSuccess(g,r);assert(g.playerHp==54,"utility rewards are awarded once")
g=fixture();g.monster.creatureArmor=50;r=press(g,"attack","pierce")
assert(C.resolvePlayerAttack(g,40,nil,r)==64 and g.monster.creatureArmor==50,"pierce bypasses normal armor")
g=fixture();local before=D.peekCardAttackSpeed(g.hand[1]);r=press(g,"attack","haste")
C.resolvePlayerAttack(g,40,nil,r);assert(D.peekCardAttackSpeed(g.hand[1])==before+1)
g=fixture();r=press(g,"parry","mend");local hit=C.resolveMonsterAttack(g,nil,10,g.monster,r)
assert(hit.damage==5 and g.playerHp==49,"mend heals 4 after taking the reduced 5 damage")
g=fixture();g.timingChains={reserve=1};r=press(g,"parry","reserve")
C.resolveMonsterAttack(g,nil,10,g.monster,r);assert(g.discardsRemaining==2)
g=fixture();g.discardsRemaining=3;r=press(g,"parry","reserve")
C.resolveMonsterAttack(g,nil,10,g.monster,r);assert(g.discardsRemaining==3)
g=fixture();r=press(g,"parry","rebound");hit=C.resolveMonsterAttack(g,nil,10,g.monster,r)
assert(hit.damage==5 and hit.reflectedDamage==60 and g.monster.hp==940)
g=fixture();g.playerHp=1;r=press(g,"parry","mend");C.resolveMonsterAttack(g,nil,10,g.monster,r)
assert(g.playerHp==0 and not r.successClaimed,"healing reward cannot revive a lethal mistake")
for _,grade in ipairs({"siphon","pierce","haste","mend","reserve","rebound"}) do
    local s=T.start("attack",10,10);s.result={grade=grade,chain=2};s.hold=.1
    assert(require("src.timing_vfx").profiles[grade] and require("src.timing_audio").cue("attack",grade))
end
local names={"siphon","pierce","haste","mend","reserve","rebound"}
for i,grade in ipairs(names) do
    local u=T.utility[grade];assert(u.hint and #u.hint>10 and u.pitch)
    for j=i+1,#names do
        local other=T.utility[names[j]].color;local distance=0
        for k=1,3 do distance=distance+(u.color[k]-other[k])^2 end
        assert(distance>.35^2,"utility palette must separate all six bands")
    end
end
print("Timing utility PASS: six random fixed tactical bands, heal, armor piercing, team haste, discard caps, partial reflection, chains and single payout")

local D=require("src.deities")
local S=require("src.spn_convergence")
local Game=require("src.game_state")
local Poker=require("src.poker")
local Deck=require("src.deck")
local Combat=require("src.combat")
local Persistence=require("src.persistence")
local Scoring=require("src.scoring")
local Rng=require("src.rng")
local function game(id,group)
    local g=Game.new();g.deities={};g.spnCombat={};g.hand={};g.gold=10
    g.handsRemaining=3;g.maxHands=3;g.discardsRemaining=3;g.spnDiscardCap=3
    g.playerHp=80;g.maxPlayerHp=100;g.playerArmor=0
    g.monster={hp=10000,maxHp=10000,attack=10,armor=0,attackSpeed=1}
    if group then
        g.enemies={g.monster,{hp=10000,maxHp=10000,attack=10,armor=0,attackSpeed=1}}
        for i,m in ipairs(g.enemies) do m.group=g.enemies;m.groupIndex=i end
    end
    assert(D.addDeity(g,D.CATALOG[id],5));return g
end
local function hand(ranks,suits)
    local cards={};for i,rank in ipairs(ranks) do
        local c=Deck.newCard(rank,suits and suits[i] or "hearts");c.disableFactionPassives=true;cards[i]=c
    end
    return assert(Poker.evaluate(cards))
end
local function score(g,h,preview)
    return Scoring.calculate(h or hand({3}),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function effect(g,h)
    local d=g.deities[5];return d.onHandScored(h or hand({3}),{gameState=g},d,5)
end
local g=game("spirit_primeval_product");local h=hand({3,3,8})
local preview=score(g,h,true);assert(not g.deities[5].spnGrowth)
assert(score(g,h).finalScore==preview.finalScore)
assert(g.deities[5].spnGrowth.layers==3 and effect(g,h).addChips==12)
score(g,h);assert(g.deities[5].spnGrowth.layers==6)
g=game("spirit_parity")
score(g,hand({2}));assert(g.deities[5].spnGrowth.charge==1)
score(g,hand({3}));assert(g.deities[5].spnGrowth.charge==3)
score(g,hand({3}));assert(g.deities[5].spnGrowth.charge==4)
score(g,hand({2,3}));assert(g.deities[5].spnGrowth.charge==5 and g.deities[5].spnGrowth.pole=="odd")
g=game("spirit_extremes");score(g);assert(g.deities[5].spnGrowth.cracks==5)
g.playerArmor=4;Combat.resolveMonsterAttack(g)
assert(g.deities[5].spnGrowth.cracks==11,"only six actual HP lost add cracks")
assert(effect(g).addFlatDamage==16)
g.monster.attack=500;g.playerHp=3;g.playerArmor=0;Combat.resolveMonsterAttack(g)
assert(g.deities[5].spnGrowth.cracks==14,"lethal loss uses actual remaining HP")
D.evolve(g.deities[5]);local evolved=D.scaleEffect(g.deities[5],effect(g))
assert(evolved.addFlatDamage==28.5 and evolved.message=="VẾT NỨT · 19","evolution scales damage, not the displayed stack counter")
g=game("spirit_hour_product")
for i=1,3 do score(g);assert(g.handsRemaining==3) end
preview=score(g,nil,true);assert(g.handsRemaining==3 and g.deities[5].spnGrowth.sand==3)
assert(score(g).finalScore==preview.finalScore and g.handsRemaining==4 and g.deities[5].spnGrowth.sand==4)
assert(effect(g).addMult==2)
D.evolve(g.deities[5]);g.deities[5].spnGrowth={sand=7};score(g)
assert(g.handsRemaining==5,"evolution refunds one whole hand, never fractional")

-- Persistent growth survives a new battle, reordering, evolution, copies and saves.
local growing=0
for _,row in ipairs(S.entries) do
    if D.CATALOG[row[1]].accumulationMechanic then
        growing=growing+1;g=game(row[1]);score(g)
        local owned=g.deities[5];local old=owned.spnGrowth
        Combat.start(g,{hp=10000,maxHp=10000,attack=10,attackSpeed=1},1)
        assert(owned.spnGrowth==old,row[1].." battle preserves growth")
        local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
        assert(saved.deities[5].spnGrowth and S.describe(saved.deities[5])==S.describe(owned),row[1].." save")
        g.deities[1]=owned;g.deities[5]=nil;score(g)
        assert(owned.spnGrowth~=old,row[1].." growth follows moved instance")
        assert(D.addDeity(g,D.CATALOG[row[1]],5) and not g.deities[5].spnGrowth,"fresh duplicate has independent growth")
    end
end
assert(growing==4)

g=game("spirit_number_grave");g.monster.armor=20
preview=score(g,nil,true);assert(preview.flatDamageBonus==90 and g.monster.armor==20)
assert(score(g).flatDamageBonus==90 and g.monster.armor==5)
assert(score(g).flatDamageBonus==30 and g.monster.armor==0)
g=game("spirit_number_grave");g.monster.creatureArmor=20
preview=score(g,nil,true);assert(preview.flatDamageBonus==90 and g.monster.creatureArmor==20)
score(g);assert(g.monster.creatureArmor==5)
assert(Combat.resolvePlayerAttack(g,10)==5,"burial removes real absorbing armor before the hit")
g=game("spirit_number_grave");g.monster.armor=20
assert(D.addDeity(g,D.CATALOG.spirit_number_grave,1))
preview=score(g,nil,true);assert(preview.flatDamageBonus==120 and g.monster.armor==20)
assert(score(g).flatDamageBonus==120 and g.monster.armor==0,"shared armor budget")
g=game("spirit_reverse_stair");h=hand({3});h.chips=100;h.mult=2;h.scoringCards={}
local actual=score(g,h);assert(actual.totalChips==2 and actual.totalMult==125 and actual.finalScore==250)
assert(D.addDeity(g,D.CATALOG.spirit_pebble,1));actual=score(g,h)
assert(actual.totalChips==2 and actual.totalMult==150)
g.deities[1]=nil;g.deities[5]=nil;D.addDeity(g,D.CATALOG.spirit_reverse_stair,1);D.addDeity(g,D.CATALOG.spirit_pebble,5)
assert(score(g,h).finalScore==2750,"ordering after a swap changes the real formula")
g=game("spirit_three_moons",true);g.playerArmor=10
preview=score(g,hand({3}),true);assert(preview.healHp==10 and g.playerArmor==10)
assert(score(g,hand({3})).healHp==10 and g.playerArmor==0)
assert(score(g,hand({3,3,3})).flatDamageBonus==20)
preview=score(g,hand({2,3,4,5,6}),true);assert(not g.monster.spnSleep and g.discardsRemaining==3)
score(g,hand({2,3,4,5,6}));assert(g.discardsRemaining==2)
assert(Combat.resolveMonsterAttack(g).damage==0 and g.playerHp==80,"whole living group skips one attack each")
g.discardsRemaining=0;assert(not effect(g,hand({2,3,4,5,6})))

g=game("spirit_name_eater",true)
preview=score(g,hand({3,3}),true);assert(g.gold==10 and not g.monster.spnMask)
score(g,hand({3,3}));assert(g.gold==8 and g.monster.spnMask.pct==50)
score(g,hand({3,3}));assert(g.gold==8,"unspent mask is not overwritten")
local other=g.enemies[2];other.hp=3
local attack=Combat.resolveMonsterAttack(g,nil,nil,g.monster)
assert(attack.damage==5 and other.hp==0 and g.playerHp==75,"redirect can kill another monster without recursive reflection")
assert(not effect(g,hand({3,3})),"no mask can buy friendly fire in a solo fight")
g=game("spirit_name_eater",true);g.gold=1;assert(not effect(g,hand({3,3})))
g.gold=10;for _=1,7 do D.evolve(g.deities[5]) end
score(g,hand({3,3}));assert(g.monster.spnMask.pct==100 and D.getDescription(g.deities[5]):find("100%%"))

g=game("spirit_four_seasons",true)
h=hand({3,3,8,9},{"hearts","spades","clubs","diamonds"})
score(g,h,true);assert(next(g.spnCombat)==nil)
score(g,h);local damage,_,hits=Combat.resolvePlayerAttack(g,100)
assert(damage==63 and #hits==1 and hits[1].damage==62,"125 total aura is evenly routed with deterministic remainder")
damage,_,hits=Combat.resolvePlayerAttack(g,100);assert(damage==100 and #hits==0,"portal consumes once")
score(g,h);g.enemies[2].creatureArmor=10
damage,_,hits=Combat.resolvePlayerAttack(g,100);assert(damage==63 and hits[1].damage==52,"each routed hit respects its own defense")

g=game("spirit_missing_orbit")
score(g);assert(g.spnCombat[g.deities[5]].ward==20)
g.monster.attack=30;assert(Combat.resolveMonsterAttack(g).damage==10 and g.playerHp==70)
assert(g.spnCombat[g.deities[5]].debt==20)
preview=score(g,nil,true);assert(g.spnCombat[g.deities[5]].debt==20)
actual=score(g);assert(actual.finalScore==preview.finalScore and actual.flatDamageBonus==-20)
assert(not g.spnCombat[g.deities[5]].ward and not g.spnCombat[g.deities[5]].debt,"repayment cannot rearm itself")
score(g);assert(g.spnCombat[g.deities[5]].ward==20)
g=game("spirit_missing_orbit");g.handsRemaining=1;assert(not effect(g))
g.spnCombat[g.deities[5]]={debt=100000};assert(score(g).finalScore==0,"debt never creates negative damage")

-- All callbacks are preview-pure and locked slots neither grow nor spend.
for _,row in ipairs(S.entries) do
    g=game(row[1],true);g.monster.armor=20;g.playerArmor=10
    h=hand({3,3,8,9},{"hearts","spades","clubs","diamonds"})
    local rng=Rng.getState();preview=score(g,h,true)
    assert(not g.deities[5].spnGrowth and next(g.spnCombat)==nil and g.gold==10 and g.monster.armor==20 and g.playerArmor==10 and Rng.getState()==rng,row[1].." preview purity")
    assert(score(g,h).finalScore==preview.finalScore,row[1].." preview matches commit")
    local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    assert(saved.deities[5].onHandScored and next(saved.spnCombat or {})==nil)
    g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=5,untilHand=1}}
    local growth=g.deities[5].spnGrowth;local armor=g.monster.armor;local gold=g.gold
    score(g,h);assert(g.deities[5].spnGrowth==growth and g.monster.armor==armor and g.gold==gold,row[1].." boss lock")
end
g=game("spirit_primeval_product");g.deities[5].name="Tích Nguyên Sơ";g.deities[5].stat="addChips";g.deities[5].values={value=1};g.deities[5].productMechanic=true
local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(restored.deities[5].name=="Cổ Linh Bồi Tụ" and restored.deities[5].values.value==2 and not restored.deities[5].productMechanic,"old saves receive revised definitions")
assert(#D.getRandomShopPool({},99)==48)
print("SPN rework PASS: 4 persistent growth engines, 6 rule-breaking strategies, costs, save migration, preview purity, locks, damage routing and debt")

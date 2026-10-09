local D=require("src.deities")
local A=require("src.spn_anomalies")
local Combat=require("src.combat")
local Deck=require("src.deck")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Persistence=require("src.persistence")
local Game=require("src.game_state")
local Monster=require("src.monster")
local Rng=require("src.rng")
local function game(id,hp)
    local g=Game.new();g.deities={};g.hand={};g.playerHp=100;g.playerArmor=0
    g.monster={hp=hp or 1000,maxHp=hp or 1000,attack=10,attackSpeed=1}
    g.spnCombat={};g.discardsRemaining=3;g.spnDiscardCap=3;g.handsRemaining=2
    assert(D.addDeity(g,D.CATALOG[id],5))
    return g
end
local function hand(kind)
    local c=Deck.newCard(3,"hearts");c.disableFactionPassives=true
    return {type=Poker.HAND_TYPES[kind or "HIGH_CARD"],scoringCards={c},unscoredCards={}}
end
local function score(g,h,preview)
    return Scoring.calculate(h or hand(),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local g=game("spirit_afterimage")
local _,_,hits=Combat.resolvePlayerAttack(g,100)
assert(#hits==0 and g.monster.hp==900)
_,_,hits=Combat.resolvePlayerAttack(g,20)
assert(#hits==1 and hits[1].damage==35 and g.monster.hp==845)
D.evolve(g.deities[5]);_,_,hits=Combat.resolvePlayerAttack(g,10)
assert(hits[1].damage==10,"floor 52.5% of prior 20 aura")
local other={hp=1000,maxHp=1000,attack=10};g.monster=other
_,_,hits=Combat.resolvePlayerAttack(g,10)
assert(hits[1].enemy==other and hits[1].damage==5,"afterimage follows the new target")

g=game("spirit_reprisal");g.playerArmor=5
local hit=Combat.resolveMonsterAttack(g)
assert(hit.damage==5 and g.monster.hp==997,"reflect actual HP damage, not attack")
g.monster.hp=2;g.playerArmor=0;Combat.resolveMonsterAttack(g)
assert(g.monster.hp==1,"reflection cannot finish the last enemy outside the victory flow")
g=game("spirit_reprisal");g.monster.attack=500
Combat.resolveMonsterAttack(g);assert(g.monster.hp==940,"a lethal 500 attack only removes 100 actual HP")

g=game("spirit_last_pact");g.playerHp=3;g.monster.attack=500
hit=Combat.resolveMonsterAttack(g)
assert(g.playerHp==5 and g.discardsRemaining==0 and not hit.killedPlayer)
g.discardsRemaining=3;hit=Combat.resolveMonsterAttack(g)
assert(hit.killedPlayer,"once per battle, even after discard refunds")
g.playerHp=5;g.discardsRemaining=3;g.deities[1]=g.deities[5];g.deities[5]=nil
assert(Combat.resolveMonsterAttack(g).killedPlayer,"reordering cannot reset a used pact")
g=game("spirit_last_pact");g.discardsRemaining=0;g.monster.attack=500
assert(Combat.resolveMonsterAttack(g).killedPlayer,"pact needs a discard")

g=game("spirit_soul_furnace");g.souls=5
local rng=Rng.getState();local preview=score(g,nil,true)
assert(preview.flatDamageBonus==75 and g.souls==5 and Rng.getState()==rng)
local actual=score(g)
assert(actual.finalScore==preview.finalScore and g.souls==2)
assert(score(g).flatDamageBonus==50 and g.souls==0)
assert(score(g).flatDamageBonus==0,"never spends souls that do not exist")
g=game("spirit_soul_furnace");g.souls=4
assert(D.addDeity(g,D.CATALOG.spirit_soul_furnace,1))
preview=score(g,nil,true);actual=score(g)
assert(preview.flatDamageBonus==100 and actual.flatDamageBonus==100 and g.souls==0,"shared preview soul budget")

g=game("spirit_transmuter")
local h=hand();h.chips=100;h.mult=2;h.scoringCards={}
actual=score(g,h)
assert(actual.totalChips==90 and actual.totalMult==12 and actual.finalScore==1080)
g.deities[1]=D.CATALOG.spirit_pebble;g.deities[5]=D.CATALOG.spirit_transmuter
local chipsFirst=score(g,h).finalScore
g.deities[1],g.deities[5]=g.deities[5],g.deities[1]
assert(score(g,h).finalScore~=chipsFirst,"SPN position changes alchemy")
g=game("spirit_transmuter");for i=1,30 do D.evolve(g.deities[5]) end
actual=score(g,h);assert(actual.totalChips==10 and actual.totalMult==92)

g=game("spirit_archive");g.discardsRemaining=0
score(g,hand("HIGH_CARD"));score(g,hand("HIGH_CARD"));score(g,hand("PAIR"))
assert(g.discardsRemaining==0)
local state=Persistence.encode(g.spnCombat[g.deities[5]])
preview=score(g,hand("STRAIGHT"),true)
assert(g.discardsRemaining==0 and Persistence.encode(g.spnCombat[g.deities[5]])==state)
score(g,hand("STRAIGHT"));assert(g.discardsRemaining==1 and not next(g.spnCombat[g.deities[5]].seen))
for _,kind in ipairs({"PAIR","STRAIGHT","HIGH_CARD"}) do score(g,hand(kind)) end
assert(g.discardsRemaining==2,"a fresh archive cycle can refund again")
g.discardsRemaining=3
for _,kind in ipairs({"PAIR","STRAIGHT","HIGH_CARD"}) do score(g,hand(kind)) end
assert(g.discardsRemaining==3,"refund capped at opening discard allowance")

g=game("spirit_borrowed_turn");h=hand("THREE_OF_A_KIND")
h.scoringCards={Deck.newCard(3,"hearts"),Deck.newCard(3,"hearts"),Deck.newCard(3,"hearts")}
for _,c in ipairs(h.scoringCards) do c.disableFactionPassives=true end
preview=score(g,h,true);assert(g.handsRemaining==2 and g.discardsRemaining==3 and not next(g.spnCombat))
score(g,h);assert(g.handsRemaining==3 and g.discardsRemaining==2)
score(g,h);assert(g.handsRemaining==3 and g.discardsRemaining==2,"one borrowed moment per fight")

g=game("spirit_dream_jailer")
Combat.resolvePlayerAttack(g,10);assert(g.monster.spnSleep==1 and g.playerArmor==4)
local hp=g.playerHp;hit=Combat.resolveMonsterAttack(g);assert(hit.blocked and g.playerHp==hp and g.monster.spnSleep==0)
Combat.resolvePlayerAttack(g,10);assert(g.monster.spnSleep==0 and g.playerArmor==4)
assert(not Combat.resolveMonsterAttack(g).blocked,"does not put the same enemy to sleep twice")

g=game("spirit_abyss_feast",20);g.monster.creatureArmor=10
Combat.resolvePlayerAttack(g,100);assert(g.playerArmor==28 and g.playerShield==28,"40% of actual overkill after armor")
g=game("spirit_abyss_feast",20);g.monster.creatureKind="ancient_skeleton"
Combat.resolvePlayerAttack(g,100);assert(g.monster.hp>0 and g.playerArmor==0,"revival is not a kill")

g=game("spirit_zero_hour");g.playerArmor=30
Combat.resolveMonsterAttack(g);assert(g.spnCombat[g.deities[5]].charged)
preview=score(g,nil,true);assert(g.spnCombat[g.deities[5]].charged)
actual=score(g);assert(actual.finalScore==preview.finalScore and not g.spnCombat[g.deities[5]].charged)
assert(score(g).finalScore<actual.finalScore,"stored amplification is spent once")
g.playerArmor=30;Combat.resolveMonsterAttack(g)
g.deities[1]=g.deities[5];g.deities[5]=nil
local charged=score(g).finalScore
assert(charged>score(g).finalScore,"moving an SPN retains its charge until it is spent")
g=game("spirit_zero_hour");Combat.resolveMonsterAttack(g)
assert(not next(g.spnCombat),"taking HP damage cannot charge zero hour")

-- All ten obey sparse slot locks, metadata snapshots, save/load and battle reset.
for _,row in ipairs(A.entries) do
    g=game(row[1]);g.souls=20;g.playerArmor=30
    g.monster.isBoss=true;Combat.Boss.start(g)
    g.monster.bossState.slotLock={kind="spn",slot=5,untilHand=1}
    local souls,discards=g.souls,g.discardsRemaining
    score(g,nil,true);score(g);Combat.resolvePlayerAttack(g,10);Combat.resolveMonsterAttack(g)
    assert(not next(g.spnCombat) and g.souls==souls and g.discardsRemaining==discards,row[1].." locked")
    local snap=require("src.ux_polish").snapshot(g)
    assert(snap[g.deities[5]][D.CATALOG[row[1]].stat],row[1].." UX metadata")
    g.spnCombat={[g.deities[5]]={used=true,charged=true,aura=999}}
    local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    assert(restored.deities[5].id==row[1] and not restored.spnCombat)
    Combat.start(restored,Monster.create(1,false,false,1),2)
    assert(not next(restored.spnCombat),row[1].." reset")
end
assert(#D.getRandomShopPool({},99)==48)
print("SPN anomalies PASS: all 10 mechanics, costs, order, enemy armor/revival, preview budgets, locks, UX snapshots, save/load and battle reset")

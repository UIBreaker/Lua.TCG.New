local D=require("src.deities")
local V=require("src.spn_velocity")
local Deck=require("src.deck")
local Poker=require("src.poker")
local Game=require("src.game_state")
local Scoring=require("src.scoring")
local Combat=require("src.combat")
local Persistence=require("src.persistence")
local Feel=require("src.scoring_presentation")
local Rng=require("src.rng")
local function hand(ranks,suits)
    local cards={};for i,rank in ipairs(ranks) do
        cards[i]=Deck.newCard(rank,suits and suits[i] or "hearts");cards[i].disableFactionPassives=true
    end
    return assert(Poker.evaluate(cards)),cards
end
local function game(id)
    local g=Game.new();g.deities={};g.hand={};g.spnCombat={};g.handsRemaining=2
    g.monster={hp=10000,maxHp=10000,attackSpeed=15,attack=10}
    g.playerArmor=20;g.playerHp=100;g.discardsRemaining=3;g.spnDiscardCap=3
    assert(D.addDeity(g,D.CATALOG[id],5));return g
end
local function score(g,h,preview,extra)
    local c={gameState=g,monster=g.monster,preview=preview,playerAttackSpeed=10}
    for k,v in pairs(extra or {}) do c[k]=v end
    return Scoring.calculate(h,g.deities,c)
end
local function step(r,id)
    for _,s in ipairs(r.steps) do if s.type=="deity_hand" and s.deity.id==id then return s end end
end
local h,cards=hand({2,10},{"hearts","spades"})
cards[1].speedBonus=2;cards[1].temporarySpeedBonus=1;cards[1].equipments={{attackSpeed=3}}
cards[1].attackSpeed=-99
assert(Deck.peekCardAttackSpeed(cards[1])==18 and cards[1].attackSpeed==-99,"pure speed includes permanent, temporary and equipment bonuses")
assert(V.speed(h,{})==11 and cards[1].attackSpeed==-99,"whole played hand includes its unscored low/high card")
assert(Combat.getAverageAttackSpeed(cards)==11 and cards[1].attackSpeed==-99)
assert(V.speed(h,{playerAttackSpeed=12.5})==12.5,"exact committed initiative includes tactical speed")
assert(V.speed(h,{playerAttackSpeed=10000})==999)
local g=game("spirit_galefang")
assert(step(score(g,h),"spirit_galefang").addedChips==40)
assert(step(score(g,h,nil,{playerAttackSpeed=2.5}),"spirit_galefang").addedChips==10)
D.evolve(g.deities[5]);assert(step(score(g,h),"spirit_galefang").addedChips==60)
g=game("spirit_thunderpulse")
assert(step(score(g,h),"spirit_thunderpulse").addedMult==10)
D.evolve(g.deities[5]);assert(step(score(g,h),"spirit_thunderpulse").addedMult==15)

-- A damage multiplier changes the damage axis at its own slot.
g=game("spirit_slow_colossus");h=hand({3});h.chips=100;h.mult=2;h.scoringCards={}
local r=score(g,h);assert(r.totalChips==200 and r.totalMult==2 and r.finalScore==400 and r.bonusChips==100)
assert(step(r,"spirit_slow_colossus").xChips==2)
assert(g.spnAttack and g.spnAttack.guaranteeHit and not Combat.rollPlayerAttack(g).missed)
assert(Combat.resolvePlayerAttack(g,10,{missed=true,hitChance=0.1})==10,"slow colossus overrides a miss")
g.monster.attackSpeed=10;assert(not step(score(g,h),"spirit_slow_colossus"),"equal speed is not slower")
g.monster.attackSpeed=15;D.evolve(g.deities[5]);assert(score(g,h).totalChips==250)
g=game("spirit_slow_colossus");D.addDeity(g,D.CATALOG.spirit_pebble,1)
assert(score(g,h).totalChips==240)
g.deities[1]=g.deities[5];g.deities[5]=D.CATALOG.spirit_pebble
assert(score(g,h).totalChips==220,"flat damage after versus before the multiplier")
g=game("spirit_twinbeat");h,cards=hand({11,13},{"hearts","spades"})
assert(step(score(g,h),"spirit_twinbeat").xMult==2,"distinct ranks can synchronize")
cards[2].speedBonus=1;assert(not step(score(g,h),"spirit_twinbeat"))
cards[1].equipments={{attackSpeed=1}};assert(step(score(g,h),"spirit_twinbeat").xMult==2)
assert(not step(score(g,hand({3})),"spirit_twinbeat"))

-- Afterstorm multiplies the damage axis and hits every other living enemy.
g=game("spirit_afterstorm")
h=hand({2,4,7,9},{"hearts","spades","clubs","diamonds"})
local baseline=Scoring.calculate(h,{},{});r=score(g,h)
assert(step(r,"spirit_afterstorm").xChips==5 and r.finalScore==baseline.finalScore*5)
local other={hp=10000,maxHp=10000,attack=10,attackSpeed=15}
g.enemies={g.monster,other}
for i,m in ipairs(g.enemies) do m.group=g.enemies;m.groupIndex=i end
local damage,_,hits=Combat.resolvePlayerAttack(g,r.finalScore,{missed=false,hitChance=1})
assert(damage==r.finalScore and #hits==1 and hits[1].enemy==other and other.hp==10000-r.finalScore)
g=game("spirit_afterstorm");local scoredCard=Deck.newCard(3,"hearts")
g.persistentDeck={Deck.cloneCard(scoredCard)};g.hand={scoredCard}
h=hand({3});h.scoringCards={scoredCard};h.unscoredCards={}
r=score(g,h);Combat.resolvePlayerAttack(g,r.finalScore,{missed=true,hitChance=.1})
assert(scoredCard.speedBonus==2 and g.persistentDeck[1].speedBonus==2,"a miss grants permanent speed to scoring cards")
g.monster.attackSpeed=10;assert(not step(score(g,h),"spirit_afterstorm"),"equal speed does not trigger")
g.monster.attackSpeed=15;D.evolve(g.deities[5]);assert(step(score(g,h),"spirit_afterstorm").xChips==7)
g=game("spirit_afterstorm");D.addDeity(g,D.CATALOG.spirit_missing_orbit,1)
g.spnCombat[g.deities[1]]={debt=20};r=score(g,h)
assert(r.auraDebtTotal==20 and r.finalScore==(r.totalChips*r.totalMult)-20,"debt is not multiplied a second time")
local formula=Feel.formula({result=r,ui={formatNumber=tostring}})
assert(formula:find("20 nợ AURA",1,true))

h=hand({2,4,7,9},{"hearts","spades","clubs","diamonds"})
g=game("spirit_last_sun");g.handsRemaining=1
local preview=score(g,h,true);assert(step(preview,"spirit_last_sun").xMult==5 and g.playerArmor==20)
assert(score(g,h).finalScore==preview.finalScore and g.playerArmor==20)
g.playerArmor=0;assert(step(score(g,h),"spirit_last_sun"),"last sun does not require armor")
g.handsRemaining=2;assert(not step(score(g,h),"spirit_last_sun"))
-- Match the actual caller's already-deducted hand count against its preview.
g=game("spirit_last_sun");g.handsRemaining=1;preview=score(g,h,true,{handsAfterPlay=0})
g.handsRemaining=0;r=score(g,h,nil,{handsAfterPlay=0})
assert(r.finalScore==preview.finalScore and step(r,"spirit_last_sun").xMult==5)
g=game("spirit_last_sun");g.handsRemaining=1;D.addDeity(g,D.CATALOG.spirit_borrowed_turn,1)
local borrowedHand=hand({3,3,3})
local borrowedResult=score(g,borrowedHand)
assert(step(borrowedResult,"spirit_last_sun") and g.playerArmor==20 and g.backpackConsumables[1].permanentSpeed,"speed reward stored in backpack leaves the last-hand condition intact")
g=game("spirit_last_sun");g.handsRemaining=1;D.addDeity(g,D.CATALOG.spirit_last_sun,1)
preview=score(g,h,true);assert(preview.finalScore==baseline.finalScore*25)
assert(score(g,h).finalScore==preview.finalScore,"duplicate last suns both apply")

for _,row in ipairs(V.entries) do
    g=game(row[1]);g.handsRemaining=1;h=hand({2,4,7,9},{"hearts","spades","clubs","diamonds"})
    local rng=Rng.getState();preview=score(g,h,true)
    assert(g.playerArmor==20 and next(g.spnCombat)==nil and Rng.getState()==rng,row[1].." preview purity")
    assert(score(g,h).finalScore==preview.finalScore,row[1].." preview and commit")
    D.evolve(g.deities[5]);assert(not D.getDescription(g.deities[5]):find("{",1,true))
    local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
    assert(saved.deities[5].id==row[1] and saved.deities[5].onHandScored and D.getDescription(saved.deities[5])==D.getDescription(g.deities[5]))
    g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=5,untilHand=1}}
    assert(not step(score(g,h),row[1]),row[1].." boss lock")
end
assert(#D.getRandomShopPool({},99)==91)
print("SPN velocity PASS: six cards, guaranteed hit, area damage, miss speed, last hand, save/load, evolution and locks")

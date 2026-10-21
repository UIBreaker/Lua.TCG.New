local N=require("src.combat_notices")
local B=require("src.boss_abilities")
local D=require("src.deities")
local Deck=require("src.deck")
local A=require("src.spn_anomalies")
local g={hand={},deities={},consumables={},spnCombat={},monster={hp=100,isBoss=true,lockedFaction="hearts",bossData={id="test"}}}
local heart,spade=Deck.newCard(7,"hearts"),Deck.newCard(8,"spades")
g.hand={heart,spade}
g.monster.lockedFaction=heart.suit
assert(N.restriction(g,heart)=="VÔ HIỆU" and not N.restriction(g,spade))
spade.disableFactionPassives=false
g.monster.lockedFaction=spade.suit;assert(not B.scoreBlockReason(g.monster,spade),"ordinary axiom immunity")
g.monster.bossData=require("src.kingdom_bosses").definitions[4]
local suit=g.monster.bossData.entitySuit;local sealed=Deck.newCard(8,suit)
assert(B.scoreBlockReason(g.monster,sealed),"entity overrides immunity")
g.monster.bossData={id="test",humanBoss=4};assert(B.scoreBlockReason(g.monster,Deck.newCard(13,"spades")),"court overrides immunity")
g.monster.lockedFaction=nil;g.monster.bossData={id="test",active={op="silence",name="Câm Lặng",description="Khóa kỹ năng",cooldown=1}}
g.monster.bossState={handIndex=1,activeCountdown=1,activeUntil=0,passiveUntil=0,targetId=heart.id}
assert(N.warning(g,heart)=="BOSS NHẮM")
heart.abilityDisabledUntil=1;assert(N.restriction(g,heart)=="KHÓA KỸ NĂNG")
g.monster.bossState.handIndex=2;assert(not N.restriction(g,heart))
g.monster.bossState.targetId=nil
D.addDeity(g,D.CATALOG.spirit_hour_product,1)
D.addDeity(g,D.CATALOG.spirit_right_offering,2)
D.addDeity(g,D.CATALOG.spirit_ember,3)
local clock=g.deities[1];local victim=g.deities[3]
assert(N.warning(g,victim)=="SẮP HIẾN TẾ")
require("src.spn_convergence").discard(g)
assert(clock.spnGrowth.discards==1 and #g.spnFeedback==1)
local anim={floatingTexts={}}
N.update(0,g,"playing",false);A.showFeedback(g,anim)
assert(anim.deityHit[1]==0 and N.inspect(g).hits[clock],"non-score growth pulses physical source")
N.update(.08,g,"playing",false)
local angle,lift=N.pose(clock);assert(angle~=0 and lift<0)
N.update(0,g,"playing",true);angle,lift=N.pose(clock);assert(angle==0 and lift==0)
local before=N.inspect(g).hits[clock].age;N.update(1,g,"playing",false,true)
assert(N.inspect(g).hits[clock].age==before,"pause freezes presentation")
g.monster.bossState.slotLock={kind="spn",slot=1,untilHand=2}
require("src.spn_convergence").discard(g);assert(clock.spnGrowth.discards==1)
assert(N.restriction(g,clock)=="SPN BỊ KHÓA")
g.monster.bossState.slotLock=nil
D.destroyDeity(g,3,true,nil,"HIẾN TẾ THỬ")
A.showFeedback(g,anim)
assert(not g.deities[3] and #N.inspect(g).ghosts==1)
assert(not N.inspect(g).history and not N.inspect(g).current and not N.wheel and not N.containsLog,"no banner, journal or input interception remains")
assert(not D.destroyDeity(g,3,true) and #N.inspect(g).ghosts==1,"no duplicate destruction")
N.update(1,g,"playing",false);assert(#N.inspect(g).ghosts==1,"removed SPN remains visible")
N.update(1.3,g,"playing",false);assert(#N.inspect(g).ghosts==0,"ghost finishes")
g.spnCombat={};N.update(0,g,"playing",false);assert(#N.inspect(g).ghosts==0 and not N.inspect(g).hits[clock],"new encounter resets effects")
local copied={deities={},spnCombat={},hand={},consumables={},monster={hp=100}}
D.addDeity(copied,D.CATALOG.spirit_right_echo,1);D.addDeity(copied,D.CATALOG.spirit_hour_product,2)
require("src.spn_convergence").discard(copied)
assert(copied.spnFeedback[1].deity==copied.deities[1],"copied accumulation identifies the physical copier")
D.addDeity(copied,D.CATALOG.spirit_left_refrain,3)
N.update(0,copied,"playing",false);N.activate(copied.deities[1])
assert(N.inspect(copied).hits[copied.deities[3]],"the repeat helper visibly participates")
local hg={deities={},backpackDeities={},monster={isBoss=true,hp=100,maxHp=100,attack=10,attackSpeed=1,creatureArmor=0,bossData={id="notice7",humanBoss=7,encounterToken="notice7"}}}
D.addDeity(hg,D.CATALOG.spirit_guardian_shell,2)
require("src.human_bosses").start(hg)
assert(not hg.deities[2] and hg.spnFeedback[1].kind=="destroy" and hg.spnFeedback[1].slot==2,"boss deletion enters the destruction presentation")
A.showFeedback(hg,{floatingTexts={}});assert(#N.inspect(hg).ghosts==1)
print("Combat notices PASS: shared score locks/immunity, skill/slot locks, boss target, sacrifice warning, discard accumulation, source pulse, reduced motion, pause, urgent destruction and ghost lifetime")

local T=require("src.combat_timing")
local C=require("src.combat")
local G=require("src.game_state")
local D=require("src.deck")
local P=require("src.persistence")
local function fixture()
    local g=G.new("red_deck")
    g.deities={};g.hand={};g.playerHp=1000;g.maxPlayerHp=1000;g.playerArmor=0;g.lastPlayerAttackSpeed=10
    g.monster={hp=1000000,maxHp=1000000,attack=16,attackSpeed=10,intent={type="attack"}}
    return g
end
local function press(g,grade,kind)
    local bar=T.start(kind or "parry",10,10,g)
    local zone=grade=="divine" and bar.divine or grade=="apex" and bar.apex
    for _,z in ipairs(bar.zones) do if z.grade==grade then zone=z;break end end
    bar.age=bar.ready;bar.position=grade=="trap" and bar.zones[6].from+.005 or zone and (zone.from+zone.to)/2 or 0
    assert(T.press(bar));assert(not T.press(bar),"holding input cannot advance a chain")
    assert(bar.result.grade==grade)
    return bar.result
end
local g=fixture()
for n=1,4 do
    local timing=press(g,"critical")
    g.playerArmor=0;g.playerShield=0
    local hit=C.resolveMonsterAttack(g,nil,10,g.monster,timing)
    assert(timing.chain==n and hit.parryArmor==4*n,"armor reward must be rounded first, then multiplied by its chain")
    if n==2 then press(g,"perfect");assert(g.timingChains.critical==2) end
end
local saved=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
assert(saved.timingChains.critical==4 and saved.timingChains.perfect==1)
C.start(saved,require("src.monster").create(1,false,false,1),1)
assert(press(saved,"critical","attack").chain==5,"chains survive both save/load and battle changes")
press(saved,"trap");assert(next(saved.timingChains)==nil,"red clears every band chain")
assert(press(saved,"critical").chain==1)
press(saved,"normal");assert(next(saved.timingChains)==nil)
press(saved,"ultimate")
local timeout=T.start("attack",10,10,saved);T.update(timeout,timeout.ready+timeout.duration+.01)
assert(next(saved.timingChains)==nil,"timeout also breaks the chains")
assert(next(G.new("red_deck").timingChains)==nil,"a new run starts fresh")
g=fixture();g.gold=0;g.souls=0
for n=1,3 do
    local timing=press(g,"ultimate","attack")
    local damage,_,_,roll=C.resolvePlayerAttack(g,10,nil,timing)
    assert(damage==40*n and roll.timingSouls==5*n and timing.rewardGold==5*n)
    local gold,souls=g.gold,g.souls
    assert(T.awardSuccess(g,timing)==0 and g.gold==gold and g.souls==souls)
end
local white=press(g,"apex");T.awardSuccess(g,white);assert(g.timingRewardMultiplier==2)
white=press(g,"apex");T.awardSuccess(g,white);assert(g.timingRewardMultiplier==4)
local firstRuby=press(g,"divine");T.awardSuccess(g,firstRuby)
assert(g.timingRewardMultiplier==4,"different rare grades use the highest ceremony bonus, never multiply together")
press(g,"trap");assert(g.timingRewardMultiplier==4,"already-earned ceremony bonus survives a broken chain")
g=fixture()
local a=D.newCard(5,"clubs");local b=D.newCard(7,"hearts")
g.persistentDeck={a,b};g.hand={D.cloneCard(a),D.cloneCard(b)}
local spirit={id="spirit_life_bloom",rarity="common",evolutionLevel=0}
local reserve={id="spirit_fleet_wind",rarity="common",evolutionLevel=0}
g.deities={spirit,spirit};g.backpackDeities={reserve}
for n=1,2 do
    local ruby=press(g,"divine");T.awardSuccess(g,ruby)
    local levels=n==1 and 1 or 3
    assert(spirit.evolutionLevel==levels and reserve.evolutionLevel==levels,"all owned physical SPNs evolve once per payout")
    assert(a.evolutionLevel==levels and b.evolutionLevel==levels and g.hand[1].evolutionLevel==levels)
    assert(ruby.evolvedSpn==2 and ruby.evolvedCards==2)
end
local R=require("src.reward_system")
g=fixture();g.monster=nil;g.gold=0;g.souls=0;g.handsRemaining=0;g.maxInterest=0;g.timingRewardMultiplier=4
g.lastRoundDeityRewards={bonusGold=0,details={}}
R.config.tables.timing_chain_test={rolls={1,1},entries={{id="gold_bonus",weight=1}}}
local breakdown=R.calculate({type="small",baseReward=3},g,false)
assert(breakdown.totalGold==12 and breakdown.timingBonus==9)
local payout=R.begin(breakdown,g,{lootTableId="timing_chain_test"})
local count,gold=0,0
for _,loot in ipairs(payout.loot) do if loot.type=="GOLD" then count=count+1;gold=gold+loot.amount end end
assert(count==4 and g.gold==12+gold and payout.earnedSouls==4 and g.souls==4)
local wallet=g.gold;assert(R.begin(breakdown,g)==payout and g.gold==wallet and g.souls==4)
assert(g.timingRewardMultiplier==1,"ceremony consumes the combat boost")
local resumed=assert(P.restoreSnapshot(P.makeSnapshot(g,"CASH_OUT")))
local resumedGold,resumedSouls=resumed.gold,resumed.souls
assert(R.begin(breakdown,resumed)==resumed.pendingVictoryReward)
assert(resumed.gold==resumedGold and resumed.souls==resumedSouls,"resuming a multiplied ceremony cannot pay twice")
assert(R.calculate({type="small",baseReward=3},g,true).timingMultiplier==1)
print("Timing chains PASS: per-band retention/reset, cross-mode armor/damage scaling, save/battle persistence, fixed gold/souls, highest ceremony payout, unique evolution and transaction idempotency")

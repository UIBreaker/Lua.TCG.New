local B=require("src.spn_bounty")
local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Reward=require("src.reward_system")
local Rng=require("src.rng")
local P=require("src.persistence")
local Config=Reward.config
-- Ticket drops are tested separately; they must not change these exact loot counts.
local voidConfig=require("config.void_gacha")
local ticketChance=voidConfig.ticketChance
voidConfig.ticketChance=0
local blind={type="small",baseReward=3,name="Test"}
local function game(owned)
    local g=Game.new();g.deities={};g.gold=10;g.handsRemaining=2;g.selectedFaction="aurelia"
    g.persistentDeck={Deck.newCard(5,"hearts")};g.masterDeck=g.persistentDeck
    g.monster={hp=0,maxHp=100,attack=1};g.enemies={g.monster};g.lastRoundDeityRewards={bonusGold=0,details={}}
    if owned then assert(D.addDeity(g,D.CATALOG[B.id],1)) end;return g
end
local function forced(g,id)
    Config.tables.bounty_test={rolls={1,1},entries={{id=id,weight=1}}}
    return Reward.begin(Reward.calculate(blind,g),g,{lootTableId="bounty_test"})
end
local g=game(true);local rng=Rng.getState()
local bonus=B.bonus(g);assert(bonus.extraRolls==1 and bonus.rareWeightPct==100 and Rng.getState()==rng)
D.evolve(g.deities[1]);bonus=B.bonus(g);assert(bonus.extraRolls==2 and bonus.rareWeightPct==150)
assert(D.getDescription(g.deities[1]):find("+2",1,true) and D.getDescription(g.deities[1]):find("150%",1,true))
D.evolve(g.deities[1]);bonus=B.bonus(g);assert(bonus.extraRolls==3 and bonus.rareWeightPct==200)
local pool={{id="gold_bonus",weight=90},{id="spn_pack",weight=10}}
local function pick(at,bonus)
    return Reward.weighted(pool,function() return at end,function(e) return B.weight(e,e.weight,bonus) end)
end
assert(pick(.85)=="gold_bonus" and pick(.85,{rareWeightPct=100})=="spn_pack")
assert(pick(.80,{rareWeightPct=100})=="gold_bonus" and pick(.80,{rareWeightPct=150})=="spn_pack")
for _,id in ipairs({"spn_pack","itm_pack","chest","rare_reward","evolution","soul_reaper"}) do
    assert(B.weight({id=id},10,{rareWeightPct=100})==20)
end
assert(B.weight({id="card_pack"},10,{rareWeightPct=100})==10)
assert(B.weight({id="spn_pack"},0,{rareWeightPct=100})==0)

g=game(true);local result=forced(g,"playing_card")
assert(#result.loot==2 and #g.persistentDeck==3 and result.spnLootBonus.extraRolls==1,"actual bonus cards granted, not only presentation")
local saved=P.encode(P.makeSnapshot(g,"CASH_OUT"));local gold=g.gold;local rng=Rng.getState()
assert(Reward.begin(Reward.calculate(blind,g),g)==result and Rng.getState()==rng and #g.persistentDeck==3)
local anim=Reward.newAnimation(result.breakdown,result);Reward.finishImmediately(anim);Reward.finishImmediately(anim)
assert(g.gold==gold and Rng.getState()==rng and #g.persistentDeck==3)
local restored=assert(P.restoreSnapshot(assert(P.decode(saved))))
assert(restored.deities[1].onVictoryLoot and restored.pendingVictoryReward.spnLootBonus.extraRolls==1)
local loaded=P.encode(P.makeSnapshot(restored,"CASH_OUT"))
Reward.begin(Reward.calculate(blind,restored),restored)
assert(loaded==P.encode(P.makeSnapshot(restored,"CASH_OUT")) and Rng.getState()==rng,"saved ceremony never rerolls or grants twice")
g=game(true);D.evolve(g.deities[1]);assert(#forced(g,"gold_bonus").loot==3)
g=game();assert(#forced(g,"gold_bonus").loot==1)
g=game();g.backpackDeities={D.CATALOG[B.id]};assert(#forced(g,"gold_bonus").loot==1)
g=game(true);g.monster.hp=100;g.monster.isBoss=true
g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(B.bonus(g).extraRolls==0)
g.monster.hp=0;assert(B.bonus(g).extraRolls==1,"victory releases boss slot locks")
g=game(true);rng=Rng.getState()
local skipped=Reward.begin(Reward.calculate(blind,g,true),g)
assert(#skipped.loot==0 and not skipped.spnLootBonus and Rng.getState()==rng)

g=game(true);g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1])
bonus=B.bonus(g);assert(bonus.extraRolls==3 and bonus.rareWeightPct==300,"two copied activations plus source")
g=game(true);g.deities[1].evolutionLevel=10000;bonus=B.bonus(g)
assert(bonus.extraRolls==32 and bonus.rareWeightPct==2000 and #forced(g,"gold_bonus").loot==33,"bounded quantity even at extreme evolution")
g=game(true);g.deities[1].bloodPower=5;bonus=B.bonus(g)
assert(bonus.extraRolls==5 and bonus.rareWeightPct==500)
assert(D.getDescription(g.deities[1]):find("500%",1,true))

-- Rarity carries into nested chests; bonus quantity never multiplies recursively.
local chest=Config.tables.golden_chest
Config.tables.golden_chest={rolls={2,2},entries={{id="gold_bonus",weight=90},{id="evolution",weight=10}}}
local random=Rng.random
Rng.random=function(a,b) if a then return a end;return .85 end
g=game(true);result=forced(g,"rare_reward")
Rng.random=random;Config.tables.golden_chest=chest
assert(#result.loot==2 and #g.backpackConsumables==4)
for _,r in ipairs(result.loot) do assert(#r.children==2 and r.children[1].id=="evolution" and r.children[2].id=="evolution") end

-- All ordinary boss overrides use the same extra-roll path.
for _,tableId in ipairs({"boss","tax","memory","gate"}) do
    g=game(true);local data=Config.tables[tableId]
    result=Reward.begin(Reward.calculate(blind,g),g,{lootTableId=tableId})
    assert(#result.loot>=data.rolls[1]+1 and #result.loot<=data.rolls[2]+1)
end
g=game();g.gold=100
assert(require("src.shop").buyItem({items={{category="deity",deity=D.CATALOG[B.id],cost=4}}},1,g))
assert(require("src.loadout").move(g,"spn","reserve",1,1,false));D.evolve(g.deities[1])
restored=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")))
assert(B.bonus(restored).extraRolls==2 and B.bonus(restored).rareWeightPct==150)
Config.tables.bounty_test=nil
voidConfig.ticketChance=ticketChance
assert(#D.getRandomShopPool({},999)==100)
print("SPN bounty PASS: extra real grants, exact rare/evolved weights, chest inheritance/no recursive quantity, all boss tables, caps/copies/blood, no skip/reserve/locked effect, replay/save/fast-forward/RNG/shop")

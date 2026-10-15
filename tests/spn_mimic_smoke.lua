local D=require("src.deities")
local M=require("src.spn_mimic")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local Rng=require("src.rng")
local Persistence=require("src.persistence")
local function game(id,level)
    local g=Game.new();g.deities={};g.hand={};g.souls=10;g.gold=100;g.discardsRemaining=3;g.handsRemaining=3
    g.monster={hp=10000,maxHp=10000,armor=40,attack=1,attackSpeed=10}
    g.persistentDeck={Deck.newCard(3,"hearts"),Deck.newCard(4,"spades"),Deck.newCard(5,"clubs")}
    assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));assert(D.addDeity(g,D.CATALOG[id],2))
    for i=1,level or 0 do D.evolve(g.deities[1]) end
    return g
end
local h=assert(Poker.evaluate({Deck.newCard(3,"hearts")}))
local function score(g,preview) return Scoring.calculate(h,g.deities,{gameState=g,monster=g.monster,preview=preview,playerAttackSpeed=5}) end
local function steps(r,slot,key)
    local sum,count=0,0
    for _,s in ipairs(r.steps) do if s.type=="deity_hand" and s.slotIndex==slot then sum=sum+(s[key] or 0);count=count+1 end end
    return sum,count
end
local g=game("spirit_pebble");local copy=g.deities[1];local source=g.deities[2]
local r=score(g);assert(steps(r,1,"addedChips")==20 and steps(r,2,"addedChips")==20 and g.deities[1]==copy)
D.evolve(copy);r=score(g);local bonus,count=steps(r,1,"addedChips");assert(bonus==40 and count==2)
D.evolve(source);r=score(g);assert(steps(r,1,"addedChips")==60 and steps(r,2,"addedChips")==30,"source evolution controls copied strength")
g=game("spirit_twin_fang",1);r=score(g);g.deities={};local base=score(g)
assert(r.totalChips==base.totalChips*8,"two copied multipliers and the source multiply sequentially")
g=game("spirit_blade",1);r=score(g);assert(r.bonusChips>=30)
local ordinary=game("spirit_blade");ordinary.deities[1]=nil
assert(r.finalScore-score(ordinary).finalScore==20*r.totalMult,"per-card ability copied twice")

-- Never skip an empty right slot; direction remains fixed and chains terminate.
g=game("spirit_pebble");g.deities[3]=g.deities[2];g.deities[2]=nil
assert(not D.resolveDeity(g.deities,1) and select(2,steps(score(g),1,"addedChips"))==0)
g=game("spirit_pebble",1);g.deities[3]=g.deities[2]
g.deities[2]={};for k,v in pairs(D.CATALOG.spirit_right_echo) do g.deities[2][k]=v end
D.evolve(g.deities[2]);r=score(g);assert(select(2,steps(r,1,"addedChips"))==4 and select(2,steps(r,2,"addedChips"))==2)
g.deities[2]=g.deities[1];assert(not D.resolveDeity(g.deities,1),"malformed cyclic alias is inert")
g=game("spirit_pebble");g.deities[1].evolutionLevel=1000;assert(select(2,M.resolve(g.deities,1))==128)

g=game("spirit_pebble");g.monster.isBoss=true
for _,slot in ipairs({1,2}) do
    g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=slot,untilHand=1}}
    assert(select(2,steps(score(g),1,"addedChips"))==0,"lock on copier or source prevents copying")
end
g=game("spirit_pebble");local owned=g.deities[1]
local ok=pcall(M.each,g,g.deities,1,function() error("intentional callback error") end)
assert(not ok and g.deities[1]==owned,"physical owner restored after error")

g=game("spirit_soul_furnace",1);g.souls=7;r=score(g)
assert(steps(r,1,"soulCost")==6 and steps(r,2,"soulCost")==1 and g.souls==0,"each activation pays from one shared budget")
g=game("spirit_number_grave",1);local armorPreview=score(g,true);r=score(g)
assert(g.monster.armor==0 and r.finalScore==armorPreview.finalScore and steps(r,1,"addFlatDamage")==180,"armor is drained once across repeated activations")
g=game("spirit_wayfarer",1);g.consumables={}
local originalRandom=Rng.random;local rolls=0
Rng.random=function(max) rolls=rolls+1;return max and 1 or 0 end
score(g);Rng.random=originalRandom
assert(rolls==6 and #g.consumables==3,"copier rolls independently each activation, then original source")

g=game("spirit_primeval_product",1);local preview=score(g,true)
assert(not g.deities[1].mimicGrowth and not g.deities[2].spnGrowth,"preview has no live growth writes")
r=score(g);assert(r.finalScore==preview.finalScore)
assert(g.deities[1].mimicGrowth.spirit_primeval_product.layers==2 and g.deities[2].spnGrowth.layers==1)
score(g);assert(g.deities[1].mimicGrowth.spirit_primeval_product.layers==4 and g.deities[2].spnGrowth.layers==2)
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")));saved.monster=g.monster
assert(saved.deities[1].mimicGrowth.spirit_primeval_product.layers==4 and saved.deities[1].evolutionLevel==1)
score(saved);assert(saved.deities[1].mimicGrowth.spirit_primeval_product.layers==6 and saved.deities[2].spnGrowth.layers==3)

g=game("spirit_ward",1);Combat.start(g,require("src.monster").create(1,false,false,1),1)
assert(g.playerArmor==30,"two copied start bonuses plus source")
g=game("spirit_coin",1)
local reward=require("src.reward_system").calculate({reward=4},g,false)
assert(reward.deityBonus==6,"win abilities use the same activation count")
g=game("spirit_last_remnant",1);g.discardsRemaining=1
local victim=Deck.cloneCard(g.persistentDeck[1]);A.discard(g,{victim},{playerDiscard=true,remainingBefore=1})
assert(#g.persistentDeck==6 and #g.discardPile==3,"copying discard creates two copies then the original's copy")
g=game("spirit_dawn_reaper",1);victim=Deck.cloneCard(g.persistentDeck[1])
A.discard(g,{victim},{playerDiscard=true,remainingBefore=3});assert(victim.destroyed and g.souls==13 and #g.persistentDeck==2,"cannot repeat a destroyed sacrifice")
g=game("spirit_meteor_solitude");assert(not require("src.spn_legacy").canPlay(g,2))
g=game("spirit_parity",1);require("src.spn_anomalies").enemyAttack(g,g.monster,5)
assert(g.deities[1].mimicGrowth.spirit_parity.hits==2 and g.deities[2].spnGrowth.hits==1,"passive enemy-damage growth has a separate copied identity")

g=game("spirit_echo",1)
local other={hp=1000,maxHp=1000};g.monster.armor=0;g.monster.hp=1000;g.monster.maxHp=1000
g.enemies={g.monster,other};g.monster.group=g.enemies;other.group=g.enemies
local _,_,hits=Combat.resolvePlayerAttack(g,10,{missed=false});assert(#hits==3 and other.hp==994,"attack abilities replay twice plus source")
g=game("spirit_legacy_cocoon");g.monster.isBoss=true;g.monster.hp=0
assert(D.addDeity(g,D.CATALOG.spirit_pebble,3));require("src.souls").awardKills(g)
assert(g.deities[1].id~="spirit_right_echo","copied self-sacrifice consumes the copier")

-- Every catalog source can be previewed and scored without changing the physical copier's identity.
for id in pairs(D.CATALOG) do
    g=game(id);local physical=g.deities[1];local rng=Rng.getState();score(g,true)
    assert(g.deities[1]==physical and not physical.mimicGrowth and Rng.getState()==rng,id.." preview purity")
    score(g);assert(g.deities[1]==physical,id.." physical identity")
end
assert(#D.getRandomShopPool({},99)==91)
print("SPN mimic PASS: adjacent/right chains, evolution/source strength, card/hand/start/win/attack/discard/boss events, costs/chance, independent saved growth, locks, bounded aliases and pure previews across all SPNs")

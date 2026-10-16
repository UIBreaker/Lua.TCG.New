local D=require("src.deities")
local T=require("src.spn_predators")
local M=require("src.spn_mimic")
local G=require("src.game_state")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local S=require("src.scoring")
local P=require("src.persistence")
local E=require("src.enemy_abilities")
local Rng=require("src.rng")
local refrain,thief,offering="spirit_left_refrain","spirit_wind_thief","spirit_right_offering"
local function game(ids)
    local g=G.new();g.deities={};g.hand={};g.persistentDeck={};g.deck={};g.discardPile={}
    g.monster={name="Enemy",hp=10000,maxHp=10000,attackSpeed=20,attack=1,armor=0};g.enemies={g.monster}
    for i=1,3 do local c=Deck.newCard(i+2,"spades");c.disableFactionPassives=true
        g.hand[i]=c;g.persistentDeck[i]=Deck.cloneCard(c) end
    g.masterDeck=g.persistentDeck
    for slot,id in ipairs(ids or {}) do assert(D.addDeity(g,D.CATALOG[id],slot)) end
    A.start(g);return g
end
local function info(g)
    return {type=require("src.poker").HAND_TYPES.HIGH_CARD,chips=10,mult=1,scoringCards={g.hand[1]},unscoredCards={g.hand[2]}}
end
local function score(g)
    local h=info(g);A.beginHand(g,h,{g.hand[1],g.hand[2]})
    return S.calculate(h,g.deities,{gameState=g,monster=g.monster})
end
local function near(a,b) assert(math.abs(a-b)<1e-7,tostring(a).." ~= "..tostring(b)) end
local function steps(r,slot,key)
    local sum,count=0,0;for _,s in ipairs(r.steps) do
        if s.type=="deity_hand" and s.slotIndex==slot then sum=sum+(s[key] or 0);count=count+1 end
    end;return sum,count
end
local g=game({"spirit_pebble",refrain});local r=score(g)
assert(steps(r,1,"addedChips")==60 and select(2,steps(r,1,"addedChips"))==3,"two extra source activations")
D.evolve(g.deities[2]);r=score(g);assert(steps(r,1,"addedChips")==80)
D.evolve(g.deities[1]);assert(steps(score(g),1,"addedChips")==120,"source evolution controls repeated strength")
g=game({"spirit_primeval_product",refrain});score(g)
assert(g.deities[1].spnGrowth.layers==6 and not g.deities[2].spnGrowth,"repeats grow the one real source for both played cards")
g=game({refrain,"spirit_pebble"});assert(select(2,steps(score(g),2,"addedChips"))==1,"cannot repeat itself or redirect to the right")
g=game({"spirit_pebble",refrain});g.deities[3]=g.deities[2];g.deities[2]=nil;g.deities[2]=g.deities[1];g.deities[1]=nil
assert(select(2,M.resolve(g.deities,2,g))==3,"first occupied slot despite leading gaps")
g=game({"spirit_pebble","spirit_right_echo",refrain});assert(select(2,M.resolve(g.deities,1,g))==5,"copied repeaters add repeats without recursion")
g.deities[3].evolutionLevel=1000;assert(select(2,M.resolve(g.deities,1,g))==128)
g=game({"spirit_right_echo","spirit_pebble",refrain});assert(steps(score(g),1,"addedChips")==60)
g=game({"spirit_ward",refrain});require("src.combat").start(g,require("src.monster").create(1,false,false,1),1)
assert(g.playerArmor==30,"start event replays on its real source")
g=game({"spirit_pebble",refrain});g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=2,untilHand=1}}
assert(steps(score(g),1,"addedChips")==20,"locked repeater is inert")

g=game({thief});local base=Deck.peekCardAttackSpeed(g.hand[1]);score(g)
assert(E.speed(g.monster)==18 and g.hand[1].temporarySpeedBonus==2 and g.hand[2].temporarySpeedBonus==2 and not g.hand[3].temporarySpeedBonus)
near(Deck.peekCardAttackSpeed(g.hand[1]),base+2);score(g)
assert(E.speed(g.monster)==16 and g.hand[1].temporarySpeedBonus==4 and (g.persistentDeck[1].speedBonus or 0)==0,"steal once per hand including unscored cards")
local owned=g.deities[1];assert(D.destroyDeity(g,1,true))
assert(g.hand[1].speedBonus==4 and g.hand[2].speedBonus==4 and g.persistentDeck[1].speedBonus==4 and g.hand[1].temporarySpeedBonus==0)
near(Deck.peekCardAttackSpeed(g.hand[1]),base+4);T.destroyed(g,owned);assert(g.hand[1].speedBonus==4,"conversion cannot double claim")
local saved=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert(saved.persistentDeck[1].speedBonus==4)
g=game({thief});D.evolve(g.deities[1]);score(g);assert(E.speed(g.monster)==17 and g.hand[1].temporarySpeedBonus==3)
g=game({thief});g.monster.attackSpeed=2;score(g);assert(E.speed(g.monster)==1 and g.hand[1].temporarySpeedBonus==1)
score(g);assert(g.hand[1].temporarySpeedBonus==1,"cannot mint speed when enemy is at its floor")
g=game({thief,refrain});score(g);assert(E.speed(g.monster)==14 and g.hand[1].temporarySpeedBonus==6)
g=game({"spirit_right_echo",thief});score(g);assert(g.hand[1].temporarySpeedBonus==4)
assert(D.destroyDeity(g,1,true));assert(g.hand[1].speedBonus==2 and g.hand[1].temporarySpeedBonus==2,"copier owns only its stolen share")
g=game({thief});score(g);assert(require("src.shop").sellDeity(g,1));assert((g.persistentDeck[1].speedBonus or 0)==0,"selling is not combat destruction")
g=game({thief});score(g);assert(require("src.loadout").move(g,"spn","equipped",1,nil,false));assert((g.persistentDeck[1].speedBonus or 0)==0,"reserve is not destruction")
g=game({thief});score(g);D.destroyDeity(g,1,false);assert((g.persistentDeck[1].speedBonus or 0)==0,"out-of-combat removal never converts")
g=game({"spirit_right_echo",thief});score(g);D.destroyDeity(g,2,false)
assert(D.addDeity(g,D.CATALOG.spirit_phantom_heart,2));g.playerHp=1
require("src.shop").payItem({currency="blood",cost=1000},g)
assert(not g.deities[1] and (g.persistentDeck[1].speedBonus or 0)==0,"a copier depleted in the blood shop cannot crystallize its old stolen speed")
g=game({thief});score(g);saved=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));assert((saved.persistentDeck[1].speedBonus or 0)==0 and not saved.persistentDeck[1].temporarySpeedBonus)
g=game({thief});g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
score(g);assert(E.speed(g.monster)==20 and not g.hand[1].temporarySpeedBonus)

g=game({offering,thief});r=score(g)
assert(not g.deities[2] and g.deities[1].spnGrowth.offeringMult==.5 and g.hand[1].speedBonus==2,"steal before offering converts immediately")
assert(select(2,steps(r,2,"addedChips"))==0,"consumed SPN has no later scored activation")
near(r.totalMult,1.5);score(g);assert(g.deities[1].spnGrowth.offeringMult==.5,"empty right slot cannot grow")
D.evolve(g.deities[1]);assert(D.addDeity(g,D.CATALOG.spirit_pebble,2));r=score(g)
near(g.deities[1].spnGrowth.offeringMult,1.25);near(r.totalMult,2.25)
saved=assert(P.restoreSnapshot(P.makeSnapshot(g,"shop")));near(saved.deities[1].spnGrowth.offeringMult,1.25)
assert(D.getDescription(saved.deities[1]):find("2.25",1,true))
g=game({offering,"spirit_pebble"});g.deities[3]=g.deities[2];g.deities[2]=nil;score(g);assert(g.deities[3] and not g.deities[1].spnGrowth,"must not skip a gap")
g=game({offering,"spirit_pebble"});g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=2,untilHand=1}}
score(g);assert(g.deities[2] and not g.deities[1].spnGrowth,"cannot consume locked victim")
g=game({"spirit_right_echo",offering});score(g)
assert(g.deities[1].id=="spirit_right_echo" and not g.deities[2] and g.deities[1].mimicGrowth[offering].offeringMult==.5,"copier consumes its own right neighbor and owns growth")
for _,ids in ipairs({{thief},{offering,thief},{"spirit_primeval_product",refrain},{"spirit_right_echo",offering}}) do
    g=game(ids);local h=info(g);local before=P.encode(P.makeSnapshot(g,"shop"));local rng=Rng.getState()
    local preview=S.calculate(h,g.deities,{gameState=g,monster=g.monster,preview=true})
    assert(before==P.encode(P.makeSnapshot(g,"shop")) and rng==Rng.getState() and E.speed(g.monster)==20 and not g.spnCombat,"pure preview")
    r=score(g);near(r.finalScore,preview.finalScore)
end
for _,row in ipairs(T.entries) do
    g=game();g.gold=100
    assert(require("src.shop").buyItem({items={{category="deity",deity=D.CATALOG[row[1]],cost=4}}},1,g))
    assert(require("src.loadout").move(g,"spn","reserve",1,1,false));assert(D.evolve(g.deities[1]))
end
assert(#D.getRandomShopPool({},99)==96)
print("SPN predators PASS: shared source repeats/evolution/gaps/chains/caps/locks; speed steal/every played card/floor/ownership/hidden permanent destruction; per-hand adjacent offering/saved growth/upgrade; pure preview/shop/reserve/save")
return true

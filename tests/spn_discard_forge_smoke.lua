local D=require("src.deities")
local Game=require("src.game_state")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local S=require("src.spn_discard")
local Rng=require("src.rng")
local Persistence=require("src.persistence")
local function game()
    local g=Game.new();g.deities={};g.playerArmor=0;g.playerShield=0;g.hand={}
    g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
    assert(D.addDeity(g,D.CATALOG.spirit_discard_forge,1));return g
end
local function cards(values)
    local list={};for _,value in ipairs(values) do local c=Deck.newCard(3,"spades");c.baseChips=value;c.disableFactionPassives=true;list[#list+1]=c end;return list
end
local function discard(g,values,context)
    g.playerArmor=0;g.playerShield=0
    local list=cards(values);A.discard(g,list,context or {playerDiscard=true,remainingBefore=2});return g.playerArmor,list
end
local g=game();local rng=Rng.getState()
assert(discard(g,{100})==5 and discard(g,{0})==5,"single card always grants five")
assert(discard(g,{6,9,15})==10 and g.playerShield==10,"arithmetic average, not sum or average plus five")
assert(discard(g,{3,4})==3 and discard(g,{0,0})==0)
assert(Rng.getState()==rng,"discard armor uses no RNG")
D.evolve(g.deities[1]);assert(discard(g,{100})==7 and discard(g,{3,4})==5,"multiply before rounding")
assert(D.getDescription(g.deities[1]):find("×1.5",1,true))
D.evolve(g.deities[1]);assert(discard(g,{100})==10 and discard(g,{6,9,15})==20)
assert(discard(g,{6,9,15},{playerDiscard=true,freeDiscard=true})==20)
assert(discard(g,{6,9,15},{playerDiscard=true,bloodPaid=true,remainingBefore=0})==20)
assert(discard(g,{6,9,15},{playerDiscard=true,preview=true})==0)
assert(discard(g,{6,9,15},{})==0,"forced discards do not qualify")
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
saved.monster=g.monster;assert(saved.deities[1].evolutionLevel==2 and discard(saved,{6,9,15})==20)
g=game();local c=Deck.newCard(3,"spades");c.baseChips=18;c.bonusBaseChips=15
local other=Deck.newCard(3,"spades");other.baseChips=nil;other.bonusBaseChips=7
c.equipments={{id="test",onCardScore=function() return {addChips=9999} end}}
g.potionCombat={damageCards={[c.id]=999}}
A.discard(g,{c,other},{playerDiscard=true});assert(g.playerArmor==14,"18 + (3+7), no gear/score/temporary potion damage")
local context={playerDiscard=true,discardBaseDamage={[c.id]=18,[other.id]=10}}
c.baseChips=999;c.destroyed=true;g.playerArmor=0
S.discard(g,{c,other},context);assert(g.playerArmor==14,"use the pre-discard snapshot even after mutation/destruction")
g=game();g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=1,untilHand=1}}
assert(discard(g,{6,9,15})==0)
g=game();g.backpackDeities={g.deities[1]};g.deities={};assert(discard(g,{6,9,15})==0)
g=game();g.deities[2]=g.deities[1];g.deities[1]=nil
assert(D.addDeity(g,D.CATALOG.spirit_right_echo,1));D.evolve(g.deities[1]);D.evolve(g.deities[2])
assert(discard(g,{6,9,15})==45,"two copied activations plus evolved source, each adds fifteen")
g=game();g.playerArmor=998;A.discard(g,cards({100}),{playerDiscard=true});assert(g.playerArmor==999 and g.playerShield==999)
g=game();assert(D.addDeity(g,D.CATALOG.spirit_armor_vitality,2))
assert(discard(g,{6,9,15})==10);g.monster.hp=0;A.combatWin(g)
assert(g.maxPlayerHp==110 and g.playerArmor==0,"discard armor feeds the victory vitality conversion")
g=game();g.deities={};g.gold=100
local shop={items={{category="deity",deity=D.CATALOG.spirit_discard_forge,cost=4}}}
assert(require("src.shop").buyItem(shop,1,g) and #g.backpackDeities==1)
assert(require("src.loadout").move(g,"spn","reserve",1,1,false));assert(discard(g,{6,9,15})==10)
assert(#D.getRandomShopPool({},99)==80)
print("SPN discard forge PASS: flat single reward, arithmetic multi average, evolution/rounding, damage snapshots/upgrades, free/blood/forced/preview, caps, locks/reserves/mimic and save")

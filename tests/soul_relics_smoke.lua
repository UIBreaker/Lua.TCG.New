local G=require("src.game_state")
local E=require("src.equipment")
local D=require("src.deck")
local A=require("src.card_abilities")
local R=require("src.soul_relics")
local Combat=require("src.combat")
local Scoring=require("src.scoring")
local P=require("src.persistence")
local Effects=require("src.card_effects")
local function fixture(id)
    local g=G.new()
    local c=D.newCard(8,"valoria");c.disableFactionPassives=true
    assert(E.attach(c,E.ITEMS[id]))
    g.persistentDeck={c};g.hand={D.cloneCard(c)};g.deck={};g.discardPile={}
    g.monster={hp=1000,maxHp=1000,attack=10,attackSpeed=1,armor=0}
    g.enemies={g.monster}
    A.start(g)
    return g,g.hand[1]
end
local function score(g,c,others)
    local cards={c};for _,o in ipairs(others or {}) do cards[#cards+1]=o end
    local info={type={id="high_card",baseChips=5,baseMult=1},chips=5,mult=1,scoringCards=cards,unscoredCards={}}
    A.beginHand(g,info,cards)
    g.hand={};g.discardPile=cards
    local result=Scoring.calculate(info,{}, {gameState=g,monster=g.monster,playerHp=g.playerHp,maxPlayerHp=g.maxPlayerHp})
    A.finishHand(g)
    return result
end
assert(#R.definitions==10 and #E.SOUL_POOL==15)
-- Revival must intercept the real incoming damage path, once per combat.
local g,c=fixture("soul_phoenix_lantern")
g.playerHp=3;Combat.resolveMonsterAttack(g);assert(g.playerHp==50)
g.playerHp=3;Combat.resolveMonsterAttack(g);assert(g.playerHp==0)
A.start(g);g.playerHp=3;Combat.resolveMonsterAttack(g);assert(g.playerHp==50)
-- Stasis charges expire and cannot be replenished by repeats or later hands.
g,c=fixture("soul_frost_bell");score(g,c)
local hp=g.playerHp
assert(Combat.resolveMonsterAttack(g).blocked and Combat.resolveMonsterAttack(g).blocked)
Combat.resolveMonsterAttack(g);assert(g.playerHp<hp)
local before=g.soulRelicCombat.freeze;score(g,c);assert(g.soulRelicCombat.freeze==before)
-- Targeted draw moves a single existing instance; it does not clone or recycle.
g,c=fixture("soul_rift_compass")
local weak,strong=D.newCard(2,"elaris"),D.newCard(14,"aurelia")
g.deck={strong,weak};score(g,c)
assert(g.hand[1]==strong and #g.deck==1 and g.deck[1]==weak)
-- Return owns exactly one instance in exactly one pile.
g,c=fixture("soul_return_chain");score(g,c)
assert(#g.hand==1 and g.hand[1]==c and #g.discardPile==0)
-- Echo enqueues two repeats for each neighbor but never recursively echoes.
g,c=fixture("soul_echo_mirror")
local left,right=D.newCard(2,"aurelia"),D.newCard(4,"elaris")
local info={type={id="high_card"},scoringCards={left,c,right},unscoredCards={}}
local ctx=A.beginHand(g,info,info.scoringCards);ctx.index=2
R.score(g,c,ctx);assert(#ctx.queue==7 and ctx.repeats[left.id]==2 and ctx.repeats[right.id]==2)
ctx.retrigger=true;R.score(g,c,ctx);assert(#ctx.queue==7)
-- Growth writes back to the canonical card and is limited to one per battle.
g,c=fixture("soul_evolution_quill")
local target=D.newCard(5,"elaris");g.persistentDeck[#g.persistentDeck+1]=target
local live=D.cloneCard(target);score(g,c,{live})
assert(live.evolutionLevel==1 and target.evolutionLevel==1)
score(g,c,{live});assert(target.evolutionLevel==1)
-- Boss lock covers both kinds of skills; it cannot keep extending on retriggers.
g,c=fixture("soul_silence_anchor")
g.monster.isBoss=true;g.monster.bossData={id="the_water",debuffId="the_water"}
local Boss=require("src.boss_abilities");Boss.start(g)
score(g,c);local bs=Boss.state(g.monster)
assert(bs.passiveUntil>0 and bs.activeUntil==bs.passiveUntil)
local untilTurn=bs.activeUntil;score(g,c);assert(bs.activeUntil==untilTurn)
-- Poison takes three ticks, honors real damage reduction and awards souls on death.
g,c=fixture("soul_plague_chalice");score(g,c)
Combat.resolveMonsterAttack(g);Combat.resolveMonsterAttack(g);Combat.resolveMonsterAttack(g)
assert(g.monster.hp==760 and g.monster.soulPoisonTurns==0)
Combat.resolveMonsterAttack(g);assert(g.monster.hp==760)
-- Contract counts each final death once; revival is not a kill.
g,c=fixture("soul_reaper_contract");score(g,c)
g.monster.creatureKind="ancient_skeleton";g.monster.maxHp=100
Combat.resolvePlayerAttack(g,2000);assert(g.monster.hp==25 and g.souls==0)
Combat.resolvePlayerAttack(g,2000);assert(g.souls==3)
R.reap(g);assert(g.souls==3)
local other={hp=0};g.enemies[#g.enemies+1]=other;R.reap(g);assert(g.souls==6)
-- Edition crafting needs three distinct suits, preserves negative/poly and saves.
g,c=fixture("soul_edition_prism")
local x,y=D.newCard(2,"aurelia"),D.newCard(4,"elaris")
score(g,c,{x});assert(not Effects.getEffectName(c))
score(g,c,{x,y});assert(Effects.getEffectName(c)=="foil" and Effects.getEffectName(g.persistentDeck[1])=="foil")
score(g,c,{x,y});assert(Effects.getEffectName(c)=="foil")
A.start(g);score(g,c,{x,y});assert(Effects.getEffectName(c)=="holographic")
local loaded=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(Effects.getEffectName(loaded.persistentDeck[1])=="holographic" and not loaded.soulRelicCombat)
for _,id in ipairs(E.SOUL_POOL) do assert(E.ITEMS[id].soulOnly) end
print("Soul relics passed: 10 distinct mechanics, battle limits, piles, clones, kills, crafting and persistence")

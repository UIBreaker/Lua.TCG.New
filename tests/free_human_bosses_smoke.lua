local W=require("src.free_human_bosses")
local G=require("src.game_state")
local D=require("src.deck")
local Run=require("src.run_manager")
local C=require("src.combat")
local B=require("src.boss_abilities")
local A=require("src.card_abilities")
local P=require("src.persistence")
local R=require("src.rng")
local function fixture(def)
    local g=G.new("red_deck");g.run=Run.newRun("red_deck")
    g.run.ante=7;g.run.areaStage=7;g.run.regionId="human";g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(7,"red_deck","human",7);g.run.blinds[3].debuff=def
    local m=Run.createBlindMonster(g.run.blinds[3],g,true);C.start(g,m,7)
    assert(m.human and m.name==def.name and m.artKey==def.artKey and not m.cardSuit)
    return g,m
end
local g,m=fixture(W.definitions[1]);g.unlockedHands={high_card=true,pair=true,flush=false}
local function finish(id)
    W.finishHand(g,{handInfo={type={id=id}},played={}});B.handEnd(g)
end
assert(not W.handBlocked(g,"high_card"));finish("high_card")
assert(g.playerHp>0 and W.handBlocked(g,"high_card") and not W.handBlocked(g,"pair"))
assert(W.notice(m):find(require("src.poker").HAND_TYPES.HIGH_CARD.vnName,1,true))
local info=require("src.poker").evaluate({D.newCard(3,"hearts")},g.unlockedHands,g.handLevels)
local result=require("src.scoring").calculate(info,{}, {gameState=g,monster=m,hand=g.hand,preview=true})
assert(result.finalScore==0,"Locked formation preview must report zero")
finish("pair");assert(g.playerHp==0,"Only unlocked formations count toward instant defeat")
g,m=fixture(W.definitions[1]);g.unlockedHands={high_card=true};m.hp=0;finish("high_card");assert(g.playerHp>0,"Killing the boss on the final available formation wins")
g,m=fixture(W.definitions[1]);g.unlockedHands={high_card=true,pair=true};finish("high_card")
B.disable(g,1,true);assert(not W.handBlocked(g,"high_card"));finish("pair");assert(g.playerHp>0,"Passive/active counters must work")
C.start(g,Run.createBlindMonster(g.run.blinds[3],g,true),7);assert(not W.handBlocked(g,"high_card"),"Formation seals reset per battle")

g,m=fixture(W.definitions[2]);local c=D.newCard(5,"spades");c.evolutionLevel=3
g.persistentDeck={D.cloneCard(c)};g.hand={c};g.deck={};g.discardPile={}
assert(not W.blocked(m,c),"Unplayed card starts unsealed")
-- Record a previous battle in this area, then encounter the archivist.
W.finishHand(g,{handInfo={type={id="high_card"}},played={c}})
C.start(g,Run.createBlindMonster(g.run.blinds[3],g,true),7)
m=g.monster;local sealed=g.persistentDeck[1];local other=D.newCard(5,"spades")
assert(W.blocked(m,sealed) and B.isAbilityDisabled(g,sealed) and not W.blocked(m,other))
g.hand={sealed};g.deck={};g.discardPile={}
sealed.equipments={require("src.equipment").instance("basic_steel_tip")};sealed.seal="seal_bounty"
info=require("src.poker").evaluate({sealed},g.unlockedHands,g.handLevels)
local before=P.encode(g.areaPlayedCards)
result=require("src.scoring").calculate(info,{}, {gameState=g,monster=m,hand={},preview=true})
assert(before==P.encode(g.areaPlayedCards) and not result.hasBountySeal)
for _,step in ipairs(result.steps) do if step.type=="card_scored" then assert(step.addedChips==0 and step.addedMult==0) end end
B.handEnd(g);assert(sealed.evolutionLevel==2 and g.persistentDeck[1].evolutionLevel==2)
B.handEnd(g);assert(sealed.evolutionLevel==1,"Exactly one downgrade per turn")
B.disable(g,1,true);B.handEnd(g);assert(sealed.evolutionLevel==1)
B.handEnd(g);B.handEnd(g);assert(sealed.evolutionLevel==0,"No negative evolution levels")
local loaded=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"playing")))))
assert(loaded.run.blinds[3].debuff.id==W.definitions[2].id and loaded.areaPlayedCards.ids[c.id])
C.start(loaded,Run.createBlindMonster(loaded.run.blinds[3],loaded,true),7)
assert(W.blocked(loaded.monster,loaded.persistentDeck[1]),"Area seals survive loading")
g.run.ante=8;C.start(g,Run.createBlindMonster(g.run.blinds[3],g,true),8)
assert(not W.blocked(g.monster,sealed),"New area clears old card seals")

g,m=fixture(W.definitions[2]);c=D.newCard(5,"spades");c.evolutionLevel=2
g.hand={c};g.deck={};g.discardPile={};g.persistentDeck={D.cloneCard(c)}
info=require("src.poker").evaluate({c},g.unlockedHands,g.handLevels)
A.beginHand(g,info,{c},{})
assert(not W.blocked(m,c),"First play must resolve before the new seal")
A.finishHand(g);assert(W.blocked(m,c) and c.evolutionLevel==1,"Real hand lifecycle records then downgrades once")
A.finishHand(g);assert(c.evolutionLevel==1,"Repeated finish callbacks cannot downgrade twice")

for _,region in ipairs({"human","hearts","diamonds","clubs","spades","unknown","voyage"}) do
    local seen={}
    for seed=1,300 do
        R.seed(seed);local state=R.getState();local blind=Run.generateAnteBlinds(7,nil,region,7)[3]
        assert(R.getState()==state);seen[blind.debuff.id]=true
    end
    for _,def in ipairs(W.definitions) do assert(seen[def.id],"Missing free human boss in "..region) end
end
assert(not Run.generateAnteBlinds(8,nil,"blood_domain",8)[3].debuff.freeHumanBoss)
print("Free human bosses PASS: unlocked formation seals/defeat/counters, per-area card identity/history, score/ability/gear/seal mute, permanent bounded devolution, all regions and save/load")

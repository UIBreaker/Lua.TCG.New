local Deck=require("src.deck")
local Shop=require("src.shop")
local Game=require("src.game_state")
local Combat=require("src.combat")
local A=require("src.card_abilities")
local S=require("src.scoring")
local P=require("src.persistence")
local Poker=require("src.poker")
local function fixture(id)
    local g=Game.new();g.playerHp=50;g.maxPlayerHp=100;g.gold=10
    g.playerArmor=0;g.playerShield=0;g.handsRemaining=3;g.discardsRemaining=3
    local cs={}
    for i=1,5 do cs[i]=Deck.newCard(5,"aurelia");cs[i].disableFactionPassives=true end
    cs[1].seal=id;g.hand=cs;g.persistentDeck=cs;g.masterDeck=cs
    g.deck={};g.discardPile={};g.deities={};g.monster={hp=1000,maxHp=1000,armor=8,attackSpeed=1}
    A.start(g);return g,cs
end
local function score(g,cs,preview,held)
    return S.calculate({type=Poker.HAND_TYPES.HIGH_CARD,chips=10,mult=2,scoringCards=cs,unscoredCards={}}, {},
        {gameState=g,monster=g.monster,hand=held or {},preview=preview})
end
assert(#Shop.SEAL_CARDS==10 and #Shop.getPackContents("seal")==10)
local catalog=require("src.collection").getItems("seals")
assert(#catalog==10)
local seen={}
for _,id in ipairs(Deck.SEAL_ORDER) do
    local d=assert(Deck.SEALS[id]);assert(not seen[d.symbol]);seen[d.symbol]=true
    assert(d.sealType==id and d.desc and Deck.getModifierDescription("seal",id):find("{",1,true)==nil)
    assert(require("ui.components.seal_emblems").shapes[d.symbol])
    local g,cs=fixture(id)
    local before=P.encode({g.playerHp,g.gold,g.handsRemaining,g.discardsRemaining,g.depthCombat,g.combatFlags,cs,g.monster})
    score(g,cs,true)
    assert(before==P.encode({g.playerHp,g.gold,g.handsRemaining,g.discardsRemaining,g.depthCombat,g.combatFlags,cs,g.monster}),id.." mutated preview")
end
-- Multiple Blood owners can each trigger once, and cannot pay lethal costs.
local g,cs=fixture("seal_blood");cs[2].seal="seal_blood"
assert(score(g,{cs[1],cs[2]}).hpCost==6)
assert(score(g,{cs[1],cs[2]}).hpCost==0)
g,cs=fixture("seal_blood");g.playerHp=3;assert(score(g,{cs[1]}).hpCost==0)
g.playerHp=4;assert(score(g,{cs[1]}).hpCost==3)
-- Two Sunder owners break armor, then switch to damage; the preview agrees.
g,cs=fixture("seal_sunder");cs[2].seal="seal_sunder"
local pre=score(g,{cs[1],cs[2]},true);local live=score(g,{cs[1],cs[2]})
assert(g.monster.armor==0 and live.bonusChips==22 and pre.finalScore==live.finalScore)
-- Holding matching ranks rewards a deliberate split between played and held cards.
g,cs=fixture("seal_lantern")
assert(score(g,{cs[1]},false,{cs[2]}).bonusChips==21)
assert(score(g,{cs[1]},false,{cs[2],cs[3],cs[4],cs[5]}).bonusChips==53)
-- Shared preparation pays one burst; repeating a suit adds no progress.
g,cs=fixture("seal_echoes")
for i,suit in ipairs(Deck.SUIT_ORDER) do cs[i].seal="seal_echoes";cs[i].suit=suit;A.discard(g,{cs[i]}) end
assert(score(g,{cs[1]}).xMultTotal==1.75 and score(g,{cs[1]}).xMultTotal==1)
-- Extra discard and extra attack cannot be farmed by adding more stamped cards.
g,cs=fixture("seal_reclaimer");cs[2].seal="seal_reclaimer"
A.discard(g,{cs[1],cs[2]});assert(g.gold==10 and g.discardsRemaining==3)
g.gold=1;A.discard(g,{cs[1]});assert(g.gold==1 and g.discardsRemaining==3)
g.gold=10;A.discard(g,{cs[1]});A.discard(g,{cs[2]});assert(g.gold==8 and g.discardsRemaining==4)
g,cs=fixture("seal_gambit");cs[2].seal="seal_gambit"
score(g,{cs[1]});assert(g.playerHp==50 and g.handsRemaining==3)
g.playerHp=6;score(g,cs);assert(g.playerHp==6 and g.handsRemaining==3)
g.playerHp=7;score(g,cs);assert(g.playerHp==1 and g.handsRemaining==4)
score(g,cs);assert(g.playerHp==1 and g.handsRemaining==4)
g,cs=fixture("seal_blood");cs[2].seal="seal_gambit";g.playerHp=9
assert(score(g,cs).hpCost==3 and g.playerHp==9 and g.handsRemaining==3)
-- Healing advances on actual scores; previews do not charge the next beat.
g,cs=fixture("seal_threshold")
assert(score(g,{cs[1]}).healHp==0);assert(score(g,{cs[1]}).healHp==0)
assert(score(g,{cs[1]},true).healHp==8);assert(score(g,{cs[1]}).healHp==8)
assert(score(g,{cs[1]}).healHp==0)
-- Purifying always supports defense, and saves its cleanse for a live Boss.
g,cs=fixture("seal_purifying")
Combat.onMonsterTurnEnd(g);assert(g.playerArmor==4 and not g.combatFlags.purifyingSealUsed)
g.monster.bossData={id="the_needle"};Combat.onMonsterTurnEnd(g)
assert(g.playerArmor==8 and g.monster.bossDebuffCleansed and g.combatFlags.purifyingSealUsed)
for _,c in ipairs(cs) do c.seal="seal_purifying" end
Combat.onMonsterTurnEnd(g);assert(g.playerArmor==20 and g.playerShield==20)
g.playerArmor=A.config.armorCap;Combat.onMonsterTurnEnd(g);assert(g.playerArmor==A.config.armorCap)
local hp=g.playerHp;local armor=g.playerArmor
score(g,cs);assert(g.playerArmor==armor and g.playerHp==hp)
-- Every retired stamp migrates on both upgraded cards and stored consumables.
local retired=0
for old,new in pairs(Deck.RETIRED_SEALS) do
    retired=retired+1;assert(not Deck.SEALS[old])
    g,cs=fixture(old);cs[1].bonusBaseChips=20;cs[1].baseChips=25;cs[1].seedChips=20;cs[1].evolutionLevel=3
    g.consumables={{id=old,sealType=old,category="seal",cost=9}}
    g.rewardPacks={{pack={packType="seal"},cards={{id=old,sealType=old},{id=new,sealType=new}}}}
    local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"));local c=restored.persistentDeck[1]
    assert(c.seal==new and c.baseChips==25 and c.evolutionLevel==3 and c.seedChips==20)
    assert(restored.consumables[1].id==new and restored.consumables[1].cost==9 and #restored.rewardPacks[1].cards==1)
end
assert(retired==16)
-- Applying a new stamp replaces Anchor in every pile, including discarded copies.
g,cs=fixture("seal_anchor");g.deck={Deck.cloneCard(cs[1])};g.discardPile={Deck.cloneCard(cs[1])}
assert(Deck.applySeal(g,cs[1],"seal_lantern"))
assert(g.deck[1].seal=="seal_lantern" and not g.deck[1].isAnchor)
assert(g.discardPile[1].seal=="seal_lantern" and not g.discardPile[1].isAnchor)
assert(not Deck.applySeal(g,cs[1],"unknown"))
g,cs=fixture("seal_anchor");g.maxHandSize=1
Combat.start(g,{hp=100,maxHp=100,armor=0},1)
assert(g.hand[1].id==cs[1].id and g.hand[1].seal=="seal_anchor")
g,cs=fixture("seal_bounty");cs[2].seal="seal_bounty"
assert(score(g,{cs[1],cs[2]}).hasBountySeal and Deck.SEALS.seal_bounty.params.gold==2)
for i=1,150 do
    local pack=Shop.openPack({packType="seal"},Game.new());local ids={};assert(#pack.cards==3)
    for _,d in ipairs(pack.cards) do assert(Deck.SEALS[d.id] and not ids[d.id]);ids[d.id]=true end
end
print("PASS: 10 seals, costs, shared turn caps, preview parity, defense and 16 save migrations")

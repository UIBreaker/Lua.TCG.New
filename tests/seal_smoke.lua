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
local function score(g,cs,preview,held,unscored)
    return S.calculate({type=Poker.HAND_TYPES.HIGH_CARD,chips=10,mult=2,scoringCards=cs,unscoredCards=unscored or {}}, {},
        {gameState=g,monster=g.monster,hand=held or {},preview=preview})
end
assert(#Shop.SEAL_CARDS==10 and #Shop.getPackContents("seal")==10)
local catalog=require("src.collection").getItems("seals")
assert(#catalog==10)
local Description=require("src.card_description")
local sealOffers=0
for _,offer in ipairs(Shop.getRetailConsumables()) do
    if offer.category=="seal" then
        sealOffers=sealOffers+1
        local effect=Deck.getModifierDescription("seal",offer.id)
        for _,item in ipairs({offer,offer.consumable,Deck.SEALS[offer.id]}) do
            local title,body=Description.resolve(item)
            assert(title==offer.name and body:find(effect,1,true),offer.id.." missing seal effect")
            assert(not body:find("{",1,true),offer.id.." unresolved seal parameters")
            assert(#require("ui.components.card_description").model(item,title,body).rows>=2)
        end
        assert(offer.desc==offer.consumable.desc and offer.desc:find(effect,1,true))
    end
end
assert(sealOffers==10)
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
-- Blood repeats only equipment twice extra and pays three HP once per hand.
local E=require("src.equipment")
local g,cs=fixture("seal_blood");cs[2].seal="seal_blood"
cs[1].equipments={E.ITEMS.gem_fire};cs[2].equipments={E.ITEMS.gem_fire}
local before=P.encode(g);local pre=score(g,{cs[1],cs[2]},true)
assert(P.encode(g)==before)
local actual=score(g,{cs[1],cs[2]})
assert(actual.hpCost==3 and actual.bonusChips==10+6*E.ITEMS.gem_fire.params.edge)
assert(actual.finalScore==pre.finalScore and actual.hpCost==pre.hpCost)
assert(score(g,{cs[1],cs[2]}).hpCost==3,"Blood must work again on a later hand")
g,cs=fixture("seal_blood");assert(score(g,{cs[1]}).hpCost==0,"no equipment means no retrigger cost")
cs[1].equipments={E.ITEMS.gem_fire}
local unscored=score(g,{cs[2]},false,{}, {cs[1]})
assert(unscored.hpCost==3 and unscored.bonusChips==5+3*E.ITEMS.gem_fire.params.edge)
-- Sunder destroys all armor and adds ten percent of the target's maximum HP per scored owner.
g,cs=fixture("seal_sunder");cs[2].seal="seal_sunder";g.monster.armor=99999
pre=score(g,{cs[1],cs[2]},true);actual=score(g,{cs[1],cs[2]})
assert(g.monster.armor==0 and actual.flatDamageBonus==200 and pre.finalScore==actual.finalScore)
assert(score(g,{cs[1]}).flatDamageBonus==100)
-- Lantern counts held same-suit cards rather than ranks, and excludes every played card.
g,cs=fixture("seal_lantern");cs[2].rank=9;cs[3].suit="diamonds";cs[4].suit="clubs"
assert(score(g,{cs[1]},false,{cs[1],cs[2],cs[3],cs[4]}, {cs[3]}).totalMult==18)
assert(score(g,{cs[1]},false,{cs[2],cs[3]}).totalMult==34)
-- Shield and Compass activate ONLY from true held cards. Unscored played cards are not held.
g,cs=fixture("seal_purifying");cs[2].seal="seal_purifying";cs[3].seal="seal_purifying";g.maxPlayerHp=750
assert(score(g,{cs[1]},false,cs,{cs[2]}).addArmor==75)
assert(score(g,{cs[1]},false,{}, {cs[2],cs[3]}).addArmor==0)
assert(score(g,{cs[4]},false,{cs[1],cs[2],cs[3]}).addArmor==225,"held armor must not inherit the equipment cap of 30")
local armor=g.playerArmor;Combat.onMonsterTurnEnd(g);assert(g.playerArmor==armor,"no second armor grant after an enemy turn")
g,cs=fixture("seal_echoes");cs[2].seal="seal_echoes"
assert(score(g,{cs[3]},false,{cs[1],cs[2]}).totalMult==8)
assert(score(g,{cs[1]},false,{cs[1],cs[2]},{cs[2]}).totalMult==2)
-- Reclaimer pays four gold for every discarded marked card on every discard.
g,cs=fixture("seal_reclaimer");cs[2].seal="seal_reclaimer"
A.discard(g,{cs[1],cs[2]});assert(g.gold==18 and g.discardsRemaining==3)
A.discard(g,{cs[1]});assert(g.gold==22)
A.discard(g,{cs[1]},{preview=true});assert(g.gold==22)
-- Gambit frees all-marked selections, including zero remaining discards, but not mixed selections.
g,cs=fixture("seal_gambit");cs[2].seal="seal_gambit";g.discardsRemaining=0
local pacts=require("src.spn_pacts")
g.selectedIndices={1,2};assert(Deck.freeSealDiscard(g) and pacts.canDiscard(g))
local hpBefore=g.playerHp;assert(pacts.payDiscard(g)==false and g.playerHp==hpBefore)
g.selectedIndices={1,3};assert(not Deck.freeSealDiscard(g) and not pacts.canDiscard(g))
assert(not Deck.freeSealDiscard(g,{}))
-- Exercise the real discard handler, including the UI payment/turn path.
local file=assert(io.open("main.lua","r"));local source=file:read("*a");file:close()
local start=assert(source:find("local function discardSelected()",1,true))
local stop=assert(source:find("local function destroyHandCard",start,true))
local function discardLive(game)
    local env=setmetatable({game=game,Deck=Deck,screenShake=0,Sound={play=function() end},
        UI={Abilities=A,COLORS={goldYellow={1,1,1,1}}},anim={floatingTexts={}},
        clearAllSelections=function() end,dealCombatHand=function() end},{__index=_G})
    local chunk=source:sub(start,stop-1).."\nreturn discardSelected"
    local fn
    if setfenv then fn=assert(loadstring(chunk));setfenv(fn,env) else fn=assert(load(chunk,"seal discard","t",env)) end
    fn()()
end
g,cs=fixture("seal_gambit");cs[2].seal="seal_gambit";g.selectedIndices={1,2};g.discardsRemaining=0
local hp=g.playerHp;discardLive(g)
assert(#g.hand==3 and #g.discardPile==2 and g.discardsRemaining==0 and g.playerHp==hp and (g.discardsUsedInCombat or 0)==0)
g,cs=fixture("seal_gambit");g.selectedIndices={1,3};g.discardsRemaining=1;discardLive(g)
assert(#g.hand==3 and g.discardsRemaining==0 and g.discardsUsedInCombat==1)
-- Three Beats scores each stamped card three times and heals three HP once per owner.
g,cs=fixture("seal_threshold");cs[2].seal="seal_threshold";cs[1].equipments={E.ITEMS.gem_fire}
pre=score(g,{cs[1],cs[2]},true);actual=score(g,{cs[1],cs[2]})
assert(actual.healHp==6 and actual.bonusChips==30+3*E.ITEMS.gem_fire.params.edge)
assert(pre.finalScore==actual.finalScore and pre.healHp==6)
local n=0;for _,step in ipairs(actual.steps) do if step.type=="card_scored" then n=n+1 end end
assert(n==6)
-- The real ability queue must match the isolated/direct calculation.
g,cs=fixture("seal_threshold");local h={type=Poker.HAND_TYPES.HIGH_CARD,chips=10,mult=2,scoringCards={cs[1]},unscoredCards={}}
A.beginHand(g,h,{cs[1]});local live=S.calculate(h,{}, {gameState=g,monster=g.monster,hand={}})
n=0;for _,step in ipairs(live.steps) do if step.type=="card_scored" then n=n+1 end end
assert(n==3 and live.healHp==3)
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
for _,c in ipairs(cs) do c.seal="seal_anchor" end
g.bountySealClaimedThisCombat=true
Combat.start(g,{hp=100,maxHp=100,armor=0},1)
assert(#g.hand==5 and not g.bountySealClaimedThisCombat)
for _,c in ipairs(g.hand) do assert(c.seal=="seal_anchor") end
g,cs=fixture("seal_bounty");cs[2].seal="seal_bounty"
assert(score(g,{cs[1]},false,{}, {cs[2]}).bountySealGold==6)
assert(score(g,{cs[3]},false,{cs[1],cs[2]}).bountySealGold==0)
-- Real victory settlement grants stacked Bounty only once, rather than on an intermediate kill.
local rewardStart=assert(source:find("UI.applyCombatWinRewards=function(scoreResult)",1,true))
local rewardStop=assert(source:find("local function initShadersAndCanvas",rewardStart,true))
g,cs=fixture("seal_bounty");cs[2].seal="seal_bounty";g.gold=0;g.handsRemaining=0;g.run=nil
local rewardUI={COLORS={goldYellow={1,1,1,1}}};local rewardAnim={floatingTexts={}}
local env=setmetatable({game=g,Deck=Deck,UI=rewardUI,anim=rewardAnim,Deities=require("src.deities"),Sound={play=function() end}},{__index=_G})
local chunk=source:sub(rewardStart,rewardStop-1).."\nreturn UI.applyCombatWinRewards"
local loader
if setfenv then loader=assert(loadstring(chunk));setfenv(loader,env) else loader=assert(load(chunk,"seal victory","t",env)) end
local reward=loader();local result=score(g,{cs[1]},false,{}, {cs[2]})
assert(g.gold==0 and result.bountySealGold==6)
reward(result);assert(rewardAnim.earnedGold==10 and g.gold==10)
g.gold=0;reward(result);assert(rewardAnim.earnedGold==4 and g.gold==4)
for i=1,150 do
    local pack=Shop.openPack({packType="seal"},Game.new());local ids={};assert(#pack.cards==3)
    for _,d in ipairs(pack.cards) do assert(Deck.SEALS[d.id] and not ids[d.id]);ids[d.id]=true end
end
print("PASS: 10 requested seal rules, scored/unscored/held distinctions, repeated equipment, stacked rewards, preview parity and 16 save migrations")

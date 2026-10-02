local A=require("src.card_abilities")
local Boss=require("src.boss_abilities")
local Deck=require("src.deck")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Combat=require("src.combat")
local Monster=require("src.monster")
local Run=require("src.run_manager")
local Persistence=require("src.persistence")
local Description=require("src.card_description")
local Deities=require("src.deities")
local Equipment=require("src.equipment")
local function card(rank,suit,level)
    local c=Deck.newCard(rank,suit);c.disableFactionPassives=true;c.isWildSuit=false;c.isDualRankAce=false;c.evolutionLevel=level or 0;return c
end
local function game(cards,bossKey)
    local g={hand=cards or {},persistentDeck={},deck={},discardPile={},maxHandSize=3,maxHands=4,maxDiscards=3,handsRemaining=4,discardsRemaining=3,
        gold=70,playerHp=50,maxPlayerHp=100,playerArmor=0,deities={},consumables={{id="dummy1",name="Một"},{id="dummy2",name="Hai"},{id="dummy3",name="Ba"}}}
    for _,c in ipairs(g.hand) do g.persistentDeck[#g.persistentDeck+1]=Deck.cloneCard(c) end
    for i,id in ipairs({"spirit_blade","spirit_drum","spirit_pebble"}) do g.deities[i]=Deities.CATALOG[id] end
    g.monster=Monster.create(1,true,false,1,bossKey or "memory_eater");g.monster.hp=10000;g.monster.maxHp=10000
    A.start(g);Boss.start(g);return g
end
local function context(g,c,scoring)
    local x={game=g,scoring=scoring,played=scoring,active=g.hand,queue={},repeats={},once={},visited={},triggerCount=0,feedback={},
        scored={scoring[1],scoring[2]},index=1,play=3,full=true,depth=0,spnCount=3,spnSeen={},spnRepeats=0,returns={},
        unusedDiscards=3,goldBeforeInterest=70,damage=20,handInfo={type={id="pair"},scoringCards=scoring,unscoredCards={},chips=10,mult=2}}
    g.abilityHand=x;return x
end
local registered=0
for _,id in ipairs(A.config.order) do
    local d=A.definitions[id];registered=registered+1
    local c=card(d.rank,d.suit=="heart" and "hearts" or d.suit=="diamond" and "diamonds" or d.suit=="club" and "clubs" or "spades")
    assert(A.definition(c)==d,id.." registration")
    local other=card(2,"diamonds",2)
    local g=game({c,other},"black_tax_collector")
    g.deck={card(3,"hearts"),card(4,"clubs"),card(5,"diamonds")}
    local scoring={c,other}
    if d.op:find("suits") then scoring={c,card(4,"hearts"),card(4,"diamonds"),card(4,"clubs"),card(4,"spades")} end
    if d.baseParams.count==5 then scoring={c,other,card(5,"clubs"),card(5,"spades"),card(5,"hearts")} end
    local x=context(g,c,scoring)
    if d.op=="spn_repeat" then x.spnCount=1 end
    if d.op=="copy_previous" then x.previous=other end
    if d.op=="copy_diamond" then g.abilityCombat.lastDiamond={card=other,definition=A.definition(other),event="score"} end
    if d.op=="copy_destroyed" then g.abilityCombat.lastDestroyed=card(13,"hearts") end
    if d.op=="copy_held" then g.hand={card(14,"hearts"),c};assert(A.handSize(g)==5) end
    if d.op=="transfer" then c.evolutionLevel=1 end
    if d.op=="consume_cancel" then g.hand={c};scoring={other};x.scoring=scoring;x.played=scoring end
    if d.trigger=="choice" then
        local info={type={id="pair"},scoringCards=scoring,unscoredCards={}}
        local choices=A.choices(g,info,d.op=="consume_cancel" and {other} or scoring)
        local chosen
        for _,v in ipairs(choices) do if v.card==c then chosen=v;break end end
        assert(chosen,id.." must offer a real optional choice")
        x.decisions={{card=c,definition=d,params=A.params(c),target=chosen.options[1].target}}
        A.applyDecisions(g,"before");A.applyDecisions(g,"after")
        assert(x.decisions[1].applied,id.." choice executed")
    elseif d.trigger=="held" then
        A.dispatch(g,"held",{c},x)
        assert(A.handSize(g)>g.maxHandSize,id.." held effect changes capacity")
    else
        A.dispatch(g,d.trigger,{c},x)
    end
    local fired=false
    for _,v in ipairs(x.feedback) do if v.abilityId==id then fired=true end end
    assert(fired,id.." trigger must execute, not just register")
    local title,text=Description.resolve(c,g);assert(title:find(d.name,1,true));assert(#text>20 and not text:find("{[%w_]+}"),id.." tooltip")
    c.evolutionLevel=0;c.temporaryAbilityLevels=0
    local before=A.params(c);assert(A.evolve(g,c),id.." evolve")
    local after=A.params(c);local changed=false
    for k,v in pairs(before) do if after[k]~=v then changed=true end end
    assert(changed,id.." evolution changes actual parameters")
    assert(c.rank==d.rank and A.definition(c).suit==d.suit,id.." evolution must not change poker identity")
    g.persistentDeck={c};g.run=Run.newRun("red_deck")
    local snapshot=Persistence.makeSnapshot(g,"shop")
    local restored=assert(Persistence.restoreSnapshot(assert(Persistence.decode(Persistence.encode(snapshot)))))
    assert(restored.persistentDeck[1].id==c.id and restored.persistentDeck[1].evolutionLevel==1,id.." save roundtrip")
    snapshot.game.persistentDeck[1].evolutionLevel=nil
    assert(assert(Persistence.restoreSnapshot(snapshot)).persistentDeck[1].evolutionLevel==0,id.." old save default")
end
assert(registered==52)
print("52 abilities: registration, real trigger, tooltip, stronger evolution, identity and old/new saves passed")
local function play(g,cards,info,decisions)
    info=info or Poker.evaluate(cards)
    A.beginHand(g,info,cards,decisions)
    g.hand={};g.discardPile={};for _,c in ipairs(cards) do g.discardPile[#g.discardPile+1]=c end
    local result=Scoring.calculate(info,g.deities,{gameState=g,monster=g.monster,unplayedCards=g.hand,handsRemaining=g.handsRemaining})
    assert(g.abilityHand.triggerCount<=A.config.maxTriggersPerHand)
    assert(#g.abilityHand.queue<=A.config.maxTriggersPerHand)
    A.finishHand(g)
    return result
end
local combos={
    {{2,"hearts"},{2,"clubs"},{2,"diamonds"}},
    {{4,"hearts"},{4,"diamonds"},{4,"clubs"},{4,"spades"}},
    {{5,"hearts"},{5,"diamonds"},{5,"clubs"},{5,"spades"},{5,"hearts"}},
    {{6,"hearts"},{6,"diamonds"},{6,"clubs"},{6,"spades"}},
    {{7,"diamonds"},{7,"clubs"},{7,"spades"}},
    {{8,"hearts"},{8,"diamonds"},{8,"clubs"},{8,"spades"}},
    {{9,"hearts"},{9,"diamonds"},{9,"clubs"},{9,"spades"}},
    {{10,"diamonds"},{10,"clubs"},{10,"spades"}},
    {{12,"clubs"},{12,"spades"}},
    {{13,"clubs"},{13,"spades"},{11,"spades"}},
}
for index,rows in ipairs(combos) do
    local cards={};for _,v in ipairs(rows) do cards[#cards+1]=card(v[1],v[2],v[1]==10 and 1 or 0) end
    local g=game(cards,"black_tax_collector");g.maxHandSize=#cards;g.abilityCombat.playIndex=2
    local info=Poker.evaluate(cards)
    if index==1 then info={type=Poker.HAND_TYPES.PAIR,scoringCards={cards[1],cards[2]},unscoredCards={cards[3]},chips=10,mult=2} end
    if index==2 then info={type=Poker.HAND_TYPES.FOUR_OF_A_KIND,scoringCards=cards,unscoredCards={},chips=60,mult=7} end
    -- Five identical ranks are not a new five-of-a-kind hand in the unchanged evaluator.
    -- Exercise the five-scoring event contract explicitly, without adding a poker hand.
    if index==3 then assert(#info.scoringCards<5);info={type=Poker.HAND_TYPES.FLUSH,scoringCards=cards,unscoredCards={},chips=35,mult=4} end
    if index==5 or index==8 then info={type=Poker.HAND_TYPES.THREE_OF_A_KIND,scoringCards=cards,unscoredCards={},chips=30,mult=3} end
    if index==9 then info={type=Poker.HAND_TYPES.HIGH_CARD,scoringCards={card(14,"diamonds")},unscoredCards=cards,chips=8,mult=1} end
    local decisions={}
    for _,choice in ipairs(A.choices(g,info,cards)) do decisions[#decisions+1]={card=choice.card,definition=choice.definition,params=choice.params,target=choice.options[1].target} end
    if index==4 then A.discard(g,cards);A.roundEnd(g);assert(g.playerArmor>=6 and Boss.state(g.monster).delayNextAction==1) end
    if index==7 then A.consumableUsed(g);assert(g.abilityCombat.pendingRepeat>=1) end
    if index==10 then A.destroy(g,cards[1]);A.destroy(g,cards[2]) end
    local result=play(g,cards,info,decisions)
    assert(result.finalScore>=0 and result.finalScore==result.finalScore,"combo "..index)
    if index==1 then assert(#g.hand==1 and g.hand[1]==cards[2],"return hand count "..#g.hand);assert(g.abilityHand.repeats[cards[1].id]==1,"pair repeats "..tostring(g.abilityHand.repeats[cards[1].id])) end
    if index==2 then assert(g.playerArmor>=8);assert(g.abilityHand.repeats[cards[1].id]==1) end
    if index==3 then assert(#g.hand>=1 and A.level(cards[1])>0) end
    if index==9 then assert(g.abilityHand.repeats[info.scoringCards[1].id]==2) end
    print("Combo "..index..": deterministic bounded resolution passed")
end
-- Copy cycles and destruction may never recurse indefinitely.
local j1,j2=card(11,"clubs",5),card(11,"spades",5)
local g=game({j1,j2});g.abilityCombat.lastDestroyed=j1
play(g,{j1,j2})
local q=card(12,"hearts",2);assert(A.params(q).healPercent==3 and A.params(q).maxStacks==4)
local k=card(13,"hearts",2);assert(A.params(k).healPercent==35 and A.params(k).armor==14)
-- Every shipped boss is attached to an actual active, with usable counter lifecycle.
local catalog={}
for _,d in pairs(Monster.BOSSES) do catalog[d.debuffId]=d end
for id,d in pairs(Monster.DISRUPTIVE_BOSSES) do catalog[id]=d end
for id,d in pairs(Run.BOSS_DEBUFFS) do catalog[id]=d end
local bossCount=0
for key,def in pairs(catalog) do
    bossCount=bossCount+1;assert(def.active and def.desc and def.active.cooldown>=1,key.." active registration")
    local c=card(13,key:find("lock_")==1 and key~="lock_royals" and key:sub(6) or "hearts");c.equipments={Equipment.ITEMS.gem_fire}
    local b=game({c},key);b.monster.bossData=def;Boss.start(b);Boss.handStart(b)
    local s=Boss.state(b.monster);assert(s.telegraph and #s.telegraph>0,key.." telegraph")
    b.playerArmor=20;b.monster.hp=b.monster.maxHp-100;c.faceDown=false
    Boss.handEnd(b);assert(s.cycle==1 and s.activeCountdown>1,key.." active/cooldown")
    local op=def.active.op
    if op:find("silence") then assert(c.abilityDisabledUntil==2,key.." real silence")
    elseif op=="face" then assert(c.faceDown,key.." real face-down")
    elseif op=="armor" then assert(b.playerArmor==20-def.active.amount,key.." armor drain")
    elseif op=="gold" then assert(b.gold==70-def.active.amount,key.." gold drain")
    elseif op=="heal" then assert(b.monster.hp>b.monster.maxHp-100,key.." real healing")
    elseif op=="damage" then assert(s.pendingDamage==def.active.amount,key.." pending guarded damage")
    elseif op=="repeat_penalty" then assert(s.repeatUntil==2,key.." next-hand penalty")
    elseif op=="tax_lock" then assert(Boss.isSlotLocked(b,"consumable",1) and #b.consumables==3,key.." slot lock preserves inventory")
    elseif op=="hands" or op=="discard" or op=="gate_lock" then assert(s.resourceLock and s.resourceLock.untilHand==2,key.." resource lock") end
    Boss.disable(b,2,true);assert(not Boss.passiveEnabled(b.monster),key.." passive disable")
    assert(not Boss.beforeAttack(b),key.." full lock");s.actionBlocked=nil
    s.passiveUntil=0;s.activeUntil=0;s.activeCountdown=1;Boss.counter(b,"cancelNextActive",1)
    local before=s.cycle;Boss.handEnd(b);assert(s.cycle==before and s.cancelNextActive==0,key.." cancel")
    Boss.counter(b,"delayNextAction",1);assert(not Boss.beforeAttack(b));assert(s.delayNextAction==0)
    local countdown=s.activeCountdown;Boss.handEnd(b);assert(s.activeCountdown==countdown,key.." delay countdown")
    Boss.counter(b,"skipNextAction",1);assert(not Boss.beforeAttack(b));assert(s.skipNextAction==0,key.." skip")
    assert(Boss.describe(b.monster):find(def.active.name,1,true),key.." UI from definition")
end
print(bossCount.." bosses: active/telegraph/cooldown/disable/cancel/delay/skip/UI passed")
-- Exercise legacy and new passives through their actual gameplay hooks.
for key,def in pairs(catalog) do
    local c=card(13,key:find("lock_")==1 and key~="lock_royals" and key:sub(6) or "hearts")
    local b=game({c},key);b.monster.bossData=def;Boss.start(b)
    if def.applyModifier then def.applyModifier(b) end
    if key=="less_discard" or key=="max_4_cards" then assert(b.discardsRemaining==2)
    elseif key=="the_water" then assert(b.discardsRemaining==0)
    elseif key=="the_needle" then assert(b.handsRemaining==1)
    elseif key=="max_3_cards" then assert(b.maxSelectableCards==3)
    elseif key:find("lock_")==1 then
        local info=Poker.evaluate({c});local locked=Scoring.calculate(info,{}, {monster=b.monster})
        Boss.disable(b,1);local unlocked=Scoring.calculate(info,{}, {monster=b.monster});assert(unlocked.finalScore>locked.finalScore,key)
    elseif key=="damage_resist" then
        assert(Monster.takeDamage(b.monster,100)==80);Boss.disable(b,1);assert(Monster.takeDamage(b.monster,100)==100)
    elseif key=="executioner" then
        b.playerHp=30;b.playerArmor=20;b.monster.attack=5
        assert(Combat.resolveMonsterAttack(b).damage==10 and b.playerArmor==20)
    elseif key=="the_hook" then
        b.hand={card(6,"clubs"),card(6,"spades")};assert(Boss.onPlay(b)==2 and #b.hand==0 and #b.discardPile==2)
        assert(b.abilityCombat.pendingRepeat==1 and Boss.state(b.monster).delayNextAction==1)
    elseif key=="the_arm" then
        Boss.afterScore(b,{c});assert(c.rank==12 and b.persistentDeck[1].baseRank==12)
        Boss.disable(b,1);Boss.afterScore(b,{c});assert(c.rank==12)
    elseif key=="faceless" or key=="the_fish" then
        Boss.handStart(b);assert(c.faceDown);Boss.disable(b,1);assert(not c.faceDown)
    elseif key=="echo_knight" or key=="taxman" then
        b.abilityCombat.previousHandType="high_card";local info=Poker.evaluate({c});A.beginHand(b,info,{c})
        local result=Scoring.calculate(info,{}, {gameState=b,monster=b.monster})
        if key=="echo_knight" then assert(result.baseMult==0) else assert(b.gold==69) end
    elseif key=="gem_devourer" then
        c.equipments={Equipment.ITEMS.gem_fire};b.monster.hp=100
        Boss.handEnd(b);assert(#c.equipments==0 and b.monster.hp==100+Boss.config.gemPassiveHeal+def.active.amount)
    elseif key=="black_tax_collector" then
        b.gold=0;Boss.handEnd(b);assert(Boss.state(b.monster).debt==1)
    elseif key=="memory_eater" then
        assert(Boss.allowRetriggerAbility(b,c));assert(not Boss.allowRetriggerAbility(b,c));Boss.disable(b,1);assert(Boss.allowRetriggerAbility(b,c))
    elseif key=="gatekeeper" then
        b.hand={};for _=1,7 do b.hand[#b.hand+1]=card(3,"hearts") end
        Boss.handStart(b);assert(Boss.state(b.monster).excess==2);b.monster.attack=4
        assert(Combat.resolveMonsterAttack(b).attack==6 and b.monster.attack==4,"gate bonus must not compound into base attack")
    else error("Untested passive "..key) end
end
print("All 22 boss passives exercised through live scoring/combat/resource hooks")
local a,b=card(12,"hearts"),card(12,"hearts");b.id=a.id;Deck.restoreDeck({a,b});assert(a.id~=b.id,"old duplicate ID migration")
local held=card(12,"hearts",2);local g2=game({held});A.runtime(held).hearts=2
local info={type=Poker.HAND_TYPES.HIGH_CARD,scoringCards={card(14,"diamonds")},unscoredCards={held},chips=5,mult=1}
A.beginHand(g2,info,{held,info.scoringCards[1]});assert(g2.playerHp==56 and A.runtime(held).hearts==0,"played non-scoring queen releases stacks")
local c1,c2=card(2,"hearts",2),card(2,"diamonds");local g3=game({c1,c2});play(g3,{c1,c2});assert(#g3.hand==1 and g3.playerArmor==4,"return evolution must increase real strength")
g3.monster.hp=0;local cycle=Boss.state(g3.monster).cycle;Boss.handEnd(g3);assert(Boss.state(g3.monster).cycle==cycle,"dead boss must not act")
for id,d in pairs(Deck.ENHANCEMENTS) do assert(not Deck.getModifierDescription("enhancement",id):find("{[%w_]+}"),id) end
for _,catalog in ipairs({require("src.shop").SPECTRAL_CARDS,require("src.shop").JOKER_SPELLS,Poker.PLANET_CARDS}) do
    for _,item in ipairs(catalog) do local _,body=Description.resolve(item);assert(#body>10 and not body:find("{[%w_]+}"),item.id) end
end
-- Returning all five cards still improves at the last evolution level.
local returnArmor={}
for level=4,5 do
    local c=card(5,"hearts",level)
    local cards={c,card(5,"diamonds"),card(5,"clubs"),card(5,"spades"),card(5,"hearts")}
    local g=game(cards)
    local info={type=Poker.HAND_TYPES.FLUSH,scoringCards=cards,unscoredCards={},chips=5,mult=1}
    A.beginHand(g,info,cards);g.hand={};g.discardPile={}
    for _,played in ipairs(cards) do g.discardPile[#g.discardPile+1]=played end
    A.dispatch(g,"score",{c},g.abilityHand);A.finishHand(g)
    assert(#g.hand==5,"return cannot duplicate or invent cards")
    returnArmor[level]=g.playerArmor
end
assert(returnArmor[5]>returnArmor[4],"last return evolution must improve actual strength")
local g=game({card(2,"diamonds")},"executioner");g.playerArmor=1
Boss.handEnd(g);local hp=g.playerHp
A.resolveBossDamage(g)
assert(g.playerHp==hp-2 and g.playerArmor==0,"end-turn boss damage resolves immediately through armor")
A.resolveBossDamage(g);assert(g.playerHp==hp-2,"boss damage cannot resolve twice")
assert(#A.takeFeedback(g)>0,"end-turn feedback drains the combat queue")
assert(#A.takeFeedback(g)==0,"feedback is consumed once")
-- Artwork shaders and the pre-existing score formula remain outside ability resolution.
print("Gameplay expansion smoke passed")

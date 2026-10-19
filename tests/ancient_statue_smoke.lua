local S=require("src.ancient_statue")
local GS=require("src.game_state")
local Run=require("src.run_manager")
local Deck=require("src.deck")
local Rng=require("src.rng")
local P=require("src.persistence")
local H=require("src.player_health")
local original=Rng.random
local function game(ante)
    local g=GS.new();g.run=Run.newRun("red_deck");g.run.ante=ante or 2;g.run.areaStage=g.run.ante
    g.run.blinds=Run.generateAnteBlinds(g.run.ante,"red_deck","human",g.run.areaStage)
    g.run.currentBlindIndex=3;g.run.blinds[3].status="completed"
    g.persistentDeck={Deck.newCard(7,"hearts")};g.masterDeck=g.persistentDeck
    S.create(g);return g
end
local function save(g,state) return P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,state))))) end
local function force(n) Rng.random=function(a,b) if not a then return 0 elseif b then return a else return n end end end
for i,result in ipairs(S.outcomes) do
    local g=game();local card=g.persistentDeck[1];local chips=card.baseChips;local speed=Deck.peekCardAttackSpeed(card)
    card.evolutionLevel=2;local gold=g.gold
    force(i);assert(S.touch(g,card.id));assert(g.playerHp==90 and g.ancientStatue.touches==1 and g.ancientStatue.last==result.id)
    if result.id=="damage" then assert(card.baseChips==chips+5)
    elseif result.id=="speed" then assert(Deck.peekCardAttackSpeed(card)==speed+3)
    elseif result.id=="evolve" then assert(card.evolutionLevel==3)
    elseif result.id=="double" then
        assert(card.baseChips==chips*2 and Deck.peekCardAttackSpeed(card)==speed*2)
        local params=require("src.card_abilities").params(card);local plain=Deck.newCard(7,"hearts");plain.evolutionLevel=2
        for k,v in pairs(require("src.card_abilities").params(plain)) do if k=="healPercent" then assert(params[k]==v*2) end end
    elseif result.id=="copies" then
        assert(#g.persistentDeck==4);local ids={};for _,c in ipairs(g.persistentDeck) do assert(not ids[c.id]);ids[c.id]=true;assert(c.evolutionLevel==2) end
    elseif result.id=="lose_damage" then assert(card.baseChips==math.max(1,chips-5))
    elseif result.id=="lose_speed" then assert(Deck.peekCardAttackSpeed(card)==math.max(1,speed-3))
    elseif result.id=="lose_level" then assert(card.evolutionLevel==1)
    elseif result.id=="gold" then assert(g.gold==gold+100)
    elseif result.id=="nothing" then assert(g.gold==gold and card.baseChips==chips) end
    local loaded,state=save(g,"blood_statue");assert(state=="blood_statue" and loaded.playerHp==90 and loaded.ancientStatue.last==result.id)
    assert(loaded.persistentDeck[1].statuePower==card.statuePower and loaded.persistentDeck[1].statueSpeedPenalty==card.statueSpeedPenalty)
end
local g=game();local n=0
Rng.random=function() n=n+1;return .29 end
assert(S.roll(g) and n==1 and not S.roll(g));g=save(g,"shop");assert(not S.roll(g) and n==1)
g=game(3);assert(not S.roll(g) and n==1)
g=game();Rng.random=function() n=n+1;return .30 end;assert(not S.roll(g));assert(not S.roll(g) and n==2)
g=game();local hp=g.playerHp;assert(not S.touch(g,-99) and g.playerHp==hp)
force(10);local id=g.persistentDeck[1].id
for _=1,21 do assert(S.touch(g,id));assert(not g.bloodDomain) end
assert(S.touch(g,id));assert(g.playerHp<=g.maxPlayerHp*.1 and g.bloodDomain and g.run.areaStage==1)
assert(not require("src.void_gacha").enterIfDue(g) and not require("src.barter").roll(g))
local permit=require("src.expedition").travelPermit();g.consumables={permit};assert(not Run.beginTravel(g,"consumables",1,"BLIND_SELECT"))
for stage=1,8 do
    assert(g.run.areaStage==stage and g.run.currentBlindIndex==3)
    local b=Run.getCurrentBlind(g.run);local m=Run.createBlindMonster(b,g,true)
    assert(m.artKey==S.enemies[stage].key and m.cardRank==S.enemies[stage].rank and m.creatureCard)
    assert(m.isBoss==(stage==8) and not require("src.expedition").canEnter(g,"blood_domain"))
    local scene=require("config.scene_definitions").resolve("playing",m)
    assert(scene=="battle")
    if stage==8 then
        require("src.combat").start(g,m,g.run.ante)
        local initial={hp=m.hp,max=m.maxHp,attack=m.attack,speed=m.attackSpeed}
        g.playerHp=10;g.maxPlayerHp=100;g.consumables={require("src.shop").healingItem(nil,"cons_heal_small").consumable}
        assert(require("src.inventory").useUtility(g,1))
        assert(m.hp==initial.hp*2 and m.maxHp==initial.max*2 and m.attack==initial.attack*2 and m.attackSpeed==initial.speed*2)
        H.heal(g,1);assert(m.bloodHealTriggers==2 and m.maxHp==initial.max*4)
        g.playerHp=100;H.heal(g,25);assert(m.bloodHealTriggers==2,"Full HP must not count as healing")
        g.playerArmor=999;g.playerHp=10;assert(math.abs(H.bloodTurn(g)-.2)<1e-8 and math.abs(g.playerHp-9.8)<1e-8 and g.playerArmor==999)
        local before=g.playerHp;require("src.boss_abilities").handEnd(g);assert(math.abs(g.playerHp-before*.98)<1e-8,"All committed turns must drain HP once")
        require("src.boss_abilities").disable(g,1);before=g.playerHp;local triggers=m.bloodHealTriggers
        assert(H.bloodTurn(g)==0);H.heal(g,1);assert(m.bloodHealTriggers==triggers,"Sealed passive must stay disabled")
        m.hp=0;H.heal(g,1);assert(m.bloodHealTriggers==2 and H.bloodTurn(g)==0,"Dead boss cannot trigger")
    end
    Run.completeCurrentBlind(g.run,g)
    if stage<8 then
        g=save(g,"shop");assert(g.run.regionId=="blood_domain" and g.run.areaStage==stage)
        assert(Run.advanceBlind(g.run,g))
    end
end
assert(#g.bloodDomain.choices==3 and not Run.advanceBlind(g.run,g))
local ids={};for _,item in ipairs(g.bloodDomain.choices) do assert(not ids[item.id]);ids[item.id]=true;assert(require("src.blood_shop").powerOf(item)==4) end
local encoded=P.encode(g.bloodDomain.choices)
g=save(g,"blood_statue");assert(P.encode(P.makeSnapshot(g,"blood_statue").game.bloodDomain.choices)==encoded)
local choice=g.bloodDomain.choices[2];assert(S.claim(g,2) and not S.claim(g,2))
assert(g.run.regionId=="human" and g.run.ante==2 and g.backpackDeities[#g.backpackDeities].id==choice.id)
assert(g.backpackDeities[#g.backpackDeities].bloodDomainPower==4)
local D=require("src.deities");local boosted=D.scaleEffect(choice,{addChips=10});local plain={};for k,v in pairs(choice) do plain[k]=v end;plain.bloodDomainPower=nil
assert(boosted.addChips==D.scaleEffect(plain,{addChips=10}).addChips*4)
local borrowed={};for k,v in pairs(D.CATALOG.spirit_borrowed_turn) do borrowed[k]=v end;borrowed.bloodDomainPower=4
g.deities={borrowed};g.backpackConsumables={}
local result=D.scaleEffect(borrowed,{grantPermanentSpeedSmall=true})
require("src.spn_anomalies").commitHand(g,1,result)
assert(require("src.shop").getConsumableParams(g.backpackConsumables[1]).speed==12,"Borrowed Turn x4 must create a real +12 speed potion")
assert(Run.advanceBlind(g.run,g) and g.run.ante==3)
Rng.random=original
print("Ancient Statue PASS: all 10 outcomes, exact HP cost/threshold, saved appearance/results, eight encounters/one final boss, healing doubles live boss, armor-piercing drain, one of three real x4 SPNs, return route, no repeated claim")

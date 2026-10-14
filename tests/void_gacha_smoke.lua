local G=require("src.void_gacha")
local GS=require("src.game_state")
local Run=require("src.run_manager")
local Rng=require("src.rng")
local P=require("src.persistence")
local E=require("src.equipment")
local D=require("src.deities")
local Deck=require("src.deck")
local B=require("src.basic_equipment")
local Reward=require("src.reward_system")
local original=Rng.random
local function force(roll,unit)
    Rng.random=function(a,b) if b==100000 then return roll or 5 elseif not a then return unit or .99 elseif b then return a else return 1 end end
end
local function game(ante)
    local g=GS.new();g.run=Run.newRun("red_deck");g.run.ante=ante or 10;g.run.areaStage=((g.run.ante-1)%20)+1
    g.run.currentBlindIndex=3;g.run.blinds=Run.generateAnteBlinds(g.run.ante,"red_deck",g.run.regionId,g.run.areaStage)
    g.run.blinds[3].status="completed";g.gold=10000;g.voidTickets=30;force();assert(G.enterIfDue(g));return g
end
local counts={};for roll=1,100000 do local id=G.pick(roll);counts[id]=(counts[id] or 0)+1 end
for _,r in ipairs(G.config.rates) do assert(counts[r.id]==r.weight) end
assert(counts.featured_spn==2 and counts.featured_equipment==1 and counts.featured_card==1)
for _,a in ipairs({10,20,30,40,50}) do local g=game(a);local banner=P.encode(g.voidEvent);assert(not G.enterIfDue(g) and P.encode(g.voidEvent)==banner) end
local g=GS.new();g.run=Run.newRun();g.run.ante=9;g.run.currentBlindIndex=3;g.run.blinds[3].status="completed";assert(not G.enterIfDue(g))
g.run.ante=10;g.run.currentBlindIndex=2;assert(not G.enterIfDue(g));g.run.currentBlindIndex=3;g.run.blinds[3].status="current";assert(not G.enterIfDue(g))
g=game();assert(G.quote(g,1,"gold").cost==100 and G.quote(g,10,"gold").cost==1000 and G.quote(g,10,"ticket").cost==10)
assert(not G.pull(g,0,"gold") and not G.pull(g,2,"gold"));g.gold=99
local state=Rng.getState();assert(not G.pull(g,1,"gold") and g.gold==99 and Rng.getState()==state)
g.gold=10000;force(5);assert(G.pull(g,10,"ticket"));assert(g.voidTickets==20 and #g.voidEvent.results==10 and g.voidEvent.totalRolls==10)
assert(not G.pull(g,1,"ticket"));G.finishReveal(g)
g.voidEvent.totalRolls=1000000;assert(G.pull(g,1,"gold"));assert(g.voidEvent.results[1].kind=="gold" and not g.voidEvent.results[1].featured)
g=game();g.voidEvent.goldMultiplier=.5;assert(G.quote(g,10,"gold").cost==500 and G.quote(g,10,"ticket").cost==10)
g.voidEvent.freeRemaining=1;assert(G.quote(g,1,"gold").cost==0 and G.quote(g,10,"gold").cost==450)
g.gold=0;force(5);assert(G.pull(g,1,"gold") and g.voidEvent.freeRemaining==0);G.finishReveal(g);g.gold=0;assert(not G.pull(g,1,"gold"))
local catalog=P.encode({E.ITEMS.basic_plate,D.CATALOG.spirit_pebble})
g=game();g.voidEvent.spnId="spirit_pebble";g.voidEvent.equipmentId="basic_plate";g.voidEvent.rank=7;g.voidEvent.suit="hearts"
force(1);assert(G.pull(g,1,"gold"));local spn=g.backpackDeities[1];assert(spn.rarity=="unique" and spn.baseRarityTier==8 and spn.voidPower==5)
local normal=G.createReward(g,"featured_spn").item;normal.voidPower=nil
assert(D.scaleEffect(spn,{addChips=20}).addChips==D.scaleEffect(normal,{addChips=20}).addChips*5)
G.finishReveal(g);force(3);assert(G.pull(g,1,"gold"));assert(g.backpackEquipment[1].voidPower==10)
local gear=B.item(g.backpackEquipment[1]);assert(gear.onCardScore({},{},1,{}).addArmor==20 and E.getDescription(gear):find("20",1,true))
G.finishReveal(g);force(4);assert(G.pull(g,1,"gold"));local card=g.persistentDeck[1]
assert(card.rank==7 and card.baseChips==70 and card.voidPower==10)
local base=Deck.newCard(7,"hearts");assert(Deck.peekCardAttackSpeed(card)==Deck.peekCardAttackSpeed(base)*10)
local params=require("src.card_abilities").params(card);local plain=require("src.card_abilities").params(base);local grew=false
for key,value in pairs(plain) do if type(value)=="number" and value>0 and params[key]==value*10 then grew=true end end;assert(grew)
local restored,loadedState=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"void")))))
assert(loadedState=="void" and restored.voidEvent.pendingResults and not G.pull(restored,1,"gold"))
assert(restored.backpackDeities[1].voidPower==5 and B.item(restored.backpackEquipment[1]).onCardScore({},{},1,{}).addArmor==20)
assert(restored.persistentDeck[1].baseChips==70 and restored.persistentDeck[1].voidPower==10)
G.finishReveal(restored);assert(not G.enterIfDue(restored));assert(B.attach(restored,1,restored.persistentDeck[1]))
assert(restored.persistentDeck[1].equipments[1].voidPower==10);assert(B.detach(restored,restored.persistentDeck[1],1) and B.item(restored.backpackEquipment[1]).voidPower==10)
local start=0
for _,row in ipairs(G.config.rates) do
    g=game();force(start+1);assert(G.pull(g,1,"gold"));assert(g.voidEvent.results[1].id==row.id)
    if row.id=="consumable" then assert(#g.backpackConsumables==1)
    elseif row.id=="pack" then assert(#g.rewardPacks==1)
    elseif row.id=="voucher" then assert(next(g.vouchers))
    elseif row.id=="hand" then assert(g.maxHandSize==4) end
    start=start+row.weight
end
g=game();local earned=0
for amount=1,100 do
    Rng.random=function(a,b) if b==100000 then return 100000 elseif a==1 and b==100 then return amount elseif b then return a elseif not a then return .99 else return 1 end end
    assert(G.pull(g,1,"gold"));earned=earned+amount
    local reward=g.voidEvent.results[1]
    assert(reward.kind=="ticket" and reward.amount==amount and reward.name=="+"..amount.." Vé The Void")
    assert(g.voidTickets==30+earned and g.gold==10000-amount*100)
    G.finishReveal(g);assert(g.voidTickets==30+earned,"Reveal duplicated ticket reward")
end
g=game();Rng.random=function(a,b) if b==100000 then return 100000 elseif a==1 and b==100 then return 100 elseif b then return a elseif not a then return .99 else return 1 end end
assert(G.pull(g,10,"ticket") and g.voidTickets==1020 and g.gold==10000)
local ticketRestore=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"void")))))
assert(ticketRestore.voidTickets==1020 and ticketRestore.voidEvent.results[10].amount==100)
G.finishReveal(ticketRestore);assert(ticketRestore.voidTickets==1020)
g=GS.new();g.run=Run.newRun();force(5,0)
local result=Reward.begin(Reward.calculate({type="small",baseReward=3},g),g)
assert(g.voidTickets==1);local tickets=g.voidTickets;assert(Reward.begin({},g)==result and g.voidTickets==tickets)
Reward.exchangeAll(g,result);assert(g.voidTickets==tickets,"Ticket is currency, never sold by loot exchange")
g.pendingVictoryReward=nil;local skipped=Reward.calculate({type="small",baseReward=3},g,true);Reward.begin(skipped,g);assert(g.voidTickets==tickets)
force(5,.99);assert(not G.ticketReward(false) and not G.ticketReward(true));force(5,.015);assert(not G.ticketReward(false) and G.ticketReward(true))
assert(P.encode({E.ITEMS.basic_plate,D.CATALOG.spirit_pebble})==catalog)
Rng.random=original
print("Void PASS: exact 100% rates/0.004% banners, 10-stage gates, no pity, tickets/gold/free/discount, all reward groups, UQ x5/gear x10/card x10 actual stats, save mid-reveal, sockets, ticket ceremony/no duplicate/no sale, catalog isolation")

local T=require("src.barter")
local G=require("src.game_state")
local Run=require("src.run_manager")
local D=require("src.deities")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local P=require("src.persistence")
local Shop=require("src.shop")
local Rng=require("src.rng")
local Deck=require("src.deck")
local function game()
    local g=G.new();g.run=Run.newRun("red_deck");g.run.ante=2;g.run.areaStage=2;g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(2,g.selectedFaction);g.run.blinds[3].status="completed"
    g.gold=10000;g.souls=30;g.voidTickets=8;g.playerHp=74;g.backpackDeities={};g.backpackConsumables={};g.backpackEquipment={};g.deities={};g.consumables={}
    g.persistentDeck={Deck.newCard(3,"hearts"),Deck.newCard(6,"spades"),Deck.newCard(9,"clubs")};g.masterDeck=g.persistentDeck
    local d=require("src.blood_shop").clone(D.CATALOG.spirit_pebble);d.evolutionLevel=2;d.rarity="rare";d.edition="foil";d.bloodPower=5
    g.backpackDeities={d};B.store(g,E.instance("basic_plate",{bloodPower=5}),24)
    g.backpackConsumables={Shop.healingItem(nil,"cons_draw").consumable,require("src.expedition").travelPermit()}
    T.create(g);return g
end
local function find(g,side,kind,id)
    for _,entry in ipairs(T.inventory(g,side)) do if entry.kind==kind and (not id or entry.item.id==id) then return entry end end
    error("Missing "..side.." "..kind.." "..tostring(id))
end
local function agree(g)
    assert(T.propose(g));local e=g.barterEvent;assert(e.status=="thinking" and not T.accept(g))
    assert(not T.update(g,.4) and e.status=="thinking");assert(T.update(g,.6))
    if e.counter then assert(T.useCounter(g)) end
    assert(e.status=="agreed");return e
end
local function snapshot(g) return assert(P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"barter")))))) end
Rng.seed(10132)
local g=game();local random=Rng.random;Rng.random=function() return .1 end
assert(T.roll(g));assert(not T.roll(g));assert(not T.roll(snapshot(g)))
g.run.ante=3;assert(not T.roll(g));g.run.ante=2;g.run.currentBlindIndex=2;assert(not T.roll(g))
g.run.currentBlindIndex=3;g.run.blinds[3].status="current";assert(not T.roll(g))
Rng.random=random

g=game();local e=g.barterEvent
for kind in pairs(T.kinds) do assert(find(g,"npc",kind) and find(g,"player",kind)) end
assert(e.counter and e.counter.npcGold<=e.gold,"NPC initiates a feasible purchase, sale or swap")
local original=P.encode({D.CATALOG,E.ITEMS})
-- Buy several unrelated things with gold, retain exact upgrades, and replenish the NPC purse.
T.clear(g);local bought={}
for _,kind in ipairs({"spn","equipment","consumable","card","resource"}) do
    local entry=find(g,"npc",kind);T.toggle(g,"npc",entry.key);bought[#bought+1]=entry
end
T.setGold(g,"player",9000);agree(g)
local before=g.gold;local npcGold=e.gold;local souls=g.souls;local tickets=g.voidTickets
assert(T.accept(g) and e.trades==1 and g.gold==before-9000 and e.gold==npcGold+9000)
assert(#g.backpackDeities==2 and #g.backpackEquipment==2 and #g.backpackConsumables-require("src.void_tickets").count(g)==3 and #g.persistentDeck==4)
assert(g.souls+g.voidTickets>souls+tickets and not T.accept(g),"commit once only")
assert(P.encode({D.CATALOG,E.ITEMS})==original,"catalogs never mutate")

-- Sell multiple categories and exact resource amounts, with a finite NPC wallet.
g=game();e=g.barterEvent;T.clear(g)
assert(T.setAmount(g,"souls",7) and T.setAmount(g,"voidTickets",2))
for _,kind in ipairs({"spn","equipment","consumable","resource"}) do local entry=find(g,"player",kind);assert(T.toggle(g,"player",entry.key)) end
assert(T.toggle(g,"player",find(g,"player","resource","barter_voidTickets").key))
T.setGold(g,"npc",e.gold);agree(g)
local price=e.draft.npcGold;before=g.gold;npcGold=e.gold
assert(T.accept(g) and g.gold==before+price and e.gold==npcGold-price and g.souls==23 and g.voidTickets==6)
assert(#g.backpackDeities==0 and #g.backpackEquipment==0 and #g.backpackConsumables-require("src.void_tickets").count(g)==1)
local transferred,plate
for _,entry in ipairs(T.inventory(g,"npc")) do
    if entry.kind=="spn" and entry.item.bloodPower==5 then transferred=entry.item end
    if entry.kind=="equipment" and entry.item.acquisitionCost==24 then plate=entry.item end
end
assert(transferred and transferred.evolutionLevel==2 and transferred.bloodPower==5 and transferred.edition=="foil")
assert(plate and plate.id=="basic_plate")

-- Lowball offers produce a counter; genuine price reductions remain possible above their floor.
g=game();e=g.barterEvent;T.clear(g);local wanted=find(g,"npc","spn")
T.toggle(g,"npc",wanted.key);T.setGold(g,"player",1);assert(T.propose(g));T.update(g,2)
assert(e.status=="counter" and e.counter and e.counter.playerGold>1 and #g.backpackDeities==1)
local opening=e.counter.playerGold
assert(T.useCounter(g));local quote=T.valuation(g,e.draft);local floor=quote.take-quote.give
assert(floor<opening);assert(T.setGold(g,"player",floor));agree(g);assert(e.draft.playerGold==floor and T.accept(g))

-- Item-for-item with no gold; an impoverished buyer gets a useful additional-item counter.
g=game();e=g.barterEvent;T.clear(g);T.toggle(g,"player",find(g,"player","consumable","cons_travel_permit").key)
T.toggle(g,"npc",find(g,"npc","consumable").key);agree(g);assert(T.accept(g) and g.gold==10000)
g=game();e=g.barterEvent;g.gold=1;T.clear(g)
T.toggle(g,"npc",find(g,"npc","spn").key);T.setGold(g,"player",1);assert(T.propose(g));T.update(g,2)
assert(e.counter and next(e.counter.player) and e.counter.playerGold<=g.gold,"NPC requests items when buyer lacks gold")
assert(T.useCounter(g) and T.accept(g))

-- They can reject unwanted objects and quote a cash price instead.
g=game();e=g.barterEvent;e.need="guard";e.temper=0;T.clear(g)
T.toggle(g,"player",find(g,"player","resource","barter_souls").key)
T.toggle(g,"npc",find(g,"npc","spn").key);assert(T.propose(g));T.update(g,2)
assert(e.counter and not next(e.counter.player) and e.counter.playerGold>0 and e.message:find("bằng vàng",1,true))
assert(T.useCounter(g) and T.accept(g))

-- Inspecting inventories is pure, and need/duplicate premiums affect the same real object.
g=game();e=g.barterEvent;T.clear(g)
local offered=find(g,"player","consumable","cons_draw")
T.toggle(g,"player",offered.key);T.setGold(g,"npc",1)
e.need=T.role(offered.kind,offered.item);local preferred=T.valuation(g,e.draft).give
e.need=e.need=="guard" and "speed" or "guard";local ordinary=T.valuation(g,e.draft).give;assert(preferred>ordinary)
e.stock[#e.stock+1]={key="npc:duplicate",kind=offered.kind,item=require("src.blood_shop").clone(offered.item)}
assert(T.valuation(g,e.draft).give<ordinary)
local inspectRng=Rng.getState()
for _,side in ipairs({"player","npc"}) do for _,entry in ipairs(T.inventory(g,side)) do T.role(entry.kind,entry.item);T.value(entry.kind,entry.item);T.describe(entry.kind,entry.item) end end
assert(Rng.getState()==inspectRng,"inventory descriptions never reroll negotiation")

-- Overpriced requests with no affordable solution can be declined without mutation.
g=game();e=g.barterEvent;g.gold=1;g.souls=0;g.voidTickets=0;g.backpackDeities={};g.backpackEquipment={};g.backpackConsumables={};g.persistentDeck={g.persistentDeck[1]}
e.stock={{key="npc:expensive",kind="consumable",item=require("src.expedition").travelPermit()}}
T.clear(g);T.toggle(g,"npc","npc:expensive");T.setGold(g,"player",1);assert(T.propose(g));T.update(g,2)
assert(e.status=="refused" and not e.counter and g.gold==1 and #e.stock==1)

-- Exact-instance removal, sockets, active slots and last-card protection.
g=game();e=g.barterEvent;g.deities[3]=g.backpackDeities[1];g.backpackDeities={}
g.consumables={g.backpackConsumables[1]};g.backpackConsumables={};g.consumables[1].loadoutSlot=2
local card=g.persistentDeck[1];card.equipments={E.instance("basic_chain"),E.instance("basic_feather")}
T.clear(g);local cardEntry=find(g,"player","card");T.toggle(g,"player",cardEntry.key)
local socket;for _,entry in ipairs(T.owned(g,"equipment")) do if entry.card==card then socket=entry;break end end
T.toggle(g,"player",socket.key);assert(not e.draft.player[cardEntry.key],"socket selection deselects its parent")
for _,entry in ipairs(T.owned(g,"equipment")) do T.toggle(g,"player",entry.key) end
-- Rebuild an unambiguous selection of both sockets, equipped SPN and equipped potion.
T.clear(g)
for _,entry in ipairs(T.owned(g)) do if entry.source=="socket" or entry.source=="active" or entry.source=="equipped" then T.toggle(g,"player",entry.key) end end
T.setGold(g,"npc",1);agree(g);assert(T.accept(g) and #card.equipments==0 and not g.deities[3] and #g.consumables==0)
T.clear(g);for _,entry in ipairs(T.owned(g,"card")) do T.toggle(g,"player",entry.key) end;T.setGold(g,"npc",1)
assert(not T.propose(g) and #g.persistentDeck==3)

-- Saving during thinking or agreement preserves NPC stock, quotes and callbacks, without rerolls.
g=game();e=g.barterEvent;T.clear(g)
for _,entry in ipairs(e.stock) do if entry.kind=="equipment" then entry.item=E.instance("basic_plate");break end end
wanted=find(g,"npc","equipment");T.toggle(g,"npc",wanted.key);T.setGold(g,"player",5000)
assert(T.propose(g));local rng=Rng.getState();g=snapshot(g);e=g.barterEvent;assert(Rng.getState()==rng and e.status=="thinking")
T.update(g,2);assert(e.status=="agreed");g=snapshot(g);e=g.barterEvent
local accepted,reason=T.accept(g);assert(accepted,reason)
local item=B.item(g.backpackEquipment[#g.backpackEquipment]);assert(type(item.onCardScore)=="function","restored armor callback")
g=snapshot(g);assert(g.barterEvent.trades==1 and not T.accept(g))

-- A stale or edited quote cannot lose or duplicate items or money.
g=game();e=g.barterEvent;T.clear(g);wanted=find(g,"npc","consumable");T.toggle(g,"npc",wanted.key);T.setGold(g,"player",1000);agree(g)
before=g.gold;wanted.item.bloodPower=5;assert(not T.accept(g) and g.gold==before)
T.clear(g);e.draft.playerGold=-1;assert(not T.propose(g));e.draft.playerGold=0/0;assert(not T.propose(g))
T.clear(g);e.draft.player.forged=true;e.draft.npcGold=1;assert(not T.propose(g))
T.clear(g);T.toggle(g,"npc",find(g,"npc","card").key);T.setGold(g,"player",100);agree(g);e.draft.playerGold=99;assert(not T.accept(g))

-- Existing event cadence, market routing, region scenery and old saves remain valid.
g=game();g.pendingBarter=true;g.pendingSoulShop=true;local shop=Shop.new();assert(Shop.enterSoulShop(g))
assert(Shop.leave(shop,g)=="shop" and g.shopMode=="large");assert(Shop.leave(shop,g)=="barter" and not g.pendingBarter)
assert(Shop.leave(shop,g)=="advance")
g.barterEvent={offers={},completed=true};g=snapshot(g);assert(g.barterEvent.version==T.version and #g.barterEvent.stock>0)
local defs=require("config.scene_definitions")
for _,region in ipairs({"human","hearts","diamonds","clubs","spades","unknown"}) do
    local name,scene=defs.resolve("barter",{stage=8,regionId=region,areaStage=8})
    assert(name=="barter" and scene.base==require("src.expedition").area(8,region).background)
end
G.resetRun(g,"red_deck");assert(not g.barterEvent and not g.pendingBarter and not next(g.barterChecked))
print("Barter PASS: five inventory types, bundled buy/sell/swap, exact quantities, needs/duplicates/budgets, real bargaining/counters/refusal, sockets/active/last-card guards, atomic/stale/double commit, save/resume/legacy/callbacks/RNG, cadence and routing")

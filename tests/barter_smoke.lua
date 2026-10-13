local T=require("src.barter")
local G=require("src.game_state")
local Run=require("src.run_manager")
local D=require("src.deities")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local P=require("src.persistence")
local Shop=require("src.shop")
local Rng=require("src.rng")
local function game()
    local g=G.new();g.run=Run.newRun("red_deck");g.run.ante=2;g.run.areaStage=2;g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(2,g.selectedFaction);g.run.blinds[3].status="completed"
    g.gold=63;g.playerHp=74;return g
end
local function spn(id,extra)
    local d={};for k,v in pairs(D.CATALOG[id]) do d[k]=v end
    for k,v in pairs(extra or {}) do d[k]=v end;return d
end
Rng.seed(10132)
local g=game();local random=Rng.random
Rng.random=function() return .1 end
assert(T.roll(g));assert(not T.roll(g));assert(g.playerHp==74 and g.gold==63)
local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(not T.roll(restored))
g=game();g.run.ante=3;assert(not T.roll(g));g.run.ante=2;g.run.currentBlindIndex=2;assert(not T.roll(g))
g=game();g.run.blinds[3].status="current";assert(not T.roll(g))
g=game();Rng.random=function() return .99 end;assert(not T.roll(g));assert(not T.roll(g));assert(g.maxPlayerHp==100)
Rng.random=random
g=game();g.backpackDeities={spn("spirit_pebble",{rarity="rare",baseRarityTier=3,evolutionLevel=2,edition="negative",editionPower=5,bloodPower=5})}
B.store(g,E.instance("basic_plate",{bloodPower=5}),24)
local original=P.encode({D.CATALOG.spirit_pebble,E.ITEMS.basic_plate})
local event=T.create(g);assert(#event.offers==2)
for _,offer in ipairs(event.offers) do assert(offer.wantedId~=offer.rewardId and offer.reason) end
local entry=T.eligible(g,event.offers[1])[1];assert(entry)
event.selectedKey=entry.key
local reward=T.reward(event.offers[1],entry.item)
assert(reward.baseRarityTier==3 and reward.evolutionLevel==2 and reward.edition=="negative" and reward.editionPower==5 and reward.bloodPower==5)
local snapshot=P.makeSnapshot(g,"barter");assert(snapshot.activeState=="barter")
local state;g,state=P.restoreSnapshot(assert(P.decode(P.encode(snapshot))));assert(state=="barter" and T.selected(g))
local id=T.reward(g.barterEvent.offers[1],T.selected(g).item).id
assert(T.accept(g));assert(#g.backpackDeities==1 and g.backpackDeities[1].id==id)
assert(g.gold==63 and g.playerHp==74 and not T.accept(g))
g,state=P.restoreSnapshot(P.makeSnapshot(g,"barter"));assert(state=="barter" and g.barterEvent.completed and not T.accept(g))
g=game();B.store(g,E.instance("basic_plate",{bloodPower=5}),24);event=T.create(g)
for i,o in ipairs(event.offers) do if o.kind=="equipment" then event.offerIndex=i end end
entry=T.eligible(g,event.offers[event.offerIndex])[1];event.selectedKey="forged";assert(not T.accept(g) and #g.backpackEquipment==1)
event.selectedKey=entry.key;assert(T.accept(g));assert(#g.backpackEquipment==1 and g.backpackEquipment[1].bloodPower==5 and g.backpackEquipment[1].investment==24)
local item=B.item(g.backpackEquipment[1]);assert(type(item.onCardScore)=="function")
g=game();g.deities[2]=spn("spirit_pebble");event=T.create(g);entry=T.eligible(g,event.offers[1])[1];event.selectedKey=entry.key
assert(T.accept(g));assert(not g.deities[2] and #g.backpackDeities==1)
g=game();local card=require("src.deck").newCard(7,"hearts");card.equipments={E.instance("basic_plate")};g.persistentDeck={card}
event=T.create(g);for i,o in ipairs(event.offers) do if o.kind=="equipment" then event.offerIndex=i end end
entry=T.eligible(g,event.offers[event.offerIndex])[1];event.selectedKey=entry.key
assert(T.accept(g) and #card.equipments==0 and #g.backpackEquipment==1)
assert(P.encode({D.CATALOG.spirit_pebble,E.ITEMS.basic_plate})==original,"Shared catalogs must stay intact")
g=game();g.pendingBarter=true;g.pendingSoulShop=true;g.backpackDeities={spn("spirit_pebble")}
local shop=Shop.new();assert(Shop.enterSoulShop(g));assert(Shop.leave(shop,g)=="shop" and g.shopMode=="large")
assert(Shop.leave(shop,g)=="barter" and not g.pendingBarter and g.barterEvent and g.run.ante==2)
assert(Shop.leave(shop,g)=="advance")
local defs=require("config.scene_definitions")
for _,region in ipairs({"human","hearts","diamonds","clubs","spades","unknown"}) do
    local name,scene=defs.resolve("barter",{stage=8,regionId=region,areaStage=8})
    assert(name=="barter" and scene.base==require("src.expedition").area(8,region).background)
end
G.resetRun(g,"red_deck");assert(not g.barterEvent and not g.pendingBarter and not next(g.barterChecked))
print("Barter PASS: once per even stage, fixed offers, fair tiers, exact ownership, atomic swaps, active/socket items, x5/edition/evolution/receipts, save/resume, soul-large-event routing, combat backgrounds, reset")

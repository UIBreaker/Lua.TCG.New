local Shop=require("src.shop")
local T=require("src.barter")
local D=require("src.deities")
local E=require("src.equipment")
local B=require("src.basic_equipment")
local G=require("src.game_state")
local Run=require("src.run_manager")
local P=require("src.persistence")
local Blood=require("src.blood_shop")
local function game()
    local g=G.new();g.run=Run.newRun("red_deck");g.run.ante=6
    g.gold=10000;g.deities={};g.backpackDeities={};g.backpackEquipment={};g.backpackConsumables={}
    local Deck=require("src.deck")
    g.persistentDeck={Deck.newCard(2,"hearts"),Deck.newCard(3,"spades")};g.masterDeck=g.persistentDeck
    return g
end
local g=game()
local spn=Blood.clone(D.CATALOG.spirit_pebble);D.setRarity(spn,"uncommon")
assert(Shop.getMarketValue(spn,"spn")==24 and T.value("spn",spn)==24)
assert(Shop.getSacrificePrice(spn,"deity")==14,"legacy SPNs use current rarity prices")
spn.cost=6 -- Shop-generated instances already have their rarity multiplier.
assert(Shop.getMarketValue(spn,"spn")==24,"do not multiply rarity twice")
assert(Shop.buyItem({items={{category="deity",cost=24,deity=spn}}},1,g))
assert(spn.acquisitionCost==24 and spn.acquisitionMarketValue==24)
g=assert(P.restoreSnapshot(P.decode(P.encode(P.makeSnapshot(g,"shop")))))
spn=g.backpackDeities[1]
assert(spn.acquisitionCost==24 and Shop.getSacrificePrice(spn,"deity")==14)
local gold=g.gold
assert(Shop.sellStoredItem(g,"reserve_deity",1) and g.gold==gold+14)
g.backpackDeities={spn};D.evolve(spn)
assert(Shop.getSacrificePrice(spn,"deity")>14,"permanent evolution increases resale")

for _,currency in ipairs({"gold","blood","souls"}) do
    g=game();g.playerHp=100;g.souls=100
    local offer=Shop.healingItem(nil,"cons_draw");offer.cost=12
    if currency~="gold" then offer.currency=currency end
    assert(Shop.buyItem({mode=currency=="blood" and "blood_small" or "medicine",soulMode=currency=="souls",items={offer}},1,g))
    local item=g.backpackConsumables[1]
    assert(Shop.getSacrificePrice(item,"consumable")== (currency=="gold" and 7 or 0))
end

-- A cheap purchase cannot be laundered through barter, sockets or card resale.
g=game();local offer=Shop.discountedEquipment(E.ITEMS.crafted_runner,1)
offer.cost=5;offer.backpack=true
assert(Shop.buyItem({items={offer}},1,g))
local entry=g.backpackEquipment[1]
assert(B.resale(entry)==3)
T.create(g);T.clear(g);g.barterEvent.need=T.role("equipment",B.item(entry))
g.barterEvent.stock={}
assert(T.toggle(g,"player",T.owned(g,"equipment")[1].key));T.setGold(g,"npc",1)
assert(T.valuation(g,g.barterEvent.draft).give<=5)
local card=g.persistentDeck[1];local bare=Shop.getCardSellPrice(card)
B.store(g,E.instance("gem_blast"),0)
assert(B.attach(g,2,card) and Shop.getCardSellPrice(card)==bare)
assert(B.detach(g,card,1) and B.resale(g.backpackEquipment[2])==0)

-- Buy at the negotiated floor, save, and sell through either real selling route.
for _,kind in ipairs({"spn","equipment","consumable","card"}) do
    g=game();T.create(g);T.clear(g)
    local wanted
    for _,stock in ipairs(g.barterEvent.stock) do if stock.kind==kind then wanted=stock;break end end
    assert(wanted)
    local fair=T.value(kind,wanted.item)
    assert(T.toggle(g,"npc",wanted.key));T.setGold(g,"player",10000)
    local floor=T.valuation(g,g.barterEvent.draft).take
    assert(floor>=fair)
    T.setGold(g,"player",floor);assert(T.propose(g));T.update(g,2)
    assert(g.barterEvent.status=="agreed" and T.accept(g))
    g=assert(P.restoreSnapshot(P.makeSnapshot(g,"barter")))
    T.clear(g)
    local owned
    for _,held in ipairs(T.owned(g,kind)) do if held.item.id==wanted.item.id then owned=held end end
    assert(owned and owned.item.acquisitionCost>0)
    assert(T.toggle(g,"player",owned.key));T.setGold(g,"npc",1)
    assert(T.valuation(g,g.barterEvent.draft).give<floor,"no instant barter roundtrip profit")
    local resale=kind=="equipment" and B.resale(g.backpackEquipment[owned.index])
        or kind=="card" and Shop.getCardSellPrice(owned.item)
        or Shop.getSacrificePrice(owned.item,kind=="spn" and "deity" or "consumable")
    assert(resale>0 and resale<floor,"bartered items retain a useful resale receipt")
end

for stage=1,10 do
    g=game();g.run.ante=stage
    for _=1,30 do
        T.create(g)
        for _,entry in ipairs(g.barterEvent.stock) do if entry.kind=="spn" then
            local tier=D.getRarityTier(entry.item)
            assert(tier<=5 and (tier<4 or stage>=3) and (tier<5 or stage>=6))
        end end
    end
end
print("Economy resale PASS: 24->14 gold, rarity/upgrades, purchase receipts/save, non-gold/free/discount guards, barter floor and roundtrips, C-L stage gates")

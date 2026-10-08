local G=require("src.game_state")
local I=require("src.inventory")
local D=require("src.deities")
local Shop=require("src.shop")
local Run=require("src.run_manager")
local P=require("src.persistence")
local Rail=require("ui.inventory_rail")
local g=G.new()
-- No fixed ceiling; both expansions are single-use and persist for the run.
for _=1,200 do
    g.consumables={Run.createSpnSlotCard()};assert(I.useUtility(g,1) and #g.consumables==0)
    g.consumables={Run.createConsumableSlotCard()};assert(I.useUtility(g,1) and #g.consumables==0)
end
assert(D.getMaxSlots(g)==205 and I.limit(g)==203)
local saved=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(D.getMaxSlots(saved)==205 and I.limit(saved)==203)
saved.deities={{id="negative",edition="negative"}};assert(D.getMaxSlots(saved)==206)
-- Purchases and pending rewards must honor expanded capacity.
local shop=Shop.new();g.gold=100
g.consumables={{},{},{}}
shop.items={Shop.healingItem("upper","armor_potion_large")}
assert(Shop.buyItem(shop,1,g) and #g.consumables==4)
g.pendingEvolutionCards=5;g.run={};Run.deliverEvolutionRewards(g.run,g)
assert(#g.consumables==9 and g.pendingEvolutionCards==0)
-- Restoratives respect HP/armor caps and retain the card when already full.
for _,id in ipairs({"healing_potion_small","healing_potion","healing_potion_large"}) do
    local c=Shop.healingItem("upper",id).consumable
    g.playerHp=10;g.maxPlayerHp=100;g.consumables={c}
    assert(I.useUtility(g,1) and g.playerHp==10+c.healAmt and #g.consumables==0)
    g.playerHp=99;g.consumables={c};assert(I.useUtility(g,1) and g.playerHp==100)
    g.consumables={c};assert(not I.useUtility(g,1) and #g.consumables==1)
end
for _,id in ipairs({"armor_potion_small","armor_potion_large"}) do
    local c=Shop.healingItem("upper",id).consumable
    g.playerArmor=0;g.consumables={c}
    assert(I.useUtility(g,1) and g.playerArmor==c.armorAmt and g.playerShield==g.playerArmor)
    g.playerArmor=require("config.card_ability_data").armorCap-1;g.consumables={c};assert(I.useUtility(g,1) and g.playerArmor==require("config.card_ability_data").armorCap)
    g.consumables={c};assert(not I.useUtility(g,1) and #g.consumables==1)
end
-- Scroll reveals higher logical indices without shrinking or moving the panels.
Rail.offsets={spn=0,consumable=0}
assert(Rail.localIndex("spn",1,g)==1 and not Rail.localIndex("spn",7,g))
assert(not Rail.scroll(g,"shop",1100,200,-1),"shop rail replaced by backpack")
assert(Rail.scroll(g,"playing",1100,200,-1) and Rail.localIndex("spn",7,g)==1)
assert(Rail.scroll(g,"playing",1100,400,-1) and Rail.localIndex("consumable",4,g)==1)
assert(Rail.canSwipe(g,"playing",1100,400),"battle inventory accepts touch swipe")
assert(not Rail.canSwipe(g,"playing",100,400),"swipe outside inventory does not hijack card gestures")
Rail.reveal("consumable",203,g);assert(Rail.localIndex("consumable",203,g)==3)
Rail.reveal("spn",205,g);assert(Rail.localIndex("spn",205,g)==6)
-- All six normal-shop utility offers are obtainable.
local seen={}
for _=1,150 do
    Shop.refresh(shop,g)
    for _,item in ipairs(shop.items) do if item.consumable then seen[item.id]=true end end
end
for _,potion in ipairs(Shop.POTIONS) do assert(seen[potion.id],potion.id) end
assert(seen.soul_reaper)
G.resetRun(g);assert(I.limit(g)==3 and D.getMaxSlots(g)==5)
print("Inventory expansion passed: 200 upgrades, capacities, rewards, save/reset, scrolling and all potions")

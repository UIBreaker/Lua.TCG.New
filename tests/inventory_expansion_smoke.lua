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
-- Purchases and pending rewards go to storage; equip explicitly into expanded slots.
local shop=Shop.new();g.gold=100
g.consumables={{},{},{}}
shop.items={Shop.healingItem("upper","armor_potion_large")}
assert(Shop.buyItem(shop,1,g) and #g.consumables==3 and #g.backpackConsumables==1)
assert(require("src.loadout").move(g,"consumable","reserve",1,203,false))
g.pendingEvolutionCards=5;g.run={};Run.deliverEvolutionRewards(g.run,g)
assert(#g.consumables==4 and #g.backpackConsumables==5 and g.pendingEvolutionCards==0)
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
-- The original fan includes every logical slot, without a 6/3-card window.
assert(Rail.localIndex("spn",1,g)==1 and Rail.localIndex("spn",205,g)==205)
assert(not Rail.scroll(g,"shop",1100,200,-1),"shop rail replaced by backpack")
assert(not Rail.scroll(g,"playing",1100,200,-1) and Rail.localIndex("spn",16,g)==16)
assert(not Rail.scroll(g,"playing",1100,400,-1) and Rail.localIndex("consumable",203,g)==203)
assert(not Rail.canSwipe(g,"playing",1100,400),"full fan does not hide cards on swipe")
local _,last,total=Rail.range("spn",g);assert(last==total and total==205)
-- All six normal-shop utility offers are obtainable.
local seen={}
for _=1,150 do
    Shop.refresh(shop,g)
    for _,item in ipairs(shop.items) do if item.consumable then seen[item.id]=true end end
end
for _,potion in ipairs(Shop.POTIONS) do assert(seen[potion.id],potion.id) end
assert(seen.soul_reaper)
G.resetRun(g);assert(I.limit(g)==3 and D.getMaxSlots(g)==5)
print("Inventory expansion passed: 200 upgrades, capacities, rewards, save/reset, complete fans and all potions")

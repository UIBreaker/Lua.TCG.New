local Shop=require("src.shop")
local G=require("src.game_state")
local Run=require("src.run_manager")
local P=require("src.persistence")
local g=G.new();g.run=Run.newRun("red_deck");g.run.stats.blindsWon=4;g.gold=1000
Shop.enterAfterCombat(g)
local shop=Shop.new();Shop.refresh(shop,g)
local function layout(swapped)
    assert(shop.items[1].category==(swapped and "equipment" or "deity"))
    assert(shop.items[2].category==(swapped and "deity" or "equipment"))
    assert(shop.items[1].bay==1 and shop.items[2].bay==2)
end
layout(false)
assert(Shop.reroll(shop,g));layout(true)
local loaded=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(loaded.smallShopSwapped)
Shop.refresh(shop,loaded);layout(true)
g=loaded
assert(Shop.reroll(shop,g));layout(false)
local count=shop.rerollCount;local items=shop.items
g.gold=0;assert(not Shop.reroll(shop,g) and shop.items==items and not g.smallShopSwapped)
g.freeRerolls=1;assert(Shop.reroll(shop,g));layout(true)
assert(shop.rerollCount==count and g.gold==0)
g.vouchers={v_welcome=true};assert(Shop.reroll(shop,g));layout(false)
assert(shop.rerollCount==count and g.gold==0)
g.gold=1000;assert(Shop.buyItem(shop,2,g));assert(Shop.reroll(shop,g));layout(true)
Shop.enterAfterCombat(g);Shop.resetReroll(shop);Shop.refresh(shop,g);layout(false)
g.smallShopSwapped=true;G.resetRun(g);assert(not g.smallShopSwapped)
print("Small shop rotation PASS: paid/free/voucher rerolls, failed purchase guard, refill, display bays, save/load and new-visit/reset")
return true

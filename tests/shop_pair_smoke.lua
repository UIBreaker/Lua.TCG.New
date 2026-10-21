local Shop=require("src.shop")
local Game=require("src.game_state")
local Run=require("src.run_manager")
local Deck=require("src.deck")
local P=require("src.persistence")
local Rng=require("src.rng")
local function fresh(wins)
    local g=Game.new("red_deck");g.run=Run.newRun("red_deck")
    g.run.stats.blindsWon=wins;g.gold=500;g.souls=20
    g.persistentDeck={Deck.newCard(4,"hearts")}
    return g,Shop.new()
end
local seen={}
for seed=1,100 do
    local g,shop=fresh(seed==1 and 1 or seed+1)
    Rng.seed(seed*7919)
    Shop.enterAfterCombat(g)
    local companion=g.pendingCompanionShop
    assert(g.shopMode=="small" and companion and companion~="small" and companion~="large" and companion~="soul")
    seen[companion]=true;g.pendingBarter=nil
    Shop.refresh(shop,g)
    local loaded,state=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
    assert(state=="shop" and loaded.shopMode=="small" and loaded.pendingCompanionShop==companion)
    g=loaded
    local ante,index,gold,souls,hp=g.run.ante,g.run.currentBlindIndex,g.gold,g.souls,g.playerHp
    assert(Shop.leave(shop,g)=="shop" and g.shopMode==companion and shop.mode==companion)
    assert(not g.pendingCompanionShop and g.run.ante==ante and g.run.currentBlindIndex==index)
    assert(g.gold==gold and g.souls==souls and g.playerHp==hp,"shop transition pays/charges nothing")
    loaded,state=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
    assert(state=="shop" and loaded.shopMode==companion and not loaded.pendingCompanionShop)
    assert(Shop.leave(shop,loaded)=="advance" and not loaded.pendingCompanionShop,"exactly two ordinary shops")
end
for i=2,#Shop.AFTER_COMBAT_MARKETS do assert(seen[Shop.AFTER_COMBAT_MARKETS[i]],"every companion market can appear") end
local g,shop=fresh(1)
Shop.enterAfterCombat(g);Shop.refresh(shop,g)
assert(shop.items[2].starterOffer and shop.items[1].category=="deity")
local companion=g.pendingCompanionShop
assert(Shop.reroll(shop,g) and g.pendingCompanionShop==companion,"reroll preserves companion choice")
g.pendingBarter=true
assert(Shop.leave(shop,g)=="shop" and g.pendingBarter,"events wait until after companion")
assert(Shop.leave(shop,g)=="barter" and not g.pendingBarter)
g,shop=fresh(3);g.run.ante=2;g.run.currentBlindIndex=3
g.pendingCompanionShop="cards";g.pendingSoulShop=true
Shop.enterAfterCombat(g);Shop.refresh(shop,g)
assert(g.shopMode=="soul" and not g.pendingCompanionShop)
assert(Shop.leave(shop,g)=="shop" and g.shopMode=="large")
g.pendingBarter=nil
assert(Shop.leave(shop,g)=="advance","boss chain has no ordinary companion")
g,shop=fresh(5);g.bloodDomain={}
Shop.enterAfterCombat(g);Shop.refresh(shop,g)
assert(g.shopMode=="small" and g.pendingCompanionShop)
assert(Shop.leave(shop,g)=="shop" and g.shopMode~="small")
g,shop=fresh(4);g.shopMode="small"
assert(Shop.leave(shop,g)=="advance","old saves without a queued shop remain compatible")
g.pendingCompanionShop="cards";Game.resetRun(g);assert(not g.pendingCompanionShop)
print("Shop pair PASS: first/later fights, all 5 companions, save/load both visits, fixed reroll choice, no duplicate charge/reward/advance, delayed events, boss unchanged, blood domain, old saves/reset")

local Shop=require("src.shop")
local Game=require("src.game_state")
local Run=require("src.run_manager")
local Rng=require("src.rng")
local E=require("src.equipment")
local Blood=require("src.blood_shop")
local P=require("src.persistence")
local function game()
    local g=Game.new();g.run=Run.newRun("red_deck")
    g.gold,g.souls,g.playerHp,g.maxPlayerHp=100000,100000,100000,100000
    return g
end
assert(Shop.PRICE_MULTIPLIER==4)
assert(Shop.priceItem({cost=2,equipment=E.ITEMS.basic_plate})==8)
assert(Shop.priceItem(Shop.healingItem(nil,"healing_potion"))==12)
assert(Shop.priceItem(Shop.healingItem(nil,"healing_potion_large"))==21)
assert(Shop.priceItem({cost=12,deity={rarity="epic"}})==72)
assert(Shop.priceItem({cost=20,deity={rarity="legendary"}})==120)
assert(Shop.priceItem({cost=22,currency="souls"})==44)
for id,eq in pairs(E.ITEMS) do if not eq.soulOnly then
    if not eq.basic then
        assert(Shop.priceItem({cost=eq.cost,equipment=eq})==math.ceil(Shop.craftingCost(id)*1.35))
    end
    local offer=Shop.discountedEquipment(eq,1,0)
    if eq.basic or (eq.craftTier or 99)<=1 then assert(offer.free and Shop.priceItem(offer)==0)
    else assert(not offer.free and Shop.priceItem(offer)>0) end
end end
assert(Shop.priceItem(Blood.offer({cost=2,equipment=E.ITEMS.basic_plate}))==32)
assert(Shop.priceItem(Blood.offer({cost=4,deity={rarity="common"}}))==64)
for _,id in ipairs({"healing_potion","healing_potion_large"}) do
    local item=Blood.offer(Shop.healingItem(nil,id))
    assert(Shop.priceItem(item)>item.consumable.healAmt,"blood healing cannot refund its HP cost")
end
for _,mode in ipairs({"small","consumable","equipment","spn","medicine","cards","large","soul","blood_small","blood_large"}) do
    Rng.seed(90147)
    local g=game();g.shopMode=mode
    local shop=Shop.new();Shop.refresh(shop,g)
    for _,item in ipairs(shop.items) do
        assert(item.cost>=0 and item.cost==math.floor(item.cost))
        if item.originalCost then assert(item.cost<=item.originalCost) end
        if item.currency=="blood" then assert(not item.consumable or item.consumable.category~="bed") end
    end
    local item=shop.items[1]
    local currency=item.currency=="blood" and "playerHp" or item.currency=="souls" and "souls" or "gold"
    local before=g[currency]
    assert(Shop.buyItem(shop,1,g),mode)
    assert(g[currency]==before-item.cost,mode.." must charge the displayed price")
end
for _,stage in ipairs({1,3,6,10,15,21}) do
    local g=game();g.run.ante=stage
    for _,mode in ipairs({"small","large","spn","blood_small","blood_large"}) do
        g.shopMode=mode
        for seed=1,60 do
            Rng.seed(seed);local shop=Shop.new();Shop.refresh(shop,g)
            for _,item in ipairs(shop.items) do if item.deity then
                assert(stage>=(Shop.SPN_STAGE_GATES[item.deity.rarity] or 1),"premature SPN "..item.deity.rarity)
            end end
        end
    end
end
local g=game();g.run.stats.blindsWon=1;Shop.enterAfterCombat(g)
assert(g.shopMode=="small")
local shop=Shop.new();Shop.refresh(shop,g)
assert(shop.items[1].starterOffer and shop.items[1].cost==12)
assert(shop.items[1].section=="stall" and shop.items[1].bay==1,"starter gear stays in the small-shop display bay")
g.gold=11;assert(not Shop.buyItem(shop,1,g) and not g.run.stats.starterGearPurchased)
g.gold=30;assert(Shop.reroll(shop,g));assert(shop.items[1].starterOffer)
assert(shop.items[1].section=="stall" and shop.items[1].bay==1,"rerolled starter gear keeps its display bay")
assert(Shop.buyItem(shop,1,g) and g.run.stats.starterGearPurchased)
g=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(g.run.stats.starterGearPurchased)
Shop.refresh(shop,g)
for _,item in ipairs(shop.items) do assert(not item.starterOffer) end
print("Selective shop balance PASS: ten markets, recipe pricing, stage gates, saved starter offer, no free T2+, no blood heal arbitrage")
local A=require("src.card_abilities")
for _,case in ipairs({{1,false,20},{1,true,40},{6,false,15},{6,true,30},{25,true,30}}) do
    local g=game();g.maxPlayerHp=100;g.playerHp=10;g.abilityCombat={}
    g.monster={hp=0,maxHp=100,stage=case[1],isBoss=case[2]}
    A.combatWin(g)
    assert(g.playerHp==10+case[3] and g.abilityCombat.victoryRecovery==case[3])
    A.combatWin(g);assert(g.playerHp==10+case[3],"victory rest is paid once")
end
print("Victory recovery PASS: early/late, normal/boss and duplicate payment guard")
local bindings=require("src.spn_basics").cardGames
collectgarbage("collect")
local function countBindings() local n=0;for _ in pairs(bindings) do n=n+1 end;return n end
local before=countBindings()
for i=1,100 do
    local temporary={hand={{rank=2}}}
    require("src.spn_basics").bind(temporary)
end
collectgarbage("collect")
assert(countBindings()<=before,"discarded preview game/card cycles must be collectible in LuaJIT")
print("Preview context retention PASS")
local traveler=game();traveler.gold=27
traveler.backpackConsumables={require("src.expedition").travelPermit()}
assert(Run.beginTravel(traveler,"backpackConsumables",1,"BLIND_SELECT"))
assert(Run.resolveTravel(traveler.run,traveler,"sell"))
assert(traveler.gold==277 and traveler.run.stats.totalGoldEarned==250 and #traveler.backpackConsumables==0)
local saved=P.restoreSnapshot(P.makeSnapshot(traveler,"BLIND_SELECT"))
assert(saved.gold==277 and not require("src.expedition").hasTravelPermit(saved))
print("Travel permit sale PASS: 250 gold, consumed once, no respawn on reload")
return true

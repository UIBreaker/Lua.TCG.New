local Shop=require("src.shop")
local G=require("src.game_state")
local P=require("src.persistence")
local Rng=require("src.rng")
local Run=require("src.run_manager")
local Reward=require("src.reward_system")
local E=require("src.equipment")
local D=require("src.deck")
local Inventory=require("src.inventory")
Rng.seed(4271)
local game=G.new();game.run=Run.newRun("red_deck");game.gold=10000
local shop=Shop.new()
local types,rarities,equipment,consumables={},{},{},{}
local retail=Shop.getRetailConsumables()
local expected={}
for _,item in ipairs(retail) do
    assert(item.consumable and item.consumable.id==item.id and item.cost>0)
    expected[item.id]=true
    local pack
    for _,def in ipairs(Shop.PACK_CATALOG) do if def.packType==item.sourcePack then pack=def end end
    assert(item.cost==math.ceil(pack.cost*1.2))
end
for _=1,600 do
    Shop.enterAfterCombat(game)
    types[game.shopMode]=true
    assert(game.shopMode~="large" and game.shopMode~="soul")
    Shop.refresh(shop,game)
    assert(shop.mode==game.shopMode and not shop.soulMode and #shop.items<=8)
    if shop.mode=="small" then
        local cats={}
        for _,item in ipairs(shop.items) do cats[item.category]=true end
        assert(cats.deity and cats.equipment and cats.card and cats.voucher and cats.pack)
        assert(#shop.items==8)
    elseif shop.mode=="consumable" then
        assert(#shop.items==8)
        for _,item in ipairs(shop.items) do assert(item.consumable and expected[item.id]);consumables[item.id]=true end
    elseif shop.mode=="equipment" then
        assert(#shop.items==8)
        local seen={}
        for i,item in ipairs(shop.items) do
            assert(item.category=="equipment" and item.backpack and not item.equipment.soulOnly and not seen[item.id])
            assert((i<=4)==(item.equipment.basic==true))
            seen[item.id]=true;equipment[item.id]=true
        end
    elseif shop.mode=="spn" then
        assert(#shop.items==6)
        local seen={}
        for _,item in ipairs(shop.items) do
            assert(item.category=="deity" and not seen[item.id] and item.deity.rarity==item.rarity)
            seen[item.id]=true;rarities[item.rarity]=true
        end
    elseif shop.mode=="medicine" then
        assert(#shop.items==#Shop.POTIONS)
        for i,item in ipairs(shop.items) do assert(item.id==Shop.POTIONS[i].id and item.consumable) end
    elseif shop.mode=="cards" then
        assert(#shop.items==8)
        for _,item in ipairs(shop.items) do assert(item.category=="card" and item.card) end
    end
end
for _,mode in ipairs(Shop.AFTER_COMBAT_MARKETS) do assert(types[mode],mode) end
for _,rarity in ipairs(require("src.deities").RARITIES) do assert(rarities[rarity.id],rarity.id) end
for id in pairs(expected) do assert(consumables[id],"Missing retail card: "..id) end
for id,eq in pairs(E.ITEMS) do if not eq.soulOnly then assert(equipment[id],"Missing equipment: "..id) end end

-- Capacity failures keep both stock and money; individual purchases store the real card.
game.shopMode="consumable";Shop.refresh(shop,game)
local card,cost=shop.items[1].consumable,shop.items[1].cost
game.consumables={{},{},{}};local gold=game.gold
assert(not Shop.buyItem(shop,1,game) and game.gold==gold and #shop.items==8)
game.consumables={};assert(Shop.buyItem(shop,1,game))
assert(game.consumables[1]==card and game.gold==gold-cost and #shop.items==7)
local loaded,state=P.restoreSnapshot(P.makeSnapshot(game,"shop"))
assert(state=="shop" and loaded.shopMode=="consumable" and loaded.consumables[1].id==card.id)
for _,mode in ipairs(Shop.AFTER_COMBAT_MARKETS) do
    game.shopMode=mode;Shop.resetReroll(shop);Shop.refresh(shop,game)
    local before=game.gold
    assert(Shop.reroll(shop,game) and game.gold==before-5 and game.shopMode==mode and shop.mode==mode)
    local saved=P.restoreSnapshot(P.makeSnapshot(game,"shop"));assert(saved.shopMode==mode)
end

game.shopMode="equipment";Shop.refresh(shop,game)
local offer=shop.items[5];assert(Shop.buyItem(shop,5,game))
assert(game.backpackEquipment[#game.backpackEquipment].id==offer.equipment.id)
game.shopMode="spn";Shop.refresh(shop,game)
local spn=shop.items[1].deity;assert(Shop.buyItem(shop,1,game))
assert(game.deities[1].id==spn.id and game.deities[1].rarity==spn.rarity)
game.shopMode="medicine";Shop.refresh(shop,game)
game.consumables={};game.playerHp=20
assert(Shop.buyItem(shop,1,game) and Inventory.useUtility(game,1) and game.playerHp==45)
for i,item in ipairs(shop.items) do if item.id=="cons_bed" then assert(Shop.buyItem(shop,i,game));break end end
assert(Inventory.useBed(game,1) and game.playerHp==game.maxPlayerHp)

-- A boss pays out once. Leaving the soul shop does not advance its completed fight.
game.run.currentBlindIndex=3;game.run.blinds[3].status="completed"
Reward.begin(Reward.calculate({type="boss",baseReward=5},game),game)
Shop.enterAfterCombat(game);Shop.refresh(shop,game)
assert(game.shopMode=="soul" and shop.soulMode and not game.pendingSoulShop)
local ante,index,gold,souls=game.run.ante,game.run.currentBlindIndex,game.gold,game.souls
assert(Shop.leave(shop,game)=="shop" and game.shopMode=="large" and shop.mode=="large")
assert(game.run.ante==ante and game.run.currentBlindIndex==index and game.gold==gold and game.souls==souls)
assert(#shop.items>8 and not shop.soulMode)
loaded,state=P.restoreSnapshot(P.makeSnapshot(game,"shop"))
assert(state=="shop" and loaded.shopMode=="large")
assert(Shop.leave(shop,game)=="advance")
Run.advanceBlind(game.run,game)
assert(game.run.ante==ante+1 and game.run.currentBlindIndex==1)
print("Shop markets smoke PASS: 6 random shops, complete retail/equipment pools, 8 SPN rarities, purchases, potion/bed use, rerolls, saves, soul -> large -> next fight")

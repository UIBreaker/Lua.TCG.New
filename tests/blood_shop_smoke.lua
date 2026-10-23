local Shop=require("src.shop")
local Blood=require("src.blood_shop")
local G=require("src.game_state")
local D=require("src.deck")
local E=require("src.equipment")
local SPN=require("src.deities")
local P=require("src.persistence")
local B=require("src.basic_equipment")
local Rng=require("src.rng")
local function game()
    local g=G.new();g.run=require("src.run_manager").newRun("red_deck");g.gold=777;g.souls=50;g.playerHp=2000;g.maxPlayerHp=2000;return g
end
Rng.seed(72013)
local g=game();local shop=Shop.new()
local original=P.encode({E.ITEMS.basic_plate.params,SPN.CATALOG.spirit_pebble,Shop.POTIONS})
for _,mode in ipairs({"blood_small","blood_large"}) do
    g.shopMode=mode;Shop.refresh(shop,g)
    assert(#shop.items==(mode=="blood_small" and 8 or 16) and shop.bloodMode)
    local categories={}
    for _,item in ipairs(shop.items) do assert(item.currency=="blood" and item.bloodPower==5 and item.cost>=16);categories[item.category]=true end
    assert(categories.deity and categories.equipment and categories.card and categories.pack and categories.voucher and categories.hand_expansion)
    local hp=g.playerHp;local gold=g.gold
    local first=shop.items[1];assert(Shop.buyItem(shop,1,g))
    assert(g.playerHp==hp-first.cost and g.gold==gold and g.backpackDeities[#g.backpackDeities].bloodPower==5)
    g.playerHp=2000;g.freeRerolls=5;g.vouchers.v_welcome=true
    local cost=Shop.getRerollCost(shop,g);assert(cost>0)
    assert(Shop.reroll(shop,g) and g.playerHp==2000-cost and g.gold==gold and g.freeRerolls==5)
    assert(Shop.getRerollCost(shop,g)==cost+10)
    g.vouchers.v_welcome=nil
end
assert(original==P.encode({E.ITEMS.basic_plate.params,SPN.CATALOG.spirit_pebble,Shop.POTIONS}),"global catalogs must remain unchanged")
local offer=Blood.offer({category="equipment",equipment=E.ITEMS.basic_plate,backpack=true,name="Tấm Sắt",cost=2})
shop={mode="blood_small",items={offer}}
g.playerHp=offer.cost;local gold=g.gold
assert(not Shop.buyItem(shop,1,g) and g.playerHp==offer.cost and g.gold==gold and #shop.items==1)
g.playerHp=offer.cost+.5;assert(not Shop.buyItem(shop,1,g) and g.playerHp==offer.cost+.5,"fractional HP must also leave at least one HP")
g.playerHp=offer.cost+1;assert(Shop.buyItem(shop,1,g) and g.playerHp==1 and g.gold==gold)
local receipt=g.backpackEquipment[#g.backpackEquipment];assert(receipt.bloodPower==5 and receipt.investment==0)
local eq=B.item(receipt);assert(eq.onCardScore(D.newCard(2,"hearts"),{},1,{}).addArmor==10)
local card=Blood.reward(D.newCard(2,"hearts"));assert(card.baseChips==10 and D.getCardAttackSpeed(card)==D.getAttackSpeed(2)*5)
card.equipments={eq};g.persistentDeck={card};g.hand={card};g.deities={SPN.CATALOG.spirit_pebble};g.masterDeck=g.persistentDeck
local spn=Blood.reward(SPN.CATALOG.spirit_pebble)
assert(SPN.scaleEffect(spn,spn.onHandScored({type={id="high_card"}},{})).addChips==100)
g.backpackDeities={spn}
local loaded=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(loaded.backpackDeities[1].bloodPower==5 and loaded.persistentDeck[1].bloodPower==5)
assert(loaded.persistentDeck[1].equipments[1].onCardScore(card,{},1,{}).addArmor==10)
assert(B.item(loaded.backpackEquipment[#loaded.backpackEquipment]).bloodPower==5)
assert(Shop.applyEdition(card,"foil",5) and require("src.card_effects").getScoreBonus(card).damage==100)
local negative=Blood.reward(SPN.CATALOG.spirit_pebble);negative.edition="negative";negative.editionPower=5;g.deities={negative}
assert(SPN.getMaxSlots(g)==SPN.BASE_SLOTS+5)
local slots=Blood.reward(require("src.run_manager").createSpnSlotCard());g.consumables={slots};local previous=g.extraDeitySlots
assert(require("src.inventory").useUtility(g,1) and g.extraDeitySlots==previous+5)
local upgrade=Blood.reward(require("src.run_manager").createSocketCard());g.consumables={upgrade}
assert(require("src.inventory").useCardUpgrade(g,1,card) and E.getMaxSlots(card)==8)
local crafted=game();B.store(crafted,Blood.reward(E.ITEMS.basic_bandage),0);B.store(crafted,E.ITEMS.basic_plate,2)
local recipe;for _,r in ipairs(B.recipes) do if r.id=="crafted_guard" then recipe=r end end
assert(recipe and B.craft(crafted,recipe));assert(B.item(crafted.backpackEquipment[1]).bloodPower==5)
assert(E.getDescription(E.instance("gem_blast",{bloodPower=5})):find("đúng 3",1,true),"activation counts are not scaled")
local king=Blood.reward(D.newCard(13,"clubs"));king.disableFactionPassives=true
local result=require("src.scoring").calculate({type={id="high_card"},chips=1,mult=1,scoringCards={king},unscoredCards={}}, {}, {playerHp=100,hand={king}})
assert(result.totalChips==king.baseChips+1 and result.totalMult==1,"blood stats do not restore removed royal-role bonuses")
local opening=Shop.openPack({packType="arcana",bloodPower=5},g)
for _,item in ipairs(opening.cards) do assert(item.bloodPower==5 and item.onCardScore) end
local potion=Blood.reward(Shop.healingItem(nil,"healing_potion").consumable)
assert(potion.healAmt==125)
g.consumables={potion};g.playerHp=10;assert(require("src.inventory").useUtility(g,1) and g.playerHp==135)
g.monster={hp=9999,maxHp=9999,armor=100,attackSpeed=5};g.playerHp=100;g.deck={};g.discardPile={}
for i=1,30 do g.deck[i]=D.newCard(2,"hearts") end
g.consumables={Blood.reward(require("src.potions").byId.cons_draw)}
assert(require("src.potions").use(g,1) and #g.hand==26)
g.consumables={Blood.reward(require("src.potions").byId.cons_accuracy)}
assert(require("src.potions").use(g,1))
for i=1,4 do require("src.potions").endTurn(g);assert(g.potionCombat.accuracy) end
require("src.potions").endTurn(g);assert(not g.potionCombat.accuracy)
local random=Rng.random;Rng.random=function() return .99 end
g=game();g.run.ante=3;g.run.currentBlindIndex=3
assert(not Blood.roll(g) and g.maxPlayerHp==2003 and g.playerHp==2000)
assert(not Blood.roll(g) and g.maxPlayerHp==2003)
local restored=P.restoreSnapshot(P.makeSnapshot(g,"shop"));assert(not Blood.roll(restored) and restored.maxPlayerHp==2003)
g.run.ante=4;assert(not Blood.roll(g) and g.maxPlayerHp==2003)
g.run.ante=5;Rng.random=function(n) return n and 1 or .1 end
g.pendingSoulShop=true;Shop.enterAfterCombat(g);assert(g.shopMode=="soul" and g.pendingBloodShop=="blood_large")
Shop.refresh(shop,g);assert(Shop.leave(shop,g)=="shop" and g.shopMode=="large")
assert(Shop.leave(shop,g)=="shop" and g.shopMode=="blood_large" and not g.pendingBloodShop)
assert(Shop.leave(shop,g)=="advance")
Rng.random=random
print("Blood shop PASS: sizes/all categories, HP purchases/rerolls/1 HP guard, actual x5 stats, catalog isolation, potion duration/draw, save restoration, once per odd stage, +3 max HP on miss, soul-large-blood routing")

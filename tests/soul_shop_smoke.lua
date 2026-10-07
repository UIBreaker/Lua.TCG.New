local Shop=require("src.shop")
local G=require("src.game_state")
local Deck=require("src.deck")
local E=require("src.equipment")
local P=require("src.persistence")
local Reward=require("src.reward_system")
local Scoring=require("src.scoring")
local Poker=require("src.poker")
local g=G.new()
local a,b,c=Deck.newCard(10,"valoria"),Deck.newCard(9,"valoria"),Deck.newCard(8,"valoria")
g.persistentDeck={a,b,c};g.masterDeck=g.persistentDeck
a.evolutionLevel=2;a.edition="polychrome";a.equipments={E.ITEMS.gem_fire,E.ITEMS.void_catalyst}
assert(Shop.getSoulValue(a)==31)
g.hand={Deck.cloneCard(a)};g.deck={a,b};g.discardPile={a,c}
assert(not Shop.sellCard(g,a) and #g.persistentDeck==3 and g.gold==6)
assert(not Shop.destroyCard(g,a))
local shop=Shop.new();Shop.refresh(shop,g)
local seen={}
for _=1,80 do
    Shop.refresh(shop,g)
    for _,item in ipairs(shop.items) do
        if item.category=="destroy" or item.category=="heal" or item.category=="armor_potion" then seen[item.id]=true;assert(item.cost>0 and item.consumable) end
        assert(not (item.equipment and item.equipment.soulOnly))
    end
end
assert(seen.healing_potion and seen.soul_reaper,"utility slot must roll both cards")
shop.items={Shop.destructionItem("upper")}
g.consumables={{},{},{}}
assert(not Shop.buyItem(shop,1,g) and g.gold==6 and #shop.items==1)
g.consumables={}
assert(Shop.buyItem(shop,1,g) and g.gold==2 and #g.consumables==1 and not g.soulDestroyActive)
assert(Shop.activateDestruction(g,g.consumables[1]))
assert(Shop.destroyCard(g,a) and g.souls==31 and g.gold==2 and #g.consumables==0)
assert(#g.persistentDeck==2 and #g.hand==0 and #g.deck==1 and #g.discardPile==1)
assert(not Shop.destroyCard(g,a))
g.consumables={Shop.destructionItem().consumable};assert(Shop.activateDestruction(g,g.consumables[1]))
assert(Shop.destroyCard(g,b) and #g.consumables==0)
g.consumables={Shop.destructionItem().consumable};assert(Shop.activateDestruction(g,g.consumables[1]))
assert(not Shop.destroyCard(g,c) and #g.persistentDeck==1 and #g.consumables==1)
g.soulDestroyActive=false;g.soulDestroyConsumable=nil;g.consumables={}
Reward.begin(Reward.calculate({type="boss",baseReward=5},g),g)
assert(g.pendingSoulShop)
Shop.enterSoulShop(g);g.soulShopStock={};for i=1,5 do g.soulShopStock[i]=E.SOUL_POOL[i] end;Shop.refresh(shop,g)
assert(shop.soulMode and #shop.items==12 and not g.pendingSoulShop)
g.souls=0;assert(not Shop.reroll(shop,g) and Shop.getRerollCost(shop,g)==5)
g.souls=0;local gold=g.gold
assert(not Shop.buyItem(shop,1,g) and #shop.items==12 and g.gold==gold)
g.souls=100
local ok,action,eq=Shop.buyItem(shop,1,g)
assert(ok and action=="open_socketing" and eq.id=="soul_worldblade" and g.souls==68 and g.gold==gold)
assert(E.attach(c,eq))
assert(not E.attach(c,eq))
Shop.refresh(shop,g);assert(#shop.items==11)
-- Transaction and unassigned equipment survive a save/reload without duplicate stock.
g.pendingRewardEquipment=E.ITEMS.soul_crown;g.pendingShopEquipment=true
local loaded,state=P.restoreSnapshot(P.makeSnapshot(g,"socketing"))
assert(state=="socketing" and loaded.souls==68 and loaded.shopMode=="soul")
assert(loaded.pendingRewardEquipment.onCardScore and loaded.persistentDeck[1].equipments[1].onCardScore)
Shop.refresh(shop,loaded);assert(#shop.items==11)
-- Check all five relics through actual scoring, not only catalog callbacks.
for _,id in ipairs(E.SOUL_POOL) do
    local card=Deck.newCard(9,"valoria");card.disableFactionPassives=true
    assert(E.attach(card,E.ITEMS[id]))
    local result=Scoring.calculate(Poker.evaluate({card}),{}, {playerHp=20,maxPlayerHp=100})
    assert(result and result.finalScore>0,id)
    if id=="soul_worldblade" then assert(result.totalExtraDamagePct>=0.35) end
    if id=="soul_bastion" then assert(result.addArmor==30) end
    if id=="soul_heart" then assert(result.healHp==18) end
    if id=="soul_crown" then assert(result.totalMult>=30) end
    if id=="soul_hourglass" then assert(result.totalMult>=20) end
end
G.resetRun(g);assert(g.souls==0 and g.shopMode=="normal" and not g.pendingSoulShop)
-- Every destruction route shares one payout, including persistent/combat copies.
local A=require("src.card_abilities")
local Combat=require("src.combat")
local lost=Deck.newCard(10,"valoria")
lost.equipments={E.ITEMS.gem_fire};lost.evolutionLevel=2;lost.edition="polychrome"
local live=Deck.cloneCard(lost)
g.persistentDeck={lost};g.hand={live};g.deck={Deck.cloneCard(lost)}
assert(A.destroy(g,live) and g.souls==23)
assert(not A.destroy(g,live))
Combat.cleanupDestroyedCards(g)
assert(g.souls==23 and #g.persistentDeck==0)
A.destroy(g,g.deck[1]);Combat.cleanupDestroyedCards(g);assert(g.souls==23)
local lone=Deck.newCard(7,"valoria");lone.destroyed=true
g.persistentDeck={lone};Combat.cleanupDestroyedCards(g);assert(g.souls==24)
local replay=P.restoreSnapshot(P.makeSnapshot(g,"shop"))
assert(require("src.souls").award(replay,Deck.cloneCard(lost))==0 and replay.souls==24)
-- All three support cards buy with souls, preserve stock on capacity failure and reload.
local support=G.new();support.shopMode="soul";support.souls=100
local offers=Shop.new();Shop.refresh(offers,support)
for _,definition in ipairs(Shop.SOUL_SUPPORT) do
    local index
    for i,item in ipairs(offers.items) do if item.id==definition.id then index=i end end
    assert(index)
    support.consumables={{},{},{}}
    local souls,count=support.souls,#offers.items
    assert(not Shop.buyItem(offers,index,support) and support.souls==souls and #offers.items==count)
    support.consumables={}
    assert(Shop.buyItem(offers,index,support))
    assert(support.consumables[1].id==definition.id and support.souls==souls-definition.cost)
end
local saved=P.restoreSnapshot(P.makeSnapshot(support,"shop"))
Shop.refresh(offers,saved);assert(#offers.items==6 and saved.consumables[1].slotType=="consumable")
local utilityShop=Shop.new();local utilityGame=G.new();utilityGame.shopMode="soul";utilityGame.souls=10
Shop.refresh(utilityShop,utilityGame)
local utilityIndex
for i,item in ipairs(utilityShop.items) do if item.id=="soul_reaper" then utilityIndex=i end end
utilityGame.consumables={{},{},{}}
assert(not Shop.buyItem(utilityShop,utilityIndex,utilityGame) and utilityGame.souls==10)
utilityGame.consumables={}
assert(Shop.buyItem(utilityShop,utilityIndex,utilityGame) and utilityGame.souls==6 and not utilityGame.soulDestroyActive)
local utilitySaved=P.restoreSnapshot(P.makeSnapshot(utilityGame,"shop"))
Shop.refresh(utilityShop,utilitySaved)
for _,item in ipairs(utilityShop.items) do assert(item.id~="soul_reaper") end
assert(utilitySaved.consumables[1].id=="soul_reaper")
local previous={};for _,id in ipairs(utilitySaved.soulShopStock) do previous[id]=true end
local utilityGold=utilitySaved.gold
utilitySaved.freeRerolls=2;utilitySaved.vouchers={v_welcome=true}
assert(Shop.reroll(utilityShop,utilitySaved) and utilitySaved.souls==1 and utilitySaved.gold==utilityGold)
assert(#utilityShop.items==12 and Shop.getRerollCost(utilityShop,utilitySaved)==7 and utilitySaved.freeRerolls==2)
for _,id in ipairs(utilitySaved.soulShopStock) do assert(not previous[id]) end
local rerolled=P.restoreSnapshot(P.makeSnapshot(utilitySaved,"shop"))
assert(rerolled.soulRerollCount==1 and Shop.getRerollCost(utilityShop,rerolled)==7)
assert(not Shop.reroll(utilityShop,rerolled) and rerolled.souls==1 and #utilityShop.items==12)
local stock=table.concat(rerolled.soulShopStock,",");Shop.refresh(utilityShop,rerolled);assert(table.concat(utilityShop.soulStock,",")==stock)
G.resetRun(rerolled);assert(rerolled.soulRerollCount==0 and not rerolled.soulShopStock)
local devour=G.new();local eater=Deck.newCard(14,"aurelia");local meal=Deck.newCard(3,"valoria")
devour.persistentDeck={eater,meal};devour.hand={meal}
assert(not Deck.devourCard(eater,meal,devour),"Continental characters replace legacy devouring")
assert(require("src.card_abilities").destroy(devour,meal) and devour.souls==1)
Combat.cleanupDestroyedCards(devour);assert(devour.souls==1)
for _,spell in ipairs({"spell_ankh","spell_hex"}) do
    local spirit=G.new()
    spirit.deities={{id="test1",name="SPN 1",edition="foil"},{id="test2",name="SPN 2",edition="foil"}}
    local pack=Shop.new();pack.currentPackOpening={pack={packType="joker_edition"},cards={{id=spell}}}
    assert(Shop.choosePackCard(pack,1,spirit) and spirit.souls==4)
end
print("Soul shop smoke passed: destruction, valuation, piles, boss entry, currency, exclusive stock, sockets, scoring, save/reload, reset")

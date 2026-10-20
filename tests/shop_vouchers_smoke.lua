local Shop=require("src.shop")
local Game=require("src.game_state")
local Combat=require("src.combat")
local Collection=require("src.collection")
local Persistence=require("src.persistence")
local Reward=require("src.reward_system")
local Blood=require("src.blood_shop")
local Description=require("src.card_description")
local definitions={}
for _,v in ipairs(Shop.VOUCHERS) do definitions[v.id]=v end
local function game()
    local g=Game.new();g.gold=100000;g.playerHp=40;return g
end
local function buy(g,id,shop,power)
    shop=shop or Shop.new()
    local offer=Shop.voucherOffer(assert(definitions[id]),g,power)
    offer.cost=offer.cost*Shop.PRICE_MULTIPLIER
    if power==5 then offer=Blood.offer(offer);shop.mode="blood_small" end
    shop.items[#shop.items+1]=offer
    assert(Shop.buyItem(shop,#shop.items,g))
    return offer
end
assert(#Shop.VOUCHERS==9 and #Collection.getItems("vouchers")==9)
for _,v in ipairs(Shop.VOUCHERS) do
    local g=game();local price,previousGain=0,0
    for level=1,12 do
        local offer=Shop.voucherOffer(v,g)
        assert(offer.voucherLevel==level and offer.name:find("Cấp "..level,1,true))
        assert(offer.cost>price and (level<3 or offer.cost-price>=previousGain),"Marginal upgrade price must outgrow the linear benefit")
        previousGain,price=offer.cost-price,offer.cost
        buy(g,v.id)
        assert(Shop.voucherLevel(v.id,g)==level and Shop.voucherPower(v.id,g)==level)
        for k,n in pairs(v.params) do assert(Shop.voucherParams(v.id,g)[k]==n*level) end
    end
end
local g=game();local shop=Shop.new()
buy(g,"v_hand_plus",shop);buy(g,"v_hand_plus",shop)
buy(g,"v_second_chance",shop);buy(g,"v_second_chance",shop)
assert(g.maxHands==5 and g.handsRemaining==5 and g.maxDiscards==5 and g.discardsRemaining==5)
buy(g,"v_vitality",shop);buy(g,"v_vitality",shop)
assert(g.maxPlayerHp==150 and g.playerHp==90)
g.playerHp=10;buy(g,"v_apothecary",shop);assert(g.playerHp==18)
buy(g,"v_apothecary",shop);assert(g.playerHp==26)
Combat.start(g,require("src.monster").create(1),1)
assert(g.playerHp==42 and g.handsRemaining==5 and g.discardsRemaining==5)
g.playerHp=149;Combat.start(g,require("src.monster").create(1),2);assert(g.playerHp==150)
assert(Shop.getDestructionRewards(g,g.persistentDeck[1]).heal==0)

g=game();shop=Shop.new();buy(g,"v_welcome",shop);buy(g,"v_welcome",shop)
g.freeRerolls=1;local gold=g.gold
assert(Shop.reroll(shop,g) and g.freeRerolls==0 and not shop.welcomeRerollUsed)
for i=1,2 do assert(Shop.getRerollCost(shop,g)==0 and Shop.reroll(shop,g) and g.gold==gold and shop.rerollCost==5) end
assert(Shop.getRerollCost(shop,g)==5)
assert(Shop.reroll(shop,g) and g.gold==gold-5 and Shop.getRerollCost(shop,g)==7)
buy(g,"v_welcome",shop);assert(Shop.getRerollCost(shop,g)==0)
assert(Shop.reroll(shop,g) and Shop.getRerollCost(shop,g)==7)
Shop.resetReroll(shop);assert(Shop.getRerollCost(shop,g)==0)
shop.mode="blood_small";assert(Shop.getRerollCost(shop,g)==20)
shop.mode="large";shop.soulMode=true;g.soulRerollCount=0;assert(Shop.getRerollCost(shop,g)==5)

g=game();shop=Shop.new();shop.rerollCost=10
assert(Shop.getRerollCost(shop,g)==10)
g.gold=9;local stock=shop.items
assert(not Shop.reroll(shop,g) and g.gold==9 and shop.items==stock and not shop.rerollCount)
g.gold=100000
buy(g,"v_discount",shop);assert(Shop.getRerollCost(shop,g)==8)
buy(g,"v_discount",shop);assert(Shop.getRerollCost(shop,g)==6)
Shop.resetReroll(shop);Shop.refresh(shop,g);assert(Shop.getRerollCost(shop,g)==1)
assert(Shop.reroll(shop,g) and Shop.getRerollCost(shop,g)==3)
assert(Shop.reroll(shop,g) and Shop.getRerollCost(shop,g)==6)
buy(g,"v_pack_discount",shop);buy(g,"v_pack_discount",shop)
for i=1,2 do
    Shop.applyVoucherStock(shop,g)
    for _,item in ipairs(shop.items) do if item.category=="pack" then assert(item.cost==math.max(1,item.baseCost-6)) end end
end

g=game();buy(g,"v_interest");g.gold=20;assert(Shop.interest(g)==5 and g.maxInterest==10)
g.gold=40;assert(Shop.interest(g)==10)
g.gold=1000;buy(g,"v_interest");g.gold=40;assert(Shop.interest(g)==12 and g.maxInterest==15)
g.selectedFaction="diamonds";assert(Shop.interest(g)==14)
assert(Reward.calculate({baseReward=3},g).interestBonus==Shop.interest(g))
g.selectedFaction="red_deck";g.gold=0;assert(Shop.interest(g)==0)
g.gold=1000;buy(g,"v_altar");buy(g,"v_altar")
local reward=Reward.calculate({baseReward=3},g)
assert(reward.voucherBonus==4 and Reward.calculate({baseReward=3},g,true).voucherBonus==0)
assert(Shop.getSacrificePrice({cost=4},"consumable",g)==2,"No buy/sell gold loop from Tro Vàng")
local animation=Reward.newAnimation(reward)
local total=0;for _,line in ipairs(animation.lines) do total=total+line.valNum end
assert(total==reward.totalGold)

for _,v in ipairs(Shop.VOUCHERS) do g.vouchers[v.id]=true end
for _,mode in ipairs({"small","large","blood_small","blood_large"}) do
    g.shopMode=mode
    for i=1,30 do
        Shop.refresh(shop,g);local found=0
        for _,item in ipairs(shop.items) do if item.category=="voucher" then
            found=found+1;assert(item.voucherLevel==2 and item.voucherPower==(Blood.isMode(mode) and 6 or 2))
        end end
        assert(found==(mode=="blood_large" and 2 or 1))
    end
end

g=game();g.vouchers.v_hand_plus=true;g.maxHands=4;g.handsRemaining=4
buy(g,"v_hand_plus");assert(Shop.voucherLevel("v_hand_plus",g)==2 and g.maxHands==5)
g.vouchers.v_vitality={bloodPower=5};g.maxPlayerHp=200;g.playerHp=100
buy(g,"v_vitality");assert(Shop.voucherPower("v_vitality",g)==6 and g.maxPlayerHp==225)
g.playerHp=10000;g.maxPlayerHp=10000;buy(g,"v_hand_plus",nil,5)
assert(Shop.voucherLevel("v_hand_plus",g)==3 and Shop.voucherPower("v_hand_plus",g)==7 and g.maxHands==10)
local restored=assert(Persistence.restoreSnapshot(Persistence.decode(Persistence.encode(Persistence.makeSnapshot(g,"shop")))))
assert(restored.maxHands==10 and Shop.voucherLevel("v_hand_plus",restored)==3 and Shop.voucherPower("v_hand_plus",restored)==7)
buy(restored,"v_hand_plus");assert(restored.maxHands==11 and Shop.voucherLevel("v_hand_plus",restored)==4)
local title,body=Description.resolve({id="v_hand_plus",name="Bùa Hảo Thủ"},restored)
assert(title:find("Cấp 4",1,true) and body:find("8 lượt đánh",1,true))
local offer=Shop.voucherOffer(definitions.v_hand_plus,restored)
title,body=Description.resolve(offer,restored)
assert(title:find("Cấp 5",1,true) and body:find("9 lượt đánh",1,true))
shop=Shop.new();shop.items={offer};restored.gold=0
assert(not Shop.buyItem(shop,1,restored) and Shop.voucherLevel("v_hand_plus",restored)==4 and #shop.items==1)
shop.items={{category="voucher",voucherId="invalid",cost=0}};assert(not Shop.buyItem(shop,1,restored))
Game.resetRun(restored)
assert(next(restored.vouchers)==nil and restored.maxHands==3 and restored.maxDiscards==3 and restored.maxPlayerHp==100)
print("Voucher PASS: 9 repeatable upgrades, rising prices, combat stats/healing, cumulative discounts/free rolls, savings/victory income, all-owned stock, blood/legacy saves, descriptions, failure and reset")

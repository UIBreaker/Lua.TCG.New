-- E:/Lua/Lua/lua.exe tests/ux_polish_smoke.lua
local P=require("src.ux_polish")
local UI=require("src.ui")
UI.getDeitySlotRect=function() return 1042,112,64,88 end
UI.getConsumableSlotRect=function() return 1042,300,64,88 end
local Shop=require("src.shop")
local Deck=require("src.deck")
local Game=require("src.game_state")
local game=Game.new();game.gold=100;game.persistentDeck={Deck.newCard(2,"hearts")}
local shop=Shop.new();Shop.refresh(shop,game)
P.ensureShop(shop)
local function settle(fast) for i=1,90 do P.update(1/120,fast,"shop",shop) end end
local function findCard()
    for i,item in ipairs(shop.items) do if item.card then return i,item end end
    error("missing card offer")
end
local index,item=findCard();local rect={x=439,y=151,w=118,h=176}
assert(P.focusItem(item,"stock",index,rect))
P.clearFocus();assert(not P.focus and game.gold==100)
game.gold=0;P.focusItem(item,"stock",index,rect)
assert(P.button(game).disabled and not P.confirm(shop,game) and not P.busy())
game.gold=100
local before=game.gold;local size=#game.persistentDeck
assert(P.confirm(shop,game));assert(game.gold==before-item.cost and #game.persistentDeck==size+1)
assert(#P.moneyFeedback==1 and P.moneyFeedback[1].amount==-item.cost and P.moneyFeedback[1].coinSource.x==rect.x+rect.w/2)
assert(P.goldValue(game.gold)==before,"spend display counts from the prior balance")
assert(not P.confirm(shop,game) and not P.focusItem(item,"stock",index,rect))
settle();assert(not P.busy())
assert(P.goldValue(game.gold)==game.gold,"wallet settles to exact resolved balance")
local acquired=game.persistentDeck[#game.persistentDeck]
local reaper={id="soul_reaper"};game.consumables={reaper};game.soulDestroyConsumable=reaper;game.soulDestroyActive=true
P.focusItem(acquired,"card",nil,rect);local rewards=Shop.getDestructionRewards(game,acquired);before=game.gold
local souls=game.souls or 0
assert(P.confirm(shop,game));assert(game.gold==before+rewards.gold and game.souls==souls+rewards.souls and #game.persistentDeck==size)
settle(true)
P.focusItem(game.persistentDeck[1],"card",nil,rect)
game.soulDestroyActive=true
assert(P.button(game).disabled and not P.confirm(shop,game))
P.clearFocus()
local old=shop.items;before=game.gold;local cost=Shop.getRerollCost(shop,game)
assert(P.reroll(shop,game));assert(game.gold==before-cost and shop.items==old)
assert(not P.reroll(shop,game))
P.update(P.job.swapAt-0.001,false,"shop",shop);assert(shop.items==old and not P.job.swapped)
P.update(0.002,false,"shop",shop);assert(P.job.swapped and shop.items~=old)
settle();assert(not P.busy())
index,item=findCard();P.focusItem(item,"stock",index,rect);assert(P.confirm(shop,game));settle(true)
assert(game.persistentDeck[1].rank==2 and game.persistentDeck[1].evolutionLevel==0)
local Deities=require("src.deities")
local Equipment=require("src.equipment")
local catalog=Shop.PACK_CATALOG
local function buyStock(stock)
    shop=Shop.new();shop.items={stock};game.gold=1000;P.ensureShop(shop)
    P.focusItem(stock,"stock",1,rect);local oldGold=game.gold
    local callback=false
    assert(P.confirm(shop,game,function(action,eq) callback={action,eq} end))
    assert(game.gold==oldGold-stock.cost and #shop.items==0)
    settle();assert(callback and not P.busy());return callback
end
local hp=game.playerHp;game.playerHp=1
buyStock({category="heal",healAmt=25,cost=4});assert(game.playerHp==26)
local capacity=game.maxHandSize
buyStock({category="hand_expansion",cost=12});assert(game.maxHandSize==capacity+1)
local d={};for k,v in pairs(Deities.CATALOG.spirit_pebble) do d[k]=v end
buyStock({category="deity",deity=d,cost=4});assert(game.deities[1].id==d.id)
P.focusItem(game.deities[1],"deity",1,rect);local gold=game.gold
assert(P.confirm(shop,game));assert(game.gold>gold and not game.deities[1]);settle()
local c={id="test",cost=4,name="test",category="edition",edition="foil"};game.consumables={c}
P.focusItem(c,"consumable",1,rect);assert(P.confirm(shop,game));settle();assert(#game.consumables==0)
local eq=Equipment.ITEMS.gem_fire
local action=buyStock({category="equipment",equipment=eq,cost=4});assert(action[1]=="open_socketing" and action[2]==eq)
for _,pack in ipairs(catalog) do
    buyStock({category="pack",packType=pack.packType,name=pack.name,cost=pack.cost})
    assert(shop.currentPackOpening and shop.currentPackOpening.pack.packType==pack.packType)
end
game.deities={};for slot=1,Deities.getMaxSlots(game) do game.deities[slot]=d end
shop=Shop.new();shop.items={{category="deity",deity=d,cost=4}};P.ensureShop(shop)
P.focusItem(shop.items[1],"stock",1,rect);gold=game.gold
assert(not P.confirm(shop,game) and game.gold==gold and #shop.items==1,"full SPN slots preserve transaction")
P.clearFocus();game.freeRerolls=1;gold=game.gold
assert(P.reroll(shop,game) and game.gold==gold and game.freeRerolls==0);settle(true)
game.vouchers.v_welcome=true;shop.welcomeRerollUsed=false
assert(P.reroll(shop,game) and game.gold==gold and shop.welcomeRerollUsed);settle(true)
P.update(2,false,"shop",shop);assert(#P.moneyFeedback==0,"coin rewards expire after the purchase/sale job")
local ritual=Game.new();ritual.shopMode="soul";ritual.gold=10
ritual.persistentDeck={Deck.newCard(4,"hearts"),Deck.newCard(5,"spades")}
local reaper={id="soul_reaper"};ritual.consumables={reaper};ritual.soulDestroyConsumable=reaper;ritual.soulDestroyActive=true
P.focusItem(ritual.persistentDeck[1],"card",nil,rect)
assert(P.confirm(Shop.new(),ritual) and ritual.gold==15)
assert(#P.moneyFeedback==1 and P.moneyFeedback[1].amount==5,"gold awarded alongside souls gets its own gold feedback")
P.update(2,false,"shop");assert(#P.moneyFeedback==0 and P.goldValue(ritual.gold)==ritual.gold)
print("UX polish smoke PASS: click/confirm, cancel, affordability, minimum deck, single charge, wallet count/coin flight/expiration, hidden swap, spam lock, Fast")
print("UX stock coverage PASS: heal, expansion, SPN sale/capacity, consumable sale, equipment destination, all 9 packs")

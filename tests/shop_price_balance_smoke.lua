local Shop=require("src.shop")
local Game=require("src.game_state")
local Run=require("src.run_manager")
local Rng=require("src.rng")

local function stock(mode,multiplier,discount)
    Rng.seed(90147)
    local game=Game.new()
    game.run=Run.newRun("red_deck")
    game.shopMode=mode
    game.gold,game.souls,game.playerHp,game.maxPlayerHp=100000,100000,100000,100000
    if discount then game.vouchers={v_pack_discount=true} end
    local shop=Shop.new()
    Shop.PRICE_MULTIPLIER=multiplier
    Shop.refresh(shop,game)
    return shop,game
end

local multiplier=Shop.PRICE_MULTIPLIER
assert(multiplier==3)
for _,mode in ipairs({"small","consumable","equipment","spn","medicine","cards","large","soul","blood_small","blood_large"}) do
    local base=stock(mode,1)
    local raised,game=stock(mode,multiplier)
    assert(#base.items==#raised.items and #raised.items>0,mode)
    for i,item in ipairs(raised.items) do
        local previous=base.items[i]
        assert(item.category==previous.category and item.name==previous.name,mode)
        assert(item.cost==math.ceil(previous.cost*multiplier),mode.." item "..i)
        if previous.originalCost then
            assert(item.originalCost==math.ceil(previous.originalCost*multiplier),mode.." original price "..i)
        end
    end
    local item=raised.items[1]
    local balance=item.currency=="blood" and "playerHp" or item.currency=="souls" and "souls" or "gold"
    local before=game[balance]
    assert(Shop.buyItem(raised,1,game),mode.." purchase")
    assert(game[balance]==before-item.cost,mode.." charged price")
end

local base=stock("large",1,true)
local raised,game=stock("large",multiplier,true)
local packs=0
for i,item in ipairs(raised.items) do
    if item.category=="pack" then
        packs=packs+1
        assert(item.cost==math.max(1,math.ceil(base.items[i].baseCost*multiplier)-3))
    end
end
assert(packs>0)
Shop.applyVoucherStock(raised,game)
for _,item in ipairs(raised.items) do
    if item.category=="pack" then assert(item.cost==math.max(1,item.baseCost-3)) end
end
Shop.PRICE_MULTIPLIER=multiplier
print("Shop price balance smoke PASS: all ten markets, purchase deductions, sale labels and pack voucher")

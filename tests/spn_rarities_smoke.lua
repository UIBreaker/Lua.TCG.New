local D=require("src.deities")
local Shop=require("src.shop")
local GS=require("src.game_state")
local Run=require("src.run_manager")
local P=require("src.persistence")
local G=require("src.void_gacha")
local Rng=require("src.rng")
Rng.seed(1018)

local function owned(rarity,level)
    local item={}
    for k,v in pairs(D.CATALOG.spirit_pebble) do item[k]=v end
    assert(D.setRarity(item,rarity))
    for _=1,level or 0 do assert(D.evolve(item)) end
    return item
end

assert(#D.RARITIES==10 and D.RARITIES[8].id=="unique")
assert(D.RARITIES[9].id=="eternal" and D.RARITIES[9].code=="VH" and D.RARITIES[9].name=="Vĩnh Hằng")
assert(D.RARITIES[10].id=="supreme" and D.RARITIES[10].code=="TT" and D.RARITIES[10].name=="Tối Thượng")
local item=owned("unique")
local previous=D.scaleEffect(item,{addChips=20}).addChips
for _,code in ipairs({"VH","TT","TT+1"}) do
    assert(D.evolve(item) and D.getRarityBadge(item)==code)
    local power=D.scaleEffect(item,{addChips=20}).addChips
    assert(power>previous,"evolution above UQ must increase actual effects")
    previous=power
end

-- Legacy UQ overflow retains the same absolute tier and strength after loading.
local game=GS.new();game.run=Run.newRun("red_deck")
game.deities={owned("unique",1),owned("unique",2),owned("unique",3)}
game.backpackDeities={owned("eternal"),owned("supreme")}
local restored,state=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(game,"shop")))))
assert(state=="shop")
for index,code in ipairs({"VH","TT","TT+1"}) do
    assert(D.getRarityBadge(restored.deities[index])==code)
    assert(D.scaleEffect(restored.deities[index],{addChips=20}).addChips
        ==D.scaleEffect(game.deities[index],{addChips=20}).addChips)
end
assert(D.getRarityBadge(restored.backpackDeities[1])=="VH")
assert(D.getRarityBadge(restored.backpackDeities[2])=="TT")

-- Exercise both real rarity samplers, including their final tiny intervals.
local original=Rng.random
local cumulative=0
for tier,rarity in ipairs(D.RARITIES) do
    local weight=assert(Shop.SPN_RARITY_WEIGHTS[rarity.id])
    assert(weight>0 and Shop.SPN_RARITY_PRICE_MULTIPLIERS[rarity.id]>0)
    for _,roll in ipairs({cumulative+1e-10,cumulative+weight-1e-10}) do
        Rng.random=function(a,b) if not a then return roll elseif b then return a else return 1 end end
        local buyer=GS.new();buyer.shopMode="spn";buyer.gold=100000
        local shop=Shop.new();Shop.refresh(shop,buyer)
        assert(#shop.items==6)
        for _,offer in ipairs(shop.items) do
            assert(offer.rarity==rarity.id and D.getRarityBadge(offer.deity)==rarity.code)
            assert(offer.cost>0 and offer.subtitle==rarity.name)
        end
        local price=shop.items[1].cost
        assert(Shop.buyItem(shop,1,buyer) and buyer.gold==100000-price)
        assert(D.getRarityBadge(buyer.backpackDeities[1])==rarity.code)
        buyer.voidEvent={}
        local reward=G.createReward(buyer,"spn")
        assert(reward.item.rarity==rarity.id and reward.strength==tier)
        assert(G.config.colors[reward.strength],"every Void rarity needs a color")
    end
    cumulative=cumulative+weight
end
Rng.random=original
assert(math.abs(cumulative-1)<1e-12,"SPN rarity odds must sum to 100%")
assert(Shop.SPN_RARITY_PRICE_MULTIPLIERS.eternal>Shop.SPN_RARITY_PRICE_MULTIPLIERS.unique
    and Shop.SPN_RARITY_PRICE_MULTIPLIERS.supreme>Shop.SPN_RARITY_PRICE_MULTIPLIERS.eternal)
print("SPN rarities PASS: ten tiers, UQ -> VH -> TT -> TT+1 effects, legacy overflow/reserves/save, all shop/Void odds boundaries, purchases and display metadata")

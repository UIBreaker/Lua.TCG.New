local Shop=require("src.shop")
local Game=require("src.game_state")
local Deck=require("src.deck")
local Equipment=require("src.equipment")
local Basic=require("src.basic_equipment")
local Effects=require("src.card_effects")
local Persistence=require("src.persistence")
local Abilities=require("src.card_abilities")
local Rng=require("src.rng")
Rng.seed(97521)
local game=Game.new();game.run=require("src.run_manager").newRun("red_deck")
game.shopMode="cards";game.gold=100000
local shop=Shop.new()
local printed,levels,equipment,editions={},{},{},{}
local plain,combined=false,false
local catalog=Effects.getEditionCatalog()
for _=1,240 do
    Shop.refresh(shop,game)
    assert(shop.mode=="cards" and #shop.items==8)
    local seen={}
    for i,item in ipairs(shop.items) do
        local card=item.card
        assert(item.category=="card" and item.section=="stall" and item.bay==i)
        assert(not seen[item.id],"A stock should not repeat the same rank and suit")
        seen[item.id]=true;printed[card.suit.."_"..card.rank]=true
        assert(card.rank>=2 and card.rank<=14 and card.evolutionLevel>=0 and card.evolutionLevel<=2)
        levels[card.evolutionLevel]=true
        assert(#card.equipments<=1)
        local expected=4+card.evolutionLevel*6
        for _,eq in ipairs(card.equipments) do
            assert(eq.basic==true and not eq.crafted and not eq.soulOnly,"Pre-equipped cards must use ONLY basic equipment")
            assert(eq~=Equipment.ITEMS[eq.id],"Stock must own its equipment instance")
            equipment[eq.id]=true;expected=expected+eq.cost
            assert(item.desc:find(eq.name,1,true))
        end
        if card.edition then
            assert(Effects.getDefinition(card.edition))
            editions[card.edition]=true;expected=expected+8
            assert(item.desc:find(Effects.getDefinition(card.edition).shopText,1,true))
        end
        assert(item.cost==math.ceil(expected*Shop.PRICE_MULTIPLIER) and item.desc:find(Abilities.description(card),1,true))
        plain=plain or (card.evolutionLevel==0 and #card.equipments==0 and not card.edition)
        combined=combined or (card.evolutionLevel==2 and #card.equipments==1 and card.edition~=nil)
    end
end
for _,card in ipairs(Shop.STANDARD_CARDS) do assert(printed[card.suit.."_"..card.rank],card.id) end
for level=0,2 do assert(levels[level]) end
for _,id in ipairs(Basic.basic) do assert(equipment[id],id) end
for _,edition in ipairs(catalog) do assert(editions[edition.edition],edition.edition) end
assert(plain and combined)

-- Buy all 52 identities with a mixture of upgrades; keep them through deck cloning and a real save round trip.
local purchased={}
for i,printedCard in ipairs(Shop.STANDARD_CARDS) do
    local card=Deck.newCard(printedCard.rank,printedCard.suit)
    card.evolutionLevel=i%3
    if i%2==0 then
        local template=Equipment.ITEMS[Basic.basic[(i/2-1)%#Basic.basic+1]]
        local eq={};for k,v in pairs(template) do eq[k]=v end
        assert(Equipment.attach(card,eq))
    end
    if i%3~=0 then assert(Effects.setEffect(card,catalog[(i-1)%#catalog+1].edition)) end
    shop.items={Shop.playingCardOffer(card)}
    local count,gold=#game.persistentDeck,game.gold
    if i==1 then
        game.gold=shop.items[1].cost-1
        assert(not Shop.buyItem(shop,1,game))
        assert(#shop.items==1 and #game.persistentDeck==count and game.gold==shop.items[1].cost-1)
        game.gold=gold
    end
    local cost=shop.items[1].cost
    assert(Shop.buyItem(shop,1,game))
    assert(game.gold==gold-cost and #game.persistentDeck==count+1 and #shop.items==0)
    assert(game.persistentDeck[#game.persistentDeck]==card)
    purchased[card.id]=card
    local clone=Deck.cloneCard(card)
    assert(clone.evolutionLevel==card.evolutionLevel and clone.edition==card.edition)
    assert(#clone.equipments==#card.equipments and Abilities.description(clone)==Abilities.description(card))
end
local loaded,state=Persistence.restoreSnapshot(Persistence.makeSnapshot(game,"shop"))
assert(state=="shop" and loaded.shopMode=="cards" and loaded.gold==game.gold)
local count=0
for _,card in ipairs(loaded.persistentDeck) do
    local source=purchased[card.id]
    if source then
        count=count+1
        assert(card.rank==source.rank and card.suit==source.suit)
        assert(card.evolutionLevel==source.evolutionLevel and card.edition==source.edition)
        assert(Abilities.description(card)==Abilities.description(source))
        assert(#card.equipments==#source.equipments)
        for i,eq in ipairs(card.equipments) do
            assert(eq.id==source.equipments[i].id and eq.basic and type(eq.onCardScore)=="function")
        end
        assert(Deck.getCardAttackSpeed(card)==Deck.getCardAttackSpeed(source))
    end
end
assert(count==52)
Shop.refresh(shop,loaded);assert(shop.mode=="cards" and #shop.items==8)
-- Resale is restricted to the card shop and removes the owned instance from every battle pile.
local seller=Game.new();seller.run=require("src.run_manager").newRun("red_deck")
local sold,kept=Deck.newCard(13,"valoria"),Deck.newCard(2,"elaris")
sold.evolutionLevel=2;Effects.setEffect(sold,"ancient")
sold.equipments={Equipment.ITEMS.gem_fire}
seller.persistentDeck={sold,kept};seller.masterDeck=seller.persistentDeck
seller.hand={Deck.cloneCard(sold),Deck.cloneCard(kept)};seller.hand[2].selected=true
seller.deck={Deck.cloneCard(sold)};seller.discardPile={Deck.cloneCard(sold)}
seller.gold=10;seller.souls=23;seller.playerHp=41
seller.consumables={Shop.destructionItem().consumable}
seller.soulDestroyActive=true;seller.soulDestroyConsumable=seller.consumables[1]
seller.vouchers={v_apothecary=true,v_altar=true}
for _,mode in ipairs({"normal","small","consumable","equipment","spn","medicine","large","soul"}) do
    seller.shopMode=mode
    assert(not Shop.sellCard(seller,sold) and seller.gold==10 and #seller.persistentDeck==2)
end
assert(not Shop.sellCard())
seller.shopMode="cards"
local price=math.floor((4+12+8+Equipment.ITEMS.gem_fire.cost)/2)
assert(Shop.getCardSellPrice(sold)==price and Shop.getCardSellPrice(kept)==2)
local forged=Deck.cloneCard(sold);forged.evolutionLevel=100;forged.equipments={{cost=99999}}
local ok,paid=Shop.sellCard(seller,forged)
assert(ok and paid==price and seller.gold==10+price,"Use the owned card's value, not caller-supplied upgrades")
assert(#seller.persistentDeck==1 and seller.persistentDeck[1]==kept and seller.masterDeck==seller.persistentDeck)
assert(#seller.hand==1 and #seller.deck==0 and #seller.discardPile==0 and seller.selectedIndices[1]==1)
assert(seller.souls==23 and seller.playerHp==41 and #seller.consumables==1 and seller.soulDestroyActive)
assert(not sold.soulAwarded and not sold.destroyed and not (seller.soulDestroyedIds or {})[tostring(sold.id)])
assert(not Shop.sellCard(seller,sold) and not Shop.sellCard(seller,kept) and seller.gold==10+price)
local restored,restoredState=Persistence.restoreSnapshot(Persistence.makeSnapshot(seller,"shop"))
assert(restoredState=="shop" and restored.shopMode=="cards" and restored.gold==seller.gold)
assert(#restored.persistentDeck==1 and restored.persistentDeck[1].id==kept.id)
print("Card resale PASS: card shop only, upgrade/equipment/edition value, canonical ownership, all-pile removal, no soul/heal/reaper rewards, stale/last-card guards and save retention")
print("Card shop PASS: all 52 cards, levels 0/1/2, all 12 basic items ONLY, all 9 editions, combined upgrades, prices, failed/successful purchases, clone and save retention")

local D=require("src.deities")
local Deck=require("src.deck")
local A=require("src.card_abilities")
local Game=require("src.game_state")
local Persistence=require("src.persistence")
local Rng=require("src.rng")
local function game(level,slots)
    local g=Game.new();g.deities={};g.hand={};g.deck={};g.discardPile={};g.persistentDeck={}
    g.discardsRemaining=1;g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
    for _,slot in ipairs(slots or {5}) do
        assert(D.addDeity(g,D.CATALOG.spirit_last_remnant,slot))
        for i=1,level or 0 do assert(D.evolve(g.deities[slot])) end
    end
    local card=Deck.newCard(9,"spades");card.evolutionLevel=3;card.speedBonus=7;card.seedChips=6;card.depthInvestment=2
    card.seal="seal_blood";card.enhancement="enh_armor";card.edition="foil";card.maxSockets=7;card.allowDuplicateEquipment=true
    local eq=require("src.equipment").ITEMS.basic_lace
    assert(eq,"existing equipment")
    local owned={};for k,v in pairs(eq) do owned[k]=v end
    owned.params={test={value=17}};card.equipments={owned};Deck.addCardToDeck(g,card)
    return g,Deck.cloneCard(card),card
end
local function discard(g,cards,overrides)
    local context={playerDiscard=true,remainingBefore=g.discardsRemaining}
    for k,v in pairs(overrides or {}) do context[k]=v end
    A.discard(g,cards,context)
end
local g,card,canonical=game()
card.temporarySpeedBonus=99;card.temporaryAbilityLevels=9;card.selected=true;card.hovered=true;card.faceDown=true
local rng=Rng.getState();discard(g,{card})
assert(Rng.getState()==rng and #g.persistentDeck==2 and #g.discardPile==1 and #g.hand==0 and #g.deck==0)
local live,permanent=g.discardPile[1],g.persistentDeck[2]
assert(live~=permanent and live.id==permanent.id and live.id~=card.id and not live.selected and not live.faceDown)
assert(live.evolutionLevel==3 and live.speedBonus==7 and live.seedChips==6 and live.depthInvestment==2)
assert(live.seal==card.seal and live.enhancement==card.enhancement and live.edition==card.edition and live.maxSockets==7 and live.allowDuplicateEquipment)
assert(not live.temporarySpeedBonus and not live.temporaryAbilityLevels,"battle-only bonuses are not permanent copies")
assert(live.equipments[1].id==canonical.equipments[1].id)
assert(live.equipments[1].params~=permanent.equipments[1].params and permanent.equipments[1].params~=canonical.equipments[1].params)
live.equipments[1].params.test.value=42;assert(canonical.equipments[1].params.test.value==17 and permanent.equipments[1].params.test.value==17)
assert(#g.spnFeedback==1 and g.spnFeedback[1].slot==5)
assert(require("src.combat").drawCards(g,8,nil,false)==0 and #g.discardPile==1,"discard itself cannot draw the copy")
assert(require("src.combat").drawCards(g,8,nil,true)==1 and #g.discardPile==0 and g.hand[1].id==live.id,"copy rejoins when end-turn recycling is allowed")

-- Only the player's paid final discard of one live card qualifies.
for _,case in ipairs({{remainingBefore=2},{remainingBefore=0},{freeDiscard=true},{preview=true},{playerDiscard=false}}) do
    g,card=game();discard(g,{card},case);assert(#g.persistentDeck==1 and #g.discardPile==0)
end
g,card=game();A.discard(g,{card});assert(#g.persistentDeck==1,"forced discard has no player context")
g,card=game();discard(g,{});assert(#g.persistentDeck==1)
g,card=game();discard(g,{card,Deck.newCard(4,"clubs")});assert(#g.persistentDeck==1)
g,card=game();card.destroyed=true;discard(g,{card});assert(#g.persistentDeck==1)
g,card,canonical=game();canonical.destroyed=true;discard(g,{card});assert(#g.persistentDeck==1)
g,card=game();g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=5,untilHand=1}}
discard(g,{card});assert(#g.persistentDeck==1,"locked slot cannot copy")

for level=0,8 do
    g,card=game(level);discard(g,{card})
    assert(#g.persistentDeck==level+2 and #g.discardPile==level+1,"each evolution adds one copy")
    assert(D.getDescription(g.deities[5]):find("tạo "..(level+1).." bản sao",1,true))
    local seen={[card.id]=true}
    for _,copy in ipairs(g.discardPile) do assert(not seen[copy.id]);seen[copy.id]=true end
end
g,card=game();assert(D.setRarity(g.deities[5],"unique"));discard(g,{card});assert(#g.discardPile==8)
g,card=game(1,{1,5});discard(g,{card});assert(#g.discardPile==4,"each active owned instance triggers separately")

g,card,canonical=game(2);discard(g,{card})
local saved=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
assert(#saved.persistentDeck==4 and saved.deities[5].evolutionLevel==2 and saved.deities[5].onDiscard)
assert(saved.persistentDeck[2].evolutionLevel==3 and saved.persistentDeck[2].edition=="foil" and saved.persistentDeck[2].equipments[1].id==canonical.equipments[1].id)
local nextCard=Deck.newCard(2,"hearts");for _,copy in ipairs(saved.persistentDeck) do assert(nextCard.id>copy.id) end
assert(#D.getRandomShopPool({},99)==61)
print("SPN discard PASS: paid final single discard, per-level copies, canonical upgrades, unique IDs, isolated equipment, no forced/free/preview copies, boss locks and save/load")

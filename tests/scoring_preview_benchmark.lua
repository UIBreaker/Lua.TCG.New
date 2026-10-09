local Game=require("src.game_state")
local Deck=require("src.deck")
local E=require("src.equipment")
local D=require("src.deities")
local A=require("src.card_abilities")
local S=require("src.scoring")
local Poker=require("src.poker")
local g=Game.new();g.hand={};g.deck={};g.discardPile={};g.persistentDeck={};g.deities={}
for rank=2,14 do for _,suit in ipairs(Deck.SUIT_ORDER) do
    local c=Deck.newCard(rank,suit)
    c.equipments={E.ITEMS.gem_fire,E.ITEMS.basic_plate,E.ITEMS.itm_ledger,E.ITEMS.itm_bell}
    g.persistentDeck[#g.persistentDeck+1]=c
    if #g.hand<8 then g.hand[#g.hand+1]=c else g.deck[#g.deck+1]=c end
end end
g.monster={hp=10000,maxHp=10000,armor=15,attackSpeed=10};g.enemies={g.monster}
A.start(g)
for _,id in ipairs({"spirit_primeval_product","spirit_parity","spirit_number_grave","spirit_bastion","spirit_thunderpulse"}) do D.addDeity(g,D.CATALOG[id]) end
local h=assert(Poker.evaluate({g.hand[1],g.hand[2],g.hand[3],g.hand[4],g.hand[5]}))
local ctx={preview=true,gameState=g,monster=g.monster}
local started=love.timer.getTime()
for _=1,200 do S.calculate(h,g.deities,ctx) end
print(string.format("Preview benchmark: %.3f ms/call, 52 cards with 4 equipment each and 5 SPNs (200 calls)",(love.timer.getTime()-started)*5))
assert(not g.abilityHand and not next(g.spnCombat or {}) and g.persistentDeck[1].depthInvestment==nil)

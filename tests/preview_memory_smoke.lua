-- Exercise real scoring previews: every call creates and binds a temporary game.
local Game=require('src.game_state')
local Deck=require('src.deck')
local Poker=require('src.poker')
local Abilities=require('src.card_abilities')
local Scoring=require('src.scoring')
local Basics=require('src.spn_basics')
local Equipment=require('src.equipment')
local g=Game.new()
g.hand={};g.deck={};g.discardPile={};g.persistentDeck={};g.deities={}
for rank=2,14 do for _,suit in ipairs(Deck.SUIT_ORDER) do
    local c=Deck.newCard(rank,suit)
    c.equipments={Equipment.ITEMS.gem_fire,Equipment.ITEMS.basic_plate}
    g.persistentDeck[#g.persistentDeck+1]=c
    local pile=#g.hand<8 and g.hand or g.deck;pile[#pile+1]=c
end end
g.monster={hp=10000,maxHp=10000,armor=0,attackSpeed=1};g.enemies={g.monster}
Abilities.start(g)
local hand=assert(Poker.evaluate({g.hand[1],g.hand[2],g.hand[3],g.hand[4],g.hand[5]}))
local ctx={preview=true,gameState=g,monster=g.monster}
local function count()
    local n=0;for _ in pairs(Basics.cardGames) do n=n+1 end;return n
end
local function collect() collectgarbage('collect');collectgarbage('collect') end
-- Warm LuaJIT traces before comparing retained objects and heap size.
for _=1,100 do Scoring.calculate(hand,g.deities,ctx) end;collect()
local baseline=count();local memory=collectgarbage('count')
for batch=1,10 do
    for _=1,100 do Scoring.calculate(hand,g.deities,ctx) end
    collect()
    assert(count()<=baseline+5,'Scoring previews retain temporary games/cards after GC: '..count()..' bindings (baseline '..baseline..')')
end
local growth=collectgarbage('count')-memory
assert(growth<1024,'Scoring previews retain more than 1 MiB after warmup: '..growth..' KiB')
assert(not g.abilityHand and #g.hand==8,'Preview changed the live game')
print(('Preview memory PASS: 1000 full-deck previews, retained bindings %d -> %d, Lua growth %.1f KiB'):format(baseline,count(),growth))

local D=require("src.deities")
local Deck=require("src.deck")
local Game=require("src.game_state")
local Poker=require("src.poker")
local Scoring=require("src.scoring")
local Persistence=require("src.persistence")
local Rng=require("src.rng")
local function game()
    local g=Game.new();g.deities={};g.hand={};g.monster={hp=10000,maxHp=10000,attack=1,attackSpeed=1}
    assert(D.addDeity(g,D.CATALOG.spirit_twin_fang,5));return g
end
local function score(g,ranks,preview)
    local cards={};for _,rank in ipairs(ranks) do cards[#cards+1]=Deck.newCard(rank,"hearts");cards[#cards].disableFactionPassives=true end
    return Scoring.calculate(assert(Poker.evaluate(cards)),g.deities,{gameState=g,monster=g.monster,preview=preview})
end
local function factor(result)
    for _,step in ipairs(result.steps) do if step.type=="deity_hand" and step.deity.id=="spirit_twin_fang" then return step.xChips,step.message end end
end
local g=game()
for _,ranks in ipairs({{3},{3,3},{2,5,8,10,13}}) do
    local rng=Rng.getState();local preview=score(g,ranks,true);local actual=score(g,ranks)
    assert(factor(actual)==2 and actual.totalChips==preview.totalChips and actual.finalScore==preview.finalScore)
    local owned=g.deities;g.deities={};local base=score(g,ranks);g.deities=owned
    assert(actual.totalChips==base.totalChips*2 and actual.totalMult==base.totalMult)
    assert(Rng.getState()==rng,"unconditional multiplier uses no RNG")
end
D.evolve(g.deities[5]);assert(factor(score(g,{3}))==2.5 and D.getDescription(g.deities[5]):find("×2.5",1,true))
local _,message=factor(score(g,{3}));assert(message:find("×2.5",1,true),"scoring message uses the evolved factor")
D.evolve(g.deities[5]);assert(factor(score(g,{3}))==3)
-- Bonuses to the left are multiplied; later flat bonuses are added afterwards.
g=game();assert(D.addDeity(g,D.CATALOG.spirit_pebble,1))
local before=score(g,{3});g.deities[1],g.deities[5]=g.deities[5],g.deities[1]
local after=score(g,{3});assert(before.totalChips-after.totalChips==20)
g=game();assert(D.addDeity(g,D.CATALOG.spirit_twin_fang,1))
local actual=score(g,{3});g.deities={};assert(actual.totalChips==score(g,{3}).totalChips*4,"owned duplicates multiply together")
g=game();g.monster.isBoss=true;g.monster.bossState={handIndex=1,passiveUntil=0,slotLock={kind="spn",slot=5,untilHand=1}}
assert(not factor(score(g,{3})),"Boss lock disables the effect")
g=game();D.evolve(g.deities[5]);local restored=assert(Persistence.restoreSnapshot(Persistence.makeSnapshot(g,"shop")))
restored.monster=g.monster;assert(restored.deities[5].onHandScored and factor(score(restored,{3}))==2.5)
assert(#D.getRandomShopPool({},99)==78)
print("SPN twin fang PASS: unconditional damage axis, all hand sizes, evolution, order/products, pure preview/RNG, locks and save/load")

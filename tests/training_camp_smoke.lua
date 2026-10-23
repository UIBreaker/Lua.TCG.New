local M=require("src.training_camp")
local G=require("src.game_state")
local Run=require("src.run_manager")
local Deck=require("src.deck")
local P=require("src.persistence")
local R=require("src.rng")
local function fixture()
    local g=G.new("red_deck");g.run=Run.newRun("red_deck")
    g.run.ante=3;g.run.areaStage=3;g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(3,nil,"human",3);g.run.blinds[3].status="completed"
    g.persistentDeck={};for i=1,4 do g.persistentDeck[i]=Deck.newCard(i+2,"hearts") end
    g.playerHp=20;g.maxPlayerHp=100
    return g,M.create(g)
end
local function reload(g) return P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"training_camp"))))) end
local g,e=fixture()
assert(not M.leave(g) and not M.train(g) and not M.toggle(g,g.persistentDeck[1].id))
assert(M.choose(g,"rest") and g.maxPlayerHp==110 and g.playerHp==92 and e.healed==72)
assert(not M.choose(g,"train") and not M.choose(g,"rest"))
g=reload(g);assert(g.trainingCamp.phase=="results" and g.playerHp==92 and M.leave(g) and not M.leave(g))
g.trainingCamp=nil;assert(not M.create(g),"Cannot revisit a completed camp")
g,e=fixture();g.playerHp=100;assert(M.choose(g,"rest") and g.playerHp==110 and e.healed==10)
g,e=fixture();assert(M.choose(g,"train") and not M.choose(g,"rest") and not M.train(g))
assert(not M.toggle(g,"missing"))
local cards=g.persistentDeck
for i=1,3 do assert(M.toggle(g,cards[i].id)) end
assert(not M.toggle(g,cards[4].id) and #e.selected==3)
assert(M.toggle(g,cards[1].id) and M.toggle(g,cards[1].id))
g=reload(g);e=g.trainingCamp;assert(e.phase=="select" and #e.selected==3)
cards=g.persistentDeck;g.hand={cards[1]};g.deck={Deck.cloneCard(cards[2])};g.deck[1].id=cards[2].id
local random=R.random;local rolls={1,2,3};R.random=function(n) return table.remove(rolls,1) or 1 end
local before={};for _,c in ipairs(cards) do before[c.id]={chips=c.baseChips,speed=Deck.getCardAttackSpeed(c),mult=Deck.getCardEmpowerment(c)} end
assert(M.train(g) and e.phase=="results" and #e.results==3 and not M.train(g))
for _,result in ipairs(e.results) do
    local c;for _,v in ipairs(cards) do if v.id==result.id then c=v end end
    local b=before[c.id]
    if result.stat=="damage" then assert(c.baseChips==b.chips+5)
    elseif result.stat=="mult" then assert(Deck.getCardEmpowerment(c)==b.mult+5 and Deck.getCardEmpowerment(Deck.cloneCard(c))==b.mult+5)
    else assert(Deck.getCardAttackSpeed(c)==b.speed+5) end
end
assert(cards[4].baseChips==before[cards[4].id].chips and g.playerHp==20 and g.maxPlayerHp==100)
assert(g.deck[1].baseChips==cards[2].baseChips,"Matching card instances must stay synchronized")
local gains=P.encode(e.results);local saved=reload(g)
assert(P.encode(saved.trainingCamp.results)==gains and not M.train(saved) and not M.choose(saved,"rest"))
for i,c in ipairs(cards) do assert(Deck.getCardEmpowerment(saved.persistentDeck[i])==Deck.getCardEmpowerment(c)) end
assert(M.leave(saved));saved=reload(saved);assert(not M.leave(saved))
g,e=fixture();assert(M.choose(g,"train") and M.toggle(g,g.persistentDeck[1].id) and M.train(g) and #e.results==1)
g,e=fixture();Deck.applyAttackSpeedBonus(g.persistentDeck[1],999);M.choose(g,"train");M.toggle(g,g.persistentDeck[1].id)
R.random=function(n) return n end;assert(M.train(g) and e.results[1].stat~="speed")
R.random=function() return 0 end
g,e=fixture();assert(M.roll(g) and not M.roll(g));g.run.ante=4;assert(not M.roll(g))
g.run.ante=5;g.bloodDomain={};assert(not M.roll(g));g.bloodDomain=nil;g.run.currentBlindIndex=1;assert(not M.roll(g))
g.run.currentBlindIndex=3;g.run.blinds[3].status="current";assert(not M.roll(g))
R.random=random
print("Training camp PASS: odd-stage once-only roll, exclusive rest/train, capped 65% heal +10 max HP, 1-3 distinct permanent upgrades, exact +5 all stats, instance sync, speed ceiling and save/load without rerolls or repeat claims")

local M=require("src.memory_match")
local R=require("src.rng")
local G=require("src.game_state")
local Run=require("src.run_manager")
local P=require("src.persistence")
local function fixture()
    local g=G.new("red_deck");g.run=Run.newRun("red_deck")
    g.gold=200
    g.run.ante=3;g.run.areaStage=3;g.run.currentBlindIndex=3
    g.run.blinds=Run.generateAnteBlinds(3,nil,"human",3);g.run.blinds[3].status="completed"
    return g,M.create(g)
end
local function indices(e,pair)
    local result={};for i,c in ipairs(e.cards) do if c.pair==pair then result[#result+1]=i end end;return result
end
local function match(g,pair)
    local p=indices(g.memoryMatch,pair)
    assert(M.flip(g,p[1]) and not M.flip(g,p[1]) and M.flip(g,p[2]))
    M.update(g,2)
end
local g,e=fixture();assert(#e.cards==18 and #e.pairs==9 and e.remaining==M.flips and not M.flip(g,1))
for i,p in ipairs(e.pairs) do assert(#indices(e,i)==2 and p.item.id) end
for i,f in ipairs(M.supportFactories) do assert(e.pairs[i].item.id==Run[f]().id) end
local ids={};for i=7,9 do assert(e.pairs[i].kind=="spn" and not ids[e.pairs[i].item.id]);ids[e.pairs[i].item.id]=true end
assert(M.start(g) and not M.start(g));assert(not M.flip(g,0) and not M.flip(g,1.5) and not M.flip(g,19))
match(g,1);assert(e.matched==1 and e.streak==1 and M.multiplier(e)==1)
match(g,2);assert(e.matched==2 and e.streak==2 and M.multiplier(e)==2)
local a,b=indices(e,3)[1],indices(e,4)[1]
assert(M.flip(g,a) and not M.finish(g) and M.flip(g,b));assert(e.streak==0 and e.resolving and not M.flip(g,indices(e,5)[1]))
M.update(g,.5);assert(e.cards[a].shown);M.update(g,.7)
assert(not e.cards[a].shown and M.finish(g) and e.rewardMultiplier==1 and e.rewardCount==2)
local ok,count=M.claim(g);assert(ok and count==2 and #g.backpackConsumables==2 and not M.claim(g))
g.memoryMatch=nil;assert(not M.create(g),"A claimed event cannot be rerolled")

g,e=fixture();M.start(g)
for pair=1,9 do match(g,pair) end
assert(e.phase=="results" and e.streak==9 and e.rewardMultiplier==4 and e.rewardCount==36)
ok,count=M.claim(g);assert(ok and count==36 and #g.backpackConsumables==24 and #g.backpackDeities==12)
assert(g.backpackDeities[1]~=g.backpackDeities[2]);if g.backpackDeities[1].values then assert(g.backpackDeities[1].values~=g.backpackDeities[2].values) end
assert(#g.deities==0,"Rewards go to reserve, not automatic combat slots")

g,e=fixture();M.start(g);local p=indices(e,1)
M.flip(g,p[1]);local board=P.encode(e.cards);local rng=R.getState()
local loaded,state=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"memory_match")))))
assert(state=="memory_match" and loaded.memoryMatch.remaining==M.flips-1 and P.encode(loaded.memoryMatch.cards)==board)
assert(loaded.memoryMatch.open[1]==p[1] and not M.flip(loaded,p[1]))
M.flip(loaded,p[2]);M.update(loaded,2);assert(loaded.memoryMatch.matched==1)
for i=7,9 do
    local item=loaded.memoryMatch.pairs[i].item;local source=require("src.deities").CATALOG[item.id]
    if source.onHandScored then assert(type(item.onHandScored)=="function") end
end
M.finish(loaded);local snap=P.makeSnapshot(loaded,"memory_match");local restored=P.restoreSnapshot(assert(P.decode(P.encode(snap))))
assert(M.claim(restored));local paid=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(restored,"memory_match")))));assert(not M.claim(paid))

g,e=fixture();M.start(g)
for turn=1,M.flips/2 do local x,y=indices(e,1)[1],indices(e,2)[1];assert(M.flip(g,x) and M.flip(g,y));M.update(g,2) end
assert(e.remaining==0 and e.phase=="results" and e.rewardCount==0 and not M.flip(g,1))
local random=R.random;local calls=0;R.random=function() calls=calls+1;return 0 end
g=G.new("red_deck");g.run=Run.newRun("red_deck");local run=g.run
run.currentBlindIndex=3;run.blinds[3].status="completed"
assert(M.roll(g));local before=calls;assert(not M.roll(g) and calls==before)
run.ante=2;assert(not M.roll(g));run.ante=5;g.bloodDomain={};assert(not M.roll(g));g.bloodDomain=nil
run.currentBlindIndex=1;assert(not M.roll(g));run.currentBlindIndex=3;run.blinds[3].status="current";assert(not M.roll(g))
R.random=random
local sum=0;for _,w in ipairs(M.rarityWeights) do sum=sum+w end;assert(math.abs(sum-100)<1e-8)
print("Memory match PASS: odd-stage once-only event, nine exact pairs/support assets/SPNs, finite flips, combo loss/cap, early bank, independent backpack rewards, no double claim and mid-flip save/load")

g,e=fixture();g.gold=49
assert(not M.start(g) and g.gold==49 and e.phase=="ready" and not e.entryPaid)
assert(M.skip(g) and M.claim(g) and g.gold==49 and not M.start(g))
g,e=fixture();g.gold=50
assert(M.start(g) and g.gold==0 and e.entryPaid==50 and not M.start(g))
g=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"memory_match")))))
assert(g.gold==0 and g.memoryMatch.entryPaid==50 and g.memoryMatch.phase=="playing" and not M.start(g))
g,e=fixture();g.gold=125
g=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(g,"memory_match")))))
assert(M.start(g) and g.gold==75)
assert(M.finish(g) and M.claim(g) and g.gold==75)
print("Memory entry fee PASS: requires 50 gold, exactly one charge, free skip, no double charge or reload payment")
return true

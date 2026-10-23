local R=require("src.rng")
local Clone=require("src.blood_shop").clone
local M={chance=.25,flips=24,maxMultiplier=4,entryFee=50}
M.rarityWeights={45,25,15,8,4,1.5,.8,.4,.2,.1}
M.supportFactories={"createEvolutionCard","createSpeedSingleCard","createSpeedTeamCard","createVitalityCard","createSpnSlotCard","createConsumableSlotCard"}
local function key(g) local r=g.run or {};return (r.regionId or "legacy")..":"..(r.ante or g.round or 1) end
function M.roll(g)
    local r=g.run
    if not r or g.bloodDomain or r.ante%2~=1 or r.currentBlindIndex~=3 or not r.blinds or r.blinds[3].status~="completed" then return false end
    g.memoryMatchChecked=g.memoryMatchChecked or {};local k=key(g)
    if g.memoryMatchChecked[k] or (g.memoryMatchClaimed or {})[k] then return false end
    g.memoryMatchChecked[k]=true;return R.random()<M.chance
end
function M.multiplier(e) return math.max(1,math.min(M.maxMultiplier,e.streak or 0)) end
function M.rarity()
    local roll=R.random()*100;local total=0
    for i,w in ipairs(M.rarityWeights) do total=total+w;if roll<total then return i end end
    return #M.rarityWeights
end
function M.create(g)
    if g.memoryMatch then return g.memoryMatch end
    local k=key(g);if (g.memoryMatchClaimed or {})[k] then return nil end
    local Run=require("src.run_manager");local D=require("src.deities")
    local e={key=k,phase="ready",remaining=M.flips,streak=0,matched=0,pairs={},cards={},open={},age=0,message="Ghi nhớ vị trí. Giữ chuỗi. Biết lúc dừng."}
    for _,factory in ipairs(M.supportFactories) do e.pairs[#e.pairs+1]={kind="consumable",item=Run[factory]()} end
    for _,source in ipairs(D.getRandomShopPool({},3)) do
        local item=Clone(source);item.evolutionLevel=0;item.evolutionCredits=0
        D.setRarity(item,D.RARITIES[M.rarity()].id)
        e.pairs[#e.pairs+1]={kind="spn",item=item}
    end
    for index in ipairs(e.pairs) do for _=1,2 do e.cards[#e.cards+1]={pair=index,turn=0} end end
    for i=#e.cards,2,-1 do local j=R.random(i);e.cards[i],e.cards[j]=e.cards[j],e.cards[i] end
    g.pendingMemoryMatch=nil;g.memoryMatch=e;return e
end
function M.start(g)
    local e=g.memoryMatch;if not e or e.phase~="ready" then return false end
    if (g.gold or 0)<M.entryFee then return false end
    g.gold=g.gold-M.entryFee;e.entryPaid=M.entryFee
    e.phase="playing";return true
end
function M.skip(g)
    local e=g.memoryMatch;if not e or e.phase~="ready" then return false end
    e.phase="results";e.rewardMultiplier=1;e.rewardCount=0;return true
end
function M.finish(g)
    local e=g.memoryMatch
    if not e or e.phase~="playing" or e.resolving or #e.open>0 then return false end
    e.phase="results";e.rewardMultiplier=M.multiplier(e);e.rewardCount=e.matched*e.rewardMultiplier
    return true
end
function M.flip(g,index)
    local e=g.memoryMatch
    if not e or e.phase~="playing" or e.resolving or e.remaining<=0 or type(index)~="number" or index%1~=0 then return false end
    local card=e.cards[index];if not card or card.shown or card.matched then return false end
    card.shown=true;e.remaining=e.remaining-1;e.open[#e.open+1]=index
    if #e.open==2 then
        local a,b=e.cards[e.open[1]],e.cards[e.open[2]];local same=a.pair==b.pair
        if same then
            a.matched=true;b.matched=true;e.pairs[a.pair].matched=true;e.matched=e.matched+1;e.streak=e.streak+1
            e.message="TÌM ĐƯỢC CẶP · "..e.pairs[a.pair].item.name.." · CHUỖI "..e.streak.." / ×"..M.multiplier(e)
        else e.streak=0;e.message="KHÔNG TRÙNG · MẤT CHUỖI · VẪN GIỮ 1 LÁ MỖI CẶP" end
        e.resolving={timer=same and .55 or 1.1,matched=same}
    end
    return true
end
function M.update(g,dt)
    local e=g.memoryMatch;if not e then return false end
    dt=math.max(0,dt or 0);e.age=(e.age or 0)+dt
    for _,c in ipairs(e.cards) do
        local target=(c.shown or c.matched) and 1 or 0
        c.turn=(c.turn or target)+(target-(c.turn or target))*math.min(1,dt*14)
    end
    if not e.resolving then return false end
    e.resolving.timer=e.resolving.timer-dt
    if e.resolving.timer>0 then return false end
    if not e.resolving.matched then for _,i in ipairs(e.open) do e.cards[i].shown=false end end
    e.open={};e.resolving=nil
    if e.remaining==0 or e.matched==#e.pairs then M.finish(g) end
    return true
end
function M.claim(g)
    local e=g.memoryMatch
    if not e or e.phase~="results" then return false end
    g.memoryMatchClaimed=g.memoryMatchClaimed or {}
    if g.memoryMatchClaimed[e.key] then return false end
    local Loadout=require("src.loadout");local n=0
    for _,reward in ipairs(e.pairs) do if reward.matched then for _=1,e.rewardMultiplier do
        local item=Clone(reward.item)
        if reward.kind=="spn" then Loadout.storeDeity(g,item) else Loadout.storeConsumable(g,item) end
        n=n+1
    end end end
    g.memoryMatchClaimed[e.key]=true;e.phase="claimed";return true,n
end
function M.restore(g)
    local e=g.memoryMatch;if not e then return end
    local D=require("src.deities")
    for _,reward in ipairs(e.pairs or {}) do if reward.kind=="spn" and D.CATALOG[reward.item.id] then
        local item=Clone(D.CATALOG[reward.item.id]);for k,v in pairs(reward.item) do item[k]=v end;reward.item=item
    end end
end
return M

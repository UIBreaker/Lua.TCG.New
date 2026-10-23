local M=require("src.memory_match")
local R=require("src.rng")
local function play(seed,skill)
    R.seed(seed*104729+31);local g={round=seed,gold=50};local e=M.create(g);assert(M.start(g) and g.gold==0)
    local remembered={}
    while e.phase=="playing" do
        local available,unseen={},{}
        for i,c in ipairs(e.cards) do if not c.matched then available[#available+1]=i;if not remembered[i] then unseen[#unseen+1]=i end end end
        local a,b
        if skill then
            local first={}
            for _,i in ipairs(available) do local pair=remembered[i];if pair then if first[pair] then a,b=first[pair],i;break else first[pair]=i end end end
        end
        a=a or (skill and unseen[1]) or available[R.random(#available)]
        assert(M.flip(g,a));remembered[a]=e.cards[a].pair
        if skill and not b then for _,i in ipairs(available) do if i~=a and remembered[i]==remembered[a] then b=i;break end end end
        if not b and skill then for _,i in ipairs(unseen) do if i~=a then b=i;break end end end
        if not b then local choices={};for _,i in ipairs(available) do if i~=a then choices[#choices+1]=i end end;b=choices[R.random(#choices)] end
        assert(M.flip(g,b));remembered[b]=e.cards[b].pair;M.update(g,2)
        if e.phase=="playing" and e.streak>=4 and e.matched>=5 then M.finish(g) end
    end
    return e.matched,e.rewardCount,e.matched==9 and 1 or 0
end
local trials=1000;local stats={}
for _,skill in ipairs({false,true}) do
    local pairs,rewards,clears=0,0,0
    for seed=1,trials do local a,b,c=play(seed,skill);pairs=pairs+a;rewards=rewards+b;clears=clears+c;assert(b<=36) end
    local result={pairs=pairs/trials,rewards=rewards/trials,clears=clears/trials};stats[skill and "memory" or "random"]=result
    print(string.format("%s: %d games; %.3f pairs; %.3f reward cards; %.1f%% clear",skill and "Memory strategy" or "Blind flips",trials,result.pairs,result.rewards,result.clears*100))
end
assert(stats.memory.pairs>stats.random.pairs*1.5 and stats.memory.rewards>stats.random.rewards*2,"Remembered positions should substantially outperform blind luck")
print("Memory balance PASS: same board/reward rules; skill advantage without exceeding the 36-card cap")
return stats

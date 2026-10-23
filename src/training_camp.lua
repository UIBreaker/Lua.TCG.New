local R=require("src.rng")
local M={chance=.25,maxCards=3,bonus=5}
local function key(g) local r=g.run or {};return (r.regionId or "legacy")..":"..(r.ante or g.round or 1) end
function M.roll(g)
    local r=g.run
    if not r or g.bloodDomain or r.ante%2~=1 or r.currentBlindIndex~=3 or not r.blinds or r.blinds[3].status~="completed" then return false end
    g.trainingCampChecked=g.trainingCampChecked or {};local k=key(g)
    if g.trainingCampChecked[k] or (g.trainingCampClaimed or {})[k] then return false end
    g.trainingCampChecked[k]=true;return R.random()<M.chance
end
function M.cards(g)
    local cards={};local seen={}
    for _,c in ipairs(g.persistentDeck or {}) do
        if c.id and not c.destroyed and not seen[c.id] then cards[#cards+1]=c;seen[c.id]=true end
    end
    return cards
end
function M.create(g)
    if g.trainingCamp then return g.trainingCamp end
    if (g.trainingCampClaimed or {})[key(g)] then return nil end
    g.pendingTrainingCamp=nil
    g.trainingCamp={key=key(g),phase="choice",selected={},page=1}
    return g.trainingCamp
end
function M.choose(g,branch)
    local e=g.trainingCamp
    if not e or e.phase~="choice" or (branch~="rest" and branch~="train") then return false end
    if branch=="train" and #M.cards(g)==0 then return false end
    e.branch=branch
    if branch=="rest" then
        local before=g.playerHp or 0;e.oldMax=g.maxPlayerHp or 100
        g.maxPlayerHp=e.oldMax+10
        e.healed=require("src.player_health").heal(g,math.ceil(g.maxPlayerHp*.65))
        e.beforeHp=before;e.afterHp=g.playerHp;e.newMax=g.maxPlayerHp;e.phase="results"
    else e.phase="select" end
    return true
end
function M.toggle(g,id)
    local e=g.trainingCamp;if not e or e.phase~="select" then return false end
    for i,v in ipairs(e.selected) do if v==id then table.remove(e.selected,i);return true end end
    if #e.selected>=M.maxCards then return false end
    for _,c in ipairs(M.cards(g)) do if c.id==id then e.selected[#e.selected+1]=id;return true end end
    return false
end
function M.train(g)
    local e=g.trainingCamp;if not e or e.phase~="select" or #e.selected==0 or #e.selected>M.maxCards then return false end
    local byId={};for _,c in ipairs(M.cards(g)) do byId[c.id]=c end
    local seen={};for _,id in ipairs(e.selected) do if not byId[id] or seen[id] then return false end;seen[id]=true end
    e.results={}
    local Deck=require("src.deck")
    for _,id in ipairs(e.selected) do
        local c=byId[id];local stats={"damage","mult"}
        -- Do not spend a training reward on a stat already at the speed ceiling.
        if Deck.getCardAttackSpeed(c)<=994 then stats[#stats+1]="speed" end
        local stat=stats[R.random(#stats)]
        if stat=="speed" then
            require("src.chest_expansion").sync(g,c,function(card) Deck.applyAttackSpeedBonus(card,M.bonus) end)
        elseif stat=="mult" then
            require("src.chest_expansion").sync(g,c,function(card) card.trainingEmpowerment=(card.trainingEmpowerment or 0)+M.bonus end)
        else require("src.potions").makePermanent(g,c,stat,M.bonus) end
        e.results[#e.results+1]={id=id,stat=stat,amount=M.bonus}
    end
    e.phase="results";return true
end
function M.leave(g)
    local e=g.trainingCamp;if not e or e.phase~="results" then return false end
    g.trainingCampClaimed=g.trainingCampClaimed or {}
    if g.trainingCampClaimed[e.key] then return false end
    g.trainingCampClaimed[e.key]=true;e.phase="claimed";return true
end
return M

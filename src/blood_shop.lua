local B={chance=.30,power=5,priceFactor=8,smallCount=8,largeCount=16}
function B.isMode(mode) return mode=="blood_small" or mode=="blood_large" end
function B.powerOf(item) return type(item)=="table" and item.bloodPower==5 and 5 or 1 end
function B.clone(value)
    if type(value)~="table" then return value end
    local copy={};for k,v in pairs(value) do copy[k]=B.clone(v) end;return copy
end
local benefits={heal=true,armor=true,speed=true,bonus=true,charge=true,returnArmor=true,healPercent=true,gold=true,gain=true,maxStacks=true,
    capacity=true,draw=true,levels=true,repeats=true,returns=true,duration=true,hands=true,cancels=true,skip=true,block=true,
    copies=true,maxGold=true,healAmt=true,armorAmt=true,hp=true,discount=true,cap=true,discards=true,chips=true,mult=true,
    edge=true,combo=true,small=true,damagePercent=true,freeze=true}
function B.params(params,power,counts)
    if power==1 then return params end
    local copy={};for k,v in pairs(params or {}) do copy[k]=type(v)=="number" and (benefits[k] or counts and k=="count") and v*power or v end;return copy
end
local effects={healHp=true,xMultBonus=true,extraDamagePct=true,xMult=true,xChips=true,xAura=true,xSoulYield=true,
    bedExplosionPct=true,consumableChancePct=true,discardCopies=true,bossCopies=true,copyActivations=true,repeatsPerLevel=true,uqChancePct=true}
function B.effect(result,power)
    if not result or power==1 then return result end
    local copy={}
    for k,v in pairs(result) do
        if type(v)=="number" and (effects[k] or type(k)=="string" and k:sub(1,3)=="add") then
            copy[k]=v*power
            if k:match("ChancePct$") or k=="addRedirectPct" then copy[k]=math.min(100,copy[k]) end
            if k=="addTransmutePct" then copy[k]=math.min(90,copy[k]) end
            if k=="copyActivations" or k=="repeatsPerLevel" then copy[k]=math.min(128,math.floor(copy[k])) end
        else copy[k]=v end
    end
    return copy
end
function B.describe(text,power)
    if power==1 then return text end
    return (text or ""):gsub("(%+)(%d+%.?%d*)",function(sign,n) return sign..string.format("%g",tonumber(n)*power) end)
        .."\nHUYẾT LUYỆN ×5 · Chỉ số hiệu quả gấp 5; điều kiện, chi phí phụ và số ô giữ nguyên."
end
function B.reward(item)
    local copy=B.clone(item);copy.bloodPower=5
    if copy.healAmt then copy.healAmt=copy.healAmt*5 end
    if copy.armorAmt then copy.armorAmt=copy.armorAmt*5 end
    if copy.category=="combat_potion" then copy.desc=require("src.potions").describe(copy) end
    if copy.rank then
        copy.baseChips=(copy.baseChips or require("src.deck").getChipValue(copy.rank))*5
        copy.bonusBaseChips=copy.baseChips-require("src.deck").getChipValue(copy.rank)
        require("src.deck").getCardAttackSpeed(copy)
    elseif require("src.equipment").ITEMS[copy.id] then
        copy=require("src.equipment").instance(copy.id,copy)
    end
    return copy
end
function B.applyConsumable(game,item,target,apply)
    local power=B.powerOf(item)
    if power==1 then return apply(game,item,target) end
    local fields={"baseChips","bonusBaseChips","speedBonus","evolutionLevel","temporaryAbilityLevels","depthInvestment"}
    local before={};local saved={gold=game.gold or 0,hp=game.playerHp or 0,maxHp=game.maxPlayerHp or 100}
    for _,c in ipairs(game.persistentDeck or {}) do
        before[c]={};for _,k in ipairs(fields) do before[c][k]=c[k] or 0 end
    end
    local ok,message=apply(game,item,target)
    if not ok then return ok,message end
    for _,c in ipairs(game.persistentDeck or {}) do
        if not before[c] then
            local strong=B.reward(c);for k,v in pairs(strong) do c[k]=v end
        else
            for _,k in ipairs(fields) do
                local gain=(c[k] or 0)-before[c][k]
                if gain>0 then local n=(c[k] or 0)+gain*(power-1)
                    if k=="evolutionLevel" then n=math.min(require("config.card_ability_data").maxEvolutionLevel,n) end
                    require("src.chest_expansion").sync(game,c,function(copy) copy[k]=n end)
                end
            end
        end
    end
    if (game.gold or 0)>saved.gold then game.gold=saved.gold+(game.gold-saved.gold)*power end
    if game.maxPlayerHp>saved.maxHp then game.maxPlayerHp=saved.maxHp+(game.maxPlayerHp-saved.maxHp)*power end
    if game.playerHp>saved.hp then game.playerHp=math.min(game.maxPlayerHp,saved.hp+(game.playerHp-saved.hp)*power) end
    for _,d in pairs(game.deities or {}) do if item.id:match("^spell_") and d.enchantment==item.id then d.enchantmentPower=power end end
    return ok,message
end
function B.offer(item)
    local copy=B.clone(item);copy.bloodPower=5;copy.currency="blood"
    copy.cost=math.max(16,math.ceil((item.cost or 4)*B.priceFactor));copy.sale=nil;copy.free=nil
    for _,field in ipairs({"card","deity","equipment","consumable"}) do if copy[field] then copy[field]=B.reward(copy[field]) end end
    copy.subtitle="HUYẾT LUYỆN ×5";return copy
end
function B.roll(game)
    local run=game.run
    if not run or (run.ante or 1)%2==0 or (run.currentBlindIndex or 1)~=3 then return end
    local key=tostring(run.ante)..":"..tostring(run.regionId or "human")
    game.bloodShopChecked=game.bloodShopChecked or {}
    if game.bloodShopChecked[key] then return end
    game.bloodShopChecked[key]=true
    if require("src.rng").random()<B.chance then
        return require("src.rng").random()<.25 and "blood_large" or "blood_small"
    end
    game.maxPlayerHp=(game.maxPlayerHp or 100)+3
    game.bloodShopNotice="Không gặp Shop Máu · +3 máu tối đa"
end
return B

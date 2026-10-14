local L={CONSUMABLE_STACK_LIMIT=99}
local Inventory=require("src.inventory")
local function storageKey(kind) return kind=="spn" and "backpackDeities" or "backpackConsumables" end
function L.init(game)
    game.backpackDeities=game.backpackDeities or {}
    game.backpackConsumables=game.backpackConsumables or {}
    game.deities=game.deities or {};game.consumables=game.consumables or {}
    local used={}
    for _,item in ipairs(game.consumables) do
        local slot=item.loadoutSlot
        if type(slot)~="number" or slot~=math.floor(slot) or slot<1 or slot>Inventory.limit(game) or used[slot] then item.loadoutSlot=nil
        else used[slot]=true end
    end
    for _,item in ipairs(game.consumables) do if not item.loadoutSlot then
        for slot=1,Inventory.limit(game) do if not used[slot] then item.loadoutSlot=slot;used[slot]=true;break end end
    end end
end
function L.storeConsumable(game,item)
    L.init(game);item.loadoutSlot=nil
    game.backpackConsumables[#game.backpackConsumables+1]=item
end
-- Group the reserve view without losing per-card reward receipts or old save data.
local stackIgnored={loadoutSlot=true,victoryRewardReceipt=true,slotIndex=true,alpha=true,hovered=true}
local function sameValue(a,b,seen,root)
    if a==b then return true end
    if type(a)~=type(b) or type(a)~="table" then return false end
    seen=seen or {};if seen[a]==b then return true end;seen[a]=b
    for key,value in pairs(a) do
        if not (root and stackIgnored[key]) and not sameValue(value,b[key],seen,false) then return false end
    end
    for key in pairs(b) do if not (root and stackIgnored[key]) and a[key]==nil then return false end end
    return true
end
function L.consumableStacks(game)
    local stacks,byId={},{}
    for index,item in ipairs(game.backpackConsumables or {}) do
        local bucket=item.id and byId[item.id] or {};local stack,bucketIndex
        for i,candidate in ipairs(bucket) do
            if sameValue(item,candidate.item,nil,true) then stack=candidate;bucketIndex=i;break end
        end
        if stack then
            stack.count=stack.count+1
            if stack.count==L.CONSUMABLE_STACK_LIMIT then table.remove(bucket,bucketIndex) end
        else
            stack={item=item,index=index,count=1};stacks[#stacks+1]=stack
            if item.id then byId[item.id]=bucket;bucket[#bucket+1]=stack end
        end
    end
    return stacks
end
function L.storeDeity(game,deity)
    L.init(game)
    local instance={};for k,v in pairs(deity) do instance[k]=v end
    game.backpackDeities[#game.backpackDeities+1]=instance
    return instance
end
function L.ownedDeities(game)
    local list={}
    for _,d in pairs(game.deities or {}) do list[#list+1]=d end
    for _,d in ipairs(game.backpackDeities or {}) do list[#list+1]=d end
    return list
end
function L.limit(game,kind)
    return kind=="spn" and require("src.deities").getMaxSlots(game) or Inventory.limit(game)
end
function L.equipped(game,kind,slot)
    L.init(game)
    if kind=="spn" then return game.deities[slot],slot end
    for i,item in ipairs(game.consumables) do if item.loadoutSlot==slot then return item,i end end
end
function L.move(game,kind,source,index,destination,inCombat)
    if kind~="spn" and kind~="consumable" then return false,"Chọn SPN hoặc thẻ tiêu hao." end
    L.init(game)
    local reserve=game[storageKey(kind)]
    local item,activeIndex
    if source=="equipped" then item,activeIndex=L.equipped(game,kind,index)
    elseif source=="reserve" then item=reserve[index] end
    if not item then return false,"Món đồ không còn ở vị trí này." end
    if destination==index and source=="equipped" then return false,"Lá đã ở ô này." end
    if source=="reserve" and not destination then return false,"Kéo lên một ô trang bị." end
    local limit=L.limit(game,kind)
    if kind=="spn" and source=="reserve" and item.edition=="negative" then limit=limit+math.max(item.editionPower==5 and 5 or 1,require("src.blood_shop").powerOf(item)) end
    if destination and (destination<1 or destination>limit or destination~=math.floor(destination)) then return false,"Ô trang bị không hợp lệ." end
    if inCombat then
        if (game.handsRemaining or 0)<=0 then return false,"Hết lượt đánh. Kết thúc lượt trước khi đổi đồ." end
        local Boss=require("src.boss_abilities")
        if source=="equipped" and Boss.isSlotLocked(game,kind,index)
            or destination and Boss.isSlotLocked(game,kind,destination) then return false,"Ô này đang bị boss khóa." end
    end
    local other,otherIndex
    if destination then other,otherIndex=L.equipped(game,kind,destination) end
    if kind=="spn" then
        if source=="equipped" then game.deities[index]=other else table.remove(reserve,index) end
        if destination then game.deities[destination]=item end
    else
        if source=="equipped" then
            if destination then item.loadoutSlot=destination;if other then other.loadoutSlot=index end
            else table.remove(game.consumables,activeIndex) end
        else
            if not other and #game.consumables>=Inventory.limit(game) then return false,"Ô tiêu hao đã đầy." end
            -- Legacy rewards may reuse one table for multiple copies; slots need distinct instances.
            local shared=false
            for i,v in ipairs(reserve) do if i~=index and v==item then shared=true;break end end
            for _,v in ipairs(game.consumables) do if v==item then shared=true;break end end
            if shared then local copy={};for k,v in pairs(item) do copy[k]=v end;item=copy end
            table.remove(reserve,index);item.loadoutSlot=destination
            if other then game.consumables[otherIndex]=item else game.consumables[#game.consumables+1]=item end
        end
    end
    if not destination then item.loadoutSlot=nil;reserve[#reserve+1]=item
    elseif source=="reserve" and other then other.loadoutSlot=nil;reserve[#reserve+1]=other end
    if kind=="spn" and inCombat and destination then require("src.spn_pacts").prepare(game) end
    return true,destination and "Đã đổi ô trang bị." or "Đã cất lại vào balo."
end
return L

local Rng=require("src.rng")
local D=require("src.deities")
local E=require("src.equipment")
local Basic=require("src.basic_equipment")
local Loadout=require("src.loadout")
local T={chance=.30,npcPath="assets/scene/events/mysterious_expeditioner.png"}

function T.describe(kind,item)
    return kind=="spn" and D.getDescription(item) or E.getDescription(item)
end
local reasons={
    guard="Tôi sắp vượt vùng hiểm địa. Tôi cần món này để giữ sinh lực và chống đỡ.",
    speed="Đoàn của tôi cần đi trước mối nguy. Tôi đang tìm món hỗ trợ tốc đánh.",
    wealth="Tôi cần tiếp tế cho chuyến đi dài. Món này giúp đoàn duy trì nguồn lực.",
    attack="Đường phía trước có kẻ thù mạnh. Tôi cần món này cho thế đánh của đoàn.",
}
function T.role(kind,item)
    local s=T.describe(kind,item)
    if s:find("Giáp",1,true) or s:find("HP",1,true) or s:find("hồi",1,true) then return "guard" end
    if s:find("Tốc",1,true) or s:find("tốc",1,true) then return "speed" end
    if s:find("Vàng",1,true) or s:find("vàng",1,true) then return "wealth" end
    return "attack"
end
function T.owned(game,kind)
    local list={}
    local function add(key,item,where,source,index,card)
        if item then list[#list+1]={key=key,item=item,where=where,source=source,index=index,card=card} end
    end
    if kind=="spn" then
        for slot,d in pairs(game.deities or {}) do add("active:"..slot,d,"Đang trang bị · Ô "..slot,"active",slot) end
        for i,d in ipairs(game.backpackDeities or {}) do add("reserve:"..i,d,"Trong balo","reserve",i) end
    else
        for i,entry in ipairs(game.backpackEquipment or {}) do add("bag:"..i,Basic.item(entry),"Trong balo","bag",i) end
        for _,c in ipairs(game.persistentDeck or {}) do
            for i,eq in ipairs(c.equipments or {}) do add("socket:"..c.id..":"..i,eq,"Đang khảm · "..(c.characterName or c.rankName or "Quân bài"),"socket",i,c) end
        end
    end
    table.sort(list,function(a,b) return a.key<b.key end)
    return list
end
local function rewardPool(kind,give,owned)
    local pool,preferred={},{}
    local role=T.role(kind,give)
    local ids={};for id in pairs(kind=="spn" and D.CATALOG or E.ITEMS) do ids[#ids+1]=id end;table.sort(ids)
    for _,id in ipairs(ids) do
        local item=(kind=="spn" and D.CATALOG or E.ITEMS)[id]
        local fair=kind=="spn" or ((item.basic==true)==(give.basic==true)
            and (item.soulOnly==true)==(give.soulOnly==true)
            and (item.craftTier or 0)==(give.craftTier or 0)
            and (item.cost or 0)>=(give.cost or 0)*.8 and (item.cost or 0)<=(give.cost or 0)*1.25)
        if id~=give.id and fair then
            pool[#pool+1]=id
            if not owned[id] and T.role(kind,item)~=role then preferred[#preferred+1]=id end
        end
    end
    return #preferred>0 and preferred or pool
end
function T.create(game)
    local event={offers={},offerIndex=1,page=1,ante=game.run.ante,regionId=game.run.regionId,areaStage=game.run.areaStage}
    for _,kind in ipairs({"spn","equipment"}) do
        local owned=T.owned(game,kind);local ids={};for _,entry in ipairs(owned) do ids[entry.item.id]=true end
        local candidates={}
        for _,entry in ipairs(owned) do if #rewardPool(kind,entry.item,ids)>0 then candidates[#candidates+1]=entry.item end end
        local give=candidates[1] and candidates[Rng.random(#candidates)] or (kind=="spn" and D.CATALOG.spirit_pebble or E.ITEMS.gem_fire)
        if give then
            local pool=rewardPool(kind,give,ids)
            if #pool>0 then event.offers[#event.offers+1]={kind=kind,wantedId=give.id,rewardId=pool[Rng.random(#pool)],reason=reasons[T.role(kind,give)]} end
        end
    end
    for i,offer in ipairs(event.offers) do if #T.eligible(game,offer)>0 then event.offerIndex=i;break end end
    game.barterEvent=event
    return event
end
function T.roll(game)
    local run=game.run
    if not run or run.ante%2~=0 or run.currentBlindIndex~=3
        or not run.blinds or not run.blinds[3] or run.blinds[3].status~="completed" then return false end
    local key=run.ante..":"..(run.regionId or "human")
    game.barterChecked=game.barterChecked or {}
    if game.barterChecked[key] then return false end
    game.barterChecked[key]=true
    return Rng.random()<T.chance
end
function T.eligible(game,offer)
    local list={};if not offer then return list end
    for _,entry in ipairs(T.owned(game,offer.kind)) do if entry.item.id==offer.wantedId then list[#list+1]=entry end end
    return list
end
function T.selected(game)
    local event=game.barterEvent;if not event or event.completed then return end
    local offer=event.offers[event.offerIndex]
    for _,entry in ipairs(T.eligible(game,offer)) do if entry.key==event.selectedKey then return entry,offer end end
end
function T.reward(offer,give)
    if offer.kind=="equipment" then return E.instance(offer.rewardId,{bloodPower=give and give.bloodPower,voidPower=give and give.voidPower}) end
    if not D.CATALOG[offer.rewardId] then return nil end
    local item={};for k,v in pairs(D.CATALOG[offer.rewardId]) do item[k]=v end
    for _,k in ipairs({"baseRarity","baseRarityTier","rarity","evolutionLevel","edition","editionPower","enchantment","enchantmentPower","bloodPower","voidPower"}) do
        item[k]=give and give[k] or nil
    end
    item.rarity=item.rarity or "common";return item
end
function T.accept(game)
    local event=game.barterEvent
    if not event or event.completed then return false,"Cuộc trao đổi đã kết thúc." end
    local entry,offer=T.selected(game)
    if not entry then return false,"Chọn đúng món người viễn chinh đang cần." end
    local reward=T.reward(offer,entry.item)
    if not reward then return false,"Món trao đổi không còn hợp lệ." end
    local cost=entry.item.acquisitionCost or entry.item.investment or 0
    if entry.source=="active" then game.deities[entry.index]=nil
    elseif entry.source=="reserve" then table.remove(game.backpackDeities,entry.index)
    elseif entry.source=="bag" then table.remove(game.backpackEquipment,entry.index)
    else table.remove(entry.card.equipments,entry.index) end
    if offer.kind=="spn" then
        Loadout.storeDeity(game,reward)
    else
        Basic.store(game,reward,cost)
    end
    event.receiptGiven=entry.item;event.receiptReward=reward
    event.completed=true;event.confirming=nil;event.givenName=entry.item.name;event.receivedName=reward.name
    event.message="Bạn nhận "..reward.name..". Người viễn chinh nhận "..entry.item.name.."."
    return true,event.message
end
return T

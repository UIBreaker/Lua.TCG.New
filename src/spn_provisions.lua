local Rng=require("src.rng")
local Inventory=require("src.inventory")
local P={}
P.entries={
    {"spirit_wayfarer","Sứ Giả Tiếp Tế","random","Mỗi tay tính điểm: {value}% nhận 1 tiêu hao ngẫu nhiên vào ô tiêu hao. Cần ô trống."},
    {"spirit_first_echo","Ảnh Kép Đầu Tiên","copy","Mỗi tay tính điểm: {value}% tạo bản sao tiêu hao đầu tiên trong ô tiêu hao, giữ nguyên nâng cấp. Cần tiêu hao và ô trống."},
}
local function clone(value,seen)
    if type(value)~="table" then return value end
    seen=seen or {};if seen[value] then return seen[value] end
    local copy={};seen[value]=copy
    for k,v in pairs(value) do copy[clone(k,seen)]=clone(v,seen) end
    return copy
end
function P.randomPool()
    local Shop=require("src.shop")
    local pool,seen={},{}
    local function add(card)
        if not seen[card.id] then pool[#pool+1]=card;seen[card.id]=true end
    end
    for _,offer in ipairs(Shop.getRetailConsumables()) do
        local card=offer.consumable
        if card.category=="seal" then card.desc=require("src.deck").getModifierDescription("seal",card.sealType or card.id)
        elseif card.category=="edition" then card.desc=require("src.card_effects").getDefinition(card.edition).shopText.." Chọn một lá bài để áp dụng." end
        add(card)
    end
    for _,potion in ipairs(Shop.POTIONS) do add(Shop.healingItem("upper",potion.id).consumable) end
    for _,offer in ipairs(Shop.SOUL_SUPPORT) do add(require("src.run_manager")[offer.factory]()) end
    add(Shop.destructionItem("upper").consumable)
    return pool
end
function P.register(deities)
    for _,row in ipairs(P.entries) do
        local entry={id=row[1],name=row[2],stat="consumableChancePct",values={value=25},
            trigger="hand",rarity="common",cost=4,descriptionTemplate=row[4],
            lore="Dị linh tiếp tế cho đoàn viễn chinh qua những khe hở của thực tại."}
        entry.desc=row[4]:gsub("{value}","25");entry.baseDesc=entry.desc
        -- Only the committed hand rolls; numeric score retriggers do not repeat this lottery.
        entry.onHandScored=function(hand,context,owned)
            return {consumableReward=row[3],consumableChancePct=25,message=deities.getDescription(owned or entry)}
        end
        deities.CATALOG[entry.id]=entry
    end
end
function P.commit(game,slot,result)
    local mode=result.consumableReward
    if not mode then return end
    local items=game.consumables or {}
    if #items>=Inventory.limit(game) then result.message="Ô TIÊU HAO ĐÃ ĐẦY";return end
    if mode=="copy" and not items[1] then result.message="CHƯA CÓ TIÊU HAO ĐỂ SAO CHÉP";return end
    if Rng.random()>=result.consumableChancePct/100 then
        result.message="CHƯA KÍCH HOẠT · "..string.format("%g",result.consumableChancePct).."%";return
    end
    local source=items[1]
    if mode=="random" then
        local pool=P.randomPool();source=pool[Rng.random(#pool)]
    end
    local reward=clone(source)
    game.consumables=items;items[#items+1]=reward
    result.message=(mode=="copy" and "SAO CHÉP · " or "NHẬN · ")..reward.name
    game.spnFeedback=game.spnFeedback or {}
    game.spnFeedback[#game.spnFeedback+1]={deity=game.deities[slot],slot=slot,text=result.message}
end
return P

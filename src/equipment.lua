local Rng = require("src.rng")
local Equipment = {}

Equipment.MAX_SLOTS = 3

-- Ordinary equipment and soul relics use separate reward pools.
Equipment.ITEMS = {
    gem_fire = {
        id = "gem_fire", name = "Đá Tiên Phong", icon = "🔥",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 0.95, 0.35, 0.20, 1 },
        desc = "+18 Chips; thành +30 Chips nếu lá nằm ngoài cùng",
        onCardScore = function(card, playedCards, cardIndex)
            local chips = (cardIndex == 1 or cardIndex == #playedCards) and Equipment.ITEMS.gem_fire.params.edge or Equipment.ITEMS.gem_fire.params.chips
            return { addChips = chips, message = "+" .. chips .. " Chips (Đá Tiên Phong)" }
        end,
    },
    gem_blast = {
        id = "gem_blast", name = "Đá Tam Kích", icon = "💥",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 1.00, 0.50, 0.10, 1 },
        desc = "+4 Mult; thành +8 Mult nếu đánh đúng 3 lá",
        onCardScore = function(card, playedCards)
            local mult = #playedCards == Equipment.ITEMS.gem_blast.params.count and Equipment.ITEMS.gem_blast.params.combo or Equipment.ITEMS.gem_blast.params.mult
            return { addMult = mult, message = "+" .. mult .. " Mult (Đá Tam Kích)" }
        end,
    },
    mirror_adjacent = {
        id = "mirror_adjacent", name = "Gương Dị Chất", icon = "💠",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 0.30, 0.80, 0.90, 1 },
        desc = "Mỗi lá kề bên khác chất nhận +12 Chips",
        onHandEvaluate = function(card, playedCards, cardIndex)
            local buffs = {}
            for _, index in ipairs({ cardIndex - 1, cardIndex + 1 }) do
                local adjacent = playedCards[index]
                if adjacent and adjacent.suit ~= card.suit then
                    buffs[index] = { addChips = Equipment.ITEMS.mirror_adjacent.params.chips, message = "+12 Chips (Gương Dị Chất)" }
                end
            end
            return buffs
        end,
    },
    storm_eye = {
        id = "storm_eye", name = "Mắt Đồng Chất", icon = "⚡",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 0.20, 0.90, 0.60, 1 },
        desc = "+2 Mult mỗi lá cùng chất trong tay, tối đa +8 Mult",
        onHandEvaluate = function(card, playedCards, cardIndex)
            local count = 0
            for _, other in ipairs(playedCards) do
                if other.suit == card.suit then count = count + 1 end
            end
            local mult = math.min(Equipment.ITEMS.storm_eye.params.cap, count * Equipment.ITEMS.storm_eye.params.mult)
            return { [cardIndex] = { addMult = mult, message = "+" .. mult .. " Mult (Mắt Đồng Chất)" } }
        end,
    },
    lucky_coin = {
        id = "lucky_coin", name = "Đồng Tiền Át", icon = "💰",
        rarity = "uncommon", cost = 5, slotsNeeded = 1,
        color = { 1.00, 0.85, 0.20, 1 },
        desc = "Nhận +$2 Vàng khi lá A này tạo Aura",
        onCardScore = function(card)
            if card and card.rank == 14 then
                return { addGold = Equipment.ITEMS.lucky_coin.params.gold, message = "+$2 Vàng (Đồng Tiền Át)" }
            end
        end,
    },
    ward_stone = {
        id = "ward_stone", name = "Đá Thủ Thế", icon = "🛡️",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 0.35, 0.65, 0.95, 1 },
        desc = "+6 Giáp; thành +12 Giáp nếu chỉ đánh 1–2 lá",
        onCardScore = function(card, playedCards)
            local armor = #playedCards <= Equipment.ITEMS.ward_stone.params.count and Equipment.ITEMS.ward_stone.params.small or Equipment.ITEMS.ward_stone.params.armor
            return { addArmor = armor, message = "+" .. armor .. " Giáp (Đá Thủ Thế)" }
        end,
    },
    vitality_gem = {
        id = "vitality_gem", name = "Ngọc Cấp Cứu", icon = "💚",
        rarity = "uncommon", cost = 6, slotsNeeded = 1,
        color = { 0.25, 0.90, 0.45, 1 },
        desc = "+4 HP khi Máu hiện tại dưới 50%",
        onCardScore = function(card, playedCards, cardIndex, context)
            local hp = context and (context.playerHp or (context.gameState and context.gameState.playerHp))
            local maxHp = context and (context.maxPlayerHp or (context.gameState and context.gameState.maxPlayerHp))
            if hp and maxHp and hp < maxHp * Equipment.ITEMS.vitality_gem.params.threshold then
                return { healHp = Equipment.ITEMS.vitality_gem.params.heal, message = "+4 HP (Ngọc Cấp Cứu)" }
            end
        end,
    },
    blood_ring = {
        id = "blood_ring", name = "Nhẫn Liều Mạng", icon = "⚔️",
        rarity = "rare", cost = 6, slotsNeeded = 1,
        color = { 0.85, 0.10, 0.25, 1 },
        desc = "+10% sát thương, nhưng mất 2 HP khi kích hoạt",
        onCardScore = function()
            return { extraDamagePct = Equipment.ITEMS.blood_ring.params.damagePercent / 100, hpCost = Equipment.ITEMS.blood_ring.params.hpCost, message = "+10% Sát thương, -2 HP (Nhẫn Liều Mạng)" }
        end,
    },
    void_catalyst = {
        id = "void_catalyst", name = "Xúc Tác Hư Không", icon = "🌌",
        rarity = "legendary", cost = 8, slotsNeeded = 2,
        color = { 0.85, 0.35, 0.95, 1 },
        desc = "Tốn 2 hốc: +30 Chips và +10 Mult khi lá tạo Aura",
        onCardScore = function()
            return { addChips = Equipment.ITEMS.void_catalyst.params.chips, addMult = Equipment.ITEMS.void_catalyst.params.mult, message = "+30 Chips, +10 Mult (Xúc Tác Hư Không)" }
        end,
    },
}

local values = {
    gem_fire={chips=18,edge=30}, gem_blast={mult=4,combo=8,count=3}, mirror_adjacent={chips=12},
    storm_eye={mult=2,cap=8},lucky_coin={gold=2},ward_stone={armor=6,small=12,count=2},
    vitality_gem={heal=4,threshold=0.5},blood_ring={damagePercent=10,hpCost=2},void_catalyst={chips=30,mult=10},
}
local templates = {
    gem_fire="+{chips} Sát thương; +{edge} ở vị trí đầu/cuối của vùng tính điểm.",
    gem_blast="+{mult} Cường hóa; +{combo} khi đúng {count} lá tính điểm.",
    mirror_adjacent="Mỗi lá kề bên khác chất trong vùng tính điểm: +{chips} Sát thương.",
    storm_eye="+{mult} Cường hóa mỗi lá cùng chất trong vùng tính điểm, tối đa {cap}.",
    lucky_coin="Lá A tính điểm: +{gold} Vàng.",
    ward_stone="+{armor} Giáp; +{small} khi có tối đa {count} lá tính điểm.",
    vitality_gem="+{heal} HP nếu HP dưới {thresholdPercent}% tối đa.",
    blood_ring="+{damagePercent}% sát thương; mất {hpCost} HP khi tính điểm.",
    void_catalyst="Chiếm 2 hốc: +{chips} Sát thương và +{mult} Cường hóa.",
}
for id,p in pairs(values) do Equipment.ITEMS[id].params=p;Equipment.ITEMS[id].descriptionTemplate=templates[id] end
function Equipment.getDescription(item)
    local def=Equipment.ITEMS[item.id];if not def then return item.desc or "" end
    if not def.descriptionTemplate then return def.desc or "" end
    return def.descriptionTemplate:gsub("{([%w_]+)}",function(k)
        local n=k=="thresholdPercent" and def.params.threshold*100 or def.params[k]
        return string.format("%g",n or 0)
    end)
end
for _,item in pairs(Equipment.ITEMS) do item.desc=Equipment.getDescription(item) end

Equipment.POOL = {
    "gem_fire", "gem_blast", "mirror_adjacent", "storm_eye", "lucky_coin",
    "ward_stone", "vitality_gem", "blood_ring", "void_catalyst",
}
local discoveries={}
for _,module in ipairs({"src.chest_expansion","src.chest_depth"}) do
    for _,item in ipairs(require(module).equipment) do discoveries[#discoveries+1]=item end
end
for _, item in ipairs(discoveries) do
    Equipment.ITEMS[item.id] = item
    Equipment.POOL[#Equipment.POOL + 1] = item.id
end

-- Soul relics never enter the ordinary random equipment pool.
Equipment.SOUL_POOL = {"soul_worldblade", "soul_crown", "soul_bastion", "soul_heart", "soul_hourglass"}
local relics = {
    {id="soul_worldblade",name="Kiếm Diệt Thế",cost=32,slotsNeeded=2,color={0.95,0.42,0.18,1},
        desc="Chiếm 2 hốc: +120 Sát thương và +35% sát thương khi tính điểm.",effect={addChips=120,extraDamagePct=0.35}},
    {id="soul_crown",name="Vương Miện Hư Không",cost=28,slotsNeeded=2,color={0.72,0.42,1,1},
        desc="Chiếm 2 hốc: +30 Cường hóa khi tính điểm.",effect={addMult=30}},
    {id="soul_bastion",name="Khiên Thành Trì",cost=22,slotsNeeded=1,color={0.35,0.72,1,1},
        desc="+30 Giáp và +60 Sát thương khi tính điểm.",effect={addArmor=30,addChips=60}},
    {id="soul_heart",name="Tim Cổ Thụ",cost=24,slotsNeeded=1,color={0.35,0.92,0.58,1},
        desc="Hồi 18 HP khi tính điểm, tối đa HP tối đa.",effect={healHp=18}},
    {id="soul_hourglass",name="Đồng Hồ Tận Thế",cost=30,slotsNeeded=2,color={0.92,0.76,0.4,1},
        desc="Chiếm 2 hốc: +80 Sát thương và +20 Cường hóa khi tính điểm.",effect={addChips=80,addMult=20}},
}
for _, relic in ipairs(relics) do
    local effect, name = relic.effect, relic.name
    relic.rarity, relic.soulOnly = "mythic", true
    relic.onCardScore = function()
        local result = {message=name}
        for key,value in pairs(effect) do result[key]=value end
        return result
    end
    Equipment.ITEMS[relic.id] = relic
end

for _,relic in ipairs(require("src.soul_relics").definitions) do
    relic.rarity,relic.soulOnly="mythic",true
    Equipment.ITEMS[relic.id]=relic
    Equipment.SOUL_POOL[#Equipment.SOUL_POOL+1]=relic.id
end

function Equipment.getUsedSlots(card)
    local total = 0
    for _, equipment in ipairs((card and card.equipments) or {}) do
        total = total + (equipment.slotsNeeded or 1)
    end
    return total
end

function Equipment.getRandomEquipment()
    return Equipment.ITEMS[Equipment.POOL[Rng.random(#Equipment.POOL)]]
end

function Equipment.canAttach(card, equipItem)
    if not card or not equipItem then return false, "Dữ liệu không hợp lệ" end
    card.equipments = card.equipments or {}
    for _, existing in ipairs(card.equipments) do
        if existing.id == equipItem.id then
            return false, "Không thể gắn hai trang bị cùng loại lên một lá bài!"
        end
    end
    local available = math.min(card.maxSockets or Equipment.MAX_SLOTS, Equipment.MAX_SLOTS)
    if Equipment.getUsedSlots(card) + (equipItem.slotsNeeded or 1) > available then
        return false, "Lá bài này không còn đủ hốc khảm (tối đa " .. Equipment.MAX_SLOTS .. ")!"
    end
    return true
end

function Equipment.attach(card, equipItem)
    local allowed, reason = Equipment.canAttach(card, equipItem)
    if not allowed then return false, reason end
    table.insert(card.equipments, equipItem)
    return true, "Đã gắn " .. equipItem.name .. " vào lá " .. (card.rankName or "") .. (card.suitSymbol or "")
end

for _,item in ipairs(require("src.basic_equipment").definitions) do Equipment.ITEMS[item.id]=item end
return Equipment

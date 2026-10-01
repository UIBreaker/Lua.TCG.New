local Rng = require("src.rng")
local Deities = {}

Deities.RARITIES = {
    { id = "common", name = "Thường", code = "C", color = { 0.82, 0.84, 0.88, 1 } },
    { id = "uncommon", name = "Không Thường", code = "UC", color = { 0.28, 0.82, 0.48, 1 } },
    { id = "rare", name = "Hiếm", code = "R", color = { 0.30, 0.62, 1.00, 1 } },
    { id = "epic", name = "Sử Thi", code = "E", color = { 0.72, 0.38, 0.94, 1 } },
    { id = "legendary", name = "Huyền Thoại", code = "L", color = { 1.00, 0.62, 0.22, 1 } },
    { id = "mythic", name = "Thần Thoại", code = "M", color = { 0.94, 0.28, 0.30, 1 } },
    { id = "transcendent", name = "Siêu Việt", code = "T", color = { 0.48, 0.90, 0.96, 1 } },
    { id = "unique", name = "Độc Nhất", code = "UQ", color = { 0.82, 0.70, 1.00, 1 } },
}

local rarityIndex = {}
for index, rarity in ipairs(Deities.RARITIES) do rarityIndex[rarity.id] = index end

local function rarityState(deity)
    local baseTier = tonumber(deity and deity.baseRarityTier)
        or rarityIndex[deity and (deity.baseRarity or deity.rarity)]
        or 1
    baseTier = math.max(1, math.min(#Deities.RARITIES, baseTier))
    local evolutionLevel = math.max(0, math.floor(tonumber(deity and deity.evolutionLevel) or 0))
    local absoluteTier = baseTier + evolutionLevel
    local tier = math.min(#Deities.RARITIES, absoluteTier)
    return Deities.RARITIES[tier], math.max(0, absoluteTier - #Deities.RARITIES), baseTier, evolutionLevel
end

function Deities.getRarityBadge(deity)
    local rarity, overflow = rarityState(deity)
    return rarity.code .. (overflow > 0 and ("+" .. overflow) or ""), rarity.color
end

function Deities.getRarityLabel(deity)
    local rarity, overflow = rarityState(deity)
    return rarity.name .. (overflow > 0 and (" +" .. overflow) or ""), rarity.color
end

local function formatEffectNumber(value)
    if value % 1 == 0 then return tostring(math.floor(value)) end
    return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""))
end

local function effectMultiplier(deity)
    local _, _, baseTier, evolutionLevel = rarityState(deity)
    return 1 + (baseTier - 1 + evolutionLevel) * 0.5
end

local function scaleDescription(description, multiplier)
    return (description or ""):gsub("([+])(%d+%.?%d*)", function(sign, amount)
        return sign .. formatEffectNumber(tonumber(amount) * multiplier)
    end)
end

function Deities.setRarity(deity, rarityId)
    local tier = rarityIndex[rarityId]
    if type(deity) ~= "table" or not tier then return false end

    deity.baseDesc = deity.baseDesc or deity.desc or ""
    deity.baseRarityTier = tier
    deity.baseRarity = rarityId
    deity.rarity = rarityId
    deity.evolutionLevel = math.max(0, math.floor(tonumber(deity.evolutionLevel) or 0))
    deity.desc = scaleDescription(deity.baseDesc, effectMultiplier(deity))
    return true
end

function Deities.evolve(deity)
    if type(deity) ~= "table" or not deity.id then return false end
    local rarity, _, baseTier, evolutionLevel = rarityState(deity)
    deity.baseRarityTier = baseTier
    deity.baseRarity = deity.baseRarity or rarity.id
    deity.evolutionLevel = evolutionLevel + 1
    local nextRarity = rarityState(deity)
    deity.rarity = nextRarity.id
    deity.baseDesc = deity.baseDesc or deity.desc or ""
    deity.desc = scaleDescription(deity.baseDesc, effectMultiplier(deity))
    local badge = Deities.getRarityBadge(deity)
    return true, badge
end

function Deities.scaleEffect(deity, result)
    local multiplier = effectMultiplier(deity)
    if not result or multiplier == 1 then return result end

    for key, value in pairs(result) do
        if type(key) == "string" and key:sub(1, 3) == "add" and type(value) == "number" then
            local scaled = value * multiplier
            result[key] = scaled

            local message = result.message
            if message then
                local number = formatEffectNumber(value)
                local startAt, endAt = message:find(number, 1, true)
                if startAt then
                    local before = startAt > 1 and message:sub(startAt - 1, startAt - 1) or ""
                    local after = message:sub(endAt + 1, endAt + 1)
                    if not before:match("[%d%.]") and not after:match("[%d%.]") then
                        result.message = message:sub(1, startAt - 1) .. formatEffectNumber(scaled) .. message:sub(endAt + 1)
                    end
                end
            end
        end
    end

    if type(result.xMult) == "number" and result.xMult > 1 then
        result.xMult = 1 + (result.xMult - 1) * multiplier
    end
    return result
end

-- Đúng 9 Hộ Linh cơ bản, tất cả bậc C (Common), mỗi lá một hiệu ứng dễ đọc.
Deities.CATALOG = {
    spirit_pebble = {
        id = "spirit_pebble", name = "Cổ Thạch", rarity = "common", cost = 4,
        desc = "+20 Chips cho mỗi tay bài",
        lore = "Cổ thạch trấn giữ linh lực bền bỉ qua từng lượt.",
        onHandScored = function() return { addChips = 20, message = "+20 Chips" } end,
    },
    spirit_ember = {
        id = "spirit_ember", name = "Tàn Hỏa", rarity = "common", cost = 4,
        desc = "+4 Mult cho mỗi tay bài",
        lore = "Đốm lửa cuối cùng vẫn âm ỉ bùng lên sức mạnh.",
        onHandScored = function() return { addMult = 4, message = "+4 Mult" } end,
    },
    spirit_blade = {
        id = "spirit_blade", name = "Kiếm Ảnh", rarity = "common", cost = 4,
        desc = "Mỗi lá tạo Aura nhận +8 Chips",
        lore = "Lưỡi kiếm vô hình gia hộ từng lá bài được đánh ra.",
        onCardScored = function() return { addChips = 8, message = "+8 Chips" } end,
    },
    spirit_drum = {
        id = "spirit_drum", name = "Trống Lôi", rarity = "common", cost = 4,
        desc = "Mỗi lá tạo Aura nhận +1 Mult",
        lore = "Tiếng trống sấm vang lên theo từng lá bài.",
        onCardScored = function() return { addMult = 1, message = "+1 Mult" } end,
    },
    spirit_pair = {
        id = "spirit_pair", name = "Song Đôi", rarity = "common", cost = 4,
        desc = "+6 Mult khi đánh Đôi",
        lore = "Hai linh ảnh cộng hưởng khi một đôi xuất hiện.",
        onHandScored = function(hand)
            if hand and hand.type and hand.type.id == "pair" then
                return { addMult = 6, message = "Đôi +6 Mult" }
            end
        end,
    },
    spirit_straight = {
        id = "spirit_straight", name = "Lộ Kiếm", rarity = "common", cost = 4,
        desc = "+30 Chips khi đánh Sảnh",
        lore = "Kiếm khí mở đường thẳng qua mọi chướng ngại.",
        onHandScored = function(hand)
            if hand and hand.type and hand.type.id == "straight" then
                return { addChips = 30, message = "Sảnh +30 Chips" }
            end
        end,
    },
    spirit_flush = {
        id = "spirit_flush", name = "Đồng Chất", rarity = "common", cost = 4,
        desc = "+5 Mult khi đánh Thùng",
        lore = "Những linh ấn cùng chất hợp thành một dòng sức mạnh.",
        onHandScored = function(hand)
            if hand and hand.type and hand.type.id == "flush" then
                return { addMult = 5, message = "Thùng +5 Mult" }
            end
        end,
    },
    spirit_crown = {
        id = "spirit_crown", name = "Huyết Vương", rarity = "common", cost = 4,
        desc = "Mỗi lá J, Q hoặc K tạo Aura nhận +15 Chips",
        lore = "Vương miện cổ ban sức mạnh cho các bậc hoàng gia.",
        onCardScored = function(card)
            if card and card.rank and card.rank >= 11 and card.rank <= 13 then
                return { addChips = 15, message = "Hoàng Gia +15 Chips" }
            end
        end,
    },
    spirit_coin = {
        id = "spirit_coin", name = "Kim Tệ", rarity = "common", cost = 4,
        desc = "+$2 Vàng sau khi thắng một Blind",
        lore = "Linh kim sinh sôi sau mỗi chiến thắng.",
        onRoundWin = function() return { addGold = 2, message = "+$2 Vàng" } end,
    },
}

function Deities.getCount(deities)
    local count = 0
    for key, deity in pairs(deities or {}) do
        if type(key) == "number" and deity ~= nil then count = count + 1 end
    end
    return count
end

function Deities.resolveDeity(deities, index)
    return deities and deities[index] or nil
end

function Deities.getStarterDeity(suit)
    local starters = {
        hearts = "spirit_ember", valoria = "spirit_ember",
        diamonds = "spirit_coin", aurelia = "spirit_coin",
        clubs = "spirit_blade", elaris = "spirit_blade",
        spades = "spirit_pebble", vharos = "spirit_pebble",
    }
    return Deities.CATALOG[starters[suit] or "spirit_pebble"]
end

function Deities.getRandomShopPool(ownedDeities, count)
    local owned = {}
    for _, deity in pairs(ownedDeities or {}) do
        if type(deity) == "table" and deity.id then owned[deity.id] = true end
    end

    local candidates = {}
    for id, deity in pairs(Deities.CATALOG) do
        if not owned[id] then table.insert(candidates, deity) end
    end
    for i = #candidates, 2, -1 do
        local j = Rng.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    local result = {}
    for i = 1, math.min(count or 3, #candidates) do result[i] = candidates[i] end
    return result
end

function Deities.getBossDraftPool(ownedDeities, count)
    return Deities.getRandomShopPool(ownedDeities, count or 2)
end

Deities.BASE_SLOTS = 5
Deities.MAX_SLOTS = 5

function Deities.getMaxSlots(gameState)
    local maxSlots = Deities.BASE_SLOTS + ((gameState and gameState.extraDeitySlots) or 0)
    local list = gameState and gameState.deities or gameState
    for _, deity in pairs(type(list) == "table" and list or {}) do
        if type(deity) == "table" and deity.edition == "negative" then maxSlots = maxSlots + 1 end
    end
    return maxSlots
end

function Deities.addDeity(gameState, deity, preferredSlot)
    if not gameState or not deity then return false end
    gameState.deities = gameState.deities or {}
    local maxSlots = Deities.getMaxSlots(gameState)
    if Deities.getCount(gameState.deities) >= maxSlots then return false end

    local instance = {}
    for key, value in pairs(deity) do instance[key] = value end

    if preferredSlot and preferredSlot >= 1 and preferredSlot <= maxSlots and not gameState.deities[preferredSlot] then
        gameState.deities[preferredSlot] = instance
        return true
    end
    for i = 1, maxSlots do
        if not gameState.deities[i] then
            gameState.deities[i] = instance
            return true
        end
    end
    return false
end

return Deities

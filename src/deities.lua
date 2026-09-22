local Rng = require("src.rng")
local Deities = {}

-- Đúng 9 Hộ Linh cơ bản, tất cả bậc C (Common), mỗi lá một hiệu ứng dễ đọc.
Deities.CATALOG = {
    spirit_pebble = {
        id = "spirit_pebble", name = "The Rock", rarity = "common", cost = 4,
        desc = "+20 Chips cho mỗi tay bài",
        lore = "Nhướng một bên mày, cộng Chips bằng cơ bắp.",
        onHandScored = function() return { addChips = 20, message = "+20 Chips" } end,
    },
    spirit_ember = {
        id = "spirit_ember", name = "This Is Fine", rarity = "common", cost = 4,
        desc = "+4 Mult cho mỗi tay bài",
        lore = "Mọi thứ đang cháy, nhưng Mult vẫn tăng đều.",
        onHandScored = function() return { addMult = 4, message = "+4 Mult" } end,
    },
    spirit_blade = {
        id = "spirit_blade", name = "Bonk Cheems", rarity = "common", cost = 4,
        desc = "Mỗi lá ghi điểm nhận +8 Chips",
        lore = "Mỗi lá ghi điểm được Bonk thêm một phát.",
        onCardScored = function() return { addChips = 8, message = "+8 Chips" } end,
    },
    spirit_drum = {
        id = "spirit_drum", name = "Bongo Cat", rarity = "common", cost = 4,
        desc = "Mỗi lá ghi điểm nhận +1 Mult",
        lore = "Mỗi lá chạm bàn là thêm một nhịp Mult.",
        onCardScored = function() return { addMult = 1, message = "+1 Mult" } end,
    },
    spirit_pair = {
        id = "spirit_pair", name = "Spider-Men", rarity = "common", cost = 4,
        desc = "+6 Mult khi đánh Đôi",
        lore = "Hai lá giống nhau cùng chỉ: chính là hắn.",
        onHandScored = function(hand)
            if hand and hand.type and hand.type.id == "pair" then
                return { addMult = 6, message = "Đôi +6 Mult" }
            end
        end,
    },
    spirit_straight = {
        id = "spirit_straight", name = "Đường Tăng", rarity = "common", cost = 4,
        desc = "+30 Chips khi đánh Sảnh",
        lore = "Thỉnh kinh không vòng vo: cứ Sảnh thẳng mà đi.",
        onHandScored = function(hand)
            if hand and hand.type and hand.type.id == "straight" then
                return { addChips = 30, message = "Sảnh +30 Chips" }
            end
        end,
    },
    spirit_flush = {
        id = "spirit_flush", name = "Minion Đồng Phục", rarity = "common", cost = 4,
        desc = "+5 Mult khi đánh Thùng",
        lore = "Cả đội mặc cùng một chất, sức mạnh tăng đồng loạt.",
        onHandScored = function(hand)
            if hand and hand.type and hand.type.id == "flush" then
                return { addMult = 5, message = "Thùng +5 Mult" }
            end
        end,
    },
    spirit_crown = {
        id = "spirit_crown", name = "Gigachad", rarity = "common", cost = 4,
        desc = "Mỗi lá J, Q hoặc K ghi điểm nhận +15 Chips",
        lore = "Chỉ J, Q, K mới đủ góc hàm để nhận thêm Chips.",
        onCardScored = function(card)
            if card and card.rank and card.rank >= 11 and card.rank <= 13 then
                return { addChips = 15, message = "Hoàng Gia +15 Chips" }
            end
        end,
    },
    spirit_coin = {
        id = "spirit_coin", name = "Stonks", rarity = "common", cost = 4,
        desc = "+$2 Vàng sau khi thắng một Blind",
        lore = "Thắng Blind, biểu đồ đi lên và ví có thêm tiền.",
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

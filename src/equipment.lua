local Rng = require("src.rng")
local Equipment = {}

Equipment.MAX_SLOTS = 3

-- Đúng 9 trang bị: mỗi món phục vụ một quyết định chiến thuật riêng.
Equipment.ITEMS = {
    gem_fire = {
        id = "gem_fire", name = "Đá Tiên Phong", icon = "🔥",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 0.95, 0.35, 0.20, 1 },
        desc = "+18 Chips; thành +30 Chips nếu lá nằm ngoài cùng",
        onCardScore = function(card, playedCards, cardIndex)
            local chips = (cardIndex == 1 or cardIndex == #playedCards) and 30 or 18
            return { addChips = chips, message = "+" .. chips .. " Chips (Đá Tiên Phong)" }
        end,
    },
    gem_blast = {
        id = "gem_blast", name = "Đá Tam Kích", icon = "💥",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 1.00, 0.50, 0.10, 1 },
        desc = "+4 Mult; thành +8 Mult nếu đánh đúng 3 lá",
        onCardScore = function(card, playedCards)
            local mult = #playedCards == 3 and 8 or 4
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
                    buffs[index] = { addChips = 12, message = "+12 Chips (Gương Dị Chất)" }
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
            local mult = math.min(8, count * 2)
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
                return { addGold = 2, message = "+$2 Vàng (Đồng Tiền Át)" }
            end
        end,
    },
    ward_stone = {
        id = "ward_stone", name = "Đá Thủ Thế", icon = "🛡️",
        rarity = "common", cost = 4, slotsNeeded = 1,
        color = { 0.35, 0.65, 0.95, 1 },
        desc = "+6 Giáp; thành +12 Giáp nếu chỉ đánh 1–2 lá",
        onCardScore = function(card, playedCards)
            local armor = #playedCards <= 2 and 12 or 6
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
            if hp and maxHp and hp < maxHp * 0.5 then
                return { healHp = 4, message = "+4 HP (Ngọc Cấp Cứu)" }
            end
        end,
    },
    blood_ring = {
        id = "blood_ring", name = "Nhẫn Liều Mạng", icon = "⚔️",
        rarity = "rare", cost = 6, slotsNeeded = 1,
        color = { 0.85, 0.10, 0.25, 1 },
        desc = "+10% sát thương, nhưng mất 2 HP khi kích hoạt",
        onCardScore = function()
            return { extraDamagePct = 0.10, hpCost = 2, message = "+10% Sát thương, -2 HP (Nhẫn Liều Mạng)" }
        end,
    },
    void_catalyst = {
        id = "void_catalyst", name = "Xúc Tác Hư Không", icon = "🌌",
        rarity = "legendary", cost = 8, slotsNeeded = 2,
        color = { 0.85, 0.35, 0.95, 1 },
        desc = "Tốn 2 hốc: +30 Chips và +10 Mult khi lá tạo Aura",
        onCardScore = function()
            return { addChips = 30, addMult = 10, message = "+30 Chips, +10 Mult (Xúc Tác Hư Không)" }
        end,
    },
}

Equipment.POOL = {
    "gem_fire", "gem_blast", "mirror_adjacent", "storm_eye", "lucky_coin",
    "ward_stone", "vitality_gem", "blood_ring", "void_catalyst",
}

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

return Equipment

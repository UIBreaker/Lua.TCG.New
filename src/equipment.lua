local Rng = require("src.rng")
local Equipment = {}

Equipment.MAX_SLOTS = 3

Equipment.ITEMS = {
    gem_fire = {
        id = "gem_fire",
        name = "Đá Lửa",
        icon = "💎",
        rarity = "common",
        slotsNeeded = 1,
        color = { 0.95, 0.35, 0.2, 1 },
        desc = "+18 Chips; tăng thành +30 Chips nếu nằm ở vị trí ngoài cùng",
        onCardScore = function(card, playedCards, cardIndex)
            local isOuter = (cardIndex == 1 or cardIndex == #playedCards)
            local c = isOuter and 30 or 18
            return { addChips = c, message = "+" .. c .. " Chips (Đá Lửa" .. (isOuter and " Ngoài Cùng" or "") .. ")" }
        end
    },
    gem_blast = {
        id = "gem_blast",
        name = "Đá Bùng Nổ",
        icon = "🔥",
        rarity = "common",
        slotsNeeded = 1,
        color = { 1.0, 0.5, 0.1, 1 },
        desc = "+4 Mult; tăng thành +8 Mult nếu đánh đúng 3 lá",
        onCardScore = function(card, playedCards, cardIndex)
            local isThree = (#playedCards == 3)
            local m = isThree and 8 or 4
            return { addMult = m, message = "+" .. m .. " Mult (Đá Bùng Nổ" .. (isThree and " 3 Lá" or "") .. ")" }
        end
    },
    mirror_adjacent = {
        id = "mirror_adjacent",
        name = "Gương Lan Tỏa",
        icon = "💠",
        rarity = "common",
        slotsNeeded = 1,
        color = { 0.3, 0.8, 0.9, 1 },
        desc = "Buff +12 Chips cho 2 lá cạnh nếu khác chất",
        onHandEvaluate = function(card, playedCards, cardIndex)
            local buffs = {}
            if cardIndex > 1 and playedCards[cardIndex - 1].suit ~= card.suit then
                buffs[cardIndex - 1] = { addChips = 12, message = "+12 Chips (Lan tỏa khác chất)" }
            end
            if cardIndex < #playedCards and playedCards[cardIndex + 1].suit ~= card.suit then
                buffs[cardIndex + 1] = { addChips = 12, message = "+12 Chips (Lan tỏa khác chất)" }
            end
            return buffs
        end
    },
    storm_eye = {
        id = "storm_eye",
        name = "Mắt Bão",
        icon = "⚡",
        rarity = "common",
        slotsNeeded = 1,
        color = { 0.2, 0.9, 0.6, 1 },
        desc = "+2 Mult mỗi lá cùng chất, tối đa +8 Mult",
        onHandEvaluate = function(card, playedCards, cardIndex)
            local sameSuitCount = 0
            for _, other in ipairs(playedCards) do
                if other.suit == card.suit then
                    sameSuitCount = sameSuitCount + 1
                end
            end
            local multGain = math.min(8, sameSuitCount * 2)
            local buffs = {}
            if multGain > 0 then
                buffs[cardIndex] = { addMult = multGain, message = "+" .. multGain .. " Mult (Mắt Bão)" }
            end
            return buffs
        end
    },
    lucky_coin = {
        id = "lucky_coin",
        name = "Đồng Tiền May Mắn",
        icon = "💰",
        rarity = "common",
        slotsNeeded = 1,
        color = { 1.0, 0.85, 0.2, 1 },
        desc = "Thưởng ngay +$2 Vàng (1 lần mỗi trận)",
        onCardScore = function(card, playedCards, cardIndex, context)
            if context and not context.luckyCoinTriggered then
                context.luckyCoinTriggered = true
                return { addGold = 2, message = "+$2 Vàng (May Mắn)" }
            end
            return nil
        end
    },
    free_feather = {
        id = "free_feather",
        name = "Lông Vũ Tự Do",
        icon = "✨",
        rarity = "common",
        slotsNeeded = 1,
        color = { 0.8, 0.7, 1.0, 1 },
        desc = "Đổi bài miễn phí 1 lần mỗi trận",
        onDiscard = function(card, context)
            if context and not context.freeFeatherUsed then
                context.freeFeatherUsed = true
                return { freeDiscard = true }
            end
            return nil
        end
    },
    blood_ring = {
        id = "blood_ring",
        name = "Nhẫn Huyết Thần",
        icon = "⚔️",
        rarity = "uncommon",
        slotsNeeded = 1,
        color = { 0.85, 0.1, 0.25, 1 },
        desc = "+10% sát thương chuẩn, mất 2 HP khi kích hoạt",
        onCardScore = function(card, playedCards, cardIndex)
            return { extraDamagePct = 0.10, hpCost = 2, message = "+10% Sát thương Huyết Thần (-2 HP)!" }
        end
    },
    holy_relic = {
        id = "holy_relic",
        name = "Ngọc Bội Thánh Tích",
        icon = "👑",
        rarity = "legendary",
        slotsNeeded = 2,
        color = { 0.95, 0.8, 0.2, 1 },
        desc = "[Huyền Thoại - Tốn 2 Hốc Khảm Bài] x1.2 XMult một lần mỗi tay, không cộng dồn bản sao",
        onCardScore = function(card, playedCards, cardIndex, context)
            if context and not context.holyRelicTriggeredThisHand then
                context.holyRelicTriggeredThisHand = true
                return { xMultBonus = 0.2, message = "+0.2 XMult (Thánh Tích)" }
            end
            return nil
        end
    },
    ward_stone = {
        id = "ward_stone",
        name = "Đá Hộ Mệnh",
        icon = "🛡️",
        rarity = "common",
        slotsNeeded = 1,
        color = { 0.35, 0.65, 0.95, 1 },
        desc = "+6 Giáp; tăng thành +12 Giáp nếu chỉ đánh 1-2 lá",
        onCardScore = function(card, playedCards, cardIndex)
            local isSmall = (#playedCards <= 2)
            local arm = isSmall and 12 or 6
            return { addArmor = arm, message = "+" .. arm .. " Giáp (Đá Hộ Mệnh" .. (isSmall and " Đơn/Đôi" or "") .. ")" }
        end
    },
    shield_gem = {
        id = "shield_gem",
        name = "Ngọc Hộ Thân",
        icon = "🛡️",
        rarity = "uncommon",
        slotsNeeded = 1,
        color = { 0.45, 0.75, 1.0, 1 },
        desc = "+15 Giáp nhưng lá bài bị Kiệt Sức một lượt",
        onCardScore = function(card, playedCards, cardIndex)
            card.exhausted = true
            return { addArmor = 15, message = "+15 Giáp (Ngọc Hộ Thân - Kiệt Sức)!" }
        end
    },
    vitality_gem = {
        id = "vitality_gem",
        name = "Ngọc Hồi Máu",
        icon = "💚",
        rarity = "uncommon",
        slotsNeeded = 1,
        color = { 0.25, 0.90, 0.45, 1 },
        desc = "+5 HP một lần mỗi trận, chỉ kích hoạt khi dưới 50% HP",
        onCardScore = function(card, playedCards, cardIndex, context)
            local curHp = context and (context.playerHp or (context.gameState and context.gameState.playerHp)) or 100
            local maxHp = context and (context.maxPlayerHp or (context.gameState and context.gameState.maxPlayerHp)) or 100
            if curHp < (maxHp * 0.5) and context and not context.vitalityGemUsed then
                context.vitalityGemUsed = true
                return { healHp = 5, message = "+5 HP (Ngọc Hồi Máu Nguy Cấp)!" }
            end
            return nil
        end
    },
}

Equipment.ITEMS.stone_armor = Equipment.ITEMS.ward_stone
Equipment.ITEMS.gem_armor = Equipment.ITEMS.ward_stone

Equipment.ITEMS.void_catalyst = {
    id = "void_catalyst",
    name = "Xúc Tác Hư Không",
    icon = "🌌",
    rarity = "legendary",
    slotsNeeded = 2,
    color = { 0.85, 0.35, 0.95, 1 },
    desc = "[Huyền Thoại - Tốn 2 Hốc Khảm Bài] +30 Chips và +10 Mult khi tính điểm",
    onCardScore = function(card, playedCards, cardIndex, context)
        return { addChips = 30, addMult = 10, message = "+30 Chips, +10 Mult (Xúc Tác Hư Không)!" }
    end
}

Equipment.ITEMS.iron_spikes = {
    id = "iron_spikes",
    name = "Gai Sắt",
    icon = "🪓",
    rarity = "common",
    slotsNeeded = 1,
    color = { 0.65, 0.65, 0.70, 1 },
    desc = "+15 Chips khi lá bài ghi điểm",
    onCardScore = function(card, playedCards, cardIndex, context)
        return { addChips = 15, message = "+15 Chips (Gai Sắt)!" }
    end
}

Equipment.ITEMS.vanguard_spear = {
    id = "vanguard_spear",
    name = "Mũi Giáo Tiên Phong",
    icon = "🔱",
    rarity = "uncommon",
    slotsNeeded = 1,
    color = { 0.90, 0.45, 0.20, 1 },
    desc = "Lá ngoài cùng nhận +25 Chips; ở giữa bị −5 Chips",
    onCardScore = function(card, playedCards, cardIndex, context)
        local isOuter = (cardIndex == 1 or cardIndex == #playedCards)
        local c = isOuter and 25 or -5
        return { addChips = c, message = (isOuter and "+25" or "-5") .. " Chips (Mũi Giáo Tiên Phong)" }
    end,
}

Equipment.ITEMS.shield_lock = {
    id = "shield_lock",
    name = "Khóa Khiên",
    icon = "🔒",
    rarity = "uncommon",
    slotsNeeded = 1,
    color = { 0.35, 0.65, 0.85, 1 },
    desc = "+12 Giáp, sau đó lá bị Kiệt Sức một lượt",
    onCardScore = function(card, playedCards, cardIndex, context)
        card.exhausted = true
        return { addArmor = 12, message = "+12 Giáp, Bị Kiệt Sức 1 Lượt (Khóa Khiên)" }
    end,
}

Equipment.ITEMS.tactical_compass = {
    id = "tactical_compass",
    name = "La Bàn Chiến Trận",
    icon = "🧭",
    rarity = "legendary",
    slotsNeeded = 2,
    color = { 0.85, 0.40, 0.95, 1 },
    desc = "[Huyền Thoại - Tốn 2 Hốc Khảm Bài] x1.25 XMult, hoán đổi vị trí với lá bài liền kề",
    onCardScore = function(card, playedCards, cardIndex, context)
        if cardIndex > 1 and playedCards[cardIndex - 1] then
            playedCards[cardIndex], playedCards[cardIndex - 1] = playedCards[cardIndex - 1], playedCards[cardIndex]
        elseif cardIndex < #playedCards and playedCards[cardIndex + 1] then
            playedCards[cardIndex], playedCards[cardIndex + 1] = playedCards[cardIndex + 1], playedCards[cardIndex]
        end
        return { xMultBonus = 0.25, message = "x1.25 XMult & Hoán Đổi Vị Trí (La Bàn Chiến Trận)" }
    end,
}

Equipment.POOL = {
    "gem_fire",
    "gem_blast",
    "mirror_adjacent",
    "storm_eye",
    "lucky_coin",
    "free_feather",
    "blood_ring",
    "holy_relic",
    "ward_stone",
    "shield_gem",
    "vitality_gem",
    "void_catalyst",
    "iron_spikes",
    "vanguard_spear",
    "shield_lock",
    "tactical_compass",
}

function Equipment.getUsedSlots(card)
    if not card or not card.equipments then return 0 end
    local total = 0
    for _, eq in ipairs(card.equipments) do
        total = total + (eq.slotsNeeded or 1)
    end
    return total
end

function Equipment.getRandomEquipment()
    local idx = Rng.random(#Equipment.POOL)
    local key = Equipment.POOL[idx]
    return Equipment.ITEMS[key]
end

function Equipment.canAttach(card, equipItem)
    if not card or not equipItem then return false, "Dữ liệu không hợp lệ" end
    card.equipments = card.equipments or {}
    for _, existing in ipairs(card.equipments) do
        if existing.id == equipItem.id then
            return false, "Không thể gắn hai trang bị cùng loại lên một lá bài!"
        end
    end
    local needed = equipItem.slotsNeeded or 1
    local available = math.min(card.maxSockets or Equipment.MAX_SLOTS, Equipment.MAX_SLOTS)
    if Equipment.getUsedSlots(card) + needed > available then
        return false, "Lá bài này không còn đủ hốc khảm (tối đa " .. Equipment.MAX_SLOTS .. ")!"
    end
    return true
end

function Equipment.attach(card, equipItem)
    local canAttach, reason = Equipment.canAttach(card, equipItem)
    if not canAttach then return false, reason end
    table.insert(card.equipments, equipItem)
    return true, "Đã gắn " .. equipItem.name .. " vào lá " .. (card.rankName or "") .. (card.suitSymbol or "")
end

return Equipment

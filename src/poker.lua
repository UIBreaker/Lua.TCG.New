local Poker = {}

Poker.HAND_TYPES = {
    STRAIGHT_FLUSH = { id = "straight_flush", name = "Straight Flush", vnName = "VẠN KIẾM QUY TÔNG", subtitle = "Thùng phá sảnh", baseChips = 100, baseMult = 8, order = 9, requiredCards = 5 },
    FOUR_OF_A_KIND = { id = "four_of_a_kind", name = "Four of a Kind", vnName = "TỨ TƯỢNG", subtitle = "Tứ quý", baseChips = 60, baseMult = 7, order = 8, requiredCards = 4 },
    FULL_HOUSE     = { id = "full_house",     name = "Full House",     vnName = "HỖN NGUYÊN", subtitle = "Cù lũ", baseChips = 40, baseMult = 4, order = 7, requiredCards = 5 },
    FLUSH          = { id = "flush",          name = "Flush",          vnName = "ĐỒNG KHÍ", subtitle = "Thùng", baseChips = 35, baseMult = 4, order = 6, requiredCards = 5 },
    STRAIGHT       = { id = "straight",       name = "Straight",       vnName = "TRƯỜNG LONG", subtitle = "Sảnh (hoặc Sảnh 3 lá)", baseChips = 30, baseMult = 4, order = 5, requiredCards = 3 },
    THREE_OF_A_KIND= { id = "three_of_a_kind",name = "Three of a Kind",vnName = "TAM HOA", subtitle = "Sám cô", baseChips = 30, baseMult = 3, order = 4, requiredCards = 3 },
    TWO_PAIR       = { id = "two_pair",       name = "Two Pair",       vnName = "SONG ĐÔI", subtitle = "Hai đôi", baseChips = 20, baseMult = 2, order = 3, requiredCards = 4 },
    PAIR           = { id = "pair",           name = "Pair",           vnName = "SONG ĐAO", subtitle = "Đôi", baseChips = 10, baseMult = 2, order = 2, requiredCards = 2 },
    HIGH_CARD      = { id = "high_card",      name = "High Card",      vnName = "ĐƠN THỦ", subtitle = "Mậu thầu (1 lá)", baseChips = 5, baseMult = 1, order = 1, requiredCards = 1 },
}

Poker.HAND_TYPES_ORDERED = {
    Poker.HAND_TYPES.STRAIGHT_FLUSH,
    Poker.HAND_TYPES.FOUR_OF_A_KIND,
    Poker.HAND_TYPES.FULL_HOUSE,
    Poker.HAND_TYPES.FLUSH,
    Poker.HAND_TYPES.STRAIGHT,
    Poker.HAND_TYPES.THREE_OF_A_KIND,
    Poker.HAND_TYPES.TWO_PAIR,
    Poker.HAND_TYPES.PAIR,
    Poker.HAND_TYPES.HIGH_CARD,
}

Poker.SKILL_BOOKS = {
    pair = {
        id = "book_pair",
        handId = "pair",
        name = "Bí Tịch: Song Đao",
        handName = "SONG ĐAO (Đôi)",
        cost = 5,
        desc = "Mở khóa vĩnh viễn tay bài SONG ĐAO (Đôi). Đánh ra 2 lá cùng số (10 Chips × 2 Mult).",
        color = { 0.3, 0.7, 0.9, 1 },
    },
    two_pair = {
        id = "book_two_pair",
        handId = "two_pair",
        name = "Bí Tịch: Song Đôi",
        handName = "SONG ĐÔI (Hai Đôi)",
        cost = 6,
        desc = "Mở khóa vĩnh viễn tay bài SONG ĐÔI (Hai Đôi). Đánh ra 2 cặp lá cùng số (20 Chips × 2 Mult).",
        color = { 0.35, 0.75, 0.85, 1 },
    },
    three_of_a_kind = {
        id = "book_three_of_a_kind",
        handId = "three_of_a_kind",
        name = "Bí Tịch: Tam Hoa",
        handName = "TAM HOA (Sám Cô)",
        cost = 7,
        desc = "Mở khóa vĩnh viễn tay bài TAM HOA (Sám Cô). Đánh ra 3 lá cùng số (30 Chips × 3 Mult).",
        color = { 0.5, 0.85, 0.4, 1 },
    },
    straight = {
        id = "book_straight",
        handId = "straight",
        name = "Bí Tịch: Trường Long",
        handName = "TRƯỜNG LONG (Sảnh)",
        cost = 8,
        desc = "Mở khóa vĩnh viễn tay bài TRƯỜNG LONG (Sảnh). 5 lá số liên tiếp nhau (30 Chips × 4 Mult).",
        color = { 0.95, 0.7, 0.2, 1 },
    },
    flush = {
        id = "book_flush",
        handId = "flush",
        name = "Bí Tịch: Đồng Khí",
        handName = "ĐỒNG KHÍ (Thùng)",
        cost = 9,
        desc = "Mở khóa vĩnh viễn tay bài ĐỒNG KHÍ (Thùng). 5 lá cùng chất màu (35 Chips × 4 Mult).",
        color = { 0.95, 0.4, 0.5, 1 },
    },
    full_house = {
        id = "book_full_house",
        handId = "full_house",
        name = "Bí Tịch: Hỗn Nguyên",
        handName = "HỖN NGUYÊN (Cù Lũ)",
        cost = 10,
        desc = "Mở khóa vĩnh viễn tay bài HỖN NGUYÊN (Cù Lũ). Gồm 1 bộ ba và 1 bộ đôi (40 Chips × 4 Mult).",
        color = { 0.8, 0.4, 0.9, 1 },
    },
    four_of_a_kind = {
        id = "book_four_of_a_kind",
        handId = "four_of_a_kind",
        name = "Bí Tịch: Tứ Tượng",
        handName = "TỨ TƯỢNG (Tứ Quý)",
        cost = 12,
        desc = "Mở khóa vĩnh viễn tay bài TỨ TƯỢNG (Tứ Quý). 4 lá cùng số uy lực hủy diệt (60 Chips × 7 Mult).",
        color = { 0.95, 0.25, 0.25, 1 },
    },
    straight_flush = {
        id = "book_straight_flush",
        handId = "straight_flush",
        name = "Bí Tịch: Vạn Kiếm",
        handName = "VẠN KIẾM QUY TÔNG (Thùng Phá Sảnh)",
        cost = 15,
        desc = "Mở khóa tuyệt kỹ tối thượng VẠN KIẾM QUY TÔNG. 5 lá vừa sảnh vừa thùng (100 Chips × 8 Mult).",
        color = { 0.98, 0.85, 0.15, 1 },
    },
}

Poker.HAND_LEVEL_SCALING = {
    high_card       = { chips = 10, mult = 1, planetName = "Sao Diêm Vương (Pluto)", planetId = "planet_pluto" },
    pair            = { chips = 15, mult = 1, planetName = "Sao Thủy (Mercury)",     planetId = "planet_mercury" },
    two_pair        = { chips = 20, mult = 1, planetName = "Sao Thiên Vương (Uranus)",planetId = "planet_uranus" },
    three_of_a_kind = { chips = 20, mult = 2, planetName = "Sao Kim (Venus)",       planetId = "planet_venus" },
    straight        = { chips = 30, mult = 3, planetName = "Sao Thổ (Saturn)",      planetId = "planet_saturn" },
    flush           = { chips = 15, mult = 2, planetName = "Sao Mộc (Jupiter)",     planetId = "planet_jupiter" },
    full_house      = { chips = 25, mult = 2, planetName = "Địa Cầu (Earth)",        planetId = "planet_earth" },
    four_of_a_kind  = { chips = 30, mult = 3, planetName = "Sao Hỏa (Mars)",        planetId = "planet_mars" },
    straight_flush  = { chips = 40, mult = 4, planetName = "Sao Hải Vương (Neptune)",planetId = "planet_neptune" },
}

Poker.PLANET_CARDS = {
    { id = "planet_pluto", handId = "high_card", name = "Sao Diêm Vương (Pluto)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho ĐƠN THỦ (+10 Chips, +1 Mult)", icon = "🪐", color = { 0.45, 0.55, 0.70, 1 } },
    { id = "planet_mercury", handId = "pair", name = "Sao Thủy (Mercury)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho SONG ĐAO (+15 Chips, +1 Mult)", icon = "🪐", color = { 0.35, 0.75, 0.95, 1 } },
    { id = "planet_uranus", handId = "two_pair", name = "Sao Thiên Vương (Uranus)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho SONG ĐÔI (+20 Chips, +1 Mult)", icon = "🪐", color = { 0.30, 0.85, 0.85, 1 } },
    { id = "planet_venus", handId = "three_of_a_kind", name = "Sao Kim (Venus)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho TAM HOA (+20 Chips, +2 Mult)", icon = "🪐", color = { 0.95, 0.75, 0.25, 1 } },
    { id = "planet_saturn", handId = "straight", name = "Sao Thổ (Saturn)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho TRƯỜNG LONG (+30 Chips, +3 Mult)", icon = "🪐", color = { 0.90, 0.60, 0.25, 1 } },
    { id = "planet_jupiter", handId = "flush", name = "Sao Mộc (Jupiter)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho ĐỒNG KHÍ (+15 Chips, +2 Mult)", icon = "🪐", color = { 0.85, 0.35, 0.45, 1 } },
    { id = "planet_earth", handId = "full_house", name = "Địa Cầu (Earth)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho HỖN NGUYÊN (+25 Chips, +2 Mult)", icon = "🌍", color = { 0.25, 0.75, 0.45, 1 } },
    { id = "planet_mars", handId = "four_of_a_kind", name = "Sao Hỏa (Mars)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho TỨ TƯỢNG (+30 Chips, +3 Mult)", icon = "🪐", color = { 0.95, 0.30, 0.25, 1 } },
    { id = "planet_neptune", handId = "straight_flush", name = "Sao Hải Vương (Neptune)", subtitle = "HÀNH TINH", desc = "+1 Cấp cho VẠN KIẾM QUY TÔNG (+40 Chips, +4 Mult)", icon = "🪐", color = { 0.25, 0.45, 0.95, 1 } },
    { id = "planet_supernova", handId = "random", name = "Siêu Tân Tinh (Supernova)", subtitle = "KỲ QUAN", desc = "Nâng ngẫu nhiên 1 thế bài lên +3 Cấp độ!", icon = "🌟", color = { 0.98, 0.88, 0.25, 1 } },
    { id = "planet_black_hole", handId = "all", name = "Hố Đen (Black Hole)", subtitle = "HỐ ĐEN", desc = "Nâng cấp TẤT CẢ 9 thế bài Poker lên +1 Cấp độ!", icon = "🕳️", color = { 0.45, 0.25, 0.65, 1 } },
}

function Poker.getHandStats(handId, level)
    if type(handId) == "table" and handId.id then handId = handId.id end
    local hType = nil
    for _, ht in pairs(Poker.HAND_TYPES) do
        if ht.id == handId then
            hType = ht
            break
        end
    end
    if not hType then return { chips = 5, mult = 1, level = 1, baseChips = 5, baseMult = 1, scaleChips = 10, scaleMult = 1 } end
    local lvl = math.max(1, level or 1)
    local scale = Poker.HAND_LEVEL_SCALING[handId] or { chips = 10, mult = 1 }
    local c = hType.baseChips + (lvl - 1) * scale.chips
    local m = hType.baseMult + (lvl - 1) * scale.mult
    return {
        chips = c,
        mult = m,
        level = lvl,
        scaleChips = scale.chips,
        scaleMult = scale.mult,
        baseChips = hType.baseChips,
        baseMult = hType.baseMult,
    }
end

-- Helper to check if hand contains Queen of Clubs (Tổ Mẫu Đồng Hóa)
local function hasQueenOfClubs(cards)
    for _, c in ipairs(cards or {}) do
        if not c.disableFactionPassives and c.rank == 12 and (c.suit == "elaris" or c.suit == "clubs") then
            return true
        end
    end
    return false
end

-- Check if sorted ranks form a straight (3 cards for 3-card hands, 4 cards if Queen of Clubs present, 5 cards normally)
local function checkStraight(sortedCards)
    local len = #sortedCards
    if len < 3 then return false end
    local minRequired = (len == 3) and 3 or (hasQueenOfClubs(sortedCards) and 4 or 5)
    if len < minRequired then return false end

    -- Extract unique ranks descending
    local uniqueRanks = {}
    for _, c in ipairs(sortedCards) do
        if #uniqueRanks == 0 or uniqueRanks[#uniqueRanks] ~= c.rank then
            table.insert(uniqueRanks, c.rank)
        end
    end
    if #uniqueRanks < minRequired then return false end

    -- Check regular consecutive sequences of length minRequired
    for startIdx = 1, #uniqueRanks - minRequired + 1 do
        local ok = true
        for j = startIdx, startIdx + minRequired - 2 do
            if uniqueRanks[j] - uniqueRanks[j + 1] ~= 1 then
                ok = false
                break
            end
        end
        if ok then return true end
    end

    -- Check Ace-low straight
    local hasAce = (uniqueRanks[1] == 14)
    if hasAce then
        if minRequired == 3 then
            local r3, r2 = false, false
            for _, r in ipairs(uniqueRanks) do
                if r == 3 then r3 = true
                elseif r == 2 then r2 = true end
            end
            if r3 and r2 then return true end
        elseif minRequired == 4 then
            local r4, r3, r2 = false, false, false
            for _, r in ipairs(uniqueRanks) do
                if r == 4 then r4 = true
                elseif r == 3 then r3 = true
                elseif r == 2 then r2 = true end
            end
            if r4 and r3 and r2 then return true end
        elseif minRequired == 5 then
            local r5, r4, r3, r2 = false, false, false, false
            for _, r in ipairs(uniqueRanks) do
                if r == 5 then r5 = true
                elseif r == 4 then r4 = true
                elseif r == 3 then r3 = true
                elseif r == 2 then r2 = true end
            end
            if r5 and r4 and r3 and r2 then return true end
        end
    end

    return false
end

-- Check if cards have the same suit (5 cards normally, 4 cards if Queen of Clubs present, A Clubs is wild)
local function checkFlush(cards)
    local minRequired = hasQueenOfClubs(cards) and 4 or 5
    if #cards < minRequired then return false end

    local suitCounts = {}
    local wildCount = 0
    for _, c in ipairs(cards) do
        local isWild = require("src.card_effects").getEffectName(c)=="astral"
            or not c.disableFactionPassives and (c.isWildSuit or ((c.rank == 1 or c.rank == 14) and (c.suit == "elaris" or c.suit == "clubs")))
        if isWild then
            wildCount = wildCount + 1
        else
            suitCounts[c.suit] = (suitCounts[c.suit] or 0) + 1
        end
    end

    if wildCount >= minRequired then return true end
    for suit, count in pairs(suitCounts) do
        if count + wildCount >= minRequired then
            return true
        end
    end
    return false
end

local function getUnscoredCards(allCards, scoringCards)
    local unscored = {}
    for _, c in ipairs(allCards) do
        local isScored = false
        for _, sc in ipairs(scoringCards) do
            if sc == c then
                isScored = true
                break
            end
        end
        if not isScored then
            table.insert(unscored, c)
        end
    end
    return unscored
end

-- Find all valid poker hands that the given cards can make, ordered by rank
local function getPossibleHands(sorted)
    local hands = {}

    local countByRank = {}
    local rankGroups = {}
    for _, c in ipairs(sorted) do
        countByRank[c.rank] = (countByRank[c.rank] or 0) + 1
        rankGroups[c.rank] = rankGroups[c.rank] or {}
        table.insert(rankGroups[c.rank], c)
    end

    local fourRank, threeRank
    local pairRanks = {}
    for rank, count in pairs(countByRank) do
        if count == 4 then
            fourRank = rank
        elseif count == 3 then
            threeRank = rank
        elseif count == 2 then
            table.insert(pairRanks, rank)
        end
    end
    table.sort(pairRanks, function(a, b) return a > b end)

    local isFlush = checkFlush(sorted)
    local isStraight = checkStraight(sorted)

    -- 1. Straight Flush (Order 9)
    if isFlush and isStraight then
        table.insert(hands, {
            type = Poker.HAND_TYPES.STRAIGHT_FLUSH,
            scoringCards = sorted,
            unscoredCards = {},
        })
    end

    -- 2. Four of a Kind (Order 8)
    if fourRank then
        local scoring = rankGroups[fourRank]
        table.insert(hands, {
            type = Poker.HAND_TYPES.FOUR_OF_A_KIND,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 3. Full House (Order 7)
    if threeRank and #pairRanks >= 1 then
        local scoring = {}
        for _, c in ipairs(rankGroups[threeRank]) do table.insert(scoring, c) end
        for _, c in ipairs(rankGroups[pairRanks[1]]) do table.insert(scoring, c) end
        table.insert(hands, {
            type = Poker.HAND_TYPES.FULL_HOUSE,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 4. Flush (Order 6)
    if isFlush then
        table.insert(hands, {
            type = Poker.HAND_TYPES.FLUSH,
            scoringCards = sorted,
            unscoredCards = {},
        })
    end

    -- 5. Straight (Order 5)
    if isStraight then
        table.insert(hands, {
            type = Poker.HAND_TYPES.STRAIGHT,
            scoringCards = sorted,
            unscoredCards = {},
        })
    end

    -- 6. Three of a Kind (Order 4)
    if threeRank or fourRank then
        local tRank = threeRank or fourRank
        local scoring = { rankGroups[tRank][1], rankGroups[tRank][2], rankGroups[tRank][3] }
        table.insert(hands, {
            type = Poker.HAND_TYPES.THREE_OF_A_KIND,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 7. Two Pair (Order 3)
    if #pairRanks >= 2 or fourRank or (threeRank and #pairRanks >= 1) then
        local scoring = {}
        if fourRank then
            scoring = { rankGroups[fourRank][1], rankGroups[fourRank][2], rankGroups[fourRank][3], rankGroups[fourRank][4] }
        elseif #pairRanks >= 2 then
            for _, c in ipairs(rankGroups[pairRanks[1]]) do table.insert(scoring, c) end
            for _, c in ipairs(rankGroups[pairRanks[2]]) do table.insert(scoring, c) end
        elseif threeRank and #pairRanks >= 1 then
            table.insert(scoring, rankGroups[threeRank][1])
            table.insert(scoring, rankGroups[threeRank][2])
            table.insert(scoring, rankGroups[pairRanks[1]][1])
            table.insert(scoring, rankGroups[pairRanks[1]][2])
        end
        if #scoring == 4 then
            table.insert(hands, {
                type = Poker.HAND_TYPES.TWO_PAIR,
                scoringCards = scoring,
                unscoredCards = getUnscoredCards(sorted, scoring),
            })
        end
    end

    -- 8. Pair (Order 2)
    if #pairRanks >= 1 or threeRank or fourRank then
        local pRank = pairRanks[1] or threeRank or fourRank
        local scoring = { rankGroups[pRank][1], rankGroups[pRank][2] }
        table.insert(hands, {
            type = Poker.HAND_TYPES.PAIR,
            scoringCards = scoring,
            unscoredCards = getUnscoredCards(sorted, scoring),
        })
    end

    -- 9. High Card (Order 1)
    local highScoring = { sorted[1] }
    table.insert(hands, {
        type = Poker.HAND_TYPES.HIGH_CARD,
        scoringCards = highScoring,
        unscoredCards = getUnscoredCards(sorted, highScoring),
    })

    return hands
end

function Poker.evaluate(cards, unlockedHands, handLevels)
    if not cards or #cards == 0 then return nil end

    -- Shallow copy sorted descending by rank
    local sorted = {}
    for _, c in ipairs(cards) do table.insert(sorted, c) end
    table.sort(sorted, function(a, b)
        if a.rank == b.rank then return a.suit < b.suit end
        return a.rank > b.rank
    end)

    local possibleHands = getPossibleHands(sorted)
    if #possibleHands == 0 then return nil end

    local naturalHand = possibleHands[1]

    local function finalizeHand(hand)
        if not hand then return nil end
        -- Poker membership is unchanged. Resolution order is always visual play order.
        local members = {}; for _, c in ipairs(hand.scoringCards) do members[c] = true end
        hand.scoringCards, hand.unscoredCards = {}, {}
        for _, c in ipairs(cards) do
            local list = members[c] and hand.scoringCards or hand.unscoredCards
            list[#list + 1] = c
        end
        local handId = hand.type.id
        local lvl = (handLevels and handLevels[handId]) or 1
        local stats = Poker.getHandStats(handId, lvl)
        hand.level = lvl
        hand.chips = stats.chips
        hand.mult = stats.mult
        return hand
    end

    -- If unlockedHands not specified, allow all (standard poker evaluation)
    if not unlockedHands then
        return finalizeHand(naturalHand)
    end

    -- Return the highest-ranking valid hand that has been unlocked
    for _, hand in ipairs(possibleHands) do
        if unlockedHands[hand.type.id] then
            if hand.type.order < naturalHand.type.order then
                hand.lockedHandAttempted = naturalHand.type.vnName
            end
            return finalizeHand(hand)
        end
    end

    -- Default fallback: High Card (always unlocked)
    local fallback = possibleHands[#possibleHands]
    if naturalHand.type.order > fallback.type.order then
        fallback.lockedHandAttempted = naturalHand.type.vnName
    end
    return finalizeHand(fallback)
end

return Poker

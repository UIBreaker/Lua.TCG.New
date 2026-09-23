local Rng = require("src.rng")
local Deck = {}

-- 6 Combat Battle Seals (Ấn Chiến)
Deck.SEALS = {
    seal_blood = {
        id = "seal_blood",
        name = "Ấn Huyết",
        icon = "🩸",
        color = { 0.90, 0.15, 0.15, 1 },
        desc = "+15 Mult, Tái kích hoạt toàn bộ chỉ số cơ bản của lá bài 1 lần duy nhất trong trận (tiêu hao 3 HP)",
    },
    seal_prophecy = {
        id = "seal_prophecy",
        name = "Ấn Tiên Tri",
        icon = "🔮",
        color = { 0.30, 0.60, 0.95, 1 },
        desc = "Khi ghi điểm, nhìn thấu 2 ý định (Intent) kế tiếp của Quái vật / Boss",
    },
    seal_ashen = {
        id = "seal_ashen",
        name = "Ấn Tro Tàn",
        icon = "🔥",
        color = { 0.60, 0.55, 0.50, 1 },
        desc = "Tự thiêu hủy vĩnh viễn khỏi bộ bài khi đánh, gây 40 Sát thương Chuẩn và nhận +$2 Vàng",
    },
    seal_bounty = {
        id = "seal_bounty",
        name = "Ấn Truy Nã",
        icon = "💰",
        color = { 0.95, 0.80, 0.25, 1 },
        desc = "Nếu lá này kết liễu Quái vật, thưởng ngay +$4 Vàng tiền truy nã",
    },
    seal_anchor = {
        id = "seal_anchor",
        name = "Ấn Neo",
        icon = "⚓",
        color = { 0.20, 0.70, 0.60, 1 },
        desc = "Ưu tiên chia vào tay khởi đầu, không thể bị bỏ bài; nhận +8 Giáp khi giữ trên tay cuối lượt",
    },
    seal_purifying = {
        id = "seal_purifying",
        name = "Ấn Thanh Tẩy",
        icon = "✨",
        color = { 0.85, 0.85, 0.95, 1 },
        desc = "Tẩy sạch 1 hiệu ứng suy yếu (boss debuff) khi kết thúc lượt quái nếu lá bài được giữ trên tay",
    },
}
-- Backward compatibility aliases
Deck.SEALS.gold = Deck.SEALS.seal_bounty
Deck.SEALS.red = Deck.SEALS.seal_blood
Deck.SEALS.blue = Deck.SEALS.seal_prophecy
Deck.SEALS.purple = Deck.SEALS.seal_ashen

-- 10 Card Enhancements (Thuật Rèn Bài)
Deck.ENHANCEMENTS = {
    enh_armor = {
        id = "enh_armor",
        name = "Giáp Hóa",
        icon = "🛡️",
        color = { 0.40, 0.70, 0.90, 1 },
        desc = "+8 Giáp khi ghi điểm, nhưng lá này bị -10 Chips vĩnh viễn",
    },
    enh_blood = {
        id = "enh_blood",
        name = "Huyết Hóa",
        icon = "🩸",
        color = { 0.85, 0.15, 0.20, 1 },
        desc = "Tiêu hao 4 HP người chơi, đổi lại +15 Mult cho tay bài này",
    },
    enh_overcharged = {
        id = "enh_overcharged",
        name = "Tích Điện",
        icon = "⚡",
        color = { 0.20, 0.90, 0.80, 1 },
        desc = "Mỗi lượt nằm trên tay không đánh: tích +5 Chips (tối đa +25). Khi đánh: xả toàn bộ",
    },
    enh_cursed = {
        id = "enh_cursed",
        name = "Nguyền Rủa",
        icon = "💀",
        color = { 0.65, 0.20, 0.85, 1 },
        desc = "+20 Mult, nhưng sau khi đánh tăng Cuồng Nộ của Quái thêm +1 tầng (+8% ATK)",
    },
    enh_brittle = {
        id = "enh_brittle",
        name = "Nứt Vỡ",
        icon = "💥",
        color = { 0.90, 0.60, 0.30, 1 },
        desc = "x1.4 XMult cực mạnh, nhưng 25% tỉ lệ vỡ vụn biến mất vĩnh viễn sau khi ghi điểm",
    },
    enh_escort = {
        id = "enh_escort",
        name = "Hộ Tống",
        icon = "🤝",
        color = { 0.30, 0.80, 0.40, 1 },
        desc = "Không cần đánh ra — khi nằm trên tay lúc kết thúc lượt: +5 Giáp cho người chơi",
    },
    enh_harmonic = {
        id = "enh_harmonic",
        name = "Cộng Hưởng",
        icon = "🎶",
        color = { 0.95, 0.45, 0.75, 1 },
        desc = "+3 Mult cho mỗi lá bài khác trên tay có cùng chất với lá này",
    },
    enh_boss_hunter = {
        id = "enh_boss_hunter",
        name = "Săn Boss",
        icon = "🏹",
        color = { 0.95, 0.75, 0.20, 1 },
        desc = "+25 Chips & +8 Mult khi đối đầu Boss; vô hiệu hóa trước quái thường",
    },
    enh_vanguard = {
        id = "enh_vanguard",
        name = "Tiên Phong",
        icon = "🔱",
        color = { 0.95, 0.50, 0.20, 1 },
        desc = "Mạnh nhất khi đi đầu — nếu đánh ở vị trí đầu tiên (lá 1): +15 Chips & +4 Mult",
    },
    enh_rearguard = {
        id = "enh_rearguard",
        name = "Hậu Vệ",
        icon = "🛡️",
        color = { 0.35, 0.70, 0.90, 1 },
        desc = "Vững chắc chốt chặn — nếu là lá cuối cùng trong tay bài ghi điểm: +8 Giáp & +3 Mult",
    },
}

Deck.FACTIONS = {
    aurelia = {
        id = "aurelia",
        alias = "diamonds",
        name = "Trật Tự Hoàng Kim",
        title = "TRẬT TỰ HOÀNG KIM",
        fullName = "Trật Tự Hoàng Kim (The Gilded Conclave)",
        vnName = "Hoàng Kim",
        symbol = "♦",
        color = { 1.0, 0.82, 0.22, 1 },
        icon = "♦",
        archetype = "Tài Phiệt, Khai Thác 5 Ô Khảm & Lãi Suất Vận Mệnh",
        passive1 = "Kim Ngân & Lãi Vô Tận: Mỗi lá Rô ghi điểm +$1 Vàng. Lãi suất +$1 cho mỗi $4 không giới hạn trần.",
        passive2 = "Khảm Nén Quặng: Mở sẵn 2/5 ô khảm khi nhặt, toàn bộ Ngọc Khảm tăng +50% uy lực.",
    },
    elaris = {
        id = "elaris",
        alias = "clubs",
        name = "Bầy Nguyên Sinh",
        title = "BẦY NGUYÊN SINH",
        fullName = "Bầy Nguyên Sinh (The Feral Swarm)",
        vnName = "Nguyên Sinh",
        symbol = "♣",
        color = { 0.22, 0.82, 0.42, 1 },
        icon = "♣",
        archetype = "Ký Sinh Tiến Hóa, Tuần Hoàn Bộ Bài & Đột Biến Rank",
        passive1 = "Bầy Đàn & Tuần Hoàn: Khởi đầu với 9 lá trên tay. Lá Chuồn khi Discard chui thẳng về đáy Cọc Rút.",
        passive2 = "Tiến Hóa Nuốt Chửng: Chiến Binh Chuồn kết liễu quái vật tiến hóa vĩnh viễn +1 Rank (Rank 10 -> Chân Rết 50c/5m).",
    },
    vharos = {
        id = "vharos",
        alias = "spades",
        name = "Thiết Quân Thứ",
        title = "THIẾT QUÂN THỨ",
        fullName = "Thiết Quân Thứ (The Iron Axiom)",
        vnName = "Thiết Quân Thứ",
        symbol = "♠",
        color = { 0.88, 0.25, 0.35, 1 },
        icon = "♠",
        archetype = "Định luật Bất Biến & Lũy Tiến Chips Cơ Học",
        passive1 = "Định Luật Bất Biến: Lá Bích tự động xếp theo Rank từ bé đến lớn. Miễn nhiễm 100% debuff Boss.",
        passive2 = "Chỉ Số Thép & Quân Lực: Mỗi lá Bích ghi điểm +20 Chips. Rank tăng dần thưởng +(ΔRank × 10) Chips.",
    },
    valoria = {
        id = "valoria",
        alias = "hearts",
        name = "Giáo Hội Huyết Ước",
        title = "GIÁO HỘI HUYẾT ƯỚC",
        fullName = "Giáo Hội Huyết Ước (The Sanguine Covenant)",
        vnName = "Huyết Ước",
        symbol = "♥",
        color = { 0.95, 0.25, 0.35, 1 },
        icon = "♥",
        archetype = "Tử Đạo, Chuyển Hóa Máu & Bùng Nổ Mult Siêu Cấp",
        passive1 = "Huyết Tế Discard: Đổi bài Chiến Binh Cơ (2-10) gây Sát thương Chuẩn = Rank trực tiếp vào Boss.",
        passive2 = "Dấu Ấn Tử Đạo: Mỗi lá Cơ bị Discard tích 1 Huyết Ấn (max 5), tay bài sau nhận +8 Mult và +0.15 XMult mỗi tầng.",
    },
}

-- Backward compatibility aliases
Deck.SUITS = Deck.FACTIONS
Deck.SUITS.hearts             = Deck.FACTIONS.valoria
Deck.SUITS.sanguine_covenant  = Deck.FACTIONS.valoria
Deck.SUITS.diamonds           = Deck.FACTIONS.aurelia
Deck.SUITS.gilded_conclave    = Deck.FACTIONS.aurelia
Deck.SUITS.clubs              = Deck.FACTIONS.elaris
Deck.SUITS.feral_swarm        = Deck.FACTIONS.elaris
Deck.SUITS.spades             = Deck.FACTIONS.vharos
Deck.SUITS.iron_axiom         = Deck.FACTIONS.vharos

Deck.FACTION_ORDER = { "vharos", "valoria", "aurelia", "elaris" }
Deck.SUIT_ORDER = Deck.FACTION_ORDER
Deck.STANDARD_SUIT_NAMES = {
    aurelia = "Rô",
    elaris = "Chuồn",
    vharos = "Bích",
    valoria = "Cơ",
}

Deck.STARTER_DECKS = {
    red_deck = {
        id = "red_deck",
        name = "Bộ Bài Đỏ",
        color = { 0.88, 0.16, 0.20, 1 },
        desc = "+10 Mult cho tay bài đầu tiên của mỗi trận. Bắt đầu combat với 3 lá ngẫu nhiên.",
    },
}

Deck.RANK_NAMES = {
    [1] = "A",
    [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6",
    [7] = "7", [8] = "8", [9] = "9", [10] = "10",
    [11] = "J", [12] = "Q", [13] = "K", [14] = "A"
}

Deck.CARD_ROLES = {
    soldier = {
        id = "soldier",
        name = "Chiến Binh",
        title = "Hàng Ngũ Chiến Binh (2-10)",
        icon = "🛡️",
        desc = "Lực lượng nòng cốt xếp các thế bài cơ bản. Điểm số tăng dần từ 2 đến 10.",
    },
    knight = {
        id = "knight",
        name = "Hiệp Sĩ",
        title = "Hiệp Sĩ / Cận Vệ (J)",
        icon = "🗡️",
        desc = "Bản lề chiến thuật: Tăng thêm +15 Chips & +2 Mult cho mỗi lá Chiến Binh đứng cùng.",
    },
    queen = {
        id = "queen",
        name = "Hoàng Hậu",
        title = "Hoàng Hậu / Phù Sư (Q)",
        icon = "👑",
        desc = "Tương tác trang bị: Tự đem lại x1.1 XMult, +15 Chips & +2 Mult cho mỗi ô trang bị đã khảm.",
    },
    king = {
        id = "king",
        name = "Quốc Vương",
        title = "Quốc Vương / Lãnh Chúa (K)",
        icon = "🏰",
        desc = "Sức mạnh áp đảo: Trụ cột dồn sát thương nặng ký, cộng trực tiếp +25 Chips & +5 Mult.",
    },
    ace = {
        id = "ace",
        name = "Thần Khí",
        title = "Át Chủ Bài / Thần Khí (A)",
        icon = "⚡",
        desc = "Linh hoạt tối đa: Có thể làm đầu hoặc cuối trong Sảnh.",
    },
}

function Deck.getCardRole(rank)
    if rank >= 2 and rank <= 10 then
        return Deck.CARD_ROLES.soldier
    elseif rank == 11 then
        return Deck.CARD_ROLES.knight
    elseif rank == 12 then
        return Deck.CARD_ROLES.queen
    elseif rank == 13 then
        return Deck.CARD_ROLES.king
    elseif rank == 1 or rank == 14 then
        return Deck.CARD_ROLES.ace
    end
    return Deck.CARD_ROLES.soldier
end

function Deck.getChipValue(rank)
    if rank == 1 then
        return 1
    elseif rank == 14 then
        return 11
    elseif rank >= 10 and rank <= 13 then
        return 10
    else
        return rank
    end
end

local nextCardId = 1

-- Keep generated card ids unique after restoring a saved run whose cards may
-- have ids larger than the number of cards currently in the deck.
function Deck.ensureNextCardId(id)
    local numericId = tonumber(id)
    if numericId and numericId >= nextCardId then
        nextCardId = numericId + 1
    end
end

function Deck.newCard(rank, suit)
    local requestedSuit = suit
    if suit == "red_deck" then
        suit = Deck.FACTION_ORDER[Rng.random(#Deck.FACTION_ORDER)]
    end
    local suitInfo = Deck.FACTIONS[suit] or Deck.SUITS[suit] or Deck.FACTIONS.aurelia
    local actualSuit = suitInfo.id
    local role = Deck.getCardRole(rank)

    local isAceOfClubs = ((rank == 1 or rank == 14) and (actualSuit == "elaris" or actualSuit == "clubs"))
    local isAceOfSpades = ((rank == 1 or rank == 14) and (actualSuit == "vharos" or actualSuit == "spades"))

    local card = {
        id = nextCardId,
        rank = rank,
        baseRank = rank, -- Persistent rank
        suit = actualSuit,
        suitName = suitInfo.name,
        suitSymbol = suitInfo.symbol,
        rankName = Deck.RANK_NAMES[rank] or tostring(rank),
        color = suitInfo.color,
        baseChips = Deck.getChipValue(rank),
        role = role.id,
        roleName = role.name,
        roleTitle = role.title,
        roleIcon = role.icon,
        roleDesc = role.desc,
        equipments = {}, -- Up to 3 equipment slots
        maxSockets = 3,
        unlockedSockets = 3,
        isWildSuit = requestedSuit ~= "red_deck" and isAceOfClubs,
        isDualRankAce = requestedSuit ~= "red_deck" and isAceOfSpades,
        isPrimalDrone = false,
        seal = nil, -- "gold" | "red" | "blue" | "purple"
        disableFactionPassives = requestedSuit == "red_deck",
        starterDeckId = requestedSuit == "red_deck" and "red_deck" or nil,
        -- Visual properties
        x = 0,
        y = 0,
        selected = false,
        hovered = false,
        scale = 1.0,
        rotation = 0,
        alpha = 1.0,
    }
    if requestedSuit == "red_deck" then
        card.suitName = Deck.STANDARD_SUIT_NAMES[actualSuit] or card.suitName
        card.unlockedSockets = 3
    end
    nextCardId = nextCardId + 1
    return card
end

Deck.DEFAULT_HAND_SIZE = 3

function Deck.createRedStarterDeck()
    local cards = {}
    for _, suit in ipairs(Deck.FACTION_ORDER) do
        for rank = 2, 14 do
            local card = Deck.newCard(rank, suit)
            card.disableFactionPassives = true
            card.starterDeckId = "red_deck"
            card.isWildSuit = false
            card.isDualRankAce = false
            card.suitName = Deck.STANDARD_SUIT_NAMES[card.suit] or card.suitName
            card.unlockedSockets = 3
            table.insert(cards, card)
        end
    end
    return cards
end

-- Create the selected starter deck. Legacy faction decks remain readable for
-- old saves/tests, while new runs use the 52-card Red Deck.
function Deck.createStarterDeck(suit)
    if suit == "red_deck" then return Deck.createRedStarterDeck() end
    local cards = {
        Deck.newCard(3, suit),  -- Lính 3 (Soldier 3)
        Deck.newCard(8, suit),  -- Lính 8 (Soldier 8)
        Deck.newCard(11, suit), -- Hiệp sĩ J (Knight J)
    }
    return cards
end

-- Degrade card rank by 1 on play. A (rank 1) being degraded causes the card to break ("destroyed")
function Deck.degradeCard(card)
    if card.rank > 2 then
        card.rank = card.rank - 1
        card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
        card.baseChips = Deck.getChipValue(card.rank)
        return "degraded"
    elseif card.rank == 2 then
        card.rank = 1
        card.rankName = "A"
        card.baseChips = Deck.getChipValue(1)
        return "degraded"
    elseif card.rank == 1 then
        return "destroyed"
    end
    return "intact"
end

-- Upgrade card rank by 1 (used in Rest Site / Forge to restore durability)
function Deck.upgradeCard(card)
    local bRank = card.baseRank or card.rank
    if bRank == 1 then
        bRank = 2
    elseif bRank < 13 then
        bRank = bRank + 1
    end
    card.baseRank = bRank
    card.rank = bRank
    card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
    card.baseChips = Deck.getChipValue(card.rank)
    return card
end

-- Reset any in-combat stat modifications back to master card stats
function Deck.restoreDeck(deck)
    if not deck then return end
    for _, card in ipairs(deck) do
        local bRank = card.baseRank or card.rank
        card.rank = bRank
        card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
        if card.isPrimalDrone then
            card.baseChips = 50
            card.baseMult = 5
            card.roleTitle = "Chân Rết Nguyên Thủy"
            card.roleIcon = "🐛"
        else
            card.baseChips = (card.bonusBaseChips or 0) + Deck.getChipValue(card.rank)
        end
        card.selected = false
        card.hovered = false
        card.faceDown = false
    end
    return deck
end

-- Clone card cleanly with separate table reference for combat
function Deck.cloneCard(card)
    local newC = Deck.newCard(card.baseRank or card.rank, card.suit)
    newC.id = card.id -- Preserve exact persistent card identity
    Deck.ensureNextCardId(card.id)
    newC.baseRank = card.baseRank or card.rank
    newC.rank = newC.baseRank
    newC.rankName = Deck.RANK_NAMES[newC.rank] or tostring(newC.rank)
    newC.baseChips = card.baseChips or Deck.getChipValue(newC.rank)
    newC.bonusBaseChips = card.bonusBaseChips or 0
    newC.role = card.role or newC.role
    newC.roleName = card.roleName or newC.roleName
    newC.roleTitle = card.roleTitle or newC.roleTitle
    newC.roleIcon = card.roleIcon or newC.roleIcon
    newC.roleDesc = card.roleDesc or newC.roleDesc
    newC.selected = false
    newC.hovered = false
    newC.faceDown = card.faceDown or false
    newC.isPrimalDrone = card.isPrimalDrone or false
    newC.isWildSuit = card.isWildSuit or false
    newC.isDualRankAce = card.isDualRankAce or false
    newC.disableFactionPassives = card.disableFactionPassives or false
    newC.starterDeckId = card.starterDeckId
    newC.seal = card.seal
    newC.enhancement = card.enhancement
    newC.overchargeStacks = card.overchargeStacks or 0
    newC.isAnchor = card.isAnchor or (card.seal == "seal_anchor" or card.seal == "anchor")
    newC.unlockedSockets = 3
    newC.maxSockets = 3
    newC.exhausted = card.exhausted or false
    newC.equipments = {}
    if card.equipments then
        for _, eq in ipairs(card.equipments) do
            local eqCopy = {}
            for k, v in pairs(eq) do eqCopy[k] = v end
            table.insert(newC.equipments, eqCopy)
        end
    end
    return newC
end

-- A♦ & K♣: Devour card mechanic
function Deck.devourCard(targetCard, sacrificedCard, gameState)
    if not targetCard or not sacrificedCard then return false, "Chưa chọn đủ lá bài!" end
    if targetCard.id == sacrificedCard.id then return false, "Không thể tự nuốt chính mình!" end

    -- A♦ (Lõi Vàng Thủy Tổ): Devour soldier card (2-10) to permanently gain +15 base chips
    local isAceOfDiamonds = (targetCard.rank == 1 or targetCard.rank == 14) and (targetCard.suit == "aurelia" or targetCard.suit == "diamonds")
    local isKingOfClubs = (targetCard.rank == 13) and (targetCard.suit == "elaris" or targetCard.suit == "clubs")
    if targetCard.disableFactionPassives then
        isAceOfDiamonds = false
        isKingOfClubs = false
    end

    if isAceOfDiamonds then
        if sacrificedCard.rank < 2 or sacrificedCard.rank > 10 then
            return false, "Lõi Vàng Thủy Tổ chỉ có thể khảm nuốt lá bài Chiến Binh (2-10)!"
        end
        targetCard.bonusBaseChips = (targetCard.bonusBaseChips or 0) + 15
        targetCard.baseChips = (targetCard.baseChips or Deck.getChipValue(targetCard.rank)) + 15
        
        -- Remove sacrificedCard from persistent deck
        if gameState and gameState.persistentDeck then
            for idx, c in ipairs(gameState.persistentDeck) do
                if c.id == sacrificedCard.id then
                    table.remove(gameState.persistentDeck, idx)
                    break
                end
            end
        end
        return true, "Lõi Vàng Thủy Tổ đã nuốt lá " .. sacrificedCard.rankName .. sacrificedCard.suitSymbol .. " (+15 Chips vĩnh viễn)!"

    elseif isKingOfClubs then
        -- K♣ (Chúa Tể Bầy Sâu): Devours an off-faction card to heal +20 HP or gain +2 Discards
        local isOffFaction = (sacrificedCard.suit ~= "elaris" and sacrificedCard.suit ~= "clubs")
        if not isOffFaction then
            return false, "Chúa Tể Bầy Sâu chỉ ăn thịt lá bài của phe phái khác!"
        end
        if gameState then
            gameState.playerHp = math.min(gameState.maxPlayerHp or 100, (gameState.playerHp or 100) + 20)
            gameState.discardsRemaining = (gameState.discardsRemaining or 3) + 2
            if gameState.persistentDeck then
                for idx, c in ipairs(gameState.persistentDeck) do
                    if c.id == sacrificedCard.id then
                        table.remove(gameState.persistentDeck, idx)
                        break
                    end
                end
            end
        end
        return true, "Chúa Tể Bầy Sâu đã ăn thịt lá " .. sacrificedCard.rankName .. sacrificedCard.suitSymbol .. " (+20 HP & +2 Discard)!"
    end

    return false, "Lá bài này không có khả năng nuốt chửng!"
end

-- Safely add a card to player's persistent deck without duplicating
function Deck.addCardToDeck(gameState, card)
    if not card then return nil end
    if gameState and gameState.starterDeckId == "red_deck" then
        card.disableFactionPassives = true
        card.starterDeckId = "red_deck"
        card.isWildSuit = false
        card.isDualRankAce = false
        card.suitName = Deck.STANDARD_SUIT_NAMES[card.suit] or card.suitName
        card.unlockedSockets = 3
    end
    card.baseRank = card.baseRank or card.rank
    card.rank = card.baseRank
    card.rankName = Deck.RANK_NAMES[card.rank] or tostring(card.rank)
    card.baseChips = Deck.getChipValue(card.rank)
    local role = Deck.getCardRole(card.rank)
    card.role = role.id
    card.roleName = role.name
    card.roleTitle = role.title
    card.roleIcon = role.icon
    card.roleDesc = role.desc
    card.selected = false
    card.hovered = false
    card.equipments = card.equipments or {}

    if not gameState.persistentDeck then
        gameState.persistentDeck = {}
    end
    -- Prevent duplicate references or duplicate IDs
    for _, c in ipairs(gameState.persistentDeck) do
        if c == card or c.id == card.id then
            return c
        end
    end
    table.insert(gameState.persistentDeck, card)
    gameState.masterDeck = gameState.persistentDeck
    return card
end

-- Get remaining durability uses
function Deck.getDurabilityUses(card)
    if card.rank == 1 then
        return 1
    else
        return card.rank
    end
end

-- Create pure mono-suit deck of 52 cards (4 copies of each rank 2..14)
function Deck.createMonoSuitDeck(suit)
    local cards = {}
    for copy = 1, 4 do
        for rank = 2, 14 do
            table.insert(cards, Deck.newCard(rank, suit))
        end
    end
    return cards
end

-- Create cross-suit reward card for boss chest
function Deck.createRewardCard(excludeSuit)
    local availableSuits = {}
    for _, s in ipairs(Deck.SUIT_ORDER) do
        if s ~= excludeSuit then
            table.insert(availableSuits, s)
        end
    end
    local suit = availableSuits[Rng.random(#availableSuits)]
    -- Random high rank: 10, J, Q, K, A
    local ranks = { 10, 11, 12, 13, 14 }
    local rank = ranks[Rng.random(#ranks)]

    local card = Deck.newCard(rank, suit)
    if excludeSuit == "red_deck" then
        card.disableFactionPassives = true
        card.starterDeckId = "red_deck"
        card.isWildSuit = false
        card.isDualRankAce = false
        card.suitName = Deck.STANDARD_SUIT_NAMES[card.suit] or card.suitName
        card.unlockedSockets = 3
    end
    return card
end

function Deck.shuffle(deck)
    local n = #deck
    for i = n, 2, -1 do
        local j = Rng.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    return deck
end

function Deck.sortByRank(hand)
    table.sort(hand, function(a, b)
        if a.rank == b.rank then
            return a.suit < b.suit
        end
        return a.rank > b.rank
    end)
end

function Deck.sortBySuit(hand)
    local suitOrderMap = { aurelia = 1, elaris = 2, vharos = 3, valoria = 4, hearts = 1, diamonds = 2, clubs = 3, spades = 4 }
    table.sort(hand, function(a, b)
        local sa = suitOrderMap[a.suit] or 99
        local sb = suitOrderMap[b.suit] or 99
        if sa == sb then
            return a.rank > b.rank
        end
        return sa < sb
    end)
end

-- Move one card without rebuilding the hand, preserving every card field and id.
function Deck.moveCard(hand, fromIndex, toIndex)
    if not hand or fromIndex == toIndex or not hand[fromIndex] or toIndex < 1 or toIndex > #hand then
        return false
    end
    local card = table.remove(hand, fromIndex)
    table.insert(hand, toIndex, card)
    return true
end

return Deck

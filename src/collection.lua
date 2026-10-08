local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Deck = require("src.deck")
local Shop = require("src.shop")
local RunManager = require("src.run_manager")
local Poker = require("src.poker")

local Collection = {}

-- Definition of all Compendium Categories matching media_1789532874907.png
Collection.CATEGORIES = {
    -- Left Column
    {
        id = "jokers",
        title = "SPN",
        sub = "SPN",
        col = "left",
        btnColor = { 0.58, 0.16, 0.14, 1 }, -- Dark Crimson / Reddish Brown
        badge = "25",
    },
    {
        id = "playing_cards",
        title = "Lá Bài",
        sub = "Bộ Chuẩn 52 Lá",
        col = "left",
        btnColor = { 0.92, 0.28, 0.22, 1 },
    },
    {
        id = "decks",
        title = "Bộ Bài",
        sub = "Bộ Bài Khởi Đầu",
        col = "left",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "1",
    },
    {
        id = "vouchers",
        title = "Phiếu",
        sub = "3 Phiếu Đặc Quyền",
        col = "left",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "3",
        alert = true,
    },
    {
        id = "equipment",
        title = "Trang Bị",
        sub = "Trang Bị Khảm Ngọc",
        col = "left",
        isBigOrange = true,
        btnColor = { 0.96, 0.54, 0.08, 1 }, -- Bright Balatro Orange
        badge = "8",
    },

    -- Right Column
    {
        id = "enhancements",
        title = "Lá Cường Hoá",
        sub = "Thuật Rèn Bài",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "8",
    },
    {
        id = "seals",
        title = "Con Dấu",
        sub = "Ấn Chiến Ma Pháp",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "6",
    },
    {
        id = "editions",
        title = "Ấn Bản",
        sub = "Hiệu Ứng Phủ Bài",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "4",
        alert = true,
    },
    {
        id = "packs",
        title = "Rương",
        sub = "Toàn Bộ Rương Trong Game",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "5",
    },
    {
        id = "blinds",
        title = "Blind",
        sub = "Quái & Dị Biến Boss",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        isTall = true,
        badge = "9",
        alert = true,
    },
    {
        id = "other",
        title = "Thế Đánh",
        sub = "9 Bí Tịch Cửu Phẩm",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "9",
    },
    {
        id = "consumables",
        title = "Lá Tiêu Thụ",
        sub = "Dược Liệu & Vật Phẩm Tiêu Hao",
        col = "right",
        btnColor = { 0.95, 0.55, 0.55, 1 },
        icon = "✧",
    },
}

local categoryAccents = {
    jokers = { "✦", { 0.40, 0.72, 0.92, 1 } }, playing_cards = { "♡", { 0.72, 0.24, 0.22, 1 } },
    decks = { "▣", { 0.78, 0.61, 0.32, 1 } }, vouchers = { "◈", { 0.30, 0.68, 0.48, 1 } },
    equipment = { "◇", { 0.48, 0.70, 0.82, 1 } }, enhancements = { "✧", { 0.82, 0.53, 0.30, 1 } },
    seals = { "✦", { 0.62, 0.42, 0.82, 1 } }, editions = { "◇", { 0.82, 0.67, 0.34, 1 } },
    packs = { "▣", { 0.32, 0.68, 0.84, 1 } }, consumables = { "✧", { 0.72, 0.40, 0.40, 1 } },
    blinds = { "⚔", { 0.68, 0.34, 0.34, 1 } }, other = { "✦", { 0.40, 0.68, 0.44, 1 } },
}
for _, cat in ipairs(Collection.CATEGORIES) do
    local style = categoryAccents[cat.id]
    if style then cat.icon, cat.accent = style[1], style[2] end
end

-- Static items for categories that don't have dedicated Lua modules
local EDITIONS = {
    { id = "ed_base", name = "Ấn Bản Chuẩn (Standard)", rarity = "Cơ Bản", desc = "Lá bài gốc nguyên bản không mang lớp phủ quang học ma thuật.", icon = "🃏", color = { 0.70, 0.70, 0.70, 1 } },
}
local itemCache = {}
local cacheWarmKeys = {}
local cacheWarmIndex = 1

function Collection.getCategories()
    for _, cat in ipairs(Collection.CATEGORIES) do
        local count = #Collection.getItems(cat.id)
        cat.badge = tostring(count)
    end
    return Collection.CATEGORIES
end

function Collection.getCategoryById(catId)
    for _, cat in ipairs(Collection.CATEGORIES) do
        if cat.id == catId then
            cat.badge = tostring(#Collection.getItems(cat.id))
            return cat
        end
    end
    return nil
end

local function buildItems(category, packFilter)
    local items = {}

    if category == "playing_cards" then
        for _, suit in ipairs(Deck.FACTION_ORDER) do
            local info = Deck.FACTIONS[suit]
            for rank = 2, 14 do
                local rankName = Deck.RANK_NAMES[rank]
                local A=require("src.card_abilities")
                local card={rank=rank,suit=suit}
                local def=A.definition(card)
                table.insert(items, {
                    id = "standard_" .. suit .. "_" .. rank,
                    name = rankName .. " " .. Deck.STANDARD_SUIT_NAMES[suit].." · "..def.characterName,
                    rank = rank,
                    rankName = rankName,
                    suit = suit,
                    suitSymbol = info.symbol,
                    subtitle = "BỘ CHUẨN • " .. Deck.STANDARD_SUIT_NAMES[suit],
                    rarity = "Lá Bài",
                    desc = def.name..": "..A.description(card).."\n"..def.ambition,
                    color = info.color,
                })
            end
        end
    elseif category == "jokers" then
        -- Harvest all deities dynamically from Deities.CATALOG
        for id, d in pairs(Deities.CATALOG) do
            local rarityName = (d.rarity == "legendary" and "Huyền Thoại") or
                               (d.rarity == "rare" and "Sử Thi") or
                               (d.rarity == "uncommon" and "Hiếm") or "Thường"
            table.insert(items, {
                id = d.id or id,
                name = d.name or "Thần Vô Danh",
                subtitle = (d.suit and string.upper(d.suit) or "SPN") .. " • " .. string.upper(rarityName),
                rarity = rarityName,
                cost = d.cost or 5,
                showCost = true,
                desc = (d.desc or "Hiệu ứng thần bài hộ mệnh") .. (d.lore and ("\n\n\"" .. d.lore .. "\"") or ""),
                icon = "🃏",
                color = (d.rarity == "legendary" and { 0.95, 0.82, 0.22, 1 }) or
                        (d.rarity == "rare" and { 0.88, 0.35, 0.88, 1 }) or
                        (d.rarity == "uncommon" and { 0.35, 0.75, 0.95, 1 }) or
                        { 0.75, 0.75, 0.75, 1 },
                suit = d.suit,
            })
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "equipment" then
        -- Harvest all equipment dynamically from Equipment.POOL and canonical Equipment.ITEMS
        local seen = {}
        local equipmentIds = {}
        for _, pool in ipairs({Equipment.POOL, Equipment.SOUL_POOL}) do
            for _, id in ipairs(pool or {}) do equipmentIds[#equipmentIds+1] = id end
        end
        for _,eq in ipairs(require("src.basic_equipment").definitions) do equipmentIds[#equipmentIds+1]=eq.id end
        for _, id in ipairs(equipmentIds) do
            local eq = Equipment.ITEMS[id]
            if eq and not seen[eq.id or id] then
                seen[eq.id or id] = true
                local slotsNeeded = eq.slotsNeeded or 1
                local rarity = eq.rarity or "common"
                local rarityName = (rarity == "legendary" and "Huyền Thoại") or
                                   (rarity == "rare" and "Sử Thi") or
                                   (rarity == "uncommon" and "Hiếm") or "Thường"
                local subtitle = (slotsNeeded > 1 and (slotsNeeded .. " HỐC KHẢM") or "1 HỐC KHẢM") .. " • " .. string.upper(rarityName)
                table.insert(items, {
                    id = eq.id or id,
                    name = eq.name or "Trang Bị",
                    subtitle = subtitle,
                    rarity = rarityName,
                    slotsNeeded = slotsNeeded,
                    cost = eq.cost or (slotsNeeded > 1 and 8 or 4),
                    desc = (eq.desc or "Ngọc ma thuật dùng khảm vào ô trống của lá bài")
                        ..(eq.soulOnly and ("\nChỉ đổi tại Chợ Linh Hồn: "..eq.cost.." LH.") or ""),
                    icon = eq.icon or "💎",
                    color = eq.color or (rarity == "legendary" and { 0.95, 0.82, 0.22, 1 } or { 0.95, 0.54, 0.08, 1 }),
                })
            end
        end
        for id, eq in pairs(Equipment.ITEMS or {}) do
            local itemId = eq.id or id
            if type(eq) == "table" and not seen[itemId] and id == itemId then
                seen[itemId] = true
                local slotsNeeded = eq.slotsNeeded or 1
                local rarity = eq.rarity or "common"
                local rarityName = (rarity == "legendary" and "Huyền Thoại") or
                                   (rarity == "rare" and "Sử Thi") or
                                   (rarity == "uncommon" and "Hiếm") or "Thường"
                local subtitle = (slotsNeeded > 1 and (slotsNeeded .. " HỐC KHẢM") or "1 HỐC KHẢM") .. " • " .. string.upper(rarityName)
                table.insert(items, {
                    id = itemId,
                    name = eq.name or "Trang Bị",
                    subtitle = subtitle,
                    rarity = rarityName,
                    slotsNeeded = slotsNeeded,
                    cost = eq.cost or (slotsNeeded > 1 and 8 or 4),
                    desc = eq.desc or "Ngọc ma thuật dùng khảm vào ô trống của lá bài",
                    icon = eq.icon or "💎",
                    color = eq.color or { 0.95, 0.54, 0.08, 1 },
                })
            end
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "consumables" then
        local groups = {heal={1,"BÌNH MÁU"}, armor_potion={2,"BÌNH GIÁP"},
            speed_single={3,"TỐC ĐÁNH"}, speed_team={3,"TỐC ĐÁNH"}, destroy={4,"TIÊU HỦY"}, bed={5,"GIƯỜNG"}}
        local seen = {}
        local function add(item)
            if seen[item.id] then return end
            seen[item.id] = true
            local group = groups[item.category] or {6,"TIÊU HAO"}
            item.subtitle = group[2] .. " • VẬT PHẨM TIÊU HAO"
            item.rarity = "Tiêu Hao"
            item.groupOrder, item.catalogOrder = group[1], #items + 1
            items[#items+1] = item
        end
        -- Share the actual shop definitions, so future potion/utility entries
        -- automatically appear with their real values and descriptions.
        for _, def in ipairs(Shop.POTIONS or {}) do add(Shop.healingItem("upper", def.id)) end
        for _, offer in ipairs(Shop.SOUL_SUPPORT or {}) do
            local card = RunManager[offer.factory]()
            if card.category == "speed_single" or card.category == "speed_team" or card.category=="socket_expansion" or card.category=="rule_break" then
                card.desc = (Shop.getConsumableDescription(card) or card.desc)
                    .. "\nNguồn: Chợ Linh Hồn, " .. offer.cost .. " LH."
                add(card)
            end
        end
        add(Shop.destructionItem("upper"))
        table.sort(items, function(a,b)
            if a.groupOrder ~= b.groupOrder then return a.groupOrder < b.groupOrder end
            return a.catalogOrder < b.catalogOrder
        end)

    elseif category == "decks" then
        local red = Deck.STARTER_DECKS.red_deck
        table.insert(items, {
            id = red.id,
            name = red.name,
            subtitle = "BỘ BÀI KHỞI ĐẦU",
            rarity = "Starter Deck",
            desc = red.desc,
            icon = "🂠",
            color = red.color,
            badge = "🔴",
        })

    elseif category == "vouchers" then
        for _, voucher in ipairs(Shop.VOUCHERS or {}) do
            table.insert(items, {
                id = voucher.id,
                name = voucher.name,
                subtitle = "PHIẾU ĐẶC QUYỀN",
                rarity = "Đặc Quyền",
                cost = voucher.cost,
                desc = voucher.desc,
                icon = voucher.icon or "🎟️",
                color = voucher.color,
            })
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "enhancements" then
        -- Harvest directly from Deck.ENHANCEMENTS
        for id, enh in pairs(Deck.ENHANCEMENTS or {}) do
            table.insert(items, {
                id = enh.id or id,
                name = enh.name or "Cường Hóa",
                subtitle = "THUẬT RÈN BÀI • CƯỜNG HÓA",
                rarity = "Chiến Thuật",
                desc = enh.desc or "Hiệu ứng cường hóa thẻ bài",
                icon = enh.icon or "🛡️",
                color = enh.color or { 0.40, 0.70, 0.90, 1 },
            })
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "seals" then
        -- Harvest directly from Deck.SEALS (canonical items only)
        local seen = {}
        for id, s in pairs(Deck.SEALS or {}) do
            local sId = s.id or id
            if type(s) == "table" and not seen[sId] and id == sId then
                seen[sId] = true
                table.insert(items, {
                    id = sId,
                    name = s.name or "Ấn Chiến",
                    subtitle = "ẤN CHIẾN MA PHÁP",
                    rarity = "Ấn Chiến",
                    desc = s.desc or "Dấu ấn ma pháp ban phước cho quân bài",
                    icon = s.icon or "🩸",
                    color = s.color or { 0.90, 0.15, 0.15, 1 },
                })
            end
        end
        table.sort(items, function(a, b) return a.name < b.name end)

    elseif category == "editions" then
        table.insert(items,EDITIONS[1])
        for _, ed in ipairs(require("src.card_effects").getEditionCatalog()) do
            table.insert(items, ed)
        end

    elseif category == "packs" then
        for _, pack in ipairs(Shop.PACK_CATALOG or {}) do
            if not packFilter then
                table.insert(items, {
                    id = "pack_" .. pack.packType,
                    packType = pack.packType,
                    name = pack.name,
                    subtitle = pack.subtitle,
                    rarity = pack.rarity or "Gói Bài",
                    cost = pack.cost,
                    desc = pack.desc,
                    icon = pack.icon,
                    color = pack.color,
                })
            end
            if packFilter and pack.packType == packFilter then
                for index, reward in ipairs(Shop.getPackContents(pack.packType)) do
                    local item = {}
                    for key, value in pairs(reward) do item[key] = value end
                    if pack.packType == "buffoon" then item.deityId = reward.id end
                    item.id = "pack_content_" .. pack.packType .. "_" .. tostring(reward.id or (reward.suit or "item") .. "_" .. (reward.rank or index))
                    item.packType = pack.packType
                    item.sourcePackType = pack.packType
                    item.isPackContent = true
                    item.name = reward.name or ((reward.rankName or tostring(reward.rank or "?")) .. (reward.suitSymbol or ""))
                    item.subtitle = pack.name .. " • NỘI DUNG CÓ THỂ NHẬN"
                    item.rarity = reward.rarity or pack.rarity or "Nội Dung Gói"
                    item.desc = (reward.desc or "Quân bài có thể xuất hiện khi mở gói.") .. "\n\nNguồn: " .. pack.name
                    item.icon = reward.icon or pack.icon
                    item.color = reward.color or pack.color
                    item.cost = nil
                    table.insert(items, item)
                end
            end
        end

    elseif category == "blinds" then
        -- Normal, Elite, and Bosses
        table.insert(items, {
            id = "blind_small",
            name = "Small Blind (Cược Nhỏ)",
            subtitle = "VÒNG ĐẤU CƠ BẢN",
            rarity = "Tiêu Chuẩn",
            desc = "Trận đấu bắt buộc với nhà thám hiểm. Từ ải 41 mới gặp quái vật.",
            icon = "🔷",
            color = { 0.35, 0.65, 0.95, 1 },
        })
        table.insert(items, {
            id = "blind_big",
            name = "Big Blind (Cược Lớn)",
            subtitle = "VÒNG ĐẤU THỬ THÁCH",
            rarity = "Thử Thách",
            desc = "Trận tinh anh bắt buộc, mục tiêu 1.5x HP và thưởng nhiều Vàng hơn.",
            icon = "🔶",
            color = { 0.95, 0.55, 0.20, 1 },
        })

        -- Only show bosses that the active expedition can actually generate.
        for _, id in ipairs(RunManager.BOSS_KEYS or {}) do
            local boss = RunManager.BOSS_DEBUFFS[id]
            if boss then
                table.insert(items, {
                    id = boss.id or id,
                    name = boss.name,
                    subtitle = boss.title or "BOSS DỊ BIẾN",
                    rarity = "Boss",
                    desc = boss.desc or "Lời nguyền áp chế đặc biệt của Boss Blind. Không thể Bỏ Qua!",
                    icon = "💀",
                    color = boss.color or { 0.95, 0.25, 0.25, 1 },
                })
            end
        end

    elseif category == "other" then
        -- 9 Poker Hand Types (Thế Đánh)
        for _, h in ipairs(Poker.HAND_TYPES_ORDERED or {}) do
            table.insert(items, {
                id = h.id,
                handId = h.id,
                name = h.vnName or h.name,
                subtitle = "THẾ ĐÁNH • " .. string.upper(h.name),
                rarity = "Bí Tịch Cửu Phẩm",
                desc = "Aura cơ sở: " .. h.baseChips .. " Chips × " .. h.baseMult .. " Mult.\nTổ hợp yêu cầu: " .. (h.subtitle or h.name) .. " (" .. (h.requiredCards or 1) .. " lá).\nNâng cấp cấp độ vĩnh viễn thông qua các Thẻ Hành Tinh tương ứng!",
                icon = "🎴",
                color = { 0.40, 0.75, 0.95, 1 },
            })
        end
    end

    return items
end

local function cacheKey(category, packFilter)
    return tostring(category) .. "\31" .. tostring(packFilter or "")
end

function Collection.getItems(category, packFilter)
    local key = cacheKey(category, packFilter)
    local items = itemCache[key]
    if not items then
        items = buildItems(category, packFilter)
        itemCache[key] = items
    end
    return items
end

-- Build one catalog per idle frame so opening the collection never has to
-- construct all category tables in a single draw call.
function Collection.prepareCacheStep()
    if #cacheWarmKeys == 0 then
        for _, category in ipairs(Collection.CATEGORIES) do
            cacheWarmKeys[#cacheWarmKeys + 1] = { category.id }
        end
        for _, pack in ipairs(Shop.PACK_CATALOG or {}) do
            cacheWarmKeys[#cacheWarmKeys + 1] = { "packs", pack.packType }
        end
    end
    local entry = cacheWarmKeys[cacheWarmIndex]
    if not entry then return true end
    Collection.getItems(entry[1], entry[2])
    cacheWarmIndex = cacheWarmIndex + 1
    return cacheWarmIndex > #cacheWarmKeys
end

function Collection.invalidateCache()
    itemCache = {}
    cacheWarmKeys = {}
    cacheWarmIndex = 1
end

return Collection

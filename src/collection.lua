local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Deck = require("src.deck")
local Shop = require("src.shop")
local Monster = require("src.monster")
local RunManager = require("src.run_manager")
local Poker = require("src.poker")

local Collection = {}

-- Definition of all Compendium Categories matching media_1789532874907.png
Collection.CATEGORIES = {
    -- Left Column
    {
        id = "jokers",
        title = "Hộ Linh",
        sub = "Hộ Linh",
        col = "left",
        btnColor = { 0.58, 0.16, 0.14, 1 }, -- Dark Crimson / Reddish Brown
        badge = "25",
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
        sub = "Bí Tịch & Đặc Quyền",
        col = "left",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "9",
        alert = true,
    },
    {
        id = "consumables",
        title = "Lá Tiêu Thụ",
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
        title = "Gói Bài",
        sub = "Gói Thẻ Cửa Hàng",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "5",
    },
    {
        id = "tags",
        title = "Khế Ước",
        sub = "Đánh Đổi & Truy Nã",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "6",
        alert = true,
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
        title = "Khác",
        sub = "Tổ Hợp & Luật Bài",
        col = "right",
        btnColor = { 0.92, 0.28, 0.22, 1 },
        badge = "9",
    },
}

-- Static items for categories that don't have dedicated Lua modules
local EDITIONS = {
    { id = "ed_base", name = "Ấn Bản Chuẩn (Standard)", rarity = "Cơ Bản", desc = "Lá bài gốc nguyên bản không mang lớp phủ quang học ma thuật.", icon = "🃏", color = { 0.70, 0.70, 0.70, 1 } },
    { id = "ed_foil", name = "Mạ Bạc (Foil)", rarity = "Đặc Biệt", desc = "Phủ một lớp kim loại bạc lấp lánh: Tặng thêm +50 Chips cố định mỗi khi kích hoạt!", icon = "✨", color = { 0.35, 0.75, 0.95, 1 } },
    { id = "ed_holo", name = "Quang Phổ (Holographic)", rarity = "Hiếm", desc = "Phản chiếu 7 sắc cầu vồng: Tặng thêm +10 Mult cho tổng điểm tay bài khi kích hoạt!", icon = "🌟", color = { 0.85, 0.35, 0.85, 1 } },
    { id = "ed_poly", name = "Đa Sắc (Polychrome)", rarity = "Huyền Thoại", desc = "Hào quang ngũ sắc rực rỡ: Nhân x1.5 XMult trực tiếp vào điểm số cuối cùng!", icon = "🌈", color = { 0.95, 0.80, 0.20, 1 } },
}

local PACKS = {
    { id = "pack_buffoon", name = "Gói Hộ Linh", cost = 4, rarity = "Đặc Quyền", desc = "Mở ra 2 Hộ Linh ngẫu nhiên. Chọn 1 để nhận!", icon = "🃏", color = { 0.90, 0.40, 0.20, 1 } },
    { id = "pack_standard", name = "Gói Quân Binh (Standard Pack)", cost = 4, rarity = "Tiêu Chuẩn", desc = "Mở ra 3 quân bài ma thuật kèm cường hóa hoặc ấn bản. Chọn 1 lá thêm vào bộ bài!", icon = "🎴", color = { 0.25, 0.60, 0.90, 1 } },
    { id = "pack_arcana", name = "Gói Trang Bị (Arcana Pack)", cost = 4, rarity = "Ma Pháp", desc = "Mở ra 3 Trang Bị Khảm Ngọc ngẫu nhiên. Chọn 1 bảo vật để khảm vào quân bài!", icon = "🔮", color = { 0.65, 0.35, 0.85, 1 } },
    { id = "pack_celestial", name = "Gói Thiên Thể (Celestial Pack)", cost = 4, rarity = "Thần Thánh", desc = "Mở ra các hành tinh ban phước, tăng vĩnh viễn Chips và Mult cho một thế bài cụ thể!", icon = "🪐", color = { 0.20, 0.75, 0.75, 1 } },
    { id = "pack_spectral", name = "Gói U Hồn (Spectral Pack)", cost = 6, rarity = "Cấm Kỵ", desc = "Mở ra các phép thuật biến dị cổ đại cực mạnh nhưng mang theo tác dụng phụ khó lường!", icon = "👻", color = { 0.85, 0.20, 0.40, 1 } },
}

local VOUCHERS = {
    { id = "v_discount", name = "Thẻ Thành Viên (Overstock)", rarity = "Phiếu", cost = 10, desc = "Giảm vĩnh viễn -$2 giá gieo lại (Reroll) tại mọi Cửa Hàng suốt cả hành trình!", icon = "🎟️", color = { 0.35, 0.85, 0.55, 1 } },
    { id = "v_interest", name = "Sổ Tiết Kiệm (Seed Money)", rarity = "Phiếu", cost = 10, desc = "Nâng trần mức lãi ngân khố sau mỗi trận từ +$5 lên tối đa +$10 mỗi ván (cần $50 để đạt tối đa)!", icon = "💰", color = { 0.95, 0.80, 0.25, 1 } },
    { id = "v_hand_plus", name = "Bùa Hảo Thủ (Grabber)", rarity = "Phiếu", cost = 10, desc = "Tăng vĩnh viễn +1 Lượt Đánh bài (Max Hands) tối đa trong mọi trận chiến!", icon = "✋", color = { 0.85, 0.45, 0.95, 1 } },
    { id = "v_discard_plus", name = "Túi Đổi Vận (Wasteful)", rarity = "Phiếu", cost = 10, desc = "Tăng vĩnh viễn +1 Lượt Đổi bài (Max Discards) tối đa trong mọi trận chiến!", icon = "🔄", color = { 0.40, 0.75, 0.95, 1 } },
    { id = "v_crystal", name = "Kính Ma Thuật (Telescope)", rarity = "Phiếu", cost = 10, desc = "Gói Thiên Thể luôn chứa hành tinh nâng cấp cho tay bài bạn chơi nhiều nhất!", icon = "🔭", color = { 0.30, 0.85, 0.85, 1 } },
    { id = "v_omen", name = "Chiêm Tinh Cổ (Omen Globe)", rarity = "Phiếu", cost = 10, desc = "Gói Trang Bị có tỷ lệ xuất hiện các cổ vật Huyền Thoại và Ấn Bản quý hiếm!", icon = "🔮", color = { 0.75, 0.40, 0.90, 1 } },
    { id = "v_directors", name = "Lệnh Giám Khảo (Director's Cut)", rarity = "Phiếu", cost = 10, desc = "Cho phép Gieo Lại (Reroll) Boss Blind 1 lần mỗi Ante với giá $10!", icon = "🎬", color = { 0.95, 0.50, 0.20, 1 } },
    { id = "v_glow", name = "Quang Diệu (Glow Up)", rarity = "Phiếu", cost = 10, desc = "Tăng gấp đôi tỷ lệ Hộ Linh có hiệu ứng Foil, Holo hoặc Polychrome!", icon = "✨", color = { 0.95, 0.85, 0.30, 1 } },
    { id = "v_reroll_surplus", name = "Chợ Đen (Reroll Surplus)", rarity = "Phiếu", cost = 10, desc = "Giá khởi điểm gieo lại tại Cửa Hàng giảm xuống còn $3 (bình thường $5)!", icon = "🏷️", color = { 0.40, 0.90, 0.60, 1 } },
}

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

function Collection.getItems(category)
    local items = {}

    if category == "jokers" then
        -- Harvest all deities dynamically from Deities.CATALOG
        for id, d in pairs(Deities.CATALOG) do
            local rarityName = (d.rarity == "legendary" and "Huyền Thoại") or
                               (d.rarity == "rare" and "Sử Thi") or
                               (d.rarity == "uncommon" and "Hiếm") or "Thường"
            table.insert(items, {
                id = d.id or id,
                name = d.name or "Thần Vô Danh",
                subtitle = (d.suit and string.upper(d.suit) or "HỘ LINH") .. " • " .. string.upper(rarityName),
                rarity = rarityName,
                cost = d.cost or 5,
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

    elseif category == "consumables" then
        -- Harvest all equipment dynamically from Equipment.POOL and canonical Equipment.ITEMS
        local seen = {}
        for _, id in ipairs(Equipment.POOL or {}) do
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
                    desc = eq.desc or "Ngọc ma thuật dùng khảm vào ô trống của lá bài",
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
        for _, v in ipairs(VOUCHERS) do
            table.insert(items, v)
        end

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
        for _, ed in ipairs(EDITIONS) do
            table.insert(items, ed)
        end

    elseif category == "packs" then
        for _, p in ipairs(PACKS) do
            table.insert(items, p)
        end

    elseif category == "tags" then
        -- Include Unified Skip Pacts
        if RunManager.SKIP_PACTS then
            for _, pact in ipairs(RunManager.SKIP_PACTS) do
                table.insert(items, {
                    id = pact.id,
                    name = pact.name,
                    subtitle = "KHẾ ƯỚC BỎ ẢI",
                    rarity = "Khế Ước",
                    desc = "🎁 Nhận ngay: " .. (pact.instantDesc or "") .. "\n⚠️ Món nợ: " .. (pact.debtDesc or "") .. "\n⏳ Thời hạn: " .. (pact.durationDesc or "Toàn bộ ván chơi"),
                    icon = pact.icon or "📜",
                    color = pact.color or { 0.95, 0.82, 0.22, 1 },
                })
            end
        end
        -- Include Legacy Skip Tags
        for _, t in ipairs(RunManager.TAGS or {}) do
            table.insert(items, {
                id = t.id,
                name = t.name,
                subtitle = "NHÃN BỎ QUA",
                rarity = "Thẻ Thưởng",
                desc = t.desc,
                icon = t.icon or "🏷️",
                color = t.color or { 0.95, 0.82, 0.22, 1 },
            })
        end

    elseif category == "blinds" then
        -- Normal, Elite, and Bosses
        table.insert(items, {
            id = "blind_small",
            name = "Small Blind (Cược Nhỏ)",
            subtitle = "VÒNG ĐẤU CƠ BẢN",
            rarity = "Tiêu Chuẩn",
            desc = "Mục tiêu điểm chuẩn theo Ante hiện tại. Có thể Bỏ Qua để nhận Thẻ Thưởng Skip Tag!",
            icon = "🔷",
            color = { 0.35, 0.65, 0.95, 1 },
        })
        table.insert(items, {
            id = "blind_big",
            name = "Big Blind (Cược Lớn)",
            subtitle = "VÒNG ĐẤU THỬ THÁCH",
            rarity = "Thử Thách",
            desc = "Mục tiêu 1.5x điểm. Thưởng nhiều Vàng hơn và có thể Bỏ Qua nhận Thẻ Thưởng quý!",
            icon = "🔶",
            color = { 0.95, 0.55, 0.20, 1 },
        })

        -- Active disruptive bosses
        for id, b in pairs(Monster.DISRUPTIVE_BOSSES or {}) do
            table.insert(items, {
                id = b.id or id,
                name = b.name,
                subtitle = b.title or "BOSS DỊ BIẾN",
                rarity = "Boss",
                desc = b.desc or "Lời nguyền áp chế đặc biệt của Boss Blind. Không thể Bỏ Qua!",
                icon = "💀",
                color = b.color or { 0.95, 0.25, 0.25, 1 },
            })
        end

    elseif category == "other" then
        -- 9 Poker Hand Types
        for _, h in ipairs(Poker.HAND_TYPES_ORDERED or {}) do
            table.insert(items, {
                id = h.id,
                name = h.vnName or h.name,
                subtitle = "TAY BÀI: " .. string.upper(h.name),
                rarity = "Tổ Hợp Bài",
                desc = "Điểm cơ sở: " .. h.baseChips .. " Chips x " .. h.baseMult .. " Mult.\nĐộ hiếm nâng cấp tăng mạnh khi sở hữu Bí Tịch Thiên Thể!",
                icon = "🎴",
                color = { 0.40, 0.75, 0.95, 1 },
            })
        end
    end

    return items
end

return Collection

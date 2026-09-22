local Equipment = require("src.equipment")
local Poker = require("src.poker")
local Sound = require("src.sound")
local Deck = require("src.deck")
local Deities = require("src.deities")
local Rng = require("src.rng")

local Shop = {}

function Shop.new()
    return {
        items = {},
        baseRerollCost = 5,
        rerollCost = 5,
        currentPackOpening = nil,
    }
end

function Shop.resetReroll(shop)
    if not shop then return end
    shop.rerollCost = shop.baseRerollCost or 5
end

function Shop.refresh(shop, gameState)
    shop.items = {}
    local unlockedHands = gameState.unlockedHands or {}
    local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"

    ----------------------------------------------------------------------------
    -- 1. UPPER SECTION CARDS (Thần Hộ Mệnh, Trang Bị Khảm, Quân Bài Tuyển Mộ)
    ----------------------------------------------------------------------------
    -- A. Thần Hộ Mệnh (Deity / Joker equivalent)
    local availableDeities = Deities.getRandomShopPool(gameState.deities, 2)
    if #availableDeities > 0 then
        local d = availableDeities[1]
        local dColor = { 0.95, 0.85, 0.35, 1 }
        if d.rarity == "rare" then dColor = { 0.95, 0.40, 0.40, 1 }
        elseif d.rarity == "uncommon" then dColor = { 0.35, 0.70, 0.95, 1 } end

        table.insert(shop.items, {
            section = "upper",
            category = "deity",
            deity = d,
            name = d.name,
            subtitle = "HỘ LINH",
            desc = d.desc or "+Hiệu ứng đặc biệt ván đấu",
            cost = d.cost or 5,
            rarity = d.rarity or "common",
            icon = "👑",
            color = dColor,
        })
    end

    -- B. Trang Bị Khảm (Gemstone / Weapon Equipment)
    local eq1 = Equipment.getRandomEquipment()
    table.insert(shop.items, {
        section = "upper",
        category = "equipment",
        equipment = eq1,
        name = eq1.name,
        subtitle = "TRANG BỊ KHẢM",
        desc = eq1.desc,
        cost = 5,
        icon = eq1.icon or "💎",
        color = eq1.color or { 0.95, 0.75, 0.25, 1 },
    })

    -- C. Quân Bài Chiêu Mộ (Reinforcement Card for Deck)
    local rewardCard = nil
    if Rng.random() < 0.5 then
        rewardCard = Deck.createRewardCard(userFaction)
    else
        local rankPool = { 9, 10, 11, 12, 13, 14 }
        local r = rankPool[Rng.random(#rankPool)]
        rewardCard = Deck.newCard(r, userFaction)
    end
    table.insert(shop.items, {
        section = "upper",
        category = "card",
        card = rewardCard,
        name = (rewardCard.roleTitle or "Chiến Binh") .. " " .. rewardCard.rankName .. rewardCard.suitSymbol,
        subtitle = "QUÂN BÀI",
        desc = "Thêm lá " .. (rewardCard.roleTitle or "") .. " " .. rewardCard.rankName .. rewardCard.suitSymbol .. " (+" .. rewardCard.baseChips .. " Chips, Chất " .. rewardCard.suitName .. ") vào bộ bài!",
        cost = 4,
        icon = rewardCard.suitSymbol,
        color = rewardCard.color,
    })

    -- D. Thẻ Mở Rộng Tay Bài (Hand Size Expansion max 5)
    local curHandSize = (gameState and gameState.maxHandSize) or 3
    if curHandSize < 5 then
        local expandCost = (curHandSize == 3) and 12 or 18
        table.insert(shop.items, {
            section = "upper",
            category = "hand_expansion",
            name = "Mở Rộng Tay Bài",
            subtitle = "TAY BÀI +1 (MAX 5)",
            desc = "Tăng vĩnh viễn +1 Kích thước tay bài tối đa (3 -> 4 -> 5 lá, tối đa 5 lá)!",
            cost = expandCost,
            icon = "🎴",
            color = { 0.85, 0.45, 0.95, 1 },
        })
    end

    ----------------------------------------------------------------------------
    -- 2. LOWER SECTION CARDS (Phiếu Ante / Voucher & Gói Bài Booster Packs)
    ----------------------------------------------------------------------------
    -- A. Left: Phiếu Ante / Sách Bí Tịch (Voucher Slot)
    local availableBooks = {}
    for handId, book in pairs(Poker.SKILL_BOOKS) do
        if not unlockedHands[handId] then
            table.insert(availableBooks, book)
        end
    end
    for i = #availableBooks, 2, -1 do
        local j = Rng.random(i)
        availableBooks[i], availableBooks[j] = availableBooks[j], availableBooks[i]
    end

    if #availableBooks > 0 then
        local b = availableBooks[1]
        table.insert(shop.items, {
            section = "lower_voucher",
            category = "book", -- maintains compatibility with Test 9
            handId = b.handId,
            name = b.name,
            subtitle = "PHIẾU BÍ TỊCH",
            desc = "Mở khóa vĩnh viễn tay bài: " .. b.name .. " (" .. b.desc .. ")",
            cost = 10,
            color = { 0.22, 0.72, 0.98, 1 },
            icon = "📜",
        })
    else
        -- All hands unlocked: offer permanent Ante Voucher
        local vouchers = {
            { id = "v_discount", name = "Thẻ Thành Viên", desc = "Giảm vĩnh viễn -$2 giá gieo lại (Reroll) tại mọi Shop!", cost = 10, color = { 0.35, 0.85, 0.55, 1 } },
            { id = "v_interest", name = "Sổ Tiết Kiệm (Seed Money)", desc = "Nâng trần mức lãi ngân khố từ +$5 lên tối đa +$10 mỗi ván (cần $50 để đạt tối đa)!", cost = 10, color = { 0.95, 0.80, 0.25, 1 } },
            { id = "v_hand_plus", name = "Bùa Hảo Thủ", desc = "Tăng vĩnh viễn +1 Lượt Đánh (Max Hands) mỗi trận!", cost = 10, color = { 0.85, 0.45, 0.95, 1 } },
            { id = "v_hand_size", name = "Mở Rộng Tay Bài", desc = "Tăng vĩnh viễn +1 Kích thước tay bài tối đa (Hand Size: 3 -> 4 -> 5...)!", cost = 8, color = { 0.85, 0.45, 0.95, 1 } },
        }
        local v = vouchers[Rng.random(#vouchers)]
        table.insert(shop.items, {
            section = "lower_voucher",
            category = "voucher",
            voucherId = v.id,
            name = v.name,
            subtitle = "PHIẾU ĐẶC QUYỀN",
            desc = v.desc,
            cost = v.cost,
            color = v.color,
            icon = "🎟️",
        })
    end

    -- B. Right 1 & Right 2: Gói Bài Booster Packs (7 loại Gói Bài Balatro)
    local packCatalog = {
        {
            packType = "buffoon",
            name = "GÓI HỘ LINH",
            subtitle = "BUFFOON PACK",
            desc = "Mở gói gồm 3 Hộ Linh. Chọn 1 để sở hữu!",
            cost = 4,
            color = { 0.88, 0.35, 0.35, 1 },
            icon = "🃏",
        },
        {
            packType = "arcana",
            name = "GÓI TRANG BỊ",
            subtitle = "ARCANA PACK",
            desc = "Mở gói bao gồm 3 Trang Bị Khảm. Người chơi chọn 1 để khảm vào bài!",
            cost = 5,
            color = { 0.95, 0.75, 0.25, 1 },
            icon = "💎",
        },
        {
            packType = "standard",
            name = "GÓI QUÂN BÀI",
            subtitle = "STANDARD PACK",
            desc = "Mở gói bao gồm 3 Quân Bài cường hóa. Người chơi chọn 1 đưa vào bộ bài!",
            cost = 4,
            color = { 0.25, 0.60, 0.95, 1 },
            icon = "📦",
        },
        {
            packType = "joker_edition",
            name = "GÓI PHÙ PHÉP HỘ LINH",
            subtitle = "PHÙ PHÉP HỘ LINH",
            desc = "Mở gói gồm 3 phép Aura, Ectoplasm, Ankh hoặc Hex. Chọn 1 để cường hóa Hộ Linh!",
            cost = 6,
            color = { 0.85, 0.40, 0.95, 1 },
            icon = "✨",
        },
        {
            packType = "seal",
            name = "GÓI CON DẤU",
            subtitle = "SEALS PACK",
            desc = "Mở gói gồm 3 Con Dấu (Vàng, Đỏ, Lam, Tím). Chọn 1 để đóng dấu!",
            cost = 6,
            color = { 0.95, 0.70, 0.20, 1 },
            icon = "🔴",
        },
        {
            packType = "spectral",
            name = "GÓI BIẾN ĐỔI",
            subtitle = "SPECTRAL PACK",
            desc = "Mở gói gồm 3 Phép Biến Đổi Dị Thể (Familiar, Cryptid, Immolate...). Chọn 1!",
            cost = 7,
            color = { 0.40, 0.85, 0.85, 1 },
            icon = "🔮",
        },
        {
            packType = "celestial",
            name = "GÓI HÀNH TINH",
            subtitle = "CELESTIAL PACK",
            desc = "Mở gói gồm 3 Thẻ Hành Tinh nâng cấp Cấp Độ thế bài Poker. Chọn 1!",
            cost = 5,
            color = { 0.35, 0.55, 0.95, 1 },
            icon = "🪐",
        },
    }

    for i = #packCatalog, 2, -1 do
        local j = Rng.random(i)
        packCatalog[i], packCatalog[j] = packCatalog[j], packCatalog[i]
    end

    local pack1 = packCatalog[1]
    local pack2 = packCatalog[2]

    table.insert(shop.items, {
        section = "lower_pack",
        category = "pack",
        packType = pack1.packType,
        name = pack1.name,
        subtitle = pack1.subtitle,
        desc = pack1.desc,
        cost = pack1.cost,
        color = pack1.color,
        icon = pack1.icon,
    })

    if (gameState.playerHp or 100) < 60 and Rng.random() < 0.5 then
        table.insert(shop.items, {
            section = "lower_pack",
            category = "heal",
            name = "BÌNH MÁU THÁNH",
            subtitle = "DƯỢC LIỆU",
            desc = "Uống lập tức hồi phục +25 HP sinh lực cho nhân vật!",
            cost = 4,
            color = { 0.25, 0.85, 0.45, 1 },
            icon = "🧪",
            healAmt = 25,
        })
    else
        table.insert(shop.items, {
            section = "lower_pack",
            category = "pack",
            packType = pack2.packType,
            name = pack2.name,
            subtitle = pack2.subtitle,
            desc = pack2.desc,
            cost = pack2.cost,
            color = pack2.color,
            icon = pack2.icon,
        })
    end
end

function Shop.buyItem(shop, itemIndex, gameState)
    local item = shop.items[itemIndex]
    if not item then return false, "Vật phẩm không tồn tại!" end

    if (gameState.gold or 0) < item.cost then
        Sound.play("cant_afford")
        return false, "Không đủ tiền vàng!"
    end

    if item.category == "deity" then
        local maxSlots = Deities.getMaxSlots(gameState)
        if Deities.getCount(gameState.deities) >= maxSlots then
            Sound.play("cant_afford")
            return false, "Đã đầy " .. maxSlots .. " Hộ Linh! Hãy bán bớt một Hộ Linh trước khi mua mới."
        end
        gameState.gold = gameState.gold - item.cost
        Deities.addDeity(gameState, item.deity)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã chiêu mộ: " .. item.deity.name .. "!"

    elseif item.category == "hand_expansion" then
        local curH = gameState.maxHandSize or 3
        if curH >= 5 then
            Sound.play("cant_afford")
            return false, "Kích thước tay bài đã đạt tối đa (5 lá)!"
        end
        gameState.gold = gameState.gold - item.cost
        gameState.maxHandSize = curH + 1
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã mở rộng kích thước tay bài lên tối đa " .. gameState.maxHandSize .. " lá!"

    elseif item.category == "book" then
        gameState.gold = gameState.gold - item.cost
        gameState.unlockedHands[item.handId] = true
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã mở khóa bí tịch: " .. item.name .. "!"

    elseif item.category == "voucher" then
        gameState.gold = gameState.gold - item.cost
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        gameState.vouchers = gameState.vouchers or {}
        gameState.vouchers[item.voucherId] = true
        if item.voucherId == "v_discount" then
            shop.baseRerollCost = math.max(1, (shop.baseRerollCost or 5) - 2)
            shop.rerollCost = math.max(1, shop.rerollCost - 2)
        elseif item.voucherId == "v_interest" then
            gameState.maxInterest = 10
            gameState.hasSeedMoney = true
        elseif item.voucherId == "v_hand_plus" then
            gameState.maxHands = (gameState.maxHands or 4) + 1
            gameState.handsRemaining = (gameState.handsRemaining or 4) + 1
        elseif item.voucherId == "v_hand_size" then
            gameState.maxHandSize = (gameState.maxHandSize or 3) + 1
        end
        return true, "Đã kích hoạt đặc quyền: " .. item.name .. "!"

    elseif item.category == "equipment" then
        gameState.gold = gameState.gold - item.cost
        local eq = item.equipment
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "open_socketing", eq

    elseif item.category == "card" then
        gameState.gold = gameState.gold - item.cost
        Deck.addCardToDeck(gameState, item.card)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã thêm lá " .. item.card.rankName .. item.card.suitSymbol .. " vào bộ bài!"

    elseif item.category == "pack" then
        gameState.gold = gameState.gold - item.cost
        local pack = item
        table.remove(shop.items, itemIndex)
        Sound.play("pack_open")
        local packData = Shop.openPack(pack, gameState)
        shop.currentPackOpening = packData
        return true, "open_pack", packData

    elseif item.category == "heal" then
        gameState.gold = gameState.gold - item.cost
        local healVal = item.healAmt or 25
        gameState.playerHp = math.min(gameState.maxPlayerHp or 100, (gameState.playerHp or 100) + healVal)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã hồi phục +" .. healVal .. " HP sinh lực!"

    elseif item.category == "consumable" then
        gameState.gold = gameState.gold - item.cost
        if item.apply then item.apply(gameState) end
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã kích hoạt Phù Chú Tiếp Lực!"
    end

    return false, "Vật phẩm không hợp lệ"
end

function Shop.openPack(packItem, gameState)
    local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"
    local candidates = {}

    if packItem.packType == "buffoon" then
        candidates = Deities.getRandomShopPool(gameState.deities, 3)

    elseif packItem.packType == "standard" then
        local enhList = { "enh_armor", "enh_blood", "enh_overcharged", "enh_cursed", "enh_brittle", "enh_escort", "enh_harmonic", "enh_boss_hunter" }
        for i = 1, 3 do
            local c = Deck.createRewardCard(userFaction)
            if Rng.random(100) <= 70 then
                c.enhancement = enhList[Rng.random(#enhList)]
            end
            table.insert(candidates, c)
        end

    elseif packItem.packType == "arcana" then
        for i = 1, 3 do
            table.insert(candidates, Equipment.getRandomEquipment())
        end

    elseif packItem.packType == "joker_edition" then
        local spells = {
            {
                id = "spell_aura",
                name = "Aura",
                subtitle = "HÀO QUANG",
                desc = "Thêm Foil (+50c), Holo (+10m), hoặc Polychrome (x1.5m) cho 1 Thần ngẫu nhiên!",
                icon = "✨",
                color = { 0.95, 0.85, 0.35, 1 },
            },
            {
                id = "spell_ectoplasm",
                name = "Ectoplasm",
                subtitle = "NGOẠI CHẤT",
                desc = "Thêm Negative (+1 Slot Thần) cho 1 Thần ngẫu nhiên, đổi lại giảm -1 Hand Size!",
                icon = "👻",
                color = { 0.35, 0.85, 0.55, 1 },
            },
            {
                id = "spell_ankh",
                name = "Ankh",
                subtitle = "THÁNH GIÁ",
                desc = "Sao chép 1 Thần ngẫu nhiên và hủy diệt toàn bộ các Thần còn lại!",
                icon = "☥",
                color = { 0.95, 0.75, 0.25, 1 },
            },
            {
                id = "spell_hex",
                name = "Hex",
                subtitle = "LỜI NGUYỀN",
                desc = "Thêm Polychrome (x1.5 Mult) cho 1 Thần ngẫu nhiên và hủy diệt toàn bộ các Thần còn lại!",
                icon = "🔮",
                color = { 0.85, 0.25, 0.45, 1 },
            },
        }
        for i = #spells, 2, -1 do
            local j = Rng.random(i)
            spells[i], spells[j] = spells[j], spells[i]
        end
        for i = 1, 3 do table.insert(candidates, spells[i]) end

    elseif packItem.packType == "seal" then
        local seals = {
            {
                id = "seal_blood",
                sealType = "seal_blood",
                sealName = "Ấn Huyết",
                name = "Ấn Huyết (Blood)",
                subtitle = "ẤN HUYẾT",
                desc = "+50% Sát thương khi máu người chơi < 50%!",
                icon = "🩸",
                color = { 0.90, 0.15, 0.15, 1 },
            },
            {
                id = "seal_prophecy",
                sealType = "seal_prophecy",
                sealName = "Ấn Tiên Tri",
                name = "Ấn Tiên Tri (Prophecy)",
                subtitle = "ẤN TIÊN TRI",
                desc = "Khi ghi điểm, nhìn thấy Intent tiếp theo của Boss!",
                icon = "🔮",
                color = { 0.30, 0.60, 0.95, 1 },
            },
            {
                id = "seal_ashen",
                sealType = "seal_ashen",
                sealName = "Ấn Tro Tàn",
                name = "Ấn Tro Tàn (Ashen)",
                subtitle = "ẤN TRO TÀN",
                desc = "Tự thiêu hủy lá này sau khi đánh, gây 40 Sát thương Chuẩn vào Quái!",
                icon = "🔥",
                color = { 0.60, 0.55, 0.50, 1 },
            },
            {
                id = "seal_bounty",
                sealType = "seal_bounty",
                sealName = "Ấn Truy Nã",
                name = "Ấn Truy Nã (Bounty)",
                subtitle = "ẤN TRUY NÃ",
                desc = "Nếu lá này kết liễu Quái, thưởng ngay +$2 Vàng!",
                icon = "💰",
                color = { 0.95, 0.80, 0.25, 1 },
            },
            {
                id = "seal_anchor",
                sealType = "seal_anchor",
                sealName = "Ấn Neo",
                name = "Ấn Neo (Anchor)",
                subtitle = "ẤN NEO",
                desc = "Lá này luôn nằm trên tay khi bắt đầu lượt (không bị xáo vào cọc)!",
                icon = "⚓",
                color = { 0.20, 0.70, 0.60, 1 },
            },
            {
                id = "seal_purifying",
                sealType = "seal_purifying",
                sealName = "Ấn Thanh Tẩy",
                name = "Ấn Thanh Tẩy (Purifying)",
                subtitle = "ẤN THANH TẨY",
                desc = "Xóa bỏ 1 trạng thái bất lợi (debuff) trên bản thân khi kích hoạt!",
                icon = "✨",
                color = { 0.85, 0.85, 0.95, 1 },
            },
        }
        for i = #seals, 2, -1 do
            local j = Rng.random(i)
            seals[i], seals[j] = seals[j], seals[i]
        end
        for i = 1, 3 do table.insert(candidates, seals[i]) end

    elseif packItem.packType == "spectral" then
        local spectrals = {
            { id = "spec_familiar", name = "Familiar", subtitle = "LINH THÚ", desc = "Hủy 1 lá ngẫu nhiên trên tay, thêm 3 lá Hoàng Gia (J, Q, K) có trang bị vào bộ bài!", icon = "🦉", color = { 0.65, 0.45, 0.85, 1 } },
            { id = "spec_grim", name = "Grim", subtitle = "TỬ THẦN", desc = "Hủy 1 lá ngẫu nhiên trên tay, thêm 2 lá Át (A) có trang bị vào bộ bài!", icon = "💀", color = { 0.85, 0.30, 0.40, 1 } },
            { id = "spec_incantation", name = "Incantation", subtitle = "CHÚ THUẬT", desc = "Hủy 1 lá ngẫu nhiên trên tay, thêm 4 lá Quân Số (2-10) có trang bị vào bộ bài!", icon = "🕯️", color = { 0.95, 0.60, 0.30, 1 } },
            { id = "spec_cryptid", name = "Cryptid", subtitle = "DỊ THỂ", desc = "Nhân bản 1 lá bài đã chọn trên tay thành 2 bản sao y hệt!", icon = "👥", color = { 0.40, 0.75, 0.95, 1 } },
            { id = "spec_immolate", name = "Immolate", subtitle = "THIÊU RỤI", desc = "Hủy diệt tối đa 5 lá bài ngẫu nhiên trên tay, lập tức nhận +$20 Tiền Vàng!", icon = "🔥", color = { 0.95, 0.40, 0.20, 1 } },
            { id = "spec_sigil", name = "Sigil", subtitle = "ẤN KÝ", desc = "Biến đổi toàn bộ các lá bài trên tay thành cùng 1 chất ngẫu nhiên (♠, ♥, ♦, ♣)!", icon = "🔯", color = { 0.50, 0.85, 0.65, 1 } },
            { id = "spec_ouija", name = "Ouija", subtitle = "CẦU CƠ", desc = "Biến đổi toàn bộ các lá bài trên tay thành cùng 1 Cấp Số ngẫu nhiên, giảm -1 Hand Size!", icon = "👁️", color = { 0.75, 0.35, 0.85, 1 } },
            { id = "spec_black_hole", name = "Black Hole", subtitle = "HỐ ĐEN", desc = "Tăng Cấp Độ của TẤT CẢ các thế bài Poker lên +1 Cấp (Level)!", icon = "🕳️", color = { 0.30, 0.30, 0.45, 1 } },
        }
        for i = #spectrals, 2, -1 do
            local j = Rng.random(i)
            spectrals[i], spectrals[j] = spectrals[j], spectrals[i]
        end
        for i = 1, 3 do table.insert(candidates, spectrals[i]) end

    elseif packItem.packType == "celestial" then
        local planets = {}
        for _, p in ipairs(Poker.PLANET_CARDS) do table.insert(planets, p) end
        for i = #planets, 2, -1 do
            local j = Rng.random(i)
            planets[i], planets[j] = planets[j], planets[i]
        end
        for i = 1, 3 do table.insert(candidates, planets[i]) end
    end

    return {
        pack = packItem,
        cards = candidates,
    }
end

function Shop.choosePackCard(shop, chosenIndex, gameState)
    if not shop.currentPackOpening then return false end
    local pack = shop.currentPackOpening.pack
    local card = shop.currentPackOpening.cards and shop.currentPackOpening.cards[chosenIndex]
    if not card then return false end

    local function getTargetCard()
        if gameState.selectedIndices and #gameState.selectedIndices > 0 and gameState.hand and gameState.hand[gameState.selectedIndices[1]] then
            return gameState.hand[gameState.selectedIndices[1]]
        end
        if gameState.hand and #gameState.hand > 0 then
            return gameState.hand[1]
        end
        if gameState.persistentDeck and #gameState.persistentDeck > 0 then
            return gameState.persistentDeck[1]
        end
        return nil
    end

    if pack.packType == "buffoon" then
        local maxSlots = Deities.getMaxSlots(gameState)
        if Deities.getCount(gameState.deities) >= maxSlots then
            Sound.play("cant_afford")
            return false, "Đã đầy " .. maxSlots .. " Hộ Linh!"
        end
        Deities.addDeity(gameState, card)
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "Đã chiêu mộ: " .. card.name .. "!"

    elseif pack.packType == "standard" then
        Deck.addCardToDeck(gameState, card)
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "Đã thêm lá " .. card.rankName .. card.suitSymbol .. " vào bộ bài!"

    elseif pack.packType == "arcana" then
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "open_socketing", card

    elseif pack.packType == "joker_edition" then
        local deityList = {}
        for di = 1, 10 do
            if gameState.deities and gameState.deities[di] then
                table.insert(deityList, { slot = di, deity = gameState.deities[di] })
            end
        end

        if card.id == "spell_aura" then
            if #deityList == 0 then
                Sound.play("cant_afford")
                return false, "Không có Hộ Linh nào để phù phép!"
            end
            local chosen = deityList[Rng.random(#deityList)]
            local edPool = { "foil", "holo", "polychrome" }
            chosen.deity.edition = edPool[Rng.random(#edPool)]
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Aura: Thần [" .. chosen.deity.name .. "] nhận hiệu ứng " .. chosen.deity.edition:upper() .. "!"

        elseif card.id == "spell_ectoplasm" then
            if #deityList == 0 then
                Sound.play("cant_afford")
                return false, "Không có Hộ Linh nào!"
            end
            local chosen = deityList[Rng.random(#deityList)]
            chosen.deity.edition = "negative"
            gameState.maxHandSize = math.max(1, (gameState.maxHandSize or 3) - 1)
            Sound.play("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Ectoplasm: Thần [" .. chosen.deity.name .. "] nhận NEGATIVE (+1 Ô Thần), Hand Size giảm còn " .. gameState.maxHandSize .. "!"

        elseif card.id == "spell_ankh" then
            if #deityList == 0 then
                Sound.play("cant_afford")
                return false, "Không có Hộ Linh nào!"
            end
            local chosen = deityList[Rng.random(#deityList)]
            local cloned = {}
            for k, v in pairs(chosen.deity) do cloned[k] = v end
            -- Clear all other slots and put two copies in slots 1 and 2
            gameState.deities = { [1] = chosen.deity, [2] = cloned }
            Sound.play("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Ankh: Nhân bản [" .. cloned.name .. "] và hủy diệt toàn bộ các Thần còn lại!"

        elseif card.id == "spell_hex" then
            if #deityList == 0 then
                Sound.play("cant_afford")
                return false, "Không có Hộ Linh nào!"
            end
            local chosen = deityList[Rng.random(#deityList)]
            chosen.deity.edition = "polychrome"
            local kept = chosen.deity
            gameState.deities = { [1] = kept }
            Sound.play("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Hex: Thần [" .. kept.name .. "] nhận POLYCHROME (x1.5 Mult) và hủy diệt toàn bộ các Thần còn lại!"
        end

    elseif pack.packType == "seal" then
        local targetCard = getTargetCard()
        if not targetCard then
            Sound.play("cant_afford")
            return false, "Không tìm thấy lá bài để đóng dấu!"
        end
        targetCard.seal = card.sealType
        if gameState.persistentDeck then
            for _, pc in ipairs(gameState.persistentDeck) do
                if pc.id == targetCard.id then
                    pc.seal = card.sealType
                    break
                end
            end
        end
        Sound.play("shop_buy")
        shop.currentPackOpening = nil
        return true, "Đã đóng ấn [" .. (card.sealName or card.subtitle or card.name) .. "] lên lá " .. (targetCard.rankName or "") .. (targetCard.suitSymbol or "") .. "!"

    elseif pack.packType == "spectral" then
        local userFaction = gameState.selectedFaction or gameState.selectedSuit or "aurelia"
        if card.id == "spec_familiar" then
            if gameState.hand and #gameState.hand > 0 then
                table.remove(gameState.hand, Rng.random(#gameState.hand))
            end
            if gameState.persistentDeck and #gameState.persistentDeck > 0 then
                table.remove(gameState.persistentDeck, Rng.random(#gameState.persistentDeck))
            end
            local ranks = { 11, 12, 13 }
            for i = 1, 3 do
                local r = ranks[i]
                local nc = Deck.newCard(r, userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(gameState, nc)
            end
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Familiar: Hủy 1 lá, thêm 3 lá Hoàng Gia (J, Q, K) có trang bị vào bộ bài!"

        elseif card.id == "spec_grim" then
            if gameState.hand and #gameState.hand > 0 then
                table.remove(gameState.hand, Rng.random(#gameState.hand))
            end
            if gameState.persistentDeck and #gameState.persistentDeck > 0 then
                table.remove(gameState.persistentDeck, Rng.random(#gameState.persistentDeck))
            end
            for i = 1, 2 do
                local nc = Deck.newCard(14, userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(gameState, nc)
            end
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Grim: Hủy 1 lá, thêm 2 lá Át (A) có trang bị vào bộ bài!"

        elseif card.id == "spec_incantation" then
            if gameState.hand and #gameState.hand > 0 then
                table.remove(gameState.hand, Rng.random(#gameState.hand))
            end
            if gameState.persistentDeck and #gameState.persistentDeck > 0 then
                table.remove(gameState.persistentDeck, Rng.random(#gameState.persistentDeck))
            end
            for i = 1, 4 do
                local r = Rng.random(2, 10)
                local nc = Deck.newCard(r, userFaction)
                nc.equipments = { Equipment.getRandomEquipment() }
                Deck.addCardToDeck(gameState, nc)
            end
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Incantation: Hủy 1 lá, thêm 4 lá Quân Số (2-10) có trang bị vào bộ bài!"

        elseif card.id == "spec_cryptid" then
            local targetCard = getTargetCard()
            if not targetCard then
                Sound.play("cant_afford")
                return false, "Không tìm thấy lá bài để nhân bản!"
            end
            local clone1 = Deck.cloneCard(targetCard)
            clone1.id = "card_" .. tostring(Rng.random(100000, 999999))
            local clone2 = Deck.cloneCard(targetCard)
            clone2.id = "card_" .. tostring(Rng.random(100000, 999999))
            Deck.addCardToDeck(gameState, clone1)
            Deck.addCardToDeck(gameState, clone2)
            if gameState.hand then
                table.insert(gameState.hand, clone1)
                table.insert(gameState.hand, clone2)
            end
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Cryptid: Tạo 2 bản sao của lá " .. (targetCard.rankName or "") .. (targetCard.suitSymbol or "") .. "!"

        elseif card.id == "spec_immolate" then
            local destroyed = 0
            while gameState.hand and #gameState.hand > 0 and destroyed < 5 do
                table.remove(gameState.hand, 1)
                destroyed = destroyed + 1
            end
            if gameState.persistentDeck then
                local dDeck = 0
                while #gameState.persistentDeck > 3 and dDeck < destroyed do
                    table.remove(gameState.persistentDeck, 1)
                    dDeck = dDeck + 1
                end
            end
            gameState.gold = (gameState.gold or 0) + 20
            Sound.play("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Immolate: Thiêu rụi " .. destroyed .. " lá, nhận ngay +$20 Tiền Vàng!"

        elseif card.id == "spec_sigil" then
            local suits = Deck.SUIT_ORDER
            local targetSuit = suits[Rng.random(#suits)]
            local fInfo = Deck.SUITS[targetSuit]
            if gameState.hand then
                for _, c in ipairs(gameState.hand) do
                    c.suit = targetSuit
                    c.suitName = Deck.STANDARD_SUIT_NAMES[targetSuit] or fInfo.name
                    c.suitSymbol = fInfo.symbol
                    c.color = fInfo.color
                end
            end
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Sigil: Toàn bộ bài trên tay biến đổi thành Chất " .. (Deck.STANDARD_SUIT_NAMES[targetSuit] or fInfo.name) .. " (" .. fInfo.symbol .. ")!"

        elseif card.id == "spec_ouija" then
            local r = Rng.random(2, 14)
            local rName = Deck.RANK_NAMES[r] or tostring(r)
            if gameState.hand then
                for _, c in ipairs(gameState.hand) do
                    c.rank = r
                    c.rankName = rName
                    c.baseChips = Deck.getChipValue(r)
                end
            end
            gameState.maxHandSize = math.max(1, (gameState.maxHandSize or 3) - 1)
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Ouija: Toàn bộ bài trên tay biến đổi thành Rank " .. rName .. ", Hand Size giảm còn " .. gameState.maxHandSize .. "!"

        elseif card.id == "spec_black_hole" then
            gameState.handLevels = gameState.handLevels or {}
            for _, ht in pairs(Poker.HAND_TYPES) do
                gameState.handLevels[ht.id] = (gameState.handLevels[ht.id] or 1) + 1
            end
            Sound.play("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Black Hole: Tất cả các thế bài Poker tăng +1 Cấp độ!"
        end

    elseif pack.packType == "celestial" then
        gameState.handLevels = gameState.handLevels or {}
        if card.handId == "random" or card.id == "planet_supernova" or card.id == "supernova" then
            local allHands = {}
            for _, ht in pairs(Poker.HAND_TYPES) do table.insert(allHands, ht) end
            local h = allHands[Rng.random(#allHands)]
            gameState.handLevels[h.id] = (gameState.handLevels[h.id] or 1) + 3
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Siêu Tân Tinh: Nâng cấp " .. h.vnName .. " lên +3 Cấp (Cấp " .. gameState.handLevels[h.id] .. ")!"
        elseif card.handId == "all" or card.id == "planet_black_hole" or card.id == "black_hole" then
            for _, ht in pairs(Poker.HAND_TYPES) do
                gameState.handLevels[ht.id] = (gameState.handLevels[ht.id] or 1) + 1
            end
            Sound.play("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Hố Đen: Nâng cấp TẤT CẢ các thế bài Poker lên +1 Cấp độ!"
        elseif card.handId then
            gameState.handLevels[card.handId] = (gameState.handLevels[card.handId] or 1) + 1
            local hType = nil
            for _, ht in pairs(Poker.HAND_TYPES) do if ht.id == card.handId then hType = ht break end end
            local vName = hType and hType.vnName or card.name
            Sound.play("round_win")
            shop.currentPackOpening = nil
            return true, "Đã nâng cấp thế bài " .. vName .. " lên Cấp " .. gameState.handLevels[card.handId] .. "!"
        end
    end

    shop.currentPackOpening = nil
    return true
end

function Shop.keepPackCard(shop, chosenIndex, gameState)
    if not shop.currentPackOpening then return false, "Không có gói bài nào đang mở!" end
    local pack = shop.currentPackOpening.pack
    local card = shop.currentPackOpening.cards and shop.currentPackOpening.cards[chosenIndex]
    if not card then return false, "Lá bài không hợp lệ!" end

    local validPacks = {
        joker_edition = "joker_spell",
        seal = "seal",
        spectral = "spectral",
        celestial = "celestial"
    }
    local cat = validPacks[pack.packType]
    if not cat then
        return false, "Chỉ có thể cất giữ Thẻ Phép & Hành Tinh vào Ô Tiêu Hao!"
    end

    gameState.consumables = gameState.consumables or {}
    if #gameState.consumables >= 3 then
        Sound.play("cant_afford")
        return false, "Ô tiêu hao đã đầy (3/3)!"
    end

    local storedCard = {}
    for k, v in pairs(card) do storedCard[k] = v end
    storedCard.category = cat

    table.insert(gameState.consumables, storedCard)
    Sound.play("shop_buy")
    shop.currentPackOpening = nil
    return true, "Đã cất [" .. (storedCard.name or "Thẻ Phép") .. "] vào Ô Tiêu Hao!"
end

function Shop.skipPack(shop)
    shop.currentPackOpening = nil
    Sound.play("ui_click")
end

function Shop.reroll(shop, gameState)
    if gameState and (gameState.freeRerolls or 0) > 0 then
        gameState.freeRerolls = gameState.freeRerolls - 1
        Shop.refresh(shop, gameState)
        Sound.play("shop_reroll")
        return true
    end
    local cost = shop.rerollCost or 5
    if (gameState.gold or 0) < cost then
        Sound.play("cant_afford")
        return false, "Không đủ tiền làm mới!"
    end
    gameState.gold = gameState.gold - cost
    shop.rerollCount = (shop.rerollCount or 0) + 1
    shop.rerollCost = cost + 1 + shop.rerollCount
    Shop.refresh(shop, gameState)
    Sound.play("shop_reroll")
    return true
end

function Shop.sellDeity(gameState, deityIndex)
    local d = gameState.deities and gameState.deities[deityIndex]
    if not d then return false end
    local sellPrice = math.max(1, math.floor((d.cost or 4) / 2))
    gameState.gold = (gameState.gold or 0) + sellPrice
    gameState.deities[deityIndex] = nil
    Sound.play("chip_tick")
    return true
end

function Shop.transferEquipment(sourceCard, eqIndex, targetCard)
    if not sourceCard or not targetCard then return false, "Chưa chọn đủ bài nguồn và đích!" end
    if sourceCard == targetCard then return false, "Không thể chuyển vào cùng một lá bài!" end
    if not sourceCard.equipments or not sourceCard.equipments[eqIndex] then
        return false, "Trang bị không tồn tại!"
    end
    local eq = sourceCard.equipments[eqIndex]
    local canOk, canErr = Equipment.canAttach(targetCard, eq)
    if not canOk then
        return false, canErr
    end

    table.remove(sourceCard.equipments, eqIndex)
    targetCard.equipments = targetCard.equipments or {}
    table.insert(targetCard.equipments, eq)
    Sound.play("round_win")
    return true, "Đã chuyển [" .. eq.name .. "] sang Lá " .. (targetCard.rankName or "") .. (targetCard.suitSymbol or "") .. "!"
end

return Shop

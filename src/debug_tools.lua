local Deck = require("src.deck")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Shop = require("src.shop")
local RunManager = require("src.run_manager")

local DebugTools = {}
local MAX_GOLD = 9007199254740991 -- Largest integer exactly representable by Lua's double numbers.

function DebugTools.setGold(game, value)
    local n = tonumber(value)
    if not n or n < 0 or n > MAX_GOLD or n ~= math.floor(n) then
        return false, "Nhập số vàng nguyên từ 0 đến 9007199254740991."
    end
    game.gold = n
    return true, "Đã đặt vàng: $" .. n
end

function DebugTools.addGold(game, value)
    local n = tonumber(value)
    if not n or n < 0 or n ~= math.floor(n) or (game.gold or 0) + n > MAX_GOLD then
        return false, "Số vàng không hợp lệ."
    end
    game.gold = (game.gold or 0) + n
    return true, "Đã cộng +$" .. n
end

function DebugTools.setAnte(game, value, blindIndex)
    local ante = tonumber(value)
    if not ante or ante < 1 or ante > 999 or ante ~= math.floor(ante) then
        return false, "Ante phải là số nguyên từ 1 đến 999."
    end
    if not game.run then game.run = RunManager.newRun(game.selectedFaction) end
    game.run.ante = ante
    game.run.maxAnte = math.max(RunManager.MAX_ANTE, ante)
    game.run.endless = ante > RunManager.MAX_ANTE
    game.run.victory = false
    game.run.currentBlindIndex = math.max(1, math.min(3, blindIndex or 1))
    game.run.shopsVisitedInAnte = 0
    game.run.blinds = RunManager.generateAnteBlinds(ante, game.selectedFaction)
    for i = 1, 3 do
        game.run.blinds[i].status = i < game.run.currentBlindIndex and "completed" or
            (i == game.run.currentBlindIndex and "current" or "upcoming")
    end
    game.currentBlind = nil
    game.monster = nil
    return true, "Đã chuyển đến Ante " .. ante .. ", Blind " .. game.run.currentBlindIndex
end

function DebugTools.grantCollectionItem(game, shop, category, item, targetCard)
    if not item then return false, "Chưa chọn vật phẩm." end
    local id = item.id
    if category == "jokers" then
        local deity = Deities.CATALOG[id]
        if not deity or not Deities.addDeity(game, deity) then return false, "Không còn ô Hộ Linh trống." end
        return true, "Đã nhận Hộ Linh: " .. item.name
    elseif category == "consumables" then
        local equipment = Equipment.ITEMS[id]
        if not equipment then return false, "Không tìm thấy trang bị." end
        return true, "socketing", equipment
    elseif category == "vouchers" then
        shop.items = shop.items or {}
        shop.items[#shop.items + 1] = { category = "voucher", voucherId = id, cost = 0, name = item.name }
        local ok, message = Shop.buyItem(shop, #shop.items, game)
        if not ok then table.remove(shop.items) end
        return ok, message
    elseif category == "enhancements" or category == "seals" or category == "editions" then
        if not targetCard then return false, "Bộ bài chưa có lá để áp dụng." end
        if category == "enhancements" then targetCard.enhancement = id
        elseif category == "seals" then targetCard.seal = id
        else targetCard.edition = ({ ed_base = "base", ed_foil = "foil", ed_holo = "holo", ed_poly = "polychrome" })[id] end
        return true, "Đã áp dụng " .. item.name .. " lên " .. (targetCard.rankName or "lá bài") .. (targetCard.suitSymbol or "")
    elseif category == "packs" then
        if not item.isPackContent then return true, "pack", item.packType end
        local packType = item.packType
        local reward
        for _, candidate in ipairs(Shop.getPackContents(packType)) do
            if candidate.name == item.name or (candidate.rank == item.rank and candidate.suit == item.suit and item.rank) then
                reward = candidate
                break
            end
        end
        if not reward then return false, "Không tìm thấy nội dung gói." end
        if packType == "standard" then
            local card = Deck.newCard(reward.rank, reward.suit)
            Deck.addCardToDeck(game, card)
            return true, "Đã nhận quân bài " .. item.name
        elseif packType == "buffoon" then
            if not Deities.addDeity(game, reward) then return false, "Không còn ô Hộ Linh trống." end
            return true, "Đã nhận " .. item.name
        elseif packType == "arcana" then
            return true, "socketing", Equipment.ITEMS[reward.id]
        elseif packType == "seal" then
            if not targetCard then return false, "Bộ bài chưa có lá để đóng dấu." end
            targetCard.seal = reward.sealType
            return true, "Đã đóng " .. reward.name .. " lên " .. (targetCard.rankName or "lá bài") .. (targetCard.suitSymbol or "")
        end
        -- Use the same effect handler as a real pack opening, including its trade-offs.
        local opening = { currentPackOpening = { pack = { packType = packType }, cards = { reward } } }
        local ok, result = Shop.choosePackCard(opening, 1, game)
        return ok, result or (ok and "Đã dùng " .. item.name or "Không thể dùng vật phẩm này.")
    elseif category == "other" then
        game.unlockedHands = game.unlockedHands or {}
        game.unlockedHands[item.handId or id] = true
        return true, "Đã mở khóa thế đánh " .. item.name
    elseif category == "tags" then
        for _, pact in ipairs(RunManager.SKIP_PACTS) do
            if pact.id == id then
                return true, "Đã kích hoạt khế ước " .. item.name .. ": " .. tostring(pact.apply(game))
            end
        end
        return false, "Không tìm thấy khế ước."
    elseif category == "blinds" then
        return true, "blind", id
    elseif category == "decks" then
        return false, "Bộ bài khởi đầu được chọn khi tạo ván mới."
    end
    return false, "Mục này chưa thể nhận."
end

return DebugTools

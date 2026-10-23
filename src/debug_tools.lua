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

function DebugTools.validateAnte(value, blindIndex, regionId)
    local ante = tonumber(value)
    if not ante or ante < 1 or ante > 999 or ante ~= math.floor(ante) then
        return false, "Ante phải là số nguyên từ 1 đến 999."
    end
    local index = tonumber(blindIndex or 1)
    if not index or index < 1 or index > 3 or index ~= math.floor(index) then
        return false, "Trận đấu phải từ 1 đến 3."
    end
    if regionId and not require("src.expedition").byId[regionId] then
        return false, "Vùng không hợp lệ."
    end
    return true, ante, index
end

function DebugTools.setAnte(game, value, blindIndex, regionId)
    local ok, ante, index = DebugTools.validateAnte(value, blindIndex, regionId)
    if not ok then return false, ante end
    if not game.run then game.run = RunManager.newRun(game.selectedFaction) end
    game.run.ante = ante
    game.round = ante
    game.run.maxAnte = math.max(RunManager.MAX_ANTE, ante)
    game.run.endless = ante > RunManager.MAX_ANTE
    game.run.travelPermit = false
    game.run.difficultyCap=nil
    local E=require("src.expedition")
    game.run.regionId=regionId or game.run.regionId or E.region(ante).id
    game.run.areaStage=game.run.regionId=="unknown" and ante or ((ante-1)%20)+1
    game.run.regionStartAnte=ante-game.run.areaStage+1
    game.run.victory = false
    game.run.currentBlindIndex = index
    game.run.shopsVisitedInAnte = 0
    game.run.blinds = RunManager.generateAnteBlinds(ante, game.selectedFaction,game.run.regionId,game.run.areaStage)
    for i = 1, 3 do
        game.run.blinds[i].status = i < game.run.currentBlindIndex and "completed" or
            (i == game.run.currentBlindIndex and "current" or "upcoming")
    end
    game.currentBlind = RunManager.getCurrentBlind(game.run)
    game.monster = nil
    game.enemies = nil
    return true, "Đã chuyển đến Ante " .. ante .. ", Blind " .. game.run.currentBlindIndex
end

function DebugTools.clearScene(game)
    -- Keep owned cards/resources; discard pending actions from the abandoned scene.
    for _, key in ipairs({"currentNodeId", "currentEvent", "eventOutcomeText", "monster", "enemies",
        "pendingVictoryReward", "pendingRoundRewardChoice", "pendingRewardEquipment", "pendingShopEquipment",
        "pendingSoulShop", "pendingBloodShop", "pendingBarter", "barterEvent", "voidEvent", "pendingAncientStatue", "ancientStatue", "bloodDomain",
        "pendingMemoryMatch", "memoryMatch",
        "pendingTrainingCamp", "trainingCamp",
        "soulDestroyConsumable", "potionVictoryPending", "abilityCombat", "abilityHand", "bossCombat",
        "spnAttack", "enemyActed", "enemyActionPhases", "advancedCombat", "advancedHand"}) do game[key] = nil end
    game.soulDestroyActive = false
    game.bloodShopNotice = nil
    game.potionCombat = {}
    game.hand, game.deck, game.discardPile, game.selectedIndices = {}, {}, {}, {}
    game.bossDeityDraft = {}
    game.rewardPacks = {}
    game.playerArmor, game.playerShield, game.enemyPoison = 0, 0, 0
    if game.persistentDeck then Deck.restoreDeck(game.persistentDeck); game.masterDeck = game.persistentDeck end
end

function DebugTools.grantCollectionItem(game, shop, category, item, targetCard)
    if not item then return false, "Chưa chọn vật phẩm." end
    local id = item.id
    if category == "playing_cards" then
        if not item.rank or not item.suit then return false, "Quân bài không hợp lệ." end
        Deck.addCardToDeck(game, Deck.newCard(item.rank, item.suit))
        return true, "Đã nhận quân bài " .. item.name
    elseif category == "jokers" then
        local deity = Deities.CATALOG[id]
        if not deity then return false,"Không tìm thấy SPN." end
        require("src.loadout").storeDeity(game,deity)
        return true, "Đã nhận Hộ Linh: " .. item.name
    elseif category == "equipment" then
        local equipment = Equipment.ITEMS[id]
        if not equipment then return false, "Không tìm thấy trang bị." end
        return true, "socketing", equipment
    elseif category == "consumables" then
        local card = {}
        for key, value in pairs(item.consumable or item) do card[key] = value end
        require("src.loadout").storeConsumable(game,card)
        return true, "Đã nhận " .. item.name
    elseif category == "vouchers" then
        local grant = Shop.new()
        grant.items = {{ category = "voucher", voucherId = id, cost = 0, name = item.name }}
        grant.baseRerollCost, grant.rerollCost = shop.baseRerollCost or 5, shop.rerollCost or 5
        local ok, message = Shop.buyItem(grant, 1, game)
        if ok then
            shop.baseRerollCost, shop.rerollCost = grant.baseRerollCost, grant.rerollCost
            Shop.applyVoucherStock(shop, game)
        end
        return ok, message
    elseif category == "enhancements" or category == "seals" or category == "editions" then
        if not targetCard then return false, "Bộ bài chưa có lá để áp dụng." end
        local effect = item.edition or ({ ed_foil = "foil", ed_holo = "holographic", ed_poly = "polychrome" })[id]
            or id:match("^edition_(.+)$")
        if category == "editions" and id ~= "ed_base" and not require("src.card_effects").getDefinition(effect) then
            return false, "Ấn bản không hợp lệ."
        end
        require("src.chest_expansion").sync(game, targetCard, function(card)
            if category == "enhancements" then card.enhancement = id
            elseif category == "seals" then card.seal = id
            else require("src.card_effects").setEffect(card, effect) end
        end)
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
            require("src.loadout").storeDeity(game,reward)
            return true, "Đã nhận " .. item.name
        elseif packType == "arcana" then
            return true, "socketing", Equipment.ITEMS[reward.id]
        elseif packType == "seal" then
            if not targetCard then return false, "Bộ bài chưa có lá để đóng dấu." end
            require("src.chest_expansion").sync(game, targetCard, function(card) card.seal = reward.sealType end)
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
        if not Deck.STARTER_DECKS[id] then return false, "Không tìm thấy bộ bài khởi đầu." end
        return true, "deck", id
    end
    return false, "Mục này chưa thể nhận."
end

return DebugTools

-- lovec.exe . --test-shop-deck-drop: real shop input/render, isolated from saves.
local UI = require("src.ui")
local Shop = require("src.shop")
local Deck = require("src.deck")
local Deities = require("src.deities")
local Surfaces = require("ui.card_surfaces")
local Test = {}
local stage, deadline, index = "start", 0, 0
local cases, current, shop, item, gold, count, size

local function pointer(x, y, action)
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / 1280, h / 720)
    local px, py = (w - 1280 * scale) / 2 + x * scale, (h - 720 * scale) / 2 + y * scale
    love.mouse.setPosition(px, py)
    if action == "press" then love.mousepressed(px, py, 1)
    elseif action == "release" then love.mousereleased(px, py, 1)
    else love.mousemoved(px, py, 0, 0) end
end

local function wait(nextStage, seconds)
    stage, deadline = nextStage, love.timer.getTime() + (seconds or 0.15)
end

local function snapshot(name)
    love.graphics.captureScreenshot(function(data)
        local file = assert(io.open(name, "wb"))
        file:write(data:encode("png"):getString())
        file:close()
    end)
end

local function checkBacks()
    local g = love.graphics
    assert(UI.getCardBackImage() == UI.components.DeckCounter.getImage())
    local function pixels(draw)
        local canvas = g.newCanvas(128, 176)
        g.push("all"); g.setCanvas(canvas); g.clear(); g.origin(); g.setShader()
        UI.CardPhysics.suspend()
        draw()
        UI.CardPhysics.resume()
        g.pop()
        return canvas:newImageData()
    end
    local reference = pixels(function() UI.drawCardBack(0, 0, 128, 176) end)
    local hidden = { faceDown = true, rank = 14, rankName = "A", suit = "spades",
        selected = true, edition = "polychrome", baseChips = 999, seal = "blood",
        name = "MUST NOT APPEAR", desc = "MUST NOT APPEAR", id = "blood_king", rarity = "L" }
    local renderers = {
        function() UI.drawCard(hidden, 0, 0, 128, 176) end,
        function() UI.drawCardFace(hidden, 0, 0, 128, 176) end,
        function() UI.drawPatronCard(hidden, 0, 0, 128, 176) end,
        function() Surfaces.catalog(hidden, 0, 0, 128, 176, "consumables") end,
        function() Surfaces.reward(hidden, 0, 0, 128, 176, "edition") end,
        function() Surfaces.round(hidden, 0, 0, 128, 176) end,
        function() Surfaces.preview(hidden, 0, 0, 128, 176, "jokers") end,
        function() Surfaces.image(hidden, 0, 0, 128, 176, UI.getDeityImage("blood_king")) end,
        function() Surfaces.starter(hidden, 0, 0, 128, 176) end,
    }
    for i, draw in ipairs(renderers) do
        local actual = pixels(draw)
        assert(actual:getString() == reference:getString(), "Face-down renderer leaked face information: " .. i)
    end
    for _, pack in ipairs(Shop.PACK_CATALOG) do
        assert(UI.getPackCardImage(pack.packType, hidden) == UI.getCardBackImage())
    end
    print("[PASS] Shared card back: nine renderers and all pack previews; no names/rank/stats/edition leakage")
end

function Test.update(game, callbacks)
    if love.timer.getTime() < deadline then return end
    if stage == "start" then
        callbacks.startNewGame("red_deck")
        callbacks.openShop()
        checkBacks()
        cases = {
            { category = "card", mode = "click" },
            { category = "card", mode = "outside", x = 650, y = 180 },
            { category = "card", mode = "outside", x = 1170, y = 560 },
            { category = "card", mode = "outside", x = 1022, y = 560 },
            { category = "card", mode = "poor" },
            { category = "deity", mode = "full" },
            { category = "heal", mode = "healthy" },
            { category = "card", mode = "buy" },
            { category = "deity", mode = "buy" },
            { category = "heal", mode = "buy" },
            { category = "hand_expansion", mode = "buy" },
            { category = "voucher", mode = "buy" },
            { category = "equipment", mode = "buy" },
        }
        for _, pack in ipairs(Shop.PACK_CATALOG) do
            cases[#cases + 1] = { category = "pack", mode = "buy", pack = pack }
        end
        wait("setup", 0.3)
    elseif stage == "setup" then
        index = index + 1
        current = cases[index]
        if not current then
            -- Verify the actual combat draw deck and hidden hand/consumable/SPN.
            callbacks.startNewGame("red_deck")
            callbacks.startMonsterEncounter(1, false)
            game.hand[1].faceDown = true
            game.deities = { Deities.getStarterDeity("aurelia") }
            game.deities[1].faceDown = true
            game.consumables = { { id = "test_hidden", faceDown = true, name = "HIDDEN" } }
            wait("combat", 0.4)
            return
        end
        callbacks.closePack()
        callbacks.openShop()
        shop = callbacks.getShopData()
        game.gold, game.playerHp, game.deities = 10000, 50, {}
        if current.pack then
            local p = current.pack
            item = { category = "pack", packType = p.packType, name = p.name, cost = p.cost }
            shop.items = { item }
        else
            item = nil
            for _, candidate in ipairs(shop.items) do
                if candidate.category == current.category then item = candidate; break end
            end
            assert(item, "Missing stock: " .. current.category)
        end
        if current.mode == "poor" then game.gold = 0 end
        if current.mode == "healthy" then game.playerHp = game.maxPlayerHp end
        if current.mode == "full" then
            for n = 1, Deities.getMaxSlots(game) do game.deities[n] = Deities.getStarterDeity("aurelia") end
        end
        gold, count, size = game.gold, #shop.items, #game.persistentDeck
        wait("press", 0.35)
    elseif stage == "press" then
        local visual = assert(UI.CardPhysics.getState(item), "Stock surface missing: " .. current.category)
        pointer(visual.x + visual.w * 0.5, visual.y + visual.h * 0.5, "press")
        assert(UI.CardPhysics.isHeld(item), "Stock must visibly follow the pointer: " .. current.category)
        wait("move", 0.08)
    elseif stage == "move" then
        if current.mode == "click" then
            local visual = UI.CardPhysics.getState(item)
            pointer(visual.x + visual.w * 0.5, visual.y + visual.h * 0.5, "release")
            wait("verify")
        else
            pointer(current.x or 1065, current.y or 555)
            wait("held", 0.12)
        end
    elseif stage == "held" then
        if current.category == "card" and current.mode == "buy" then snapshot("shot_shop_deck_drop.png") end
        wait("release", 0.05)
    elseif stage == "release" then
        pointer(current.x or 1065, current.y or 555, "release")
        wait("verify", 0.3)
    elseif stage == "verify" then
        if current.mode == "buy" then
            assert(game.gold == gold - item.cost, "Charge once at deck drop: " .. current.category)
            assert(#shop.items == count - 1, "Remove purchased stock once")
            if current.category == "card" then assert(#game.persistentDeck == size + 1) end
            if current.category == "deity" then assert(Deities.getCount(game.deities) == 1) end
            if current.category == "heal" then assert(game.playerHp > 50) end
            if current.category == "voucher" then assert(game.vouchers[item.voucherId]) end
            if current.category == "pack" then
                assert(shop.currentPackOpening and shop.currentPackOpening.pack.packType == current.pack.packType)
            end
            pointer(1065, 555, "release")
            assert(game.gold == gold - item.cost and #shop.items == count - 1, "Repeated release must not purchase twice")
        else
            assert(game.gold == gold and #shop.items == count and #game.persistentDeck == size,
                "Invalid drop/click/failed purchase must preserve gold and stock: " .. current.mode)
        end
        print("[PASS] Shop deck drop: " .. current.category .. " / " .. current.mode
            .. (current.pack and (" / " .. current.pack.packType) or ""))
        wait("setup", 0.15)
    elseif stage == "combat" then
        snapshot("shot_shared_card_back.png")
        wait("done", 0.2)
    elseif stage == "done" then
        print("Shop deck-drop + shared card-back regression passed (" .. #cases .. " input cases)")
        love.event.quit(0)
        stage = "finished"
    end
end
return Test

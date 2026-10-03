-- lovec.exe . --test-card-physics (isolated capture run, never writes player save).
local UI = require("src.ui")
local Physics = UI.CardPhysics
local CardEffects = require("src.card_effects")
local Deities = require("src.deities")
local Shop = require("src.shop")
local Deck = require("src.deck")
local Test = {}
local stage, deadline, queue, index, current, state, originX, originY = "start", 0, {}, 0
local initialGold, initialDeckSize, presses = 0, 0, 0
local packIndex = 0
local tailOnly = false
for _, argument in ipairs(arg or {}) do if argument == "--physics-tail" then tailOnly = true end end

local function pointer(x, y, action)
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / 1280, h / 720)
    local px, py = (w - 1280 * scale) / 2 + x * scale, (h - 720 * scale) / 2 + y * scale
    love.mouse.setPosition(px, py)
    if action == "press" then
        local isDown = love.keyboard.isDown
        if current and current.label == "battle hand" then
            love.keyboard.isDown = function(...) return true end -- Shift + drag holds a hand card.
        end
        love.mousepressed(px, py, 1)
        love.keyboard.isDown = isDown
    elseif action == "release" then love.mousereleased(px, py, 1)
    else love.mousemoved(px, py, 0, 0) end
end
local function after(seconds, nextStage)
    deadline, stage = love.timer.getTime() + seconds, nextStage
end
local function snapshot(name)
    love.graphics.captureScreenshot(function(data)
        local file = assert(io.open(name, "wb"))
        file:write(data:encode("png"):getString()); file:close()
    end)
end
local function add(card, label) queue[#queue + 1] = { card = card, label = label } end

function Test.update(game, callbacks)
    if love.timer.getTime() < deadline then return end
    if stage == "start" then
        callbacks.startNewGame("red_deck")
        callbacks.startMonsterEncounter(1, false)
        game.deities = { Deities.getStarterDeity("aurelia"), Deities.getStarterDeity("valoria") }
        game.consumables = { { id = "test_physics", name = "Test", icon = "✦", desc = "Visual only", color = {0.4, 0.8, 1} } }
        add(game.hand[1], "battle hand")
        add(game.deities[1], "battle SPN")
        add(game.consumables[1], "battle consumable")
        initialDeckSize, initialGold = #game.persistentDeck, game.gold
        if tailOnly then
            callbacks.openShop()
            packIndex = #Shop.PACK_CATALOG + 1
            after(0.3, "nextScene")
        else after(1, "pick") end
    elseif stage == "pick" then
        index = index + 1
        current = queue[index]
        if not current then stage = "nextScene"; return end
        state = assert(Physics.getState(current.card), "Card not hooked: " .. current.label)
        originX, originY = state.x, state.y
        local x = state.ox + state.a * state.w * 0.16 + state.c * state.h * 0.38
        local y = state.oy + state.b * state.w * 0.16 + state.d * state.h * 0.38
        assert(Physics.cardAt(x, y) == current.card, "Sample covered by another surface: " .. current.label)
        pointer(x, y, "press")
        assert(Physics.isHeld(current.card), "Hold did not reach actual renderer: " .. current.label)
        presses = presses + 1
        after(0.12, "move")
    elseif stage == "move" then
        pointer(650, 595)
        after(0.045, "lag")
    elseif stage == "lag" then
        assert(math.abs(state.x - state.targetX) > 0.1, "Card glued to mouse: " .. current.label)
        assert(math.abs(state.rotation) > 0.0001, "No velocity tilt: " .. current.label)
        local velocity = state.vx
        pointer(520, 600)
        assert(state.vx == velocity, "Reversal must not reset inertia")
        if current.label == "shop SPN" then snapshot("shot_card_physics.png") end
        after(0.18, "release")
    elseif stage == "release" then
        local vx, vy, av = state.vx, state.vy, state.angularVelocity
        pointer(520, 600, "release")
        assert(not Physics.isHeld(current.card))
        assert(state.vx == vx and state.vy == vy and state.angularVelocity == av,
            "Release discarded momentum: " .. current.label)
        after(1, "settle")
    elseif stage == "settle" then
        if Physics.getState(current.card) then
            assert(math.abs(state.x - state.homeX) < 3 and math.abs(state.y - state.homeY) < 3,
                "Card did not return to its slot: " .. current.label)
        end
        print("[PASS] hold / lag / reverse / release / settle: " .. current.label)
        after(0.1, "pick")
    elseif stage == "nextScene" then
        assert(#game.persistentDeck == initialDeckSize and game.gold == initialGold, "Visual drag mutated deck/money")
        if packIndex == 0 then
            callbacks.openShop()
            queue, index = {}, 0
            local shop = callbacks.getShopData()
            for _, item in ipairs(shop.items) do add(item, "shop " .. item.category) end
            add(game.deities[1], "shop SPN")
            add(game.consumables[1], "shop consumable")
            packIndex = 1
            after(0.4, "pick")
        elseif packIndex <= #Shop.PACK_CATALOG then
            local pack = Shop.PACK_CATALOG[packIndex]
            callbacks.openPack(pack)
            queue, index = {}, 0
            for _, card in ipairs(callbacks.getShopData().currentPackOpening.cards or {}) do
                add(card, "pack " .. pack.packType)
            end
            packIndex = packIndex + 1
            after(0.4, "pick")
        else
            callbacks.closePack()
            callbacks.openDeckViewer()
            after(0.2, "viewer")
        end
    elseif stage == "viewer" then
        current = { card = assert(Physics.cardAt(95, 202)), label = "deck viewer" }
        state = assert(Physics.getState(current.card))
        pointer(95, 202, "press")
        assert(Physics.isHeld(current.card))
        presses = presses + 1
        pointer(520, 600)
        after(0.2, "viewerRelease")
    elseif stage == "viewerRelease" then
        pointer(520, 600, "release")
        assert(state.detached and state.active, "Hidden deck-viewer card must animate back to deck pile")
        after(1, "swap")
    elseif stage == "swap" then
        assert(math.abs(state.x - state.homeX) < 3 and math.abs(state.y - state.homeY) < 3)
        current = { card = game.deities[1] }
        state = assert(Physics.getState(current.card))
        local x = state.ox + state.a * state.w * 0.5 + state.c * state.h * 0.38
        local y = state.oy + state.b * state.w * 0.5 + state.d * state.h * 0.38
        pointer(x, y, "press")
        presses = presses + 1
        local dx, dy, dw, dh = UI.getDeitySlotRect(2, "shop")
        pointer(dx + dw / 2, dy + dh / 2)
        pointer(dx + dw / 2, dy + dh / 2, "release")
        assert(game.deities[2] == current.card, "Valid SPN drop must preserve reorder behavior")
        after(1, "collection")
    elseif stage == "collection" then
        callbacks.openCollection("consumables")
        after(0.2, "catalogHold")
    elseif stage == "catalogHold" then
        local card = assert(Physics.cardAt(95, 160), "Collection artwork must be a physics surface")
        pointer(95, 160, "press")
        assert(Physics.isHeld(card))
        presses = presses + 1
        pointer(540, 580)
        after(0.15, "catalogRelease")
    elseif stage == "catalogRelease" then
        pointer(540, 580, "release")
        callbacks.closeCollection()
        love.keypressed("f10")
        after(0.2, "lab")
    elseif stage == "lab" then
        assert(Physics.isLabOpen())
        love.keypressed("1"); assert(Physics.config.preset == "LIGHT")
        love.keypressed("3"); assert(Physics.config.preset == "HEAVY")
        love.keypressed("2"); assert(Physics.config.preset == "MEDIUM")
        love.keypressed("space"); assert(CardEffects.getEffectName(Physics.labCard) == "foil")
        love.keypressed("space"); assert(CardEffects.getEffectName(Physics.labCard) == "holographic")
        love.keypressed("space"); assert(CardEffects.getEffectName(Physics.labCard) == "polychrome")
        pointer(640, 300, "press")
        assert(Physics.isHeld(Physics.labCard))
        presses = presses + 1
        pointer(760, 400)
        -- A stalled frame must remain finite and bounded, including shader UV.
        Physics.update(4, 900, 420)
        local s = assert(Physics.getState(Physics.labCard))
        assert(s.x == s.x and math.abs(s.x) < 10000 and math.abs(s.rotation) < 0.3)
        pointer(760, 400, "release")
        love.keypressed("p")
        after(0.2, "done")
    elseif stage == "done" then
        pointer(640, 300, "press")
        love.focus(false)
        assert(not Physics.isHeld(Physics.labCard), "Lost focus must release the held card")
        print("Card physics integration passed: " .. presses .. " real card holds; "
            .. (tailOnly and "viewer/reorder/collection/lab" or "shop/hand/SPN/consumables/all packs/viewer/reorder/collection/lab")
            .. "; presets/shader/focus/dt spike")
        love.event.quit(0)
        stage = "finished"
    end
end
return Test

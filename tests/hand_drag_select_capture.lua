-- ../love-11.5-win64/lovec.exe . --test-hand-drag-select
-- Exercises real input routing, renderer geometry and animated cards without player saves.
local Deck = require("src.deck")
local UI = require("src.ui")
local Test = {}
local stage, deadline, case = "start", 0, 0
local function point(i)
    local width, count = 100, 8
    local spacing = math.min(106, (UI.BATTLE_ARENA_W - 20 - width) / (count - 1))
    local left = UI.BATTLE_ARENA_X + (UI.BATTLE_ARENA_W - ((count - 1) * spacing + width)) / 2
    return left + (i - 1) * spacing + 8, 536
end
local function pointer(x, y, action)
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / 1280, h / 720)
    local px, py = (w - 1280 * scale) / 2 + x * scale, (h - 720 * scale) / 2 + y * scale
    love.mouse.setPosition(px, py)
    if action == "press" then love.mousepressed(px, py, 1)
    elseif action == "release" then love.mousereleased(px, py, 1)
    else love.mousemoved(px, py, 0, 0) end
end
local function after(seconds, nextStage)
    deadline, stage = love.timer.getTime() + seconds, nextStage
end
function Test.update(game, callbacks)
    if love.timer.getTime() < deadline then return end
    if stage == "start" then
        callbacks.startNewGame("red_deck")
        callbacks.startMonsterEncounter(1, false)
        game.hand, game.selectedIndices = {}, {}
        game.maxHandSize = 8
        game.unlockedHands = {high_card = true, flush = true}
        for i = 1, 8 do game.hand[i] = Deck.newCard(i + 1, "hearts") end
        after(0.5, "press")
    elseif stage == "press" then
        case = case + 1
        for _, card in ipairs(game.hand) do card.selected = false end
        game.selectedIndices = {}
        local x, y = point(1)
        if case == 2 then x = x - 20 end -- Start just beside the hand.
        pointer(x, y, "press")
        if case ~= 2 then assert(game.hand[1].selected, "No immediate selection on actual mousepress") end
        assert(not UI.CardPhysics.isHolding(), "Selection incorrectly picked up a physical card")
        after(0.06, "jitter")
    elseif stage == "jitter" then
        local x, y = point(1)
        pointer(x + 2, y + 14) -- Vertical movement used to permanently steal the gesture.
        after(0.06, "sweep")
    elseif stage == "sweep" then
        local x, y = point(8)
        pointer(x, y + (case % 3 - 1) * 35)
        assert(#game.selectedIndices == 5, "Diagonal/fast sweep failed through actual input routing: case "
            .. case .. ", selected " .. #game.selectedIndices .. " [" .. table.concat(game.selectedIndices, ",") .. "]")
        for i = 1, 5 do assert(game.hand[i].selected, "Sweep skipped visible card " .. i) end
        after(0.12, "release")
    elseif stage == "release" then
        local x, y = point(8)
        pointer(x, y, "release")
        assert(#game.selectedIndices == 5, "Release toggled the selection twice")
        if case == 3 then
            love.graphics.captureScreenshot(function(data)
                local f = assert(io.open("shot_drag_select.png", "wb"))
                f:write(data:encode("png"):getString()); f:close()
            end)
        end
        after(0.15, "deselect")
    elseif stage == "deselect" then
        local x, y = point(5)
        pointer(x, y - 35, "press") -- Lifted, selected card.
        x, y = point(1)
        pointer(x, y - 35)
        pointer(x, y - 35, "release")
        assert(#game.selectedIndices == 0, "Reverse swipe did not deselect animated cards")
        print("[PASS] actual animated hand drag selection " .. case)
        if case == 4 then love.window.setMode(960, 540, {resizable = true}); love.resize(960, 540) end
        if case == 8 then love.window.setMode(1920, 1080, {resizable = true}); love.resize(1920, 1080) end
        after(0.12, case < 12 and "press" or "reorder")
    elseif stage == "reorder" then
        local original = game.hand[1]
        local x, y = point(1)
        local isDown = love.keyboard.isDown
        love.keyboard.isDown = function() return true end
        pointer(x, y, "press")
        love.keyboard.isDown = isDown
        assert(UI.CardPhysics.isHeld(original), "Shift must retain physical pickup")
        pointer(x, y - 30)
        x, y = point(4); pointer(x + 42, y - 30); pointer(x + 42, y - 30, "release")
        assert(game.hand[4] == original and #game.selectedIndices == 0, "Shift reorder changed selection or failed")
        after(0.3, "focus")
    elseif stage == "focus" then
        local x, y = point(1); pointer(x, y, "press")
        love.focus(false)
        x, y = point(8); pointer(x, y); pointer(x, y, "release")
        assert(#game.selectedIndices == 1, "Focus loss did not cancel further selection")
        print("DRAG SELECT PASSED: 12 animated gesture cycles at 960/1280/1920 widths; overlap, adjacent start, cap, Shift reorder and focus loss")
        love.event.quit(0)
    end
end
return Test

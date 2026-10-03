-- Legacy command retained, but drag-to-deck purchases have been replaced by focus/confirm.
local UI = require("src.ui")
local Shop = require("src.shop")
local Surfaces = require("ui.card_surfaces")
local Test = {}
local checked = false
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
    if not checked then checkBacks();checked=true end
    return require("tests.ux_polish_capture").update(game, callbacks)
end
return Test

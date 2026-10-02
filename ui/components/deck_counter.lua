local Theme = require("ui.theme")
local Core = require("ui.components.core")
local DeckCounter = {}
local image, loaded = nil, false

function DeckCounter.getImage()
    if not loaded then
        loaded = true
        local ok, result = pcall(love.graphics.newImage, "assets/cards/card_back.png")
        if ok then
            image = result
            image:setFilter("linear", "linear")
        else
            print("[CardBack] Artwork unavailable: " .. tostring(result))
        end
    end
    return image
end

-- One shared back for every card family; no face labels or stat overlays.
function DeckCounter.drawBack(x, y, w, h, alpha)
    local g, art = love.graphics, DeckCounter.getImage()
    g.push("all")
    g.setColor(1, 1, 1, alpha or 1)
    if art then
        local iw, ih = art:getDimensions()
        g.draw(art, x, y, 0, w / iw, h / ih)
    else
        g.setColor(0.06, 0.10, 0.18, alpha or 1)
        g.rectangle("fill", x, y, w, h)
    end
    g.pop()
end

function DeckCounter.draw(x, y, w, h, remaining, total, fonts, hovered, dropColor)
    local g = love.graphics
    g.push("all")
    local artH = h - 24
    DeckCounter.drawBack(x + 3, y + 6, w - 3, artH, 0.55)
    DeckCounter.drawBack(x + 1, y + 3, w - 1, artH, 0.8)
    DeckCounter.drawBack(x, y, w, artH)
    if hovered or dropColor then
        Core.color(dropColor or Theme.colors.gold)
        g.setLineWidth(dropColor and 3 or 1.5)
        g.rectangle("line", x - 2, y - 2, w + 4, artH + 4, 5, 5)
    end
    Core.text(tostring(remaining) .. " / " .. tostring(total), x, y + h - 17,
        w, fonts.tiny, Theme.colors.text, "center")
    g.pop()
end
return DeckCounter

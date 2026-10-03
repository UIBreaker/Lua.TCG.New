local Theme = require("ui.theme")
local Core = require("ui.components.core")
local Frame = require("ui.components.card_frame")
local DeckCounter = {}
local image, loaded = nil, false

-- Trim only the source's outside matte, never threshold dark artwork inside it.
-- Bake the eight-sided outline once so direct image users share the same alpha.
local function trimBack(source)
    local g = love.graphics
    local iw, ih = source:getDimensions()
    local x, y, w, h = iw * 14 / 262, ih * 13 / 350, iw * 236 / 262, ih * 325 / 350
    local quad = g.newQuad(x, y, w, h, iw, ih)
    local mask = g.newShader([[
        vec4 effect(vec4 color, Image tex, vec2 uv, vec2 pixel) {
            vec2 p = (uv * vec2(262.0, 350.0) - vec2(14.0, 13.0));
            vec2 edge = min(p, vec2(236.0, 325.0) - p);
            float distance = min(min(edge.x, edge.y), (edge.x + edge.y - 9.0) * 0.70710678);
            vec4 base = Texel(tex, uv) * color;
            base.a *= smoothstep(0.0, 0.8, distance);
            return base;
        }
    ]])
    local canvas = g.newCanvas(math.floor(w + 0.5), math.floor(h + 0.5))
    g.push("all")
    g.setCanvas(canvas); g.origin(); g.clear(0, 0, 0, 0)
    g.setColor(1, 1, 1, 1); g.setBlendMode("alpha", "alphamultiply")
    g.setShader(mask); g.draw(source, quad, 0, 0)
    g.pop()
    -- Canvas pixels are premultiplied; images drawn by callers are straight alpha.
    local data = canvas:newImageData()
    data:mapPixel(function(_, _, r, b, c, a)
        if a == 0 then return 0, 0, 0, 0 end
        return r / a, b / a, c / a, a
    end)
    local result = g.newImage(data)
    mask:release(); quad:release(); canvas:release(); data:release()
    return result
end

function DeckCounter.getImage()
    if not loaded then
        loaded = true
        local ok, result = pcall(love.graphics.newImage, "assets/cards/card_back.png")
        if ok then
            local trimmed, art = pcall(trimBack, result)
            image = trimmed and art or result
            if trimmed then result:release()
            else print("[CardBack] Outline trim unavailable: " .. tostring(art)) end
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
        Frame.image(art, x, y, w, h)
    else
        g.setColor(0.06, 0.10, 0.18, alpha or 1)
        g.rectangle("fill", x, y, w, h)
    end
    Frame.draw(x, y, w, h, nil, alpha)
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
        Frame.draw(x, y, w, artH, dropColor or Theme.colors.gold)
    end
    Core.text(tostring(remaining) .. " / " .. tostring(total), x, y + h - 17,
        w, fonts.tiny, Theme.colors.text, "center")
    g.pop()
end
return DeckCounter

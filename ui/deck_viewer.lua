local Viewer = { pageSize = 18, sort = "rank" }
local Core = require("ui.components.core")
local Chrome = require("ui.combat_chrome")
local Theme = require("ui.theme")
local previews=setmetatable({}, {__mode="k"})
local drawSurface

local function drawPreview(card,x,y,w,h,hovered)
    local UI=require("src.ui")
    local preview=previews[card]
    if not preview then
        preview=setmetatable({rotation=0,tiltX=0,tiltY=0,visualScale=1,scale=1,scaleX=1,scaleY=1,
            alpha=1,selected=false,hovered=false},{__index=card})
        previews[card]=preview
    end
    UI.drawCard(preview,x,y,w,h,false,false)
    if hovered then UI.drawCardBorder(x,y,w,h,UI.COLORS.chipsBlue,nil,preview) end
end

function Viewer.drawCard(card,x,y,w,h,hovered)
    if not drawSurface then drawSurface=require("src.card_physics").wrap(drawPreview,nil,7) end
    Viewer.motionActive=true
    -- Keep hit-testing/dragging on the real card, with an independent upright face.
    drawSurface(card,x,y,w,h,hovered,false)
end

function Viewer.resetMotion()
    drawSurface=nil;previews=setmetatable({}, {__mode="k"});Viewer.motionActive=false
end

function Viewer.cardRect(index, x, y)
    return x + 32 + ((index - 1) % 6) * 111,
        y + 166 + math.floor((index - 1) / 6) * 148, 96, 138
end

function Viewer.sortCards(cards)
    local indexed = {}
    for i, card in ipairs(cards) do indexed[i] = {card = card, index = i} end
    table.sort(indexed, function(a, b)
        local ac, bc = a.card, b.card
        local as, bs = ac.suit or "", bc.suit or ""
        local ar, br = tonumber(ac.rank) or 0, tonumber(bc.rank) or 0
        if ar == 1 then ar = 14 end
        if br == 1 then br = 14 end
        if Viewer.sort == "suit" and as ~= bs then return as < bs end
        if ar ~= br then return ar > br end
        if as ~= bs then return as < bs end
        return a.index < b.index
    end)
    for i, item in ipairs(indexed) do cards[i] = item.card end
    return cards
end

function Viewer.drawHands(UI, game, x, y, w)
    local Poker = require("src.poker")
    local gold, muted = Theme.colors.gold, Theme.colors.muted
    local unlocked = 0
    for _, h in ipairs(Poker.HAND_TYPES_ORDERED) do
        if (game.unlockedHands or {})[h.id] then unlocked = unlocked + 1 end
    end
    Chrome.panel(x - 9, y + 83, w + 18, 545, gold)
    require("ui.backpack_style").glyph("craft", x + 17, y + 105, 10, gold)
    Chrome.title("BẢNG BÍ TÍCH", x + 37, y + 92, w - 112, UI.fonts.bookChapter or UI.fonts.medium, gold)
    Core.text(unlocked .. " / 9", x + w - 64, y + 97, 49, UI.fonts.small, gold, "right")
    Core.textLine("Mở để tạo Aura · ST: Sát thương · CH: Cường hóa", x + 12, y + 121, w - 24, UI.fonts.tiny, muted)
    Chrome.rule(x + 12, y + 142, w - 24, gold)
    for i = 1, #Poker.HAND_TYPES_ORDERED do
        local h = Poker.HAND_TYPES_ORDERED[#Poker.HAND_TYPES_ORDERED - i + 1]
        local open = (game.unlockedHands or {})[h.id] == true
        local hy = y + 150 + (i - 1) * 53
        local accent = open and gold or Theme.colors.metal
        Chrome.well(x + 4, hy, w - 8, 48, accent)
        local image = UI.getHandImage(h.id)
        if image then
            love.graphics.setColor(1, 1, 1, open and 1 or 0.35)
            UI.CardFrame.image(image, x + 12, hy + 6, 24, 36)
        end
        Chrome.title(h.vnName, x + 45, hy + 6, w - 125, UI.fonts.tiny, open and gold or muted)
        Core.text(open and "ĐÃ MỞ" or "KHÓA", x + w - 72, hy + 7, 56, UI.fonts.tiny, open and Theme.colors.green or muted, "right")
        local level = (game.handLevels or {})[h.id] or 1
        local stats = Poker.getHandStats(h.id, level)
        local subtitle = ({high_card="Mậu thầu",straight="Sảnh"})[h.id] or h.subtitle
        subtitle = subtitle .. " · " .. (h.id == "straight" and "3–5" or h.requiredCards) .. " lá"
        Core.textLine(subtitle .. " · Cấp " .. level, x + 45, hy + 27, w - 185, UI.fonts.tiny, muted)
        Core.text(stats.chips .. " ST × " .. stats.mult .. " CH", x + w - 137, hy + 27, 121, UI.fonts.tiny, Theme.colors.text, "right")
    end
end

return Viewer

local Theme = require("ui.theme")

local Layout = { width = Theme.virtualWidth, height = Theme.virtualHeight, logicalWidth = 1280, logicalHeight = 720 }

function Layout.scale(windowWidth, windowHeight, fillScreen)
    if fillScreen then
        return windowWidth / Layout.width, 0, 0, windowHeight / Layout.height
    end
    local factor = math.min(windowWidth / Layout.width, windowHeight / Layout.height)
    return factor, (windowWidth - Layout.width * factor) / 2, (windowHeight - Layout.height * factor) / 2, factor
end

function Layout.toLogical(x, y, sx, sy, ox, oy, renderScale)
    return (x - ox) / (sx * renderScale), (y - oy) / (sy * renderScale)
end

function Layout.fanCardRect(panelRect, index, count, cardW, cardH)
    cardW, cardH = cardW or 82, cardH or 118
    local padding = 16
    local availableW = panelRect[3] - padding * 2
    local step = count > 1 and math.max(0, (availableW - cardW) / (count - 1)) or 0
    return panelRect[1] + padding + (index - 1) * step, panelRect[2] + 29, cardW, cardH
end

Layout.battle = {
    hud = {55, 5, 1170, 65},
    hand = {12, 76, 222, 615},
    spm = {988, 73, 276, 184},
    consumables = {988, 265, 276, 184},
    enemy = {290, 82, 680, 365},
    cards = {250, 455, 760, 170},
    actions = {365, 628, 530, 68},
    deck = {1140, 535, 115, 160},
}

function Layout.inside(x, y, rect)
    return x >= rect[1] and y >= rect[2] and x <= rect[1] + rect[3] and y <= rect[2] + rect[4]
end

return Layout

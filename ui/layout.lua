local Theme = require("ui.theme")

local Layout = { width = Theme.virtualWidth, height = Theme.virtualHeight, logicalWidth = 1280, logicalHeight = 720 }

function Layout.scale(windowWidth, windowHeight)
    local factor = math.min(windowWidth / Layout.width, windowHeight / Layout.height)
    return factor, (windowWidth - Layout.width * factor) / 2, (windowHeight - Layout.height * factor) / 2
end

Layout.battle = {
    hud = {55, 5, 1170, 65},
    hand = {12, 76, 222, 615},
    spm = {1028, 73, 239, 248},
    consumables = {1028, 326, 239, 146},
    enemy = {290, 82, 680, 365},
    cards = {250, 455, 760, 170},
    actions = {365, 628, 530, 68},
    deck = {1140, 535, 115, 160},
}

function Layout.inside(x, y, rect)
    return x >= rect[1] and y >= rect[2] and x <= rect[1] + rect[3] and y <= rect[2] + rect[4]
end

return Layout

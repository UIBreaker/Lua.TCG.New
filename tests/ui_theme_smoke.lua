package.path = "./?.lua;./?/init.lua;" .. package.path

local draws = 0
local font = {
    getHeight = function() return 16 end,
    getWidth = function(_, text) return #tostring(text) * 8 end,
    getWrap = function(self, text, width)
        local lines = {}
        local maxChars = math.max(1, math.floor(width / 8))
        text = tostring(text)
        for start = 1, #text, maxChars do
            table.insert(lines, text:sub(start, start + maxChars - 1))
        end
        return self:getWidth(lines[1] or ""), lines
    end,
}
local fonts = {tiny = font, small = font, regular = font, medium = font, large = font}
local g = {}
for _, name in ipairs({"push", "pop", "setColor", "setLineWidth", "line", "polygon", "setFont"}) do
    g[name] = function() end
end
function g.getFont() return font end
function g.newImage(path)
    local width, height = path:find("top_hud_frame_v1", 1, true) and 2126 or 1774,
        path:find("top_hud_frame_v1", 1, true) and 740 or 887
    return {setFilter = function() end, getDimensions = function() return width, height end}
end
function g.newQuad(x, y, w, h, sw, sh) return {x, y, w, h, sw, sh} end
function g.draw(_, quad, _, _, _, sx, sy)
    if type(quad) == "table" then
        assert(sx > 0 and sx <= 1 and sy > 0 and sy <= 1, "sprite quad scaled by source pixels instead of target size")
    end
end
function g.printf(_, x, y, w)
    assert(x >= -0.01 and y >= -0.01 and w > 0 and x + w <= 1280.01 and y <= 720.01,
        "UI text outside logical viewport")
end
function g.rectangle(_, x, y, w, h)
    assert(x == x and y == y and w > 0 and h > 0, "invalid UI geometry")
    assert(x >= -0.01 and y >= -0.01 and x + w <= 1280.01 and y + h <= 720.01, "UI outside logical viewport")
    draws = draws + 1
end
love = {graphics = g, mouse = {isDown = function() return false end}}

local Layout = require("ui.layout")
local Gallery = require("ui.gallery")
local TopHUD = require("ui.components.top_hud")
local UI = require("src.ui")
UI.fonts = fonts
local b = Layout.battle
local function overlaps(a, c)
    return a[1] < c[1] + c[3] and c[1] < a[1] + a[3]
        and a[2] < c[2] + c[4] and c[2] < a[2] + a[4]
end
for _, pair in ipairs({{"hud", "hand"}, {"hud", "enemy"}, {"hud", "spm"},
    {"hand", "enemy"}, {"enemy", "spm"}, {"spm", "consumables"},
    {"cards", "actions"}, {"cards", "deck"}, {"actions", "deck"}}) do
    assert(not overlaps(b[pair[1]], b[pair[2]]), pair[1] .. " overlaps " .. pair[2])
end
local hudButtons = TopHUD.draw({ante = 1, round = 1, enemyName = "Tiểu Yêu", hp = 82,
    maxHp = 100, gold = 999, hands = 3, maxHands = 3, discards = 2}, fonts, 1100, 30,
    "open_settings")
assert(#hudButtons == 3 and hudButtons[3].id == "open_settings", "TopHUD action hitboxes missing")
for _, size in ipairs({{1920, 1080}, {1600, 900}, {1366, 768}}) do
    local scale, offsetX, offsetY = Layout.scale(size[1], size[2])
    assert(scale > 0 and offsetX >= 0 and offsetY >= 0)
    assert(offsetX + Layout.width * scale <= size[1] + 0.001)
    assert(offsetY + Layout.height * scale <= size[2] + 0.001)
    Gallery.draw(fonts, 300, 610)
    love.mouse.isDown = function() return true end
    Gallery.draw(fonts, 300, 610)
    love.mouse.isDown = function() return false end
end
assert(draws > 100, "Gallery did not draw all components")
for _, state in ipairs({"normal", "hover", "pressed", "disabled", "selected"}) do
    local btn = {text = state, x = 300, y = 400, w = 120, h = 40,
        disabled = state == "disabled", selected = state == "selected"}
    UI.drawButton(btn, state == "hover", state == "pressed")
end
UI.drawGildedPanel(300, 450, 200, 100)
UI.drawSlot("selected", "spm", 520, 450, 60, 80)
UI.drawPlayerHpBar(600, 450, 200, 26, 80, 100)
print("UI theme smoke OK: 1920x1080, 1600x900, 1366x768")

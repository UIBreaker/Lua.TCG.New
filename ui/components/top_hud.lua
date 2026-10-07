local Core = require("ui.components.core")
local Theme = require("ui.theme")

local TopHUD = {}
local assets

local HUD_X, HUD_Y, HUD_W, HUD_H = 55, 5, 1170, 65
local FRAME_SOURCE = {x = 10, y = 308, w = 2105, h = 121}
local ICON_ROWS, ICON_COLUMNS = 2, 4

local ICON = {
    heart = {1, 1}, coin = {1, 2}, cards = {1, 3}, discard = {1, 4},
    battle = {2, 1}, deck = {2, 2}, options = {2, 3},
}

local function loadAssets()
    if assets then return assets end

    local g = love.graphics
    local frame = g.newImage("assets/ui/generated/top_hud/top_hud_frame_v1.png")
    local atlas = g.newImage("assets/ui/generated/top_hud/top_hud_icons_atlas_v1.png")
    frame:setFilter("linear", "linear")
    atlas:setFilter("linear", "linear")

    local frameW, frameH = frame:getDimensions()
    local atlasW, atlasH = atlas:getDimensions()
    local cellW, cellH = atlasW / ICON_COLUMNS, atlasH / ICON_ROWS
    local quads = {}
    for name, cell in pairs(ICON) do
        quads[name] = g.newQuad((cell[2] - 1) * cellW, (cell[1] - 1) * cellH,
            cellW, cellH, atlasW, atlasH)
    end

    assets = {
        frame = frame,
        frameQuad = g.newQuad(FRAME_SOURCE.x, FRAME_SOURCE.y, FRAME_SOURCE.w,
            FRAME_SOURCE.h, frameW, frameH),
        atlas = atlas,
        iconCellW = cellW,
        iconCellH = cellH,
        icons = quads,
    }
    return assets
end

local function drawIcon(name, x, y, size, alpha)
    local a = loadAssets()
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(a.atlas, a.icons[name], x, y, 0,
        size / a.iconCellW, size / a.iconCellH)
end

local function fitText(text, width, preferred, fallback)
    if preferred:getWidth(text) <= width then return preferred end
    if fallback and fallback:getWidth(text) <= width then return fallback end
    return fallback or preferred
end

local function drawHealth(data, fonts)
    local g = love.graphics
    local hp = math.max(0, tonumber(data.hp) or 0)
    local maxHp = math.max(1, tonumber(data.maxHp) or 1)
    local armor = math.max(0, tonumber(data.armor) or 0)
    local x, y, w, h = 231, 32, 187, 23
    local ratio = math.max(0, math.min(1, hp / maxHp))

    Core.color({0.025, 0.11, 0.075, 0.94})
    g.rectangle("fill", x, y, w, h, 4, 4)
    if ratio > 0 then
        Core.gradient(x + 1, y + 1, math.max(1, (w - 2) * ratio), h - 2,
            {0.18, 0.70, 0.42, 1}, {0.08, 0.38, 0.24, 1}, 3)
    end

    -- A distinct armor layer sits above HP, including an explicit empty state.
    Core.color({0.025,0.07,0.12,0.98})
    g.rectangle("fill", x, 16, w, 14, 3, 3)
    local armorRatio = math.min(1, armor / math.max(1, data.armorCap or 30))
    if armorRatio > 0 then
        local fillW=(w-2)*armorRatio
        Core.gradient(x+1,17,fillW,12,{0.18,0.65,0.84,1},{0.07,0.25,0.47,1},2)
        Core.color({0.7,0.94,1,0.5});g.rectangle("fill",x+3,18,math.max(0,fillW-4),1)
        local flash=math.min(1,math.max(0,((data.armorBounce or 1)-1)*10))
        Core.color({0.7,0.95,1,flash*0.42})
        g.rectangle("fill",x+1,17,fillW,12,2,2)
        Core.color({0.8,0.97,1,flash*0.7})
        g.rectangle("fill",x+2+(fillW-4)*(1-flash),18,2,10)
        for i=1,5 do
            local sx=x+w*i/6
            if sx<x+fillW then Core.color({0.03,0.13,0.22,0.28});g.line(sx,19,sx,27) end
        end
    end
    Core.color({0.45,0.83,1,0.9})
    g.setLineWidth(1)
    g.rectangle("line", x, 16, w, 14, 3, 3)
    g.push("all");g.translate(x+w/2,23);g.scale(data.armorBounce or 1);g.translate(-x-w/2,-23)
    Core.text("GIÁP " .. tostring(math.floor(armor)), x+4, 16, w-8, fonts.hudArmor,
        {0.75,0.94,1,1}, "center")
    g.pop()
    drawIcon("heart", x + 5, y, 23)
    local label = "MÁU " .. tostring(math.floor(hp)) .. " / " .. tostring(math.floor(maxHp))
    local font = fitText(label, w - 40, fonts.hudStat, fonts.hudSmall)
    g.push("all");g.translate(x+120,y+h/2);g.scale(data.hpBounce or 1);g.translate(-x-120,-y-h/2)
    Core.textLine(label, x + 30, y + (h-font:getHeight())/2, w - 35, font, Theme.colors.text, "center", fonts.hudSmall)
    g.pop()
end

local function drawActionButton(spec, mx, my, pressedId, fonts)
    local g = love.graphics
    local hovered = mx and my and mx >= spec.x and mx <= spec.x + spec.w
        and my >= spec.y and my <= spec.y + spec.h
    local pressed = pressedId == spec.id
    local accent = Theme.accent(spec.variant)

    if pressed or hovered then
        Core.color(accent, pressed and 0.28 or 0.16)
        g.rectangle("fill", spec.x + 6, spec.y + 6, spec.w - 12, spec.h - 12, 5, 5)
    end

    local iconSize = 31
    local gap = 4
    local labelW = fonts.hudButton:getWidth(spec.text)
    local contentW = iconSize + gap + labelW
    local iconX = spec.x + (spec.w - contentW) / 2
    local iconY = spec.y + (spec.h - iconSize) / 2 + (pressed and 1 or 0)
    drawIcon(spec.icon, iconX, iconY, iconSize, pressed and 0.92 or 1)
    local font = fitText(spec.text, spec.w - iconSize - gap - 16, fonts.hudButton, fonts.hudSmall)
    Core.textLine(spec.text, iconX + iconSize + gap, spec.y + (spec.h - font:getHeight()) / 2
        + (pressed and 1 or 0), spec.w - (iconX - spec.x) - iconSize - gap - 5,
        font, Theme.colors.text, "center", fonts.hudSmall)

    return {
        id = spec.id, text = spec.text, x = spec.x + 4, y = spec.y + 3,
        w = spec.w - 8, h = spec.h - 6, variant = spec.variant,
    }
end

function TopHUD.draw(data, fonts, mx, my, pressedId)
    data = data or {}
    fonts = fonts or {}
    local g = love.graphics
    local defaultFont = g.getFont()
    local hudTitle = fonts.hudTitle or defaultFont
    local hudSmall = fonts.hudSmall or defaultFont
    local hudStat = fonts.hudStat or defaultFont
    local hudButton = fonts.hudButton or defaultFont
    local hudFonts = {hudTitle = hudTitle, hudSmall = hudSmall, hudStat = hudStat, hudArmor = fonts.tiny or hudSmall,
        hudButton = hudButton}
    local a = loadAssets()

    g.setColor(1, 1, 1, 1)
    g.draw(a.frame, a.frameQuad, HUD_X, HUD_Y, 0, HUD_W / FRAME_SOURCE.w, HUD_H / FRAME_SOURCE.h)

    -- These bounds follow the inset wells in the generated frame atlas.
    Core.textLine("ẢI " .. tostring(data.ante or 1) .. "-" .. tostring(data.round or 1),
        88, 15, 124, hudTitle, Theme.colors.gold, "center", hudSmall)
    Core.textLine(data.enemyName or "Tiểu Yêu", 88, 39, 124, hudSmall, Theme.colors.text, "center")
    drawHealth(data, hudFonts)

    g.push("all")
    g.translate(470,37)
    g.scale(data.goldBounce or 1)
    g.translate(-470,-37)
    local goldFlash=math.min(1,math.max(0,((data.goldBounce or 1)-1)*5))
    g.setBlendMode("add")
    g.setColor(1,0.72,0.18,goldFlash*0.16);g.ellipse("fill",448,27,22,15)
    g.setColor(1,0.91,0.5,goldFlash*0.8);g.setLineWidth(1.3)
    g.line(454,12,454,21);g.line(450,16,458,16)
    g.setBlendMode("alpha")
    drawIcon("coin", 430, 14, 25)
    Core.textLine(tostring(data.gold or 0), 460, 17, 48, hudStat, Theme.colors.gold, "left", hudSmall)
    g.pop()
    Core.textLine(tostring(data.souls or 0).." LH", 430, 43, 78, hudFonts.hudArmor, Theme.colors.purple, "center")

    drawIcon("cards", 519, 22, 30)
    Core.textLine("LƯỢT " .. tostring(data.hands or 0) .. "/" .. tostring(data.maxHands or 0),
        548, 25, 99, hudStat, Theme.colors.text, "center", hudSmall)

    drawIcon("discard", 657, 22, 30)
    Core.textLine("BỎ " .. tostring(data.discards or 0), 688, 25, 69,
        hudStat, Theme.colors.text, "center", hudSmall)

    local specs = {
        {id = "open_handbook", text = "TRẬN", icon = "battle", x = 764, y = 11,
            w = 124, h = 52, variant = "cyan"},
        {id = "open_deck_viewer", text = "BỘ BÀI", icon = "deck", x = 888, y = 11,
            w = 131, h = 52, variant = "gold"},
        {id = "open_settings", text = "TÙY CHỌN", icon = "options", x = 1019, y = 11,
            w = 153, h = 52, variant = "purple"},
    }
    local buttons = {}
    for _, spec in ipairs(specs) do
        table.insert(buttons, drawActionButton(spec, mx, my, pressedId, hudFonts))
    end
    g.setColor(1, 1, 1, 1)
    return buttons
end

return TopHUD

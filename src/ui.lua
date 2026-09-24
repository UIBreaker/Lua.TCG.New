local UI = {}

-- Color constants
UI.COLORS = {
    bg = { 0.055, 0.075, 0.090, 1 },
    felt = { 0.080, 0.120, 0.130, 1 },
    panelBg = { 0.090, 0.125, 0.145, 0.96 },
    panelBorder = { 0.34, 0.40, 0.42, 1 },
    cardBg = { 0.91, 0.91, 0.87, 1 },
    cardBorder = { 0.44, 0.52, 0.54, 1 },
    cardSelectedBorder = { 0.95, 0.72, 0.38, 1 },
    textLight = { 0.95, 0.96, 0.98, 1 },
    textDark = { 0.15, 0.15, 0.18, 1 },
    textMuted = { 0.68, 0.74, 0.80, 1 },
    chipsBlue = { 0.25, 0.49, 0.54, 1 },
    multRed = { 0.55, 0.28, 0.26, 1 },
    suitCrimson = { 0.62, 0.19, 0.22, 1 },
    suitObsidian = { 0.13, 0.21, 0.26, 1 },
    xmultGold = { 0.88, 0.65, 0.31, 1 },
    goldYellow = { 0.91, 0.76, 0.48, 1 },
    hpGreen = { 0.31, 0.62, 0.49, 1 },
    hpRed = { 0.72, 0.24, 0.25, 1 },
    bossPurple = { 0.53, 0.37, 0.58, 1 },
    btnPlay = { 0.24, 0.48, 0.51, 1 },
    btnDiscard = { 0.56, 0.29, 0.27, 1 },
    btnConfirm = { 0.27, 0.55, 0.42, 1 },
    btnSpecial = { 0.68, 0.50, 0.29, 1 },
    btnDestruct = { 0.60, 0.26, 0.25, 1 },
    btnNormal = { 0.18, 0.25, 0.29, 1 },
}

UI.fonts = {}
UI.BATTLE_ARENA_X = 250
UI.BATTLE_ARENA_W = 760
UI.BATTLE_CENTER_X = UI.BATTLE_ARENA_X + UI.BATTLE_ARENA_W / 2

function UI.getScoringCardX(index, count)
    local cardW = 96
    local spacing = count > 1 and math.min(112, (UI.BATTLE_ARENA_W - cardW) / (count - 1)) or 0
    local totalW = cardW + math.max(0, count - 1) * spacing
    return UI.BATTLE_ARENA_X + (UI.BATTLE_ARENA_W - totalW) / 2 + (index - 1) * spacing
end

UI.useLegacyPixelArt = false
function UI.visualImage(image)
    return UI.useLegacyPixelArt and image or nil
end

function UI.sanitizeText(str)
    if type(str) ~= "string" then return str end
    -- Strip UTF-8 variation selectors U+FE0E and U+FE0F that cause tofu squares in Love2D FreeType
    local s = str:gsub("\239\184\142", ""):gsub("\239\184\143", "")
    return s
end

local utf8 = require("utf8")
function UI.truncateUtf8(str, maxChars)
    if type(str) ~= "string" then return "" end
    maxChars = maxChars or 35
    local ok, len = pcall(utf8.len, str)
    if not ok or not len or len <= maxChars then return str end
    local okOffset, byteOffset = pcall(utf8.offset, str, maxChars + 1)
    if okOffset and byteOffset then
        return str:sub(1, byteOffset - 1) .. "..."
    end
    return str
end

local VN_LOWER_TO_UPPER = {
    ["a"] = "A", ["à"] = "À", ["á"] = "Á", ["ả"] = "Ả", ["ã"] = "Ã", ["ạ"] = "Ạ",
    ["ă"] = "Ă", ["ằ"] = "Ằ", ["ắ"] = "Ắ", ["ẳ"] = "Ẳ", ["ẵ"] = "Ẵ", ["ặ"] = "Ặ",
    ["â"] = "Â", ["ầ"] = "Ầ", ["ấ"] = "Ấ", ["ẩ"] = "Ẩ", ["ẫ"] = "Ẫ", ["ậ"] = "Ậ",
    ["đ"] = "Đ",
    ["e"] = "E", ["è"] = "È", ["é"] = "É", ["ẻ"] = "Ẻ", ["ẽ"] = "Ẽ", ["ẹ"] = "Ẹ",
    ["ê"] = "Ê", ["ề"] = "Ề", ["ế"] = "Ế", ["ể"] = "Ể", ["ễ"] = "Ễ", ["ệ"] = "Ệ",
    ["i"] = "I", ["ì"] = "Ì", ["í"] = "Í", ["ỉ"] = "Ỉ", ["ĩ"] = "Ĩ", ["ị"] = "Ị",
    ["o"] = "O", ["ò"] = "Ò", ["ó"] = "Ó", ["ỏ"] = "Ỏ", ["õ"] = "Õ", ["ọ"] = "Ọ",
    ["ô"] = "Ô", ["ồ"] = "Ồ", ["ố"] = "Ố", ["ổ"] = "Ổ", ["ỗ"] = "Ỗ", ["ộ"] = "Ộ",
    ["ơ"] = "Ơ", ["ờ"] = "Ờ", ["ớ"] = "Ớ", ["ở"] = "Ở", ["ỡ"] = "Ỡ", ["ợ"] = "Ợ",
    ["u"] = "U", ["ù"] = "Ù", ["ú"] = "Ú", ["ủ"] = "Ủ", ["ũ"] = "Ũ", ["ụ"] = "Ụ",
    ["ư"] = "Ư", ["ừ"] = "Ừ", ["ứ"] = "Ứ", ["ử"] = "Ử", ["ữ"] = "Ữ", ["ự"] = "Ự",
    ["y"] = "Y", ["ỳ"] = "Ỳ", ["ý"] = "Ý", ["ỷ"] = "Ỷ", ["ỹ"] = "Ỹ", ["ỵ"] = "Ỵ",
}

function UI.toUpperUtf8(str)
    if type(str) ~= "string" or str == "" then return str or "" end
    local res = str
    for low, upp in pairs(VN_LOWER_TO_UPPER) do
        if #low > 1 then
            res = res:gsub(low, upp)
        end
    end
    return res:upper()
end

function UI.initFonts()
    local fontBoldPath = "fonts/arialbd.ttf"
    local fontRegularPath = "fonts/arial.ttf"
    local function loadFont(size)
        local ok, font = pcall(love.graphics.newFont, fontBoldPath, size)
        if not (ok and font) then
            ok, font = pcall(love.graphics.newFont, fontRegularPath, size)
        end
        if not (ok and font) then
            font = love.graphics.newFont(size)
        end
        -- Setup fallback fonts for symbols & emoji
        local okSym, symFont = pcall(love.graphics.newFont, "fonts/seguisym.ttf", size)
        local okEmj, emjFont = pcall(love.graphics.newFont, "C:/Windows/Fonts/seguiemj.ttf", size)
        local fallbacks = {}
        if okSym and symFont then table.insert(fallbacks, symFont) end
        if okEmj and emjFont then table.insert(fallbacks, emjFont) end
        if #fallbacks > 0 and font.setFallbacks then
            pcall(function() font:setFallbacks(unpack(fallbacks)) end)
        end
        return font
    end

    UI.fonts.tiny = loadFont(12)
    UI.fonts.small = loadFont(14)
    UI.fonts.regular = loadFont(17)
    UI.fonts.medium = loadFont(22)
    UI.fonts.large = loadFont(28)
    UI.fonts.title = loadFont(36)
    UI.fonts.huge = loadFont(48)
    UI.fonts.logo = loadFont(92)
end

function UI.drawRoundedRect(mode, x, y, w, h, r)
    r = r or 6
    love.graphics.rectangle(mode, x, y, w, h, r, r)
end

function UI.drawGildedPanel(x, y, w, h, accent)
    local g = love.graphics
    accent = accent or UI.COLORS.goldYellow
    g.push("all")
    g.setColor(0, 0, 0, 0.55)
    UI.drawRoundedRect("fill", x + 4, y + 6, w, h, 7)
    g.setColor(0.045, 0.065, 0.09, 0.93)
    UI.drawRoundedRect("fill", x, y, w, h, 7)
    g.setColor(accent[1], accent[2], accent[3], 0.9)
    g.setLineWidth(2)
    UI.drawRoundedRect("line", x, y, w, h, 7)
    g.setColor(accent[1], accent[2], accent[3], 0.35)
    g.setLineWidth(1)
    UI.drawRoundedRect("line", x + 5, y + 5, w - 10, h - 10, 4)
    local corner = math.min(18, w / 7, h / 4)
    g.setColor(accent[1], accent[2], accent[3], 0.8)
    for _, sx in ipairs({ x, x + w }) do
        for _, sy in ipairs({ y, y + h }) do
            local dx = sx == x and 1 or -1
            local dy = sy == y and 1 or -1
            g.line(sx + dx * 2, sy + dy * corner, sx + dx * 2, sy + dy * 2, sx + dx * corner, sy + dy * 2)
        end
    end
    g.pop()
end

-- Procedural vector drawing for card faction and suit symbols
function UI.drawSuitSymbol(suit, cx, cy, size, customColor)
    love.graphics.push("all")
    if customColor then
        love.graphics.setColor(customColor)
    end

    local s = suit or "aurelia"

    -- Red Deck: a simple red-backed playing card emblem.
    if s == "red_deck" then
        love.graphics.rectangle("fill", cx - size * 0.34, cy - size * 0.46, size * 0.68, size * 0.92, size * 0.08)
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.rectangle("line", cx - size * 0.27, cy - size * 0.39, size * 0.54, size * 0.78, size * 0.06)
        love.graphics.polygon("fill", {
            cx, cy - size * 0.22,
            cx + size * 0.18, cy,
            cx, cy + size * 0.22,
            cx - size * 0.18, cy,
        })

    -- 1. ☀️ AURELIA (Phe Ánh Sáng / Hearts alias)
    elseif s == "aurelia" or s == "hearts" then
        -- Central radiant sun circle
        local r = size * 0.22
        love.graphics.circle("fill", cx, cy, r)

        -- 8 Sun rays bursting outwards
        local rayOuter = size * 0.46
        local rayInner = size * 0.25
        local rayHalfW = size * 0.08
        local angles = { 0, math.pi / 4, math.pi / 2, 3 * math.pi / 4, math.pi, 5 * math.pi / 4, 3 * math.pi / 2, 7 * math.pi / 4 }
        for _, ang in ipairs(angles) do
            local cosA = math.cos(ang)
            local sinA = math.sin(ang)
            local perpX = -sinA * rayHalfW
            local perpY = cosA * rayHalfW

            local tipX = cx + cosA * rayOuter
            local tipY = cy + sinA * rayOuter
            local b1X = cx + cosA * rayInner + perpX
            local b1Y = cy + sinA * rayInner + perpY
            local b2X = cx + cosA * rayInner - perpX
            local b2Y = cy + sinA * rayInner - perpY

            love.graphics.polygon("fill", { b1X, b1Y, tipX, tipY, b2X, b2Y })
        end

    -- 2. 🌲 ELARIS (Phe Thiên Nhiên / Clubs alias)
    elseif s == "elaris" or s == "clubs" then
        -- Tree trunk
        local tw = size * 0.12
        local th = size * 0.22
        love.graphics.rectangle("fill", cx - tw / 2, cy + size * 0.22, tw, th)

        -- 3 Layered triangular evergreen foliage
        -- Top tier
        love.graphics.polygon("fill", {
            cx, cy - size * 0.46,
            cx + size * 0.24, cy - size * 0.14,
            cx - size * 0.24, cy - size * 0.14
        })
        -- Middle tier
        love.graphics.polygon("fill", {
            cx, cy - size * 0.22,
            cx + size * 0.34, cy + size * 0.06,
            cx - size * 0.34, cy + size * 0.06
        })
        -- Bottom tier
        love.graphics.polygon("fill", {
            cx, cy - size * 0.02,
            cx + size * 0.44, cy + size * 0.24,
            cx - size * 0.44, cy + size * 0.24
        })

    -- 3. 🔥 VHAROS (Phe Hắc Ám / Spades alias)
    elseif s == "vharos" or s == "spades" then
        -- Dark leaping flame with dynamic horns/curls
        local flamePoly = {
            cx, cy - size * 0.48,           -- top main peak
            cx + size * 0.18, cy - size * 0.26,
            cx + size * 0.38, cy - size * 0.12,  -- right sub-flame
            cx + size * 0.32, cy + size * 0.15,
            cx + size * 0.18, cy + size * 0.44,  -- bottom right base
            cx - size * 0.18, cy + size * 0.44,  -- bottom left base
            cx - size * 0.32, cy + size * 0.15,
            cx - size * 0.38, cy - size * 0.12,  -- left sub-flame
            cx - size * 0.18, cy - size * 0.26
        }
        love.graphics.polygon("fill", flamePoly)

        -- Inner brighter flame core
        love.graphics.setColor(1, 1, 1, 0.45)
        local innerFlame = {
            cx, cy - size * 0.28,
            cx + size * 0.14, cy + size * 0.06,
            cx + size * 0.08, cy + size * 0.32,
            cx - size * 0.08, cy + size * 0.32,
            cx - size * 0.14, cy + size * 0.06
        }
        love.graphics.polygon("fill", innerFlame)

    -- 4. ⚔️ VALORIA (Phe Nhân Loại / Diamonds alias)
    elseif s == "valoria" or s == "diamonds" then
        -- Crossed swords
        local halfBlade = size * 0.44
        local bladeW = size * 0.08

        -- Sword 1 (TL to BR)
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(math.pi / 4)
        -- Blade
        love.graphics.polygon("fill", {
            0, -halfBlade,
            bladeW / 2, -halfBlade * 0.8,
            bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, -halfBlade * 0.8
        })
        -- Crossguard
        love.graphics.rectangle("fill", -size * 0.18, halfBlade * 0.5, size * 0.36, size * 0.06)
        -- Hilt & Pommel
        love.graphics.rectangle("fill", -size * 0.04, halfBlade * 0.56, size * 0.08, size * 0.18)
        love.graphics.circle("fill", 0, halfBlade * 0.78, size * 0.06)
        love.graphics.pop()

        -- Sword 2 (TR to BL)
        love.graphics.push()
        love.graphics.translate(cx, cy)
        love.graphics.rotate(-math.pi / 4)
        -- Blade
        love.graphics.polygon("fill", {
            0, -halfBlade,
            bladeW / 2, -halfBlade * 0.8,
            bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, halfBlade * 0.5,
            -bladeW / 2, -halfBlade * 0.8
        })
        -- Crossguard
        love.graphics.rectangle("fill", -size * 0.18, halfBlade * 0.5, size * 0.36, size * 0.06)
        -- Hilt & Pommel
        love.graphics.rectangle("fill", -size * 0.04, halfBlade * 0.56, size * 0.08, size * 0.18)
        love.graphics.circle("fill", 0, halfBlade * 0.78, size * 0.06)
        love.graphics.pop()

        -- Central Shield Boss
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.circle("fill", cx, cy, size * 0.12)
    end

    love.graphics.pop()
end

function UI.drawButton(btn, isHovered, isPressed)
    if not btn or btn.invisible then return end
    if not btn.x or not btn.y or not btn.w or not btn.h then return end

    -- One calm material treatment across menus, combat and shop.
    local g = love.graphics
    local enabled = not btn.disabled
    local hover = enabled and isHovered
    local pressed = enabled and isPressed
    local base = btn.color or UI.COLORS.btnNormal
    local scale = pressed and 0.98 or (hover and 1.025 or 1)
    local cx, cy = btn.x + btn.w / 2, btn.y + btn.h / 2
    g.push("all")
    g.translate(cx, cy)
    g.scale(scale)
    g.translate(-cx, -cy)
    if btn.menuStyle then
        local accent = btn.menuAccent or UI.COLORS.goldYellow
        UI.drawGildedPanel(btn.x, btn.y, btn.w, btn.h, accent)
        g.setColor(base[1], base[2], base[3], hover and 0.58 or 0.34)
        UI.drawRoundedRect("fill", btn.x + 6, btn.y + 6, btn.w - 12, btn.h - 12, 4)
        g.setColor(accent[1], accent[2], accent[3], hover and 0.88 or 0.52)
        g.line(btn.x + 75, btn.y + 14, btn.x + 75, btn.y + btn.h - 14)
        g.setFont(UI.fonts.title)
        g.setColor(accent)
        g.printf(btn.icon or "✦", btn.x + 12, btn.y + (btn.h - UI.fonts.title:getHeight()) / 2, 54, "center")
        local font = btn.font or UI.fonts.large
        local label = UI.toUpperUtf8(UI.sanitizeText(btn.text or ""))
        g.setFont(font)
        g.setColor(enabled and UI.COLORS.textLight or UI.COLORS.textMuted)
        g.printf(label, btn.x + 90, btn.y + (btn.sub and 13 or (btn.h - font:getHeight()) / 2), btn.w - 105, "left")
        if btn.sub then
            g.setFont(UI.fonts.tiny)
            g.setColor(0.78, 0.82, 0.87, 1)
            g.printf(btn.sub, btn.x + 90, btn.y + 48, btn.w - 105, "left")
        end
        g.pop()
        return
    end
    g.setColor(0.01, 0.025, 0.03, 0.32)
    UI.drawRoundedRect("fill", btn.x + 2, btn.y + 4, btn.w, btn.h, 5)
    g.setColor(enabled and base or { 0.17, 0.20, 0.22, 0.86 })
    UI.drawRoundedRect("fill", btn.x, btn.y, btn.w, btn.h, 5)
    g.setColor(1, 1, 1, hover and 0.25 or 0.12)
    g.polygon("fill", btn.x + 4, btn.y + 3, btn.x + btn.w - 4, btn.y + 3,
        btn.x + btn.w - 13, btn.y + 10, btn.x + 10, btn.y + 10)
    g.setLineWidth(hover and 1.7 or 1)
    g.setColor(hover and UI.COLORS.goldYellow or { 0.54, 0.61, 0.60, 0.75 })
    UI.drawRoundedRect("line", btn.x, btn.y, btn.w, btn.h, 5)
    if btn.w >= 90 and btn.h >= 36 then
        g.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], hover and 0.9 or 0.48)
        g.line(btn.x + 6, btn.y + 13, btn.x + 6, btn.y + 6, btn.x + 18, btn.y + 6)
        g.line(btn.x + btn.w - 18, btn.y + btn.h - 6, btn.x + btn.w - 6, btn.y + btn.h - 6,
            btn.x + btn.w - 6, btn.y + btn.h - 13)
    end
    local font = btn.font or UI.fonts.regular
    g.setFont(font)
    g.setColor(enabled and (btn.textColor or UI.COLORS.textLight) or UI.COLORS.textMuted)
    local label = UI.sanitizeText(btn.text or "")
    if not btn.preserveCase then label = UI.toUpperUtf8(label) end
    local labelY = btn.y + (btn.h - font:getHeight()) / 2 - (btn.sub and 7 or 0)
    g.printf(label, btn.x + 3, labelY, btn.w - 6, "center")
    if btn.sub then
        g.setFont(UI.fonts.tiny)
        g.setColor(UI.COLORS.textMuted)
        g.printf(UI.sanitizeText(btn.sub), btn.x + 3, labelY + font:getHeight() + 1, btn.w - 6, "center")
    end
    g.pop()
end

-- Matte stone/ivory cards with a single faceted suit emblem. The same renderer
-- is used by the hand, collection, shop, rewards and pack reveals.
function UI.drawCard(card, x, y, w, h)
    local g = love.graphics
    local rank = tostring(card.rankName or card.rank or "?")
    local red = card.suit == "hearts" or card.suit == "diamonds"
        or card.suit == "valoria" or card.suit == "aurelia"
    local accent = red and UI.COLORS.suitCrimson or UI.COLORS.suitObsidian
    local selected = card.selected == true
    local hovered = card.hovered == true
    local s = card.visualScale or 1
    g.push("all")
    g.translate(x + w / 2, y + h / 2)
    g.rotate(card.rotation or 0)
    g.scale((card.scaleX or card.scale or 1) * s, (card.scaleY or card.scale or 1) * s)
    g.translate(-w / 2, -h / 2)
    g.setColor(0, 0, 0, selected and 0.44 or 0.30)
    UI.drawRoundedRect("fill", 4, selected and 11 or 6, w, h, 5)
    g.setColor(UI.COLORS.cardBg)
    UI.drawRoundedRect("fill", 0, 0, w, h, 5)
    g.setColor(1, 1, 1, 0.58)
    g.polygon("fill", 4, 4, w - 4, 4, w * 0.72, h * 0.32, w * 0.18, h * 0.49)
    g.setColor(0.55, 0.62, 0.61, 0.11)
    g.polygon("fill", 4, h * 0.72, w * 0.72, h * 0.32, w - 4, h - 4, 4, h - 4)
    g.setLineWidth(selected and 3 or (hovered and 2 or 1.2))
    g.setColor(selected and UI.COLORS.cardSelectedBorder or (hovered and UI.COLORS.chipsBlue or UI.COLORS.cardBorder))
    UI.drawRoundedRect("line", 0, 0, w, h, 5)
    g.setColor(accent)
    g.setFont(UI.fonts.large)
    g.print(rank, 8, 3)
    UI.drawSuitSymbol(card.suit, 18, 37, math.min(w, h) * 0.15, accent)
    if card.faceDown then
        g.setColor(0.13, 0.19, 0.22, 0.94)
        UI.drawRoundedRect("fill", 4, 4, w - 8, h - 8, 4)
        g.setColor(UI.COLORS.goldYellow)
        g.setFont(UI.fonts.medium)
        g.printf("?", 0, h / 2 - 13, w, "center")
    else
        local cx, cy = w / 2, h * 0.52
        local facet = math.min(w * 0.31, h * 0.22)
        g.setColor(accent[1], accent[2], accent[3], 0.12)
        g.polygon("fill", cx, cy - facet * 1.35, cx + facet * 1.1, cy,
            cx, cy + facet * 1.35, cx - facet * 1.1, cy)
        g.setColor(accent[1], accent[2], accent[3], 0.35)
        g.polygon("fill", cx, cy - facet * 1.08, cx + facet * 0.78, cy,
            cx, cy + facet * 0.15, cx - facet * 0.78, cy)
        UI.drawSuitSymbol(card.suit, cx, cy + 1, facet * 1.48, accent)
        g.setColor(accent)
        g.setFont(UI.fonts.regular)
        g.print(rank, w - UI.fonts.regular:getWidth(rank) - 8, h - 24)
        local slots = (Equipment and Equipment.MAX_SLOTS) or 3
        for i = 1, slots do
            local eq = card.equipments and card.equipments[i]
            local sx = w / 2 + (i - (slots + 1) / 2) * 15
            local col = eq and (eq.color or UI.COLORS.goldYellow) or UI.COLORS.cardBorder
            g.setColor(col)
            g.polygon(eq and "fill" or "line", sx, 6, sx + 4, 10, sx, 14, sx - 4, 10)
        end
        if card.seal then
            g.setColor(UI.COLORS.goldYellow)
            g.circle("fill", w - 14, 16, 7)
            g.setColor(UI.COLORS.textDark)
            g.setFont(UI.fonts.tiny)
            g.printf(tostring(card.seal):sub(1, 1):upper(), w - 21, 9, 14, "center")
        end
        if card.baseChips then
            g.setColor(accent)
            UI.drawRoundedRect("fill", 6, h - 26, 32, 19, 4)
            g.setColor(UI.COLORS.textLight)
            g.setFont(UI.fonts.tiny)
            g.printf("+" .. tostring(card.baseChips), 6, h - 23, 32, "center")
        end
    end
    g.pop()
end


-- Procedural Grimdark Relic / Patron Sigils
function UI.drawRelicSigil(sigilId, cx, cy, size, color)
    love.graphics.push("all")
    love.graphics.setColor(color or { 0.9, 0.8, 0.3, 1 })

    local s = sigilId or ""

    if s:find("pair") or s:find("gemini") or s == "deity_pairs" then
        -- Twin Grotesque Linked Masks (Song Hồn Cổ Linh)
        local r = size * 0.40
        -- Mask 1 (Left: menacing grin)
        love.graphics.setColor(0.75, 0.25, 0.35, 1)
        love.graphics.circle("fill", cx - r * 0.55, cy - 2, r)
        love.graphics.setColor(0.12, 0.08, 0.10, 1)
        love.graphics.circle("fill", cx - r * 0.75, cy - 4, r * 0.22)
        love.graphics.circle("fill", cx - r * 0.35, cy - 4, r * 0.22)
        love.graphics.arc("line", "open", cx - r * 0.55, cy + 2, r * 0.45, 0, math.pi)

        -- Mask 2 (Right: weeping sorrow)
        love.graphics.setColor(0.35, 0.55, 0.85, 1)
        love.graphics.circle("fill", cx + r * 0.55, cy + 2, r)
        love.graphics.setColor(0.08, 0.10, 0.14, 1)
        love.graphics.circle("fill", cx + r * 0.35, cy, r * 0.22)
        love.graphics.circle("fill", cx + r * 0.75, cy, r * 0.22)
        love.graphics.arc("line", "open", cx + r * 0.55, cy + 8, r * 0.45, math.pi, 2 * math.pi)

        -- Spectral Chain linking them
        love.graphics.setColor(0.95, 0.85, 0.35, 0.9)
        love.graphics.setLineWidth(1.5)
        love.graphics.line(cx - r * 0.2, cy, cx + r * 0.2, cy)

    elseif s:find("mirror") or s == "deity_mirror" then
        -- Fractured Soul Mirror (Gương Hồn Phản Chiếu)
        local mw, mh = size * 0.65, size * 0.90
        love.graphics.setColor(0.85, 0.75, 0.35, 1)
        UI.drawRoundedRect("fill", cx - mw / 2, cy - mh / 2, mw, mh, 5)
        love.graphics.setColor(0.12, 0.16, 0.22, 1)
        UI.drawRoundedRect("fill", cx - mw / 2 + 2, cy - mh / 2 + 2, mw - 4, mh - 4, 4)
        -- Mirror glass sheen
        love.graphics.setColor(0.35, 0.55, 0.75, 0.5)
        love.graphics.polygon("fill", cx - mw / 2 + 3, cy + 4, cx, cy - mh / 2 + 3, cx + 4, cy - mh / 2 + 3, cx - mw / 2 + 3, cy + 8)
        -- Fracture Crack
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(0.98, 0.92, 0.85, 0.95)
        love.graphics.line(cx - 4, cy - mh / 2 + 3, cx + 2, cy - 2, cx - 3, cy + 4, cx + 5, cy + mh / 2 - 3)
        -- Ethereal eye inside
        love.graphics.setColor(0.20, 0.85, 0.95, 0.9)
        love.graphics.circle("fill", cx, cy, 3)

    elseif s:find("genesis") or s == "deity_genesis" then
        -- Primordial Ouroboros Serpent & Eye (Nguyên Tội Cổ Thần)
        love.graphics.setLineWidth(3)
        love.graphics.setColor(0.88, 0.22, 0.25, 0.95)
        love.graphics.circle("line", cx, cy, size * 0.40)
        -- Eye in center
        love.graphics.setColor(0.98, 0.85, 0.22, 1)
        love.graphics.circle("fill", cx, cy, 5)
        love.graphics.setColor(0.10, 0.08, 0.08, 1)
        love.graphics.rectangle("fill", cx - 1, cy - 4, 2, 8)

    elseif s:find("hearts") or s == "deity_hearts" then
        -- Blood Altar & Sacrificial Flame (Tế Đàn Huyết Cơ)
        local aw, ah = size * 0.7, size * 0.35
        love.graphics.setColor(0.24, 0.18, 0.20, 1)
        love.graphics.rectangle("fill", cx - aw / 2, cy + 2, aw, ah, 2)
        -- Chalice & Crimson Fire
        love.graphics.setColor(0.88, 0.65, 0.22, 1)
        love.graphics.polygon("fill", cx - 7, cy + 2, cx + 7, cy + 2, cx, cy + 9)
        love.graphics.setColor(0.85, 0.15, 0.22, 1)
        love.graphics.circle("fill", cx, cy - 4, 6)
        love.graphics.setColor(1, 0.65, 0.20, 1)
        love.graphics.circle("fill", cx, cy - 5, 3.5)

    elseif s:find("golden") or s == "deity_golden" or s:find("diamonds") or s == "deity_diamonds" then
        -- Midas Skeletal Hand & Gold Coins (Thổ Phỉ Hoàng Kim)
        love.graphics.setColor(0.95, 0.80, 0.22, 1)
        love.graphics.circle("fill", cx, cy - 3, 7)
        love.graphics.circle("fill", cx - 7, cy + 4, 6)
        love.graphics.circle("fill", cx + 7, cy + 4, 6)
        love.graphics.setColor(0.12, 0.08, 0.04, 1)
        love.graphics.circle("fill", cx, cy - 3, 4)
        love.graphics.circle("fill", cx - 7, cy + 4, 3.5)
        love.graphics.circle("fill", cx + 7, cy + 4, 3.5)

    elseif s:find("clubs") or s == "deity_clubs" then
        -- Demonic Claw Slashes (Vuốt Quỷ Nguyên Sinh)
        love.graphics.setLineWidth(2.5)
        love.graphics.setColor(0.22, 0.85, 0.45, 1)
        love.graphics.line(cx - 10, cy - 12, cx - 6, cy + 12)
        love.graphics.line(cx - 2, cy - 14, cx + 2, cy + 14)
        love.graphics.line(cx + 6, cy - 12, cx + 10, cy + 12)

    elseif s:find("spades") or s == "deity_spades" then
        -- Plunged Iron Greatsword (Thiết Quân Hắc Kiếm)
        love.graphics.setColor(0.85, 0.88, 0.92, 1)
        love.graphics.polygon("fill", cx - 3, cy - 14, cx + 3, cy - 14, cx, cy + 10)
        love.graphics.setColor(0.95, 0.75, 0.22, 1)
        love.graphics.rectangle("fill", cx - 8, cy - 14, 16, 3)
        love.graphics.circle("fill", cx, cy - 17, 2.5)

    elseif s:find("formation") or s == "deity_formation" then
        -- War Banner Standard (Chiến Trận Quân Kỳ)
        love.graphics.setColor(0.45, 0.50, 0.55, 1)
        love.graphics.rectangle("fill", cx - 2, cy - 14, 4, 28)
        love.graphics.setColor(0.85, 0.22, 0.28, 1)
        love.graphics.polygon("fill", cx + 2, cy - 13, cx + 14, cy - 7, cx + 2, cy - 1)

    elseif s:find("elite") or s == "deity_elite" then
        -- Spectral Skull in Helm (Linh Hồn Tử Sĩ)
        love.graphics.setColor(0.88, 0.90, 0.95, 0.95)
        love.graphics.circle("fill", cx, cy - 2, 8)
        love.graphics.rectangle("fill", cx - 4, cy + 4, 8, 5)
        love.graphics.setColor(0.10, 0.12, 0.16, 1)
        love.graphics.circle("fill", cx - 3, cy - 2, 2)
        love.graphics.circle("fill", cx + 3, cy - 2, 2)

    elseif s:find("banner") or s == "deity_banner" then
        -- Bloodied War Horn (Huyết Tẩy Tàn Quân)
        love.graphics.setColor(0.85, 0.65, 0.25, 1)
        love.graphics.polygon("fill", cx - 12, cy + 6, cx + 10, cy - 10, cx + 12, cy - 6, cx - 10, cy + 10)

    elseif s:find("floral") or s == "deity_floral" then
        -- Wilted Dark Rose (Héo Mòn Hoa Độc)
        love.graphics.setColor(0.75, 0.12, 0.18, 1)
        love.graphics.circle("fill", cx, cy - 3, 7)
        love.graphics.circle("fill", cx - 4, cy - 5, 5)
        love.graphics.circle("fill", cx + 4, cy - 5, 5)
        love.graphics.setColor(0.20, 0.45, 0.25, 1)
        love.graphics.line(cx, cy + 3, cx, cy + 14)

    elseif s:find("fruit") or s == "deity_sacred_fruit" then
        -- Eldritch Forbidden Fruit (Cấm Quả Hỗn Mang)
        love.graphics.setColor(0.85, 0.25, 0.35, 1)
        love.graphics.circle("fill", cx, cy, 9)
        love.graphics.setColor(0.25, 0.10, 0.12, 1)
        love.graphics.line(cx - 3, cy - 3, cx + 3, cy + 3)
        love.graphics.line(cx + 3, cy - 3, cx - 3, cy + 3)

    elseif s:find("tree") or s == "deity_eternal_tree" then
        -- World Tree Silhouette (Bất Diệt Cổ Thụ)
        love.graphics.setColor(0.95, 0.85, 0.25, 1)
        love.graphics.circle("fill", cx, cy - 4, 11)
        love.graphics.setColor(0.10, 0.11, 0.13, 1)
        love.graphics.rectangle("fill", cx - 2, cy - 2, 4, 14)

    elseif s:find("echo") or s == "deity_echo" then
        -- Concentric Echo Waves (Vọng Âm Trùng Điệp)
        love.graphics.setLineWidth(1.8)
        love.graphics.setColor(0.45, 0.75, 0.95, 0.9)
        love.graphics.arc("line", "open", cx, cy, 6, -math.pi * 0.4, math.pi * 0.4)
        love.graphics.arc("line", "open", cx, cy, 11, -math.pi * 0.4, math.pi * 0.4)
        love.graphics.arc("line", "open", cx, cy, 16, -math.pi * 0.4, math.pi * 0.4)
    else
        -- Default: Occult Runic Seal
        love.graphics.setLineWidth(1.5)
        love.graphics.circle("line", cx, cy, size * 0.38)
        love.graphics.polygon("line", cx, cy - size * 0.35, cx + size * 0.30, cy + size * 0.20, cx - size * 0.30, cy + size * 0.20)
    end

    love.graphics.pop()
end

-- Deterministic faceted emblem for catalogue/shop items without raster art.
function UI.drawItemEmblem(item, cx, cy, size, color)
    local g = love.graphics
    local id = tostring((item and (item.id or item.name)) or "relic")
    local seed = 0
    for i = 1, #id do seed = (seed * 33 + id:byte(i)) % 997 end
    local c = color or UI.COLORS.goldYellow
    local sides = 5 + seed % 3
    local points = {}
    local inner = {}
    for i = 1, sides do
        local a = (i - 1) * math.pi * 2 / sides - math.pi / 2
        local radius = size * (0.78 + ((seed + i * 7) % 5) * 0.045)
        points[i] = { cx + math.cos(a) * radius, cy + math.sin(a) * radius }
        inner[i] = { cx + math.cos(a) * size * 0.32, cy + math.sin(a) * size * 0.32 }
    end
    g.push("all")
    for i = 1, sides do
        local j = i % sides + 1
        local shade = (i % 2 == 0) and 0.68 or 1
        g.setColor(c[1] * shade, c[2] * shade, c[3] * shade, 0.9)
        g.polygon("fill", cx, cy, points[i][1], points[i][2], points[j][1], points[j][2])
    end
    g.setColor(1, 1, 1, 0.4)
    g.polygon("fill", inner[1][1], inner[1][2], inner[2][1], inner[2][2], cx, cy)
    g.setColor(0.06, 0.10, 0.12, 0.7)
    g.circle("fill", cx, cy, size * 0.12)
    g.pop()
end

-- Cache and loader for authentic deity card artwork
UI.deityImages = UI.deityImages or {}

function UI.getDeityImage(deityId)
    if not deityId then return nil end
    if UI.deityImages[deityId] ~= nil then
        return UI.deityImages[deityId] or nil
    end
    if love and love.graphics and love.graphics.newImage and love.filesystem and love.filesystem.getInfo then
        local path = "assets/deities/" .. deityId .. ".png"
        local okInfo, info = pcall(love.filesystem.getInfo, path)
        if okInfo and info then
            local okImg, img = pcall(love.graphics.newImage, path)
            if okImg and img then
                if img.setFilter then
                    img:setFilter("nearest", "nearest")
                end
                UI.deityImages[deityId] = img
                return img
            end
        end
    end
    UI.deityImages[deityId] = false
    return nil
end

-- Cache and loader for authentic equipment card artwork
UI.equipmentImages = UI.equipmentImages or {}

function UI.getEquipmentImage(equipId)
    if not equipId then return nil end
    if UI.equipmentImages[equipId] ~= nil then
        return UI.equipmentImages[equipId] or nil
    end
    if love and love.graphics and love.graphics.newImage and love.filesystem and love.filesystem.getInfo then
        local path = "assets/equipment/" .. equipId .. ".png"
        local okInfo, info = pcall(love.filesystem.getInfo, path)
        if okInfo and info then
            local okImg, img = pcall(love.graphics.newImage, path)
            if okImg and img then
                if img.setFilter then
                    img:setFilter("nearest", "nearest")
                end
                UI.equipmentImages[equipId] = img
                return img
            end
        end
    end
    UI.equipmentImages[equipId] = false
    return nil
end

-- Cache and loader for authentic pack artwork
UI.packImages = UI.packImages or {}

local PACK_TYPE_MAP = {
    buffoon = "pack_buffoon",
    pack_buffoon = "pack_buffoon",
    spm_pack = "pack_buffoon",
    spm = "pack_buffoon",

    arcana = "pack_arcana",
    pack_arcana = "pack_arcana",
    itm_pack = "pack_arcana",
    itm = "pack_arcana",

    standard = "pack_standard",
    pack_standard = "pack_standard",
    card_pack = "pack_standard",
    card = "pack_standard",

    joker_edition = "pack_joker_edition",
    pack_joker_edition = "pack_joker_edition",
    enchantment_pack = "pack_joker_edition",
    enchantment = "pack_joker_edition",

    seal = "pack_seal",
    pack_seal = "pack_seal",
    seal_pack = "pack_seal",

    spectral = "pack_spectral",
    pack_spectral = "pack_spectral",
    transformation_pack = "pack_spectral",
    transformation = "pack_spectral",

    celestial = "pack_celestial",
    pack_celestial = "pack_celestial",
    planet_pack = "pack_celestial",
    planet = "pack_celestial",
}

function UI.getPackImage(packId)
    if not packId then return nil end
    local mapped = PACK_TYPE_MAP[packId] or packId
    if UI.packImages[mapped] ~= nil then
        return UI.packImages[mapped] or nil
    end
    if love and love.graphics and love.graphics.newImage and love.filesystem and love.filesystem.getInfo then
        local candidates = {
            "assets/scene/treasure_chest.png",
            "assets/packs/" .. mapped .. ".png",
            "assets/packs/" .. packId .. ".png",
        }
        for _, path in ipairs(candidates) do
            local okInfo, info = pcall(love.filesystem.getInfo, path)
            if okInfo and info then
                local okImg, img = pcall(love.graphics.newImage, path)
                if okImg and img then
                    if img.setFilter then img:setFilter("linear", "linear") end
                    UI.packImages[mapped] = img
                    return img
                end
            end
        end
    end
    UI.packImages[mapped] = false
    return nil
end

-- Cache and loader for authentic poker hand / martial arts cards (9 hand types)
UI.handImages = UI.handImages or {}

local HAND_ALIAS_MAP = {
    straight_flush = "straight_flush",
    four_of_a_kind = "four_of_a_kind",
    full_house = "full_house",
    flush = "flush",
    straight = "straight",
    three_of_a_kind = "three_of_a_kind",
    two_pair = "two_pair",
    pair = "pair",
    high_card = "high_card",

    van_kiem_quy_ton = "straight_flush",
    van_kiem_quy_tong = "straight_flush",
    tu_tuong = "four_of_a_kind",
    hon_nguyen = "full_house",
    dong_khi = "flush",
    truong_long = "straight",
    tam_hoa = "three_of_a_kind",
    song_doi = "two_pair",
    song_dao = "pair",
    don_thu = "high_card",

    book_straight_flush = "straight_flush",
    book_four_of_a_kind = "four_of_a_kind",
    book_full_house = "full_house",
    book_flush = "flush",
    book_straight = "straight",
    book_three_of_a_kind = "three_of_a_kind",
    book_two_pair = "two_pair",
    book_pair = "pair",
    book_high_card = "high_card",

    hand_straight_flush = "straight_flush",
    hand_four_of_a_kind = "four_of_a_kind",
    hand_full_house = "full_house",
    hand_flush = "flush",
    hand_straight = "straight",
    hand_three_of_a_kind = "three_of_a_kind",
    hand_two_pair = "two_pair",
    hand_pair = "pair",
    hand_high_card = "high_card",
}

function UI.getHandImage(handId)
    if not handId then return nil end
    local mapped = HAND_ALIAS_MAP[handId] or handId
    if UI.handImages[mapped] ~= nil then
        return UI.handImages[mapped] or nil
    end
    if love and love.graphics and love.graphics.newImage and love.filesystem and love.filesystem.getInfo then
        local candidates = {
            "assets/hands/hand_" .. mapped .. ".png",
            "assets/hands/" .. mapped .. ".png",
            "assets/hands/" .. handId .. ".png",
        }
        for _, path in ipairs(candidates) do
            local okInfo, info = pcall(love.filesystem.getInfo, path)
            if okInfo and info then
                local okImg, img = pcall(love.graphics.newImage, path)
                if okImg and img then
                    if img.setFilter then
                        img:setFilter("nearest", "nearest")
                    end
                    UI.handImages[mapped] = img
                    return img
                end
            end
        end
    end
    UI.handImages[mapped] = false
    return nil
end

-- Cache and loader for authentic voucher / hand expansion artwork
UI.voucherImages = UI.voucherImages or {}

local VOUCHER_ALIAS_MAP = {
    v_hand_size = "v_hand_size",
    hand_expansion = "v_hand_size",
    mo_rong_tay_bai = "v_hand_size",
    ["Mở Rộng Tay Bài"] = "v_hand_size",
}

function UI.getVoucherImage(voucherId)
    if not voucherId then return nil end
    local mapped = VOUCHER_ALIAS_MAP[voucherId] or voucherId
    if UI.voucherImages[mapped] ~= nil then
        return UI.voucherImages[mapped] or nil
    end
    if love and love.graphics and love.graphics.newImage and love.filesystem and love.filesystem.getInfo then
        local candidates = {
            "assets/vouchers/" .. mapped .. ".png",
            "assets/vouchers/" .. voucherId .. ".png",
            "assets/hands/" .. mapped .. ".png",
            "assets/cards/" .. mapped .. ".png",
        }
        for _, path in ipairs(candidates) do
            local okInfo, info = pcall(love.filesystem.getInfo, path)
            if okInfo and info then
                local okImg, img = pcall(love.graphics.newImage, path)
                if okImg and img then
                    if img.setFilter then
                        img:setFilter("nearest", "nearest")
                    end
                    UI.voucherImages[mapped] = img
                    return img
                end
            end
        end
    end
    UI.voucherImages[mapped] = false
    return nil
end

-- Cache and loader for authentic playing card artwork (52 cards)
UI.cardImages = UI.cardImages or {}

local SUIT_ALIAS_MAP = {
    hearts = "hearts",
    valoria = "hearts",
    sanguine_covenant = "hearts",

    diamonds = "diamonds",
    aurelia = "diamonds",
    gilded_conclave = "diamonds",

    clubs = "clubs",
    elaris = "clubs",
    feral_swarm = "clubs",

    spades = "spades",
    vharos = "spades",
    iron_axiom = "spades",
}

local RANK_ALIAS_MAP = {
    [1] = "A",
    [14] = "A",
    ["1"] = "A",
    ["14"] = "A",
    ["A"] = "A",
    ["Ace"] = "A",
    [11] = "J",
    ["11"] = "J",
    ["J"] = "J",
    ["Jack"] = "J",
    [12] = "Q",
    ["12"] = "Q",
    ["Q"] = "Q",
    ["Queen"] = "Q",
    [13] = "K",
    ["13"] = "K",
    ["K"] = "K",
    ["King"] = "K",
}

function UI.getCardImage(suit, rank)
    if not suit or not rank then return nil end
    local s = SUIT_ALIAS_MAP[suit] or suit
    local r = RANK_ALIAS_MAP[rank] or tostring(rank)
    local key = s .. "_" .. r
    if UI.cardImages[key] ~= nil then
        return UI.cardImages[key] or nil
    end
    if love and love.graphics and love.graphics.newImage and love.filesystem and love.filesystem.getInfo then
        local candidates = {
            "assets/cards/" .. key .. ".png",
            "assets/cards/" .. suit .. "_" .. r .. ".png",
        }
        for _, path in ipairs(candidates) do
            local okInfo, info = pcall(love.filesystem.getInfo, path)
            if okInfo and info then
                local okImg, img = pcall(love.graphics.newImage, path)
                if okImg and img then
                    if img.setFilter then
                        img:setFilter("nearest", "nearest")
                    end
                    UI.cardImages[key] = img
                    return img
                end
            end
        end
    end
    UI.cardImages[key] = false
    return nil
end

-- Presentation-only terminology: combat IDs and saved data keep their stable names.
function UI.localizeText(value)
    if type(value) ~= "string" then return value end
    return value
        :gsub("SMALL BLIND", "QUÁI THƯỜNG")
        :gsub("BIG BLIND", "QUÁI TINH ANH")
        :gsub("BOSS BLIND", "QUÁI THỦ LĨNH")
        :gsub("Small Blind", "Quái Thường")
        :gsub("Big Blind", "Quái Tinh Anh")
        :gsub("Boss Blind", "Quái Thủ Lĩnh")
        :gsub("BLIND", "QUÁI")
        :gsub("Blind", "Quái")
        :gsub("ANTE", "ẢI")
        :gsub("Ante", "Ải")
        :gsub("ante", "ải")
        :gsub("HỘ LINH", "SPM")
        :gsub("Hộ Linh", "SPM")
        :gsub("hộ linh", "SPM")
        :gsub("JOKER", "SPM")
        :gsub("Joker", "SPM")
        :gsub("Straight Flush", "Thùng Phá Sảnh")
        :gsub("Four of a Kind", "Tứ Quý")
        :gsub("Full House", "Cù Lũ")
        :gsub("Two Pair", "Hai Đôi")
        :gsub("Three of a Kind", "Sám Cô")
        :gsub("High Card", "Đơn Thủ")
        :gsub("Straight", "Sảnh")
        :gsub("Flush", "Thùng")
        :gsub("Pair", "Đôi")
        :gsub("XMult", "Hệ số")
        :gsub("CHIPS", "SÁT THƯƠNG")
        :gsub("Chips", "Sát thương")
        :gsub("%f[%a]chips%f[%A]", "sát thương")
        :gsub("MULT", "CƯỜNG HÓA")
        :gsub("Mult", "Cường hóa")
        :gsub("%f[%a]mult%f[%A]", "cường hóa")
        :gsub("BOOSTER", "RƯƠNG")
        :gsub("Booster", "Rương")
        :gsub("GÓI", "RƯƠNG")
        :gsub("Gói", "Rương")
        :gsub(" DMG", " ST")
        :gsub("MENU", "TÙY CHỌN")
end

-- Render each reward as its own material card, without reverting to pixel sprites.
UI.packRewardImages = UI.packRewardImages or {}
function UI.getPackCardImage(packType, card)
    card = card or {}
    if not UI.useLegacyPixelArt and love.graphics.newCanvas then
        local key = table.concat({ tostring(packType), tostring(card.id or card.handId or card.name or ""),
            tostring(card.rank or ""), tostring(card.suit or "") }, ":")
        if UI.packRewardImages[key] then return UI.packRewardImages[key], true end
        local g = love.graphics
        local canvas = g.newCanvas(128, 176)
        canvas:setFilter("linear", "linear")
        local previousCanvas = g.getCanvas()
        g.push("all")
        g.setCanvas(canvas)
        g.clear(0, 0, 0, 0)
        g.origin()
        if packType == "standard" then
            UI.drawCard(card, 0, 0, 128, 176)
        elseif packType == "buffoon" then
            UI.drawPatronCard(card, 0, 0, 128, 176)
        else
            local col = card.color or UI.COLORS.chipsBlue
            g.setColor(0.13, 0.19, 0.21, 1)
            UI.drawRoundedRect("fill", 0, 0, 128, 176, 6)
            g.setColor(col)
            UI.drawRoundedRect("line", 1, 1, 126, 174, 6)
            g.polygon("fill", 64, 34, 102, 87, 64, 140, 26, 87)
            g.setColor(1, 1, 1, 0.30)
            g.polygon("fill", 64, 34, 102, 87, 64, 87, 26, 87)
            g.setFont(UI.fonts.tiny)
            g.setColor(UI.COLORS.textLight)
            g.printf(UI.toUpperUtf8(UI.truncateUtf8(card.name or "VẬT PHẨM", 20)), 7, 8, 114, "center")
        end
        g.setCanvas(previousCanvas)
        g.pop()
        UI.packRewardImages[key] = canvas
        return canvas, true
    end
    if packType == "buffoon" then
        local image = UI.getDeityImage(card.id)
        if image then return image, true end
    elseif packType == "standard" then
        local image = UI.getCardImage(card.suit, card.rank or card.rankName)
        if image then return image, true end
    elseif packType == "arcana" then
        local image = UI.getEquipmentImage(card.id)
        if image then return image, true end
    elseif packType == "celestial" then
        local image = UI.getHandImage(card.handId or card.id)
        if image then return image, true end
    end
    return UI.getPackImage(packType), false
end



-- Full Tarot Card Frame for Hộ Linh (Patrons)

function UI.drawPatronCard(d, x, y, w, h, isHovered, isPressed, isDropTarget, copyTarget)
    if not d then return end
    w, h = w or 82, h or 118
    local g = love.graphics
    local rim = d.rarity == "legendary" and UI.COLORS.goldYellow
        or (d.rarity == "rare" and UI.COLORS.chipsBlue or UI.COLORS.panelBorder)
    local s = isPressed and 0.98 or (isHovered and 1.04 or 1)
    g.push("all")
    g.translate(x + w / 2, y + h / 2)
    g.scale(s)
    g.translate(-w / 2, -h / 2)
    g.setColor(0, 0, 0, 0.35)
    UI.drawRoundedRect("fill", 3, 5, w, h, 5)
    g.setColor(0.13, 0.18, 0.20, 0.98)
    UI.drawRoundedRect("fill", 0, 0, w, h, 5)
    g.setColor(rim[1], rim[2], rim[3], 0.25)
    g.polygon("fill", 4, 4, w - 4, 4, w * 0.66, h * 0.52, 4, h * 0.62)
    g.setColor(rim)
    g.setLineWidth(isHovered and 2 or 1)
    UI.drawRoundedRect("line", 0, 0, w, h, 5)
    g.setFont(UI.fonts.tiny)
    g.setColor(UI.COLORS.textLight)
    local name = w < 75 and UI.truncateUtf8(d.name or "SPM", 9) or (d.name or "SPM")
    g.printf(UI.toUpperUtf8(name), 5, 8, w - 10, "center")
    g.setColor(rim[1], rim[2], rim[3], 0.16)
    g.circle("fill", w / 2, h * 0.55, w * 0.27)
    UI.drawRelicSigil(d.id, w / 2, h * 0.55, math.min(w * 0.38, h * 0.33), rim)
    g.setColor(rim)
    g.polygon("fill", w / 2, h - 13, w / 2 + 4, h - 9, w / 2, h - 5, w / 2 - 4, h - 9)
    if d.edition then
        g.setFont(UI.fonts.tiny)
        g.setColor(UI.COLORS.goldYellow)
        local editionLabel = ({ negative = "NEG", polychrome = "POLY", holo = "HOLO", foil = "FOIL" })[d.edition] or d.edition
        g.printf(UI.toUpperUtf8(editionLabel), 3, h - 26, w - 6, "center")
    end
    if isDropTarget then
        g.setColor(0.04, 0.08, 0.09, 0.86)
        UI.drawRoundedRect("fill", 3, 3, w - 6, h - 6, 4)
        g.setFont(UI.fonts.tiny)
        g.setColor(UI.COLORS.goldYellow)
        g.printf("HOÁN ĐỔI", 3, h / 2 - 9, w - 6, "center")
    end
    g.pop()
end

-- Rich Floating Tooltip for Hộ Linh (Patrons)
function UI.drawPatronTooltip(d, mx, my, copyTarget)
    if not d then return end
    local ttW = 310
    local ttH = 110
    local ttx = math.min(1280 - ttW - 12, math.max(12, mx + 14))
    local tty = math.min(720 - ttH - 12, math.max(12, my + 18))

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.75)
    UI.drawRoundedRect("fill", ttx + 4, tty + 5, ttW, ttH, 7)

    -- Background: Deep Void Obsidian Parchment
    love.graphics.setColor(0.08, 0.09, 0.11, 0.98)
    UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 7)

    -- Gilded Frame & Corner Brackets
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(0.78, 0.65, 0.22, 0.95)
    UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 7)

    -- Rarity badge string & color
    local rText = "[THƯỜNG]"
    local rCol = { 0.70, 0.75, 0.82, 1 }
    if d.rarity == "uncommon" then
        rText = "[HIẾM]"
        rCol = { 0.22, 0.82, 0.45, 1 }
    elseif d.rarity == "rare" then
        rText = "[CỰC PHẨM]"
        rCol = { 0.25, 0.65, 1.0, 1 }
    elseif d.rarity == "legendary" then
        rText = "[TRUYỀN THUYẾT]"
        rCol = { 0.98, 0.82, 0.22, 1 }
    end

    -- Line 1: Title & Rarity
    love.graphics.setFont(UI.fonts.medium)
    love.graphics.setColor(0.98, 0.88, 0.45, 1)
    love.graphics.print(d.name, ttx + 12, tty + 8)

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(rCol)
    local rW = UI.fonts.small:getWidth(rText)
    love.graphics.print(rText, ttx + ttW - rW - 12, tty + 13)

    -- Divider Line
    love.graphics.setLineWidth(1)
    love.graphics.setColor(0.35, 0.30, 0.22, 0.8)
    love.graphics.line(ttx + 10, tty + 36, ttx + ttW - 10, tty + 36)

    -- Line 2: Mechanics Description
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(0.94, 0.95, 0.98, 1)
    local desc = d.desc or ""
    if d.isCopyDeity then
        desc = copyTarget and ("Sao chép năng lực của " .. copyTarget.name) or "Đặt bên trái 1 Hộ Linh khác để sao chép"
    end
    love.graphics.printf(desc, ttx + 12, tty + 42, ttW - 24, "left")

    -- Line 3: Grimdark Lore Flavor Quote
    local lore = d.lore or "Một tàn tích cổ xưa thì thầm trong bóng đêm vô tận..."
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(0.62, 0.58, 0.52, 0.85)
    love.graphics.printf('"' .. lore .. '"', ttx + 12, tty + 84, ttW - 24, "left")
end

function UI.drawMonsterHpBar(x, y, w, h, currentHp, maxHp, damageLagHp)
    -- Background bar
    love.graphics.setColor(0.12, 0.14, 0.16, 0.95)
    UI.drawRoundedRect("fill", x, y, w, h, 6)

    local maxH = math.max(1, maxHp)
    -- Damage lag bar (yellow/red trailing bar)
    if damageLagHp and damageLagHp > currentHp then
        local lagRatio = math.min(1.0, math.max(0.0, damageLagHp / maxH))
        love.graphics.setColor(0.9, 0.45, 0.1, 0.85)
        UI.drawRoundedRect("fill", x, y, w * lagRatio, h, 6)
    end

    -- Current HP Fill (Green fading to red)
    local ratio = math.min(1.0, math.max(0.0, currentHp / maxH))
    if ratio > 0 then
        if ratio > 0.5 then
            love.graphics.setColor(UI.COLORS.hpGreen)
        elseif ratio > 0.25 then
            love.graphics.setColor(UI.COLORS.goldYellow)
        else
            love.graphics.setColor(UI.COLORS.hpRed)
        end
        UI.drawRoundedRect("fill", x, y, w * ratio, h, 6)
    end

    -- Border
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.35, 0.45, 0.5, 1)
    UI.drawRoundedRect("line", x, y, w, h, 6)

    -- HP Text inside bar
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    local hpText = currentHp .. " / " .. maxHp .. " HP"
    local tw = UI.fonts.small:getWidth(hpText)
    love.graphics.print(hpText, x + (w - tw) / 2, y + (h - 16) / 2)
end

function UI.drawPlayerHpBar(x, y, w, h, currentHp, maxHp, shield)
    currentHp = math.max(0, currentHp or 100)
    maxHp = maxHp or 100
    shield = shield or 0

    -- Background
    love.graphics.setColor(0.1, 0.13, 0.16, 0.95)
    UI.drawRoundedRect("fill", x, y, w, h, 6)

    -- Fill bar
    local pct = math.min(1.0, math.max(0.0, currentHp / maxHp))
    local fillW = math.floor((w - 4) * pct)
    if fillW > 0 then
        if pct > 0.5 then
            love.graphics.setColor(0.2, 0.8, 0.4, 0.95)
        elseif pct > 0.25 then
            love.graphics.setColor(0.95, 0.8, 0.2, 0.95)
        else
            love.graphics.setColor(0.85, 0.2, 0.2, 0.95)
        end
        UI.drawRoundedRect("fill", x + 2, y + 2, fillW, h - 4, 4)
    end

    -- Border
    love.graphics.setColor(0.3, 0.4, 0.48, 1)
    love.graphics.setLineWidth(1.5)
    UI.drawRoundedRect("line", x, y, w, h, 6)

    -- Text
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    local hpText = "MÁU: " .. currentHp .. " / " .. maxHp .. " HP"
    if shield > 0 then
        hpText = hpText .. " (GIÁP: +" .. shield .. ")"
    end
    local tw = UI.fonts.small:getWidth(hpText)
    love.graphics.print(hpText, x + (w - tw) / 2, y + (h - 16) / 2)
end

-- Format numbers with commas (e.g. 1,234,567) or scientific e-notation (e.g. 1.234e12)
function UI.formatNumber(num)
    if not num then return "0" end
    local absVal = math.abs(num)
    local sign = (num < 0) and "-" or ""

    -- Scientific e-notation when >= 1 Billion (1e9)
    if absVal >= 1e9 then
        local exp = math.floor(math.log10(absVal))
        local mantissa = absVal / (10 ^ exp)
        return string.format("%s%.3fe%d", sign, mantissa, exp)
    end

    if absVal % 1 ~= 0 and absVal < 100 then
        return string.format("%s%.1f", sign, absVal)
    end

    local n = math.floor(absVal)
    local formatted = tostring(n)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return sign .. formatted
end

-- Draw Balatro-style hover badge above hand card
function UI.drawCardHoverBadge(card, cx, cy, cardW, cardH)
    if not card or card.faceDown then return end
    local bw = 108
    local bh = 46
    local bx = cx + (cardW - bw) / 2
    local by = cy - bh - 8

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.4)
    UI.drawRoundedRect("fill", bx + 2, by + 2, bw, bh, 6)

    -- Background
    love.graphics.setColor(0.10, 0.12, 0.16, 0.96)
    UI.drawRoundedRect("fill", bx, by, bw, bh, 6)
    love.graphics.setLineWidth(1.5)
    love.graphics.setColor(0.40, 0.50, 0.62, 0.9)
    UI.drawRoundedRect("line", bx, by, bw, bh, 6)

    -- Top Section: Rank & Suit
    love.graphics.setFont(UI.fonts.small)
    local sColor = UI.COLORS[card.suit] or UI.COLORS.goldYellow
    love.graphics.setColor(sColor)
    local suitShort = (card.suit == "aurelia") and "Thánh" or ((card.suit == "elaris") and "Mộc" or ((card.suit == "vharos") and "Quỷ" or "Thép"))
    local titleStr = UI.sanitizeText(card.rankName .. " " .. (card.suitSymbol or "") .. " (" .. suitShort .. ")")
    love.graphics.printf(titleStr, bx, by + 4, bw, "center")

    -- Divider
    love.graphics.setColor(0.25, 0.32, 0.40, 0.7)
    love.graphics.line(bx + 6, by + 24, bx + bw - 6, by + 24)

    -- Bottom Section: +Chips / Equipment bonus
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.chipsBlue)
    local chipStr = "+" .. (card.baseChips or 0) .. " chip"
    if card.equipments and #card.equipments > 0 then
        local eqMult = 0
        for _, eq in ipairs(card.equipments) do
            if eq.addedMult then eqMult = eqMult + eq.addedMult end
        end
        if eqMult > 0 then
            chipStr = chipStr .. " / +" .. eqMult .. "m"
        end
    end
    love.graphics.printf(chipStr, bx, by + 28, bw, "center")
end

-- Center-anchored dynamic scaling number rendering
function UI.drawAnimatedNumber(text, bx, by, bw, bh, color, scaleFactor)
    scaleFactor = scaleFactor or 1.0
    local font = UI.fonts.huge
    if font:getWidth(text) > (bw - 16) then
        font = UI.fonts.large
    end
    if font:getWidth(text) > (bw - 16) then
        font = UI.fonts.medium
    end
    love.graphics.setFont(font)
    love.graphics.setColor(color)

    local cx = bx + bw / 2
    local cy = by + 22 + (bh - 22) / 2
    local tw = font:getWidth(text)
    local th = font:getHeight()

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(scaleFactor, scaleFactor)
    love.graphics.print(text, -tw / 2, -th / 2)
    love.graphics.pop()
end

function UI.calculateTilt(mx, my, cx, cy, w, h)
    if not mx or not my or not cx or not cy then return 0, 0 end
    local cardCenterX = cx + (w or 100) / 2
    local cardCenterY = cy + (h or 140) / 2
    local normX = math.max(-1, math.min(1, (mx - cardCenterX) / ((w or 100) * 0.5)))
    local normY = math.max(-1, math.min(1, (my - cardCenterY) / ((h or 140) * 0.5)))
    return normX, normY
end

return UI

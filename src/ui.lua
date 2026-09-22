local UI = {}

-- Color constants
UI.COLORS = {
    bg = { 0.08, 0.12, 0.11, 1 },
    felt = { 0.10, 0.18, 0.14, 1 },
    panelBg = { 0.12, 0.16, 0.18, 0.95 },
    panelBorder = { 0.25, 0.35, 0.38, 1 },
    cardBg = { 0.92, 0.88, 0.80, 1 },
    cardBorder = { 0.52, 0.46, 0.38, 1 },
    cardSelectedBorder = { 0.95, 0.8, 0.1, 1 },
    textLight = { 0.95, 0.96, 0.98, 1 },
    textDark = { 0.15, 0.15, 0.18, 1 },
    textMuted = { 0.68, 0.74, 0.80, 1 },
    chipsBlue = { 0.18, 0.55, 0.92, 1 },
    multRed = { 0.78, 0.12, 0.18, 1 },
    suitCrimson = { 0.78, 0.12, 0.18, 1 },
    suitObsidian = { 0.11, 0.12, 0.15, 1 },
    xmultGold = { 0.95, 0.72, 0.12, 1 },
    goldYellow = { 0.98, 0.85, 0.25, 1 },
    hpGreen = { 0.2, 0.8, 0.3, 1 },
    hpRed = { 0.85, 0.2, 0.2, 1 },
    bossPurple = { 0.85, 0.25, 0.8, 1 },
    btnPlay = { 0.18, 0.55, 0.92, 1 },
    btnDiscard = { 0.88, 0.28, 0.22, 1 },
    btnConfirm = { 0.18, 0.70, 0.38, 1 },
    btnSpecial = { 0.95, 0.75, 0.18, 1 },
    btnDestruct = { 0.82, 0.22, 0.24, 1 },
    btnNormal = { 0.22, 0.28, 0.35, 1 },
}

UI.fonts = {}

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

    -- 1. Auto-resolve hover & pressed states if omitted
    if isHovered == nil then
        local mx = UI.virtualMouseX
        local my = UI.virtualMouseY
        if not mx and love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        if mx and my then
            isHovered = (mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h)
        else
            isHovered = false
        end
    end
    if isPressed == nil then
        isPressed = (btn.isPressed == true) or (btn.id and btn.id == UI.currentPressedBtnId)
    else
        isPressed = isPressed or (btn.isPressed == true) or (btn.id and btn.id == UI.currentPressedBtnId)
    end

    -- 2. Spring Scale Animation (Hover expansion 1.06x, Click shrink 0.94x)
    btn.animScale = btn.animScale or 1.0
    local targetScale = 1.0
    if btn.disabled then
        targetScale = 1.0
    elseif isPressed then
        targetScale = 0.94
    elseif isHovered then
        targetScale = 1.06
    end
    btn.animScale = btn.animScale + (targetScale - btn.animScale) * 0.28

    -- 3. Mechanical Depression Animation (Instant snap down, spring release)
    btn.pressProgress = btn.pressProgress or 0
    if isPressed and not btn.disabled then
        btn.pressProgress = 1.0
    else
        btn.pressProgress = btn.pressProgress * 0.65
        if btn.pressProgress < 0.01 then btn.pressProgress = 0 end
    end

    -- 4. 3D Mouse Tilt (Perspective shear based on cursor offset from center)
    btn.tiltX = btn.tiltX or 0
    btn.tiltY = btn.tiltY or 0
    if isHovered and not btn.disabled then
        local mx = UI.virtualMouseX
        local my = UI.virtualMouseY
        if not mx and love.mouse and love.mouse.getPosition then
            mx, my = love.mouse.getPosition()
        end
        if mx and my then
            local tx, ty = UI.calculateTilt(mx, my, btn.x, btn.y, btn.w, btn.h)
            btn.tiltX = btn.tiltX + (tx - btn.tiltX) * 0.25
            btn.tiltY = btn.tiltY + (ty - btn.tiltY) * 0.25
        end
    else
        btn.tiltX = btn.tiltX * 0.72
        btn.tiltY = btn.tiltY * 0.72
        if math.abs(btn.tiltX) < 0.001 then btn.tiltX = 0 end
        if math.abs(btn.tiltY) < 0.001 then btn.tiltY = 0 end
    end

    -- 5. Extrusion Depth & Corner Radius
    local depth = 0
    if not btn.disabled then
        if btn.depth then
            depth = btn.depth
        elseif btn.h <= 24 then
            depth = 2
        elseif btn.h <= 36 then
            depth = 3
        elseif btn.h <= 55 then
            depth = 5
        else
            depth = 6
        end
    end
    local r = btn.cornerRadius or math.min(8, math.max(4, math.floor(btn.h * 0.2)))
    local depressY = math.floor(btn.pressProgress * math.max(0, depth - 1) + 0.5)

    -- 6. Color Scheme & Disabled State Handling
    local baseCol = btn.color or UI.COLORS.btnNormal
    local faceColor, baseColor, borderColor, textColor
    if btn.disabled then
        faceColor = { 0.22, 0.25, 0.29, 0.88 }
        baseColor = { 0.16, 0.18, 0.21, 0.88 }
        borderColor = { 0.15, 0.17, 0.20, 0.70 }
        textColor = { 0.48, 0.52, 0.56, 0.85 }
    else
        local bright = isHovered and 1.15 or 1.0
        faceColor = {
            math.min(1.0, baseCol[1] * bright),
            math.min(1.0, baseCol[2] * bright),
            math.min(1.0, baseCol[3] * bright),
            baseCol[4] or 1
        }
        baseColor = {
            baseCol[1] * 0.40,
            baseCol[2] * 0.40,
            baseCol[3] * 0.40,
            baseCol[4] or 1
        }
        if isHovered then
            borderColor = { 1.0, 1.0, 1.0, 0.98 }
        else
            borderColor = { 0.06, 0.08, 0.10, 0.88 }
        end
        textColor = btn.textColor or { 1.0, 1.0, 1.0, 1.0 }
    end

    -- 7. Render Transformation
    local cx = btn.x + btn.w / 2
    local cy = btn.y + btn.h / 2

    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(btn.animScale, btn.animScale)
    if btn.tiltX ~= 0 or btn.tiltY ~= 0 then
        love.graphics.shear(btn.tiltX * 0.045, btn.tiltY * 0.045)
    end
    love.graphics.translate(-cx, -cy)

    -- A. Extruded 3D Base (Chân nút phía dưới dày 3-6px)
    if depth > 0 then
        love.graphics.setColor(baseColor)
        UI.drawRoundedRect("fill", btn.x, btn.y + 2, btn.w, btn.h - 2, r)

        love.graphics.setColor(0.04, 0.05, 0.07, 0.92)
        love.graphics.setLineWidth(1.5)
        UI.drawRoundedRect("line", btn.x, btn.y + 2, btn.w, btn.h - 2, r)
    end

    -- B. Button Face (Mặt trên nút)
    local faceY = btn.y + depressY
    local faceH = btn.h - depth
    if isPressed and depth > 0 then
        faceH = math.max(4, faceH - 1)
    end

    love.graphics.setColor(faceColor)
    UI.drawRoundedRect("fill", btn.x, faceY, btn.w, faceH, r)

    -- Face Top Glossy Highlight (Phản quang mép trên)
    if not btn.disabled and faceH > 10 then
        love.graphics.setColor(1, 1, 1, isHovered and 0.26 or 0.16)
        local hlH = math.max(2, math.min(6, math.floor(faceH * 0.22)))
        UI.drawRoundedRect("fill", btn.x + 2, faceY + 1, btn.w - 4, hlH, math.max(2, r - 2))
    end

    -- Face Bottom Inset Shadow (Rãnh phân tách Face và Base)
    if not btn.disabled and depth > 0 and faceH > 12 then
        love.graphics.setColor(0, 0, 0, 0.24)
        UI.drawRoundedRect("fill", btn.x + 2, faceY + faceH - 3, btn.w - 4, 2, math.max(1, r - 2))
    end

    -- Face Outline (Sáng trắng khi hover, viền đen pixel khi bình thường)
    love.graphics.setLineWidth(isHovered and not btn.disabled and 2.0 or 1.5)
    love.graphics.setColor(borderColor)
    UI.drawRoundedRect("line", btn.x, faceY, btn.w, faceH, r)

    -- C. Typography, Labels & Subtitles
    local font = btn.font or UI.fonts.regular or love.graphics.getFont()
    love.graphics.setFont(font)

    local rawText = btn.text or ""
    local cleanText = UI.sanitizeText(rawText)
    if not btn.preserveCase then
        cleanText = UI.toUpperUtf8(cleanText)
    end

    if btn.isMultiLine and btn.sub then
        local f1 = UI.fonts.large or font
        local f2 = UI.fonts.medium or font
        -- Line 1
        love.graphics.setFont(f1)
        local l1W = f1:getWidth(cleanText)
        local l1Y = faceY + faceH * 0.24
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(cleanText, btn.x + (btn.w - l1W) / 2, l1Y + 1.5)
        love.graphics.setColor(textColor)
        love.graphics.print(cleanText, btn.x + (btn.w - l1W) / 2, l1Y)

        -- Subtitle
        local subText = UI.sanitizeText(btn.sub or "")
        if not btn.preserveCase then subText = UI.toUpperUtf8(subText) end
        love.graphics.setFont(f2)
        local subW = f2:getWidth(subText)
        local subY = faceY + faceH * 0.52
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY + 1.5)
        love.graphics.setColor(btn.disabled and textColor or { 0.92, 0.94, 0.98, 0.95 })
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY)
    elseif btn.sub then
        local fMain = font
        local fSub = UI.fonts.small or font
        if btn.h <= 55 then
            fMain = UI.fonts.small or font
            fSub = UI.fonts.tiny or font
        end
        local gap = 2
        local totalH = fMain:getHeight() + gap + fSub:getHeight()
        local mainY = faceY + math.floor((faceH - totalH) / 2)
        local subY = mainY + fMain:getHeight() + gap

        love.graphics.setFont(fMain)
        local mainW = fMain:getWidth(cleanText)
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(cleanText, btn.x + (btn.w - mainW) / 2, mainY + 1.5)
        love.graphics.setColor(textColor)
        love.graphics.print(cleanText, btn.x + (btn.w - mainW) / 2, mainY)

        local subText = UI.sanitizeText(btn.sub or "")
        if not btn.preserveCase then subText = UI.toUpperUtf8(subText) end
        love.graphics.setFont(fSub)
        local subW = fSub:getWidth(subText)
        love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY + 1.5)
        love.graphics.setColor(btn.disabled and textColor or { 0.92, 0.94, 0.98, 0.92 })
        love.graphics.print(subText, btn.x + (btn.w - subW) / 2, subY)
    else
        -- Check for newline
        if cleanText:find("\n") then
            local rawLines = {}
            for l in cleanText:gmatch("([^\r\n]*)") do
                table.insert(rawLines, l)
            end
            if #rawLines > 1 and rawLines[#rawLines] == "" then
                table.remove(rawLines)
            end
            local lineH = font:getHeight()
            local lineSpacing = 2
            local totalH = #rawLines * lineH + (#rawLines - 1) * lineSpacing
            local curY = faceY + (faceH - totalH) / 2
            for _, line in ipairs(rawLines) do
                if #line > 0 then
                    local lw = font:getWidth(line)
                    local lx = btn.x + (btn.w - lw) / 2
                    -- Shadow
                    love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
                    love.graphics.print(line, lx, curY + 1.5)
                    -- Face text
                    love.graphics.setColor(textColor)
                    love.graphics.print(line, lx, curY)
                end
                curY = curY + lineH + lineSpacing
            end
        else
            local textW = font:getWidth(cleanText)
            local textH = font:getHeight()
            local tx = btn.x + (btn.w - textW) / 2
            local ty = faceY + (faceH - textH) / 2
            love.graphics.setColor(0.04, 0.04, 0.06, 0.95)
            love.graphics.print(cleanText, tx, ty + 1.5)
            love.graphics.setColor(textColor)
            love.graphics.print(cleanText, tx, ty)
        end
    end

    -- Alert exclamation badge on right side
    if btn.alert then
        local badgeX = btn.x + btn.w - 18
        local badgeY = faceY + faceH / 2
        love.graphics.setColor(0.85, 0.18, 0.18, 1)
        love.graphics.circle("fill", badgeX, badgeY, 11)
        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.setLineWidth(1.5)
        love.graphics.circle("line", badgeX, badgeY, 11)
        love.graphics.setFont(UI.fonts.tiny or font)
        love.graphics.setColor(0, 0, 0, 0.95)
        love.graphics.printf("!", badgeX - 11, badgeY - 6, 22, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("!", badgeX - 11, badgeY - 7, 22, "center")
    end

    love.graphics.pop()
end

function UI.drawCard(card, x, y, w, h)
    love.graphics.push()
    love.graphics.translate(x + w / 2, y + h / 2)
    if card.rotation and card.rotation ~= 0 then
        love.graphics.rotate(card.rotation)
    end
    -- Pseudo-3D perspective tilt
    if (card.tiltX and card.tiltX ~= 0) or (card.tiltY and card.tiltY ~= 0) then
        love.graphics.shear((card.tiltX or 0) * 0.12, (card.tiltY or 0) * 0.12)
    end
    local s = card.visualScale or 1
    local sx = (card.scaleX or card.scale or 1) * s
    local sy = (card.scaleY or card.scale or 1) * s
    love.graphics.scale(sx, sy)
    love.graphics.translate(-w / 2, -h / 2)

    -- Dynamic Drop Shadow based on tilt & elevation
    local isLifted = (s > 1.05) or (card.isLifted == true)
    local shOffX = 4 + (card.tiltX or 0) * 10
    local shOffY = (isLifted and 14 or 6) + (card.tiltY or 0) * 10
    local shAlpha = isLifted and 0.45 or 0.32
    love.graphics.setColor(0, 0, 0, shAlpha)
    UI.drawRoundedRect("fill", shOffX, shOffY, w, h, 8)

    -- Face-down Card Drawing (The Fish boss ability)
    if card.faceDown then
        love.graphics.setColor(0.12, 0.14, 0.18, 0.98)
        UI.drawRoundedRect("fill", 3, 3, w - 6, h - 6, 6)
        love.graphics.setColor(0.35, 0.28, 0.38, 0.8)
        UI.drawRoundedRect("line", 5, 5, w - 10, h - 10, 5)
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(0.75, 0.68, 0.85, 0.9)
        love.graphics.printf("?", 0, h / 2 - 18, w, "center")
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.5, 0.45, 0.55, 0.8)
        love.graphics.printf("PHONG ẤN", 0, h / 2 + 14, w, "center")
        love.graphics.pop()
        return
    end

    local cImg = UI.getCardImage(card.suit, card.rank or card.rankName)
    if cImg then
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = cImg:getDimensions()
        love.graphics.draw(cImg, 0, 0, 0, w / iw, h / ih)

        -- Highlight borders
        love.graphics.setLineWidth(card.selected and 3.5 or (card.hovered and 2.5 or 1.5))
        if card.selected then
            love.graphics.setColor(UI.COLORS.cardSelectedBorder)
            UI.drawRoundedRect("line", 0, 0, w, h, 8)
        elseif card.hovered then
            love.graphics.setColor(UI.COLORS.chipsBlue)
            UI.drawRoundedRect("line", 0, 0, w, h, 8)
        end
    else
    -- Card background: Ancient Weathered Ivory Parchment
    love.graphics.setColor(UI.COLORS.cardBg)
    UI.drawRoundedRect("fill", 0, 0, w, h, 8)

    -- Inner edge burnt / aged soot vignette
    love.graphics.setColor(0.72, 0.65, 0.54, 0.45)
    UI.drawRoundedRect("line", 1.5, 1.5, w - 3, h - 3, 7)
    love.graphics.setColor(0.82, 0.76, 0.66, 0.35)
    UI.drawRoundedRect("line", 3, 3, w - 6, h - 6, 6)

    -- Border
    love.graphics.setLineWidth(card.selected and 3.5 or 2)
    if card.selected then
        love.graphics.setColor(UI.COLORS.cardSelectedBorder)
    elseif card.hovered then
        love.graphics.setColor(UI.COLORS.chipsBlue)
    else
        love.graphics.setColor(UI.COLORS.cardBorder)
    end
    UI.drawRoundedRect("line", 0, 0, w, h, 8)

    -- Corner Gothic Filigree Brackets
    love.graphics.setColor(0.48, 0.42, 0.34, 0.65)
    love.graphics.setLineWidth(1)
    love.graphics.line(5, 12, 5, 5, 12, 5)
    love.graphics.line(w - 5, 12, w - 5, 5, w - 12, 5)
    love.graphics.line(5, h - 12, 5, h - 5, 12, h - 5)
    love.graphics.line(w - 5, h - 12, w - 5, h - 5, w - 12, h - 5)

    -- Face-down Card Drawing (The Fish boss ability)
    if card.faceDown then
        love.graphics.setColor(0.12, 0.14, 0.18, 0.98)
        UI.drawRoundedRect("fill", 3, 3, w - 6, h - 6, 6)
        love.graphics.setColor(0.35, 0.28, 0.38, 0.8)
        UI.drawRoundedRect("line", 5, 5, w - 10, h - 10, 5)
        love.graphics.setFont(UI.fonts.large)
        love.graphics.setColor(0.75, 0.68, 0.85, 0.9)
        love.graphics.printf("?", 0, h / 2 - 18, w, "center")
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.5, 0.45, 0.55, 0.8)
        love.graphics.printf("PHONG ẤN", 0, h / 2 + 14, w, "center")
        love.graphics.pop()
        return
    end

    -- Gilded inner frame for equipped cards (subtle, elegant golden foil inlay)
    local eqCount = (card.equipments and #card.equipments) or 0
    if eqCount > 0 then
        love.graphics.setLineWidth(1.5)
        love.graphics.setColor(0.85, 0.70, 0.22, 0.85)
        UI.drawRoundedRect("line", 3, 3, w - 6, h - 6, 6)
    end

    -- Suit Color (Crimson Burgundy or Void Obsidian)
    local isRedSuit = (card.suit == "hearts" or card.suit == "valoria" or card.suit == "diamonds" or card.suit == "aurelia")
    local suitColor = isRedSuit and UI.COLORS.suitCrimson or UI.COLORS.suitObsidian

    -- Top-left rank
    love.graphics.setColor(suitColor)
    love.graphics.setFont(UI.fonts.large)
    love.graphics.print(card.rankName, 8, 4)

    -- Top-left small suit icon
    UI.drawSuitSymbol(card.suit, 15, 38, 14, suitColor)

    -- Bottom-right rank
    love.graphics.setColor(suitColor)
    love.graphics.setFont(UI.fonts.regular)
    local rk = card.rankName
    local rkW = UI.fonts.regular:getWidth(rk)
    love.graphics.print(rk, w - rkW - 8, h - 23)

    local socketCount = (Equipment and Equipment.MAX_SLOTS) or 3
    local dw = 5.2
    local dh = 5.2
    local socketGap = 15
    local socketStartX = (w - (socketCount * socketGap - 3)) / 2 + 3
    local socketY = 9

    for s = 1, socketCount do
        local sx = socketStartX + (s - 1) * socketGap
        local eq = card.equipments and card.equipments[s]

        if not eq then
            -- 2. Open Empty Socket: Metallic beveled chisel rim & deep dark velvet cavity
            love.graphics.setColor(0.48, 0.40, 0.28, 0.95)
            love.graphics.polygon("fill", sx, socketY - dh - 0.8, sx + dw + 0.8, socketY, sx, socketY + dh + 0.8, sx - dw - 0.8, socketY)
            love.graphics.setColor(0.09, 0.08, 0.08, 0.98)
            love.graphics.polygon("fill", sx, socketY - dh + 0.5, sx + dw - 0.5, socketY, sx, socketY + dh - 0.5, sx - dw + 0.5, socketY)
            love.graphics.setColor(0.82, 0.72, 0.50, 0.7)
            love.graphics.setLineWidth(1)
            love.graphics.line(sx - dw, socketY, sx, socketY - dh)
            love.graphics.line(sx, socketY - dh, sx + dw, socketY)
        else
            -- 3. Socketed Gemstone: Faceted jewel with glowing core & 4 prongs
            local gc = eq.color or UI.COLORS.goldYellow
            -- Jewelry Bezel
            love.graphics.setColor(0.85, 0.72, 0.22, 0.95)
            love.graphics.polygon("fill", sx, socketY - dh - 1.2, sx + dw + 1.2, socketY, sx, socketY + dh + 1.2, sx - dw - 1.2, socketY)
            -- Upper Facet
            love.graphics.setColor(math.min(1, gc[1] * 1.3), math.min(1, gc[2] * 1.3), math.min(1, gc[3] * 1.3), 1)
            love.graphics.polygon("fill", sx, socketY - dh, sx + dw, socketY, sx, socketY, sx - dw, socketY)
            -- Lower Facet
            love.graphics.setColor(gc[1] * 0.65, gc[2] * 0.65, gc[3] * 0.65, 1)
            love.graphics.polygon("fill", sx - dw, socketY, sx + dw, socketY, sx, socketY + dh)
            -- Core table glow
            love.graphics.setColor(1, 1, 1, 0.55)
            love.graphics.polygon("fill", sx, socketY - dh * 0.45, sx + dw * 0.45, socketY, sx, socketY + dh * 0.45, sx - dw * 0.45, socketY)
            -- 4 Golden Prongs
            love.graphics.setColor(0.98, 0.88, 0.35, 1)
            love.graphics.circle("fill", sx, socketY - dh, 1.0)
            love.graphics.circle("fill", sx + dw, socketY, 1.0)
            love.graphics.circle("fill", sx, socketY + dh, 1.0)
            love.graphics.circle("fill", sx - dw, socketY, 1.0)
            -- Specular sparkle
            love.graphics.setColor(1, 1, 1, 0.95)
            love.graphics.line(sx - 2, socketY - 1.5, sx, socketY - 1.5)
            love.graphics.line(sx - 1, socketY - 2.5, sx - 1, socketY - 0.5)
        end
    end

    -- Center Artwork: Face Cards Gothic Pixel Portraits or Numeric Pips
    local rank = card.rank or 2
    local cx = w / 2
    local cy = h / 2 - 3

    if rank == 13 then
        -- 👑 KING (K - Quốc Vương): Gothic Bloodied Sovereign Portrait
        local pw, ph = 52, 60
        local px = cx - pw / 2
        local py = cy - ph / 2 + 1

        -- Gothic Arched Frame
        love.graphics.setColor(0.18, 0.11, 0.12, 0.95)
        UI.drawRoundedRect("fill", px, py, pw, ph, 6)
        love.graphics.setColor(0.72, 0.58, 0.22, 0.95)
        love.graphics.setLineWidth(1.5)
        UI.drawRoundedRect("line", px, py, pw, ph, 6)

        -- Regal Ermine Mantle
        love.graphics.setColor(0.55, 0.10, 0.14, 1)
        love.graphics.polygon("fill", px + 4, py + ph - 2, px + pw - 4, py + ph - 2, cx, py + 24)
        love.graphics.setColor(0.94, 0.92, 0.88, 1)
        love.graphics.rectangle("fill", px + 8, py + ph - 14, pw - 16, 7, 2)
        love.graphics.setColor(0.10, 0.08, 0.08, 1)
        love.graphics.circle("fill", px + 14, py + ph - 10, 1.1)
        love.graphics.circle("fill", px + 22, py + ph - 10, 1.1)
        love.graphics.circle("fill", px + 30, py + ph - 10, 1.1)
        love.graphics.circle("fill", px + 38, py + ph - 10, 1.1)

        -- Masked Visage / Brooding Face
        love.graphics.setColor(0.82, 0.72, 0.42, 1)
        love.graphics.rectangle("fill", cx - 9, py + 18, 18, 16, 4)
        love.graphics.setColor(0.10, 0.06, 0.06, 1)
        love.graphics.rectangle("fill", cx - 7, py + 22, 4, 3)
        love.graphics.rectangle("fill", cx + 3, py + 22, 4, 3)

        -- Bleeding Iron Crown
        love.graphics.setColor(0.28, 0.26, 0.28, 1)
        love.graphics.polygon("fill",
            cx - 12, py + 18,
            cx - 13, py + 6,
            cx - 6, py + 12,
            cx, py + 4,
            cx + 6, py + 12,
            cx + 13, py + 6,
            cx + 12, py + 18
        )
        love.graphics.setColor(0.85, 0.70, 0.22, 1)
        love.graphics.rectangle("fill", cx - 12, py + 16, 24, 3)
        love.graphics.setColor(0.85, 0.12, 0.15, 0.95)
        love.graphics.circle("fill", cx, py + 8, 1.8)
        love.graphics.circle("fill", cx - 9, py + 10, 1.5)
        love.graphics.circle("fill", cx + 9, py + 10, 1.5)
        love.graphics.line(cx - 9, py + 11, cx - 9, py + 16)

        -- Suit Insignia on Gorget
        UI.drawSuitSymbol(card.suit, cx, py + ph - 18, 11, suitColor)

    elseif rank == 12 then
        -- 👸 QUEEN (Q - Hoàng Hậu): Mourning Veiled Sovereign Portrait
        local pw, ph = 52, 60
        local px = cx - pw / 2
        local py = cy - ph / 2 + 1

        -- Gothic Arched Frame
        love.graphics.setColor(0.14, 0.10, 0.16, 0.95)
        UI.drawRoundedRect("fill", px, py, pw, ph, 6)
        love.graphics.setColor(0.65, 0.45, 0.72, 0.95)
        love.graphics.setLineWidth(1.5)
        UI.drawRoundedRect("line", px, py, pw, ph, 6)

        -- Black Mourning Veil Cascading
        love.graphics.setColor(0.10, 0.08, 0.12, 1)
        love.graphics.polygon("fill", cx - 13, py + 14, px + 5, py + ph - 2, cx - 4, py + ph - 2, cx, py + 28)
        love.graphics.polygon("fill", cx + 13, py + 14, px + pw - 5, py + ph - 2, cx + 4, py + ph - 2, cx, py + 28)

        -- Pale Regal Face
        love.graphics.setColor(0.90, 0.86, 0.82, 1)
        love.graphics.rectangle("fill", cx - 8, py + 18, 16, 16, 4)
        love.graphics.setColor(0.25, 0.18, 0.25, 1)
        love.graphics.line(cx - 6, py + 24, cx - 2, py + 24)
        love.graphics.line(cx + 2, py + 24, cx + 6, py + 24)

        -- Thorned Amethyst Tiara
        love.graphics.setColor(0.20, 0.18, 0.22, 1)
        love.graphics.polygon("fill", cx - 10, py + 18, cx - 8, py + 8, cx, py + 12, cx + 8, py + 8, cx + 10, py + 18)
        love.graphics.setColor(0.78, 0.32, 0.88, 1)
        love.graphics.circle("fill", cx, py + 13, 2.2)

        -- Suit Insignia
        UI.drawSuitSymbol(card.suit, cx, py + ph - 16, 11, suitColor)

    elseif rank == 11 then
        -- ⚔️ KNIGHT (J - Hiệp Sĩ): Slotted Iron Visor Greathelm Portrait
        local pw, ph = 52, 60
        local px = cx - pw / 2
        local py = cy - ph / 2 + 1

        -- Gothic Shield Frame
        love.graphics.setColor(0.12, 0.14, 0.18, 0.95)
        UI.drawRoundedRect("fill", px, py, pw, ph, 6)
        love.graphics.setColor(0.48, 0.58, 0.68, 0.95)
        love.graphics.setLineWidth(1.5)
        UI.drawRoundedRect("line", px, py, pw, ph, 6)

        -- Iron Greathelm
        love.graphics.setColor(0.32, 0.36, 0.42, 1)
        love.graphics.rectangle("fill", cx - 11, py + 10, 22, 28, 4)
        love.graphics.setColor(0.48, 0.52, 0.60, 1)
        love.graphics.rectangle("fill", cx - 13, py + 19, 26, 4, 1)
        -- Slotted Visor Eye Slit
        love.graphics.setColor(0.08, 0.08, 0.10, 1)
        love.graphics.rectangle("fill", cx - 9, py + 20, 18, 2)
        love.graphics.setColor(0.95, 0.35, 0.15, 0.95)
        love.graphics.rectangle("fill", cx - 4, py + 20, 3, 2)
        love.graphics.rectangle("fill", cx + 2, py + 20, 3, 2)

        -- Steel Gorget & Shoulders
        love.graphics.setColor(0.24, 0.28, 0.34, 1)
        love.graphics.polygon("fill", px + 4, py + ph - 2, px + pw - 4, py + ph - 2, cx + 8, py + 38, cx - 8, py + 38)
        love.graphics.setColor(0.70, 0.75, 0.82, 1)
        love.graphics.circle("fill", px + 9, py + ph - 8, 1.1)
        love.graphics.circle("fill", px + pw - 9, py + ph - 8, 1.1)

        -- Suit Crest
        UI.drawSuitSymbol(card.suit, cx, py + ph - 15, 11, suitColor)

    elseif rank == 14 then
        -- 🗡️ ACE (A - Thần Khí): Divine Relic Sigil & Holy Halo
        love.graphics.setColor(suitColor[1], suitColor[2], suitColor[3], 0.18)
        love.graphics.circle("fill", cx, cy, 26)
        love.graphics.setColor(suitColor[1], suitColor[2], suitColor[3], 0.35)
        love.graphics.circle("line", cx, cy, 28)
        UI.drawSuitSymbol(card.suit, cx, cy, 38, suitColor)
    else
        -- 🛡️ SOLDIER (2-10): Gothic Pips & Insignia
        UI.drawSuitSymbol(card.suit, cx, cy, 40, suitColor)
    end

    -- Role text at lower center in retro pixel font
    local roleText = card.roleName
    if not roleText and card.rank then
        local Deck = require("src.deck")
        local role = Deck.getCardRole(card.rank)
        roleText = role.name
    end
    if roleText then
        local displayRole = roleText
        if rank == 13 then displayRole = "KING"
        elseif rank == 12 then displayRole = "QUEEN"
        elseif rank == 11 then displayRole = "KNIGHT"
        elseif rank == 14 then displayRole = "DIVINE"
        else displayRole = "SOLDIER"
        end

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(0.32, 0.28, 0.24, 0.95)
        local rw = UI.fonts.tiny:getWidth(displayRole)
        love.graphics.print(displayRole, (w - rw) / 2, h - 35 + 1)
        love.graphics.setColor(0.52, 0.46, 0.38, 1)
        love.graphics.print(displayRole, (w - rw) / 2, h - 35)
    end
    end

    -- Con Dấu Sáp (Wax Seal) Base Chip Badge in bottom corner
    local sealCX = 22
    local sealCY = h - 18
    local sealR = 11.5

    -- Molten Wax Lobes
    love.graphics.setColor(0.48, 0.08, 0.10, 0.95)
    for a = 0, 5 do
        local ang = a * (math.pi / 3)
        local lx = sealCX + math.cos(ang) * (sealR - 1)
        local ly = sealCY + math.sin(ang) * (sealR - 1)
        love.graphics.circle("fill", lx, ly, 4.2)
    end
    love.graphics.setColor(0.68, 0.12, 0.15, 0.98)
    love.graphics.circle("fill", sealCX, sealCY, sealR)

    -- Inner Stamped Seal Cavity
    love.graphics.setColor(0.52, 0.08, 0.10, 1)
    love.graphics.circle("fill", sealCX, sealCY, sealR - 2.5)

    -- Top Glossy Highlight Arc
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.setLineWidth(1)
    love.graphics.arc("line", "open", sealCX, sealCY, sealR - 1.5, math.pi * 1.1, math.pi * 1.8)

    -- Stamped Number
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(0.98, 0.88, 0.45, 1)
    local chipStr = "+" .. card.baseChips
    local cW = UI.fonts.tiny:getWidth(chipStr)
    love.graphics.print(chipStr, sealCX - cW / 2, sealCY - UI.fonts.tiny:getHeight() / 2)

    -- Top-Right Decorative Wax Seal (Gold, Red, Blue, Purple)
    if card.seal then
        local sCX = w - 16
        local sCY = 16
        local sR = 9
        local sealColor = { 0.95, 0.75, 0.20, 1 }
        local sealText = "G"
        if card.seal == "red" then
            sealColor = { 0.88, 0.20, 0.25, 1 }
            sealText = "R"
        elseif card.seal == "blue" then
            sealColor = { 0.25, 0.55, 0.95, 1 }
            sealText = "B"
        elseif card.seal == "purple" then
            sealColor = { 0.75, 0.25, 0.90, 1 }
            sealText = "P"
        end
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.circle("fill", sCX + 1, sCY + 1, sR)
        love.graphics.setColor(sealColor[1] * 0.7, sealColor[2] * 0.7, sealColor[3] * 0.7, 1)
        love.graphics.circle("fill", sCX, sCY, sR)
        love.graphics.setColor(sealColor)
        love.graphics.circle("fill", sCX, sCY, sR - 2)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(sealText, sCX - 8, sCY - 7, 16, "center")
    end

    love.graphics.pop()
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
            "assets/packs/" .. mapped .. ".png",
            "assets/packs/" .. packId .. ".png",
        }
        for _, path in ipairs(candidates) do
            local okInfo, info = pcall(love.filesystem.getInfo, path)
            if okInfo and info then
                local okImg, img = pcall(love.graphics.newImage, path)
                if okImg and img then
                    if img.setFilter then
                        img:setFilter("nearest", "nearest")
                    end
                    UI.packImages[mapped] = img
                    return img
                end
            end
        end
    end
    UI.packImages[mapped] = false
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



-- Full Tarot Card Frame for Hộ Linh (Patrons)
function UI.drawPatronCard(d, x, y, w, h, isHovered, isPressed, isDropTarget, copyTarget)
    if not d then return end
    w = w or 82
    h = h or 118

    love.graphics.push()
    love.graphics.translate(x + w / 2, y + h / 2)
    local s = (isHovered and 1.05 or 1.0)
    if isPressed then s = 0.96 end
    if isDropTarget then s = 1.08 end
    love.graphics.scale(s, s)
    love.graphics.translate(-w / 2, -h / 2)

    -- Drop shadow
    love.graphics.setColor(0, 0, 0, 0.45)
    UI.drawRoundedRect("fill", 3, 5, w, h, 6)

    -- Border by Rarity
    local rBorder = { 0.45, 0.48, 0.54, 1 }
    local rGlow = { 0.5, 0.5, 0.5, 0.2 }
    if d.rarity == "uncommon" then
        rBorder = { 0.20, 0.78, 0.45, 1 }
        rGlow = { 0.2, 0.8, 0.4, 0.25 }
    elseif d.rarity == "rare" then
        rBorder = { 0.22, 0.60, 0.98, 1 }
        rGlow = { 0.2, 0.6, 1.0, 0.25 }
    elseif d.rarity == "legendary" then
        rBorder = { 0.96, 0.78, 0.22, 1 }
        rGlow = { 0.95, 0.78, 0.2, 0.3 }
    end

    if isDropTarget then
        rBorder = UI.COLORS.bossPurple
    elseif isHovered then
        rBorder = { 1, 1, 1, 1 }
    end

    local img = UI.getDeityImage(d.id)
    if img then
        -- Render authentic pixel art card artwork
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = img:getDimensions()
        love.graphics.draw(img, 0, 0, 0, w / iw, h / ih)

        if isHovered then
            love.graphics.setLineWidth(2.0)
            love.graphics.setColor(1, 1, 1, 0.95)
            UI.drawRoundedRect("line", 0, 0, w, h, 6)
        elseif d.rarity == "legendary" then
            love.graphics.setLineWidth(1.5)
            love.graphics.setColor(0.96, 0.78, 0.22, 0.6)
            UI.drawRoundedRect("line", 0, 0, w, h, 6)
        end
    else
        -- Card Body: Deep Void Obsidian
        love.graphics.setColor(0.10, 0.11, 0.13, 0.98)
        UI.drawRoundedRect("fill", 0, 0, w, h, 6)

        -- Inner background halo
        love.graphics.setColor(rGlow)
        love.graphics.circle("fill", w / 2, h / 2 + 2, w * 0.42)

        -- Ornate Gothic Double Hairline Border
        love.graphics.setLineWidth(isHovered and 2.0 or 1.5)
        love.graphics.setColor(rBorder)
        UI.drawRoundedRect("line", 0, 0, w, h, 6)
        love.graphics.setLineWidth(1)
        love.graphics.setColor(rBorder[1], rBorder[2], rBorder[3], 0.45)
        UI.drawRoundedRect("line", 3, 3, w - 6, h - 6, 4)

        -- Corner Gothic Fleuron Notches
        love.graphics.setColor(rBorder)
        love.graphics.line(5, 7, 7, 5)
        love.graphics.line(w - 5, 7, w - 7, 5)
        love.graphics.line(5, h - 7, 7, h - 5)
        love.graphics.line(w - 5, h - 7, w - 7, h - 5)

        -- Title Ribbon Banner at Top
        local bannerH = 22
        love.graphics.setColor(0.06, 0.07, 0.08, 0.95)
        love.graphics.rectangle("fill", 4, 6, w - 8, bannerH, 3)
        love.graphics.setColor(rBorder[1], rBorder[2], rBorder[3], 0.7)
        love.graphics.rectangle("line", 4, 6, w - 8, bannerH, 3)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 0.95)
        local displayName = UI.toUpperUtf8(d.name)
        love.graphics.printf(displayName, 5, 10, w - 10, "center")

        -- Center Dedicated Relic Sigil / Artwork
        local cx = w / 2
        local cy = h / 2 + 5
        UI.drawRelicSigil(d.id, cx, cy, 28, rBorder)

        -- Bottom Rarity Jewel Talisman
        love.graphics.setColor(rBorder)
        local jR = 3.5
        love.graphics.polygon("fill", cx, h - 12 - jR, cx + jR, h - 12, cx, h - 12 + jR, cx - jR, h - 12)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.circle("fill", cx - 0.8, h - 12 - 0.8, 1.0)
    end

    -- Blueprint / Copy indicator
    if d.isCopyDeity and copyTarget then
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("⇄", 4, h - 22, w - 8, "center")
    end

    -- Joker Edition Badge (Foil, Holo, Polychrome, Negative)
    if d.edition then
        local edW = w - 8
        local edH = 16
        local edY = h - 20
        local edCol = { 0.25, 0.65, 0.95, 0.95 }
        local edText = "FOIL +50c"
        if d.edition == "holo" then
            edCol = { 0.95, 0.35, 0.85, 0.95 }
            edText = "HOLO +10m"
        elseif d.edition == "polychrome" then
            edCol = { 0.95, 0.75, 0.20, 0.95 }
            edText = "POLY x1.5"
        elseif d.edition == "negative" then
            edCol = { 0.15, 0.18, 0.22, 0.95 }
            edText = "NEGATIVE +1"
        end
        love.graphics.setColor(edCol)
        UI.drawRoundedRect("fill", 4, edY, edW, edH, 3)
        love.graphics.setColor(1, 1, 1, 0.9)
        UI.drawRoundedRect("line", 4, edY, edW, edH, 3)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.printf(edText, 4, edY + 1, edW, "center")
    end

    if isDropTarget then
        love.graphics.setColor(0, 0, 0, 0.75)
        UI.drawRoundedRect("fill", 2, 2, w - 4, h - 4, 5)
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.goldYellow)
        love.graphics.printf("⇄\nHOÁN\nĐỔI", 4, h / 2 - 18, w - 8, "center")
    end

    love.graphics.pop()
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

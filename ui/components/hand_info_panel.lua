local Theme = require("ui.theme")
local Panel = require("ui.components.panel")
local Core = require("ui.components.core")
local HandInfoPanel = {}
local utf8 = require("utf8")

local PANEL_IMAGE = "assets/ui/hand_info_panel_v2.png"
local ICON_IMAGE = "assets/ui/hand_info_icons_v2.png"
local ICON_INDEX = {damage = 1, power = 2, aura = 3, health = 4, intent = 5, trait = 6}
local loaded, panelImage, iconImage, iconQuads, iconCellW, iconCellH = false, nil, nil, {}, 0, 0

local function loadImages()
    if loaded then return end
    loaded = true

    local ok, image = pcall(love.graphics.newImage, PANEL_IMAGE)
    if ok and image then
        panelImage = image
        image:setFilter("linear", "linear")
    end

    ok, image = pcall(love.graphics.newImage, ICON_IMAGE)
    if ok and image then
        iconImage = image
        iconImage:setFilter("linear", "linear")
        local w, h = image:getDimensions()
        iconCellW, iconCellH = w / 3, h / 2
        for index = 1, 6 do
            local column = (index - 1) % 3
            local row = math.floor((index - 1) / 3)
            iconQuads[index] = love.graphics.newQuad(
                column * iconCellW, row * iconCellH, iconCellW, iconCellH, w, h)
        end
    end
end

local function drawIcon(name, x, y, size)
    if not iconImage then return end
    local quad = iconQuads[ICON_INDEX[name]]
    if not quad then return end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(iconImage, quad, x, y, 0, size / iconCellW, size / iconCellH)
end

local function boundedLines(text, font, width, maxLines)
    local _, lines = font:getWrap(tostring(text or ""), width)
    if #lines > maxLines then
        local last = lines[maxLines] or ""
        while last ~= "" and font:getWidth(last .. "…") > width do
            local ok, start = pcall(utf8.offset, last, -1)
            if not ok or not start then break end
            last = last:sub(1, start - 1)
        end
        lines[maxLines] = last .. "…"
        for i = #lines, maxLines + 1, -1 do lines[i] = nil end
    end
    return table.concat(lines, "\n")
end

local function fitValue(text, fonts, width)
    for _, key in ipairs({"aura", "value", "body", "label", "detail"}) do
        local font = fonts[key]
        if font and font:getWidth(text) <= width then return font end
    end
    return fonts.detail or love.graphics.getFont()
end

local function drawMetric(x, y, w, h, label, value, variant, icon, fonts)
    local color = Theme.colors[variant] or Theme.colors.gold
    local text = tostring(value or "0")
    Core.text(label, x + 3, y + 7, w - 6, fonts.detail, color, "center")

    local iconSize = 15
    local valueFont = fitValue(text, fonts, w - iconSize - 14)
    local textWidth = math.min(valueFont:getWidth(text), w - iconSize - 14)
    local groupWidth = iconSize + 5 + textWidth
    local startX = x + (w - groupWidth) / 2
    drawIcon(icon, startX, y + h - 33, iconSize)
    Core.text(text, startX + iconSize + 5, y + h - 39, textWidth + 2,
        valueFont, Theme.colors.text, "left")
end

function HandInfoPanel.draw(data, fonts, formatNumber)
    data = data or {}
    loadImages()

    local x, y, w, h = 12, 76, 222, 615
    local infoFonts = (fonts and fonts.info) or fonts or {}
    local baseFont = love.graphics.getFont()
    local drawFonts = {
        detail = infoFonts.detail or (fonts and fonts.tiny) or baseFont,
        label = infoFonts.label or (fonts and fonts.small) or baseFont,
        body = infoFonts.body or (fonts and fonts.regular) or baseFont,
        title = infoFonts.title or (fonts and fonts.medium) or baseFont,
        value = infoFonts.value or (fonts and fonts.medium) or baseFont,
        aura = infoFonts.aura or (fonts and fonts.large) or baseFont,
    }
    local fmt = formatNumber or tostring
    local g = love.graphics

    if panelImage then
        local iw, ih = panelImage:getDimensions()
        g.push("all")
        g.setColor(1, 1, 1, 1)
        g.draw(panelImage, x, y, 0, w / iw, h / ih)
        g.pop()
    else
        Panel.draw(x, y, w, h)
    end

    Core.text("TAY BÀI", x + 16, y + 13, w - 32, drawFonts.title, Theme.colors.gold)
    Core.textLine(data.handName or "Chọn bài để xem", x + 16, y + 41, w - 32,
        drawFonts.body, Theme.colors.text, "left", drawFonts.label)

    drawMetric(x + 12, y + 78, 94, 66, "SÁT THƯƠNG", fmt(data.chips or 0),
        "cyan", "damage", drawFonts)
    drawMetric(x + 116, y + 78, 94, 66, "CƯỜNG HÓA", fmt(data.mult or 0),
        "red", "power", drawFonts)

    Core.text(tostring(fmt(data.chips or 0)) .. " × " .. tostring(fmt(data.mult or 0))
        .. ((data.xMult or 1) > 1 and (" × " .. string.format("%.2f", data.xMult)) or ""),
        x + 12, y + 151, w - 24, drawFonts.label, Theme.colors.muted, "center")

    local auraLabel = data.scoring and "AURA ĐANG CỘNG" or "AURA DỰ KIẾN"
    Core.text(auraLabel, x + 20, y + 181, w - 40, drawFonts.label, Theme.colors.gold, "center")
    drawIcon("aura", x + 27, y + 207, 24)
    local auraText = tostring(fmt(data.aura or 0))
    local auraFont = fitValue(auraText, drawFonts, w - 78)
    Core.text(auraText, x + 56, y + 202, w - 80, auraFont, Theme.colors.gold, "center")

    drawIcon("trait", x + 14, y + 267, 19)
    Core.text("QUÁI VẬT", x + 39, y + 268, w - 53, drawFonts.title, Theme.colors.gold)
    Core.textLine(data.enemyName or "Không rõ", x + 16, y + 293, w - 32,
        drawFonts.body, Theme.colors.text, "left", drawFonts.label)

    drawIcon("health", x + 16, y + 318, 15)
    Core.text("MÁU " .. tostring(data.enemyHp or 0) .. "/" .. tostring(data.enemyMaxHp or 0),
        x + 38, y + 317, w - 54, drawFonts.label, Theme.colors.muted)

    local barX, barY, barW, barH = x + 18, y + 340, w - 36, 16
    local hp, maxHp = math.max(0, tonumber(data.enemyHp) or 0), tonumber(data.enemyMaxHp) or 1
    local ratio = math.max(0, math.min(1, hp / math.max(1, maxHp)))
    if ratio > 0 then
        g.push("all")
        g.setColor(0.76, 0.18, 0.20, 1)
        g.rectangle("fill", barX + 3, barY + 3, (barW - 6) * ratio, barH - 6, 2, 2)
        g.pop()
    end

    drawIcon("intent", x + 15, y + 363, 18)
    Core.text("CHIÊU TIẾP THEO", x + 39, y + 364, w - 53,
        drawFonts.label, Theme.colors.red)
    Core.text(boundedLines(data.intent or "Chưa rõ", drawFonts.body, w - 32, 2),
        x + 16, y + 388, w - 32, drawFonts.body, Theme.colors.text)

    drawIcon("trait", x + 15, y + 442, 18)
    Core.text(data.isBoss and "DEBUFF" or "ĐẶC ĐIỂM", x + 39, y + 443,
        w - 53, drawFonts.label, data.isBoss and Theme.colors.red or Theme.colors.gold)
    Core.text(boundedLines(data.debuff or "Không có hiệu ứng bất lợi",
        drawFonts.detail, w - 32, 2), x + 16, y + 467, w - 32,
        drawFonts.detail, Theme.colors.muted)

    if data.scoring then
        Core.text(data.category or "ĐANG CỘNG AURA", x + 16, y + 535,
            w - 32, drawFonts.label, Theme.colors.gold)
        Core.text(boundedLines(data.detail or "", drawFonts.detail, w - 32, 3),
            x + 16, y + 557, w - 32, drawFonts.detail, Theme.colors.text)
    end
end

return HandInfoPanel

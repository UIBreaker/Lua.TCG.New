local UI = require("src.ui")
local Physics = UI.CardPhysics
local Surfaces = {}
local catalogHandles = {}

-- Collection cards, including equipment, vouchers, styles and all pack contents.
function Surfaces.catalog(item, cx, cy, cardW, cardH, collectionCategory, isH, mx, my)
    if item.faceDown then return UI.drawCardBack(cx, cy, cardW, cardH, item.alpha) end
    -- 3D Tilt calculation
    if isH and not item.faceDown then UI.descriptionCandidate = item end
    local tX, tY = 0, 0
    if isH then
        tX, tY = UI.calculateTilt(mx, my, cx, cy, cardW, cardH)
    end

    love.graphics.push()
    love.graphics.translate(cx + cardW / 2, cy + cardH / 2)
    if isH then
        love.graphics.shear(tX * 0.08, tY * 0.08)
        love.graphics.scale(1.05, 1.05)
    end
    love.graphics.translate(-cardW / 2, -cardH / 2)
    Physics.capture(item, 0, 0, cardW, cardH)

    -- Card Body
    local deityId = (collectionCategory == "jokers" and item.id)
        or (collectionCategory == "packs" and item.isPackContent and item.deityId)
    local deityArt = deityId and UI.getDeityImage(deityId)
    local dImg = deityArt
              or ((collectionCategory == "consumables") and UI.getEquipmentImage(item.id))
              or ((collectionCategory == "packs") and (item.isPackContent and UI.getPackCardImage(item.packType, item) or UI.getPackImage(item.packType or item.id)))
              or ((collectionCategory == "other") and UI.getHandImage(item.handId or item.id))
              or ((collectionCategory == "vouchers") and (UI.getVoucherImage(item.id) or UI.getHandImage(item.handId or item.id) or UI.getHandImage(item.id)))
    if not UI.useLegacyPixelArt and collectionCategory ~= "packs" and collectionCategory ~= "consumables" and not deityArt then dImg = nil end
    if deityArt then
        UI.drawPatronCard(item, 0, 0, cardW, cardH)
        if isH then
            love.graphics.setLineWidth(2.5)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)
        end
    elseif dImg then
        love.graphics.setColor(0, 0, 0, 0.35)
        UI.drawRoundedRect("fill", 2, 4, cardW, cardH, 8)

        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = dImg:getDimensions()
        love.graphics.draw(dImg, 0, 0, 0, cardW / iw, cardH / ih)

        if isH then
            love.graphics.setLineWidth(2.5)
            love.graphics.setColor(UI.COLORS.goldYellow)
            UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)
        end
    else
        local itemCol = item.color or { 0.3, 0.4, 0.5, 1 }
        love.graphics.setColor(0, 0, 0, 0.35)
        UI.drawRoundedRect("fill", 2, 4, cardW, cardH, 8)

        love.graphics.setColor(0.18, 0.22, 0.26, 1)
        UI.drawRoundedRect("fill", 0, 0, cardW, cardH, 8)

        -- Card Header Banner
        love.graphics.setColor(itemCol[1], itemCol[2], itemCol[3], 0.9)
        UI.drawRoundedRect("fill", 0, 0, cardW, 26, 8)
        UI.drawRoundedRect("fill", 0, 16, cardW, 10, 0)

        -- Card Border
        love.graphics.setLineWidth(isH and 2.5 or 1.5)
        love.graphics.setColor(isH and UI.COLORS.goldYellow or { itemCol[1], itemCol[2], itemCol[3], 0.8 })
        UI.drawRoundedRect("line", 0, 0, cardW, cardH, 8)

        UI.drawItemEmblem(item, cardW / 2, 69, 19, itemCol)

        -- Card Name
        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(1, 1, 1, 1)
        local cleanName = UI.truncateUtf8(item.name, 16)
        love.graphics.printf(cleanName, 4, 100, cardW - 8, "center")

        -- Rarity / Cost pill
        if item.cost then
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.goldYellow)
            love.graphics.printf("$" .. item.cost, 0, 134, cardW, "center")
        elseif item.rarity then
            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.printf(item.rarity, 0, 134, cardW, "center")
        end
    end

    love.graphics.pop()
end

-- Pack reward body: choice/keep buttons remain in the existing gameplay handler.
function Surfaces.reward(card, cx, drawCY, cW, cH, packType, label, isChoiceHovered)
    if card.faceDown then return UI.drawCardBack(cx, drawCY, cW, cH, card.alpha) end
    love.graphics.setColor(0.16, 0.20, 0.26, 0.98)
    UI.drawRoundedRect("fill", cx, drawCY, cW, cH, 10)
    love.graphics.setColor(isChoiceHovered and UI.COLORS.goldYellow or (card.color or { 0.45, 0.55, 0.70, 0.8 }))
    love.graphics.setLineWidth(isChoiceHovered and 3 or 1.5)
    UI.drawRoundedRect("line", cx, drawCY, cW, cH, 10)

    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(card.color or UI.COLORS.goldYellow)
    love.graphics.printf(label or "THẺ BÀI", cx + 4, drawCY + 9, cW - 8, "center")

    if isChoiceHovered and not card.faceDown then UI.descriptionCandidate = card end
    local art = UI.getPackCardImage(packType, card)
    if art then
        local iw, ih = art:getDimensions()
        local artW, artH = 104, 104
        local artScale = math.min(artW / iw, artH / ih)
        local drawW, drawH = iw * artScale, ih * artScale
        love.graphics.setColor(1, 1, 1, 1)
        local ax, ay = cx + (cW - drawW) / 2, drawCY + 28 + (artH - drawH) / 2
        if card.rank then
            UI.drawCardFace(card, ax, ay, drawW, drawH, isChoiceHovered)
        elseif packType == "buffoon" then
            UI.drawPatronCard(card, ax, ay, drawW, drawH, isChoiceHovered)
        else
            love.graphics.draw(art, ax, ay, 0, artScale, artScale)
        end
    end

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(card.name or ((card.rankName or "") .. (card.suitSymbol or "")), cx + 6, drawCY + 138, cW - 12, "center")
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textLight)
    local desc = UI.truncateUtf8(select(2,UI.Description.resolve(card,UI.descriptionGame)),112)
    love.graphics.printf(desc, cx + 8, drawCY + 163, cW - 16, "center")


end

function Surfaces.round(item, x, cardY, cardW, cardH, hovered)
    if item.faceDown then return UI.drawCardBack(x, cardY, cardW, cardH, item.alpha) end
    local color = item.color or UI.COLORS.goldYellow
    love.graphics.setColor(0, 0, 0, 0.35)
    UI.drawRoundedRect("fill", x + 3, cardY + 5, cardW, cardH, 12)
    love.graphics.setColor(0.12, 0.16, 0.21, 1)
    UI.drawRoundedRect("fill", x, cardY, cardW, cardH, 12)
    love.graphics.setLineWidth(hovered and 3 or 2)
    love.graphics.setColor(color)
    UI.drawRoundedRect("line", x, cardY, cardW, cardH, 12)
    love.graphics.setFont(UI.fonts.large or UI.fonts.title)
    love.graphics.setColor(color)
    love.graphics.printf(item.icon or "✦", x, cardY + 26, cardW, "center")
    love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.printf(item.name or "Phần thưởng", x + 14, cardY + 110, cardW - 28, "center")
    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textMuted or UI.COLORS.textLight)
    love.graphics.printf(item.desc or "", x + 22, cardY + 160, cardW - 44, "center")

end

function Surfaces.image(item, x, y, w, h, image)
    if item.faceDown then return UI.drawCardBack(x, y, w, h, item.alpha) end
    if not image then return end
    local iw, ih = image:getDimensions()
    love.graphics.draw(image, x, y, 0, w / iw, h / ih)
end

function Surfaces.starter(deckInfo, cardX, cardY, cardW, cardH)
    UI.drawCardBack(cardX, cardY, cardW, cardH)
end
function Surfaces.preview(inspItem, lcx, lcy, lcw, lch, collectionCategory)
    if inspItem.faceDown then return UI.drawCardBack(lcx, lcy, lcw, lch, inspItem.alpha) end
    local lcol = inspItem.color or UI.COLORS.goldYellow
    local deityPreviewId = (collectionCategory == "jokers" and inspItem.id)
        or (collectionCategory == "packs" and inspItem.isPackContent and inspItem.deityId)
    local deityPreview = deityPreviewId and UI.getDeityImage(deityPreviewId)
    local inspImg = deityPreview
                 or ((collectionCategory == "consumables") and UI.getEquipmentImage(inspItem.id))
                 or ((collectionCategory == "packs") and (inspItem.isPackContent and UI.getPackCardImage(inspItem.packType, inspItem) or UI.getPackImage(inspItem.packType or inspItem.id)))
                 or ((collectionCategory == "other") and UI.getHandImage(inspItem.handId or inspItem.id))
                 or ((collectionCategory == "vouchers") and (UI.getVoucherImage(inspItem.id) or UI.getHandImage(inspItem.handId or inspItem.id) or UI.getHandImage(inspItem.id)))
    if not UI.useLegacyPixelArt and collectionCategory ~= "packs" and collectionCategory ~= "consumables" and not deityPreview then inspImg = nil end
    if deityPreview then
        UI.drawPatronCard(inspItem, lcx, lcy, lcw, lch)
    elseif inspImg then
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = inspImg:getDimensions()
        require("ui.card_surfaces").image(inspItem, lcx, lcy, lcw, lch, inspImg)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(lcol)
        UI.drawRoundedRect("line", lcx, lcy, lcw, lch, 10)
    else
        love.graphics.setColor(0.16, 0.20, 0.24, 1)
        UI.drawRoundedRect("fill", lcx, lcy, lcw, lch, 10)
        love.graphics.setColor(lcol[1], lcol[2], lcol[3], 0.95)
        UI.drawRoundedRect("fill", lcx, lcy, lcw, 32, 10)
        UI.drawRoundedRect("fill", lcx, lcy + 18, lcw, 14, 0)
        love.graphics.setLineWidth(2)
        love.graphics.setColor(lcol)
        UI.drawRoundedRect("line", lcx, lcy, lcw, lch, 10)

        UI.drawItemEmblem(inspItem, lcx + lcw / 2, lcy + 92, 36, lcol)
    end


end

Surfaces.starter = Physics.wrap(Surfaces.starter)
Surfaces.preview = Physics.wrap(Surfaces.preview, function(item, x, y, w, h, category)
    local key = tostring(category) .. ":" .. tostring(item.id or item.name)
    catalogHandles[key] = catalogHandles[key] or {}
    return catalogHandles[key]
end)
Surfaces.round = Physics.wrap(Surfaces.round, nil, 6)
Surfaces.image = Physics.wrap(Surfaces.image)

Surfaces.catalog = Physics.wrap(Surfaces.catalog, function(item, x, y, w, h, category)
    local key = tostring(category) .. ":" .. tostring(item.id or item.name)
    catalogHandles[key] = catalogHandles[key] or {}
    return catalogHandles[key]
end, 7)
Surfaces.reward = Physics.wrap(Surfaces.reward, nil, 8)
return Surfaces

local UI = require("src.ui")
local Physics = UI.CardPhysics
local Effects = require("src.card_effects")
local Surfaces = {}
local catalogHandles = {}
local warmPageKey, warmQueue, warmIndex, pendingWarmItems = nil, {}, 1, {}
local warmedCatalogItems = {}

local function catalogItemKey(item, category)
    return table.concat({ tostring(category), tostring(item.packType or ""), tostring(item.id or item.name) }, ":")
end

function Surfaces.beginCatalogWarm(items, category, pageKey)
    if warmPageKey == pageKey then return end
    warmPageKey, warmQueue, warmIndex, pendingWarmItems = pageKey, {}, 1, {}
    for _, item in ipairs(items) do
        local key = catalogItemKey(item, category)
        if not warmedCatalogItems[key] and not pendingWarmItems[key] then
            pendingWarmItems[key] = item
            warmQueue[#warmQueue + 1] = { item = item, key = key, category = category }
        end
    end
end

local function loadCatalogArt(item, category)
    local deityId = (category == "jokers" and item.id)
        or (category == "packs" and item.isPackContent and item.deityId)
    local deityArt = deityId and UI.getDeityImage(deityId)
    local consumableArt = UI.getConsumableImage(item)
    local art = consumableArt or deityArt
        or ((category == "playing_cards") and UI.getCardImage(item.suit, item.rank))
        or ((category == "equipment") and UI.getEquipmentImage(item.id))
        or ((category == "packs") and (item.isPackContent and UI.getPackCardImage(item.packType, item) or UI.getPackImage(item.packType or item.id)))
        or ((category == "other") and UI.getHandImage(item.handId or item.id))
        or ((category == "vouchers") and (UI.getVoucherImage(item.id) or UI.getHandImage(item.handId or item.id) or UI.getHandImage(item.id)))
    return art, deityArt, consumableArt
end

function Surfaces.warmCatalogStep()
    local entry = warmQueue[warmIndex]
    if not entry then return false end
    -- Loading at most one card per frame spreads file decoding and generated
    -- card canvas work over the natural page-turn animation.
    loadCatalogArt(entry.item, entry.category)
    pendingWarmItems[entry.key] = nil
    warmedCatalogItems[entry.key] = true
    warmIndex = warmIndex + 1
    return true
end

function Surfaces.isCatalogWarm(items, category)
    for _, item in ipairs(items) do
        if not warmedCatalogItems[catalogItemKey(item, category)] then return false end
    end
    return true
end

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
    love.graphics.translate(cx + cardW / 2, cy + cardH / 2 - (isH and 3 or 0))
    if isH then
        love.graphics.shear(tX * 0.08, tY * 0.08)
        love.graphics.scale(1.035, 1.035)
    end
    love.graphics.translate(-cardW / 2, -cardH / 2)
    Physics.capture(item, 0, 0, cardW, cardH)

    -- Card Body
    local isPending = pendingWarmItems[catalogItemKey(item, collectionCategory)] ~= nil
    local dImg, deityArt, consumableArt
    if not isPending then dImg, deityArt, consumableArt = loadCatalogArt(item, collectionCategory) end
    if not UI.useLegacyPixelArt and collectionCategory ~= "packs" and collectionCategory ~= "equipment" and collectionCategory ~= "playing_cards" and not deityArt and not consumableArt and not UI.illustratedImages[dImg] then dImg = nil end
    if deityArt then
        UI.drawPatronCard(item, 0, 0, cardW, cardH, isH)
    elseif dImg then
        love.graphics.setColor(0, 0, 0, 0.35)
        UI.drawRoundedRect("fill", 2, 4, cardW, cardH, 8)

        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = dImg:getDimensions()
        Effects.setInteraction(item, isH, false)
        local active = item.category == "edition" and Effects.beginCard(item)
        UI.CardFrame.image(dImg, 0, 0, cardW, cardH)
        Effects.endCard(active)
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

    if not deityArt then UI.drawCardBorder(0, 0, cardW, cardH, isH and UI.COLORS.goldYellow, nil, item) end
    love.graphics.pop()
end

-- Full-bleed reward face. Actions and names are laid out below the card.
function Surfaces.fullReward(item,x,y,w,h,packType,hovered,opacity)
    if item.faceDown then return UI.drawCardBack(x,y,w,h,item.alpha) end
    opacity=opacity or 1
    local g=love.graphics;g.push("all")
    g.setColor(0,0,0,0.45*opacity);g.rectangle("fill",x+4,y+7,w,h,8,8)
    if packType == "buffoon" then
        UI.drawPatronCard(item,x,y,w,h,hovered)
        g.pop();return
    end
    local art=UI.getConsumableImage(item) or (item.handId and UI.getHandImage(item.handId))
        or (packType=="arcana" and UI.getEquipmentImage(item.id))
        or (packType=="standard" and UI.getCardImage(item.suit,item.rank or item.rankName))
        or (packType=="buffoon" and UI.getDeityImage(item.id))
        or ((packType=="celestial" or packType=="hand_styles") and UI.getHandImage(item.handId or item.id))
    local backdrop=not art and UI.getPackImage(packType)
    art=art or backdrop
    if art then
        g.setColor(1,1,1,opacity)
        Effects.setInteraction(item, hovered, false)
        local active = item.category == "edition" and Effects.beginCard(item)
        UI.CardFrame.image(art,x,y,w,h)
        Effects.endCard(active)
        if backdrop then
            local col=item.color or UI.COLORS.goldYellow
            g.setColor(col[1],col[2],col[3],0.28);g.rectangle("fill",x,y,w,h)
            g.setColor(0.025,0.035,0.06,0.75);g.circle("fill",x+w/2,y+h/2,w*0.30)
            UI.drawItemEmblem(item,x+w/2,y+h/2,w*0.24,col)
        end
    else
        g.setColor(0.12,0.14,0.20,1);g.rectangle("fill",x,y,w,h,8,8)
        UI.drawItemEmblem(item,x+w/2,y+h/2,w*0.25,item.color or UI.COLORS.goldYellow)
    end
    if hovered then UI.descriptionCandidate=item end
    UI.drawCardBorder(x,y,w,h,hovered and UI.COLORS.goldYellow,opacity,item)
    g.pop()
end

-- Pack reward body: choice/keep buttons remain in the existing gameplay handler.
function Surfaces.reward(card, cx, drawCY, cW, cH, packType, label, isChoiceHovered)
    if card.faceDown then return UI.drawCardBack(cx, drawCY, cW, cH, card.alpha) end
    local artwork = UI.getConsumableImage(card) or (packType == "arcana" and UI.getEquipmentImage(card.id))
    if artwork then return Surfaces.fullReward(card, cx, drawCY, cW, cH, packType, isChoiceHovered) end
    love.graphics.setColor(0.16, 0.20, 0.26, 0.98)
    UI.drawRoundedRect("fill", cx, drawCY, cW, cH, 10)
    UI.drawCardBorder(cx, drawCY, cW, cH, isChoiceHovered and UI.COLORS.goldYellow, nil, card)

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
    require("ui.components.core").textLine(card.name or ((card.rankName or "") .. (card.suitSymbol or "")),
        cx + 6, drawCY + 138, cW - 12, UI.fonts.small, UI.COLORS.textLight, "center", UI.fonts.tiny)
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(UI.COLORS.textLight)
    -- Reserve the action region. Full ability/evolution details remain in hover.
    local font = UI.fonts.tiny
    local _, lines = font:getWrap(select(2,UI.Description.resolve(card,UI.descriptionGame)), cW - 16)
    local count = math.max(1, math.min(3, math.floor((cH - 163 - 58) / font:getHeight())))
    local shown = {}
    for i = 1, math.min(count, #lines) do shown[i] = lines[i] end
    if #lines > count then
        local last = shown[count]
        while #last > 0 and font:getWidth(last .. "…") > cW - 16 do
            local utf8 = require("utf8")
            last = last:sub(1, (utf8.offset(last, -1) or 1) - 1)
        end
        shown[count] = last .. "…"
    end
    love.graphics.printf(table.concat(shown, "\n"), cx + 8, drawCY + 163, cW - 16, "center")
    love.graphics.setColor(UI.COLORS.textMuted)
    love.graphics.printf("Rê chuột: chi tiết", cx + 8, drawCY + cH - 57, cW - 16, "center")


end

function Surfaces.round(item, x, cardY, cardW, cardH, hovered)
    if item.faceDown then return UI.drawCardBack(x, cardY, cardW, cardH, item.alpha) end
    if UI.getConsumableImage(item) then
        return Surfaces.fullReward(item, x, cardY, cardW, cardH, nil, hovered)
    end
    local color = item.color or UI.COLORS.goldYellow
    love.graphics.setColor(0, 0, 0, 0.35)
    UI.drawRoundedRect("fill", x + 3, cardY + 5, cardW, cardH, 12)
    love.graphics.setColor(0.12, 0.16, 0.21, 1)
    UI.drawRoundedRect("fill", x, cardY, cardW, cardH, 12)
    UI.drawCardBorder(x, cardY, cardW, cardH, hovered and UI.COLORS.goldYellow, nil, item)
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
    UI.CardFrame.image(image, x, y, w, h)
    UI.drawCardBorder(x,y,w,h,nil,nil,item)
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
    local consumableArt = UI.getConsumableImage(inspItem)
    local inspImg = consumableArt or deityPreview
                 or ((collectionCategory == "playing_cards") and UI.getCardImage(inspItem.suit, inspItem.rank))
                 or ((collectionCategory == "equipment") and UI.getEquipmentImage(inspItem.id))
                 or ((collectionCategory == "packs") and (inspItem.isPackContent and UI.getPackCardImage(inspItem.packType, inspItem) or UI.getPackImage(inspItem.packType or inspItem.id)))
                 or ((collectionCategory == "other") and UI.getHandImage(inspItem.handId or inspItem.id))
                 or ((collectionCategory == "vouchers") and (UI.getVoucherImage(inspItem.id) or UI.getHandImage(inspItem.handId or inspItem.id) or UI.getHandImage(inspItem.id)))
    if not UI.useLegacyPixelArt and collectionCategory ~= "packs" and collectionCategory ~= "equipment" and collectionCategory ~= "playing_cards" and not deityPreview and not consumableArt and not UI.illustratedImages[inspImg] then inspImg = nil end
    if deityPreview then
        UI.drawPatronCard(inspItem, lcx, lcy, lcw, lch)
    elseif inspImg then
        love.graphics.setColor(1, 1, 1, 1)
        local iw, ih = inspImg:getDimensions()
        require("ui.card_surfaces").image(inspItem, lcx, lcy, lcw, lch, inspImg)
    else
        love.graphics.setColor(0.16, 0.20, 0.24, 1)
        UI.drawRoundedRect("fill", lcx, lcy, lcw, lch, 10)
        love.graphics.setColor(lcol[1], lcol[2], lcol[3], 0.95)
        UI.drawRoundedRect("fill", lcx, lcy, lcw, 32, 10)
        UI.drawRoundedRect("fill", lcx, lcy + 18, lcw, 14, 0)
        UI.drawCardBorder(lcx,lcy,lcw,lch,nil,nil,inspItem)

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

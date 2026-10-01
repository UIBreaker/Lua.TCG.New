local UI = require("src.ui")
local Theme = require("ui.theme")
local Shop = require("src.shop")

local Display = {}
local C = Theme.colors
local categories = {
    deity = "SPN", equipment = "TRANG BỊ · ITM",
    card = "QUÂN BÀI", hand_expansion = "MỞ RỘNG TAY", heal = "DƯỢC LIỆU",
}
local retailOrder = { deity = 1, equipment = 2, card = 3, hand_expansion = 4, heal = 5 }
local voucherGlyphs = { v_discount = "◇", v_interest = "$", v_hand_plus = "♠" }

local function text(value, x, y, width, font, color, align)
    love.graphics.setFont(font or UI.fonts.tiny)
    love.graphics.setColor(color or C.text)
    love.graphics.printf(value, x, y, width, align or "left")
end

local function panel(x, y, w, h, title, note, accent)
    love.graphics.setColor(C.surface)
    UI.drawRoundedRect("fill", x, y, w, h, 9)
    love.graphics.setColor(C.metal)
    love.graphics.setLineWidth(1)
    UI.drawRoundedRect("line", x, y, w, h, 9)
    love.graphics.setColor(accent or C.gold)
    love.graphics.rectangle("fill", x + 14, y + 14, 3, 12)
    text(title, x + 25, y + 11, w - 40, UI.fonts.small, accent or C.gold)
    if note then text(note, x + 25, y + 30, w - 40, nil, C.muted) end
end

local function price(item, x, y, w, affordable)
    love.graphics.setColor(affordable and { 0.20, 0.16, 0.09, 1 } or C.inset)
    UI.drawRoundedRect("fill", x + (w - 54) / 2, y, 54, 21, 5)
    text("$" .. item.cost, x, y + 2, w, UI.fonts.small, affordable and C.gold or C.red, "center")
end

-- Code-drawn seal/ticket: no names or stats are painted over artwork.
local function ticket(item, x, y, w, h, hovered)
    local accent = item.color or C.gold
    love.graphics.setColor(0.018, 0.025, 0.036, 0.5)
    UI.drawRoundedRect("fill", x + 4, y + 6, w, h, 7)
    love.graphics.setColor(accent[1] * 0.18, accent[2] * 0.18, accent[3] * 0.18, 1)
    UI.drawRoundedRect("fill", x, y, w, h, 7)
    love.graphics.setColor(accent[1], accent[2], accent[3], hovered and 1 or 0.65)
    love.graphics.setLineWidth(hovered and 2 or 1)
    UI.drawRoundedRect("line", x, y, w, h, 7)
    UI.drawRoundedRect("line", x + 6, y + 6, w - 12, h - 12, 4)
    for i = 0, 4 do
        love.graphics.circle("line", x + w / 2, y + h * 0.40, w * 0.23 + i * 2)
    end
    text(voucherGlyphs[item.voucherId or item.id] or item.icon or "◇", x, y + h * 0.40 - 15, w, UI.fonts.large, accent, "center")
    for dx = 10, w - 10, 7 do
        love.graphics.line(x + dx, y + h * 0.72, x + dx + 3, y + h * 0.72)
    end
    love.graphics.setColor(C.surface)
    love.graphics.circle("fill", x, y + h * 0.72, 5)
    love.graphics.circle("fill", x + w, y + h * 0.72, 5)
end

local function art(item, x, y, w, h, hovered, mx, my)
    local tx, ty = 0, 0
    if hovered then tx, ty = UI.calculateTilt(mx, my, x, y, w, h) end
    love.graphics.setColor(C.shadow)
    UI.drawRoundedRect("fill", x + 3, y + 6, w, h, 6)
    love.graphics.push()
    love.graphics.translate(x + w / 2, y + h / 2)
    love.graphics.shear(tx * 0.07, ty * 0.07)
    love.graphics.translate(-w / 2, -h / 2)
    UI.CardPhysics.capture(item, 0, 0, w, h)
    if item.deity then
        UI.drawPatronCard(item.deity, 0, 0, w, h, hovered, false, false, nil, x, y, tx * 0.07, ty * 0.07, 1, 1)
    elseif item.card then
        UI.drawCardFace(item.card, 0, 0, w, h, hovered, x, y, tx * 0.07, ty * 0.07, 1, 1)
    else
        local image = item.equipment and UI.getEquipmentImage(item.equipment.id)
            or (item.category == "hand_expansion" and UI.getVoucherImage("v_hand_size"))
            or (item.category == "pack" and UI.getPackImage(item.packType))
        if image then
            love.graphics.setColor(1, 1, 1, 1)
            local iw, ih = image:getDimensions()
            love.graphics.draw(image, 0, 0, 0, w / iw, h / ih)
        elseif item.category == "heal" then
            -- A potion silhouette replaces the old generic text/gem card.
            local a = item.color or C.green
            love.graphics.setColor(C.inset)
            UI.drawRoundedRect("fill", 0, 0, w, h, 7)
            love.graphics.setColor(a[1], a[2], a[3], 0.20)
            love.graphics.circle("fill", w / 2, h * 0.50, w * 0.35)
            love.graphics.setColor(0.55, 0.86, 0.78, 0.85)
            UI.drawRoundedRect("fill", w * 0.38, h * 0.20, w * 0.24, h * 0.20, 4)
            UI.drawRoundedRect("fill", w * 0.23, h * 0.37, w * 0.54, h * 0.37, 11)
            love.graphics.setColor(a)
            UI.drawRoundedRect("fill", w * 0.27, h * 0.50, w * 0.46, h * 0.20, 8)
            love.graphics.setColor(C.gold)
            UI.drawRoundedRect("fill", w * 0.35, h * 0.18, w * 0.30, h * 0.06, 3)
            love.graphics.setColor(1, 1, 1, 0.55)
            UI.drawRoundedRect("fill", w * 0.30, h * 0.40, 4, h * 0.20, 2)
        else
            ticket(item, 0, 0, w, h, hovered)
        end
    end
    love.graphics.pop()
end

art = UI.CardPhysics.wrap(art, nil, 6)
ticket = UI.CardPhysics.wrap(ticket, nil, 6)

function Display.draw(shop, game, buttons, drag, mx, my, time)
    panel(32, 88, 961, 268, "HÀNG TUYỂN CHỌN", "Nhấp để mua · Kéo thả để nhận · Rê chuột xem chi tiết", C.cyan)
    panel(32, 368, 250, 256, "ĐẶC QUYỀN", "Mua một lần · Hiệu lực suốt run", C.gold)
    panel(294, 368, 699, 256, "KHO RƯƠNG", "Thế đánh · Ba rương ngẫu nhiên · Ấn bản khi xuất hiện", C.purple)
    local hoveredItem, position
    local packIndex = 0
    local voucherFound = false
    for index, item in ipairs(shop.items or {}) do
        local x, y, w, h, hovered
        local retail = item.section == "upper"
        local voucher = item.category == "voucher" or item.category == "book"
        local pack = item.category == "pack"
        if retail then
            x, y, w, h = 67 + ((retailOrder[item.category] or index) - 1) * 186, 151, 118, 176
        elseif voucher then
            voucherFound = true
            x, y, w, h = 48, 422, 218, 186
        elseif pack then
            packIndex = packIndex + 1
            x, y, w, h = 318 + (packIndex - 1) * 134, 435, 112, 158
        end
        if x then
            hovered = mx >= x and mx <= x + w and my >= y - (voucher and 0 or 24) and my <= y + h + (voucher and 0 or 21)
            local dragged = false -- Physics draws held surfaces above the UI.
            local affordable = (game.gold or 0) >= item.cost
            if voucher then
                if not dragged then
                    ticket(item, x + 2, y + 3, 62, 80, hovered)
                    text(item.name, x + 78, y + 4, w - 78, UI.fonts.small, item.color or C.gold)
                    text("HIỆU LỰC SUỐT RUN", x + 78, y + 66, w - 78, nil, C.muted)
                    text(item.desc or "", x, y + 96, w, nil, C.text)
                    local buy = { text = affordable and ("SỞ HỮU · $" .. item.cost) or ("CẦN $" .. item.cost), x = x, y = y + 152, w = w, h = 31, color = UI.COLORS.btnSpecial, font = UI.fonts.small }
                    UI.drawButton(buy, hovered, false)
                end
            else
                local dy = dragged and y or y + (hovered and -5 or math.sin(time * 1.2 + index) * 1.2)
                price(item, x, y - 25, w, affordable)
                if not dragged then art(item, x, dy, w, h, hovered, mx, my) end
                text(retail and categories[item.category] or (item.subtitle or item.name), x - 20, y + h + 8, w + 40, nil, hovered and C.text or (item.color or C.muted), "center")
            end
            if dragged then
                love.graphics.setColor(C.metal)
                UI.drawRoundedRect("line", x, y, w, h, 6)
            end
            buttons[#buttons + 1] = { id = "buy_" .. index, text = "", x = x, y = y - (voucher and 0 or 24), w = w, h = h + (voucher and 0 or 45), invisible = true, itemIndex = index }
            if hovered and not UI.CardPhysics.isHolding() and not (drag.active and drag.isDragging) then
                hoveredItem = item
                position = { x = x + w + 10, y = y + 8 }
            end
        end
    end
    if not voucherFound then
        local count = 0
        for _, v in ipairs(Shop.VOUCHERS) do if game.vouchers and game.vouchers[v.id] then count = count + 1 end end
        text("ĐẶC QUYỀN ĐÃ NHẬN", 50, 440, 214, UI.fonts.small, C.gold, "center")
        text("Đổi hàng để khám phá đặc quyền chưa sở hữu.", 60, 475, 194, nil, C.muted, "center")
        text(count .. " / " .. #Shop.VOUCHERS .. " đặc quyền sở hữu", 50, 567, 214, nil, C.gold, "center")
    end
    if packIndex < 5 then
        love.graphics.setColor(0.16, 0.12, 0.22, 0.35)
        UI.drawRoundedRect("fill", 854, 435, 112, 158, 6)
        love.graphics.setColor(0.40, 0.31, 0.50, 0.40)
        UI.drawRoundedRect("line", 854, 435, 112, 158, 6)
        text("◇", 854, 471, 112, UI.fonts.large, C.purple, "center")
        text("ẤN BẢN\n25% xuất hiện\nkhi đổi hàng", 864, 517, 92, nil, C.muted, "center")
    end
    love.graphics.setLineWidth(1)
    return hoveredItem, position
end

return Display

local UI = require("src.ui")
local Theme = require("ui.theme")
local Shop = require("src.shop")
local Visual = require("config.visual_config")
local Lighting = require("render.lighting")

local Display = {}
local C = Theme.colors
local categories = {
    deity = "SPN", equipment = "TRANG BỊ · ITM",
    card = "QUÂN BÀI", hand_expansion = "MỞ RỘNG TAY", heal = "DƯỢC LIỆU", armor_potion="DƯỢC GIÁP", destroy="TIÊU HỦY · LINH HỒN",speed_single="TỐC ĐÁNH",bed="NGHỈ NGƠI · BẪY GIƯỜNG",
}
local retailOrder = { deity = 1, equipment = 2, card = 3, hand_expansion = 4, heal = 5, armor_potion=5,destroy=5,speed_single=5,bed=5 }
local voucherGlyphs = { v_discount = "◇", v_interest = "$", v_hand_plus = "♠" }

local function text(value, x, y, width, font, color, align)
    love.graphics.setFont(font or UI.fonts.tiny)
    love.graphics.setColor(color or C.text)
    love.graphics.printf(value, x, y, width, align or "left")
end

local function panel(x, y, w, h, title, note, accent)
    -- Display bays let the chamber show through; labels have a quiet opaque rail.
    love.graphics.setColor(C.surface[1], C.surface[2], C.surface[3], 0.28)
    UI.drawRoundedRect("fill", x, y, w, h, 9)
    love.graphics.setColor(C.metal[1],C.metal[2],C.metal[3],0.55)
    love.graphics.setLineWidth(1)
    love.graphics.line(x+10,y+h,x+w-10,y+h)
    love.graphics.setColor(0.015,0.025,0.038,0.82)
    UI.drawRoundedRect("fill",x+6,y+6,w-12,48,5)
    love.graphics.setColor(accent or C.gold)
    love.graphics.rectangle("fill", x + 14, y + 14, 3, 12)
    text(title, x + 25, y + 11, w - 40, UI.fonts.small, accent or C.gold)
    if note then text(note, x + 25, y + 30, w - 40, nil, C.muted) end
end

local function price(item, x, y, w, affordable)
    love.graphics.setColor(affordable and { 0.20, 0.16, 0.09, 1 } or C.inset)
    UI.drawRoundedRect("fill", x + (w - 54) / 2, y, 54, 21, 5)
    text(item.currency=="souls" and (item.cost.." LH") or ("$"..item.cost), x, y + 2, w, UI.fonts.small, affordable and C.gold or C.red, "center")
end

-- Code-drawn seal/ticket: no names or stats are painted over artwork.
local function ticket(item, x, y, w, h, hovered)
    local image=require("src.continental_art").get(item.voucherId or item.id)
    if image then
        love.graphics.setColor(1,1,1,1);UI.CardFrame.image(image,x,y,w,h)
        UI.drawCardBorder(x,y,w,h,hovered and C.gold,nil,item);return
    end
    local accent = item.color or C.gold
    love.graphics.setColor(0.018, 0.025, 0.036, 0.5)
    UI.drawRoundedRect("fill", x + 4, y + 6, w, h, 7)
    love.graphics.setColor(accent[1] * 0.18, accent[2] * 0.18, accent[3] * 0.18, 1)
    UI.drawRoundedRect("fill", x, y, w, h, 7)
    love.graphics.setColor(accent[1], accent[2], accent[3], hovered and 1 or 0.65)
    love.graphics.setLineWidth(hovered and 2 or 1)
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
    UI.drawCardBorder(x, y, w, h, hovered and C.gold, nil, item)
end

local function art(item, x, y, w, h, hovered, mx, my)
    if item.faceDown then return UI.drawCardBack(x, y, w, h, item.alpha) end
    local tx, ty = 0, 0
    -- Shared card physics eases pointer tilt for all shop faces.
    love.graphics.setColor(0.005,0.008,0.015,Visual.shop.shadow)
    love.graphics.ellipse("fill",x+w/2,y+h+3,w*0.49,hovered and 12 or 8)
    if Visual.enabled and hovered then
        love.graphics.push("all");love.graphics.setBlendMode("add")
        Lighting.glow(x+w/2,y+h*0.45,w*0.95,item.color or C.gold,Visual.shop.focusedLight)
        love.graphics.pop()
    end
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
        local image = UI.getConsumableImage(item) or (item.equipment and UI.getEquipmentImage(item.equipment.id))
            or (item.category == "hand_expansion" and UI.getVoucherImage("v_hand_size"))
            or (item.category == "pack" and UI.getPackImage(item.packType))
        if image then
            love.graphics.setColor(1, 1, 1, 1)
            UI.CardFrame.image(image, 0, 0, w, h)
            UI.drawCardBorder(0, 0, w, h, hovered and C.gold, nil, item.equipment or item)
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
            UI.drawCardBorder(0, 0, w, h, hovered and C.gold, nil, item.equipment or item)
        else
            ticket(item, 0, 0, w, h, hovered)
        end
    end
    love.graphics.pop()
end

art = UI.CardPhysics.wrap(art, nil, 6)
ticket = UI.CardPhysics.wrap(ticket, nil, 6)

local function privilege(item, x, y, w, h, hovered, affordable)
    if item.faceDown then return UI.drawCardBack(x, y, w, h, item.alpha) end
    ticket(item, x + 2, y + 3, 62, 80, hovered)
    text(item.name, x + 78, y + 4, w - 78, UI.fonts.small, item.color or C.gold)
    text("HIỆU LỰC SUỐT RUN", x + 78, y + 66, w - 78, nil, C.muted)
    text("Rê chuột để xem hiệu lực", x, y + 112, w, nil, C.muted)
    text(affordable and ("NHẤP ĐỂ CHỌN · $" .. item.cost) or ("CẦN $" .. item.cost),
        x, y + 158, w, UI.fonts.small, affordable and C.gold or C.red, "center")
end
privilege = UI.CardPhysics.wrap(privilege, nil, 6)
local function position(item,index,packIndex)
    if item.section=="upper" then return 67+((retailOrder[item.category] or index)-1)*186,151,118,176 end
    if item.category=="voucher" or item.category=="book" then return 48,422,218,186 end
    if item.category=="pack" then return 318+(packIndex-1)*134,435,112,158 end
end
function Display.drawWorld(shop,time)
    if not shop then return end
    if shop.soulMode then return end
    local g=love.graphics;local packIndex=0
    g.push("all")
    for index,item in ipairs(UI.Polish.items(shop) or {}) do
        if item.category=="pack" and item.section~="upper" then packIndex=packIndex+1 end
        local x,y,w,h=position(item,index,packIndex)
        if x and item.category~="voucher" and item.category~="book" then
            local focus=UI.Polish.focus and UI.Polish.focus.item==item
            local color=item.color or item.deity and (item.deity.color or C.gold) or C.gold
            local rarity=item.rarity or item.deity and item.deity.rarity
            g.setColor(0.015,0.023,0.035,0.88)
            g.polygon("fill",x-12,y+h+8,x+w+12,y+h+8,x+w+18,y+h+20,x-18,y+h+20)
            g.setColor(0.42,0.35,0.23,0.42);g.line(x-12,y+h+8,x+w+12,y+h+8)
            if Visual.enabled and Visual.effects.lighting then
                g.setBlendMode("add")
                local strength=focus and Visual.shop.focusedLight or Visual.shop.spotlight
                if rarity=="rare" or rarity=="legendary" then strength=strength*1.4 end
                Lighting.glow(x+w/2,y+h*0.6,w*1.2,color,strength)
                g.setColor(color[1],color[2],color[3],strength*0.10)
                g.polygon("fill",x+w/2-10,y-50,x+w/2+10,y-50,x+w+20,y+h,x-20,y+h)
                g.setBlendMode("alpha")
            end
        end
    end
    g.pop()
end
local soulBackground
function Display.drawSoulBackground(time)
    local g=love.graphics
    soulBackground=soulBackground or g.newImage("assets/scene/soul_bazaar.png")
    local w,h=soulBackground:getDimensions()
    local fit=math.max(1280/w,720/h)*1.025
    g.push("all");g.setColor(1,1,1)
    g.draw(soulBackground,(1280-w*fit)/2+math.sin(time*0.08)*5,(720-h*fit)/2,0,fit,fit)
    g.setColor(0.025,0.01,0.055,0.20);g.rectangle("fill",0,0,1280,720)
    for i=1,22 do
        local x=(i*173+math.sin(time*0.22+i)*12)%1280
        local y=(i*83-time*(5+i%4))%720
        g.setColor(0.68,0.78,1,0.16+0.12*math.sin(time+i)^2)
        g.circle("fill",x,y,1+i%3*0.3)
    end
    g.pop()
end

local function soulShop(shop, game, buttons, mx, my, time)
    local g=love.graphics
    g.setColor(0.025,0.014,0.06,0.32);UI.drawRoundedRect("fill",22,76,992,560,16)
    text("THƯƠNG ĐIỆN LINH HỒN",56,91,920,UI.fonts.medium,{0.88,0.75,1,1},"center")
    text("Di vật cổ đại · Tiến hóa · Tốc đánh · Đổi bằng linh hồn thu từ mọi lần tiêu hủy",56,122,920,nil,{0.79,0.78,0.90,1},"center")
    local hoveredItem
    local stock=UI.Polish.items(shop)
    local function find(id)
        for index,item in ipairs(stock) do if item.id==id then return item,index end end
    end
    local function bay(x,y,w,h)
        g.setColor(0.045,0.028,0.09,0.76);UI.drawRoundedRect("fill",x,y,w,h,10)
        g.setColor(0.67,0.50,0.84,0.40);g.setLineWidth(1);UI.drawRoundedRect("line",x,y,w,h,10)
    end
    local function offer(item,index,x,y,w,h)
        local hovered=mx>=x and mx<=x+w and my>=y and my<=y+h
        UI.Polish.surface(item,index,hovered,x,y,w,h,function()
            art(item,x,y,w,h,hovered,mx,my)
        end)
        buttons[#buttons+1]={id="buy_"..index,x=x,y=y,w=w,h=h,invisible=true,itemIndex=index,stockItem=item}
        if hovered and UI.Polish.tooltipAllowed(item) then hoveredItem=item end
    end
    for slot=1,5 do
        local id=(shop.soulStock or {})[slot]
        local x=40+(slot-1)*192
        bay(x,153,180,256)
        local item,index=find(id)
        if item then
            offer(item,index,x+39,178,102,153)
            text(item.cost.." LH",x,157,180,UI.fonts.small,(game.souls or 0)>=item.cost and C.purple or C.red,"center")
            text(item.name,x+6,342,168,UI.fonts.small,item.color,"center")
            local caption=item.equipment.shopSummary or item.desc:gsub("Chiếm ",""):gsub(" khi tính điểm%.",""):gsub(" và "," · "):gsub(", tối đa HP tối đa%.","")
            text(caption,x+10,365,160,nil,{0.81,0.79,0.89,1},"center")
        else text("ĐÃ ĐỔI",x,253,180,UI.fonts.medium,C.purple,"center") end
    end
    text("THẺ HỖ TRỢ · MUA VÀO Ô TIÊU HAO",44,429,920,UI.fonts.small,{0.86,0.76,1,1})
    local summaries={evolution="Tiến hóa +1",speed_single="Tốc đơn +5",speed_team="Tốc đội +2",vitality="Máu tối đa +20"}
    for slot=1,#Shop.SOUL_SUPPORT+1 do
        local definition=Shop.SOUL_SUPPORT[slot]
        local id=definition and definition.id or "soul_reaper"
        local item,index=find(id)
        local x=40+(slot-1)*136
        bay(x,460,128,164)
        if item then
            text(item.name,x+8,476,112,UI.fonts.tiny,item.color,"center")
            offer(item,index,x+39,511,50,75)
            local c=item.consumable
            local summary=c.slotType=="spn" and "Ô SPN +1" or c.slotType=="consumable" and "Ô tiêu hao +1"
                or summaries[c.category] or "Hủy bài → LH"
            text(summary,x+4,590,120,UI.fonts.tiny,{.81,.79,.89,1},"center")
            text(item.cost.." LH",x+4,607,120,UI.fonts.tiny,(game.souls or 0)>=item.cost and C.purple or C.red,"center")
        else text("ĐÃ ĐỔI",x+4,531,120,UI.fonts.small,C.purple,"center") end
    end
    return hoveredItem
end

function Display.draw(shop, game, buttons, drag, mx, my, time)
    if shop.soulMode then
        UI.Polish.ensureShop(shop)
        return soulShop(shop,game,buttons,mx,my,time)
    end
    panel(32, 88, 961, 268, "HÀNG TUYỂN CHỌN", "Nhấp chọn hàng → MUA · Rê chuột xem chi tiết", C.cyan)
    panel(32, 368, 250, 256, "ĐẶC QUYỀN", "Mua một lần · Hiệu lực suốt run", C.gold)
    panel(294, 368, 699, 256, "KHO RƯƠNG", "Thế đánh · Ba rương ngẫu nhiên · Ấn bản khi xuất hiện", C.purple)
    UI.Polish.ensureShop(shop)
    local hoveredItem
    local packIndex = 0
    local voucherFound = false
    for index, item in ipairs(UI.Polish.items(shop) or {}) do
        local x, y, w, h, hovered
        local retail = item.section == "upper"
        local voucher = item.category == "voucher" or item.category == "book"
        local pack = item.category == "pack"
        if voucher then voucherFound=true end
        if pack and not retail then packIndex=packIndex+1 end
        x,y,w,h=position(item,index,packIndex)
        if x then
            hovered = mx >= x and mx <= x + w and my >= y - (voucher and 0 or 24) and my <= y + h + (voucher and 0 or 21)
            local dragged = false -- Physics draws held surfaces above the UI.
            local affordable = (game.gold or 0) >= item.cost
            UI.Polish.surface(item, index, hovered, x, y, w, h, function()
            if voucher then
                privilege(item, x, y, w, h, hovered, affordable)
            else
                local dy = y
                price(item, x, y - 25, w, affordable)
                if not dragged then art(item, x, dy, w, h, hovered, mx, my) end
                text(retail and categories[item.category] or (item.subtitle or item.name), x - 20, y + h + 8, w + 40, nil, hovered and C.text or (item.color or C.muted), "center")
            end
            end)
            if dragged then
                love.graphics.setColor(C.metal)
                UI.drawRoundedRect("line", x, y, w, h, 6)
            end
            buttons[#buttons + 1] = { id = "buy_" .. index, text = "", x = x, y = y - (voucher and 0 or 6), w = w, h = h + (voucher and 0 or 6), invisible = true, itemIndex = index, stockItem = item }
            if hovered and UI.Polish.tooltipAllowed(item) and not UI.CardPhysics.isHolding() and not (drag.active and drag.isDragging) then
                hoveredItem = item
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
    return hoveredItem
end

Display.drawArt = art
return Display

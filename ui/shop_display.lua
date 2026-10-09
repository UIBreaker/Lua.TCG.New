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
    if item.sale then
        love.graphics.setColor(0.10,0.075,0.035,.98)
        UI.drawRoundedRect("fill",x-10,y,w+20,23,5)
        text("$"..item.originalCost,x-5,y+5,48,UI.fonts.tiny,C.muted,"center")
        love.graphics.setColor(.85,.46,.27,1);love.graphics.setLineWidth(1.5)
        love.graphics.line(x-1,y+17,x+40,y+5)
        text(item.cost==0 and "MIỄN PHÍ" or ("$"..item.cost),x+44,y+4,w-42,UI.fonts.tiny,item.cost==0 and C.green or affordable and C.gold or C.red,"center")
        return
    end
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
    if item.backpack and item.equipment then require("ui.backpack").stats(UI,item.equipment,0,0,w,h) end
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
    if item.section=="basic" then return 734+(item.bay-1)*132,153,118,176 end
    if item.section=="discount" then return 946+(item.bay-1)*164,443,118,176 end
    if item.section=="upper" then return 46+((retailOrder[item.category] or index)-1)*132,153,118,176 end
    if item.category=="voucher" or item.category=="book" then return 36,443,210,186 end
    if item.category=="pack" then return 280+(packIndex-1)*124,443,96,144 end
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
    g.setColor(0.018,0.014,0.035,0.58);UI.drawRoundedRect("fill",22,77,1236,566,14)
    g.setColor(.56,.43,.73,.45);g.setLineWidth(1);UI.drawRoundedRect("line",22,77,1236,566,14)
    text("DI VẬT DỊ GIỚI",40,89,370,UI.fonts.medium,{0.88,0.75,1,1})
    text("5 di vật tuyển chọn · Nhấp xem, xác nhận để đổi",405,95,570,nil,C.muted,"right")
    text("LINH HỒN · "..(game.souls or 0),1002,91,235,UI.fonts.small,C.gold,"right")
    g.setColor(.56,.43,.73,.32);g.line(40,117,1240,117)
    local hoveredItem
    local stock=UI.Polish.items(shop)
    local function find(id)
        for index,item in ipairs(stock) do if item.id==id then return item,index end end
    end
    local function bay(x,y,w,h,accent,hovered)
        accent=accent or C.purple
        g.setColor(0.006,0.004,0.018,.5);UI.drawRoundedRect("fill",x+2,y+4,w,h,9)
        g.setColor(hovered and {0.095,0.062,0.145,.96} or {0.031,0.022,0.057,.9});UI.drawRoundedRect("fill",x,y,w,h,9)
        g.setColor(accent[1],accent[2],accent[3],hovered and .8 or .32);g.setLineWidth(1);UI.drawRoundedRect("line",x,y,w,h,9)
        g.setColor(accent[1],accent[2],accent[3],.65);g.line(x+14,y,x+w-14,y)
    end
    local function offer(item,index,x,y,w,h,face)
        local hovered=mx>=x and mx<=x+w and my>=y and my<=y+h
        UI.Polish.surface(item,index,hovered,face.x,face.y,face.w,face.h,function()
            art(item,face.x,face.y,face.w,face.h,hovered,mx,my)
        end)
        buttons[#buttons+1]={id="buy_"..index,x=x,y=y,w=w,h=h,invisible=true,itemIndex=index,stockItem=item,focusRect=face}
        if hovered and UI.Polish.tooltipAllowed(item) then hoveredItem=item end
    end
    for slot=1,5 do
        local id=(shop.soulStock or {})[slot]
        local x=40+(slot-1)*244
        local item,index=find(id)
        local hovered=mx>=x and mx<x+224 and my>=127 and my<=396
        bay(x,127,224,269,item and item.color,hovered)
        if item then
            offer(item,index,x,127,224,269,{x=x+56,y=157,w=112,h=168})
            g.setColor(.15,.1,.23,1);UI.drawRoundedRect("fill",x+71,133,82,20,5)
            text(item.cost.." LH",x+71,134,82,UI.fonts.small,(game.souls or 0)>=item.cost and C.gold or C.red,"center")
            text(item.name,x+7,332,210,UI.fonts.small,item.color,"center")
            local caption=item.equipment.shopSummary or item.desc:gsub("Chiếm ",""):gsub(" khi tính điểm%.",""):gsub(" và "," · "):gsub(", tối đa HP tối đa%.","")
            text(caption,x+12,358,200,nil,{0.81,0.79,0.89,1},"center")
        else
            local eq=require("src.equipment").ITEMS[id]
            text("◇",x,205,224,UI.fonts.large,C.muted,"center")
            text("ĐÃ ĐỔI",x,255,224,UI.fonts.small,C.muted,"center")
            if eq then text(eq.name,x+10,332,204,UI.fonts.small,C.muted,"center") end
        end
    end
    text("NGHI LỄ & THẺ HỖ TRỢ",40,409,440,UI.fonts.small,{0.86,0.76,1,1})
    text("HIẾN TẾ TẠI CHỢ: ×2 LH · +10 HP · +5 VÀNG",580,411,660,nil,C.gold,"right")
    local summaries={evolution="Tiến hóa +1",speed_single="Tốc đơn +5",speed_team="Tốc đội +2",vitality="Máu tối đa +20",socket_expansion="Hốc +1 / 8",rule_break="ITM trùng loại"}
    for slot=1,#Shop.SOUL_SUPPORT+1 do
        local definition=Shop.SOUL_SUPPORT[slot]
        local id=definition and definition.id or "soul_reaper"
        local item,index=find(id)
        local x=40+(slot-1)*136
        local rare=id=="cons_socket" or id=="cons_rulebreak"
        local hovered=mx>=x and mx<=x+112 and my>=439 and my<=634
        bay(x,439,112,195,item and item.color,hovered)
        if item then
            text(item.name,x+4,447,104,UI.fonts.tiny,item.color,"center")
            offer(item,index,x,439,112,195,{x=x+16,y=478,w=80,h=120})
            local c=item.consumable
            local summary=c.slotType=="spn" and "Ô SPN +1" or c.slotType=="consumable" and "Ô tiêu hao +1"
                or summaries[c.category] or "Hủy bài · ×2 LH"
            text(summary,x+2,602,108,UI.fonts.tiny,{.81,.79,.89,1},"center")
            text(item.cost.." LH",x+4,618,104,UI.fonts.tiny,(game.souls or 0)>=item.cost and (rare and C.gold or C.purple) or C.red,"center")
        else
            text("ĐÃ ĐỔI",x+4,520,104,UI.fonts.small,C.muted,"center")
            if definition then text(require("src.run_manager")[definition.factory]().name,x+4,447,104,UI.fonts.tiny,C.muted,"center") end
        end
    end
    return hoveredItem
end

function Display.draw(shop, game, buttons, drag, mx, my, time)
    if shop.soulMode then
        UI.Polish.ensureShop(shop)
        return soulShop(shop,game,buttons,mx,my,time)
    end
    panel(20,80,690,280,"HÀNG TUYỂN CHỌN","Nhấp chọn → mua · Rê chuột xem chi tiết",C.cyan)
    panel(722,80,540,280,"NGUYÊN LIỆU CƠ BẢN","Máu · Giáp · Tốc đánh · Kinh tế — cất vào balo để ghép",C.green)
    panel(20,376,232,264,"ĐẶC QUYỀN","Mua một lần · Hiệu lực suốt run",C.gold)
    panel(264,376,650,264,"KHO RƯƠNG","Thế đánh · Rương ngẫu nhiên · Ấn bản",C.purple)
    panel(926,376,336,264,"QUẦY GIẢM GIÁ","Giảm 35% · Mỗi món có 8% miễn phí",C.gold)
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
        UI.drawRoundedRect("fill", 776, 443, 96, 144, 6)
        love.graphics.setColor(0.40, 0.31, 0.50, 0.40)
        UI.drawRoundedRect("line", 776, 443, 96, 144, 6)
        text("◇", 776, 475, 96, UI.fonts.large, C.purple, "center")
        text("ẤN BẢN\n25% xuất hiện\nkhi đổi hàng", 782, 517, 84, nil, C.muted, "center")
    end
    love.graphics.setLineWidth(1)
    return hoveredItem
end

Display.position = position
Display.drawArt = art
return Display

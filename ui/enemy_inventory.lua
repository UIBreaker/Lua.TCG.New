local Core=require("ui.components.core")
local Chrome=require("ui.combat_chrome")
local L=require("src.enemy_loadout")
local I={}
local gold={.95,.78,.39};local blue={.56,.83,1};local muted={.66,.73,.78}
local function text(value,x,y,w,font,color) Core.text(value,x,y,w,font,color or muted) end
local function item(UI,owned,x,y,w,h,label)
    Chrome.well(x,y,w,h,blue)
    if not owned then text(label.." · Chưa có",x+14,y+14,w-28,UI.fonts.small);return end
    local d=L.describeItem(owned)
    local image=owned.kind=="equipment" and UI.getEquipmentImage(owned.id)
        or owned.kind=="spn" and UI.getDeityImage(owned.id) or UI.getConsumableImage({id=owned.id,category=owned.kind})
    if image then
        local compact=h<80
        local ix,iy,iw,ih=x+(compact and 8 or 12),y+(compact and 7 or 12),compact and 30 or 44,compact and 45 or 66
        love.graphics.setColor(1,1,1);UI.CardFrame.image(image,ix,iy,iw,ih)
        UI.drawCardBorder(ix,iy,iw,ih)
    end
    if h<80 then
        Core.textLine(label.." · "..d.name,x+46,y+5,w-54,UI.fonts.tiny,gold,"left")
        text(d.desc,x+46,y+22,w-54,UI.fonts.tiny)
        return
    end
    text(label.." · "..d.name,x+68,y+9,w-80,UI.fonts.small,gold)
    text(d.desc,x+68,y+32,w-80,UI.fonts.small)
    if d.edition then
        text(d.edition.." · "..d.editionDesc,x+68,y+h-26,w-80,UI.fonts.tiny,blue)
    end
end
function I.draw(UI,m,buttons)
    local g=love.graphics;local bag=m.enemyInventory
    g.push("all");g.setShader();g.setScissor();g.setBlendMode("alpha")
    g.setColor(.02,.035,.05,1);g.rectangle("fill",0,0,1280,720)
    Chrome.panel(8,8,1264,704,gold)
    text("KHO ĐỒ ĐỊCH · "..m.name,28,25,1050,UI.fonts.large,gold)
    text(L.describe(m).." · "..(m.isBoss and "BOSS" or m.isElite and "TINH ANH" or "ĐỐI THỦ THƯỜNG"),28,66,1120,UI.fonts.small)
    local A=require("src.enemy_abilities")
    text("HP "..UI.formatNumber(m.hp).." / "..UI.formatNumber(m.maxHp).."     GIÁP "..UI.formatNumber(m.creatureArmor or 0)
        .."     ST "..UI.formatNumber(A.attack(m)).."     TỐC "..A.speed(m),28,101,1190,UI.fonts.medium,blue)
    Chrome.panel(28,143,600,335,blue);Chrome.panel(647,143,605,335,blue)
    text("TRANG BỊ ĐANG MANG",42,155,570,UI.fonts.small,gold)
    for index=1,3 do item(UI,bag.equipment[index],42,184+(index-1)*94,572,88,"Ô "..index) end
    text("DẤU ẤN / SPN",663,155,570,UI.fonts.small,gold)
    item(UI,bag.seal,661,184,577,120,"Dấu ấn")
    item(UI,bag.spn,661,314,577,100,"SPN")
    local r=A.resources(m);local c=r.charges
    text("LƯỢT CÒN · Hồi "..c.heal.." / Giáp "..c.armor.." / Tốc "..c.speed.." / ST "..c.damage,663,420,567,UI.fonts.tiny,gold)
    text("DỰ TRỮ CÒN · Hồi "..UI.formatNumber(r.healingLeft).." HP / Tạo "..UI.formatNumber(r.armorLeft).." Giáp",663,435,567,UI.fonts.tiny,blue)
    text(m.isBoss and (require("src.boss_abilities").passiveEnabled(m) and "Phong ấn nội tại để vô hiệu Dấu / SPN." or "Dấu / SPN đang bị phong ấn.")
        or "Dấu / SPN dùng chung dự trữ hồi và tạo giáp.",663,450,567,UI.fonts.tiny)
    Chrome.panel(28,494,1224,198,gold)
    text("BALO DỰ TRỮ · DÙNG / ĐỔI ĐỒ TỐN MỘT HÀNH ĐỘNG",42,506,1160,UI.fonts.small,gold)
    local supplies={}
    local reserve=bag.backpack.equipment[1] or bag.stowed
    if reserve then supplies[#supplies+1]={owned=reserve,label=bag.stowed and "Đã cất" or "Trang bị dự trữ"} end
    local spn=(bag.backpack.spns or {})[1] or bag.stowedSpn
    if spn then supplies[#supplies+1]={owned=spn,label=bag.stowedSpn and "SPN đã cất" or "SPN dự trữ"} end
    for index,owned in ipairs(bag.backpack.consumables) do supplies[#supplies+1]={owned=owned,label="Tiêu hao "..index} end
    for index,entry in ipairs(supplies) do
        item(UI,entry.owned,42+((index-1)%3)*400,530+math.floor((index-1)/3)*64,386,60,entry.label)
    end
    if #supplies==0 then text("Balo trống · Không còn đồ dự trữ.",42,550,1160,UI.fonts.small) end
    text("Ý định: "..(m.intent and m.intent.label or "Chưa rõ"),42,662,1180,UI.fonts.tiny,blue)
    local close={id="close_inspector",text="ĐÓNG · ESC",x=1106,y=23,w=143,h=43,font=UI.fonts.small,color=UI.COLORS.btnDiscard}
    buttons[#buttons+1]=close;UI.drawButton(close)
    g.pop()
end
return I

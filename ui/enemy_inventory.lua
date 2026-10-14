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
        love.graphics.setColor(1,1,1);UI.CardFrame.image(image,x+12,y+12,44,66)
        UI.drawCardBorder(x+12,y+12,44,66)
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
    item(UI,bag.spn,661,314,577,120,"SPN")
    text(m.isBoss and (require("src.boss_abilities").passiveEnabled(m) and "Phong ấn nội tại để vô hiệu Dấu / SPN." or "Dấu / SPN đang bị phong ấn.")
        or "Dấu / SPN kích hoạt theo hành động của đối thủ.",663,446,567,UI.fonts.tiny)
    Chrome.panel(28,494,1224,185,gold)
    text("BALO DỰ TRỮ · DÙNG / ĐỔI ĐỒ TỐN MỘT HÀNH ĐỘNG",42,506,1160,UI.fonts.small,gold)
    local reserve=bag.backpack.equipment[1] or bag.stowed
    item(UI,reserve,42,536,572,114,bag.stowed and "Đã cất · không đổi lại" or "Trang bị dự trữ")
    item(UI,bag.backpack.consumables[1],661,536,577,114,"Thuốc dự trữ")
    text("Ý định: "..(m.intent and m.intent.label or "Chưa rõ"),42,657,1180,UI.fonts.tiny,blue)
    local close={id="close_inspector",text="ĐÓNG · ESC",x=1106,y=23,w=143,h=43,font=UI.fonts.small,color=UI.COLORS.btnDiscard}
    buttons[#buttons+1]=close;UI.drawButton(close)
    g.pop()
end
return I

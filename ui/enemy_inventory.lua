local Core=require("ui.components.core")
local Style=require("ui.backpack_style")
local L=require("src.enemy_loadout")
local I={}
local gold={.88,.73,.47};local blue={.36,.76,.96};local green={.42,.82,.62}
local red={1,.40,.38};local purple={.72,.59,.91};local white={.92,.94,.92};local muted={.55,.64,.68}
local function text(value,x,y,w,font,color,align) Core.text(value,x,y,w,font,color or muted,align) end
local function line(value,x,y,w,font,color) Core.textLine(value,x,y,w,font,color or white) end
local function percent(value) return string.format("%.1f",value*100):gsub("%.0$","").."%" end
local function summary(owned)
    if owned.kind=="consumable" then
        for _,def in ipairs(L.config.consumables) do if def.id==owned.id then
            local p=percent(owned.pct or (def.pct or 0)*(owned.power or 1))
            return ({heal="Hồi "..p.." HP",armor="Giáp "..p.." HP",damage="+"..p.." sát thương",
                speed="+"..p.." tốc"..(def.team and " · cả đội" or ""),accuracy="Trúng 100% · 1 đòn"})[def.effect]
        end end
    end
    local def,power=L.item(owned)
    if not def then return "" end
    if def.stats then
        local parts={}
        for _,key in ipairs({"damage","hp","speed","armor","heal"}) do if def.stats[key] then
            parts[#parts+1]=({damage="ST +",hp="HP +",speed="Tốc +",armor="Giáp ",heal="Hồi "})[key]..percent(def.stats[key]*power)
        end end
        return table.concat(parts," · ")
    end
    local p=percent(def.pct*power)
    return ({leech="Hút "..p.." HP",pierce="Xuyên "..p.." giáp",supportArmor="Giáp "..p.." sau hỗ trợ",
        support="+"..p.." hiệu lực buff",echo="+"..p.." ST / đòn 3"})[def.stat] or ""
end
local function accent(owned)
    return owned and (owned.kind=="spn" and purple or owned.kind=="seal" and blue or owned.kind=="consumable" and green) or gold
end
local function tile(UI,entry,x,y,reserve)
    local owned=entry.owned;local w,h=174,reserve and 158 or 230
    local mx,my=UI.virtualMouseX or -1,UI.virtualMouseY or -1
    local hover=owned and mx>=x and mx<=x+w and my>=y and my<=y+h
    local color=accent(owned)
    Style.panel(x,y,w,h,color,hover,.96)
    line(entry.label,x+12,y+10,w-24,UI.fonts.tiny,owned and color or muted)
    if not owned then
        Style.glyph(entry.kind or "equipment",x+w/2,y+(reserve and 68 or 101),17,{.25,.34,.37})
        text("Chưa trang bị",x+12,y+(reserve and 111 or 169),w-24,UI.fonts.small,muted,"center")
        return
    end
    local d=L.describeItem(owned)
    local image=owned.kind=="equipment" and UI.getEquipmentImage(owned.id)
        or owned.kind=="spn" and UI.getDeityImage(owned.id) or UI.getConsumableImage({id=owned.id,category=owned.kind})
    local iw,ih=reserve and 44 or 72,reserve and 66 or 108
    if image then
        love.graphics.setColor(1,1,1);UI.CardFrame.image(image,x+(w-iw)/2,y+(reserve and 26 or 30),iw,ih)
        UI.drawCardBorder(x+(w-iw)/2,y+(reserve and 26 or 30),iw,ih)
    end
    if d.edition then Core.textLine(d.edition,x+69,y+10,w-81,UI.fonts.tiny,blue,"right") end
    text(d.name,x+12,y+(reserve and 100 or 147),w-24,reserve and UI.fonts.small or UI.fonts.regular,white,"center")
    if reserve then Core.textLine(summary(owned),x+10,y+139,w-20,UI.fonts.tiny,color,"center")
    else text(summary(owned),x+12,y+194,w-24,UI.fonts.small,color,"center") end
    return hover and {item=owned,label=entry.label,detail=d} or nil
end
local function meter(UI,label,value,maximum,x,y,color)
    line(label,x,y,100,UI.fonts.small,muted)
    Core.textLine(UI.formatNumber(value),x,y-2,212,UI.fonts.regular,color,"right")
    Core.color({.015,.033,.042});love.graphics.rectangle("fill",x,y+26,212,5,2)
    if value>0 then
        Core.color(color);love.graphics.rectangle("fill",x,y+26,212*math.min(1,value/math.max(1,maximum)),5,2)
    end
end
function I.draw(UI,m,buttons)
    local g=love.graphics;local bag=m.enemyInventory;local A=require("src.enemy_abilities")
    local r=A.resources(m)
    g.push("all");g.setShader();g.setScissor();g.setBlendMode("alpha")
    Core.gradient(0,0,1280,720,{.035,.067,.080,1},{.012,.026,.035,1})
    Core.color(gold,.28);g.rectangle("line",12,12,1256,696,12)
    Style.panel(24,24,260,672,gold,false)
    Style.glyph("bag",52,52,10,gold)
    line("HỒ SƠ ĐỐI THỦ",74,43,188,UI.fonts.small,gold)
    text(m.name,44,84,218,UI.fonts.medium,white)
    line(bag.role.." · "..(m.isBoss and "BOSS" or m.isElite and "TINH ANH" or "THƯỜNG"),44,151,216,UI.fonts.small,gold)
    Core.color(gold,.2);g.line(44,181,260,181)
    meter(UI,"SINH LỰC",m.hp,m.maxHp,44,202,green)
    line("/ "..UI.formatNumber(m.maxHp).." HP tối đa",44,241,214,UI.fonts.small,muted)
    meter(UI,"GIÁP",m.creatureArmor or 0,m.creatureArmorMax or 0,44,276,blue)
    for index,stat in ipairs({{label="SÁT THƯƠNG",value=A.attack(m),color=red},{label="TỐC ĐÁNH",value=A.speed(m),color=blue}}) do
        local x=44+(index-1)*112
        line(stat.label,x,335,106,UI.fonts.tiny,muted)
        line(UI.formatNumber(stat.value),x,358,106,UI.fonts.medium,stat.color)
    end
    Core.color(gold,.2);g.line(44,407,260,407)
    line("LƯỢT HỖ TRỢ CÒN",44,427,214,UI.fonts.small,gold)
    for index,stat in ipairs({{"heal","HỒI",green},{"armor","GIÁP",blue},{"speed","TỐC",blue},{"damage","ST",red}}) do
        local x=44+(index-1)*55
        text(r.charges[stat[1]],x,461,46,UI.fonts.medium,stat[3],"center")
        text(stat[2],x,492,46,UI.fonts.tiny,muted,"center")
    end
    line("DỰ TRỮ TRONG TRẬN",44,542,216,UI.fonts.tiny,muted)
    line("Hồi  "..UI.formatNumber(r.healingLeft).." HP",44,568,216,UI.fonts.small,green)
    line("Tạo  "..UI.formatNumber(r.armorLeft).." giáp",44,593,216,UI.fonts.small,blue)
    local sealed=m.isBoss and not require("src.boss_abilities").passiveEnabled(m)
    text(sealed and "Dấu ấn / SPN đang bị phong ấn" or "Hồi máu và tạo giáp dùng chung dự trữ.",44,643,212,UI.fonts.small,sealed and purple or muted)
    line("ĐANG TRANG BỊ",310,31,600,UI.fonts.medium,white)
    line("Trang bị · dấu ấn · SPN",310,59,600,UI.fonts.small,muted)
    local equipped={}
    for index=1,3 do equipped[#equipped+1]={owned=bag.equipment[index],label="Ô "..index,kind="equipment"} end
    equipped[4]={owned=bag.seal,label="DẤU ẤN",kind="cards"};equipped[5]={owned=bag.spn,label="SPN",kind="spn"}
    local hovered
    for index,entry in ipairs(equipped) do hovered=tile(UI,entry,310+(index-1)*190,88,false) or hovered end
    line("BALO DỰ TRỮ",310,333,260,UI.fonts.regular,gold)
    Core.textLine("Dùng / thay đồ tốn 1 hành động",580,336,664,UI.fonts.small,muted,"right")
    local supplies={}
    local reserve=bag.backpack.equipment[1] or bag.stowed
    if reserve then supplies[#supplies+1]={owned=reserve,label=bag.stowed and "ĐÃ CẤT" or "TRANG BỊ"} end
    local spn=(bag.backpack.spns or {})[1] or bag.stowedSpn
    if spn then supplies[#supplies+1]={owned=spn,label=bag.stowedSpn and "SPN ĐÃ CẤT" or "SPN DỰ TRỮ"} end
    for _,owned in ipairs(bag.backpack.consumables) do supplies[#supplies+1]={owned=owned,label="DÙNG MỘT LẦN"} end
    for index,entry in ipairs(supplies) do hovered=tile(UI,entry,310+(index-1)*190,365,true) or hovered end
    if #supplies==0 then
        Style.panel(310,365,934,158,gold,false)
        Style.glyph("bag",354,439,18,muted)
        line("Balo trống",397,412,790,UI.fonts.regular,white)
        line("Đối thủ không còn đồ dự trữ.",397,443,790,UI.fonts.small,muted)
    end
    Style.panel(310,542,934,122,hovered and accent(hovered.item) or gold,false)
    if hovered then
        line(hovered.detail.name,330,556,892,UI.fonts.medium,accent(hovered.item))
        text(hovered.detail.desc,330,589,892,UI.fonts.regular,white)
        if hovered.detail.edition then line(hovered.detail.editionDesc,330,639,892,UI.fonts.tiny,blue) end
    else
        line("Ý ĐỊNH TIẾP THEO",330,557,892,UI.fonts.tiny,gold)
        text(m.intent and m.intent.label or "Chưa rõ",330,584,892,UI.fonts.regular,white)
        line("Rê chuột lên một món để xem hiệu ứng đầy đủ.",330,637,892,UI.fonts.small,muted)
    end
    line(hovered and ("Tiếp theo: "..(m.intent and m.intent.label or "Chưa rõ")) or "Đồ đang dùng và đồ dự trữ thuộc riêng đối thủ này.",310,682,934,UI.fonts.tiny,muted)
    local close={id="close_inspector",text="ĐÓNG · ESC",x=1106,y=23,w=143,h=43,font=UI.fonts.small,color=UI.COLORS.btnDiscard}
    buttons[#buttons+1]=close;UI.drawButton(close)
    g.pop()
end
return I

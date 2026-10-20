local I={scroll={0,0},columns={}}
local E=require("src.equipment")
local D=require("src.card_description")
local A=require("src.card_abilities")
local Deck=require("src.deck")
local Style=require("ui.backpack_style")
local Chrome=require("ui.combat_chrome")
local Core=require("ui.components.core")
local Theme=require("ui.theme")
local function unwrap(item)
    while item.card or item.deity or item.equipment or item.item do item=item.card or item.deity or item.equipment or item.item end
    return item
end
local function row(label,text,color) return {label=label,text=text,color=color} end
function I.model(item,game)
    item=unwrap(item)
    local title,body=D.resolve(item,game)
    local voucher=require("src.shop").voucherDescription(item.voucherId or item.id)
    local def=A.definition(item)
    local m={item=item,title=title,body=body,rows={},equipment={},accent=item.color or {.88,.72,.43,1}}
    m.name=def and def.characterName:match("^(.-) ·") or (voucher and title) or item.name or title
    m.subtitle=def and ((item.rankName or item.rank)..(item.suitSymbol or "").." · "..def.name) or title
    local groups, order = {}, {"primary","warning","state","next","upgrades","role","rules","lore"}
    local labels={primary=def and "KHẢ NĂNG HIỆN TẠI" or "TÁC DỤNG",state="TRẠNG THÁI HIỆN TẠI",warning="ĐANG BỊ HẠN CHẾ",
        next="CẤP KẾ TIẾP",upgrades="TIẾN HÓA & HIỆU ỨNG BỔ SUNG",role="VAI TRÒ TRONG THẾ ĐÁNH",
        rules="QUY TẮC KÍCH HOẠT",lore="CÂU CHUYỆN"}
    local colors={primary=Theme.colors.gold,warning=Theme.colors.red,state=Theme.colors.cyan,next=Theme.colors.cyan,
        upgrades=Theme.colors.purple,role=Theme.colors.gold,rules=Theme.colors.muted,lore=Theme.colors.muted}
    local section="primary"
    local socketLines, socketSection={},false
    for _,eq in ipairs(item.equipments or {}) do
        for line in (E.getDescription(eq).."\n"):gmatch("([^\n]+)\n") do socketLines[line]=true end
    end
    local function append(kind,line)
        groups[kind]=groups[kind] or {}
        groups[kind][#groups[kind]+1]=line
    end
    for line in (body.."\n"):gmatch("([^\n]+)\n") do
        if line:match("^SPN · ") or line:match("^ITM · %d+%.") or line:match("^HỐC TRANG BỊ") or line:match("^Cơ bản:") or socketSection and socketLines[line] then
            -- Stats and socket effects are already shown in their own columns.
            if line:match("^HỐC TRANG BỊ") then socketSection=true end
        elseif def and line==def.ambition then append("lore",line)
        elseif line:match("^KẾ TIẾP:") then append("next",line:gsub("^KẾ TIẾP: *",""))
        elseif line:match("^TIẾN HÓA") then
            section="state"
            if line:find("TẠM",1,true) then append("upgrades",line) end
        elseif line:match("^Vai trò") then append("role",line)
        elseif line:find("KHÓA",1,true) or line:find("VÔ HIỆU",1,true) or line:find("QUÊN LÃNG",1,true) then append("warning",line)
        elseif line:match("^Kích hoạt") or line:match("^Toàn tay:") or line:match("^Cơ: hồi Máu dư") or line:match("^Vàng hoặc Tốc vượt") then append("rules",line)
        elseif line:match("^ẤN BẢN · ") or line:match("^ẤN ·") or line:match("^RÈN ·") or line:match("^PHÁ LUẬT")
            or line:match("^THUỐC") or line:match("^DƯỢC HỒN") or line:match("^PHÙ PHÉP") then section="upgrades";append(section,line)
        else append(section,line:gsub("^ITM · ","")) end
    end
    if item.lore and item.lore~="" and not body:find(item.lore,1,true) then append("lore",item.lore) end
    for _,kind in ipairs(order) do
        if groups[kind] then
            local r=row(labels[kind],table.concat(groups[kind],"\n\n"),colors[kind])
            r.kind=kind;m.rows[#m.rows+1]=r
        end
    end
    if item.rank then
        m.role=item.role and Deck.CARD_ROLES[item.role] or Deck.getCardRole(item.rank)
        m.stats={{"SÁT THƯƠNG",item.baseChips or Deck.getChipValue(item.rank)},
            {"TỐC ĐÁNH",Deck.peekCardAttackSpeed(item,game)},
            {"TIẾN HÓA",(item.evolutionLevel or 0).." / "..A.config.maxEvolutionLevel},
            {"HỐC KHẢM",E.getUsedSlots(item).." / "..E.getMaxSlots(item)}}
        local entries=E.getSocketEntries(item)
        local positions={"Trái trên","Phải trên","Phải dưới","Trái dưới","Cạnh trên","Cạnh phải","Cạnh dưới","Cạnh trái"}
        local empty={}
        for slot=1,E.getMaxSlots(item) do
            local entry=entries[slot];local eq=entry and entry.equipment
            if not eq then
                empty[#empty+1]=string.format("Ô %02d · ",slot)..(positions[slot] or "Hốc mở rộng")
            elseif not entry.linked then
                local r=row(string.format("Ô %02d · ",slot)..positions[slot].." · T"..E.getTier(eq).." · "..(eq.slotsNeeded or 1).." hốc",E.getDescription(eq),E.getTierColor(eq))
                r.equipment=eq;r.name=eq.name;r.kind="equipment"
                m.equipment[#m.equipment+1]=r
            end
        end
        if #empty>0 then
            local r=row(#empty.." HỐC CÒN TRỐNG",table.concat(empty,"\n"),Theme.colors.muted)
            r.kind="empty";m.equipment[#m.equipment+1]=r
        end

    else
        m.stats={}
        local deity=require("src.deities").CATALOG[item.id]
        if deity then
            m.subtitle="SPN · "..require("src.deities").getRarityLabel(item).." · Tiến hóa "..(item.evolutionLevel or 0)
            m.stats={{"BẬC SPN",require("src.deities").getRarityLabel(item)},{"TIẾN HÓA",item.evolutionLevel or 0}}
            local active=false
            for _,owned in pairs(game and game.deities or {}) do if owned==item then active=true end end
            m.equipment={row("TRẠNG THÁI TRANG BỊ",active and "Đang ở ô SPN chiến đấu. Khả năng có hiệu lực khi ô không bị khóa." or "SPN trong kho hoặc đang xem trước. Đưa vào ô trang bị để kích hoạt trong trận.")}
        elseif E.ITEMS[item.id] then
            m.subtitle="TRANG BỊ · T"..E.getTier(item).." · "..(item.slotsNeeded or 1).." hốc"
            m.stats={{"TẦNG TRANG BỊ","T"..E.getTier(item)},{"HỐC CẦN DÙNG",item.slotsNeeded or 1}}
            m.equipment={row("GẮN & THU HỒI","Gắn vào quân bài trong shop. Tháo về balo để giữ lại hoặc dùng làm nguyên liệu ghép."),row("LOẠI TRANG BỊ",item.soulOnly and "Di vật linh hồn" or item.basic and "Nguyên liệu cơ bản" or "Trang bị lớn")}
        else
            m.subtitle=item.packType and "RƯƠNG BÀI" or voucher and "ĐẶC QUYỀN · SUỐT RUN" or "TIÊU HAO · DÙNG MỘT LẦN"
            m.equipment={row("SỬ DỤNG",item.packType and (item.desc or "Mở rương và chọn phần thưởng.") or voucher and "Mua để áp dụng ngay suốt run. Mua lại tăng cấp và cộng dồn hiệu ứng." or "Tiêu hao trong kho cần được đưa vào ô trang bị trước khi dùng. Chuột phải lá đã trang bị để kích hoạt; hủy chọn mục tiêu không mất lá.")}
        end
    end
    return m
end
local function text(UI,value,x,y,w,font,color,align)
    local g=love.graphics;g.setFont(font or UI.fonts.small);g.setColor(color or UI.COLORS.textLight)
    g.printf(tostring(value or ""),x,y,w,align or "left")
end
local function wrappedHeight(font,value,width)
    local _,lines=font:getWrap(tostring(value or ""),width)
    return #lines*(font:getHeight()+3)
end
function I.layout(rows,fonts,x,y,w,h)
    local l={x=x,y=y,w=w,h=h,rows={},height=0}
    for i,r in ipairs(rows) do
        local inset=r.equipment and 67 or 18
        local nameH=r.name and wrappedHeight(fonts.small,r.name,w-inset-23)+4 or 0
        local labelH=r.label~="" and wrappedHeight(fonts.tiny,r.label,w-inset-23)+9 or 0
        local height=16+nameH+labelH+wrappedHeight(fonts.small,r.text,w-inset-23)+16
        if r.equipment then height=math.max(102,height) end
        l.rows[i]={y=l.height,h=height,inset=inset,nameH=nameH,labelH=labelH}
        l.height=l.height+height+12
    end
    l.maxScroll=math.max(0,l.height-12-h)
    return l
end
local function drawColumn(UI,rows,l,scroll)
    local g=love.graphics
    g.push("all")
    local sx,sy=g.transformPoint(l.x,l.y);local ex,ey=g.transformPoint(l.x+l.w,l.y+l.h)
    g.intersectScissor(sx,sy,ex-sx,ey-sy)
    for i,r in ipairs(rows) do
        local bounds=l.rows[i];local y=l.y+bounds.y-scroll
        if y+bounds.h>l.y and y<l.y+l.h then
            local color=r.color or Theme.colors.gold
            if r.kind=="primary" then
                Core.gradient(l.x,y,l.w-10,bounds.h,Theme.colors.raised,Theme.colors.inset,6)
                Core.color(Theme.colors.gold,.55);g.setLineWidth(2);g.line(l.x+1,y+10,l.x+1,y+bounds.h-10)
            elseif r.equipment then
                Style.panel(l.x,y,l.w-10,bounds.h,color,false)
            else
                Core.color(Theme.colors.inset,.7);g.rectangle("fill",l.x,y,l.w-10,bounds.h,5)
                Core.color(Theme.colors.metal,.4);g.setLineWidth(1);g.line(l.x+15,y+bounds.h,l.x+l.w-25,y+bounds.h)
            end
            local tx=l.x+bounds.inset;local ty=y+16;local width=l.w-bounds.inset-23
            if r.equipment then
                local image=UI.getEquipmentImage(r.equipment.id)
                if image then g.setColor(1,1,1);UI.CardFrame.image(image,l.x+14,y+18,38,57) end
                text(UI,r.name,tx,ty,width,UI.fonts.small,color);ty=ty+bounds.nameH
            end
            if r.label~="" then text(UI,r.label,tx,ty,width,UI.fonts.tiny,color);ty=ty+bounds.labelH end
            local font=UI.fonts.small;local old=font:getLineHeight()
            font:setLineHeight((font:getHeight()+3)/font:getHeight())
            text(UI,r.text,tx,ty,width,font,(r.kind=="empty" or r.kind=="lore") and Theme.colors.muted or Theme.colors.text)
            font:setLineHeight(old)
        end
    end
    g.pop()
    if l.maxScroll>0 then
        local thumb=math.max(32,l.h*l.h/l.height)
        Core.color(Theme.colors.metal,.4);g.rectangle("fill",l.x+l.w-4,l.y,3,l.h,2)
        Core.color(Theme.colors.gold,.8);g.rectangle("fill",l.x+l.w-4,l.y+(l.h-thumb)*scroll/l.maxScroll,3,thumb,2)
    end
end
function I.draw(UI,item,game,buttons,mx,my)
    local m=I.model(item,game)
    if I.item~=m.item then I.item=m.item;I.scroll={0,0} end
    I.current=m
    local g=love.graphics;g.push("all");g.setShader();g.setScissor();g.setBlendMode("alpha")
    Core.color(Theme.colors.charcoal);g.rectangle("fill",0,0,1280,720)
    Chrome.panel(10,10,1260,700,Theme.colors.gold)
    Chrome.crest(48,49,22,Theme.colors.gold,m.item.rank and "cards" or "spn")
    Chrome.title(m.name,82,22,994,UI.fonts.bookHeading or UI.fonts.large,Theme.colors.gold)
    Core.textLine(m.subtitle,83,62,987,UI.fonts.small,Theme.colors.muted)
    local close={id="close_inspector",text="ĐÓNG · ESC",x=1106,y=23,w=143,h=43,font=UI.fonts.small,variant="gold"}
    buttons[#buttons+1]=close;Chrome.button(UI,close,mx,my)
    Chrome.rule(30,94,1220)
    UI.CardPhysics.blockBehind()
    Chrome.well(28,108,230,334,Theme.colors.gold)
    Style.compass(143,272,105,Theme.colors.gold,.08,0)
    if m.item.rank then UI.drawCard(m.item,38,118,210,315,false,false)
    else UI.Polish.renderItem(UI,m.item,38,118,210,315) end
    for i,stat in ipairs(m.stats) do
        local x=28+(i-1)%2*118;local y=456+math.floor((i-1)/2)*65
        local color=i==1 and Theme.colors.cyan or i==2 and Theme.colors.text or Theme.colors.gold
        Chrome.well(x,y,112,57,color)
        text(UI,stat[1],x+11,y+9,90,UI.fonts.tiny,Theme.colors.muted)
        local valueFont=UI.fonts.regular:getWidth(tostring(stat[2]))>90 and UI.fonts.tiny or UI.fonts.regular
        text(UI,stat[2],x+11,y+29,90,valueFont,color)
    end
    if m.role then
        Chrome.rule(38,597,210)
        text(UI,m.role.name,38,610,210,UI.fonts.small,Theme.colors.gold)
        text(UI,m.role.desc,38,637,210,UI.fonts.tiny,Theme.colors.muted)
    end
    Chrome.panel(274,108,570,575)
    Chrome.panel(858,108,394,575)
    Chrome.title("KHẢ NĂNG & HIỆU ỨNG",292,123,530,UI.fonts.bookChapter or UI.fonts.medium,Theme.colors.gold)
    Chrome.title(m.item.rank and ("TRANG BỊ · "..E.getUsedSlots(m.item).." / "..E.getMaxSlots(m.item).." HỐC") or "HỒ SƠ VẬT PHẨM",876,123,360,UI.fonts.bookChapter or UI.fonts.medium,Theme.colors.gold)
    Chrome.rule(292,155,532);Chrome.rule(876,155,357)
    I.columns={I.layout(m.rows,UI.fonts,290,168,538,499),I.layout(m.equipment,UI.fonts,874,168,362,499)}
    for i,l in ipairs(I.columns) do
        I.scroll[i]=math.min(I.scroll[i],l.maxScroll)
        drawColumn(UI,i==1 and m.rows or m.equipment,l,I.scroll[i])
    end
    text(UI,"Cuộn trên cột cần xem · PgUp / PgDn · Home / End",290,686,540,UI.fonts.tiny,Theme.colors.muted)
    text(UI,"Chuột phải hoặc Esc để đóng",875,686,360,UI.fonts.tiny,Theme.colors.muted,"right")
    UI.descriptionCandidate=nil
    g.pop()
end
function I.wheel(delta,mx,my)
    local column=1
    for i,l in ipairs(I.columns) do if mx>=l.x and mx<=l.x+l.w and my>=l.y and my<=l.y+l.h then column=i;break end end
    local l=I.columns[column]
    if l then I.scroll[column]=math.max(0,math.min(l.maxScroll,I.scroll[column]-delta*52)) end
    return true
end
function I.key(key,mx,my)
    local column=mx and mx>=866 and 2 or 1
    local l=I.columns[column]
    if not l then return false end
    if key=="home" then I.scroll[column]=0
    elseif key=="end" then I.scroll[column]=l.maxScroll
    elseif key=="pageup" then I.scroll[column]=math.max(0,I.scroll[column]-l.h*.8)
    elseif key=="pagedown" then I.scroll[column]=math.min(l.maxScroll,I.scroll[column]+l.h*.8)
    else return false end
    return true
end
return I

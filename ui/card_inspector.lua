local I={scroll={0,0},columns={}}
local E=require("src.equipment")
local D=require("src.card_description")
local A=require("src.card_abilities")
local Deck=require("src.deck")
local Style=require("ui.backpack_style")
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
    local pendingEdition
    for line in (body.."\n"):gmatch("([^\n]+)\n") do
        if line:match("^SPN · ") then
            -- Rarity and evolution already have dedicated header/stat fields.
        elseif line:match("^ITM · %d+%.") or line:match("^HỐC TRANG BỊ") then
            -- The socket column shows each item's complete effect instead.
        elseif line:match("^ẤN BẢN · ") then
            pendingEdition=row(line,"",{.75,.61,1,1});m.rows[#m.rows+1]=pendingEdition
        elseif pendingEdition then pendingEdition.text=line;pendingEdition=nil
        else
            local label,color="",nil
            if #m.rows==0 then label=def and "KHẢ NĂNG HIỆN TẠI" or "TÁC DỤNG";line=line:gsub("^ITM · ","")
            elseif line:match("^KẾ TIẾP:") then label="CẤP KẾ TIẾP";line=line:gsub("^KẾ TIẾP: *","");color={.48,.83,1,1}
            elseif line:match("^TIẾN HÓA") then label="TIẾN HÓA"
            elseif line:match("^Vai trò") then label="VAI TRÒ TRONG THẾ ĐÁNH"
            elseif line:match("^ẤN ·") or line:match("^RÈN ·") or line:match("^PHÁ LUẬT") then label="NÂNG CẤP & ẤN CHÚ"
            elseif line:find("KHÓA",1,true) or line:find("VÔ HIỆU",1,true) or line:find("QUÊN LÃNG",1,true) then label="TRẠNG THÁI HIỆN TẠI";color={1,.52,.45,1}
            elseif line:match("^THUỐC") then label="HIỆU ỨNG TẠM THỜI";color={.48,.89,.64,1}
            elseif line:match("^Kích hoạt") or line:match("^Toàn tay:") then label="QUY TẮC KÍCH HOẠT" end
            m.rows[#m.rows+1]=row(label,line,color)
        end
    end
    if item.lore and item.lore~="" and not body:find(item.lore,1,true) then m.rows[#m.rows+1]=row("CÂU CHUYỆN",item.lore) end
    if item.rank then
        m.role=item.role and Deck.CARD_ROLES[item.role] or Deck.getCardRole(item.rank)
        m.stats={{"SÁT THƯƠNG",item.baseChips or Deck.getChipValue(item.rank)},
            {"TỐC ĐÁNH",Deck.peekCardAttackSpeed(item,game)},
            {"TIẾN HÓA",(item.evolutionLevel or 0).." / "..A.config.maxEvolutionLevel},
            {"HỐC KHẢM",E.getUsedSlots(item).." / "..E.getMaxSlots(item)}}
        local entries=E.getSocketEntries(item)
        local positions={"Trái trên","Phải trên","Phải dưới","Trái dưới","Cạnh trên","Cạnh phải","Cạnh dưới","Cạnh trái"}
        for slot=1,E.getMaxSlots(item) do
            local entry=entries[slot];local eq=entry and entry.equipment
            local r=row(string.format("Ô %02d · ",slot)..positions[slot],eq and (entry.linked and ("Hốc liên kết · Trang bị này chiếm "..(eq.slotsNeeded or 1).." hốc, kích hoạt một lần.") or E.getDescription(eq)) or "Chưa gắn trang bị.",eq and E.getTierColor(eq))
            if eq then r.label=r.label.." · T"..E.getTier(eq).." · "..(eq.slotsNeeded or 1).." hốc" end
            r.equipment=eq;r.name=eq and eq.name;r.linked=entry and entry.linked
            m.equipment[#m.equipment+1]=r
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
        local inset=r.equipment and 64 or 14
        local nameH=r.name and wrappedHeight(fonts.small,r.name,w-inset-23) or 0
        local labelH=r.label~="" and wrappedHeight(fonts.tiny,r.label,w-inset-23)+6 or 0
        local height=14+nameH+labelH+wrappedHeight(fonts.small,r.text,w-inset-23)+14
        if r.equipment then height=math.max(100,height) end
        l.rows[i]={y=l.height,h=height,inset=inset,nameH=nameH,labelH=labelH}
        l.height=l.height+height+9
    end
    l.maxScroll=math.max(0,l.height-9-h)
    return l
end
local function drawColumn(UI,rows,l,scroll,accent)
    local g=love.graphics
    g.push("all")
    local sx,sy=g.transformPoint(l.x,l.y);local ex,ey=g.transformPoint(l.x+l.w,l.y+l.h)
    g.intersectScissor(sx,sy,ex-sx,ey-sy)
    for i,r in ipairs(rows) do
        local bounds=l.rows[i];local y=l.y+bounds.y-scroll
        if y+bounds.h>l.y and y<l.y+l.h then
            local color=r.color or accent
            Style.panel(l.x,y,l.w-9,bounds.h,color,false)
            local tx=l.x+bounds.inset;local ty=y+12;local width=l.w-bounds.inset-23
            if r.equipment then
                local image=UI.getEquipmentImage(r.equipment.id)
                if image then g.setColor(1,1,1);UI.CardFrame.image(image,l.x+12,y+15,40,60) end
                text(UI,r.name,tx,ty,width,UI.fonts.small,color);ty=ty+bounds.nameH
            end
            if r.label~="" then text(UI,r.label,tx,ty,width,UI.fonts.tiny,r.color or UI.COLORS.goldYellow);ty=ty+bounds.labelH end
            local font=UI.fonts.small;local old=font:getLineHeight()
            font:setLineHeight((font:getHeight()+3)/font:getHeight())
            text(UI,r.text,tx,ty,width,font);font:setLineHeight(old)
        end
    end
    g.pop()
    if l.maxScroll>0 then
        local thumb=math.max(32,l.h*l.h/l.height)
        g.setColor(.22,.28,.29,1);g.rectangle("fill",l.x+l.w-4,l.y,3,l.h,2)
        g.setColor(accent);g.rectangle("fill",l.x+l.w-4,l.y+(l.h-thumb)*scroll/l.maxScroll,3,thumb,2)
    end
end
function I.draw(UI,item,game,buttons,mx,my)
    local m=I.model(item,game)
    if I.item~=m.item then I.item=m.item;I.scroll={0,0} end
    I.current=m
    local g=love.graphics;g.push("all");g.setShader();g.setScissor();g.setBlendMode("alpha")
    g.setColor(.025,.042,.053,1);g.rectangle("fill",0,0,1280,720)
    Style.glow(141,298,235,m.accent,.11);Style.compass(143,293,193,m.accent,.12,UI.Polish.time)
    Style.panel(8,8,1264,704,m.accent)
    text(UI,m.name,28,23,1010,UI.fonts.large,UI.COLORS.goldYellow)
    text(UI,m.subtitle,29,60,1058,UI.fonts.small,UI.COLORS.textMuted)
    local close={id="close_inspector",text="ĐÓNG · ESC",x=1106,y=23,w=143,h=43,font=UI.fonts.small,color=UI.COLORS.btnDiscard}
    buttons[#buttons+1]=close;UI.drawButton(close,mx>=close.x and mx<=close.x+close.w and my>=close.y and my<=close.y+close.h)
    g.setColor(.72,.56,.31,.3);g.line(28,92,1251,92)
    UI.CardPhysics.suspend()
    if m.item.rank then UI.drawCard(m.item,35,115,210,315,false,false)
    else UI.Polish.renderItem(UI,m.item,35,115,210,315) end
    UI.CardPhysics.resume()
    for i,stat in ipairs(m.stats) do
        local x=28+(i-1)%2*116;local y=447+math.floor((i-1)/2)*63
        Style.panel(x,y,108,55,m.accent)
        text(UI,stat[1],x+9,y+8,90,UI.fonts.tiny,UI.COLORS.textMuted)
        local valueFont=UI.fonts.regular:getWidth(tostring(stat[2]))>90 and UI.fonts.tiny or UI.fonts.regular
        text(UI,stat[2],x+9,y+26,90,valueFont,m.accent)
    end
    if m.role then
        text(UI,m.role.name.." · "..(m.item.suitName or m.item.suitSymbol or "Vô chất"),28,585,225,UI.fonts.small,m.accent)
        text(UI,m.role.desc,28,617,225,UI.fonts.tiny,UI.COLORS.textMuted)
    end
    text(UI,"KHẢ NĂNG & HIỆU ỨNG",282,110,555,UI.fonts.medium,UI.COLORS.goldYellow)
    text(UI,m.item.rank and ("TRANG BỊ · "..E.getUsedSlots(m.item).." / "..E.getMaxSlots(m.item).." HỐC") or "HỒ SƠ VẬT PHẨM",866,110,383,UI.fonts.medium,UI.COLORS.goldYellow)
    I.columns={I.layout(m.rows,UI.fonts,282,149,556,529),I.layout(m.equipment,UI.fonts,866,149,383,529)}
    for i,l in ipairs(I.columns) do
        I.scroll[i]=math.min(I.scroll[i],l.maxScroll)
        drawColumn(UI,i==1 and m.rows or m.equipment,l,I.scroll[i],m.accent)
    end
    text(UI,"Lăn chuột trên từng cột để xem toàn bộ · Page Up / Down · Home / End · Chuột phải hoặc Esc để đóng",282,695,967,UI.fonts.tiny,UI.COLORS.textMuted)
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

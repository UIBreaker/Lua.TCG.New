local Theme = require("ui.theme")
local Core = require("ui.components.core")
local View = {}
local function equipmentText(eq)
    return require("src.equipment").getDescription(eq):gsub("^Chiếm %d+ hốc[%.:]%s*","")
        :gsub("; nếu không:","\nNếu không:")
end
local prefixes = {
    {"KẾ TIẾP: ", "Cấp kế tiếp", "next"}, {"Cơ bản: ", "", "stats"},
    {"Vai trò ", "THƯỞNG QUÂN BÀI", "role"}, {"ITM · ", "", "equipment"},
    {"ẤN · ", "Dấu ấn", "modifier"}, {"RÈN · ", "Cường hóa", "modifier"},
    {"ẤN BẢN · ", "Ấn bản", "edition"},
}
local function classify(line, def)
    for _,p in ipairs(prefixes) do
        if line:sub(1,#p[1])==p[1] then
            local text=line:sub(#p[1]+1)
            if p[3]=="role" then text=text:match("^[^:]+: (.*)$") or text end
            return {label=p[2],text=text,kind=p[3]}
        end
    end
    if line:find("KHÓA",1,true) or line:find("VÔ HIỆU",1,true) or line:find("QUÊN LÃNG",1,true) then
        return {text=line,kind="warning"}
    end
    if line:match("^Kích hoạt trước") or line:match("^Toàn tay:")
        or line:match("^Cơ: hồi Máu dư") or line:match("^Vàng hoặc Tốc vượt") then
        return {text=line,kind="rules"}
    end
    local detail=def and line==def.ambition or line:match("^Ghép tầng")
        or line:match("^Nguyên liệu cho") or line:match("^Và %d+ công thức")
        or line:match("^Gắn/tháo miễn phí")
    return {text=line,kind=detail and "detail" or "state"}
end
function View.model(item,title,body,expanded)
    while item.card or item.deity or item.equipment or item.item do
        item=item.card or item.deity or item.equipment or item.item
    end
    local def=require("src.card_abilities").definition(item)
    local m={title=title,badge="TIÊU HAO",accent=Theme.colors.purple,rows={},expanded=expanded}
    if def then
        m.title=def.name;m.badge=(item.rankName or tostring(item.rank))..(item.suitSymbol or "").." · QUÂN BÀI";m.accent=Theme.colors.gold
        m.subtitle=def.characterName
        m.stats={damage=item.baseChips or require("src.deck").getChipValue(item.rank),speed=require("src.deck").getCardAttackSpeed(item)}
    elseif body:match("^SPN · ") or item.deityId then m.badge="SPN";m.accent=Theme.colors.cyan
    elseif body:match("^ITM · ") then m.badge="TRANG BỊ";m.accent=Theme.colors.green
    elseif item.packType then m.badge="RƯƠNG BÀI";m.accent=Theme.colors.gold
    elseif item.voucherId or tostring(item.id):match("^v_") then m.badge="ĐẶC QUYỀN";m.accent=Theme.colors.green end
    local primary,warnings,additions,details={},{},{},{}
    local previous
    for line in (body.."\n"):gmatch("([^\n]+)\n") do
        if line:match("^SPN · ") then m.badge=line
        elseif line:match("^TIẾN HÓA ") then
            m.level,m.maxLevel=line:match("^TIẾN HÓA (%d+) / (%d+)");m.temporary=line:match("TẠM %+(%d+)")
        elseif #primary==0 then
            local eq=require("src.equipment").ITEMS[item.id]
            if eq then
                m.accent=require("src.equipment").getTierColor(eq)
                primary[1]={kind="equipment",equipment=item,standalone=true,label="TẦNG "..require("src.equipment").getTier(item).." · "..(item.slotsNeeded or 1).." HỐC",text=equipmentText(item)}
            else primary[1]={text=line:gsub("^ITM · ",""),kind="effect",label=def and "KHẢ NĂNG HIỆN TẠI" or nil} end
        else
            local row=classify(line,def)
            if previous and previous.kind=="edition" and row.kind=="state" then previous.text=previous.text..": "..row.text
            elseif row.kind=="warning" then warnings[#warnings+1]=row
            elseif row.kind=="next" or row.kind=="detail" then details[#details+1]=row
            elseif row.kind=="stats" and m.stats then
            elseif row.kind=="rules" then -- Global rules are omitted from card tooltips.
            elseif row.kind=="equipment" then -- Structured equipment rows below retain slot and tier.
            elseif row.text:match("^HỐC TRANG BỊ") then
            elseif row.kind=="modifier" or row.kind=="edition" then additions[#additions+1]=row
            elseif row.text~="" then primary[#primary+1]=row end
            previous=row
        end
    end
    m.hasDetails=#details>0
    local function append(rows) for _,row in ipairs(rows) do m.rows[#m.rows+1]=row end end
    append(warnings);append(primary)
    local lines={}
    for _,row in ipairs(additions) do
        if row.text~="" then lines[#lines+1]="• "..(row.label~="" and row.label..": " or "")..row.text end
    end
    if def then
        local E=require("src.equipment")
        m.rows[#m.rows+1]={text="TRANG BỊ KHẢM · "..#(item.equipments or {}).." món · "..E.getUsedSlots(item).." / "..E.getMaxSlots(item).." hốc",kind="sockets"}
        for slot,entry in ipairs(E.getSocketEntries(item)) do
            if not entry.linked then
                local eq=entry.equipment
                m.rows[#m.rows+1]={kind="equipment",equipment=eq,slot=slot,
                    label="Ô "..slot..((eq.slotsNeeded or 1)>1 and ("–"..(slot+eq.slotsNeeded-1)) or "").." · TẦNG "..E.getTier(eq),
                    text=equipmentText(eq)}
            end
        end
    end
    if #lines>0 then m.rows[#m.rows+1]={label="BỔ SUNG",text=table.concat(lines,"\n"),kind="additions"} end
    if expanded then append(details) end
    return m
end
local function height(font,text,width,gap)
    local _,lines=font:getWrap(text,width)
    return #lines*(font:getHeight()+(gap or 2))
end
function View.layout(m,fonts)
    local l={w=m.stats and 400 or 360,font=fonts.description or fonts.small,referenceFont=fonts.descriptionNote or fonts.tiny,titleFont=fonts.medium or fonts.regular or fonts.small,nameFont=fonts.small,valueFont=fonts.regular or fonts.small,labelFont=fonts.tiny,rows={},scale=1}
    local columnW=l.w
    l.headerH=42+height(l.titleFont,m.title,l.w-36,1)
    l.subtitleY=l.headerH-6
    if m.subtitle then l.headerH=l.headerH+height(l.labelFont,m.subtitle,l.w-36)+5 end
    l.statsY=l.headerH
    if m.stats then l.headerH=l.headerH+38 end
    local y=0
    for i,row in ipairs(m.rows) do
        local labelH=row.label and row.label~="" and 16 or 0
        local nameH=row.kind=="equipment" and not row.standalone and height(l.nameFont,row.equipment.name,l.w-88,1) or 0
        local rowFont=row.kind=="rules" and l.referenceFont or (row.kind=="stats" or row.kind=="sockets") and l.labelFont or l.font
        local h=row.kind=="equipment" and math.max(78,26+nameH+height(l.font,row.text,l.w-88)+10) or labelH+height(rowFont,row.text,l.w-40)+16
        l.rows[i]={x=0,y=y,w=columnW,h=h,textY=labelH+8,nameH=nameH};y=y+h+5
    end
    l.contentH=math.max(0,y-5);l.footerH=m.hasDetails and 26 or 12
    if not m.expanded and l.headerH+l.contentH+l.footerH+8>600 then
        -- Keep complete rows readable; widen the same panel before resorting to scaling.
        local capacity=600-l.headerH-l.footerH-8
        local col,cy,tallest=0,0,0
        for _,r in ipairs(l.rows) do
            if cy>0 and cy+r.h>capacity then col=col+1;cy=0 end
            r.x=col*(columnW+12);r.y=cy
            cy=cy+r.h+5;tallest=math.max(tallest,cy-5)
        end
        if col>2 then
            -- Exceptional content still fits without discarding any information.
            local target=math.max(capacity,math.ceil((y-5)/3))
            col,cy,tallest=0,0,0
            for _,r in ipairs(l.rows) do
                if col<2 and cy>0 and cy+r.h>target then col=col+1;cy=0 end
                r.x=col*(columnW+12);r.y=cy
                cy=cy+r.h+5;tallest=math.max(tallest,cy-5)
            end
        end
        l.w=(col+1)*columnW+col*12;l.contentH=tallest
    end
    local fullH=l.headerH+l.contentH+l.footerH+8
    l.h=m.expanded and math.min(600,fullH) or fullH
    if not m.expanded then l.scale=math.min(1,600/l.h) end
    l.viewportH=l.h-l.headerH-l.footerH-8;l.maxScroll=math.max(0,l.contentH-l.viewportH)
    if l.maxScroll>0 then l.footerH=32;l.viewportH=l.h-l.headerH-l.footerH-8;l.maxScroll=math.max(0,l.contentH-l.viewportH) end
    return l
end
local function rich(text,color)
    local runs,pos={},1
    while true do
        local first,last=text:find("[+%-]?%d+%.?%d*",pos)
        if not first then runs[#runs+1]=Theme.colors.text;runs[#runs+1]=text:sub(pos);break end
        runs[#runs+1]=Theme.colors.text;runs[#runs+1]=text:sub(pos,first-1)
        runs[#runs+1]=color;runs[#runs+1]=text:sub(first,last);pos=last+1
    end
    return runs
end
function View.draw(m,l,x,y,scroll)
    local g=love.graphics
    local w,h,accent=l.w,l.h,m.accent
    scroll=math.max(0,math.min(l.maxScroll,scroll or 0))
    g.push("all");g.translate(x,y);g.scale(l.scale)
    g.setColor(0,0,0,0.28);g.rectangle("fill",3,5,w,h,7,7)
    g.setColor(0.035,0.053,0.067,0.99);g.rectangle("fill",0,0,w,h,7,7)
    Core.color(accent,0.035);g.rectangle("fill",1,1,w-2,l.headerH-1,7,7)
    g.setLineWidth(1);Core.color(accent,0.45);g.rectangle("line",0.5,0.5,w-1,h-1,7,7)
    local level=tonumber(m.level) or 0
    local levelText=(m.level and "Cấp "..level.." / "..(m.maxLevel or level) or "")..(m.temporary and " +"..m.temporary.." tạm" or "")
    local levelW=levelText~="" and l.labelFont:getWidth(levelText)+16 or 0
    Core.text(m.badge,18,13,w-36-levelW,l.labelFont,accent)
    if levelW>0 then
        Core.color(accent,0.13);g.rectangle("fill",w-18-levelW,9,levelW,21,4,4)
        Core.text(levelText,w-18-levelW,13,levelW,l.labelFont,accent,"center")
    end
    Core.text(m.title,18,29,w-36,l.titleFont,Theme.colors.text)
    if m.subtitle then Core.text(m.subtitle,18,l.subtitleY,w-36,l.labelFont,Theme.colors.muted) end
    if m.stats then
        local tileW=(math.min(w,400)-44)/2
        Core.color(Theme.colors.metal,0.35);g.line(18,l.statsY-3,w-18,l.statsY-3)
        for i,stat in ipairs({{"SÁT THƯƠNG GỐC",m.stats.damage,Theme.colors.gold},{"TỐC ĐÁNH CỦA LÁ",m.stats.speed,Theme.colors.cyan}}) do
            local tx=18+(i-1)*(tileW+8)
            Core.text(stat[1],tx,l.statsY+8,tileW-36,l.labelFont,Theme.colors.muted)
            Core.text(tostring(stat[2]),tx,l.statsY+5,tileW,l.valueFont,stat[3],"right")
        end
    end
    Core.color(Theme.colors.metal,0.5);g.line(18,l.headerH-4,w-18,l.headerH-4)
    g.push("all")
    local sx,sy=g.transformPoint(12,l.headerH)
    local ex,ey=g.transformPoint(w-12,l.headerH+l.viewportH)
    g.intersectScissor(sx,sy,ex-sx,ey-sy)
    for i,row in ipairs(m.rows) do
        local r=l.rows[i];local ry=l.headerH+r.y-scroll
        if ry+r.h>l.headerH and ry<l.headerH+l.viewportH then
            g.push("all");g.translate(r.x,0)
            local w=r.w
            local color=row.kind=="warning" and Theme.colors.red or row.kind=="next" and Theme.colors.cyan or row.kind=="additions" and Theme.colors.green or accent
            if row.kind=="equipment" then
                local E=require("src.equipment")
                local eq=row.equipment;local tint=E.getTierColor(eq)
                Core.color(tint,0.035);g.rectangle("fill",12,ry,w-24,r.h,5,5)
                local Frame=require("ui.components.card_frame")
                Core.color(tint,0.20);g.line(18,ry,w-18,ry)
                local UI=require("src.ui");local image=UI.getEquipmentImage(eq.id)
                if image then g.setColor(1,1,1,1);Frame.image(image,20,ry+10,36,54) end
                if not row.standalone then Core.text(eq.name,68,ry+8,w-88,l.nameFont,Theme.colors.text) end
                Core.text(row.label,68,ry+9+r.nameH,w-88,l.labelFont,tint)
                g.setFont(l.font);g.setColor(1,1,1,1)
                local old=l.font:getLineHeight();l.font:setLineHeight((l.font:getHeight()+2)/l.font:getHeight())
                g.printf(rich(row.text,tint),68,ry+26+r.nameH,w-88,"left");l.font:setLineHeight(old)
            else
                if row.kind=="warning" or row.kind=="effect" then
                    Core.color(color,row.kind=="effect" and 0.07 or 0.1);g.rectangle("fill",12,ry,w-24,r.h,4,4)
                    Core.color(color,0.7);g.rectangle("fill",12,ry+8,2,r.h-16,1,1)
                elseif row.kind=="additions" or row.kind=="sockets" then Core.color(Theme.colors.metal,0.35);g.line(18,ry,w-18,ry) end
                if row.label and row.label~="" then Core.text(row.label,20,ry+6,w-40,l.labelFont,Theme.colors.muted) end
                local font=row.kind=="rules" and l.referenceFont or (row.kind=="stats" or row.kind=="sockets") and l.labelFont or l.font
                g.setFont(font);g.setColor(1,1,1,1)
                local old=font:getLineHeight();font:setLineHeight((font:getHeight()+2)/font:getHeight())
                g.printf(rich(row.text,color),20,ry+r.textY,w-40,"left");font:setLineHeight(old)
            end
            g.pop()
        end
    end
    g.pop()
    if m.expanded and l.maxScroll>0 and scroll<l.maxScroll then
        for n=1,12 do
            g.setColor(0.035,0.053,0.067,n/12)
            g.rectangle("fill",12,l.headerH+l.viewportH-12+n-1,w-24,1)
        end
    end
    if m.expanded and l.maxScroll>0 then
        local track=l.viewportH;local thumb=math.max(24,track*track/l.contentH)
        Core.color(Theme.colors.metal,0.3);g.rectangle("fill",w-8,l.headerH,2,track,1,1)
        Core.color(accent,0.6);g.rectangle("fill",w-8,l.headerH+(track-thumb)*scroll/l.maxScroll,2,thumb,1,1)
    end
    local footerY=h-l.footerH+8
    local hint=m.expanded and l.maxScroll>0 and "Giữ Shift · Cuộn để xem thêm"
        or m.hasDetails and (m.expanded and "Thả Shift để thu gọn" or "Shift · Chi tiết")
    if hint then Core.text(hint,18,footerY,w-36,l.labelFont,Theme.colors.muted,"right") end
    g.pop()
end
return View

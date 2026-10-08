local Theme = require("ui.theme")
local Core = require("ui.components.core")
local View = {}
local prefixes = {
    {"KẾ TIẾP: ", "Cấp kế tiếp", "next"}, {"Cơ bản: ", "Chỉ số", "stats"},
    {"Vai trò ", "", "role"}, {"ITM · ", "", "equipment"},
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
    local detail=def and line==def.ambition or line:match("^Kích hoạt trước")
        or line:match("^Toàn tay:") or line:match("^Cơ: hồi Máu dư")
        or line:match("^Vàng hoặc Tốc vượt") or line:match("^Ghép tầng")
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
        elseif #primary==0 then primary[1]={text=line:gsub("^ITM · ",""),kind="effect"}
        else
            local row=classify(line,def)
            if previous and previous.kind=="edition" and row.kind=="state" then previous.text=previous.text..": "..row.text
            elseif row.kind=="warning" then warnings[#warnings+1]=row
            elseif row.kind=="next" or row.kind=="stats" or row.kind=="role" or row.kind=="detail" then details[#details+1]=row
            elseif row.kind=="equipment" or row.kind=="modifier" or row.kind=="edition" then additions[#additions+1]=row
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
    if #lines>0 then m.rows[#m.rows+1]={label="BỔ SUNG",text=table.concat(lines,"\n"),kind="additions"} end
    if expanded then append(details) end
    return m
end
local function height(font,text,width,gap)
    local _,lines=font:getWrap(text,width)
    return #lines*(font:getHeight()+(gap or 2))
end
function View.layout(m,fonts)
    local l={w=340,font=fonts.description or fonts.small,titleFont=fonts.regular or fonts.small,labelFont=fonts.tiny,rows={},scale=1}
    l.headerH=42+height(l.titleFont,m.title,l.w-36,1)
    local y=0
    for i,row in ipairs(m.rows) do
        local labelH=row.label and row.label~="" and 20 or 0
        local h=labelH+height(l.font,row.text,l.w-40)+16
        l.rows[i]={y=y,h=h,textY=labelH+8};y=y+h+4
    end
    l.contentH=math.max(0,y-4);l.footerH=(m.hasDetails or tonumber(m.level or 0)>0 or m.temporary) and 32 or 12
    l.h=math.min(m.expanded and 600 or 440,l.headerH+l.contentH+l.footerH+8)
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
    g.push("all");g.translate(x,y)
    g.setColor(0,0,0,0.28);g.rectangle("fill",3,5,w,h,7,7)
    g.setColor(0.035,0.053,0.067,0.99);g.rectangle("fill",0,0,w,h,7,7)
    g.setLineWidth(1);Core.color(accent,0.45);g.rectangle("line",0.5,0.5,w-1,h-1,7,7)
    Core.text(m.badge,18,13,w-36,l.labelFont,accent)
    Core.text(m.title,18,33,w-36,l.titleFont,Theme.colors.text)
    Core.color(Theme.colors.metal,0.5);g.line(18,l.headerH-4,w-18,l.headerH-4)
    g.push("all")
    local sx,sy=g.transformPoint(12,l.headerH)
    local ex,ey=g.transformPoint(w-12,l.headerH+l.viewportH)
    g.intersectScissor(sx,sy,ex-sx,ey-sy)
    for i,row in ipairs(m.rows) do
        local r=l.rows[i];local ry=l.headerH+r.y-scroll
        if ry+r.h>l.headerH and ry<l.headerH+l.viewportH then
            local color=row.kind=="warning" and Theme.colors.red or row.kind=="next" and Theme.colors.cyan or row.kind=="additions" and Theme.colors.green or accent
            if row.kind=="warning" then Core.color(color,0.1);g.rectangle("fill",12,ry,w-24,r.h,4,4)
            elseif row.kind=="additions" then Core.color(Theme.colors.metal,0.35);g.line(18,ry,w-18,ry) end
            if row.label and row.label~="" then Core.text(row.label,20,ry+6,w-40,l.labelFont,Theme.colors.muted) end
            g.setFont(l.font);g.setColor(1,1,1,1)
            local old=l.font:getLineHeight();l.font:setLineHeight((l.font:getHeight()+2)/l.font:getHeight())
            g.printf(rich(row.text,color),20,ry+r.textY,w-40,"left");l.font:setLineHeight(old)
        end
    end
    g.pop()
    if l.maxScroll>0 then
        local track=l.viewportH;local thumb=math.max(24,track*track/l.contentH)
        Core.color(Theme.colors.metal,0.3);g.rectangle("fill",w-8,l.headerH,2,track,1,1)
        Core.color(accent,0.6);g.rectangle("fill",w-8,l.headerH+(track-thumb)*scroll/l.maxScroll,2,thumb,1,1)
    end
    local footerY=h-l.footerH+8
    local level=tonumber(m.level) or 0
    if level>0 or m.temporary then Core.text("Cấp "..level..(m.temporary and " · +"..m.temporary.." tạm" or ""),18,footerY,120,l.labelFont,accent) end
    local hint=l.maxScroll>0 and (m.hasDetails and not m.expanded and "Shift · Chi tiết / Cuộn" or "Cuộn để xem thêm")
        or m.hasDetails and (m.expanded and "Thả Shift để thu gọn" or "Shift · Chi tiết")
    if hint then Core.text(hint,18,footerY,w-36,l.labelFont,Theme.colors.muted,"right") end
    g.pop()
end
return View

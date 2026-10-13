local UI=require("src.ui")
local Theme=require("ui.theme")
local T=require("src.barter")
local D=require("src.deities")
local E=require("src.equipment")
local C=Theme.colors
local V={}
local function text(s,x,y,w,font,color,align)
    love.graphics.setFont(font or UI.fonts.tiny);love.graphics.setColor(color or C.text)
    love.graphics.printf(s,x,y,w,align or "left")
end
local function panel(x,y,w,h,accent)
    love.graphics.setColor(.016,.023,.032,.91);UI.drawRoundedRect("fill",x,y,w,h,8)
    local c=accent or C.gold;love.graphics.setColor(c[1],c[2],c[3],.55);love.graphics.setLineWidth(1)
    UI.drawRoundedRect("line",x+1,y+1,w-2,h-2,7)
end
local function button(buttons,id,label,x,y,w,h,disabled,color)
    local b={id=id,text=label,x=x,y=y,w=w,h=h,disabled=disabled,color=color or C.inset,font=UI.fonts.small}
    UI.drawButton(b,false);buttons[#buttons+1]=b
end
local function card(kind,item,x,y,w,h)
    if kind=="spn" then UI.drawPatronCard(item,x,y,w,h,false,false,false)
    else
        local image=UI.getEquipmentImage(item.id)
        if image then love.graphics.setColor(1,1,1);UI.CardFrame.image(image,x,y,w,h) end
        UI.drawCardBorder(x,y,w,h,nil,nil,item)
        require("ui.backpack").stats(UI,item,x,y,w,h)
    end
end
local function summary(kind,item)
    if kind=="spn" then return D.getRarityLabel(item).." · Tiến hóa "..(item.evolutionLevel or 0)..(item.edition and " · "..item.edition or "") end
    return (item.basic and "Trang bị cơ bản" or "Trang bị · T"..(item.craftTier or 1))..(item.bloodPower==5 and " · Huyết Luyện ×5" or "")
end
local function side(kind,item,x,title,note,accent)
    panel(x,160,400,308,accent)
    text(title,x+18,176,364,UI.fonts.small,accent)
    love.graphics.setColor(accent[1],accent[2],accent[3],.25);love.graphics.line(x+18,205,x+382,205)
    if item then
        card(kind,item,x+19,222,98,147)
        text(item.name,x+133,221,250,UI.fonts.small,C.gold)
        text(summary(kind,item),x+133,250,250,nil,C.muted)
        local sx,sy=love.graphics.transformPoint(x+133,282)
        local ex,ey=love.graphics.transformPoint(x+383,420)
        love.graphics.setScissor(sx,sy,ex-sx,ey-sy)
        text(T.describe(kind,item),x+133,282,250,nil,C.text)
        love.graphics.setScissor()
    end
    text(note,x+19,427,362,nil,C.muted)
end
function V.draw(game,buttons,mx,my)
    local g=love.graphics;local event=game.barterEvent
    if not event then return end
    g.push("all")
    g.setColor(.005,.011,.02,.16);g.rectangle("fill",0,0,1280,720)
    panel(18,14,1244,64)
    text("GẶP GỠ · NGƯỜI VIỄN CHINH BÍ ẨN",36,24,940,UI.fonts.large,C.gold)
    text("Ải "..event.ante.." · Hai hành trang, một thỏa thuận · Không dùng vàng hoặc máu",38,57,1000,nil,C.muted)
    if not V.npc then V.npc=love.graphics.newImage(T.npcPath);V.npc:setFilter("linear","linear") end
    local iw,ih=V.npc:getDimensions();local scale=490/ih
    g.setColor(.015,.024,.036,.35);g.ellipse("fill",164,587,107,17)
    g.setColor(1,1,1,1);g.draw(V.npc,164-iw*scale/2,108,0,scale,scale)
    panel(23,595,280,96)
    text("BẠN ĐƯỜNG KHÔNG TÊN",38,610,250,UI.fonts.small,C.gold)
    text(event.completed and "\"Đúng thứ tôi cần. Chúc đoàn của bạn bình an trên đường phía trước.\"" or "\"Tôi giữ món không hợp chuyến đi. Bạn có thứ đoàn tôi đang thiếu chứ?\"",38,638,250,nil,C.text)
    local offer=event.offers[event.offerIndex]
    for i,o in ipairs(event.offers) do
        local b={id="barter_offer_"..i,text=o.kind=="spn" and "KHẾ ƯỚC SPN" or "TRAO ĐỔI TRANG BỊ",x=325+(i-1)*221,y=99,w=210,h=42,color=i==event.offerIndex and C.cyan or C.inset,font=UI.fonts.small,disabled=event.completed}
        UI.drawButton(b,false);buttons[#buttons+1]=b
    end
    text("Mỗi cuộc gặp: một lần trao đổi",820,110,412,UI.fonts.small,C.gold,"right")
    if not offer then
        panel(325,160,910,459);text("Hiện chưa có món phù hợp để đề nghị trao đổi.",350,315,860,UI.fonts.medium)
        button(buttons,"barter_leave","TIẾP TỤC HÀNH TRÌNH",829,643,400,48,false,C.cyan)
        g.pop();return
    end
    local selected=T.selected(game)
    local wanted=(offer.kind=="spn" and D.CATALOG or E.ITEMS)[offer.wantedId]
    local given=event.completed and event.receiptGiven or selected and selected.item or wanted
    local received=event.completed and event.receiptReward or T.reward(offer,selected and selected.item)
    side(offer.kind,given,325,event.completed and "NGƯỜI VIỄN CHINH ĐÃ NHẬN" or "BẠN ĐƯA · HỌ ĐANG CẦN",event.completed and "Đã trao đúng món theo thỏa thuận." or selected and selected.where or "Cần đúng món: "..wanted.name,C.gold)
    side(offer.kind,received,829,event.completed and "BẠN ĐÃ NHẬN · TRONG BALO" or "HỌ ĐƯA · BẠN NHẬN",event.completed and "Đã cất an toàn vào balo." or "Giữ bậc, tiến hóa, ấn bản và Huyết Luyện của món đưa.",C.green)
    for _,pair in ipairs({{given,325},{received,829}}) do
        if mx>=pair[2]+18 and mx<=pair[2]+382 and my>=222 and my<=420 then UI.descriptionCandidate=pair[1] end
    end
    g.setColor(C.gold);g.setLineWidth(2);g.circle("line",777,315,26)
    g.line(762,309,789,309,783,303);g.line(791,320,763,320,769,326)
    text(event.completed and event.message or offer.reason,325,478,904,nil,event.completed and C.green or C.text)
    panel(325,508,904,109)
    if event.completed then
        text("THỎA THUẬN HOÀN TẤT",345,532,864,UI.fonts.medium,C.green,"center")
        text("Món nhận đã nằm trong balo. Hai bên giữ nguyên vàng và sinh lực.",345,570,864,nil,C.muted,"center")
    else
        local list=T.owned(game,offer.kind);local pages=math.max(1,math.ceil(#list/6));event.page=math.max(1,math.min(pages,event.page or 1))
        if #list==0 then
            text("Chưa có "..(offer.kind=="spn" and "SPN" or "trang bị").." để trao đổi. Bạn có thể xem đề nghị khác hoặc rời đi.",345,543,864,nil,C.muted,"center")
        end
        for i=(event.page-1)*6+1,math.min(#list,event.page*6) do
            local entry=list[i];local x=337+((i-1)%6)*147;local eligible=entry.item.id==offer.wantedId
            panel(x,520,139,84,event.selectedKey==entry.key and C.green or eligible and C.gold or C.muted)
            g.setColor(1,1,1,eligible and 1 or .4);card(offer.kind,entry.item,x+5,526,43,65)
            text(entry.item.name,x+55,530,77,nil,eligible and C.text or C.muted)
            text(eligible and "ĐÚNG MÓN" or "Khác yêu cầu",x+55,577,77,nil,eligible and C.green or C.muted)
            buttons[#buttons+1]={id="barter_item",key=entry.key,x=x,y=520,w=139,h=84,disabled=not eligible}
        end
        text("HÀNH TRANG · "..#list.." MÓN · "..event.page.." / "..pages,325,624,675,nil,C.muted)
        button(buttons,"barter_prev","‹",1101,620,57,22,event.page<=1)
        button(buttons,"barter_next","›",1172,620,57,22,event.page>=pages)
    end
    button(buttons,"barter_leave",event.completed and "LÊN ĐƯỜNG" or "RỜI ĐI",325,653,199,38,false)
    if event.confirming and not event.completed then button(buttons,"barter_cancel","CHỌN LẠI",541,653,267,38,false) end
    button(buttons,"barter_accept",event.completed and "ĐÃ TRAO ĐỔI" or event.confirming and "XÁC NHẬN ĐỔI 1 ↔ 1" or "ĐỀ NGHỊ TRAO ĐỔI",829,653,400,38,event.completed or not selected,C.cyan)
    if event.confirming then text("Xác nhận sẽ lấy đúng món bạn chọn, kể cả món đang trang bị/khảm. Món mới vào balo.",325,697,904,nil,C.gold) end
    g.pop()
end
function V.press(game,b)
    local event=game.barterEvent
    if not event or b.disabled then return end
    if b.id=="barter_leave" then return "leave" end
    if event.completed then return end
    if b.id:match("^barter_offer_%d+$") then event.offerIndex=tonumber(b.id:match("(%d+)$"));event.selectedKey=nil;event.confirming=nil;event.page=1
    elseif b.id=="barter_item" then event.selectedKey=b.key;event.confirming=nil
    elseif b.id=="barter_prev" then event.page=event.page-1
    elseif b.id=="barter_next" then event.page=event.page+1
    elseif b.id=="barter_cancel" then event.confirming=nil
    elseif b.id=="barter_accept" and T.selected(game) then
        if not event.confirming then event.confirming=true
        else local ok,msg=T.accept(game);event.message=msg;return ok and "accepted" or "changed" end
    end
    return "changed"
end
return V

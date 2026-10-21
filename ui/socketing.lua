local S={pageSize=10,equipmentRect={x=255,y=86,w=56,h=80}}
local E=require("src.equipment")
local Chrome=require("ui.combat_chrome")
local Core=require("ui.components.core")
local Theme=require("ui.theme")
local Style=require("ui.backpack_style")

function S.cardRect(index)
    return 312+(index-1)%5*138,198+math.floor((index-1)/5)*198,104,150
end

function S.draw(UI,equipment,cards,page,message,mx,my,application)
    local g=love.graphics
    local gold,muted=Theme.colors.gold,Theme.colors.muted
    local pages=math.max(1,math.ceil(#cards/S.pageSize))
    page=math.max(1,math.min(page,pages))
    local eligible=0
    for _,card in ipairs(cards) do if E.canAttach(card,equipment) then eligible=eligible+1 end;card.hovered=false end
    g.push("all")
    Chrome.panel(220,16,840,688,gold)
    Chrome.crest(254,46,20,gold,"equipment")
    Chrome.title("KHẢM TRANG BỊ",289,28,537,UI.fonts.bookHeading or UI.fonts.large,gold)
    Core.text("Chọn một quân bài để nhận trang bị",290,60,580,UI.fonts.tiny,muted)
    Core.text(eligible.." / "..#cards.." lá gắn được",842,38,192,UI.fonts.small,eligible>0 and Theme.colors.green or Theme.colors.red,"right")
    Chrome.well(241,80,798,101,gold)
    local image=UI.getEquipmentImage(equipment.id)
    local rect=S.equipmentRect
    if image then
        g.setColor(1,1,1,1)
        require("ui.card_surfaces").image(equipment,rect.x,rect.y,rect.w,rect.h,image)
    else Style.glyph("equipment",rect.x+28,rect.y+40,25,gold) end
    Chrome.title(equipment.name,329,91,536,UI.fonts.bookChapter or UI.fonts.medium,E.getTierColor(equipment))
    Core.text("T"..E.getTier(equipment).." · "..(equipment.slotsNeeded or 1).." HỐC",873,95,146,UI.fonts.tiny,gold,"right")
    local _,lines=UI.fonts.small:getWrap(E.getDescription(equipment),685)
    for i=1,math.min(2,#lines) do
        Core.textLine(lines[i]..(i==2 and #lines>2 and "…" or ""),329,120+(i-1)*18,685,UI.fonts.small,Theme.colors.text)
    end
    if #lines<2 then Core.text("Lá có Phá Luật có thể gắn trùng loại",329,154,685,UI.fonts.tiny,muted) end
    if mx>=241 and mx<=1039 and my>=80 and my<=181 then UI.descriptionCandidate=equipment end
    Chrome.well(241,188,798,404,gold)
    Style.compass(640,390,170,gold,.035,0)
    local first=(page-1)*S.pageSize+1
    for index=first,math.min(#cards,first+S.pageSize-1) do
        local card=cards[index]
        local x,y,w,h=S.cardRect(index-first+1)
        local hover=mx>=x and mx<=x+w and my>=y and my<=y+h
        local can,reason=E.canAttach(card,equipment)
        if application and application.target==card then can=true end
        local used,total=E.getUsedSlots(card),E.getMaxSlots(card)
        local color=can and Theme.colors.green or Theme.colors.red
        card.hovered=hover
        UI.drawCard(card,x,y,w,h)
        if not can then
            g.setColor(.015,.018,.022,.48);g.rectangle("fill",x,y,w,h,6)
        end
        if hover then
            UI.drawCardBorder(x,y,w,h,color,nil,card)
            UI.descriptionCandidate=card
        end
        local pipW=math.min(14,(w-12-(total-1)*4)/total)
        local start=x+(w-(total*pipW+(total-1)*4))/2
        for slot=1,total do
            Core.color(slot<=used and gold or Theme.colors.metal,slot<=used and .95 or .5)
            g.rectangle("fill",start+(slot-1)*(pipW+4),y+h+8,pipW,4,1)
        end
        local status=can and (used.." / "..total.." · Còn "..(total-used))
            or reason and reason:find("cùng loại",1,true) and "ĐÃ CÓ LOẠI NÀY" or "KHÔNG ĐỦ HỐC"
        Core.textLine(status,x-8,y+h+17,w+16,UI.fonts.tiny,color,"center")
    end
    if #cards==0 then Core.text("Bộ bài chưa có quân bài",285,373,710,UI.fonts.medium,muted,"center") end
    Core.text(message or (eligible==0 and "Chưa có lá phù hợp. Có thể bỏ qua trang bị này." or "Nhấp lá gắn được để khảm · Rê chuột xem chi tiết"),250,606,780,UI.fonts.tiny,message and Theme.colors.red or eligible==0 and gold or muted,"center")
    Chrome.rule(250,633,780)
    local buttons={
        {id="socket_prev",text="← TRƯỚC",x=250,y=648,w=150,h=36,disabled=page<=1},
        {id="skip_socket",text="BỎ QUA TRANG BỊ",x=510,y=648,w=260,h=36},
        {id="socket_next",text="SAU →",x=880,y=648,w=150,h=36,disabled=page>=pages},
    }
    Core.text(page.." / "..pages,403,661,100,UI.fonts.tiny,muted,"center")
    Core.text(#cards.." LÁ",775,661,100,UI.fonts.tiny,muted,"center")
    for _,b in ipairs(buttons) do
        b.font=UI.fonts.small;b.variant="gold"
        if application then b.disabled=true end
        Chrome.button(UI,b,mx,my)
    end
    g.pop()
    return buttons,page
end
return S

local H={page=0,basicPage=1,selected=nil}
local Poker=require("src.poker")
local Examples=require("ui.handbook_examples")
local cache={}
local function inside(mx,my,x,y,w,h)
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end
function H.click(id)
    if id=="handbook_basic" then H.page=0;H.basicPage=1;H.selected=nil;return true end
    if id=="handbook_advanced" then H.page=math.max(1,H.page);H.selected=nil;return true end
    if id=="handbook_prev" or id=="handbook_next" then
        local delta=id=="handbook_prev" and -1 or 1
        if H.page==0 then H.basicPage=math.max(1,math.min(2,H.basicPage+delta))
        else H.page=math.max(1,math.min(3,H.page+delta)) end
        H.selected=nil;return true
    end
    local selected=id:match("^handbook_select_(.+)$")
    if selected then H.selected=selected;return true end
end
function H.tabs(UI,buttons,mx,my,x,y)
    for i,entry in ipairs({{"handbook_basic","CƠ BẢN · 9",H.page==0},{"handbook_advanced","NÂNG CAO · 18",H.page>0}}) do
        local b={id=entry[1],text=entry[2],x=x+(i-1)*252,y=y,w=240,h=38,font=UI.fonts.regular,color=entry[3] and UI.COLORS.goldYellow or UI.COLORS.btnSort}
        buttons[#buttons+1]=b;UI.drawButton(b,inside(mx,my,b.x,b.y,b.w,b.h))
    end
end
local symbols={hearts="♥",diamonds="♦",clubs="♣",spades="♠"}
local ranks={[14]="A",[13]="K",[12]="Q",[11]="J"}
local function illustration(UI,hand,tx,ty,tw)
    local g=love.graphics
    if not cache[hand.id] then
        local cards,scored=Examples.get(hand.id)
        cache[hand.id]={cards=cards,scored=scored}
    end
    local example=cache[hand.id]
    g.setFont(UI.fonts.regular);g.setColor(UI.COLORS.goldYellow)
    g.print("MẪU LÁ ĐÁNH · TRÁI → PHẢI",tx,ty)
    local cw=math.min(70,(tw-48)/5);local gap=12
    local start=tx+(tw-(cw*5+gap*4))/2
    local age=love.timer.getTime()-(H.previewAt or 0)
    for i,card in ipairs(example.cards) do
        local scored=example.scored[card]
        local lift=scored and 7*math.min(1,math.max(0,(age-(i-1)*.045)/.18)) or 0
        local cx,cy=start+(i-1)*(cw+gap),ty+38-lift
        g.setColor(1,1,1,scored and 1 or .35)
        local image=UI.getCardImage(card.suit,card.rank)
        if image then
            UI.CardFrame.image(image,cx,cy,cw,cw*1.5)
            UI.CardFrame.draw(cx,cy,cw,cw*1.5,nil,scored and 1 or .35,card)
        end
        g.setFont(UI.fonts.regular)
        g.setColor(scored and UI.COLORS.textLight or UI.COLORS.textMuted)
        g.printf((ranks[card.rank] or tostring(card.rank))..symbols[card.suit],cx,ty+cw*1.5+44,cw,"center")
        if scored then
            g.setColor(UI.COLORS.chipsBlue);g.rectangle("fill",cx+4,ty+cw*1.5+67,cw-8,2)
        end
    end
    g.setFont(UI.fonts.regular);g.setColor(UI.COLORS.textMuted)
    g.printf(hand.condition and "Chọn đủ 5 lá theo mẫu; giữ đúng thứ tự." or "Lá sáng: ghi điểm · Lá mờ: có thể bỏ khỏi tay đánh.",tx,ty+cw*1.5+79,tw,"left")
end
function H.draw(game,UI,buttons,mx,my,x,y,w,h)
    local g=love.graphics;local basic=H.page==0
    local list=basic and Poker.HAND_TYPES_ORDERED or Poker.ADVANCED_HANDS_ORDERED
    local page=basic and H.basicPage or H.page
    local pageSize=basic and 5 or 6
    local first=(page-1)*pageSize+1
    local last=math.min(first+pageSize-1,#list)
    local rowH,step=basic and 92 or 78,basic and 104 or 87
    local listW=math.floor((w-72)*.49)
    local detailX=x+48+listW
    local top=y+142
    local selected=list[first]
    for index=first,last do
        if list[index].id==H.selected then selected=list[index] end
    end
    for index=first,last do
        if inside(mx,my,x+24,top+(index-first)*step,listW,rowH) then selected=list[index] end
    end
    if H.preview~=selected.id then H.preview=selected.id;H.previewAt=love.timer.getTime() end
    for index=first,last do
        local hand=list[index];local ry=top+(index-first)*step
        local active=hand==selected;local unlocked=hand.id=="high_card" or game.unlockedHands and game.unlockedHands[hand.id]
        UI.drawGildedPanel(x+24,ry,listW,rowH,active and (hand.color or UI.COLORS.goldYellow) or {0.35,0.32,0.27,1})
        local img=UI.getHandImage(hand.id)
        local thumbH=rowH-10
        if img then g.setColor(1,1,1,1);require("ui.card_surfaces").image(hand,x+34,ry+5,thumbH*2/3,thumbH,img) end
        g.setFont(UI.fonts.medium);g.setColor(active and UI.COLORS.goldYellow or UI.COLORS.textLight)
        local textX=x+(basic and 104 or 86)
        g.print(hand.vnName,textX,ry+(basic and 15 or 7))
        g.setFont(UI.fonts.small);g.setColor(unlocked and UI.COLORS.chipsBlue or UI.COLORS.textMuted)
        local category=basic and hand.subtitle or hand.mythic and "HUYỀN THOẠI" or "NÂNG CAO"
        g.print(category.." · "..(unlocked and "ĐÃ HỌC" or "CHƯA HỌC").." · Cấp "..(game.handLevels and game.handLevels[hand.id] or 1),textX,ry+(basic and 46 or 40))
        buttons[#buttons+1]={id="handbook_select_"..hand.id,text="",x=x+24,y=ry,w=listW,h=rowH}
    end
    UI.drawGildedPanel(detailX,top,w-(detailX-x)-24,h-166)
    local tx,tw=detailX+24,w-(detailX-x)-72
    g.setFont(UI.fonts.medium);g.setColor(UI.COLORS.goldYellow);g.printf(selected.vnName,tx,y+160,tw,"left")
    local img=UI.getHandImage(selected.id)
    if img then g.setColor(1,1,1,1);require("ui.card_surfaces").image(selected,tx,y+202,90,135,img) end
    local infoX,infoW=tx+114,tw-114
    local stats=Poker.getHandStats(selected.id,game.handLevels and game.handLevels[selected.id] or 1)
    g.setFont(UI.fonts.regular);g.setColor(UI.COLORS.chipsBlue)
    g.printf("Cấp "..stats.level.." · "..stats.chips.." Sát thương × "..stats.mult.." Cường hóa",infoX,y+210,infoW,"left")
    g.setColor(UI.COLORS.goldYellow)
    g.print(basic and "ĐIỀU KIỆN" or "ĐIỀU KIỆN · ĐÚNG 5 LÁ",infoX,y+249)
    g.setColor(UI.COLORS.textLight);g.printf(selected.condition or Examples.conditions[selected.id],infoX,y+278,infoW,"left")
    illustration(UI,selected,tx,y+378,tw)
    g.setFont(UI.fonts.regular);g.setColor(UI.COLORS.goldYellow)
    g.print(basic and "CÁCH SỬ DỤNG" or "HIỆU QUẢ SAU ĐÒN ĐÁNH",tx,y+614)
    local unlocked=selected.id=="high_card" or game.unlockedHands and game.unlockedHands[selected.id]
    g.setColor(UI.COLORS.textLight)
    g.printf(selected.effect or (unlocked and "Chọn các lá cần thiết rồi nhấn ĐÁNH. Thế cao hơn đã học được ưu tiên." or "Học thế này từ Rương Thế Đánh hoặc Bí Tịch trước khi sử dụng."),tx,y+643,tw,"left")
    local foot=y+h-36
    local pageCount=basic and 2 or 3
    for _,entry in ipairs({{"handbook_prev","←",x+24,page==1},{"handbook_next","→",x+24+listW-66,page==pageCount}}) do
        local b={id=entry[1],text=entry[2],x=entry[3],y=foot,w=66,h=30,font=UI.fonts.regular,color=UI.COLORS.btnSort,disabled=entry[4]}
        buttons[#buttons+1]=b;UI.drawButton(b,inside(mx,my,b.x,b.y,b.w,b.h))
    end
    g.setFont(UI.fonts.small);g.setColor(UI.COLORS.textMuted)
    g.printf("Trang "..page.." / "..pageCount..(basic and " · Rê chuột xem mẫu · Bấm để giữ" or " · A=1 · Rê chuột để xem mẫu"),x+98,foot+7,listW-148,"center")
    return true
end
return H

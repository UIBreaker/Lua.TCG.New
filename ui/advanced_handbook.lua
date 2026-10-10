local H={page=0,selected=nil}
function H.click(id)
    if id=="handbook_basic" then H.page=0;return true end
    if id=="handbook_advanced" then H.page=math.max(1,H.page);return true end
    if id=="handbook_prev" then H.page=math.max(1,H.page-1);H.selected=nil;return true end
    if id=="handbook_next" then H.page=math.min(3,H.page+1);H.selected=nil;return true end
    local selected=id:match("^handbook_select_(.+)$")
    if selected then H.selected=selected;return true end
end
function H.tabs(UI,buttons,mx,my,x,y)
    for i,entry in ipairs({{"handbook_basic","CƠ BẢN · 9",H.page==0},{"handbook_advanced","NÂNG CAO · 18",H.page>0}}) do
        local b={id=entry[1],text=entry[2],x=x+(i-1)*190,y=y,w=180,h=28,font=UI.fonts.tiny,color=entry[3] and UI.COLORS.goldYellow or UI.COLORS.btnSort}
        buttons[#buttons+1]=b;UI.drawButton(b,mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h)
    end
end
function H.draw(game,UI,buttons,mx,my,x,y,w,h)
    if H.page==0 then return false end
    local g=love.graphics;local list=require("src.poker").ADVANCED_HANDS_ORDERED
    local first=(H.page-1)*6+1
    local selected=require("src.advanced_hands").byId[H.selected] or list[first]
    for index=first,math.min(first+5,#list) do
        local hand=list[index];local ry=y+110+(index-first)*76
        local active=hand==selected;local unlocked=game.unlockedHands and game.unlockedHands[hand.id]
        UI.drawGildedPanel(x+24,ry,550,68,active and hand.color or {0.35,0.32,0.27,1})
        local img=UI.getHandImage(hand.id)
        if img then g.setColor(1,1,1,1);require("ui.card_surfaces").image(hand,x+34,ry+5,38,58,img) end
        g.setFont(UI.fonts.small);g.setColor(active and UI.COLORS.goldYellow or UI.COLORS.textLight)
        g.print(hand.vnName,x+86,ry+8)
        g.setFont(UI.fonts.tiny);g.setColor(UI.COLORS.textMuted)
        g.print((hand.mythic and "HUYỀN THOẠI · " or "NÂNG CAO · ")..(unlocked and "ĐÃ HỌC" or "CHƯA HỌC"),x+86,ry+33)
        local b={id="handbook_select_"..hand.id,text="",x=x+24,y=ry,w=550,h=68}
        buttons[#buttons+1]=b
    end
    UI.drawGildedPanel(x+592,y+110,w-616,h-142)
    local tx=x+610;local tw=w-654;local ty=y+126
    g.setFont(UI.fonts.regular);g.setColor(UI.COLORS.goldYellow);g.printf(selected.vnName,tx,ty,tw,"left")
    ty=ty+54
    local img=UI.getHandImage(selected.id)
    if img then g.setColor(1,1,1,1);require("ui.card_surfaces").image(selected,tx+tw/2-42,ty,84,126,img) end
    ty=ty+138
    local stats=require("src.poker").getHandStats(selected.id,game.handLevels and game.handLevels[selected.id] or 1)
    g.setFont(UI.fonts.small);g.setColor(UI.COLORS.chipsBlue);g.printf("Cấp "..stats.level.." · "..stats.chips.." × "..stats.mult,tx,ty,tw,"center")
    ty=ty+36
    g.setFont(UI.fonts.tiny);g.setColor(UI.COLORS.goldYellow);g.print("ĐIỀU KIỆN · ĐÚNG 5 LÁ",tx,ty)
    g.setColor(UI.COLORS.textLight);g.printf(selected.condition,tx,ty+21,tw,"left")
    ty=ty+80
    g.setColor(UI.COLORS.goldYellow);g.print("HIỆU QUẢ SAU ĐÒN ĐÁNH",tx,ty)
    g.setColor(UI.COLORS.textLight);g.printf(selected.effect,tx,ty+21,tw,"left")
    local foot=y+h-46
    for _,entry in ipairs({{"handbook_prev","←",x+24},{"handbook_next","→",x+508}}) do
        local b={id=entry[1],text=entry[2],x=entry[3],y=foot,w=66,h=30,font=UI.fonts.small,color=UI.COLORS.btnSort}
        buttons[#buttons+1]=b;UI.drawButton(b,mx>=b.x and mx<=b.x+b.w and my>=b.y and my<=b.y+b.h)
    end
    g.setFont(UI.fonts.tiny);g.setColor(UI.COLORS.textMuted)
    g.printf("Trang "..H.page.." / 3 · A=1 · Thứ tự trái → phải",x+102,foot+9,392,"center")
    return true
end
return H

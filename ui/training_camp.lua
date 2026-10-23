local UI=require("src.ui")
local Core=require("ui.components.core")
local C=require("ui.theme").colors
local M=require("src.training_camp")
local V={}
local gold={.91,.76,.49,1}
local green={.56,.85,.70,1}
local blue={.56,.77,.93,1}
local labels={damage="Sát thương",speed="Tốc đánh",mult="Cường hóa"}
local function text(s,x,y,w,font,color,align) Core.text(s,x,y,w,font or UI.fonts.small,color or C.text,align) end
local function inside(mx,my,x,y,w,h) return mx>=x and mx<=x+w and my>=y and my<=y+h end
local function line(x,y,w,color,alpha)
    love.graphics.setColor(color[1],color[2],color[3],alpha or .25);love.graphics.setLineWidth(1);love.graphics.line(x,y,x+w,y)
end
local function panel(x,y,w,h,accent,focus)
    local g=love.graphics
    g.setColor(0,0,0,.25);g.rectangle("fill",x,y+6,w,h,12)
    Core.gradient(x,y,w,h,{.055,.075,.083,.97},{.022,.035,.042,.97},10)
    g.setLineWidth(focus and 1.6 or 1)
    g.setColor(accent[1],accent[2],accent[3],focus and .8 or .27);g.rectangle("line",x+.5,y+.5,w-1,h-1,10)
end
local function button(buttons,id,label,x,y,w,h,mx,my,disabled,data,accent)
    accent=accent or gold
    local hover=not disabled and inside(mx,my,x,y,w,h);local g=love.graphics
    g.setColor(accent[1],accent[2],accent[3],disabled and .045 or hover and .24 or .13);g.rectangle("fill",x,y,w,h,6)
    g.setColor(accent[1],accent[2],accent[3],disabled and .16 or hover and .95 or .5);g.setLineWidth(1);g.rectangle("line",x+.5,y+.5,w-1,h-1,6)
    text(label,x+12,y+(h-UI.fonts.small:getHeight())/2,w-24,UI.fonts.small,disabled and C.muted or accent,"center")
    local b={id=id,text=label,x=x,y=y,w=w,h=h,disabled=disabled}
    for k,v in pairs(data or {}) do b[k]=v end;buttons[#buttons+1]=b
end
local function selected(e,id) for i,v in ipairs(e.selected) do if v==id then return i end end end
local function name(c)
    local d=require("src.card_abilities").definition(c)
    local value=c.characterName or c.name or d and d.characterName
    return value and (value:match("^(.-) ·") or value) or ((c.rankName or tostring(c.rank))..(c.suitSymbol or ""))
end
local function card(c,x,y,w,h,mx,my)
    UI.CardPhysics.suspend()
    UI.drawCardFace(c,x,y,w,h,false)
    UI.CardPhysics.resume()
    if inside(mx,my,x,y,w,h) and love.keyboard.isDown("lshift","rshift") then UI.descriptionCandidate=c end
end
local function portrait(which,x,y,w,h)
    if not V.art then V.art=love.graphics.newImage("assets/scene/events/training_camp.png");V.art:setFilter("linear","linear") end
    local iw,ih=V.art:getDimensions();local sourceW=iw*.42;local sourceH=sourceW*h/w
    V.quads=V.quads or {}
    local key=which..":"..w..":"..h
    if not V.quads[key] then V.quads[key]=love.graphics.newQuad(which==1 and 0 or iw-sourceW,ih*(which==1 and .15 or .34),sourceW,sourceH,iw,ih) end
    local g=love.graphics;g.setColor(1,1,1,.94);g.draw(V.art,V.quads[key],x,y,0,w/sourceW,h/sourceH)
    for i=0,19 do g.setColor(.025,.04,.047,(i/19)^2*.9);g.rectangle("fill",x,y+h*.55+i*h*.45/20,w,h*.45/20+1) end
end
local function health(hp,maxHp,x,y,w)
    local g=love.graphics;g.setColor(.02,.04,.04,.9);g.rectangle("fill",x,y,w,7,3)
    g.setColor(green);g.rectangle("fill",x,y,w*math.max(0,math.min(1,hp/maxHp)),7,3)
end
local function heading(game,e)
    local g=love.graphics;g.setColor(.018,.029,.036,.9);g.rectangle("fill",0,0,1280,85)
    line(36,84,1208,gold,.26)
    text("ĐIỂM DỪNG CHÂN / TRẠM VIỄN CHINH",42,18,760,UI.fonts.tiny,gold)
    text("Trạm Nghỉ Huấn Luyện",42,38,740,UI.fonts.large,C.text)
    text(string.format("SINH LỰC  %.0f / %.0f",game.playerHp or 0,game.maxPlayerHp or 100),880,29,224,UI.fonts.small,green,"right")
    health(game.playerHp or 0,game.maxPlayerHp or 100,920,56,184)
    text(e.phase=="choice" and "01  CHỌN HOẠT ĐỘNG" or e.phase=="select" and "02  CHỌN THÀNH VIÊN" or "03  SẴN SÀNG LÊN ĐƯỜNG",42,686,650,UI.fonts.tiny,gold)
end
local function welcome(game,e,buttons,mx,my)
    text("NGỌN LỬA CÒN ẤM",48,145,334,UI.fonts.tiny,gold)
    text("Dừng chân.\nSẵn sàng cho\nchặng đường mới.",46,181,344,UI.fonts.large,C.text)
    line(48,319,78,gold,.8)
    text("Một khoảng nghỉ giữa cuộc viễn chinh.\nBạn muốn hồi sức cho bản thân,\nhay rèn giũa những người đồng hành?",48,345,334,UI.fonts.small,C.text)
    text("CHỈ ĐƯỢC CHỌN MỘT",48,468,334,UI.fonts.tiny,gold)
    text("Miễn phí tại trạm\nLợi ích được giữ vĩnh viễn",48,498,334,UI.fonts.small,C.muted)
    for i=1,2 do
        local x=414+(i-1)*414;local w=390;local accent=i==1 and green or blue
        panel(x,123,w,518,accent,inside(mx,my,x,123,w,518))
        portrait(i,x+10,133,w-20,176)
        text(i==1 and "01 / HỒI PHỤC" or "02 / RÈN LUYỆN",x+24,150,w-48,UI.fonts.tiny,accent)
        text(i==1 and "Nghỉ ngơi" or "Huấn luyện",x+24,286,w-48,UI.fonts.large,C.text)
        text(i==1 and "Bình yên bên lửa trại" or "Mạnh hơn trước bình minh",x+24,330,w-48,UI.fonts.small,C.muted)
        line(x+24,368,w-48,accent)
        text(i==1 and "65%" or "+5",x+24,389,150,UI.fonts.large,accent)
        text(i==1 and "máu tối đa được hồi" or "một chỉ số mỗi lá",x+140,400,w-164,UI.fonts.small,C.text)
        text(i==1 and "+10 máu tối đa vĩnh viễn" or "Tối đa 3 quân bài khác nhau",x+24,444,w-48,UI.fonts.medium,gold)
        local nextMax=(game.maxPlayerHp or 100)+10
        local nextHp=math.min(nextMax,(game.playerHp or 0)+math.ceil(nextMax*.65))
        text(i==1 and string.format("Sau nghỉ: %.0f / %.0f máu\nTăng giới hạn máu trước khi hồi phục.",nextHp,nextMax) or "Ngẫu nhiên: sát thương, tốc đánh\nhoặc cường hóa. Nâng cấp vĩnh viễn.",x+24,490,w-48,UI.fonts.small,C.muted)
        button(buttons,i==1 and "camp_rest" or "camp_train",i==1 and "Nghỉ bên lửa trại  →" or "Chọn quân bài huấn luyện  →",x+24,568,w-48,48,mx,my,i==2 and #M.cards(game)==0,nil,accent)
    end
    text("Lựa chọn sẽ được lưu ngay khi xác nhận.",734,685,494,UI.fonts.tiny,C.muted,"right")
end
local function selection(game,e,buttons,mx,my)
    local cards=M.cards(game);local pages=math.max(1,math.ceil(#cards/8));e.page=math.max(1,math.min(e.page,pages))
    local byId={};for _,c in ipairs(cards) do byId[c.id]=c end
    panel(30,107,280,544,blue)
    text("ĐỘI HÌNH HUẤN LUYỆN",50,129,240,UI.fonts.tiny,blue)
    text(#e.selected.." / 3 thành viên",50,158,240,UI.fonts.medium,C.text)
    text("Mỗi lá +5 một chỉ số ngẫu nhiên",50,195,240,UI.fonts.tiny,C.muted)
    for i=1,3 do
        local y=234+(i-1)*108;local c=byId[e.selected[i]]
        love.graphics.setColor(blue[1],blue[2],blue[3],c and .08 or .025);love.graphics.rectangle("fill",48,y,244,96,7)
        if c then
            card(c,58,y+8,53,80,mx,my)
            text("THÀNH VIÊN 0"..i,124,y+12,154,UI.fonts.tiny,gold)
            Core.textLine(name(c),124,y+34,154,UI.fonts.small,C.text,"left",UI.fonts.tiny)
            button(buttons,"camp_card","Bỏ chọn",124,y+60,150,27,mx,my,false,{cardId=c.id},blue)
        else
            text("0"..i,64,y+29,46,UI.fonts.medium,blue)
            text("Chưa chọn quân bài",120,y+38,160,UI.fonts.small,C.muted)
        end
    end
    text("Sát thương · Tốc đánh · Cường hóa",50,579,240,UI.fonts.tiny,blue)
    text("Có thể tập 1–3 lá.\nĐã chọn nhánh huấn luyện.",50,608,240,UI.fonts.tiny,C.muted)
    text("Chạm một quân bài để chọn hoặc bỏ chọn",338,111,630,UI.fonts.small,C.text)
    text("Giữ Shift trên lá để xem chi tiết",910,114,328,UI.fonts.tiny,C.muted,"right")
    for slot=1,8 do
        local c=cards[(e.page-1)*8+slot]
        if c then
            local x=334+((slot-1)%4)*230;local y=147+math.floor((slot-1)/4)*241
            local index=selected(e,c.id);local hover=inside(mx,my,x,y,212,226);local disabled=not index and #e.selected>=3
            panel(x,y,212,226,index and gold or blue,index~=nil or hover and not disabled)
            card(c,x+55,y+12,102,153,mx,my)
            Core.textLine(name(c),x+9,y+173,194,UI.fonts.small,index and gold or C.text,"center",UI.fonts.tiny)
            text(index and "✓  ĐÃ CHỌN · 0"..index or disabled and "Đã đủ 3 thành viên" or "Chọn thành viên",x+9,y+201,194,UI.fonts.tiny,index and gold or C.muted,"center")
            buttons[#buttons+1]={id="camp_card",cardId=c.id,x=x,y=y,w=212,h=226,disabled=disabled}
        end
    end
    button(buttons,"camp_page","←",336,645,42,32,mx,my,e.page<=1,{delta=-1},blue)
    text("Trang "..e.page.." / "..pages,389,654,140,UI.fonts.small,C.muted,"center")
    button(buttons,"camp_page","→",540,645,42,32,mx,my,e.page>=pages,{delta=1},blue)
    button(buttons,"camp_confirm","Huấn luyện "..#e.selected.." quân bài  →",850,642,388,40,mx,my,#e.selected==0,nil,blue)
end
local function results(game,e,buttons,mx,my)
    local rest=e.branch=="rest";local accent=rest and green or blue
    text("MỘT ĐÊM KHÔNG UỔNG PHÍ",50,128,1100,UI.fonts.tiny,gold)
    text(rest and "Hơi ấm cho chặng đường dài." or "Những người đồng hành đã mạnh hơn.",48,161,1176,UI.fonts.large,C.text)
    if rest then
        panel(50,231,1178,373,accent)
        portrait(1,60,241,460,353)
        text("ĐÃ NGHỈ NGƠI",553,257,610,UI.fonts.tiny,green)
        text(string.format("+%.0f máu hồi phục",e.healed),550,298,620,UI.fonts.large,green)
        text("+10 máu tối đa vĩnh viễn",553,351,610,UI.fonts.medium,gold)
        line(553,400,628,green)
        text(string.format("SINH LỰC  %.0f / %.0f",e.afterHp,e.newMax),553,427,610,UI.fonts.medium,C.text)
        health(e.afterHp,e.newMax,553,471,620)
        text(string.format("Giới hạn sinh lực: %.0f → %.0f\nĐoàn viễn chinh đã sẵn sàng lên đường.",e.oldMax,e.newMax),553,510,610,UI.fonts.small,C.muted)
    else
        local byId={};for _,c in ipairs(M.cards(game)) do byId[c.id]=c end
        local n=#(e.results or {})
        for i,reward in ipairs(e.results or {}) do
            local x=640-n*174+(i-1)*348;panel(x+10,231,328,372,blue)
            text("THÀNH VIÊN 0"..i,x+30,250,288,UI.fonts.tiny,gold,"center")
            if byId[reward.id] then card(byId[reward.id],x+109,281,130,195,mx,my) end
            text("+5 "..labels[reward.stat],x+24,500,300,UI.fonts.medium,green,"center")
            text("ĐÃ LƯU VĨNH VIỄN",x+24,547,300,UI.fonts.tiny,C.muted,"center")
        end
    end
    button(buttons,"camp_leave","Tiếp tục cuộc viễn chinh  →",830,632,398,48,mx,my,false,nil,accent)
    text(rest and "Hồi phục hoàn tất · Sinh lực tối đa đã tăng" or "Huấn luyện hoàn tất · Chỉ số mới đã áp dụng",50,649,738,UI.fonts.small,C.muted)
end
function V.draw(game,buttons,mx,my)
    local e=game.trainingCamp;if not e then return end
    local g=love.graphics;g.push("all")
    g.setColor(.009,.02,.028,e.phase=="choice" and .25 or .52);g.rectangle("fill",0,0,1280,720)
    heading(game,e)
    if e.phase=="choice" then welcome(game,e,buttons,mx,my)
    elseif e.phase=="select" then selection(game,e,buttons,mx,my)
    else results(game,e,buttons,mx,my) end
    g.pop()
end
function V.press(game,b)
    if b.id=="camp_rest" then return M.choose(game,"rest") end
    if b.id=="camp_train" then return M.choose(game,"train") end
    if b.id=="camp_card" then return M.toggle(game,b.cardId) end
    if b.id=="camp_confirm" then return M.train(game) end
    if b.id=="camp_page" and game.trainingCamp.phase=="select" then game.trainingCamp.page=math.max(1,game.trainingCamp.page+b.delta);return true end
    if b.id=="camp_leave" and M.leave(game) then return "leave" end
end
return V

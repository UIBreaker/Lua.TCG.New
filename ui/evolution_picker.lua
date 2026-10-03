local A=require("src.card_abilities")
local Deities=require("src.deities")
local Core=require("ui.components.core")
local Picker={}
local ink={0.90,0.92,0.97,1}
local muted={0.53,0.58,0.69,1}
local violet={0.66,0.48,0.97,1}
local function text(UI,value,x,y,w,font,color,align)
    Core.textLine(value,x,y,w,UI.fonts[font],color or ink,align or "left",UI.fonts.tiny)
end
local function panel(x,y,w,h,color)
    love.graphics.setColor(color);love.graphics.rectangle("fill",x,y,w,h,10,10)
end
local function description(UI,value,x,y,w,h,color)
    local font=UI.fonts.small
    local _,lines=font:getWrap(value,w)
    if #lines*font:getHeight()>h then font=UI.fonts.tiny end
    love.graphics.setFont(font);love.graphics.setColor(color or ink)
    love.graphics.printf(value,x,y,w)
end
function Picker.draw(UI,m,mx,my)
    local g=love.graphics
    g.push("all");g.setColor(0.015,0.02,0.04,0.94);g.rectangle("fill",0,0,1280,720)
    panel(54,32,1172,656,{0.055,0.068,0.095,1})
    g.setColor(0.27,0.24,0.39,1);g.setLineWidth(1);g.rectangle("line",54,32,1172,656,10,10)
    text(UI,"NÂNG CẤP VĨNH VIỄN",84,55,700,"tiny",violet)
    text(UI,"Chọn lá tiến hóa",84,80,700,"large")
    text(UI,"Nâng khả năng của một lá. Giữ nguyên bậc và chất.",84,120,700,"small",muted)
    m.buttons={}
    local function button(id,label,x,y,w,h,index,disabled,active)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,index=index,disabled=disabled,
            font=UI.fonts.small,color=active and {0.35,0.24,0.55,1} or UI.COLORS.btnNormal}
        m.buttons[#m.buttons+1]=b;UI.drawButton(b,not disabled and mx>=x and mx<=x+w and my>=y and my<=y+h)
    end
    local counts={cards=0,deities=0};local filtered={}
    for _,c in ipairs(m.cards) do local kind=A.definition(c) and "cards" or "deities";counts[kind]=counts[kind]+1 end
    m.filter=m.filter or (counts.cards>0 and "cards" or "deities")
    for i,c in ipairs(m.cards) do if (A.definition(c) and "cards" or "deities")==m.filter then filtered[#filtered+1]=i end end
    button("tab_cards","QUÂN BÀI  ·  "..counts.cards,84,158,176,36,nil,false,m.filter=="cards")
    button("tab_deities","HỘ LINH  ·  "..counts.deities,272,158,176,36,nil,false,m.filter=="deities")
    g.setColor(violet);g.rectangle("fill",m.filter=="cards" and 84 or 272,195,176,2,1,1)
    local pages=math.max(1,math.ceil(#filtered/8));m.page=math.max(1,math.min(m.page,pages))
    UI.CardPhysics.suspend()
    for slot=0,7 do
        local index=filtered[(m.page-1)*8+slot+1]
        if index then
            local c=m.cards[index];local x,y=84+(slot%4)*180,210+math.floor(slot/4)*200
            local selected=m.selected==c;local hovered=mx>=x and mx<=x+166 and my>=y and my<=y+190
            panel(x,y,166,190,selected and {0.16,0.115,0.25,1} or hovered and {0.105,0.12,0.17,1} or {0.075,0.087,0.12,1})
            if selected or hovered then
                g.setColor(selected and violet or {0.34,0.38,0.49,1});g.setLineWidth(selected and 2 or 1);g.rectangle("line",x,y,166,190,10,10)
            end
            if A.definition(c) then UI.drawCard(c,x+31,y+9,104,150)
            else UI.drawPatronCard(c,x+31,y+9,104,150) end
            local name=c.name or ((c.rankName or tostring(c.rank))..(c.suitSymbol or ""))
            text(UI,name,x+8,y+165,150,"small",selected and violet or ink,"center")
            m.buttons[#m.buttons+1]={id="target",index=index,x=x,y=y,w=166,h=190}
        end
    end
    UI.CardPhysics.resume()
    if #filtered==0 then text(UI,"Không có lá thuộc nhóm này.",100,350,660,"small",muted,"center") end
    panel(824,158,372,448,{0.075,0.087,0.12,1})
    text(UI,"XEM TRƯỚC TIẾN HÓA",848,179,324,"tiny",violet)
    local c=m.selected
    if c then
        local d=A.definition(c);local name=c.name or ((c.rankName or tostring(c.rank))..(c.suitSymbol or ""))
        text(UI,name,848,210,324,"medium")
        text(UI,d and ("Cấp "..(c.evolutionLevel or 0).."  →  Cấp "..((c.evolutionLevel or 0)+1)) or "Nâng bậc Hộ Linh",848,245,324,"small",violet)
        local before=d and A.description(c) or Deities.getDescription(c)
        local after
        if d then after=A.description(c,A.level(c)+1)
        else local copy={};for k,v in pairs(c) do copy[k]=v end;copy.evolutionLevel=(copy.evolutionLevel or 0)+1;after=Deities.getDescription(copy) end
        text(UI,"HIỆN TẠI",848,291,324,"tiny",muted)
        description(UI,before,848,315,324,95,muted)
        g.setColor(0.24,0.26,0.34,1);g.line(848,422,1172,422)
        text(UI,"SAU TIẾN HÓA",848,443,324,"tiny",violet)
        description(UI,after,848,469,324,110)
    else
        text(UI,"Chọn một lá bên trái",848,308,324,"medium")
        description(UI,"Xem thay đổi khả năng trước khi xác nhận. Thẻ tiến hóa chỉ được dùng khi bạn xác nhận.",848,356,324,120,muted)
    end
    button("cancel","HỦY  /  ESC",84,628,160,38)
    text(UI,"Trang "..m.page.." / "..pages,330,638,180,"tiny",muted,"center")
    if m.page>1 then button("prev","←",270,628,46,38) end
    if m.page<pages then button("next","→",524,628,46,38) end
    button("confirm","XÁC NHẬN TIẾN HÓA",824,624,372,46,nil,not c,true)
    g.pop()
end
return Picker

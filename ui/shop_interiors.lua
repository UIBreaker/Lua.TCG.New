local Profiles=require("config.shop_visuals").profiles
local UI=require("src.ui")
local Theme=require("ui.theme")
local Lighting=require("render.lighting")
local Visual=require("config.visual_config")
local I={profiles=Profiles}
local C=Theme.colors

function I.position(mode,item,index,page)
    local profile=Profiles[mode]
    if not profile then return end
    local bay=item.bay or index
    if mode=="medicine" then
        local current=page or 1
        if math.ceil(bay/8)~=current then return end
        bay=bay-(current-1)*8
    end
    local row=math.floor((bay-1)/profile.columns)
    local col=(bay-1)%profile.columns
    local w,h,y=106,159,row==0 and 157 or 435
    if mode=="equipment" then
        w,h,y=row==0 and 96 or 108,row==0 and 144 or 162,row==0 and 170 or 435
    elseif mode=="spn" then w,h,y=110,165,row==0 and 155 or 435 end
    local lane=934/profile.columns
    local x=308+(col+.5)*lane-w/2
    return x,y,w,h,row+1,col+1
end

local function text(value,x,y,w,font,color,align)
    love.graphics.setFont(font or UI.fonts.tiny)
    love.graphics.setColor(color or C.text)
    love.graphics.printf(value,x,y,w,align or "left")
end

local function plate(x,y,w,h,profile)
    local g=love.graphics;local m=profile.material
    g.setColor(.009,.009,.016,.65);UI.drawRoundedRect("fill",x+3,y+5,w,h,5)
    g.setColor(m[1]*.55,m[2]*.55,m[3]*.55,.94);UI.drawRoundedRect("fill",x,y,w,h,5)
    g.setColor(profile.accent[1],profile.accent[2],profile.accent[3],.45);g.setLineWidth(1)
    UI.drawRoundedRect("line",x+2,y+2,w-4,h-4,4)
    for _,cx in ipairs({x+9,x+w-9}) do for _,cy in ipairs({y+9,y+h-9}) do
        g.setColor(C.gold);g.circle("fill",cx,cy,1.5)
    end end
end

local function emblem(mode,cx,cy,accent)
    local g=love.graphics
    g.setColor(accent);g.setLineWidth(1.5);g.circle("line",cx,cy,23)
    if mode=="medicine" then
        g.rectangle("line",cx-5,cy-17,10,8,2,2)
        g.polygon("line",cx-5,cy-9,cx-12,cy-3,cx-12,cy+12,cx+12,cy+12,cx+12,cy-3,cx+5,cy-9)
        g.line(cx-6,cy+3,cx+6,cy+3);g.line(cx,cy-3,cx,cy+9)
    elseif mode=="equipment" then
        g.polygon("line",cx-17,cy-6,cx+17,cy-6,cx+10,cy,cx+4,cy,cx+4,cy+9,cx+12,cy+14,cx-12,cy+14,cx-4,cy+9,cx-4,cy,cx-11,cy)
        g.line(cx-3,cy-15,cx+8,cy-15);g.line(cx+2,cy-15,cx+2,cy-6)
    elseif mode=="small" then
        g.rectangle("line",cx-14,cy-11,28,24,2,2)
        g.line(cx-14,cy-3,cx+14,cy-3);g.line(cx-3,cy-11,cx-3,cy+13);g.line(cx+3,cy-11,cx+3,cy+13)
    elseif mode=="cards" then
        g.rectangle("line",cx-13,cy-15,20,28,2,2)
        g.rectangle("line",cx-6,cy-10,20,28,2,2)
        g.polygon("fill",cx+4,cy-3,cx+9,cy+4,cx+4,cy+11,cx-1,cy+4)
    elseif mode=="consumable" then
        g.polygon("line",cx-16,cy-12,cx,cy-7,cx+16,cy-12,cx+16,cy+12,cx,cy+16,cx-16,cy+12)
        g.line(cx,cy-7,cx,cy+16);g.line(cx-12,cy-3,cx-4,cy);g.line(cx+4,cy,cx+12,cy-3)
    else
        g.ellipse("line",cx,cy,17,8);g.ellipse("line",cx,cy,8,17)
        g.circle("fill",cx,cy,4);g.line(cx,cy-19,cx,cy-23);g.line(cx,cy+19,cx,cy+23)
    end
end

local function sidebar(shop,game,profile)
    local g=love.graphics
    g.setColor(.37,.29,.17,.85);g.setLineWidth(2)
    g.line(62,67,62,88);g.line(238,67,238,88)
    plate(28,86,242,164,profile)
    emblem(shop.mode,149,125,profile.accent)
    text(profile.brand,40,161,218,UI.fonts.small,profile.accent,"center")
    text(profile.motto,48,194,202,nil,C.text,"center")

    plate(28,461,242,181,profile)
    text("SỔ QUẦY",46,475,206,UI.fonts.small,profile.accent)
    text("Hàng còn lại",46,503,145,nil,C.muted)
    text(tostring(#shop.items).." món",191,503,59,nil,C.text,"right")
    if shop.mode=="spn" then
        local D=require("src.deities")
        text("SPN trong balo",46,528,150,nil,C.muted)
        text(tostring(#(game.backpackDeities or {})),196,528,54,nil,C.text,"right")
    elseif shop.mode=="equipment" then
        text("Trang bị trong balo",46,528,154,nil,C.muted)
        text(tostring(#(game.backpackEquipment or {})),206,528,44,nil,C.text,"right")
    elseif shop.mode=="cards" then
        text("Quân bài trong bộ",46,528,154,nil,C.muted)
        text(tostring(#(game.persistentDeck or {})),206,528,44,nil,C.text,"right")
    else
        text("Tiêu hao trong balo",46,528,150,nil,C.muted)
        text(tostring(#(game.backpackConsumables or {})),196,528,54,nil,C.text,"right")
    end
    g.setColor(profile.accent[1],profile.accent[2],profile.accent[3],.25);g.line(46,553,252,553)
    text(profile.help,46,566,204,nil,C.muted)
    text("Chọn món → xác nhận mua",46,613,204,nil,profile.accent,"center")
end

local function displayCase(profile,row,tactical)
    local g=love.graphics;local m=profile.material
    local x,y,w,h=292,row==1 and 86 or 372,966,row==1 and 277 or 270
    g.setColor(.006,.009,.015,.32);UI.drawRoundedRect("fill",x+3,y+5,w,h,6)
    g.setColor(m[1]*.35,m[2]*.35,m[3]*.35,.48);UI.drawRoundedRect("fill",x,y,w,h,6)
    g.setColor(profile.accent[1],profile.accent[2],profile.accent[3],.25);g.setLineWidth(1)
    UI.drawRoundedRect("line",x+2,y+2,w-4,h-4,5)
    plate(x+12,y+8,w-24,34,profile)
    text((tactical and profile.tacticalRows or profile.rows)[row],x+27,y+17,360,UI.fonts.small,profile.accent)
    text((tactical and profile.tacticalNotes or profile.notes)[row],x+390,y+18,w-417,nil,C.muted,"right")
end

function I.draw(shop,game,time,buttons)
    local profile=Profiles[shop.mode]
    if not profile then return end
    local g=love.graphics;g.push("all")
    sidebar(shop,game,profile)
    local page=shop.page or 1
    local tactical=shop.mode=="medicine" and page==2
    displayCase(profile,1,tactical);displayCase(profile,2,tactical)
    if shop.mode=="medicine" then
        for index,label in ipairs({"HỒI PHỤC", "CHIẾN THUẬT"}) do
            local b={id="medicine_page_"..index,text=label,x=28+(index-1)*123,y=385,w=119,h=36,
                font=UI.fonts.tiny,color=page==index and C.green or C.inset}
            UI.drawButton(b,false);if buttons then buttons[#buttons+1]=b end
        end
        text("NGĂN "..page.." / 2",28,432,242,nil,profile.accent,"center")
    end
    local occupied={}
    for _,item in ipairs(shop.items) do
        if I.position(shop.mode,item,nil,page) then occupied[item.bay-(shop.mode=="medicine" and (page-1)*8 or 0)]=true end
    end
    for bay=1,profile.columns*2 do
        local x,y,w,h=I.position(shop.mode,{bay=bay+(shop.mode=="medicine" and (page-1)*8 or 0)},nil,page)
        local cx,foot=x+w/2,y+h+4
        if shop.mode=="spn" then
            g.setColor(.035,.048,.087,.85);g.ellipse("fill",cx,foot+9,93,14)
            g.setColor(profile.accent[1],profile.accent[2],profile.accent[3],.38);g.ellipse("line",cx,foot+6,86,9)
        else
            g.setColor(.15,.095,.048,.9)
            g.polygon("fill",cx-95,foot,cx+95,foot,cx+101,foot+8,cx-101,foot+8)
            g.setColor(.04,.027,.019,.95);g.rectangle("fill",cx-101,foot+8,202,35,2,2)
            g.setColor(profile.accent[1],profile.accent[2],profile.accent[3],.35);g.line(cx-95,foot+8,cx+95,foot+8)
        end
        if not occupied[bay] then
            text("HẾT HÀNG",cx-85,y+h*.48,170,nil,C.muted,"center")
        end
    end
    g.pop()
end

function I.label(item,x,y,w,h)
    local g=love.graphics;g.push("all")
    local width=208;local font=UI.fonts.small
    local scale=math.min(1,width/math.max(1,font:getWidth(item.name or "")))
    g.setFont(font);g.setColor(C.text)
    g.translate(x+w/2-width/2,y+h+9);g.scale(scale)
    g.printf(item.name or "",0,0,width/scale,"center");g.pop()
    local caption=item.deity and require("src.deities").getRarityLabel(item.deity)
        or item.equipment and (item.equipment.basic and "NGUYÊN LIỆU CƠ BẢN" or "TRANG BỊ LỚN")
        or item.subtitle or "TIÊU HAO"
    text(caption,x+w/2-104,y+h+28,208,nil,item.color or C.muted,"center")
end

function I.drawWorld(shop,time)
    local profile=Profiles[shop.mode]
    if not profile then return end
    local g=love.graphics;g.push("all")
    if Visual.enabled and Visual.effects.lighting then
        g.setBlendMode("add")
        Lighting.glow(146,335,165,profile.accent,.065)
        for _,item in ipairs(shop.items) do
            local x,y,w,h=I.position(shop.mode,item,nil,shop.page)
            if x then Lighting.glow(x+w/2,y+h*.6,w*1.1,item.color or profile.accent,Visual.shop.spotlight*.5) end
        end
    end
    g.pop()
end
return I

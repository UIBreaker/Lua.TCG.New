local E = require("src.expedition")
local Run = require("src.run_manager")
local Art = require("src.enemy_art")
local Boss = require("src.boss_abilities")
local S = {}
function S.draw(game, UI, mx, my)
    local g, buttons = love.graphics, {}
    local run=game.run; if not run then return buttons end
    local region=E.region(run.ante)
    local gold, muted, white = {0.92,0.77,0.49}, {0.63,0.70,0.74}, {0.93,0.94,0.90}
    local function text(value,x,y,w,font,color,align)
        g.setFont(UI.fonts[font] or UI.fonts.small); g.setColor(color or white)
        g.printf(value,x,y,w,align or "left")
    end
    local function panel(x,y,w,h,color,alpha)
        g.setColor(0.025,0.045,0.061,alpha or 0.94); g.rectangle("fill",x,y,w,h,12,12)
        g.setColor(color[1],color[2],color[3],0.55);g.setLineWidth(1);g.rectangle("line",x,y,w,h,12,12)
    end
    local function button(id,label,x,y,w,h,color)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,color=color,font=UI.fonts.small}
        buttons[#buttons+1]=b; UI.drawButton(b,mx>=x and mx<=x+w and my>=y and my<=y+h)
    end
    g.push("all")
    g.setColor(0.015,0.024,0.035,0.42);g.rectangle("fill",0,0,1280,720)
    panel(24,18,1232,76,gold)
    text("NHẬT KÝ VIỄN CHINH",44,29,600,"large",gold)
    text("ĐOÀN THÁM HIỂM  /  LIÊN MINH BỐN VƯƠNG QUỐC",46,65,700,"tiny",muted)
    button("open_handbook","SỔ TAY",872,32,108,46,{0.17,0.29,0.29,1})
    button("open_deck_viewer","BỘ BÀI",991,32,108,46,{0.19,0.27,0.36,1})
    button("open_pause_menu","TÙY CHỌN",1110,32,126,46,{0.22,0.25,0.30,1})
    -- Persistent route: chapter boundaries and objectives are always visible.
    for i,r in ipairs(E.regions) do
        local x=24+(i-1)*416
        local active=region==r
        panel(x,108,400,64,active and r.color or muted,active and 0.94 or 0.78)
        text(string.format("0%d  %s",i,r.name),x+16,120,370,"small",active and r.color or muted)
        text(r.range..(active and "   /   ĐANG KHÁM PHÁ" or run.ante>r.first and "   /   ĐÃ ĐI QUA" or "   /   CHƯA ĐẾN"),x+16,148,370,"tiny",muted)
    end
    panel(24,186,1232,82,region.color,0.89)
    text("ẢI "..string.format("%02d",run.ante).."  /  "..region.name,44,197,800,"medium",region.color)
    text(region.objective,44,229,910,"small",white)
    text(run.travelPermit and "GIẤY PHÉP: ĐÃ CẤP" or "GIẤY PHÉP: MỐC 20",984,204,250,"small",gold,"right")
    text(run.endless and "CHẾ ĐỘ VÔ TẬN" or "CHIẾN DỊCH 20 ẢI",994,235,240,"tiny",muted,"right")
    -- Three encounter dossiers. Only the current fight can be started.
    for i,blind in ipairs(run.blinds) do
        local x,y,w,h=24+(i-1)*416,282,400,340
        local current=blind.status=="current"
        local done=blind.status=="completed"
        local c=current and region.color or muted
        panel(x,y,w,h,c,current and 0.96 or 0.90)
        g.setColor(c[1],c[2],c[3],current and 1 or 0.35);g.rectangle("fill",x+15,y+1,w-30,3)
        text(string.format("0%d / %s",i,({"ĐỐI THỦ","TINH ANH","THỦ LĨNH"})[i]),x+18,y+14,w-36,"small",c)
        local m=Run.createBlindMonster(blind,game,true)
        -- Preview rendering must not consume combat RNG.
        local img=Art.image(m,{})
        if img then
            local iw,ih=img:getDimensions();local fit=math.min(112/iw,155/ih)
            g.setColor(1,1,1,done and 0.45 or current and 1 or 0.68)
            g.draw(img,x+24+(112-iw*fit)/2,y+50,0,fit,fit)
        end
        text(blind.kingdom and ("VƯƠNG QUỐC "..blind.kingdom:upper()) or "SINH VẬT BÍ ẨN",x+153,y+52,228,"tiny",muted)
        text(blind.name,x+153,y+73,228,"medium",white)
        text("HP  "..UI.formatNumber(blind.hp),x+153,y+145,228,"small",region.color)
        text("CHIẾN LỢI PHẨM  +$"..blind.baseReward,x+153,y+174,228,"tiny",gold)
        local count=require("src.enemy_group").count(blind.ante,i==3,i==2)
        text("ĐỘI HÌNH  "..count.." ĐỐI THỦ",x+153,y+196,228,"tiny",muted)
        g.setColor(c[1],c[2],c[3],0.2);g.line(x+18,y+217,x+w-18,y+217)
        if blind.debuff then
            text("NỘI TẠI • "..UI.truncateUtf8(Boss.passiveDescription(m) or blind.debuff.desc,94),x+18,y+228,w-36,"tiny",muted)
            local active=blind.debuff.active
            if active then text("CHIÊU • "..active.name.." / mỗi "..(active.cooldown+1).." tay",x+18,y+264,w-36,"tiny",gold) end
        else
            text(i==1 and "Thắng trận để tích lũy vàng và mở trận tinh anh." or "Đối thủ mạnh hơn. Thắng để tiến đến thử thách thủ lĩnh.",x+18,y+233,w-36,"small",muted)
        end
        if current then button("fight_blind","VÀO TRẬN",x+18,y+h-48,w-36,34,{0.18,0.48,0.39,1})
        else text(done and "ĐÃ CHIẾN THẮNG" or "HOÀN THÀNH TRẬN TRƯỚC ĐỂ MỞ",x+18,y+h-41,w-36,"small",done and {0.44,0.80,0.59} or muted,"center") end
    end
    panel(24,636,1232,66,gold)
    local count=region.last and region.last-region.first+1 or 20
    local block=region.last and region.first or (41+math.floor((run.ante-41)/20)*20)
    text("TUYẾN HÀNH TRÌNH",44,646,240,"tiny",gold)
    for j=1,count do
        local stage=block+j-1;local x=283+(j-1)*39
        g.setColor(stage<run.ante and 0.32 or region.color[1],stage<run.ante and 0.65 or region.color[2],stage<run.ante and 0.49 or region.color[3],stage<=run.ante and 0.9 or 0.22)
        g.rectangle("fill",x,654,30,28,5,5)
        text(tostring(stage),x,661,30,"tiny",stage==run.ante and white or muted,"center")
    end
    text("HP "..(game.playerHp or 100).."/"..(game.maxPlayerHp or 100).."   •   $"..(game.gold or 0).."   •   "..#(game.persistentDeck or {}).." LÁ",44,674,240,"tiny",muted)
    text("3 TRẬN / ẢI",1085,663,150,"small",muted,"right")
    g.pop()
    return buttons
end
return S

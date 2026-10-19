local E = require("src.expedition")
local Run = require("src.run_manager")
local Art = require("src.enemy_art")
local Boss = require("src.boss_abilities")
local S = {}
function S.drawBlood(game,UI,mx,my)
    local g=love.graphics;local buttons={};local run=game.run;local red={.87,.34,.38,1}
    local Chrome=require("ui.combat_chrome");local Core=require("ui.components.core")
    local function text(value,x,y,w,font,color,align) Core.text(value,x,y,w,font or UI.fonts.small,color or {0.94,0.93,0.88,1},align) end
    local function button(id,label,x,y,w,h)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,color={.22,.09,.12,1},font=UI.fonts.small}
        UI.drawButton(b,mx>=x and mx<=x+w and my>=y and my<=y+h);buttons[#buttons+1]=b
    end
    g.push("all")
    Chrome.panel(24,22,1232,76,red)
    text("LÃNH ĐỊA MÁU · HÀNH TRÌNH KHÉP KÍN",43,39,920,UI.fonts.large,red)
    text(string.format("TRẬN %d / 8 · SINH LỰC %.1f / %g · ĐỘ KHÓ ×2 NHÁNH CHÍNH (ẢI %d)",run.areaStage,game.playerHp or 0,game.maxPlayerHp or 100,run.difficultyCap or run.ante),45,77,1030,UI.fonts.tiny)
    button("open_pause_menu","TÙY CHỌN",1104,36,130,43)
    for stage=1,8 do
        local x=24+(stage-1)*156;local active=stage==run.areaStage
        Chrome.panel(x,116,140,62,active and red or {.40,.34,.35,1})
        text(stage==8 and "08 · VƯƠNG HUYẾT" or string.format("ẢI %02d",stage),x+8,126,124,UI.fonts.small,active and red or {.69,.64,.62,1},"center")
        text(stage<run.areaStage and "ĐÃ VƯỢT QUA" or active and "ĐANG ĐỐI MẶT" or "CHƯA ĐẾN",x+8,153,124,UI.fonts.tiny,nil,"center")
    end
    Chrome.panel(24,199,1232,402,red)
    local blind=Run.getCurrentBlind(run);local m=Run.createBlindMonster(blind,game,true)
    local image=Art.image(m,{})
    if image then
        g.setColor(1,1,1,1);local Frame=require("ui.components.card_frame")
        Frame.image(image,86,226,224,336);Frame.draw(86,226,224,336,nil,nil,m)
    end
    text(m.name,355,232,840,UI.fonts.large,red)
    text(m.title,358,280,830,UI.fonts.small)
    text(string.format("MÁU %g   ·   SÁT THƯƠNG %g",m.maxHp,m.attack),358,324,830,UI.fonts.medium,{.94,.76,.47,1})
    text(m.desc,358,375,820,UI.fonts.medium)
    text("Không thể dùng giấy phép để rời đi.\nPhần thưởng boss: chọn 1 trong 3 SPN có chỉ số ×4.\nHạ boss để trở lại đúng hành trình trước khi chạm tượng.",358,495,820,UI.fonts.small,{.72,.69,.68,1})
    button("open_backpack","CHUẨN BỊ BALO",24,630,290,54)
    button("open_deck_viewer","XEM BỘ BÀI",328,630,250,54)
    button("fight_blind",run.areaStage==8 and "ĐỐI MẶT VƯƠNG HUYẾT" or "BƯỚC VÀO TRẬN",834,630,422,54)
    g.pop();return buttons
end
function S.draw(game, UI, mx, my)
    if game.run and game.run.regionId=="blood_domain" then return S.drawBlood(game,UI,mx,my) end
    local g, buttons = love.graphics, {}
    local run=game.run; if not run then return buttons end
    local region=E.region(run.ante,run.regionId)
    local localStage=run.areaStage or run.ante
    local area=E.area(localStage,region.id)
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
    text("TỔNG HÀNH TRÌNH "..run.ante.."  /  "..(region.suit and "ĐỐI THỦ ĐỒNG CHẤT" or region.id=="human" and "ĐOÀN ĐỘC LẬP • VÔ CHẤT" or "KHÁM PHÁ LỤC ĐỊA"),46,65,700,"tiny",muted)
    button("open_handbook","SỔ TAY",872,32,108,46,{0.17,0.29,0.29,1})
    button("open_backpack","BALO",753,32,108,46,{.28,.24,.16,1})
    button("open_deck_viewer","BỘ BÀI",991,32,108,46,{0.19,0.27,0.36,1})
    button("open_pause_menu","TÙY CHỌN",1110,32,126,46,{0.22,0.25,0.30,1})
    -- Persistent route: chapter boundaries and objectives are always visible.
    for i=1,4 do
        local x=24+(i-1)*312
        local active=area.index==i
        panel(x,108,296,64,active and region.color or muted,active and 0.94 or 0.78)
        text(string.format("0%d  %s",i,(region.areas or {})[i] or "MIỀN ĐẤT CHƯA KHÁM PHÁ"),x+12,120,272,"small",active and region.color or muted)
        text(string.format("ẢI %02d — %02d",(run.regionStartAnte or run.ante-localStage+1)+(i-1)*5,(run.regionStartAnte or run.ante-localStage+1)+i*5-1)..(active and "   /   ĐANG KHÁM PHÁ" or area.index>i and "   /   ĐÃ ĐI QUA" or "   /   CHƯA ĐẾN"),x+12,148,272,"tiny",muted)
    end
    panel(24,186,1232,82,region.color,0.89)
    text("ẢI "..string.format("%02d",run.ante).."  /  "..region.name,44,197,800,"medium",region.color)
    text(run.difficultyCap and ("ĐÃ CHINH PHỤC · GIỮ ĐỘ KHÓ ẢI "..run.difficultyCap.." · Dùng giấy phép trong balo để rời đi lúc cần.") or region.objective,44,229,910,"small",white)
    text(E.hasTravelPermit(game) and (E.unlimitedTravel(game) and "GIẤY PHÉP: VÔ HẠN" or "GIẤY PHÉP: TRONG BALO") or "GIẤY PHÉP: MỐC 20",974,204,260,"small",gold,"right")
    text(region.id=="unknown" and "KHÁM PHÁ VÔ TẬN" or "4 KHU VỰC • 20 ẢI",994,235,240,"tiny",muted,"right")
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
            local Frame=require("ui.components.card_frame")
            local bx=x+24+(112-iw*fit)/2
            Frame.image(img,bx,y+50,iw*fit,ih*fit);Frame.draw(bx,y+50,iw*fit,ih*fit,nil,nil,m)
        end
        text(m.neutralHuman and "NHÂN LOẠI • VÔ CHẤT" or blind.kingdom and ("VƯƠNG QUỐC "..blind.kingdom:upper()) or "SINH VẬT BÍ ẨN",x+153,y+52,228,"tiny",muted)
        text(blind.name,x+153,y+73,228,"medium",white)
        text("HP  "..UI.formatNumber(blind.hp),x+153,y+145,228,"small",region.color)
        text("CHIẾN LỢI PHẨM  +$"..blind.baseReward,x+153,y+174,228,"tiny",gold)
        local count=require("src.enemy_group").count(blind.difficultyAnte or blind.ante,i==3,i==2)
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
    local count=20
    local block=region.id=="unknown" and (1+math.floor((localStage-1)/20)*20) or 1
    text("TUYẾN HÀNH TRÌNH",44,646,240,"tiny",gold)
    for j=1,count do
        local stage=block+j-1;local x=283+(j-1)*39
        g.setColor(stage<localStage and 0.32 or region.color[1],stage<localStage and 0.65 or region.color[2],stage<localStage and 0.49 or region.color[3],stage<=localStage and 0.9 or 0.22)
        g.rectangle("fill",x,654,30,28,5,5)
        text(tostring((run.regionStartAnte or run.ante-localStage+1)+stage-1),x,661,30,"tiny",stage==localStage and white or muted,"center")
    end
    text("HP "..(game.playerHp or 100).."/"..(game.maxPlayerHp or 100).."   •   $"..(game.gold or 0).."   •   "..#(game.persistentDeck or {}).." LÁ",44,674,240,"tiny",muted)
    text("3 TRẬN / ẢI",1085,663,150,"small",muted,"right")
    g.pop()
    return buttons
end
return S

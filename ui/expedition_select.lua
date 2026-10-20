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
local Chrome=require("ui.combat_chrome")
local Core=require("ui.components.core")
local Theme=require("ui.theme")
local Group=require("src.enemy_group")
function S.preview(blind,game)
    local m=Run.createBlindMonster(blind,game,true)
    local count=Group.count(blind.difficultyAnte or blind.ante,blind.type=="boss",blind.type=="big")
    local passive=Boss.passiveDescription(m)
    if passive=="" then passive=m.enemyAbility and m.enemyAbility.desc or "Không có nội tại đặc biệt được công bố." end
    local active=m.bossData and m.bossData.active
    local action=active and Boss.activeDescription(m) or "Đánh thường và sử dụng trang bị theo tình hình trận đấu."
    local cadence=active and ("Mỗi "..((active.cooldown or 0)+1).." tay") or "Theo lượt chiến đấu"
    return {monster=m,count=count,passive=passive,action=action,active=active,cadence=cadence,
        detail={encounterPreview=true,hoverKey=blind,name=m.name,desc="MÁU NỀN ĐỘI HÌNH · "..blind.hp.." HP\nSÁT THƯƠNG NỀN · "..m.attack.."\nĐỘI HÌNH · "..count.." đối thủ\nTHƯỞNG · +"..blind.baseReward.." Vàng\n\nNỘI TẠI\n"..passive.."\n\n"..(active and active.name or "HÀNH ĐỘNG").." · "..cadence.."\n"..action.."\n\nChỉ số nền chưa gồm trang bị và hiệu ứng trong trận. Tốc đánh được xác định khi vào trận."}}
end
function S.draw(game, UI, mx, my)
    if game.run and game.run.regionId=="blood_domain" then return S.drawBlood(game,UI,mx,my) end
    local g,buttons=love.graphics,{}
    local run=game.run;if not run then return buttons end
    local region=E.region(run.ante,run.regionId)
    local localStage=run.areaStage or run.ante
    local area=E.area(localStage,region.id)
    local gold,muted,white=Theme.colors.gold,Theme.colors.muted,Theme.colors.text
    local function text(value,x,y,w,font,color,align)
        Core.text(value,x,y,w,UI.fonts[font] or UI.fonts.small,color or white,align)
    end
    local function button(id,label,x,y,w,h,variant)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,variant=variant or "gold",font=UI.fonts.small}
        buttons[#buttons+1]=b;Chrome.button(UI,b,mx,my)
    end
    local function excerpt(value,x,y,w,lines,color)
        local font=UI.fonts.tiny
        local _,wrapped=font:getWrap(value,w)
        for i=1,math.min(lines,#wrapped) do
            local line=wrapped[i]
            if i==lines and #wrapped>lines then line=line.."…" end
            Core.textLine(line,x,y+(i-1)*16,w,font,color or white)
        end
    end
    g.push("all")
    g.setColor(.008,.015,.022,.48);g.rectangle("fill",0,0,1280,720)
    Chrome.panel(24,16,1232,70)
    Chrome.crest(56,50,22,gold)
    Chrome.title("NHẬT KÝ VIỄN CHINH",88,27,636,UI.fonts.bookHeading or UI.fonts.large,gold)
    text("ẢI "..run.ante.." · "..(region.suit and "ĐỐI THỦ ĐỒNG CHẤT" or region.id=="human" and "ĐOÀN ĐỘC LẬP · VÔ CHẤT" or "KHÁM PHÁ LỤC ĐỊA"),89,62,630,"tiny",muted)
    button("open_backpack","BALO",753,29,108,43)
    button("open_handbook","SỔ TAY",872,29,108,43,"cyan")
    button("open_deck_viewer","BỘ BÀI",991,29,108,43)
    button("open_pause_menu","TÙY CHỌN",1110,29,126,43,"purple")
    for i=1,4 do
        local x=24+(i-1)*312;local current=area.index==i
        Chrome.well(x,99,296,49,current and region.color or Theme.colors.metal)
        Core.textLine(string.format("%02d · %s",i,(region.areas or {})[i] or "MIỀN ĐẤT CHƯA KHÁM PHÁ"),x+12,108,272,UI.fonts.small,current and gold or muted)
        text(string.format("ẢI %02d–%02d",(run.regionStartAnte or run.ante-localStage+1)+(i-1)*5,(run.regionStartAnte or run.ante-localStage+1)+i*5-1).." · "..(current and "ĐANG KHÁM PHÁ" or area.index>i and "ĐÃ VƯỢT" or "CHƯA ĐẾN"),x+12,130,272,"tiny",muted)
    end
    Chrome.panel(24,160,1232,66,region.color)
    Chrome.title("ẢI "..string.format("%02d",run.ante).." / "..region.name,43,171,850,UI.fonts.bookChapter or UI.fonts.medium,gold)
    Core.textLine(run.difficultyCap and ("Giữ độ khó ải "..run.difficultyCap.." · Dùng giấy phép trong balo để rời đi.") or region.objective,44,201,905,UI.fonts.tiny,muted)
    text(E.hasTravelPermit(game) and (E.unlimitedTravel(game) and "GIẤY PHÉP VÔ HẠN" or "ĐÃ CÓ GIẤY PHÉP") or "GIẤY PHÉP · MỐC 20",966,175,267,"small",gold,"right")
    text("3 TRẬN / ẢI · "..(region.id=="unknown" and "VÔ TẬN" or "20 ẢI"),966,203,267,"tiny",muted,"right")
    S.previews={}
    for i,blind in ipairs(run.blinds) do
        local x,y,w,h=24+(i-1)*416,240,400,390
        local current,done=blind.status=="current",blind.status=="completed"
        local accent=current and gold or Theme.colors.metal
        Chrome.panel(x,y,w,h,accent)
        text(string.format("%02d · %s",i,({"ĐỐI THỦ","TINH ANH","THỦ LĨNH"})[i]),x+17,y+15,190,"small",i==3 and Theme.colors.red or gold)
        text(done and "ĐÃ THẮNG" or current and "SẴN SÀNG" or "CHƯA MỞ",x+222,y+16,160,"tiny",done and Theme.colors.green or current and gold or muted,"right")
        Chrome.rule(x+18,y+39,w-36,accent)
        local p=S.preview(blind,game);S.previews[i]=p
        local m=p.monster
        local image=Art.image(m,{})
        if image then
            g.setColor(1,1,1,done and .5 or 1)
            UI.CardFrame.image(image,x+19,y+53,94,141)
            UI.CardFrame.draw(x+19,y+53,94,141,nil,nil,m)
        end
        local nameFont=UI.fonts.regular
        local _,nameLines=nameFont:getWrap(m.name,249)
        if #nameLines>2 then nameFont=UI.fonts.small end
        Core.text(m.name,x+132,y+54,249,nameFont,white)
        Core.textLine(m.neutralHuman and "NHÂN LOẠI · VÔ CHẤT" or m.kingdom and m.kingdom:upper() or "SINH VẬT BÍ ẨN",x+132,y+102,249,UI.fonts.tiny,muted)
        local stats={{"MÁU NỀN ĐỘI",UI.formatNumber(blind.hp),Theme.colors.red},{"ST NỀN ĐỘI",UI.formatNumber(m.attack),Theme.colors.cyan},{"ĐỐI THỦ",p.count,white},{"THƯỞNG VÀNG","+"..blind.baseReward,gold}}
        for n,stat in ipairs(stats) do
            local tx=x+130+(n-1)%2*126;local ty=y+124+math.floor((n-1)/2)*43
            Chrome.well(tx,ty,122,39,stat[3])
            text(stat[1],tx+9,ty+5,104,"tiny",muted)
            text(stat[2],tx+9,ty+20,104,"small",stat[3],"right")
        end
        Chrome.rule(x+18,y+215,w-36,accent)
        text("NỘI TẠI",x+19,y+227,w-38,"tiny",gold)
        excerpt(p.passive,x+19,y+247,w-38,2,muted)
        Core.textLine(p.active and (p.active.name.." · "..p.cadence) or "HÀNH ĐỘNG",x+19,y+285,w-38,UI.fonts.tiny,p.active and Theme.colors.red or gold)
        excerpt(p.action,x+19,y+305,w-38,2,white)
        if mx>=x+12 and mx<=x+w-12 and my>=y+45 and my<=y+337 then UI.descriptionCandidate=p.detail end
        if current then button("fight_blind","VÀO TRẬN",x+18,y+342,w-36,34,"cyan")
        else
            text(done and "HOÀN THÀNH" or "THẮNG TRẬN TRƯỚC ĐỂ MỞ",x+18,y+352,w-36,"small",done and Theme.colors.green or muted,"center")
        end
    end
    Chrome.panel(24,643,1232,60)
    text("TUYẾN HÀNH TRÌNH",43,655,230,"tiny",gold)
    text("HP "..(game.playerHp or 100).."/"..(game.maxPlayerHp or 100).." · "..(game.gold or 0).." Vàng · "..#(game.persistentDeck or {}).." lá",43,678,235,"tiny",muted)
    local block=region.id=="unknown" and (1+math.floor((localStage-1)/20)*20) or 1
    for j=1,20 do
        local stage=block+j-1;local x=283+(j-1)*39
        Chrome.well(x,657,30,29,stage==localStage and gold or stage<localStage and Theme.colors.green or Theme.colors.metal)
        text(tostring((run.regionStartAnte or run.ante-localStage+1)+stage-1),x,664,30,"tiny",stage==localStage and gold or muted,"center")
    end
    text("Rê chuột lên địch",1073,656,162,"tiny",muted,"right")
    text("để xem đầy đủ",1073,678,162,"tiny",muted,"right")
    g.pop();return buttons
end
return S

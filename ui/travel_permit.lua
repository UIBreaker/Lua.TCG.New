local E=require("src.expedition")
local P={images={}}
function P.draw(game,UI,mx,my)
    local g,buttons=love.graphics,{}
    local run=game.run;local current=E.region(run.ante,run.regionId)
    local gold={.92,.77,.49};local muted={.65,.72,.75}
    local function text(s,x,y,w,font,c,align)
        g.setColor(c or gold);g.setFont(UI.fonts[font]);g.printf(s,x,y,w,align or "left")
    end
    local function panel(x,y,w,h,c)
        g.setColor(.025,.043,.059,.95);g.rectangle("fill",x,y,w,h,10,10)
        g.setLineWidth(1);g.setColor(c[1],c[2],c[3],.6);g.rectangle("line",x,y,w,h,10,10)
    end
    local function button(id,label,x,y,w,h,c,disabled)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,color=c,font=UI.fonts.small,disabled=disabled}
        buttons[#buttons+1]=b;UI.drawButton(b,mx>=x and mx<=x+w and my>=y and my<=y+h)
    end
    g.push("all");g.setColor(.008,.014,.023,.66);g.rectangle("fill",0,0,1280,720)
    panel(24,22,1232,150,gold)
    local permit=E.travelPermit();local permitArt=UI.getConsumableImage(permit)
    if permitArt then g.setColor(1,1,1);UI.CardFrame.image(permitArt,44,39,72,108);UI.drawCardBorder(44,39,72,108,nil,nil,permit) end
    text("GIẤY PHÉP DI CHUYỂN",138,38,970,"large",gold)
    text((run.victory and "ĐÃ HOÀN THÀNH 20 ẢI • " or "ẢI "..run.ante.." • ")..current.name,138,82,1090,"medium",current.color)
    text("Chọn điểm đến · Chỉ tiêu hao khi xác nhận · Công nhận "..E.recognitionCount(game).."/4",138,120,1090,"small",muted)
    local slot=0
    for _,region in ipairs(E.regions) do
        if region.id~=current.id then
            local x,y,w,h=24+slot*249,194,236,338;slot=slot+1
            panel(x,y,w,h,region.color)
            local key=region.areas and "journey_"..region.id.."_1" or region.background
            local path=E.backgroundPaths[key] or "assets/scene/expedition_coast.png"
            if not P.images[key] and love.filesystem.getInfo(path) then
                P.images[key]=g.newImage(path);P.images[key]:setFilter("linear","linear")
            end
            local img=P.images[key]
            if img then
                local iw,ih=img:getDimensions();local fit=math.max((w-16)/iw,130/ih)
                local sx,sy=g.transformPoint(x+8,y+8);local ex,ey=g.transformPoint(x+w-8,y+138)
                g.setScissor(sx,sy,ex-sx,ey-sy);g.setColor(.8,.84,.87,1)
                g.draw(img,x+w/2-iw*fit/2,y+73-ih*fit/2,0,fit,fit);g.setScissor()
            end
            text(region.short,x+14,y+153,w-28,"medium",region.color)
            text(region.id=="unknown" and "LỤC ĐỊA • VÔ TẬN" or "20 ẢI • 4 KHU VỰC",x+14,y+194,w-28,"small",gold)
            text(region.id=="human" and "Đoàn độc lập, lá bài vô chất." or region.id=="unknown" and "Bờ biển đá ngầm và các sinh vật bí ẩn." or "Đối thủ chỉ mang chất của vương quốc này.",x+14,y+229,w-28,"small",muted)
            local allowed,reason=E.canEnter(game,region.id)
            if not allowed then text("CẦN 4 CÔNG NHẬN · "..E.recognitionCount(game).."/4",x+14,y+269,w-28,"tiny",{.95,.55,.42}) end
            button("travel_"..region.id,allowed and "DÙNG GIẤY PHÉP" or "CHƯA ĐỦ ĐIỀU KIỆN",x+12,y+h-49,w-24,36,{region.color[1]*.35,region.color[2]*.35,region.color[3]*.35,1},not allowed)
        end
    end
    panel(24,552,1232,144,gold)
    for i,id in ipairs(E.recognitionIds) do
        local x=44+(i-1)*225;local card=E.recognitionCard(id);local owned=(game.regionRecognitions or {})[id]
        local img=UI.getConsumableImage(card);g.setColor(1,1,1,owned and 1 or .35)
        if img then UI.CardFrame.image(img,x,569,38,57);UI.drawCardBorder(x,569,38,57,nil,nil,card) end
        text(E.byId[id].short,x+48,575,164,"small",owned and card.color or muted)
        text(owned and "ĐÃ CÔNG NHẬN" or "CHƯA CHINH PHỤC",x+48,602,164,"tiny",muted)
        if mx>=x and mx<=x+212 and my>=569 and my<=626 then UI.descriptionCandidate=card end
    end
    text(E.recognitionCount(game).." / 4 CÔNG NHẬN",976,581,260,"small",gold,"center")
    button("travel_sell","BÁN • +1.000 VÀNG",44,642,320,38,{.44,.33,.15,1})
    text("VÀNG "..(game.gold or 0).." • "..(run.stats.blindsWon or 0).." TRẬN THẮNG",395,654,545,"small",muted)
    button(game.travelRequest and "travel_cancel" or "victory_menu",game.travelRequest and "GIỮ GIẤY PHÉP · QUAY LẠI" or "VỀ MÀN HÌNH CHÍNH",958,642,278,38,{.21,.26,.30,1})
    g.pop();return buttons
end
return P

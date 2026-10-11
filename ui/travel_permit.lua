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
    local function button(id,label,x,y,w,h,c)
        local b={id=id,text=label,x=x,y=y,w=w,h=h,color=c,font=UI.fonts.small}
        buttons[#buttons+1]=b;UI.drawButton(b,mx>=x and mx<=x+w and my>=y and my<=y+h)
    end
    g.push("all");g.setColor(.008,.014,.023,.66);g.rectangle("fill",0,0,1280,720)
    panel(24,22,1232,150,gold)
    text("GIẤY PHÉP DI CHUYỂN",44,38,1000,"large",gold)
    text("ĐÃ HOÀN THÀNH 20 ẢI • "..current.name,44,82,1140,"medium",current.color)
    text("Chọn một điểm đến để dùng giấy phép, hoặc bán và tiếp tục khám phá tại đây.",44,120,1140,"small",muted)
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
            button("travel_"..region.id,"DÙNG GIẤY PHÉP",x+12,y+h-49,w-24,36,{region.color[1]*.35,region.color[2]*.35,region.color[3]*.35,1})
        end
    end
    panel(24,552,1232,144,gold)
    text("Ở LẠI "..current.short,44,565,750,"medium",gold)
    text("Bán giấy phép: +1.000 vàng. Bắt đầu chặng 20 ải mới tại vùng hiện tại.",44,599,900,"small",muted)
    button("travel_sell","BÁN • +1.000 VÀNG",44,642,320,38,{.44,.33,.15,1})
    text("VÀNG "..(game.gold or 0).." • "..(run.stats.blindsWon or 0).." TRẬN THẮNG",395,654,545,"small",muted)
    button("victory_menu","VỀ MÀN HÌNH CHÍNH",958,642,278,38,{.21,.26,.30,1})
    g.pop();return buttons
end
return P

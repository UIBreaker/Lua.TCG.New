local frames=0
function love.load()
    love.filesystem.setIdentity("poker_roguelike_human_boss_gallery")
    love.window.setMode(1600,1060,{resizable=false})
    require("src.ui").initFonts()
end
function love.draw()
    local g=love.graphics;local UI=require("src.ui");local Core=require("ui.components.core")
    local Frame=require("ui.components.card_frame");local Art=require("src.enemy_art")
    local rows=require("config.human_boss_data").list
    g.clear(.02,.035,.045,1)
    Core.text("LỤC ĐỊA CON NGƯỜI · MƯỜI THỦ LĨNH",30,18,1540,UI.fonts.large,{.94,.78,.48},"center")
    Core.text("ẢI 1–20 · BOSS NGẪU NHIÊN · TRANH RIÊNG CHO TỪNG CƠ CHẾ",30,59,1540,UI.fonts.small,{.61,.75,.79},"center")
    for index,d in ipairs(rows) do
        local x=20+((index-1)%5)*316;local y=100+math.floor((index-1)/5)*476
        local image=assert(require("src.continental_art").get(d.id),"Missing human Boss art: "..d.id)
        local w,h=image:getDimensions();assert(math.abs(w/h-2/3)<.01)
        g.setColor(1,1,1);Frame.image(image,x+43,y+10,210,315)
        Frame.draw(x+43,y+10,210,315)
        Core.textLine(index.." · "..d.name,x+4,y+340,292,UI.fonts.regular,{.94,.80,.53},"center",UI.fonts.small)
        Core.text(d.desc,x+6,y+376,290,UI.fonts.small,{.80,.85,.84},"center")
        Core.text(d.active.name,x+6,y+444,290,UI.fonts.small,{.52,.81,.94},"center")
        assert(Art.key({isBoss=true,bossData=d,neutralHuman=true,cardRank=13})==d.id)
    end
    frames=frames+1
    if frames==3 then
        g.captureScreenshot(function(data)
            local f=assert(io.open("docs/human_boss_roster.png","wb"));f:write(data:encode("png"):getString());f:close()
            print("Human Boss gallery PASS: ten distinct Continental portraits, runtime loader, common frame, names and mechanics")
            love.event.quit(0)
        end)
    end
end

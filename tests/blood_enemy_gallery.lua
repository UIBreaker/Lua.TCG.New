local G={}
function G.capture()
    local UI=require("src.ui")
    local Core=require("ui.components.core")
    local Chrome=require("ui.combat_chrome")
    local Frame=require("ui.components.card_frame")
    local Art=require("src.enemy_art")
    local S=require("src.ancient_statue")
    local g=love.graphics;local canvas=g.newCanvas(1600,1120)
    g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.clear(.022,.028,.037,1)
    local gold={.92,.75,.46,1};local red={.84,.29,.34,1}
    Core.text("LÃNH ĐỊA MÁU · TÁM KẺ CANH GIỮ",30,24,1540,UI.fonts.large,gold,"center")
    Core.text("7 LOÀI ĐỊCH RIÊNG BIỆT · 1 BOSS VƯƠNG HUYẾT",30,70,1540,UI.fonts.small,red,"center")
    for stage,e in ipairs(S.enemies) do
        local x=22+((stage-1)%4)*394;local y=114+math.floor((stage-1)/4)*492
        Chrome.panel(x,y,376,476,stage==8 and gold or red)
        local m=S.decorate({stage=stage,areaStage=stage},stage)
        local image=assert(Art.image(m,{}),"Missing GPU artwork: "..e.key)
        local w,h=image:getDimensions();assert(math.abs(w/h-2/3)<.01)
        Core.textLine("ẢI "..stage.." · "..(stage==8 and "BOSS · " or "").."CẤP "..require("src.expedition").rankName(e.rank),x+14,y+16,348,UI.fonts.small,gold,"center")
        g.setColor(1,1,1,1);Frame.image(image,x+88,y+50,200,300);Frame.draw(x+88,y+50,200,300,nil,nil,m)
        Core.textLine(e.name,x+12,y+365,352,UI.fonts.medium,gold,"center",UI.fonts.small)
        Core.text(e.skill or "Khát Sinh Mệnh",x+14,y+401,348,UI.fonts.small,red,"center")
        Core.text(stage==8 and "Bạn hồi HP: boss ×2 Máu / Tốc / ST.\nCuối lượt: −2% HP hiện tại." or e.desc,x+14,y+430,348,UI.fonts.tiny,{.73,.74,.75,1},"center")
    end
    g.pop()
    local data=canvas:newImageData();local file=assert(io.open("docs/blood_enemies_roster.png","wb"))
    file:write(data:encode("png"):getString());file:close();data:release();canvas:release()
    print("Blood enemy gallery PASS: all eight runtime images, indices, common frames and descriptions rendered")
end
return G

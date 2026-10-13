local UI=require("src.ui")
local Deck=require("src.deck")
local Emblems=UI.SealEmblems
local briefs={blood="Trang bị thêm 2 lần · 3 HP cả tay",anchor="Luôn trên tay khi bắt đầu trận",bounty="Thắng trận · +3 Vàng mỗi lá",
    purifying="Giữ bài · Giáp = 10% HP tối đa",sunder="Xóa Giáp · +10% HP tối đa địch",lantern="Cùng chất giữ lại · +16 Cường hóa",
    echoes="Giữ bài · ×2 Cường hóa mỗi lá",reclaimer="Bỏ bài · +4 Vàng mỗi lá",gambit="Bỏ các lá mang ấn · miễn lượt",threshold="Tính điểm 3 lần · hồi 3 HP / lá"}
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
local function save(canvas,path)
    local data=canvas:newImageData();local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close();data:release()
end
function love.load()
    require("tests.seal_smoke")
    UI.initFonts();UI.CardPhysics.suspend()
    local g=love.graphics
    -- Compare silhouettes with identical enamel, so different colors cannot hide duplicates.
    local hashes={};local stamp=g.newCanvas(64,64)
    for _,id in ipairs(Deck.SEAL_ORDER) do
        local d=Deck.SEALS[id];local color=d.color;d.color={0.4,0.4,0.4,1}
        g.push("all");g.setCanvas(stamp);g.clear(0,0,0,0);Emblems.draw(id,32,32,25);g.pop()
        local data=stamp:newImageData();local key=data:getString();data:release();d.color=color
        assert(not hashes[key],"duplicate silhouette: "..id);hashes[key]=true
    end
    g.push("all");g.setCanvas(stamp);g.clear(0,0,0,0);Emblems.draw("red",32,32,25,0);g.pop()
    local data=stamp:newImageData();local alpha=0
    for y=0,63 do for x=0,63 do local _,_,_,a=data:getPixel(x,y);alpha=alpha+a end end
    assert(alpha==0,"stamp must disappear with card opacity");data:release();stamp:release()
    local canvas=g.newCanvas(1600,1060)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.022,0.032,0.047,1)
    g.setColor(0.94,0.87,0.69,1);g.setFont(UI.fonts.title);g.print("MƯỜI ẤN VIỄN CHINH",35,22)
    g.setColor(UI.COLORS.textMuted);g.setFont(UI.fonts.small);g.print("Biểu tượng khắc nổi riêng · Một lá, một dấu · Lựa chọn theo chiến thuật",37,67)
    for i,id in ipairs(Deck.SEAL_ORDER) do
        local d=Deck.SEALS[id];local x,y=20+(i-1)%5*316,115+math.floor((i-1)/5)*453
        g.setColor(0.038,0.054,0.072,1);g.rectangle("fill",x,y,302,432,8,8)
        g.setColor(d.color);g.setLineWidth(1);g.line(x+17,y+52,x+285,y+52)
        g.setFont(UI.fonts.medium);g.printf(d.name,x+10,y+17,282,"center")
        local card=Deck.newCard(10,"clubs");card.seal=id;card.evolutionLevel=2
        UI.drawCard(card,x+17,y+72,144,216)
        Emblems.draw(id,x+233,y+136,48)
        g.setColor(UI.COLORS.textMuted);g.setFont(UI.fonts.tiny);g.printf("KHẮC NỔI",x+178,y+192,106,"center")
        UI.drawCard(card,x+194,y+225,64,96)
        g.setColor(0.94,0.89,0.77,1);g.setFont(UI.fonts.small);g.printf(briefs[d.symbol],x+14,y+340,274,"center")
        g.setColor(UI.COLORS.textMuted);g.setFont(UI.fonts.tiny)
        local note=(d.symbol=="purifying" or d.symbol=="echoes") and "Chỉ giữ trên tay · Đánh ra không tính" or "Cộng dồn theo các lá mang dấu"
        g.printf(note,x+14,y+390,274,"center")
    end
    g.pop();save(canvas,"docs/seal_emblems_runtime.png");canvas:release()
    UI.CardPhysics.resume()
    print("PASS: 10 distinct monochrome silhouettes, opacity and real card renders at 64 / 144 px")
    love.event.quit(0)
end

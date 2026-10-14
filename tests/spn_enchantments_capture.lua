local UI=require("src.ui")
local E=require("src.spn_enchantments")
local T=require("ui.card_surfaces")
local roles={spell_bastion="PHÒNG THỦ · Đánh từ 2 lá",spell_mend="HỒI PHỤC · Tay nhỏ hồi nhiều hơn",
    spell_prosper="KIẾM VỐN · 9 Vàng mỗi trận",spell_confluence="THÙNG · +75% Cường hóa cuối",
    spell_ladder="SẢNH · +75% ST cuối",spell_balance="MỘT LÁ · +100% Cường hóa cuối",
    spell_retinue="TRANG BỊ · Nhiều loại ITM",spell_switchcraft="ĐỔI THẾ · +50% Cường hóa cuối"}
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
local function save(canvas,path)
    local data=canvas:newImageData();local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close();data:release()
end
function love.load()
    require("tests.spn_enchantments_smoke")
    UI.initFonts();UI.CardPhysics.suspend()
    local g=love.graphics;local canvas=g.newCanvas(1600,1100)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.024,0.032,0.047,1)
    g.setColor(0.96,0.86,0.64,1);g.setFont(UI.fonts.title);g.print("TÁM PHÙ PHÉP SPN",30,20)
    g.setColor(UI.COLORS.textMuted);g.setFont(UI.fonts.small);g.print("Chọn SPN nhận phép · Một SPN, một phù phép · Tăng sức mạnh sau khi SPN kích hoạt",32,65)
    for i,d in ipairs(E.catalog()) do
        local x,y=20+(i-1)%4*395,110+math.floor((i-1)/4)*480
        g.setColor(0.042,0.054,0.075,1);g.rectangle("fill",x,y,380,460,10,10)
        g.setColor(0.9,0.75,0.96,1);g.setFont(UI.fonts.medium);g.printf(d.name:gsub("Phù Phép ",""),x+10,y+15,360,"center")
        T.fullReward(d,x+20,y+64,140,210,"joker_edition",false)
        g.setFont(UI.fonts.small);g.setColor(0.94,0.87,0.73,1);g.printf(roles[d.id],x+180,y+75,175,"left")
        g.setFont(UI.fonts.tiny);g.setColor(0.85,0.87,0.91,1);g.printf(d.desc,x+180,y+136,175,"left")
        g.setColor(0.72,0.79,0.84,1);g.setFont(UI.fonts.small);g.printf("Mua riêng: 4 Vàng",x+15,y+317,350,"center")
        g.setFont(UI.fonts.tiny);g.printf("Giữ tiến hóa và ấn bản · Hủy chọn không mất phép",x+15,y+393,350,"center")
    end
    g.pop();save(canvas,"docs/spn_enchantments_runtime.png");canvas:release()
    local game=require("src.game_state").new()
    game.deities={[1]={id="spirit_ward",name="Băng Vệ",enchantment="spell_bastion"},[3]={id="spirit_blade",name="Kiếm Linh"}}
    game.backpackDeities={{id="spirit_ember",name="Hỏa Linh"}}
    local modal=require("ui.ability_choices")
    assert(E.openTarget(game,E.get("spell_mend"),modal,function() end))
    canvas=g.newCanvas(1280,720);g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.024,0.032,0.047,1)
    modal.draw(UI,-1,-1);g.pop();save(canvas,"docs/spn_enchantments_target.png");canvas:release();modal.key("escape")
    UI.CardPhysics.resume();print("PASS: 8 real Continental spell cards and live SPN selection modal rendered")
    love.event.quit(0)
end

local UI=require("src.ui")
local S=require("src.spectral")
local T=require("ui.card_surfaces")
local Modal=require("ui.ability_choices")
local roles={spec_cryptid="NHÂN BẢN · Lá chủ lực",spec_immolate="LỌC BỘ · Loại lá thừa",
    spec_sigil="THÙNG · Chọn chất",spec_ouija="ĐỒNG RANK · Chọn rank",
    spec_rethread="TÁI TRANG BỊ · Chọn 2 lá",spec_shrink="TAY LỚN · Đổi HP tối đa",
    spec_black_hole="THẾ ĐÁNH · Cả thế nâng cao"}
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
local function save(canvas,path)
    local data=canvas:newImageData();local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close();data:release()
end
function love.load()
    require("tests.spectral_persistence_smoke")
    UI.initFonts();UI.CardPhysics.suspend()
    local g=love.graphics;local canvas=g.newCanvas(1600,1100)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.024,0.032,0.047,1)
    g.setColor(0.96,0.86,0.64,1);g.setFont(UI.fonts.title);g.print("BẢY DỊ THỂ THIẾT YẾU",30,20)
    g.setColor(UI.COLORS.textMuted);g.setFont(UI.fonts.small);g.print("28 → 7 lá · Chọn mục tiêu từ cả bộ bài · Thay đổi vĩnh viễn · Giữ chiến thuật rõ ràng",32,65)
    for i,d in ipairs(S.cards) do
        local x,y=20+(i-1)%4*395,110+math.floor((i-1)/4)*480
        g.setColor(0.042,0.054,0.075,1);g.rectangle("fill",x,y,380,460,10,10)
        g.setColor(0.9,0.75,0.96,1);g.setFont(UI.fonts.medium);g.printf(d.name,x+10,y+15,360,"center")
        T.fullReward(d,x+20,y+64,140,210,"spectral",false)
        g.setFont(UI.fonts.small);g.setColor(0.94,0.87,0.73,1);g.printf(roles[d.id],x+180,y+75,175,"left")
        g.setFont(UI.fonts.tiny);g.setColor(0.85,0.87,0.91,1);g.printf(d.desc,x+180,y+136,175,"left")
        g.setColor(0.72,0.79,0.84,1);g.setFont(UI.fonts.small);g.printf("Mua riêng: "..d.cost.." Vàng",x+15,y+355,350,"center")
        g.setFont(UI.fonts.tiny);g.printf("Chọn rõ mục tiêu · Xác nhận trước khi dùng\nHủy chọn giữ nguyên lá và tài nguyên",x+15,y+393,350,"center")
    end
    g.setColor(0.94,0.87,0.73,1);g.setFont(UI.fonts.medium);g.printf("XÂY BỘ BÀI CÓ CHỦ ĐÍCH",1215,680,350,"center")
    g.setFont(UI.fonts.small);g.setColor(0.85,0.87,0.91,1);g.printf("Nhân lá mạnh. Bỏ lá yếu.\nChọn chất/rank để tạo thế.\nChuyển ITM sang đúng lá.\nĐổi sức bền lấy tay lớn.",1225,745,330,"center")
    g.pop();save(canvas,"docs/spectral_runtime.png");canvas:release()
    local game=require("src.game_state").new();game.persistentDeck={};game.playerHp=80
    local Deck=require("src.deck")
    for r=2,14 do game.persistentDeck[#game.persistentDeck+1]=Deck.newCard(r,"hearts") end
    game.persistentDeck[5].seal="seal_lantern";game.persistentDeck[5].equipments={require("src.equipment").instance("gem_fire")}
    assert(S.openTarget(game,S.get("spec_sigil"),Modal,function() end));Modal.choose(2);Modal.choose(3)
    canvas=g.newCanvas(1280,720);g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.024,0.032,0.047,1)
    Modal.draw(UI,-1,-1);g.pop();save(canvas,"docs/spectral_target.png");canvas:release();Modal.key("escape")
    UI.CardPhysics.resume();print("PASS: 7 Continental Spectrals and live permanent-deck picker rendered")
    love.event.quit(0)
end

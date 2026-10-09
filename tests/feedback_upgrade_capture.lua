local UI=require("src.ui")
local F=require("src.combat_feedback")
local P=UI.Polish
local function save(canvas,path)
    local data=canvas:newImageData();local file=assert(io.open(path,"wb"))
    file:write(data:encode("png"):getString());file:close();data:release()
end
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function love.load()
    require("tests.combat_feedback_smoke")
    UI.initFonts()
    local g=love.graphics
    local canvas=g.newCanvas(1280,1000)
    local function title(text,x,y,w)
        g.setColor(UI.COLORS.textLight);g.setFont(UI.fonts.small);g.printf(text,x,y,w,"center")
    end
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.037,0.05,1)
    title("SÁT THƯƠNG · NĂM CẤP ĐỘ XUNG LỰC",0,18,1280)
    for i,amount in ipairs({25,250,2500,25000,250000}) do
        title(UI.formatNumber(amount),(i-1)*256,52,256)
        for row,age in ipairs({0.13,0.56}) do
            local ft=F.new("damage",amount,640,214,UI.formatNumber);F.update(ft,age)
            g.push("all");g.translate((i-1)*256+128,95+(row-1)*140);g.scale(0.59);g.translate(-640,-214)
            local font,blend=g.getFont(),g.getBlendMode();local r,gg,b,a=g.getColor()
            F.draw(ft,UI)
            assert(font==g.getFont() and blend==g.getBlendMode(),"floating text leaks graphics state")
            local nr,ng,nb,na=g.getColor();assert(r==nr and gg==ng and b==nb and a==na)
            g.pop()
        end
    end
    title("GIÁP TRÊN MÁU · TÍCH LŨY / HẤP THỤ / CẠN GIÁP",0,357,1280)
    for i,values in ipairs({{0,0,100,100},{0,20,100,100},{20,5,100,100},{20,0,100,75}}) do
        local armor=F.updateMeter(F.updateMeter(nil,values[1],0),values[2],0.17)
        local hp=F.updateMeter(F.updateMeter(nil,values[3],0),values[4],0.17)
        g.push("all");g.setScissor((i-1)*320+5,390,310,83);g.translate((i-1)*320-220,394)
        UI.components.TopHUD.draw({hp=values[4],maxHp=100,armor=values[2],gold=80,
            meters={armor=armor,hp=hp}},UI.fonts)
        g.pop()
        title((i==1 and "CHƯA CÓ GIÁP" or i==2 and "+20 GIÁP" or i==3 and "GIÁP ĐỠ 15 ST" or "GIÁP VỀ 0 · HP MẤT 25"),(i-1)*320,466,320)
    end
    title("VÀNG · MUA / BÁN VỚI SỐ DƯ VÀ GIAO DỊCH THẬT",0,522,1280)
    local Game=require("src.game_state");local Deck=require("src.deck");local Shop=require("src.shop")
    local game=Game.new();game.gold=50;game.persistentDeck={Deck.newCard(4,"clubs"),Deck.newCard(8,"hearts")}
    local card=Deck.newCard(10,"spades")
    local rect={x=480,y=220,w=112,h=168}
    local shop=Shop.new();shop.items={{category="card",card=card,cost=7}}
    P.job=nil;P.moneyFeedback={};P.goldMeter=nil;P.goldPosition=P.config.gold;P.ensureShop(shop)
    for i=1,2 do
        if i==1 then P.focusItem(shop.items[1],"stock",1,rect)
        else
            P.update(2,false,"shop",shop)
            game.deities={require("src.deities").CATALOG.spirit_pebble}
            P.focusItem(game.deities[1],"deity",1,rect)
        end
        local before=game.gold
        assert(P.confirm(shop,game),"actual purchase/sale rejected")
        local delta=game.gold-before
        assert((i==1 and delta==-7) or (i==2 and delta>0))
        assert(not P.confirm(shop,game),"repeat confirmation must not charge twice")
        P.update(0.24,false,"shop",shop)
        assert(#P.moneyFeedback==1 and P.goldValue(game.gold)~=before)
        g.push("all");g.setScissor((i-1)*640,562,640,360);g.translate((i-1)*640,562);g.scale(0.5)
        g.setColor(0.05,0.075,0.09,1);g.rectangle("fill",0,0,1280,720)
        UI.drawGildedPanel(14,8,1252,56)
        title("CỬA HÀNG",30,24,220)
        title("VÀNG "..P.goldValue(game.gold),310,24,170)
        UI.drawCard(card,rect.x,rect.y,rect.w,rect.h)
        P.draw(UI,game,{},-1000,-1000)
        g.pop()
        title(i==1 and "MUA −7 VÀNG · XU BAY TỪ VÍ ĐẾN LÁ" or ("BÁN +"..delta.." VÀNG · XU TRỞ VỀ VÍ"),(i-1)*640,939,640)
    end
    P.update(2,false,"shop",shop)
    assert(#P.moneyFeedback==0 and P.goldValue(game.gold)==game.gold)
    g.pop();save(canvas,"docs/combat_feedback/upgrade_gallery.png");canvas:release()
    print("Feedback GPU PASS: five impact tiers, both phases, armor gain/absorption/depletion over HP, real shop purchase/sale, bounded coin tail, exact wallet settle and graphics state")
    love.event.quit(0)
end

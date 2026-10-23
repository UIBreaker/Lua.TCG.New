local S=require("ui.components.shield")
local UI=require("src.ui")
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function love.load()
    UI.initFonts()
    local g=love.graphics;local rng=require("src.rng");local before=rng.getState()
    local canvas=g.newCanvas(960,650)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(.025,.037,.05,1)
    local function title(text,x,y,w)
        g.setFont(UI.fonts.small);g.setColor(.85,.90,.96);g.printf(text,x,y,w,"center")
    end
    title("KHIÊN THÉP · MỘT MẪU CHUNG CHO TOÀN BỘ GIAO DIỆN",0,18,960)
    for i,size in ipairs({12,16,25,39,74,110}) do
        S.draw(80+(i-1)*160,115,size,{.24,.90,1},1)
        title(size.." px",i*160-160,181,160)
    end
    require("ui.components.progress_bar").draw(65,235,235,20,20,30,{shield=true,label="GIÁP 20",font=UI.fonts.small})
    require("ui.components.progress_bar").draw(330,235,235,20,40,100,{shield=true,label="GIÁP ĐỊCH 40",font=UI.fonts.small})
    title("NỬA KHIÊN / VỠ / GIÁP NHỎ TRONG CHỮ",600,230,340)
    S.draw(635,302,64,{.12,1,.65},1,{partial=true})
    S.draw(725,302,64,{1,.25,.19},1,{broken=true,split=16,tilt=.18})
    g.setFont(UI.fonts.small);g.setColor(.7,.94,1)
    S.printf("🛡️ +20 Giáp\n🛡 Đỡ đòn · tiếng Việt",785,282,165,"left")
    -- Both emoji spellings, wrapping and alignment must render without leaking state.
    local polygon=g.polygon;local draws=0
    g.polygon=function(...) draws=draws+1;return polygon(...) end
    for index,align in ipairs({"left","center","right"}) do
        g.setBlendMode("add");g.setColor(.7,.9,1,.8);g.setLineWidth(3)
        g.setScissor(10,10,940,630)
        local bx,by=g.transformPoint(0,0);local font=g.getFont()
        S.printf("🛡️ GIÁP +20  🛡 CHẶN ĐÒN",10+(index-1)*310,360,180,align)
        local blend=g.getBlendMode();local r,green,b,a=g.getColor();local ax,ay=g.transformPoint(0,0)
        local sx,sy,sw,sh=g.getScissor()
        assert(blend=="add" and g.getLineWidth()==3 and font==g.getFont())
        assert(math.abs(r-.7)<.001 and math.abs(green-.9)<.001 and b==1 and math.abs(a-.8)<.001)
        assert(ax==bx and ay==by and sx==10 and sy==10 and sw==940 and sh==630)
    end
    assert(draws>0,"shield emoji must draw the shared native shield")
    local count=draws
    S.printf("🛡️ GIÁP +20",-1000,-1000,180,"left",true)
    S.draw(0,0,0);S.draw(0,0,74,nil,0)
    assert(draws==count,"shadow passes and hidden icons cannot add ghost shields")
    g.polygon=polygon;g.setScissor();g.setBlendMode("alpha")
    -- Exercise real action and potion renderers, not just the reusable component.
    local F=require("src.combat_feedback");F.clearVfx()
    for i,kind in ipairs({"armor_gain","armor_loss"}) do
        local e=F.emit(kind,95+(i-1)*130,490,20,nil,true);e.age=.14
    end
    F.drawVfx(UI);title("TĂNG / MẤT GIÁP",10,545,270)
    local P=require("ui.potion_effects");P.active={}
    for i,kind in ipairs({"armor","armor_break"}) do
        P.active[i]={kind=kind,x=420+(i-1)*270,y=515,age=.55,life=1.9,contactAt=0,
            reduced=true,reactive=true,anchors={},particles={},label=kind=="armor" and "THUỐC GIÁP" or "PHÁ GIÁP"}
    end
    P.draw(UI,{},"shop");P.active={};F.clearVfx()
    assert(rng.getState()==before,"shield rendering cannot change gameplay RNG")
    g.pop()
    local data=canvas:newImageData();local f=assert(io.open("docs/shield_style_gallery.png","wb"))
    f:write(data:encode("png"):getString());f:close()
    print("Steel shield PASS: six icon sizes, partial/broken variants, UTF-8 inline icons, wrapped alignment, hidden shadow passes, graphics state, armor/potion integration and RNG isolation")
    love.event.quit(0)
end

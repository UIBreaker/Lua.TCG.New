local T={}
function T.verify()
    local UI,E,D=require("src.ui"),require("src.equipment"),require("src.deck")
    local F,V,Rng=UI.CardFrame,require("config.visual_config"),require("src.rng")
    local g=love.graphics
    local oldTime,oldReduced,quality,enabled=UI.Polish.time,UI.Polish.reducedMotion,V.quality,V.enabled
    local rng=Rng.getState()
    local function equipment(tier,slots)
        local item={};for k,v in pairs(E.ITEMS.basic_plate) do item[k]=v end
        item.craftTier=tier;item.slotsNeeded=slots or 1;return item
    end
    for _,w in ipairs({46,82,200}) do
        local h=math.floor(w*1.5);local canvas=g.newCanvas(w+20,h+20)
        local function render(card,time,reduced,alpha)
            g.push("all");g.setCanvas(canvas);g.origin();g.clear(0,0,0,0);g.translate(10,10)
            g.setColor(.2,.3,.4,.7);g.setLineWidth(2.5)
            local xx,yy=g.transformPoint(1,2)
            F.drawSockets(0,0,w,h,card,alpha or 1,time,reduced)
            local r,b,c,a=g.getColor();local tx,ty=g.transformPoint(1,2)
            assert(math.abs(r-.2)+math.abs(b-.3)+math.abs(c-.4)+math.abs(a-.7)<.001
                and g.getLineWidth()==2.5 and xx==tx and yy==ty,"sockets leak graphics state")
            g.pop();return canvas:newImageData()
        end
        for tier=1,8 do
            local card=D.newCard(10,"clubs");card.maxSockets=8;card.equipments={equipment(tier,2),equipment(tier)}
            local a,b=render(card,.2,false),render(card,1.9,false)
            assert(a:getString()~=b:getString(),"equipped jewels must breathe or orbit")
            for y=0,h+19 do for x=0,w+19 do
                local r,b,c,alpha=a:getPixel(x,y)
                if math.max(r,b,c,alpha)>.005 then assert(x>=10 and x<w+10 and y>=10 and y<h+10,
                    string.format("socket light spills off card: T%d / %dpx / (%d,%d)",tier,w,x,y)) end
            end end
            a:release();b:release()
            a,b=render(card,.2,true),render(card,1.9,true)
            assert(a:getString()==b:getString(),"Reduced Motion animates jewels")
            a:release();b:release()
            card.faceDown=true;a=render(card,0,false);card.faceDown=nil;b=render(card,0,false,0)
            assert(a:getString()==b:getString(),"hidden sockets leave light")
            a:release();b:release()
        end
        local card=D.newCard(10,"clubs");card.equipments={equipment(8)}
        V.quality="LOW"
        local a,b=render(card,.2,false),render(card,1.9,false)
        assert(a:getString()~=b:getString(),"LOW must keep high-tier jewel motion")
        a:release();b:release();V.quality=quality
        V.enabled=false;a,b=render(card,.2,false),render(card,1.9,false)
        assert(a:getString()==b:getString(),"disabled effects animate sockets")
        a:release();b:release();V.enabled=enabled
        card.equipments={};a,b=render(card,.2,false),render(card,1.9,false)
        assert(a:getString()==b:getString(),"empty sockets must remain unlit and static")
        a:release();b:release();canvas:release()
    end
    local attached=D.newCard(10,"hearts");attached.maxSockets=8;attached.equipments={equipment(8,2)}
    local original=F.socketGem;local drawn=0
    F.socketGem=function(cx,cy,...)
        local state=assert(UI.CardPhysics.getState(attached))
        local x,y=g.transformPoint(cx,cy)
        assert(math.abs(x-(state.ox+state.a*cx+state.c*cy))+math.abs(y-(state.oy+state.b*cx+state.d*cy))<.001,
            "sockets detach from moving card")
        drawn=drawn+1;return original(cx,cy,...)
    end
    UI.CardPhysics.update(1/60,300,150);UI.CardPhysics.beginFrame(true)
    UI.drawCard(attached,200,100,128,192);UI.CardPhysics.endFrame();F.socketGem=original
    assert(drawn==8,"every open socket must render once, above metadata")
    local cards={}
    for tier=1,8 do
        local card=D.newCard(10,({"hearts","diamonds","clubs","spades"})[(tier-1)%4+1])
        card.evolutionLevel=tier-1;card.maxSockets=8
        card.equipments={equipment(tier,2),equipment(tier),equipment(tier),equipment(tier),equipment(tier)}
        cards[tier]=card
    end
    local canvas=g.newCanvas(1280,1020)
    local function sheet(time)
        UI.Polish.time=time;UI.Polish.reducedMotion=false
        g.push("all");g.setCanvas(canvas);g.origin();g.clear(.015,.023,.038,1)
        g.setFont(UI.fonts.title);g.setColor(.96,.85,.60,1);g.print("HỐC TRANG BỊ · BẢO THẠCH THỨC TỈNH",32,22)
        g.setFont(UI.fonts.small);g.setColor(.68,.75,.83,1)
        g.print("Ổ KIM LOẠI · NGỌC KHẢM · QUỸ ĐẠO · BÙNG SÁNG THEO BẬC TRANG BỊ",34,62)
        UI.CardPhysics.suspend()
        for tier,card in ipairs(cards) do
            local x,y=32+(tier-1)%4*312,110+math.floor((tier-1)/4)*440
            UI.drawCard(card,x,y,170,255)
            local rarity=require("src.deities").RARITIES[tier]
            g.setFont(UI.fonts.medium);g.setColor(rarity.color);g.print(rarity.code,x+190,y+6)
            F.socketGem(x+225,y+100,22,E.getTierColor(card.equipments[1]),1,0,false,tier,time,false,tier)
            F.socketGem(x+200,y+183,9,nil,1,0,false,1,time,false,tier)
            F.socketGem(x+249,y+183,9,E.getTierColor(card.equipments[1]),1,0,true,tier,time,false,tier)
            g.setFont(UI.fonts.tiny);g.setColor(.75,.81,.88,1)
            g.print("Trống",x+183,y+204);g.print("Liên kết",x+226,y+204)
            g.setFont(UI.fonts.small);g.setColor(rarity.color);g.print(rarity.name,x,y+270)
            g.setColor(.8,.85,.9,1);g.print("6 / 8 hốc · T"..tier,x,y+296)
        end
        UI.CardPhysics.resume();g.pop()
    end
    local function save(path)
        local data=canvas:newImageData();local f=assert(io.open(path,"wb"))
        f:write(data:encode("png"):getString());f:close();data:release()
    end
    sheet(1.3);save("docs/equipment_socket_jewels.png")
    local video=os.getenv("POKER_SOCKET_VIDEO")
    if video then for i=0,95 do sheet(i/24);save(video..string.format("/frame_%03d.png",i)) end end
    UI.Polish.time=oldTime;UI.Polish.reducedMotion=oldReduced;canvas:release()
    assert(Rng.getState()==rng,"socket presentation consumed gameplay RNG")
    print("Socket jewels PASS: 8 equipment tiers/3 sizes, bounded light, LOW/Reduced/off/fade/backs/empty, graphics state, single attached pass, no gameplay RNG")
end
return T

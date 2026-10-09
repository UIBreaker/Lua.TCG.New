local UI=require("src.ui")
local E=require("src.equipment")
local D=require("src.deck")
local Frame=UI.CardFrame
local function save(canvas,path)
    local data=canvas:newImageData();local f=assert(io.open(path,"wb"))
    f:write(data:encode("png"):getString());f:close();data:release()
end
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function love.load()
    require("tests.equipment_sockets_smoke")
    UI.initFonts()
    local g=love.graphics
    local cards={}
    local items={"basic_plate","crafted_guard","crafted_bulwark","crafted_courier","itm_surveyhammer","itm_fieldneedle","basic_bandage","basic_stamp"}
    for i,slots in ipairs({4,4,6,8}) do
        local card=D.newCard(10,"clubs");card.maxSockets=slots;card.unlockedSockets=slots;card.evolutionLevel=4
        if i>1 then for index=1,(i==2 and 2 or i==3 and 4 or 8) do assert(E.attach(card,E.ITEMS[items[index]])) end end
        cards[i]=card
    end
    -- Only unlocked sockets render, including empty mounts; no side sockets at baseline.
    for _,card in ipairs(cards) do
        local c=g.newCanvas(200,300)
        g.push("all");g.setCanvas(c);g.origin();g.clear(0,0,0,0);Frame.drawSockets(0,0,200,300,card,1);g.pop()
        local data=c:newImageData()
        for index=1,8 do
            local x,y=Frame.socketPosition(index,200,300)
            local _,_,_,alpha=data:getPixel(math.floor(x),math.floor(y))
            assert((alpha>0)==(index<=E.getMaxSlots(card)),"locked side sockets must stay invisible")
        end
        data:release();c:release()
    end
    local canvas=g.newCanvas(1320,960)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.037,0.05,1)
    UI.CardPhysics.suspend()
    for i,card in ipairs(cards) do
        local x=20+(i-1)*220
        UI.drawCard(card,x,32,170,255)
        g.setColor(UI.COLORS.textLight);g.setFont(UI.fonts.small)
        g.printf((i==1 and "4 HỐC TRỐNG" or (E.getUsedSlots(card).." / "..E.getMaxSlots(card).." HỐC")),x,302,170,"center")
    end
    require("ui.components.equipment_panel").draw(UI,cards[4],20,365,820,445)
    local title,body=require("src.card_description").resolve(cards[4])
    local View=require("ui.components.card_description")
    local model=View.model(cards[4],title,body)
    local layout=View.layout(model,UI.fonts)
    assert(layout.maxScroll>0,"eight equipment rows must remain scrollable at readable font size")
    local rows=0;for _,row in ipairs(model.rows) do if row.kind=="equipment" then rows=rows+1 end end
    assert(rows==8,"equipment details must retain every installed item")
    View.draw(model,layout,920,32,0)
    View.draw(model,layout,920,480,layout.maxScroll)
    UI.CardPhysics.resume();g.pop()
    save(canvas,"docs/equipment_socket_frames.png");canvas:release()
    local pair={D.newCard(10,"clubs"),D.newCard(10,"spades")}
    for _,card in ipairs(pair) do assert(E.attach(card,E.ITEMS.basic_plate)) end
    local info=require("src.poker").evaluate(pair,{pair=true,high_card=true})
    local result=require("src.scoring").calculate(info,{}, {preview=true})
    local anim={playedCards=pair,cardBounce={},cardHit={},deityBounce={},scoredCards={},
        bounceScale={chips=1,mult=1,score=1},floatingTexts={}}
    local Feel=require("src.scoring_presentation")
    Feel.start(anim,result,UI,{},1000)
    local found=false
    for _=1,600 do
        require("src.card_effects").update(1/60)
        Feel.update(anim,1/60,false)
        local event=anim.sequence.events[anim.sequence.index]
        if event and event.source and event.source.type=="equipment_trigger" and event.source.card==pair[2]
            and anim.sequence.entered and anim.sequence.age>0.025 then found=true;break end
    end
    assert(found and result.addArmor==4,"both owners must receive their own equipment animation and +4 total armor")
    assert(require("src.card_effects").getEquipmentPulse(pair[2],1)>0)
    local popups=0
    for _,link in ipairs(anim.sequence.links) do if link.text=="+2 GIÁP" then popups=popups+1 end end
    assert(popups==2,"two equipment contributions must remain separate above their source cards")
    canvas=g.newCanvas(1280,480)
    g.push("all");g.setCanvas(canvas);g.origin();g.clear(0.025,0.037,0.05,1)
    UI.CardPhysics.suspend()
    g.setColor(UI.COLORS.goldYellow);g.setFont(UI.fonts.medium)
    g.printf("MỖI LÁ KÍCH HOẠT TRANG BỊ RIÊNG",0,50,1280,"center")
    for i,card in ipairs(pair) do UI.drawCard(card,UI.getScoringCardX(i,2),285,96,144) end
    Feel.draw(anim,UI)
    g.setColor(UI.COLORS.chipsBlue);g.setFont(UI.fonts.medium)
    g.printf("TỔNG NHẬN +4 GIÁP",0,444,1280,"center")
    UI.CardPhysics.resume();g.pop()
    save(canvas,"docs/equipment_scoring_stack.png");canvas:release()
    print("Equipment socket render PASS: four corner mounts, expanded side mounts, 8 detailed items, readable scrolling, linked frame transforms")
    love.event.quit(0)
end

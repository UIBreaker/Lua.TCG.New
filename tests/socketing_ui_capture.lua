-- lovec.exe . --capture-shop --capture-socketing-ui
local T={step=0,deadline=0}
local UI=require("src.ui")
local S=require("ui.socketing")
local E=require("src.equipment")
local Deck=require("src.deck")
local function pointer(x,y,click)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
    love.mouse.setPosition(px,py)
    if click then love.mousepressed(px,py,1);love.mousereleased(px,py,1) end
end
local function button(cb,id,click)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then
        assert(b.x>=0 and b.y>=0 and b.x+b.w<=1280 and b.y+b.h<=720)
        if click then assert(not b.disabled,id);pointer(b.x+b.w/2,b.y+b.h/2,true) end
        return b
    end end
    error("Missing button "..id)
end
local function shot(name)
    pointer(5,5);UI.Description.reset()
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/socketing_ui_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    local now=love.timer.getTime();if now<T.deadline then return end
    local n=T.step
    if n==0 then
        cb.startNewGame("red_deck");game.persistentDeck={}
        for i=1,7 do game.persistentDeck[i]=Deck.newCard(i+3,i==7 and "spades" or "hearts") end
        T.eq=E.ITEMS.basic_plate
        game.persistentDeck[1].equipments={T.eq}
        game.persistentDeck[3].equipments={E.ITEMS.basic_chain,E.ITEMS.basic_feather,E.ITEMS.basic_stamp,E.ITEMS.basic_lace}
        cb.openSocketing(T.eq,"shop")
    elseif n==1 then
        assert(button(cb,"socket_prev").disabled and button(cb,"socket_next").disabled)
        shot("overview")
    elseif n==2 then
        local x,y,w,h=S.cardRect(1);pointer(x+w/2,y+h/2,true)
        assert(#game.persistentDeck[1].equipments==1 and select(2,cb.getRunState())=="socketing","duplicate denied without leaving picker")
    elseif n==3 then
        shot("blocked")
        for i=8,15 do game.persistentDeck[i]=Deck.newCard(i%12+2,"clubs") end
    elseif n==4 then button(cb,"socket_next",true)
    elseif n==5 then
        assert(button(cb,"socket_next").disabled and not button(cb,"socket_prev").disabled)
        button(cb,"socket_prev",true)
    elseif n==6 then
        love.window.setMode(960,540,{resizable=true});love.resize(960,540)
    elseif n==7 then shot("960")
    elseif n==8 then
        local x,y,w,h=S.cardRect(2);pointer(x+w/2,y+h/2,true)
        assert(#game.persistentDeck[2].equipments==1,"real attach follows rendered card")
        assert(select(2,cb.getRunState())=="socketing","target retained during attachment flight")
        local app=assert(UI.Polish.applications[1]);assert(app.source.x==S.equipmentRect.x and app.source.y==S.equipmentRect.y,"flight starts at equipment portrait")
        pointer(x+w/2,y+h/2,true)
        assert(#game.persistentDeck[2].equipments==1,"repeated input during flight does not attach twice")
        T.deadline=now+1.8;T.step=n+1;return
    elseif n==9 then
        assert(select(2,cb.getRunState())=="shop" and #game.persistentDeck[2].equipments==1,"attach completes exactly once")
        cb.openSocketing(T.eq,"shop")
    elseif n==10 then button(cb,"skip_socket",true)
    elseif n==11 then
        assert(select(2,cb.getRunState())=="shop","skip returns to shop")
        print("SOCKETING UI PASS: eligible/duplicate/full slots, page navigation, 960 input, real attachment/source/docking, skip")
        love.event.quit(0);return
    end
    T.step=n+1;T.deadline=now+.7
end
return T

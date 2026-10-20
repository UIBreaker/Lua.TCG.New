-- lovec.exe . --capture-shop --capture-deck-viewer (isolated player saves)
local T = {stage=0, deadline=0}
local Viewer = require("ui.deck_viewer")
local Deck = require("src.deck")
local function pointer(x,y,click)
    local w,h=love.graphics.getDimensions()
    local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if click then love.mousepressed(px,py,1);love.mousereleased(px,py,1) end
end
local function button(cb,id,click)
    for _,b in ipairs(cb.getButtons()) do
        if b.id==id then
            if click then assert(not b.disabled,id);pointer(b.x+b.w/2,b.y+b.h/2,true) end
            return b
        end
    end
    error("Missing button "..id)
end
local function shot(name)
    pointer(5,5)
    require("src.ui").Description.reset()
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/deck_viewer_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if now<T.deadline then return end
    local n=T.stage
    if n==0 then
        cb.startNewGame("red_deck");cb.openShop()
        game.persistentDeck={}
        for i=1,9 do game.persistentDeck[i]=Deck.newCard(i+1,i%2==0 and "clubs" or "diamonds") end
        game.handLevels.pair=3
        game.unlockedHands={high_card=true,pair=true,two_pair=true,three_of_a_kind=true,four_of_a_kind=true}
        cb.openDeckViewer()
        for i=1,Viewer.pageSize do
            local x,y,w,h=Viewer.cardRect(i,50,35)
            assert(x>=68 and x+w<=752 and y>=179 and y+h<=643,"grid bounds")
        end
        local a,b,c={rank=7,suit="a"},{rank=12,suit="b"},{rank=7,suit="a"}
        local sorted=Viewer.sortCards({a,b,c})
        assert(sorted[1]==b and sorted[2]==a and sorted[3]==c,"stable rank sort")
    elseif n==1 then
        assert(button(cb,"deck_page_next").disabled)
        if not T.overview then shot("overview");T.overview=true;T.deadline=now+.3;return end
        button(cb,"deck_sort",true);assert(Viewer.sort=="suit")
    elseif n==2 then
        -- Empty spade filter, then restore all cards.
        pointer(50+24+3*114+54,35+129,true)
    elseif n==3 then
        assert(button(cb,"deck_page_next").disabled)
        if not T.empty then shot("empty");T.empty=true;T.deadline=now+.3;return end
        pointer(128,164,true)
        game.persistentDeck={}
        for _,suit in ipairs({"diamonds","clubs","spades","hearts"}) do
            for rank=2,14 do table.insert(game.persistentDeck,Deck.newCard(rank,suit)) end
        end
    elseif n==4 then
        assert(not button(cb,"deck_page_next").disabled)
        button(cb,"deck_page_next",true)
    elseif n==5 then
        assert(not button(cb,"deck_page_prev").disabled)
        pointer(300,400);love.wheelmoved(0,1)
    elseif n==6 then
        assert(button(cb,"deck_page_prev").disabled,"wheel returns to page one")
        local cards=Viewer.sortCards({unpack(game.persistentDeck)})
        T.expected=cards[1]
        local x,y,w,h=Viewer.cardRect(1,50,35)
        pointer(x+w/2,y+h/2,true)
    elseif n==7 then
        assert(cb.getInspector()==T.expected,"hit area follows sorted card grid")
        cb.closeInspector()
        love.window.setMode(960,540,{resizable=true});love.resize(960,540)
    elseif n==8 then
        if not T.small then shot("960");T.small=true;T.deadline=now+.3;return end
        button(cb,"deck_sort",true)
        assert(Viewer.sort=="rank")
    elseif n==9 then
        game.shopMode="cards"
    elseif n==10 then
        local x,y,w,h=Viewer.cardRect(1,50,35)
        pointer(x+w/2,y+h/2,true)
    elseif n==11 then
        local P=require("src.ui").Polish
        assert(P.focus and P.focus.kind=="card_sale","sale selection retained")
        P.clearFocus();game.soulDestroyActive=true
    elseif n==12 then
        local x,y,w,h=Viewer.cardRect(1,50,35)
        pointer(x+w/2,y+h/2,true)
    elseif n==13 then
        local P=require("src.ui").Polish
        assert(P.focus and P.focus.kind=="card","destruction selection retained")
        cb.closeDeckViewer()
        print("DECK VIEWER PASS: stable sorting, grid bounds, filters, pagination, wheel, inspector, sale/destruction selection and 960 input")
        love.event.quit(0);return
    end
    T.stage=n+1;T.deadline=now+.7
end
return T

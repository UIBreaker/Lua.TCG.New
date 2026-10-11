local Poker=require("src.poker")
local E=require("ui.handbook_examples")
for _,hand in ipairs(Poker.ALL_HANDS_ORDERED) do
    local cards,scored=E.get(hand.id)
    local count=0
    for _,card in ipairs(cards) do if scored[card] then count=count+1 end end
    assert(count==(hand.condition and 5 or hand.id=="straight" and 5 or hand.requiredCards),hand.id)
    assert(#cards==5)
end
local H=require("ui.advanced_handbook")
H.click("handbook_advanced");H.click("handbook_select_fibonacci")
H.click("handbook_basic");assert(H.page==0 and H.selected==nil)
H.click("handbook_advanced");assert(H.page==1 and H.selected==nil)
H.click("handbook_next");assert(H.page==2)
H.click("handbook_prev");assert(H.page==1)
H.click("handbook_basic")
H.click("handbook_prev");assert(H.page==0 and H.basicPage==1)
H.click("handbook_next");assert(H.page==0 and H.basicPage==2)
H.click("handbook_next");assert(H.page==0 and H.basicPage==2)
H.click("handbook_prev");assert(H.page==0 and H.basicPage==1)
local originalLove=love
local noop=function() end
local graphics=setmetatable({},{__index=function() return noop end})
love={graphics=graphics,timer={getTime=function() return 1 end}}
local UI={fonts={},COLORS=setmetatable({},{__index=function() return {1,1,1,1} end}),
    drawGildedPanel=noop,drawButton=noop,getHandImage=function() end,
    getCardImage=function() end,CardFrame={image=noop,draw=noop}}
local game={unlockedHands={},handLevels={}}
for group,list in ipairs({Poker.HAND_TYPES_ORDERED,Poker.ADVANCED_HANDS_ORDERED}) do
    for index,hand in ipairs(list) do
        H.page=group==1 and 0 or math.floor((index-1)/6)+1
        H.basicPage=math.floor((index-1)/5)+1
        H.selected=nil
        local row=group==1 and (index-1)%5 or (index-1)%6
        local buttons={}
        H.draw(game,UI,buttons,30,142+row*(group==1 and 104 or 87)+20,0,0,1280,720)
        assert(H.preview==hand.id and H.selected==nil,"hover "..hand.id)
        assert(#buttons==(group==1 and (index<=5 and 7 or 6) or 8))
        if group==1 then
            local first=index<=5 and 1 or 6
            local count=index<=5 and 5 or 4
            for i=1,count do assert(buttons[i].id=="handbook_select_"..list[first+i-1].id) end
            assert(buttons[count+1].disabled==(H.basicPage==1))
            assert(buttons[count+2].disabled==(H.basicPage==2))
        end
        H.click("handbook_select_"..hand.id)
        H.draw(game,UI,{},-100,-100,0,0,1280,720)
        assert(H.preview==hand.id and H.selected==hand.id,"pin "..hand.id)
    end
end
love=originalLove
H.click("handbook_basic")
print("Handbook: all 27 examples, hover/pin, locked previews and tab/page selection passed")

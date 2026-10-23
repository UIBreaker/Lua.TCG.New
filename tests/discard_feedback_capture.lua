local T={stage=0,at=0}
local UI=require("src.ui")
local Deck=require("src.deck")
local Fx=require("ui.potion_effects")
local function shot(path)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if T.stage==0 then
        require("tests.discard_feedback_smoke")
        local D=require("ui.discard_effects");local pose=D.cardPose
        local drawReceipt,drawTags=D.drawReceipt,D.draw
        T.receiptDraws=0;T.tagDraws=0
        D.drawReceipt=function(ui,event,slot)
            local result=drawReceipt(ui,event,slot)
            if result then
                T.receiptDraws=T.receiptDraws+1;T.lastReceipt=result
                T.firstReceipt=T.firstReceipt or result
                assert(result.x==T.firstReceipt.x and result.y==T.firstReceipt.y,"notification anchor is stable")
                assert(result.x>=slot.x and result.y>=slot.y and result.x+result.w<=slot.x+slot.w+.001 and result.y+result.h<=slot.y+slot.h+.001)
            end
            return result
        end
        D.draw=function(...) T.tagDraws=T.tagDraws+1;return drawTags(...) end
        T.lifted={}
        D.cardPose=function(card,...)
            local x,y,angle=pose(card,...)
            T.poseCalls=(T.poseCalls or 0)+1
            if y<-.5 then T.lifted[card]=true end
            return x,y,angle
        end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setGameSpeed(1)
        cb.setReducedMotion(false)
        game.hand={};game.deck={};game.deities={};game.consumables={};game.selectedIndices={}
        game.playerHp=80;game.maxPlayerHp=200;game.gold=5;game.playerArmor=0;game.playerShield=0
        game.maxHandSize=8;game.unlockedHands={high_card=true,flush=true};game.discardsRemaining=3;game.potionFeedback={}
        for i,suit in ipairs({"hearts","diamonds","clubs","spades"}) do
            local c=Deck.newCard(i+3,suit);c.evolutionLevel=3;game.hand[i]=c
            game.hand[i+4]=Deck.newCard(8,suit)
        end
        game.persistentDeck={};for _,c in ipairs(game.hand) do game.persistentDeck[#game.persistentDeck+1]=Deck.cloneCard(c) end
        Fx.active={};T.stage=1;T.at=now
    elseif T.stage==1 and now-T.at>.9 then
        for i=1,4 do cb.selectCardIndex(i) end
        love.keypressed("d")
        T.stage=2;T.at=now;T.frameAt=now;T.frames=0
    elseif T.stage==2 then
        local receipt;for _,v in ipairs(Fx.active) do if v.kind=="discard" then receipt=v end end
        if receipt and receipt.age>=T.frames*.06+.03 and T.frames<16 then
            T.frames=T.frames+1;T.frameAt=now
            shot(string.format("docs/discard_buff_frame_%02d.png",T.frames))
        end
        if receipt and receipt.age>.27 and not T.checked then
        local e;for _,v in ipairs(Fx.active) do if v.kind=="discard" then e=v end end
        assert(e and e.count==4 and e.heal==8 and e.gold==4 and e.speed==2 and e.empowerment==4,
            "discard receipt: "..tostring(e and e.count).."/"..tostring(e and e.heal).."/"..tostring(e and e.gold).."/"..tostring(e and e.speed).."/"..tostring(e and e.empowerment).." held="..#game.hand.." selected="..#game.selectedIndices)
        assert(#game.hand==4 and game.playerHp==88 and game.gold==9)
        assert(T.lastReceipt,"receipt is drawn by the sidebar")
        for _,target in ipairs(e.targets) do assert(T.lifted[target.card],"the real hand renderer lifts every buffed card: calls="..tostring(T.poseCalls).." age="..e.age.." reduced="..tostring(e.reduced)) end
        local g=love.graphics;local blend,alpha=g.getBlendMode();local width=g.getLineWidth()
        local rng=require("src.rng");local before=rng.getState()
        Fx.draw(UI,game,"playing")
        local b,a=g.getBlendMode();assert(b==blend and a==alpha and g.getLineWidth()==width and rng.getState()==before)
        shot("docs/discard_feedback.png");T.checked=true
        end
        if receipt and receipt.age>1.1 and T.frames==16 then T.stage=3;T.at=now end
    elseif T.stage==3 and now-T.at>3.2 then
        cb.setReducedMotion(true)
        local c=Deck.newCard(4,"hearts");c.evolutionLevel=3;game.playerHp=game.maxPlayerHp
        require("src.card_abilities").discard(game,{c},{playerDiscard=true})
        T.stage=4;T.at=now
    elseif T.stage==4 and now-T.at>.25 then
        for _,card in ipairs(game.hand) do
            local x,y,a=require("ui.discard_effects").cardPose(card,true)
            assert(x==0 and y==0 and a==0,"reduced motion disables the real card wobble")
        end
        shot("docs/discard_feedback_reduced.png");T.stage=5;T.at=now
    elseif T.stage==5 and now-T.at>.2 then
        game.enemies={game.monster,require("src.monster").create(2,false,false,2)}
        for i,m in ipairs(game.enemies) do m.group=game.enemies;m.groupIndex=i end
        local discarded={}
        for i,suit in ipairs({"hearts","diamonds","clubs","spades"}) do
            discarded[i]=Deck.newCard(4,suit);discarded[i].evolutionLevel=3
        end
        require("src.card_abilities").discard(game,discarded,{playerDiscard=true})
        T.stage=6;T.at=now
    elseif T.stage==6 and now-T.at>.35 then
        shot("docs/discard_feedback_squad.png");T.stage=7;T.at=now
    elseif T.stage==7 and now-T.at>.2 then
        cb.selectCardIndex(1);T.selectionDraws=T.receiptDraws;T.stage=8;T.at=now
    elseif T.stage==8 and now-T.at>.25 then
        assert(not require("ui.discard_effects").receipt(game,"playing") and T.receiptDraws==T.selectionDraws,"selection restores preview without receipt overlap")
        shot("docs/discard_feedback_selected.png")
        T.stage=8.5;T.at=now
    elseif T.stage==8.5 and now-T.at>.15 then
        cb.selectCardIndex(1);cb.openDeckViewer();T.overlayTags=T.tagDraws;T.stage=9;T.at=now
    elseif T.stage==9 and now-T.at>.25 then
        assert(T.tagDraws==T.overlayTags,"card feedback stays below the deck viewer")
        cb.closeDeckViewer();T.resizeIndex=1;T.stage=10;T.at=now
    elseif T.stage==10 and now-T.at>.2 then
        local sizes={{960,600},{1280,720},{1920,1080}};local size=sizes[T.resizeIndex]
        if not size then
            T.stage=13
            print("Discard UI PASS: fixed sidebar slot; one/two enemies; selection and deck viewer; 960x600, 1280x720, 1920x1080; motion and graphics/RNG isolation")
            love.event.quit(0);return
        end
        love.window.setMode(size[1],size[2],{resizable=true,vsync=0})
        love.resize(size[1],size[2])
        T.size=size
        local discarded={}
        for i,suit in ipairs({"hearts","diamonds","clubs","spades"}) do discarded[i]=Deck.newCard(4,suit) end
        require("src.card_abilities").discard(game,discarded,{playerDiscard=true})
        T.stage=11;T.at=now
    elseif T.stage==11 and now-T.at>.35 then
        assert(T.lastReceipt.x==T.firstReceipt.x and T.lastReceipt.y==T.firstReceipt.y,"resize keeps logical anchor")
        shot("docs/discard_feedback_"..T.size[1].."x"..T.size[2]..".png")
        T.stage=12;T.at=now
    elseif T.stage==12 and now-T.at>.2 then
        T.resizeIndex=T.resizeIndex+1;T.stage=10;T.at=now
    end
    assert(T.stage==0 or now-T.at<8,"discard capture timeout")
end
return T

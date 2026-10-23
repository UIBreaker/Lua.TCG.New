local T={step=0}
local function button(cb,id,cardId,delta)
    for _,b in ipairs(cb.getButtons()) do if b.id==id and (not cardId or b.cardId==cardId) and (not delta or b.delta==delta) then return b end end
end
local function click(b)
    assert(b and not b.disabled,"Missing camp control at step "..T.step)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x=(w-1280*s)/2+(b.x+b.w/2)*s;local y=(h-720*s)/2+(b.y+b.h/2)*s
    love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/training_camp_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function open(game,cb)
    cb.startNewGame("red_deck");local Run=require("src.run_manager")
    game.run.ante=3;game.run.areaStage=3;game.run.currentBlindIndex=3
    game.run.blinds=Run.generateAnteBlinds(3,nil,"human",3);game.run.blinds[3].status="completed"
    game.pendingAncientStatue=nil;game.pendingBarter=nil;game.pendingMemoryMatch=nil
    game.playerHp=20;game.maxPlayerHp=100
    -- Exercise pagination even when the chosen starting deck contains few cards.
    game.persistentDeck={};for i=1,12 do game.persistentDeck[i]=require("src.deck").newCard(i+1,"hearts") end
    cb.openTrainingCamp()
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime();if T.next and now<T.next then return end
    if T.step==0 then require("tests.training_camp_smoke");open(game,cb);T.next=now+1.5
    elseif T.step==1 then assert(select(2,cb.getRunState())=="training_camp");shot("choice")
    elseif T.step==2 then click(button(cb,"camp_train"))
    elseif T.step==3 then shot("selection")
    elseif T.step==4 then click(button(cb,"camp_card",game.persistentDeck[1].id))
    elseif T.step==5 then click(button(cb,"camp_page",nil,1))
    elseif T.step==6 then click(button(cb,"camp_card",game.persistentDeck[9].id))
    elseif T.step==7 then click(button(cb,"camp_card",game.persistentDeck[10].id))
    elseif T.step==8 then assert(#game.trainingCamp.selected==3);shot("selected")
    elseif T.step==9 then
        local R=require("src.rng");local random=R.random;local roll=0
        R.random=function(n) roll=roll+1;return math.min(n,roll) end
        click(button(cb,"camp_confirm"));R.random=random
        love.mouse.setPosition(2,2);T.next=now+1
    elseif T.step==10 then assert(#game.trainingCamp.results==3);shot("trained")
    elseif T.step==11 then click(button(cb,"camp_leave"))
    elseif T.step==12 then assert(game.trainingCamp==nil and game.run.ante==4 and select(2,cb.getRunState())=="BLIND_SELECT");open(game,cb)
    elseif T.step==13 then click(button(cb,"camp_rest"))
    elseif T.step==14 then assert(game.playerHp==92 and game.maxPlayerHp==110);shot("rested")
    elseif T.step==15 then click(button(cb,"camp_leave"))
    else
        assert(game.trainingCamp==nil and game.run.ante==4 and select(2,cb.getRunState())=="BLIND_SELECT")
        T.done=true;print("Training camp UI PASS: normal event routing, exclusive branches, real card clicks across pages, three upgrades, healing and return to next main stage");love.event.quit(0);return
    end
    T.step=T.step+1;T.next=T.next and T.next>now and T.next or now+.5
end
return T

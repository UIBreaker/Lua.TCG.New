local T={step=0}
local M=require("src.memory_match")
local function button(cb,id,index)
    for _,b in ipairs(cb.getButtons()) do if b.id==id and (not index or b.index==index) then return b end end
end
local function click(b)
    assert(b and not b.disabled,"Missing or disabled memory control at step "..T.step)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x=(w-1280*s)/2+(b.x+b.w/2)*s;local y=(h-720*s)/2+(b.y+b.h/2)*s
    love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/memory_match_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function pair(e,n)
    local p={};for i,c in ipairs(e.cards) do if c.pair==n then p[#p+1]=i end end;return p
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime();if T.next and now<T.next then return end
    local e=game.memoryMatch
    if T.step==0 then
        require("tests.memory_match_smoke")
        cb.startNewGame("red_deck");local Run=require("src.run_manager")
        game.run.ante=3;game.run.areaStage=3;game.run.currentBlindIndex=3
        game.run.blinds=Run.generateAnteBlinds(3,nil,"human",3);game.run.blinds[3].status="completed"
        game.pendingAncientStatue=nil;game.pendingBarter=nil
        game.pendingTrainingCamp=nil;game.gold=49
        cb.openMemoryMatch();T.next=now+1.5
    elseif T.step==1 then assert(select(2,cb.getRunState())=="memory_match" and button(cb,"memory_start").disabled);shot("insufficient")
    elseif T.step==2 then click(button(cb,"memory_rules"))
    elseif T.step==3 then shot("rules")
    elseif T.step==4 then click(button(cb,"memory_rules_close"));game.gold=125
    elseif T.step==5 then
        if not T.paidPreview then shot("welcome");T.paidPreview=true;T.next=now+.5;return end
        click(button(cb,"memory_start"));assert(game.gold==75 and game.memoryMatch.entryPaid==50)
    elseif T.step==6 then shot("table")
    elseif T.step==7 then click(button(cb,"memory_flip",pair(e,1)[1]))
    elseif T.step==8 then shot("reveal")
    elseif T.step==9 then click(button(cb,"memory_flip",pair(e,1)[2]));T.next=now+.8
    elseif T.step==10 then assert(e.matched==1);click(button(cb,"memory_flip",pair(e,2)[1]))
    elseif T.step==11 then click(button(cb,"memory_flip",pair(e,2)[2]));T.next=now+.8
    elseif T.step==12 then assert(e.streak==2);shot("combo")
    elseif T.step==13 then click(button(cb,"memory_flip",pair(e,3)[1]))
    elseif T.step==14 then click(button(cb,"memory_flip",pair(e,4)[1]))
    elseif T.step==15 then assert(e.streak==0);shot("mismatch");T.next=now+1.2
    elseif T.step>=16 and T.step<=23 then
        local targets={7,8,9,3};local offset=T.step-16;local p=pair(e,targets[math.floor(offset/2)+1])
        click(button(cb,"memory_flip",p[offset%2+1]));if offset%2==1 then T.next=now+.8 end
    elseif T.step==24 then assert(e.streak==4 and e.matched==6);shot("max_combo")
    elseif T.step==25 then click(button(cb,"memory_finish"))
    elseif T.step==26 then assert(e.rewardMultiplier==4 and e.rewardCount==24);shot("rewards")
    elseif T.step==27 then click(button(cb,"memory_claim"))
    elseif T.step==28 then
        assert(game.memoryMatch==nil and game.run.ante==4 and #game.backpackDeities==12 and #game.backpackConsumables==12)
        assert(select(2,cb.getRunState())=="BLIND_SELECT")
        cb.startNewGame("red_deck");local Run=require("src.run_manager")
        game.run.ante=3;game.run.areaStage=3;game.run.currentBlindIndex=3
        game.run.blinds=Run.generateAnteBlinds(3,nil,"human",3);game.run.blinds[3].status="completed"
        game.pendingTrainingCamp=nil;game.pendingAncientStatue=nil;game.pendingBarter=nil;game.gold=49
        cb.openMemoryMatch()
    elseif T.step==29 then
        assert(button(cb,"memory_start").disabled);click(button(cb,"memory_finish"))
    else
        assert(game.memoryMatch==nil and game.run.ante==4 and game.gold==49 and select(2,cb.getRunState())=="BLIND_SELECT")
        T.done=true;print("Memory UI PASS: actual clicks, 50-gold fee/insufficient funds/free skip, rules, flips, combos, x4 bank, 24 backpack rewards and return to ante 4");love.event.quit(0);return
    end
    T.step=T.step+1;T.next=T.next and T.next>now and T.next or now+.4
end
return T

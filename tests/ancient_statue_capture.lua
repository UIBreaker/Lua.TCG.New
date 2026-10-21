local T={step=0}
local S=require("src.ancient_statue")
local Run=require("src.run_manager")
local function button(cb,id) for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end end
local function click(b)
    assert(b and not b.disabled,"Missing statue control at "..T.step)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function shot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/ancient_statue_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function touch(cb,n)
    local Rng=require("src.rng");local original=Rng.random
    Rng.random=function(a,b) if not a then return .99 elseif b then return a else return n end end
    local ok,err=pcall(function()
        click(button(cb,"statue_touch"))
        local V=require("ui.ancient_statue")
        local result=V.update(cb.getRunState(),2.1)
        if result=="entered" then cb.setCaptureState("BLIND_SELECT")
        else V.press(cb.getRunState(),{id="statue_continue"}) end
    end);Rng.random=original;assert(ok,err)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime();assert(love.timer.getTime()-T.started<80,"Statue capture timeout "..T.step)
    if love.timer.getTime()<(T.deadline or 0) then return end
    local step=T.step
    if step==0 then
        require("tests.ancient_statue_smoke")
        require("tests.blood_enemies_smoke")
        require("tests.blood_difficulty_smoke")
        require("tests.blood_enemy_gallery").capture()
        cb.startNewGame("red_deck");game.run.ante=2;game.run.areaStage=2;game.run.currentBlindIndex=3
        game.run.blinds=Run.generateAnteBlinds(2,"red_deck","human",2);game.run.blinds[3].status="completed"
        game.pendingAncientStatue=true;game.pendingBarter=nil;game.shopMode="small";cb.openShop()
    elseif step==1 then click(button(cb,"leave_shop") or button(cb,"next_round"))
    elseif step==2 then
        local _,state=cb.getRunState();assert(state=="blood_statue");click(button(cb,"statue_select"))
        T.step=2.5;T.deadline=love.timer.getTime()+.65;return
    elseif step==2.5 then
        local Bag=require("src.ui").Backpack
        assert(Bag.open and Bag.cardPicker)
        click(Bag.cellRect(1))
        T.step=3;T.deadline=love.timer.getTime()+.65;return
    elseif step==3 then shot("offering");touch(cb,4)
    elseif step==4 then assert(game.playerHp==90);shot("blessing");click(button(cb,"statue_rates"))
    elseif step==5 then shot("rates");click(button(cb,"statue_rates_close"))
    elseif step==6 then game.playerHp=11;touch(cb,10)
    elseif step==7 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and game.run.regionId=="blood_domain" and game.run.areaStage==1)
        click(button(cb,"fight_blind"))
    elseif step==8 then
        assert(game.monster.regionId=="blood_domain");shot("outer_combat")
        for stage=1,7 do
            Run.completeCurrentBlind(game.run,game);assert(Run.advanceBlind(game.run,game))
        end
        cb.setCaptureState("BLIND_SELECT")
    elseif step==9 then
        click(button(cb,"fight_blind"))
        if not game.monster then T.deadline=love.timer.getTime()+.5;return end
    elseif step==10 then
        assert(game.monster.bloodSovereign and game.run.areaStage==8);shot("boss")
        T.bossHp=game.monster.maxHp
        game.consumables={require("src.shop").healingItem(nil,"cons_heal_small").consumable}
        assert(require("src.inventory").useUtility(game,1));assert(game.monster.maxHp==T.bossHp*2)
    elseif step==11 then
        shot("boss_heal_reaction");game.monster.hp=0;cb.openReward("boss")
    elseif step==12 then require("src.reward_system").finishImmediately(cb.getRewardAnimation())
    elseif step==13 then click(button(cb,"cashout_continue"))
    elseif step==14 then
        local _,state=cb.getRunState();assert(state=="blood_statue" and #game.bloodDomain.choices==3);shot("reward_choice")
    elseif step==15 then click(button(cb,"statue_claim"))
    elseif step==16 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and game.run.regionId=="human" and game.run.ante==3 and not game.bloodDomain)
        assert(game.backpackDeities[#game.backpackDeities].bloodDomainPower==4)
        print("Statue UI PASS: shop -> statue, selected card/cost/blessing/rates, threshold teleport, domain combat art, final boss heal reaction, reward ceremony -> three x4 SPNs -> original route")
        love.event.quit(0);return
    end
    T.step=step+1;T.deadline=love.timer.getTime()+.65
end
return T

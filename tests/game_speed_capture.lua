local T={stage=0,clock=0,at=0,index=0,times={}}
local UI=require("src.ui")
local function nextStage() T.stage=T.stage+1;T.at=T.clock end
local function speedButton(cb)
    for _,b in ipairs(cb.getButtons()) do if b.id=="setting_speed" then return b end end
    error("missing speed setting")
end
local function click(b)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local x,y=(w-1280*scale)/2+(b.x+b.w/2)*scale,(h-720*scale)/2+(b.y+b.h/2)*scale
    love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
function T.update(game,cb)
    if T.done then return end
    assert(T.clock-T.at<35,"speed stage timeout "..T.stage)
    if T.stage==0 then
        require("tests.game_speed_smoke")
        local update=love.update
        love.update=function() T.clock=T.clock+1/60;update(1/60) end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setGameSpeed(1);cb.openSettings()
        nextStage()
    elseif T.stage==1 and T.clock-T.at>.2 then
        assert(cb.getGameSpeed()==1 and speedButton(cb).text:find("×1",1,true));click(speedButton(cb));nextStage()
    elseif T.stage==2 and T.clock-T.at>.2 then
        assert(cb.getGameSpeed()==2 and speedButton(cb).text:find("×2",1,true));click(speedButton(cb));nextStage()
    elseif T.stage==3 and T.clock-T.at>.2 then
        assert(cb.getGameSpeed()==4 and speedButton(cb).text:find("×4",1,true))
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/game_speed_settings.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
        nextStage()
    elseif T.stage==4 then
        if T.clock-T.at<.2 then return end
        if not T.settingsClosed then
            click(speedButton(cb));assert(cb.getGameSpeed()==1);cb.closeSettings()
            T.settingsClosed=true;T.at=T.clock;return
        end
        T.index=T.index+1
        if T.index>3 then
            assert(math.abs(T.times[1]/T.times[2]-2)<.18 and math.abs(T.times[1]/T.times[3]-4)<.35,"actual combat speed ratios")
            T.done=true
            print(string.format("GAME SPEED RUNTIME PASS: settings clicks 1 -> 2 -> 4 -> 1, actual scoring impact %.3f / %.3f / %.3f real seconds; identical damage and single hand consumption",T.times[1],T.times[2],T.times[3]))
            love.event.quit(0);return
        end
        cb.startMonsterEncounter(1,false);cb.setGameSpeed(({1,2,4})[T.index])
        game.deities={};game.hand={require("src.deck").newCard(2,"hearts")};game.selectedIndices={};game.maxHandSize=1
        local m=game.monster;m.hp=1000000;m.maxHp=m.hp;m.damageLagHp=m.hp;m.armor=0;m.creatureArmor=0;m.attack=0;m.attackSpeed=0
        m.enemyInventory=nil;m.enemyAbility=nil;m.isBoss=false;m.bossData=nil;m.intent={type="attack",value=0}
        require("src.combat").getHitChance=function() return 1 end
        T.hands=game.handsRemaining;T.impact=nil
        cb.selectCardIndex(1);T.started=T.clock;cb.playSelectedHand();nextStage()
    elseif T.stage==5 then
        if not T.impact and game.monster.hp<1000000 then
            T.impact=T.clock-T.started;T.times[T.index]=T.impact
            local damage=1000000-game.monster.hp;T.damage=T.damage or damage;assert(damage==T.damage,"speed must not alter damage")
        end
        local anim,screen=cb.getScoringState()
        if screen=="playing" and not anim.active and not anim.enemyTurn then
            assert(T.impact and game.handsRemaining==T.hands-1)
            T.stage=4;T.at=T.clock
        end
    end
end
return T

-- lovec.exe . --capture-shop --capture-encounter-preview
local T={step=0,deadline=0}
local S=require("ui.expedition_select")
local Debug=require("src.debug_tools")
local function pointer(x,y,click)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local px,py=(w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale
    love.mouse.setPosition(px,py)
    if click then love.mousepressed(px,py,1);love.mousereleased(px,py,1) end
end
local function shot(name)
    pointer(5,5);require("src.ui").Description.reset()
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/encounter_preview_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
local function check(game,cb)
    local n=0
    for _,b in ipairs(cb.getButtons()) do
        assert(b.x>=0 and b.y>=0 and b.x+b.w<=1280 and b.y+b.h<=720,"control bounds")
        if b.id=="fight_blind" then n=n+1;T.fight=b end
    end
    assert(n==1,"only current encounter can be started")
    local R=require("src.rng");local random=R.random
    R.random=function() error("Preview must not consume combat RNG") end
    for i,b in ipairs(game.run.blinds) do
        local p=S.preview(b,game)
        assert(p.count==require("src.enemy_group").count(b.difficultyAnte or b.ante,i==3,i==2))
        assert(p.detail.desc:find(p.passive,1,true) and p.detail.desc:find(p.action,1,true),"full skill descriptions retained")
        assert(p.monster.attackSpeed==1,"preview speed is a placeholder, never shown as combat speed")
        local title,body=require("src.card_description").resolve(p.detail,game)
        local model=require("ui.components.card_description").model(p.detail,title,body,false)
        assert(model.badge=="ĐỐI THỦ · XEM TRƯỚC","hover dossier has enemy identity")
    end
    R.random=random
end
function T.update(game,cb)
    local now=love.timer.getTime();if now<T.deadline then return end
    local step=T.step
    if step==0 then cb.startNewGame("red_deck");cb.setCaptureState("BLIND_SELECT")
    elseif step==1 then
        check(game,cb);shot("starter")
    elseif step==2 then Debug.setAnte(game,3,2);cb.setCaptureState("BLIND_SELECT")
    elseif step==3 then check(game,cb);shot("squad")
    elseif step==4 then Debug.setAnte(game,20,3);cb.setCaptureState("BLIND_SELECT")
    elseif step==5 then check(game,cb);shot("boss")
    elseif step==6 then game.run.regionId="unknown";Debug.setAnte(game,42,1);cb.setCaptureState("BLIND_SELECT")
    elseif step==7 then check(game,cb);shot("unknown")
    elseif step==8 then love.window.setMode(960,540,{resizable=true});love.resize(960,540)
    elseif step==9 then check(game,cb);shot("960")
    elseif step==10 then pointer(T.fight.x+T.fight.w/2,T.fight.y+T.fight.h/2,true)
    elseif step==11 then
        assert(select(2,cb.getRunState())=="playing","fight button enters combat at 960")
        print("ENCOUNTER PREVIEW PASS: starter, squad, boss, unknown, full skill descriptions, no combat RNG, controls and 960 fight input")
        love.event.quit(0);return
    end
    T.step=step+1;T.deadline=now+.7
end
return T

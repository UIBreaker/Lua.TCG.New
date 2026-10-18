local UI=require("src.ui")
local F=require("ui.enemy_formation")
local G=require("src.enemy_group")
local R=require("render.renderer")
local T={clock=0,stage=0,at=0,reticles=0}
local record=false
for _,a in ipairs(arg or {}) do if a=="--record-target-clarity" then record=true end end
local function pointer(x,y,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if button then love.mousepressed(px,py,button);love.mousereleased(px,py,button) end
end
local function shot(path)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function nextStage() T.stage=T.stage+1;T.at=T.clock end
function T.update(game,cb)
    assert(T.clock-T.at<12,"target clarity timeout: "..T.stage)
    if T.stage==0 then
        require("tests.target_clarity_smoke")
        local update=love.update
        love.update=function(dt) local step=math.min(dt,1/30);T.clock=T.clock+step;update(step) end
        local hud=F.hud
        F.hud=function(...)
            local g=love.graphics;local line=g.line
            g.line=function(...)
                local args={...};local r,b,c=g.getColor()
                if g.getLineWidth()==3 and #args==6 and ((r==1 and math.abs(b-.83)<.001) or math.abs(r-.42)<.001 and math.abs(b-.91)<.001) then
                    local matches=false
                    for _,m in ipairs(G.members(game)) do
                        local face=R.entity.face(m)
                        if m.hp>0 and face then
                            local points={};local cx,cy=0,0
                            for i=1,8,2 do
                                if R.world then points[i],points[i+1]=face[i]/R.worldScale,face[i+1]/R.worldScale
                                else points[i],points[i+1]=R.worldRoot:inverseTransformPoint(face[i],face[i+1]) end
                                cx,cy=cx+points[i]/4,cy+points[i+1]/4
                            end
                            for i=1,8,2 do
                                local x,y=cx+(points[i]-cx)*1.07,cy+(points[i+1]-cy)*1.045
                                if math.abs(args[3]-x)+math.abs(args[4]-y)<.05 then matches=true end
                            end
                        end
                    end
                    assert(matches,"sharp target marker must follow the final moving face")
                    T.reticles=T.reticles+1
                end
                return line(...)
            end
            hud(...);g.line=line
        end
        cb.startNewGame("red_deck");require("src.debug_tools").setAnte(game,3,1)
        game.maxHandSize=3;game.persistentDeck={}
        for i,rank in ipairs({14,5,5}) do game.persistentDeck[i]=require("src.deck").newCard(rank,i==1 and "hearts" or "spades") end
        cb.startMonsterEncounter(3,false);assert(#game.enemies==3)
        T.gold=game.gold;T.hands=game.handsRemaining
        pointer(2,2);nextStage();return
    end
    if record and T.stage<=6 and T.clock>=(T.nextShot or 0) then
        shot(string.format(".tmp/target-review/demo_%04d.png",T.frame or 0))
        T.frame=(T.frame or 0)+1;T.nextShot=(T.nextShot or T.clock)+.05
    end
    if T.clock-T.at<(record and 1 or .35) then return end
    if T.stage==1 and UI.HandMotion.busy(game.hand) then return end
    if T.stage==1 then
        local x,y,w,h=G.rect(2,3);pointer(x+w/2,y+h/2,1)
        assert(game.monster==game.enemies[2] and not cb.getInspector())
        cb.selectCardIndex(1);pointer(G.rect(3,3)+64,250);nextStage()
    elseif T.stage==2 then
        assert(game.monster==game.enemies[2],"hover cannot change selected target")
        assert(T.reticles>0,"reticles must be drawn on the sharp UI canvas")
        for _,b in ipairs(cb.getButtons()) do if b.id=="play" then assert(b.text=="TẤN CÔNG #2" and not b.disabled) end end
        if not T.selectedShot then shot("docs/target_clarity_combat.png");T.selectedShot=true;T.at=T.clock;return end
        local hx,hy=F.headerRect(1,3);pointer(hx+30,hy+15,1)
        assert(game.monster==game.enemies[1] and not cb.getInspector());nextStage()
    elseif T.stage==3 then
        local x,y,w,h=F.bagRect(1,3);pointer(x+w/2,y+h/2,1)
        assert(cb.getInspector()==game.enemies[1]);cb.closeInspector()
        local anim=cb.getScoringState();anim.active=true
        pointer(G.rect(3,3)+64,250,1)
        assert(game.monster==game.enemies[1],"resolving combat must lock target selection")
        anim.active=false
        game.enemies[1].hp=0;G.ensureTarget(game);pointer(2,2);nextStage()
    elseif T.stage==4 then
        assert(game.monster==game.enemies[2])
        assert(not F.press(game,G.rect(1,3)+64,250))
        if not T.killShot then shot("docs/target_clarity_after_kill.png");T.killShot=true;T.at=T.clock;return end
        love.window.setMode(960,540,{resizable=true});love.resize(960,540);nextStage()
    elseif T.stage==5 then
        local image=require("src.enemy_art").image(game.enemies[3],{})
        if image:typeOf("Canvas") then
            local data=image:newImageData();local _,_,_,alpha=data:getPixel(256,384)
            assert(alpha>.9,"enemy illustration must survive a window resize");data:release()
        end
        pointer(G.rect(3,3)+64,250,1);assert(game.monster==game.enemies[3])
        if not T.smallShot then shot("docs/target_clarity_960.png");T.smallShot=true;T.at=T.clock;return end
        love.window.setMode(1920,1080,{resizable=true});love.resize(1920,1080);nextStage()
    elseif T.stage==6 then
        assert(game.gold==T.gold and game.handsRemaining==T.hands,"target selection cannot spend resources")
        cb.openReward("normal");nextStage()
    elseif T.stage==7 then
        local reward=cb.getRewardAnimation();require("src.reward_system").finishImmediately(reward)
        pointer(2,2);nextStage()
    elseif T.stage==8 then
        if not T.rewardShot then shot("docs/target_clarity_reward.png");T.rewardShot=true;T.at=T.clock;return end
        game.rewardPacks={};cb.closePack();game.shopMode="equipment";cb.openShop();nextStage()
    elseif T.stage==9 then
        if UI.Polish.age<1.3 then return end
        shot("docs/target_clarity_shop.png")
        print("TARGET CLARITY PASS: card/header/hover/bag, selection lock, survivor target, 960/1920 input, moving sharp markers, rewards/shop; "..T.reticles.." verified corners")
        love.event.quit(0)
    end
end
return T

local T={index=0}
local C=require("src.combat")
local Run=require("src.run_manager")
local Deck=require("src.deck")
local A=require("src.enemy_abilities")
local L=require("src.enemy_loadout")
local R=require("src.rng")
local cases={{kind="small",stage=1,width=1920},{kind="small",width=1920},{kind="big",width=960},{kind="big",width=960,meters=true},{kind="boss",width=1920},
    {kind="swap",width=1920},{kind="potion",width=960},{kind="oneshot",width=1920}}
local function click(x,y,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    love.mousepressed((w-1280*s)/2+x*s,(h-720*s)/2+y*s,button or 1)
    love.mousereleased((w-1280*s)/2+x*s,(h-720*s)/2+y*s,button or 1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/enemy_loadout_"..name..".png","wb"))
        f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if not T.started then
        T.index=T.index+1;local spec=cases[T.index]
        if not spec then R.random=T.random;print("Enemy inventory runtime passed: actual bag/right clicks, 1920/960 UI, equip/potion contact and 500K one-shot scoring");love.event.quit(0);return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        local stage=spec.stage or 20
        game.run.ante=stage;game.run.areaStage=stage
        local kind=spec.kind=="oneshot" and "small" or spec.kind
        if spec.kind=="swap" or spec.kind=="potion" then kind="boss" end
        local blind=Run.generateAnteBlinds(stage)[kind=="small" and 1 or kind=="big" and 2 or 3]
        game.run.currentBlindIndex=blind.index
        local m=Run.createBlindMonster(blind,game)
        if spec.kind=="swap" or spec.kind=="potion" then m.bossData=require("src.boss_abilities").newDefinitions.gatekeeper end
        C.start(game,m,stage)
        if spec.meters then
            m.hp=math.floor(m.maxHp*.625);m.damageLagHp=m.hp
            m.creatureArmor=math.floor(m.creatureArmor*.5)
        end
        game.playerHp=stage==1 and 100 or 500;game.maxPlayerHp=game.playerHp;game.deities={};game.hand={Deck.newCard(8,"hearts")};game.selectedIndices={}
        love.window.setMode(spec.width,spec.width*9/16,{resizable=true});love.resize(spec.width,spec.width*9/16)
        -- setMode can discard cached render targets; rebuild indexed art for the new context.
        local Art=require("src.continental_art")
        Art.cache={};Art.indexed=setmetatable({}, {__mode="k"})
        for _,enemy in ipairs(game.enemies) do require("src.enemy_art").image(enemy,{}) end
        T.started=now;T.step=0;T.spec=spec;T.deadline=now+1.8;T.checked=false
        T.random=T.random or R.random;R.random=function(a,b) if a then return T.random(a,b) end;return 0 end
        local anim=cb.getScoringState();anim.floatingTexts={}
        if spec.kind=="swap" or spec.kind=="potion" then
            assert(m.enemyInventory.backpack.equipment[1] and m.enemyInventory.backpack.consumables[1])
            m.attackSpeed=999;m.hp=math.floor(m.maxHp*(spec.kind=="swap" and .45 or .25));m.damageLagHp=m.hp
            A.plan(game,m);T.hp=m.hp
            assert(m.intent.type==(spec.kind=="swap" and "equip" or "consume"))
            cb.selectCardIndex(1);cb.playSelectedHand()
        elseif spec.kind=="oneshot" then
            game.hand[1].baseChips=500000;game.hand[1].speedBonus=50
            T.target=m;cb.selectCardIndex(1);cb.playSelectedHand()
        end
        return
    end
    assert(now-T.started<30,"enemy loadout runtime timeout")
    local spec=T.spec;local anim,state=cb.getScoringState()
    if spec.kind=="swap" or spec.kind=="potion" then
        local turn=anim.enemyTurn
        if turn and turn.index==1 and turn.phase=="recover" and not T.checked then
            local hit=assert(turn.result);assert(hit.damage==0 and game.playerHp==500)
            if spec.kind=="swap" then assert(hit.action=="equip" and #game.monster.enemyInventory.backpack.equipment==0 and game.monster.enemyInventory.stowed)
            else assert(hit.action=="heal" and game.monster.hp>T.hp and #game.monster.enemyInventory.backpack.consumables==0) end
            shot(spec.kind);T.checked=true
        end
        if T.checked and state=="playing" and not anim.enemyTurn and not anim.active then T.started=nil end
    elseif spec.kind=="oneshot" then
        if anim.sequence and anim.sequence.damageApplied and not T.checked then
            assert(anim.damageDealt>=500000 and T.target.hp==0,"500K actual Poker score must one-shot a stage-20 geared opponent")
            shot("oneshot");T.checked=true
        end
        if T.checked and not anim.active and not anim.enemyTurn then T.started=nil end
    elseif now>=T.deadline then
        if T.step==0 then
            shot((spec.stage==1 and "starter" or spec.meters and "meters" or spec.kind).."_combat")
            T.step=1;T.deadline=now+.1
        elseif T.step==1 then
            local x,y,w,h=require("ui.enemy_formation").bagRect(1,#game.enemies)
            click(x+w/2,y+h/2);assert(cb.getInspector()==game.monster,"bag button opens actual enemy inventory")
            T.step=2;T.deadline=now+.35
        elseif T.step==2 then
            love.keypressed("space");assert(cb.getInspector()==game.monster and not anim.active,"inventory traps combat shortcuts")
            shot((spec.stage==1 and "starter" or spec.meters and "meters" or spec.kind).."_inventory");T.step=3;T.deadline=now+.1
        elseif T.step==3 then
            love.wheelmoved(0,-2);love.keypressed("escape")
            assert(not cb.getInspector(),"Escape closes enemy inventory")
            local hx,hy,hw,hh=require("ui.enemy_formation").bagRect(1,#game.enemies)
            click(hx-45,hy+hh/2);assert(cb.getInspector()==game.monster,"the nameplate is a larger touch target for inventory")
            love.keypressed("escape")
            local x,y,w,h=require("src.enemy_group").rect(1,#game.enemies)
            click(x+w/2,y+h/2,2);assert(cb.getInspector()==game.monster,"right click opens the same inventory")
            T.step=4;T.deadline=now+.2
        else
            click(1160,40);assert(not cb.getInspector(),"close button works")
            print("Enemy loadout UI "..spec.kind.." at "..spec.width.." passed");T.started=nil
        end
    end
end
return T

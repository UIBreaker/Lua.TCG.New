local UI=require("src.ui")
local P=require("src.enemy_attack_presentation")
local Combat=require("src.combat")
local Deck=require("src.deck")
local T={clock=0}
local preview=true
for _,a in ipairs(arg or {}) do if a=="--no-motion-preview" then preview=false end end
local cases={{name="enemy_first",before=true,armor=8},{name="counter_fast",fast=true,armor=4},
    {name="reduced_armor",before=true,reduced=true,armor=100},
    {name="miss",before=true,miss=true},{name="blocked",before=true,blocked=true},
    {name="support",before=true,support=true},{name="group",group=true},
    {name="lethal",before=true,lethal=true},{name="reprisal_fast",fast=true,reflect=true}}
local index,stage,started,frame,nextShot=0,"start",0,0,0
local recording,turn,seen,hits,lastHp,lastArmor,initialHp,initialArmor,trail,reflected
local originalResolve=Combat.resolveMonsterAttack
local function after(name) stage=name;started=T.clock end
local function click(card)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    local x,y=(w-1280*scale)/2+(card.visualX+50)*scale,(h-720*scale)/2+(card.visualY+65)*scale
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
function T.update(game,cb)
    assert(T.clock-started<15,"enemy motion timeout at "..stage)
    if recording and T.clock>=nextShot then
        local path=string.format(".tmp/enemy-motion/frame_%04d.png",frame)
        love.graphics.captureScreenshot(function(data)
            local file=assert(io.open(path,"wb"));file:write(data:encode("png"):getString());file:close()
        end)
        frame=frame+1;nextShot=nextShot+.05
    end
    if stage=="start" then
        require("tests.enemy_motion_smoke")
        local update=love.update
        love.update=function(dt)
            local step=math.min(dt,recording and 1/30 or .05);T.clock=T.clock+step;update(step)
        end
        Combat.resolveMonsterAttack=function(...)
            local a=cb.getScoringState();local s=assert(a.enemyTurn)
            assert(s.phase=="recover" and s.age==0,"gameplay resolves at the contact boundary")
            hits=hits+1
            local result=originalResolve(...)
            if cases[index].miss then assert(result.missed) end
            if cases[index].blocked then assert(result.blocked) end
            if cases[index].support then assert(result.action=="armor") end
            return result
        end
        local HUD=require("ui.components.top_hud")
        local draw=HUD.draw
        HUD.draw=function(data,...)
            local a=cb.getScoringState();local s=a.enemyTurn
            if s then
                assert(data.meters.hp==s.hp and data.meters.armor==s.armor,"HUD must read the contact clock")
                assert(data.meters.hp.shown>=game.playerHp-1e-6 and data.meters.armor.shown>=(game.playerArmor or 0)-1e-6)
            elseif turn and turn.finished and stage=="settle" then
                assert(math.abs(data.meters.hp.shown-game.playerHp)<1e-6,"HUD cannot rebound on unlock")
                assert(math.abs(data.meters.armor.shown-(game.playerArmor or 0))<1e-6)
            end
            return draw(data,...)
        end
        local Health=require("ui.components.health_bar")
        local drawHealth=Health.draw
        Health.draw=function(x,y,w,h,value,maximum,options)
            if y==142 and turn and turn.reactions then
                local a=cb.getScoringState();local Group=require("src.enemy_group");local list=Group.members(game)
                for i,m in ipairs(list) do
                    local r=turn.reactions[m]
                    if r and x==Group.rect(i,#list)-9 then
                        if a.enemyTurn==turn then
                            assert(value==r.hp.shown and options.trailValue==r.hp.trail,"reflected HP follows the enemy clock")
                        elseif turn.finished and stage=="settle" then
                            assert(value==m.hp,"post-counter HUD cannot revive the player's old target snapshot")
                        end
                    end
                end
            end
            return drawHealth(x,y,w,h,value,maximum,options)
        end
        after("case")
    elseif stage=="case" then
        index=index+1
        if not cases[index] then
            Combat.resolveMonsterAttack=originalResolve
            print("Enemy motion runtime PASS: 9 flows; "..frame.." preview frames")
            love.event.quit(0);return
        end
        local spec=cases[index]
        cb.startNewGame("red_deck");cb.setScoringSpeed(spec.fast==true);cb.setReducedMotion(spec.reduced==true)
        game.maxHandSize=1;game.persistentDeck={Deck.newCard(8,"spades")}
        cb.startMonsterEncounter(1,false)
        if spec.group then game.monster.stage=3;Combat.start(game,game.monster,3) end
        game.deities=spec.reflect and {require("src.deities").CATALOG.spirit_reprisal} or {}
        game.hand={Deck.newCard(8,"spades")};game.selectedIndices={};game.abilityApproved={}
        game.deck={Deck.newCard(3,"clubs"),Deck.newCard(4,"hearts")}
        game.playerHp=spec.lethal and 1 or 200;game.maxPlayerHp=200
        game.playerArmor=spec.armor or 0;game.playerShield=game.playerArmor
        game.potionCombat={evasion=spec.miss or nil}
        for _,m in ipairs(require("src.enemy_group").members(game)) do
            m.hp=1000;m.maxHp=1000;m.damageLagHp=1000;m.creatureArmor=0
            m.enemyInventory=nil;m.enemyAbility=nil;m.bossData=nil;m.isBoss=false
            m.attack=24;m.attackSpeed=spec.before and 999 or Combat.getAverageAttackSpeed(game.hand,game)
            m.intent=spec.support and {type="armor",value=5,label="Gia cố"} or {type="attack",value=24,label="Tấn công"}
            m.spnFrozen=spec.blocked and 1 or nil
        end
        turn=nil;seen={};hits=0;trail=false;reflected=false
        love.mouse.setPosition(2,2);after("deal")
    elseif stage=="deal" and T.clock-started>.9 and not UI.HandMotion.busy(game.hand) then
        local spec=cases[index]
        initialHp,initialArmor=game.playerHp,game.playerArmor;lastHp,lastArmor=initialHp,initialArmor
        recording=preview and index==1;nextShot=T.clock
        if spec.group then game.handsRemaining=0;assert(cb.endPlayerTurn())
        else click(game.hand[1]);assert(#game.selectedIndices==1);love.keypressed("space") end
        after("active")
    elseif stage=="active" then
        local spec=cases[index];local a,state=cb.getScoringState()
        if a.enemyTurn then
            if not turn then
                initialHp,initialArmor=a.enemyTurn.hp.value,a.enemyTurn.armor.value
                lastHp,lastArmor=initialHp,initialArmor
                recording=preview and index<=2;nextShot=T.clock
            end
            turn=a.enemyTurn;seen[turn.phase]=true
            if spec.before then assert(not a.active,"enemy first must finish before score")
            elseif not spec.group then assert(a.sequence.finished,"counter must wait for score recovery") end
            if hits==0 then assert(game.playerHp==initialHp and game.playerArmor==initialArmor,"no early damage") end
            assert(turn.hp.shown<=lastHp+1e-6 and turn.armor.shown<=lastArmor+1e-6,"monotone meters")
            lastHp,lastArmor=turn.hp.shown,turn.armor.shown
            trail=trail or turn.hp.trail>turn.hp.shown+.001 or turn.armor.trail>turn.armor.shown+.001
            if turn.reducedMotion then
                assert(P.motion(turn,turn.attackers[turn.index])==0 and P.camera(turn)==0)
            end
            for m,r in pairs(turn.reactions or {}) do
                reflected=true;assert(spec.reflect and r.damage>0)
                assert(r.hp.shown>=m.hp-1e-6)
            end
            local hands=game.handsRemaining;cb.playSelectedHand();assert(game.handsRemaining==hands,"input remains locked")
        elseif turn and turn.finished then
            assert(hits==(spec.group and 3 or 1) and seen.prepare and seen.strike and seen.recover)
            assert(math.abs(turn.hp.shown-game.playerHp)<1e-6 and math.abs(turn.hp.trail-game.playerHp)<1e-6)
            assert(math.abs(turn.armor.shown-game.playerArmor)<1e-6 and math.abs(turn.armor.trail-game.playerArmor)<1e-6)
            if spec.miss or spec.blocked or spec.support then
                assert(game.playerHp==initialHp and game.playerArmor==initialArmor and not trail)
            else assert(trail,"received hit needs a visible meter trail") end
            if spec.reflect then assert(reflected,"real reprisal must animate the actual enemy HP loss") end
            if spec.lethal then assert(game.playerHp==0 and state=="defeating","lethal waits for recovery before defeat") end
            for m,r in pairs(turn.reactions or {}) do assert(math.abs(r.hp.trail-m.hp)<1e-6) end
            print("Enemy runtime PASS: "..spec.name.."; contacts="..hits..", HP="..game.playerHp..", armor="..game.playerArmor)
            after("settle")
        end
    elseif stage=="settle" and T.clock-started>.3 then recording=false;after("case") end
end
return T

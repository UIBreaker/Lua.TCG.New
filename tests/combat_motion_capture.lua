local UI=require("src.ui")
local Feel=UI.ScoringFeel
local Deck=require("src.deck")
local Combat=require("src.combat")
local T={clock=0}
local preview=true
for _,a in ipairs(arg or {}) do if a=="--no-motion-preview" then preview=false end end
local cases={{name="pair",count=5,armor=20},{name="fast",count=5,armor=25,fast=true},
    {name="reduced_block",count=1,armor=100000,reduced=true},
    {name="skip_miss",count=5,armor=30,miss=true,forward=true},{name="lethal",count=1,hp=1},
    {name="enemy_first",count=1,armor=10,enemyFirst=true}}
local index,stage,started,frame,nextShot=0,"start",0,0,0
local enemy,hpBefore,armorBefore,hands,seq,lastHp,lastArmor,contacts,hpTrail,armorTrail
local recording,originalRoll=false,Combat.rollPlayerAttack
local function after(name) stage=name;started=T.clock end
local function click(c)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(c.visualX+50)*s,(h-720*s)/2+(c.visualY+65)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
function T.update(game,cb)
    assert(T.clock-started<20,"combat capture timeout at "..stage)
    if recording and T.clock>=nextShot then
        local path=string.format(".tmp/combat-motion/frame_%04d.png",frame)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
        end)
        frame=frame+1;nextShot=nextShot+0.05
    end
    if stage=="start" then
        require("tests.combat_motion_smoke")
        local update=love.update
        love.update=function(dt)
            local step=math.min(dt,recording and 1/30 or 0.05);T.clock=T.clock+step;update(step)
        end
        Combat.rollPlayerAttack=function() return {missed=cases[index].miss==true,hitChance=cases[index].miss and 0 or 1} end
        local Light=require("render.lighting")
        local flash=Light.flash
        Light.flash=function(x,y,color,...)
            assert(not (seq and seq.missed and x==seq.attack.cx and y==270 and color==seq.attack.color),
                "miss must not emit a successful-contact flash")
            return flash(x,y,color,...)
        end
        local Health=require("ui.components.health_bar")
        local draw=Health.draw
        Health.draw=function(x,y,w,h,value,maxHp,options)
            if seq and (stage=="scoring" or stage=="recovery") then
                local Group=require("src.enemy_group");local list=Group.members(game)
                for i,m in ipairs(list) do if m==enemy and x==Group.rect(i,#list)-9 then
                    local anim,state=cb.getScoringState()
                    if state=="scoring" and anim.active and anim.sequence==seq then
                        if y==142 then assert(value==seq.hp and options.trailValue==seq.hpTrail,"rendered HP follows contact clock") end
                        if y==120 then assert(value==seq.armor and options.trailValue==seq.armorTrail,"rendered armor follows contact clock") end
                    elseif seq.finished and stage=="recovery" then
                        if y==142 then assert(value==enemy.hp,"unlock cannot revive a stale HP meter") end
                    end
                end end
            end
            return draw(x,y,w,h,value,maxHp,options)
        end
        after("case")
    elseif stage=="case" then
        index=index+1
        if not cases[index] then
            Combat.rollPlayerAttack=originalRoll
            print("Combat motion runtime PASS: all 6 flows; "..frame.." preview frames")
            love.event.quit(0);return
        end
        local spec=cases[index]
        cb.startNewGame("red_deck");cb.setScoringSpeed(spec.fast==true);cb.setReducedMotion(spec.reduced==true)
        game.maxHandSize=spec.count;game.persistentDeck={}
        local ranks,suits={8,8,5,10,2},{"spades","hearts","clubs","diamonds","spades"}
        for i=1,spec.count do game.persistentDeck[i]=Deck.newCard(ranks[i],suits[i]) end
        game.unlockedHands={high_card=true,pair=true,full_house=true}
        cb.startMonsterEncounter(1,false)
        enemy=game.monster;enemy.hp=spec.hp or 1000;enemy.maxHp=enemy.hp;enemy.damageLagHp=enemy.hp
        enemy.creatureArmor=spec.armor or 0;enemy.creatureArmorMax=enemy.creatureArmor
        enemy.attackSpeed=spec.enemyFirst and 999 or 1;enemy.attack=0;enemy.enemyInventory=nil;enemy.enemyAbility=nil
        enemy.targetAura=35;enemy.isBoss=false;enemy.bossData=nil
        game.playerHp=1000;game.maxPlayerHp=1000;game.consumables={}
        if index==2 then
            game.deities={require("src.deities").CATALOG.spirit_blade,require("src.deities").CATALOG.thunder_drum}
            game.hand[1].equipments={require("src.equipment").ITEMS.gem_fire}
        end
        for i=1,2 do
            local card=Deck.newCard(i+2,"clubs")
            game.persistentDeck[#game.persistentDeck+1]=card;game.deck[#game.deck+1]=card
        end
        love.mouse.setPosition(2,2);after("deal")
    elseif stage=="deal" and not UI.HandMotion.busy(game.hand) and T.clock-started>0.9 then
        for _,c in ipairs(game.hand) do click(c) end
        assert(#game.selectedIndices==cases[index].count,"real clicks select the hand")
        hpBefore,armorBefore=enemy.hp,enemy.creatureArmor;lastHp,lastArmor=hpBefore,armorBefore
        hands=game.handsRemaining;contacts=0;hpTrail=false;armorTrail=false
        recording=preview and index==1;nextShot=T.clock
        love.keypressed("space");assert(game.handsRemaining==hands-1,"one play charge")
        after("entry")
    elseif stage=="entry" then
        local anim,state=cb.getScoringState()
        if state=="scoring" and anim.active then
            seq=anim.sequence;assert(seq.enemy==enemy)
            if cases[index].forward then Feel.skipOrFastForward(anim) end
            after("scoring")
        else
            assert(cases[index].enemyFirst and anim.enemyTurn,"only enemy-first waits before scoring")
            assert(enemy.hp==hpBefore and enemy.creatureArmor==armorBefore)
        end
        cb.playSelectedHand();assert(game.handsRemaining==hands-1,"play spam cannot spend twice")
    elseif stage=="scoring" then
        local anim,state=cb.getScoringState()
        if not seq.impactDispatched then
            assert(enemy.hp==hpBefore and enemy.creatureArmor==armorBefore,"damage must wait for contact")
        end
        if seq.damageApplied and not T.seenContact then
            T.seenContact=true;contacts=contacts+1
            assert(math.min(seq.actualDamage,hpBefore)==math.max(0,hpBefore-enemy.hp),"resolved damage preserves overkill")
        end
        assert(enemy.hp<=lastHp and enemy.creatureArmor<=lastArmor,"enemy stats must not rebound")
        assert(seq.hp<=hpBefore and seq.hp>=enemy.hp-0.001 and seq.armor>=enemy.creatureArmor-0.001)
        lastHp,lastArmor=enemy.hp,enemy.creatureArmor
        hpTrail=hpTrail or seq.hpTrail>seq.hp+0.001
        armorTrail=armorTrail or seq.armorTrail>seq.armor+0.001
        if cases[index].reduced and seq.damageApplied then
            local r,s=Feel.enemyReaction(anim);assert(r==0 and s==1)
        end
        if seq.finished and not anim.active then
            assert(contacts==1 and anim.displayAura==seq.result.finalScore)
            assert(math.abs(seq.hp-enemy.hp)<0.001 and math.abs(seq.armor-enemy.creatureArmor)<0.001)
            assert(math.abs(seq.hpTrail-enemy.hp)<0.001 and math.abs(seq.armorTrail-enemy.creatureArmor)<0.001)
            if cases[index].miss then assert(seq.missed and enemy.hp==hpBefore and enemy.creatureArmor==armorBefore)
            else
                if enemy.hp<hpBefore then assert(hpTrail,"HP trail must be visible") end
                if enemy.creatureArmor<armorBefore then assert(armorTrail,"armor trail must be visible") end
            end
            recording=false;T.seenContact=false
            print("Combat runtime PASS: "..cases[index].name.."; aura="..seq.result.finalScore..", actual="..seq.actualDamage..", armor="..enemy.creatureArmor)
            after("recovery")
        end
    elseif stage=="recovery" and T.clock-started>0.6 then after("case") end
end
return T

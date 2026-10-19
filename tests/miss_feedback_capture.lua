-- Exercise a real missed hand through input, resolver, world and HUD.
arg={"--capture"}
local Deck=require("src.deck")
local Combat=require("src.combat")
local Feel=require("src.scoring_presentation")
local originalRoll=Combat.rollPlayerAttack
Combat.rollPlayerAttack=function() return {missed=true,hitChance=0} end
local stage,clock,done="start",0,false
local lastState,lastAge
local case=1
local reduced=false
local tier=1
package.loaded.capture_screens={update=function(game,cb)
    clock=clock+1/60
    if stage=="start" then
        cb.startNewGame("red_deck");cb.setReducedMotion(reduced)
        game.maxHandSize=5;game.persistentDeck={}
        for i,rank in ipairs({8,8,8,8,2}) do
            game.persistentDeck[i]=Deck.newCard(rank,({"spades","hearts","clubs","diamonds","spades"})[i])
        end
        cb.startMonsterEncounter(1,false)
        game.unlockedHands={high_card=true,four_of_a_kind=true,full_house=true}
        local enemy=game.monster
        enemy.hp=1000;enemy.maxHp=1000;enemy.damageLagHp=1000
        enemy.creatureArmor=50;enemy.creatureArmorMax=50
        enemy.attackSpeed=1;enemy.attack=0;enemy.targetAura=({1000000,700,1})[tier]
        enemy.enemyInventory=nil;enemy.enemyAbility=nil
        game.deities={};game.consumables={}
        clock=0;stage="deal"
    elseif stage=="deal" and clock>1.2 and not require("src.hand_motion").busy(game.hand) then
        for i in ipairs(game.hand) do cb.selectCardIndex(i) end
        assert(#game.selectedIndices==5,"select real hand: "..#game.hand.." cards / "..#game.selectedIndices.." selected")
        cb.playSelectedHand();stage="scoring"
    elseif stage=="scoring" then
        local anim,state=cb.getScoringState();local s=anim.sequence
        lastState=state;lastAge=s and s.attack.missAge
        if s and s.missed and s.attack.missAge>=require("src.miss_feedback").duration(s.attack)*.35 then
            assert(s.attack.nen.tier==tier,"resolved miss tier")
            assert(game.monster.hp==1000 and game.monster.creatureArmor==50,"miss preserves HP and armor")
            local x,y=Feel.camera(anim);assert(x==0 and y==0 and anim.hitStop==0)
            local recoil,scale,flash=Feel.enemyReaction(anim)
            assert(scale==1 and flash==0 and (not reduced or recoil==0))
            local path="docs/audio/miss_"..(reduced and "reduced" or "feedback")..(tier==3 and "" or "_tier"..tier)..".png"
            love.graphics.captureScreenshot(function(data)
                local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close()
            end)
            stage="captured"
        end
    elseif stage=="captured" then
        case=case+1
        if case>6 then done=true else
            tier=(case-1)%3+1;reduced=case>3;stage="start"
        end
    end
end}
assert(loadfile("main.lua"))();love.load();love.audio.setVolume(0)
for frame=1,3600 do
    love.update(1/60);love.draw();love.graphics.present()
    if done then break end
end
assert(done,"miss capture completed: case "..case.." / "..stage.." / "..tostring(lastState).." / age "..tostring(lastAge))
Combat.rollPlayerAttack=originalRoll
require("src.sound").stopAll()
print("Real game miss PASS: selection/resolver, three tiers, unchanged HP/armor, no contact flash/shake, six normal/reduced renders")

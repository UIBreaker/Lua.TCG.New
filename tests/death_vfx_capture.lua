-- Live LÖVE render harness, isolated by the existing capture/save guard.
local D=require("src.death_vfx")
local R=require("render.renderer")
local T={};local phase=0;local elapsed=0;local captured=false
-- Legacy new-game/defeat callbacks delete saves even in capture mode.
local Persistence=require("src.persistence")
Persistence.deleteRun=function() return true end
Persistence.saveRun=function() return true end
Persistence.saveSettings=function() return true end
local preset=1;local presets={"mini","elite","boss"}
local case=0;local cases={"kill_mini","kill_boss","pre_score_death","counter_death","end_turn_death","needle_exhaustion"}
local lastHp,impacts,seen,expected,originalGold,encounters
local qualityIndex=1;local qualities={"LOW","MEDIUM","HIGH"};local samples={};local savedShader
local previewOnly=false
for _,value in ipairs(arg or {}) do if value=="--death-preview-only" then previewOnly=true end end
local Sound=require("src.sound")
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/death_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
function T.update(game,cb)
    elapsed=elapsed+love.timer.getDelta()
    assert(elapsed<16,"death test timeout, phase "..phase.." case "..case)
    if phase==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(20,true)
        assert(D.shader,D.shaderError);D.startEnemy(game.monster,640,R.quality)
        D.reset();game.monster.isBoss=false;game.monster.isElite=false;D.startEnemy(game.monster,640,R.quality)
        phase=1;elapsed=0
        if previewOnly then D.reset();game.monster.isBoss=true;cb.previewPlayerDefeat();phase=2 end
    elseif phase==1 then
        if D.age>0.36 and not captured then shot("enemy_break_"..presets[preset]);captured=true end
        if elapsed>1.8 then
            assert(not D.busy());assert(D.dissolve()==1);assert(D.count<=D.config.particles.max)
            local kinds={};for i=1,D.count do kinds[D.pool[i].kind]=true end
            assert(kinds.ash and kinds.ember and kinds.smoke)
            assert(#D.points>0,"silhouette samples")
            if preset<3 then
                preset=preset+1;D.reset();game.monster.isBoss=preset==3;game.monster.isElite=preset==2
                D.startEnemy(game.monster,640,R.quality);elapsed=0;captured=false
            else
                print("Death VFX mini/elite/boss runtime PASS")
                D.reset();cb.previewPlayerDefeat();phase=2;elapsed=0;captured=false
            end
        end
    elseif phase==2 then
        local _,state=cb.getScoringState()
        if D.age>0.64 and not captured then shot("player_collapse");captured=true end
        if elapsed>1.9 then
            assert(state=="gameover","defeat must settle into existing gameover")
            assert(D.ambience and D.text and D.burst)
            shot("player_settled");print("Death VFX player runtime PASS");phase=3;elapsed=0
            if previewOnly then love.event.quit(0);phase=99 end
        end
    elseif phase==3 then
        case=case+1;D.reset();cb.startNewGame("red_deck");cb.startMonsterEncounter(1,case==2)
        cb.setScoringSpeed(case%2==0)
        game.monster.hp=(case<=2) and 1 or 100000
        game.monster.maxHp,game.monster.damageLagHp=game.monster.hp,game.monster.hp
        game.monster.attackSpeed=case==3 and 999 or 0
        game.monster.attack=case==6 and 0 or 10
        game.playerHp=(case>=3 and case<=5) and 1 or 100
        game.maxPlayerHp=100;game.playerArmor=0;game.playerShield=0;game.deities={}
        local card=require("src.deck").newCard(8,"hearts")
        card.visualX,card.visualY=585,466
        game.hand={card};game.deck={};game.discardPile={};game.selectedIndices={}
        game.handsRemaining=case==6 and 1 or 3
        if case==6 then game.monster.isBoss=true;game.monster.bossData={id="the_needle",debuffId="the_needle"} end
        originalGold=game.gold;encounters=game.monsterEncounterCount
        if case==5 then
            game.hand={};game.deck={require("src.deck").newCard(9,"hearts")};assert(cb.endPlayerTurn())
        else cb.selectCardIndex(1);cb.playSelectedHand() end
        local anim=cb.getScoringState();expected=anim.scoringData and anim.scoringData.finalScore
        lastHp=game.monster.hp;impacts=0;seen=false;phase=4;elapsed=0;captured=false
    elseif phase==4 then
        local anim,state=cb.getScoringState()
        if game.monster.hp~=lastHp then impacts=impacts+1;lastHp=game.monster.hp end
        if D.kind then seen=true end
        if D.kind and D.age>0.56 and not captured then shot("real_"..cases[case]);captured=true end
        if case<=2 then
            if D.enemyActive(game.monster) and D.busy() then
                assert(state=="scoring","reward UI must wait for ash settle")
                local hands=game.handsRemaining;love.keypressed("return");love.mousepressed(10,10,1)
                assert(game.handsRemaining==hands,"input blocked during death")
            end
            if state~="scoring" then
                assert(seen and game.monster.hp==0);assert(impacts==1)
                assert(anim.damageDealt==expected,"unchanged actual damage")
                assert(game.monsterEncounterCount==encounters+1,"victory applied once")
                assert(state=="CASH_OUT" and game.gold>=originalGold,"existing reward flow")
                print("Death integration "..cases[case].." PASS")
                phase=3;elapsed=0
            end
        elseif state=="gameover" then
            assert(seen and D.kind=="player");assert(not D.busy())
            assert(case==6 or game.playerHp==0);assert(game.gold==originalGold,"defeat does not award gold")
            if case==3 then assert(#D.cards==1,"pre-score cards preserved") end
            print("Death integration "..cases[case].." PASS")
            if case<#cases then phase=3 else phase=5 end;elapsed=0
        end
    elseif phase==5 then
        D.reset();cb.startMonsterEncounter(20,true);R.setQuality(qualities[qualityIndex])
        D.startEnemy(game.monster,640,R.quality);samples={};phase=6;elapsed=0
    elseif phase==6 then
        if elapsed>0.10 then samples[#samples+1]=love.timer.getDelta()*1000 end
        assert(D.count<=D.config.particles[qualities[qualityIndex]])
        if not D.busy() then
            table.sort(samples);local total=0;for _,v in ipairs(samples) do total=total+v end
            local f=assert(io.open("docs/death_performance.log",qualityIndex==1 and "wb" or "ab"))
            local line=string.format("%s: %d frames, mean %.2f ms, p95 %.2f ms\n",qualities[qualityIndex],#samples,total/#samples,samples[math.ceil(#samples*0.95)])
            f:write(line);f:close();print(line)
            if qualityIndex<3 then qualityIndex=qualityIndex+1;phase=5 else phase=7 end;elapsed=0
        end
    elseif phase==7 then
        savedShader=D.shader;D.shader=nil;D.reset();cb.startMonsterEncounter(20,true)
        D.startEnemy(game.monster,640,R.quality);phase=8;elapsed=0;captured=false
    elseif phase==8 then
        if D.age>0.45 and not captured then shot("fallback");captured=true end
        if not D.busy() then
            D.shader=savedShader
            for _,hook in ipairs({"enemy_death_hit","enemy_ash_break","defeat_hit","defeat_collapse","defeat_ambience","defeat_text_reveal"}) do assert(Sound.has(hook),hook) end
            print("Death VFX quality/fallback/audio PASS");love.event.quit(0);phase=99
        end
    end
end
return T

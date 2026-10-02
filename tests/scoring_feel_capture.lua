-- lovec.exe . --test-scoring-feel : real calculator, renderer, audio, input and combat lifecycle.
local UI = require("src.ui")
local Feel = UI.ScoringFeel
local Deck = require("src.deck")
local Deities = require("src.deities")
local Effects = require("src.card_effects")
local Test = {}
local case, stage, deadline, started, previousHp, expected, transitions = 0, "start", 0, 0, 0, 0, {}
local impacts, lastHp, frameCount, frameTime = 0, nil, 0, 0
local screenshots = {}
local function snapshot(name)
    if screenshots[name] then return end
    screenshots[name] = true
    love.graphics.captureScreenshot(function(data)
        local file = assert(io.open(name, "wb"))
        file:write(data:encode("png"):getString()); file:close()
    end)
end

function Test.update(game, callbacks)
    local now = love.timer.getTime()
    if now < deadline then return end
    if stage=="start" then
        case=case+1
        callbacks.startNewGame("red_deck")
        callbacks.startMonsterEncounter(1,false)
        callbacks.setScoringSpeed(case==2)
        game.maxHandSize=5
        game.unlockedHands={high_card=true,pair=true,three_of_a_kind=true,straight=true,flush=true,full_house=true,straight_flush=true}
        game.playerHp, game.maxPlayerHp = 100,100
        game.monster.hp, game.monster.maxHp, game.monster.damageLagHp = case==4 and 21 or 1000000,1000000,1000000
        game.monster.attackSpeed=case==3 and 999 or 1
        game.monster.isBoss=case==3
        if case==3 then game.monster.bossData={modifyDamage=function(value) return math.floor(value*0.5) end} end
        game.hand, game.deck, game.discardPile, game.selectedIndices = {},{},{},{}
        local count=(case==1 or case==4) and 1 or 5
        for i=1,count do
            local card=Deck.newCard(i+7,case==1 and "hearts" or "spades")
            Effects.setEffect(card,({"foil","holographic","polychrome"})[(i-1)%3+1])
            if case~=1 then
                card.equipments={{name="Gem capture",onCardScore=function() return {addChips=25,addMult=3} end}}
                card.enhancement="enh_blood"
            end
            game.hand[i]=card
        end
        game.deities={}
        if case~=1 then
            game.deities={Deities.CATALOG.spirit_blade,Deities.CATALOG.thunder_drum,
                {id="lab_multiplier",name="SPN test ×8",rarity="common",onHandScored=function() return {xMult=8} end}}
        end
        previousHp=game.monster.hp
        for i=1,count do callbacks.selectCardIndex(i) end
        callbacks.playSelectedHand()
        local anim,state=callbacks.getScoringState()
        assert(state=="scoring" and anim.active)
        expected=case==3 and math.floor(anim.scoringData.finalScore*0.5) or anim.scoringData.finalScore
        assert(game.monster.hp==previousHp,"HP must stay unchanged at play")
        local hands=game.handsRemaining
        callbacks.playSelectedHand()
        assert(game.handsRemaining==hands,"repeat Play Hand must be blocked")
        started,stage,impacts,lastHp=now,"scoring",0,previousHp
        transitions={}
    elseif stage=="scoring" then
        local anim,state=callbacks.getScoringState()
        local seq=anim.sequence
        local ev=seq.events[seq.index]
        if ev then transitions[ev.kind]=true end
        if not seq.impactDispatched then
            assert(game.monster.hp==previousHp and seq.hp==previousHp,"HP reduction before projectile impact")
        end
        if game.monster.hp~=lastHp then impacts=impacts+1;lastHp=game.monster.hp end
        if ev and ev.kind=="AURA_COUNT" and seq.age>0.12 then snapshot("shot_scoring_build_"..case..".png") end
        if ev and ev.kind=="CONVERGENCE" and seq.age>ev.duration*0.45 then snapshot("shot_scoring_energy_"..case..".png") end
        if ev and ev.kind=="ATTACK" and seq.age>ev.duration*0.50 then snapshot("shot_scoring_attack_"..case..".png") end
        if ev and ev.kind=="SETTLE" then snapshot("shot_scoring_impact_"..case..".png") end
        frameCount,frameTime=frameCount+1,frameTime+love.timer.getDelta()
        if state~="scoring" then
            assert(seq.finished and seq.damageApplied,"unlock only after settle")
            assert(impacts==1,"damage must apply once")
            assert(anim.damageDealt==expected,"real damage includes boss conversion")
            assert(game.monster.hp==math.max(0,previousHp-expected))
            assert(transitions.BASE_DAMAGE and transitions.BASE_ENHANCE and transitions.AURA_COUNT
                and transitions.ENERGY_CONVERSION and transitions.ATTACK and transitions.ENEMY_IMPACT)
            print(string.format("Real scoring case %d passed: %d AURA / %d actual damage / %.2fs",case,seq.result.finalScore,expected,now-started))
            if case<4 then stage,deadline="start",now+0.15
            else
                stage="lab"; love.keypressed("f6"); love.keypressed("5")
                deadline=now+0.05
                assert(Feel.labOpen and Feel.labAnim)
                previousHp,expected=game.playerHp,game.gold
            end
        end
        assert(now-started<25,"runtime sequence timed out")
    elseif stage=="lab" then
        assert(game.playerHp==previousHp and game.gold==expected,"Lab must not mutate the run")
        if Feel.isFinished(Feel.labAnim) then
            snapshot("shot_scoring_lab.png")
            love.keypressed("f6")
            assert(not Feel.labOpen)
            print(string.format("LÖVE scoring renderer/audio/input/HP lifecycle and isolated Feel Lab passed; mean frame %.2fms over %d frames",frameTime/math.max(1,frameCount)*1000,frameCount))
            stage,deadline="quit",now+0.25
        end
    elseif stage=="quit" then love.event.quit(0) end
end
return Test

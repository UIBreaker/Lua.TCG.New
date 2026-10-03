local UI=require("src.ui")
local F=UI.ScoringFeel
local D=require("src.deck")
local R=require("render.renderer")
local T={}
local case,started,lastHp,hits,expected=0,nil,0,0,0
local presets={{14},{8,8},{8,8,11,11},{8,8,8},{7,8,9,10,11},{2,5,8,11,14},{8,8,8,11,11},{8,8,8,8},{10,11,12,13,14}}
function T.update(game,cb)
    if not started then
        if case==0 then require("tests.hd2d_smoke") end
        case=case+1
        if case>9 then print("All nine real combat attack profiles/HP/input/quality/shaders passed");love.event.quit(0);return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setScoringSpeed(case%2==0)
        R.setQuality(({"LOW","MEDIUM","HIGH"})[(case-1)%3+1])
        game.maxHandSize=5;game.unlockedHands={}
        for _,id in ipairs(F.Attacks.config.order) do game.unlockedHands[id]=true end
        game.hand,game.deck,game.discardPile,game.selectedIndices={},{},{},{}
        local id=F.Attacks.config.order[case]
        for i,rank in ipairs(presets[case]) do game.hand[i]=D.newCard(rank,(id=="flush" or id=="straight_flush") and "spades" or ({"spades","hearts","clubs","diamonds"})[(i-1)%4+1]) end
        game.monster.hp,game.monster.maxHp,game.monster.damageLagHp=10000000,10000000,10000000
        game.monster.targetAura=1;game.monster.attackSpeed=1;game.deities={}
        for i=1,#game.hand do cb.selectCardIndex(i) end
        game.abilityApproved={} -- Default decisions in isolated capture; no interactive prompt.
        cb.playSelectedHand()
        local anim,state=cb.getScoringState()
        assert(state=="scoring" and anim.sequence.attack.profile.id==id, "case "..case.." state "..state.." profile "..tostring(anim.sequence and anim.sequence.attack.profile.id))
        expected=anim.scoringData.finalScore;lastHp=game.monster.hp;hits=0;started=love.timer.getTime()
        local hands=game.handsRemaining;cb.playSelectedHand();assert(game.handsRemaining==hands)
    else
        local a,state=cb.getScoringState();local s=a.sequence
        if not s.impactDispatched then assert(game.monster.hp==10000000) end
        if game.monster.hp~=lastHp then hits=hits+1;lastHp=game.monster.hp end
        assert(love.timer.getTime()-started<25)
        if state~="scoring" then
            assert(s.finished and s.damageApplied and hits==1 and a.damageDealt==expected)
            assert(game.monster.hp==10000000-expected)
            assert(#R.post.diagnostics==0,"world shader compilation fallback")
            print("Real combat "..s.attack.profile.id.." / "..R.quality.." passed")
            started=nil
        end
    end
end
return T

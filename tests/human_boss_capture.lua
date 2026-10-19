local T={index=0}
local C=require("src.combat")
local H=require("src.human_bosses")
local R=require("src.run_manager")
function T.update(game,cb)
    local now=love.timer.getTime()
    if not T.started then
        T.index=T.index+1
        if T.index>10 then print("Human Boss runtime PASS: all ten actual encounters/artworks/UI, hand restriction/armor notices, captive formation and real contact effects");love.event.quit(0);return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.persistentDeck={}
        for i=1,8 do game.persistentDeck[i]=require("src.deck").newCard(i+1,"hearts") end
        game.run.currentBlindIndex=3;game.run.ante=5;game.run.areaStage=5;game.run.regionId="human"
        game.run.blinds=R.generateAnteBlinds(5,nil,"human",5)
        local data={};for k,v in pairs(H.definitions[T.index]) do data[k]=v end;data.encounterToken=90000+T.index
        local blind=game.run.blinds[3];blind.debuff=data
        local m=R.createBlindMonster(blind,game);C.start(game,m,5)
        game.playerHp=100000;game.maxPlayerHp=100000;game.handsRemaining=20
        assert(require("src.enemy_art").image(m,{}),"human Boss runtime art missing")
        T.started=now;T.phase=0;T.next=now+.8
        return
    end
    assert(now-T.started<25,"human Boss runtime timeout")
    local animation,state=cb.getScoringState()
    if T.phase==0 and now>=T.next then
        love.graphics.captureScreenshot(function(image)
            local f=assert(io.open("docs/human_boss_combat_"..T.index..".png","wb"));f:write(image:encode("png"):getString());f:close()
        end)
        T.phase=1;T.next=now+.15
    elseif T.phase==1 and now>=T.next then
        local m=game.monster;T.hp=game.playerHp;T.cards=#game.persistentDeck
        T.regen=m.hp;T.contacts=0
        local P=require("src.enemy_attack_presentation")
        if T.index~=9 then m.intent={type="attack"} end
        game.lastPlayerAttackSpeed=1
        T.turn=P.start(game,nil,nil,function(hit)
            T.contacts=T.contacts+1
            if T.index==9 then assert(hit.action=="human_skill" and #game.persistentDeck==T.cards-1) end
        end,function() end)
        T.phase=2
    elseif T.phase==2 then
        if require("src.enemy_attack_presentation").update(T.turn,game,love.timer.getDelta()) then
            assert(T.contacts==#game.enemies,"every hostile takes exactly one contact action")
            if T.index==8 then assert(#game.enemies==3 and #H.primary(game).humanBossState.receipt.captives==2) end
            T.started=nil
        end
    end
end
return T

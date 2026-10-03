local T={};local step="start";local deadline=0;local started=0;local kills=0;local case=1
local Debug=require("src.debug_tools")
local Deck=require("src.deck")
local Group=require("src.enemy_group")
local function click(x,y)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    love.mousepressed((w-1280*s)/2+x*s,(h-720*s)/2+y*s,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/expedition/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function exportCards()
    local Art=require("src.enemy_art")
    local Trait=require("src.enemy_abilities")
    local Monster=require("src.monster")
    for _,list in ipairs({Art.normal,Art.bosses}) do
        for _,key in ipairs(list) do
            local m=Monster.create(41,false,false,1)
            m.artKey=key;m.isBoss=list==Art.bosses;Trait.attach(m)
            local ranks=m.isBoss and {11,12,13} or {2,13}
            for _,rank in ipairs(ranks) do
                m.cardRank=rank
                local canvas=assert(require("ui.enemy_card").image(m,Art.images[key]));local data=canvas:newImageData()
                local path="assets/scene/enemy_cards/"..key.."_"..rank..".png"
                local f=assert(io.open(path,"wb"));f:write(data:encode("png"):getString());f:close();data:release()
            end
        end
    end
end
function T.update(game,cb)
    local now=love.timer.getTime()
    assert(started==0 or now-started<90,"enemy-group real scoring timeout: "..step)
    if now<deadline then return end
    if step=="start" then
        started=now
        require("tests.enemy_group_smoke");exportCards()
        cb.startNewGame("red_deck")
        game.persistentDeck={}
        for i=1,9 do local c=Deck.newCard(8,"spades");c.disableFactionPassives=true;game.persistentDeck[i]=c end
        game.maxHands=8;game.maxHandSize=3;game.maxPlayerHp=200;game.playerHp=200
        Debug.setAnte(game,case==1 and 3 or 42,1);cb.setCaptureState("BLIND_SELECT")
        step="fight";deadline=now+0.8
    elseif step=="fight" then
        click(224,591);assert(#game.enemies==3)
        for _,m in ipairs(game.enemies) do m.hp=1;m.maxHp=1;m.damageLagHp=1;m.attackSpeed=1 end
        -- Second case includes the skeleton's real one-time resurrection.
        local x,y,w,h=Group.rect(3,3);click(x+w/2,y+h/2)
        assert(game.monster==game.enemies[3],"real click must select the third enemy")
        step="portrait";deadline=now+0.8
    elseif step=="portrait" then
        shot(case==1 and "human_group_3" or "monster_group_3")
        step="play";deadline=now+0.1
    elseif step=="play" then
        cb.selectCardIndex(1);cb.playSelectedHand()
        local _,state=cb.getScoringState();assert(state=="scoring","must start actual score animation")
        step="settle";deadline=now+0.1
    elseif step=="settle" then
        local _,state=cb.getScoringState()
        if state=="playing" then
            assert(Group.alive(game.enemies)>0)
            assert(game.run.stats.blindsWon==0 and game.run.blinds[1].status=="current","partial kills cannot grant victory")
            assert(game.monster.hp>0,"target advances to a survivor")
            kills=kills+1;step="play";deadline=now+0.1
        elseif state=="CASH_OUT" then
            assert(Group.alive(game.enemies)==0 and game.run.stats.blindsWon==1,"all kills grant exactly one reward")
            assert(kills>=(case==1 and 2 or 3),"all three enemies and resurrection must resolve through real scoring")
            shot(case==1 and "human_group_reward" or "monster_group_reward")
            if case==1 then case=2;kills=0;step="restart";deadline=now+0.2
            else step="done";deadline=now+0.4 end
        end
    elseif step=="restart" then step="start"
    elseif step=="done" then print("Enemy group real capture passed: 3 targets, targeted scoring, 6 kills + resurrection, reward once, 57 exported cards");love.event.quit() end
end
return T

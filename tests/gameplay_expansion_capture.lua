-- Real LÖVE input/render/scoring exercise. Never reads or writes the player's save.
local UI=require("src.ui")
local Deck=require("src.deck")
local A=UI.Abilities
local Boss=UI.BossAbilities
local Run=require("src.run_manager")
local Layout=require("ui.layout")
local Test={}
local stage="start";local deadline=0;local started=0;local target;local cards
local function click(x,y,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    love.mousepressed((w-1280*s)/2+x*s,(h-720*s)/2+y*s,button or 1)
    love.mousereleased((w-1280*s)/2+x*s,(h-720*s)/2+y*s,button or 1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open(name,"wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function nextStage(name,delay) stage=name;deadline=love.timer.getTime()+(delay or 0.12) end
function Test.update(game,callbacks)
    if love.timer.getTime()<deadline then return end
    if stage=="start" then
        callbacks.startNewGame("red_deck")
        game.persistentDeck={Deck.newCard(12,"hearts")}
        for _,suit in ipairs({"hearts","diamonds","clubs","spades"}) do
            for rank=2,14 do game.persistentDeck[#game.persistentDeck+1]=Deck.newCard(rank,suit) end
        end
        for _,c in ipairs(game.persistentDeck) do c.disableFactionPassives=true;c.isWildSuit=false;c.isDualRankAce=false end
        target=game.persistentDeck[1];game.maxHandSize=5
        callbacks.startMonsterEncounter(5,true)
        game.monster.bossData=Boss.newDefinitions.memory_eater;Boss.start(game);Boss.handStart(game)
        game.monster.hp=1000000;game.monster.maxHp=1000000;game.monster.attackSpeed=1
        game.playerHp=100;game.consumables={Run.createEvolutionCard()}
        nextStage("open_evolution")
    elseif stage=="open_evolution" then
        local x,y,w,h=Layout.fanCardRect(Layout.battle.consumables,1,3)
        click(x+w/2,y+h/2,2)
        assert(UI.AbilityUI.current and UI.AbilityUI.current.mode=="evolution","right click must open evolution")
        nextStage("select_evolution")
    elseif stage=="select_evolution" then
        local m=UI.AbilityUI.current
        assert(#m.cards==53,"all owned standard instances eligible")
        click(245,220)
        assert(m.selected==target)
        nextStage("preview")
    elseif stage=="preview" then
        shot("shot_expansion_evolution.png")
        assert(target.evolutionLevel==0 and #game.consumables==1,"preview must not consume or upgrade")
        nextStage("confirm")
    elseif stage=="confirm" then
        click(900,625)
        assert(target.evolutionLevel==1 and #game.consumables==0,"confirmation must upgrade and consume once")
        assert(target.rank==12 and A.definition(target).suit=="heart")
        print("[PASS] Evolution: right-click, 53 instances, live preview, confirm, identity preserved")
        cards={Deck.newCard(2,"spades"),Deck.newCard(2,"hearts")}
        for _,c in ipairs(cards) do c.disableFactionPassives=true;c.isWildSuit=false end
        game.hand={cards[1],cards[2]};game.deck={};game.discardPile={};game.selectedIndices={};game.handsRemaining=4
        game.unlockedHands={high_card=true,pair=true};game.persistentDeck={Deck.cloneCard(cards[1]),Deck.cloneCard(cards[2])}
        A.start(game);Boss.start(game);Boss.handStart(game)
        callbacks.selectCardIndex(1);callbacks.selectCardIndex(2)
        nextStage("choice")
    elseif stage=="choice" then
        callbacks.playSelectedHand()
        assert(UI.AbilityUI.current and UI.AbilityUI.current.mode=="choices")
        assert(game.handsRemaining==4 and #game.hand==2,"prompt must not commit a hand")
        love.keypressed("escape")
        assert(not UI.AbilityUI.current and game.handsRemaining==4 and #game.hand==2,"cancel must be safe")
        callbacks.playSelectedHand()
        nextStage("approve")
    elseif stage=="approve" then
        shot("shot_expansion_choice.png")
        nextStage("commit")
    elseif stage=="commit" then
        click(245,220)
        local anim,state=callbacks.getScoringState();assert(state=="scoring" and anim.active)
        started=love.timer.getTime();nextStage("scoring",0)
    elseif stage=="scoring" then
        local anim,state=callbacks.getScoringState()
        if state=="playing" then
            assert(#game.persistentDeck==1,"chosen destruction must remove exactly one instance")
            assert(game.persistentDeck[1].id==cards[2].id and game.persistentDeck[1].evolutionLevel==1,"survivor upgrade saved by ID")
            assert(#game.hand==0,"2 hearts returns its partner, not itself; the destroyed partner must stay destroyed")
            shot("shot_expansion_boss.png")
            print("[PASS] Choice cancel, selected destruction, real scoring/energy attack, upgrade persistence, return-hand integrity")
            nextStage("done",0.2)
        elseif love.timer.getTime()-started>35 then error("scoring lifecycle timeout") end
    elseif stage=="done" then
        print("Gameplay expansion real LÖVE capture passed")
        love.event.quit(0)
    end
end
return Test

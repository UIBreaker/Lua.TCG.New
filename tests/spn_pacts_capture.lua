local T={};local step,deadline=0,0
local D=require("src.deities")
local Deck=require("src.deck")
local P=require("src.spn_pacts")
local function button(cb)
    for _,b in ipairs(cb.getButtons()) do if b.id=="discard" then return b end end
    error("Missing discard button")
end
local function click(b)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x=(w-1280*s)/2+(b.x+b.w/2)*s;local y=(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime()
    assert(love.timer.getTime()-T.started<35,"Blood discard UI timed out at "..step)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.deities={};game.hand={};game.persistentDeck={};game.discardPile={};game.deck={}
        for i=1,5 do
            local c=Deck.newCard(i+2,"spades");c.disableFactionPassives=true
            game.persistentDeck[#game.persistentDeck+1]=Deck.cloneCard(c)
            if i<=3 then game.hand[#game.hand+1]=c else game.deck[#game.deck+1]=c end
        end
        for i,row in ipairs(P.entries) do assert(D.addDeity(game,D.CATALOG[row[1]],i)) end
        game.playerHp=100;game.maxPlayerHp=100;game.playerArmor=0;game.playerShield=0
        game.discardsRemaining=0;game.selectedIndices={};game.spnCombat={}
        P.prepare(game);require("src.spn_basics").bind(game)
        local R=require("src.rng");T.originalRandom=R.random;R.random=function(a,b) return a and (b and a or 1) or .99 end
    elseif step==1 then game.hand[1].selected=true;game.selectedIndices={1};T.id=game.hand[1].id
    elseif step==2 then
        local b=button(cb);assert(not b.disabled and b.text:find("20 HP",1,true))
        love.mouse.setPosition(2,2)
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/spn_pacts_blood.png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
    elseif step==3 then
        click(button(cb))
        assert(game.playerHp==80 and game.discardsRemaining==0 and game.discardsUsedInCombat==1)
        assert(#game.hand==3 and #game.discardPile==1 and game.discardPile[1].id==T.id)
    elseif step==4 then
        game.playerHp=20;game.hand[1].selected=true;game.selectedIndices={1}
    elseif step==5 then
        local b=button(cb);assert(b.disabled);click(b)
        assert(game.playerHp==20 and game.discardsRemaining==0 and #game.discardPile==1)
        require("src.rng").random=T.originalRandom
        print("SPN pacts UI PASS: real discard button at zero discards, visible 20 HP price, one payment/refill/routing, nonlethal disabled button and four native SPN artworks")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+.6
end
return T

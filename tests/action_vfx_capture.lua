local F=require("src.combat_feedback")
local UI=require("src.ui")
local P=UI.Polish
local Deck=require("src.deck")
local Equipment=require("src.equipment")
local kinds={"armor_gain","armor_loss","heal","hurt","equip","destroy","enemy_first","player_first","buy","sell"}
local T={};local stage=0;local began;local fired;local captured=false
local function has(kind) for _,e in ipairs(F.vfx) do if e.kind==kind then return true end end end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open("docs/action_vfx/"..name..".png","wb"));file:write(data:encode("png"):getString());file:close()
    end)
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if not began then
        stage=stage+1
        if stage>9 then print("Action VFX GPU PASS: actual HP/armor, equip contact, ability destruction, both attack priorities; 10-profile render and graphics-state restoration");love.event.quit(0);return end
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false);cb.setScoringSpeed(false)
        game.playerHp=70;game.playerArmor=20;game.playerShield=20
        game.hand={Deck.newCard(8,"spades")};game.persistentDeck={game.hand[1],Deck.newCard(5,"clubs")};game.selectedIndices={};game.deities={}
        P.applications={};P.job=nil;P.clearFocus()
        local a=cb.getScoringState();a.active=false;a.enemyTurn=nil;a.hitStop=0
        began=now;fired=false;captured=false
    elseif not fired and now-began>0.35 then
        F.clearVfx()
        if stage==1 then game.playerArmor=35;game.playerShield=35
        elseif stage==2 then game.playerArmor=5;game.playerShield=5
        elseif stage==3 then game.playerHp=90
        elseif stage==4 then game.playerHp=50
        elseif stage==5 then local before=P.snapshot(game);assert(Equipment.attach(game.hand[1],Equipment.ITEMS.gem_fire));P.changed(UI,game,before,Equipment.ITEMS.gem_fire)
        elseif stage==6 then UI.Abilities.destroy(game,game.hand[1]);assert(game.hand[1].destroyed)
        elseif stage==7 or stage==8 then
            for _,m in ipairs(game.enemies) do m.attackSpeed=stage==7 and 99 or 0.01;m.hp=10000000;m.maxHp=m.hp end
            game.abilityApproved={};cb.selectCardIndex(1);cb.playSelectedHand()
            assert(has(stage==7 and "enemy_first" or "player_first"))
        else
            local original=love.draw
            love.draw=function(...)
                original(...)
                local g=love.graphics;g.push("all");g.origin()
                local w,h=g.getDimensions();g.translate((w-1280*math.min(w/1280,h/720))/2,(h-720*math.min(w/1280,h/720))/2);g.scale(math.min(w/1280,h/720))
                g.setColor(0.015,0.023,0.04,0.96);g.rectangle("fill",30,50,1220,590,14,14)
                for i,kind in ipairs(kinds) do
                    local x=150+((i-1)%5)*245;local y=165+math.floor((i-1)/5)*265
                    g.setColor(0.10,0.15,0.21,1);g.rectangle("fill",x-105,y-75,210,190,12,12)
                    g.setFont(UI.fonts.small);g.setColor(0.85,0.9,1,1);g.printf(kind,x-105,y+75,210,"center")
                end
                local blend,alpha=g.getBlendMode();local red,green,blue,a=g.getColor()
                F.drawVfx(UI)
                assert(g.getBlendMode()==blend,"blend mode leaked")
                local r,gg,b,aa=g.getColor();assert(r==red and gg==green and b==blue and aa==a,"color leaked")
                g.pop()
            end
            for i,kind in ipairs(kinds) do F.emit(kind,150+((i-1)%5)*245,165+math.floor((i-1)/5)*265,10) end
        end
        fired=now
    elseif fired and not captured then
        local elapsed=now-fired
        local expected=({"armor_gain","armor_loss","heal","hurt","equip","destroy"})[stage]
        if expected and elapsed>(stage==5 and P.config.application*0.60+0.12 or 0.10) then assert(has(expected),"missing real event "..expected) end
        if elapsed>(stage==5 and P.config.application*0.60+0.20 or 0.24) then
            if stage==5 or stage==9 then shot(stage==9 and "all_profiles" or "equip") end
            captured=true
        end
    elseif captured and now-fired>1.3 then began=nil end
end
return T

local T={index=0}
local W=require("src.free_human_bosses")
local Run=require("src.run_manager")
local D=require("src.deck")
local function gallery()
    local g=love.graphics;local UI=require("src.ui");local Core=require("ui.components.core")
    local Frame=require("ui.components.card_frame");local Art=require("src.enemy_art")
    local canvas=g.newCanvas(1400,900);g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.clear(.018,.027,.04,1)
    Core.text("HAI KẺ VIỄN CHINH · BOSS TỰ DO",25,23,1350,UI.fonts.large,{.94,.78,.48},"center")
    for i=1,2 do
        local def=W.definitions[i]
        local blind=Run.generateAnteBlinds(7,nil,"human",7)[3];blind.debuff=def
        local m=Run.createBlindMonster(blind,{},true);local image=assert(Art.image(m,{}),def.id)
        local x=35+(i-1)*690
        require("ui.combat_chrome").panel(x,88,640,780,def.color)
        Frame.image(image,x+173,110,294,441);Frame.draw(x+173,110,294,441,nil,nil,m)
        Core.textLine(def.name,x+12,570,616,UI.fonts.large,def.color,"center",UI.fonts.medium)
        Core.text(def.desc,x+30,625,580,UI.fonts.small,{.81,.85,.86},"center")
        Core.text(def.active.name.."\n"..def.active.description,x+30,730,580,UI.fonts.small,{.94,.78,.48},"center")
    end
    g.pop();local data=canvas:newImageData();local f=assert(io.open("docs/free_human_boss_roster.png","wb"));f:write(data:encode("png"):getString());f:close();data:release();canvas:release()
end
function T.update(game,cb)
    if T.done then return end
    local now=love.timer.getTime()
    if not T.started then
        if T.index==0 then require("tests.free_human_bosses_smoke");gallery() end
        T.index=T.index+1
        if T.index>2 then T.done=true;print("Free human bosses UI PASS: human portraits, neutral K frames, live seals and devolution HUD");love.event.quit(0);return end
        local def=W.definitions[T.index]
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.run.ante=7;game.run.areaStage=7;game.run.regionId="unknown";game.run.currentBlindIndex=3
        game.run.blinds=Run.generateAnteBlinds(7,"red_deck","unknown",7);game.run.blinds[3].debuff=def
        local m=Run.createBlindMonster(game.run.blinds[3],game,true);require("src.combat").start(game,m,7)
        local c=D.newCard(5,"spades");c.evolutionLevel=2;game.hand={c,D.newCard(7,"hearts"),D.newCard(9,"clubs")}
        game.persistentDeck={};for _,card in ipairs(game.hand) do game.persistentDeck[#game.persistentDeck+1]=D.cloneCard(card) end
        game.unlockedHands={high_card=true,pair=true,straight=true,flush=true}
        W.finishHand(game,{handInfo={type={id="high_card"}},played={c}})
        if T.index==1 then assert(W.handBlocked(game,"high_card")) else assert(W.blocked(m,c));require("src.boss_abilities").handEnd(game);assert(c.evolutionLevel==1) end
        T.started=now;return
    end
    if now-T.started<1 then return end
    local index=T.index
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/free_human_boss_combat_"..index..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
    T.started=nil
end
return T

local T={index=0}
local K=require("src.kingdom_bosses")
local Run=require("src.run_manager")
local D=require("src.deck")
local A=require("src.enemy_abilities")
local function gallery()
    local g=love.graphics;local UI=require("src.ui");local Core=require("ui.components.core")
    local Frame=require("ui.components.card_frame");local Art=require("src.enemy_art")
    local canvas=g.newCanvas(1600,900);g.push("all");g.setCanvas(canvas);g.origin();g.setShader();g.setScissor();g.clear(.018,.027,.04,1)
    Core.text("BỐN VƯƠNG QUỐC · BỐN THỰC THỂ BÍ ẨN",25,23,1550,UI.fonts.large,{.94,.78,.48},"center")
    Core.text("BOSS TỰ DO · PHONG ẤN CHẤT · MỖI LÁ ĐÚNG CHẤT TRÊN TAY: +10% TỐC VÀ SÁT THƯƠNG",30,71,1540,UI.fonts.small,{.7,.77,.8},"center")
    for i,def in ipairs(K.definitions) do
        local b=Run.generateAnteBlinds(40,"red_deck",def.entitySuit,20)[3]
        local m=Run.createBlindMonster(b,{},true);local image=assert(Art.image(m,{}),"Missing entity art: "..def.id)
        local x=24+(i-1)*396
        require("ui.combat_chrome").panel(x,115,364,748,def.color)
        g.setColor(1,1,1,1);Frame.image(image,x+32,146,300,450);Frame.draw(x+32,146,300,450,nil,nil,m)
        Core.textLine(def.name,x+12,625,340,UI.fonts.medium,def.color,"center",UI.fonts.small)
        Core.text("PHONG ẤN CHẤT "..def.suitName,x+16,678,332,UI.fonts.small,def.color,"center")
        Core.text("Khóa điểm, khả năng và trang bị khi tính điểm.\nMỗi lá cùng chất trên tay bạn:\n+10% Tốc · +10% Sát thương.",x+20,721,324,UI.fonts.small,{.81,.85,.86},"center")
    end
    g.pop();local data=canvas:newImageData();local f=assert(io.open("docs/kingdom_entity_roster.png","wb"));f:write(data:encode("png"):getString());f:close();data:release();canvas:release()
end
function T.update(game,cb)
    local now=love.timer.getTime()
    if not T.started then
        if T.index==0 then require("tests.kingdom_bosses_smoke");gallery() end
        T.index=T.index+1
        if T.index>4 then print("Kingdom entities UI PASS: four unique runtime portraits/frames/suits, kingdom encounters, live 30% -> 20% -> 0% HUD and seals");love.event.quit(0);return end
        local def=K.definitions[T.index]
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        game.run.ante=40;game.run.areaStage=20;game.run.regionId=def.entitySuit;game.run.currentBlindIndex=3
        game.run.blinds=Run.generateAnteBlinds(40,"red_deck",def.entitySuit,20)
        game.run.blinds[3].debuff=def
        local m=Run.createBlindMonster(game.run.blinds[3],game,true);require("src.combat").start(game,m,40)
        game.hand={D.newCard(3,def.entitySuit),D.newCard(6,def.entitySuit),D.newCard(9,def.entitySuit),D.newCard(7,def.entitySuit=="hearts" and "clubs" or "hearts")}
        game.persistentDeck={};for _,c in ipairs(game.hand) do game.persistentDeck[#game.persistentDeck+1]=D.cloneCard(c) end
        assert(K.count(m)==3 and K.factor(m)==1.3)
        require("src.enemy_abilities").plan(game,m)
        T.started=now;T.next=now+1;T.phase=0;return
    end
    if now<T.next then return end
    local m=game.monster
    if T.phase==0 then
        love.graphics.captureScreenshot(function(data)
            local f=assert(io.open("docs/kingdom_entity_combat_"..T.index..".png","wb"));f:write(data:encode("png"):getString());f:close()
        end)
        local before=A.attack(m);table.remove(game.hand,1);assert(K.count(m)==2 and math.abs(A.attack(m)-before/1.3*1.2)<1e-6)
        require("src.enemy_abilities").plan(game,m);T.phase=1;T.next=now+.35
    else
        require("src.boss_abilities").disable(game,1);assert(K.count(m)==0 and not K.disabled(game,game.hand[1]))
        T.started=nil
    end
end
return T

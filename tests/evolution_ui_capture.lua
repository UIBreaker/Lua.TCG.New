local T={};local UI=require("src.ui");local Modal=UI.AbilityUI;local A=require("src.card_abilities")
local P=require("src.persistence");P.deleteRun=function() return true end;P.saveRun=function() return true end;P.saveSettings=function() return true end
local stage,age=0,0;local target,consumable
local function press(id,index)
    for _,b in ipairs(Modal.current.buttons) do if b.id==id and (not index or b.index==index) then Modal.press(b.x+b.w/2,b.y+b.h/2,1);return b end end
    error("missing button "..id)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data) local f=assert(io.open("docs/evolution_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close() end)
end
function love.errorhandler(message) print(debug.traceback(message,2));return function() return 1 end end
function T.update(game,cb)
    age=age+love.timer.getDelta();assert(age<10,"evolution UI timeout")
    if stage==0 then
        cb.startNewGame("red_deck");cb.setCaptureState("playing");love.mouse.setPosition(4,4)
        local Deck=require("src.deck");game.persistentDeck={}
        for _,suit in ipairs({"clubs","hearts","diamonds","spades"}) do for rank=2,5 do game.persistentDeck[#game.persistentDeck+1]=Deck.newCard(rank,suit) end end
        for _,c in ipairs(game.persistentDeck) do if A.definition(c) then target=c;target.evolutionLevel=0;break end end
        assert(target)
        local D=require("src.deities");game.deities={}
        for _,id in ipairs({"golden_joker","joker"}) do if D.CATALOG[id] then local c={};for k,v in pairs(D.CATALOG[id]) do c[k]=v end;game.deities[1]=c;break end end
        if not game.deities[1] then for _,v in pairs(D.CATALOG) do local c={};for k,a in pairs(v) do c[k]=a end;game.deities[1]=c;break end end
        consumable={id="cons_evolution",category="evolution",name="Tiến hóa"};game.consumables={consumable}
        assert(Modal.openEvolution(game,consumable));stage=1;age=0
    elseif stage==1 and age>0.25 then
        assert(press("confirm").disabled and not Modal.current.selected,"no selection cannot confirm")
        shot("picker");stage=1.5;age=0
    elseif stage==1.5 and age>0.2 then
        press("next");stage=2;age=0
    elseif stage==2 and age>0.2 then
        assert(Modal.current.page==2);press("prev");press("tab_deities");stage=3;age=0
    elseif stage==3 and age>0.2 then
        local i;for n,c in ipairs(Modal.current.cards) do if c==game.deities[1] then i=n end end
        press("target",assert(i));stage=4;age=0
    elseif stage==4 and age>0.2 then
        assert(Modal.current.selected==game.deities[1]);shot("patron");stage=4.5;age=0
    elseif stage==4.5 and age>0.2 then
        press("tab_cards");stage=5;age=0
    elseif stage==5 and age>0.2 then
        local i;for n,c in ipairs(Modal.current.cards) do if c==target then i=n end end
        press("target",assert(i));stage=6;age=0
    elseif stage==6 and age>0.2 then
        assert(target.evolutionLevel==0 and #game.consumables==1,"preview preserves reward")
        shot("selected");stage=7;age=0
    elseif stage==7 and age>0.2 then
        press("confirm");assert(not Modal.current and target.evolutionLevel==1 and #game.consumables==0)
        print("Evolution selection, tabs, pagination, preview and confirm PASS")
        game.consumables={consumable};assert(Modal.openEvolution(game,consumable));Modal.key("escape")
        assert(not Modal.current and #game.consumables==1);print("Evolution cancel preserves consumable PASS")
        love.event.quit(0);stage=99
    end
end
return T

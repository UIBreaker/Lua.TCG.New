local T={};local step,deadline=0,0
local UI=require("src.ui")
local I=require("ui.card_inspector")
local Deck=require("src.deck")
local E=require("src.equipment")
local function pointer(x,y,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    if button then love.mousepressed(px,py,button);love.mousereleased(px,py,button) end
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/inspector_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function checkLayout()
    assert(#I.columns==2)
    for column,l in ipairs(I.columns) do
        assert(l.x>=0 and l.y>=0 and l.x+l.w<=1280 and l.y+l.h<=720)
        local rows=column==1 and I.current.rows or I.current.equipment
        for i,r in ipairs(rows) do
            assert(not r.text:find("…",1,true),"Inspector must retain the full description")
            local bounds=l.rows[i];local _,lines=UI.fonts.small:getWrap(r.text,l.w-bounds.inset-23)
            assert(bounds.h>=bounds.nameH+bounds.labelH+#lines*(UI.fonts.small:getHeight()+3)+24)
        end
    end
end
function T.update(game,cb)
    if love.timer.getTime()<deadline then return end
    if step==0 then
        local draw,frame=I.draw,UI.CardFrame.draw
        I.draw=function(...)
            T.inspectorDraw=true;draw(...);T.inspectorDraw=false
        end
        UI.CardFrame.draw=function(x,y,w,h,highlight,alpha,card)
            if T.inspectorDraw and card and card.rank then T.frame={w=w,h=h} end
            return frame(x,y,w,h,highlight,alpha,card)
        end
        cb.startNewGame("red_deck");game.shopMode="cards";cb.openShop()
        T.simple=Deck.newCard(5,"aurelia");T.simple.equipments={E.ITEMS.basic_chain}
        T.long=Deck.newCard(12,"valoria");T.long.evolutionLevel=3;T.long.maxSockets=8;T.long.allowDuplicateEquipment=true
        T.long.edition="resonant";T.long.enhancement="enh_overcharged";T.long.seal="seal_echoes"
        T.long.temporaryAbilityLevels=1;T.long.abilityState={tacticCharge=4}
        T.long.equipments={}
        for _,id in ipairs({"gem_fire","gem_blast","mirror_adjacent","storm_eye","lucky_coin","ward_stone","vitality_gem","blood_ring"}) do T.long.equipments[#T.long.equipments+1]=E.ITEMS[id] end
        game.persistentDeck={T.simple,T.long};game.masterDeck=game.persistentDeck
        UI.Backpack.show();UI.Backpack.tab="cards"
        for _,suit in ipairs(Deck.SUIT_ORDER) do for rank=2,14 do
            local m=I.model(Deck.newCard(rank,suit),game)
            assert(#m.rows>0 and #m.equipment==4 and m.title:find(require("src.card_abilities").definition(m.item).name,1,true))
        end end
    elseif step==1 then
        local r=UI.Backpack.cellRect(1);pointer(r.x+r.w/2,r.y+r.h/2,2)
        assert(cb.getInspector()==T.simple)
    elseif step==2 then
        checkLayout();assert(I.current.item==T.simple and #I.current.equipment==4)
        assert(T.frame.w==210 and T.frame.h==315,"Portrait rim must follow the enlarged face, not the backpack card")
        assert(I.current.equipment[1].text==E.getDescription(E.ITEMS.basic_chain))
        assert(I.current.equipment[1].label:find(" · T",1,true) and I.current.equipment[1].label:find("1 hốc",1,true))
        pointer(20,690);shot("playing_card")
    elseif step==3 then
        love.keypressed("escape");assert(not cb.getInspector() and UI.Backpack.open)
        cb.openInspector(T.long)
    elseif step==4 then
        checkLayout();assert(I.columns[1].maxScroll>0 and I.columns[2].maxScroll>0 and #I.current.equipment==8)
        for i,r in ipairs(I.current.equipment) do assert(r.text==E.getDescription(T.long.equipments[i])) end
        pointer(600,400);love.wheelmoved(0,-999)
        assert(I.scroll[1]==I.columns[1].maxScroll and I.scroll[2]==0)
        pointer(1080,400);love.keypressed("end")
        assert(I.scroll[2]==I.columns[2].maxScroll)
    elseif step==5 then
        checkLayout();shot("all_effects")
    elseif step==6 then
        pointer(1080,400);love.keypressed("home");assert(I.scroll[2]==0)
        love.keypressed("pagedown");assert(I.scroll[2]>0)
        love.keypressed("pageup");assert(I.scroll[2]==0)
        pointer(1200,47,1);assert(not cb.getInspector())
        T.spn={};for k,v in pairs(require("src.deities").CATALOG.spirit_transmuter) do T.spn[k]=v end
        T.spn.enchantment="spell_bastion";T.spn.edition="polychrome";T.spn.evolutionLevel=2
        cb.openInspector(T.spn)
    elseif step==7 then
        checkLayout();assert(I.scroll[1]==0 and I.scroll[2]==0 and I.current.body:find("PHÙ PHÉP",1,true))
        shot("spn")
    elseif step==8 then
        pointer(600,400,2);assert(not cb.getInspector())
        cb.openInspector(E.ITEMS.void_catalyst)
    elseif step==9 then
        checkLayout();assert(I.current.body:find("2 hốc",1,true));shot("equipment")
    elseif step==10 then
        cb.openInspector(require("src.shop").healingItem(nil,"cons_armor_break").consumable)
    elseif step==11 then
        checkLayout();shot("potion")
        local n,coins=#game.persistentDeck,game.gold
        pointer(400,200,1);assert(cb.getInspector() and #game.persistentDeck==n and game.gold==coins)
        love.keypressed("escape");assert(not cb.getInspector() and UI.Backpack.open)
        print("Card inspector PASS: fullscreen bounds, real backpack entry, all 52 abilities, complete 8-item effects, upgrades/modifiers/state, independent wheel + keyboard scrolling, SPN enchantments, equipment, potions, close/input isolation")
        love.event.quit(0)
    end
    step=step+1;deadline=love.timer.getTime()+(step==1 and 1.6 or .4)
end
return T

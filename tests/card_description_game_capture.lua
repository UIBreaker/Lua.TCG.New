local T={}
local age,card,pointed,stage=0,nil,false,0
local expanded=false
local eight
local panel
local function screenshot(path,done)
    love.graphics.captureScreenshot(function(data)
        local file=assert(io.open(path,"wb"))
        file:write(data:encode("png"):getString());file:close()
        done()
    end)
end
function T.update(game,cb)
    age=age+love.timer.getDelta()
    assert(age<16,"description capture timed out")
    if not card then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        local Deck=require("src.deck");local Equipment=require("src.equipment")
        card=Deck.newCard(2,"clubs");card.speedBonus=14-Deck.getCardAttackSpeed(card)
        card.equipments={Equipment.ITEMS.basic_pouch,Equipment.ITEMS.basic_salve,Equipment.ITEMS.basic_bandage}
        card.edition="resonant";card.enhancement="enh_overcharged"
        eight=Deck.newCard(12,"hearts");eight.maxSockets=8;eight.equipments={}
        for _,id in ipairs({"gem_fire","gem_blast","mirror_adjacent","storm_eye","lucky_coin","ward_stone","vitality_gem","blood_ring"}) do
            eight.equipments[#eight.equipments+1]=Equipment.ITEMS[id]
        end
        local View=require("ui.components.card_description")
        local render=View.draw
        View.draw=function(m,l,x,y,scroll)
            panel={model=m,layout=l,x=x,y=y,scroll=scroll,at=age}
            render(m,l,x,y,scroll)
        end
        local isDown=love.keyboard.isDown
        love.keyboard.isDown=function(...)
            for _,key in ipairs({...}) do if (key=="lshift" or key=="rshift") and expanded then return true end end
            return isDown(...)
        end
        game.hand={card};love.mouse.setPosition(2,2)
    elseif not pointed and age>0.8 then
        local s=assert(require("src.ui").CardPhysics.getState(card),"live card renderer")
        local x=s.ox+s.a*s.w*.5+s.c*s.h*.5
        local y=s.oy+s.b*s.w*.5+s.d*s.h*.5
        local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
        love.mouse.setPosition((w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale)
        pointed=true
    elseif pointed and stage==0 and age>2 then
        assert(panel and not panel.model.expanded and panel.layout.maxScroll==0 and not panel.layout.summarized and panel.layout.w==400 and panel.layout.h<=520,"reported three-item card stays compact with every effect visible")
        for _,row in ipairs(panel.layout.rows) do assert(row.x==0 and not row.summary,"default no longer expands into columns") end
        stage=0.5
        screenshot("docs/card_description_combat.png",function()
            card.equipments=eight.equipments;card.maxSockets=8
            expanded=true;stage=1
        end)
    elseif stage==1 and age>2.4 then
        assert(panel.model.expanded and panel.layout.maxScroll>0,"live Shift detail has scrollable overflow")
        local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
        love.mouse.setPosition((w-1280*scale)/2+(panel.x+panel.layout.w/2)*scale,(h-720*scale)/2+(panel.y+panel.layout.h/2)*scale)
        stage=2
    elseif stage==2 and age>2.8 then
        assert(panel.at>2.6,"Shift retains tooltip after cursor leaves the card")
        love.wheelmoved(0,-999);stage=3
    elseif stage==3 and age>3.2 then
        assert(panel.at>3 and panel.scroll==panel.layout.maxScroll,"actual game wheel handler reaches final Shift content")
        stage=3.5
        screenshot("docs/card_description_shift.png",function()
            expanded=false;love.mouse.setPosition(2,2);stage=4
        end)
    elseif stage==4 and age>3.6 then
        assert(panel.at<3.4 and not require("src.card_description").wheelmoved(-1),"releasing Shift dismisses panel and releases the wheel")
        print("PASS: live combat; full default panel, Shift retention, wheel to last row, release")
        love.event.quit()
    end
end
return T

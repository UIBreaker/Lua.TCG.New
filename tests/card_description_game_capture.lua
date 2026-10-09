local T={}
local age,card,pointed,saved=0,nil,false,false
function T.update(game,cb)
    age=age+love.timer.getDelta()
    assert(age<12,"description capture timed out")
    if not card then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
        card=require("src.deck").newCard(7,"spades")
        card.equipments={require("src.equipment").ITEMS.itm_phoenixcradle}
        game.hand={card};love.mouse.setPosition(2,2)
    elseif not pointed and age>0.8 then
        local s=assert(require("src.ui").CardPhysics.getState(card),"live card renderer")
        local x=s.ox+s.a*s.w*.5+s.c*s.h*.5
        local y=s.oy+s.b*s.w*.5+s.d*s.h*.5
        local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
        love.mouse.setPosition((w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale)
        pointed=true
    elseif pointed and not saved and age>2 then
        saved=true
        love.graphics.captureScreenshot(function(data)
            local file=assert(io.open("docs/card_description_combat.png","wb"))
            file:write(data:encode("png"):getString());file:close()
            print("PASS: optimized description captured in live combat")
            love.event.quit()
        end)
    end
end
return T

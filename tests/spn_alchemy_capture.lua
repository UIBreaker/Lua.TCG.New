local T={step=0,deadline=0}
local UI=require("src.ui")
local function click(x,y)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    x=(w-1280*s)/2+x*s;y=(h-720*s)/2+y*s
    love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
function T.update(game,cb)
    if love.timer.getTime()<T.deadline then return end
    local D=require("src.deities");local Shop=require("src.shop");local Rng=require("src.rng")
    if T.step==0 then
        cb.startNewGame("red_deck");cb.startMonsterEncounter(3,false)
        game.deities={};assert(D.addDeity(game,D.CATALOG.spirit_potion_resonance,1));assert(D.addDeity(game,D.CATALOG.spirit_potion_eternity,2))
        game.deities[2].evolutionLevel=18 -- Deterministic 100% proc; chance boundaries are covered in the smoke test.
        T.card=game.hand[1];T.speed=T.card.speedBonus or 0
        game.consumables={Shop.healingItem("upper","cons_speed_small").consumable}
    elseif T.step==1 then
        T.rng=Rng.getState();assert(cb.activateStoredReward(1));love.keypressed("escape")
        assert(#game.consumables==1 and Rng.getState()==T.rng and (T.card.speedBonus or 0)==T.speed,"cancel has no roll/consumption")
        assert(cb.activateStoredReward(1))
    elseif T.step==2 then
        click((T.card.visualX or 0)+50,(T.card.visualY or 0)+75)
        assert(#game.consumables==0 and T.card.speedBonus==T.speed+6 and not T.card.temporarySpeedBonus)
        local found=false;for _,c in ipairs(game.persistentDeck) do if c.id==T.card.id then assert(c.speedBonus==T.speed+6);found=true end end;assert(found)
        game.consumables={Shop.healingItem("upper","cons_damage").consumable,Shop.healingItem("upper","cons_empower").consumable}
        assert(cb.activateStoredReward(1) and cb.activateStoredReward(1))
        for _,c in ipairs(game.hand) do assert(c.potionPermanentDamage==40 and c.potionPermanentMult==10) end
    elseif T.step==3 then
        love.graphics.captureScreenshot(function(data)
            local file=assert(io.open("docs/spn_alchemy_battle.png","wb"));file:write(data:encode("png"):getString());file:close()
        end)
    elseif T.step==4 then
        print("SPN alchemy UI PASS: confirmed speed target/cancel/RNG, amplified permanent speed +6, whole-hand permanent damage +40 and Mult +10, live feedback")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.45
end
return T

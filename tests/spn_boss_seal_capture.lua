local T={step=0,deadline=0}
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/spn_boss_seal_"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function click(x,y)
    local w,h=love.graphics.getDimensions();local scale=math.min(w/1280,h/720)
    love.mousepressed((w-1280*scale)/2+x*scale,(h-720*scale)/2+y*scale,1)
end
local function setup(g,cb,reserve)
    local UI=require("src.ui");UI.Backpack.close();cb.startNewGame("red_deck");cb.startMonsterEncounter(1,false)
    local data=require("config.free_human_boss_data").list[4]
    g.run.ante=7;g.run.areaStage=7;g.run.regionId="human";g.run.currentBlindIndex=3
    g.run.blinds=require("src.run_manager").generateAnteBlinds(7,"red_deck","human",7);g.run.blinds[3].debuff=data
    local m=require("src.run_manager").createBlindMonster(g.run.blinds[3],g,true);require("src.combat").start(g,m,7)
    m.enemyInventory=nil;g.deities={};g.backpackDeities={}
    local D=require("src.deities");assert(D.addDeity(g,D.CATALOG.spirit_crown_eraser,1));D.evolve(g.deities[1]);D.evolve(g.deities[1])
    m.bossData.sealedSpnTier=D.getRarityTier(g.deities[1]);assert(require("src.boss_abilities").isSlotLocked(g,"spn",1))
    if reserve then g.backpackDeities[1]=g.deities[1];g.deities[1]=nil end
    require("src.enemy_abilities").plan(g,m);T.hands=g.handsRemaining;T.gold=g.gold;T.boss=m
    UI.Backpack.tab="spn";UI.Backpack.show();UI.Backpack.selected=1;UI.Backpack.selectedSource=reserve and "reserve" or "equipped"
end
function T.update(g,cb)
    if love.timer.getTime()<T.deadline then return end
    local UI=require("src.ui")
    if T.step==0 then setup(g,cb,false)
    elseif T.step==1 then shot("backpack")
    elseif T.step==2 or T.step==5 then
        local button
        for _,b in ipairs(UI.Backpack.buttons) do if b.id=="bag_destroy_spn" then button=b end end
        assert(button and not button.disabled,"destruction button available even against SPN-rarity lock")
        click(button.x+button.w/2,button.y+button.h/2)
    elseif T.step==3 or T.step==6 then
        assert(T.boss.spnAbilitiesSealed and not require("src.boss_abilities").passiveEnabled(T.boss))
        assert(not g.deities[1] and #g.backpackDeities==0 and g.handsRemaining==T.hands and g.gold==T.gold)
        assert(T.boss.intent.type=="attack" and UI.Backpack.message:find("vô hiệu hóa",1,true))
        if T.step==3 then UI.Backpack.close();shot("sealed") end
    elseif T.step==4 then setup(g,cb,true)
    elseif T.step==7 then
        UI.Backpack.close();print("SPN boss seal UI PASS: real backpack button, equipped locked slot and reserve, source removed once, no gold/hand cost, boss passive/skills permanently off and normal attack retained")
        love.event.quit(0)
    end
    T.step=T.step+1;T.deadline=love.timer.getTime()+.7
end
return T

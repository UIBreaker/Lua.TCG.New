local T={};local stage="start";local deadline=0;local started=0;local preHp
local UI=require("src.ui")
local Shop=require("src.shop")
local D=require("src.deities")
local Deck=require("src.deck")
local function pointer(x,y,button)
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local px,py=(w-1280*s)/2+x*s,(h-720*s)/2+y*s
    love.mouse.setPosition(px,py)
    love.mousepressed(px,py,button or 1);love.mousereleased(px,py,button or 1)
end
local function nextStage(name,delay) stage=name;deadline=love.timer.getTime()+(delay or .4) end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/"..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function use(g,cb)
    local _,state=cb.getScoringState()
    local x,y,w,h=UI.getConsumableSlotRect(1,state);pointer(x+w/2,y+h/2,2)
end
function T.update(g,cb)
    local now=love.timer.getTime();assert(started==0 or now-started<70,"bed capture timeout: "..stage)
    if now<deadline then return end
    if stage=="start" then
        started=now;require("tests.bed_speed_smoke")
        cb.startNewGame("red_deck");g.gold=100;g.playerHp=20;g.maxPlayerHp=150;cb.openShop()
        local stock=cb.getShopData()
        for i,item in ipairs(stock.items) do if item.consumable then stock.items[i]=Shop.healingItem("upper","cons_bed");break end end
        nextStage("shop",1.5)
    elseif stage=="shop" then shot("bed_normal_shop");pointer(870,220);nextStage("buy")
    elseif stage=="buy" then
        local b=assert(UI.Polish.button(g));pointer(b.x+b.w/2,b.y+b.h/2)
        assert(g.gold==91 and #g.consumables==1 and g.playerHp==20);nextStage("shop_use",1.3)
    elseif stage=="shop_use" then
        use(g,cb);assert(g.playerHp==150 and #g.consumables==0)
        g.persistentDeck={};for i=1,9 do g.persistentDeck[i]=Deck.newCard(8,"spades") end
        require("src.debug_tools").setAnte(g,3,1);cb.setCaptureState("BLIND_SELECT");nextStage("fight")
    elseif stage=="fight" then
        pointer(224,591);assert(#g.enemies==3)
        for _,m in ipairs(g.enemies) do m.hp=100000;m.maxHp=100000;m.damageLagHp=m.hp;m.attack=1;m.attackSpeed=1 end
        g.playerHp=10;g.maxPlayerHp=150;g.playerArmor=0;g.playerShield=0
        g.consumables={Shop.healingItem("upper","cons_bed").consumable};nextStage("sleep")
    elseif stage=="sleep" then use(g,cb);assert(UI.AbilityUI.current);nextStage("picker")
    elseif stage=="picker" then shot("bed_target_picker");nextStage("self")
    elseif stage=="self" then
        pointer(245,225)
        local a=cb.getScoringState();assert(g.playerHp==150 and #g.consumables==0 and a.enemyTurn,"sleep must start enemy turn")
        nextStage("wake",.1)
    elseif stage=="wake" then
        local a=cb.getScoringState();if a.enemyTurn then return end
        local _,state=cb.getScoringState();assert(g.playerHp<150 and state=="playing","sleep must yield the full turn")
        g.consumables={Shop.healingItem("upper","cons_speed_small").consumable};nextStage("speed")
    elseif stage=="speed" then use(g,cb);nextStage("speed_target")
    elseif stage=="speed_target" then
        local c=g.hand[1];local old=Deck.getCardAttackSpeed(c);pointer((c.visualX or 0)+50,(c.visualY or 0)+70)
        assert(#g.consumables==0 and Deck.getCardAttackSpeed(c)==old+3)
        g.consumables={Shop.healingItem("upper","cons_speed_large").consumable};nextStage("large")
    elseif stage=="large" then use(g,cb);nextStage("large_target")
    elseif stage=="large_target" then
        local c=g.hand[1];local old=Deck.getCardAttackSpeed(c);pointer((c.visualX or 0)+50,(c.visualY or 0)+70)
        assert(#g.consumables==0 and Deck.getCardAttackSpeed(c)==old+10)
        g.consumables={Shop.healingItem("upper","cons_bed").consumable};nextStage("trap")
    elseif stage=="trap" then use(g,cb);assert(UI.AbilityUI.current);nextStage("trap_target")
    elseif stage=="trap_target" then
        pointer(450,225);assert(g.enemies[1].hasBed and #g.consumables==0)
        g.deities={};D.addDeity(g,D.CATALOG.spirit_hell_sleep);nextStage("portrait",2.7)
    elseif stage=="portrait" then shot("bed_hell_sleep_battle");nextStage("play")
    elseif stage=="play" then preHp=g.enemies[2].hp;cb.selectCardIndex(1);cb.playSelectedHand();nextStage("scoring",.1)
    elseif stage=="scoring" then
        local _,state=cb.getScoringState()
        if state~="playing" then return end
        assert(not g.enemies[1].hasBed and g.enemies[2].hp<preHp and g.enemies[3].hp<preHp)
        assert(g.enemies[1].hp<g.enemies[2].hp,"target takes attack plus blast")
        shot("bed_explosion_result");nextStage("done")
    elseif stage=="done" then print("Bed/speed live UI passed: buy, shop heal, self sleep + enemy turn, small/large target speed, enemy bed, SPN explosion")
        love.event.quit()
    end
end
return T

local T={step=0}
local G=require("src.void_gacha")
local V=require("ui.void_gacha")
local Rng=require("src.rng")
local P=require("src.persistence")
local function button(cb,id)
    for _,b in ipairs(cb.getButtons()) do if b.id==id then return b end end
end
local function click(b)
    assert(b and not b.disabled,"Missing/disabled Void control")
    local w,h=love.graphics.getDimensions();local s=math.min(w/1280,h/720)
    local x,y=(w-1280*s)/2+(b.x+b.w/2)*s,(h-720*s)/2+(b.y+b.h/2)*s
    love.mouse.setPosition(x,y);love.mousepressed(x,y,1);love.mousereleased(x,y,1)
end
local function shot(name)
    love.mouse.setPosition(2,2)
    love.graphics.captureScreenshot(function(data)
        local f=assert(io.open("docs/void_"..(os.getenv("POKER_VOID_CAPTURE_PREFIX") or "")..name..".png","wb"));f:write(data:encode("png"):getString());f:close()
    end)
end
local function forced(fn,rolls,units,ticketAmount)
    local original=Rng.random;local ri,ui=0,0
    Rng.random=function(a,b)
        if b==100000 then ri=ri+1;return rolls[ri] or 5
        elseif ticketAmount and a==1 and b==100 then return ticketAmount
        elseif not a then ui=ui+1;return units and units[ui] or .99
        elseif b then return a else return 1 end
    end
    local ok,err=pcall(fn);Rng.random=original;assert(ok,err)
end
local function burst(game,index,name)
    assert(game.voidEvent.pendingResults and V.animation)
    local spec=V.effectSpec(game.voidEvent.results[index].strength)
    V.animation.index=index;V.animation.time=spec.revealAt+(spec.duration-spec.revealAt)*.23
    shot(name)
end
function T.update(game,cb)
    T.started=T.started or love.timer.getTime();assert(love.timer.getTime()-T.started<75,"Void UI timeout at "..T.step)
    if love.timer.getTime()<(T.deadline or 0) then return end
    local step=T.step
    if step==0 then
        require("tests.void_gacha_smoke")
        cb.startNewGame("red_deck");game.run.ante=10;game.run.areaStage=10;game.run.currentBlindIndex=3
        game.run.blinds=require("src.run_manager").generateAnteBlinds(10,"red_deck","human",10)
        game.gold=10000;game.voidTickets=0
        forced(function() cb.openReward("boss") end,{}, {0,0,0,0,0,0})
        assert(game.voidTickets==1)
    elseif step==1 then
        local anim=cb.getRewardAnimation();require("src.reward_system").finishImmediately(anim);shot("ticket_ceremony")
    elseif step==2 then
        forced(function() click(button(cb,"cashout_continue")) end,{})
    elseif step==3 then
        local _,state=cb.getRunState();assert(state=="void" and game.run.ante==10)
        assert(require("render.scene").definition.backgroundPath==G.config.background and require("render.scene").art.theVoid)
        assert(#V.featured==3 and V.featured[1].item.voidPower==5 and V.featured[2].item.voidPower==10 and V.featured[3].item.voidPower==10)
        require("src.void_tickets").add(game,9);game.voidEvent.payment="ticket"
        game.voidEvent.spnId="spirit_borrowed_turn";game.voidEvent.equipmentId="soul_edition_prism";V.bannerEvent=nil
        local UI=require("src.ui");local Shop=require("src.shop")
        assert(UI.getVoucherImage("v_hand_size")==require("src.continental_art").get("hand_expansion"))
        assert(require("src.continental_art").get("void_ticket"))
        for _,item in ipairs(G.consumablePool()) do assert(UI.getConsumableImage(item),"Void consumable art missing: "..item.id) end
        for id in pairs(require("src.equipment").ITEMS) do assert(UI.getEquipmentImage(id),"Void equipment art missing: "..id) end
        for id in pairs(require("src.deities").CATALOG) do assert(UI.getDeityImage(id),"Void SPN art missing: "..id) end
        for _,item in ipairs(Shop.PACK_CATALOG) do assert(UI.getPackImage(item.packType),"Void pack art missing: "..item.packType) end
        for _,item in ipairs(Shop.VOUCHERS) do assert(UI.getVoucherImage(item.id),"Void voucher art missing: "..item.id) end
        shot("rates");click(button(cb,"void_rates"))
    elseif step==4 then shot("banner");click(button(cb,"void_rates_close"))
    elseif step==5 then
        T.gold=game.gold
        forced(function() click(button(cb,"void_pull_1")) end,{1})
        assert(game.voidTickets==0 and game.gold==T.gold and game.backpackDeities[#game.backpackDeities].voidPower==5)
    elseif step==6 then burst(game,1,"banner_spn_burst")
    elseif step==7 then click(button(cb,"void_skip"))
    elseif step==8 then click(button(cb,"void_gold"))
    elseif step==9 then
        local start=0;local spnRoll
        for _,r in ipairs(G.config.rates) do if r.id=="spn" then spnRoll=start+1 end;start=start+r.weight end
        local rolls={};for i=1,8 do rolls[i]=spnRoll end;rolls[9]=1;rolls[10]=3
        T.gold=game.gold;T.spnCount=#game.backpackDeities;T.gearCount=#game.backpackEquipment
        forced(function() click(button(cb,"void_pull_10")) end,rolls,{.1,.7,.85,.95,.98,.99,.996,.9999})
        assert(game.gold==T.gold-1000 and #game.voidEvent.results==10 and #game.backpackDeities==T.spnCount+9 and #game.backpackEquipment==T.gearCount+1)
        for i=1,9 do assert(game.voidEvent.results[i].strength==i) end
    elseif step>=10 and step<=18 then burst(game,step-9,"vfx_tier_"..(step-9))
    elseif step==19 then click(button(cb,"void_skip"))
    elseif step==20 then shot("results_10");T.step=20.1;T.deadline=love.timer.getTime()+.28;return
    elseif step==20.1 then forced(function() click(button(cb,"void_pull_1")) end,{4});T.step=21;T.deadline=love.timer.getTime()+.28;return
    elseif step==21 then burst(game,1,"banner_card_burst")
    elseif step==22 then click(button(cb,"void_skip"))
    elseif step==23 then
        local restored,state=P.restoreSnapshot(assert(P.decode(P.encode(P.makeSnapshot(game,"void")))))
        assert(state=="void" and restored.voidTickets==0 and not G.enterIfDue(restored))
        assert(restored.persistentDeck[#restored.persistentDeck].voidPower==10)
        for i=1,8 do
            local a,b=V.effectSpec(i),V.effectSpec(i+1);assert(b.particles>a.particles and b.kick>a.kick and b.duration>a.duration)
        end
        local Art=require("src.continental_art");assert(Art.get("void_gold") and Art.get("void_souls"))
        for i=1,9 do
            assert(V.phase(i,0)=="charge" and V.phase(i,1)=="charge" and V.phase(i,1.1)=="signal")
            assert(V.phase(i,1.5)=="fracture" and V.phase(i,V.effectSpec(i).revealAt)=="reveal")
        end
        local start,rolls=0,{}
        for _,row in ipairs(G.config.rates) do rolls[row.id]=start+1;start=start+row.weight end
        forced(function() click(button(cb,"void_pull_10")) end,{5,37005,rolls.hand,rolls.ticket,5,37005,5,37005,5,37005},nil,100)
        assert(game.voidEvent.results[3].kind=="hand" and game.voidEvent.results[4].kind=="ticket" and game.voidEvent.results[4].amount==100 and game.voidTickets==100)
        T.rewardGold=game.gold;T.rewardSouls=game.souls
        T.step=23.1;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.1 then
        V.animation.time=.55;T.rng=Rng.getState();shot("charge")
        T.step=23.2;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.2 then
        assert(Rng.getState()==T.rng,"Presentation consumed gameplay RNG")
        V.animation.time=1.51;shot("fracture")
        T.step=23.3;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.3 then
        burst(game,1,"gold_reveal");T.step=23.4;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.4 then
        burst(game,2,"souls_reveal");T.step=23.41;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.41 then
        burst(game,3,"hand_expansion_reveal");T.step=23.42;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.42 then
        burst(game,4,"ticket_reveal");T.step=23.5;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.5 then
        local index=V.animation.index;V.animation.time=V.effectSpec(game.voidEvent.results[index].strength).duration
        V.update(0,game);assert(V.animation.index==index+1 and V.animation.time==0 and not V.animation.signal and not V.animation.impact)
        while game.voidEvent.pendingResults do V.update(V.effectSpec(game.voidEvent.results[V.animation.index].strength).duration,game) end
        assert(not V.animation and game.gold==T.rewardGold and game.souls==T.rewardSouls,"Automatic reveal awarded twice")
        T.step=23.6;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.6 then
        shot("currency_results");T.step=23.7;T.deadline=love.timer.getTime()+.28;return
    elseif step==23.7 then
        click(button(cb,"void_leave"));T.step=24;T.deadline=love.timer.getTime()+1.15;return
    elseif step==24 then
        local _,state=cb.getRunState();assert(state=="shop" and game.shopMode=="soul","Void return: "..state.."/"..game.shopMode)
        assert(game.run.ante==10 and game.voidVisited["10:human"] and not game.voidEvent)
        love.keypressed("i")
        local Bag=require("ui.backpack");require("ui.backpack_qol").switch(Bag,"consumable")
        require("ui.backpack_qol").state(Bag).query="ve the void"
        T.step=24.1;T.deadline=love.timer.getTime()+.6;return
    elseif step==24.1 then
        local Bag=require("ui.backpack");assert(Bag.open)
        local cell;for _,r in ipairs(Bag.cells) do if r.item.id=="void_ticket" then cell=r;break end end
        assert(cell and cell.count==99);click(cell)
        T.step=24.2;T.deadline=love.timer.getTime()+.4;return
    elseif step==24.2 then
        assert(button(cb,"bag_redeem_ticket") and require("src.consumable_art").get(require("src.void_tickets").item()))
        shot("tickets_backpack");T.ticketGold=game.gold
        T.step=24.3;T.deadline=love.timer.getTime()+.3;return
    elseif step==24.3 then
        click(button(cb,"bag_redeem_ticket"));assert(game.gold==T.ticketGold+99 and require("src.void_tickets").count(game)==1)
        love.keypressed("i");T.step=24.4;T.deadline=love.timer.getTime()+.3;return
    elseif step==24.4 then
        click(button(cb,"next_round") or button(cb,"leave_shop"))
        T.step=25;T.deadline=love.timer.getTime()+1.15;return
    elseif step==25 then
        assert(game.shopMode=="large" and game.run.ante==10);click(button(cb,"next_round") or button(cb,"leave_shop"))
    elseif step==26 then
        local _,state=cb.getRunState()
        if state=="barter" then click(button(cb,"barter_leave"));T.step=27;T.deadline=love.timer.getTime()+.3;return end
        assert(state=="BLIND_SELECT" and game.run.ante==11);T.step=27;T.deadline=love.timer.getTime()+.3;return
    elseif step==27 then
        local _,state=cb.getRunState();assert(state=="BLIND_SELECT" and game.run.ante==11)
        print("Void UI PASS: ceremony -> Void, 10/100-ticket quotes, actual ticket/gold pulls, powered banners, rarity VFX 1-9, save/resume, physical tickets/99 stacks/99-gold backpack redemption, Void -> soul -> large -> optional barter -> stage 11")
        love.event.quit(0)
    end
    T.step=step+1;T.deadline=love.timer.getTime()+((step==0 or step==2 or step==24 or step==25) and 1.15 or .28)
end
return T

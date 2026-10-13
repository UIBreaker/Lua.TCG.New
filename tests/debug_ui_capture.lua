local T = {step = 1, actions = {}}
local UI = require("src.ui")
local Run = require("src.run_manager")
local function button(cb, id)
    for _, b in ipairs(cb.getButtons()) do if b.id == id then return b end end
end
local function click(cb, id)
    local b = assert(button(cb, id), "Missing control: " .. id)
    assert(not b.disabled, "Disabled control: " .. id)
    local w,h = love.graphics.getDimensions()
    local s = math.min(w / 1280, h / 720)
    local x,y = (w - 1280*s)/2 + (b.x+b.w/2)*s, (h - 720*s)/2 + (b.y+b.h/2)*s
    love.mouse.setPosition(x,y); love.mousepressed(x,y,1); love.mousereleased(x,y,1)
end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f = assert(io.open("docs/debug_" .. name .. ".png", "wb"))
        f:write(data:encode("png"):getString()); f:close()
    end)
end
local function add(f, delay) T.actions[#T.actions+1] = {run=f, delay=delay or .2} end
local function press(id, delay) add(function(g,cb) click(cb,id) end, delay) end
local function key(k) add(function() love.keypressed(k) end) end
local function input(field, value)
    press("debug_focus_" .. field)
    add(function() love.textinput(value) end)
end
local function route(id, ante)
    key("f7")
    press("debug_tab_teleport")
    input("ante", tostring(ante or 3))
    add(function(g,cb)
        local target = "debug_screen_" .. id
        if not button(cb,target) then click(cb,UI.Debug.screenPage==1 and "debug_screens_next" or "debug_screens_prev") end
    end)
    press("debug_screen_" .. id, .8)
    add(function(g,cb)
        local _,state = cb.getRunState()
        local expected = id:match("^shop_") and "shop" or
            (id=="small" or id=="big" or id=="boss") and "playing" or id
        if id == "scoring" then
            assert(g.monster and #g.enemies > 0, "scoring must create a real encounter")
        else assert(state == expected, id .. " -> " .. state) end
        assert(not g.pendingBloodShop and not g.pendingBarter and not g.soulDestroyActive)
        if expected == "shop" then
            assert(#cb.getShopData().items > 0 and Run.getCurrentBlind(g.run).status == "completed")
        elseif expected == "playing" then
            assert(g.playerHp > 0 and #g.hand > 0 and g.monster.stage == (ante or 3))
        elseif id == "victory" then assert(g.run.travelPermit and g.run.victory)
        elseif id == "rest" or id == "treasure" or id == "chest" or id == "event" or id == "boss_deity" then assert(g.map)
        elseif id == "socketing" then assert(g.pendingShopEquipment and g.pendingRewardEquipment)
        elseif id == "void" then assert(g.voidEvent and g.run.currentBlindIndex == 3)
        elseif id == "gameover" then assert(g.playerHp == 0) end
    end)
end
local function build()
    add(function(g,cb) cb.openSettings() end)
    add(function(g,cb) if not cb.isDebugEnabled() then click(cb,"setting_debug_toggle") end end)
    press("setting_debug_open")
    press("debug_tab_teleport")
    press("debug_focus_ante")
    add(function()
        love.keypressed("1", "1"); love.textinput("1"); love.keyreleased("1", "1")
        love.keypressed("3", "3"); love.textinput("3"); love.keyreleased("3", "3")
    end)
    add(function(g,cb) assert(button(cb,"debug_focus_ante").text:match("(%d+)$")=="13", "digits must not be doubled by textinput") end)
    press("debug_focus_ante")
    add(function()
        love.keypressed("kp1", "kp1"); love.keyreleased("kp1", "kp1")
        love.keypressed("kp3", "kp3"); love.keyreleased("kp3", "kp3")
    end)
    add(function(g,cb) assert(button(cb,"debug_focus_ante").text:match("(%d+)$")=="13", "numpad must work without textinput") end)
    press("debug_focus_ante")
    add(function()
        love.keypressed("end", "kp1"); love.keyreleased("end", "kp1")
        love.keypressed("pagedown", "kp3"); love.keyreleased("pagedown", "kp3")
    end)
    add(function(g,cb) assert(button(cb,"debug_focus_ante").text:match("(%d+)$")=="13", "Num Lock off must use the keypad scancode, without changing pages") end)
    input("ante", "0")
    press("debug_set_ante")
    add(function(g,cb) assert(not g.run and select(2,cb.getRunState()) == "menu", "invalid ante must not start a run") end)
    press("debug_tab_gold")
    input("gold", "150")
    key("return")
    add(function(g) assert(g.gold == 150 and g.run, "gold from menu must survive run initialization") end)
    press("debug_add_gold")
    add(function(g) assert(g.gold == 300) end)
    press("debug_focus_gold")
    key("backspace")
    press("debug_set_gold")
    add(function(g) assert(g.gold == 300, "empty set must not fall through to add") end)
    press("debug_add_souls"); press("debug_add_tickets")
    add(function(g) g.playerHp=5 end)
    press("debug_heal")
    add(function(g) assert(g.souls==100 and g.voidTickets==10 and g.playerHp==g.maxPlayerHp); shot("resources") end)
    press("debug_tab_items")
    press("debug_category_playing_cards")
    press("debug_grant_1")
    add(function(g) assert(#g.persistentDeck==2) end)
    press("debug_items_next")
    press("debug_grant_13")
    add(function(g) assert(#g.persistentDeck==3) end)
    press("debug_category_equipment")
    add(function(g,cb) assert(button(cb,"debug_grant_1")); shot("collection") end)
    press("debug_grant_1", .8)
    add(function(g,cb) assert(select(2,cb.getRunState())=="socketing" and g.pendingShopEquipment) end)
    press("skip_socket", .8)
    add(function(g,cb) assert(select(2,cb.getRunState())=="shop" and not g.pendingRewardEquipment) end)
    for _,id in ipairs({"BLIND_SELECT","small","big","boss","scoring","shop","rest","treasure","event","boss_deity","chest","map","socketing","CASH_OUT","gameover","victory","barter","void",
        "shop_small","shop_consumable","shop_equipment","shop_spn","shop_medicine","shop_cards","shop_large","shop_soul","shop_blood_small","shop_blood_large"}) do
        route(id,id=="void" and 10 or 3)
        if id=="shop_small" then
            add(function(g,cb) click(cb,button(cb,"leave_shop") and "leave_shop" or "next_round") end,.8)
            add(function(g,cb) assert(select(2,cb.getRunState())=="BLIND_SELECT" and g.run.currentBlindIndex==2) end)
        elseif id=="victory" then
            press("travel_unknown",.8)
            add(function(g,cb) assert(select(2,cb.getRunState())=="BLIND_SELECT" and g.run.regionId=="unknown" and not g.run.travelPermit) end)
        elseif id=="void" then
            press("void_leave",.8)
            add(function(g,cb) assert(select(2,cb.getRunState())=="shop" and #cb.getShopData().items>0) end)
        elseif id=="chest" or id=="treasure" then
            press("chest_choice_1_1",.8)
            add(function(g,cb) assert(select(2,cb.getRunState())=="map" and g.map) end)
        elseif id=="barter" then
            press("barter_leave",.8)
            add(function(g,cb) assert(select(2,cb.getRunState())=="BLIND_SELECT" and g.run.ante==4) end)
        end
    end
    key("f7"); press("debug_tab_teleport")
    input("ante","3")
    press("debug_screen_void")
    add(function(g,cb) assert(button(cb,"debug_close") and select(2,cb.getRunState())=="shop", "Void condition must reject safely") end)
    press("debug_region_next")
    press("debug_screens_prev")
    press("debug_screen_small",.8)
    add(function(g) assert(g.monster.regionId==UI.Debug.region and g.run.regionId==UI.Debug.region) end)
    key("f7"); press("debug_tab_teleport")
    add(function(g,cb)
        local a = cb.getScoringState()
        g.pendingVictoryReward={}; g.pendingBarter=true; g.pendingBloodShop="blood_small"
        T.pausedHand=g.hand; T.pausedTimer=a.timer
        shot("teleport")
    end,.7)
    add(function(g,cb) local a=cb.getScoringState(); assert(g.hand==T.pausedHand and a.timer==T.pausedTimer,"Debug must pause gameplay") end)
    press("debug_screen_BLIND_SELECT")
    add(function(g) assert(not g.pendingVictoryReward and not g.pendingBarter and not g.pendingBloodShop and #g.hand==0) end)
    route("shop_cards")
    add(function(g,cb) assert(UI.Polish.reroll(cb.getShopData(),g)); assert(UI.Polish.busy()); love.keypressed("f7") end)
    press("debug_tab_teleport")
    press("debug_screens_prev")
    press("debug_screen_BLIND_SELECT")
    add(function(g) assert(not UI.Polish.busy(), "old market jobs must not finish in the new scene") end)
    key("f7"); press("debug_tab_items"); press("debug_category_blinds")
    press("debug_grant_3", .8)
    add(function(g)
        local item=require("src.collection").getItems("blinds")[3]
        assert(g.monster.isBoss and g.monster.bossData==Run.BOSS_DEBUFFS[item.id],"selected boss must be initialized once with its real ability")
    end)
    key("f7"); press("debug_tab_items"); press("debug_category_editions")
    press("debug_grant_2")
    add(function(g)
        local card=g.persistentDeck[1]
        for _,pile in ipairs({g.hand,g.deck,g.discardPile}) do for _,c in ipairs(pile) do if c.id==card.id then assert(c.edition==card.edition) end end end
    end)
    press("debug_category_decks"); press("debug_grant_1", .8)
    add(function(g,cb) assert(select(2,cb.getRunState())=="BLIND_SELECT" and #g.persistentDeck==1 and g.gold==6) end)
    route("menu")
    add(function(g,cb)
        assert(select(2,cb.getRunState())=="menu")
        print("Debug UI PASS: real settings/F7/input/mouse controls, resources, grants/pagination/socket return, all 29 destinations, market/chest/permit/barter/Void exits, regions, pause, stale job cleanup, exact boss, live editions and new deck; captures in docs/debug_*.png")
        love.event.quit(0)
    end)
end
function T.update(g,cb)
    for _,value in ipairs(arg or {}) do
        if value=="--test-debug-input" then
            if not T.started then
                T.started=love.timer.getTime()
                cb.startNewGame("red_deck")
                UI.Debug.open(); UI.Debug.activate("debug_tab_teleport")
                T.nativeKey = love.keypressed
                love.keypressed = function(key, scancode, ...)
                    print("DEBUG NATIVE KEY: " .. key .. " / " .. tostring(scancode))
                    T.nativeKey(key, scancode, ...)
                end
                love.window.setTitle("Debug keyboard input test (no player save)")
                love.window.setFullscreen(false)
                love.window.setMode(1280,720,{resizable=true})
                love.resize(1280,720)
                print("DEBUG INPUT READY: click ante, type 13 with physical keys, press Enter")
            end
            assert(love.timer.getTime()-T.started<180,"Native input test timeout")
            local field = button(cb,"debug_focus_ante")
            local current = field and field.text or ("APPLIED " .. g.run.ante)
            if current ~= T.nativeField then print("DEBUG NATIVE FIELD: " .. current); T.nativeField = current end
            if g.run.ante==13 and select(2,cb.getRunState())=="BLIND_SELECT" and not button(cb,"debug_close") then
                print("Debug native keyboard PASS: applied stage 13 through the OS event path; player save untouched")
                love.event.quit(0)
            end
            return
        end
    end
    if not T.started then T.started=love.timer.getTime();build() end
    assert(love.timer.getTime()-T.started<170,"Debug UI timeout at "..T.step)
    if love.timer.getTime()<(T.deadline or 0) then return end
    local action=assert(T.actions[T.step],"Missing debug test action "..T.step)
    action.run(g,cb)
    T.step=T.step+1;T.deadline=love.timer.getTime()+action.delay
end
return T

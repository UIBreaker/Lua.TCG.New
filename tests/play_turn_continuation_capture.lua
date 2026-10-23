local T = { case = 0, stage = "setup" }
local Deck = require("src.deck")
local Combat = require("src.combat")
local Rng = require("src.rng")
local cases = {
    { name = "exhausted mouse", remaining = 0, speed = 1 },
    { name = "exhausted keyboard fast enemy", remaining = 0, speed = 80, keyboard = true },
    { name = "exhausted stale button", remaining = 0, speed = 1, stale = true },
    { name = "exhausted multiple selected cards", remaining = 0, speed = 1, multiple = true },
    { name = "faster player", remaining = 3, speed = 1 },
    { name = "faster enemy", remaining = 3, speed = 80 },
    { name = "equal speed", remaining = 3, speed = 50 },
    { name = "explicit end turn", remaining = 0, speed = 1, noSelection = true },
    { name = "lethal enemy cancels queued hand", remaining = 0, speed = 80, lethal = true },
}
local function pointer(x, y)
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / 1280, h / 720)
    x, y = (w - 1280 * scale) / 2 + x * scale, (h - 720 * scale) / 2 + y * scale
    love.mouse.setPosition(x, y)
    love.mousepressed(x, y, 1); love.mousereleased(x, y, 1)
end
local function clickAction(cb)
    for _, b in ipairs(cb.getButtons()) do
        if b.id == "play" or b.id == "end_turn" then
            assert(not b.disabled, "primary action unexpectedly disabled")
            pointer(b.x + b.w / 2, b.y + b.h / 2); return
        end
    end
    error("missing primary action")
end
function T.update(game, cb)
    local now = love.timer.getTime()
    local active=cb.getScoringState()
    local timing=active.attackTiming or active.enemyTurn and active.enemyTurn.timing
    if timing and not timing.result and timing.age>=timing.ready+.02 then
        timing.position=0;love.keypressed("space",nil,false)
    end
    if not T.originalPlayer then
        local Core = require("ui.components.core")
        T.originalText = Core.text
        Core.text = function(value, ...)
            local _, state = cb.getScoringState()
            assert(value ~= "BẠN RA ĐÒN TRƯỚC" or game.handsRemaining > 0 or state ~= "playing",
                "speed panel must not promise a first strike while ending an exhausted turn")
            return T.originalText(value, ...)
        end
        T.originalPlayer, T.originalEnemy, T.originalRandom = Combat.resolvePlayerAttack, Combat.resolveMonsterAttack, Rng.random
        Combat.resolvePlayerAttack = function(...)
            T.playerHits = T.playerHits + 1; T.order[#T.order + 1] = "player"
            return T.originalPlayer(...)
        end
        Combat.resolveMonsterAttack = function(...)
            local result = T.originalEnemy(...)
            if result then T.enemyHits = T.enemyHits + 1; T.order[#T.order + 1] = "enemy" end
            return result
        end
        Rng.random = function(lo, hi) if lo then return T.originalRandom(lo, hi) end return 0 end
    end
    if T.stage == "setup" then
        T.case = T.case + 1
        local spec = cases[T.case]
        if not spec then
            require("ui.components.core").text = T.originalText
            Combat.resolvePlayerAttack, Combat.resolveMonsterAttack, Rng.random = T.originalPlayer, T.originalEnemy, T.originalRandom
            print("Play continuation PASS: exhausted mouse/keyboard/stale button, fast/slow/equal speed, explicit end turn, lethal cancellation")
            love.event.quit(0); return
        end
        cb.startNewGame("red_deck"); cb.startMonsterEncounter(1, false); cb.setScoringSpeed(true)
        game.unlockedHands = {high_card = true, pair = true}
        game.hand, game.selectedIndices, game.deities, game.deck, game.discardPile = {}, {}, {}, {}, {}
        for i = 1, 3 do
            local c = Deck.newCard(8, "spades"); c.disableFactionPassives = true
            c.speedBonus = 50 - Deck.peekCardAttackSpeed(c); game.hand[i] = c
        end
        game.playerHp, game.maxPlayerHp, game.playerArmor, game.playerShield = spec.lethal and 1 or 1000, 1000, 0, 0
        local m = game.monster
        m.hp, m.maxHp, m.damageLagHp, m.creatureArmor = 1000000, 1000000, 1000000, 0
        m.attackSpeed, m.attack, m.enemyInventory, m.enemyAbility = spec.speed, 10, nil, nil
        m.intent = {type = "attack", value = 10, label = "Test attack"}
        game.handsRemaining, game.abilityApproved = spec.remaining, {}
        T.chosen, T.otherChosen, T.playerHits, T.enemyHits, T.order = game.hand[1], game.hand[3], 0, 0, {}
        T.started, T.stage = now, "select"
    else
        local spec = cases[T.case]
        assert(now - T.started < 30, spec.name .. " timed out")
        if T.stage == "select" and now - T.started > .4 then
            if not spec.noSelection then
                pointer(T.chosen.visualX + 20, T.chosen.visualY + 70)
                assert(T.chosen.selected, "real click must select the requested card")
                if spec.multiple then
                    pointer(T.otherChosen.visualX + 20, T.otherChosen.visualY + 70)
                    assert(T.otherChosen.selected and #game.selectedIndices == 2, "multiple selection must survive rollover")
                end
            end
            T.stage, T.selectedAt = "click", now
            if spec.stale then clickAction(cb); T.stage = "wait" end
        elseif T.stage == "click" and now - T.selectedAt > .1 then
            if T.case == 1 and not T.shot then
                T.shot = true
                love.graphics.captureScreenshot(function(data)
                    local file = io.open(".tmp/play-turn/queued.png", "wb")
                    if file then file:write(data:encode("png"):getString()); file:close() end
                end)
                T.selectedAt = now; return
            end
            if spec.keyboard then love.keypressed("space") else clickAction(cb) end
            T.stage = "wait"
        elseif T.stage == "wait" then
            local a, state = cb.getScoringState()
            if a.enemyTurn then
                local hands = game.handsRemaining
                love.keypressed("space")
                assert(game.handsRemaining == hands, "repeated input must not spend or queue another hand")
            end
            if spec.lethal and (state == "defeating" or state == "gameover") then
                assert(T.playerHits == 0 and game.playerHp == 0, "dead player cannot execute a queued hand")
            elseif state ~= "playing" or a.active or a.enemyTurn then return
            else
                local expected = (spec.noSelection or spec.remaining==0) and 0 or 1
                assert(T.playerHits == expected, spec.name .. ": selected attack disappeared; player resolutions=" .. T.playerHits)
                assert(game.handsRemaining == (spec.remaining == 0 and game.turnHandLimit or spec.remaining) - expected,
                    "queued attack must spend exactly one hand in the new turn")
                assert(T.enemyHits == 1, "enemy must act once per phase")
                if spec.remaining==0 then
                    assert(game.combatReshuffles==1 and #game.selectedIndices==0,"rollover shuffles and cancels stale card selections")
                end
                if expected>0 then
                    assert(T.chosen == a.playedCards[1] or T.chosen == game.discardPile[#game.discardPile], "play must keep the chosen card")
                    if spec.multiple then
                        local found = false
                        for _, c in ipairs(game.discardPile) do if c == T.otherChosen then found = true end end
                        assert(found, "queued multi-card attack must play every requested card")
                    end
                    assert(T.order[spec.remaining == 0 and 2 or 1] == (spec.speed > 50 and "enemy" or "player"), "speed must control order")
                end
            end
            print("[PASS] " .. spec.name); T.stage = "setup"
        end
    end
end
return T

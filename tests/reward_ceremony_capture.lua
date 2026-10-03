-- lovec.exe . --test-reward-ceremony; capture mode never writes player saves.
local Reward = require("src.reward_system")
local Sound = require("src.sound")
local Deck = require("src.deck")
local C = Reward.config
local Test = {}
local stage, deadline, started, frames = "start", 0, 0, 0
local gold, before, originalRng
local function nextStage(name, delay) stage = name; deadline = love.timer.getTime() + (delay or 0.15) end
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f = assert(io.open(name, "wb")); f:write(data:encode("png"):getString()); f:close()
    end)
end
local function clickButton(callbacks, id)
    for _, b in ipairs(callbacks.getButtons()) do
        if b.id == id then
            local w, h = love.graphics.getDimensions(); local scale = math.min(w / 1280, h / 720)
            local x, y = (w - 1280 * scale) / 2 + (b.x + b.w / 2) * scale, (h - 720 * scale) / 2 + (b.y + b.h / 2) * scale
            love.mousepressed(x, y, 1); love.mousereleased(x, y, 1)
            return
        end
    end
    error("Missing button: " .. id)
end
function Test.update(game, callbacks)
    frames = frames + 1
    if love.timer.getTime() < deadline then return end
    assert(stage == "done" or started == 0 or love.timer.getTime() - started < 25, "Reward capture timed out at " .. stage)
    if stage == "start" then
        started = love.timer.getTime()
        callbacks.startNewGame("red_deck")
        game.gold, game.handsRemaining = 20, 3
        C.tables.capture = {rolls = {2, 2}, entries = {{id = "rare_reward", weight = 1}}}
        -- Four saved pack rewards exercise a full six-slot boss ceremony.
        C.tables.golden_chest = {rolls = {2, 2}, entries = {{id = "itm_pack", weight = 1}}}
        callbacks.openReward("capture")
        local anim, state = callbacks.getRewardAnimation()
        assert(state == "CASH_OUT" and #anim.slots == 6 and #game.rewardPacks == 4)
        gold, before = game.gold, #game.persistentDeck
        originalRng = require("src.rng").getState()
        for _, name in ipairs({"reward_coin_spawn", "reward_coin_land", "reward_coin_collect", "reward_gold_total", "reward_loot_reveal", "reward_rare_reveal", "reward_chest_open"}) do assert(Sound.has(name), name) end
        nextStage("coins", 0.55)
    elseif stage == "coins" then
        local anim = callbacks.getRewardAnimation()
        assert(#anim.coins > 0 and anim.displayTotal < anim.result.earnedGold)
        shot("shot_reward_coins.png")
        nextStage("rare", 1)
    elseif stage == "rare" then
        shot("shot_reward_rare.png")
        nextStage("summary", 2.8)
    elseif stage == "summary" then
        local anim = callbacks.getRewardAnimation()
        if not anim.finished then nextStage("summary", 0.1); return end
        assert(anim.finished and anim.displayTotal == anim.result.earnedGold and game.gold == gold)
        assert(require("src.rng").getState() == originalRng, "drawing cannot alter gameplay RNG")
        shot("shot_reward_summary.png")
        local w, h = love.graphics.getDimensions(); local scale = math.min(w / 1280, h / 720)
        love.mouse.setPosition((w - 1280 * scale) / 2 + 400 * scale, (h - 720 * scale) / 2 + 460 * scale)
        nextStage("tooltip", 0.65)
    elseif stage == "tooltip" then
        local candidate = require("src.ui").descriptionCandidate
        assert(candidate and candidate.hoverKey and candidate.name == "ITM PACK")
        shot("shot_reward_tooltip.png")
        nextStage("continue")
    elseif stage == "continue" then
        love.mouse.setPosition(2, 2)
        love.keypressed("return")
        assert(select(2, callbacks.getRewardAnimation()) == "shop")
        assert(not game.pendingVictoryReward and callbacks.getShopData().currentPackOpening)
        nextStage("choose", 1.2)
    elseif stage == "choose" then
        if callbacks.getShopData().currentPackOpening.animationTimer < 1.8 then nextStage("choose", 0.1); return end
        shot("shot_reward_free_pack.png")
        nextStage("pick")
    elseif stage == "pick" then
        clickButton(callbacks, "choose_pack_1")
        assert(select(2, callbacks.getRewardAnimation()) == "socketing" and game.pendingRewardEquipment)
        assert(#game.rewardPacks == 4, "ITM queue survives until socketing resolves")
        nextStage("socket")
    elseif stage == "socket" then
        clickButton(callbacks, "skip_socket")
        assert(not game.pendingRewardEquipment and #game.rewardPacks == 3)
        nextStage("skip_pack", 1.2)
    elseif stage == "skip_pack" then
        clickButton(callbacks, "skip_pack")
        assert(#game.rewardPacks == 2 and game.gold == gold)
        nextStage("fast")
    elseif stage == "fast" then
        game.rewardPacks = {}
        callbacks.closePack()
        C.tables.capture.entries = {{id = "playing_card", weight = 1}}
        C.tables.capture.rolls = {1, 1}
        callbacks.openReward("capture")
        assert(#game.persistentDeck == before + 1)
        gold = game.gold
        love.keypressed("space")
        local anim, state = callbacks.getRewardAnimation()
        assert(state == "CASH_OUT" and anim.finished and game.gold == gold)
        nextStage("card")
    elseif stage == "card" then
        shot("shot_reward_card.png")
        nextStage("card_continue")
    elseif stage == "card_continue" then
        love.keypressed("return")
        assert(select(2, callbacks.getRewardAnimation()) == "shop" and game.gold == gold)
        print("LÖVE reward ceremony passed: coins, six loot slots, audio hooks, saved pack handoff, ITM socket, skip, direct card, keyboard fast-forward; " .. frames .. " frames")
        stage = "done"; love.event.quit(0)
    end
end
return Test

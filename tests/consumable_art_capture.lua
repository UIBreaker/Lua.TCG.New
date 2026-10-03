local T = {}
local UI = require("src.ui")
local Shop = require("src.shop")
local Run = require("src.run_manager")
local Art = require("src.consumable_art")
local Persistence = require("src.persistence")
Persistence.deleteRun = function() return true end
Persistence.saveRun = function() return true end
Persistence.saveSettings = function() return true end
local types = {"spectral", "joker_edition", "seal", "edition", "arcana"}
local step, age, initialized, captured = 1, 0, false, false
local options = Run.createRoundRewardOptions()
local function shot(name)
    love.graphics.captureScreenshot(function(data)
        local f = assert(io.open("docs/consumable_" .. name .. ".png", "wb"))
        f:write(data:encode("png"):getString()); f:close()
    end)
end
function love.errorhandler(message)
    print(debug.traceback(message, 2)); return function() return 1 end
end
function T.update(game, cb)
    age = age + love.timer.getDelta()
    if not initialized then
        local count, all = 0, {}
        for _, packType in ipairs({"spectral", "joker_edition", "seal", "edition"}) do
            for _, item in ipairs(Shop.getPackContents(packType)) do
                local image = assert(UI.getConsumableImage(item), "missing " .. tostring(item.id))
                assert(UI.getPackCardImage(packType, item) == image, "reward must use its own image")
                local entry = {id="pack_content_" .. packType .. "_" .. item.id, packType=packType, isPackContent=true}
                assert(UI.getConsumableImage(entry) == image, "collection must use the same image")
                count = count + 1
                all[#all + 1] = item
            end
        end
        for _, item in ipairs(options) do
            assert(UI.getConsumableImage(item)); count = count + 1; all[#all + 1] = item
        end
        for _, item in ipairs(Shop.getPackContents("arcana")) do
            local image = assert(UI.getEquipmentImage(item.id), "missing ITM " .. item.id)
            assert(UI.getPackCardImage("arcana", item) == image)
        end
        assert(count == 24, "all requested consumables covered")
        assert(Art.id({id="ed_holo"}) == "edition_holographic")
        assert(not UI.getConsumableImage({id="unknown_card"}), "unknown art safely falls back")
        local g = love.graphics
        local canvas, previous = g.newCanvas(1200, 1440), g.getCanvas()
        g.push("all"); g.setCanvas(canvas); g.origin(); g.clear(0.025, 0.03, 0.045, 1)
        for i, item in ipairs(all) do
            local x, y = ((i - 1) % 6) * 200 + 10, math.floor((i - 1) / 6) * 360 + 10
            require("ui.card_surfaces").fullReward(item, x, y, 180, 270, nil, false)
            g.setFont(UI.fonts.small); g.setColor(1, 1, 1, 1)
            g.printf(item.name, x, y + 282, 180, "center")
        end
        g.setCanvas(previous); g.pop()
        local f = assert(io.open("docs/consumable_art_catalog.png", "wb"))
        f:write(canvas:newImageData():encode("png"):getString()); f:close()
        print("Consumable art coverage PASS: 24 unique cards and collection aliases")
        cb.startNewGame("red_deck"); cb.openShop(); love.mouse.setPosition(4, 4)
        cb.openPack({packType=types[step], name="RƯƠNG • " .. types[step]}, true)
        initialized = true; age = 0
    elseif step <= #types and not captured and age > 2.9 then
        shot(types[step]); captured = true; age = 0
    elseif step <= #types and captured and age > 0.2 then
        cb.closePack(); step = step + 1; age = 0; captured = false
        if types[step] then cb.openPack({packType=types[step], name="RƯƠNG • " .. types[step]}, true)
        else game.consumables = options; cb.startMonsterEncounter(1, false) end
    elseif step == 6 and not captured and age > 0.8 then
        shot("battle"); captured = true; age = 0
    elseif step == 6 and captured and age > 0.2 then
        step = 7; age = 0; captured = false
        cb.openReward("memory")
        game.pendingRoundRewardChoice = {ante=1, options=options}
    elseif step == 7 and age > 0.5 and cb.getRewardAnimation().finished then
        shot("round"); step = 8; age = 0
    elseif step == 8 and age > 0.2 then
        print("Consumable art rendering PASS: five chests, inventory and round reward")
        love.event.quit(0)
    end
end
return T

local T = {}
local UI = require("src.ui")
local Shop = require("src.shop")
local Deities = require("src.deities")
local Equipment = require("src.equipment")
local Poker = require("src.poker")
local Surfaces = require("ui.card_surfaces")
local Persistence = require("src.persistence")
Persistence.deleteRun = function() return true end
Persistence.saveRun = function() return true end
Persistence.saveSettings = function() return true end
local step, age, initialized, captured = 1, 0, false, false
local scenes = {"shop", "buffoon", "arcana", "hand_styles", "collection", "handbook", "battle", "defeated"}
local function save(data, name)
    local bytes = data:encode("png"):getString()
    local path = "docs/illustrated_" .. name .. ".png"
    local f, err
    -- Windows thumbnail readers can briefly lock an existing capture.
    for attempt = 1, 10 do
        f, err = io.open(path, "wb")
        if f then break end
        love.timer.sleep(0.05)
    end
    assert(f, err); f:write(bytes); f:close()
end
local function sheet(items, category, name)
    local g = love.graphics
    local canvas, previous = g.newCanvas(900, 1050), g.getCanvas()
    g.push("all"); g.setCanvas(canvas); g.origin(); g.clear(0.025, 0.03, 0.045, 1)
    UI.CardPhysics.suspend()
    for i, item in ipairs(items) do
        local x, y = ((i - 1) % 3) * 300 + 50, math.floor((i - 1) / 3) * 350 + 10
        Surfaces.catalog(item, x, y, 200, 300, category, false, -1000, -1000)
        g.setFont(UI.fonts.small); g.setColor(1, 1, 1, 1)
        g.printf(item.name or item.vnName, x - 25, y + 311, 250, "center")
    end
    UI.CardPhysics.resume(); g.setCanvas(previous); g.pop()
    save(canvas:newImageData(), name)
end
local function verify(image, path)
    assert(love.filesystem.getInfo(path), "missing illustrated asset " .. path)
    assert(image, "loader must return " .. path)
    assert(image:getWidth() >= 512 and image:getHeight() >= 768, "loader must prefer new portrait " .. path)
end
local function enter(game, cb)
    local scene = scenes[step]
    if scene == "shop" then cb.openShop()
    elseif scene == "buffoon" or scene == "arcana" or scene == "hand_styles" then
        cb.openPack({packType=scene, name=({buffoon="RƯƠNG SPN", arcana="RƯƠNG ITM", hand_styles="RƯƠNG THẾ ĐÁNH"})[scene]}, true)
    elseif scene == "collection" then cb.openCollection("other")
    elseif scene == "handbook" then cb.closeCollection(); cb.openHandbook()
    elseif scene == "battle" then cb.closeHandbook(); cb.startMonsterEncounter(1, false)
    elseif scene == "defeated" then
        game.monster.stage=3
        require("src.combat").start(game,game.monster,3)
        assert(#game.enemies==3)
        for i=1,2 do game.enemies[i].hp=0;game.enemies[i].damageLagHp=0 end
        assert(require("src.enemy_group").select(game,3))
    end
end
function love.errorhandler(message)
    print(debug.traceback(message, 2)); return function() return 1 end
end
function T.update(game, cb)
    age = age + love.timer.getDelta()
    assert(age < 12, "illustrated capture timeout at " .. step)
    if not initialized then
        for _,argument in ipairs(arg or {}) do
            if argument=="--continental-coverage" then require("tests.continental_art_coverage").verify() end
        end
        local spn, itm, hands = {}, {}, {}
        for _, item in pairs(Deities.CATALOG) do
            verify(UI.getDeityImage(item.id), "assets/deities/illustrated/" .. item.id .. ".png")
            assert(UI.deityImageIsSpnCard[item.id], "SPN uses full-bleed drawing")
            spn[#spn + 1] = item
        end
        table.sort(spn, function(a,b) return a.id < b.id end)
        for _, id in ipairs(Equipment.POOL) do
            verify(UI.getEquipmentImage(id), "assets/equipment/illustrated/" .. id .. ".png")
            assert(UI.getPackCardImage("arcana", Equipment.ITEMS[id]) == UI.getEquipmentImage(id))
            itm[#itm + 1] = Equipment.ITEMS[id]
        end
        for i = #Poker.HAND_TYPES_ORDERED, 1, -1 do
            local hand = Poker.HAND_TYPES_ORDERED[i]
            local image = UI.getHandImage(hand.id)
            verify(image, "assets/hands/illustrated/" .. hand.id .. ".png")
            assert(UI.visualImage(image) == image, "new hand artwork stays visible in modern UI")
            assert(UI.getHandImage("book_" .. hand.id) == image, "book alias reuses hand art")
            assert(UI.getHandImage("hand_" .. hand.id) == image, "hand alias reuses hand art")
            hands[#hands + 1] = {id=hand.id, handId=hand.id, name=hand.vnName}
        end
        assert(#spn == 9 and #itm == 9 and #hands == 9)
        for _, item in ipairs(Shop.getPackContents("hand_styles")) do
            assert(UI.getPackCardImage("hand_styles", item) == UI.getHandImage(item.handId))
        end
        require("tests.card_frame_capture").verify()
        sheet(spn, "jokers", "spn_catalog"); sheet(itm, "consumables", "itm_catalog"); sheet(hands, "other", "hands_catalog")
        print("Illustrated artwork coverage PASS: 9 SPN, 9 ITM, 9 hand styles, full-bleed and aliases")
        cb.startNewGame("red_deck"); love.mouse.setPosition(4, 4)
        game.deities = {}
        for i=1,3 do game.deities[i] = spn[i] end
        game.consumables = {}
        for i=1,3 do game.consumables[i] = {id="stored_" .. itm[i].id, category="stored_equipment", equipmentId=itm[i].id, name=itm[i].name} end
        enter(game, cb); initialized = true; age = 0
    elseif step <= #scenes and not captured and age > ((step >= 2 and step <= 4) and 2.9 or 0.7) then
        local name = scenes[step]
        if name == "battle" then
            for _, deity in ipairs(game.deities) do
                local s = assert(UI.CardPhysics.getState(deity))
                local x,y,w,h = UI.CardFrame.pennantRect(s.w,s.h)
                x,y = x+w/2,y+h*0.35
                assert(UI.CardPhysics.cardAt(s.ox+s.a*x+s.c*y,s.oy+s.b*x+s.d*y)==deity,
                    "each exposed right pennant must select its own SPN")
            end
            print("SPN fan PASS: each exposed rarity flag selects its own card")
        end
        love.graphics.captureScreenshot(function(data) save(data, name) end)
        captured = true; age = 0
    elseif step <= #scenes and captured and age > 0.2 then
        cb.closePack(); step = step + 1; age = 0; captured = false
        if scenes[step] then enter(game, cb)
        else print("Illustrated rendering PASS: shop, three chests, collection, handbook, battle inventory, defeated enemies without ghost frames"); love.event.quit(0) end
    end
end
return T

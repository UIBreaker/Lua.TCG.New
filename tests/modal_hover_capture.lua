local T = {}
local UI = require("src.ui")
local step, deadline = 0, 0
local hovered, descriptions = {}, 0
local Shop = require("src.shop")
local packIndex, packPhase = 1, 0
local stockItem, stockX, stockY
local drawnFrames = 0

local function pointer(x, y, click)
    local w, h = love.graphics.getDimensions()
    local s = math.min(w / 1280, h / 720)
    local px, py = (w - 1280 * s) / 2 + x * s, (h - 720 * s) / 2 + y * s
    love.mouse.setPosition(px, py)
    love.mousemoved(px, py, 0, 0)
    if click then love.mousepressed(px, py, 1); love.mousereleased(px, py, 1) end
end

local function button(cb, id)
    for _, b in ipairs(cb.getButtons()) do
        if b.id == id then return b end
    end
    error("Missing button: " .. id)
end

local function click(cb, id)
    local b = button(cb, id)
    pointer(b.x + b.w / 2, b.y + b.h / 2, true)
end

local function blocked(cb, prefix)
    assert(UI.descriptionCandidate == nil and descriptions == 0, "Background tooltip leaked")
    for _, b in ipairs(cb.getButtons()) do
        assert(b.id:find(prefix, 1, true) == 1, "Background button leaked: " .. b.id)
    end
end

function T.update(game, cb)
    if love.timer.getTime() < deadline or step > 0 and drawnFrames < 3 then return end
    if step == 0 then
        local draw, drawButton, describe = love.draw, UI.drawButton, UI.Description.draw
        UI.drawButton = function(b, hover, ...)
            if hover then hovered[b.id] = true end
            return drawButton(b, hover, ...)
        end
        UI.Description.draw = function(...)
            descriptions = descriptions + 1
            return describe(...)
        end
        love.draw = function(...)
            hovered, descriptions = {}, 0
            draw(...)
            drawnFrames = drawnFrames + 1
        end
        cb.startNewGame("red_deck")
        game.shopMode = "soul"; game.souls = 320; cb.openShop()
        pointer(630, 540)
    elseif step == 1 then
        assert(UI.descriptionCandidate and descriptions > 0, "Fixture must hover a soul offer")
        love.keypressed("escape")
        pointer(630, 494)
    elseif step == 2 then
        blocked(cb, "pause_")
        assert(hovered.pause_quit, "Pause button must still hover")
        click(cb, "pause_settings")
    elseif step == 3 then
        assert(UI.descriptionCandidate == nil and descriptions == 0, "Settings tooltip leaked")
        assert(not hovered.pause_settings, "Covered pause button still hovered")
        click(cb, "close_settings")
    elseif step == 4 then
        blocked(cb, "pause_")
        click(cb, "pause_resume"); pointer(630, 540)
    elseif step == 5 then
        assert(UI.descriptionCandidate and descriptions > 0, "Shop hover must resume")
        cb.openDeckViewer()
        pointer(630, 540)
    elseif step == 6 then
        assert(UI.descriptionCandidate == nil and descriptions == 0, "Deck viewer leaked shop tooltip")
        cb.closeDeckViewer(); cb.openHandbook(); pointer(630, 540)
    elseif step == 7 then
        assert(UI.descriptionCandidate == nil and descriptions == 0, "Handbook leaked shop tooltip")
        cb.closeHandbook(); pointer(630, 540)
    elseif step == 8 then
        assert(UI.descriptionCandidate and descriptions > 0, "Shop hover must resume after overlays")
        game.shopMode = "large"; cb.openShop()
        stockItem = {category="pack",packType="seal",name="RƯƠNG CON DẤU",desc="Background offer",cost=6}
        cb.getShopData().items = {stockItem}
        local x,y,w,h = require("ui.shop_display").position(stockItem,1,1)
        stockX,stockY = x+w/2,y+h+12
        pointer(stockX,stockY)
        local isDown = love.keyboard.isDown
        love.keyboard.isDown = function(...)
            for _, key in ipairs({...}) do
                if T.shiftHeld and (key == "lshift" or key == "rshift") then return true end
            end
            return isDown(...)
        end
    elseif step > 8 then
        local pack = Shop.PACK_CATALOG[packIndex]
        if packPhase == 0 then
            assert(UI.descriptionCandidate == stockItem and descriptions > 0,
                "Fixture must hover background pack: candidate="..tostring(UI.descriptionCandidate and UI.descriptionCandidate.name).." descriptions="..descriptions)
            T.shiftHeld = true
            cb.openPack(pack,packIndex == 1)
            packPhase = 1
        elseif packPhase == 1 then
            assert(UI.descriptionCandidate == nil and descriptions == 0, "Pack leaked stock tooltip: "..pack.packType)
            assert(not hovered.buy_1, "Covered stock button hovered")
            for _, b in ipairs(cb.getButtons()) do
                assert(not b.stockItem and b.id ~= "reroll" and b.id ~= "open_backpack", "Pack leaked stock input")
            end
            cb.getShopData().currentPackOpening.animationTimer = UI.ChestChoices.finished()
            T.shiftHeld = false
            local pose = UI.ChestChoices.pose(UI.ChestChoices.finished(),1)
            pointer(pose.x+100,pose.y+100)
            packPhase = 2
        elseif packPhase == 2 then
            assert(UI.descriptionCandidate == cb.getShopData().currentPackOpening.cards[1] and descriptions > 0,
                "Reward tooltip must still work: "..pack.packType)
            cb.openPauseMenu(); packPhase = 3
        elseif packPhase == 3 then
            blocked(cb,"pause_")
            cb.closePauseMenu(); cb.closePack(); pointer(stockX,stockY)
            print("PACK HOVER PASS: "..pack.packType)
            packIndex = packIndex+1; packPhase = 0
            if packIndex > #Shop.PACK_CATALOG then
                cb.openShopTransfer(); packPhase = 4
            end
        elseif packPhase == 4 then
            assert(UI.descriptionCandidate ~= stockItem, "Equipment transfer leaked stock tooltip")
            cb.closeShopTransfer(); pointer(stockX,stockY); packPhase = 5
        elseif packPhase == 5 then
            assert(UI.descriptionCandidate == stockItem and descriptions > 0, "Shop hover must resume after packs/transfer")
            print("MODAL HOVER PASS: global dialogs, every pack, pinned tooltip, reward hover, transfer, resume")
            love.event.quit(0)
        end
    end
    step = step + 1
    drawnFrames = 0
    deadline = love.timer.getTime() + 0.6
end
return T

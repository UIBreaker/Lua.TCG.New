local Capture = {}

local frame = 0
local Equipment = require("src.equipment")
local Deities = require("src.deities")

local function clickVirtual(x, y)
    local w, h = love.graphics.getDimensions()
    local scale = math.min(w / 1280, h / 720)
    love.mousepressed((w - 1280 * scale) / 2 + x * scale,
        (h - 720 * scale) / 2 + y * scale, 1)
end

local function saveImage(name)
    love.graphics.captureScreenshot(function(imgData)
        local fileData = imgData:encode("png")
        local bytes = fileData:getString()
        local f = io.open(name, "wb")
        if f then
            f:write(bytes)
            f:close()
            print("[CAPTURED] " .. name)
        else
            print("[ERROR OPENING] " .. name)
        end
    end)
end

function Capture.update(gameRef, callbacks)
    frame = frame + 1

    if frame == 2 then
        saveImage("shot_main_menu.png")

    elseif frame == 4 then
        if callbacks.openCollection then callbacks.openCollection(nil) end
        saveImage("shot_collection_hub.png")

    elseif frame == 6 then
        if callbacks.openCollection then callbacks.openCollection("jokers") end
        saveImage("shot_collection_detail.png")

    elseif frame == 7 then
        if callbacks.openCollection then callbacks.openCollection("consumables") end
        saveImage("shot_collection_equipment.png")

    elseif frame == 8 then
        if callbacks.openCollection then callbacks.openCollection("packs") end
        saveImage("shot_collection_packs.png")

    elseif frame == 9 then
        if callbacks.openCollection then callbacks.openCollection("other") end
        saveImage("shot_collection_hands.png")

    elseif frame == 10 then
        if callbacks.closeCollection then callbacks.closeCollection() end
        if callbacks.setMenuMode then callbacks.setMenuMode("deck_select") end
        saveImage("shot_menu.png")

    elseif frame == 12 then
        callbacks.startNewGame("red_deck")
        if callbacks.openPauseMenu then callbacks.openPauseMenu() end
        saveImage("shot_pause_menu.png")

    elseif frame == 18 then
        if callbacks.closePauseMenu then callbacks.closePauseMenu() end
        if callbacks.openSettings then callbacks.openSettings() end
        saveImage("shot_settings.png")

    elseif frame == 19 then
        if not callbacks.isDebugEnabled() then clickVirtual(760, 430) end

    elseif frame == 20 then
        saveImage("shot_settings_debug.png")

    elseif frame == 21 then
        clickVirtual(640, 485)

    elseif frame == 22 then
        saveImage("shot_debug.png")
        clickVirtual(200, 300)
        love.textinput("123")

    elseif frame == 23 then
        clickVirtual(620, 300)
        assert(gameRef.gold == 123, "Debug gold control must update the run")
        clickVirtual(350, 120)

    elseif frame == 24 then
        saveImage("shot_debug_teleport.png")
        clickVirtual(550, 120)

    elseif frame == 25 then
        saveImage("shot_debug_items.png")
        clickVirtual(250, 338)
        assert(Deities.getCount(gameRef.deities) == 1, "Debug collection button must grant a spirit")
        clickVirtual(1130, 65)

    elseif frame == 26 then
        if callbacks.closeSettings then callbacks.closeSettings() end
        saveImage("shot_map.png")

    elseif frame == 34 then
        callbacks.startMonsterEncounter(1, false)
        gameRef.deities = {
            [1] = { id = "deity_aurelia", name = "Aurelia", edition = "negative" },
            [2] = { id = "deity_genesis", name = "Khởi Nguyên", currentMult = 4 },
            [3] = { id = "deity_iron", name = "Thiết Thứ" },
            [4] = { id = "deity_gold", name = "Kim Tài" },
            [5] = { id = "deity_swarm", name = "Bầy Đàn" },
        }
        gameRef.consumables = {
            { id = "spell_aura", name = "Aura", category = "joker_spell", icon = "✨", desc = "Thêm Foil, Holo hoặc Poly cho 1 Joker ngẫu nhiên", color = { 0.95, 0.45, 0.85, 1 } }
        }
        if gameRef.hand and gameRef.hand[1] then
            Equipment.attach(gameRef.hand[1], Equipment.ITEMS.gem_fire)
            Equipment.attach(gameRef.hand[1], Equipment.ITEMS.mirror_adjacent)
        end
        saveImage("shot_combat_starter.png")

    elseif frame == 44 then
        callbacks.openInspector(gameRef.hand[1])
        saveImage("shot_card_inspector.png")

    elseif frame == 54 then
        callbacks.closeInspector()
        callbacks.openHandbook()
        saveImage("shot_handbook.png")

    elseif frame == 64 then
        callbacks.closeHandbook()
        callbacks.openShop()

    elseif frame == 68 then
        saveImage("shot_shop.png")

    elseif frame == 70 then
        if callbacks.openPack then
            callbacks.openPack({ packType = "joker_edition", name = "Gói Phù Phép Joker", cost = 6 })
        end

    elseif frame == 72 then
        saveImage("shot_pack_keep.png")

    elseif frame == 74 then
        if callbacks.closePack then callbacks.closePack() end

    elseif frame == 78 then
        Equipment.attach(gameRef.persistentDeck[1], Equipment.ITEMS.gem_fire)
        callbacks.openShopTransfer()
        saveImage("shot_shop_transfer.png")

    elseif frame == 80 then
        clickVirtual(809, 400)
        assert(select(2, callbacks.getShopTransferState()) == 2, "Transfer next-page button must respond")

    elseif frame == 81 then
        clickVirtual(470, 400)
        assert(select(2, callbacks.getShopTransferState()) == 1, "Transfer previous-page button must respond")

    elseif frame == 82 then
        clickVirtual(345, 180)
        assert(select(3, callbacks.getShopTransferState()) == gameRef.persistentDeck[1], "Transfer source card must respond")

    elseif frame == 83 then
        clickVirtual(300, 465)
        assert(select(4, callbacks.getShopTransferState()) == 1, "Transfer equipment choice must respond")

    elseif frame == 84 then
        clickVirtual(430, 180)
        assert(#gameRef.persistentDeck[1].equipments == 0 and #gameRef.persistentDeck[2].equipments == 1,
            "Transfer target card must receive the equipment")

    elseif frame == 85 then
        clickVirtual(900, 635)
        assert(not callbacks.getShopTransferState(), "Transfer close button must respond")

    elseif frame == 86 then
        callbacks.closeShopTransfer()
        callbacks.openRest()
        saveImage("shot_rest.png")

    elseif frame == 92 then
        callbacks.openBossDeity()
        saveImage("shot_boss_deity.png")

    elseif frame == 102 then
        -- Add 1 reward card (e.g. K of Spades) to persistent deck and open Socketing
        local Deck = require("src.deck")
        local kSpades = Deck.newCard(13, "valoria")
        Deck.addCardToDeck(gameRef, kSpades)
        callbacks.openSocketing(Equipment.ITEMS.vitality_gem)
        saveImage("shot_socketing_fix.png")

    elseif frame == 112 then
        callbacks.openDeckViewer()
        saveImage("shot_deck_viewer_fix.png")

    elseif frame == 122 then
        callbacks.closeDeckViewer()
        callbacks.startMonsterEncounter(1, false)
        callbacks.selectCardIndex(1)
        saveImage("shot_hand_selection_fix.png")

    elseif frame == 132 then
        callbacks.playSelectedHand()

    elseif frame == 145 then
        saveImage("shot_scoring_juice.png")

    elseif frame == 160 then
        callbacks.openSettings()

    elseif frame == 161 then
        clickVirtual(640, 485)

    elseif frame == 162 then
        clickVirtual(350, 120)

    elseif frame == 163 then
        clickVirtual(350, 175)
        love.textinput("9")

    elseif frame == 164 then
        clickVirtual(500, 175)
        clickVirtual(180, 350)
        assert(gameRef.run.ante == 9 and gameRef.monster and gameRef.monster.isBoss,
            "Debug teleport must start Boss combat at the selected Ante")

    elseif frame == 165 then
        print("All screenshots captured!")
        love.event.quit(0)
    end
end

return Capture

local Rng = require("src.rng")
local Map = {}

Map.NODE_TYPES = {
    monster = {
        type = "monster",
        name = "Quái Vật",
        icon = "⚔",
        desc = "Giao chiến quái vật để tích lũy vàng và tôi luyện bài.",
        color = { 0.85, 0.35, 0.35, 1 },
        bgColor = { 0.25, 0.12, 0.12, 0.95 },
    },
    elite = {
        type = "elite",
        name = "Quái Tinh Anh",
        icon = "!",
        desc = "Quái vật cấp cao đầy nguy hiểm. Phần thưởng cực lớn: Vàng khủng + Rương Trang Bị!",
        color = { 0.98, 0.50, 0.20, 1 },
        bgColor = { 0.28, 0.16, 0.10, 0.95 },
    },
    shop = {
        type = "shop",
        name = "Cửa Hàng",
        icon = "$",
        desc = "Mua Bí Tịch, Trang Bị, thêm Bài mới và Hoán Đổi Trang Bị giữa các lá bài.",
        color = { 0.95, 0.80, 0.25, 1 },
        bgColor = { 0.24, 0.20, 0.10, 0.95 },
    },
    event = {
        type = "event",
        name = "Kỳ Ngộ Bí Ẩn",
        icon = "?",
        desc = "Gặp gỡ cơ duyên cổ đại: Suối thánh, Miếu cổ, Tiên tri bí truyền.",
        color = { 0.40, 0.75, 0.95, 1 },
        bgColor = { 0.12, 0.18, 0.24, 0.95 },
    },
    rest = {
        type = "rest",
        name = "Trạm Nghỉ & Lò Rèn",
        icon = "T",
        desc = "Dưỡng Sức (tăng lượt đánh/đổi) hoặc Mài Sắc Bài (tăng Rank +1 phục hồi độ bền).",
        color = { 0.35, 0.88, 0.55, 1 },
        bgColor = { 0.12, 0.24, 0.16, 0.95 },
    },
    treasure = {
        type = "treasure",
        name = "Rương Báu Cổ",
        icon = "R",
        desc = "Mở rương nhận miễn phí Trang bị hiếm hoặc Lá bài viện binh phẩm chất cao!",
        color = { 0.85, 0.45, 0.95, 1 },
        bgColor = { 0.22, 0.12, 0.26, 0.95 },
    },
    boss = {
        type = "boss",
        name = "TRÙM TỐI CAO",
        icon = "W",
        desc = "Thủ lĩnh tối cao Tầng 20! Tiêu diệt để chọn 1 trong 2 HỘ LINH!",
        color = { 1.0, 0.25, 0.25, 1 },
        bgColor = { 0.30, 0.10, 0.10, 0.95 },
    },
}

Map.SKIP_TAGS = {
    {
        id = "gold_pack",
        name = "Túi Vàng Cực Lớn",
        desc = "Nhận ngay +$15 Vàng vào túi!",
        color = { 0.95, 0.85, 0.25, 1 },
        icon = "💰",
        apply = function(gameState)
            gameState.gold = (gameState.gold or 0) + 15
            return "+$15 Vàng!"
        end,
    },
    {
        id = "free_upgrade",
        name = "Thẻ Rèn Thần Tốc",
        desc = "Nâng cấp vĩnh viễn 2 lá bài (+1 Rank)!",
        color = { 0.35, 0.85, 0.45, 1 },
        icon = "⚒️",
        apply = function(gameState)
            local upgraded = 0
            if gameState.persistentDeck and #gameState.persistentDeck > 0 then
                local Deck = require("src.deck")
                for i = 1, math.min(2, #gameState.persistentDeck) do
                    local idx = Rng.random(#gameState.persistentDeck)
                    local c = gameState.persistentDeck[idx]
                    if c then
                        Deck.upgradeCard(c)
                        upgraded = upgraded + 1
                    end
                end
            end
            return "Đã nâng cấp " .. upgraded .. " lá bài (+1 Rank)!"
        end,
    },
    {
        id = "gear_pack",
        name = "Gói Trang Bị Quý",
        desc = "Nhận ngay 1 Trang Bị Quý Tộc khảm vào bài!",
        color = { 0.85, 0.45, 0.95, 1 },
        icon = "💎",
        apply = function(gameState)
            local Equipment = require("src.equipment")
            local items = { Equipment.ITEMS.gem_fire, Equipment.ITEMS.gem_lightning, Equipment.ITEMS.holy_relic, Equipment.ITEMS.dark_blade }
            local chosenEq = items[Rng.random(#items)]
            if gameState.persistentDeck and #gameState.persistentDeck > 0 then
                local c = gameState.persistentDeck[1]
                Equipment.attach(c, chosenEq)
                return "Khảm thành công: " .. chosenEq.name .. " vào " .. (c.rankName or "bài") .. "!"
            end
            return "Đã nhận trang bị: " .. chosenEq.name
        end,
    },
    {
        id = "rare_deity",
        name = "Hộ Linh Bí Ẩn",
        desc = "Nhận ngay 1 Hộ Linh ngẫu nhiên trợ chiến!",
        color = { 0.95, 0.4, 0.25, 1 },
        icon = "👑",
        apply = function(gameState)
            local Deities = require("src.deities")
            local pool = Deities.getBossDraftPool(gameState.deities or {}, 1)
            if pool and pool[1] then
                Deities.addDeity(gameState, pool[1])
                return "Đã nhận Hộ Linh: " .. pool[1].name .. "!"
            end
            return "Đã nhận Hộ Linh!"
        end,
    },
}

function Map.skipCombatNode(gameState, nodeId)
    local node = gameState.map and gameState.map.nodes and gameState.map.nodes[nodeId]
    if not node or not node.skipTag then return false, "Không thể bỏ qua ải này" end

    local rewardMsg = node.skipTag.apply(gameState)
    -- Advance encounter count so subsequent monsters are stronger
    gameState.monsterEncounterCount = (gameState.monsterEncounterCount or 1) + 1
    -- Complete node on map
    Map.onNodeCompleted(gameState.map, nodeId)
    return true, rewardMsg, node.skipTag
end

function Map.generate(act)
    act = act or 1
    local totalFloors = 20
    local nodes = {}
    local nodesByFloor = {}

    for f = 1, totalFloors do
        nodesByFloor[f] = {}
    end

    local floorBlueprints = {
        [1]  = { { type = "monster", title = "Yêu Tinh Rừng Xanh" }, { type = "monster", title = "Thạch Quỷ Nham Thạch" } },
        [2]  = { { type = "monster", title = "Quái Thường" }, { type = "event", title = "Kỳ Ngộ Đầu Tiên" } },
        [3]  = { { type = "shop", title = "Tiệm Rèn Đầu Tiên" }, { type = "monster", title = "Bóng Ma Đầm Lầy" }, { type = "event", title = "Kỳ Ngộ Cổ Đại" } },
        [4]  = { { type = "monster", title = "Sói Băng Cực Bắc" }, { type = "event", title = "Suối Nguồn Thần Bí" } },
        [5]  = { { type = "rest", title = "Trạm Nghỉ & Lò Rèn 1" }, { type = "rest", title = "Lò Rèn Cổ Tầng 5" } },
        [6]  = { { type = "elite", title = "Hắc Ám Long Kỵ Sĩ" }, { type = "elite", title = "Hắc Ám Long Kỵ Sĩ" } },
        [7]  = { { type = "treasure", title = "Rương Báu Cổ Tầng 7" }, { type = "treasure", title = "Rương Kho Báu Cổ" } },
        [8]  = { { type = "shop", title = "Cửa Hàng Lữ Khách" }, { type = "event", title = "Đền Thờ Kỳ Duyên" }, { type = "monster", title = "Bọ Cạp Sa Mạc" } },
        [9]  = { { type = "monster", title = "Hiệp Sĩ Xương Cổ" }, { type = "event", title = "Kỳ Duyên Đạo Nhân" } },
        [10] = { { type = "rest", title = "Trạm Nghỉ & Lò Rèn 2" }, { type = "rest", title = "Lò Rèn Cổ Tầng 10" } },
        [11] = { { type = "elite", title = "Huyết Quỷ Sa Mạc" }, { type = "elite", title = "Huyết Quỷ Sa Mạc" } },
        [12] = { { type = "shop", title = "Chợ Đêm Thần Bí" }, { type = "monster", title = "Phù Thủy Hắc Ám" }, { type = "event", title = "Miếu Cổ Hoang Phế" } },
        [13] = { { type = "treasure", title = "Rương Báu Cổ Tầng 13" }, { type = "treasure", title = "Rương Kho Báu Cổ" } },
        [14] = { { type = "monster", title = "Rồng Đất Cổ Đại" }, { type = "event", title = "Tiên Tri Huyền Bí" } },
        [15] = { { type = "rest", title = "Trạm Nghỉ & Lò Rèn 3" }, { type = "rest", title = "Lò Rèn Cổ Tầng 15" } },
        [16] = { { type = "elite", title = "Cự Ma Băng Giá" }, { type = "elite", title = "Cự Ma Băng Giá" } },
        [17] = { { type = "shop", title = "Cửa Hàng Lữ Khách" }, { type = "event", title = "Kỳ Ngộ Tối Thượng" }, { type = "monster", title = "Hắc Long Thức Tỉnh" } },
        [18] = { { type = "monster", title = "Vệ Binh Cổng Địa Ngục" }, { type = "event", title = "Linh Tuyền Tiếp Sức" } },
        [19] = { { type = "shop", title = "Trạm Tiếp Tế Trước Trùm" }, { type = "rest", title = "Lò Rèn Cuối Cùng" } },
        [20] = { { type = "boss", title = "TỐI THƯỢNG TRÙM TẦNG 20" } },
    }

    for f = 1, totalFloors do
        local bpList = floorBlueprints[f] or { { type = "monster", title = "Quái Tầng " .. f } }
        for col, bp in ipairs(bpList) do
            local id = "f" .. f .. "_" .. col
            local skipTag = nil
            if bp.type == "monster" or bp.type == "elite" then
                local tagIdx = ((f * 3 + col) % #Map.SKIP_TAGS) + 1
                skipTag = Map.SKIP_TAGS[tagIdx]
            end

            local node = {
                id = id,
                floor = f,
                col = col,
                type = bp.type,
                title = bp.title,
                skipTag = skipTag,
                connectedTo = {},
                visited = false,
                available = (f == 1),
            }
            nodes[id] = node
            table.insert(nodesByFloor[f], node)
        end
    end

    for f = 1, totalFloors - 1 do
        local currFloorNodes = nodesByFloor[f]
        local nextFloorNodes = nodesByFloor[f + 1]
        local nCurr = #currFloorNodes
        local nNext = #nextFloorNodes

        if nCurr == 1 and nNext == 1 then
            table.insert(currFloorNodes[1].connectedTo, nextFloorNodes[1].id)
        elseif nCurr == 1 then
            for _, nextN in ipairs(nextFloorNodes) do
                table.insert(currFloorNodes[1].connectedTo, nextN.id)
            end
        elseif nNext == 1 then
            for _, currN in ipairs(currFloorNodes) do
                table.insert(currN.connectedTo, nextFloorNodes[1].id)
            end
        elseif nCurr == 2 and nNext == 2 then
            table.insert(currFloorNodes[1].connectedTo, nextFloorNodes[1].id)
            table.insert(currFloorNodes[1].connectedTo, nextFloorNodes[2].id)
            table.insert(currFloorNodes[2].connectedTo, nextFloorNodes[1].id)
            table.insert(currFloorNodes[2].connectedTo, nextFloorNodes[2].id)
        elseif nCurr == 2 and nNext == 3 then
            table.insert(currFloorNodes[1].connectedTo, nextFloorNodes[1].id)
            table.insert(currFloorNodes[1].connectedTo, nextFloorNodes[2].id)
            table.insert(currFloorNodes[2].connectedTo, nextFloorNodes[2].id)
            table.insert(currFloorNodes[2].connectedTo, nextFloorNodes[3].id)
        elseif nCurr == 3 and nNext == 2 then
            table.insert(currFloorNodes[1].connectedTo, nextFloorNodes[1].id)
            table.insert(currFloorNodes[2].connectedTo, nextFloorNodes[1].id)
            table.insert(currFloorNodes[2].connectedTo, nextFloorNodes[2].id)
            table.insert(currFloorNodes[3].connectedTo, nextFloorNodes[2].id)
        else
            for _, currN in ipairs(currFloorNodes) do
                for _, nextN in ipairs(nextFloorNodes) do
                    table.insert(currN.connectedTo, nextN.id)
                end
            end
        end
    end

    local startX = 140
    local floorSpacingX = 190
    local centerY = 370

    for f = 1, totalFloors do
        local floorNodes = nodesByFloor[f]
        local count = #floorNodes
        local startY = centerY - (count - 1) * 75
        for i, n in ipairs(floorNodes) do
            n.x = startX + (f - 1) * floorSpacingX
            n.y = startY + (i - 1) * 150
            n.w = (f == 20) and 125 or ((n.type == "elite" or n.type == "treasure") and 96 or 88)
            n.h = n.w
        end
    end

    local maxScroll = math.max(0, startX + (totalFloors - 1) * floorSpacingX + 220 - 1280)

    return {
        act = act,
        totalFloors = totalFloors,
        nodes = nodes,
        nodesByFloor = nodesByFloor,
        currentFloor = 1,
        currentNodeId = nil,
        scrollX = 0,
        targetScrollX = 0,
        maxScroll = maxScroll,
    }
end

function Map.onNodeCompleted(map, completedNodeId)
    local curr = map.nodes[completedNodeId]
    if not curr then return end

    curr.visited = true
    curr.available = false
    map.currentNodeId = completedNodeId

    if map.nodesByFloor[curr.floor] then
        for _, n in ipairs(map.nodesByFloor[curr.floor]) do
            n.available = false
        end
    end

    for _, targetId in ipairs(curr.connectedTo) do
        local target = map.nodes[targetId]
        if target then
            target.available = true
        end
    end

    map.currentFloor = curr.floor + 1
    Map.focusFloor(map, map.currentFloor)
end

function Map.focusFloor(map, floor)
    if not map then return end
    local floorX = 140 + (floor - 1) * 190
    map.targetScrollX = math.max(0, math.min(map.maxScroll, floorX - 420))
end

function Map.scroll(map, delta)
    if not map then return end
    map.targetScrollX = math.max(0, math.min(map.maxScroll, map.targetScrollX + delta))
end

function Map.update(map, dt)
    if not map then return end
    if map.scrollX ~= map.targetScrollX then
        map.scrollX = map.scrollX + (map.targetScrollX - map.scrollX) * math.min(1, dt * 12)
        if math.abs(map.targetScrollX - map.scrollX) < 1 then
            map.scrollX = map.targetScrollX
        end
    end
end

function Map.getNodeAt(map, mx, my)
    if not map then return nil end
    local scrollX = map.scrollX or 0
    for _, n in pairs(map.nodes) do
        local screenX = n.x - scrollX
        local rad = n.w / 2
        local dist = math.sqrt((mx - screenX)^2 + (my - n.y)^2)
        if dist <= rad then
            return n
        end
    end
    return nil
end

function Map.draw(map, mx, my, UI)
    if not map then return end
    local scrollX = map.scrollX or 0

    -- 1. Draw Connecting Path Lines
    love.graphics.setLineWidth(3)
    for _, node in pairs(map.nodes) do
        for _, targetId in ipairs(node.connectedTo) do
            local target = map.nodes[targetId]
            if target then
                local x1 = node.x - scrollX
                local y1 = node.y
                local x2 = target.x - scrollX
                local y2 = target.y

                if (x1 >= -100 or x2 >= -100) and (x1 <= 1380 or x2 <= 1380) then
                    local isPathActive = node.visited and target.available
                    if isPathActive then
                        love.graphics.setColor(UI.COLORS.goldYellow[1], UI.COLORS.goldYellow[2], UI.COLORS.goldYellow[3], 0.85)
                    elseif node.visited then
                        love.graphics.setColor(0.35, 0.45, 0.55, 0.5)
                    else
                        love.graphics.setColor(0.20, 0.25, 0.30, 0.4)
                    end
                    love.graphics.line(x1, y1, x2, y2)
                end
            end
        end
    end

    -- 2. Draw Nodes
    local hoveredNode = nil
    for _, node in pairs(map.nodes) do
        local screenX = node.x - scrollX
        if screenX >= -120 and screenX <= 1400 then
            local meta = Map.NODE_TYPES[node.type] or Map.NODE_TYPES.monster
            local rad = node.w / 2
            local dist = math.sqrt((mx - screenX)^2 + (my - node.y)^2)
            local isHovered = (dist <= rad)
            if isHovered then hoveredNode = node end

            if node.available then
                local pulse = math.sin(love.timer.getTime() * 4) * 4
                love.graphics.setColor(meta.color[1], meta.color[2], meta.color[3], 0.35)
                love.graphics.circle("fill", screenX, node.y, rad + 7 + pulse)
            end

            if node.visited then
                love.graphics.setColor(0.12, 0.15, 0.18, 0.90)
            elseif node.available then
                love.graphics.setColor(meta.bgColor)
            else
                love.graphics.setColor(0.10, 0.12, 0.14, 0.75)
            end
            love.graphics.circle("fill", screenX, node.y, rad)

            love.graphics.setLineWidth((isHovered and node.available) and 4 or (node.available and 3 or 1.5))
            if node.visited then
                love.graphics.setColor(0.35, 0.45, 0.55, 0.7)
            elseif node.available then
                love.graphics.setColor(isHovered and UI.COLORS.goldYellow or meta.color)
            else
                love.graphics.setColor(0.28, 0.32, 0.38, 0.5)
            end
            love.graphics.circle("line", screenX, node.y, rad)

            if node.visited then
                love.graphics.setColor(UI.COLORS.hpGreen)
                love.graphics.setLineWidth(3.5)
                love.graphics.line(screenX - 11, node.y, screenX - 3, node.y + 8, screenX + 12, node.y - 8)
            else
                local iconCol = node.available and meta.color or { 0.45, 0.50, 0.55, 0.7 }
                love.graphics.setColor(iconCol)

                if node.type == "monster" then
                    love.graphics.setLineWidth(2.5)
                    love.graphics.line(screenX - 10, node.y - 10, screenX + 10, node.y + 10)
                    love.graphics.line(screenX + 10, node.y - 10, screenX - 10, node.y + 10)
                    love.graphics.circle("fill", screenX, node.y, 3)
                elseif node.type == "elite" then
                    love.graphics.setFont(UI.fonts.medium)
                    love.graphics.printf("!", screenX - 25, node.y - 14, 50, "center")
                elseif node.type == "shop" then
                    love.graphics.setFont(UI.fonts.large)
                    love.graphics.printf("$", screenX - 25, node.y - 16, 50, "center")
                elseif node.type == "event" then
                    love.graphics.setFont(UI.fonts.large)
                    love.graphics.printf("?", screenX - 25, node.y - 16, 50, "center")
                elseif node.type == "rest" then
                    love.graphics.polygon("fill",
                        screenX, node.y - 12,
                        screenX + 11, node.y + 10,
                        screenX - 11, node.y + 10
                    )
                elseif node.type == "treasure" then
                    love.graphics.rectangle("fill", screenX - 12, node.y - 8, 24, 18, 3, 3)
                    love.graphics.setColor(0.1, 0.1, 0.1, 1)
                    love.graphics.circle("fill", screenX, node.y + 1, 2.5)
                elseif node.type == "boss" then
                    love.graphics.polygon("fill",
                        screenX - 18, node.y + 10,
                        screenX + 18, node.y + 10,
                        screenX + 16, node.y - 10,
                        screenX + 6, node.y,
                        screenX, node.y - 16,
                        screenX - 6, node.y,
                        screenX - 16, node.y - 10
                    )
                end
            end

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(node.available and UI.COLORS.textLight or UI.COLORS.textMuted)
            love.graphics.printf("T" .. node.floor .. ": " .. meta.name, screenX - 65, node.y + rad + 5, 130, "center")
        end
    end

    -- 3. Top Progress Bar (Floors 1 to 20 Mini-Tracker)
    local barW = 860
    local barH = 12
    local barX = (1280 - barW) / 2
    local barY = 96

    love.graphics.setColor(0.12, 0.16, 0.20, 0.9)
    UI.drawRoundedRect("fill", barX, barY, barW, barH, 4)
    love.graphics.setColor(0.3, 0.35, 0.45, 0.5)
    UI.drawRoundedRect("line", barX, barY, barW, barH, 4)

    local progressFrac = math.min(1.0, math.max(0, (map.currentFloor - 1) / 19))
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("fill", barX, barY, barW * progressFrac, barH, 4)

    -- 4. Hover Tooltip for hovered node
    if hoveredNode then
        local meta = Map.NODE_TYPES[hoveredNode.type] or Map.NODE_TYPES.monster
        local ttW = 270
        local ttH = 90
        local ttx = math.min(1280 - ttW - 20, math.max(20, mx + 16))
        local tty = math.min(720 - ttH - 20, math.max(20, my - 30))

        love.graphics.setColor(0.08, 0.10, 0.14, 0.96)
        UI.drawRoundedRect("fill", ttx, tty, ttW, ttH, 8)
        love.graphics.setColor(hoveredNode.available and meta.color or { 0.4, 0.45, 0.5, 0.8 })
        UI.drawRoundedRect("line", ttx, tty, ttW, ttH, 8)

        love.graphics.setFont(UI.fonts.small)
        love.graphics.setColor(meta.color)
        love.graphics.print(hoveredNode.title .. " (Tầng " .. hoveredNode.floor .. ")", ttx + 12, tty + 10)

        love.graphics.setFont(UI.fonts.tiny)
        love.graphics.setColor(UI.COLORS.textLight)
        love.graphics.printf(meta.desc, ttx + 12, tty + 34, ttW - 24, "left")

        love.graphics.setColor(hoveredNode.available and UI.COLORS.goldYellow or (hoveredNode.visited and UI.COLORS.hpGreen or UI.COLORS.multRed))
        local statusText = hoveredNode.visited and "• Đã hoàn thành" or (hoveredNode.available and "▶ Nhấp để tiến vào!" or "• Chưa thể đi tới")
        love.graphics.print(statusText, ttx + 12, tty + 66)
    end
end

return Map

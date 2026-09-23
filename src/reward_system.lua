local UI = require("src.ui")
local Sound = require("src.sound")
local Deities = require("src.deities")

local RewardSystem = {}

-- Calculate cash out breakdown from the 5 sources
function RewardSystem.calculate(blind, gameState, wasSkipped)
    local wasSkip = (wasSkipped == true)
    local basePayout = 0
    if not wasSkip and blind then
        basePayout = blind.baseReward or (blind.type == "boss" and 5 or (blind.type == "big" and 4 or 3))
    end

    -- 1. Unused Hands (+1$ each)
    local handsLeft = (not wasSkip and (gameState.handsRemaining or 0)) or 0
    local unusedHandsBonus = handsLeft * 1

    -- 2. Interest (+1$ per 5$ stored, max 3$ default or 5$ with Seed Money voucher)
    -- Trần Lãi Siêu Việt: Gilded Conclave gets +1$ per 4$ stored with NO CAP!
    local isGilded = (gameState.selectedFaction == "diamonds" or gameState.selectedFaction == "gilded_conclave" or gameState.isGildedConclave == true)
    local maxInt = gameState.maxInterest or 3
    if gameState.vouchers and (gameState.vouchers["v_interest"] or gameState.vouchers["seed_money"]) then
        maxInt = math.max(maxInt, 5)
    end
    local currentGold = gameState.gold or 0
    local interestBonus
    if isGilded then
        interestBonus = math.floor(currentGold / 4)
    else
        interestBonus = math.min(maxInt, math.floor(currentGold / 5))
    end

    -- 3. Deities onRoundWin Bonuses (Use cached from main.lua if available to prevent double execution)
    local deityBonus = 0
    local deityDetails = {}
    if not wasSkip then
        if gameState.lastRoundDeityRewards then
            deityBonus = gameState.lastRoundDeityRewards.bonusGold or 0
            deityDetails = gameState.lastRoundDeityRewards.details or {}
        elseif gameState.deities then
            local maxDeiSlots = Deities.getMaxSlots and Deities.getMaxSlots(gameState) or 10
            for di = 1, maxDeiSlots do
                local d = gameState.deities[di]
                if d then
                    local effectiveDeity = Deities.resolveDeity and Deities.resolveDeity(gameState.deities, di) or d
                    if effectiveDeity and effectiveDeity.onRoundWin then
                        local r = effectiveDeity.onRoundWin(gameState, effectiveDeity)
                        if r and r.addGold and r.addGold > 0 then
                            deityBonus = deityBonus + r.addGold
                            table.insert(deityDetails, {
                                slotIndex = di,
                                name = d.name,
                                amount = r.addGold,
                                message = r.message or ("+$" .. r.addGold .. " từ " .. d.name),
                            })
                        end
                    end
                end
            end
        end
    end

    -- Subtotal of items 1-4
    local subtotal = basePayout + unusedHandsBonus + interestBonus + deityBonus

    -- 4. Valoria Faction Passive: +25% Gold (math.ceil(subtotal * 0.25))
    local factionBonus = 0
    local isValoria = (gameState.selectedFaction == "valoria" or gameState.selectedSuit == "valoria")
    if isValoria and subtotal > 0 then
        factionBonus = math.ceil(subtotal * 0.25)
    end

    local totalGold = subtotal + factionBonus

    return {
        blind = blind,
        wasSkipped = wasSkip,
        tag = wasSkip and blind and blind.tag,
        basePayout = basePayout,
        handsLeft = handsLeft,
        unusedHandsBonus = unusedHandsBonus,
        currentGold = currentGold,
        maxInterest = maxInt,
        interestBonus = interestBonus,
        isGilded = isGilded,
        deityBonus = deityBonus,
        deityDetails = deityDetails,
        subtotal = subtotal,
        isValoria = isValoria,
        factionBonus = factionBonus,
        totalGold = totalGold,
    }
end

-- Initialize animated state for Cash Out screen
function RewardSystem.newAnimation(breakdown)
    local lines = {}

    -- 1. Nguồn 1: Thưởng Cơ Bản (Blind Reward)
    if breakdown.wasSkipped then
        table.insert(lines, {
            label = "1. THƯỞNG CƠ BẢN (SKIP BLIND)",
            desc = breakdown.tag and ("Bỏ qua nhận Thẻ Bùa Ấn: " .. breakdown.tag.name) or "Đã bỏ qua ải",
            valText = "$0",
            valNum = 0,
            icon = "⏭️",
            color = { 0.7, 0.75, 0.85, 1 },
        })
    else
        local bTitle = breakdown.blind and breakdown.blind.title or "ẢI CHIẾN THẮNG"
        table.insert(lines, {
            label = "1. THƯỞNG CƠ BẢN (" .. bTitle .. ")",
            desc = "Hoàn thành mục tiêu Aura của Blind",
            valText = "+$" .. breakdown.basePayout,
            valNum = breakdown.basePayout,
            icon = "🏆",
            color = UI.COLORS.goldYellow,
        })
    end

    -- 2. Nguồn 2: Lượt Đánh Thừa (Remaining Hands)
    if breakdown.unusedHandsBonus > 0 then
        table.insert(lines, {
            label = "2. LƯỢT ĐÁNH THỪA (REMAINING HANDS)",
            desc = breakdown.handsLeft .. " lượt ra đòn chưa dùng (+$1 mỗi Hand)",
            valText = "+$" .. breakdown.unusedHandsBonus,
            valNum = breakdown.unusedHandsBonus,
            icon = "✋",
            color = UI.COLORS.btnBlue,
        })
    else
        table.insert(lines, {
            label = "2. LƯỢT ĐÁNH THỪA (REMAINING HANDS)",
            desc = "Không còn lượt đánh thừa nào (+$1/Hand)",
            valText = "$0",
            valNum = 0,
            icon = "✋",
            color = UI.COLORS.textMuted,
        })
    end

    -- 3. Nguồn 3: Tiền Lãi (Interest)
    local maxCap = breakdown.maxInterest or 5
    if breakdown.interestBonus > 0 then
        local capStr = (maxCap > 5) and (" (Trần Lãi: +$" .. maxCap .. " từ Seed Money)") or (" (Trần Lãi: +$5 khi có $25)")
        local intDesc = breakdown.isGilded and ("+$1 mỗi $4 sở hữu (Không giới hạn trần! Có $" .. breakdown.currentGold .. ")") or ("+$1 cho mỗi $5 đang sở hữu (Có $" .. breakdown.currentGold .. ")" .. capStr)
        table.insert(lines, {
            label = "3. TIỀN LÃI TIẾT KIỆM (INTEREST)",
            desc = intDesc,
            valText = "+$" .. breakdown.interestBonus,
            valNum = breakdown.interestBonus,
            icon = "🏦",
            color = { 0.35, 0.95, 0.55, 1 },
        })
    else
        local capStr = (maxCap > 5) and " (Trần: +$10)" or " (Trần: +$5)"
        table.insert(lines, {
            label = "3. TIỀN LÃI TIẾT KIỆM (INTEREST)",
            desc = breakdown.isGilded and "Cần tối thiểu $4 trong túi để sinh lãi" or ("+$1 mỗi $5 sở hữu (Cần tối thiểu $5 trong túi)" .. capStr),
            valText = "$0",
            valNum = 0,
            icon = "🏦",
            color = UI.COLORS.textMuted,
        })
    end

    -- 4. Nguồn 4: Hiệu Ứng Bổ Trợ (Vouchers & Jokers)
    if #breakdown.deityDetails > 0 then
        for _, dd in ipairs(breakdown.deityDetails) do
            table.insert(lines, {
                label = "4. HIỆU ỨNG BỔ TRỢ (" .. dd.name:upper() .. ")",
                desc = dd.message,
                valText = "+$" .. dd.amount,
                valNum = dd.amount,
                icon = "👑",
                color = { 0.95, 0.45, 0.85, 1 },
            })
        end
    end

    -- 5. Đặc quyền Valoria (nếu có)
    if breakdown.isValoria and breakdown.factionBonus > 0 then
        table.insert(lines, {
            label = "ĐẶC QUYỀN PHE VALORIA (+25%)",
            desc = "Quân lương viện trợ Nhân Loại",
            valText = "+$" .. breakdown.factionBonus,
            valNum = breakdown.factionBonus,
            icon = "⚔️",
            color = { 0.98, 0.85, 0.25, 1 },
        })
    end

    return {
        breakdown = breakdown,
        lines = lines,
        timer = 0,
        revealedCount = 0,
        totalRevealed = false,
        displayTotal = 0,
        lineInterval = 0.35,
        finished = false,
        buttonActive = false,
        soundPlayed = {},
    }
end

-- Update cash out animation
function RewardSystem.update(anim, dt)
    if not anim or anim.finished then return end

    anim.timer = anim.timer + dt

    -- Unroll lines one by one
    local targetLines = math.min(#anim.lines, math.floor(anim.timer / anim.lineInterval))
    if targetLines > anim.revealedCount then
        anim.revealedCount = targetLines
        Sound.play("coin")
    end

    -- Once all lines unrolled, count up total
    if anim.revealedCount >= #anim.lines then
        local totalDelay = #anim.lines * anim.lineInterval + 0.2
        if anim.timer >= totalDelay then
            if not anim.totalRevealed then
                anim.totalRevealed = true
                Sound.play("shop_buy")
            end
            -- Count up total
            if anim.displayTotal < anim.breakdown.totalGold then
                anim.displayTotal = math.min(anim.breakdown.totalGold, anim.displayTotal + math.max(1, math.floor(anim.breakdown.totalGold * dt * 4)))
            else
                anim.buttonActive = true
                anim.finished = true
            end
        end
    end
end

-- Immediately skip to finished state
function RewardSystem.finishImmediately(anim)
    if not anim then return end
    anim.revealedCount = #anim.lines
    anim.totalRevealed = true
    anim.displayTotal = anim.breakdown.totalGold
    anim.buttonActive = true
    anim.finished = true
end

-- Render Cash Out Modal Screen
function RewardSystem.draw(anim, V_WIDTH, V_HEIGHT, mx, my, buttonsTable)
    if not anim then return end

    -- Dim backdrop
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle("fill", 0, 0, V_WIDTH, V_HEIGHT)

    -- Cash Out Certificate Box
    local modalW = 680
    local modalH = 500
    local modalX = (V_WIDTH - modalW) / 2
    local modalY = (V_HEIGHT - modalH) / 2 - 10

    -- Background Card
    love.graphics.setColor(0.10, 0.13, 0.17, 0.98)
    UI.drawRoundedRect("fill", modalX, modalY, modalW, modalH, 12)
    love.graphics.setLineWidth(3)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX, modalY, modalW, modalH, 12)

    -- Header Ribbon
    local bTitle = (anim.breakdown.blind and anim.breakdown.blind.title) or "ẢI CHIẾN THẮNG"
    local bName = (anim.breakdown.blind and anim.breakdown.blind.name) or ""
    love.graphics.setFont(UI.fonts.title or UI.fonts.large)
    love.graphics.setColor(UI.COLORS.goldYellow)
    love.graphics.printf("TỔNG KẾT CHIẾN LỢI PHẨM", modalX, modalY + 20, modalW, "center")

    love.graphics.setFont(UI.fonts.small)
    love.graphics.setColor(UI.COLORS.textLight)
    local subHeaderText = anim.breakdown.wasSkipped and ("ĐÃ BỎ QUA: " .. bTitle) or ("HẠ GỤC: " .. bTitle .. " — " .. bName)
    love.graphics.printf(subHeaderText, modalX, modalY + 62, modalW, "center")

    -- Decorative divider
    love.graphics.setColor(0.35, 0.45, 0.55, 0.5)
    love.graphics.line(modalX + 30, modalY + 92, modalX + modalW - 30, modalY + 92)

    -- Draw Revealed Lines
    local startY = modalY + 106
    local rowH = 46

    for i = 1, anim.revealedCount do
        local line = anim.lines[i]
        if line then
            local ry = startY + (i - 1) * rowH

            -- Row background alternating
            love.graphics.setColor(0.14, 0.18, 0.23, 0.85)
            UI.drawRoundedRect("fill", modalX + 30, ry, modalW - 60, rowH - 6, 6)

            -- Icon
            love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.print(line.icon or "💰", modalX + 44, ry + 7)

            -- Label & Desc
            love.graphics.setFont(UI.fonts.small)
            love.graphics.setColor(line.color or UI.COLORS.textLight)
            love.graphics.print(line.label, modalX + 85, ry + 5)

            love.graphics.setFont(UI.fonts.tiny)
            love.graphics.setColor(UI.COLORS.textMuted)
            love.graphics.print(line.desc, modalX + 85, ry + 24)

            -- Value Amount
            love.graphics.setFont(UI.fonts.medium or UI.fonts.regular)
            love.graphics.setColor(line.color or UI.COLORS.goldYellow)
            love.graphics.printf(line.valText, modalX + modalW - 170, ry + 9, 130, "right")
        end
    end

    -- Bottom Total Box
    local totalBoxY = modalY + modalH - 120

    -- Formula summary text
    love.graphics.setFont(UI.fonts.tiny)
    love.graphics.setColor(0.70, 0.80, 0.90, 0.85)
    love.graphics.printf("Công thức: Tổng Tiền = Thưởng Blind + Hands Còn Lại + min(floor(Tiền/5), Trần Lãi) + Thưởng Hộ Linh", modalX, totalBoxY - 18, modalW, "center")

    love.graphics.setColor(0.08, 0.10, 0.13, 0.95)
    UI.drawRoundedRect("fill", modalX + 30, totalBoxY, modalW - 60, 48, 8)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(UI.COLORS.goldYellow)
    UI.drawRoundedRect("line", modalX + 30, totalBoxY, modalW - 60, 48, 8)

    love.graphics.setFont(UI.fonts.regular)
    love.graphics.setColor(UI.COLORS.textLight)
    love.graphics.print("TỔNG TIỀN VÀNG THU ĐƯỢC:", modalX + 50, totalBoxY + 14)

    love.graphics.setFont(UI.fonts.large or UI.fonts.title)
    love.graphics.setColor(UI.COLORS.goldYellow)
    local displayValStr = anim.totalRevealed and ("+$" .. anim.displayTotal .. " VÀNG") or "..."
    love.graphics.printf(displayValStr, modalX + modalW - 270, totalBoxY + 8, 230, "right")

    -- Continue Button
    local btnW = 320
    local btnH = 46
    local btnX = (V_WIDTH - btnW) / 2
    local btnY = modalY + modalH - 58

    local btnContinue = {
        id = "cashout_continue",
        text = "TIẾP TỤC ĐẾN CỬA HÀNG ➔",
        x = btnX,
        y = btnY,
        w = btnW,
        h = btnH,
        color = { 0.22, 0.72, 0.42, 1 },
        textColor = { 1, 1, 1, 1 },
        font = UI.fonts.regular,
    }

    if buttonsTable then
        table.insert(buttonsTable, btnContinue)
    end

    local isHovered = (mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH)
    UI.drawButton(btnContinue, isHovered)
end

return RewardSystem

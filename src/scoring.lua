local Scoring = {}
local Deities = require("src.deities")
local Deck = require("src.deck")

local function isSpade(card)
    if not card then return false end
    if card.disableFactionPassives then return false end
    return card.suit == "spades" or card.suit == "vharos" or card.suit == "iron_axiom"
end

local function isHeart(card)
    if not card then return false end
    if card.disableFactionPassives then return false end
    return card.suit == "hearts" or card.suit == "valoria" or card.suit == "sanguine_covenant"
end

local function isDiamond(card)
    if not card then return false end
    if card.disableFactionPassives then return false end
    return card.suit == "diamonds" or card.suit == "aurelia" or card.suit == "gilded_conclave"
end

local function isClub(card)
    if not card then return false end
    if card.disableFactionPassives then return false end
    return card.suit == "clubs" or card.suit == "elaris" or card.suit == "feral_swarm" or card.isWildSuit
end

--[[
Formula:
Score = (Base Chips + Bonus Chips) * (Base Mult + Bonus Mult) * (Product of XMults)
Damage to Monster = Score * (1 + Total Extra Damage Pct)
]]

function Scoring.calculate(handInfo, deities, context)
    local handType = handInfo.type
    local baseChips = handInfo.chips or (handType and handType.baseChips) or 10
    local baseMult = handInfo.mult or (handType and handType.baseMult) or 1
    local handLevel = handInfo.level or 1

    local bonusChips = 0
    local bonusMult = 0
    local xMultTotal = 1.0
    local xMultBonus = 0.0
    local totalHpCost = 0
    local totalExtraDamagePct = 0
    local bonusGoldAwarded = 0
    local totalArmorGain = 0
    local totalHealHp = 0
    local hasAceOfSpades = false
    local hasAceOfHearts = false
    local hasKingOfDiamonds = false
    local hasBountySeal = false

    local steps = {}

    -- Step 1: Base hand values
    local lvlStr = handLevel > 1 and (" (Lv. " .. handLevel .. ")") or ""
    table.insert(steps, {
        type = "base_hand",
        handName = handType and handType.name or "Hand",
        vnName = handType and handType.vnName or "Tay Bài",
        chips = baseChips,
        mult = baseMult,
        level = handLevel,
        message = (handType and handType.vnName or "Tay Bài") .. lvlStr .. ": " .. baseChips .. " Chips × " .. baseMult .. " Mult"
    })

    -- Step 1b: Tactical Discard Buffs
    if context and context.discardBuffs then
        local db = context.discardBuffs
        local addedC = db.chips or 0
        local addedM = db.mult or 0
        local addedX = db.xMult or 1.0
        local addedDmgPct = db.bonusDamagePct or 0

        bonusChips = bonusChips + addedC
        bonusMult = bonusMult + addedM
        if addedX > 1.0 then
            xMultBonus = xMultBonus + (addedX - 1.0)
        end
        totalExtraDamagePct = totalExtraDamagePct + addedDmgPct

        if addedC > 0 or addedM > 0 or addedX > 1.0 or addedDmgPct > 0 then
            local msgParts = {}
            if addedC > 0 then table.insert(msgParts, "+" .. addedC .. " Chips") end
            if addedM > 0 then table.insert(msgParts, "+" .. addedM .. " Mult") end
            if addedX > 1.0 then table.insert(msgParts, "x" .. string.format("%.2f", addedX) .. " XMult") end
            if addedDmgPct > 0 then table.insert(msgParts, "+" .. math.floor(addedDmgPct * 100) .. "% Sát Thương") end

            table.insert(steps, {
                type = "discard_buff_trigger",
                addedChips = addedC,
                addedMult = addedM,
                xMult = addedX,
                message = "⚡ CHIẾN THUẬT BỎ BÀI: " .. table.concat(msgParts, ", "),
            })
        end
    end

    -- Check pre-hand equipment buffs (adjacent mirror, same suit storm eye)
    local cardExternalBuffs = {} -- cardIndex -> { chips, mult }
    for i, card in ipairs(handInfo.scoringCards) do
        for _, eq in ipairs(card.equipments or {}) do
            if eq.onHandEvaluate then
                local buffs = eq.onHandEvaluate(card, handInfo.scoringCards, i)
                for targetIdx, buff in pairs(buffs or {}) do
                    cardExternalBuffs[targetIdx] = cardExternalBuffs[targetIdx] or { chips = 0, mult = 0 }
                    if buff.addChips then
                        cardExternalBuffs[targetIdx].chips = cardExternalBuffs[targetIdx].chips + buff.addChips
                        table.insert(steps, {
                            type = "equipment_trigger",
                            message = eq.name .. " -> Lá " .. targetIdx .. ": +" .. buff.addChips .. " Chips",
                            addedChips = buff.addChips,
                        })
                    end
                    if buff.addMult then
                        cardExternalBuffs[targetIdx].mult = cardExternalBuffs[targetIdx].mult + buff.addMult
                        table.insert(steps, {
                            type = "equipment_trigger",
                            message = eq.name .. " -> Lá " .. targetIdx .. ": +" .. buff.addMult .. " Mult",
                            addedMult = buff.addMult,
                        })
                    end
                end
            end
        end
    end

    -- Apply external buffs to totals
    for _, b in pairs(cardExternalBuffs) do
        bonusChips = bonusChips + b.chips
        bonusMult = bonusMult + b.mult
    end

    -- Count Soldiers (ranks 2..10) in played hand (scoringCards and unscoredCards) for Knight (J) synergy
    local soldierCount = 0
    for _, c in ipairs(handInfo.scoringCards or {}) do
        if c.rank >= 2 and c.rank <= 10 then
            soldierCount = soldierCount + 1
        end
    end
    for _, c in ipairs(handInfo.unscoredCards or {}) do
        if c.rank >= 2 and c.rank <= 10 then
            soldierCount = soldierCount + 1
        end
    end

    -- Step 2: Scoring cards, Roles, Faction Passives & Equipments
    local hasAureliaCard = false

    for idx, card in ipairs(handInfo.scoringCards) do
        -- Check Boss Debuffs: locked faction or locked royals (Trảm Vương)
        local isPillarLocked = false
        local debuffReason = "KHÓA BÀI"
        if context and context.monster then
            if context.monster.lockedFaction and (card.suit == context.monster.lockedFaction) then
                isPillarLocked = true
                debuffReason = "KHÓA PHÁI: Phe " .. (card.suitName or card.suit) .. " bị vô hiệu hóa (0c / 0m)!"
            elseif context.monster.lockedRoyals and (card.rank >= 11 and card.rank <= 13) then
                isPillarLocked = true
                debuffReason = "TRẢM VƯƠNG: Bài Hoàng Gia (" .. card.rankName .. ") bị vô hiệu hóa (0c / 0m)!"
            end
        end

        -- ♠️ Thiết Quân Thứ: Chỉ Số Thép - Miễn nhiễm 100% với debuff của Boss (không bị khóa, không bị úp mặt)
        if isSpade(card) then
            isPillarLocked = false
            card.faceDown = false
        end

        if card.exhausted then
            table.insert(steps, {
                type = "card_scored",
                card = card,
                cardIndex = idx,
                addedChips = 0,
                addedMult = 0,
                message = "💤 KIỆT SỨC: " .. (card.rankName or "") .. (card.suitSymbol or "") .. " nghỉ ngơi (0 điểm)"
            })
        elseif isPillarLocked then
            table.insert(steps, {
                type = "card_scored",
                card = card,
                cardIndex = idx,
                addedChips = 0,
                addedMult = 0,
                message = "🚫 " .. debuffReason
            })
        else
            -- Battle Seal: Blood Seal (Ấn Huyết) retriggers card base stats once, costs 3 HP, max 1/combat
            local flags = (context and context.combatFlags) or context or {}
            local cardTriggers = 1
            local isBloodSeal = (card.seal == "seal_blood" or card.seal == "blood" or card.seal == "red")
            if isBloodSeal and not flags.bloodSealUsedThisCombat then
                cardTriggers = 2
                flags.bloodSealUsedThisCombat = true
                if context then context.bloodSealUsedThisCombat = true end
            end

            for cTrig = 1, cardTriggers do
                if cTrig == 2 then
                    totalHpCost = totalHpCost + 3
                    table.insert(steps, {
                        type = "seal_trigger",
                        card = card,
                        cardIndex = idx,
                        seal = "blood",
                        message = "🩸 ẤN HUYẾT (Blood Seal): Tái kích hoạt " .. (card.rankName or "") .. (card.suitSymbol or "") .. " (-3 HP)!"
                    })
                end
                local cardChips = (card.baseChips or 0) + (card.bonusBaseChips or 0)
                bonusChips = bonusChips + cardChips

                local cardEvent = {
                    type = "card_scored",
                    card = card,
                    cardIndex = idx,
                    addedChips = cardChips,
                    addedMult = 0,
                    message = (card.roleIcon or "") .. " " .. card.rankName .. (card.suitSymbol or "") .. " +" .. cardChips .. " Chips"
                }

            -- Faction Passives per card
            -- 1. ♠️ THIẾT QUÂN THỨ: Chỉ Số Thép (+20 Chips per scored Spade; +40 for legacy Vharos)
            if isSpade(card) then
                local spadeChips = (card.suit == "spades" or card.suit == "iron_axiom" or (context and context.isAxiom)) and 20 or 40
                bonusChips = bonusChips + spadeChips
                cardEvent.addedChips = cardEvent.addedChips + spadeChips
                cardEvent.message = cardEvent.message .. " | ⚔️ Chỉ Số Thép (+" .. spadeChips .. " Chips)"
            end

            -- 2. ♥️ GIÁO HỘI HUYẾT ƯỚC: Cộng Hưởng (+5 Mult per scored Heart)
            local isSanguineHeart = not card.disableFactionPassives and (card.suit == "hearts" or card.suit == "sanguine_covenant" or (context and (context.isSanguine or context.selectedFaction == "hearts" or context.selectedFaction == "sanguine_covenant")))
            if isSanguineHeart then
                bonusMult = bonusMult + 5
                cardEvent.addedMult = cardEvent.addedMult + 5
                cardEvent.message = cardEvent.message .. " | 🩸 Huyết Ước (+5 Mult)"
            end

            -- 3. ♦️ TRẬT TỰ HOÀNG KIM: Kim Ngân (+1 Gold per scored Diamond)
            local isGildedDiamond = not card.disableFactionPassives and (card.suit == "diamonds" or card.suit == "gilded_conclave" or (context and (context.isGildedConclave or context.selectedFaction == "diamonds" or context.selectedFaction == "gilded_conclave")))
            if not card.disableFactionPassives and (card.suit == "aurelia" or (context and context.selectedSuit == "aurelia")) then
                hasAureliaCard = true
            end
            if isGildedDiamond and cTrig == 1 then
                hasAureliaCard = true
                bonusGoldAwarded = bonusGoldAwarded + 1
                cardEvent.message = cardEvent.message .. " | 💰 Kim Ngân (+$1)"
            end

            -- 4. ♣️ BẦY NGUYÊN SINH: Chân Rết Nguyên Thủy (Primal Drone: +50 Chips & +5 Mult)
            if card.isPrimalDrone then
                bonusChips = bonusChips + 50
                bonusMult = bonusMult + 5
                cardEvent.addedChips = cardEvent.addedChips + 50
                cardEvent.addedMult = cardEvent.addedMult + 5
                cardEvent.message = cardEvent.message .. " | 🦗 Chân Rết Nguyên Thủy (+50 Chips, +5 Mult)"
            end

            -- Card Role Passives & Faction Royals:
            -- J (Hiệp Sĩ): +15 Chips & +2 Mult per Soldier in the hand
            if card.rank == 11 then
                if soldierCount > 0 then
                    local jChips = 15 * soldierCount
                    local jMult = 2 * soldierCount
                    bonusChips = bonusChips + jChips
                    bonusMult = bonusMult + jMult
                    cardEvent.addedChips = cardEvent.addedChips + jChips
                    cardEvent.addedMult = cardEvent.addedMult + jMult
                    cardEvent.message = cardEvent.message .. " | 🗡️ Cận Vệ (+" .. jChips .. " Chips, +" .. jMult .. " Mult)"
                end
                -- J♠ (Tổng Trấn Tiền Phương): +40 Chips per Soldier behind it when J is first/lowest
                if isSpade(card) then
                    local isFirstOrLowest = (idx == 1)
                    if not isFirstOrLowest then
                        local minR = 999
                        for _, sc in ipairs(handInfo.scoringCards) do
                            if sc.rank < minR then minR = sc.rank end
                        end
                        if card.rank <= minR then isFirstOrLowest = true end
                    end
                    if isFirstOrLowest then
                        local soldiersBehind = 0
                        for sIdx = idx + 1, #handInfo.scoringCards do
                            local sc = handInfo.scoringCards[sIdx]
                            if sc.rank >= 2 and sc.rank <= 10 then
                                soldiersBehind = soldiersBehind + 1
                            end
                        end
                        if soldiersBehind > 0 then
                            local jSpadeChips = soldiersBehind * 40
                            bonusChips = bonusChips + jSpadeChips
                            cardEvent.addedChips = cardEvent.addedChips + jSpadeChips
                            cardEvent.message = cardEvent.message .. " | 🛡️ Tổng Trấn Tiền Phương (+" .. jSpadeChips .. " Chips)"
                        end
                    end
                end
                -- J♦ (Thương Nhân Vong Mạng): Steals $2 into purse
                if isDiamond(card) and cTrig == 1 then
                    bonusGoldAwarded = bonusGoldAwarded + 2
                    cardEvent.message = cardEvent.message .. " | 💸 Thương Nhân Vong Mạng (+$2)"
                end
                -- J♣ (Ấu Trùng Ký Sinh): Draws 2 cards from deck to hand
                if isClub(card) and cTrig == 1 then
                    if context and context.drawCards then
                        context.drawCards(2)
                    end
                    cardEvent.message = cardEvent.message .. " | 🐛 Ấu Trùng Ký Sinh (Bốc 2 lá)"
                end

            -- Q (Hoàng Hậu): +0.1 XMult & +15 Chips, +2 Mult per equipped socket
            elseif card.rank == 12 then
                xMultBonus = xMultBonus + 0.1
                local eqCount = #(card.equipments or {})
                if eqCount > 0 then
                    local qChips = 15 * eqCount
                    local qMult = 2 * eqCount
                    bonusChips = bonusChips + qChips
                    bonusMult = bonusMult + qMult
                    cardEvent.addedChips = cardEvent.addedChips + qChips
                    cardEvent.addedMult = cardEvent.addedMult + qMult
                    cardEvent.message = cardEvent.message .. " | 👑 Hoàng Hậu (+0.1 XMult, +" .. qChips .. " Chips, +" .. qMult .. " Mult)"
                else
                    cardEvent.message = cardEvent.message .. " | 👑 Hoàng Hậu (+0.1 XMult)"
                end

                -- Q♠ (Mệnh Lệnh Thiết Kỷ): +0.4 XMult if hand has 5 Spades
                if isSpade(card) then
                    local spadeCount = 0
                    for _, sc in ipairs(handInfo.scoringCards) do
                        if isSpade(sc) then spadeCount = spadeCount + 1 end
                    end
                    if spadeCount >= 5 then
                        xMultBonus = xMultBonus + 0.4
                        cardEvent.message = cardEvent.message .. " | ⚔️ Mệnh Lệnh Thiết Kỷ (+0.4 XMult)"
                    end
                end

                -- Q♥ (Mẫu Nghi Tế Đàn): Other Hearts lose 1 rank, +0.35 XMult
                if isHeart(card) then
                    xMultBonus = xMultBonus + 0.35
                    for _, sc in ipairs(handInfo.scoringCards) do
                        if sc ~= card and isHeart(sc) then
                            sc.rank = math.max(2, sc.rank - 1)
                            sc.rankName = Deck.RANK_NAMES[sc.rank] or tostring(sc.rank)
                            sc.baseChips = Deck.getChipValue(sc.rank)
                        end
                    end
                    cardEvent.message = cardEvent.message .. " | 🩸 Mẫu Nghi Tế Đàn (-1 Rank Cơ, +0.35 XMult)"
                end

                -- Q♦ (Nữ Hoàng Tài Phiệt): +Gold * 0.02 capped at +1.0
                if isDiamond(card) then
                    local goldHold = (context and context.gold) or (context and context.gameState and context.gameState.gold) or 0
                    local qWealthBonus = math.min(1.0, goldHold * 0.02)
                    if qWealthBonus > 0 then
                        xMultBonus = xMultBonus + qWealthBonus
                        cardEvent.message = cardEvent.message .. " | 💎 Nữ Hoàng Tài Phiệt (+" .. string.format("%.2f", qWealthBonus) .. " XMult)"
                    end
                end

            -- K (Quốc Vương): Pillar of damage: +25 Chips & +5 Mult
            elseif card.rank == 13 then
                local kChips = 25
                local kMult = 5
                bonusChips = bonusChips + kChips
                bonusMult = bonusMult + kMult
                cardEvent.addedChips = cardEvent.addedChips + kChips
                cardEvent.addedMult = cardEvent.addedMult + kMult
                cardEvent.message = cardEvent.message .. " | 🏰 Quốc Vương (+" .. kChips .. " Chips, +" .. kMult .. " Mult)"

                -- K♠ (Đại Tướng Quân Pháo Đài): +15 Chips per Spade remaining in hand
                if isSpade(card) then
                    local unplayedSpades = 0
                    local unplayedList = (context and context.unplayedCards) or (context and context.hand) or (context and context.gameState and context.gameState.hand) or {}
                    for _, hc in ipairs(unplayedList) do
                        if isSpade(hc) then unplayedSpades = unplayedSpades + 1 end
                    end
                    if unplayedSpades > 0 then
                        local kSpadeBonus = unplayedSpades * 15
                        bonusChips = bonusChips + kSpadeBonus
                        cardEvent.addedChips = cardEvent.addedChips + kSpadeBonus
                        cardEvent.message = cardEvent.message .. " | 🛡️ Đại Tướng Quân (+" .. kSpadeBonus .. " Chips từ " .. unplayedSpades .. " Bích trên tay)"
                    end
                end

                -- K♥ (Huyết Vương Bất Tử): If <= 1 Hand left, +100 Chips & +25 Mult
                if isHeart(card) then
                    local handsLeft = (context and context.handsRemaining) or 0
                    if handsLeft <= 1 then
                        bonusChips = bonusChips + 100
                        bonusMult = bonusMult + 25
                        cardEvent.addedChips = cardEvent.addedChips + 100
                        cardEvent.addedMult = cardEvent.addedMult + 25
                        cardEvent.message = cardEvent.message .. " | 💀 Huyết Vương Bất Tử (+100 Chips, +25 Mult)"
                    end
                end

                -- K♦ (Đế Vương Mua Chuộc): Flagged for bribe calculation
                if isDiamond(card) then
                    hasKingOfDiamonds = true
                end

                -- K♣ (Chúa Tể Bầy Đàn): Each scored Club adds +0.3 XMult
                if isClub(card) then
                    local clubScoredCount = 0
                    for _, sc in ipairs(handInfo.scoringCards) do
                        if isClub(sc) then clubScoredCount = clubScoredCount + 1 end
                    end
                    if clubScoredCount > 0 then
                        local kClubBonus = clubScoredCount * 0.3
                        xMultBonus = xMultBonus + kClubBonus
                        cardEvent.message = cardEvent.message .. " | 🐜 Chúa Tể Bầy Đàn (+" .. string.format("%.2f", kClubBonus) .. " XMult)"
                    end
                end

            -- A (Thần Khí): Ultimate resonance: +15 Chips
            elseif card.rank == 1 or card.rank == 14 then
                local aChips = 15
                bonusChips = bonusChips + aChips
                cardEvent.addedChips = cardEvent.addedChips + aChips
                cardEvent.message = cardEvent.message .. " | ⚡ Thần Khí (+" .. aChips .. " Chips)"

                -- A♠ (Lưỡi Hái Trật Tự): Flags overkill Sát Khí storage
                if isSpade(card) then
                    hasAceOfSpades = true
                    cardEvent.message = cardEvent.message .. " | ⚔️ Lưỡi Hái Trật Tự (Tích Sát Khí khi Overkill)"
                end

                -- A♥ (Chén Thánh Khát Máu): Flags killing blow gold conversion (5% monster max HP)
                if isHeart(card) then
                    hasAceOfHearts = true
                    cardEvent.message = cardEvent.message .. " | 🩸 Chén Thánh Khát Máu (Hút máu thành Vàng khi dứt điểm)"
                end
            end

            -- Check Card Equipments ONLY on primary trigger (cTrig == 1):
            -- "Ấn không được kích hoạt lại hiệu ứng trang bị, vàng, hồi máu hoặc tạo giáp"
            if cTrig == 1 then
                for _, eq in ipairs(card.equipments or {}) do
                    if eq.onCardScore then
                        local res = eq.onCardScore(card, handInfo.scoringCards, idx, context)
                        if res then
                            local eqMult = isDiamond(card) and 1.5 or 1.0
                            if res.addChips then
                                local c = math.floor(res.addChips * eqMult)
                                bonusChips = bonusChips + c
                                cardEvent.addedChips = cardEvent.addedChips + c
                            end
                            if res.addMult then
                                local m = math.floor(res.addMult * eqMult)
                                bonusMult = bonusMult + m
                                cardEvent.addedMult = cardEvent.addedMult + m
                            end
                            if res.xMultBonus or res.xMult then
                                local xm = res.xMultBonus or (res.xMult - 1.0)
                                if isDiamond(card) then
                                    xm = xm * 1.5
                                end
                                xMultBonus = xMultBonus + xm
                            end
                            if res.extraDamagePct then
                                totalExtraDamagePct = totalExtraDamagePct + (res.extraDamagePct * eqMult)
                            end
                            if res.hpCost then
                                totalHpCost = totalHpCost + res.hpCost
                                cardEvent.message = cardEvent.message .. " | 🩸 -" .. res.hpCost .. " HP"
                            end
                            if res.addGold then
                                local g = math.floor(res.addGold * eqMult)
                                bonusGoldAwarded = bonusGoldAwarded + g
                            end
                            if res.addArmor then
                                local arm = math.floor(res.addArmor * eqMult)
                                totalArmorGain = math.min(30, totalArmorGain + arm)
                                cardEvent.message = cardEvent.message .. " | 🛡️ +" .. arm .. " Giáp"
                                table.insert(steps, {
                                    type = "armor_gain",
                                    card = card,
                                    equipment = eq,
                                    amount = arm,
                                    message = (card.rankName or "") .. (card.suitSymbol or "") .. " kích hoạt " .. eq.name .. ": +" .. arm .. " Giáp!"
                                })
                            end
                            if res.healHp then
                                local heal = math.floor(res.healHp * eqMult)
                                totalHealHp = totalHealHp + heal
                                cardEvent.message = cardEvent.message .. " | 💚 +" .. heal .. " Máu"
                                table.insert(steps, {
                                    type = "heal_hp",
                                    card = card,
                                    equipment = eq,
                                    amount = heal,
                                    message = (card.rankName or "") .. (card.suitSymbol or "") .. " kích hoạt " .. eq.name .. ": +" .. heal .. " HP!"
                                })
                            end
                        end
                    end
                end

                -- Card Enhancements (Thuật Rèn Bài)
                if card.enhancement then
                    local enh = card.enhancement
                    if enh == "enh_armor" or enh == "armor" then
                        bonusChips = bonusChips - 10
                        totalArmorGain = math.min(30, totalArmorGain + 8)
                        cardEvent.addedChips = cardEvent.addedChips - 10
                        cardEvent.message = cardEvent.message .. " | 🛡️ Giáp Hóa (-10c, +8 Giáp)"
                    elseif enh == "enh_blood" or enh == "blood" then
                        bonusMult = bonusMult + 15
                        totalHpCost = totalHpCost + 4
                        cardEvent.addedMult = cardEvent.addedMult + 15
                        cardEvent.message = cardEvent.message .. " | 🩸 Huyết Hóa (+15 Mult, -4 HP)"
                    elseif enh == "enh_overcharged" or enh == "overcharged" then
                        local stacks = card.overchargeStacks or 0
                        if stacks > 0 then
                            bonusChips = bonusChips + stacks
                            cardEvent.addedChips = cardEvent.addedChips + stacks
                            cardEvent.message = cardEvent.message .. " | ⚡ Tích Điện (+" .. stacks .. " Chips)"
                            card.overchargeStacks = 0
                        end
                    elseif enh == "enh_cursed" or enh == "cursed" then
                        bonusMult = bonusMult + 20
                        cardEvent.addedMult = cardEvent.addedMult + 20
                        if context and context.monster then
                            context.monster.enrageStacks = (context.monster.enrageStacks or 0) + 1
                        end
                        cardEvent.message = cardEvent.message .. " | 💀 Nguyền Rủa (+20 Mult, +1 Cuồng Nộ Quái)"
                    elseif enh == "enh_brittle" or enh == "brittle" then
                        xMultBonus = xMultBonus + 0.4
                        cardEvent.message = cardEvent.message .. " | 💥 Nứt Vỡ (+0.4 XMult)"
                        if Rng.random(100) <= 25 then
                            card.destroyed = true
                            cardEvent.message = cardEvent.message .. " [VỠ VỤN VĨNH VIỄN]"
                        end
                    elseif enh == "enh_harmonic" or enh == "harmonic" then
                        local handCards = (context and context.hand) or {}
                        local sameCount = 0
                        for _, hc in ipairs(handCards) do
                            if hc ~= card and hc.suit == card.suit then
                                sameCount = sameCount + 1
                            end
                        end
                        if sameCount > 0 then
                            local hMult = sameCount * 3
                            bonusMult = bonusMult + hMult
                            cardEvent.addedMult = cardEvent.addedMult + hMult
                            cardEvent.message = cardEvent.message .. " | 🎶 Cộng Hưởng (+" .. hMult .. " Mult)"
                        end
                    elseif enh == "enh_boss_hunter" or enh == "boss_hunter" then
                        if context and context.monster and context.monster.isBoss then
                            bonusChips = bonusChips + 25
                            bonusMult = bonusMult + 8
                            cardEvent.addedChips = cardEvent.addedChips + 25
                            cardEvent.addedMult = cardEvent.addedMult + 8
                            cardEvent.message = cardEvent.message .. " | 🏹 Săn Boss (+25 Chips, +8 Mult)"
                        end
                    elseif enh == "enh_vanguard" or enh == "vanguard" then
                        if idx == 1 then
                            bonusChips = bonusChips + 15
                            bonusMult = bonusMult + 4
                            cardEvent.addedChips = cardEvent.addedChips + 15
                            cardEvent.addedMult = cardEvent.addedMult + 4
                            cardEvent.message = cardEvent.message .. " | ⚔️ Tiên Phong (+15 Chips, +4 Mult)"
                        end
                    elseif enh == "enh_rearguard" or enh == "rearguard" then
                        if idx == #handInfo.scoringCards then
                            totalArmorGain = math.min(30, totalArmorGain + 8)
                            bonusMult = bonusMult + 3
                            cardEvent.addedMult = cardEvent.addedMult + 3
                            cardEvent.message = cardEvent.message .. " | 🛡️ Hậu Vệ (+8 Giáp, +3 Mult)"
                        end
                    end
                end

                -- 6 Battle Seals (Ấn Chiến)
                if card.seal == "seal_blood" or card.seal == "blood" or card.seal == "red" then
                    -- Ấn Huyết đã kích hoạt tái kích hoạt (retrigger) ở trên, không cộng dồn sát thương thừa
                elseif card.seal == "seal_prophecy" or card.seal == "prophecy" or card.seal == "blue" then
                    if context and context.monster then
                        context.monster.showNextIntent = true
                        context.monster.revealedIntents = 2
                        cardEvent.message = cardEvent.message .. " | 🔮 Ấn Tiên Tri (Thấu Thị Intent)"
                    end
                elseif card.seal == "seal_ashen" or card.seal == "ashen" or card.seal == "purple" then
                    card.destroyed = true
                    if context and context.monster then
                        context.monster.hp = math.max(0, context.monster.hp - 40)
                        cardEvent.message = cardEvent.message .. " | 🔥 Ấn Tro Tàn (40 ST Chuẩn & Thiêu Hủy)"
                    end
                elseif card.seal == "seal_bounty" or card.seal == "bounty" or card.seal == "gold" then
                    hasBountySeal = true
                    cardEvent.message = cardEvent.message .. " | 💰 Ấn Truy Nã (+$2 khi kết liễu)"
                elseif card.seal == "seal_anchor" or card.seal == "anchor" then
                    card.isAnchor = true
                    cardEvent.message = cardEvent.message .. " | ⚓ Ấn Neo"
                elseif card.seal == "seal_purifying" or card.seal == "purifying" then
                    if context and context.removeOneDebuff then
                        context.removeOneDebuff()
                    end
                    cardEvent.message = cardEvent.message .. " | ✨ Ấn Thanh Tẩy (Giải Trừ 1 Debuff)"
                end
            end

            -- Check Deities triggered by card (evaluated sequentially across all slots)
            local deityTriggers = {}
            local maxDeitySlots = 5
            if deities then
                for k in pairs(deities) do
                    if type(k) == "number" and k > maxDeitySlots then
                        maxDeitySlots = k
                    end
                end
            end
            for di = 1, maxDeitySlots do
                local deity = deities and deities[di]
                if deity then
                    local effectiveDeity = Deities.resolveDeity and Deities.resolveDeity(deities, di) or deity
                    if effectiveDeity and effectiveDeity.onCardScored then
                        local res = effectiveDeity.onCardScored(card, context, effectiveDeity, idx, handInfo.scoringCards)
                        if res then
                            if res.addChips then
                                bonusChips = bonusChips + res.addChips
                                cardEvent.addedChips = cardEvent.addedChips + res.addChips
                            end
                            if res.addMult then
                                bonusMult = bonusMult + res.addMult
                                cardEvent.addedMult = cardEvent.addedMult + res.addMult
                            end
                            if res.addGold then
                                cardEvent.bonusGold = (cardEvent.bonusGold or 0) + res.addGold
                            end
                            local dName = deity.isCopyDeity and (deity.name .. " (" .. effectiveDeity.name .. ")") or deity.name
                            table.insert(deityTriggers, {
                                slotIndex = di,
                                deityName = dName,
                                message = res.message or effectiveDeity.name
                            })
                        end
                    end
                end
            end

            -- (Gold / Bounty Seal handled on primary trigger)

            cardEvent.deityTriggers = deityTriggers
            table.insert(steps, cardEvent)
        end
    end
end

    -- Check Card Equipments on unscored played cards (Survival equipment activates on play)
    for _, ucard in ipairs(handInfo.unscoredCards or {}) do
        for _, eq in ipairs(ucard.equipments or {}) do
            if eq.onCardScore then
                local res = eq.onCardScore(ucard, handInfo.scoringCards, 0)
                if res then
                    local eqMult = isDiamond(ucard) and 1.5 or 1.0
                    if res.addArmor then
                        local arm = math.floor(res.addArmor * eqMult)
                        totalArmorGain = totalArmorGain + arm
                        table.insert(steps, {
                            type = "armor_gain",
                            card = ucard,
                            equipment = eq,
                            amount = arm,
                            message = (ucard.rankName or "") .. (ucard.suitSymbol or "") .. " (Phụ) kích hoạt " .. eq.name .. ": +" .. arm .. " Giáp!"
                        })
                    end
                    if res.healHp then
                        local heal = math.floor(res.healHp * eqMult)
                        totalHealHp = totalHealHp + heal
                        table.insert(steps, {
                            type = "heal_hp",
                            card = ucard,
                            equipment = eq,
                            amount = heal,
                            message = (ucard.rankName or "") .. (ucard.suitSymbol or "") .. " (Phụ) kích hoạt " .. eq.name .. ": +" .. heal .. " HP!"
                        })
                    end
                end
            end
        end
    end

    -- ♠️ Thiết Quân Thứ: Quân Lực Thẳng Hàng (Phalanx Progression)
    if #handInfo.scoringCards >= 2 then
        local sortedAsc = {}
        for _, c in ipairs(handInfo.scoringCards) do table.insert(sortedAsc, c) end
        table.sort(sortedAsc, function(a, b) return a.rank < b.rank end)

        local isStrictlyAscending = true
        for i = 2, #sortedAsc do
            if sortedAsc[i].rank <= sortedAsc[i - 1].rank then
                isStrictlyAscending = false
                break
            end
        end
        if isStrictlyAscending then
            local phalanxChips = 0
            local details = {}
            for i = 2, #sortedAsc do
                local diff = sortedAsc[i].rank - sortedAsc[i - 1].rank
                local cardBonus = diff * 10
                phalanxChips = phalanxChips + cardBonus
                table.insert(details, "+" .. cardBonus .. "c (" .. sortedAsc[i - 1].rankName .. "->" .. sortedAsc[i].rankName .. ")")
            end
            bonusChips = bonusChips + phalanxChips
            table.insert(steps, {
                type = "phalanx_progression",
                addedChips = phalanxChips,
                message = "🛡️ QUÂN LỰC THẲNG HÀNG (Phalanx): +" .. phalanxChips .. " Chips! [" .. table.concat(details, ", ") .. "]"
            })
        end
    end

    -- ♥️ Giáo Hội Huyết Ước: Dấu Ấn Tử Đạo (Martyr Stacks)
    local martyrStacks = (context and context.martyrStacks) or (context and context.gameState and context.gameState.martyrStacks) or 0
    if martyrStacks > 0 then
        local mMult = martyrStacks * 8
        local mBonus = martyrStacks * 0.15
        local mXMult = 1.0 + mBonus
        bonusMult = bonusMult + mMult
        xMultBonus = xMultBonus + mBonus
        table.insert(steps, {
            type = "martyr_stacks",
            stacks = martyrStacks,
            addedMult = mMult,
            xMult = mXMult,
            message = "🩸 DẤU ẤN TỬ ĐẠO: Tiêu thụ " .. martyrStacks .. " điểm (+" .. mMult .. " Mult, x" .. string.format("%.2f", mXMult) .. " XMult)!"
        })
    end

    -- Starting Sát Khí Chips from previous Overkill (A♠)
    local slaughterChips = (context and context.storedSlaughterChips) or (context and context.gameState and context.gameState.storedSlaughterChips) or 0
    if slaughterChips > 0 then
        bonusChips = bonusChips + slaughterChips
        table.insert(steps, {
            type = "slaughter_chips",
            addedChips = slaughterChips,
            message = "⚔️ SÁT KHÍ TÍCH TỤ (A♠): +" .. slaughterChips .. " Starting Chips!"
        })
    end

    -- ♦️ Trật Tự Hoàng Kim: K♦ Đế Vương Mua Chuộc (Bribe)
    local bribeDollarsSpent = 0
    local availableGold = (context and context.gold) or (context and context.gameState and context.gameState.gold) or 0
    if hasKingOfDiamonds and context and context.monster and availableGold > 0 then
        local currentChips = baseChips + bonusChips
        local currentMult = baseMult + bonusMult
        local currentProjScore = math.floor(currentChips * currentMult * xMultTotal * (1 + totalExtraDamagePct))
        if currentProjScore < context.monster.hp then
            local maxBribe = math.min(5, availableGold)
            local dollarsNeeded = 0
            for d = 1, maxBribe do
                dollarsNeeded = d
                local testChips = currentChips + (d * 30)
                local testMult = currentMult + (d * 3)
                local testScore = math.floor(testChips * testMult * xMultTotal * (1 + totalExtraDamagePct))
                if testScore >= context.monster.hp then
                    break
                end
            end
            if dollarsNeeded > 0 then
                bribeDollarsSpent = dollarsNeeded
                local bribeChips = dollarsNeeded * 30
                local bribeMult = dollarsNeeded * 3
                bonusChips = bonusChips + bribeChips
                bonusMult = bonusMult + bribeMult
                if context.gameState then
                    context.gameState.gold = math.max(0, (context.gameState.gold or 0) - dollarsNeeded)
                elseif context.gold then
                    context.gold = context.gold - dollarsNeeded
                end
                table.insert(steps, {
                    type = "king_diamonds_bribe",
                    dollarsSpent = dollarsNeeded,
                    addedChips = bribeChips,
                    addedMult = bribeMult,
                    message = "💰 ĐẾ VƯƠNG MUA CHUỘC (K♦): Tiêu $" .. dollarsNeeded .. " -> +" .. bribeChips .. " Chips, +" .. bribeMult .. " Mult cứu nguy!"
                })
            end
        end
    end

    -- Aurelia Faction Passive: Hào Quang Thánh Thiện (+0.15 XMult if hand contains Aurelia card)
    if hasAureliaCard then
        xMultBonus = xMultBonus + 0.15
        table.insert(steps, {
            type = "faction_bonus",
            message = "☀️ Hào Quang Thánh Thiện (Aurelia): +0.15 XMult!",
            xMult = 1.15,
        })
    end

    -- Step 3: Deities hand-level triggers (+Chips, +Mult, XMult) - Sequentially evaluated Left-to-Right (Slot 1 -> maxSlots)
    local currentChips = baseChips + bonusChips
    local currentMult = baseMult + bonusMult
    local cardXMultTotal = math.min(5.0, 1.0 + xMultBonus)

    local maxDeitySlots = 5
    if deities then
        for k in pairs(deities) do
            if type(k) == "number" and k > maxDeitySlots then
                maxDeitySlots = k
            end
        end
    end

    for di = 1, maxDeitySlots do
        local deity = deities and deities[di]
        if deity then
            local effectiveDeity = Deities.resolveDeity and Deities.resolveDeity(deities, di) or deity
            if effectiveDeity and effectiveDeity.onHandScored then
                local res = effectiveDeity.onHandScored(handInfo, context, effectiveDeity)
                if res then
                    local addedChips = res.addChips or 0
                    local addedMult = res.addMult or 0
                    local cardXMult = res.xMult or 1.0

                    -- Sequential left-to-right formula: add Chips, add Mult, then multiply by XMult!
                    currentChips = currentChips + addedChips
                    currentMult = currentMult + addedMult
                    if cardXMult > 1.0 then
                        currentMult = currentMult * cardXMult
                        xMultBonus = xMultBonus + (cardXMult - 1.0)
                    end

                    bonusChips = bonusChips + addedChips

                    local displayName = deity.isCopyDeity and (deity.name .. " (" .. effectiveDeity.name .. ")") or deity.name
                    table.insert(steps, {
                        type = "deity_hand",
                        slotIndex = di,
                        deity = deity,
                        effectiveDeity = effectiveDeity,
                        addedChips = addedChips,
                        addedMult = addedMult,
                        xMult = cardXMult,
                        resultingChips = currentChips,
                        resultingMult = currentMult,
                        message = displayName .. ": " .. (res.message or effectiveDeity.desc or deity.desc or effectiveDeity.name or deity.name or "")
                    })
                end
            end

            -- Joker Edition Trigger (Foil +50c, Holo +10m, Polychrome x1.5m)
            if deity.edition then
                if deity.edition == "foil" then
                    currentChips = currentChips + 50
                    bonusChips = bonusChips + 50
                    table.insert(steps, {
                        type = "deity_edition",
                        slotIndex = di,
                        deity = deity,
                        edition = "foil",
                        addedChips = 50,
                        resultingChips = currentChips,
                        resultingMult = currentMult,
                        message = "✨ FOIL: " .. deity.name .. " (+50 Chips)!"
                    })
                elseif deity.edition == "holo" then
                    currentMult = currentMult + 10
                    bonusMult = bonusMult + 10
                    table.insert(steps, {
                        type = "deity_edition",
                        slotIndex = di,
                        deity = deity,
                        edition = "holo",
                        addedMult = 10,
                        resultingChips = currentChips,
                        resultingMult = currentMult,
                        message = "🌈 HOLOGRAPHIC: " .. deity.name .. " (+10 Mult)!"
                    })
                elseif deity.edition == "polychrome" then
                    currentMult = math.floor(currentMult * 1.5)
                    xMultBonus = xMultBonus + 0.5
                    table.insert(steps, {
                        type = "deity_edition",
                        slotIndex = di,
                        deity = deity,
                        edition = "polychrome",
                        xMult = 1.5,
                        resultingChips = currentChips,
                        resultingMult = currentMult,
                        message = "🌟 POLYCHROME: " .. deity.name .. " (x1.5 Mult)!"
                    })
                end
            end
        end
    end

    -- Total calculation: card/equipment XMult is additive & capped at x5.0
    local totalChips = currentChips
    local totalMult = currentMult
    local rawScore = math.floor(totalChips * totalMult * cardXMultTotal)
    local finalScore = math.floor(rawScore * (1 + totalExtraDamagePct))
    local finalCombinedXMult = math.min(5.0, 1.0 + xMultBonus)

    table.insert(steps, {
        type = "final_score",
        totalChips = totalChips,
        totalMult = totalMult,
        xMult = finalCombinedXMult,
        rawScore = rawScore,
        extraDamagePct = totalExtraDamagePct,
        finalScore = finalScore,
        bonusGold = bonusGoldAwarded,
        message = totalChips .. " Chips × " .. totalMult .. " Mult" .. (finalCombinedXMult > 1.0 and (" × " .. string.format("%.2f", finalCombinedXMult) .. " XMult") or "") .. " = " .. finalScore .. " Sát thương!"
    })

    return {
        baseChips = baseChips,
        baseMult = baseMult,
        bonusChips = bonusChips,
        bonusMult = bonusMult,
        totalChips = totalChips,
        totalMult = totalMult,
        xMultTotal = finalCombinedXMult,
        rawScore = rawScore,
        finalScore = finalScore,
        totalExtraDamagePct = totalExtraDamagePct,
        bonusGoldAwarded = bonusGoldAwarded,
        addArmor = math.min(30, totalArmorGain),
        healHp = totalHealHp,
        hpCost = totalHpCost,
        hasAceOfSpades = hasAceOfSpades,
        hasAceOfHearts = hasAceOfHearts,
        hasBountySeal = hasBountySeal,
        bribeDollarsSpent = bribeDollarsSpent,
        martyrStacksConsumed = martyrStacks,
        steps = steps
    }
end

return Scoring

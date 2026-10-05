local Inventory = require("src.inventory")
local Monster = require("src.monster")

local RunManager = {}

-- 20 campaign stages, 3 mandatory encounters per stage.
RunManager.MAX_ANTE = 20

-- Retired pools are empty so older save data cannot grant skip rewards.
RunManager.SKIP_PACTS = {}
RunManager.TAGS = {}

RunManager.BOSS_DEBUFFS = {
    -- Faction Locks
    lock_aurelia = {
        id = "lock_aurelia",
        debuffId = "lock_aurelia",
        name = "KHÓA QUANG HUY",
        title = "TRÙM: KHÓA ÁNH SÁNG",
        desc = "Quang Huy Tắt Lịm: Toàn bộ bài phe Aurelia (Ánh Sáng) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.95, 0.82, 0.22, 1 },
        lockedFaction = "aurelia",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "aurelia"
        end,
    },
    lock_elaris = {
        id = "lock_elaris",
        debuffId = "lock_elaris",
        name = "KHÓA SINH LINH",
        title = "TRÙM: KHÓA THIÊN NHIÊN",
        desc = "Rừng Già Khô Cạn: Toàn bộ bài phe Elaris (Thiên Nhiên) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.25, 0.82, 0.45, 1 },
        lockedFaction = "elaris",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "elaris"
        end,
    },
    lock_vharos = {
        id = "lock_vharos",
        debuffId = "lock_vharos",
        name = "KHÓA HẮC ÁM",
        title = "TRÙM: KHÓA BÓNG ĐÊM",
        desc = "Lửa Quỷ Đóng Băng: Toàn bộ bài phe Vharos (Hắc Ám) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.92, 0.25, 0.35, 1 },
        lockedFaction = "vharos",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "vharos"
        end,
    },
    lock_valoria = {
        id = "lock_valoria",
        debuffId = "lock_valoria",
        name = "KHÓA THIẾT HUYẾT",
        title = "TRÙM: KHÓA NHÂN LOẠI",
        desc = "Khí Giới Rỉ Sét: Toàn bộ bài phe Valoria (Nhân Loại) bị vô hiệu hóa (0 Chips / 0 Mult)!",
        color = { 0.35, 0.65, 0.95, 1 },
        lockedFaction = "valoria",
        applyModifier = function(gameState)
            gameState.monster.lockedFaction = "valoria"
        end,
    },

    -- Hierarchy & Rule Disruptions
    lock_royals = {
        id = "lock_royals",
        debuffId = "lock_royals",
        name = "TRẢM VƯƠNG QUAN",
        title = "TRÙM: TRẢM VƯƠNG",
        desc = "Trảm Vương: Khóa toàn bộ bài Hoàng Gia (J, Q, K - 0 Chips / 0 Mult)!",
        color = { 0.85, 0.45, 0.95, 1 },
        lockedRoyals = true,
        applyModifier = function(gameState)
            gameState.monster.lockedRoyals = true
        end,
    },
    the_needle = {
        id = "the_needle",
        debuffId = "the_needle",
        name = "CHÚA TỂ KIM NHỌN",
        title = "TRÙM: THE NEEDLE",
        desc = "Kim Nhọn Tuyệt Mạng: Chỉ có duy nhất 1 Lượt Đánh (1 Hand) cả trận!",
        color = { 0.95, 0.25, 0.25, 1 },
        applyModifier = function(gameState)
            gameState.handsRemaining = 1
        end,
    },
    the_water = {
        id = "the_water",
        debuffId = "the_water",
        name = "THỦY THẦN NƯỚC LŨ",
        title = "TRÙM: THE WATER",
        desc = "Nước Lũ Tối Tăm: Bắt đầu trận đấu với 0 Lượt Đổi bài (0 Discards)!",
        color = { 0.2, 0.6, 0.95, 1 },
        applyModifier = function(gameState)
            gameState.discardsRemaining = 0
        end,
    },
    the_fish = {
        id = "the_fish",
        debuffId = "the_fish",
        name = "VUA BIỂN ĐÊM ĐEN",
        title = "TRÙM: THE FISH",
        desc = "Màn Đêm Vô Tận: Mọi lá bài rút lên đều bị Úp Mặt (Face-down)!",
        color = { 0.3, 0.35, 0.55, 1 },
        applyModifier = function(gameState)
            for _, c in ipairs(gameState.hand or {}) do
                c.faceDown = true
            end
        end,
    },
    the_arm = {
        id = "the_arm",
        debuffId = "the_arm",
        name = "CỰ MA BÀN TAY",
        title = "TRÙM: THE ARM",
        desc = "Bàn Tay Suy Đồi: Mỗi lượt đánh, các lá bài tạo Aura bị suy đồi giảm vĩnh viễn 1 Rank!",
        color = { 0.5, 0.8, 0.3, 1 },
    },
    the_hook = {
        id = "the_hook",
        debuffId = "the_hook",
        name = "MA THẦN LƯỠI CÂU",
        title = "TRÙM: THE HOOK",
        desc = "Lưỡi Câu Đoạt Mệnh: Mỗi khi chơi bài, Boss tự động vứt bỏ ngẫu nhiên 2 lá trên tay!",
        color = { 0.9, 0.5, 0.2, 1 },
    },
    max_3_cards = {
        id = "max_3_cards",
        debuffId = "max_3_cards",
        name = "HẠN CHẾ BINH LỰC",
        title = "TRÙM: THIẾU QUÂN",
        desc = "Hạn Chế Binh Lực: Mỗi tay bài xuất trận chỉ được chọn tối đa 3 lá bài!",
        color = { 0.95, 0.55, 0.2, 1 },
        maxSelectedCards = 3,
        applyModifier = function(gameState)
            gameState.maxSelectableCards = 3
        end,
    },
}

local Expedition = require("src.expedition")
local BossAbilities = require("src.boss_abilities")
for _, d in pairs(RunManager.BOSS_DEBUFFS) do BossAbilities.attach(d) end
for id, d in pairs(BossAbilities.newDefinitions) do RunManager.BOSS_DEBUFFS[id]=BossAbilities.attach(d) end
RunManager.BOSS_KEYS = {
    "lock_royals", "black_tax_collector", "the_water", "memory_eater", "the_arm", "gatekeeper", "the_hook", "max_3_cards", "the_needle", "the_fish"
}

-- HP formula:
-- Small Blind: round(21 * (1.71 ^ (Ante - 1)))
-- Big Blind: round(1.5 * Small HP)
-- Boss Blind: round(2.0 * Small HP)
function RunManager.calculateBlindHp(ante, blindType)
    local a = math.max(1, ante or 1)
    local smallHp = 21
    for _ = 2, a do
        smallHp = math.floor(smallHp * 1.71 + 0.5)
    end

    if blindType == "small" then
        return smallHp
    elseif blindType == "big" then
        return math.floor(smallHp * 1.5 + 0.5)
    elseif blindType == "boss" then
        return math.floor(smallHp * 2.0 + 0.5)
    end
    return smallHp
end

-- Generate 3 blinds for a given Ante
function RunManager.generateAnteBlinds(ante, starterFaction)
    local a = math.max(1, ante or 1)

    local smallHp = RunManager.calculateBlindHp(a, "small")
    local bigHp = RunManager.calculateBlindHp(a, "big")
    local bossHp = RunManager.calculateBlindHp(a, "boss")

    -- Choose a Boss Debuff
    local bKey = RunManager.BOSS_KEYS[((a - 1) % #RunManager.BOSS_KEYS) + 1]
    local bossDebuff = RunManager.BOSS_DEBUFFS[bKey] or RunManager.BOSS_DEBUFFS.the_needle

    bossDebuff = Expedition.bossData(a, Monster.DISRUPTIVE_BOSSES, bossDebuff)

    local blinds = {
        {
            index = 1,
            type = "small",
            name = "Tiểu Yêu",
            title = "SMALL BLIND",
            ante = a,
            hp = smallHp,
            baseReward = 3,
            canSkip = false,
            status = "upcoming", -- "upcoming", "current", "completed", "skipped"
            color = { 0.25, 0.65, 0.95, 1 },
            icon = "⚔️",
        },
        {
            index = 2,
            type = "big",
            name = "Đại Quái",
            title = "BIG BLIND",
            ante = a,
            hp = bigHp,
            baseReward = 4,
            canSkip = false,
            status = "upcoming",
            color = { 0.95, 0.60, 0.20, 1 },
            icon = "👹",
        },
        {
            index = 3,
            type = "boss",
            name = bossDebuff.name,
            title = "BOSS BLIND",
            ante = a,
            hp = bossHp,
            baseReward = 5,
            canSkip = false,
            status = "upcoming",
            debuff = bossDebuff,
            color = { 0.95, 0.25, 0.35, 1 },
            icon = "👑",
        },
    }

    for i, blind in ipairs(blinds) do
        local identity = Expedition.decorate({isBoss=i==3, isElite=i==2, bossData=blind.debuff}, a, (a-1)*3+i)
        if identity.human then
            blind.name, blind.title, blind.color = identity.name, identity.title, identity.color
            blind.cardSuit, blind.cardRank, blind.kingdom = identity.cardSuit, identity.cardRank, identity.kingdom
        end
        blind.stage, blind.regionId = a, Expedition.region(a).id
    end
    blinds[1].status = "current"
    return blinds
end

-- Initialize a fresh Run
function RunManager.newRun(starterFaction)
    local run = {
        faction = starterFaction or "aurelia",
        selectedFaction = starterFaction or "aurelia",
        ante = 1,
        maxAnte = RunManager.MAX_ANTE,
        currentBlindIndex = 1, -- 1: Small, 2: Big, 3: Boss
        blinds = RunManager.generateAnteBlinds(1, starterFaction),
        victory = false,
        shopsVisitedInAnte = 0,
        stats = {
            blindsWon = 0,
            blindsSkipped = 0,
            totalGoldEarned = 0,
        },
    }
    return run
end

-- Get current active blind
function RunManager.getCurrentBlind(run)
    if not run or not run.blinds then return nil end
    return run.blinds[run.currentBlindIndex]
end

-- Create Monster instance for the current Blind
function RunManager.createBlindMonster(blind, gameState, preview)
    local isBoss = (blind.type == "boss")
    local isElite = (blind.type == "big")
    local encounterCount = (blind.ante - 1) * 3 + blind.index
    local atk = Monster.getAttackByEncounter(encounterCount, isBoss, isElite)
    local m = {
        round = blind.ante,
        encounterCount = encounterCount,
        isBoss = isBoss,
        isElite = isElite,
        hp = blind.hp,
        maxHp = blind.hp,
        damageLagHp = blind.hp,
        attack = atk,
        attackSpeed = preview and 1 or Monster.rollAttackSpeed(encounterCount),
        intent = {
            type = "attack",
            value = atk,
            label = "Tấn Công " .. atk .. " DMG",
        },
        name = blind.name,
        title = blind.title .. " (ANTE " .. blind.ante .. ")",
        desc = isBoss and (blind.debuff and blind.debuff.desc or "Trùm Ma Thần đầy quyền năng!") or ("Ải " .. blind.name .. ": Mục tiêu " .. blind.hp .. " HP"),
        color = blind.color or { 0.85, 0.25, 0.25, 1 },
        bossData = blind.debuff,
    }

    if isBoss and blind.debuff then
        m.bossData = blind.debuff
    end

    return Expedition.decorate(m, blind.ante, encounterCount)
end

-- Compatibility guard for old callers: skipping never changes the run.
function RunManager.skipCurrentBlind()
    return false, "Mọi trận đấu phải được hoàn thành."
end

-- Complete current blind (on combat victory)
function RunManager.createEvolutionCard()
    return {
        id = "cons_evolution",
        category = "evolution",
        name = "Tiến Hóa",
        desc = "Chọn lá bài để nâng +1 cấp thông số khả năng, không đổi rank/chất; hoặc nâng một SPN lên bậc kế tiếp.",
        icon = "✦",
        color = { 0.72, 0.42, 0.96, 1 },
    }
end

function RunManager.createSpeedSingleCard()
    return { id = "cons_speed_single", category = "speed_single", name = "Tăng Tốc Đơn",
        desc = "Chuột phải dùng trong trận, sau đó chọn một lá bài trên tay để tăng +5 tốc đánh vĩnh viễn.",
        icon = "➤", color = { 0.30, 0.68, 1, 1 } }
end

function RunManager.createSpeedTeamCard()
    return { id = "cons_speed_team", category = "speed_team", name = "Tăng Tốc Đội",
        desc = "Chuột phải dùng trong trận để tăng +2 tốc đánh vĩnh viễn cho mọi lá đang cầm.",
        icon = "»", color = { 0.30, 0.86, 0.65, 1 } }
end

function RunManager.createVitalityCard()
    return {id="cons_vitality",category="vitality",name="Sinh Lực Vĩnh Cửu",hpBonus=20,
        desc="Tiêu hao một lần: tăng vĩnh viễn 20 máu tối đa và hồi 20 HP trong run hiện tại.",
        color={0.92,0.38,0.45,1}}
end

function RunManager.createSpnSlotCard()
    return {id="cons_spn_slot",category="slot_expansion",slotType="spn",name="Khế Ước Dung Linh",
        desc="Tiêu hao một lần: thêm 1 ô SPN vĩnh viễn trong run. Dùng bao nhiêu lần cũng được.",color={.75,.5,1,1}}
end
function RunManager.createConsumableSlotCard()
    return {id="cons_consumable_slot",category="slot_expansion",slotType="consumable",name="Túi Không Gian",
        desc="Tiêu hao một lần: thêm 1 ô tiêu hao vĩnh viễn trong run. Không giới hạn số lần mở rộng.",color={.4,.8,1,1}}
end

function RunManager.createRoundRewardOptions()
    return {
        RunManager.createEvolutionCard(),
        RunManager.createSpeedSingleCard(),
        RunManager.createSpeedTeamCard(),
    }
end

function RunManager.chooseRoundReward(gameState, index)
    local offer = gameState and gameState.pendingRoundRewardChoice
    local reward = offer and offer.options and offer.options[index]
    if not reward then return false end
    gameState.consumables = gameState.consumables or {}
    if #gameState.consumables < Inventory.limit(gameState) then
        table.insert(gameState.consumables, reward)
    else
        gameState.pendingRewardCards = gameState.pendingRewardCards or {}
        table.insert(gameState.pendingRewardCards, reward)
    end
    gameState.pendingRoundRewardChoice = nil
    return true, reward
end

function RunManager.deliverEvolutionRewards(run, gameState)
    if not gameState then return 0 end
    gameState.consumables = gameState.consumables or {}
    gameState.pendingEvolutionCards = gameState.pendingEvolutionCards or 0

    local runStats = run and run.stats
    if runStats then
        local earned = math.max(0, math.floor(runStats.evolutionRewardsPending or 0))
        gameState.pendingEvolutionCards = gameState.pendingEvolutionCards + earned
        runStats.evolutionRewardsPending = 0
    end

    local delivered = 0
    while gameState.pendingEvolutionCards > 0 and #gameState.consumables < Inventory.limit(gameState) do
        table.insert(gameState.consumables, RunManager.createEvolutionCard())
        gameState.pendingEvolutionCards = gameState.pendingEvolutionCards - 1
        delivered = delivered + 1
    end
    gameState.pendingRewardCards = gameState.pendingRewardCards or {}
    while #gameState.pendingRewardCards > 0 and #gameState.consumables < Inventory.limit(gameState) do
        table.insert(gameState.consumables, table.remove(gameState.pendingRewardCards, 1))
        delivered = delivered + 1
    end
    return delivered
end

function RunManager.completeCurrentBlind(run, gameState)
    local blind = RunManager.getCurrentBlind(run)
    local rewardEarned = false
    if blind then
        if blind.status == "completed" then return false end
        blind.status = "completed"
        run.stats.blindsWon = (run.stats.blindsWon or 0) + 1
        local completedAnte = blind.ante or run.ante
        if completedAnte == 20 and blind.type == "boss" then run.travelPermit = true end
        local isAnteBoss = (blind.index == 3) or (run.currentBlindIndex == 3)
        run.stats.roundRewardAntes = run.stats.roundRewardAntes or {}
        if isAnteBoss and completedAnte % 4 == 0 and not run.stats.roundRewardAntes[completedAnte] then
            run.stats.roundRewardAntes[completedAnte] = true
            rewardEarned = true
            if gameState then
                gameState.pendingRoundRewardChoice = {
                    ante = completedAnte,
                    options = RunManager.createRoundRewardOptions(),
                }
            end
        end
    end
    RunManager.deliverEvolutionRewards(run, gameState)
    return rewardEarned
end

-- Advance to the next Blind directly or after leaving the Shop
-- Returns: true if game continues, false + "victory" if Stage 20 Boss defeated!
function RunManager.advanceBlind(run, gameState)
    if not run then return false end
    local current = RunManager.getCurrentBlind(run)
    if not current or current.status ~= "completed" then return false, "incomplete" end
    run.shopsVisitedInAnte = (run.shopsVisitedInAnte or 0) + 1

    if run.currentBlindIndex < 3 then
        run.currentBlindIndex = run.currentBlindIndex + 1
        run.blinds[run.currentBlindIndex].status = "current"
        return true, "next_blind"
    else
        -- Finished Boss Blind of the current Ante
        if run.ante >= RunManager.MAX_ANTE and not run.endless then
            run.victory = true
            return false, "victory"
        else
            run.ante = run.ante + 1
            run.currentBlindIndex = 1
            run.shopsVisitedInAnte = 0
            run.blinds = RunManager.generateAnteBlinds(run.ante, gameState and gameState.selectedFaction)
            return true, "next_ante"
        end
    end
end

-- Alias for backwards compatibility
RunManager.advanceAfterShop = RunManager.advanceBlind

return RunManager

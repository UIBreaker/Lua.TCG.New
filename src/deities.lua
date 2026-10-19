local Rng = require("src.rng")
local Deities = {}

Deities.RARITIES = {
    { id = "common", name = "Thường", code = "C", color = { 0.82, 0.84, 0.88, 1 } },
    { id = "uncommon", name = "Không Thường", code = "UC", color = { 0.28, 0.82, 0.48, 1 } },
    { id = "rare", name = "Hiếm", code = "R", color = { 0.30, 0.62, 1.00, 1 } },
    { id = "epic", name = "Sử Thi", code = "E", color = { 0.72, 0.38, 0.94, 1 } },
    { id = "legendary", name = "Huyền Thoại", code = "L", color = { 1.00, 0.62, 0.22, 1 } },
    { id = "mythic", name = "Thần Thoại", code = "M", color = { 0.94, 0.28, 0.30, 1 } },
    { id = "transcendent", name = "Siêu Việt", code = "T", color = { 0.48, 0.90, 0.96, 1 } },
    { id = "unique", name = "Độc Nhất", code = "UQ", color = { 0.82, 0.70, 1.00, 1 } },
    { id = "eternal", name = "Vĩnh Hằng", code = "VH", color = { 0.46, 0.95, 0.77, 1 } },
    { id = "supreme", name = "Tối Thượng", code = "TT", color = { 1.00, 0.85, 0.43, 1 } },
}

local rarityIndex = {}
for index, rarity in ipairs(Deities.RARITIES) do rarityIndex[rarity.id] = index end

local function rarityState(deity)
    local baseTier = tonumber(deity and deity.baseRarityTier)
        or rarityIndex[deity and (deity.baseRarity or deity.rarity)]
        or 1
    baseTier = math.max(1, math.min(#Deities.RARITIES, baseTier))
    local evolutionLevel = math.max(0, math.floor(tonumber(deity and deity.evolutionLevel) or 0))
    local absoluteTier = baseTier + evolutionLevel
    local tier = math.min(#Deities.RARITIES, absoluteTier)
    return Deities.RARITIES[tier], math.max(0, absoluteTier - #Deities.RARITIES), baseTier, evolutionLevel
end

function Deities.getRarityTier(card)
    local _, overflow, base, level = rarityState(card)
    return math.min(#Deities.RARITIES, base + level), overflow
end

function Deities.getRarityBadge(deity)
    local rarity, overflow = rarityState(deity)
    return rarity.code .. (overflow > 0 and ("+" .. overflow) or ""), rarity.color
end

function Deities.getRarityLabel(deity)
    local rarity, overflow = rarityState(deity)
    return rarity.name .. (overflow > 0 and (" +" .. overflow) or ""), rarity.color
end

local function formatEffectNumber(value)
    if value % 1 == 0 then return tostring(math.floor(value)) end
    return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", ""))
end

local function effectMultiplier(deity)
    local _, _, baseTier, evolutionLevel = rarityState(deity)
    return 1 + (baseTier - 1 + evolutionLevel) * 0.5
end

local function scaleDescription(description, multiplier)
    return (description or ""):gsub("([+])(%d+%.?%d*)", function(sign, amount)
        return sign .. formatEffectNumber(tonumber(amount) * multiplier)
    end)
end

function Deities.setRarity(deity, rarityId)
    local tier = rarityIndex[rarityId]
    if type(deity) ~= "table" or not tier then return false end

    deity.baseDesc = deity.baseDesc or deity.desc or ""
    deity.baseRarityTier = tier
    deity.baseRarity = rarityId
    deity.rarity = rarityId
    deity.evolutionLevel = math.max(0, math.floor(tonumber(deity.evolutionLevel) or 0))
    deity.desc = Deities.getDescription(deity)
    return true
end

function Deities.evolve(deity)
    if type(deity) ~= "table" or not deity.id then return false end
    local rarity, _, baseTier, evolutionLevel = rarityState(deity)
    deity.baseRarityTier = baseTier
    deity.baseRarity = deity.baseRarity or rarity.id
    deity.evolutionLevel = evolutionLevel + 1
    local nextRarity = rarityState(deity)
    deity.rarity = nextRarity.id
    deity.baseDesc = deity.baseDesc or deity.desc or ""
    deity.desc = Deities.getDescription(deity)
    local badge = Deities.getRarityBadge(deity)
    return true, badge
end

function Deities.scaleEffect(deity, result)
    local multiplier = effectMultiplier(deity)
    if not result or multiplier==1 then return require("src.blood_shop").effect(result,require("src.blood_shop").powerOf(deity)) end

    if result.consumableChancePct then result.consumableChancePct=math.min(100,result.consumableChancePct*multiplier) end
    if result.discardCopies then result.discardCopies=math.floor(result.discardCopies+2*(multiplier-1)) end
    if result.bossCopies then result.bossCopies=math.floor(result.bossCopies+2*(multiplier-1)) end
    if result.copyActivations then result.copyActivations=math.min(128,math.floor(result.copyActivations+2*(multiplier-1))) end
    if result.repeatsPerLevel then result.repeatsPerLevel=math.min(128,math.floor(result.repeatsPerLevel+2*(multiplier-1))) end
    if result.uqChancePct then result.uqChancePct=math.min(100,result.uqChancePct*multiplier) end

    for key, value in pairs(result) do
        if type(key) == "string" and key:sub(1, 3) == "add" and type(value) == "number" then
            local scaled = value * multiplier
            local def=Deities.CATALOG[deity.id]
            if def and def.doubleEvolution and key==def.stat then scaled=value*2^(2*(multiplier-1)) end
            if def and def.turnGrowth and key==def.stat then scaled=value+2*(multiplier-1) end
            if def and def.integerEffect and key==def.stat then scaled=math.floor(scaled) end
            if key=="addTransmutePct" then scaled=math.min(90,scaled) end
            if key=="addRedirectPct" then scaled=math.min(100,scaled) end
            if key=="addPotionChancePct" then scaled=math.min(100,scaled) end
            if key=="addFreezeTurns" then scaled=math.min(128,scaled) end
            result[key] = scaled

            local message = not result.fixedMessage and result.message
            if message then
                local number = formatEffectNumber(value)
                local startAt, endAt = message:find(number, 1, true)
                if startAt then
                    local before = startAt > 1 and message:sub(startAt - 1, startAt - 1) or ""
                    local after = message:sub(endAt + 1, endAt + 1)
                    if not before:match("[%d%.]") and not after:match("[%d%.]") then
                        result.message = message:sub(1, startAt - 1) .. formatEffectNumber(scaled) .. message:sub(endAt + 1)
                    end
                end
            end
        end
    end

    for _,key in ipairs({"xMult","xChips","xAura","xSoulYield","xPotionPower"}) do
        if type(result[key])=="number" and result[key]>1 then result[key]=1+(result[key]-1)*multiplier end
    end
    return require("src.blood_shop").effect(result,require("src.blood_shop").powerOf(deity))
end

-- Numeric values are shared by callbacks and descriptions.
Deities.CATALOG = {}
local entries = {
    {"spirit_pebble","Cổ Thạch","hand","addChips",20,nil,"+{value} Sát thương mỗi tay."},
    {"spirit_ember","Tàn Hỏa","hand","xMult",1,nil,"×{factor} Cường hóa mỗi tay."},
    {"spirit_twin_fang","Song Nanh Hư Không","hand","xChips",1,nil,"Mỗi tay tính điểm: ×{factor} Sát thương tại ô này."},
    {"spirit_blade","Kiếm Ảnh","card","addChips",10,nil,"Mỗi lá tính điểm: +{value} Sát thương."},
    {"spirit_drum","Trống Lôi","card","addMult",2,nil,"Mỗi lá tính điểm: +{value} Cường hóa."},
    {"spirit_pair","Song Đôi","hand","addMult",6,"pair","Đôi: +{value} Cường hóa."},
    {"spirit_straight","Lộ Kiếm","hand","addChips",30,"straight","Sảnh: +{value} Sát thương."},
    {"spirit_flush","Đồng Chất","hand","addMult",5,"flush","Thùng: +{value} Cường hóa."},
    {"spirit_crown","Huyết Vương","card","addChips",15,"royal","Mỗi lá J/Q/K tính điểm: +{value} Sát thương."},
    {"spirit_coin","Kim Tệ","win","addGold",2,nil,"Thắng trận: +{value} Vàng."},
    {"spirit_ward","Băng Vệ","start","addArmor",10,nil,"Vào trận: +{value} Giáp."},
    {"spirit_echo","Dội Lôi","attack","addSplashPct",20,nil,"Mỗi lần đánh: gây {value}% tổng AURA lên 1 quái còn sống ngẫu nhiên ngay bên cạnh mục tiêu."},
    {"spirit_hell_sleep","Ngủ Dưới Địa Ngục","attack","bedExplosionPct",500,nil,"Mỗi Giường đang giữ: +10 Cường hóa khi tính điểm."},
}
for _, row in ipairs(entries) do
    local entry={id=row[1],name=row[2],trigger=row[3],stat=row[4],values={value=row[5]},condition=row[6],
        descriptionTemplate=row[7],rarity="common",cost=4,lore="Hộ linh đồng hành cùng các lá bài."}
    entry.desc=row[7]:gsub("{value}",tostring(row[5])):gsub("{factor}",tostring(1+row[5]));entry.baseDesc=entry.desc
    local function callback(subject,context,owned)
        if entry.condition=="royal" and not (subject and subject.rank>=11 and subject.rank<=13) then return nil end
        if entry.condition and entry.condition~="royal" and not (subject and subject.type and subject.type.id==entry.condition) then return nil end
        local message=entry.id=="spirit_twin_fang" and Deities.getDescription(owned or entry) or entry.desc
        return {[entry.stat]=entry.stat:sub(1,1)=="x" and 1+entry.values.value or entry.values.value,message=message}
    end
    if entry.trigger=="card" then entry.onCardScored=callback
    elseif entry.trigger=="hand" then entry.onHandScored=callback
    elseif entry.trigger=="start" then entry.onRoundStart=callback
    elseif entry.trigger=="attack" then entry.onAttack=callback
    else entry.onRoundWin=callback end
    Deities.CATALOG[entry.id]=entry
end
Deities.CATALOG.spirit_hell_sleep.onHandScored=function(hand,context)
    local game=context and (context.gameState or context) or {}
    local beds=0
    for _,item in ipairs(game.consumables or {}) do if item.id=="cons_bed" then beds=beds+1 end end
    if beds>0 then return {addMult=10*beds} end
end
-- These callbacks only read the evaluated hand and battle state, so previews
-- and real scoring use the same conditions without spending resources.
local function playedCards(hand)
    local cards = {}
    for _, group in ipairs({hand.scoringCards or {}, hand.unscoredCards or {}}) do
        for _, card in ipairs(group) do cards[#cards + 1] = card end
    end
    return cards
end

local factionAliases = {
    valoria="hearts", sanguine_covenant="hearts", aurelia="diamonds", gilded_conclave="diamonds",
    elaris="clubs", feral_swarm="clubs", vharos="spades", iron_axiom="spades",
}
local tacticalEntries = {
    {"spirit_lone", "Độc Hành", 1, "Chơi đúng 1 lá: ×{factor} Cường hóa.", function(hand, game, value)
        if #playedCards(hand) == 1 then return {xMult=1 + value} end
    end},
    {"spirit_confluence", "Hội Lưu", 3, "Ít nhất 3 phe trong các lá tính điểm: +{value} Cường hóa mỗi phe.", function(hand, game, value)
        local seen, count = {}, 0
        for _, card in ipairs(hand.scoringCards or {}) do
            local faction = factionAliases[card.suit] or card.suit
            if faction and not seen[faction] then seen[faction]=true; count=count + 1 end
        end
        if count >= 3 then return {addMult=value * count} end
    end},
    {"spirit_rearguard", "Hậu Vệ", 4, "Mỗi lá đã chơi không tính điểm: +{value} Giáp.", function(hand, game, value)
        local count = #(hand.unscoredCards or {})
        if count > 0 then return {addArmor=value * count} end
    end},
    {"spirit_wound", "Huyết Khuyết", 1, "Mỗi HP đã mất: +{value} Sát thương (tính tối đa 60 HP).", function(hand, game, value)
        local missing = math.min(60, math.max(0, (game.maxPlayerHp or 100) - (game.playerHp or 100)))
        if missing > 0 then return {addChips=value * missing} end
    end},
    {"spirit_bastion", "Pháo Linh", 0.02, "Mỗi Giáp hiện có: +{value} vào hệ số Cường hóa (tính tối đa 30 Giáp).", function(hand, game, value)
        local armor = math.min(30, math.max(0, game.playerArmor or game.playerShield or 0))
        if armor > 0 then return {xMult=1 + value * armor} end
    end},
    {"spirit_stillness", "Tĩnh Triều", 8, "Chưa bỏ bài trong trận: +{value} Cường hóa mỗi lượt bỏ còn lại. Chơi lá 8: tiêu hủy lá đó sau tính điểm để tăng vĩnh viễn 1 lượt bỏ.", function(hand, game, value)
        local remaining = math.max(0, game.discardsRemaining or 0)
        local result={}
        if (game.discardsUsedInCombat or 0) == 0 and remaining > 0 then result.addMult=value * remaining end
        if #(game.persistentDeck or {})>1 then
            for _,card in ipairs(playedCards(hand)) do
                if card.rank==8 and not card.destroyed then result.destroyEight=card;break end
            end
        end
        if next(result) then return result end
    end},
    {"spirit_molt", "Lột Xác", 2, "Mỗi lượt bỏ đã dùng trong trận: +{value} Cường hóa (tính tối đa 3 lượt).", function(hand, game, value)
        local used = math.min(3, math.max(0, game.discardsUsedInCombat or 0))
        if used > 0 then return {addMult=value * used} end
    end},
    {"spirit_pivot", "Chuyển Ảnh", 0.4, "Từ tay thứ hai, đổi kiểu tay bài so với tay trước: ×{factor} Cường hóa.", function(hand, game, value)
        local previous = game.abilityCombat and game.abilityCombat.previousHandType
        if previous and hand.type and previous ~= hand.type.id then return {xMult=1 + value} end
    end},
    {"spirit_mender", "Khâu Hồn", 4, "Ít nhất 2 lá tính điểm có trang bị: hồi +{value} HP.", function(hand, game, value)
        local count = 0
        for _, card in ipairs(hand.scoringCards or {}) do
            if #(card.equipments or {}) > 0 then count=count + 1 end
        end
        if count >= 2 then return {addHealHp=value} end
    end},
    {"spirit_gleaner", "Mót Sao", 1, "Chỉ chơi bài bậc 2–10, tổng bậc không quá 12: +{value} Vàng.", function(hand, game, value)
        local cards, total = playedCards(hand), 0
        if #cards == 0 then return nil end
        for _, card in ipairs(cards) do
            if not card.rank or card.rank < 2 or card.rank > 10 then return nil end
            total=total + card.rank
        end
        if total <= 12 then return {addGold=value} end
    end},
}
local tacticalStats = {
    spirit_lone="xMult", spirit_confluence="addMult", spirit_rearguard="addArmor",
    spirit_wound="addChips", spirit_bastion="xMult", spirit_stillness="addMult",
    spirit_molt="addMult", spirit_pivot="xMult", spirit_mender="addHealHp", spirit_gleaner="addGold",
}
for _, row in ipairs(tacticalEntries) do
    local entry = {id=row[1], name=row[2], values={value=row[3]}, descriptionTemplate=row[4],
        stat=tacticalStats[row[1]], rarity="common", cost=4, trigger="hand", lore="Một dị linh của lục địa, đáp lại chiến thuật riêng của đoàn viễn chinh."}
    entry.onHandScored = function(hand, context)
        return row[5](hand or {}, context and (context.gameState or context) or {}, entry.values.value)
    end
    Deities.CATALOG[entry.id] = entry
end

require("src.spn_anomalies").register(Deities)
require("src.spn_convergence").register(Deities)
require("src.spn_velocity").register(Deities)
require("src.spn_provisions").register(Deities)
require("src.spn_discard").register(Deities)
require("src.spn_souls").register(Deities)
require("src.spn_legacy").register(Deities)
require("src.spn_mimic").register(Deities)
require("src.spn_basics").register(Deities)
require("src.spn_turns").register(Deities)
require("src.spn_pacts").register(Deities)
require("src.spn_vitality").register(Deities)
require("src.spn_foundations").register(Deities)
require("src.spn_growth").register(Deities)
require("src.spn_bounty").register(Deities)
require("src.spn_alchemy").register(Deities)
require("src.spn_elements").register(Deities)
require("src.spn_predators").register(Deities)
require("src.spn_reserves").register(Deities)
require("src.spn_formations").register(Deities)
require("src.spn_aura").register(Deities)
require("src.spn_trials").register(Deities)

function Deities.getDescription(deity)
    local def=Deities.CATALOG[deity.id]
    if not def then return deity.desc or "" end
    local value=def.values.value*(def.stat=="bedExplosionPct" and 1 or effectMultiplier(deity))
    if def.doubleEvolution then value=def.values.value*2^(2*(effectMultiplier(deity)-1)) end
    if def.turnGrowth then value=def.values.value+2*(effectMultiplier(deity)-1) end
    if def.integerEffect then value=math.floor(value) end
    if def.stat=="addTransmutePct" then value=math.min(90,value) end
    if def.stat=="addRedirectPct" then value=math.min(100,value) end
    if def.stat=="consumableChancePct" then value=math.min(100,value) end
    if def.stat=="discardCopies" or def.stat=="bossCopies" then value=math.floor(def.values.value+2*(effectMultiplier(deity)-1)) end
    if def.stat=="copyActivations" then value=math.min(128,math.floor(def.values.value+2*(effectMultiplier(deity)-1))) end
    if def.stat=="repeatsPerLevel" then value=math.min(128,math.floor(def.values.value+2*(effectMultiplier(deity)-1))) end
    if def.stat=="uqChancePct" then value=math.min(100,value) end
    if def.stat=="addPotionChancePct" then value=math.min(100,value) end
    value=value*require("src.blood_shop").powerOf(deity)
    if def.stat=="addTransmutePct" then value=math.min(90,value) end
    if def.stat=="addRedirectPct" then value=math.min(100,value) end
    if def.stat=="copyActivations" or def.stat=="repeatsPerLevel" then value=math.min(128,math.floor(value)) end
    if def.stat=="consumableChancePct" or def.stat=="uqChancePct" then value=math.min(100,value) end
    if def.stat=="addPotionChancePct" then value=math.min(100,value) end
    if def.stat=="addFreezeTurns" then value=math.min(128,value) end
    local text=(def.descriptionTemplate:gsub("{value}",formatEffectNumber(value)):gsub("{factor}",formatEffectNumber(require("src.blood_shop").powerOf(deity) + value)):gsub("{double}",formatEffectNumber(value*2)):gsub("{scale}",formatEffectNumber(effectMultiplier(deity)*require("src.blood_shop").powerOf(deity))))
    if deity.id=="spirit_victory_bounty" then text=require("src.spn_bounty").description(deity) end
    if deity.id=="spirit_cinder_confluence" then text=text:gsub("{burn}",formatEffectNumber(Deities.scaleEffect(deity,{addBurnPct=5}).addBurnPct)) end
    if deity.id=="spirit_march_covenant" then text=text:gsub("{heal}",formatEffectNumber(Deities.scaleEffect(deity,{addHealPct=5}).addHealPct)) end
    if deity.id=="spirit_gilded_weight" then text=def.descriptionTemplate:gsub("{value}",(string.format("%.3f",value):gsub("0+$", ""):gsub("%.$", ""))) end
    if deity.id=="spirit_hell_sleep" then
        text="Mỗi Giường đang giữ: +"..formatEffectNumber(10*effectMultiplier(deity)*require("src.blood_shop").powerOf(deity)).." Cường hóa khi tính điểm."
    elseif deity.id=="spirit_last_pact" then
        text="Một lần mỗi trận: chặn đòn chí tử, còn "..(5*require("src.blood_shop").powerOf(deity)).." HP, không vượt máu tối đa."
    end
    if deity.id=="spirit_borrowed_turn" then
        text="Một lần mỗi trận: chơi đúng 3 lá đều tính điểm, nhận một bình +"..(3*require("src.blood_shop").powerOf(deity)).." tốc đánh vĩnh viễn cho một lá (tối đa 999)."
    elseif deity.id=="spirit_archive" and require("src.blood_shop").powerOf(deity)>1 then
        text="Mỗi 3 kiểu tay khác nhau đánh trong trận: nhận "..require("src.blood_shop").powerOf(deity).." lá Tiến Hóa, rồi bắt đầu đếm lại."
    end
    local growth=require("src.spn_convergence").describe(deity)
    if deity.id=="spirit_right_offering" then growth="TÍCH HIẾN TẾ · ×"..formatEffectNumber(1+((deity.spnGrowth or {}).offeringMult or 0)) end
    if deity.id=="spirit_ashen_legacy" then growth="TÍCH THỪA DIỆT · ×"..formatEffectNumber(1+((deity.spnGrowth or {}).deathChips or 0)) end
    if growth then text=text.."\n"..growth end
    local spell=require("src.spn_enchantments").get(deity.enchantment)
    if spell then text=text.."\nPHÙ PHÉP · "..spell.name..": "..require("src.blood_shop").describe(spell.desc,deity.enchantmentPower or 1) end
    if deity.bloodPower then text=text.."\nHUYẾT LUYỆN ×5 · Chỉ số hiệu quả gấp 5." end
    if deity.bloodDomainPower then text=text.."\nLÃNH ĐỊA MÁU ×4 · Chỉ số hiệu quả gấp 4." end
    if deity.voidPower then text=text.."\nTHE VOID ×"..deity.voidPower.." · Chỉ số hiệu quả gấp "..deity.voidPower.."." end
    return text
end
for _, row in ipairs(tacticalEntries) do
    local entry = Deities.CATALOG[row[1]]
    entry.desc = Deities.getDescription(entry)
    entry.baseDesc = entry.desc
end

function Deities.getCount(deities)
    local count = 0
    for key, deity in pairs(deities or {}) do
        if type(key) == "number" and deity ~= nil then count = count + 1 end
    end
    return count
end

function Deities.resolveDeity(deities, index,game)
    return require("src.spn_mimic").resolve(deities,index,game)
end

function Deities.getStarterDeity(suit)
    local starters = {
        hearts = "spirit_ember", valoria = "spirit_ember",
        diamonds = "spirit_coin", aurelia = "spirit_coin",
        clubs = "spirit_blade", elaris = "spirit_blade",
        spades = "spirit_pebble", vharos = "spirit_pebble",
    }
    return Deities.CATALOG[starters[suit] or "spirit_pebble"]
end

function Deities.getRandomShopPool(ownedDeities, count)
    local owned = {}
    for _, deity in pairs(ownedDeities or {}) do
        if type(deity) == "table" and deity.id then owned[deity.id] = true end
    end

    local candidates = {}
    for id, deity in pairs(Deities.CATALOG) do
        if not owned[id] then table.insert(candidates, deity) end
    end
    for i = #candidates, 2, -1 do
        local j = Rng.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    local result = {}
    for i = 1, math.min(count or 3, #candidates) do result[i] = candidates[i] end
    return result
end

function Deities.getBossDraftPool(ownedDeities, count)
    return Deities.getRandomShopPool(ownedDeities, count or 2)
end

Deities.BASE_SLOTS = 5
Deities.MAX_SLOTS = 5

function Deities.getMaxSlots(gameState)
    local maxSlots = Deities.BASE_SLOTS + ((gameState and gameState.extraDeitySlots) or 0)
    local list = gameState and gameState.deities or gameState
    local occupiedMax=0
    for slot, deity in pairs(type(list) == "table" and list or {}) do
        if type(slot)=="number" and type(deity)=="table" and deity.id then occupiedMax=math.max(occupiedMax,slot) end
        if type(deity) == "table" and deity.edition == "negative" then maxSlots=maxSlots+math.max(deity.editionPower==5 and 5 or 1,require("src.blood_shop").powerOf(deity)) end
    end
    -- Boss rewards may exceed capacity; every occupied slot stays visible and active.
    return math.max(maxSlots,occupiedMax)
end

function Deities.destroyDeity(game,slot,inCombat,physical)
    if not game.deities or not game.deities[slot] then return false end
    physical=physical or game.deities[slot]
    if inCombat then require("src.spn_predators").destroyed(game,physical) end
    game.deities[slot]=nil
    if game.spnCombat then game.spnCombat[physical]=nil end
    require("src.spn_reserves").destroyed(game)
    return true
end

function Deities.addDeity(gameState, deity, preferredSlot)
    if not gameState or not deity then return false end
    gameState.deities = gameState.deities or {}
    local maxSlots = Deities.getMaxSlots(gameState)
    if Deities.getCount(gameState.deities) >= maxSlots then return false end

    local instance = {}
    for key, value in pairs(deity) do instance[key] = value end

    if preferredSlot and preferredSlot >= 1 and preferredSlot <= maxSlots and not gameState.deities[preferredSlot] then
        gameState.deities[preferredSlot] = instance
        return true
    end
    for i = 1, maxSlots do
        if not gameState.deities[i] then
            gameState.deities[i] = instance
            return true
        end
    end
    return false
end

return Deities

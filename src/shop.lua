local Loadout = require("src.loadout")
local Equipment = require("src.equipment")
local Poker = require("src.poker")
local Sound = require("src.sound")
local Deck = require("src.deck")
local Deities = require("src.deities")
local Rng = require("src.rng")
local CardEffects = require("src.card_effects")
local Souls = require("src.souls")
local Blood = require("src.blood_shop")

local Shop = {}

Shop.MARKETS = {
    small = {name="SHOP NHỎ", note="Quầy tổng hợp · SPN, trang bị, quân bài, đặc quyền, rương và tiêu hao", color={.35,.82,.78,1}},
    consumable = {name="SHOP TIÊU HAO", note="Thẻ lẻ từ mọi rương tiêu hao · Giá cao hơn giá rương 20%, làm tròn lên", color={.74,.48,.94,1}},
    equipment = {name="SHOP TRANG BỊ", note="4 nguyên liệu cơ bản + 4 trang bị lớn · Mua để cất vào balo", color={.95,.73,.35,1}},
    spn = {name="SHOP SPN", note="Chỉ bán C–L · Bậc cao hiếm hơn, đắt hơn · E từ ải 3 · L từ ải 6", color={.53,.75,.98,1}},
    medicine = {name="SHOP THUỐC", note="Hồi phục, giáp, tốc đánh và 8 thuốc chiến thuật · Hai ngăn thuốc", color={.38,.88,.57,1}},
    cards = {name="SHOP QUÂN BÀI", note="52 quân bài · Tiến hóa cấp 1–2 · Chỉ trang bị cơ bản · 9 ấn bản", color={.92,.64,.48,1}},
    large = {name="SHOP LỚN", note="Thương hội lớn · Trạm tiếp tế sau chợ linh hồn", color={.95,.78,.35,1}},
    soul = {name="CHỢ LINH HỒN"},
    blood_small = {name="SHOP MÁU NHỎ",note="8 món Huyết Luyện ×5 · Mua và đổi hàng bằng HP",color={.93,.28,.35,1}},
    blood_large = {name="SHOP MÁU LỚN",note="16 món Huyết Luyện ×5 · Mua và đổi hàng bằng HP",color={.93,.28,.35,1}},
}
Shop.AFTER_COMBAT_MARKETS = {"small", "consumable", "equipment", "spn", "medicine", "cards"}

function Shop.marketMode(mode)
    -- "normal" is retained for old callers that preview the original shop.
    return Shop.MARKETS[mode] and mode or "large"
end
function Shop.canAfford(item,game)
    local cost=tonumber(item.cost)
    if not cost or cost<0 or cost~=cost or cost==math.huge then return false end
    if item.currency=="blood" then return (game.playerHp or 0)>=1 and (game.playerHp or 0)+require("src.spn_elements").remaining(game)-cost>=1 end
    return (item.currency=="souls" and (game.souls or 0) or (game.gold or 0))>=cost
end
function Shop.payItem(item,game)
    if item.currency=="blood" then
        if not Shop.canAfford(item,game) then return false end
        game.playerHp=game.playerHp-require("src.spn_elements").absorb(game,item.cost,false)
    else game.gold=(game.gold or 0)-item.cost end
end
local function basicHandsUnlocked(gameState)
    for _, hand in ipairs(Poker.HAND_TYPES_ORDERED) do
        if not (gameState.unlockedHands and gameState.unlockedHands[hand.id]) then return false end
    end
    return true
end
Shop.FREE_OFFER_CHANCE = 0.08
Shop.SALE_MULTIPLIER = 0.65
Shop.PRICE_MULTIPLIER = 4
Shop.SPN_STAGE_GATES = {epic=3,legendary=6}
function Shop.discountedEquipment(eq,bay,roll)
    local free=(roll or Rng.random())<Shop.FREE_OFFER_CHANCE and (eq.basic or (eq.craftTier or 99)<=1)
    return {section="discount",bay=bay,category="equipment",equipment=eq,name=eq.name,
        desc=Equipment.getDescription(eq),color=eq.color,originalCost=eq.cost,
        cost=free and 0 or math.max(1,math.floor(eq.cost*Shop.SALE_MULTIPLIER)),
        backpack=true,sale=true,free=free,subtitle=eq.name}
end

Shop.SOUL_SUPPORT = {
    {id="cons_evolution",factory="createEvolutionCard",cost=12},
    {id="cons_speed_single",factory="createSpeedSingleCard",cost=6},
    {id="cons_speed_team",factory="createSpeedTeamCard",cost=10},
    {id="cons_vitality",factory="createVitalityCard",cost=10},
    {id="cons_spn_slot",factory="createSpnSlotCard",cost=18},
    {id="cons_consumable_slot",factory="createConsumableSlotCard",cost=12},
    {id="cons_socket",factory="createSocketCard",cost=32},
    {id="cons_rulebreak",factory="createRulebreakCard",cost=48},
}

-- Public catalogs are shared with the collection screen so every listed item
-- is obtainable and every obtainable shop item is documented in one place.
Shop.VOUCHERS = {
    { id = "v_discount", name = "Thẻ Thành Viên", cost = 6, color = { 0.35, 0.85, 0.55, 1 }, icon = "🎟️" },
    { id = "v_interest", name = "Sổ Tiết Kiệm", cost = 8, color = { 0.95, 0.80, 0.25, 1 }, icon = "💰" },
    { id = "v_hand_plus", name = "Bùa Hảo Thủ", cost = 12, color = { 0.85, 0.45, 0.95, 1 }, icon = "✋" },
    { id = "v_welcome", name = "Lời Chào Thương Hội", cost = 6, color = { 0.38, 0.80, 0.94, 1 }, icon = "↻" },
    { id = "v_pack_discount", name = "Bản Đồ Kho Báu", cost = 8, color = { 0.95, 0.68, 0.30, 1 }, icon = "◇" },
    { id = "v_apothecary", name = "Lời Thề Dược Sư", cost = 8, color = { 0.39, 0.84, 0.62, 1 }, icon = "+" },
    { id = "v_altar", name = "Giao Kèo Tro Vàng", cost = 8, color = { 0.94, 0.48, 0.38, 1 }, icon = "✦" },
    { id = "v_vitality", name = "Trái Tim Bất Diệt", cost = 8, color = { 0.93, 0.36, 0.51, 1 }, icon = "♥" },
    { id = "v_second_chance", name = "Quân Cờ Dự Phòng", cost = 8, color = { 0.65, 0.58, 0.94, 1 }, icon = "♠" },
}
local voucherParams={v_discount={discount=2},v_interest={cap=5,bonus=1},v_hand_plus={hands=1},v_welcome={rolls=1},
    v_pack_discount={discount=3},v_apothecary={heal=8},v_altar={gold=2},v_vitality={hp=25},v_second_chance={discards=1}}
local voucherText={
    v_discount="Giảm {discount} Vàng mỗi lần đổi hàng trả vàng, tối thiểu 1 Vàng. Không giảm giá đổi bằng HP/linh hồn.",
    v_interest="Trần lãi +{cap} Vàng; thêm {bonus} Vàng lãi mỗi 20 Vàng tích trữ. Phe miễn trần lãi vẫn nhận lãi thêm.",
    v_hand_plus="Thêm {hands} lượt đánh mỗi trận. Mỗi lần mua nhận ngay phần lượt tăng thêm.",
    v_welcome="{rolls} lần đổi hàng đầu mỗi shop vàng miễn phí, không tăng giá đổi hàng. Không áp dụng shop máu/linh hồn.",
    v_pack_discount="Mọi rương shop giảm {discount} Vàng, tối thiểu 1; áp dụng ngay và suốt run.",
    v_apothecary="Hồi {heal} HP đầu mỗi trận. Khi mua hồi ngay phần hồi phục mới thêm, không vượt HP tối đa.",
    v_altar="Mỗi trận thắng nhận thêm {gold} Vàng. Không thưởng khi bỏ qua trận; không tăng giá bán đồ.",
    v_vitality="Tổng HP tối đa +{hp}. Khi mua tăng và hồi đúng phần HP mới thêm.",
    v_second_chance="Thêm {discards} lượt bỏ bài mỗi trận. Mỗi lần mua nhận ngay phần lượt tăng thêm.",
}
function Shop.voucherLevel(id,game)
    local owned=game and game.vouchers and game.vouchers[id]
    return owned and (type(owned)=="table" and owned.level or 1) or 0
end
function Shop.voucherPower(id,game)
    local owned=game and game.vouchers and game.vouchers[id]
    return owned and (type(owned)=="table" and owned.power or Blood.powerOf(owned)) or 0
end
function Shop.voucherParams(id,game)
    local power=game and Shop.voucherPower(id,game) or 1
    local params={}
    for k,v in pairs(voucherParams[id] or {}) do params[k]=v*power end
    return params
end
function Shop.voucherName(id,level)
    for _,v in ipairs(Shop.VOUCHERS) do if v.id==id then return v.name.." · Cấp "..level end end
    return id
end
function Shop.voucherDescription(id,item)
    local template=voucherText[id];if not template then return nil end
    local power=item and item.voucherPower or Blood.powerOf(item)
    local text=template:gsub("{([%w_]+)}",function(k) return tostring((voucherParams[id][k] or 0)*power) end)
    return text.."\nSuốt run · Mua lại cộng dồn, tăng cấp và tăng giá."
end
function Shop.voucherOffer(v,game,power)
    power=power or 1
    local level=Shop.voucherLevel(v.id,game)+1
    local offer={id=v.id,category="voucher",voucherId=v.id,voucherLevel=level,voucherPreviousLevel=level-1,
        voucherPower=Shop.voucherPower(v.id,game)+power,name=Shop.voucherName(v.id,level),
        cost=math.ceil(v.cost*(1+.6*(level-1)+.15*(level-1)^2)),color=v.color,icon=v.icon,
        subtitle="PHIẾU ĐẶC QUYỀN · CẤP "..level}
    offer.desc=Shop.voucherDescription(v.id,offer)
    return offer
end
for _,v in ipairs(Shop.VOUCHERS) do v.params=Shop.voucherParams(v.id);v.desc=Shop.voucherDescription(v.id) end

function Shop.interest(game)
    local p=Shop.voucherParams("v_interest",game)
    local cap=math.max(game.maxInterest or 3,Shop.voucherLevel("v_interest",game)>0 and 5+p.cap or 0,
        game.vouchers and game.vouchers.seed_money and 5 or 0)
    local gold=game.gold or 0
    local gilded=game.selectedFaction=="diamonds" or game.selectedFaction=="gilded_conclave" or game.isGildedConclave==true
    local interest=math.floor(gold/(gilded and 4 or 5))+math.floor(gold/20)*p.bonus
    return gilded and interest or math.min(cap,interest),cap,gilded
end

Shop.PACK_CATALOG = {
    { packType = "buffoon", name = "GÓI HỘ LINH", subtitle = "HỘ LINH", desc = "Mở 3 Hộ Linh, chọn 1 để sở hữu.", cost = 4, rarity = "Hộ Linh", color = { 0.88, 0.35, 0.35, 1 }, icon = "🃏" },
    { packType = "arcana", name = "GÓI TRANG BỊ", subtitle = "KHẢM NGỌC", desc = "Mở 3 Trang Bị Khảm, chọn 1 để gắn vào bài.", cost = 5, rarity = "Trang Bị", color = { 0.95, 0.75, 0.25, 1 }, icon = "💎" },
    { packType = "standard", name = "GÓI QUÂN BÀI", subtitle = "CƯỜNG HÓA", desc = "Mở 3 quân bài có thể mang cường hóa, chọn 1 vào bộ bài.", cost = 4, rarity = "Quân Bài", color = { 0.25, 0.60, 0.95, 1 }, icon = "📦" },
    { packType = "joker_edition", name = "GÓI PHÙ PHÉP HỘ LINH", subtitle = "PHÙ PHÉP", desc = "Mở 3 trong 8 phù phép chiến thuật; chọn 1 và SPN nhận phép.", cost = 6, rarity = "Phù Phép", color = { 0.85, 0.40, 0.95, 1 }, icon = "✨" },
    { packType = "seal", name = "GÓI CON DẤU", subtitle = "ẤN CHIẾN", desc = "Mở 3 Con Dấu chiến thuật, chọn 1 để đóng lên bài.", cost = 6, rarity = "Con Dấu", color = { 0.95, 0.70, 0.20, 1 }, icon = "🔴" },
    { packType = "spectral", name = "GÓI BIẾN ĐỔI", subtitle = "DỊ THỂ", desc = "Mở 3 trong 7 Dị Thể thiết yếu; chọn 1 để chỉnh bộ bài, hoặc cất trong balo.", cost = 7, rarity = "Biến Đổi", color = { 0.40, 0.85, 0.85, 1 }, icon = "🔮" },
    { packType = "celestial", name = "GÓI HÀNH TINH", subtitle = "HÀNH TINH", desc = "Mở 3 Hành Tinh nâng cấp tay bài, chọn 1.", cost = 5, rarity = "Hành Tinh", color = { 0.35, 0.55, 0.95, 1 }, icon = "🪐" },
    { packType = "hand_styles", name = "RƯƠNG THẾ ĐÁNH", subtitle = "THẾ ĐÁNH", desc = "Ưu tiên Bí Tịch cho thế đánh chưa mở khóa; mở 3 lá, chọn 1.", cost = 7, rarity = "Bí Tịch", color = { 0.95, 0.72, 0.22, 1 }, icon = "♠" },
    { packType = "edition", name = "RƯƠNG ẤN BẢN", subtitle = "ẤN BẢN", desc = "Chọn một trong 9 Ấn Bản để cất hoặc khảm lên một lá bài.", cost = 8, rarity = "Ấn Bản", color = { 0.78, 0.48, 0.96, 1 }, icon = "✦" },
}
Shop.ADVANCED_HAND_CHEST = {packType="hand_styles_advanced",name="RƯƠNG THẾ ĐÁNH NÂNG CAO",subtitle="THẾ ĐÁNH NÂNG CAO",desc="18 thế đánh đặc biệt, yêu cầu đánh đủ 5 lá. Mở 3 bí tịch, chọn 1; ưu tiên thế chưa học. Bí tịch trùng +1 cấp.",cost=12,rarity="Bí Tịch Nâng Cao",color={0.72,0.56,0.96,1},icon="♠"}
Shop.PACK_CATALOG[#Shop.PACK_CATALOG+1]=Shop.ADVANCED_HAND_CHEST

Shop.SPN_RARITY_WEIGHTS = {
    common = 0.68, uncommon = 0.22, rare = 0.075, epic = 0.02, legendary = 0.005,
}
Shop.SPN_RARITY_PRICE_MULTIPLIERS = {
    common = 1, uncommon = 1.5, rare = 2, epic = 3,
    legendary = 5, mythic = 8, transcendent = 12, unique = 18,
    eternal = 27, supreme = 40,
}

-- Canonical pack reward catalogs. Both the shop and the collection read these
-- tables so a reward can never be sold without also being documented.
Shop.JOKER_SPELLS = {}

Shop.SEAL_CARDS = {}
for _,id in ipairs(Deck.SEAL_ORDER) do Shop.SEAL_CARDS[#Shop.SEAL_CARDS+1]=Deck.SEALS[id] end

Shop.SPECTRAL_CARDS = require("src.spectral").cards

Shop.CONSUMABLE_RULES={
    cons_speed_small={params={speed=3},description="Chọn một lá đang trên tay: +{speed} tốc đánh trong trận hiện tại (tối đa 999). Hủy chọn không mất thẻ."},
    cons_speed_large={params={speed=10},description="Chọn một lá đang trên tay: +{speed} tốc đánh trong trận hiện tại (tối đa 999). Hủy chọn không mất thẻ."},
    speed_single={params={speed=5},description="Chọn một lá đang trên tay: +{speed} tốc đánh lâu dài (tối đa 999). Hủy chọn không mất thẻ."},
    speed_team={params={speed=2},description="Mọi lá đang trên tay: +{speed} tốc đánh lâu dài (tối đa 999). Chỉ dùng khi đang chiến đấu và có bài."},
    celestial={params={levels=2},description=""},
    planet_supernova={params={levels=3},description="Một thế đánh ngẫu nhiên tăng {levels} cấp; không tự mở khóa."},
    planet_black_hole={params={levels=2},description="Tăng mọi thế đánh {levels} cấp; không tự mở khóa."},
}
for _, entry in ipairs({{Shop.JOKER_SPELLS,"spells"}}) do
    local cards={}
    for _,module in ipairs({"src.chest_expansion","src.chest_depth"}) do
        for _,card in ipairs(require(module)[entry[2]]) do cards[#cards+1]=card end
    end
    for _, card in ipairs(cards) do
        entry[1][#entry[1]+1]=card
        if entry[2]~="seals" then Shop.CONSUMABLE_RULES[card.id]={params=card.params,description=card.desc} end
    end
end
Shop.PACK_CATALOG[4].desc="Mở 3 phép trong bộ 8 phù phép chiến thuật; chọn 1 rồi chọn SPN nhận phép, hoặc cất trong balo."
function Shop.getConsumableParams(item)
    local rule=Shop.CONSUMABLE_RULES[item.id] or Shop.CONSUMABLE_RULES[item.category]
    return Blood.params(rule and rule.params or {},Blood.powerOf(item),true)
end
function Shop.getConsumableDescription(item,game)
    if game and require("src.spn_alchemy").isPotion(item) then
        local text=require("src.potions").describe(item,game)
        if text then return text end
        local boost=require("src.spn_alchemy").multiplier(game,item)
        if item.healAmt then return "Hồi "..(item.healAmt*boost).." HP, không vượt HP tối đa." end
        if item.armorAmt then return "+"..(item.armorAmt*boost).." Giáp, không vượt giới hạn Giáp." end
        local speed=Shop.getConsumableParams(item).speed*boost
        local _,chance=require("src.spn_alchemy").effects(game)
        return "Chọn một quân trên tay: +"..speed..(item.permanentSpeed and " tốc đánh vĩnh viễn" or " tốc đánh trong trận")..", tối đa 999. Hủy chọn không mất thuốc."
            ..(chance>0 and ("\nDƯỢC HỒN · "..string.format("%g",chance).."% giữ lượng tăng vĩnh viễn.") or "")
    end
    local spectral=require("src.spectral").describe(item);if spectral then return spectral end
    if Blood.powerOf(item)>1 then
        if item.category=="combat_potion" then return require("src.potions").describe(item) end
        if item.healAmt then return "Hồi "..item.healAmt.." HP, không vượt HP tối đa.\nHUYẾT LUYỆN ×5" end
        if item.armorAmt then return "+"..item.armorAmt.." Giáp, không vượt giới hạn Giáp.\nHUYẾT LUYỆN ×5" end
        if item.category=="slot_expansion" then return "Thêm 5 ô "..(item.slotType=="spn" and "SPN" or "tiêu hao").." vĩnh viễn.\nHUYẾT LUYỆN ×5" end
        if item.category=="socket_expansion" then return "Mở thêm tối đa 5 hốc trang bị cho quân bài, không vượt 8 hốc.\nHUYẾT LUYỆN ×5" end
        if item.id=="cons_vitality" then return "Tăng "..((item.hpBonus or 20)*5).." HP tối đa và hồi lượng HP tương ứng.\nHUYẾT LUYỆN ×5" end
        local base=Blood.clone(item);base.bloodPower=nil
        return Blood.describe(Shop.getConsumableDescription(base) or item.desc or "",5)
    end
    if item.sealType or item.category=="seal" then
        local seal=Deck.getModifier("seal",item.sealType or item.id)
        if seal then return "Đóng lên lá được chọn (hoặc lá đầu tay/bộ bài nếu chưa chọn).\n"..Deck.getModifierDescription("seal",seal.id) end
    end
    local enchantment=require("src.spn_enchantments").get(item.id)
    if enchantment then return "Chọn SPN đang trang bị hoặc trong balo; thay phù phép cũ, giữ tiến hóa và ấn bản.\n"..enchantment.desc end
    if item.handId and Poker.SKILL_BOOKS[item.handId] and require("src.advanced_hands").byId[item.handId] and item.id and item.id:find("book_",1,true) then return Poker.SKILL_BOOKS[item.handId].desc end
    if item.permanentSpeed then return item.desc end
    local rule=Shop.CONSUMABLE_RULES[item.id] or Shop.CONSUMABLE_RULES[item.category]
    if item.handId and item.handId~="random" and item.handId~="all" then
        local scale=Poker.HAND_LEVEL_SCALING[item.handId];local stats=Poker.getHandStats(item.handId,1)
        local levels=rule and rule.params.levels or (item.id and item.id:match("^planet_") and Shop.CONSUMABLE_RULES.celestial.params.levels or 1)
        local name=item.handId
        for _,hand in ipairs(Poker.ALL_HANDS_ORDERED) do if hand.id==item.handId then name=hand.vnName;break end end
        if scale then return "Nâng thế đánh "..name.." +"..levels.." cấp: mỗi cấp +"..scale.chips.." ST và +"..scale.mult.." Cường hóa. Nền cấp 1: "..stats.chips.." × "..stats.mult.."; không tự mở khóa." end
    end
    if not rule then return nil end
    return rule.description:gsub("{([%w_]+)}",function(k) return tostring(rule.params[k] or 0) end)
end

Shop.STANDARD_CARDS = {}
for _, suit in ipairs({ "hearts", "diamonds", "clubs", "spades" }) do
    local suitInfo = Deck.SUITS[suit]
    for rank = 2, 14 do
        Shop.STANDARD_CARDS[#Shop.STANDARD_CARDS + 1] = {
            id = "standard_" .. suit .. "_" .. rank,
            name = (Deck.RANK_NAMES[rank] or tostring(rank)) .. (suitInfo.symbol or ""),
            rank = rank,
            rankName = Deck.RANK_NAMES[rank] or tostring(rank),
            suit = suitInfo.id,
            suitSymbol = suitInfo.symbol,
            color = suitInfo.color,
            baseChips = Deck.getChipValue(rank),
            desc = "Quân bài " .. (Deck.RANK_NAMES[rank] or tostring(rank)) .. (suitInfo.symbol or "") .. " có thể xuất hiện với một Cường Hóa.",
        }
    end
end

local function copyList(source)
    local result = {}
    for _, item in ipairs(source or {}) do result[#result + 1] = item end
    return result
end

function Shop.getPackContents(packType)
    if packType == "buffoon" then
        local result = {}
        for _, deity in pairs(Deities.CATALOG or {}) do result[#result + 1] = deity end
        table.sort(result, function(a, b) return a.name < b.name end)
        return result
    elseif packType == "arcana" then
        local result = {}
        for _, id in ipairs(Equipment.POOL or {}) do result[#result + 1] = Equipment.ITEMS[id] end
        return result
    elseif packType == "standard" then
        return copyList(Shop.STANDARD_CARDS)
    elseif packType == "joker_edition" then
        return copyList(Shop.JOKER_SPELLS)
    elseif packType == "seal" then
        return copyList(Shop.SEAL_CARDS)
    elseif packType == "spectral" then
        return copyList(Shop.SPECTRAL_CARDS)
    elseif packType == "celestial" then
        return copyList(Poker.PLANET_CARDS)
    elseif packType == "hand_styles" or packType == "hand_styles_advanced" then
        local result = {}
        for _, hand in ipairs(packType=="hand_styles_advanced" and Poker.ADVANCED_HANDS_ORDERED or Poker.HAND_TYPES_ORDERED) do
            local book = Poker.SKILL_BOOKS[hand.id]
            if hand.id == "high_card" then
                book = {
                    id = "book_high_card", handId = "high_card", name = "Bí Tịch: Kỵ Sĩ Tiên Phong",
                    handName = "KỴ SĨ TIÊN PHONG (Mậu Thầu)",
                    desc = "Thế đánh cơ bản; nhận Bí Tịch trùng để tăng cấp độ Kỵ Sĩ Tiên Phong.",
                    color = { 0.72, 0.78, 0.86, 1 },
                }
            end
            if book then result[#result + 1] = book end
        end
        return result
    elseif packType == "edition" then
        return CardEffects.getEditionCatalog()
    end
    return {}
end

function Shop.new()
    return {
        items = {},
        baseRerollCost = 5,
        rerollCost = 5,
        currentPackOpening = nil,
        lastPackTypes = {},
    }
end

function Shop.resetReroll(shop)
    if not shop then return end
    shop.baseRerollCost, shop.rerollCost = 5, 5
    shop.rerollCount = 0
    shop.welcomeRerollUsed = false
    shop.welcomeRerollsUsed = 0
end

function Shop.getRerollCost(shop, gameState)
    if Blood.isMode(shop.mode) then return (shop.mode=="blood_large" and 30 or 20)+10*(shop.rerollCount or 0) end
    if shop.soulMode then return 5 + 2 * (gameState.soulRerollCount or 0) end
    if (gameState.freeRerolls or 0) > 0
        or (shop.welcomeRerollsUsed or (shop.welcomeRerollUsed and 1 or 0)) < Shop.voucherParams("v_welcome",gameState).rolls then
        return 0
    end
    return math.max(1,(shop.rerollCost or 5)-Shop.voucherParams("v_discount",gameState).discount)
end

-- Reprice existing stock as well as future rerolls, without stacking discounts.
function Shop.applyVoucherStock(shop, gameState)
    if Blood.isMode(shop.mode) then return end
    local owned = gameState.vouchers or {}
    for _, item in ipairs(shop.items or {}) do
        if item.category == "pack" then
            item.baseCost = item.baseCost or item.cost
            item.cost = math.max(1, item.baseCost - (owned.v_pack_discount and Shop.voucherParams("v_pack_discount",gameState).discount or 0))
        end
    end
end

local function cloneDeity(deity)
    local clone = {}
    for key, value in pairs(deity or {}) do clone[key] = value end
    return clone
end

local function rollSpnRarity(game)
    local stage=game and game.run and game.run.ante or 1
    local total=0
    for _,r in ipairs(Deities.RARITIES) do
        if stage>=(Shop.SPN_STAGE_GATES[r.id] or 1) then total=total+(Shop.SPN_RARITY_WEIGHTS[r.id] or 0) end
    end
    local roll, cumulative = Rng.random()*total, 0
    for _, rarity in ipairs(Deities.RARITIES) do
        cumulative = cumulative + (stage>=(Shop.SPN_STAGE_GATES[rarity.id] or 1) and (Shop.SPN_RARITY_WEIGHTS[rarity.id] or 0) or 0)
        if roll < cumulative then return rarity end
    end
    return Deities.RARITIES[1]
end

Shop.rollSpnRarity=rollSpnRarity

local function randomStandardCard()
    local printed = Shop.STANDARD_CARDS[Rng.random(#Shop.STANDARD_CARDS)]
    return Deck.newCard(printed.rank, printed.suit)
end

local function appendPackItem(shop, pack)
    shop.items[#shop.items + 1] = {
        section = "lower_pack", category = "pack", packType = pack.packType,
        name = pack.name, subtitle = pack.subtitle, desc = pack.desc,
        cost = pack.cost, color = pack.color, icon = pack.icon,
    }
end

local RETAIL_CONSUMABLE_PACKS = {
    joker_edition="joker_spell", seal="seal", spectral="spectral",
    celestial="celestial", edition="edition",
}

function Shop.getRetailConsumables()
    local pool = {}
    for _, pack in ipairs(Shop.PACK_CATALOG) do
        local category = RETAIL_CONSUMABLE_PACKS[pack.packType]
        if category then
            for _, definition in ipairs(Shop.getPackContents(pack.packType)) do
                local card = cloneDeity(definition)
                card.category = category
                card.desc = Shop.getConsumableDescription(card)
                pool[#pool+1] = {id=card.id, category=category, consumable=card,
                    name=card.name, desc=card.desc, color=card.color, sourcePack=pack.packType,
                    cost=(definition.isEnchantment or category=="spectral") and definition.cost or math.ceil(pack.cost*1.2), subtitle=pack.name}
            end
        end
    end
    return pool
end

local function shuffle(pool)
    for i=#pool,2,-1 do local j=Rng.random(i);pool[i],pool[j]=pool[j],pool[i] end
    return pool
end

local function equipmentOffer(eq)
    return {id=eq.id, category="equipment", equipment=eq, backpack=true,
        name=eq.name, desc=eq.desc, cost=eq.cost, color=eq.color,
        subtitle=eq.basic and "NGUYÊN LIỆU CƠ BẢN" or "TRANG BỊ LỚN"}
end

Shop.CARD_SHOP_PRICES = {base=4, evolution=6, edition=8}

local function playingCardValue(card)
    local prices=Shop.CARD_SHOP_PRICES
    local value=prices.base+(card.evolutionLevel or 0)*prices.evolution
    for _,eq in ipairs(card.equipments or {}) do value=value+(eq.cost or 0) end
    if CardEffects.getDefinition(CardEffects.getEffectName(card)) then value=value+prices.edition end
    return value
end

function Shop.getCardSellPrice(card)
    return math.floor(Shop.getResaleBasis(card,"card")*.6)
end

function Shop.playingCardOffer(card)
    local level=card.evolutionLevel or 0
    local cost=playingCardValue(card)
    local labels={}
    local desc={"Thêm lá "..card.rankName..card.suitSymbol.." vào bộ bài, giữ nguyên mọi nâng cấp.",
        "Tiến hóa cấp "..level.." · "..require("src.card_abilities").description(card)}
    if level>0 then labels[#labels+1]="TIẾN HÓA "..level end
    for _,eq in ipairs(card.equipments or {}) do
        labels[#labels+1]="ĐỒ CƠ BẢN"
        desc[#desc+1]="Trang bị cơ bản đã gắn: "..eq.name.." — "..Equipment.getDescription(eq)
    end
    local edition=CardEffects.getDefinition(CardEffects.getEffectName(card))
    if edition then
        labels[#labels+1]="ẤN BẢN"
        desc[#desc+1]=edition.shopLabel.." — "..edition.shopText
    end
    return {id="standard_"..card.suit.."_"..card.rank, category="card", card=card,
        name=card.rankName..card.suitSymbol, cost=cost, desc=table.concat(desc,"\n"),
        subtitle=#labels>0 and table.concat(labels," · ") or "BẢN THƯỜNG",
        editionName=edition and edition.shopLabel, icon=card.suitSymbol, color=card.color}
end

-- Recipe fees are paid once; only raw materials use the retail multiplier.
function Shop.craftingCost(id)
    local eq=Equipment.ITEMS[id]
    if eq.basic then return math.ceil(eq.cost*Shop.PRICE_MULTIPLIER) end
    local recipe=require("src.basic_equipment").byResult[id]
    local cost=recipe.fee
    for _,ingredient in ipairs(recipe.ingredients) do cost=cost+Shop.craftingCost(ingredient) end
    return cost
end
function Shop.priceItem(item,game)
    if item.starterOffer then return 12 end
    if item.currency=="souls" then return math.ceil(item.cost*2) end
    if item.currency=="blood" then
        local price=math.ceil(item.cost*2)
        local c=item.consumable
        if c and c.category=="heal" then price=math.max(price,(c.healAmt or 25)+1) end
        if c and c.category=="bed" then price=math.max(price,(game and game.maxPlayerHp or 100)+1) end
        return price
    end
    local eq=item.equipment
    if eq and not eq.basic and not eq.soulOnly then
        local full=math.ceil(Shop.craftingCost(eq.id)*1.35)
        if item.free then return 0,full end
        return item.sale and math.max(1,math.floor(full*Shop.SALE_MULTIPLIER)) or full,item.originalCost and full
    end
    local multiplier=Shop.PRICE_MULTIPLIER
    if item.deity and Shop.SPN_STAGE_GATES[item.deity.rarity] then multiplier=6 end
    if item.consumable and item.consumable.category=="heal" then multiplier=3 end
    return math.ceil(item.cost*multiplier),item.originalCost and math.ceil(item.originalCost*multiplier)
end
-- Owned items carry catalog costs, not the final retail offer price.
local marketConsumables
function Shop.getMarketValue(item,kind)
    if not item then return 0 end
    local value
    if kind=="deity" or kind=="spn" then
        local rarity=Deities.RARITIES[Deities.getRarityTier(item)].id
        local base=Deities.CATALOG[item.id]
        local cost=math.ceil((base and base.cost or item.cost or 4)*(Shop.SPN_RARITY_PRICE_MULTIPLIERS[rarity] or 1))
        value=Shop.priceItem({cost=cost,deity={rarity=rarity}})
        value=value+(item.edition and 40 or 0)+(item.enchantment and 32 or 0)
    elseif kind=="equipment" then
        local eq=Equipment.ITEMS[item.id] or item
        value=eq.soulOnly and (eq.cost or 0)*2*3 or Shop.priceItem({cost=eq.cost,equipment=eq})
    elseif kind=="card" then
        value=Shop.priceItem(Shop.playingCardOffer(item))
        for _,eq in ipairs(item.equipments or {}) do
            value=value-(eq.cost or 0)*Shop.PRICE_MULTIPLIER+Shop.getMarketValue(eq,"equipment")
        end
        value=value+math.max(0,item.bonusBaseChips or 0)*.8+math.max(0,item.speedBonus or 0)*8
            +math.max(0,item.potionPermanentMult or 0)*12+math.max(0,Equipment.getMaxSlots(item)-4)*16
    else
        if not marketConsumables then
            marketConsumables={}
            for _,catalog in ipairs({Shop.POTIONS,Shop.getRetailConsumables(),Shop.SOUL_SUPPORT}) do
                for _,offer in ipairs(catalog) do marketConsumables[offer.id]=offer.cost end
            end
        end
        value=Shop.priceItem({cost=marketConsumables[item.id] or item.cost or 4,consumable=item})
    end
    return math.max(1,math.ceil(value*Blood.powerOf(item)))
end

function Shop.getResaleBasis(item,kind)
    local market=Shop.getMarketValue(item,kind)
    if kind=="card" then
        for _,eq in ipairs(item.equipments or {}) do
            if eq.acquisitionCost~=nil then
                local full=Shop.getMarketValue(eq,"equipment")
                market=market-math.max(0,full-eq.acquisitionCost)
            end
        end
        market=math.max(0,market)
    end
    if item.acquisitionCost==nil then return market end -- Older saves and earned loot.
    if item.acquisitionCost<=0 then return 0 end
    local upgrades=math.max(0,market-(item.acquisitionMarketValue or market))
    return math.min(market,item.acquisitionCost+upgrades)
end

local function purchaseReceipt(owned,offer,kind)
    owned.acquisitionCost=(offer.currency=="blood" or offer.currency=="souls") and 0 or offer.cost
    owned.acquisitionMarketValue=Shop.getMarketValue(owned,kind)
end

local function priceStock(shop,game)
    for _, item in ipairs(shop.items) do
        item.cost,item.originalCost=Shop.priceItem(item,game)
    end
end

local function finishStock(shop, gameState)
    if shop.mode=="small" and gameState.smallShopSwapped and shop.items[1].category=="deity" and shop.items[2].category=="equipment" then
        shop.items[1],shop.items[2]=shop.items[2],shop.items[1]
        shop.items[1].bay,shop.items[2].bay=1,2
    end
    if shop.mode=="small" and gameState.run and gameState.run.stats.blindsWon==1 and not gameState.run.stats.starterGearPurchased then
        local bay=shop.items[1].category=="equipment" and 1 or 2
        local offer=equipmentOffer(Equipment.ITEMS.gem_blast)
        offer.starterOffer=true;offer.section="stall";offer.bay=bay
        offer.subtitle="TIẾP TẾ · 1 LẦN/RUN"
        shop.items[bay]=offer
    end
    -- The card stall rolls all nine editions before calculating its price and labels.
    if shop.mode~="cards" then
        for _, item in ipairs(shop.items) do CardEffects.rollShopItem(item) end
    end
    priceStock(shop,gameState)
    Shop.applyVoucherStock(shop, gameState)
end

local function marketStock(shop, gameState)
    local mode = shop.mode
    if Blood.isMode(mode) then
        local retail=Shop.getRetailConsumables()
        for _,support in ipairs(Shop.SOUL_SUPPORT) do
            local c=require("src.run_manager")[support.factory]()
            retail[#retail+1]={id=c.id,category=c.category,consumable=c,name=c.name,desc=c.desc,cost=support.cost,color=c.color}
        end
        retail[#retail+1]=Shop.destructionItem("stall")
        local gear={};for id in pairs(Equipment.ITEMS) do gear[#gear+1]=id end;table.sort(gear)
        local vouchers={};for _,v in ipairs(Shop.VOUCHERS) do vouchers[#vouchers+1]=v end
        local packs={};for _,p in ipairs(Shop.PACK_CATALOG) do if p.packType~="hand_styles_advanced" or basicHandsUnlocked(gameState) then packs[#packs+1]=p end end
        local count=mode=="blood_large" and Blood.largeCount or Blood.smallCount
        for i=1,count do
            local kind=(i-1)%8+1;local offer
            if kind==1 then
                local d=Deities.getRandomShopPool(Loadout.ownedDeities(gameState),1)[1]
                if d then d=cloneDeity(d);Deities.setRarity(d,rollSpnRarity(gameState).id)
                    offer={id=d.id,category="deity",deity=d,name=d.name,cost=math.ceil((d.cost or 4)*(Shop.SPN_RARITY_PRICE_MULTIPLIERS[d.rarity] or 1)),color=d.color} end
            elseif kind==2 then offer=equipmentOffer(Equipment.ITEMS[gear[Rng.random(#gear)]])
            elseif kind==3 then offer=Shop.playingCardOffer(randomStandardCard())
            elseif kind==4 then
                local pool={};for _,p in ipairs(Shop.POTIONS) do if p.category~="bed" then pool[#pool+1]=p end end
                offer=Shop.healingItem("stall",pool[Rng.random(#pool)].id)
            elseif kind==5 and #vouchers>0 then
                local v=table.remove(vouchers,Rng.random(#vouchers))
                offer=Shop.voucherOffer(v,gameState,5)
            elseif kind==6 then
                offer=cloneDeity(packs[Rng.random(#packs)]);offer.category="pack"
            elseif kind==7 then offer=retail[Rng.random(#retail)]
            elseif kind==8 then offer={id="hand_expansion",category="hand_expansion",name="Túi Bài Huyết Luyện",cost=7,desc="Tăng kích thước tay bài thêm 5 lá.",color={.94,.32,.40,1}} end
            offer=offer or equipmentOffer(Equipment.ITEMS[gear[Rng.random(#gear)]])
            shop.items[i]=Blood.offer(offer)
        end
    elseif mode == "consumable" then
        local pool = shuffle(Shop.getRetailConsumables())
        for i=1,math.min(7,#pool) do shop.items[i]=pool[i] end
        local permit=require("src.expedition").travelPermit()
        shop.items[#shop.items+1]={id=permit.id,category=permit.category,consumable=permit,name=permit.name,
            desc=permit.desc,color=permit.color,cost=2000,subtitle="GIẤY TỜ VIỄN CHINH"}
    elseif mode == "equipment" then
        local basics = shuffle(copyList(require("src.basic_equipment").basic))
        for slot=1,4 do
            shop.items[#shop.items+1]=equipmentOffer(Equipment.ITEMS[basics[slot]])
        end
        local pool = {}
        for id,eq in pairs(Equipment.ITEMS) do
            if not eq.basic and not eq.soulOnly then pool[#pool+1]=id end
        end
        table.sort(pool);shuffle(pool)
        for i=1,math.min(4,#pool) do shop.items[#shop.items+1]=equipmentOffer(Equipment.ITEMS[pool[i]]) end
    elseif mode == "spn" then
        for _, definition in ipairs(Deities.getRandomShopPool(Loadout.ownedDeities(gameState), 6)) do
            local d = cloneDeity(definition)
            local rarity = rollSpnRarity(gameState)
            Deities.setRarity(d, rarity.id)
            d.cost=math.ceil((tonumber(d.cost) or 4)*Shop.SPN_RARITY_PRICE_MULTIPLIERS[rarity.id])
            shop.items[#shop.items+1]={id=d.id, category="deity", deity=d, name=d.name,
                desc=d.desc, cost=d.cost, rarity=rarity.id, color=rarity.color, subtitle=rarity.name}
        end
    elseif mode == "medicine" then
        for _, potion in ipairs(Shop.POTIONS) do shop.items[#shop.items+1]=Shop.healingItem("stall",potion.id) end
    elseif mode == "cards" then
        local pool=shuffle(copyList(Shop.STANDARD_CARDS))
        local basics=require("src.basic_equipment").basic
        local editions=CardEffects.getEditionCatalog()
        for i=1,8 do
            local printed=pool[i]
            local card=Deck.newCard(printed.rank,printed.suit)
            local evolution=Rng.random(100)
            card.evolutionLevel=evolution<=35 and 1 or evolution<=50 and 2 or 0
            if Rng.random()<.35 then
                -- Deliberately use the basic-only catalog, never the general equipment pool.
                Equipment.attach(card,cloneDeity(Equipment.ITEMS[basics[Rng.random(#basics)]]))
            end
            if Rng.random()<.30 then CardEffects.setEffect(card,editions[Rng.random(#editions)].edition) end
            shop.items[i]=Shop.playingCardOffer(card)
        end
    else
        return false
    end
    local medicineBays={1,2,5,6,7,8,3,9,10,11,13,14,15,12,16}
    for i,item in ipairs(shop.items) do
        item.section="stall";item.bay=mode=="medicine" and medicineBays[i] or i
    end
    finishStock(shop,gameState)
    return true
end

function Shop.rollSoulStock(gameState)
    local previous={}
    for _,id in ipairs(gameState.soulShopStock or {}) do previous[id]=true end
    local pool={}
    for _,id in ipairs(Equipment.SOUL_POOL) do if not previous[id] then pool[#pool+1]=id end end
    for i=#pool,2,-1 do local j=Rng.random(i);pool[i],pool[j]=pool[j],pool[i] end
    gameState.soulShopStock={}
    for i=1,5 do gameState.soulShopStock[i]=pool[i] end
end

function Shop.refresh(shop, gameState)
    shop.items = {}
    shop.page=1
    shop.mode = Shop.marketMode(gameState.shopMode)
    shop.soulMode = gameState.shopMode == "soul"
    shop.bloodMode = Blood.isMode(shop.mode)
    if shop.soulMode then
        if not gameState.soulShopStock then Shop.rollSoulStock(gameState) end
        shop.soulStock=gameState.soulShopStock
        for _, id in ipairs(shop.soulStock) do
            local eq = Equipment.ITEMS[id]
            if not (gameState.soulShopPurchased or {})[id] then
                shop.items[#shop.items+1] = {id=id,section="soul",category="equipment",equipment=eq,
                    name=eq.name,subtitle="DI VẬT LINH HỒN",desc=eq.desc,cost=eq.cost,currency="souls",color=eq.color}
            end
        end
        for _, offer in ipairs(Shop.SOUL_SUPPORT) do
            if not (gameState.soulShopPurchased or {})[offer.id] then
                local card = require("src.run_manager")[offer.factory]()
                shop.items[#shop.items+1] = {id=card.id,section="soul_support",category="soul_consumable",consumable=card,
                    name=card.name,desc=card.desc,cost=offer.cost,currency="souls",color=card.color}
            end
        end
        if not (gameState.soulShopPurchased or {}).soul_reaper then
            local utility = Shop.destructionItem("soul_utility")
            utility.currency = "souls"
            shop.items[#shop.items+1] = utility
        end
        priceStock(shop,gameState)
        return
    end

    if marketStock(shop, gameState) then return end

    ----------------------------------------------------------------------------
    -- 1. UPPER SECTION CARDS (Thần Hộ Mệnh, Trang Bị Khảm, Quân Bài Tuyển Mộ)
    ----------------------------------------------------------------------------
    -- A. Thần Hộ Mệnh (Deity / Joker equivalent)
    local availableDeities = Deities.getRandomShopPool(Loadout.ownedDeities(gameState), 1)
    if #availableDeities > 0 then
        local d = cloneDeity(availableDeities[1])
        local rarity = rollSpnRarity(gameState)
        Deities.setRarity(d, rarity.id)
        d.cost = math.ceil((tonumber(d.cost) or 4) * (Shop.SPN_RARITY_PRICE_MULTIPLIERS[rarity.id] or 1))
        local dColor = rarity.color or { 0.95, 0.85, 0.35, 1 }

        table.insert(shop.items, {
            section = "upper",
            category = "deity",
            deity = d,
            name = d.name,
            subtitle = "HỘ LINH",
            desc = d.desc or "+Hiệu ứng đặc biệt ván đấu",
            cost = d.cost or 5,
            rarity = d.rarity or "common",
            icon = "👑",
            color = dColor,
        })
    end

    -- B. Trang Bị Khảm (Gemstone / Weapon Equipment)
    local eq1 = Equipment.getRandomEquipment()
    table.insert(shop.items, {
        section = "upper",
        category = "equipment",
        equipment = eq1,
        backpack = true,
        name = eq1.name,
        subtitle = "TRANG BỊ KHẢM",
        desc = eq1.desc,
        cost = eq1.cost or 5,
        icon = eq1.icon or "💎",
        color = eq1.color or { 0.95, 0.75, 0.25, 1 },
    })

    -- C. Retail card: every rank and suit has an equal chance (52 total).
    local rewardCard = randomStandardCard()
    table.insert(shop.items, {
        section = "upper",
        category = "card",
        card = rewardCard,
        name = rewardCard.rankName .. rewardCard.suitSymbol,
        subtitle = "QUÂN BÀI",
        desc = "Thêm lá " .. rewardCard.rankName .. rewardCard.suitSymbol .. " (Chất " .. rewardCard.suitName .. ") vào bộ bài!",
        cost = 4,
        icon = rewardCard.suitSymbol,
        color = rewardCard.color,
    })

    -- D. Thẻ Mở Rộng Tay Bài: không giới hạn, giá tăng theo kích thước hiện tại.
    local curHandSize = (gameState and gameState.maxHandSize) or 3
    local expandCost = 12 + math.max(0, curHandSize - 3) * 6
    table.insert(shop.items, {
        id = "hand_expansion",
        voucherId = "v_hand_size",
        section = "upper",
        category = "hand_expansion",
        name = "Mở Rộng Tay Bài",
        subtitle = "TAY BÀI " .. curHandSize .. " → " .. (curHandSize + 1),
        desc = "Tăng vĩnh viễn +1 kích thước tay bài. Không giới hạn; giá tăng theo số lá đang cầm.",
        cost = expandCost,
        icon = "🎴",
        color = { 0.85, 0.45, 0.95, 1 },
    })

    local utilityRoll=Rng.random(#Shop.POTIONS+1)
    table.insert(shop.items,utilityRoll>#Shop.POTIONS and Shop.destructionItem("upper") or Shop.healingItem("upper",Shop.POTIONS[utilityRoll].id))

    ----------------------------------------------------------------------------
    -- 2. LOWER SECTION CARDS (Phiếu Ante / Voucher & Gói Bài Booster Packs)
    ----------------------------------------------------------------------------
    -- A. Left: permanent voucher. Hand unlocks now come from the hand-style chest.
    local v=Shop.VOUCHERS[Rng.random(#Shop.VOUCHERS)]
    local offer=Shop.voucherOffer(v,gameState)
    offer.section="lower_voucher"
    table.insert(shop.items,offer)

    -- B. Replace the hand-style chest once every hand is unlocked.
    local handChest
    for _, pack in ipairs(Shop.PACK_CATALOG) do
        if pack.packType == "hand_styles" then handChest = pack break end
    end
    local allUnlocked = basicHandsUnlocked(gameState)
    if allUnlocked then handChest = Shop.ADVANCED_HAND_CHEST end
    if handChest then appendPackItem(shop, handChest) end

    -- C. Three random chests, without same-shop duplicates or the two fixed chests.
    local recent = {}
    for _, packType in ipairs(shop.lastPackTypes or {}) do recent[packType] = true end
    local packCatalog = {}
    for _, pack in ipairs(Shop.PACK_CATALOG) do
        if pack.packType ~= "hand_styles" and pack.packType ~= "hand_styles_advanced" and pack.packType ~= "edition" and not recent[pack.packType] then
            table.insert(packCatalog, pack)
        end
    end
    if #packCatalog < 3 then
        for _, pack in ipairs(Shop.PACK_CATALOG) do
            if pack.packType ~= "hand_styles" and pack.packType ~= "hand_styles_advanced" and pack.packType ~= "edition" then
                table.insert(packCatalog, pack)
            end
        end
    end

    for i = #packCatalog, 2, -1 do
        local j = Rng.random(i)
        packCatalog[i], packCatalog[j] = packCatalog[j], packCatalog[i]
    end

    shop.lastPackTypes = {}
    for i = 1, math.min(3, #packCatalog) do
        local pack = packCatalog[i]
        shop.lastPackTypes[#shop.lastPackTypes + 1] = pack.packType
        appendPackItem(shop, pack)
    end

    -- D. The edition chest is a separate 25% roll, not part of the random trio.
    if Rng.random() < 0.25 then
        for _, pack in ipairs(Shop.PACK_CATALOG) do
            if pack.packType == "edition" then appendPackItem(shop, pack) break end
        end
    end

    -- Rotate the whole material pool without duplicates, including offensive components.
    local basics=shuffle(copyList(require("src.basic_equipment").basic))
    local chosen={[eq1.id]=true}
    for slot=1,4 do
        local eq=Equipment.ITEMS[basics[slot]];chosen[eq.id]=true
        shop.items[#shop.items+1]={section="basic",bay=slot,category="equipment",equipment=eq,
            name=eq.name,desc=eq.desc,color=eq.color,cost=eq.cost,originalCost=eq.cost,backpack=true,subtitle=eq.name}
    end
    local candidates={}
    for id,eq in pairs(Equipment.ITEMS) do if not eq.soulOnly and not chosen[id] then candidates[#candidates+1]=id end end
    table.sort(candidates) -- Stable pool order preserves seeded runs across processes.
    for bay=1,2 do
        local eq=Equipment.ITEMS[table.remove(candidates,Rng.random(#candidates))]
        shop.items[#shop.items+1]=Shop.discountedEquipment(eq,bay)
    end
    if shop.mode == "small" then
        local stock = {}
        for _,item in ipairs(shop.items) do
            if item.section == "upper" or item.category == "voucher" then
                stock[#stock+1]=item
            end
        end
        local packs={}
        for _,pack in ipairs(Shop.PACK_CATALOG) do
            if pack.packType=="hand_styles" and basicHandsUnlocked(gameState) then
                packs[#packs+1]=Shop.ADVANCED_HAND_CHEST
            else packs[#packs+1]=pack end
        end
        local chest={items={}}
        appendPackItem(chest,packs[Rng.random(#packs)])
        stock[#stock+1]=chest.items[1]
        local retail = Shop.getRetailConsumables()
        stock[#stock+1]=retail[Rng.random(#retail)]
        shop.items=stock
        for i,item in ipairs(shop.items) do item.section="stall";item.bay=i end
    end
    finishStock(shop,gameState)
end

function Shop.applyEdition(card, edition,power)
    local ok=CardEffects.setEffect(card, edition);if ok then card.editionPower=power end;return ok
end

function Shop.buyItem(shop, itemIndex, gameState)
    local item = shop.items[itemIndex]
    if not item then return false, "Vật phẩm không tồn tại!" end
    if item.packType == "hand_styles_advanced" and not basicHandsUnlocked(gameState) then
        return false, "Học đủ 9 thế đánh cơ bản để mở Rương Thế Đánh Nâng Cao."
    end
    if item.currency == "souls" then
        if not shop.soulMode or (gameState.souls or 0) < item.cost then
            return false, "Không đủ linh hồn!"
        end
        if item.category ~= "equipment" and not item.consumable then return false, "Không thể đổi vật phẩm này." end
        gameState.souls = gameState.souls - item.cost
        gameState.soulShopPurchased = gameState.soulShopPurchased or {}
        gameState.soulShopPurchased[item.id] = true
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        if item.category == "equipment" then
            local eq=Blood.clone(item.equipment);purchaseReceipt(eq,item,"equipment")
            return true, "open_socketing", eq
        end
        purchaseReceipt(item.consumable,item,"consumable")
        Loadout.storeConsumable(gameState,item.consumable)
        return true, "Đã cất "..item.name.." vào balo. Kéo lên ô trang bị để mang vào trận."
    end
    if item.category == "voucher" and not voucherParams[item.voucherId] then
        return false, "Đặc quyền không tồn tại!"
    end

    if item.currency=="blood" and not Blood.isMode(shop.mode) then return false,"Vật phẩm này chỉ đổi tại Shop Máu." end
    if not Shop.canAfford(item,gameState) then
        Sound.play("cant_afford")
        return false, item.currency=="blood" and "Cần đủ HP và giữ ít nhất 1 HP sau giao dịch." or "Không đủ tiền vàng!"
    end

    if item.consumable then
        Shop.payItem(item,gameState)
        purchaseReceipt(item.consumable,item,"consumable")
        Loadout.storeConsumable(gameState,item.consumable)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã cất "..item.name.." vào balo. Kéo lên ô trang bị để mang vào trận."
    end

    if item.category == "deity" then
        Shop.payItem(item,gameState)
        purchaseReceipt(item.deity,item,"deity")
        Loadout.storeDeity(gameState, item.deity)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã cất SPN " .. item.deity.name .. " vào balo."

    elseif item.category == "hand_expansion" then
        local curH = gameState.maxHandSize or 3
        Shop.payItem(item,gameState)
        gameState.maxHandSize = curH + Blood.powerOf(item)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã mở rộng kích thước tay bài lên tối đa " .. gameState.maxHandSize .. " lá!"

    elseif item.category == "book" then
        Shop.payItem(item,gameState)
        gameState.unlockedHands[item.handId] = true
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã mở khóa bí tịch: " .. item.name .. "!"

    elseif item.category == "voucher" then
        local power=Blood.powerOf(item)
        local p={};for k,v in pairs(voucherParams[item.voucherId]) do p[k]=v*power end
        local level=Shop.voucherLevel(item.voucherId,gameState)+1
        local totalPower=Shop.voucherPower(item.voucherId,gameState)+power
        local previousInterestCap=item.voucherId=="v_interest" and select(2,Shop.interest(gameState))
        Shop.payItem(item,gameState)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        gameState.vouchers = gameState.vouchers or {}
        gameState.vouchers[item.voucherId] = {level=level,power=totalPower}
        if item.voucherId == "v_interest" then
            gameState.maxInterest = previousInterestCap+p.cap
            gameState.hasSeedMoney = true
        elseif item.voucherId == "v_hand_plus" then
            gameState.maxHands = (gameState.maxHands or 4) + p.hands
            gameState.handsRemaining = (gameState.handsRemaining or 4) + p.hands
        elseif item.voucherId == "v_hand_size" then
            gameState.maxHandSize = (gameState.maxHandSize or 3) + 1
        elseif item.voucherId == "v_vitality" then
            gameState.maxPlayerHp = (gameState.maxPlayerHp or 100) + p.hp
            require("src.player_health").heal(gameState,p.hp)
        elseif item.voucherId == "v_apothecary" then
            require("src.player_health").heal(gameState,p.heal)
        elseif item.voucherId == "v_second_chance" then
            gameState.maxDiscards = (gameState.maxDiscards or 3) + p.discards
            gameState.discardsRemaining = (gameState.discardsRemaining or 0) + p.discards
        end
        Shop.applyVoucherStock(shop, gameState)
        return true, "Đã nhận " .. Shop.voucherName(item.voucherId,level) .. " · Hiệu lực suốt run!"

    elseif item.category == "equipment" then
        Shop.payItem(item,gameState)
        if item.starterOffer then gameState.run.stats.starterGearPurchased=true end
        local eq = item.equipment
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        if item.backpack then
            require("src.basic_equipment").store(gameState,eq,item.currency=="blood" and 0 or item.cost)
            return true,"Đã cất "..eq.name.." vào balo."
        end
        eq=Blood.clone(eq);purchaseReceipt(eq,item,"equipment")
        return true, "open_socketing", eq

    elseif item.category == "card" then
        Shop.payItem(item,gameState)
        purchaseReceipt(item.card,item,"card")
        Deck.addCardToDeck(gameState, item.card)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã thêm lá " .. item.card.rankName .. item.card.suitSymbol .. " vào bộ bài!"

    elseif item.category == "pack" then
        Shop.payItem(item,gameState)
        local pack = item
        table.remove(shop.items, itemIndex)
        Sound.play("pack_open")
        local packData = Shop.openPack(pack, gameState)
        shop.currentPackOpening = packData
        return true, "open_pack", packData

    elseif item.category == "heal" then
        if (gameState.playerHp or 100) >= (gameState.maxPlayerHp or 100) then
            Sound.play("cant_afford")
            return false, "Sinh lực đang đầy!"
        end
        Shop.payItem(item,gameState)
        local healVal = item.healAmt or 25
        require("src.player_health").heal(gameState,healVal)
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã hồi phục +" .. healVal .. " HP sinh lực!"

    elseif item.category == "consumable" then
        Shop.payItem(item,gameState)
        if item.apply then item.apply(gameState) end
        table.remove(shop.items, itemIndex)
        Sound.play("shop_buy")
        return true, "Đã kích hoạt Phù Chú Tiếp Lực!"
    end

    return false, "Vật phẩm không hợp lệ"
end

function Shop.openPack(packItem, gameState)
    local candidates = {}

    if packItem.packType == "buffoon" then
        for _, deity in ipairs(Deities.getRandomShopPool(Loadout.ownedDeities(gameState), 3)) do
            local reward = cloneDeity(deity)
            CardEffects.rollCard(reward)
            candidates[#candidates + 1] = reward
        end

    elseif packItem.packType == "standard" then
        local enhList = {}
        for id, enhancement in pairs(Deck.ENHANCEMENTS or {}) do
            if type(enhancement) == "table" and (enhancement.id or id) == id then
                table.insert(enhList, id)
            end
        end
        for i = 1, 3 do
            local c = randomStandardCard()
            if Rng.random(100) <= 70 then
                c.enhancement = enhList[Rng.random(#enhList)]
            end
            CardEffects.rollCard(c)
            table.insert(candidates, c)
        end

    elseif packItem.packType == "arcana" then
        local pool=copyList(packItem.rewardPack and require("src.basic_equipment").basic or Equipment.POOL)
        for i=#pool,2,-1 do local j=Rng.random(i);pool[i],pool[j]=pool[j],pool[i] end
        for i=1,math.min(3,#pool) do candidates[i]=Equipment.ITEMS[pool[i]] end

    elseif packItem.packType == "joker_edition" then
        local spells = copyList(Shop.JOKER_SPELLS)
        for i = #spells, 2, -1 do
            local j = Rng.random(i)
            spells[i], spells[j] = spells[j], spells[i]
        end
        for i = 1, 3 do table.insert(candidates, spells[i]) end

    elseif packItem.packType == "seal" then
        local seals = copyList(Shop.SEAL_CARDS)
        for i = #seals, 2, -1 do
            local j = Rng.random(i)
            seals[i], seals[j] = seals[j], seals[i]
        end
        for i = 1, 3 do table.insert(candidates, seals[i]) end

    elseif packItem.packType == "spectral" then
        local spectrals = copyList(Shop.SPECTRAL_CARDS)
        for i = #spectrals, 2, -1 do
            local j = Rng.random(i)
            spectrals[i], spectrals[j] = spectrals[j], spectrals[i]
        end
        for i = 1, 3 do table.insert(candidates, spectrals[i]) end

    elseif packItem.packType == "celestial" then
        local planets = {}
        for _, p in ipairs(Poker.PLANET_CARDS) do
            if not require("src.advanced_hands").byId[p.handId] or gameState.unlockedHands and gameState.unlockedHands[p.handId] then planets[#planets+1]=p end
        end
        for i = #planets, 2, -1 do
            local j = Rng.random(i)
            planets[i], planets[j] = planets[j], planets[i]
        end
        for i = 1, 3 do table.insert(candidates, planets[i]) end

    elseif packItem.packType == "hand_styles" or packItem.packType == "hand_styles_advanced" then
        local locked, unlocked = {}, {}
        for _, book in ipairs(Shop.getPackContents(packItem.packType)) do
            local pool = book.handId ~= "high_card" and not (gameState.unlockedHands and gameState.unlockedHands[book.handId]) and locked or unlocked
            pool[#pool + 1] = book
        end
        for _, pool in ipairs({locked, unlocked}) do
            for i = #pool, 2, -1 do local j = Rng.random(i); pool[i], pool[j] = pool[j], pool[i] end
            for _, book in ipairs(pool) do if #candidates < 3 then candidates[#candidates + 1] = book end end
        end

    elseif packItem.packType == "edition" then
        local editions=CardEffects.getEditionCatalog()
        for i=#editions,2,-1 do local j=Rng.random(i);editions[i],editions[j]=editions[j],editions[i] end
        for i=1,3 do candidates[i]=editions[i] end
    end

    if Blood.powerOf(packItem)>1 then for i,card in ipairs(candidates) do candidates[i]=Blood.reward(card) end end
    return {
        pack = packItem,
        cards = candidates,
        animationTimer = 0,
    }
end

function Shop.choosePackCard(shop, chosenIndex, gameState, targetDeity)
    if not shop.currentPackOpening then return false end
    local pack = shop.currentPackOpening.pack
    local card = shop.currentPackOpening.cards and shop.currentPackOpening.cards[chosenIndex]
    if not card then return false end
    local function received(fallback)
        if pack.rewardPack then
            require("src.reward_audio").play("collect",card,shop.rewardAudioPitch or 1)
        else Sound.play(fallback or "shop_buy") end
    end

    local function getTargetCard()
        if gameState.selectedIndices and #gameState.selectedIndices > 0 and gameState.hand and gameState.hand[gameState.selectedIndices[1]] then
            return gameState.hand[gameState.selectedIndices[1]]
        end
        if gameState.hand and #gameState.hand > 0 then
            return gameState.hand[1]
        end
        if gameState.persistentDeck and #gameState.persistentDeck > 0 then
            return gameState.persistentDeck[1]
        end
        return nil
    end

    local Enchantments=require("src.spn_enchantments")
    if Enchantments.get(card.id) then
        local ok,message,pending=Enchantments.apply(gameState,card,targetDeity)
        if ok then shop.currentPackOpening=nil;received() end
        return ok,message,pending
    end
    local Spectral=require("src.spectral")
    if Spectral.get(card.id) then
        local ok,message,pending=Spectral.apply(gameState,card,targetDeity)
        if ok then shop.currentPackOpening=nil;received() end
        return ok,message,pending
    end
    local expandedResult, expandedMessage = require("src.chest_expansion").apply(gameState, card, getTargetCard())
    if expandedResult ~= nil then
        if expandedResult then shop.currentPackOpening=nil;received() end
        return expandedResult, expandedMessage
    end

    if pack.packType == "buffoon" then
        Loadout.storeDeity(gameState, card)
        received()
        shop.currentPackOpening = nil
        return true, "Đã chiêu mộ: " .. card.name .. "!"

    elseif pack.packType == "standard" then
        Deck.addCardToDeck(gameState, card)
        received()
        shop.currentPackOpening = nil
        return true, "Đã thêm lá " .. card.rankName .. card.suitSymbol .. " vào bộ bài!"

    elseif pack.packType == "arcana" then
        received()
        shop.currentPackOpening = nil
        return true, "open_socketing", card

    elseif pack.packType == "joker_edition" then
        return false,"Phù phép không hợp lệ."

    elseif pack.packType == "seal" then
        local targetCard = getTargetCard()
        if not targetCard then
            Sound.play("cant_afford")
            return false, "Không tìm thấy lá bài để đóng dấu!"
        end
        if not Deck.applySeal(gameState,targetCard,card.sealType or card.id,card.bloodPower) then return false,"Con dấu không hợp lệ." end
        received()
        shop.currentPackOpening = nil
        return true, "Đã đóng ấn [" .. (card.sealName or card.subtitle or card.name) .. "] lên lá " .. (targetCard.rankName or "") .. (targetCard.suitSymbol or "") .. "!"

    elseif pack.packType == "spectral" then
        return false,"Dị Thể không hợp lệ."

    elseif pack.packType == "celestial" then
        gameState.handLevels = gameState.handLevels or {}
        if card.handId == "random" or card.id == "planet_supernova" or card.id == "supernova" then
            local allHands = {}
            for _, ht in pairs(Poker.HAND_TYPES) do table.insert(allHands, ht) end
            local h = allHands[Rng.random(#allHands)]
            gameState.handLevels[h.id] = (gameState.handLevels[h.id] or 1) + 3*Blood.powerOf(card)
            received("round_win")
            shop.currentPackOpening = nil
            return true, "Siêu Tân Tinh: Nâng cấp " .. h.vnName .. " lên +3 Cấp (Cấp " .. gameState.handLevels[h.id] .. ")!"
        elseif card.handId == "all" or card.id == "planet_black_hole" or card.id == "black_hole" then
            for _, ht in pairs(Poker.HAND_TYPES) do
                gameState.handLevels[ht.id] = (gameState.handLevels[ht.id] or 1) + 2*Blood.powerOf(card)
            end
            received("xmult_boom")
            shop.currentPackOpening = nil
            return true, "Hố Đen: Nâng cấp TẤT CẢ các thế bài Poker lên +2 Cấp độ!"
        elseif card.handId then
            gameState.handLevels[card.handId] = (gameState.handLevels[card.handId] or 1) + 2*Blood.powerOf(card)
            local hType = nil
            for _, ht in pairs(Poker.HAND_TYPES) do if ht.id == card.handId then hType = ht break end end
            local vName = hType and hType.vnName or card.name
            received("round_win")
            shop.currentPackOpening = nil
            return true, "Đã nâng cấp thế bài " .. vName .. " lên Cấp " .. gameState.handLevels[card.handId] .. "!"
        end

    elseif pack.packType == "hand_styles" or pack.packType == "hand_styles_advanced" then
        gameState.unlockedHands = gameState.unlockedHands or {}
        gameState.handLevels = gameState.handLevels or {}
        local handId = card.handId
        if not handId then return false, "Bí Tịch không hợp lệ!" end
        if gameState.unlockedHands[handId] then
            gameState.handLevels[handId] = (gameState.handLevels[handId] or 1) + Blood.powerOf(card)
            shop.currentPackOpening = nil
            received("round_win")
            return true, "Thế đánh " .. (card.handName or card.name) .. " tăng lên Cấp " .. gameState.handLevels[handId] .. "!"
        end
        gameState.unlockedHands[handId] = true
        gameState.handLevels[handId] = math.max(1, gameState.handLevels[handId] or 1)
        shop.currentPackOpening = nil
        received()
        return true, "Đã mở khóa thế đánh: " .. (card.handName or card.name) .. "!"

    elseif pack.packType == "edition" then
        local targetCard = gameState.selectedIndices and gameState.hand
            and gameState.hand[gameState.selectedIndices[1]]
        if not targetCard then
            Sound.play("cant_afford")
            return false, "Hãy chọn một lá bài trước, hoặc cất Ấn Bản vào balo."
        end
        Shop.applyEdition(targetCard, card.edition,card.bloodPower)
        for _, pile in ipairs({ gameState.persistentDeck or {}, gameState.hand or {}, gameState.deck or {}, gameState.discardPile or {} }) do
            for _, copy in ipairs(pile) do
                if copy and targetCard.id and copy.id == targetCard.id then Shop.applyEdition(copy, card.edition,card.bloodPower) end
            end
        end
        shop.currentPackOpening = nil
        received("round_win")
        return true, targetCard.rankName .. (targetCard.suitSymbol or "") .. " nhận " .. card.name .. "!"
    end

    shop.currentPackOpening = nil
    return true
end

function Shop.keepPackCard(shop, chosenIndex, gameState)
    if not shop.currentPackOpening then return false, "Không có gói bài nào đang mở!" end
    local pack = shop.currentPackOpening.pack
    local card = shop.currentPackOpening.cards and shop.currentPackOpening.cards[chosenIndex]
    if not card then return false, "Lá bài không hợp lệ!" end

    local validPacks = {
        joker_edition = "joker_spell",
        seal = "seal",
        spectral = "spectral",
        celestial = "celestial",
        edition = "edition",
    }
    local cat = validPacks[pack.packType]
    if not cat then
        return false, "Chỉ có thể cất giữ Thẻ Phép, Hành Tinh và Ấn Bản vào balo!"
    end

    local storedCard = {}
    for k, v in pairs(card) do storedCard[k] = v end
    storedCard.category = cat
    require("src.spn_enchantments").migrateItem(storedCard)

    Loadout.storeConsumable(gameState,storedCard)
    if pack.rewardPack then require("src.reward_audio").play("collect",card,shop.rewardAudioPitch or 1)
    else Sound.play("shop_buy") end
    shop.currentPackOpening = nil
    return true, "Đã cất [" .. (storedCard.name or "Thẻ Phép") .. "] vào balo!"
end

function Shop.getPackExchangeGold(opening)
    local pack = opening and opening.pack
    if not pack then return 0 end
    local price
    for _, entry in ipairs(Shop.PACK_CATALOG) do
        if entry.packType == pack.packType then price = entry.cost; break end
    end
    return math.max(1, math.floor(((pack.rewardPack and price) or pack.cost or price or 4) / 2))
end

function Shop.getChestExchangeGold(rewards)
    local price = 0
    for _, reward in ipairs(rewards or {}) do
        local item = reward.card or reward.item
        if item then price = math.max(price, item.cost or 4) end
    end
    return price > 0 and math.max(1, math.floor(price / 2)) or 0
end

function Shop.exchangeChest(rewards, gameState)
    if not rewards or rewards.resolved or #rewards == 0 then return false, 0 end
    local gold = Shop.getChestExchangeGold(rewards)
    rewards.resolved = true
    gameState.gold = (gameState.gold or 0) + gold
    Sound.play("sell")
    return true, gold
end

-- The opening stores its receipt so a queued/saved reward cannot pay twice.
function Shop.skipPack(shop, gameState)
    local opening = shop.currentPackOpening
    if not opening or not gameState then return false, 0 end
    local gold = 0
    if not opening.exchangedGold then
        gold = Shop.getPackExchangeGold(opening)
        opening.exchangedGold = gold
        gameState.gold = (gameState.gold or 0) + gold
    end
    shop.currentPackOpening = nil
    Sound.play("sell")
    return true, gold
end

function Shop.reroll(shop, gameState, refresh)
    local function refreshShop(s,g)
        if s.mode=="small" then g.smallShopSwapped=not g.smallShopSwapped end
        (refresh or Shop.refresh)(s,g)
    end
    if Blood.isMode(shop.mode) then
        local cost=Shop.getRerollCost(shop,gameState)
        if not Shop.canAfford({cost=cost,currency="blood"},gameState) then return false,"Đổi hàng cần "..cost.." HP và phải giữ lại 1 HP." end
        Shop.payItem({cost=cost,currency="blood"},gameState)
        shop.rerollCount=(shop.rerollCount or 0)+1
        refreshShop(shop,gameState);Sound.play("shop_reroll");return true
    end
    if shop.soulMode then
        local cost=Shop.getRerollCost(shop,gameState)
        if (gameState.souls or 0)<cost then return false,"Không đủ linh hồn để đổi hàng!" end
        gameState.souls=gameState.souls-cost
        gameState.soulRerollCount=(gameState.soulRerollCount or 0)+1
        Shop.rollSoulStock(gameState)
        gameState.soulShopPurchased={}
        refreshShop(shop,gameState)
        Sound.play("shop_reroll")
        return true
    end
    if gameState and (gameState.freeRerolls or 0) > 0 then
        gameState.freeRerolls = gameState.freeRerolls - 1
        refreshShop(shop, gameState)
        Sound.play("shop_reroll")
        return true
    end
    if (shop.welcomeRerollsUsed or (shop.welcomeRerollUsed and 1 or 0)) < Shop.voucherParams("v_welcome",gameState).rolls then
        shop.welcomeRerollsUsed=(shop.welcomeRerollsUsed or (shop.welcomeRerollUsed and 1 or 0))+1
        shop.welcomeRerollUsed = true
        refreshShop(shop, gameState)
        Sound.play("shop_reroll")
        return true
    end
    local cost = Shop.getRerollCost(shop, gameState)
    if (gameState.gold or 0) < cost then
        Sound.play("cant_afford")
        return false, "Không đủ tiền làm mới!"
    end
    gameState.gold = gameState.gold - cost
    shop.rerollCount = (shop.rerollCount or 0) + 1
    shop.rerollCost = (shop.rerollCost or 5) + 1 + shop.rerollCount
    refreshShop(shop, gameState)
    Sound.play("shop_reroll")
    return true
end

function Shop.getSacrificePrice(item, kind, gameState)
    if kind == "deity" or kind == "consumable" then
        return math.floor(Shop.getResaleBasis(item or {},kind)*.6)
    elseif kind == "card" then
        return math.max(1, math.floor(((item and item.sellValue) or 1)))
    end
    return 0
end

function Shop.sellConsumable(gameState, consumableIndex)
    local item = gameState.consumables and gameState.consumables[consumableIndex]
    if not item then return false end
    local price = Shop.getSacrificePrice(item, "consumable", gameState)
    table.remove(gameState.consumables, consumableIndex)
    if require("src.void_tickets").isTicket(item) then require("src.void_tickets").count(gameState) end
    gameState.gold = (gameState.gold or 0) + price
    Sound.play("sell")
    return true, price
end

function Shop.sellStoredItem(gameState,kind,index)
    local list=gameState[kind=="reserve_deity" and "backpackDeities" or "backpackConsumables"]
    local item=list and list[index]
    if not item then return false,"Món đồ không còn trong balo." end
    local price=Shop.getSacrificePrice(item,kind=="reserve_deity" and "deity" or "consumable",gameState)
    table.remove(list,index);gameState.gold=(gameState.gold or 0)+price
    if require("src.void_tickets").isTicket(item) then require("src.void_tickets").count(gameState) end
    Sound.play("sell");return true,price
end

function Shop.sellCard(gameState, targetCard)
    if not gameState or gameState.shopMode~="cards" then
        return false, "Chỉ Shop quân bài thu mua quân bài."
    end
    local deck=gameState.persistentDeck or {}
    local targetId=type(targetCard)=="table" and targetCard.id or targetCard
    local index
    for i,card in ipairs(deck) do
        if card==targetCard or (targetId~=nil and card.id==targetId) then index=i;targetCard=card;break end
    end
    if not index then return false, "Lá bài không còn trong bộ bài." end
    if #deck<=1 then return false, "Bộ bài phải còn ít nhất 1 lá." end
    local price=Shop.getCardSellPrice(targetCard)
    table.remove(deck,index)
    for _,name in ipairs({"hand","deck","discardPile"}) do
        local pile=gameState[name] or {}
        for i=#pile,1,-1 do
            if pile[i]==targetCard or (targetCard.id~=nil and pile[i].id==targetCard.id) then table.remove(pile,i) end
        end
    end
    gameState.masterDeck=deck
    gameState.selectedIndices={}
    for i,card in ipairs(gameState.hand or {}) do if card.selected then table.insert(gameState.selectedIndices,i) end end
    gameState.gold=(gameState.gold or 0)+price
    Sound.play("sell")
    return true,price
end

function Shop.destructionItem(section)
    local item = {id="soul_reaper",section=section,category="destroy",cost=4,name="Lá Tiêu Hủy",
        subtitle="NGHI LỄ LINH HỒN",color={0.69,0.42,0.96,1},
        desc="Tiêu hao một lần trong shop: chọn quân bài rồi xác nhận tiêu hủy để nhận linh hồn. Tại chợ linh hồn: thưởng x2 linh hồn, hồi 10 HP và +5 Vàng. Giữ ít nhất 1 lá; hủy chọn không mất thẻ."}
    item.consumable={id=item.id,category=item.category,name=item.name,desc=item.desc,color=item.color}
    return item
end

Shop.POTIONS={
    {id="healing_potion",name="Bình Máu",cost=4,healAmt=25},
    {id="healing_potion_large",name="Bình Máu Lớn",cost=7,healAmt=60},
    {id="armor_potion_small",name="Bình Giáp Nhỏ",cost=3,armorAmt=8},
    {id="armor_potion_large",name="Bình Giáp Lớn",cost=6,armorAmt=20},
    {id="cons_speed_small",name="Tốc Đánh Nhỏ",cost=3,speed=3,category="speed_single"},
    {id="cons_speed_large",name="Tốc Đánh Lớn",cost=8,speed=10,category="speed_single"},
    {id="cons_bed",name="Cái Giường",cost=9,category="bed",desc="Tiêu hao: hồi 100% HP tối đa. Trong trận, chọn bản thân (bỏ một lượt để ngủ) hoặc một quái để đặt giường. Quái nhận sát thương mà sống sẽ dùng giường hồi đầy HP."},
}
for _,def in ipairs(require("src.potions").definitions) do Shop.POTIONS[#Shop.POTIONS+1]=def end
function Shop.healingItem(section,id)
    local def=Shop.POTIONS[1]
    for _,potion in ipairs(Shop.POTIONS) do if potion.id==id then def=potion;break end end
    local item={id=def.id,section=section,category=def.category or (def.healAmt and "heal" or "armor_potion"),cost=def.cost,name=def.name,
        color=def.color or (def.healAmt and {0.35,0.9,0.6,1} or {.4,.7,1,1}),
        desc=def.desc or (def.speed and Shop.getConsumableDescription(def)) or (def.healAmt and ("Tiêu hao một lần: hồi "..def.healAmt.." HP, không vượt sinh lực tối đa.")
            or ("Tiêu hao một lần: tăng "..def.armorAmt.." giáp hiện tại, tối đa "..require("config.card_ability_data").armorCap.." giáp. Dùng trong trận để giữ giáp."))}
    item.subtitle=def.healAmt and ("HỒI "..def.healAmt.." HP") or def.armorAmt and ("+"..def.armorAmt.." GIÁP")
        or def.speed and ("+"..def.speed.." TỐC · 1 TRẬN")
        or ({accuracy="TRÚNG 100% · 1 LƯỢT",evasion="NÉ ĐÒN · 1 LƯỢT",armor_break="PHÁ TOÀN BỘ GIÁP",
            damage="+20 ST / LÁ · 1 LƯỢT",empower="+5 CH / LÁ · 1 LƯỢT",gold_blood="1 HP = 1 VÀNG",
            draw="RÚT NGAY 5 LÁ",slow="-50% TỐC · 2 HÀNH ĐỘNG"})[def.kind]
        or "HỒI ĐẦY HP · NGỦ"
    item.consumable={id=item.id,category=item.category,name=item.name,desc=item.desc,color=item.color,healAmt=def.healAmt,armorAmt=def.armorAmt}
    return item
end

function Shop.activateDestruction(gameState, consumable)
    for _,card in ipairs(gameState.consumables or {}) do
        if card==consumable and card.id=="soul_reaper" then
            gameState.soulDestroyActive=true
            gameState.soulDestroyConsumable=card
            return true
        end
    end
    return false
end

function Shop.getSoulValue(card)
    return Souls.value(card)
end

function Shop.getDestructionRewards(gameState, card)
    local soulMarket=gameState.shopMode=="soul"
    local heal=soulMarket and 10 or 0
    return {souls=Souls.value(card)*(soulMarket and 2 or 1), multiplier=soulMarket and 2 or 1,
        heal=heal, gold=soulMarket and 5 or 0}
end

function Shop.enterSoulShop(gameState)
    if gameState.pendingSoulShop then
        gameState.shopMode = "soul"
        gameState.pendingSoulShop = false
        gameState.soulShopPurchased = {}
        gameState.soulRerollCount = 0
        gameState.soulShopStock = nil
        return true
    end
    return false
end

function Shop.enterAfterCombat(gameState)
    gameState.smallShopSwapped=false
    gameState.pendingCompanionShop=nil
    if gameState.run and gameState.run.stats.blindsWon==1 then
        gameState.shopMode="small"
        gameState.pendingCompanionShop=Shop.AFTER_COMBAT_MARKETS[Rng.random(2,#Shop.AFTER_COMBAT_MARKETS)]
        return
    end
    if gameState.bloodDomain then
        gameState.shopMode="small";gameState.pendingSoulShop=false
        gameState.pendingCompanionShop=Shop.AFTER_COMBAT_MARKETS[Rng.random(2,#Shop.AFTER_COMBAT_MARKETS)]
        return
    end
    gameState.bloodShopNotice=nil
    local blood=Blood.roll(gameState)
    if require("src.barter").roll(gameState) then gameState.pendingBarter=true end
    if require("src.ancient_statue").roll(gameState) then gameState.pendingAncientStatue=true end
    if Shop.enterSoulShop(gameState) then gameState.pendingBloodShop=blood or gameState.pendingBloodShop
    else
        gameState.shopMode="small"
        gameState.pendingCompanionShop=blood or Shop.AFTER_COMBAT_MARKETS[Rng.random(2,#Shop.AFTER_COMBAT_MARKETS)]
    end
    gameState.soulDestroyActive=false
    gameState.soulDestroyConsumable=nil
end

function Shop.leave(shop, gameState)
    gameState.soulDestroyActive=false
    gameState.soulDestroyConsumable=nil
    if gameState.shopMode == "soul" then
        gameState.shopMode="large"
        Shop.resetReroll(shop)
        Shop.refresh(shop,gameState)
        return "shop"
    end
    if gameState.shopMode=="small" and gameState.pendingCompanionShop then
        gameState.shopMode=gameState.pendingCompanionShop;gameState.pendingCompanionShop=nil
        Shop.resetReroll(shop);Shop.refresh(shop,gameState);return "shop"
    end
    if gameState.shopMode=="large" and gameState.pendingBloodShop then
        gameState.shopMode=gameState.pendingBloodShop;gameState.pendingBloodShop=nil
        Shop.resetReroll(shop);Shop.refresh(shop,gameState);return "shop"
    end
    gameState.shopMode="normal";gameState.bloodShopNotice=nil
    if gameState.pendingBarter then
        gameState.pendingBarter=nil;require("src.barter").create(gameState)
        return "barter"
    end
    return "advance"
end

function Shop.destroyCard(gameState, targetCard)
    if not gameState.soulDestroyActive then return false, "Kích hoạt Lá Tiêu Hủy trước." end
    local consumableIndex
    for i,card in ipairs(gameState.consumables or {}) do
        if card==gameState.soulDestroyConsumable and card.id=="soul_reaper" then consumableIndex=i;break end
    end
    if not consumableIndex then return false, "Cần một Lá Tiêu Hủy trong ô tiêu hao." end
    local deck = gameState.persistentDeck or {}
    local targetId = type(targetCard) == "table" and targetCard.id or targetCard
    local deckIndex
    for i, card in ipairs(deck) do
        if card == targetCard or (targetId ~= nil and card.id == targetId) then
            deckIndex = i
            targetCard = card
            break
        end
    end
    if not deckIndex or #deck <= 1 then
        return false, "Bộ bài phải còn ít nhất 1 lá."
    end

    if targetCard.soulAwarded or (gameState.soulDestroyedIds or {})[tostring(targetCard.id)] then
        return false, "Lá này đã nhận thưởng tiêu hủy."
    end
    local rewards = Shop.getDestructionRewards(gameState,targetCard)
    local price = rewards.souls
    local cardId = targetCard.id
    table.remove(deck, deckIndex)
    for _, pileName in ipairs({ "hand", "deck", "discardPile" }) do
        local pile = gameState[pileName]
        if pile then
            for i = #pile, 1, -1 do
                local card = pile[i]
                if card == targetCard or (cardId ~= nil and card.id == cardId) then
                    table.remove(pile, i)
                end
            end
        end
    end
    Souls.award(gameState, targetCard, rewards.multiplier)
    require("src.player_health").heal(gameState,rewards.heal)
    gameState.gold = (gameState.gold or 0)+rewards.gold
    gameState.soulDestroyActive = false
    table.remove(gameState.consumables, consumableIndex)
    gameState.soulDestroyConsumable = nil
    require("src.card_abilities").consumableUsed(gameState)
    gameState.masterDeck = deck
    targetCard.destroyed = true
    gameState.selectedIndices = {}
    for i, card in ipairs(gameState.hand or {}) do
        if card.selected then table.insert(gameState.selectedIndices, i) end
    end
    Sound.play("card_destroy")
    return true, price, rewards
end

function Shop.sellDeity(gameState, deityIndex)
    local d = gameState.deities and gameState.deities[deityIndex]
    if not d then return false end
    local sellPrice = Shop.getSacrificePrice(d, "deity", gameState)
    gameState.gold = (gameState.gold or 0) + sellPrice
    gameState.deities[deityIndex] = nil
    Sound.play("sell")
    return true
end

function Shop.transferEquipment(sourceCard, eqIndex, targetCard)
    if not sourceCard or not targetCard then return false, "Chưa chọn đủ bài nguồn và đích!" end
    if sourceCard == targetCard then return false, "Không thể chuyển vào cùng một lá bài!" end
    if not sourceCard.equipments or not sourceCard.equipments[eqIndex] then
        return false, "Trang bị không tồn tại!"
    end
    local eq = sourceCard.equipments[eqIndex]
    local canOk, canErr = Equipment.canAttach(targetCard, eq)
    if not canOk then
        return false, canErr
    end

    table.remove(sourceCard.equipments, eqIndex)
    targetCard.equipments = targetCard.equipments or {}
    table.insert(targetCard.equipments, eq)
    Sound.play("card_slide",0.92)
    return true, "Đã chuyển [" .. eq.name .. "] sang Lá " .. (targetCard.rankName or "") .. (targetCard.suitSymbol or "") .. "!"
end

return Shop

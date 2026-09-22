local Equipment = require("src.equipment")
local Poker = require("src.poker")
local Deck = require("src.deck")
local Rng = require("src.rng")

local Events = {}

Events.LIST = {
    {
        id = "spring",
        title = "💧 SUỐI THÁNH CỔ ĐẠI 💧",
        subtitle = "Nguồn năng lượng thanh khiết tuôn chảy giữa vùng hoang dã.",
        desc = "Trước mắt bạn là một dòng suối phát ra ánh sáng lung linh huyền ảo. Dòng nước dường như có khả năng gột rửa mệt mỏi và củng cố tinh thần cho các ván bài sắp tới.",
        options = {
            {
                title = "Uống Nước Suối Thánh",
                desc = "Tăng vĩnh viễn +1 Lượt Đánh (Hands) và +1 Lượt Đổi bài (Discards)!",
                action = function(gameState)
                    gameState.maxHands = gameState.maxHands + 1
                    gameState.handsRemaining = gameState.handsRemaining + 1
                    gameState.maxDiscards = gameState.maxDiscards + 1
                    gameState.discardsRemaining = gameState.discardsRemaining + 1
                    return "Bạn cảm thấy sinh lực dâng trào: +1 Lượt Đánh & +1 Lượt Đổi bài vĩnh viễn!"
                end,
            },
            {
                title = "Thanh Tẩy Thẻ Bài",
                desc = "Cường hóa +20 Chips vĩnh viễn cho 3 lá bài ngẫu nhiên trong bộ bài!",
                action = function(gameState)
                    local targetDeck = (gameState.persistentDeck and #gameState.persistentDeck > 0) and gameState.persistentDeck or gameState.deck
                    local buffed = 0
                    for _, c in ipairs(targetDeck) do
                        c.baseChips = c.baseChips + 20
                        buffed = buffed + 1
                        if buffed >= 3 then break end
                    end
                    return "3 lá bài trong bộ bài đã được gột rửa và nhận thêm +20 Chips vĩnh viễn!"
                end,
            },
            {
                title = "Vớt Vàng Dưới Đáy Suối",
                desc = "Lấy những đồng tiền vàng cổ xưa lấp lánh dưới đáy suối (+$10 Vàng).",
                action = function(gameState)
                    gameState.gold = gameState.gold + 10
                    return "Bạn đã vớt được một bọc tiền vàng cổ: +$10 Vàng!"
                end,
            },
        },
    },
    {
        id = "forge",
        title = "🔥 LÒ RÈN THẦN BÍ 🔥",
        subtitle = "Tiếng đe búa vang vọng từ một hầm rèn cổ xưa ngập tràn đốm lửa.",
        desc = "Một thợ rèn người lùn phủ đầy tàn tro nhìn bạn với ánh mắt tò mò. Ông ta gõ mạnh cây búa thép xuống đe và chỉ vào những món trang bị lấp lánh trên giá đỡ.",
        options = {
            {
                title = "Nhận 1 Trang Bị Miễn Phí",
                desc = "Thợ rèn tặng bạn 1 món trang bị vũ khí ngẫu nhiên để gắn vào bài!",
                action = function(gameState)
                    local eq = Equipment.getRandomEquipment()
                    return "Nhận được trang bị: " .. eq.name .. " (" .. eq.desc .. ")!", eq
                end,
                hasEquipmentReward = true,
            },
            {
                title = "Tôi Luyện Bộ Bài",
                desc = "Thợ rèn gia cố +15 Chips cho tất cả lá bài đang có trên tay bạn!",
                action = function(gameState)
                    for _, c in ipairs(gameState.hand) do
                        c.baseChips = c.baseChips + 15
                    end
                    return "Tất cả các lá bài trên tay bạn đã được tôi luyện: +15 Chips!"
                end,
            },
            {
                title = "Thu Nhặt Phế Liệu Lò Rèn",
                desc = "Giúp dọn dẹp lò rèn và nhận thù lao (+$8 Vàng).",
                action = function(gameState)
                    gameState.gold = gameState.gold + 8
                    return "Thợ rèn cảm ơn sự giúp đỡ của bạn: +$8 Vàng!"
                end,
            },
        },
    },
    {
        id = "shrine",
        title = "📖 ĐỀN THỜ BÍ TỊCH CỔ 📖",
        subtitle = "Một ngôi miếu cổ khắc những ký tự võ đạo poker đã thất truyền.",
        desc = "Giữa ngôi đền là một án thư bằng ngọc thạch. Trên đó đặt các pho cổ thư ghi lại các thế bài và thế trận huyền bí của giới bài vương ngày xưa.",
        options = {
            {
                title = "Cầu Nguyện Giác Ngộ Bí Tịch",
                desc = "Mở khóa NGẪU NHIÊN 1 tay bài mà bạn chưa sở hữu!",
                action = function(gameState)
                    local lockedKeys = {}
                    for k, b in pairs(Poker.SKILL_BOOKS) do
                        if not gameState.unlockedHands[k] then
                            table.insert(lockedKeys, k)
                        end
                    end
                    if #lockedKeys > 0 then
                        local chosenKey = lockedKeys[Rng.random(#lockedKeys)]
                        gameState.unlockedHands[chosenKey] = true
                        local book = Poker.SKILL_BOOKS[chosenKey]
                        return "Ánh sáng khai mở tâm trí! Bạn đã mở khóa: " .. book.handName .. "!"
                    else
                        gameState.gold = gameState.gold + 12
                        return "Bạn đã lĩnh hội toàn bộ bí kịch! Đền thờ ban tặng: +$12 Vàng!"
                    end
                end,
            },
            {
                title = "Thỉnh 1 Lá Bài Ngoại Lai Hiếm",
                desc = "Nhận 1 lá bài chất khác với chỉ số cao vào thẳng bộ bài!",
                action = function(gameState)
                    local rew = Deck.createRewardCard(gameState.selectedSuit)
                    Deck.addCardToDeck(gameState, rew)
                    return "Nhận được lá bài hiếm: " .. rew.rankName .. " " .. rew.suitName .. " (+ " .. rew.baseChips .. " Chips)!"
                end,
            },
            {
                title = "Rút Tiền Công Đức",
                desc = "Lấy vàng trên án thư và rời đi (+$6 Vàng).",
                action = function(gameState)
                    gameState.gold = gameState.gold + 6
                    return "Bạn rời khỏi ngôi đền: +$6 Vàng!"
                end,
            },
        },
    },
    {
        id = "oracle",
        title = "🔮 TIÊN TRI HỘ LINH 🔮",
        subtitle = "Bà thầy bói bí ẩn lơ lửng giữa làn khói tím mờ ảo.",
        desc = "Bà ta xòe những ngón tay đeo đầy nhẫn đá quý, nhìn thấu số phận và cơ duyên của bộ bài bạn mang theo. 'Ngươi muốn thay đổi vận mệnh thế nào, hỡi lữ khách?'",
        options = {
            {
                title = "Đồng Khí Quy Tâm",
                desc = "Biến đổi 3 lá bài ngẫu nhiên trong bộ bài thành cùng một CHẤT ngẫu nhiên!",
                action = function(gameState)
                    local targetDeck = (gameState.persistentDeck and #gameState.persistentDeck > 0) and gameState.persistentDeck or gameState.deck
                    local changed = 0
                    local targetSuit = Deck.SUIT_ORDER[Rng.random(#Deck.SUIT_ORDER)]
                    local sInfo = Deck.SUITS[targetSuit]
                    for _, c in ipairs(targetDeck) do
                        if c.suit ~= targetSuit then
                            c.suit = targetSuit
                            c.suitName = Deck.STANDARD_SUIT_NAMES[targetSuit] or sInfo.name
                            c.suitSymbol = sInfo.symbol
                            c.color = sInfo.color
                            changed = changed + 1
                            if changed >= 3 then break end
                        end
                    end
                    if changed > 0 then
                        return "Lời nguyền đảo ngược! " .. changed .. " lá bài đã đổi sang chất " .. (Deck.STANDARD_SUIT_NAMES[targetSuit] or sInfo.name) .. "!"
                    else
                        gameState.gold = gameState.gold + 8
                        return "Bộ bài đã đồng chất " .. (Deck.STANDARD_SUIT_NAMES[targetSuit] or sInfo.name) .. "! Bà tiên tri tặng bạn: +$8 Vàng!"
                    end
                end,
            },
            {
                title = "Đánh Cược Vận Mệnh",
                desc = "50% trúng lớn nhận +$18 Vàng, 50% mất -$4 Vàng.",
                action = function(gameState)
                    if Rng.random() < 0.5 then
                        gameState.gold = gameState.gold + 18
                        return "Vận may mỉm cười rực rỡ! Bạn trúng cược: +$18 Vàng!"
                    else
                        gameState.gold = math.max(0, gameState.gold - 4)
                        return "Vận đen gõ cửa! Bạn thua cược mất -$4 Vàng."
                    end
                end,
            },
            {
                title = "Xin Lời Khuyên Bình An",
                desc = "Từ chối đánh cược và nhận quà chào mừng (+$5 Vàng).",
                action = function(gameState)
                    gameState.gold = gameState.gold + 5
                    return "Bà tiên tri gật đầu tán thưởng: +$5 Vàng an toàn!"
                end,
            },
        },
    },
}

function Events.getRandomEvent()
    local idx = Rng.random(#Events.LIST)
    return Events.LIST[idx]
end

return Events

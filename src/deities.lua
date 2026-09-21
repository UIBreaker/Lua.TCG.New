local Rng = require("src.rng")
local Deities = {}

Deities.CATALOG = {
    -- Starter deities for each suit
    deity_hearts = {
        id = "deity_hearts",
        name = "Tế Đàn Huyết Cơ",
        suit = "hearts",
        rarity = "uncommon",
        cost = 5,
        desc = "+4 Mult cho mỗi lá Cơ ghi điểm",
        lore = "Máu hiến tế nuôi dưỡng ngọn lửa cuồng nộ không bao giờ tắt.",
        onCardScored = function(card, ctx)
            if card.suit == "hearts" or card.suit == "valoria" then
                return { addMult = 4, message = "Cơ +4 Mult!" }
            end
        end,
    },
    deity_diamonds = {
        id = "deity_diamonds",
        name = "Linh Ấn Hoàng Kim",
        suit = "diamonds",
        rarity = "uncommon",
        cost = 5,
        desc = "+25 Chips cho mỗi lá Rô ghi điểm và +$2 thưởng sau mỗi round",
        lore = "Vàng ròng khắc cổ tự mua chuộc cả vận mệnh tử thần.",
        onCardScored = function(card, ctx)
            if card.suit == "diamonds" or card.suit == "aurelia" then
                return { addChips = 25, message = "Rô +25 Chips!" }
            end
        end,
        onRoundWin = function(ctx)
            return { addGold = 2, message = "+$2 từ Linh Ấn!" }
        end,
    },
    deity_clubs = {
        id = "deity_clubs",
        name = "Vuốt Quỷ Nguyên Sinh",
        suit = "clubs",
        rarity = "uncommon",
        cost = 5,
        desc = "+1 Discard mỗi round & +30 Chips cho mọi tay bài",
        lore = "Móng vuốt tàn bạo xé rách ranh giới giữa sự sống và diệt vong.",
        onRoundStart = function(ctx)
            return { addDiscards = 1 }
        end,
        onHandScored = function(handInfo, ctx)
            return { addChips = 30, message = "Vuốt Quỷ +30 Chips!" }
        end,
    },
    deity_spades = {
        id = "deity_spades",
        name = "Thiết Quân Hắc Kiếm",
        suit = "spades",
        rarity = "rare",
        cost = 6,
        desc = "x1.5 XMult nếu tay bài đánh ra có ít nhất 1 lá Bích",
        lore = "Thanh kiếm rèn từ thép thiên thạch đen chém đứt mọi bóng ma.",
        onHandScored = function(handInfo, ctx)
            for _, c in ipairs(handInfo.scoringCards) do
                if c.suit == "spades" or c.suit == "vharos" then
                    return { xMult = 1.5, message = "Bích x1.5 Mult!" }
                end
            end
        end,
    },

    -- 10 Core Balatro-Adapted Deities
    -- 1. Joker cơ bản -> Nguyên Tội Cổ Thần (+4 Mult vô điều kiện)
    deity_genesis = {
        id = "deity_genesis",
        name = "Nguyên Tội Cổ Thần",
        rarity = "common",
        cost = 4,
        desc = "+4 Mult vô điều kiện cho mọi tay bài đánh ra",
        lore = "Tội lỗi khởi nguyên từ thuở hồng hoang vẫn đang gặm nhấm thực tại.",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 4, message = "Khởi Nguyên +4 Mult!" }
        end,
    },

    -- 2. Greedy/Lusty/Wrathful/Gluttonous Joker -> four suit-based deities.
    deity_aurelia = {
        id = "deity_aurelia",
        name = "Quang Huy Thánh Trọng",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Rô ghi điểm",
        lore = "Ánh sáng chói lòa thiêu rụi kẻ dị giáo dưới chân thiên tòa.",
        onCardScored = function(card, ctx, self)
            if card.suit == "aurelia" or card.suit == "diamonds" then
                return { addMult = 4, message = "Quang Huy +4 Mult!" }
            end
        end,
    },
    deity_elaris = {
        id = "deity_elaris",
        name = "Mộc Linh Bất Tử",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Chuồn ghi điểm",
        lore = "Rễ cây cổ thụ cắm sâu vào linh hồn người đã khuất.",
        onCardScored = function(card, ctx, self)
            if card.suit == "elaris" or card.suit == "clubs" then
                return { addMult = 4, message = "Trường Sinh +4 Mult!" }
            end
        end,
    },
    deity_vharos = {
        id = "deity_vharos",
        name = "Huyết Ma Tận Diệt",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Bích ghi điểm",
        lore = "Bóng tối nuốt chửng tro tàn của những vương triều sụp đổ.",
        onCardScored = function(card, ctx, self)
            if card.suit == "vharos" or card.suit == "spades" then
                return { addMult = 4, message = "Huyết Lửa +4 Mult!" }
            end
        end,
    },
    deity_valoria = {
        id = "deity_valoria",
        name = "Thiết Giáp Bất Bại",
        rarity = "common",
        cost = 5,
        desc = "+4 Mult cho mỗi lá chất Cơ ghi điểm",
        lore = "Ý chí bằng sắt thép không bao giờ cúi đầu trước số phận.",
        onCardScored = function(card, ctx, self)
            if card.suit == "valoria" or card.suit == "hearts" then
                return { addMult = 4, message = "Thiết Huyết +4 Mult!" }
            end
        end,
    },

    -- 3. Sly/Wily/Clever Joker -> Chiến Trận Quân Kỳ (+50 Chips cho Song Đao / Tam Hoa)
    deity_formation = {
        id = "deity_formation",
        name = "Chiến Trận Quân Kỳ",
        rarity = "common",
        cost = 5,
        desc = "+50 Chips nếu tay bài là Song Đao hoặc Tam Hoa",
        lore = "Lá cờ rách nát dựng lên giữa muôn vàn xác lính tử trận.",
        onHandScored = function(handInfo, ctx, self)
            local hId = handInfo.type and handInfo.type.id
            if hId == "pair" or hId == "two_pair" or hId == "three_of_a_kind" or hId == "full_house" then
                return { addChips = 50, message = "Trận Pháp +50 Chips!" }
            end
        end,
    },

    -- 4. Half Joker -> Linh Hồn Tử Sĩ (+7 Mult nếu đánh đúng 3 lá thuộc 3 chất khác nhau)
    deity_elite = {
        id = "deity_elite",
        name = "Linh Hồn Tử Sĩ",
        rarity = "common",
        cost = 5,
        desc = "+7 Mult nếu đánh đúng 3 lá thuộc 3 chất khác nhau",
        lore = "Sự phối hợp kỳ tài giữa ba binh chủng khác biệt tạo nên sức mạnh bất ngờ.",
        onHandScored = function(handInfo, ctx, self)
            local scoring = handInfo.scoringCards or {}
            if #scoring == 3 then
                local suits = {}
                for _, c in ipairs(scoring) do
                    suits[c.suit] = true
                end
                local count = 0
                for _ in pairs(suits) do count = count + 1 end
                if count == 3 then
                    return { addMult = 7, message = "Tinh Binh +7 Mult (3 Lá 3 Chất)!" }
                end
            end
        end,
    },

    -- 5. Banner -> Huyết Tẩy Tàn Quân (+12 Chips cho mỗi lượt Discard còn lại)
    deity_banner = {
        id = "deity_banner",
        name = "Huyết Tẩy Tàn Quân",
        rarity = "common",
        cost = 5,
        desc = "+12 Chips cho mỗi lượt Đổi Bài (Discard) còn lại",
        lore = "Mỗi nhát cờ phất lên là một linh hồn bị gạt bỏ khỏi nhân gian.",
        onHandScored = function(handInfo, ctx, self)
            local discards = (ctx and ctx.discardsRemaining) or 0
            if discards > 0 then
                local bonus = discards * 12
                return { addChips = bonus, message = "Chiến Kỷ +" .. bonus .. " Chips (" .. discards .. " Đổi)!" }
            end
        end,
    },

    -- 6. Popcorn -> Héo Mòn Hoa Độc (+20 Mult ban đầu, -4 Mult sau mỗi trận cho đến khi tan biến)
    deity_floral = {
        id = "deity_floral",
        name = "Héo Mòn Hoa Độc",
        rarity = "common",
        cost = 5,
        currentMult = 20,
        desc = "+20 Mult ban đầu (giảm -4 Mult sau mỗi trận thắng)",
        lore = "Đóa hoa ngậm độc tàn lụi dần theo từng hơi thở tử thần.",
        onHandScored = function(handInfo, ctx, self)
            local cur = (self and self.currentMult) or 20
            if cur > 0 then
                return { addMult = cur, message = "Bách Hoa +" .. cur .. " Mult!" }
            end
        end,
        onRoundWin = function(game, self)
            local cur = (self and self.currentMult) or 20
            cur = cur - 4
            if self then
                self.currentMult = cur
                self.desc = "+" .. math.max(0, cur) .. " Mult ban đầu (giảm -4 Mult sau mỗi trận)"
                if cur <= 0 then
                    self.extinct = true
                    return { message = "Héo Mòn Hoa Độc đã cạn kiệt linh lực và tan biến!" }
                end
            end
            return { message = "Héo Mòn Hoa Độc tàn phai còn +" .. cur .. " Mult" }
        end,
    },

    -- 7. Golden Joker -> Thổ Phỉ Hoàng Kim (+$4 Vàng khi thắng trận)
    deity_golden = {
        id = "deity_golden",
        name = "Thổ Phỉ Hoàng Kim",
        rarity = "common",
        cost = 6,
        desc = "Nhận +$4 Vàng khi chiến thắng mỗi trận",
        lore = "Bàn tay tham lam bới móc châu báu từ những nấm mồ vô danh.",
        onRoundWin = function(game, self)
            return { addGold = 4, message = "+$4 Vàng từ Thổ Phỉ Hoàng Kim!" }
        end,
    },

    -- Delayed Gratification -> Kiên Nhẫn Thần Thụ (+ $2 mỗi Discard còn lại nếu không dùng Discard nào)
    deity_delayed_gratification = {
        id = "deity_delayed_gratification",
        name = "Kiên Nhẫn Thần Thụ",
        rarity = "uncommon",
        cost = 5,
        desc = "Nhận +$2 Vàng cho mỗi lượt Đổi bài (Discard) còn lại nếu không dùng lượt Đổi bài nào trong trận",
        lore = "Sự kiềm chế tột cùng trước cám dỗ đổi vận mang lại quả ngọt vô giá.",
        onRoundWin = function(game, self)
            local discardsUsed = (game and game.discardsUsedInCombat) or 0
            local discardsLeft = (game and game.discardsRemaining) or 0
            if discardsUsed == 0 and discardsLeft > 0 then
                local bonus = discardsLeft * 2
                return { addGold = bonus, message = "+$" .. bonus .. " từ Kiên Nhẫn (" .. discardsLeft .. " Discard chưa dùng)!" }
            end
        end,
    },

    -- Business Card -> Danh Thiếp Thương Gia (+ $2 Vàng khi lá Hoàng Gia J, Q, K ghi điểm)
    deity_business_card = {
        id = "deity_business_card",
        name = "Danh Thiếp Thương Gia",
        rarity = "common",
        cost = 4,
        desc = "Mỗi lá bài Hoàng Gia (J, Q, K) ghi điểm có 50% tỉ lệ nhận ngay +$2 Vàng",
        lore = "Mối quan hệ giao thương kín đáo mang lại nguồn tài chính dồi dào khi xuất quân.",
        onCardScored = function(card, ctx, self)
            local r = card.rank or 0
            if r == 11 or r == 12 or r == 13 then
                local roll = Rng.random(2)
                if roll == 1 then
                    return { addGold = 2, message = "+$2 Vàng (Danh Thiếp)!" }
                end
            end
        end,
    },

    -- 8. Gros Michel -> Cấm Quả Hỗn Mang (+15 Mult, 1/6 tự hủy mở khóa Bất Diệt Cổ Thụ)
    deity_sacred_fruit = {
        id = "deity_sacred_fruit",
        name = "Cấm Quả Hỗn Mang",
        rarity = "common",
        cost = 5,
        desc = "+15 Mult. Có 1/6 tỉ lệ thăng thiên sau mỗi trận (mở khóa Bất Diệt Cổ Thụ)",
        lore = "Trái cấm mang mầm mống diệt vong, chực chờ thức tỉnh cổ thụ.",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 15, message = "Cấm Quả +15 Mult!" }
        end,
        onRoundWin = function(game, self)
            local roll = Rng.random(6)
            if roll == 1 then
                if self then self.extinct = true end
                if game then game.sacredFruitExtinct = true end
                return { message = "Cấm Quả Hỗn Mang đã thức tỉnh! (Mở khóa Bất Diệt Cổ Thụ trong Shop)" }
            end
        end,
    },
    -- Cavendish -> Bất Diệt Thần Thụ (x1.5 sau khi đã đánh 3 kiểu bài khác nhau trong trận)
    deity_eternal_tree = {
        id = "deity_eternal_tree",
        name = "Bất Diệt Thần Thụ",
        rarity = "rare",
        cost = 8,
        requiresExtinct = "deity_sacred_fruit",
        desc = "x1.5 XMult sau khi đã đánh 3 kiểu bài khác nhau trong trận",
        lore = "Cây đại thụ hấp thu linh khí từ sự biến hóa khôn lường của trận đồ.",
        onHandScored = function(handInfo, ctx, self)
            local history = (ctx and ctx.playedHandsHistory) or (ctx and ctx.gameState and ctx.gameState.playedHandsHistory) or {}
            local distinct = 0
            for _ in pairs(history) do distinct = distinct + 1 end
            if distinct >= 3 then
                return { xMult = 1.5, message = "Bất Diệt Thần Thụ ×1.5 Mult (3 kiểu bài khác nhau)!" }
            end
        end,
    },

    -- 9. Card Sharp -> Vọng Âm Trùng Điệp (x1.6 XMult khi kiểu bài khác lượt trước)
    deity_echo = {
        id = "deity_echo",
        name = "Vọng Âm Trùng Điệp",
        rarity = "rare",
        cost = 7,
        desc = "x1.6 XMult khi kiểu bài khác lượt trước",
        lore = "Tiếng vang biến ảo không bao giờ lặp lại chính mình.",
        onHandScored = function(handInfo, ctx, self)
            local handId = handInfo.type and handInfo.type.id
            local lastHandId = (ctx and ctx.lastPlayedHandId) or (ctx and ctx.gameState and ctx.gameState.lastPlayedHandId)
            if lastHandId and handId and handId ~= lastHandId then
                return { xMult = 1.6, message = "Vọng Âm ×1.6 Mult (Khác kiểu bài lượt trước)!" }
            end
        end,
    },

    -- 10. Blueprint -> Gương Hồn Phản Chiếu (Sao chép Thần bên phải)
    deity_mirror = {
        id = "deity_mirror",
        name = "Gương Hồn Phản Chiếu",
        rarity = "legendary",
        cost = 10,
        isCopyDeity = true,
        desc = "Sao chép toàn bộ kỹ năng của Hộ Linh đứng ngay bên phải nó",
        lore = "Mặt gương nứt vỡ phản chiếu bản sao quái dị của thực tại.",
    },

    -- Shop & discoverable deities
    deity_generous = {
        id = "deity_generous",
        name = "Hào Phóng Cổ Thần",
        rarity = "common",
        cost = 4,
        desc = "+50 Chips cố định vào mỗi tay bài",
        lore = "Bố thí chút sinh lực tàn tạ cho kẻ dám thách thức thần linh.",
        onHandScored = function(handInfo, ctx, self)
            return { addChips = 50, message = "+50 Chips!" }
        end,
    },
    deity_flame = {
        id = "deity_flame",
        name = "Hỏa Diệm Nộ Cuồng",
        rarity = "common",
        cost = 4,
        desc = "+6 Mult cho mọi tay bài",
        lore = "Lửa căm hờn bùng cháy thiêu rụi toàn bộ bàn bài.",
        onHandScored = function(handInfo, ctx, self)
            return { addMult = 6, message = "+6 Mult!" }
        end,
    },
    deity_pairs = {
        id = "deity_pairs",
        name = "Song Hồn Cổ Linh",
        rarity = "uncommon",
        cost = 5,
        desc = "+12 Mult nếu tay bài là Đôi hoặc Hai Đôi",
        lore = "Hai linh hồn dị dạng bị xích chặt vào nhau trong ngục tối.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "pair" or handInfo.type.id == "two_pair" then
                return { addMult = 12, message = "Song Hồn +12 Mult!" }
            end
        end,
    },
    deity_straight = {
        id = "deity_straight",
        name = "Trường Long Cuồng Nộ",
        rarity = "uncommon",
        cost = 6,
        desc = "+100 Chips và x1.5 XMult nếu đánh ra Sảnh",
        lore = "Con rồng xương rỗng uốn mình giữa dòng chảy hỗn mang.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "straight" or handInfo.type.id == "straight_flush" then
                return { addChips = 100, xMult = 1.5, message = "Trường Long x1.5 Mult & +100 Chips!" }
            end
        end,
    },
    deity_flush = {
        id = "deity_flush",
        name = "Thâm Uyên Hải Triều",
        rarity = "uncommon",
        cost = 6,
        desc = "+15 Mult nếu tay bài là Thùng",
        lore = "Thủy triều đen nhấn chìm mọi hy vọng vào đáy biển sâu.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "flush" or handInfo.type.id == "straight_flush" then
                return { addMult = 15, message = "Thâm Uyên +15 Mult!" }
            end
        end,
    },
    deity_royalty = {
        id = "deity_royalty",
        name = "Huyết Mạch Vương Quyền",
        rarity = "uncommon",
        cost = 6,
        desc = "+25 Chips cho mỗi lá J, Q, K ghi điểm",
        lore = "Dòng máu quý tộc nhiễm độc chảy trong huyết quản kẻ bạo chúa.",
        onCardScored = function(card, ctx, self)
            if card.rank >= 11 and card.rank <= 13 then
                return { addChips = 25, message = "Vương Quyền +25 Chips!" }
            end
        end,
    },
    deity_ace = {
        id = "deity_ace",
        name = "Thần Khí Tuyệt Diệt",
        rarity = "rare",
        cost = 7,
        desc = "+15 Mult và x1.5 XMult khi có ít nhất một lá Át ghi điểm",
        lore = "Cổ vật cấm kỵ có thể xóa sổ cả một nền văn minh trong chớp mắt.",
        onHandScored = function(handInfo, ctx, self)
            local hasAce = false
            for _, c in ipairs(handInfo.scoringCards) do
                if c.rank == 14 then
                    hasAce = true
                    break
                end
            end
            if hasAce then
                return { addMult = 15, xMult = 1.5, message = "Tuyệt Diệt x1.5 Mult & +15 Mult!" }
            end
        end,
    },
    deity_fullhouse = {
        id = "deity_fullhouse",
        name = "Thâm Uyên Cự Thú",
        rarity = "rare",
        cost = 7,
        desc = "x2.0 XMult nếu đánh ra Cù Lũ hoặc Tứ Quý",
        lore = "Quái vật nghìn mắt thức giấc từ đáy vực sâu thẳm.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo.type.id == "full_house" or handInfo.type.id == "four_of_a_kind" then
                return { xMult = 2.0, message = "Cự Thú x2.0 Mult!" }
            end
        end,
    },
    deity_clutch = {
        id = "deity_clutch",
        name = "Tử Khắc Phục Hận",
        rarity = "rare",
        cost = 7,
        desc = "x2.0 XMult ở Lượt đánh (Hand) cuối cùng của round",
        lore = "Cú đánh tuyệt vọng của kẻ sắp bước qua ngưỡng cửa tử thần.",
        onHandScored = function(handInfo, ctx, self)
            if ctx and ctx.handsRemaining == 0 then
                return { xMult = 2.0, message = "Tử Khắc x2.0 Mult!" }
            end
        end,
    },
    deity_supreme = {
        id = "deity_supreme",
        name = "Hỗn Mang Tối Thượng",
        rarity = "legendary",
        cost = 10,
        desc = "x1.4 XMult nếu nó là Hộ Linh duy nhất đang hoạt động",
        lore = "Sức mạnh tuyệt đối khinh miệt sự hiện diện của bất kỳ thần linh nào khác.",
        onHandScored = function(handInfo, ctx, self)
            local deities = (ctx and ctx.deities) or (ctx and ctx.gameState and ctx.gameState.deities) or {}
            local activeCount = Deities.getCount(deities)
            if activeCount <= 1 then
                return { xMult = 1.4, message = "TỐI THƯỢNG ×1.4 Mult (Độc Tôn)!" }
            end
        end,
    },

    -- 5 Hộ Linh Chiến Lược Mới
    deity_war_god = {
        id = "deity_war_god",
        name = "Chiến Thần Tàn Bạo",
        rarity = "rare",
        cost = 7,
        desc = "Nếu người chơi có Giáp: +15 Giáp nhưng -50% Sát thương; Nếu không có Giáp: +12 Mult",
        lore = "Chiến tranh chỉ có hai bộ mặt: hoặc bọc thép phòng ngự, hoặc liều chết xung phong.",
        onHandScored = function(handInfo, ctx, self)
            local curArmor = (ctx and ctx.playerArmor) or (ctx and ctx.gameState and ctx.gameState.playerArmor) or 0
            if curArmor > 0 then
                return { addArmor = 15, xMult = 0.5, message = "Chiến Thần: Thủ Trận (+15 Giáp, -50% Dmg)" }
            else
                return { addMult = 12, message = "Chiến Thần: Công Trận (+12 Mult)" }
            end
        end,
    },
    deity_time_weaver = {
        id = "deity_time_weaver",
        name = "Kẻ Diệt Thời Gian",
        rarity = "uncommon",
        cost = 6,
        desc = "Giữ 1 lá bài sang lượt sau; lượt tiếp theo rút ít hơn 1 lá",
        lore = "Kéo dài khoảnh khắc hiện tại đồng nghĩa với việc rút ngắn tương lai.",
        onRoundStart = function(ctx)
            return { addDiscards = 1 }
        end,
    },
    deity_living_archive = {
        id = "deity_living_archive",
        name = "Thư Khố Sống",
        rarity = "rare",
        cost = 7,
        desc = "+50 Chips & +15 Mult khi đã chơi ít nhất 3 kiểu bài khác nhau trong trận",
        lore = "Tri thức vĩ đại thức tỉnh khi binh pháp biến ảo khôn lường.",
        onHandScored = function(handInfo, ctx, self)
            local history = (ctx and ctx.playedHandsHistory) or (ctx and ctx.gameState and ctx.gameState.playedHandsHistory) or {}
            local distinct = 0
            for _ in pairs(history) do distinct = distinct + 1 end
            if distinct >= 3 then
                return { addChips = 50, addMult = 15, message = "Thư Khố Sống (+50 Chips, +15 Mult)!" }
            end
        end,
    },
    deity_debt_god = {
        id = "deity_debt_god",
        name = "Minh Phủ Khế Ước",
        rarity = "uncommon",
        cost = 6,
        desc = "Mỗi trận chiến: Tự giảm 3 Max HP để nhận vĩnh viễn +25 Chips và +4 Mult cho trận này",
        lore = "Đánh đổi từng mảnh sinh mệnh để đổi lấy chiến thắng trước mắt.",
        onRoundStart = function(ctx)
            if ctx and ctx.maxPlayerHp and ctx.maxPlayerHp > 10 then
                ctx.maxPlayerHp = ctx.maxPlayerHp - 3
                if ctx.playerHp and ctx.playerHp > ctx.maxPlayerHp then
                    ctx.playerHp = ctx.maxPlayerHp
                end
            end
        end,
        onHandScored = function(handInfo, ctx, self)
            return { addChips = 25, addMult = 4, message = "Minh Phủ (+25 Chips, +4 Mult)" }
        end,
    },
    deity_gravekeeper = {
        id = "deity_gravekeeper",
        name = "Người Giữ Mộ Cổ",
        rarity = "uncommon",
        cost = 5,
        desc = "+20 Chips và +3 Mult cho mỗi lá bài đã bị tiêu hao hoặc vứt bỏ trong trận",
        lore = "Linh hồn những lá bài đã mất hóa thành sức mạnh cho kẻ còn sống.",
        onHandScored = function(handInfo, ctx, self)
            local discardsUsed = (ctx and ctx.discardsUsedInCombat) or 0
            local bonusC = discardsUsed * 20
            local bonusM = discardsUsed * 3
            if bonusC > 0 or bonusM > 0 then
                return { addChips = bonusC, addMult = bonusM, message = "Người Giữ Mộ (+" .. bonusC .. " Chips, +" .. bonusM .. " Mult)" }
            end
        end,
    },
    deity_vanguard_marshal = {
        id = "deity_vanguard_marshal",
        name = "Nguyên Soái Tiền Tuyến",
        rarity = "uncommon",
        cost = 6,
        desc = "Lá bài đầu tiên ghi điểm nhận +10 Mult; lá bài cuối cùng ghi điểm tạo +6 Giáp",
        lore = "Kỷ luật thép điều binh khiển tướng: tiền quân công phá, hậu quân vững thành.",
        onHandScored = function(handInfo, ctx, self)
            if handInfo and handInfo.scoringCards and #handInfo.scoringCards > 0 then
                return { addMult = 10, addArmor = 6, message = "Nguyên Soái Tiền Tuyến (+10 Mult Tiền Quân, +6 Giáp Hậu Quân)" }
            end
        end,
    },
}

function Deities.getCount(deities)
    if not deities then return 0 end
    local count = 0
    for i = 1, 5 do
        if deities[i] ~= nil then
            count = count + 1
        end
    end
    for k, v in pairs(deities) do
        if type(k) == "number" and (k < 1 or k > 5) and v ~= nil then
            count = count + 1
        end
    end
    return count
end

function Deities.resolveDeity(deities, index)
    if not deities or not deities[index] then return nil end
    local current = deities[index]
    if not current.isCopyDeity then return current end

    -- Blueprint logic: copy first valid non-copy deity to the right (checking slots up to maxLimit)
    local maxLimit = 5
    for k in pairs(deities) do
        if type(k) == "number" and k > maxLimit then
            maxLimit = k
        end
    end
    local targetIdx = index + 1
    while targetIdx <= maxLimit do
        local candidate = deities[targetIdx]
        if candidate and not candidate.isCopyDeity then
            -- Mirror cannot copy Legendary deities:
            if candidate.rarity == "legendary" then
                return nil
            end
            -- Mirror copies at 60% potency and excludes economic effects (addGold)
            local proxy = {
                id = candidate.id,
                name = candidate.name,
                rarity = candidate.rarity,
                cost = candidate.cost,
                desc = "(Gương 60%) " .. (candidate.desc or ""),
            }
            if candidate.onCardScored then
                proxy.onCardScored = function(card, ctx, self)
                    local res = candidate.onCardScored(card, ctx, candidate)
                    if res then
                        local copyRes = {}
                        if res.addChips then copyRes.addChips = math.floor(res.addChips * 0.6) end
                        if res.addMult then copyRes.addMult = math.floor(res.addMult * 0.6) end
                        if res.xMult then copyRes.xMult = 1.0 + (res.xMult - 1.0) * 0.6 end
                        copyRes.message = (res.message or "") .. " (Gương 60%)"
                        return copyRes
                    end
                end
            end
            if candidate.onHandScored then
                proxy.onHandScored = function(handInfo, ctx, self)
                    local res = candidate.onHandScored(handInfo, ctx, candidate)
                    if res then
                        local copyRes = {}
                        if res.addChips then copyRes.addChips = math.floor(res.addChips * 0.6) end
                        if res.addMult then copyRes.addMult = math.floor(res.addMult * 0.6) end
                        if res.xMult then copyRes.xMult = 1.0 + (res.xMult - 1.0) * 0.6 end
                        copyRes.message = (res.message or "") .. " (Gương 60%)"
                        return copyRes
                    end
                end
            end
            -- onRoundWin / economic effects are omitted
            return proxy
        end
        targetIdx = targetIdx + 1
    end
    return nil
end

function Deities.getStarterDeity(suit)
    if suit == "hearts" or suit == "valoria" then
        return Deities.CATALOG.deity_valoria or Deities.CATALOG.deity_hearts
    elseif suit == "diamonds" or suit == "aurelia" then
        return Deities.CATALOG.deity_aurelia or Deities.CATALOG.deity_diamonds
    elseif suit == "clubs" or suit == "elaris" then
        return Deities.CATALOG.deity_elaris or Deities.CATALOG.deity_clubs
    elseif suit == "spades" or suit == "vharos" then
        return Deities.CATALOG.deity_vharos or Deities.CATALOG.deity_spades
    end
    return Deities.CATALOG.deity_genesis or Deities.CATALOG.deity_hearts
end

function Deities.getRandomShopPool(ownedDeities, count, gameState)
    local pool = {}
    local ownedIds = {}
    local hasLegendary = false
    if ownedDeities then
        for _, d in pairs(ownedDeities) do
            if type(d) == "table" and d.id then
                ownedIds[d.id] = true
                if d.rarity == "legendary" then
                    hasLegendary = true
                end
            end
        end
    end

    local currentAnte = (gameState and gameState.run and gameState.run.ante) or (gameState and gameState.ante) or 1

    local categorized = { common = {}, uncommon = {}, rare = {}, legendary = {} }
    for id, d in pairs(Deities.CATALOG) do
        if not ownedIds[id] then
            local allowed = true
            if d.requiresExtinct and not (gameState and gameState.sacredFruitExtinct) then
                allowed = false
            end
            if d.rarity == "legendary" and (currentAnte < 5 or hasLegendary) then
                allowed = false
            end
            if allowed then
                local r = d.rarity or "common"
                categorized[r] = categorized[r] or {}
                table.insert(categorized[r], d)
            end
        end
    end

    -- Rarity Distribution: Thường 60%, Khá 28%, Hiếm 10%, Huyền thoại 2% (Ante 5+)
    local targetCount = count or 3
    for _ = 1, targetCount do
        local roll = Rng.random(100)
        local targetRarity = "common"
        if roll <= 60 then
            targetRarity = "common"
        elseif roll <= 88 then
            targetRarity = "uncommon"
        elseif roll <= 98 then
            targetRarity = "rare"
        else
            targetRarity = (currentAnte >= 5 and not hasLegendary) and "legendary" or "rare"
        end

        local bucket = categorized[targetRarity]
        if not bucket or #bucket == 0 then
            for _, rName in ipairs({ "common", "uncommon", "rare", "legendary" }) do
                if categorized[rName] and #categorized[rName] > 0 then
                    bucket = categorized[rName]
                    break
                end
            end
        end

        if bucket and #bucket > 0 then
            local idx = Rng.random(#bucket)
            local chosen = table.remove(bucket, idx)
            table.insert(pool, chosen)
            if chosen.rarity == "legendary" then hasLegendary = true end
        end
    end

    return pool
end

function Deities.getBossDraftPool(ownedDeities, count)
    count = count or 2
    local pool = {}
    local ownedIds = {}
    if ownedDeities then
        for i = 1, 5 do
            local d = ownedDeities[i]
            if d and d.id then ownedIds[d.id] = true end
        end
        for _, d in pairs(ownedDeities) do
            if type(d) == "table" and d.id then ownedIds[d.id] = true end
        end
    end

    local candidates = {}
    for id, d in pairs(Deities.CATALOG) do
        if not ownedIds[id] then
            table.insert(candidates, d)
        end
    end

    for i = #candidates, 2, -1 do
        local j = Rng.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end

    for i = 1, math.min(count, #candidates) do
        table.insert(pool, candidates[i])
    end

    return pool
end

Deities.BASE_SLOTS = 3
Deities.MAX_SLOTS = 3

function Deities.getMaxSlots(gameState)
    local base = Deities.BASE_SLOTS or 3
    local bonus = (gameState and gameState.extraDeitySlots) or 0
    local maxSlots = math.min(4, base + bonus)
    local deitiesList = nil
    if gameState and gameState.deities then
        deitiesList = gameState.deities
    elseif type(gameState) == "table" and not gameState.deities then
        deitiesList = gameState
    end
    if deitiesList then
        for _, d in pairs(deitiesList) do
            if type(d) == "table" and d.edition == "negative" then
                maxSlots = maxSlots + 1
            end
        end
    end
    return maxSlots
end

function Deities.addDeity(gameState, deity, preferredSlot)
    if not gameState.deities then
        gameState.deities = {}
    end
    local maxSlots = Deities.getMaxSlots(gameState)
    local count = Deities.getCount(gameState.deities)
    if count >= maxSlots then
        return false
    end
    -- Clone deity so instance state (such as currentMult or extinct) is isolated
    local instance = {}
    for k, v in pairs(deity) do
        instance[k] = v
    end

    if preferredSlot and preferredSlot >= 1 and preferredSlot <= maxSlots and gameState.deities[preferredSlot] == nil then
        gameState.deities[preferredSlot] = instance
        return true
    end

    for i = 1, maxSlots do
        if gameState.deities[i] == nil then
            gameState.deities[i] = instance
            return true
        end
    end
    return false
end

return Deities

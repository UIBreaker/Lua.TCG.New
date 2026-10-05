-- Initial economy values for playtesting; weights need not sum to 100.
local C = {
    fallbackGold = 2,
    goldBonus = {1, 3},
    maxCoins = 40,
    rowInterval = 0.16,
    lootInterval = 0.18,
    rarePause = 0.24,
    presentation = {maxSparks = 72, trailPoints = 5, flareDuration = 0.55, ambience = 18},
    pity = {enabled = false, after = 6, extraPackWeight = 5},
    -- One independent supply roll per won encounter; bosses have better odds.
    supplies = {normalChance = 0.35, bossChance = 0.65, entries = {
        {id = "healing_potion_small", weight = 25}, {id = "healing_potion_large", weight = 10},
        {id = "armor_potion_small", weight = 20}, {id = "armor_potion_large", weight = 10},
        {id = "cons_speed_small", weight = 20}, {id = "cons_speed_large", weight = 10},
        {id = "soul_reaper", weight = 5},
    }},
    rarities = {
        common = {color = {0.70, 0.76, 0.82}, label = "THƯỜNG", strength = 1},
        uncommon = {color = {0.38, 0.86, 0.62}, label = "KHÁC THƯỜNG", strength = 2},
        rare = {color = {0.28, 0.72, 1}, label = "HIẾM", strength = 3},
        epic = {color = {0.77, 0.44, 1}, label = "SỬ THI", strength = 4},
        legendary = {color = {1, 0.78, 0.27}, label = "HUYỀN THOẠI", strength = 5},
    },
    definitions = {
        gold_bonus = {type = "GOLD", rarity = "common", name = "VÀNG THƯỞNG"},
        playing_card = {type = "PLAYING_CARD", rarity = "common", name = "QUÂN BÀI"},
        card_pack = {type = "CARD_PACK", packType = "standard", rarity = "uncommon", name = "CARD PACK"},
        spn_pack = {type = "SPN_PACK", packType = "buffoon", rarity = "rare", name = "SPN PACK"},
        itm_pack = {type = "ITM_PACK", packType = "arcana", rarity = "rare", name = "ITM PACK"},
        consumable = {type = "CONSUMABLE", rarity = "uncommon", name = "TIẾP LỰC"},
        evolution = {type = "CONSUMABLE", consumable = "evolution", rarity = "epic", name = "TIẾN HÓA"},
        consumable_pack = {type = "CONSUMABLE_PACK", packType = "celestial", rarity = "uncommon", name = "GÓI HÀNH TINH"},
        chest = {type = "CHEST", rarity = "epic", name = "RƯƠNG BẠC", tableId = "silver_chest"},
        rare_reward = {type = "CHEST", rarity = "legendary", name = "RƯƠNG HOÀNG KIM", tableId = "golden_chest"},
    },
    tables = {
        normal_enemy = {rolls = {1, 1}, entries = {
            {id = "gold_bonus", weight = 40}, {id = "playing_card", weight = 25},
            {id = "card_pack", weight = 15}, {id = "consumable", weight = 10},
            {id = "spn_pack", weight = 5}, {id = "itm_pack", weight = 4}, {id = "chest", weight = 1},
        }},
        boss = {rolls = {1, 2}, entries = {
            {id = "gold_bonus", weight = 20}, {id = "playing_card", weight = 15},
            {id = "card_pack", weight = 20}, {id = "spn_pack", weight = 15},
            {id = "itm_pack", weight = 15}, {id = "chest", weight = 12}, {id = "rare_reward", weight = 3},
        }},
        tax = {rolls = {2, 2}, entries = {{id = "gold_bonus", weight = 65}, {id = "card_pack", weight = 25}, {id = "chest", weight = 10}}},
        memory = {rolls = {1, 2}, entries = {{id = "playing_card", weight = 40}, {id = "evolution", weight = 20}, {id = "card_pack", weight = 30}, {id = "chest", weight = 10}}},
        gate = {rolls = {1, 2}, entries = {{id = "card_pack", weight = 35}, {id = "spn_pack", weight = 25}, {id = "itm_pack", weight = 25}, {id = "chest", weight = 15}}},
        silver_chest = {rolls = {2, 2}, entries = {{id = "gold_bonus", weight = 40}, {id = "playing_card", weight = 30}, {id = "card_pack", weight = 20}, {id = "consumable", weight = 10}}},
        golden_chest = {rolls = {2, 2}, entries = {{id = "spn_pack", weight = 35}, {id = "itm_pack", weight = 35}, {id = "evolution", weight = 20}, {id = "consumable_pack", weight = 10}}},
    },
    bossOverrides = {black_tax_collector = "tax", memory_eater = "memory", gatekeeper = "gate"},
}
for _, entry in ipairs(C.supplies.entries) do
    C.definitions[entry.id] = {type = "CONSUMABLE", consumableId = entry.id,
        rarity = entry.id == "soul_reaper" and "rare" or entry.id:match("large$") and "uncommon" or "common"}
end
return C

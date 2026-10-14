local A={MAX_POWER=128,entries={
    {"spirit_potion_resonance","Dược Linh Cộng Hưởng","xPotionPower",1,"Hiệu quả thuốc ×{factor}: tăng lượng hồi, giáp, sát thương, cường hóa, tốc, rút bài, phá giáp và vàng. Chính Xác/Né Tránh tăng thời gian; Giảm Tốc tăng độ giảm, tối đa 100%. Tổng trần ×128."},
    {"spirit_potion_eternity","Dược Hồn Bất Diệt","addPotionChancePct",10,"Khi dùng thuốc Sát Thương, Cường Hóa hoặc Tốc Đánh Nhỏ/Lớn: {value}% cơ hội biến phần tăng tạm thành vĩnh viễn cho các quân chịu thuốc. Một lần quay mỗi bình; tỷ lệ tối đa 100%. Không áp dụng thuốc khác."},
}}
local D
function A.register(deities)
    D=deities
    for _,row in ipairs(A.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,trigger="potion",
            lore="Dị linh luyện dược khuếch đại tinh chất hoặc kết nó vào quân bài thành dấu ấn lâu dài."}
        entry.desc=row[5]:gsub("{factor}","2"):gsub("{value}",tostring(row[4]));entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
function A.isPotion(item)
    return item and (require("src.potions").byId[item.id] or item.id=="healing_potion" or item.id=="healing_potion_large"
        or item.id=="armor_potion_small" or item.id=="armor_potion_large" or item.id=="cons_speed_small" or item.id=="cons_speed_large")
end
function A.effects(game)
    D=D or require("src.deities")
    local power,chance=1,0
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source)
                if source.id=="spirit_potion_resonance" then
                    power=math.min(A.MAX_POWER,power*D.scaleEffect(source,{xPotionPower=2}).xPotionPower)
                elseif source.id=="spirit_potion_eternity" then
                    local percent=D.scaleEffect(source,{addPotionChancePct=10}).addPotionChancePct
                    chance=chance+(100-chance)*percent/100
                end
            end)
        end
    end
    return power,chance
end
function A.multiplier(game,item)
    if not A.isPotion(item) then return 1 end
    return (A.effects(game))
end
function A.rollPermanent(game)
    local _,chance=A.effects(game)
    return chance>=100 or chance>0 and require("src.rng").random()*100<chance
end
return A

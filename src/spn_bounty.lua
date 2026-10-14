local B={id="spirit_victory_bounty",MAX_EXTRA_ROLLS=32,MAX_RARE_WEIGHT_PCT=2000}
local D
function B.register(deities)
    D=deities
    local entry={id=B.id,name="Phúc Linh Khải Hoàn",stat="addRewardRolls",values={value=1},turnGrowth=true,integerEffect=true,
        rarity="common",cost=4,trigger="victory_loot",lore="Sứ giả dị giới mở cánh cổng phúc lành cho đoàn viễn chinh vừa chiến thắng.",
        descriptionTemplate="Lễ trao thưởng khi thắng: +{value} lượt rút quà; tăng trọng số quà bậc Hiếm trở lên thêm {rareWeight}%. Áp dụng độ hiếm cả trong rương và tiếp tế của lễ. Tổng tối đa +32 lượt, +2000% trọng số mỗi lễ."}
    entry.onVictoryLoot=function() return {addRewardRolls=1,addRareWeightPct=100} end
    entry.desc=entry.descriptionTemplate:gsub("{value}","1"):gsub("{rareWeight}","100");entry.baseDesc=entry.desc
    D.CATALOG[B.id]=entry
end
function B.description(deity)
    D=D or require("src.deities")
    local value=D.scaleEffect(deity,{addRewardRolls=1,addRareWeightPct=100})
    return D.CATALOG[B.id].descriptionTemplate:gsub("{value}",string.format("%g",math.min(B.MAX_EXTRA_ROLLS,value.addRewardRolls)))
        :gsub("{rareWeight}",string.format("%g",math.min(B.MAX_RARE_WEIGHT_PCT,value.addRareWeightPct)))
end
function B.bonus(game)
    D=D or require("src.deities")
    local bonus={extraRolls=0,rareWeightPct=0}
    for slot=1,D.getMaxSlots(game) do
        if not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            require("src.spn_mimic").each(game,game.deities,slot,function(source)
                if not source.onVictoryLoot then return end
                local effect=D.scaleEffect(source,source.onVictoryLoot(game,source))
                if not effect then return end
                bonus.extraRolls=math.min(B.MAX_EXTRA_ROLLS,bonus.extraRolls+math.max(0,math.floor(effect.addRewardRolls or 0)))
                bonus.rareWeightPct=math.min(B.MAX_RARE_WEIGHT_PCT,bonus.rareWeightPct+math.max(0,effect.addRareWeightPct or 0))
            end)
        end
    end
    return bonus
end
function B.weight(entry,weight,bonus)
    local config=require("config.reward_loot")
    local def=config.definitions[entry.id]
    local rarity=def and config.rarities[def.rarity]
    if rarity and rarity.strength>=3 then return weight*(1+(bonus and bonus.rareWeightPct or 0)/100) end
    return weight
end
return B

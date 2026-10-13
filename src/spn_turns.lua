local T={entries={
    {"spirit_second_choice","Gió Đổi Vận","addDiscards",1,"Vào trận: +{value} lượt bỏ bài. Mỗi cấp tiến hóa thêm 1 lượt."},
    {"spirit_extra_strike","Dư Âm Chiến Ý","addHands",1,"Vào trận: +{value} lượt đánh. Mỗi cấp tiến hóa thêm 1 lượt."},
    {"spirit_legend_council","Hội Đồng Huyền Thoại","xMult",1.5,"Khi tính điểm: mỗi SPN đúng bậc L trong ô trang bị nhân ×{factor} Cường hóa, nhân liên tiếp. Tính cả chính lá này nếu đạt L; không tính balo hay bậc khác."},
}}
local D
function T.legendCount(list)
    D=D or require("src.deities")
    local count=0
    for slot,owned in pairs(list or {}) do
        if type(slot)=="number" and slot>=1 and type(owned)=="table" and owned.id then
            local tier,overflow=D.getRarityTier(owned)
            if tier==5 and overflow==0 then count=count+1 end
        end
    end
    return count
end
function T.register(deities)
    D=deities
    for _,row in ipairs(T.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,
            trigger=row[3]=="xMult" and "hand" or "start",lore="Một dị linh kéo dài cơ hội chiến đấu, hoặc tụ hội uy quyền huyền thoại."}
        if entry.trigger=="start" then
            entry.turnGrowth=true;entry.integerEffect=true
            entry.onRoundStart=function() return {[entry.stat]=entry.values.value} end
        else
            entry.onHandScored=function(hand,context)
                context=context or {}
                local count=context.legendarySpnCount
                if count==nil then count=T.legendCount(context.gameState and context.gameState.deities) end
                if count>0 then
                    return {xMult=1+entry.values.value,xMultRepeats=count,fixedMessage=true,
                        message="HỘI ĐỒNG · "..count.." SPN ĐÚNG BẬC L"}
                end
            end
        end
        entry.desc=row[5]:gsub("{value}",tostring(row[4])):gsub("{factor}",tostring(1+row[4]));entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
return T

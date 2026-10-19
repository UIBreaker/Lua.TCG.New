local A={entries={
    {"spirit_aura_bifurcation","Song Quang Hội Tụ","xAura",1,"Mỗi tay: ×{factor} tổng AURA sau khi tính Sát thương × Cường hóa và sát thương cố định. Không nhân riêng Sát thương hay Cường hóa."},
    {"spirit_numeral_weaver","Kẻ Dệt Số","addWrittenAuraPower",1,"Ghép số của mọi quân đã đánh theo thứ tự để ghi thẳng AURA, rồi ×{value}. A=1, J=11, Q=12, K=13. Thay điểm nền, Sát thương, Cường hóa và sát thương cố định; vẫn nhận ×AURA. Nhiều bản chỉ dùng kết quả cao nhất, không nối lại số."},
}}
local D
function A.digits(hand)
    local parts={}
    for _,card in ipairs(require("src.spn_formations").played(hand)) do
        local rank=tonumber(card.rank)
        if not rank or rank%1~=0 or rank<1 or rank>14 then return nil end
        parts[#parts+1]=tostring(rank==14 and 1 or rank)
    end
    if #parts==0 then return nil end
    return table.concat(parts)
end
function A.isWriting(deities,game)
    D=D or require("src.deities")
    for slot=1,D.getMaxSlots(game or deities) do
        if not game or not require("src.boss_abilities").isSlotLocked(game,"spn",slot) then
            local source=D.resolveDeity(deities,slot,game)
            if source and source.id=="spirit_numeral_weaver" then return true end
        end
    end
    return false
end
function A.register(deities)
    D=deities
    for _,row in ipairs(A.entries) do
        local entry={id=row[1],name=row[2],stat=row[3],values={value=row[4]},descriptionTemplate=row[5],rarity="common",cost=4,trigger="hand",
            lore="Dị linh viết lại dòng năng lượng của đoàn viễn chinh."}
        if entry.id=="spirit_aura_bifurcation" then
            entry.onHandScored=function() return {xAura=2,fixedMessage=true,message="SONG QUANG · NHÂN TỔNG AURA"} end
        else
            entry.onHandScored=function(hand,_,owned)
                local digits=A.digits(hand);if not digits then return end
                local power=D.scaleEffect(owned or entry,{addWrittenAuraPower=1}).addWrittenAuraPower
                return {writtenAura=tonumber(digits)*power,writtenDigits=digits,fixedMessage=true,message="DỆT SỐ · "..digits.." → AURA · ×"..power}
            end
        end
        entry.desc=row[5]:gsub("{factor}","2"):gsub("{value}","1");entry.baseDesc=entry.desc
        D.CATALOG[entry.id]=entry
    end
end
return A
